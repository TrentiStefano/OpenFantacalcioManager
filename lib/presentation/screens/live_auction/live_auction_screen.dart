import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_tiers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/player.dart';
import '../../../data/models/league_settings.dart';
import '../../providers/players_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/summary_provider.dart';
import '../../shared/role_badge.dart';
import '../../shared/tier_badge.dart';
import '../../shared/status_badge.dart';

class LiveAuctionScreen extends ConsumerStatefulWidget {
  const LiveAuctionScreen({super.key});

  @override
  ConsumerState<LiveAuctionScreen> createState() => _LiveAuctionScreenState();
}

class _LiveAuctionScreenState extends ConsumerState<LiveAuctionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _hammerPriceController = TextEditingController();
  int? _selectedPlayerId;
  String? _poolRoleFilter;
  int _mobileAuctionTab = 0; // 0 = Asta In Corso, 1 = Cerca / Chiama Giocatore

  @override
  void dispose() {
    _searchController.dispose();
    _hammerPriceController.dispose();
    super.dispose();
  }

  void _selectPlayer(Player player, int initialBudget) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPlayerId = player.id;
      // Pre-fill hammer price with target price or base value
      final target = player.targetPrice ?? player.calculateBaseValue(initialBudget);
      _hammerPriceController.text = target > 0 ? target.toString() : '1';
      _mobileAuctionTab = 0; // Switch to live focus on mobile
    });
  }

  void _adjustHammerPrice(int delta) {
    HapticFeedback.lightImpact();
    final current = int.tryParse(_hammerPriceController.text.trim()) ?? 1;
    final updated = (current + delta).clamp(1, 9999);
    _hammerPriceController.text = updated.toString();
    setState(() {});
  }

  Future<void> _assignToMe(Player player) async {
    final price = int.tryParse(_hammerPriceController.text.trim());
    if (price == null || price < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un prezzo di aggiudicazione valido (>= 1 credit).')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await ref.read(playersProvider.notifier).assignToMe(player.id, price);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name} assegnato alla tua rosa per $price crediti!'),
          backgroundColor: AppColors.statusMine,
        ),
      );
    }
  }

  Future<void> _soldToOthers(Player player) async {
    HapticFeedback.lightImpact();
    await ref.read(playersProvider.notifier).soldToOthers(player.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name} segnato come venduto ad altri manager.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  Future<void> _makeAvailable(Player player) async {
    HapticFeedback.selectionClick();
    await ref.read(playersProvider.notifier).makeAvailable(player.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${player.name} rimesso disponibile nell\'asta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final players = ref.watch(playersProvider).value ?? [];
    final settings = ref.watch(settingsProvider).value ?? const LeagueSettings();
    final summary = ref.watch(auctionSummaryProvider);

    final selectedPlayer = _selectedPlayerId != null
        ? players.where((p) => p.id == _selectedPlayerId).firstOrNull
        : null;

    final query = _searchController.text.toLowerCase().trim();
    final poolPlayers = players.where((p) {
      if (p.isCeduto) return false;
      if (_poolRoleFilter != null && p.role.toUpperCase() != _poolRoleFilter) return false;
      if (query.isNotEmpty) {
        return p.name.toLowerCase().contains(query) || p.team.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 850;

          return Column(
            children: [
              // Sticky Responsive Mini-Dashboard
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: isMobile ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131C2E) : const Color(0xFFEFF6FF),
                  border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFBFDBFE))),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildBudgetCard(summary, isDark)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildDeltaCard(summary, isDark)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: ['P', 'D', 'C', 'A'].map((role) {
                                return _buildRoleSlotItem(role, summary, isDark, compact: true);
                              }).toList(),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _buildBudgetCard(summary, isDark),
                          const SizedBox(width: 10),
                          _buildDeltaCard(summary, isDark),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: ['P', 'D', 'C', 'A'].map((role) {
                                return Expanded(child: _buildRoleSlotItem(role, summary, isDark));
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
              ),

              // Mobile Segmented Switcher (< 850px)
              if (isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: [
                            ButtonSegment(
                              value: 0,
                              icon: const Icon(Icons.gavel, size: 16),
                              label: Text(
                                selectedPlayer != null ? selectedPlayer.name : 'In Asta',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ButtonSegment(
                              value: 1,
                              icon: const Icon(Icons.people_outline, size: 16),
                              label: Text('Chiama (${poolPlayers.length})'),
                            ),
                          ],
                          selected: {_mobileAuctionTab},
                          onSelectionChanged: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _mobileAuctionTab = val.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Main Workspace
              Expanded(
                child: isMobile
                    ? (_mobileAuctionTab == 0
                        // Mobile Tab 0: Active Card (or empty call invitation)
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16.0),
                            child: selectedPlayer == null
                                ? _buildEmptyMobileAuctionState(l10n)
                                : _buildActivePlayerCard(selectedPlayer, settings, isDark, l10n, isMobile: true),
                          )
                        // Mobile Tab 1: Search & Pool
                        : _buildPlayerPool(poolPlayers, settings, isDark, l10n))
                    // Desktop / Tablet (>= 850px): Side-by-Side Studio
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20.0),
                              child: selectedPlayer == null
                                  ? Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(40.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.gavel, size: 64, color: Colors.grey[400]),
                                            const SizedBox(height: 16),
                                            Text(
                                              l10n.translate('no_player_selected'),
                                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Cerca un calciatore nel pannello di destra e clicca per aprire l\'asta in corso.',
                                              style: TextStyle(fontSize: 13, color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _buildActivePlayerCard(selectedPlayer, settings, isDark, l10n),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                              ),
                              child: _buildPlayerPool(poolPlayers, settings, isDark, l10n),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyMobileAuctionState(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel_rounded, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 14),
            Text(
              l10n.translate('no_player_selected'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nessun calciatore attualmente chiamato all\'asta.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _mobileAuctionTab = 1);
              },
              icon: const Icon(Icons.search),
              label: const Text('Cerca e Chiama Giocatore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(dynamic summary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RESIDUO TOTALE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                '${summary.remainingBudget} cr',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaCard(dynamic summary, bool isDark) {
    final hasExtra = summary.totalOverUnderBudget > 0;
    final hasLoss = summary.totalOverUnderBudget < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasExtra
            ? AppColors.accent.withValues(alpha: 0.12)
            : (hasLoss ? Colors.red.withValues(alpha: 0.12) : (isDark ? AppColors.darkCard : Colors.white)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasExtra
              ? AppColors.accent.withValues(alpha: 0.4)
              : (hasLoss ? Colors.red.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasExtra ? Icons.savings_outlined : (hasLoss ? Icons.warning_amber_rounded : Icons.insights),
            color: hasExtra ? AppColors.accent : (hasLoss ? Colors.red : Colors.grey),
            size: 18,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasExtra ? 'EXTRA BUDGET' : (hasLoss ? 'SFORAMENTO' : 'BILANCIO'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: hasExtra ? AppColors.accent : (hasLoss ? Colors.red : Colors.grey),
                ),
              ),
              Text(
                summary.formattedTotalOverUnder,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: hasExtra ? AppColors.accent : (hasLoss ? Colors.red : (isDark ? Colors.white : Colors.black87)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSlotItem(String role, dynamic summary, bool isDark, {bool compact = false}) {
    final rSum = summary.roleSummaries[role];
    final roleColor = AppColors.getRoleColor(role);
    final remainingSlots = rSum?.remainingSlots ?? 0;
    final remainingCredits = rSum?.remainingBudget ?? 0;
    final isCompleted = rSum?.isCompleted ?? false;
    final delta = rSum?.roleDelta ?? 0;

    return Container(
      width: compact ? 105 : null,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? AppColors.accent.withValues(alpha: 0.4) : roleColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role,
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  if (isCompleted && delta != 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      rSum!.formattedDelta,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: delta > 0 ? AppColors.accent : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
              if (!compact) const SizedBox(width: 6),
              Text(
                isCompleted ? 'Completo' : '$remainingSlots liberi',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.w600,
                  color: isCompleted ? AppColors.accent : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: rSum?.slotProgress ?? 0.0,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.accent : roleColor,
              ),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$remainingCredits cr',
            style: TextStyle(
              fontSize: 10,
              color: remainingCredits < 0 ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[700]),
              fontWeight: remainingCredits < 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPool(List<Player> poolPlayers, LeagueSettings settings, bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        // Pool Search & Role Tabs
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.translate('search_player_hint'),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('TUTTI', style: TextStyle(fontSize: 11)),
                      selected: _poolRoleFilter == null,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _poolRoleFilter = null);
                      },
                    ),
                    const SizedBox(width: 6),
                    ...['P', 'D', 'C', 'A'].map((r) {
                      final isSel = _poolRoleFilter == r;
                      final color = AppColors.getRoleColor(r);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(
                            r,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : color,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: color,
                          onSelected: (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _poolRoleFilter = val ? r : null);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Pool List
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: poolPlayers.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            itemBuilder: (context, index) {
              final p = poolPlayers[index];
              final isSelected = p.id == _selectedPlayerId;
              final baseVal = p.calculateBaseValue(settings.initialBudget);

              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                leading: RoleBadge(role: p.role),
                title: Row(
                  children: [
                    if (p.isFavorite) ...[
                      const Icon(Icons.star, size: 14, color: AppColors.starActive),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.status == PlayerStatus.mine
                              ? AppColors.statusMine
                              : (p.status == PlayerStatus.others ? Colors.grey : null),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(p.team, style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TierBadge(tier: p.tier),
                    const SizedBox(width: 8),
                    Text(
                      '$baseVal cr',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(status: p.status, purchasePrice: p.purchasePrice),
                  ],
                ),
                onTap: () => _selectPlayer(p, settings.initialBudget),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivePlayerCard(
    Player player,
    LeagueSettings settings,
    bool isDark,
    AppLocalizations l10n, {
    bool isMobile = false,
  }) {
    final baseValue = player.calculateBaseValue(settings.initialBudget);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badges, Star, Change button on mobile
            Row(
              children: [
                RoleBadge(
                  role: player.role,
                  mantraRole: player.roleMantra,
                  showMantra: settings.isMantra,
                  size: 32,
                ),
                const SizedBox(width: 10),
                TierBadge(
                  tier: player.tier,
                  availableTiers: player.role == 'P' ? AppTiers.goalkeeperTiers : settings.availableTiers,
                  onTierChanged: (newTier) {
                    ref.read(playersProvider.notifier).updateTier(player.id, newTier);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    player.isFavorite ? Icons.star : Icons.star_border,
                    color: player.isFavorite ? AppColors.starActive : Colors.grey,
                    size: 26,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(playersProvider.notifier).toggleFavorite(player.id);
                  },
                ),
                if (isMobile)
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _mobileAuctionTab = 1);
                    },
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Cambia'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Player Name and Club
            Text(
              player.name,
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              player.team.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem('QT. ATTUALE', '${player.qtA.toStringAsFixed(0)} cr'),
                  _metricItem('FVM', (settings.isMantra && player.fvmM > 0 ? player.fvmM : player.fvm).toStringAsFixed(0)),
                  _metricItem('BASE ASTA', '$baseValue cr', highlightColor: AppColors.primary),
                  _metricItem('TARGET', player.targetPrice != null ? '${player.targetPrice} cr' : '- cr', highlightColor: AppColors.accent),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Strategic Notes
            if (player.notes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        player.notes,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 14),

            // Tactile Bidding Steppers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Offerta Asta',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _hammerPriceController.text = baseValue > 0 ? baseValue.toString() : '1';
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Usa Base', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ),
                    if (player.targetPrice != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _hammerPriceController.text = player.targetPrice.toString();
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Usa Target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bid stepper buttons row
            Row(
              children: [
                _buildStepperButton('-5', () => _adjustHammerPrice(-5)),
                const SizedBox(width: 6),
                _buildStepperButton('-1', () => _adjustHammerPrice(-1)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hammerPriceController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      suffixText: 'cr',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStepperButton('+1', () => _adjustHammerPrice(1)),
                const SizedBox(width: 6),
                _buildStepperButton('+5', () => _adjustHammerPrice(5)),
                const SizedBox(width: 6),
                _buildStepperButton('+10', () => _adjustHammerPrice(10)),
              ],
            ),
            const SizedBox(height: 16),

            // Action: Assegna a me (Mio!)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _assignToMe(player),
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text(
                  l10n.translate('assign_to_me'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusMine,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Actions: Sold to others / Reset
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _soldToOthers(player),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                    label: Text(
                      l10n.translate('sold_to_others'),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (player.status != PlayerStatus.available) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeAvailable(player),
                      icon: const Icon(Icons.undo, size: 18),
                      label: Text(
                        l10n.translate('reset_available'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperButton(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, {Color? highlightColor}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: highlightColor,
          ),
        ),
      ],
    );
  }
}
