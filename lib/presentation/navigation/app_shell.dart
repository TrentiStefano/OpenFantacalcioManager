import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/summary_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/import_setup/setup_screen.dart';
import '../screens/listone/listone_screen.dart';
import '../screens/strategy/strategy_screen.dart';
import '../screens/live_auction/live_auction_screen.dart';
import '../screens/my_team/my_team_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../shared/strategy_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 1; // Default to Listone

  final List<Widget> _screens = const [
    SetupScreen(),
    ListoneScreen(),
    StrategyScreen(),
    LiveAuctionScreen(),
    MyTeamScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = ref.watch(auctionSummaryProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        final destinations = [
          _NavDestination(icon: Icons.upload_file, label: l10n.translate('nav_setup')),
          _NavDestination(icon: Icons.table_rows_rounded, label: l10n.translate('nav_listone')),
          _NavDestination(icon: Icons.psychology_alt, label: l10n.translate('nav_strategy')),
          _NavDestination(icon: Icons.gavel_rounded, label: l10n.translate('nav_auction')),
          _NavDestination(icon: Icons.shield_outlined, label: l10n.translate('nav_my_team')),
          _NavDestination(icon: Icons.settings, label: l10n.translate('nav_settings')),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OFM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l10n.translate('app_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Budget Chip Header (only shown if wide enough)
              if (constraints.maxWidth >= 650)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Residuo: ${summary.remainingBudget} cr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (constraints.maxWidth >= 750) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 12,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.group, size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Slot: ${summary.remainingSlots} / ${summary.totalSlots}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),

              // Theme toggle button
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
                tooltip: isDark ? 'Tema Chiaro' : 'Tema Scuro',
                onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
              ),

              // Language toggle button
              IconButton(
                icon: const Icon(Icons.language, size: 20),
                tooltip: 'Cambia lingua / Toggle Language',
                onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop) ...[
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations.map((d) {
                    return NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.icon, color: AppColors.primary),
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: Column(
                  children: [
                    StrategyBar(
                      onOpenStrategy: () => setState(() => _selectedIndex = 2),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _screens,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isDesktop
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                  destinations: destinations.map((d) {
                    return NavigationDestination(
                      icon: Icon(d.icon),
                      label: d.label,
                    );
                  }).toList(),
                )
              : null,
        );
      },
    );
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  const _NavDestination({required this.icon, required this.label});
}
