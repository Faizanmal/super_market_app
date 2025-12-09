"""
Django management command to initialize the security system.
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from products.security_models import SecurityRole, UserProfile

User = get_user_model()


class Command(BaseCommand):
    help = 'Initialize the security system with default roles and settings'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--create-admin',
            action='store_true',
            help='Create a default admin user with owner role',
        )
        parser.add_argument(
            '--admin-username',
            type=str,
            default='admin',
            help='Username for admin user (default: admin)',
        )
        parser.add_argument(
            '--admin-email',
            type=str,
            default='admin@supermarket.local',
            help='Email for admin user',
        )
        parser.add_argument(
            '--admin-password',
            type=str,
            default='SuperMarket123!',
            help='Password for admin user',
        )
    
    def handle(self, *args, **options):
        self.stdout.write('Initializing Super Market Helper Security System...\n')
        
        # Create default security roles
        self.stdout.write('Creating default security roles...')
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
                self.stdout.write(
                    self.style.SUCCESS(f'  ✓ Created role: {role.name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'  - Role already exists: {role.name}')
                )
        
        # Create admin user if requested
        if options['create_admin']:
            self.stdout.write('\nCreating admin user...')
            username = options['admin_username']
            email = options['admin_email']
            password = options['admin_password']
            
            # Check if user already exists
            if User.objects.filter(username=username).exists():
                self.stdout.write(
                    self.style.WARNING(f'  - User "{username}" already exists')
                )
                admin_user = User.objects.get(username=username)
            else:
                admin_user = User.objects.create_user(
                    username=username,
                    email=email,
                    password=password,
                    is_staff=True,
                    is_superuser=True
                )
                self.stdout.write(
                    self.style.SUCCESS(f'  ✓ Created admin user: {username}')
                )
            
            # Assign owner role
            owner_role = SecurityRole.objects.filter(level='owner').first()
            if owner_role:
                profile, created = UserProfile.objects.get_or_create(user=admin_user)
                if profile.security_role != owner_role:
                    profile.security_role = owner_role
                    profile.save()
                    self.stdout.write(
                        self.style.SUCCESS(f'  ✓ Assigned owner role to {username}')
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(f'  - {username} already has owner role')
                    )
        
        # Show summary
        total_roles = SecurityRole.objects.count()
        total_users = User.objects.count()
        users_with_roles = UserProfile.objects.filter(security_role__isnull=False).count()
        
        self.stdout.write('\n' + '='*50)
        self.stdout.write(self.style.SUCCESS('Security System Initialization Complete!'))
        self.stdout.write('='*50)
        
        self.stdout.write(f'📋 Total Security Roles: {total_roles}')
        self.stdout.write(f'👥 Total Users: {total_users}')
        self.stdout.write(f'🔐 Users with Roles: {users_with_roles}')
        
        if created_roles:
            self.stdout.write(f'✨ New Roles Created: {", ".join(created_roles)}')
        
        self.stdout.write('\n📚 Next Steps:')
        self.stdout.write('  1. Access the security dashboard at /api/security/dashboard/')
        self.stdout.write('  2. Assign roles to users at /api/security/user-roles/')
        self.stdout.write('  3. Monitor audit logs at /api/security/audit-logs/')
        
        if options['create_admin']:
            self.stdout.write('\n🔑 Admin Login Details:')
            self.stdout.write(f'  Username: {options["admin_username"]}')
            self.stdout.write(f'  Password: {options["admin_password"]}')
            self.stdout.write('  (Please change the password after first login)')
        
        self.stdout.write('\n🚀 Super Market Helper is now secured and ready to use!')
    
    def show_role_permissions(self, role):
        """Display role permissions in a formatted way."""
        permissions = []
        for field_name in dir(role):
            if field_name.startswith('can_') and hasattr(role, field_name):
                if getattr(role, field_name):
                    permissions.append(field_name.replace('can_', '').replace('_', ' ').title())
        
        if permissions:
            self.stdout.write(f'    Permissions: {", ".join(permissions)}')
        else:
            self.stdout.write('    Permissions: None')