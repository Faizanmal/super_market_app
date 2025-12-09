"""
ViewSets for Sustainability Management System
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import timedelta
from django.db.models import Sum

from .sustainability_models import (
    SustainabilityMetrics, WasteRecord,
    SustainabilityInitiative, GreenSupplierRating
)
from .advanced_serializers import (
    SustainabilityMetricsSerializer, WasteRecordSerializer, SustainabilityInitiativeSerializer,
    GreenSupplierRatingSerializer
)


class SustainabilityMetricsViewSet(viewsets.ModelViewSet):
    """ViewSet for Sustainability Metrics"""
    serializer_class = SustainabilityMetricsSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = SustainabilityMetrics.objects.all()
        
        store_id = self.request.query_params.get('store_id')
        if store_id:
            queryset = queryset.filter(store_id=store_id)
        
        period = self.request.query_params.get('period')
        if period:
            days = {'week': 7, 'month': 30, 'quarter': 90, 'year': 365}.get(period, 30)
            start_date = timezone.now() - timedelta(days=days)
            queryset = queryset.filter(reporting_period_start__gte=start_date)
        
        return queryset.order_by('-reporting_period_end')
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Get sustainability dashboard data"""
        store_id = request.query_params.get('store_id')
        
        # Get latest metrics
        metrics_qs = SustainabilityMetrics.objects.all()
        if store_id:
            metrics_qs = metrics_qs.filter(store_id=store_id)
        
        try:
            latest_metrics = metrics_qs.latest('reporting_period_end')
            serializer = self.get_serializer(latest_metrics)
            
            # Calculate trends
            previous_period = metrics_qs.filter(
                reporting_period_end__lt=latest_metrics.reporting_period_start
            ).latest('reporting_period_end') if metrics_qs.count() > 1 else None
            
            trends = {}
            if previous_period:
                trends = {
                    'score_change': float(latest_metrics.sustainability_score - previous_period.sustainability_score),
                    'waste_change': float(latest_metrics.total_waste - previous_period.total_waste),
                    'carbon_change': float(latest_metrics.total_carbon_footprint - previous_period.total_carbon_footprint),
                }
            
            return Response({
                'metrics': serializer.data,
                'trends': trends
            })
        except SustainabilityMetrics.DoesNotExist:
            return Response({'detail': 'No metrics available'}, status=status.HTTP_404_NOT_FOUND)


class WasteRecordViewSet(viewsets.ModelViewSet):
    """ViewSet for Waste Records"""
    serializer_class = WasteRecordSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = WasteRecord.objects.all()
        
        store_id = self.request.query_params.get('store_id')
        if store_id:
            queryset = queryset.filter(store_id=store_id)
        
        waste_type = self.request.query_params.get('waste_type')
        if waste_type:
            queryset = queryset.filter(waste_type=waste_type)
        
        preventable = self.request.query_params.get('preventable')
        if preventable is not None:
            queryset = queryset.filter(preventable=preventable.lower() == 'true')
        
        return queryset.order_by('-recorded_at')
    
    def perform_create(self, serializer):
        serializer.save(recorded_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def analytics(self, request):
        """Get waste analytics"""
        store_id = request.query_params.get('store_id')
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now() - timedelta(days=days)
        
        queryset = WasteRecord.objects.filter(recorded_at__gte=start_date)
        if store_id:
            queryset = queryset.filter(store_id=store_id)
        
        # Aggregate by waste type
        by_type = queryset.values('waste_type').annotate(
            total_quantity=Sum('quantity'),
            total_value=Sum('monetary_value'),
            total_carbon=Sum('carbon_impact')
        )
        
        # Preventable waste
        preventable = queryset.filter(preventable=True).aggregate(
            quantity=Sum('quantity'),
            value=Sum('monetary_value')
        )
        
        return Response({
            'period_days': days,
            'total_records': queryset.count(),
            'by_type': list(by_type),
            'preventable_waste': preventable,
            'total_quantity': queryset.aggregate(Sum('quantity'))['quantity__sum'] or 0,
            'total_value': queryset.aggregate(Sum('monetary_value'))['monetary_value__sum'] or 0,
            'total_carbon_impact': queryset.aggregate(Sum('carbon_impact'))['carbon_impact__sum'] or 0,
        })


class SustainabilityInitiativeViewSet(viewsets.ModelViewSet):
    """ViewSet for Sustainability Initiatives"""
    serializer_class = SustainabilityInitiativeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = SustainabilityInitiative.objects.all()
        
        store_id = self.request.query_params.get('store_id')
        if store_id:
            queryset = queryset.filter(store_id=store_id)
        
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        
        initiative_status = self.request.query_params.get('status')
        if initiative_status:
            queryset = queryset.filter(status=initiative_status)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def update_progress(self, request, pk=None):
        """Update initiative progress"""
        initiative = self.get_object()
        
        # Update progress fields
        for field in ['actual_waste_reduction', 'actual_carbon_reduction', 'actual_cost']:
            if field in request.data:
                setattr(initiative, field, request.data[field])
        
        initiative.save()
        serializer = self.get_serializer(initiative)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark initiative as completed"""
        initiative = self.get_object()
        initiative.status = 'completed'
        initiative.end_date = timezone.now().date()
        initiative.save()
        
        serializer = self.get_serializer(initiative)
        return Response(serializer.data)


class GreenSupplierRatingViewSet(viewsets.ModelViewSet):
    """ViewSet for Green Supplier Ratings"""
    serializer_class = GreenSupplierRatingSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = GreenSupplierRating.objects.all()
        
        min_rating = self.request.query_params.get('min_rating')
        if min_rating:
            queryset = queryset.filter(overall_rating__gte=float(min_rating))
        
        certified_only = self.request.query_params.get('certified_only')
        if certified_only and certified_only.lower() == 'true':
            queryset = queryset.filter(
                iso14001_certified=True
            ) | queryset.filter(
                carbon_neutral_certified=True
            ) | queryset.filter(
                organic_certified=True
            )
        
        return queryset.order_by('-overall_rating')
    
    @action(detail=False, methods=['get'])
    def top_rated(self, request):
        """Get top-rated green suppliers"""
        limit = int(request.query_params.get('limit', 10))
        suppliers = self.get_queryset()[:limit]
        serializer = self.get_serializer(suppliers, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def certified(self, request):
        """Get certified suppliers"""
        cert_type = request.query_params.get('type', 'iso14001')
        
        queryset = self.get_queryset()
        if cert_type == 'iso14001':
            queryset = queryset.filter(iso14001_certified=True)
        elif cert_type == 'carbon_neutral':
            queryset = queryset.filter(carbon_neutral_certified=True)
        elif cert_type == 'organic':
            queryset = queryset.filter(organic_certified=True)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
