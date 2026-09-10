import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _onSelectDestination(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = ref.watch(auctionSummaryProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 750;

        final allDestinations = [
          _NavDestination(icon: Icons.upload_file, label: l10n.translate('nav_setup')),
          _NavDestination(icon: Icons.table_rows_rounded, label: l10n.translate('nav_listone')),
          _NavDestination(icon: Icons.psychology_alt, label: l10n.translate('nav_strategy')),
          _NavDestination(icon: Icons.gavel_rounded, label: l10n.translate('nav_auction')),
          _NavDestination(icon: Icons.shield_outlined, label: l10n.translate('nav_my_team')),
          _NavDestination(icon: Icons.settings, label: l10n.translate('nav_settings')),
        ];

        // On mobile phone (< 750px), show 5 primary tabs in bottom bar and keep settings in appbar
        final mobileDestinations = [
          _NavDestination(icon: Icons.table_rows_rounded, label: l10n.translate('nav_listone')),
          _NavDestination(icon: Icons.gavel_rounded, label: l10n.translate('nav_auction')),
          _NavDestination(icon: Icons.shield_outlined, label: l10n.translate('nav_my_team')),
          _NavDestination(icon: Icons.psychology_alt, label: l10n.translate('nav_strategy')),
          _NavDestination(icon: Icons.upload_file, label: l10n.translate('nav_setup')),
        ];

        // Map mobile index back to _screens index:
        // mobile 0 -> screen 1 (Listone)
        // mobile 1 -> screen 3 (Auction)
        // mobile 2 -> screen 4 (MyTeam)
        // mobile 3 -> screen 2 (Strategy)
        // mobile 4 -> screen 0 (Setup)
        final mobileNavIndex = switch (_selectedIndex) {
          1 => 0, // Listone
          3 => 1, // Auction
          4 => 2, // MyTeam
          2 => 3, // Strategy
          0 => 4, // Setup
          _ => -1,
        };

        return SafeArea(
          top: false, // Let AppBar handle top status bar / safe area
          bottom: true,
          child: Scaffold(
            appBar: AppBar(
              titleSpacing: constraints.maxWidth < 400 ? 10 : null,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      constraints.maxWidth < 400 ? 'OFM' : l10n.translate('app_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                // Budget Chip Header
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.remainingBudget} cr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (constraints.maxWidth >= 600) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 10,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.group, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          '${summary.remainingSlots}/${summary.totalSlots}',
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),

                // Language toggle button
                IconButton(
                  icon: const Icon(Icons.language, size: 20),
                  tooltip: 'Cambia lingua / Toggle Language',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(localeProvider.notifier).toggleLocale();
                  },
                ),

                // Settings icon in AppBar for mobile
                if (!isDesktop)
                  IconButton(
                    icon: Icon(
                      _selectedIndex == 5 ? Icons.settings : Icons.settings_outlined,
                      size: 20,
                      color: _selectedIndex == 5 ? AppColors.primary : null,
                    ),
                    tooltip: l10n.translate('nav_settings'),
                    onPressed: () => _onSelectDestination(5),
                  ),

                const SizedBox(width: 4),
              ],
            ),
            body: Row(
              children: [
                if (isDesktop) ...[
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onSelectDestination,
                    labelType: NavigationRailLabelType.all,
                    destinations: allDestinations.map((d) {
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
                        onOpenStrategy: () => _onSelectDestination(2),
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
                    selectedIndex: mobileNavIndex >= 0 ? mobileNavIndex : 0,
                    onDestinationSelected: (idx) {
                      final targetIndex = switch (idx) {
                        0 => 1, // Listone
                        1 => 3, // Auction
                        2 => 4, // MyTeam
                        3 => 2, // Strategy
                        4 => 0, // Setup
                        _ => 1,
                      };
                      _onSelectDestination(targetIndex);
                    },
                    height: 64,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: mobileDestinations.map((d) {
                      return NavigationDestination(
                        icon: Icon(d.icon, size: 22),
                        selectedIcon: Icon(d.icon, size: 22, color: AppColors.primary),
                        label: d.label,
                      );
                    }).toList(),
                  )
                : null,
          ),
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
