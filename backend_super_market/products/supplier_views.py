"""
ViewSets for Enhanced Supplier Management System
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import timedelta

from .models import (
    Supplier, SupplierPerformance, SupplierContract
)
from .supplier_models import (
    AutomatedReorder, SupplierCommunication
)
from .advanced_serializers import (
    EnhancedSupplierSerializer, SupplierPerformanceSerializer,
    SupplierContractSerializer, AutomatedReorderSerializer,
    SupplierCommunicationSerializer
)


class EnhancedSupplierViewSet(viewsets.ModelViewSet):
    """ViewSet for Enhanced Supplier Management"""
    serializer_class = EnhancedSupplierSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Supplier.objects.all()
        
        # Filters
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        
        is_preferred = self.request.query_params.get('is_preferred')
        if is_preferred is not None:
            queryset = queryset.filter(is_preferred=is_preferred.lower() == 'true')
        
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(name__icontains=search)
        
        return queryset.order_by('-is_preferred', 'name')
    
    @action(detail=True, methods=['get'])
    def performance(self, request, pk=None):
        """Get supplier performance metrics"""
        supplier = self.get_object()
        try:
            performance = SupplierPerformance.objects.filter(supplier=supplier).latest('evaluation_date')
            serializer = SupplierPerformanceSerializer(performance)
            return Response(serializer.data)
        except SupplierPerformance.DoesNotExist:
            return Response({'detail': 'No performance data available'}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=True, methods=['get'])
    def contracts(self, request, pk=None):
        """Get supplier contracts"""
        supplier = self.get_object()
        contracts = SupplierContract.objects.filter(supplier=supplier)
        serializer = SupplierContractSerializer(contracts, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        """Send message to supplier"""
        supplier = self.get_object()
        
        SupplierCommunication.objects.create(
            supplier=supplier,
            communication_type=request.data.get('type', 'email'),
            subject=request.data.get('subject'),
            message=request.data.get('message'),
            created_by=request.user
        )
        
        return Response({'status': 'Message sent'}, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['get'])
    def communications(self, request, pk=None):
        """Get communication history with supplier"""
        supplier = self.get_object()
        communications = SupplierCommunication.objects.filter(supplier=supplier).order_by('-created_at')
        serializer = SupplierCommunicationSerializer(communications, many=True)
        return Response(serializer.data)


class SupplierPerformanceViewSet(viewsets.ModelViewSet):
    """ViewSet for Supplier Performance Management"""
    serializer_class = SupplierPerformanceSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = SupplierPerformance.objects.all()
        
        supplier_id = self.request.query_params.get('supplier_id')
        if supplier_id:
            queryset = queryset.filter(supplier_id=supplier_id)
        
        period = self.request.query_params.get('period')
        if period:
            days = {'week': 7, 'month': 30, 'quarter': 90, 'year': 365}.get(period, 30)
            start_date = timezone.now() - timedelta(days=days)
            queryset = queryset.filter(evaluation_date__gte=start_date)
        
        return queryset.order_by('-evaluation_date')
    
    @action(detail=False, methods=['get'])
    def top_performers(self, request):
        """Get top performing suppliers"""
        limit = int(request.query_params.get('limit', 10))
        performances = self.get_queryset().order_by('-overall_score')[:limit]
        serializer = self.get_serializer(performances, many=True)
        return Response(serializer.data)


class SupplierContractViewSet(viewsets.ModelViewSet):
    """ViewSet for Supplier Contract Management"""
    serializer_class = SupplierContractSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = SupplierContract.objects.all()
        
        supplier_id = self.request.query_params.get('supplier_id')
        if supplier_id:
            queryset = queryset.filter(supplier_id=supplier_id)
        
        contract_status = self.request.query_params.get('status')
        if contract_status:
            queryset = queryset.filter(status=contract_status)
        
        return queryset.order_by('-start_date')
    
    @action(detail=False, methods=['get'])
    def expiring(self, request):
        """Get contracts expiring soon"""
        days = int(request.query_params.get('days', 30))
        expiry_date = timezone.now().date() + timedelta(days=days)
        contracts = SupplierContract.objects.filter(
            end_date__lte=expiry_date,
            end_date__gte=timezone.now().date(),
            status='active'
        )
        serializer = self.get_serializer(contracts, many=True)
        return Response(serializer.data)


class AutomatedReorderViewSet(viewsets.ModelViewSet):
    """ViewSet for Automated Reorder Rules"""
    serializer_class = AutomatedReorderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = AutomatedReorder.objects.all()
        
        product_id = self.request.query_params.get('product_id')
        if product_id:
            queryset = queryset.filter(product_id=product_id)
        
        supplier_id = self.request.query_params.get('supplier_id')
        if supplier_id:
            queryset = queryset.filter(supplier_id=supplier_id)
        
        is_active = self.request.query_params.get('is_active')
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        
        return queryset.order_by('-is_active', 'product__name')
    
    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        """Activate reorder rule"""
        rule = self.get_object()
        rule.is_active = True
        rule.save()
        return Response({'status': 'Rule activated'})
    
    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        """Deactivate reorder rule"""
        rule = self.get_object()
        rule.is_active = False
        rule.save()
        return Response({'status': 'Rule deactivated'})
    
    @action(detail=True, methods=['post'])
    def test(self, request, pk=None):
        """Test reorder rule (dry run)"""
        rule = self.get_object()
        
        # Simulate reorder check
        current_stock = rule.product.current_stock if hasattr(rule.product, 'current_stock') else 0
        should_reorder = current_stock <= rule.reorder_point
        
        return Response({
            'rule_id': rule.id,
            'product': rule.product.name,
            'current_stock': current_stock,
            'reorder_point': rule.reorder_point,
            'should_reorder': should_reorder,
            'would_order_quantity': rule.reorder_quantity if should_reorder else 0,
        })
    
    @action(detail=False, methods=['post'])
    def check_all(self, request):
        """Check all active reorder rules"""
        active_rules = AutomatedReorder.objects.filter(is_active=True)
        triggered = []
        
        for rule in active_rules:
            if rule.should_reorder:
                triggered.append({
                    'rule_id': rule.id,
                    'product': rule.product.name,
                    'supplier': rule.supplier.name,
                    'quantity': rule.reorder_quantity,
                })
                rule.last_triggered_at = timezone.now()
                rule.save()
        
        return Response({
            'checked': active_rules.count(),
            'triggered': len(triggered),
            'orders': triggered
        })
