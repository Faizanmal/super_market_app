"""
Enterprise-grade views for advanced inventory management.
"""
from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from datetime import timedelta

from .models import (
    Notification, AuditLog, Currency, InventoryAdjustment,
    StoreTransfer, PriceHistory, SupplierContract
)
from .serializers import (
    NotificationSerializer, AuditLogSerializer, CurrencySerializer,
    InventoryAdjustmentSerializer, StoreTransferSerializer,
    PriceHistorySerializer, SupplierContractSerializer
)


class NotificationViewSet(viewsets.ModelViewSet):
    """
    Manage user notifications with real-time updates.
    """
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return only current user's notifications."""
        return Notification.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['get'])
    def unread(self, request):
        """Get all unread notifications."""
        notifications = self.get_queryset().filter(is_read=False)
        serializer = self.get_serializer(notifications, many=True)
        return Response({
            'count': notifications.count(),
            'notifications': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a notification as read."""
        notification = self.get_object()
        notification.mark_as_read()
        return Response({'status': 'notification marked as read'})
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read."""
        count = self.get_queryset().filter(is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )
        return Response({'status': f'{count} notifications marked as read'})
    
    @action(detail=False, methods=['delete'])
    def clear_old(self, request):
        """Delete read notifications older than 30 days."""
        cutoff_date = timezone.now() - timedelta(days=30)
        count, _ = self.get_queryset().filter(
            is_read=True,
            created_at__lt=cutoff_date
        ).delete()
        return Response({'status': f'{count} old notifications deleted'})
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get notification summary statistics."""
        queryset = self.get_queryset()
        
        summary = {
            'total': queryset.count(),
            'unread': queryset.filter(is_read=False).count(),
            'by_type': list(queryset.values('notification_type').annotate(
                count=Count('id')
            )),
            'by_priority': list(queryset.values('priority').annotate(
                count=Count('id')
            )),
            'critical_unread': queryset.filter(
                is_read=False,
                priority='critical'
            ).count(),
        }
        
        return Response(summary)


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    View audit logs (read-only for security).
    """
    serializer_class = AuditLogSerializer
    permission_classes = [IsAuthenticated]
    queryset = AuditLog.objects.all()
    
    def get_queryset(self):
        """Filter audit logs based on query parameters."""
        queryset = super().get_queryset()
        
        # Filter by user
        user_id = self.request.query_params.get('user', None)
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        
        # Filter by action
        action = self.request.query_params.get('action', None)
        if action:
            queryset = queryset.filter(action=action)
        
        # Filter by model
        model_name = self.request.query_params.get('model', None)
        if model_name:
            queryset = queryset.filter(model_name=model_name)
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date', None)
        end_date = self.request.query_params.get('end_date', None)
        
        if start_date:
            queryset = queryset.filter(timestamp__gte=start_date)
        if end_date:
            queryset = queryset.filter(timestamp__lte=end_date)
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def user_activity(self, request):
        """Get user activity summary."""
        user_id = request.query_params.get('user', request.user.id)
        
        logs = AuditLog.objects.filter(user_id=user_id)
        
        activity = {
            'total_actions': logs.count(),
            'by_action': list(logs.values('action').annotate(
                count=Count('id')
            )),
            'by_model': list(logs.values('model_name').annotate(
                count=Count('id')
            )),
            'recent_activity': AuditLogSerializer(
                logs[:10], many=True
            ).data,
            'failed_actions': logs.filter(success=False).count(),
        }
        
        return Response(activity)
    
    @action(detail=False, methods=['get'])
    def object_history(self, request):
        """Get complete history for a specific object."""
        model_name = request.query_params.get('model')
        object_id = request.query_params.get('object_id')
        
        if not model_name or not object_id:
            return Response(
                {'error': 'model and object_id parameters required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        history = AuditLog.objects.filter(
            model_name=model_name,
            object_id=object_id
        )
        
        serializer = self.get_serializer(history, many=True)
        return Response(serializer.data)


class CurrencyViewSet(viewsets.ModelViewSet):
    """
    Manage currencies for multi-currency support.
    """
    serializer_class = CurrencySerializer
    permission_classes = [IsAuthenticated]
    queryset = Currency.objects.all()
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active currencies."""
        currencies = Currency.objects.filter(is_active=True)
        serializer = self.get_serializer(currencies, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def base(self, request):
        """Get the base currency."""
        try:
            base_currency = Currency.objects.get(is_base_currency=True)
            serializer = self.get_serializer(base_currency)
            return Response(serializer.data)
        except Currency.DoesNotExist:
            return Response(
                {'error': 'No base currency configured'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=False, methods=['post'])
    def convert(self, request):
        """
        Convert amount from one currency to another.
        Body: {amount, from_currency_code, to_currency_code}
        """
        amount = float(request.data.get('amount', 0))
        from_code = request.data.get('from_currency')
        to_code = request.data.get('to_currency')
        
        try:
            from_currency = Currency.objects.get(code=from_code, is_active=True)
            to_currency = Currency.objects.get(code=to_code, is_active=True)
            
            # Convert to base currency first, then to target currency
            base_amount = amount / from_currency.exchange_rate
            converted_amount = base_amount * to_currency.exchange_rate
            
            return Response({
                'original_amount': amount,
                'from_currency': from_code,
                'to_currency': to_code,
                'converted_amount': round(converted_amount, 2),
                'exchange_rate': round(to_currency.exchange_rate / from_currency.exchange_rate, 6)
            })
        except Currency.DoesNotExist:
            return Response(
                {'error': 'Currency not found or inactive'},
                status=status.HTTP_404_NOT_FOUND
            )


class InventoryAdjustmentViewSet(viewsets.ModelViewSet):
    """
    Manage inventory adjustments with approval workflow.
    """
    serializer_class = InventoryAdjustmentSerializer
    permission_classes = [IsAuthenticated]
    queryset = InventoryAdjustment.objects.all()
    
    def perform_create(self, serializer):
        """Set created_by to current user."""
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get all pending adjustments."""
        pending = self.get_queryset().filter(status='pending')
        serializer = self.get_serializer(pending, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve an adjustment and update inventory."""
        adjustment = self.get_object()
        
        if adjustment.status != 'pending':
            return Response(
                {'error': 'Only pending adjustments can be approved'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update product quantity
        product = adjustment.product
        product.quantity = adjustment.quantity_after
        product.save()
        
        # Update adjustment status
        adjustment.status = 'approved'
        adjustment.approved_by = request.user
        adjustment.approved_at = timezone.now()
        adjustment.save()
        
        return Response({
            'status': 'adjustment approved',
            'new_quantity': product.quantity
        })
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject an adjustment."""
        adjustment = self.get_object()
        
        if adjustment.status != 'pending':
            return Response(
                {'error': 'Only pending adjustments can be rejected'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        adjustment.status = 'rejected'
        adjustment.approved_by = request.user
        adjustment.approved_at = timezone.now()
        adjustment.save()
        
        return Response({'status': 'adjustment rejected'})
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Get adjustment statistics."""
        queryset = self.get_queryset()
        
        stats = {
            'total': queryset.count(),
            'by_status': list(queryset.values('status').annotate(
                count=Count('id')
            )),
            'by_reason': list(queryset.values('reason').annotate(
                count=Count('id')
            )),
            'total_increases': queryset.filter(
                adjustment_quantity__gt=0
            ).aggregate(
                total=Sum('adjustment_quantity')
            )['total'] or 0,
            'total_decreases': abs(queryset.filter(
                adjustment_quantity__lt=0
            ).aggregate(
                total=Sum('adjustment_quantity')
            )['total'] or 0),
        }
        
        return Response(stats)


class StoreTransferViewSet(viewsets.ModelViewSet):
    """
    Manage inventory transfers between stores.
    """
    serializer_class = StoreTransferSerializer
    permission_classes = [IsAuthenticated]
    queryset = StoreTransfer.objects.all()
    
    def perform_create(self, serializer):
        """Set initiated_by to current user."""
        serializer.save(initiated_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get all pending transfers."""
        pending = self.get_queryset().filter(status='pending')
        serializer = self.get_serializer(pending, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def ship(self, request, pk=None):
        """Mark transfer as shipped."""
        transfer = self.get_object()
        
        if transfer.status != 'pending':
            return Response(
                {'error': 'Only pending transfers can be shipped'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Deduct from source store
        product = transfer.product
        if product.quantity < transfer.quantity:
            return Response(
                {'error': 'Insufficient quantity in source store'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        product.quantity -= transfer.quantity
        product.save()
        
        transfer.status = 'in_transit'
        transfer.shipped_at = timezone.now()
        transfer.save()
        
        return Response({'status': 'transfer shipped'})
    
    @action(detail=True, methods=['post'])
    def receive(self, request, pk=None):
        """Mark transfer as received."""
        transfer = self.get_object()
        
        if transfer.status != 'in_transit':
            return Response(
                {'error': 'Only in-transit transfers can be received'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Add to destination store
        # Note: In a real implementation, you'd handle product-store relationships
        transfer.status = 'received'
        transfer.received_by = request.user
        transfer.received_at = timezone.now()
        transfer.save()
        
        return Response({'status': 'transfer received'})
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel a transfer."""
        transfer = self.get_object()
        
        if transfer.status == 'received':
            return Response(
                {'error': 'Cannot cancel received transfers'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # If already shipped, return quantity to source
        if transfer.status == 'in_transit':
            product = transfer.product
            product.quantity += transfer.quantity
            product.save()
        
        transfer.status = 'cancelled'
        transfer.save()
        
        return Response({'status': 'transfer cancelled'})


class PriceHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    View price history for products.
    """
    serializer_class = PriceHistorySerializer
    permission_classes = [IsAuthenticated]
    queryset = PriceHistory.objects.all()
    
    @action(detail=False, methods=['get'])
    def product_history(self, request):
        """Get price history for a specific product."""
        product_id = request.query_params.get('product_id')
        
        if not product_id:
            return Response(
                {'error': 'product_id parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        history = self.get_queryset().filter(product_id=product_id)
        serializer = self.get_serializer(history, many=True)
        
        return Response({
            'product_id': product_id,
            'history': serializer.data,
            'total_changes': history.count()
        })
    
    @action(detail=False, methods=['get'])
    def recent_changes(self, request):
        """Get recent price changes across all products."""
        days = int(request.query_params.get('days', 7))
        cutoff_date = timezone.now() - timedelta(days=days)
        
        changes = self.get_queryset().filter(changed_at__gte=cutoff_date)
        serializer = self.get_serializer(changes, many=True)
        
        return Response({
            'days': days,
            'changes': serializer.data,
            'total_changes': changes.count()
        })


class SupplierContractViewSet(viewsets.ModelViewSet):
    """ 
    Manage supplier contracts and agreements.
    """
    serializer_class = SupplierContractSerializer
    permission_classes = [IsAuthenticated]
    queryset = SupplierContract.objects.all()
    
    def perform_create(self, serializer):
        """Set created_by to current user."""
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active contracts."""
        today = timezone.now().date()
        active = self.get_queryset().filter(
            status='active',
            start_date__lte=today,
            end_date__gte=today
        )
        serializer = self.get_serializer(active, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Get contracts expiring in the next 30 days."""
        today = timezone.now().date()
        expiry_date = today + timedelta(days=30)
        
        expiring = self.get_queryset().filter(
            status='active',
            end_date__range=[today, expiry_date]
        )
        serializer = self.get_serializer(expiring, many=True)
        
        return Response({
            'count': expiring.count(),
            'contracts': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def by_supplier(self, request):
        """Get contracts for a specific supplier."""
        supplier_id = request.query_params.get('supplier_id')
        
        if not supplier_id:
            return Response(
                {'error': 'supplier_id parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        contracts = self.get_queryset().filter(supplier_id=supplier_id)
        serializer = self.get_serializer(contracts, many=True)
        
        return Response({
            'supplier_id': supplier_id,
            'contracts': serializer.data,
            'total': contracts.count()
        })
