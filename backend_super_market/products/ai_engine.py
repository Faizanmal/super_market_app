"""
AI-Powered Predictive Analytics Engine
Provides machine learning-based predictions for inventory optimization.
"""
import logging
from typing import Dict, List, Any, Optional, Tuple
from decimal import Decimal
from datetime import datetime, date, timedelta
from collections import defaultdict
import json

from django.db.models import Sum, Avg, Count, F, Q
from django.db.models.functions import TruncDate, TruncWeek, ExtractWeekDay
from django.utils import timezone

logger = logging.getLogger(__name__)


class PredictiveAnalyticsEngine:
    """
    AI-powered predictive analytics for inventory management.
    Uses statistical analysis and ML-style predictions for:
    - Demand forecasting
    - Expiry waste prediction
    - Optimal pricing recommendations
    - Reorder point optimization
    """
    
    def __init__(self, store_id: int = None):
        self.store_id = store_id
    
    def predict_demand(
        self,
        product_id: int,
        days_ahead: int = 30,
        confidence_level: float = 0.95
    ) -> Dict[str, Any]:
        """
        Predict demand for a product using historical data and seasonality.
        
        Uses weighted moving average with seasonal adjustments.
        """
        from products.models import Product, StockMovement
        
        try:
            product = Product.objects.get(pk=product_id)
        except Product.DoesNotExist:
            return {'error': 'Product not found'}
        
        # Get historical sales data (90 days)
        lookback_days = 90
        start_date = timezone.now() - timedelta(days=lookback_days)
        
        movements = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=start_date
        ).annotate(
            date=TruncDate('created_at'),
            weekday=ExtractWeekDay('created_at')
        ).values('date', 'weekday').annotate(
            daily_sales=Sum('quantity')
        ).order_by('date')
        
        if not movements.exists():
            return {
                'product_id': product_id,
                'product_name': product.name,
                'prediction_confidence': 0,
                'message': 'Insufficient historical data for prediction',
                'forecast': []
            }
        
        # Calculate statistics
        daily_data = list(movements)
        total_sales = sum(d['daily_sales'] for d in daily_data)
        avg_daily_sales = total_sales / len(daily_data)
        
        # Calculate weekday multipliers for seasonality
        weekday_sales = defaultdict(list)
        for d in daily_data:
            weekday_sales[d['weekday']].append(d['daily_sales'])
        
        weekday_multipliers = {}
        for weekday, sales in weekday_sales.items():
            weekday_avg = sum(sales) / len(sales) if sales else avg_daily_sales
            weekday_multipliers[weekday] = weekday_avg / avg_daily_sales if avg_daily_sales > 0 else 1.0
        
        # Calculate variance for confidence intervals
        variance = sum((d['daily_sales'] - avg_daily_sales) ** 2 for d in daily_data) / len(daily_data)
        std_dev = variance ** 0.5
        
        # Z-score for confidence level (95% = 1.96)
        z_score = 1.96 if confidence_level == 0.95 else 1.645
        
        # Generate forecast
        forecast = []
        current_date = timezone.now().date()
        cumulative_demand = 0
        
        for i in range(days_ahead):
            forecast_date = current_date + timedelta(days=i + 1)
            weekday = forecast_date.weekday() + 1  # 1-7 for Monday-Sunday
            
            # Apply seasonal multiplier
            multiplier = weekday_multipliers.get(weekday, 1.0)
            predicted = avg_daily_sales * multiplier
            
            # Confidence interval
            margin = z_score * std_dev * multiplier
            
            cumulative_demand += predicted
            
            forecast.append({
                'date': forecast_date.isoformat(),
                'predicted_demand': round(predicted, 1),
                'lower_bound': max(0, round(predicted - margin, 1)),
                'upper_bound': round(predicted + margin, 1),
                'cumulative_demand': round(cumulative_demand, 1),
            })
        
        # Calculate stockout risk
        stockout_day = None
        for i, day in enumerate(forecast):
            if day['cumulative_demand'] > product.quantity:
                stockout_day = i + 1
                break
        
        # Calculate prediction confidence based on data quality
        data_points = len(daily_data)
        data_quality_score = min(100, data_points * 1.5)  # More data = higher confidence
        variance_score = max(0, 100 - (std_dev / avg_daily_sales * 100)) if avg_daily_sales > 0 else 50
        prediction_confidence = (data_quality_score + variance_score) / 2
        
        return {
            'product_id': product_id,
            'product_name': product.name,
            'current_stock': product.quantity,
            'average_daily_demand': round(avg_daily_sales, 2),
            'prediction_confidence': round(prediction_confidence, 1),
            'data_points_used': data_points,
            'weekday_patterns': {
                self._weekday_name(k): round(v, 2) 
                for k, v in weekday_multipliers.items()
            },
            'stockout_risk': {
                'days_until_stockout': stockout_day,
                'recommended_reorder_date': (
                    current_date + timedelta(days=stockout_day - 7)
                ).isoformat() if stockout_day and stockout_day > 7 else None,
                'recommended_quantity': round(cumulative_demand * 1.2, 0),  # 20% buffer
            } if stockout_day else {'days_until_stockout': None, 'risk_level': 'low'},
            'forecast': forecast,
        }
    
    def predict_waste(
        self,
        category_id: int = None,
        days_ahead: int = 30
    ) -> Dict[str, Any]:
        """
        Predict potential waste from expiring products.
        """
        from products.models import Product
        
        today = timezone.now().date()
        end_date = today + timedelta(days=days_ahead)
        
        # Get products expiring in the forecast period
        products = Product.objects.filter(
            is_active=True,
            expiry_date__gte=today,
            expiry_date__lte=end_date
        )
        
        if category_id:
            products = products.filter(category_id=category_id)
        
        if self.store_id:
            products = products.filter(store_id=self.store_id)
        
        # Group by expiry date
        expiry_data = products.values('expiry_date').annotate(
            product_count=Count('id'),
            total_quantity=Sum('quantity'),
            total_value=Sum(F('quantity') * F('cost_price')),
        ).order_by('expiry_date')
        
        # Calculate risk scores based on typical sales velocity
        waste_forecast = []
        total_at_risk_value = Decimal('0')
        total_at_risk_quantity = 0
        
        for data in expiry_data:
            days_until = (data['expiry_date'] - today).days
            
            # Risk increases as expiry approaches
            # Products need to sell faster as they approach expiry
            if days_until <= 3:
                risk_score = 0.9  # Very high risk
            elif days_until <= 7:
                risk_score = 0.6  # High risk
            elif days_until <= 14:
                risk_score = 0.3  # Medium risk
            else:
                risk_score = 0.1  # Lower risk
            
            at_risk_quantity = int(data['total_quantity'] * risk_score)
            at_risk_value = data['total_value'] * Decimal(str(risk_score))
            
            total_at_risk_quantity += at_risk_quantity
            total_at_risk_value += at_risk_value
            
            waste_forecast.append({
                'expiry_date': data['expiry_date'].isoformat(),
                'days_until_expiry': days_until,
                'products_count': data['product_count'],
                'total_quantity': data['total_quantity'],
                'total_value': float(data['total_value']),
                'risk_score': risk_score,
                'at_risk_quantity': at_risk_quantity,
                'at_risk_value': float(at_risk_value),
                'recommended_action': self._get_expiry_recommendation(days_until),
            })
        
        return {
            'forecast_period_days': days_ahead,
            'store_id': self.store_id,
            'category_id': category_id,
            'summary': {
                'total_products_at_risk': sum(d['products_count'] for d in expiry_data),
                'total_quantity_at_risk': total_at_risk_quantity,
                'total_value_at_risk': float(total_at_risk_value),
                'waste_reduction_potential': float(total_at_risk_value * Decimal('0.5')),  # 50% recoverable
            },
            'daily_forecast': waste_forecast,
            'recommendations': self._generate_waste_recommendations(waste_forecast),
        }
    
    def optimize_reorder_points(
        self,
        product_id: int = None,
        service_level: float = 0.95
    ) -> List[Dict[str, Any]]:
        """
        Calculate optimal reorder points using statistical analysis.
        Service level: probability of not having a stockout (default 95%)
        """
        from products.models import Product, StockMovement
        
        products = Product.objects.filter(is_active=True)
        if product_id:
            products = products.filter(pk=product_id)
        if self.store_id:
            products = products.filter(store_id=self.store_id)
        
        # Limit to top 100 products by value if not specific product
        if not product_id:
            products = products.order_by(
                F('quantity') * F('cost_price')
            ).reverse()[:100]
        
        recommendations = []
        
        for product in products:
            # Get historical demand data
            movements = StockMovement.objects.filter(
                product=product,
                movement_type='out',
                created_at__gte=timezone.now() - timedelta(days=90)
            )
            
            daily_demand = movements.annotate(
                date=TruncDate('created_at')
            ).values('date').annotate(
                demand=Sum('quantity')
            )
            
            if not daily_demand.exists():
                continue
            
            demands = [d['demand'] for d in daily_demand]
            avg_demand = sum(demands) / len(demands)
            
            # Calculate standard deviation
            variance = sum((d - avg_demand) ** 2 for d in demands) / len(demands)
            std_dev = variance ** 0.5
            
            # Z-score for service level
            z_scores = {0.90: 1.28, 0.95: 1.645, 0.99: 2.33}
            z = z_scores.get(service_level, 1.645)
            
            # Lead time in days (default 7, could be from supplier data)
            lead_time = 7
            
            # Safety stock = Z * σ * √L
            safety_stock = z * std_dev * (lead_time ** 0.5)
            
            # Reorder point = Average demand during lead time + Safety stock
            reorder_point = (avg_demand * lead_time) + safety_stock
            
            # Economic Order Quantity (simplified)
            ordering_cost = 50  # Fixed cost per order
            holding_cost = float(product.cost_price) * 0.20  # 20% of cost per year
            annual_demand = avg_demand * 365
            
            if holding_cost > 0:
                eoq = ((2 * annual_demand * ordering_cost) / holding_cost) ** 0.5
            else:
                eoq = avg_demand * 30  # Default to 30 days supply
            
            recommendations.append({
                'product_id': product.id,
                'product_name': product.name,
                'current_min_level': product.min_stock_level,
                'current_reorder_qty': product.reorder_quantity,
                'analysis': {
                    'average_daily_demand': round(avg_demand, 2),
                    'demand_std_deviation': round(std_dev, 2),
                    'lead_time_days': lead_time,
                    'service_level': service_level,
                },
                'recommendations': {
                    'optimal_reorder_point': int(round(reorder_point)),
                    'recommended_safety_stock': int(round(safety_stock)),
                    'economic_order_quantity': int(round(eoq)),
                },
                'potential_impact': {
                    'stockout_risk_reduction': f"{service_level * 100}%",
                    'inventory_turns_improvement': round(annual_demand / max(eoq, 1), 1),
                },
            })
        
        return recommendations
    
    def recommend_pricing(
        self,
        product_id: int,
        target_margin: float = 0.20
    ) -> Dict[str, Any]:
        """
        Generate pricing recommendations based on various factors.
        """
        from products.models import Product, StockMovement
        
        try:
            product = Product.objects.get(pk=product_id)
        except Product.DoesNotExist:
            return {'error': 'Product not found'}
        
        today = timezone.now().date()
        days_until_expiry = (product.expiry_date - today).days if product.expiry_date else 365
        
        # Base price analysis
        current_margin = float(
            (product.selling_price - product.cost_price) / product.cost_price
        ) if product.cost_price > 0 else 0
        
        # Sales velocity
        recent_sales = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=timezone.now() - timedelta(days=30)
        ).aggregate(total=Sum('quantity'))['total'] or 0
        
        avg_daily_sales = recent_sales / 30
        days_of_stock = product.quantity / avg_daily_sales if avg_daily_sales > 0 else 999
        
        # Generate pricing scenarios
        recommendations = []
        
        # Expiry-based pricing
        if days_until_expiry <= 7:
            discount = min(50, max(20, 50 - days_until_expiry * 5))  # 20-50% discount
            recommendations.append({
                'scenario': 'Expiry Clearance',
                'reason': f'Product expires in {days_until_expiry} days',
                'discount_percentage': discount,
                'recommended_price': float(product.selling_price * Decimal(str(1 - discount/100))),
                'expected_margin': round(current_margin - discount/100, 2),
                'urgency': 'high',
            })
        elif days_until_expiry <= 14:
            discount = 15
            recommendations.append({
                'scenario': 'Near Expiry Discount',
                'reason': f'Product expires in {days_until_expiry} days',
                'discount_percentage': discount,
                'recommended_price': float(product.selling_price * Decimal('0.85')),
                'expected_margin': round(current_margin - 0.15, 2),
                'urgency': 'medium',
            })
        
        # Overstock pricing
        if days_of_stock > 60:
            discount = min(25, int((days_of_stock - 60) / 10) * 5)
            recommendations.append({
                'scenario': 'Overstock Reduction',
                'reason': f'High stock levels ({int(days_of_stock)} days supply)',
                'discount_percentage': discount,
                'recommended_price': float(product.selling_price * Decimal(str(1 - discount/100))),
                'expected_margin': round(current_margin - discount/100, 2),
                'urgency': 'low',
            })
        
        # Margin optimization
        if current_margin < target_margin:
            target_price = float(product.cost_price) * (1 + target_margin)
            recommendations.append({
                'scenario': 'Margin Optimization',
                'reason': f'Current margin ({current_margin:.1%}) below target ({target_margin:.1%})',
                'discount_percentage': 0,
                'recommended_price': round(target_price, 2),
                'expected_margin': target_margin,
                'urgency': 'low',
            })
        
        return {
            'product_id': product_id,
            'product_name': product.name,
            'current_price': float(product.selling_price),
            'cost_price': float(product.cost_price),
            'current_margin': round(current_margin, 3),
            'current_quantity': product.quantity,
            'days_until_expiry': days_until_expiry,
            'average_daily_sales': round(avg_daily_sales, 2),
            'days_of_stock': round(days_of_stock, 1),
            'recommendations': recommendations,
        }
    
    def _weekday_name(self, weekday: int) -> str:
        """Convert weekday number to name."""
        names = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday',
                 5: 'Friday', 6: 'Saturday', 7: 'Sunday'}
        return names.get(weekday, f'Day {weekday}')
    
    def _get_expiry_recommendation(self, days_until: int) -> str:
        """Get recommended action based on days until expiry."""
        if days_until <= 1:
            return "Donate or dispose immediately"
        elif days_until <= 3:
            return "Apply maximum clearance discount (50%+)"
        elif days_until <= 7:
            return "Apply significant discount (30-50%)"
        elif days_until <= 14:
            return "Apply moderate discount (15-30%)"
        else:
            return "Monitor and promote"
    
    def _generate_waste_recommendations(self, forecast: List[Dict]) -> List[str]:
        """Generate actionable recommendations to reduce waste."""
        recommendations = []
        
        high_risk = [d for d in forecast if d['risk_score'] >= 0.6]
        medium_risk = [d for d in forecast if 0.3 <= d['risk_score'] < 0.6]
        
        if high_risk:
            total_value = sum(d['at_risk_value'] for d in high_risk)
            recommendations.append(
                f"URGENT: ${total_value:,.2f} worth of products at high risk of waste. "
                "Implement immediate clearance pricing."
            )
        
        if medium_risk:
            total_qty = sum(d['at_risk_quantity'] for d in medium_risk)
            recommendations.append(
                f"Schedule promotional campaigns for {total_qty:,} units expiring in 7-14 days."
            )
        
        recommendations.append(
            "Consider partnering with food banks or discount retailers for near-expiry items."
        )
        recommendations.append(
            "Review ordering patterns to reduce future overstock of perishable items."
        )
        
        return recommendations


class SmartPricingEngine:
    """
    Dynamic pricing engine with multiple pricing strategies.
    """
    
    def __init__(self, store_id: int = None):
        self.store_id = store_id
    
    def calculate_dynamic_price(
        self,
        product_id: int,
        strategy: str = 'balanced'
    ) -> Dict[str, Any]:
        """
        Calculate dynamic price based on multiple factors.
        
        Strategies:
        - 'aggressive': Maximize margin
        - 'competitive': Match market
        - 'balanced': Balance between margin and sales
        - 'clearance': Prioritize sales over margin
        """
        from products.models import Product
        
        try:
            product = Product.objects.get(pk=product_id)
        except Product.DoesNotExist:
            return {'error': 'Product not found'}
        
        # Calculate base factors
        factors = self._calculate_pricing_factors(product)
        
        # Strategy weights
        strategy_weights = {
            'aggressive': {'margin': 0.7, 'demand': 0.2, 'competition': 0.1},
            'competitive': {'margin': 0.2, 'demand': 0.3, 'competition': 0.5},
            'balanced': {'margin': 0.4, 'demand': 0.3, 'competition': 0.3},
            'clearance': {'margin': 0.1, 'demand': 0.6, 'competition': 0.3},
        }
        
        weights = strategy_weights.get(strategy, strategy_weights['balanced'])
        
        # Calculate recommended price
        base_price = float(product.selling_price)
        
        # Margin factor
        margin_adjustment = 1.0 + (factors['margin_score'] - 0.5) * 0.2
        
        # Demand factor
        demand_adjustment = 1.0 + (factors['demand_score'] - 0.5) * 0.15
        
        # Expiry factor (always applies)
        expiry_adjustment = factors['expiry_factor']
        
        # Calculate final price
        price_adjustment = (
            margin_adjustment * weights['margin'] +
            demand_adjustment * weights['demand'] +
            1.0 * weights['competition']  # Placeholder for competitor data
        )
        
        recommended_price = base_price * price_adjustment * expiry_adjustment
        
        # Apply floor (cost + minimum margin)
        min_price = float(product.cost_price) * 1.05  # 5% minimum margin
        recommended_price = max(recommended_price, min_price)
        
        return {
            'product_id': product_id,
            'product_name': product.name,
            'current_price': base_price,
            'recommended_price': round(recommended_price, 2),
            'price_change': round(recommended_price - base_price, 2),
            'price_change_percentage': round((recommended_price - base_price) / base_price * 100, 1),
            'strategy': strategy,
            'factors': factors,
            'confidence_score': round(factors['confidence'], 1),
        }
    
    def _calculate_pricing_factors(self, product) -> Dict[str, float]:
        """Calculate various factors affecting price."""
        from products.models import StockMovement
        from django.utils import timezone
        
        today = timezone.now().date()
        
        # Expiry factor
        if product.expiry_date:
            days_until = (product.expiry_date - today).days
            if days_until <= 0:
                expiry_factor = 0.5  # 50% off expired
            elif days_until <= 3:
                expiry_factor = 0.6
            elif days_until <= 7:
                expiry_factor = 0.75
            elif days_until <= 14:
                expiry_factor = 0.9
            else:
                expiry_factor = 1.0
        else:
            expiry_factor = 1.0
        
        # Stock level factor
        if product.quantity <= product.min_stock_level:
            stock_score = 0.8  # Low stock, could increase price
        elif product.quantity > product.reorder_quantity * 2:
            stock_score = 0.3  # Overstocked, should decrease
        else:
            stock_score = 0.5  # Normal
        
        # Calculate margin score
        margin = float(product.selling_price - product.cost_price) / float(product.cost_price) if product.cost_price > 0 else 0
        margin_score = min(1.0, margin / 0.5)  # Score based on 50% target margin
        
        # Demand score from recent sales
        recent_sales = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=timezone.now() - timedelta(days=14)
        ).aggregate(total=Sum('quantity'))['total'] or 0
        
        # Normalize demand (assuming 100 units/14 days is high)
        demand_score = min(1.0, recent_sales / 100)
        
        # Confidence based on data availability
        data_points = StockMovement.objects.filter(
            product=product,
            created_at__gte=timezone.now() - timedelta(days=90)
        ).count()
        confidence = min(100, data_points * 2)
        
        return {
            'expiry_factor': expiry_factor,
            'stock_score': stock_score,
            'margin_score': margin_score,
            'demand_score': demand_score,
            'confidence': confidence,
        }
    
    def bulk_price_optimization(
        self,
        category_id: int = None,
        strategy: str = 'balanced'
    ) -> Dict[str, Any]:
        """
        Generate pricing recommendations for multiple products.
        """
        from products.models import Product
        
        products = Product.objects.filter(is_active=True)
        if category_id:
            products = products.filter(category_id=category_id)
        if self.store_id:
            products = products.filter(store_id=self.store_id)
        
        # Limit to products that need pricing review
        today = timezone.now().date()
        products = products.filter(
            Q(expiry_date__lte=today + timedelta(days=14)) |  # Near expiry
            Q(quantity__gt=F('reorder_quantity') * 2)  # Overstocked
        )[:50]  # Limit to 50 products
        
        recommendations = []
        total_potential_revenue_change = Decimal('0')
        
        for product in products:
            result = self.calculate_dynamic_price(product.id, strategy)
            if 'error' not in result:
                revenue_change = (Decimal(str(result['recommended_price'])) - product.selling_price) * product.quantity
                total_potential_revenue_change += revenue_change
                
                recommendations.append({
                    **result,
                    'quantity': product.quantity,
                    'potential_revenue_impact': float(revenue_change),
                })
        
        return {
            'total_products': len(recommendations),
            'strategy': strategy,
            'total_potential_revenue_change': float(total_potential_revenue_change),
            'recommendations': recommendations,
        }
