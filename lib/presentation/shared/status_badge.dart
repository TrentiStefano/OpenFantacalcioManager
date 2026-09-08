import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/player.dart';

class StatusBadge extends StatelessWidget {
  final PlayerStatus status;
  final int? purchasePrice;

  const StatusBadge({
    super.key,
    required this.status,
    this.purchasePrice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (status) {
      case PlayerStatus.mine:
        bg = AppColors.statusMine.withValues(alpha: 0.15);
        fg = AppColors.statusMine;
        text = purchasePrice != null
            ? '${l10n.translate('status_mine')} (${purchasePrice} cr)'
            : l10n.translate('status_mine');
        icon = Icons.check_circle_outline;
        break;
      case PlayerStatus.others:
        bg = AppColors.statusOthers.withValues(alpha: 0.15);
        fg = AppColors.statusOthers;
        text = l10n.translate('status_others');
        icon = Icons.cancel_outlined;
        break;
      case PlayerStatus.available:
        bg = AppColors.statusAvailable.withValues(alpha: 0.15);
        fg = AppColors.statusAvailable;
        text = l10n.translate('status_available');
        icon = Icons.radio_button_unchecked;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
