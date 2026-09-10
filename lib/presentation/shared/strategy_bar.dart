import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/summary_provider.dart';

class StrategyBar extends ConsumerWidget {
  final VoidCallback? onOpenStrategy;

  const StrategyBar({
    super.key,
    this.onOpenStrategy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = ref.watch(auctionSummaryProvider);

    final totalDelta = summary.totalOverUnderBudget;
    final deltaColor = totalDelta > 0
        ? AppColors.accent
        : (totalDelta < 0 ? Colors.red : (isDark ? Colors.grey[400]! : Colors.grey[700]!));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          final roleChips = ['P', 'D', 'C', 'A'].map((role) {
            final rSum = summary.roleSummaries[role];
            final roleColor = AppColors.getRoleColor(role);
            final remainingBudget = rSum?.remainingBudget ?? 0;
            final remainingSlots = rSum?.remainingSlots ?? 0;
            final isCompleted = rSum?.isCompleted ?? false;
            final delta = rSum?.roleDelta ?? 0;

            final hasOverrun = remainingBudget < 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hasOverrun
                      ? Colors.red.withValues(alpha: 0.5)
                      : (isCompleted
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : roleColor.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: roleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$remainingBudget cr',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: hasOverrun
                                  ? Colors.red
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          if (isCompleted && delta != 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: delta > 0
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rSum!.formattedDelta,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: delta > 0 ? AppColors.accent : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        isCompleted ? 'Completato' : '$remainingSlots slot liberi',
                        style: TextStyle(
                          fontSize: 9,
                          color: isCompleted
                              ? AppColors.accent
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList();

          final balanceWidget = InkWell(
            onTap: onOpenStrategy,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: totalDelta > 0
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : (totalDelta < 0
                        ? Colors.red.withValues(alpha: 0.12)
                        : (isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.08))),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: deltaColor.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    totalDelta > 0
                        ? Icons.add_circle_outline
                        : (totalDelta < 0 ? Icons.remove_circle_outline : Icons.balance),
                    size: 16,
                    color: deltaColor,
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalDelta > 0
                            ? 'EXTRA BUDGET'
                            : (totalDelta < 0 ? 'SFORAMENTO' : 'BILANCIO STRAT.'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: deltaColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        summary.formattedTotalOverUnder,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: deltaColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.translate('strategy_bar_title'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    balanceWidget,
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < roleChips.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        roleChips[i],
                      ],
                    ],
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.insights, size: 15, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.translate('strategy_bar_title'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < roleChips.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        roleChips[i],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              balanceWidget,
            ],
          );
        },
      ),
    );
  }
}
