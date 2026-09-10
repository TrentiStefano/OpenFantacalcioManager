import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tiers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/player.dart';
import '../../../data/models/league_settings.dart';
import '../../providers/players_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/summary_provider.dart';
import '../../shared/tier_badge.dart';
import '../../shared/editable_budget_cell.dart';

class StrategyScreen extends ConsumerStatefulWidget {
  const StrategyScreen({super.key});

  @override
  ConsumerState<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends ConsumerState<StrategyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _roles = ['P', 'D', 'C', 'A'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playersAsync = ref.watch(playersProvider);
    final settings = ref.watch(settingsProvider).value ?? const LeagueSettings();

    return Scaffold(
      body: Column(
        children: [
          const _StrategyTargetPanel(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: _roles.map((role) {
                final roleName = l10n.translate('role_$role');
                final color = AppColors.getRoleColor(role);
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(roleName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: playersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (allPlayers) {
                return TabBarView(
                  controller: _tabController,
                  children: _roles.map((role) {
                    return _RoleStrategyView(
                      role: role,
                      players: allPlayers,
                      settings: settings,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleStrategyView extends ConsumerWidget {
  final String role;
  final List<Player> players;
  final LeagueSettings settings;

  const _RoleStrategyView({
    required this.role,
    required this.players,
    required this.settings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter players for this role and sort by Tier priority then base value DESC
    final rolePlayers = players.where((p) => p.role.toUpperCase() == role && !p.isCeduto).toList();
    rolePlayers.sort((a, b) {
      final tierComp = AppTiers.getPriority(a.tier).compareTo(AppTiers.getPriority(b.tier));
      if (tierComp != 0) return tierComp;
      final valA = a.calculateBaseValue(settings.initialBudget);
      final valB = b.calculateBaseValue(settings.initialBudget);
      return valB.compareTo(valA);
    });

    final roleTiers = role == 'P' ? AppTiers.goalkeeperTiers : settings.availableTiers;

    final summary = ref.watch(auctionSummaryProvider);
    final rSum = summary.roleSummaries[role];
    final roleColor = AppColors.getRoleColor(role);
    final roleName = AppLocalizations.of(context).translate('role_$role');

    return Column(
      children: [
        // Role strategy summary banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: isDark ? 0.12 : 0.06),
            border: Border(
              bottom: BorderSide(
                color: roleColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  role,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$roleName: ',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'Target: ${rSum?.allocatedBudget ?? 0} cr (${(settings.targetPercentages[role] ?? 0.0).toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 12),
              Text(
                'Spesi: ${rSum?.spentBudget ?? 0} cr (${rSum?.acquiredCount ?? 0}/${rSum?.totalSlots ?? 0} slot)',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rimasti da spendere: ', style: TextStyle(fontSize: 12)),
                  Text(
                    '${rSum?.remainingBudget ?? 0} cr',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: (rSum?.remainingBudget ?? 0) < 0 ? Colors.red : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (rSum != null && (rSum.isCompleted || rSum.roleDelta != 0)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: rSum.roleDelta > 0
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : (rSum.roleDelta < 0
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: rSum.roleDelta > 0
                          ? AppColors.accent.withValues(alpha: 0.3)
                          : (rSum.roleDelta < 0 ? Colors.red.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rSum.roleDelta > 0
                            ? Icons.savings_outlined
                            : (rSum.roleDelta < 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                        size: 14,
                        color: rSum.roleDelta > 0
                            ? AppColors.accent
                            : (rSum.roleDelta < 0 ? Colors.red : Colors.grey),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        rSum.roleDelta > 0
                            ? 'Risparmio: ${rSum.formattedDelta}'
                            : (rSum.roleDelta < 0
                                ? 'Sforamento: ${rSum.formattedDelta}'
                                : 'In budget'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: rSum.roleDelta > 0
                              ? AppColors.accent
                              : (rSum.roleDelta < 0 ? Colors.red : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Role strategy table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9),
          child: const Row(
            children: [
              SizedBox(width: 34), // Star
              Expanded(flex: 3, child: Text('CALCIATORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('SQUADRA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('FVM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('% BUDGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('BASE ASTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('FASCIA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('PREZZO OBIETTIVO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('NOTE STRATEGICHE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
        ),

        Expanded(
          child: rolePlayers.isEmpty
              ? const Center(child: Text('Nessun giocatore caricato per questo ruolo.'))
              : ListView.separated(
                  itemCount: rolePlayers.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  itemBuilder: (context, index) {
                    final player = rolePlayers[index];
                    final baseValue = player.calculateBaseValue(settings.initialBudget);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          // Favorite star
                          SizedBox(
                            width: 34,
                            child: IconButton(
                              icon: Icon(
                                player.isFavorite ? Icons.star : Icons.star_border,
                                color: player.isFavorite ? AppColors.starActive : Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () {
                                ref.read(playersProvider.notifier).toggleFavorite(player.id);
                              },
                            ),
                          ),
                          // Name
                          Expanded(
                            flex: 3,
                            child: Text(
                              player.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          // Team
                          Expanded(
                            flex: 2,
                            child: Text(
                              player.team,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          // FVM
                          Expanded(
                            flex: 1,
                            child: Text(
                              (settings.isMantra && player.fvmM > 0 ? player.fvmM : player.fvm).toStringAsFixed(0),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          // % Budget (interactive inline cell)
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: EditableBudgetCell(
                                budgetPercent: player.budgetPercent,
                                onPercentChanged: (newPct) {
                                  ref.read(playersProvider.notifier).updateBudgetPercent(player.id, newPct);
                                },
                              ),
                            ),
                          ),
                          // Base auction value
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$baseValue cr',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: baseValue > 0 ? AppColors.primary : Colors.grey,
                              ),
                            ),
                          ),
                          // Tier
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TierBadge(
                                tier: player.tier,
                                availableTiers: roleTiers,
                                onTierChanged: (newTier) {
                                  ref.read(playersProvider.notifier).updateTier(player.id, newTier);
                                },
                              ),
                            ),
                          ),
                          // Prezzo Obiettivo (Target Price)
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _TargetPriceInput(
                                player: player,
                                onTargetPriceChanged: (val) {
                                  ref.read(playersProvider.notifier).updateTargetPrice(player.id, val);
                                },
                              ),
                            ),
                          ),
                          // Note (Notes)
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _NotesInput(
                                player: player,
                                onNotesChanged: (val) {
                                  ref.read(playersProvider.notifier).updateNotes(player.id, val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TargetPriceInput extends StatefulWidget {
  final Player player;
  final ValueChanged<int?> onTargetPriceChanged;

  const _TargetPriceInput({
    required this.player,
    required this.onTargetPriceChanged,
  });

  @override
  State<_TargetPriceInput> createState() => _TargetPriceInputState();
}

class _TargetPriceInputState extends State<_TargetPriceInput> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.player.targetPrice?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _TargetPriceInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.player.targetPrice != widget.player.targetPrice) {
      _controller.text = widget.player.targetPrice?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final text = _controller.text.trim();
    final parsed = int.tryParse(text);
    widget.onTargetPriceChanged(parsed);
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 70,
        height: 32,
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            suffixText: 'cr',
            suffixStyle: const TextStyle(fontSize: 10),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onSubmitted: (_) => _commit(),
        ),
      );
    }

    final hasVal = widget.player.targetPrice != null;
    return InkWell(
      onTap: () {
        setState(() {
          _isEditing = true;
          _controller.text = widget.player.targetPrice?.toString() ?? '';
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hasVal ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasVal ? AppColors.accent.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          hasVal ? '${widget.player.targetPrice} cr' : '- cr',
          style: TextStyle(
            fontWeight: hasVal ? FontWeight.bold : FontWeight.normal,
            color: hasVal ? AppColors.accent : Colors.grey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _NotesInput extends StatefulWidget {
  final Player player;
  final ValueChanged<String> onNotesChanged;

  const _NotesInput({
    required this.player,
    required this.onNotesChanged,
  });

  @override
  State<_NotesInput> createState() => _NotesInputState();
}

class _NotesInputState extends State<_NotesInput> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.player.notes);
  }

  @override
  void didUpdateWidget(covariant _NotesInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.player.notes != widget.player.notes) {
      _controller.text = widget.player.notes;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onNotesChanged(_controller.text.trim());
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        height: 34,
        child: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            isDense: true,
            hintText: 'Aggiungi nota...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onSubmitted: (_) => _commit(),
        ),
      );
    }

    final hasNotes = widget.player.notes.isNotEmpty;
    return InkWell(
      onTap: () {
        setState(() {
          _isEditing = true;
          _controller.text = widget.player.notes;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          hasNotes ? widget.player.notes : 'Clicca per aggiungere note...',
          style: TextStyle(
            fontSize: 12,
            fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
            color: hasNotes ? null : Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _StrategyTargetPanel extends ConsumerStatefulWidget {
  const _StrategyTargetPanel();

  @override
  ConsumerState<_StrategyTargetPanel> createState() => _StrategyTargetPanelState();
}

class _StrategyTargetPanelState extends ConsumerState<_StrategyTargetPanel> {
  bool _isCollapsed = false;

  void _adjustPercent(String role, double delta, LeagueSettings settings) {
    final currentMap = Map<String, double>.from(settings.targetPercentages);
    final currentVal = currentMap[role] ?? 0.0;
    final newVal = (currentVal + delta).clamp(0.0, 100.0);
    currentMap[role] = newVal;
    ref.read(settingsProvider.notifier).updateTargetPercentages(currentMap);
  }

  void _showEditPercentDialog(BuildContext context, String role, double currentVal, LeagueSettings settings) {
    final controller = TextEditingController(text: currentVal.toStringAsFixed(0));
    final roleName = AppLocalizations.of(context).translate('role_$role');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifica % Budget: $roleName ($role)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Percentuale target (%)',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 0 && parsed <= 100) {
                final currentMap = Map<String, double>.from(settings.targetPercentages);
                currentMap[role] = parsed;
                ref.read(settingsProvider.notifier).updateTargetPercentages(currentMap);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider).value ?? const LeagueSettings();
    final summary = ref.watch(auctionSummaryProvider);

    final totalDelta = summary.totalOverUnderBudget;
    final deltaColor = totalDelta > 0
        ? AppColors.accent
        : (totalDelta < 0 ? Colors.red : (isDark ? Colors.grey[400]! : Colors.grey[700]!));

    final totalPercent = settings.targetPercentages.values.fold(0.0, (sum, p) => sum + p);
    final is100 = (totalPercent - 100.0).abs() < 0.1;

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.psychology_alt, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('strategy_target_title'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.translate('strategy_target_subtitle'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).resetStrategyToDefault();
                  },
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: Text(
                    l10n.translate('reset_default_strategy'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isCollapsed ? Icons.expand_more : Icons.expand_less, size: 20),
                  tooltip: _isCollapsed ? 'Espandi Strategia' : 'Comprimi Strategia',
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                ),
              ],
            ),

            if (!_isCollapsed) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Role cards row and total delta card
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  final roleWidgets = ['P', 'D', 'C', 'A'].map((role) {
                    final roleColor = AppColors.getRoleColor(role);
                    final rSum = summary.roleSummaries[role];
                    final pct = settings.targetPercentages[role] ?? 0.0;
                    final allocated = rSum?.allocatedBudget ?? 0;
                    final spent = rSum?.spentBudget ?? 0;
                    final remaining = rSum?.remainingBudget ?? 0;
                    final isCompleted = rSum?.isCompleted ?? false;
                    final delta = rSum?.roleDelta ?? 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161F30) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.3),
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
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: roleColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      role,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.translate('role_$role'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: delta >= 0
                                        ? AppColors.accent.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rSum!.formattedDelta,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: delta >= 0 ? AppColors.accent : Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Percentage adjustment
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _adjustPercent(role, -1.0, settings),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.remove, size: 14),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showEditPercentDialog(context, role, pct, settings),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkCard : Colors.white,
                                      border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${pct.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _adjustPercent(role, 1.0, settings),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.add, size: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Target: $allocated cr',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                'Spesi: $spent cr',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Da spendere:', style: TextStyle(fontSize: 11)),
                              Text(
                                '$remaining cr',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: remaining < 0 ? Colors.red : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList();

                  final totalCard = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: totalDelta > 0
                          ? AppColors.accent.withValues(alpha: 0.1)
                          : (totalDelta < 0
                              ? Colors.red.withValues(alpha: 0.1)
                              : (isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9))),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: deltaColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.translate('strategy_balance').toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: deltaColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: is100
                                    ? AppColors.accent.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${l10n.translate('percent_total')}: ${totalPercent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: is100 ? AppColors.accent : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.formattedTotalOverUnder,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: deltaColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalDelta > 0
                              ? 'Spendendo $totalDelta cr in meno, hai crediti extra a disposizione per altri ruoli!'
                              : (totalDelta < 0
                                  ? 'Attenzione: sforamento di ${totalDelta.abs()} cr rispetto alla strategia.'
                                  : 'Spesa allineata alla strategia impostata.'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final w in roleWidgets) ...[
                          Expanded(child: w),
                          const SizedBox(width: 8),
                        ],
                        Expanded(flex: 2, child: totalCard),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          for (int i = 0; i < 2; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(child: roleWidgets[i]),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (int i = 2; i < 4; i++) ...[
                            if (i > 2) const SizedBox(width: 8),
                            Expanded(child: roleWidgets[i]),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      totalCard,
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
