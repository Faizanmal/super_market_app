"""
Advanced ML-powered API views for demand forecasting and inventory optimization.
"""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
import pandas as pd
import numpy as np
import logging
import os

from .models import Product, StockMovement
from .advanced_ml_models import DemandForecastingEngine, InventoryOptimizer

logger = logging.getLogger(__name__)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def advanced_demand_forecast(request, product_id=None):
    """
    Advanced demand forecasting using ML models.
    """
    try:
        days_ahead = int(request.GET.get('days', 30))
        
        if product_id:
            # Forecast for specific product
            product = get_object_or_404(Product, id=product_id, created_by=request.user)
            
            # Get historical data
            historical_data = get_product_historical_data(product)
            
            if len(historical_data) < 10:
                return Response({
                    'error': 'Insufficient historical data for forecasting',
                    'required_days': 30,
                    'available_days': len(historical_data)
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create and train forecasting engine
            engine = DemandForecastingEngine()
            performance = engine.train_models(historical_data)
            
            # Generate predictions
            predictions = engine.predict_demand(historical_data, days_ahead)
            insights = engine.get_demand_insights(historical_data)
            reorder_info = engine.calculate_reorder_point(historical_data)
            
            return Response({
                'product_id': product_id,
                'product_name': product.name,
                'forecast_period_days': days_ahead,
                'predictions': predictions,
                'model_performance': performance,
                'demand_insights': insights,
                'reorder_recommendations': reorder_info,
                'generated_at': timezone.now().isoformat()
            })
        
        else:
            # Forecast for all products
            products = Product.objects.filter(created_by=request.user, is_deleted=False)
            results = {}
            
            for product in products:
                try:
                    historical_data = get_product_historical_data(product)
                    
                    if len(historical_data) >= 10:
                        engine = DemandForecastingEngine()
                        engine.train_models(historical_data)
                        
                        predictions = engine.predict_demand(historical_data, min(days_ahead, 7))
                        insights = engine.get_demand_insights(historical_data)
                        
                        results[product.id] = {
                            'name': product.name,
                            'predictions': predictions,
                            'insights': insights,
                            'urgency_score': calculate_urgency_score(insights)
                        }
                except Exception as e:
                    logger.error(f"Error forecasting for product {product.id}: {e}")
                    continue
            
            return Response({
                'forecast_summary': results,
                'total_products': len(results),
                'generated_at': timezone.now().isoformat()
            })
            
    except Exception as e:
        logger.error(f"Error in advanced_demand_forecast: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def inventory_optimization_report(request):
    """
    Generate comprehensive inventory optimization report.
    """
    try:
        # Get all active products
        products = Product.objects.filter(created_by=request.user, is_deleted=False)
        
        optimizer = InventoryOptimizer()
        products_data = {}
        
        # Collect historical data for all products
        for product in products:
            historical_data = get_product_historical_data(product)
            if len(historical_data) >= 10:
                products_data[product.id] = historical_data
        
        # Run optimization
        optimization_results = optimizer.optimize_inventory_levels(products_data)
        
        # Aggregate insights
        total_products = len(optimization_results)
        high_risk_products = sum(1 for r in optimization_results.values() 
                               if r.get('insights', {}).get('stockout_risk') == 'high')
        
        avg_optimization_score = np.mean([r.get('optimization_score', 0) 
                                        for r in optimization_results.values()]) if optimization_results else 0
        
        # Top recommendations
        recommendations = generate_optimization_recommendations(optimization_results, products)
        
        return Response({
            'summary': {
                'total_products_analyzed': total_products,
                'high_risk_products': high_risk_products,
                'average_optimization_score': round(avg_optimization_score, 2),
                'analysis_date': timezone.now().isoformat()
            },
            'product_optimizations': optimization_results,
            'recommendations': recommendations,
            'risk_distribution': {
                'high': sum(1 for r in optimization_results.values() 
                          if r.get('insights', {}).get('stockout_risk') == 'high'),
                'medium': sum(1 for r in optimization_results.values() 
                            if r.get('insights', {}).get('stockout_risk') == 'medium'),
                'low': sum(1 for r in optimization_results.values() 
                         if r.get('insights', {}).get('stockout_risk') == 'low')
            }
        })
        
    except Exception as e:
        logger.error(f"Error in inventory_optimization_report: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def smart_reorder_alerts(request):
    """
    Get smart reorder alerts based on ML predictions.
    """
    try:
        products = Product.objects.filter(created_by=request.user, is_deleted=False)
        alerts = []
        
        for product in products:
            try:
                historical_data = get_product_historical_data(product)
                
                if len(historical_data) >= 10:
                    engine = DemandForecastingEngine()
                    engine.train_models(historical_data)
                    
                    insights = engine.get_demand_insights(historical_data)
                    reorder_info = engine.calculate_reorder_point(historical_data)
                    
                    current_stock = product.quantity
                    reorder_point = reorder_info.get('reorder_point', 0)
                    
                    if current_stock <= reorder_point:
                        alert_level = 'critical' if current_stock <= reorder_point * 0.5 else 'warning'
                        
                        alerts.append({
                            'product_id': product.id,
                            'product_name': product.name,
                            'alert_level': alert_level,
                            'current_stock': current_stock,
                            'reorder_point': round(reorder_point, 2),
                            'recommended_order_quantity': round(reorder_info.get('safety_stock', 0) * 2, 2),
                            'days_of_stock_remaining': insights.get('days_of_stock', 0),
                            'urgency_score': calculate_urgency_score(insights),
                            'reason': f"Current stock ({current_stock}) is below reorder point ({round(reorder_point, 2)})"
                        })
                        
            except Exception as e:
                logger.error(f"Error checking reorder for product {product.id}: {e}")
                continue
        
        # Sort by urgency score
        alerts.sort(key=lambda x: x['urgency_score'], reverse=True)
        
        return Response({
            'alerts': alerts,
            'total_alerts': len(alerts),
            'critical_alerts': sum(1 for a in alerts if a['alert_level'] == 'critical'),
            'warning_alerts': sum(1 for a in alerts if a['alert_level'] == 'warning'),
            'generated_at': timezone.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in smart_reorder_alerts: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def retrain_ml_models(request):
    """
    Manually retrain ML models for all products.
    """
    try:
        products = Product.objects.filter(created_by=request.user, is_deleted=False)
        results = {}
        
        for product in products:
            try:
                historical_data = get_product_historical_data(product)
                
                if len(historical_data) >= 30:
                    engine = DemandForecastingEngine()
                    performance = engine.train_models(historical_data)
                    
                    # Save model (in production, you'd save to a model store)
                    model_path = f"/tmp/models/product_{product.id}_model.pkl"
                    os.makedirs(os.path.dirname(model_path), exist_ok=True)
                    engine.save_models(model_path)
                    
                    results[product.id] = {
                        'status': 'success',
                        'performance': performance,
                        'data_points': len(historical_data)
                    }
                else:
                    results[product.id] = {
                        'status': 'insufficient_data',
                        'data_points': len(historical_data)
                    }
                    
            except Exception as e:
                logger.error(f"Error retraining model for product {product.id}: {e}")
                results[product.id] = {
                    'status': 'error',
                    'message': str(e)
                }
        
        successful_models = sum(1 for r in results.values() if r['status'] == 'success')
        
        return Response({
            'retraining_results': results,
            'successful_models': successful_models,
            'total_products': len(results),
            'retrained_at': timezone.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in retrain_ml_models: {e}")
        return Response({
            'error': 'Internal server error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def get_product_historical_data(product) -> pd.DataFrame:
    """
    Get historical sales and stock data for a product.
    """
    try:
        # Get stock movements for the last 90 days
        end_date = timezone.now()
        start_date = end_date - timedelta(days=90)
        
        movements = StockMovement.objects.filter(
            product=product,
            created_at__range=[start_date, end_date]
        ).order_by('created_at')
        
        if not movements.exists():
            return pd.DataFrame()
        
        # Create DataFrame
        data = []
        for movement in movements:
            data.append({
                'date': movement.created_at.date(),
                'quantity_sold': abs(movement.quantity) if movement.movement_type == 'sale' else 0,
                'stock_quantity': movement.quantity_after,
                'price': float(product.price),
                'category': product.category.name if product.category else 'Uncategorized',
                'supplier': product.supplier.name if product.supplier else 'Unknown'
            })
        
        df = pd.DataFrame(data)
        
        if not df.empty:
            df['date'] = pd.to_datetime(df['date'])
            df = df.groupby('date').agg({
                'quantity_sold': 'sum',
                'stock_quantity': 'last',
                'price': 'last',
                'category': 'last',
                'supplier': 'last'
            }).reset_index()
            
            # Fill missing dates
            date_range = pd.date_range(start=df['date'].min(), end=df['date'].max(), freq='D')
            df = df.set_index('date').reindex(date_range).reset_index()
            df.rename(columns={'index': 'date'}, inplace=True)
            
            # Forward fill missing values
            df = df.fillna(method='forward').fillna(0)
        
        return df
        
    except Exception as e:
        logger.error(f"Error getting historical data for product {product.id}: {e}")
        return pd.DataFrame()


def calculate_urgency_score(insights: dict) -> float:
    """
    Calculate urgency score (0-100) for reorder recommendations.
    """
    try:
        score = 0
        
        # Days of stock remaining
        days_of_stock = insights.get('days_of_stock', 30)
        if days_of_stock < 3:
            score += 50
        elif days_of_stock < 7:
            score += 30
        elif days_of_stock < 14:
            score += 15
        
        # Demand trend
        trend = insights.get('demand_trend', 'stable')
        if trend == 'increasing':
            score += 25
        elif trend == 'stable':
            score += 10
        
        # Demand volatility
        volatility = insights.get('demand_volatility', 0)
        score += min(25, volatility * 50)
        
        return min(100, max(0, score))
        
    except Exception as e:
        logger.error(f"Error calculating urgency score: {e}")
        return 50


def generate_optimization_recommendations(optimization_results: dict, products) -> list:
    """
    Generate actionable optimization recommendations.
    """
    try:
        recommendations = []
        
        for product_id, results in optimization_results.items():
            try:
                product = next((p for p in products if p.id == product_id), None)
                if not product:
                    continue
                
                insights = results.get('insights', {})
                
                # High stockout risk
                if insights.get('stockout_risk') == 'high':
                    recommendations.append({
                        'type': 'urgent_reorder',
                        'product_id': product_id,
                        'product_name': product.name,
                        'priority': 'high',
                        'message': f"Urgent: {product.name} has high stockout risk. Current stock: {product.quantity}",
                        'action': f"Reorder {results.get('economic_order_quantity', 100):.0f} units immediately"
                    })
                
                # Optimize stock levels
                optimization_score = results.get('optimization_score', 0)
                if optimization_score < 60:
                    recommendations.append({
                        'type': 'optimization',
                        'product_id': product_id,
                        'product_name': product.name,
                        'priority': 'medium',
                        'message': f"Inventory optimization needed for {product.name} (Score: {optimization_score:.1f}/100)",
                        'action': f"Set reorder point to {results.get('reorder_point', 0):.0f} units"
                    })
                
                # Trend-based recommendations
                trend = insights.get('demand_trend')
                if trend == 'increasing':
                    recommendations.append({
                        'type': 'trend_alert',
                        'product_id': product_id,
                        'product_name': product.name,
                        'priority': 'medium',
                        'message': f"Increasing demand trend detected for {product.name}",
                        'action': "Consider increasing safety stock levels"
                    })
                    
            except Exception as e:
                logger.error(f"Error generating recommendation for product {product_id}: {e}")
                continue
        
        # Sort by priority
        priority_order = {'high': 0, 'medium': 1, 'low': 2}
        recommendations.sort(key=lambda x: priority_order.get(x['priority'], 2))
        
        return recommendations[:20]  # Return top 20 recommendations
        
    except Exception as e:
        logger.error(f"Error generating optimization recommendations: {e}")
        return []