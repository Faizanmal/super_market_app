"""
API ViewSets for Expiry & Shelf Management System.
Comprehensive views for batch tracking, receiving, audits, alerts, tasks, and analytics.
"""
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Sum, Q
from django.utils import timezone
from datetime import timedelta, datetime
from decimal import Decimal

from .models import (
    ProductBatch, ShelfLocation, BatchLocation, ReceivingLog,
    ShelfAudit, AuditItem, ExpiryAlert, Task, PhotoEvidence,
    NotificationPreference, WastageReport, WastageItem,
    ComplianceLog, SupplierPerformance, DynamicPricing,
    Product, Store
)
from .serializers import (
    ProductBatchSerializer, ShelfLocationSerializer, BatchLocationSerializer,
    ReceivingLogSerializer, ShelfAuditSerializer, AuditItemSerializer,
    ExpiryAlertSerializer, TaskSerializer, PhotoEvidenceSerializer,
    NotificationPreferenceSerializer, WastageReportSerializer, WastageItemSerializer,
    ComplianceLogSerializer, SupplierPerformanceSerializer, DynamicPricingSerializer,
    ExpiryAnalyticsSerializer, WastageAnalyticsSerializer,
    StoreComparisonSerializer, DashboardSummarySerializer
)


class ProductBatchViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Product Batches with GS1-128 support.
    """
    queryset = ProductBatch.objects.all()
    serializer_class = ProductBatchSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'store', 'supplier', 'product']
    search_fields = ['gtin', 'batch_number', 'product__name']
    ordering_fields = ['expiry_date', 'created_at', 'quantity']
    ordering = ['expiry_date']
    
    def get_queryset(self):
        """Filter by user's store if not head office."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Get batches expiring within specified days (default 30)."""
        days = int(request.query_params.get('days', 30))
        threshold_date = timezone.now().date() + timedelta(days=days)
        
        batches = self.get_queryset().filter(
            expiry_date__lte=threshold_date,
            expiry_date__gte=timezone.now().date(),
            status='active'
        )
        
        serializer = self.get_serializer(batches, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def expired(self, request):
        """Get all expired batches."""
        batches = self.get_queryset().filter(
            expiry_date__lt=timezone.now().date(),
            status='active'
        )
        
        serializer = self.get_serializer(batches, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_severity(self, request):
        """Get batches grouped by expiry severity."""
        today = timezone.now().date()
        
        critical = self.get_queryset().filter(
            expiry_date__lt=today + timedelta(days=7),
            expiry_date__gte=today,
            status='active'
        )
        
        high = self.get_queryset().filter(
            expiry_date__gte=today + timedelta(days=7),
            expiry_date__lt=today + timedelta(days=15),
            status='active'
        )
        
        medium = self.get_queryset().filter(
            expiry_date__gte=today + timedelta(days=15),
            expiry_date__lt=today + timedelta(days=30),
            status='active'
        )
        
        return Response({
            'critical': self.get_serializer(critical, many=True).data,
            'high': self.get_serializer(high, many=True).data,
            'medium': self.get_serializer(medium, many=True).data,
        })
    
    @action(detail=True, methods=['post'])
    def mark_expired(self, request, pk=None):
        """Mark a batch as expired."""
        batch = self.get_object()
        batch.status = 'expired'
        batch.save()
        
        return Response({
            'message': 'Batch marked as expired',
            'batch': self.get_serializer(batch).data
        })
    
    @action(detail=True, methods=['post'])
    def recall(self, request, pk=None):
        """Mark a batch as recalled."""
        batch = self.get_object()
        batch.status = 'recalled'
        batch.save()
        
        # Create compliance log
        ComplianceLog.objects.create(
            store=batch.store,
            log_type='batch_recall',
            title=f'Batch Recall: {batch.batch_number}',
            description=request.data.get('reason', 'Product recall'),
            logged_by=request.user
        )
        
        return Response({
            'message': 'Batch recalled and compliance log created',
            'batch': self.get_serializer(batch).data
        })


class ShelfLocationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Shelf Locations with QR code support.
    """
    queryset = ShelfLocation.objects.all()
    serializer_class = ShelfLocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['store', 'aisle', 'is_active']
    search_fields = ['location_code', 'aisle', 'section', 'description']
    ordering_fields = ['aisle', 'section', 'created_at']
    ordering = ['aisle', 'section']
    
    def get_queryset(self):
        """Filter by user's store if not head office."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    @action(detail=True, methods=['get'])
    def qr_code(self, request, pk=None):
        """Generate QR code for shelf location."""
        location = self.get_object()
        
        # Generate QR code if not exists
        if not location.qr_code:
            location.qr_code = f"SHELF_{location.store.code}_{location.location_code}"
            location.save()
        
        return Response({
            'qr_code': location.qr_code,
            'location': self.get_serializer(location).data
        })
     
    @action(detail=False, methods=['get'])
    def by_store(self, request):
        """Get locations grouped by store."""
        store_id = request.query_params.get('store_id')
        if store_id:
            locations = self.get_queryset().filter(store_id=store_id)
        else:
            locations = self.get_queryset()
        
        serializer = self.get_serializer(locations, many=True)
        return Response(serializer.data)


class BatchLocationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Batch Locations - tracking where batches are placed.
    """
    queryset = BatchLocation.objects.all()
    serializer_class = BatchLocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['batch', 'shelf_location', 'is_active']
    search_fields = ['batch__batch_number', 'shelf_location__location_code']
    ordering_fields = ['placed_at', 'quantity']
    ordering = ['-placed_at']
    
    def perform_create(self, serializer):
        """Set placed_by to current user."""
        serializer.save(placed_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def by_location(self, request):
        """Get all batches at a specific location."""
        location_id = request.query_params.get('location_id')
        if not location_id:
            return Response({'error': 'location_id is required'}, status=400)
        
        batch_locations = self.get_queryset().filter(
            shelf_location_id=location_id,
            is_active=True
        )
        
        serializer = self.get_serializer(batch_locations, many=True)
        return Response(serializer.data)


class ReceivingLogViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Receiving Logs - warehouse receiving activities.
    """
    queryset = ReceivingLog.objects.all()
    serializer_class = ReceivingLogSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'store', 'supplier', 'has_expiry_issues']
    search_fields = ['receipt_number', 'shipment_number', 'invoice_number']
    ordering_fields = ['received_date', 'total_value']
    ordering = ['-received_date']
    
    def get_queryset(self):
        """Filter by user's store if not head office."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Set received_by to current user and generate receipt number."""
        receipt_number = f"REC{datetime.now().strftime('%Y%m%d%H%M%S')}"
        serializer.save(
            received_by=self.request.user,
            receipt_number=receipt_number
        )
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a receiving log."""
        receiving_log = self.get_object()
        receiving_log.status = 'approved'
        receiving_log.approved_by = request.user
        receiving_log.save()
        
        return Response({
            'message': 'Receiving log approved',
            'log': self.get_serializer(receiving_log).data
        })
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a receiving log."""
        receiving_log = self.get_object()
        receiving_log.status = 'rejected'
        receiving_log.validation_notes = request.data.get('reason', 'Rejected')
        receiving_log.save()
        
        return Response({
            'message': 'Receiving log rejected',
            'log': self.get_serializer(receiving_log).data
        })


class ShelfAuditViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Shelf Audits - periodic inspections.
    """
    queryset = ShelfAudit.objects.all()
    serializer_class = ShelfAuditSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'store', 'scope', 'category']
    search_fields = ['audit_number', 'notes']
    ordering_fields = ['audit_date', 'items_checked']
    ordering = ['-audit_date']
    
    def get_queryset(self):
        """Filter by user's store if not head office."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Set auditor to current user and generate audit number."""
        audit_number = f"AUD{datetime.now().strftime('%Y%m%d%H%M%S')}"
        serializer.save(
            auditor=self.request.user,
            audit_number=audit_number
        )
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Complete an audit and calculate totals."""
        audit = self.get_object()
        audit.status = 'completed'
        
        # Calculate totals from audit items
        audit_items = audit.audit_items.all()
        audit.items_checked = audit_items.count()
        audit.items_expired = audit_items.filter(status='expired').count()
        audit.items_near_expiry = audit_items.filter(status='near_expiry').count()
        audit.items_damaged = audit_items.filter(status='damaged').count()
        audit.items_misplaced = audit_items.filter(status='misplaced').count()
        
        audit.save()
        
        return Response({
            'message': 'Audit completed',
            'audit': self.get_serializer(audit).data
        })


class AuditItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Audit Items - individual items checked during audit.
    """
    queryset = AuditItem.objects.all()
    serializer_class = AuditItemSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['audit', 'status', 'batch']
    search_fields = ['batch__batch_number', 'notes']
    ordering_fields = ['created_at']
    ordering = ['-created_at']


class ExpiryAlertViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Expiry Alerts - automated expiry notifications.
    """
    queryset = ExpiryAlert.objects.all()
    serializer_class = ExpiryAlertSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['severity', 'store', 'is_acknowledged', 'is_resolved']
    search_fields = ['batch__product__name', 'batch__batch_number']
    ordering_fields = ['days_until_expiry', 'created_at', 'estimated_loss']
    ordering = ['days_until_expiry']
    
    def get_queryset(self):
        """Filter by user's store if not head office."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        """Acknowledge an expiry alert."""
        alert = self.get_object()
        alert.is_acknowledged = True
        alert.acknowledged_by = request.user
        alert.acknowledged_at = timezone.now()
        alert.save()
        
        return Response({
            'message': 'Alert acknowledged',
            'alert': self.get_serializer(alert).data
        })
    
    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Resolve an expiry alert with action taken."""
        alert = self.get_object()
        alert.is_resolved = True
        alert.resolved_by = request.user
        alert.resolved_at = timezone.now()
        alert.resolution_action = request.data.get('action')
        alert.resolution_notes = request.data.get('notes')
        alert.save()
        
        return Response({
            'message': 'Alert resolved',
            'alert': self.get_serializer(alert).data
        })
    
    @action(detail=False, methods=['get'])
    def critical(self, request):
        """Get critical alerts (< 7 days)."""
        alerts = self.get_queryset().filter(
            severity='critical',
            is_resolved=False
        )
        
        serializer = self.get_serializer(alerts, many=True)
        return Response(serializer.data)


class TaskViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Tasks - staff task management.
    """
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'priority', 'task_type', 'assigned_to', 'store']
    search_fields = ['title', 'description']
    ordering_fields = ['due_date', 'priority', 'created_at']
    ordering = ['due_date', '-priority']
    
    def get_queryset(self):
        """Filter by user's store and assignments."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.role in ['store_manager', 'auditor']:
            return queryset.filter(store=user.store)
        else:
            # Regular staff see only their assigned tasks
            return queryset.filter(assigned_to=user)
    
    def perform_create(self, serializer):
        """Set assigned_by to current user."""
        serializer.save(assigned_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Complete a task with notes and photo."""
        task = self.get_object()
        task.status = 'completed'
        task.completed_at = timezone.now()
        task.completion_notes = request.data.get('notes')
        
        # Handle photo upload
        if 'photo' in request.FILES:
            task.completion_photo = request.FILES['photo']
        
        task.save()
        
        return Response({
            'message': 'Task completed',
            'task': self.get_serializer(task).data
        })
    
    @action(detail=False, methods=['get'])
    def my_tasks(self, request):
        """Get tasks assigned to current user."""
        tasks = self.get_queryset().filter(assigned_to=request.user)
        serializer = self.get_serializer(tasks, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def urgent(self, request):
        """Get urgent tasks."""
        tasks = self.get_queryset().filter(
            priority='urgent',
            status__in=['pending', 'in_progress']
        )
        serializer = self.get_serializer(tasks, many=True)
        return Response(serializer.data)
    serializer_class = ShelfLocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['store', 'is_active']
    search_fields = ['location_code', 'aisle', 'section', 'position']
    ordering_fields = ['aisle', 'section', 'created_at']
    ordering = ['aisle', 'section']
    
    @action(detail=True, methods=['get'])
    def batches(self, request, pk=None):
        """Get all batches at this location."""
        location = self.get_object()
        batch_locations = BatchLocation.objects.filter(
            shelf_location=location,
            is_active=True
        )
        
        batches_data = []
        for bl in batch_locations:
            batch_data = ProductBatchSerializer(bl.batch).data
            batch_data['quantity_at_location'] = bl.quantity
            batch_data['placed_at'] = bl.placed_at
            batches_data.append(batch_data)
        
        return Response(batches_data)
    
    @action(detail=True, methods=['post'])
    def generate_qr(self, request, pk=None):
        """Generate QR code for this location."""
        location = self.get_object()
        
        # QR code would be generated here (using qrcode library)
        # For now, just set the QR code field
        if not location.qr_code:
            location.qr_code = f"QR-{location.location_code}"
            location.save()
        
        return Response({
            'message': 'QR code generated',
            'qr_code': location.qr_code,
            'location': self.get_serializer(location).data
        })


class BatchLocationMappingViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Batch-Location mappings.
    """
    queryset = BatchLocation.objects.all()
    serializer_class = BatchLocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['batch', 'shelf_location', 'is_active']
    ordering_fields = ['placed_at', 'quantity']
    ordering = ['-placed_at']
    
    def perform_create(self, serializer):
        """Auto-set placed_by."""
        serializer.save(placed_by=self.request.user)


class ReceivingLogIntakeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Receiving Logs (warehouse intake).
    """
    queryset = ReceivingLog.objects.all()
    serializer_class = ReceivingLogSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'store', 'supplier']
    search_fields = ['receipt_number', 'shipment_number', 'invoice_number']
    ordering_fields = ['received_date', 'total_value']
    ordering = ['-received_date']
    
    def get_queryset(self):
        """Filter by user's store."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Auto-set received_by and store."""
        serializer.save(
            received_by=self.request.user,
            store=self.request.user.store if not self.request.data.get('store') else None
        )
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve receiving log."""
        log = self.get_object()
        
        if not request.user.can_manage_staff:
            return Response(
                {'error': 'You do not have permission to approve receiving logs'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        log.status = 'approved'
        log.approved_by = request.user
        log.save()
        
        return Response({
            'message': 'Receiving log approved',
            'log': self.get_serializer(log).data
        })
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject receiving log."""
        log = self.get_object()
        
        if not request.user.can_manage_staff:
            return Response(
                {'error': 'You do not have permission to reject receiving logs'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        log.status = 'rejected'
        log.validation_notes = request.data.get('reason', '')
        log.save()
        
        return Response({
            'message': 'Receiving log rejected',
            'log': self.get_serializer(log).data
        })


class ShelfAuditManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Shelf Audits.
    """
    queryset = ShelfAudit.objects.all()
    serializer_class = ShelfAuditSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'store', 'scope', 'category']
    search_fields = ['audit_number']
    ordering_fields = ['audit_date', 'items_checked']
    ordering = ['-audit_date']
    
    def get_queryset(self):
        """Filter by user's store or audits assigned to user."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.role == 'auditor':
            return queryset.filter(Q(store=user.store) | Q(auditor=user))
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Auto-set auditor and store."""
        serializer.save(
            auditor=self.request.user,
            store=self.request.user.store if not self.request.data.get('store') else None
        )
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark audit as completed."""
        audit = self.get_object()
        audit.status = 'completed'
        audit.save()
        
        # Generate follow-up tasks for flagged items
        flagged_items = audit.audit_items.exclude(status='ok')
        for item in flagged_items:
            Task.objects.create(
                title=f'Follow-up: {item.batch.product.name}',
                description=f'Address {item.status} issue found in audit {audit.audit_number}',
                assigned_to=request.user,
                assigned_by=request.user,
                store=audit.store,
                task_type='expiry_review' if item.status in ['expired', 'near_expiry'] else 'other',
                priority='urgent' if item.status == 'expired' else 'high',
                batch=item.batch,
                due_date=timezone.now() + timedelta(days=1)
            )
        
        return Response({
            'message': f'Audit completed. {flagged_items.count()} follow-up tasks created.',
            'audit': self.get_serializer(audit).data
        })


class AuditItemManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Audit Items.
    """
    queryset = AuditItem.objects.all()
    serializer_class = AuditItemSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['audit', 'status']
    ordering_fields = ['created_at']
    ordering = ['-created_at']


class ExpiryAlertManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Expiry Alerts.
    """
    queryset = ExpiryAlert.objects.all()
    serializer_class = ExpiryAlertSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['severity', 'is_acknowledged', 'is_resolved', 'store']
    ordering_fields = ['days_until_expiry', 'created_at', 'estimated_loss']
    ordering = ['days_until_expiry']
    
    def get_queryset(self):
        """Filter by user's store."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    @action(detail=False, methods=['get'])
    def critical(self, request):
        """Get all critical alerts."""
        alerts = self.get_queryset().filter(
            severity='critical',
            is_resolved=False
        )
        serializer = self.get_serializer(alerts, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def unresolved(self, request):
        """Get all unresolved alerts."""
        alerts = self.get_queryset().filter(is_resolved=False)
        serializer = self.get_serializer(alerts, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        """Acknowledge an alert."""
        alert = self.get_object()
        alert.is_acknowledged = True
        alert.acknowledged_by = request.user
        alert.acknowledged_at = timezone.now()
        alert.save()
        
        return Response({
            'message': 'Alert acknowledged',
            'alert': self.get_serializer(alert).data
        })
    
    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Resolve an alert."""
        alert = self.get_object()
        alert.is_resolved = True
        alert.resolved_by = request.user
        alert.resolved_at = timezone.now()
        alert.resolution_action = request.data.get('action')
        alert.resolution_notes = request.data.get('notes', '')
        alert.save()
        
        return Response({
            'message': 'Alert resolved',
            'alert': self.get_serializer(alert).data
        })


class TaskManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Tasks.
    """
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'priority', 'task_type', 'assigned_to', 'store']
    search_fields = ['title', 'description']
    ordering_fields = ['due_date', 'priority', 'created_at']
    ordering = ['due_date', '-priority']
    
    def get_queryset(self):
        """Filter by user's store or assigned tasks."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.role in ['store_manager', 'auditor']:
            return queryset.filter(Q(store=user.store) | Q(assigned_to=user))
        else:
            return queryset.filter(assigned_to=user)
    
    @action(detail=False, methods=['get'])
    def my_tasks(self, request):
        """Get tasks assigned to current user."""
        tasks = self.get_queryset().filter(assigned_to=request.user, status__in=['pending', 'in_progress'])
        serializer = self.get_serializer(tasks, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def overdue(self, request):
        """Get overdue tasks."""
        tasks = self.get_queryset().filter(
            due_date__lt=timezone.now(),
            status__in=['pending', 'in_progress']
        )
        serializer = self.get_serializer(tasks, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """Mark task as in progress."""
        task = self.get_object()
        task.status = 'in_progress'
        task.save()
        
        return Response({
            'message': 'Task started',
            'task': self.get_serializer(task).data
        })
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark task as completed."""
        task = self.get_object()
        task.status = 'completed'
        task.completed_at = timezone.now()
        task.completion_notes = request.data.get('notes', '')
        
        # Handle photo upload if provided
        if 'photo' in request.FILES:
            task.completion_photo = request.FILES['photo']
        
        task.save()
        
        return Response({
            'message': 'Task completed',
            'task': self.get_serializer(task).data
        })


class PhotoEvidenceViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Photo Evidence.
    """
    queryset = PhotoEvidence.objects.all()
    serializer_class = PhotoEvidenceSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['photo_type', 'store', 'batch', 'audit', 'task']
    ordering_fields = ['uploaded_at']
    ordering = ['-uploaded_at']
    
    def get_queryset(self):
        """Filter by user's store."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Auto-set uploaded_by and store."""
        serializer.save(
            uploaded_by=self.request.user,
            store=self.request.user.store if not self.request.data.get('store') else None
        )


class WastageReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Wastage Reports.
    """
    queryset = WastageReport.objects.all()
    serializer_class = WastageReportSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'store']
    search_fields = ['report_number']
    ordering_fields = ['report_date', 'total_monetary_loss']
    ordering = ['-report_date']
    
    def get_queryset(self):
        """Filter by user's store."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Auto-set prepared_by and store."""
        serializer.save(
            prepared_by=self.request.user,
            store=self.request.user.store if not self.request.data.get('store') else None
        )


class WastageItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Wastage Items.
    """
    queryset = WastageItem.objects.all()
    serializer_class = WastageItemSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['wastage_report', 'reason']
    search_fields = ['product_name', 'batch_number']
    ordering_fields = ['created_at', 'total_loss']
    ordering = ['-created_at']


class ComplianceLogViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Compliance Logs.
    """
    queryset = ComplianceLog.objects.all()
    serializer_class = ComplianceLogSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['log_type', 'outcome', 'store', 'action_completed']
    search_fields = ['title', 'description', 'inspector_name']
    ordering_fields = ['log_date', 'action_deadline']
    ordering = ['-log_date']
    
    def get_queryset(self):
        """Filter by user's store."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Auto-set logged_by and store."""
        serializer.save(
            logged_by=self.request.user,
            store=self.request.user.store if not self.request.data.get('store') else None
        )


class SupplierPerformanceViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Supplier Performance tracking.
    """
    queryset = SupplierPerformance.objects.all()
    serializer_class = SupplierPerformanceSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['supplier', 'store', 'performance_status']
    search_fields = ['supplier__name']
    ordering_fields = ['period_end', 'overall_score']
    ordering = ['-period_end']
    
    def get_queryset(self):
        """Filter by user's store."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    @action(detail=True, methods=['post'])
    def recalculate(self, request, pk=None):
        """Recalculate supplier performance scores."""
        performance = self.get_object()
        performance.calculate_scores()
        
        return Response({
            'message': 'Performance scores recalculated',
            'performance': self.get_serializer(performance).data
        })


class DynamicPricingViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Dynamic Pricing - automated discounts for near-expiry items.
    """
    queryset = DynamicPricing.objects.all()
    serializer_class = DynamicPricingSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'reason', 'store', 'is_active']
    search_fields = ['batch__product__name', 'batch__batch_number']
    ordering_fields = ['created_at', 'discount_percentage', 'effective_from']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Filter by user's store."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Auto-set created_by and store."""
        serializer.save(
            created_by=self.request.user,
            store=self.request.user.store if not self.request.data.get('store') else None
        )
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve dynamic pricing."""
        pricing = self.get_object()
        pricing.status = 'approved'
        pricing.approved_by = request.user
        pricing.save()
        
        return Response({
            'message': 'Dynamic pricing approved',
            'pricing': self.get_serializer(pricing).data
        })
    
    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        """Activate dynamic pricing."""
        pricing = self.get_object()
        if pricing.status == 'approved':
            pricing.status = 'active'
            pricing.is_active = True
            pricing.save()
            
            return Response({
                'message': 'Dynamic pricing activated',
                'pricing': self.get_serializer(pricing).data
            })
        
        return Response(
            {'error': 'Pricing must be approved before activation'},
            status=status.HTTP_400_BAD_REQUEST
        )


class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Notification Preferences.
    """
    queryset = NotificationPreference.objects.all()
    serializer_class = NotificationPreferenceSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Users can only access their own preferences."""
        return self.queryset.filter(user=self.request.user)
    
    def get_object(self):
        """Get or create preferences for current user."""
        try:
            return NotificationPreference.objects.get(user=self.request.user)
        except NotificationPreference.DoesNotExist:
            return NotificationPreference.objects.create(user=self.request.user)


# ==================== ANALYTICS VIEWSETS ====================

class ExpiryAnalyticsViewSet(viewsets.ViewSet):
    """
    Analytics for expiry management.
    """
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def dashboard_summary(self, request):
        """Get comprehensive dashboard summary."""
        user = request.user
        
        if user.role == 'head_office':
            # Head office sees all stores
            store_filter = {}
        else:
            # Store staff see only their store
            store_filter = {'store': user.store}
        
        # Get counts
        total_batches = ProductBatch.objects.filter(**store_filter, status='active').count()
        
        today = timezone.now().date()
        critical_alerts = ExpiryAlert.objects.filter(
            **store_filter,
            severity='critical',
            is_resolved=False
        ).count()
        
        pending_tasks = Task.objects.filter(
            **store_filter,
            status__in=['pending', 'in_progress']
        ).count()
        
        # Wastage this month
        current_month = today.replace(day=1)
        wastage_this_month = WastageReport.objects.filter(
            **store_filter,
            report_date__gte=current_month
        ).aggregate(
            total=Sum('total_monetary_loss')
        )['total'] or Decimal('0')
        
        # Revenue recovered from dynamic pricing
        revenue_recovered = DynamicPricing.objects.filter(
            **store_filter,
            status='active',
            created_at__gte=current_month
        ).aggregate(
            total=Sum('revenue_generated')
        )['total'] or Decimal('0')
        
        # Top expiring products
        top_expiring = ProductBatch.objects.filter(
            **store_filter,
            status='active',
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=7)
        ).select_related('product').order_by('expiry_date')[:5]
        
        # Recent audits
        recent_audits = ShelfAudit.objects.filter(
            **store_filter
        ).order_by('-audit_date')[:5]
        
        summary_data = {
            'total_products': Product.objects.filter(
                created_by=user if user.role != 'head_office' else None,
                is_deleted=False
            ).count(),
            'total_batches': total_batches,
            'critical_alerts': critical_alerts,
            'pending_tasks': pending_tasks,
            'wastage_this_month': wastage_this_month,
            'revenue_recovered': revenue_recovered,
            'top_expiring': [
                {
                    'product_name': batch.product.name,
                    'batch_number': batch.batch_number,
                    'expiry_date': batch.expiry_date,
                    'days_until_expiry': batch.days_until_expiry,
                    'quantity': batch.quantity
                }
                for batch in top_expiring
            ],
            'recent_audits': [
                {
                    'audit_number': audit.audit_number,
                    'audit_date': audit.audit_date,
                    'scope': audit.scope,
                    'items_checked': audit.items_checked,
                    'items_expired': audit.items_expired
                }
                for audit in recent_audits
            ]
        }
        
        serializer = DashboardSummarySerializer(summary_data)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def submit(self, request, pk=None):
        """Submit report for review."""
        report = self.get_object()
        report.status = 'submitted'
        report.save()
        
        return Response({
            'message': 'Wastage report submitted for review',
            'report': self.get_serializer(report).data
        })
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve wastage report."""
        report = self.get_object()
        
        if not request.user.can_manage_staff:
            return Response(
                {'error': 'You do not have permission to approve reports'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        report.status = 'approved'
        report.approved_by = request.user
        report.save()
        
        return Response({
            'message': 'Wastage report approved',
            'report': self.get_serializer(report).data
        })


class DynamicPricingManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Dynamic Pricing.
    """
    queryset = DynamicPricing.objects.all()
    serializer_class = DynamicPricingSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['status', 'reason', 'is_active', 'store']
    ordering_fields = ['created_at', 'discount_percentage']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Filter by user's store."""
        queryset = super().get_queryset()
        user = self.request.user
        
        if user.role == 'head_office':
            return queryset
        elif user.store:
            return queryset.filter(store=user.store)
        return queryset.none()
    
    def perform_create(self, serializer):
        """Auto-set created_by and store."""
        serializer.save(
            created_by=self.request.user,
            store=self.request.user.store if not self.request.data.get('store') else None
        )
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve dynamic pricing."""
        pricing = self.get_object()
        
        if not request.user.can_manage_staff:
            return Response(
                {'error': 'You do not have permission to approve pricing'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        pricing.status = 'approved'
        pricing.approved_by = request.user
        pricing.save()
        
        return Response({
            'message': 'Dynamic pricing approved',
            'pricing': self.get_serializer(pricing).data
        })
    
    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        """Activate approved pricing."""
        pricing = self.get_object()
        
        if pricing.status != 'approved':
            return Response(
                {'error': 'Pricing must be approved before activation'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        pricing.is_active = True
        pricing.status = 'active'
        pricing.save()
        
        return Response({
            'message': 'Dynamic pricing activated',
            'pricing': self.get_serializer(pricing).data
        })


class SupplierPerformanceTrackingViewSet(viewsets.ModelViewSet):
    """
    ViewSet for Supplier Performance tracking.
    """
    queryset = SupplierPerformance.objects.all()
    serializer_class = SupplierPerformanceSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['supplier', 'store', 'performance_status']
    ordering_fields = ['overall_score', 'calculated_at']
    ordering = ['-calculated_at']
    
    @action(detail=True, methods=['post'])
    def calculate(self, request, pk=None):
        """Calculate performance scores."""
        performance = self.get_object()
        performance.calculate_scores()
        
        return Response({
            'message': 'Performance scores calculated',
            'performance': self.get_serializer(performance).data
        })


# ==================== ANALYTICS VIEWS ====================

class AnalyticsViewSet(viewsets.ViewSet):
    """
    ViewSet for analytics and reporting endpoints.
    """
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Get dashboard summary data."""
        user = request.user
        store_filter = Q(store=user.store) if user.store and user.role != 'head_office' else Q()
        
        # Get counts
        total_products = Product.objects.filter(store_filter, is_active=True).count()
        total_batches = ProductBatch.objects.filter(store_filter, status='active').count()
        critical_alerts = ExpiryAlert.objects.filter(
            store_filter,
            severity='critical',
            is_resolved=False
        ).count()
        pending_tasks = Task.objects.filter(
            store_filter,
            status__in=['pending', 'in_progress']
        ).count()
        
        # Wastage this month
        month_start = timezone.now().replace(day=1)
        wastage_this_month = WastageReport.objects.filter(
            store_filter,
            report_date__gte=month_start
        ).aggregate(total=Sum('total_monetary_loss'))['total'] or Decimal('0.00')
        
        # Revenue recovered from dynamic pricing
        revenue_recovered = DynamicPricing.objects.filter(
            store_filter,
            status='active'
        ).aggregate(total=Sum('revenue_generated'))['total'] or Decimal('0.00')
        
        # Top expiring products
        today = timezone.now().date()
        top_expiring = ProductBatch.objects.filter(
            store_filter,
            expiry_date__gte=today,
            expiry_date__lte=today + timedelta(days=7),
            status='active'
        ).select_related('product')[:10]
        
        # Recent audits
        recent_audits = ShelfAudit.objects.filter(
            store_filter
        ).order_by('-audit_date')[:5]
        
        data = {
            'total_products': total_products,
            'total_batches': total_batches,
            'critical_alerts': critical_alerts,
            'pending_tasks': pending_tasks,
            'wastage_this_month': wastage_this_month,
            'revenue_recovered': revenue_recovered,
            'top_expiring': ProductBatchSerializer(top_expiring, many=True).data,
            'recent_audits': ShelfAuditSerializer(recent_audits, many=True).data,
        }
        
        serializer = DashboardSummarySerializer(data)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def expiry_analytics(self, request):
        """Get expiry analytics data."""
        user = request.user
        store_filter = Q(store=user.store) if user.store and user.role != 'head_office' else Q()
        today = timezone.now().date()
        
        total_batches = ProductBatch.objects.filter(store_filter, status='active').count()
        
        expiring_critical = ProductBatch.objects.filter(
            store_filter,
            expiry_date__lt=today + timedelta(days=7),
            expiry_date__gte=today,
            status='active'
        ).count()
        
        expiring_high = ProductBatch.objects.filter(
            store_filter,
            expiry_date__gte=today + timedelta(days=7),
            expiry_date__lt=today + timedelta(days=15),
            status='active'
        ).count()
        
        expiring_medium = ProductBatch.objects.filter(
            store_filter,
            expiry_date__gte=today + timedelta(days=15),
            expiry_date__lt=today + timedelta(days=30),
            status='active'
        ).count()
        
        # Total at-risk value
        at_risk_batches = ProductBatch.objects.filter(
            store_filter,
            expiry_date__lte=today + timedelta(days=30),
            expiry_date__gte=today,
            status='active'
        )
        
        total_at_risk_value = sum([batch.total_value for batch in at_risk_batches])
        
        # Top expiring products
        top_expiring = at_risk_batches.select_related('product').order_by('expiry_date')[:20]
        
        data = {
            'total_batches': total_batches,
            'expiring_critical': expiring_critical,
            'expiring_high': expiring_high,
            'expiring_medium': expiring_medium,
            'total_at_risk_value': total_at_risk_value,
            'top_expiring_products': ProductBatchSerializer(top_expiring, many=True).data,
        }
        
        serializer = ExpiryAnalyticsSerializer(data)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def wastage_analytics(self, request):
        """Get wastage analytics data."""
        user = request.user
        store_filter = Q(store=user.store) if user.store and user.role != 'head_office' else Q()
        
        # Get date range from request (default to last 30 days)
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now().date() - timedelta(days=days)
        
        reports = WastageReport.objects.filter(
            store_filter,
            report_date__gte=start_date
        )
        
        total_wastage = reports.aggregate(total=Sum('total_items_wasted'))['total'] or 0
        total_loss = reports.aggregate(total=Sum('total_monetary_loss'))['total'] or Decimal('0.00')
        
        # Wastage by reason
        items = WastageItem.objects.filter(wastage_report__in=reports)
        wastage_by_reason = {}
        for item in items:
            reason = item.reason
            wastage_by_reason[reason] = wastage_by_reason.get(reason, 0) + item.quantity_wasted
        
        # Wastage trend (daily)
        wastage_trend = []
        for i in range(days):
            date = start_date + timedelta(days=i)
            day_wastage = items.filter(created_at__date=date).aggregate(
                total=Sum('quantity_wasted')
            )['total'] or 0
            wastage_trend.append({
                'date': date.isoformat(),
                'wastage': day_wastage
            })
        
        data = {
            'total_wastage': total_wastage,
            'total_monetary_loss': total_loss,
            'wastage_by_reason': wastage_by_reason,
            'wastage_trend': wastage_trend,
        }
        
        serializer = WastageAnalyticsSerializer(data)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def store_comparison(self, request):
        """Compare performance across stores (Head Office only)."""
        if request.user.role != 'head_office':
            return Response(
                {'error': 'This endpoint is only available to head office users'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        stores = Store.objects.filter(is_active=True)
        comparison_data = []
        
        for store in stores:
            # Wastage
            wastage = WastageReport.objects.filter(store=store).aggregate(
                total_items=Sum('total_items_wasted'),
                total_loss=Sum('total_monetary_loss')
            )
            
            # Alerts
            alerts = ExpiryAlert.objects.filter(store=store, is_resolved=False).count()
            
            # Task completion
            total_tasks = Task.objects.filter(store=store).count()
            completed_tasks = Task.objects.filter(store=store, status='completed').count()
            completion_rate = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
            
            comparison_data.append({
                'store_name': store.name,
                'total_wastage': wastage['total_items'] or 0,
                'total_loss': wastage['total_loss'] or Decimal('0.00'),
                'expiry_alerts': alerts,
                'task_completion_rate': completion_rate,
            })
        
        serializer = StoreComparisonSerializer(comparison_data, many=True)
        return Response(serializer.data)
