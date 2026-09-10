import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/players_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmResetSeason(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(l10n.translate('reset_season')),
          ],
        ),
        content: Text(l10n.translate('reset_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              await ref.read(playersProvider.notifier).resetSeason();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dati della stagione azzerati con successo.')),
                );
              }
            },
            child: const Text('Azzera Tutto', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('nav_settings'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aspetto & Lingua', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Language Switcher
                      if (isMobile) ...[
                        Row(
                          children: [
                            const Icon(Icons.language, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.translate('language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text(currentLocale.languageCode == 'it' ? 'Italiano' : 'English', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'it', label: Text('Italiano')),
                              ButtonSegment(value: 'en', label: Text('English')),
                            ],
                            selected: {currentLocale.languageCode},
                            onSelectionChanged: (set) {
                              HapticFeedback.selectionClick();
                              ref.read(localeProvider.notifier).setLocale(Locale(set.first));
                            },
                          ),
                        ),
                      ] else ...[
                        ListTile(
                          leading: const Icon(Icons.language, color: AppColors.primary),
                          title: Text(l10n.translate('language')),
                          subtitle: Text(currentLocale.languageCode == 'it' ? 'Italiano' : 'English'),
                          trailing: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'it', label: Text('Italiano')),
                              ButtonSegment(value: 'en', label: Text('English')),
                            ],
                            selected: {currentLocale.languageCode},
                            onSelectionChanged: (set) {
                              HapticFeedback.selectionClick();
                              ref.read(localeProvider.notifier).setLocale(Locale(set.first));
                            },
                          ),
                        ),
                      ],
                      const Divider(height: 32),

                      // Theme Switcher
                      if (isMobile) ...[
                        Row(
                          children: [
                            Icon(
                              themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.translate('theme'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text(
                                    themeMode == ThemeMode.dark
                                        ? l10n.translate('theme_dark')
                                        : l10n.translate('theme_light'),
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(l10n.translate('theme_light')),
                                icon: const Icon(Icons.light_mode, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(l10n.translate('theme_dark')),
                                icon: const Icon(Icons.dark_mode, size: 16),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (set) {
                              HapticFeedback.selectionClick();
                              ref.read(themeModeProvider.notifier).setThemeMode(set.first);
                            },
                          ),
                        ),
                      ] else ...[
                        ListTile(
                          leading: Icon(
                            themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                            color: AppColors.primary,
                          ),
                          title: Text(l10n.translate('theme')),
                          subtitle: Text(themeMode == ThemeMode.dark
                              ? l10n.translate('theme_dark')
                              : l10n.translate('theme_light')),
                          trailing: SegmentedButton<ThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(l10n.translate('theme_light')),
                                icon: const Icon(Icons.light_mode, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(l10n.translate('theme_dark')),
                                icon: const Icon(Icons.dark_mode, size: 16),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (set) {
                              HapticFeedback.selectionClick();
                              ref.read(themeModeProvider.notifier).setThemeMode(set.first);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 24),

          // Danger Zone
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dangerous_outlined, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Zona Pericolo / Reset',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.translate('reset_warning'),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _confirmResetSeason(context, ref),
                    icon: const Icon(Icons.delete_forever),
                    label: Text(l10n.translate('reset_season')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
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
