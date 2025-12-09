"""
Machine Learning models for predictive analytics and smart features.
"""
import numpy as np
from django.db import models
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from collections import defaultdict
import logging

logger = logging.getLogger(__name__)

class DemandForecast:
    """Advanced demand forecasting using historical data and patterns."""
    
    @staticmethod
    def predict_reorder_date(product):
        """
        Predict when a product needs to be reordered based on consumption rate.
        Uses multiple algorithms for better accuracy.
        Returns predicted date and recommended order quantity.
        """
        from .models import StockMovement
        
        # Get stock movements for the past 60 days for better accuracy
        sixty_days_ago = timezone.now() - timedelta(days=60)
        movements = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=sixty_days_ago
        ).order_by('-created_at')
        
        if not movements.exists():
            return None, None
        
        # Method 1: Simple moving average
        total_out = sum(m.quantity for m in movements)
        days_count = min(60, (timezone.now() - sixty_days_ago).days)
        avg_daily_consumption = total_out / days_count if days_count > 0 else 0
        
        # Method 2: Weighted moving average (recent data has more weight)
        weighted_consumption = DemandForecast._calculate_weighted_consumption(movements)
        
        # Method 3: Seasonal adjustment (if enough data)
        seasonal_consumption = DemandForecast._calculate_seasonal_consumption(product)
        
        # Combine methods for final prediction
        final_consumption = (avg_daily_consumption * 0.3 + 
                           weighted_consumption * 0.5 + 
                           seasonal_consumption * 0.2)
        
        if final_consumption == 0:
            return None, None
        
        # Calculate days until stock reaches minimum level
        current_stock = product.quantity
        days_to_min_stock = (current_stock - product.min_stock_level) / final_consumption
        
        # Add safety buffer (lead time + safety stock)
        safety_days = 7  # 1 week buffer
        days_to_reorder = max(0, days_to_min_stock - safety_days)
        
        reorder_date = timezone.now() + timedelta(days=days_to_reorder)
        
        # Calculate recommended order quantity
        # Consider: Lead time consumption + safety stock + review period
        lead_time_days = 14  # Assume 2 weeks lead time
        review_period = 30   # Monthly review
        
        recommended_quantity = int(final_consumption * (lead_time_days + review_period))
        recommended_quantity = max(recommended_quantity, product.min_stock_level * 2)
        
        return reorder_date, recommended_quantity
    
    @staticmethod
    def _calculate_weighted_consumption(movements):
        """Calculate consumption with more weight on recent data."""
        if not movements:
            return 0
        
        total_weighted = 0
        total_weight = 0
        
        for i, movement in enumerate(movements):
            # Weight decreases as data gets older
            weight = 1 / (i + 1)
            total_weighted += movement.quantity * weight
            total_weight += weight
        
        return total_weighted / total_weight if total_weight > 0 else 0
    
    @staticmethod
    def _calculate_seasonal_consumption(product):
        """Calculate seasonal consumption patterns."""
        from .models import StockMovement
        
        # Get 6 months of data for seasonal analysis
        six_months_ago = timezone.now() - timedelta(days=180)
        movements = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=six_months_ago
        )
        
        if movements.count() < 30:  # Not enough data
            return 0
        
        # Group by week and calculate weekly consumption
        weekly_consumption = defaultdict(int)
        for movement in movements:
            week = movement.created_at.isocalendar()[1]
            weekly_consumption[week] += movement.quantity
        
        if not weekly_consumption:
            return 0
        
        # Calculate average weekly consumption
        avg_weekly = sum(weekly_consumption.values()) / len(weekly_consumption)
        return avg_weekly / 7  # Convert to daily
    
    @staticmethod
    def get_trending_products(user, days=7, limit=10):
        """Get products with increasing consumption rate using trend analysis."""
        from .models import Product
        
        cutoff_date = timezone.now() - timedelta(days=days)
        products = Product.objects.filter(
            created_by=user,
            is_deleted=False
        ).prefetch_related('stock_movements')
        
        trending = []
        
        for product in products:
            movements = product.stock_movements.filter(
                movement_type='out',
                created_at__gte=cutoff_date
            ).order_by('created_at')
            
            if movements.count() >= 3:
                # Calculate trend using linear regression
                trend_score = DemandForecast._calculate_trend_score(movements)
                if trend_score > 0:  # Only positive trends
                    trending.append((product, trend_score))
        
        # Sort by trend score and return top products
        trending.sort(key=lambda x: x[1], reverse=True)
        return [item[0] for item in trending[:limit]]
    
    @staticmethod
    def _calculate_trend_score(movements):
        """Calculate trend score using simple linear regression."""
        if len(movements) < 3:
            return 0
        
        # Convert to arrays for calculation
        x = np.array(range(len(movements)))
        y = np.array([m.quantity for m in movements])
        
        # Simple linear regression: y = mx + b
        n = len(x)
        sum_x = np.sum(x)
        sum_y = np.sum(y)
        sum_xy = np.sum(x * y)
        sum_x2 = np.sum(x * x)
        
        # Calculate slope (trend)
        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
        
        # Return trend score (positive for increasing, negative for decreasing)
        return slope * np.mean(y)  # Weight by average consumption
    
    @staticmethod
    def calculate_stock_health_score(product):
        """
        Calculate a comprehensive health score for a product (0-100).
        Uses multiple factors with weighted importance.
        """
        score = 100
        
        # Factor 1: Stock level (25% weight)
        stock_score = DemandForecast._calculate_stock_score(product)
        score = score * 0.75 + stock_score * 0.25
        
        # Factor 2: Expiry status (35% weight)
        expiry_score = DemandForecast._calculate_expiry_score(product)
        score = score * 0.65 + expiry_score * 0.35
        
        # Factor 3: Sales velocity (25% weight)
        velocity_score = DemandForecast._calculate_velocity_score(product)
        score = score * 0.75 + velocity_score * 0.25
        
        # Factor 4: Profit margin (15% weight)
        margin_score = DemandForecast._calculate_margin_score(product)
        score = score * 0.85 + margin_score * 0.15
        
        return max(0, min(100, round(score, 1)))
    
    @staticmethod
    def _calculate_stock_score(product):
        """Calculate stock level score."""
        if product.quantity <= 0:
            return 0
        elif product.quantity <= product.min_stock_level * 0.5:
            return 20
        elif product.quantity <= product.min_stock_level:
            return 50
        elif product.quantity <= product.min_stock_level * 2:
            return 80
        else:
            return 100
    
    @staticmethod
    def _calculate_expiry_score(product):
        """Calculate expiry status score."""
        days_until_expiry = (product.expiry_date - timezone.now().date()).days
        
        if days_until_expiry < 0:
            return 0  # Expired
        elif days_until_expiry <= 3:
            return 10  # Critical
        elif days_until_expiry <= 7:
            return 30  # Very soon
        elif days_until_expiry <= 15:
            return 60  # Soon
        elif days_until_expiry <= 30:
            return 80  # Moderate
        else:
            return 100  # Fresh
    
    @staticmethod
    def _calculate_velocity_score(product):
        """Calculate sales velocity score."""
        from .models import StockMovement
        
        # Get movements from last 30 days
        thirty_days_ago = timezone.now() - timedelta(days=30)
        movements = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=thirty_days_ago
        )
        
        movement_count = movements.count()
        
        # Score based on frequency and quantity
        if movement_count == 0:
            return 10  # No sales
        elif movement_count <= 2:
            return 30  # Very slow
        elif movement_count <= 5:
            return 60  # Slow
        elif movement_count <= 10:
            return 80  # Good
        else:
            return 100  # Excellent
    
    @staticmethod
    def _calculate_margin_score(product):
        """Calculate profit margin score."""
        if product.cost_price <= 0:
            return 50  # No cost data
        
        margin_percent = ((product.selling_price - product.cost_price) / product.cost_price) * 100
        
        if margin_percent <= 0:
            return 0  # Loss
        elif margin_percent <= 10:
            return 30  # Low margin
        elif margin_percent <= 25:
            return 60  # Moderate margin
        elif margin_percent <= 50:
            return 80  # Good margin
        else:
            return 100  # Excellent margin


class AdvancedAnalytics:
    """Advanced analytics and business intelligence."""
    
    @staticmethod
    def calculate_abc_analysis(user):
        """
        Perform ABC analysis on products based on revenue contribution.
        A: Top 20% products contributing 80% revenue
        B: Next 30% products contributing 15% revenue  
        C: Remaining 50% products contributing 5% revenue
        """
        from .models import Product, StockMovement
        
        # Get sales data for last 90 days
        ninety_days_ago = timezone.now() - timedelta(days=90)
        
        product_revenue = {}
        products = Product.objects.filter(created_by=user, is_deleted=False)
        
        for product in products:
            movements = StockMovement.objects.filter(
                product=product,
                movement_type='out',
                created_at__gte=ninety_days_ago
            )
            
            revenue = sum(m.quantity * product.selling_price for m in movements)
            product_revenue[product] = revenue
        
        # Sort by revenue
        sorted_products = sorted(product_revenue.items(), key=lambda x: x[1], reverse=True)
        total_revenue = sum(product_revenue.values())
        
        if total_revenue == 0:
            return {'A': [], 'B': [], 'C': list(products)}
        
        # Calculate cumulative percentages
        cumulative_revenue = 0
        abc_classification = {'A': [], 'B': [], 'C': []}
        
        for product, revenue in sorted_products:
            cumulative_revenue += revenue
            cumulative_percent = (cumulative_revenue / total_revenue) * 100
            
            if cumulative_percent <= 80:
                abc_classification['A'].append({
                    'product': product,
                    'revenue': revenue,
                    'revenue_percent': (revenue / total_revenue) * 100
                })
            elif cumulative_percent <= 95:
                abc_classification['B'].append({
                    'product': product,
                    'revenue': revenue,
                    'revenue_percent': (revenue / total_revenue) * 100
                })
            else:
                abc_classification['C'].append({
                    'product': product,
                    'revenue': revenue,
                    'revenue_percent': (revenue / total_revenue) * 100
                })
        
        return abc_classification
    
    @staticmethod
    def calculate_inventory_turnover(product, days=365):
        """Calculate inventory turnover ratio for a product."""
        from .models import StockMovement
        
        # Get cost of goods sold (COGS)
        cutoff_date = timezone.now() - timedelta(days=days)
        sold_movements = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=cutoff_date
        )
        
        cogs = sum(m.quantity * product.cost_price for m in sold_movements)
        
        # Average inventory value
        avg_inventory_value = product.quantity * product.cost_price
        
        if avg_inventory_value == 0:
            return 0
        
        # Turnover ratio = COGS / Average Inventory Value
        turnover_ratio = cogs / avg_inventory_value
        
        return round(turnover_ratio, 2)
    
    @staticmethod
    def identify_dead_stock(user, days=90):
        """Identify products with no sales movement in specified days."""
        from .models import Product, StockMovement
        
        cutoff_date = timezone.now() - timedelta(days=days)
        
        products_with_sales = StockMovement.objects.filter(
            movement_type='out',
            created_at__gte=cutoff_date,
            product__created_by=user
        ).values_list('product_id', flat=True).distinct()
        
        dead_stock = Product.objects.filter(
            created_by=user,
            is_deleted=False,
            quantity__gt=0
        ).exclude(id__in=products_with_sales)
        
        return dead_stock
    
    @staticmethod
    def calculate_safety_stock(product, service_level=0.95):
        """
        Calculate safety stock using statistical method.
        Safety Stock = Z * σ * sqrt(L)
        Where: Z = service level factor, σ = demand std dev, L = lead time
        """
        from .models import StockMovement
        
        # Get historical demand data
        sixty_days_ago = timezone.now() - timedelta(days=60)
        movements = StockMovement.objects.filter(
            product=product,
            movement_type='out',
            created_at__gte=sixty_days_ago
        ).order_by('created_at')
        
        if movements.count() < 10:  # Not enough data
            return product.min_stock_level
        
        # Calculate daily demand
        daily_demands = []
        current_date = sixty_days_ago.date()
        end_date = timezone.now().date()
        
        while current_date <= end_date:
            daily_demand = movements.filter(
                created_at__date=current_date
            ).aggregate(total=models.Sum('quantity'))['total'] or 0
            
            daily_demands.append(daily_demand)
            current_date += timedelta(days=1)
        
        if not daily_demands:
            return product.min_stock_level
        
        # Calculate standard deviation of demand
        demand_array = np.array(daily_demands)
        demand_std = np.std(demand_array)
        
        # Z-score for service level (95% = 1.65, 99% = 2.33)
        z_score = 1.65 if service_level == 0.95 else 2.33
        
        # Assume lead time of 7 days
        lead_time_days = 7
        
        # Calculate safety stock
        safety_stock = z_score * demand_std * np.sqrt(lead_time_days)
        
        return max(int(safety_stock), product.min_stock_level)


class ProfitAnalyzer:
    """Enhanced profit analysis with advanced metrics."""
    
    @staticmethod
    def calculate_potential_profit(product):
        """Calculate potential profit from current stock."""
        margin = product.selling_price - product.cost_price
        return margin * product.quantity
    
    @staticmethod
    def get_comprehensive_profit_report(user, days=30):
        """Generate comprehensive profit report with advanced metrics."""
        from .models import StockMovement
        
        cutoff_date = timezone.now() - timedelta(days=days)
        
        # Get all sold products
        sales_movements = StockMovement.objects.filter(
            product__created_by=user,
            movement_type='out',
            created_at__gte=cutoff_date
        ).select_related('product')
        
        total_revenue = Decimal('0')
        total_cost = Decimal('0')
        product_analytics = {}
        
        for movement in sales_movements:
            product = movement.product
            quantity = movement.quantity
            
            revenue = product.selling_price * quantity
            cost = product.cost_price * quantity
            
            total_revenue += revenue
            total_cost += cost
            
            if product.id not in product_analytics:
                product_analytics[product.id] = {
                    'product': product,
                    'quantity_sold': 0,
                    'revenue': Decimal('0'),
                    'cost': Decimal('0'),
                    'profit': Decimal('0'),
                    'margin_percent': 0,
                    'turnover_ratio': 0,
                    'contribution_percent': 0
                }
            
            analytics = product_analytics[product.id]
            analytics['quantity_sold'] += quantity
            analytics['revenue'] += revenue
            analytics['cost'] += cost
            analytics['profit'] += (revenue - cost)
        
        # Calculate additional metrics
        for analytics in product_analytics.values():
            product = analytics['product']
            
            # Margin percentage
            if analytics['cost'] > 0:
                analytics['margin_percent'] = float(
                    (analytics['profit'] / analytics['cost']) * 100
                )
            
            # Revenue contribution
            if total_revenue > 0:
                analytics['contribution_percent'] = float(
                    (analytics['revenue'] / total_revenue) * 100
                )
            
            # Inventory turnover
            analytics['turnover_ratio'] = AdvancedAnalytics.calculate_inventory_turnover(
                product, days
            )
        
        total_profit = total_revenue - total_cost
        overall_margin = float((total_profit / total_revenue * 100)) if total_revenue > 0 else 0
        
        # Sort by different metrics
        by_profit = sorted(
            product_analytics.values(),
            key=lambda x: x['profit'],
            reverse=True
        )[:10]
        
        by_margin = sorted(
            product_analytics.values(),
            key=lambda x: x['margin_percent'],
            reverse=True
        )[:10]
        
        by_turnover = sorted(
            product_analytics.values(),
            key=lambda x: x['turnover_ratio'],
            reverse=True
        )[:10]
        
        return {
            'summary': {
                'total_revenue': total_revenue,
                'total_cost': total_cost,
                'total_profit': total_profit,
                'overall_margin': overall_margin,
                'products_analyzed': len(product_analytics),
                'period_days': days
            },
            'top_by_profit': by_profit,
            'top_by_margin': by_margin,
            'top_by_turnover': by_turnover,
            'abc_analysis': AdvancedAnalytics.calculate_abc_analysis(user)
        }
    
    @staticmethod
    def get_underperforming_products(user, threshold_margin=10, threshold_turnover=2):
        """Identify products that need attention."""
        from .models import Product
        
        products = Product.objects.filter(
            created_by=user,
            is_deleted=False
        )
        
        underperforming = []
        
        for product in products:
            # Check margin
            margin_percent = float(((product.selling_price - product.cost_price) / product.cost_price * 100)) if product.cost_price > 0 else 0
            
            # Check turnover
            turnover = AdvancedAnalytics.calculate_inventory_turnover(product)
            
            # Check if underperforming
            issues = []
            if margin_percent < threshold_margin:
                issues.append('Low Margin')
            if turnover < threshold_turnover:
                issues.append('Low Turnover')
            
            if issues:
                underperforming.append({
                    'product': product,
                    'margin_percent': margin_percent,
                    'turnover_ratio': turnover,
                    'issues': issues,
                    'health_score': DemandForecast.calculate_stock_health_score(product)
                })
        
        return sorted(underperforming, key=lambda x: x['health_score'])


class SmartAlerts:
    """Enhanced intelligent alerts with priority and recommendations."""
    
    @staticmethod
    def get_all_smart_alerts(user):
        """Get comprehensive intelligent alerts with recommendations."""
        from .models import Product
        
        alerts = {
            'critical': [],
            'high': [],
            'medium': [],
            'low': [],
            'recommendations': []
        }
        
        products = Product.objects.filter(created_by=user, is_deleted=False)
        
        for product in products:
            health_score = DemandForecast.calculate_stock_health_score(product)
            
            # Critical alerts (immediate action required)
            if product.quantity <= 0:
                alerts['critical'].append({
                    'type': 'out_of_stock',
                    'product': product,
                    'health_score': health_score,
                    'message': f'{product.name} is out of stock',
                    'recommendation': 'Order immediately or remove from listings',
                    'urgency': 'immediate'
                })
            
            if product.get_expiry_status() == 'expired':
                alerts['critical'].append({
                    'type': 'expired',
                    'product': product,
                    'health_score': health_score,
                    'message': f'{product.name} has expired',
                    'recommendation': 'Remove from shelves and dispose safely',
                    'urgency': 'immediate'
                })
            
            # High priority alerts
            if product.quantity <= product.min_stock_level and product.quantity > 0:
                reorder_date, reorder_qty = DemandForecast.predict_reorder_date(product)
                alerts['high'].append({
                    'type': 'low_stock',
                    'product': product,
                    'health_score': health_score,
                    'message': f'{product.name} is low on stock ({product.quantity} remaining)',
                    'recommendation': f'Reorder {reorder_qty} units',
                    'urgency': 'within_24h'
                })
            
            if product.get_expiry_status() == 'expiring_soon':
                alerts['high'].append({
                    'type': 'expiring_soon',
                    'product': product,
                    'health_score': health_score,
                    'message': f'{product.name} expires in {product.days_until_expiry} days',
                    'recommendation': 'Apply discount or move to clearance',
                    'urgency': 'within_48h'
                })
            
            # Medium priority alerts
            if health_score < 50:
                alerts['medium'].append({
                    'type': 'poor_health',
                    'product': product,
                    'health_score': health_score,
                    'message': f'{product.name} has poor health score ({health_score})',
                    'recommendation': 'Review pricing, positioning, or discontinue',
                    'urgency': 'this_week'
                })
            
            # Recommendations for optimization
            turnover = AdvancedAnalytics.calculate_inventory_turnover(product)
            if turnover < 1:
                alerts['recommendations'].append({
                    'type': 'slow_moving',
                    'product': product,
                    'health_score': health_score,
                    'message': f'{product.name} has low turnover ({turnover})',
                    'recommendation': 'Consider promotional pricing or bundle deals',
                    'potential_impact': 'medium'
                })
        
        # Add intelligent insights
        alerts['insights'] = SmartAlerts._generate_business_insights(user, products)
        
        return alerts
    
    @staticmethod
    def _generate_business_insights(user, products):
        """Generate business insights and trends."""
        insights = []
        
        # Dead stock analysis
        dead_stock = AdvancedAnalytics.identify_dead_stock(user, 60)
        if dead_stock.count() > 0:
            insights.append({
                'type': 'dead_stock',
                'title': f'{dead_stock.count()} products have no sales in 60 days',
                'description': 'Consider clearance sales or discontinuation',
                'impact': 'high',
                'action': 'Review inventory strategy'
            })
        
        # Profit margin analysis
        low_margin = ProfitAnalyzer.get_underperforming_products(user, threshold_margin=15)
        if len(low_margin) > len(products) * 0.3:  # More than 30% underperforming
            insights.append({
                'type': 'margin_concern',
                'title': f'{len(low_margin)} products have low profit margins',
                'description': 'High percentage of products underperforming',
                'impact': 'high',
                'action': 'Review pricing strategy or supplier costs'
            })
        
        # Trending analysis
        trending = DemandForecast.get_trending_products(user, days=14, limit=5)
        if trending:
            insights.append({
                'type': 'trending_opportunity',
                'title': f'{len(trending)} products showing positive trends',
                'description': 'Consider increasing stock for trending items',
                'impact': 'positive',
                'action': 'Optimize inventory levels for trending products'
            })
        
        return insights
