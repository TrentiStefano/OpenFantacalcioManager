import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/player.dart';
import '../../../data/models/league_settings.dart';
import '../../../domain/player_filter_sort.dart';
import '../../providers/players_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/filter_provider.dart';
import '../../shared/role_badge.dart';
import '../../shared/tier_badge.dart';
import '../../shared/status_badge.dart';
import '../../shared/editable_budget_cell.dart';

class ListoneScreen extends ConsumerWidget {
  const ListoneScreen({super.key});

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final players = ref.read(playersProvider).value ?? [];
    final settings = ref.read(settingsProvider).value ?? const LeagueSettings();
    final repo = ref.read(repositoryProvider);

    final bytes = repo.exportToExcel(players, settings);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salva Listone Excel',
      fileName: 'Asta_Fantacalcio_Export.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (path != null) {
      final file = File(path);
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File esportato con successo in $path')),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final players = ref.read(playersProvider).value ?? [];
    final settings = ref.read(settingsProvider).value ?? const LeagueSettings();
    final repo = ref.read(repositoryProvider);

    final csvContent = repo.exportToCsv(players, settings);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salva Listone CSV',
      fileName: 'Asta_Fantacalcio_Export.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (path != null) {
      final file = File(path);
      await file.writeAsString(csvContent);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV esportato con successo in $path')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final playersAsync = ref.watch(playersProvider);
    final filteredPlayers = ref.watch(filteredPlayersProvider);
    final filter = ref.watch(filterCriteriaProvider);
    final filterNotifier = ref.read(filterCriteriaProvider.notifier);
    final settings = ref.watch(settingsProvider).value ?? const LeagueSettings();

    if (playersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalCount = playersAsync.value?.length ?? 0;

    return Scaffold(
      body: Column(
        children: [
          // Top Control & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Column(
              children: [
                // Search & Action buttons row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: filterNotifier.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: l10n.translate('search_player_hint'),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          suffixIcon: filter.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => filterNotifier.setSearchQuery(''),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(playersProvider.notifier).suggestFromFvm(settings);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Percentuali di budget calcolate da FVM per tutti i ruoli!')),
                        );
                      },
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: Text(l10n.translate('suggest_fvm')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.download),
                      tooltip: 'Esporta',
                      onSelected: (val) {
                        if (val == 'xlsx') _exportExcel(context, ref);
                        if (val == 'csv') _exportCsv(context, ref);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'xlsx',
                          child: Row(
                            children: [
                              const Icon(Icons.table_chart, size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(l10n.translate('export_excel')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'csv',
                          child: Row(
                            children: [
                              const Icon(Icons.text_snippet, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(l10n.translate('export_csv')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filters Row: Role chips, Tier dropdown, Favorites toggle
                Row(
                  children: [
                    // Role Filter Chips
                    Wrap(
                      spacing: 6,
                      children: [
                        FilterChip(
                          label: Text(l10n.translate('filter_all_roles')),
                          selected: filter.roleFilter == null,
                          onSelected: (_) => filterNotifier.setRoleFilter(null),
                        ),
                        ...['P', 'D', 'C', 'A'].map((r) {
                          final color = AppColors.getRoleColor(r);
                          final isSelected = filter.roleFilter == r;
                          return FilterChip(
                            label: Text(
                              r,
                              style: TextStyle(
                                color: isSelected ? Colors.white : color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: color,
                            onSelected: (_) => filterNotifier.setRoleFilter(isSelected ? null : r),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Tier dropdown filter
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: filter.tierFilter,
                          hint: Text(
                            l10n.translate('filter_all_tiers'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          isDense: true,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.translate('filter_all_tiers'), style: const TextStyle(fontSize: 12)),
                            ),
                            ...settings.availableTiers.map((t) => DropdownMenuItem<String?>(
                                  value: t,
                                  child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                )),
                          ],
                          onChanged: (val) => filterNotifier.setTierFilter(val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Favorites Only Chip
                    FilterChip(
                      avatar: Icon(
                        filter.favoritesOnly ? Icons.star : Icons.star_border,
                        size: 16,
                        color: filter.favoritesOnly ? AppColors.starActive : Colors.grey,
                      ),
                      label: Text(l10n.translate('filter_favorites')),
                      selected: filter.favoritesOnly,
                      onSelected: (_) => filterNotifier.toggleFavoritesOnly(),
                    ),
                    const Spacer(),

                    Text(
                      '${filteredPlayers.length} / $totalCount ${l10n.translate('players_count')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const SizedBox(width: 34), // Star icon spacer
                _buildHeaderCell('RUOLO', flex: 1, sortCol: SortColumn.role, current: filter, notifier: filterNotifier),
                _buildHeaderCell('CALCIATORE', flex: 3, sortCol: SortColumn.name, current: filter, notifier: filterNotifier),
                _buildHeaderCell('SQUADRA', flex: 2, sortCol: SortColumn.team, current: filter, notifier: filterNotifier),
                _buildHeaderCell('FVM', flex: 1, sortCol: SortColumn.fvm, current: filter, notifier: filterNotifier),
                _buildHeaderCell('% BUDGET', flex: 2, sortCol: SortColumn.budgetPercent, current: filter, notifier: filterNotifier),
                _buildHeaderCell('BASE ASTA', flex: 2, sortCol: SortColumn.baseValue, current: filter, notifier: filterNotifier),
                _buildHeaderCell('FASCIA', flex: 2, sortCol: SortColumn.tier, current: filter, notifier: filterNotifier),
                _buildHeaderCell('STATO', flex: 2, current: filter, notifier: filterNotifier),
              ],
            ),
          ),

          // Data Rows List
          Expanded(
            child: filteredPlayers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'Nessun calciatore trovato con i filtri correnti.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredPlayers.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
                      final baseValue = player.calculateBaseValue(settings.initialBudget);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        color: player.status == PlayerStatus.mine
                            ? AppColors.statusMine.withValues(alpha: isDark ? 0.08 : 0.04)
                            : (player.status == PlayerStatus.others
                                ? Colors.grey.withValues(alpha: isDark ? 0.08 : 0.04)
                                : Colors.transparent),
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
                            // Role
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: RoleBadge(
                                  role: player.role,
                                  mantraRole: player.roleMantra,
                                  showMantra: settings.isMantra,
                                ),
                              ),
                            ),
                            // Name
                            Expanded(
                              flex: 3,
                              child: Text(
                                player.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: player.isCeduto ? TextDecoration.lineThrough : null,
                                  color: player.isCeduto ? Colors.grey : null,
                                ),
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
                            // Valore Base Asta (Computed instantly!)
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: baseValue > 0
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$baseValue cr',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: baseValue > 0 ? AppColors.primary : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Fascia (interactive dropdown selector)
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TierBadge(
                                  tier: player.tier,
                                  availableTiers: settings.availableTiers,
                                  onTierChanged: (newTier) {
                                    ref.read(playersProvider.notifier).updateTier(player.id, newTier);
                                  },
                                ),
                              ),
                            ),
                            // Status
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: StatusBadge(
                                  status: player.status,
                                  purchasePrice: player.purchasePrice,
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
      ),
    );
  }

  Widget _buildHeaderCell(
    String title, {
    required int flex,
    SortColumn? sortCol,
    required PlayerFilterCriteria current,
    required FilterCriteriaNotifier notifier,
  }) {
    final isSelected = sortCol != null && current.sortColumn == sortCol;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortCol != null ? () => notifier.setSort(sortCol) : null,
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                current.sortDirection == SortDirection.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 13,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
