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

  @override
  void dispose() {
    _searchController.dispose();
    _hammerPriceController.dispose();
    super.dispose();
  }

  void _selectPlayer(Player player, int initialBudget) {
    setState(() {
      _selectedPlayerId = player.id;
      // Pre-fill hammer price with target price or base value
      final target = player.targetPrice ?? player.calculateBaseValue(initialBudget);
      _hammerPriceController.text = target > 0 ? target.toString() : '1';
    });
  }

  Future<void> _assignToMe(Player player) async {
    final price = int.tryParse(_hammerPriceController.text.trim());
    if (price == null || price < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un prezzo di aggiudicazione valido (>= 1 credit).')),
      );
      return;
    }

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
      body: Column(
        children: [
          // Persistent Sticky Mini-Dashboard
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C2E) : const Color(0xFFEFF6FF),
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFBFDBFE))),
            ),
            child: Row(
              children: [
                // Overall Budget Remaining
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESIDUO TOTALE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '${summary.remainingBudget} / ${summary.initialBudget} cr',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Slots by Role Badges & Meters
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['P', 'D', 'C', 'A'].map((role) {
                      final rSum = summary.roleSummaries[role];
                      final roleColor = AppColors.getRoleColor(role);
                      final remainingSlots = rSum?.remainingSlots ?? 0;
                      final totalSlots = rSum?.totalSlots ?? 0;
                      final remainingCredits = rSum?.remainingBudget ?? 0;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    role,
                                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    '$remainingSlots slot liberi',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: rSum?.slotProgress ?? 0.0,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(roleColor),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Budget res: $remainingCredits cr',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: remainingCredits < 0 ? Colors.red : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                  fontWeight: remainingCredits < 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Main Auction workspace: Active Card (top/left) + Player Pool list (bottom/right)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Active Player Focus Card & Action Buttons
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
                                    'Cerca un giocatore sulla destra o clicca su uno per chiamarlo all\'asta.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildActivePlayerCard(
                            selectedPlayer,
                            settings,
                            isDark,
                            l10n,
                          ),
                  ),
                ),

                // Right Column: Search & Available Players Pool
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    ),
                    child: Column(
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
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('TUTTI', style: TextStyle(fontSize: 11)),
                                    selected: _poolRoleFilter == null,
                                    onSelected: (_) => setState(() => _poolRoleFilter = null),
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
                                        onSelected: (val) => setState(() => _poolRoleFilter = val ? r : null),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Pool List
                        Expanded(
                          child: ListView.separated(
                            itemCount: poolPlayers.length,
                            separatorBuilder: (_, __) => Divider(
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlayerCard(
    Player player,
    LeagueSettings settings,
    bool isDark,
    AppLocalizations l10n,
  ) {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badges, Star, Status
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
                    ref.read(playersProvider.notifier).toggleFavorite(player.id);
                  },
                ),
                const SizedBox(width: 6),
                StatusBadge(status: player.status, purchasePrice: player.purchasePrice),
              ],
            ),
            const SizedBox(height: 16),

            // Player Name and Club
            Text(
              player.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              player.team.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Quotation, FVM, Base Value, Target Price Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem('QUOTAZIONE (Qt.A)', '${player.qtA.toStringAsFixed(0)} cr'),
                  _metricItem('FVM', (settings.isMantra && player.fvmM > 0 ? player.fvmM : player.fvm).toStringAsFixed(0)),
                  _metricItem('BASE ASTA', '$baseValue cr', highlightColor: AppColors.primary),
                  _metricItem('TARGET CONSIGLIATO', player.targetPrice != null ? '${player.targetPrice} cr' : '- cr', highlightColor: AppColors.accent),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Strategic Notes
            if (player.notes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        player.notes,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Divider(),
            const SizedBox(height: 16),

            // Bidding Hammer Input & 3 Actions
            const Text(
              'Aggiudicazione Giocatore',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Hammer Price Input
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _hammerPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Prezzo Finale',
                      suffixText: 'cr',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Assegna a me Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _assignToMe(player),
                    icon: const Icon(Icons.check_circle),
                    label: Text(l10n.translate('assign_to_me')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusMine,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Other Actions: Venduto ad altri / Rimetti disponibile
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _soldToOthers(player),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: Text(
                      l10n.translate('sold_to_others'),
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (player.status != PlayerStatus.available) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeAvailable(player),
                      icon: const Icon(Icons.undo),
                      label: Text(l10n.translate('reset_available')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _metricItem(String label, String value, {Color? highlightColor}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: highlightColor,
          ),
        ),
      ],
    );
  }
}
