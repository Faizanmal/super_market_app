"""
Base Models - Abstract base classes for all models in the application.
Provides consistent timestamps, soft delete, and audit functionality.
"""
import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone


class TimeStampedModel(models.Model):
    """
    Abstract base model that provides self-updating created_at and updated_at fields.
    All models that need timestamp tracking should inherit from this.
    """
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
        help_text="Timestamp when this record was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Timestamp when this record was last updated"
    )

    class Meta:
        abstract = True
        ordering = ['-created_at']


class SoftDeleteManager(models.Manager):
    """Manager that filters out soft-deleted records by default."""
    
    def get_queryset(self):
        return super().get_queryset().filter(is_deleted=False)
    
    def with_deleted(self):
        """Return all records including soft-deleted ones."""
        return super().get_queryset()
    
    def only_deleted(self):
        """Return only soft-deleted records."""
        return super().get_queryset().filter(is_deleted=True)


class SoftDeleteModel(models.Model):
    """
    Abstract base model that provides soft delete functionality.
    Records are marked as deleted rather than actually removed from the database.
    """
    is_deleted = models.BooleanField(
        default=False,
        db_index=True,
        help_text="Soft delete flag - True means record is deleted"
    )
    deleted_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Timestamp when this record was soft deleted"
    )
    deleted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="%(app_label)s_%(class)s_deleted",
        help_text="User who deleted this record"
    )

    objects = SoftDeleteManager()
    all_objects = models.Manager()  # Manager to access all records

    class Meta:
        abstract = True

    def soft_delete(self, user=None):
        """Soft delete this record."""
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.deleted_by = user
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by'])

    def restore(self):
        """Restore a soft-deleted record."""
        self.is_deleted = False
        self.deleted_at = None
        self.deleted_by = None
        self.save(update_fields=['is_deleted', 'deleted_at', 'deleted_by'])


class AuditableModel(TimeStampedModel, SoftDeleteModel):
    """
    Abstract base model combining timestamps, soft delete, and audit fields.
    Use this for models requiring full audit trail.
    """
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="%(app_label)s_%(class)s_created",
        help_text="User who created this record"
    )
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="%(app_label)s_%(class)s_updated",
        help_text="User who last updated this record"
    )

    class Meta:
        abstract = True


class UUIDModel(models.Model):
    """
    Abstract base model that uses UUID as primary key.
    Provides better security and distributed database support.
    """
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Unique identifier for this record"
    )

    class Meta:
        abstract = True


class FullAuditModel(UUIDModel, AuditableModel):
    """
    Complete audit model combining UUID primary key, timestamps,
    soft delete, and user tracking. Use for critical business entities.
    """
    
    class Meta:
        abstract = True
