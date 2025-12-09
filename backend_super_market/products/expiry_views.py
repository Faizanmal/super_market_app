"""
API views for expiry and shelf management system.
Handles ProductBatch, ShelfLocation, ReceivingLog, ShelfAudit, ExpiryAlert, Task, and PhotoEvidence.
"""
from rest_framework import viewsets, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from datetime import timedelta
 
from .models import (
    ProductBatch, ShelfLocation, BatchLocation, ReceivingLog,
    ShelfAudit, ExpiryAlert, Task, PhotoEvidence
)
from .serializers import (
    ProductBatchSerializer, ShelfLocationSerializer, BatchLocationSerializer,
    ReceivingLogSerializer, ShelfAuditSerializer, ExpiryAlertSerializer, TaskSerializer, PhotoEvidenceSerializer
)


class ProductBatchViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing product batches.
    Supports GS1-128 barcode data and expiry tracking.
    """
    serializer_class = ProductBatchSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'store', 'product', 'supplier']
    search_fields = ['gtin', 'batch_number', 'product__name', 'shipment_number']
    ordering_fields = ['expiry_date', 'created_at', 'quantity']
    ordering = ['expiry_date']
    
    def get_queryset(self):
        """Return batches based on user's store or all if head office."""
        user = self.request.user
        if user.role == 'head_office':
            return ProductBatch.objects.all().select_related('product', 'supplier', 'store')
        return ProductBatch.objects.filter(store=user.store).select_related('product', 'supplier', 'store')
    
    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """Get batches expiring within specified days (default 30)."""
        days = int(request.query_params.get('days', 30))
        target_date = timezone.now().date() + timedelta(days=days)
        
        batches = self.get_queryset().filter(
            expiry_date__lte=target_date,
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
    def by_status(self, request):
        """Get batches grouped by expiry status."""
        queryset = self.get_queryset().filter(status='active')
        today = timezone.now().date()
        
        result = {
            'fresh': [],
            'warning': [],
            'critical': [],
            'expired': []
        }
        
        for batch in queryset:
            days = (batch.expiry_date - today).days
            if days < 0:
                result['expired'].append(self.get_serializer(batch).data)
            elif days <= 7:
                result['critical'].append(self.get_serializer(batch).data)
            elif days <= 30:
                result['warning'].append(self.get_serializer(batch).data)
            else:
                result['fresh'].append(self.get_serializer(batch).data)
        
        return Response(result)


class ShelfLocationViewSet(viewsets.ModelViewSet):
    """ViewSet for managing shelf locations."""
    
    serializer_class = ShelfLocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['store', 'is_active', 'aisle']
    search_fields = ['location_code', 'aisle', 'section', 'description']
    
    def get_queryset(self):
        """Return locations for user's store or all if head office."""
        user = self.request.user
        if user.role == 'head_office':
            return ShelfLocation.objects.all()
        return ShelfLocation.objects.filter(store=user.store)


class BatchLocationViewSet(viewsets.ModelViewSet):
    """ViewSet for managing batch locations (batch-to-shelf mapping)."""
    
    serializer_class = BatchLocationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['batch', 'shelf_location', 'is_active']
    
    def get_queryset(self):
        """Return batch locations for user's store."""
        user = self.request.user
        if user.role == 'head_office':
            return BatchLocation.objects.all()
        return BatchLocation.objects.filter(batch__store=user.store)


class ReceivingLogViewSet(viewsets.ModelViewSet):
    """ViewSet for managing receiving logs."""
    
    serializer_class = ReceivingLogSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'store', 'supplier', 'has_expiry_issues']
    search_fields = ['receipt_number', 'shipment_number', 'invoice_number', 'purchase_order']
    ordering_fields = ['received_date', 'total_value']
    ordering = ['-received_date']
    
    def get_queryset(self):
        """Return receiving logs for user's store."""
        user = self.request.user
        if user.role == 'head_office':
            return ReceivingLog.objects.all()
        return ReceivingLog.objects.filter(store=user.store)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a receiving log."""
        log = self.get_object()
        log.status = 'approved'
        log.approved_by = request.user
        log.save()
        return Response({'status': 'approved'})
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a receiving log."""
        log = self.get_object()
        log.status = 'rejected'
        log.validation_notes = request.data.get('notes', '')
        log.save()
        return Response({'status': 'rejected'})


class ShelfAuditViewSet(viewsets.ModelViewSet):
    """ViewSet for managing shelf audits."""
    
    serializer_class = ShelfAuditSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'scope', 'store', 'category']
    search_fields = ['audit_number', 'notes']
    ordering_fields = ['audit_date']
    ordering = ['-audit_date']
    
    def get_queryset(self):
        """Return audits for user's store."""
        user = self.request.user
        if user.role == 'head_office' or user.role == 'auditor':
            return ShelfAudit.objects.all()
        return ShelfAudit.objects.filter(store=user.store)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark audit as completed."""
        audit = self.get_object()
        audit.status = 'completed'
        audit.save()
        return Response({'status': 'completed'})


class ExpiryAlertViewSet(viewsets.ModelViewSet):
    """ViewSet for managing expiry alerts."""
    
    serializer_class = ExpiryAlertSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['severity', 'is_acknowledged', 'is_resolved', 'store']
    ordering_fields = ['days_until_expiry', 'created_at', 'severity']
    ordering = ['days_until_expiry']
    
    def get_queryset(self):
        """Return alerts for user's store."""
        user = self.request.user
        if user.role == 'head_office':
            return ExpiryAlert.objects.all()
        return ExpiryAlert.objects.filter(store=user.store)
    
    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        """Acknowledge an alert."""
        alert = self.get_object()
        alert.is_acknowledged = True
        alert.acknowledged_by = request.user
        alert.acknowledged_at = timezone.now()
        alert.save()
        return Response({'status': 'acknowledged'})
    
    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Resolve an alert."""
        alert = self.get_object()
        alert.is_resolved = True
        alert.resolved_by = request.user
        alert.resolved_at = timezone.now()
        alert.resolution_action = request.data.get('action')
        alert.resolution_notes = request.data.get('notes')
        alert.save()
        return Response({'status': 'resolved'})
    
    @action(detail=False, methods=['get'])
    def critical(self, request):
        """Get all critical alerts (< 7 days)."""
        alerts = self.get_queryset().filter(
            severity='critical',
            is_resolved=False
        )
        serializer = self.get_serializer(alerts, many=True)
        return Response(serializer.data)


class TaskViewSet(viewsets.ModelViewSet):
    """ViewSet for managing tasks."""
    
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['task_type', 'priority', 'status', 'store', 'assigned_to']
    ordering_fields = ['due_date', 'priority', 'created_at']
    ordering = ['due_date', '-priority']
    
    def get_queryset(self):
        """Return tasks for user or all if manager/head office."""
        user = self.request.user
        if user.role in ['head_office', 'store_manager']:
            if user.role == 'head_office':
                return Task.objects.all()
            return Task.objects.filter(store=user.store)
        return Task.objects.filter(assigned_to=user)
    
    @action(detail=False, methods=['get'])
    def my_tasks(self, request):
        """Get tasks assigned to current user."""
        tasks = Task.objects.filter(assigned_to=request.user, status__in=['pending', 'in_progress'])
        serializer = self.get_serializer(tasks, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """Mark task as in progress."""
        task = self.get_object()
        task.status = 'in_progress'
        task.save()
        return Response({'status': 'in_progress'})
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark task as completed."""
        task = self.get_object()
        task.status = 'completed'
        task.completed_at = timezone.now()
        task.completion_notes = request.data.get('notes')
        task.save()
        return Response({'status': 'completed'})


class PhotoEvidenceViewSet(viewsets.ModelViewSet):
    """ViewSet for managing photo evidence."""
    
    serializer_class = PhotoEvidenceSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['photo_type', 'store', 'batch', 'receiving_log', 'audit', 'task']
    ordering_fields = ['uploaded_at']
    ordering = ['-uploaded_at']
    
    def get_queryset(self):
        """Return photos for user's store."""
        user = self.request.user
        if user.role == 'head_office':
            return PhotoEvidence.objects.all()
        return PhotoEvidence.objects.filter(store=user.store)
