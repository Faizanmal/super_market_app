"""
User models for authentication and user management.
"""
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.utils.translation import gettext_lazy as _


class UserManager(BaseUserManager):
    """Custom user manager for creating users and superusers."""
    
    def create_user(self, email, password=None, **extra_fields):
        """Create and return a regular user with an email and password."""
        if not email:
            raise ValueError(_('The Email field must be set'))
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        """Create and return a superuser with an email and password."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError(_('Superuser must have is_staff=True.'))
        if extra_fields.get('is_superuser') is not True:
            raise ValueError(_('Superuser must have is_superuser=True.'))

        return self.create_user(email, password, **extra_fields)


class User(AbstractUser): 
    """Custom user model with email as the primary identifier and role-based access."""
    
    ROLE_CHOICES = [
        ('store_manager', 'Store Manager'),
        ('stock_receiver', 'Stock Receiver'),
        ('shelf_staff', 'Shelf Staff'),
        ('auditor', 'Auditor/QA'),
        ('head_office', 'Head Office Admin'),
    ]
    
    username = None  # Remove username field
    email = models.EmailField(_('email address'), unique=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    company_name = models.CharField(max_length=255, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    
    # Role and Store Assignment
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='shelf_staff')
    store = models.ForeignKey('products.Store', on_delete=models.SET_NULL, null=True, blank=True, related_name='staff_members')
    employee_id = models.CharField(max_length=50, blank=True, null=True, unique=True)
    
    # Profile fields
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    
    # Permissions
    can_receive_stock = models.BooleanField(default=False, help_text="Can perform warehouse receiving")
    can_audit = models.BooleanField(default=False, help_text="Can perform shelf audits")
    can_manage_staff = models.BooleanField(default=False, help_text="Can manage team members")
    can_view_analytics = models.BooleanField(default=False, help_text="Can access analytics dashboard")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']
    
    objects = UserManager()
    
    class Meta:
        verbose_name = _('user')
        verbose_name_plural = _('users')
        ordering = ['-created_at']
    
    def __str__(self):
        return self.email
    
    def get_full_name(self):
        """Return the first_name plus the last_name, with a space in between."""
        return f'{self.first_name} {self.last_name}'.strip()
    
    def save(self, *args, **kwargs):
        """Auto-set permissions based on role."""
        if self.role == 'store_manager':
            self.can_receive_stock = True
            self.can_audit = True
            self.can_manage_staff = True
            self.can_view_analytics = True
        elif self.role == 'stock_receiver':
            self.can_receive_stock = True
            self.can_audit = False
            self.can_manage_staff = False
            self.can_view_analytics = False
        elif self.role == 'shelf_staff':
            self.can_receive_stock = False
            self.can_audit = False
            self.can_manage_staff = False
            self.can_view_analytics = False
        elif self.role == 'auditor':
            self.can_receive_stock = False
            self.can_audit = True
            self.can_manage_staff = False
            self.can_view_analytics = True
        elif self.role == 'head_office':
            self.can_receive_stock = False
            self.can_audit = True
            self.can_manage_staff = True
            self.can_view_analytics = True
        
        super().save(*args, **kwargs)
