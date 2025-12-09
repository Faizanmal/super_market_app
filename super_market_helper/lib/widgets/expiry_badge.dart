import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';

/// Expiry badge widget
/// Displays visual indicator for product expiry status
class ExpiryBadge extends StatelessWidget {
  final ExpiryStatus expiryStatus;
  final bool showLabel;
  final double size;

  const ExpiryBadge({
    super.key,
    required this.expiryStatus,
    this.showLabel = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final badgeData = _getBadgeData();

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badgeData.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badgeData.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeData.icon,
              size: 16,
              color: badgeData.color,
            ),
            const SizedBox(width: 6),
            Text(
              badgeData.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeData.color,
              ),
            ),
          ],
        ),
      );
    } else {
      // Icon only
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: badgeData.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: badgeData.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          badgeData.icon,
          size: size,
          color: badgeData.color,
        ),
      );
    }
  }

  /// Get badge data based on expiry status
  _BadgeData _getBadgeData() {
    switch (expiryStatus) {
      case ExpiryStatus.fresh:
        return _BadgeData(
          label: 'Fresh',
          icon: Icons.check_circle,
          color: AppTheme.successColor,
        );
      case ExpiryStatus.warning:
        return _BadgeData(
          label: 'Expiring Soon',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.warningColor,
        );
      case ExpiryStatus.danger:
        return _BadgeData(
          label: 'Critical',
          icon: Icons.error,
          color: AppTheme.dangerColor,
        );
      case ExpiryStatus.expired:
        return _BadgeData(
          label: 'Expired',
          icon: Icons.cancel,
          color: AppTheme.dangerColor,
        );
    }
  }
}

/// Badge data model
class _BadgeData {
  final String label;
  final IconData icon;
  final Color color;

  _BadgeData({
    required this.label,
    required this.icon,
    required this.color,
  });
}
