"""
Views for Customer Features.
Shopping Lists and Digital Receipts with Warranty Tracking.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Sum, Count
from datetime import timedelta
from decimal import Decimal
import uuid

from .customer_features_models import (
    ShoppingList, ShoppingListItem, DigitalReceipt,
    ReceiptItem, WarrantyTracker, WarrantyClaim
)
from .new_features_serializers import (
    ShoppingListSerializer, ShoppingListItemSerializer,
    DigitalReceiptSerializer, ReceiptItemSerializer,
    WarrantyTrackerSerializer, WarrantyClaimSerializer,
    WarrantyDashboardSerializer
)
from .models import Product


class ShoppingListViewSet(viewsets.ModelViewSet):
    """ViewSet for managing shopping lists."""
    serializer_class = ShoppingListSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        # Include owned lists and shared lists
        return ShoppingList.objects.filter(
            owner=user
        ) | ShoppingList.objects.filter(
            shared_with=user
        )
    
    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
    
    @action(detail=True, methods=['post'])
    def share(self, request, pk=None):
        """Generate a share code for the list."""
        shopping_list = self.get_object()
        if shopping_list.owner != request.user:
            return Response({'error': 'Only owner can share'}, status=403)
        
        share_code = shopping_list.generate_share_code()
        shopping_list.is_shared = True
        shopping_list.save()
        
        return Response({
            'share_code': share_code,
            'share_url': f"/shopping-list/join/{share_code}"
        })
    
    @action(detail=False, methods=['post'])
    def join(self, request):
        """Join a shared shopping list."""
        share_code = request.data.get('share_code')
        
        try:
            shopping_list = ShoppingList.objects.get(share_code=share_code)
            shopping_list.shared_with.add(request.user)
            return Response(ShoppingListSerializer(shopping_list).data)
        except ShoppingList.DoesNotExist:
            return Response({'error': 'Invalid share code'}, status=404)
    
    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        """Add an item to the shopping list."""
        shopping_list = self.get_object()
        
        item_data = {
            'shopping_list': shopping_list,
            'added_by': request.user,
            **request.data
        }
        
        if 'product_id' in request.data:
            item_data['product_id'] = request.data['product_id']
        
        item = ShoppingListItem.objects.create(**item_data)
        
        # Update estimated total
        if item.estimated_price:
            shopping_list.estimated_total += item.estimated_price * item.quantity
            shopping_list.save()
        
        return Response(ShoppingListItemSerializer(item).data, status=201)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark shopping list as completed."""
        shopping_list = self.get_object()
        shopping_list.status = 'completed'
        shopping_list.completed_date = timezone.now()
        
        # Calculate actual total from purchased items
        actual_total = shopping_list.items.filter(
            status='purchased'
        ).aggregate(
            total=Sum('actual_price')
        )['total'] or Decimal('0.00')
        
        shopping_list.actual_total = actual_total
        shopping_list.save()
        
        return Response(ShoppingListSerializer(shopping_list).data)
    
    @action(detail=True, methods=['get'])
    def optimized_route(self, request, pk=None):
        """Get optimized shopping route based on store layout."""
        shopping_list = self.get_object()
        items = shopping_list.items.filter(status='pending').order_by('aisle_location')
        
        # Group by aisle
        aisles = {}
        for item in items:
            aisle = item.aisle_location or 'Unknown'
            if aisle not in aisles:
                aisles[aisle] = []
            aisles[aisle].append(ShoppingListItemSerializer(item).data)
        
        return Response({
            'route': aisles,
            'total_items': items.count()
        })


class ShoppingListItemViewSet(viewsets.ModelViewSet):
    """ViewSet for managing shopping list items."""
    serializer_class = ShoppingListItemSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return ShoppingListItem.objects.filter(
            shopping_list__owner=self.request.user
        ) | ShoppingListItem.objects.filter(
            shopping_list__shared_with=self.request.user
        )
    
    @action(detail=True, methods=['post'])
    def check_off(self, request, pk=None):
        """Mark item as purchased."""
        item = self.get_object()
        item.status = 'purchased'
        item.checked_off_at = timezone.now()
        
        if 'actual_price' in request.data:
            item.actual_price = Decimal(str(request.data['actual_price']))
        
        item.save()
        return Response(ShoppingListItemSerializer(item).data)
    
    @action(detail=True, methods=['post'])
    def uncheck(self, request, pk=None):
        """Unmark item as purchased."""
        item = self.get_object()
        item.status = 'pending'
        item.checked_off_at = None
        item.save()
        return Response(ShoppingListItemSerializer(item).data)


class DigitalReceiptViewSet(viewsets.ModelViewSet):
    """ViewSet for managing digital receipts."""
    serializer_class = DigitalReceiptSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return DigitalReceipt.objects.filter(
            customer=self.request.user
        ).prefetch_related('items')
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Get recent receipts."""
        days = int(request.query_params.get('days', 30))
        since = timezone.now() - timedelta(days=days)
        
        receipts = self.get_queryset().filter(
            transaction_date__gte=since
        ).order_by('-transaction_date')
        
        serializer = self.get_serializer(receipts, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get spending summary."""
        days = int(request.query_params.get('days', 30))
        since = timezone.now() - timedelta(days=days)
        
        receipts = self.get_queryset().filter(transaction_date__gte=since)
        
        summary = receipts.aggregate(
            total_spent=Sum('total_amount'),
            total_saved=Sum('discount_amount'),
            receipt_count=Count('id')
        )
        
        return Response({
            'total_spent': str(summary['total_spent'] or Decimal('0.00')),
            'total_saved': str(summary['total_saved'] or Decimal('0.00')),
            'receipt_count': summary['receipt_count'] or 0,
            'average_per_receipt': str(
                (summary['total_spent'] or Decimal('0.00')) / max(summary['receipt_count'] or 1, 1)
            )
        })
    
    @action(detail=True, methods=['get'])
    def download_pdf(self, request, pk=None):
        """Get PDF download URL for receipt."""
        receipt = self.get_object()
        if receipt.pdf_url:
            return Response({'pdf_url': receipt.pdf_url})
        return Response({'error': 'PDF not available'}, status=404)


class WarrantyTrackerViewSet(viewsets.ModelViewSet):
    """ViewSet for managing warranty tracking."""
    serializer_class = WarrantyTrackerSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return WarrantyTracker.objects.filter(
            customer=self.request.user
        ).prefetch_related('claims')
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Get warranty dashboard overview."""
        warranties = self.get_queryset()
        today = timezone.now().date()
        
        # Update statuses
        for warranty in warranties:
            warranty.update_status()
        
        active = warranties.filter(status='active').count()
        expiring = warranties.filter(status='expiring_soon').count()
        expired = warranties.filter(status='expired').count()
        
        upcoming = warranties.filter(
            status='expiring_soon'
        ).order_by('warranty_end_date')[:5]
        
        return Response({
            'total_warranties': warranties.count(),
            'active_warranties': active,
            'expiring_soon': expiring,
            'expired': expired,
            'upcoming_expirations': WarrantyTrackerSerializer(upcoming, many=True).data
        })
    
    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Get warranties expiring soon."""
        days = int(request.query_params.get('days', 30))
        today = timezone.now().date()
        threshold = today + timedelta(days=days)
        
        warranties = self.get_queryset().filter(
            warranty_end_date__lte=threshold,
            warranty_end_date__gt=today
        ).order_by('warranty_end_date')
        
        serializer = self.get_serializer(warranties, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def set_reminder(self, request, pk=None):
        """Set reminder for warranty expiry."""
        warranty = self.get_object()
        days_before = request.data.get('days_before', 30)
        
        warranty.reminder_days_before = days_before
        warranty.reminder_sent = False
        warranty.save()
        
        return Response({
            'reminder_set': True,
            'days_before_expiry': days_before
        })
    
    @action(detail=True, methods=['post'])
    def file_claim(self, request, pk=None):
        """File a warranty claim."""
        warranty = self.get_object()
        
        if warranty.status == 'expired':
            return Response({'error': 'Warranty has expired'}, status=400)
        
        claim = WarrantyClaim.objects.create(
            warranty=warranty,
            issue_description=request.data.get('issue_description', ''),
            images=request.data.get('images', [])
        )
        
        warranty.times_claimed += 1
        warranty.last_claim_date = timezone.now().date()
        warranty.status = 'claimed'
        warranty.save()
        
        return Response(WarrantyClaimSerializer(claim).data, status=201)


class WarrantyClaimViewSet(viewsets.ModelViewSet):
    """ViewSet for managing warranty claims."""
    serializer_class = WarrantyClaimSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return WarrantyClaim.objects.filter(
            warranty__customer=self.request.user
        )
    
    @action(detail=True, methods=['post'])
    def add_images(self, request, pk=None):
        """Add images to a claim."""
        claim = self.get_object()
        new_images = request.data.get('images', [])
        
        claim.images.extend(new_images)
        claim.save()
        
        return Response(WarrantyClaimSerializer(claim).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_dashboard(request):
    """
    Get customer dashboard with overview of all features.
    """
    user = request.user
    today = timezone.now().date()
    thirty_days_ago = today - timedelta(days=30)
    
    # Shopping lists stats
    active_lists = ShoppingList.objects.filter(
        owner=user, status='active'
    ).count()
    
    pending_items = ShoppingListItem.objects.filter(
        shopping_list__owner=user,
        shopping_list__status='active',
        status='pending'
    ).count()
    
    # Receipt stats
    recent_receipts = DigitalReceipt.objects.filter(
        customer=user,
        transaction_date__gte=thirty_days_ago
    ).aggregate(
        total_spent=Sum('total_amount'),
        total_saved=Sum('discount_amount'),
        count=Count('id')
    )
    
    # Warranty stats
    warranties = WarrantyTracker.objects.filter(customer=user)
    active_warranties = warranties.filter(status='active').count()
    expiring_warranties = warranties.filter(status='expiring_soon').count()
    
    return Response({
        'shopping_lists': {
            'active_lists': active_lists,
            'pending_items': pending_items
        },
        'receipts': {
            'total_spent': str(recent_receipts['total_spent'] or Decimal('0.00')),
            'total_saved': str(recent_receipts['total_saved'] or Decimal('0.00')),
            'receipt_count': recent_receipts['count'] or 0
        },
        'warranties': {
            'active': active_warranties,
            'expiring_soon': expiring_warranties,
            'total': warranties.count()
        }
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_receipt_from_purchase(request):
    """
    Create a digital receipt from a purchase transaction.
    """
    user = request.user
    data = request.data
    
    # Generate receipt number
    receipt_number = f"REC-{timezone.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:6].upper()}"
    
    # Create receipt
    receipt = DigitalReceipt.objects.create(
        receipt_number=receipt_number,
        customer=user,
        store_id=data.get('store_id'),
        transaction_date=timezone.now(),
        subtotal=Decimal(str(data.get('subtotal', 0))),
        tax_amount=Decimal(str(data.get('tax_amount', 0))),
        discount_amount=Decimal(str(data.get('discount_amount', 0))),
        total_amount=Decimal(str(data.get('total_amount', 0))),
        payment_method=data.get('payment_method', 'card'),
        payment_reference=data.get('payment_reference', '')
    )
    
    # Create receipt items and warranties
    items_data = data.get('items', [])
    for item_data in items_data:
        receipt_item = ReceiptItem.objects.create(
            receipt=receipt,
            product_id=item_data.get('product_id'),
            product_name=item_data.get('product_name', ''),
            product_sku=item_data.get('product_sku', ''),
            barcode=item_data.get('barcode', ''),
            quantity=item_data.get('quantity', 1),
            unit_price=Decimal(str(item_data.get('unit_price', 0))),
            discount=Decimal(str(item_data.get('discount', 0))),
            total_price=Decimal(str(item_data.get('total_price', 0))),
            has_warranty=item_data.get('has_warranty', False),
            warranty_months=item_data.get('warranty_months', 0)
        )
        
        # Create warranty if applicable
        if receipt_item.has_warranty and receipt_item.warranty_months > 0:
            warranty_end = today + timedelta(days=receipt_item.warranty_months * 30)
            receipt_item.warranty_expiry = warranty_end
            receipt_item.save()
            
            WarrantyTracker.objects.create(
                customer=user,
                receipt_item=receipt_item,
                product_name=receipt_item.product_name,
                purchase_date=today,
                warranty_start_date=today,
                warranty_end_date=warranty_end
            )
    
    return Response(DigitalReceiptSerializer(receipt).data, status=201)
