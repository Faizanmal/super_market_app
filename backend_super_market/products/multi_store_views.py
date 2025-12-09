"""
Multi-Store Management API Views
Comprehensive REST API endpoints for multi-store operations
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q, Sum, F, Count, Avg
from django.utils import timezone
from datetime import timedelta

from .models import (
    Store, StoreInventory, InterStoreTransfer, 
    StorePerformanceMetrics, StoreUser, ExpiryAlert
)
from .multi_store_serializers import (
    StoreSerializer, StoreInventorySerializer, InterStoreTransferSerializer,
    StorePerformanceMetricsSerializer, StoreUserSerializer
)


class IsStoreManagerOrReadOnly(permissions.BasePermission):
    """Custom permission to only allow store managers to edit stores"""
    
    def has_object_permission(self, request, view, obj):
        # Read permissions for any authenticated user
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions only for store managers or superusers
        if request.user.is_superuser:
            return True
         
        if hasattr(obj, 'manager'):
            return obj.manager == request.user
        
        # For StoreUser objects
        if hasattr(obj, 'user'):
            return obj.user == request.user or request.user.is_superuser
        
        return False


class StoreViewSet(viewsets.ModelViewSet):
    """ViewSet for Store management"""
    queryset = Store.objects.all()
    serializer_class = StoreSerializer
    permission_classes = [permissions.IsAuthenticated, IsStoreManagerOrReadOnly]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['store_type', 'status', 'city', 'state']
    search_fields = ['name', 'code', 'address', 'city']
    ordering_fields = ['name', 'created_at', 'code']
    ordering = ['name']

    def get_queryset(self):
        """Filter stores based on user permissions"""
        user = self.request.user
        if user.is_superuser:
            return Store.objects.all()
        
        # Get stores the user has access to
        if hasattr(user, 'store_profile'):
            return user.store_profile.accessible_stores
        
        # If no store profile, return managed stores
        return Store.objects.filter(manager=user)

    @action(detail=True, methods=['get'])
    def dashboard(self, request, pk=None):
        """Get comprehensive store dashboard data"""
        store = self.get_object()
        today = timezone.now().date()
        
        # Basic stats
        total_products = store.store_inventories.filter(is_active=True).count()
        total_stock_value = store.total_stock_value
        
        # Stock alerts
        low_stock = store.store_inventories.filter(
            current_stock__lte=F('reorder_point'),
            is_active=True
        ).count()
        
        out_of_stock = store.store_inventories.filter(
            current_stock=0,
            is_active=True
        ).count()
        
        overstocked = store.store_inventories.filter(
            current_stock__gt=F('max_stock_level'),
            is_active=True
        ).count()
        
        # Recent transfers
        recent_transfers = InterStoreTransfer.objects.filter(
            Q(from_store=store) | Q(to_store=store),
            requested_date__gte=today - timedelta(days=7)
        ).count()
        
        # Performance metrics
        try:
            latest_metrics = store.performance_metrics.filter(date=today).first()
            performance_data = {
                'total_sales': float(latest_metrics.total_sales) if latest_metrics else 0,
                'total_transactions': latest_metrics.total_transactions if latest_metrics else 0,
                'stock_health_score': latest_metrics.stock_health_score if latest_metrics else 0,
            }
        except Exception:
            performance_data = {
                'total_sales': 0,
                'total_transactions': 0,
                'stock_health_score': 0,
            }
        
        return Response({
            'store_info': {
                'id': str(store.id),
                'name': store.name,
                'code': store.code,
                'type': store.store_type,
                'status': store.status,
            },
            'inventory_summary': {
                'total_products': total_products,
                'total_stock_value': float(total_stock_value),
                'low_stock_items': low_stock,
                'out_of_stock_items': out_of_stock,
                'overstocked_items': overstocked,
            },
            'transfer_activity': {
                'recent_transfers': recent_transfers,
            },
            'performance': performance_data,
        })

    @action(detail=True, methods=['get'])
    def inventory_health(self, request, pk=None):
        """Get detailed inventory health analysis"""
        store = self.get_object()
        
        # Get all active inventory items
        inventories = store.store_inventories.filter(is_active=True).select_related('product')
        
        health_data = {
            'critical_items': [],
            'low_stock_items': [],
            'overstocked_items': [],
            'optimal_items': [],
            'expiring_soon': [],
        }
        
        for inventory in inventories:
            item_data = {
                'product_id': inventory.product.id,
                'product_name': inventory.product.name,
                'current_stock': inventory.current_stock,
                'reorder_point': inventory.reorder_point,
                'max_stock_level': inventory.max_stock_level,
                'stock_percentage': inventory.stock_percentage,
            }
            
            if inventory.current_stock == 0:
                health_data['critical_items'].append(item_data)
            elif inventory.needs_reorder:
                health_data['low_stock_items'].append(item_data)
            elif inventory.is_overstocked:
                health_data['overstocked_items'].append(item_data)
            else:
                health_data['optimal_items'].append(item_data)
        
        # Get expiring items (next 7 days)
        expiry_alerts = ExpiryAlert.objects.filter(
            product__store_inventories__store=store,
            alert_date__lte=timezone.now().date() + timedelta(days=7),
            is_resolved=False
        ).select_related('product')
        
        for alert in expiry_alerts:
            health_data['expiring_soon'].append({
                'product_id': alert.product.id,
                'product_name': alert.product.name,
                'expiry_date': alert.product.expiry_date.isoformat() if alert.product.expiry_date else None,
                'days_until_expiry': alert.days_until_expiry,
                'alert_level': alert.alert_level,
            })
        
        return Response(health_data)

    @action(detail=False, methods=['get'])
    def comparison(self, request):
        """Compare multiple stores"""
        store_ids = request.query_params.get('stores', '').split(',')
        if not store_ids or len(store_ids) < 2:
            return Response(
                {'error': 'Please provide at least 2 store IDs'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        stores = Store.objects.filter(id__in=store_ids, status='active')
        if stores.count() < 2:
            return Response(
                {'error': 'At least 2 valid stores required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        comparison_data = []
        today = timezone.now().date()
        
        for store in stores:
            # Get latest performance metrics
            metrics = store.performance_metrics.filter(date=today).first()
            
            # Calculate inventory summary
            inventory_summary = store.store_inventories.filter(is_active=True).aggregate(
                total_products=Count('id'),
                total_value=Sum(F('current_stock') * F('product__cost_price')),
                low_stock=Count('id', filter=Q(current_stock__lte=F('reorder_point'))),
                out_of_stock=Count('id', filter=Q(current_stock=0)),
            )
            
            store_data = {
                'store': {
                    'id': str(store.id),
                    'name': store.name,
                    'code': store.code,
                    'type': store.store_type,
                },
                'performance': {
                    'sales': float(metrics.total_sales) if metrics else 0,
                    'transactions': metrics.total_transactions if metrics else 0,
                    'avg_transaction': float(metrics.average_transaction_value) if metrics else 0,
                    'stock_health_score': metrics.stock_health_score if metrics else 0,
                },
                'inventory': {
                    'total_products': inventory_summary['total_products'] or 0,
                    'total_value': float(inventory_summary['total_value'] or 0),
                    'low_stock_items': inventory_summary['low_stock'] or 0,
                    'out_of_stock_items': inventory_summary['out_of_stock'] or 0,
                },
            }
            comparison_data.append(store_data)
        
        return Response({
            'comparison_date': today.isoformat(),
            'stores': comparison_data,
            'summary': {
                'total_stores': len(comparison_data),
                'best_performer': max(comparison_data, key=lambda x: x['performance']['sales']),
                'most_efficient': max(comparison_data, key=lambda x: x['performance']['stock_health_score']),
            }
        })


class StoreInventoryViewSet(viewsets.ModelViewSet):
    """ViewSet for Store Inventory management"""
    queryset = StoreInventory.objects.all()
    serializer_class = StoreInventorySerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['store', 'product', 'is_active']
    search_fields = ['product__name', 'product__barcode', 'aisle', 'shelf']
    ordering_fields = ['current_stock', 'updated_at', 'product__name']
    ordering = ['product__name']

    def get_queryset(self):
        """Filter inventory based on user store access"""
        user = self.request.user
        if user.is_superuser:
            return StoreInventory.objects.all()
        
        # Get accessible stores
        if hasattr(user, 'store_profile'):
            accessible_stores = user.store_profile.accessible_stores
        else:
            accessible_stores = Store.objects.filter(manager=user)
        
        return StoreInventory.objects.filter(store__in=accessible_stores)

    @action(detail=False, methods=['get'])
    def reorder_alerts(self, request):
        """Get items that need reordering across all accessible stores"""
        queryset = self.get_queryset().filter(
            current_stock__lte=F('reorder_point'),
            is_active=True,
            auto_reorder=True
        ).select_related('store', 'product')
        
        store_id = request.query_params.get('store')
        if store_id:
            queryset = queryset.filter(store_id=store_id)
        
        reorder_data = []
        for inventory in queryset:
            reorder_data.append({
                'id': inventory.id,
                'store': {
                    'id': str(inventory.store.id),
                    'name': inventory.store.name,
                    'code': inventory.store.code,
                },
                'product': {
                    'id': inventory.product.id,
                    'name': inventory.product.name,
                    'barcode': inventory.product.barcode,
                },
                'current_stock': inventory.current_stock,
                'reorder_point': inventory.reorder_point,
                'reorder_quantity': inventory.reorder_quantity,
                'suggested_order': max(
                    inventory.reorder_quantity,
                    inventory.max_stock_level - inventory.current_stock
                ),
                'priority': 'critical' if inventory.current_stock == 0 else 'high' if inventory.current_stock < inventory.reorder_point * 0.5 else 'medium',
            })
        
        # Sort by priority and current stock
        priority_order = {'critical': 0, 'high': 1, 'medium': 2}
        reorder_data.sort(key=lambda x: (priority_order[x['priority']], x['current_stock']))
        
        return Response({
            'total_items': len(reorder_data),
            'critical_items': len([x for x in reorder_data if x['priority'] == 'critical']),
            'reorder_list': reorder_data,
        })

    @action(detail=False, methods=['post'])
    def bulk_update_stock(self, request):
        """Bulk update stock levels for multiple items"""
        updates = request.data.get('updates', [])
        if not updates:
            return Response(
                {'error': 'No updates provided'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        updated_items = []
        errors = []
        
        for update in updates:
            try:
                inventory = StoreInventory.objects.get(
                    id=update['inventory_id'],
                    store__in=self.get_queryset().values_list('store', flat=True)
                )
                
                old_stock = inventory.current_stock
                inventory.current_stock = update['new_stock']
                inventory.save()
                
                updated_items.append({
                    'inventory_id': inventory.id,
                    'product_name': inventory.product.name,
                    'store_name': inventory.store.name,
                    'old_stock': old_stock,
                    'new_stock': inventory.current_stock,
                })
                
            except StoreInventory.DoesNotExist:
                errors.append(f"Inventory item {update['inventory_id']} not found")
            except Exception as e:
                errors.append(f"Error updating {update['inventory_id']}: {str(e)}")
        
        return Response({
            'updated_items': updated_items,
            'errors': errors,
            'success_count': len(updated_items),
            'error_count': len(errors),
        })


class InterStoreTransferViewSet(viewsets.ModelViewSet):
    """ViewSet for Inter-Store Transfer management"""
    queryset = InterStoreTransfer.objects.all()
    serializer_class = InterStoreTransferSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'from_store', 'to_store', 'reason']
    search_fields = ['transfer_number', 'product__name', 'notes']
    ordering_fields = ['requested_date', 'approved_date', 'status']
    ordering = ['-requested_date']

    def get_queryset(self):
        """Filter transfers based on user store access"""
        user = self.request.user
        if user.is_superuser:
            return InterStoreTransfer.objects.all()
        
        # Get accessible stores
        if hasattr(user, 'store_profile'):
            accessible_stores = user.store_profile.accessible_stores
        else:
            accessible_stores = Store.objects.filter(manager=user)
        
        return InterStoreTransfer.objects.filter(
            Q(from_store__in=accessible_stores) | Q(to_store__in=accessible_stores)
        )

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a transfer request"""
        transfer = self.get_object()
        
        if transfer.status != 'pending':
            return Response(
                {'error': 'Transfer is not pending approval'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user can approve transfers
        if not (request.user.is_superuser or 
                (hasattr(request.user, 'store_profile') and 
                 request.user.store_profile.can_approve_transfers)):
            return Response(
                {'error': 'You do not have permission to approve transfers'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        approved_quantity = request.data.get('approved_quantity', transfer.requested_quantity)
        
        # Validate approved quantity
        from_inventory = StoreInventory.objects.filter(
            store=transfer.from_store,
            product=transfer.product
        ).first()
        
        if not from_inventory or from_inventory.current_stock < approved_quantity:
            return Response(
                {'error': 'Insufficient stock in source store'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update transfer
        transfer.status = 'approved'
        transfer.approved_quantity = approved_quantity
        transfer.approved_date = timezone.now()
        transfer.approved_by = request.user
        transfer.save()
        
        return Response({
            'message': 'Transfer approved successfully',
            'transfer': InterStoreTransferSerializer(transfer).data
        })

    @action(detail=True, methods=['post'])
    def ship(self, request, pk=None):
        """Mark transfer as shipped"""
        transfer = self.get_object()
        
        if transfer.status != 'approved':
            return Response(
                {'error': 'Transfer must be approved before shipping'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update from store inventory
        from_inventory = StoreInventory.objects.get(
            store=transfer.from_store,
            product=transfer.product
        )
        
        if from_inventory.current_stock < transfer.approved_quantity:
            return Response(
                {'error': 'Insufficient stock in source store'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        from_inventory.current_stock -= transfer.approved_quantity
        from_inventory.save()
        
        # Update transfer status
        transfer.status = 'in_transit'
        transfer.shipped_date = timezone.now()
        transfer.save()
        
        return Response({
            'message': 'Transfer shipped successfully',
            'transfer': InterStoreTransferSerializer(transfer).data
        })

    @action(detail=True, methods=['post'])
    def receive(self, request, pk=None):
        """Mark transfer as received"""
        transfer = self.get_object()
        
        if transfer.status != 'in_transit':
            return Response(
                {'error': 'Transfer must be in transit to receive'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        received_quantity = request.data.get('received_quantity', transfer.approved_quantity)
        
        # Get or create destination store inventory
        to_inventory, created = StoreInventory.objects.get_or_create(
            store=transfer.to_store,
            product=transfer.product,
            defaults={
                'current_stock': 0,
                'min_stock_level': 0,
                'max_stock_level': 100,
                'reorder_point': 10,
                'reorder_quantity': 50,
            }
        )
        
        # Update destination inventory
        to_inventory.current_stock += received_quantity
        to_inventory.save()
        
        # Update transfer
        transfer.status = 'received'
        transfer.received_quantity = received_quantity
        transfer.received_date = timezone.now()
        transfer.received_by = request.user
        transfer.save()
        
        return Response({
            'message': 'Transfer received successfully',
            'transfer': InterStoreTransferSerializer(transfer).data
        })

    @action(detail=False, methods=['get'])
    def analytics(self, request):
        """Get transfer analytics"""
        queryset = self.get_queryset()
        
        # Date range filter
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now().date() - timedelta(days=days)
        queryset = queryset.filter(requested_date__date__gte=start_date)
        
        # Status distribution
        status_counts = queryset.values('status').annotate(count=Count('id'))
        
        # Most transferred products
        product_transfers = queryset.values('product__name').annotate(
            total_quantity=Sum('approved_quantity'),
            transfer_count=Count('id')
        ).order_by('-total_quantity')[:10]
        
        # Store activity
        store_activity = []
        stores = Store.objects.filter(
            Q(outgoing_transfers__in=queryset) | Q(incoming_transfers__in=queryset)
        ).distinct()
        
        for store in stores:
            outgoing = queryset.filter(from_store=store).count()
            incoming = queryset.filter(to_store=store).count()
            store_activity.append({
                'store_name': store.name,
                'store_code': store.code,
                'outgoing_transfers': outgoing,
                'incoming_transfers': incoming,
                'net_transfers': incoming - outgoing,
            })
        
        return Response({
            'period': f'Last {days} days',
            'total_transfers': queryset.count(),
            'status_distribution': list(status_counts),
            'top_products': list(product_transfers),
            'store_activity': store_activity,
        })


class StorePerformanceMetricsViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for Store Performance Metrics (read-only)"""
    queryset = StorePerformanceMetrics.objects.all()
    serializer_class = StorePerformanceMetricsSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['store', 'date']
    ordering_fields = ['date', 'total_sales', 'stock_health_score']
    ordering = ['-date']

    def get_queryset(self):
        """Filter metrics based on user store access"""
        user = self.request.user
        if user.is_superuser:
            return StorePerformanceMetrics.objects.all()
        
        # Get accessible stores
        if hasattr(user, 'store_profile'):
            accessible_stores = user.store_profile.accessible_stores
        else:
            accessible_stores = Store.objects.filter(manager=user)
        
        return StorePerformanceMetrics.objects.filter(store__in=accessible_stores)

    @action(detail=False, methods=['get'])
    def trends(self, request):
        """Get performance trends for stores"""
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now().date() - timedelta(days=days)
        
        queryset = self.get_queryset().filter(date__gte=start_date)
        store_id = request.query_params.get('store')
        
        if store_id:
            queryset = queryset.filter(store_id=store_id)
        
        # Group by date and calculate averages
        daily_trends = queryset.values('date').annotate(
            avg_sales=Avg('total_sales'),
            avg_transactions=Avg('total_transactions'),
            avg_health_score=Avg('stock_health_score'),
            total_stores=Count('store', distinct=True)
        ).order_by('date')
        
        return Response({
            'period': f'Last {days} days',
            'trends': list(daily_trends),
        })


class StoreUserViewSet(viewsets.ModelViewSet):
    """ViewSet for Store User management"""
    queryset = StoreUser.objects.all()
    serializer_class = StoreUserSerializer
    permission_classes = [permissions.IsAuthenticated, IsStoreManagerOrReadOnly]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ['user__username', 'user__email', 'user__first_name', 'user__last_name']
    ordering_fields = ['user__username', 'created_at']
    ordering = ['user__username']

    def get_queryset(self):
        """Filter users based on permissions"""
        user = self.request.user
        if user.is_superuser:
            return StoreUser.objects.all()
        
        # Store managers can see users in their stores
        managed_stores = Store.objects.filter(manager=user)
        return StoreUser.objects.filter(assigned_stores__in=managed_stores).distinct()