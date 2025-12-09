"""
Smart Pricing API Views
Provides endpoints for dynamic pricing, price optimization, and competitor analysis
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import F
from datetime import timedelta
from decimal import Decimal

from .smart_pricing_models import (
    PricingRule, DynamicPrice, PriceChangeHistory,
    CompetitorPrice
)
from .models import Product


class SmartPricingViewSet(viewsets.ViewSet):
    """
    ViewSet for smart pricing operations
    """
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['post'])
    def calculate_dynamic_prices(self, request):
        """
        Calculate dynamic prices for products based on rules
        """
        product_ids = request.data.get('product_ids', [])
        auto_approve = request.data.get('auto_approve', False)
        
        if not product_ids:
            # Calculate for all products with expiring batches
            products = Product.objects.filter(
                batches__expiry_date__lte=timezone.now().date() + timedelta(days=30)
            ).distinct()
        else:
            products = Product.objects.filter(id__in=product_ids)
        
        results = []
        for product in products:
            try:
                dynamic_price = self._calculate_product_dynamic_price(product, request.user)
                if auto_approve and dynamic_price:
                    dynamic_price.approve(request.user, 'Auto-approved by system')
                    dynamic_price.activate()
                results.append({
                    'product_id': product.id,
                    'product_name': product.name,
                    'original_price': float(product.selling_price),
                    'suggested_price': float(dynamic_price.suggested_price) if dynamic_price else None,
                    'discount_percent': float(dynamic_price.discount_percent) if dynamic_price else 0,
                    'status': dynamic_price.status if dynamic_price else 'no_change',
                })
            except Exception as e:
                results.append({
                    'product_id': product.id,
                    'product_name': product.name,
                    'error': str(e),
                })
        
        return Response({
            'success': True,
            'prices_calculated': len(results),
            'results': results,
        })
    
    def _calculate_product_dynamic_price(self, product, user):
        """Calculate dynamic price for a single product"""
        # Get active pricing rules in priority order
        rules = PricingRule.objects.filter(is_active=True).order_by('-priority')
        
        original_price = product.selling_price
        best_discount = Decimal('0')
        applied_rules = []
        pricing_factors = {}
        
        # Check each rule
        for rule in rules:
            # Check if rule applies to this product
            if rule.applies_to_categories and product.category_id not in rule.applies_to_categories:
                continue
            if rule.applies_to_products and product.id not in rule.applies_to_products:
                continue
            if rule.min_original_price and original_price < rule.min_original_price:
                continue
            if rule.max_original_price and original_price > rule.max_original_price:
                continue
            if not rule.is_valid_now():
                continue
            
            # Evaluate condition
            condition_met = False
            if rule.rule_type == 'expiry':
                # Check days to expiry
                nearest_expiry = product.batches.filter(
                    expiry_date__gte=timezone.now().date()
                ).order_by('expiry_date').first()
                
                if nearest_expiry:
                    days_to_expiry = (nearest_expiry.expiry_date - timezone.now().date()).days
                    condition_met = rule.evaluate_condition(Decimal(days_to_expiry))
                    pricing_factors['days_to_expiry'] = days_to_expiry
            
            elif rule.rule_type == 'demand':
                # Check stock level
                stock_level = product.quantity
                condition_met = rule.evaluate_condition(Decimal(stock_level))
                pricing_factors['stock_level'] = stock_level
            
            if condition_met:
                discount = rule.calculate_discount(original_price)
                if discount > best_discount:
                    best_discount = discount
                    applied_rules.append(rule.id)
        
        if best_discount > 0:
            suggested_price = original_price - best_discount
            discount_percent = (best_discount / original_price) * 100
            
            # Create dynamic price record
            dynamic_price = DynamicPrice.objects.create(
                product=product,
                original_price=original_price,
                suggested_price=suggested_price,
                discount_amount=best_discount,
                discount_percent=discount_percent,
                applied_rules=applied_rules,
                pricing_factors=pricing_factors,
                status='pending',
            )
            
            return dynamic_price
        
        return None
    
    @action(detail=False, methods=['get'])
    def recommendations(self, request):
        """
        Get pricing recommendations for products
        """
        # Products with expiring batches
        expiring_soon = Product.objects.filter(
            batches__expiry_date__lte=timezone.now().date() + timedelta(days=7)
        ).distinct()
        
        # Overstock products
        overstock = Product.objects.filter(
            quantity__gt=F('reorder_level') * 3
        )
        
        recommendations = []
        
        for product in expiring_soon:
            days_to_expiry = (
                product.batches.filter(expiry_date__gte=timezone.now().date())
                .order_by('expiry_date')
                .first()
                .expiry_date - timezone.now().date()
            ).days
            
            # Suggest discount based on days to expiry
            if days_to_expiry <= 3:
                suggested_discount = 50
            elif days_to_expiry <= 7:
                suggested_discount = 30
            else:
                suggested_discount = 20
            
            recommendations.append({
                'product_id': product.id,
                'product_name': product.name,
                'reason': 'expiring_soon',
                'days_to_expiry': days_to_expiry,
                'current_price': float(product.selling_price),
                'suggested_discount_percent': suggested_discount,
                'suggested_price': float(product.selling_price * (1 - suggested_discount/100)),
                'priority': 'high' if days_to_expiry <= 3 else 'medium',
            })
        
        for product in overstock:
            recommendations.append({
                'product_id': product.id,
                'product_name': product.name,
                'reason': 'overstock',
                'current_stock': product.quantity,
                'current_price': float(product.selling_price),
                'suggested_discount_percent': 15,
                'suggested_price': float(product.selling_price * 0.85),
                'priority': 'low',
            })
        
        return Response({
            'success': True,
            'total_recommendations': len(recommendations),
            'recommendations': recommendations,
        })
    
    @action(detail=False, methods=['post'])
    def add_competitor_price(self, request):
        """
        Add competitor price for a product
        """
        product_id = request.data.get('product_id')
        competitor_name = request.data.get('competitor_name')
        price = request.data.get('price')
        
        try:
            product = Product.objects.get(id=product_id)
            
            competitor_price = CompetitorPrice.objects.create(
                product=product,
                competitor_name=competitor_name,
                price=Decimal(str(price)),
                source=request.data.get('source', 'manual'),
                source_url=request.data.get('source_url', ''),
                verified=False,
            )
            
            # Calculate difference
            competitor_price.calculate_difference(product.selling_price)
            
            return Response({
                'success': True,
                'message': 'Competitor price added successfully',
                'is_cheaper': competitor_price.is_cheaper,
                'price_difference': float(competitor_price.price_difference),
                'price_difference_percent': float(competitor_price.price_difference_percent),
            })
        except Product.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Product not found',
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e),
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def competitor_analysis(self, request):
        """
        Get competitor price analysis
        """
        product_id = request.query_params.get('product_id')
        
        if product_id:
            competitor_prices = CompetitorPrice.objects.filter(product_id=product_id)
        else:
            # Get all recent competitor prices
            competitor_prices = CompetitorPrice.objects.filter(
                observed_at__gte=timezone.now() - timedelta(days=30)
            )
        
        analysis = []
        for cp in competitor_prices:
            analysis.append({
                'product_id': cp.product.id,
                'product_name': cp.product.name,
                'our_price': float(cp.product.selling_price),
                'competitor_name': cp.competitor_name,
                'competitor_price': float(cp.price),
                'price_difference': float(cp.price_difference),
                'price_difference_percent': float(cp.price_difference_percent),
                'is_cheaper': cp.is_cheaper,
                'observed_at': cp.observed_at,
            })
        
        return Response({
            'success': True,
            'total_comparisons': len(analysis),
            'analysis': analysis,
        })
    
    @action(detail=False, methods=['get'])
    def price_history(self, request):
        """
        Get price change history for a product
        """
        product_id = request.query_params.get('product_id')
        
        if not product_id:
            return Response({
                'success': False,
                'error': 'product_id is required',
            }, status=status.HTTP_400_BAD_REQUEST)
        
        history = PriceChangeHistory.objects.filter(
            product_id=product_id
        ).order_by('-changed_at')[:50]
        
        history_data = []
        for record in history:
            history_data.append({
                'old_price': float(record.old_price),
                'new_price': float(record.new_price),
                'price_difference': float(record.price_difference),
                'percent_change': float(record.percent_change),
                'change_type': record.change_type,
                'reason': record.reason,
                'changed_by': record.changed_by.username if record.changed_by else None,
                'changed_at': record.changed_at,
            })
        
        return Response({
            'success': True,
            'total_changes': len(history_data),
            'history': history_data,
        })
    
    @action(detail=False, methods=['post'])
    def approve_dynamic_price(self, request):
        """
        Approve a dynamic price suggestion
        """
        dynamic_price_id = request.data.get('dynamic_price_id')
        notes = request.data.get('notes', '')
        activate = request.data.get('activate', True)
        
        try:
            dynamic_price = DynamicPrice.objects.get(id=dynamic_price_id)
            dynamic_price.approve(request.user, notes)
            
            if activate:
                dynamic_price.activate()
                
                # Create price change history
                PriceChangeHistory.objects.create(
                    product=dynamic_price.product,
                    batch=dynamic_price.batch,
                    old_price=dynamic_price.original_price,
                    new_price=dynamic_price.suggested_price,
                    price_difference=dynamic_price.original_price - dynamic_price.suggested_price,
                    percent_change=-dynamic_price.discount_percent,
                    change_type='dynamic',
                    reason=f"Dynamic pricing applied. Rules: {dynamic_price.applied_rules}",
                    changed_by=request.user,
                    dynamic_price=dynamic_price,
                    applied_rules=dynamic_price.applied_rules,
                )
                
                # Update product price
                product = dynamic_price.product
                product.selling_price = dynamic_price.suggested_price
                product.save()
            
            return Response({
                'success': True,
                'message': 'Dynamic price approved and activated' if activate else 'Dynamic price approved',
            })
        except DynamicPrice.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Dynamic price not found',
            }, status=status.HTTP_404_NOT_FOUND)
