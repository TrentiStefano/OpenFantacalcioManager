import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tiers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/player.dart';
import '../../../data/models/league_settings.dart';
import '../../providers/players_provider.dart';
import '../../providers/settings_provider.dart';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
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
      ),
      body: playersAsync.when(
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

    return Column(
      children: [
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
                  separatorBuilder: (_, __) => Divider(
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
