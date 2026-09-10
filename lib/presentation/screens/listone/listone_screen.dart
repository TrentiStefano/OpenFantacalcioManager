import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    if (kIsWeb) {
      await FilePicker.platform.saveFile(
        dialogTitle: 'Salva Listone Excel',
        fileName: 'Asta_Fantacalcio_Export.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );
    } else {
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
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final players = ref.read(playersProvider).value ?? [];
    final settings = ref.read(settingsProvider).value ?? const LeagueSettings();
    final repo = ref.read(repositoryProvider);

    final csvContent = repo.exportToCsv(players, settings);
    if (kIsWeb) {
      await FilePicker.platform.saveFile(
        dialogTitle: 'Salva Listone CSV',
        fileName: 'Asta_Fantacalcio_Export.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(csvContent.codeUnits),
      );
    } else {
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
  }

  void _showPlayerDetailSheet(BuildContext context, WidgetRef ref, Player player, LeagueSettings settings) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseValue = player.calculateBaseValue(settings.initialBudget);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final priceController = TextEditingController(
          text: player.purchasePrice?.toString() ?? (player.targetPrice?.toString() ?? (baseValue > 0 ? baseValue.toString() : '1')),
        );
        final notesController = TextEditingController(text: player.notes);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final livePlayer = ref.watch(playersProvider).value?.firstWhere((p) => p.id == player.id, orElse: () => player) ?? player;
            final liveBaseValue = livePlayer.calculateBaseValue(settings.initialBudget);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grab handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title Header
                    Row(
                      children: [
                        RoleBadge(
                          role: livePlayer.role,
                          mantraRole: livePlayer.roleMantra,
                          showMantra: settings.isMantra,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                livePlayer.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                livePlayer.team,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            livePlayer.isFavorite ? Icons.star : Icons.star_border,
                            color: livePlayer.isFavorite ? AppColors.starActive : Colors.grey,
                            size: 26,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            ref.read(playersProvider.notifier).toggleFavorite(livePlayer.id);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Stats Grid Cards
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatPill('FVM', (settings.isMantra && livePlayer.fvmM > 0 ? livePlayer.fvmM : livePlayer.fvm).toStringAsFixed(0), isDark),
                        _buildStatPill('Base Asta', '$liveBaseValue cr', isDark, isHighlight: true),
                        _buildStatPill('Qt. Attuale', '${livePlayer.qtA}', isDark),
                        _buildStatPill('Qt. Iniziale', '${livePlayer.qtI}', isDark),
                        _buildStatPill('Diff', '${livePlayer.diff}', isDark),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Budget % and Target Price Controls
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Percentuale Budget', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              EditableBudgetCell(
                                budgetPercent: livePlayer.budgetPercent,
                                onPercentChanged: (newPct) {
                                  ref.read(playersProvider.notifier).updateBudgetPercent(livePlayer.id, newPct);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fascia / Tier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TierBadge(
                                tier: livePlayer.tier,
                                availableTiers: settings.availableTiers,
                                onTierChanged: (newTier) {
                                  ref.read(playersProvider.notifier).updateTier(livePlayer.id, newTier);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes input
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Note strategiche',
                        hintText: 'Es. Primo obiettivo, rigorista, coppia con...',
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check, size: 18),
                          onPressed: () {
                            ref.read(playersProvider.notifier).updateNotes(livePlayer.id, notesController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note salvate!')));
                          },
                        ),
                      ),
                      onSubmitted: (val) {
                        ref.read(playersProvider.notifier).updateNotes(livePlayer.id, val.trim());
                      },
                    ),
                    const SizedBox(height: 20),

                    // Auction Quick Actions
                    const Text('Stato Asta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusMine,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.gavel, size: 16),
                            label: const Text('Mio'),
                            onPressed: () async {
                              final price = int.tryParse(priceController.text.trim()) ?? (liveBaseValue > 0 ? liveBaseValue : 1);
                              await ref.read(playersProvider.notifier).assignToMe(livePlayer.id, price);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.people_alt_outlined, size: 16),
                            label: const Text('Ad altri'),
                            onPressed: () async {
                              await ref.read(playersProvider.notifier).soldToOthers(livePlayer.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Rendi disponibile',
                          onPressed: () async {
                            await ref.read(playersProvider.notifier).makeAvailable(livePlayer.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildStatPill(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.primary.withValues(alpha: 0.12)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.primary : null,
            ),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;

          return Column(
            children: [
              // Top Control & Filter Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 10),
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
                          child: TextField(
                            onChanged: filterNotifier.setSearchQuery,
                            decoration: InputDecoration(
                              hintText: l10n.translate('search_player_hint'),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              suffixIcon: filter.searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => filterNotifier.setSearchQuery(''),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isMobile) ...[
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
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.auto_fix_high, color: AppColors.accent),
                            tooltip: l10n.translate('suggest_fvm'),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref.read(playersProvider.notifier).suggestFromFvm(settings);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Percentuali di budget calcolate da FVM per tutti i ruoli!')),
                              );
                            },
                          ),
                        ],
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
                    const SizedBox(height: 8),

                    // Horizontal Scrolling Filter Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text(l10n.translate('filter_all_roles')),
                            selected: filter.roleFilter == null,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              filterNotifier.setRoleFilter(null);
                            },
                          ),
                          const SizedBox(width: 6),
                          ...['P', 'D', 'C', 'A'].map((r) {
                            final color = AppColors.getRoleColor(r);
                            final isSelected = filter.roleFilter == r;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: FilterChip(
                                label: Text(
                                  r,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: color,
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  filterNotifier.setRoleFilter(isSelected ? null : r);
                                },
                              ),
                            );
                          }),
                          const SizedBox(width: 6),

                          // Tier dropdown filter
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  filterNotifier.setTierFilter(val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Favorites Only Chip
                          FilterChip(
                            avatar: Icon(
                              filter.favoritesOnly ? Icons.star : Icons.star_border,
                              size: 16,
                              color: filter.favoritesOnly ? AppColors.starActive : Colors.grey,
                            ),
                            label: Text(l10n.translate('filter_favorites')),
                            selected: filter.favoritesOnly,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              filterNotifier.toggleFavoritesOnly();
                            },
                          ),
                          const SizedBox(width: 8),

                          Text(
                            '${filteredPlayers.length}/$totalCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Header Row (Only shown on Desktop/Tablet >= 750px)
              if (!isMobile)
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

              // Data Rows List: Mobile Cards vs Desktop Table Rows
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
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredPlayers.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
                          final baseValue = player.calculateBaseValue(settings.initialBudget);

                          // Mobile Card View (< 750px)
                          if (isMobile) {
                            return InkWell(
                              onTap: () => _showPlayerDetailSheet(context, ref, player, settings),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                color: player.status == PlayerStatus.mine
                                    ? AppColors.statusMine.withValues(alpha: isDark ? 0.08 : 0.04)
                                    : (player.status == PlayerStatus.others
                                        ? Colors.grey.withValues(alpha: isDark ? 0.08 : 0.04)
                                        : Colors.transparent),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Favorite Star
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            player.isFavorite ? Icons.star : Icons.star_border,
                                            color: player.isFavorite ? AppColors.starActive : Colors.grey[400],
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            ref.read(playersProvider.notifier).toggleFavorite(player.id);
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        RoleBadge(
                                          role: player.role,
                                          mantraRole: player.roleMantra,
                                          showMantra: settings.isMantra,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                player.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  decoration: player.isCeduto ? TextDecoration.lineThrough : null,
                                                  color: player.isCeduto ? Colors.grey : null,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                player.team,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        StatusBadge(
                                          status: player.status,
                                          purchasePrice: player.purchasePrice,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const SizedBox(width: 30), // Align with text
                                        // FVM Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'FVM ${(settings.isMantra && player.fvmM > 0 ? player.fvmM : player.fvm).toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Base Asta
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: baseValue > 0
                                                ? AppColors.primary.withValues(alpha: 0.12)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Base $baseValue cr',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: baseValue > 0 ? AppColors.primary : Colors.grey,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // % Budget
                                        Text(
                                          '${player.budgetPercent.toStringAsFixed(1)}%',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        const Spacer(),
                                        // Tier badge
                                        TierBadge(
                                          tier: player.tier,
                                          availableTiers: settings.availableTiers,
                                          onTierChanged: (newTier) {
                                            ref.read(playersProvider.notifier).updateTier(player.id, newTier);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Desktop / Tablet Table Row
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
                                      HapticFeedback.selectionClick();
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
          );
        },
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
