"""
Staff Management API Views
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Sum, Count
from datetime import datetime, timedelta
from .staff_management_models import (
    StaffProfile, Shift, TimeEntry, TimeOffRequest
)
from .training_models import TrainingModule, StaffTraining, PerformanceReview, PayrollRecord


class StaffProfileViewSet(viewsets.ModelViewSet):
    """Staff profile management"""
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'staff_profile') and user.staff_profile.position == 'manager':
            return StaffProfile.objects.all()
        return StaffProfile.objects.filter(user=user)

    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get current staff profile"""
        try:
            profile = StaffProfile.objects.get(user=request.user)
            return Response({
                'id': str(profile.id),
                'employee_id': profile.employee_id,
                'department': profile.department,
                'position': profile.position,
                'hire_date': profile.hire_date.isoformat() if profile.hire_date else None,
            })
        except StaffProfile.DoesNotExist:
            return Response({'error': 'No staff profile'}, status=404)


class ShiftViewSet(viewsets.ModelViewSet):
    """Shift scheduling"""
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        try:
            profile = StaffProfile.objects.get(user=user)
            if profile.position == 'manager':
                return Shift.objects.all()
            return Shift.objects.filter(staff=profile)
        except:
            return Shift.objects.none()

    @action(detail=False, methods=['get'])
    def my_shifts(self, request):
        """Get my upcoming shifts"""
        try:
            profile = StaffProfile.objects.get(user=request.user)
            shifts = Shift.objects.filter(
                staff=profile,
                date__gte=timezone.now().date()
            ).order_by('date', 'start_time')[:20]
            return Response([{
                'id': str(s.id),
                'date': s.date.isoformat(),
                'start_time': s.start_time.isoformat(),
                'end_time': s.end_time.isoformat(),
                'shift_type': s.shift_type,
                'status': s.status,
            } for s in shifts])
        except:
            return Response([])

    @action(detail=False, methods=['get'])
    def schedule(self, request):
        """Get weekly schedule"""
        store_id = request.query_params.get('store_id')
        start_date = request.query_params.get('start_date')
        
        if start_date:
            start = datetime.strptime(start_date, '%Y-%m-%d').date()
        else:
            start = timezone.now().date()
        
        end = start + timedelta(days=7)
        
        queryset = Shift.objects.filter(date__range=[start, end])
        if store_id:
            queryset = queryset.filter(store_id=store_id)
        
        shifts = queryset.select_related('staff__user').order_by('date', 'start_time')
        
        return Response([{
            'id': str(s.id),
            'staff_name': s.staff.user.get_full_name(),
            'date': s.date.isoformat(),
            'start_time': s.start_time.isoformat(),
            'end_time': s.end_time.isoformat(),
            'shift_type': s.shift_type,
            'status': s.status,
        } for s in shifts])


class TimeTrackingViewSet(viewsets.ViewSet):
    """Time tracking (clock in/out)"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['post'])
    def clock_in(self, request):
        """Clock in"""
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        
        try:
            profile = StaffProfile.objects.get(user=request.user)
            
            # Check if already clocked in
            last_entry = TimeEntry.objects.filter(
                staff=profile,
                entry_type='clock_in'
            ).order_by('-timestamp').first()
            
            if last_entry:
                # Check for clock out
                clock_out = TimeEntry.objects.filter(
                    staff=profile,
                    entry_type='clock_out',
                    timestamp__gt=last_entry.timestamp
                ).exists()
                
                if not clock_out:
                    return Response({'error': 'Already clocked in'}, status=400)
            
            # Check geofence
            is_within = self._check_geofence(profile, lat, lng)
            
            entry = TimeEntry.objects.create(
                staff=profile,
                entry_type='clock_in',
                timestamp=timezone.now(),
                latitude=lat,
                longitude=lng,
                is_within_geofence=is_within
            )
            
            return Response({
                'success': True,
                'time': entry.timestamp.isoformat(),
                'within_geofence': is_within
            })
        except StaffProfile.DoesNotExist:
            return Response({'error': 'No staff profile'}, status=404)

    @action(detail=False, methods=['post'])
    def clock_out(self, request):
        """Clock out"""
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        
        try:
            profile = StaffProfile.objects.get(user=request.user)
            is_within = self._check_geofence(profile, lat, lng)
            
            entry = TimeEntry.objects.create(
                staff=profile,
                entry_type='clock_out',
                timestamp=timezone.now(),
                latitude=lat,
                longitude=lng,
                is_within_geofence=is_within
            )
            
            return Response({
                'success': True,
                'time': entry.timestamp.isoformat()
            })
        except StaffProfile.DoesNotExist:
            return Response({'error': 'No staff profile'}, status=404)

    @action(detail=False, methods=['get'])
    def status(self, request):
        """Get current clock status"""
        try:
            profile = StaffProfile.objects.get(user=request.user)
            last_entry = TimeEntry.objects.filter(staff=profile).order_by('-timestamp').first()
            
            if last_entry:
                return Response({
                    'clocked_in': last_entry.entry_type == 'clock_in',
                    'last_action': last_entry.entry_type,
                    'timestamp': last_entry.timestamp.isoformat()
                })
            return Response({'clocked_in': False})
        except:
            return Response({'clocked_in': False})

    def _check_geofence(self, profile, lat, lng):
        """Check if coordinates are within store geofence"""
        if not lat or not lng:
            return False
        # Simplified geofence check - would use proper geo calculation
        return True


class TimeOffViewSet(viewsets.ModelViewSet):
    """Time off requests"""
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        try:
            profile = StaffProfile.objects.get(user=self.request.user)
            return TimeOffRequest.objects.filter(staff=profile)
        except:
            return TimeOffRequest.objects.none()


class TrainingViewSet(viewsets.ViewSet):
    """Training modules and progress"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def modules(self, request):
        """Get available training modules"""
        modules = TrainingModule.objects.filter(is_active=True)
        return Response([{
            'id': str(m.id),
            'name': m.name,
            'description': m.description,
            'category': m.category,
            'duration': m.duration_minutes,
            'is_mandatory': m.is_mandatory,
        } for m in modules])

    @action(detail=False, methods=['get'])
    def my_training(self, request):
        """Get my training progress"""
        try:
            profile = StaffProfile.objects.get(user=request.user)
            trainings = StaffTraining.objects.filter(staff=profile).select_related('module')
            return Response([{
                'module_id': str(t.module.id),
                'module_name': t.module.name,
                'status': t.status,
                'progress': t.progress,
                'score': t.quiz_score,
                'due_date': t.due_date.isoformat() if t.due_date else None,
            } for t in trainings])
        except:
            return Response([])

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """Start a training module"""
        try:
            profile = StaffProfile.objects.get(user=request.user)
            module = TrainingModule.objects.get(id=pk)
            training, created = StaffTraining.objects.get_or_create(
                staff=profile, module=module,
                defaults={'status': 'in_progress', 'started_at': timezone.now()}
            )
            if not created:
                training.status = 'in_progress'
                training.save()
            return Response({'started': True})
        except:
            return Response({'error': 'Failed to start'}, status=400)


class PerformanceViewSet(viewsets.ViewSet):
    """Performance reviews"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def my_reviews(self, request):
        """Get my performance reviews"""
        try:
            profile = StaffProfile.objects.get(user=request.user)
            reviews = PerformanceReview.objects.filter(staff=profile)
            return Response([{
                'id': str(r.id),
                'type': r.review_type,
                'period': f"{r.review_period_start} to {r.review_period_end}",
                'overall_score': float(r.overall_score) if r.overall_score else None,
                'status': r.status,
            } for r in reviews])
        except:
            return Response([])


class PayrollViewSet(viewsets.ViewSet):
    """Payroll records"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def my_payroll(self, request):
        """Get my payroll history"""
        try:
            profile = StaffProfile.objects.get(user=request.user)
            records = PayrollRecord.objects.filter(staff=profile)[:12]
            return Response([{
                'period': f"{r.pay_period_start} to {r.pay_period_end}",
                'regular_hours': float(r.regular_hours),
                'overtime_hours': float(r.overtime_hours),
                'gross_pay': float(r.gross_pay),
                'net_pay': float(r.net_pay),
                'status': r.status,
            } for r in records])
        except:
            return Response([])
