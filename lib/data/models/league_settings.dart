import 'dart:convert';
import '../../core/constants/app_tiers.dart';

class LeagueSettings {
  static const Map<String, double> defaultTargetPercentages = {
    'P': 6.0,
    'D': 16.0,
    'C': 26.0,
    'A': 52.0,
  };

  static const Map<String, int> defaultBudgetAllocations = {
    'P': 36,
    'D': 96,
    'C': 156,
    'A': 312,
  };

  final int initialBudget;
  final bool isMantra;
  final Map<String, int> slots;
  final Map<String, int> budgetAllocations;
  final Map<String, double> targetPercentages;
  final List<String> availableTiers;

  const LeagueSettings({
    this.initialBudget = 600,
    this.isMantra = false,
    this.slots = const {
      'P': 3,
      'D': 8,
      'C': 8,
      'A': 6,
    },
    this.budgetAllocations = defaultBudgetAllocations,
    this.targetPercentages = defaultTargetPercentages,
    this.availableTiers = AppTiers.defaultTiers,
  });

  int get totalSlots => slots.values.fold(0, (sum, count) => sum + count);
  int get totalAllocatedBudget => budgetAllocations.values.fold(0, (sum, b) => sum + b);

  /// Helper to calculate allocations from target percentages for a given budget
  static Map<String, int> calculateAllocations(int budget, Map<String, double> percentages) {
    return {
      for (final role in ['P', 'D', 'C', 'A'])
        role: ((percentages[role] ?? 0.0) / 100.0 * budget).round(),
    };
  }

  LeagueSettings copyWith({
    int? initialBudget,
    bool? isMantra,
    Map<String, int>? slots,
    Map<String, int>? budgetAllocations,
    Map<String, double>? targetPercentages,
    List<String>? availableTiers,
  }) {
    final newBudget = initialBudget ?? this.initialBudget;
    final newPercentages = targetPercentages ?? Map.from(this.targetPercentages);
    final newAllocations = budgetAllocations ??
        (targetPercentages != null
            ? calculateAllocations(newBudget, newPercentages)
            : Map.from(this.budgetAllocations));

    return LeagueSettings(
      initialBudget: newBudget,
      isMantra: isMantra ?? this.isMantra,
      slots: slots ?? Map.from(this.slots),
      budgetAllocations: newAllocations,
      targetPercentages: newPercentages,
      availableTiers: availableTiers ?? List.from(this.availableTiers),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'initial_budget': initialBudget,
      'is_mantra': isMantra ? 1 : 0,
      'slots_json': jsonEncode(slots),
      'allocations_json': jsonEncode(budgetAllocations),
      'target_percentages_json': jsonEncode(targetPercentages),
      'tiers_json': jsonEncode(availableTiers),
    };
  }

  factory LeagueSettings.fromMap(Map<String, dynamic> map) {
    Map<String, int> parseMap(dynamic val, Map<String, int> fallback) {
      if (val == null) return fallback;
      try {
        final decoded = jsonDecode(val.toString()) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        return fallback;
      }
    }

    Map<String, double> parseDoubleMap(dynamic val, Map<String, double> fallback) {
      if (val == null) return fallback;
      try {
        final decoded = jsonDecode(val.toString()) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {
        return fallback;
      }
    }

    List<String> parseList(dynamic val, List<String> fallback) {
      if (val == null) return fallback;
      try {
        final decoded = jsonDecode(val.toString()) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return fallback;
      }
    }

    final initialBudget = (map['initial_budget'] as num?)?.toInt() ?? 600;
    final targetPercentages = parseDoubleMap(map['target_percentages_json'], defaultTargetPercentages);
    final defaultAlloc = calculateAllocations(initialBudget, targetPercentages);

    return LeagueSettings(
      initialBudget: initialBudget,
      isMantra: (map['is_mantra'] == 1 || map['is_mantra'] == true),
      slots: parseMap(map['slots_json'], const {'P': 3, 'D': 8, 'C': 8, 'A': 6}),
      budgetAllocations: parseMap(map['allocations_json'], defaultAlloc),
      targetPercentages: targetPercentages,
      availableTiers: parseList(map['tiers_json'], AppTiers.defaultTiers),
    );
  }
}
