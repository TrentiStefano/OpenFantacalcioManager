import 'dart:convert';
import '../../core/constants/app_tiers.dart';

class LeagueSettings {
  final int initialBudget;
  final bool isMantra;
  final Map<String, int> slots;
  final Map<String, int> budgetAllocations;
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
    this.budgetAllocations = const {
      'P': 12,
      'D': 100,
      'C': 200,
      'A': 288,
    },
    this.availableTiers = AppTiers.defaultTiers,
  });

  int get totalSlots => slots.values.fold(0, (sum, count) => sum + count);
  int get totalAllocatedBudget => budgetAllocations.values.fold(0, (sum, b) => sum + b);

  LeagueSettings copyWith({
    int? initialBudget,
    bool? isMantra,
    Map<String, int>? slots,
    Map<String, int>? budgetAllocations,
    List<String>? availableTiers,
  }) {
    return LeagueSettings(
      initialBudget: initialBudget ?? this.initialBudget,
      isMantra: isMantra ?? this.isMantra,
      slots: slots ?? Map.from(this.slots),
      budgetAllocations: budgetAllocations ?? Map.from(this.budgetAllocations),
      availableTiers: availableTiers ?? List.from(this.availableTiers),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'initial_budget': initialBudget,
      'is_mantra': isMantra ? 1 : 0,
      'slots_json': jsonEncode(slots),
      'allocations_json': jsonEncode(budgetAllocations),
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

    List<String> parseList(dynamic val, List<String> fallback) {
      if (val == null) return fallback;
      try {
        final decoded = jsonDecode(val.toString()) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return fallback;
      }
    }

    return LeagueSettings(
      initialBudget: (map['initial_budget'] as num?)?.toInt() ?? 600,
      isMantra: (map['is_mantra'] == 1 || map['is_mantra'] == true),
      slots: parseMap(map['slots_json'], const {'P': 3, 'D': 8, 'C': 8, 'A': 6}),
      budgetAllocations: parseMap(map['allocations_json'], const {'P': 12, 'D': 100, 'C': 200, 'A': 288}),
      availableTiers: parseList(map['tiers_json'], AppTiers.defaultTiers),
    );
  }
}
