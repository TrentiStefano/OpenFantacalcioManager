import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/league_settings.dart';
import '../../providers/players_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/stat_card.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _budgetController = TextEditingController();
  final Map<String, TextEditingController> _slotControllers = {};
  final Map<String, TextEditingController> _allocationControllers = {};
  final Map<String, TextEditingController> _percentControllers = {};
  bool _initialized = false;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    for (final role in ['P', 'D', 'C', 'A']) {
      _slotControllers[role] = TextEditingController();
      _allocationControllers[role] = TextEditingController();
      _percentControllers[role] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    for (final c in _slotControllers.values) {
      c.dispose();
    }
    for (final c in _allocationControllers.values) {
      c.dispose();
    }
    for (final c in _percentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromSettings(LeagueSettings settings) {
    if (_initialized) return;
    _budgetController.text = settings.initialBudget.toString();
    for (final role in ['P', 'D', 'C', 'A']) {
      _slotControllers[role]?.text = (settings.slots[role] ?? 0).toString();
      _allocationControllers[role]?.text = (settings.budgetAllocations[role] ?? 0).toString();
      _percentControllers[role]?.text = (settings.targetPercentages[role] ?? 0.0).toStringAsFixed(0);
    }
    _initialized = true;
  }

  void _onPercentChanged(String role) {
    final budget = int.tryParse(_budgetController.text) ?? 600;
    final pct = double.tryParse(_percentControllers[role]?.text ?? '') ?? 0.0;
    final cr = ((pct / 100.0) * budget).round();
    _allocationControllers[role]?.text = cr.toString();
  }

  void _onAllocationChanged(String role) {
    final budget = int.tryParse(_budgetController.text) ?? 600;
    if (budget <= 0) return;
    final cr = int.tryParse(_allocationControllers[role]?.text ?? '') ?? 0;
    final pct = (cr / budget) * 100.0;
    _percentControllers[role]?.text = pct.toStringAsFixed(0);
  }

  void _resetStrategyToDefault() {
    final budget = int.tryParse(_budgetController.text) ?? 600;
    for (final entry in LeagueSettings.defaultTargetPercentages.entries) {
      final role = entry.key;
      final pct = entry.value;
      _percentControllers[role]?.text = pct.toStringAsFixed(0);
      _allocationControllers[role]?.text = ((pct / 100.0) * budget).round().toString();
    }
    setState(() {});
  }

  Future<void> _pickAndImportFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
        if (bytes != null) {
          final importRes = await ref.read(playersProvider.notifier).importFile(bytes, file.name);
          setState(() {
            _statusMessage = 'Importati con successo ${importRes.totalImported} giocatori '
                '(foglio "${importRes.sheetNameUsed}", ${importRes.cedutiCount} ceduti).';
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Errore importazione: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSampleFixture() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final importRes = await ref.read(playersProvider.notifier).loadFixtureFromAsset(
            'spreadsheets/Quotazioni_Fantacalcio_Stagione_2026_27.xlsx',
          );
      setState(() {
        _statusMessage = 'Caricato fixture 2026/27: ${importRes.totalImported} giocatori '
            '(${importRes.cedutiCount} ceduti rilevati).';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Errore caricamento fixture: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final budget = int.tryParse(_budgetController.text) ?? 600;
    final slots = <String, int>{};
    final allocations = <String, int>{};
    final percentages = <String, double>{};

    for (final role in ['P', 'D', 'C', 'A']) {
      slots[role] = int.tryParse(_slotControllers[role]?.text ?? '') ?? 0;
      allocations[role] = int.tryParse(_allocationControllers[role]?.text ?? '') ?? 0;
      percentages[role] = double.tryParse(_percentControllers[role]?.text ?? '') ?? 0.0;
    }

    final currentSettings = ref.read(settingsProvider).value ?? const LeagueSettings();
    final updated = currentSettings.copyWith(
      initialBudget: budget,
      slots: slots,
      budgetAllocations: allocations,
      targetPercentages: percentages,
    );

    await ref.read(settingsProvider.notifier).updateSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurazione salvata con successo!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final playersAsync = ref.watch(playersProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (settings) {
        _initFromSettings(settings);
        final players = playersAsync.value ?? [];
        final totalPlayers = players.length;
        final cedutiPlayers = players.where((p) => p.isCeduto).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.translate('setup_title'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.translate('setup_subtitle'),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // File Import Section Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.upload_file, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Importa Listone Quotazioni (.xlsx / .csv)',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mappatura intelligente per nome colonna (Id, R, Nome, Squadra, Qt.A, FVM, ecc.)',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickAndImportFile,
                            icon: const Icon(Icons.folder_open),
                            label: Text(l10n.translate('import_quotazioni')),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loadSampleFixture,
                            icon: const Icon(Icons.flash_on, color: AppColors.accent),
                            label: Text(l10n.translate('load_sample_file')),
                          ),
                        ],
                      ),
                      if (_isLoading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _statusMessage!.contains('Errore')
                                ? Colors.red.withValues(alpha: 0.1)
                                : AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _statusMessage!.contains('Errore')
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _statusMessage!.contains('Errore')
                                    ? Icons.error_outline
                                    : Icons.check_circle_outline,
                                color: _statusMessage!.contains('Errore')
                                    ? Colors.red
                                    : AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _statusMessage!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _statusMessage!.contains('Errore')
                                        ? Colors.red
                                        : AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status metrics row
              if (totalPlayers > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Calciatori Caricati',
                        value: '$totalPlayers',
                        icon: Icons.people_alt,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        title: 'Giocatori Ceduti',
                        value: '$cedutiPlayers',
                        icon: Icons.person_remove,
                        color: cedutiPlayers > 0 ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Settings Form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parametri Asta & Rosa',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Budget Iniziale & Mantra Mode
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate('budget_credits'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _budgetController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.monetization_on_outlined),
                                      suffixText: 'cr',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Modalità di Gioco',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: Text(l10n.translate('classic_mode')),
                                    selected: !settings.isMantra,
                                    onSelected: (val) {
                                      if (val) {
                                        ref.read(settingsProvider.notifier).toggleMantra(false);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text(l10n.translate('mantra_mode')),
                                    selected: settings.isMantra,
                                    onSelected: (val) {
                                      if (val) {
                                        ref.read(settingsProvider.notifier).toggleMantra(true);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Slot per Ruolo
                      Text(
                        l10n.translate('slots_per_role'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ['P', 'D', 'C', 'A'].map((role) {
                          final roleName = l10n.translate('role_$role');
                          final color = AppColors.getRoleColor(role);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        roleName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _slotControllers[role],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      suffixText: 'slot',
                                      suffixStyle: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Strategia & Budget Allocato per Ruolo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('strategy_target_title'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Base: P 6% • D 16% • C 26% • A 52%',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetStrategyToDefault,
                            icon: const Icon(Icons.restart_alt, size: 14),
                            label: Text(
                              l10n.translate('reset_default_strategy'),
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ['P', 'D', 'C', 'A'].map((role) {
                          final roleName = l10n.translate('role_$role');
                          final color = AppColors.getRoleColor(role);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        roleName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _percentControllers[role],
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          onChanged: (_) => _onPercentChanged(role),
                                          decoration: const InputDecoration(
                                            suffixText: '%',
                                            suffixStyle: TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: _allocationControllers[role],
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => _onAllocationChanged(role),
                                          decoration: const InputDecoration(
                                            suffixText: 'cr',
                                            suffixStyle: TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: Text(l10n.translate('save_settings')),
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
