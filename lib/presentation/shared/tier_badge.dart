import 'package:flutter/material.dart';
import '../../core/constants/app_tiers.dart';

class TierBadge extends StatelessWidget {
  final String tier;
  final ValueChanged<String>? onTierChanged;
  final List<String>? availableTiers;

  const TierBadge({
    super.key,
    required this.tier,
    this.onTierChanged,
    this.availableTiers,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTiers.getTierColor(tier);
    final tiers = availableTiers ?? AppTiers.defaultTiers;

    if (onTierChanged != null) {
      return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: tiers.contains(tier) ? tier : tiers.first,
            icon: Icon(Icons.arrow_drop_down, size: 16, color: color),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            isDense: true,
            onChanged: (newTier) {
              if (newTier != null && newTier != tier) {
                onTierChanged!(newTier);
              }
            },
            items: tiers.map((t) {
              final tColor = AppTiers.getTierColor(t);
              return DropdownMenuItem<String>(
                value: t,
                child: Text(
                  t,
                  style: TextStyle(
                    color: tColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
