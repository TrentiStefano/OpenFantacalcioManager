import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final String? mantraRole;
  final bool showMantra;
  final double size;

  const RoleBadge({
    super.key,
    required this.role,
    this.mantraRole,
    this.showMantra = false,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.getRoleColor(role);
    final bgColor = AppColors.getRoleBgColor(role, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (showMantra && mantraRole != null && mantraRole!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '($mantraRole)',
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
