"""
Security-related API views for role management and audit logging.
"""
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .security_models import SecurityRole, UserProfile, SecurityAuditLog, security_manager
from .security_middleware import require_permission, audit_access
import json

User = get_user_model()


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
@require_permission('can_manage_users')
@audit_access('security_roles', 'manage')
def security_roles_view(request):
    """
    Manage security roles - list all or create new.
    """
    if request.method == 'GET':
        roles = SecurityRole.objects.all()
        roles_data = []
        
        for role in roles:
            roles_data.append({
                'id': role.id,
                'name': role.name,
                'level': role.level,
                'description': role.description,
                'permissions': {
                    'can_create_products': role.can_create_products,
                    'can_edit_products': role.can_edit_products,
                    'can_delete_products': role.can_delete_products,
                    'can_view_products': role.can_view_products,
                    'can_manage_inventory': role.can_manage_inventory,
                    'can_view_analytics': role.can_view_analytics,
                    'can_export_data': role.can_export_data,
                    'can_manage_users': role.can_manage_users,
                    'can_view_reports': role.can_view_reports,
                    'can_manage_settings': role.can_manage_settings,
                    'can_access_financial_data': role.can_access_financial_data,
                    'can_manage_suppliers': role.can_manage_suppliers,
                    'can_approve_purchases': role.can_approve_purchases,
                    'can_use_ml_features': role.can_use_ml_features,
                    'can_access_raw_data': role.can_access_raw_data,
                    'can_modify_security': role.can_modify_security,
                },
                'created_at': role.created_at,
                'updated_at': role.updated_at
            })
        
        return Response({
            'success': True,
            'roles': roles_data,
            'total': len(roles_data)
        })
    
    elif request.method == 'POST':
        try:
            data = json.loads(request.body)
            
            # Create new role
            role = SecurityRole.objects.create(
                name=data.get('name'),
                level=data.get('level'),
                description=data.get('description', ''),
                **data.get('permissions', {})
            )
            
            security_manager.log_security_event(
                user=request.user,
                event_type='admin_action',
                description=f'Created security role: {role.name}',
                request=request,
                risk_level='medium'
            )
            
            return Response({
                'success': True,
                'message': 'Security role created successfully',
                'role_id': role.id
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to create role: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
@require_permission('can_manage_users')
@audit_access('security_role', 'manage')
def security_role_detail_view(request, role_id):
    """
    Manage individual security role - view, update, or delete.
    """
    try:
        role = get_object_or_404(SecurityRole, id=role_id)
        
        if request.method == 'GET':
            return Response({
                'success': True,
                'role': {
                    'id': role.id,
                    'name': role.name,
                    'level': role.level,
                    'description': role.description,
                    'permissions': {
                        'can_create_products': role.can_create_products,
                        'can_edit_products': role.can_edit_products,
                        'can_delete_products': role.can_delete_products,
                        'can_view_products': role.can_view_products,
                        'can_manage_inventory': role.can_manage_inventory,
                        'can_view_analytics': role.can_view_analytics,
                        'can_export_data': role.can_export_data,
                        'can_manage_users': role.can_manage_users,
                        'can_view_reports': role.can_view_reports,
                        'can_manage_settings': role.can_manage_settings,
                        'can_access_financial_data': role.can_access_financial_data,
                        'can_manage_suppliers': role.can_manage_suppliers,
                        'can_approve_purchases': role.can_approve_purchases,
                        'can_use_ml_features': role.can_use_ml_features,
                        'can_access_raw_data': role.can_access_raw_data,
                        'can_modify_security': role.can_modify_security,
                    }
                }
            })
        
        elif request.method == 'PUT':
            data = json.loads(request.body)
            
            # Update role
            for field in ['name', 'level', 'description']:
                if field in data:
                    setattr(role, field, data[field])
            
            # Update permissions
            if 'permissions' in data:
                for perm, value in data['permissions'].items():
                    if hasattr(role, perm):
                        setattr(role, perm, value)
            
            role.save()
            
            security_manager.log_security_event(
                user=request.user,
                event_type='admin_action',
                description=f'Updated security role: {role.name}',
                request=request,
                risk_level='medium'
            )
            
            return Response({
                'success': True,
                'message': 'Security role updated successfully'
            })
        
        elif request.method == 'DELETE':
            # Check if role is in use
            users_with_role = UserProfile.objects.filter(security_role=role).count()
            if users_with_role > 0:
                return Response({
                    'success': False,
                    'message': f'Cannot delete role. {users_with_role} users are assigned this role.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            role_name = role.name
            role.delete()
            
            security_manager.log_security_event(
                user=request.user,
                event_type='admin_action',
                description=f'Deleted security role: {role_name}',
                request=request,
                risk_level='high'
            )
            
            return Response({
                'success': True,
                'message': 'Security role deleted successfully'
            })
            
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
@require_permission('can_manage_users')
@audit_access('user_roles', 'manage')
def user_roles_view(request):
    """
    Manage user role assignments.
    """
    if request.method == 'GET':
        users = User.objects.select_related('security_profile__security_role').all()
        users_data = []
        
        for user in users:
            profile = getattr(user, 'security_profile', None)
            users_data.append({
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'is_active': user.is_active,
                'role': {
                    'id': profile.security_role.id if profile and profile.security_role else None,
                    'name': profile.security_role.name if profile and profile.security_role else None,
                    'level': profile.security_role.level if profile and profile.security_role else None
                } if profile else None,
                'two_factor_enabled': profile.two_factor_enabled if profile else False,
                'last_login': user.last_login
            })
        
        return Response({
            'success': True,
            'users': users_data,
            'total': len(users_data)
        })
    
    elif request.method == 'POST':
        try:
            data = json.loads(request.body)
            user_id = data.get('user_id')
            role_id = data.get('role_id')
            
            user = get_object_or_404(User, id=user_id)
            role = get_object_or_404(SecurityRole, id=role_id) if role_id else None
            
            # Get or create user profile
            profile, created = UserProfile.objects.get_or_create(user=user)
            old_role = profile.security_role.name if profile.security_role else 'None'
            
            # Update role
            profile.security_role = role
            profile.save()
            
            new_role = role.name if role else 'None'
            
            security_manager.log_security_event(
                user=request.user,
                event_type='admin_action',
                description=f'Changed user {user.username} role from {old_role} to {new_role}',
                request=request,
                risk_level='medium'
            )
            
            return Response({
                'success': True,
                'message': 'User role updated successfully'
            })
            
        except Exception as e:
            return Response({
                'success': False,
                'message': f'Failed to update user role: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_permission('can_view_reports')
@audit_access('security_logs', 'read')
def security_audit_logs_view(request):
    """
    View security audit logs with filtering.
    """
    try:
        # Get query parameters
        event_type = request.GET.get('event_type')
        risk_level = request.GET.get('risk_level')
        user_id = request.GET.get('user_id')
        start_date = request.GET.get('start_date')
        end_date = request.GET.get('end_date')
        page = int(request.GET.get('page', 1))
        per_page = int(request.GET.get('per_page', 50))
        
        # Build query
        logs = SecurityAuditLog.objects.select_related('user').all()
        
        if event_type:
            logs = logs.filter(event_type=event_type)
        if risk_level:
            logs = logs.filter(risk_level=risk_level)
        if user_id:
            logs = logs.filter(user_id=user_id)
        if start_date:
            logs = logs.filter(timestamp__gte=start_date)
        if end_date:
            logs = logs.filter(timestamp__lte=end_date)
        
        # Pagination
        total = logs.count()
        start = (page - 1) * per_page
        end = start + per_page
        logs = logs[start:end]
        
        # Format response
        logs_data = []
        for log in logs:
            logs_data.append({
                'id': log.id,
                'event_type': log.event_type,
                'risk_level': log.risk_level,
                'description': log.description,
                'user': {
                    'id': log.user.id if log.user else None,
                    'username': log.user.username if log.user else None
                },
                'ip_address': log.ip_address,
                'endpoint': log.endpoint,
                'method': log.method,
                'response_code': log.response_code,
                'context_data': log.context_data,
                'timestamp': log.timestamp
            })
        
        return Response({
            'success': True,
            'logs': logs_data,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': total,
                'total_pages': (total + per_page - 1) // per_page
            },
            'filters': {
                'available_event_types': [choice[0] for choice in SecurityAuditLog.EVENT_TYPES],
                'available_risk_levels': [choice[0] for choice in SecurityAuditLog.RISK_LEVELS]
            }
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error retrieving audit logs: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_permission('can_view_analytics')
@audit_access('security_dashboard', 'read')
def security_dashboard_view(request):
    """
    Security dashboard with key metrics and alerts.
    """
    try:
        from django.db.models import Count
        from datetime import datetime, timedelta
        
        # Calculate date ranges
        now = datetime.now()
        last_24h = now - timedelta(hours=24)
        last_7d = now - timedelta(days=7)
        last_30d = now - timedelta(days=30)
        
        # Get metrics
        metrics = {
            'recent_activity': {
                'last_24h': SecurityAuditLog.objects.filter(timestamp__gte=last_24h).count(),
                'last_7d': SecurityAuditLog.objects.filter(timestamp__gte=last_7d).count(),
                'last_30d': SecurityAuditLog.objects.filter(timestamp__gte=last_30d).count()
            },
            'risk_distribution': SecurityAuditLog.objects.filter(
                timestamp__gte=last_7d
            ).values('risk_level').annotate(count=Count('id')),
            
            'event_types': SecurityAuditLog.objects.filter(
                timestamp__gte=last_7d
            ).values('event_type').annotate(count=Count('id')),
            
            'failed_logins': SecurityAuditLog.objects.filter(
                event_type='failed_login',
                timestamp__gte=last_24h
            ).count(),
            
            'permission_denials': SecurityAuditLog.objects.filter(
                event_type='permission_denied',
                timestamp__gte=last_24h
            ).count(),
            
            'high_risk_events': SecurityAuditLog.objects.filter(
                risk_level__in=['high', 'critical'],
                timestamp__gte=last_7d
            ).count(),
            
            'active_users': User.objects.filter(
                last_login__gte=last_7d,
                is_active=True
            ).count(),
            
            'locked_accounts': UserProfile.objects.filter(
                locked_until__gt=now
            ).count()
        }
        
        # Get recent high-risk events
        recent_alerts = SecurityAuditLog.objects.filter(
            risk_level__in=['high', 'critical'],
            timestamp__gte=last_24h
        ).select_related('user')[:10]
        
        alerts_data = []
        for alert in recent_alerts:
            alerts_data.append({
                'id': alert.id,
                'event_type': alert.event_type,
                'risk_level': alert.risk_level,
                'description': alert.description,
                'user': alert.user.username if alert.user else 'Unknown',
                'timestamp': alert.timestamp
            })
        
        # Get user role distribution
        role_distribution = UserProfile.objects.filter(
            security_role__isnull=False
        ).values('security_role__name').annotate(count=Count('id'))
        
        return Response({
            'success': True,
            'dashboard': {
                'metrics': metrics,
                'recent_alerts': alerts_data,
                'role_distribution': list(role_distribution),
                'last_updated': now
            }
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error loading security dashboard: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@require_permission('can_modify_security')
@audit_access('security_settings', 'write')
def initialize_security_system_view(request):
    """
    Initialize security system with default roles and settings.
    """
    try:
        # Create default roles
        default_roles = SecurityRole.get_default_roles()
        created_roles = []
        
        for role_key, role_data in default_roles.items():
            role, created = SecurityRole.objects.get_or_create(
                level=role_data['level'],
                defaults={
                    'name': role_data['name'],
                    'description': role_data['description'],
                    **role_data['permissions']
                }
            )
            
            if created:
                created_roles.append(role.name)
        
        # Assign owner role to current user if they don't have one
        profile, created = UserProfile.objects.get_or_create(user=request.user)
        if not profile.security_role:
            owner_role = SecurityRole.objects.filter(level='owner').first()
            if owner_role:
                profile.security_role = owner_role
                profile.save()
        
        security_manager.log_security_event(
            user=request.user,
            event_type='admin_action',
            description='Initialized security system with default roles',
            request=request,
            risk_level='medium'
        )
        
        return Response({
            'success': True,
            'message': 'Security system initialized successfully',
            'created_roles': created_roles,
            'total_roles': SecurityRole.objects.count()
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Failed to initialize security system: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
@audit_access('user_permissions', 'read')
def check_permissions_view(request):
    """
    Check current user's permissions.
    """
    try:
        profile = getattr(request.user, 'security_profile', None)
        
        if not profile or not profile.security_role:
            permissions = {
                'role': None,
                'permissions': {},
                'is_superuser': request.user.is_superuser
            }
        else:
            role = profile.security_role
            permissions = {
                'role': {
                    'id': role.id,
                    'name': role.name,
                    'level': role.level,
                    'description': role.description
                },
                'permissions': {
                    'can_create_products': role.can_create_products,
                    'can_edit_products': role.can_edit_products,
                    'can_delete_products': role.can_delete_products,
                    'can_view_products': role.can_view_products,
                    'can_manage_inventory': role.can_manage_inventory,
                    'can_view_analytics': role.can_view_analytics,
                    'can_export_data': role.can_export_data,
                    'can_manage_users': role.can_manage_users,
                    'can_view_reports': role.can_view_reports,
                    'can_manage_settings': role.can_manage_settings,
                    'can_access_financial_data': role.can_access_financial_data,
                    'can_manage_suppliers': role.can_manage_suppliers,
                    'can_approve_purchases': role.can_approve_purchases,
                    'can_use_ml_features': role.can_use_ml_features,
                    'can_access_raw_data': role.can_access_raw_data,
                    'can_modify_security': role.can_modify_security,
                },
                'is_superuser': request.user.is_superuser,
                'two_factor_enabled': profile.two_factor_enabled,
                'account_locked': profile.is_account_locked()
            }
        
        return Response({
            'success': True,
            'user': {
                'id': request.user.id,
                'username': request.user.username,
                'email': request.user.email,
                'is_active': request.user.is_active,
                **permissions
            }
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error checking permissions: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)