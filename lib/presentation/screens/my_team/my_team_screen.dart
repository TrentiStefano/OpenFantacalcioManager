import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/player.dart';
import '../../providers/players_provider.dart';
import '../../providers/summary_provider.dart';
import '../../shared/role_badge.dart';
import '../../shared/stat_card.dart';

class MyTeamScreen extends ConsumerWidget {
  const MyTeamScreen({super.key});

  void _editPurchasePrice(BuildContext context, WidgetRef ref, Player player) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: player.purchasePrice?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifica Prezzo: ${player.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nuovo prezzo di acquisto (cr)',
            suffixText: 'cr',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 0) {
                HapticFeedback.selectionClick();
                ref.read(playersProvider.notifier).assignToMe(player.id, parsed);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _confirmRemovePlayer(BuildContext context, WidgetRef ref, Player player) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovi Giocatore dalla Rosa'),
        content: Text(
          'Sei sicuro di voler rimuovere ${player.name} (${player.purchasePrice} cr)? '
          'Il giocatore tornerà disponibile e il budget verrà ripristinato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(playersProvider.notifier).makeAvailable(player.id);
              Navigator.pop(ctx);
            },
            child: const Text('Rimuovi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final summary = ref.watch(auctionSummaryProvider);
    final players = ref.watch(playersProvider).value ?? [];
    final minePlayers = players.where((p) => p.status == PlayerStatus.mine).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final cards = [
          StatCard(
            title: l10n.translate('initial_budget'),
            value: '${summary.initialBudget} cr',
            icon: Icons.account_balance,
            color: AppColors.primary,
          ),
          StatCard(
            title: l10n.translate('total_spent'),
            value: '${summary.totalSpent} cr',
            subtitle: '${(summary.overallBudgetProgress * 100).toStringAsFixed(1)}% del budget',
            icon: Icons.shopping_bag_outlined,
            color: Colors.orange,
            progress: summary.overallBudgetProgress,
            progressColor: Colors.orange,
          ),
          StatCard(
            title: l10n.translate('remaining_budget'),
            value: '${summary.remainingBudget} cr',
            subtitle: 'Portafoglio rimanente',
            icon: Icons.account_balance_wallet_outlined,
            color: summary.remainingBudget < 0 ? Colors.red : AppColors.accent,
            progress: 1.0 - summary.overallBudgetProgress,
            progressColor: summary.remainingBudget < 0 ? Colors.red : AppColors.accent,
          ),
          StatCard(
            title: l10n.translate('strategy_balance'),
            value: summary.formattedTotalOverUnder,
            subtitle: summary.totalOverUnderBudget > 0
                ? 'Extra da riutilizzare'
                : (summary.totalOverUnderBudget < 0 ? 'Sforamento budget' : 'In target'),
            icon: summary.totalOverUnderBudget >= 0 ? Icons.savings_outlined : Icons.warning_amber_rounded,
            color: summary.totalOverUnderBudget > 0
                ? AppColors.accent
                : (summary.totalOverUnderBudget < 0 ? Colors.red : Colors.blueGrey),
          ),
          StatCard(
            title: l10n.translate('remaining_slots'),
            value: '${summary.remainingSlots} / ${summary.totalSlots}',
            subtitle: '${summary.totalAcquired} giocatori acquistati',
            icon: Icons.group_outlined,
            color: AppColors.primaryLight,
            progress: summary.overallSlotProgress,
          ),
        ];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              Text(
                l10n.translate('roster_title'),
                style: TextStyle(fontSize: isMobile ? 22 : 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitoraggio live del budget, delle quote per ruolo e dei calciatori acquistati',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 16),

              // Top Stat Cards
              if (isMobile)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 8),
                        Expanded(child: cards[1]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: cards[2]),
                        const SizedBox(width: 8),
                        Expanded(child: cards[3]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    cards[4],
                  ],
                )
              else if (constraints.maxWidth < 1100)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 48 - 12) / 2, child: c)).toList(),
                )
              else
                Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
              const SizedBox(height: 20),

              // Per-Role Budget & Slot Summary Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Riepilogo per Ruolo',
                              style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: summary.totalOverUnderBudget > 0
                                  ? AppColors.accent.withValues(alpha: 0.12)
                                  : (summary.totalOverUnderBudget < 0
                                      ? Colors.red.withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: summary.totalOverUnderBudget > 0
                                    ? AppColors.accent.withValues(alpha: 0.3)
                                    : (summary.totalOverUnderBudget < 0 ? Colors.red.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  summary.totalOverUnderBudget >= 0 ? Icons.savings_outlined : Icons.warning_amber_rounded,
                                  size: 14,
                                  color: summary.totalOverUnderBudget > 0
                                      ? AppColors.accent
                                      : (summary.totalOverUnderBudget < 0 ? Colors.red : Colors.grey),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Bilancio: ${summary.formattedTotalOverUnder}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: summary.totalOverUnderBudget > 0
                                        ? AppColors.accent
                                        : (summary.totalOverUnderBudget < 0 ? Colors.red : Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Mobile Role Cards (< 750px) vs Desktop Table (>= 750px)
                      if (isMobile)
                        Column(
                          children: ['P', 'D', 'C', 'A'].map((role) {
                            final rSum = summary.roleSummaries[role];
                            final roleColor = AppColors.getRoleColor(role);
                            final roleName = l10n.translate('role_$role');
                            final isCompleted = rSum?.isCompleted ?? false;
                            final delta = rSum?.roleDelta ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161F30) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCompleted
                                      ? AppColors.accent.withValues(alpha: 0.4)
                                      : roleColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          RoleBadge(role: role),
                                          const SizedBox(width: 8),
                                          Text(
                                            roleName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (rSum?.remainingSlots ?? 0) == 0
                                                  ? AppColors.accent.withValues(alpha: 0.15)
                                                  : AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${rSum?.acquiredCount ?? 0}/${rSum?.totalSlots ?? 0} slot',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: (rSum?.remainingSlots ?? 0) == 0 ? AppColors.accent : AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          if (isCompleted && delta != 0) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              rSum!.formattedDelta,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: delta > 0 ? AppColors.accent : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: rSum?.slotProgress ?? 0.0,
                                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isCompleted ? AppColors.accent : roleColor,
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Allocato: ${rSum?.allocatedBudget ?? 0} cr (${rSum?.targetPercentage.toStringAsFixed(0)}%)',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                                      ),
                                      Text(
                                        'Speso: ${rSum?.spentBudget ?? 0} cr',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[700]),
                                      ),
                                      Text(
                                        'Residuo: ${rSum?.remainingBudget ?? 0} cr',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: (rSum?.remainingBudget ?? 0) < 0 ? Colors.red : AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Table(
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 1,
                            ),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(0.9),
                            2: FlexColumnWidth(0.9),
                            3: FlexColumnWidth(0.9),
                            4: FlexColumnWidth(1.0),
                            5: FlexColumnWidth(1.2),
                            6: FlexColumnWidth(1.2),
                            7: FlexColumnWidth(1.2),
                            8: FlexColumnWidth(1.1),
                            9: FlexColumnWidth(1.5),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                              ),
                              children: const [
                                _TableCell('RUOLO', isHeader: true),
                                _TableCell('SLOT', isHeader: true),
                                _TableCell('ACQ.', isHeader: true),
                                _TableCell('RIM.', isHeader: true),
                                _TableCell('% STRAT.', isHeader: true),
                                _TableCell('ALLOCATO', isHeader: true),
                                _TableCell('SPESO', isHeader: true),
                                _TableCell('RESIDUO', isHeader: true),
                                _TableCell('DELTA', isHeader: true),
                                _TableCell('AVANZAMENTO', isHeader: true),
                              ],
                            ),
                            ...['P', 'D', 'C', 'A'].map((role) {
                              final rSum = summary.roleSummaries[role];
                              final roleColor = AppColors.getRoleColor(role);
                              final roleName = l10n.translate('role_$role');
                              final isCompleted = rSum?.isCompleted ?? false;
                              final delta = rSum?.roleDelta ?? 0;

                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                    child: Row(
                                      children: [
                                        RoleBadge(role: role),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            roleName,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _TableCell('${rSum?.totalSlots ?? 0}'),
                                  _TableCell('${rSum?.acquiredCount ?? 0}'),
                                  _TableCell(
                                    '${rSum?.remainingSlots ?? 0}',
                                    color: rSum?.remainingSlots == 0 ? Colors.grey : AppColors.primary,
                                    isBold: true,
                                  ),
                                  _TableCell('${rSum?.targetPercentage.toStringAsFixed(0)}%'),
                                  _TableCell('${rSum?.allocatedBudget ?? 0} cr'),
                                  _TableCell('${rSum?.spentBudget ?? 0} cr'),
                                  _TableCell(
                                    '${rSum?.remainingBudget ?? 0} cr',
                                    color: (rSum?.remainingBudget ?? 0) < 0 ? Colors.red : AppColors.accent,
                                    isBold: true,
                                  ),
                                  _TableCell(
                                    isCompleted || delta != 0 ? rSum!.formattedDelta : '-',
                                    color: delta > 0
                                        ? AppColors.accent
                                        : (delta < 0 ? Colors.red : Colors.grey),
                                    isBold: delta != 0,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: rSum?.slotProgress ?? 0.0,
                                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isCompleted ? AppColors.accent : roleColor,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Official Roster Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Rosa (${minePlayers.length}/${summary.totalSlots})',
                              style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'Spesi: ${summary.totalSpent} cr',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (minePlayers.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              l10n.translate('roster_empty'),
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: minePlayers.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          itemBuilder: (context, index) {
                            final player = minePlayers[index];
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 12, vertical: 2),
                              leading: RoleBadge(role: player.role),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    player.team,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: player.notes.isNotEmpty
                                  ? Text(player.notes, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusMine.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.statusMine.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      '${player.purchasePrice ?? 0} cr',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.statusMine,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Modifica prezzo',
                                    onPressed: () => _editPurchasePrice(context, ref, player),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'Rimuovi dalla rosa',
                                    onPressed: () => _confirmRemovePlayer(context, ref, player),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isBold;
  final Color? color;

  const _TableCell(
    this.text, {
    this.isHeader = false,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      child: Text(
        text,
        textAlign: isHeader ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 10 : 12,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
