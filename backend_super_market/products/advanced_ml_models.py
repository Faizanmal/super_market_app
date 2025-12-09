"""
Advanced Machine Learning models for demand forecasting and inventory optimization.
"""
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error
import joblib
import os
from typing import Dict, List
import logging

logger = logging.getLogger(__name__)


class DemandForecastingEngine:
    """
    Advanced ML engine for predicting product demand.
    """
    
    def __init__(self):
        self.models = {
            'random_forest': RandomForestRegressor(n_estimators=100, random_state=42),
            'gradient_boost': GradientBoostingRegressor(n_estimators=100, random_state=42),
            'linear_regression': LinearRegression()
        }
        self.scaler = StandardScaler()
        self.feature_importance = {}
        self.model_performance = {}
        
    def prepare_features(self, product_data: pd.DataFrame) -> pd.DataFrame:
        """
        Prepare features for ML model training.
        """
        features = pd.DataFrame()
        
        # Time-based features
        features['day_of_week'] = product_data['date'].dt.dayofweek
        features['day_of_month'] = product_data['date'].dt.day
        features['month'] = product_data['date'].dt.month
        features['quarter'] = product_data['date'].dt.quarter
        features['is_weekend'] = features['day_of_week'].isin([5, 6]).astype(int)
        
        # Historical demand features
        features['demand_lag_1'] = product_data['quantity_sold'].shift(1)
        features['demand_lag_7'] = product_data['quantity_sold'].shift(7)
        features['demand_lag_30'] = product_data['quantity_sold'].shift(30)
        
        # Rolling averages
        features['demand_ma_7'] = product_data['quantity_sold'].rolling(window=7).mean()
        features['demand_ma_30'] = product_data['quantity_sold'].rolling(window=30).mean()
        features['demand_ma_90'] = product_data['quantity_sold'].rolling(window=90).mean()
        
        # Price features
        features['price'] = product_data['price']
        features['price_change'] = product_data['price'].pct_change()
        features['price_vs_ma'] = product_data['price'] / product_data['price'].rolling(window=30).mean()
        
        # Stock features
        features['stock_level'] = product_data['stock_quantity']
        features['stock_turnover'] = product_data['quantity_sold'] / product_data['stock_quantity']
        
        # Seasonality features
        features['days_since_launch'] = (product_data['date'] - product_data['date'].min()).dt.days
        
        # Category and supplier features (encoded)
        features['category_encoded'] = pd.Categorical(product_data['category']).codes
        features['supplier_encoded'] = pd.Categorical(product_data['supplier']).codes
        
        # Fill missing values
        features = features.fillna(method='forward').fillna(0)
        
        return features
    
    def train_models(self, product_data: pd.DataFrame) -> Dict[str, float]:
        """
        Train multiple ML models and return performance metrics.
        """
        try:
            # Prepare features
            features = self.prepare_features(product_data)
            target = product_data['quantity_sold']
            
            # Remove rows with insufficient history
            valid_indices = features.dropna().index
            features = features.loc[valid_indices]
            target = target.loc[valid_indices]
            
            if len(features) < 30:
                logger.warning(f"Insufficient data for training: {len(features)} samples")
                return {}
            
            # Split data
            X_train, X_test, y_train, y_test = train_test_split(
                features, target, test_size=0.2, random_state=42, shuffle=False
            )
            
            # Scale features
            X_train_scaled = self.scaler.fit_transform(X_train)
            X_test_scaled = self.scaler.transform(X_test)
            
            # Train models
            performance = {}
            for name, model in self.models.items():
                try:
                    model.fit(X_train_scaled, y_train)
                    predictions = model.predict(X_test_scaled)
                    
                    mae = mean_absolute_error(y_test, predictions)
                    rmse = np.sqrt(mean_squared_error(y_test, predictions))
                    
                    performance[name] = {
                        'mae': mae,
                        'rmse': rmse,
                        'accuracy': max(0, 1 - (mae / (y_test.mean() + 1e-8)))
                    }
                    
                    # Store feature importance for tree-based models
                    if hasattr(model, 'feature_importances_'):
                        self.feature_importance[name] = dict(zip(
                            features.columns,
                            model.feature_importances_
                        ))
                        
                except Exception as e:
                    logger.error(f"Error training model {name}: {e}")
                    
            self.model_performance = performance
            return performance
            
        except Exception as e:
            logger.error(f"Error in train_models: {e}")
            return {}
    
    def predict_demand(self, product_data: pd.DataFrame, days_ahead: int = 7) -> Dict[str, List[float]]:
        """
        Predict future demand for the next N days.
        """
        try:
            features = self.prepare_features(product_data)
            
            if features.empty:
                return {}
            
            # Use the latest complete data point
            latest_features = features.dropna().tail(1)
            
            if latest_features.empty:
                return {}
            
            predictions = {}
            
            # Get the best performing model
            best_model_name = min(self.model_performance.keys(), 
                                key=lambda x: self.model_performance[x]['mae']) if self.model_performance else 'random_forest'
            
            best_model = self.models[best_model_name]
            
            # Predict for each day ahead
            future_predictions = []
            current_features = latest_features.copy()
            
            for day in range(days_ahead):
                try:
                    # Scale features
                    features_scaled = self.scaler.transform(current_features)
                    
                    # Make prediction
                    pred = best_model.predict(features_scaled)[0]
                    future_predictions.append(max(0, pred))  # Ensure non-negative
                    
                    # Update features for next prediction (simple approach)
                    current_features.iloc[0, current_features.columns.get_loc('demand_lag_1')] = pred
                    
                except Exception as e:
                    logger.error(f"Error predicting day {day + 1}: {e}")
                    future_predictions.append(0)
            
            predictions[best_model_name] = future_predictions
            
            # Also get ensemble prediction
            if len(self.models) > 1:
                ensemble_predictions = []
                for day in range(days_ahead):
                    day_predictions = []
                    for model_name, model in self.models.items():
                        try:
                            features_scaled = self.scaler.transform(current_features)
                            pred = model.predict(features_scaled)[0]
                            day_predictions.append(max(0, pred))
                        except Exception:
                            continue
                    
                    if day_predictions:
                        ensemble_pred = np.mean(day_predictions)
                        ensemble_predictions.append(ensemble_pred)
                    else:
                        ensemble_predictions.append(0)
                
                predictions['ensemble'] = ensemble_predictions
            
            return predictions
            
        except Exception as e:
            logger.error(f"Error in predict_demand: {e}")
            return {}
    
    def calculate_reorder_point(self, product_data: pd.DataFrame, 
                              lead_time_days: int = 7, 
                              service_level: float = 0.95) -> Dict[str, float]:
        """
        Calculate optimal reorder point using demand forecast.
        """
        try:
            # Get demand forecast
            demand_forecast = self.predict_demand(product_data, lead_time_days)
            
            if not demand_forecast:
                return {'reorder_point': 0, 'safety_stock': 0}
            
            # Use ensemble prediction if available, otherwise best model
            forecast_key = 'ensemble' if 'ensemble' in demand_forecast else list(demand_forecast.keys())[0]
            forecasted_demand = demand_forecast[forecast_key]
            
            # Calculate average demand during lead time
            avg_demand_during_lead_time = sum(forecasted_demand)
            
            # Calculate demand variability (using historical data)
            historical_demand = product_data['quantity_sold'].tail(30)
            demand_std = historical_demand.std() if len(historical_demand) > 1 else 0
            
            # Calculate safety stock (assuming normal distribution)
            from scipy.stats import norm
            z_score = norm.ppf(service_level)
            safety_stock = z_score * demand_std * np.sqrt(lead_time_days)
            
            # Calculate reorder point
            reorder_point = avg_demand_during_lead_time + safety_stock
            
            return {
                'reorder_point': max(0, reorder_point),
                'safety_stock': max(0, safety_stock),
                'forecasted_demand': avg_demand_during_lead_time,
                'demand_variability': demand_std
            }
            
        except Exception as e:
            logger.error(f"Error calculating reorder point: {e}")
            return {'reorder_point': 0, 'safety_stock': 0}
    
    def get_demand_insights(self, product_data: pd.DataFrame) -> Dict[str, any]:
        """
        Generate insights about demand patterns.
        """
        try:
            insights = {}
            
            # Basic statistics
            recent_demand = product_data['quantity_sold'].tail(30)
            insights['avg_daily_demand'] = recent_demand.mean()
            insights['demand_volatility'] = recent_demand.std() / (recent_demand.mean() + 1e-8)
            
            # Trend analysis
            if len(recent_demand) >= 14:
                first_half = recent_demand.head(15).mean()
                second_half = recent_demand.tail(15).mean()
                insights['demand_trend'] = 'increasing' if second_half > first_half * 1.1 else 'decreasing' if second_half < first_half * 0.9 else 'stable'
            else:
                insights['demand_trend'] = 'stable'
            
            # Seasonality detection
            if 'day_of_week' in product_data.columns:
                weekly_pattern = product_data.groupby(product_data['date'].dt.dayofweek)['quantity_sold'].mean()
                insights['best_selling_day'] = weekly_pattern.idxmax()
                insights['worst_selling_day'] = weekly_pattern.idxmin()
            
            # Stock-out risk
            current_stock = product_data['stock_quantity'].iloc[-1] if len(product_data) > 0 else 0
            avg_demand = insights['avg_daily_demand']
            insights['days_of_stock'] = current_stock / (avg_demand + 1e-8)
            insights['stockout_risk'] = 'high' if insights['days_of_stock'] < 3 else 'medium' if insights['days_of_stock'] < 7 else 'low'
            
            return insights
            
        except Exception as e:
            logger.error(f"Error generating demand insights: {e}")
            return {}
    
    def save_models(self, filepath: str):
        """Save trained models to disk."""
        try:
            model_data = {
                'models': self.models,
                'scaler': self.scaler,
                'feature_importance': self.feature_importance,
                'performance': self.model_performance
            }
            joblib.dump(model_data, filepath)
            logger.info(f"Models saved to {filepath}")
        except Exception as e:
            logger.error(f"Error saving models: {e}")
    
    def load_models(self, filepath: str):
        """Load trained models from disk."""
        try:
            if os.path.exists(filepath):
                model_data = joblib.load(filepath)
                self.models = model_data.get('models', self.models)
                self.scaler = model_data.get('scaler', self.scaler)
                self.feature_importance = model_data.get('feature_importance', {})
                self.model_performance = model_data.get('performance', {})
                logger.info(f"Models loaded from {filepath}")
            else:
                logger.warning(f"Model file not found: {filepath}")
        except Exception as e:
            logger.error(f"Error loading models: {e}")


class InventoryOptimizer:
    """
    Advanced inventory optimization using ML insights.
    """
    
    def __init__(self):
        self.demand_engine = DemandForecastingEngine()
    
    def optimize_inventory_levels(self, products_data: Dict[int, pd.DataFrame]) -> Dict[int, Dict]:
        """
        Optimize inventory levels for multiple products.
        """
        optimization_results = {}
        
        for product_id, product_data in products_data.items():
            try:
                # Train demand forecasting model
                self.demand_engine.train_models(product_data)
                
                # Calculate optimal reorder point
                reorder_info = self.demand_engine.calculate_reorder_point(product_data)
                
                # Get demand insights
                insights = self.demand_engine.get_demand_insights(product_data)
                
                # Calculate economic order quantity (simplified)
                avg_demand = insights.get('avg_daily_demand', 1)
                eoq = np.sqrt(2 * avg_demand * 365 * 100 / 10)  # Simplified EOQ formula
                
                optimization_results[product_id] = {
                    'reorder_point': reorder_info.get('reorder_point', 0),
                    'safety_stock': reorder_info.get('safety_stock', 0),
                    'economic_order_quantity': eoq,
                    'demand_forecast': self.demand_engine.predict_demand(product_data, 30),
                    'insights': insights,
                    'optimization_score': self.calculate_optimization_score(insights, reorder_info)
                }
                
            except Exception as e:
                logger.error(f"Error optimizing inventory for product {product_id}: {e}")
                optimization_results[product_id] = {}
        
        return optimization_results
    
    def calculate_optimization_score(self, insights: Dict, reorder_info: Dict) -> float:
        """
        Calculate a score (0-100) representing inventory optimization health.
        """
        try:
            score = 100
            
            # Penalize high volatility
            volatility = insights.get('demand_volatility', 0)
            score -= min(30, volatility * 100)
            
            # Penalize stockout risk
            stockout_risk = insights.get('stockout_risk', 'low')
            if stockout_risk == 'high':
                score -= 40
            elif stockout_risk == 'medium':
                score -= 20
            
            # Reward stable demand trend
            trend = insights.get('demand_trend', 'stable')
            if trend == 'stable':
                score += 10
            
            return max(0, min(100, score))
            
        except Exception as e:
            logger.error(f"Error calculating optimization score: {e}")
            return 50