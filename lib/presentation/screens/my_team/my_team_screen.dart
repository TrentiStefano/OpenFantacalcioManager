import 'package:flutter/material.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title
          Text(
            l10n.translate('roster_title'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Monitoraggio live del budget, delle quote per ruolo e dei calciatori acquistati',
            style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 20),

          // Top Stat Cards (5 Cards)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
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

              if (isNarrow) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 24) / 2, child: c)).toList(),
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Per-Role Budget & Slot Summary Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Riepilogo per Ruolo (Strategia, Budget & Slot)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                              size: 16,
                              color: summary.totalOverUnderBudget > 0
                                  ? AppColors.accent
                                  : (summary.totalOverUnderBudget < 0 ? Colors.red : Colors.grey),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Bilancio Extra: ${summary.formattedTotalOverUnder}',
                              style: TextStyle(
                                fontSize: 12,
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
                  const SizedBox(height: 16),
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
                      // Header Row
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
                      // Data Rows for P, D, C, A
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
          const SizedBox(height: 24),

          // Official Roster Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calciatori Acquistati (${minePlayers.length} su ${summary.totalSlots})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Spesa complessiva: ${summary.totalSpent} cr',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                          leading: RoleBadge(role: player.role),
                          title: Row(
                            children: [
                              Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: 'Modifica prezzo',
                                onPressed: () => _editPurchasePrice(context, ref, player),
                              ),
                              IconButton(
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
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final Color? color;
  final bool isBold;

  const _TableCell(
    this.text, {
    this.isHeader = false,
    this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 13,
          fontWeight: isHeader ? FontWeight.bold : (isBold ? FontWeight.bold : FontWeight.normal),
          color: color,
        ),
      ),
    );
  }
}
