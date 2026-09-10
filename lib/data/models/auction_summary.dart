class RoleSummary {
  final String role;
  final int totalSlots;
  final int acquiredCount;
  final int allocatedBudget;
  final int spentBudget;
  final double targetPercentage;

  const RoleSummary({
    required this.role,
    required this.totalSlots,
    required this.acquiredCount,
    required this.allocatedBudget,
    required this.spentBudget,
    this.targetPercentage = 0.0,
  });

  int get remainingSlots => (totalSlots - acquiredCount).clamp(0, totalSlots);
  int get remainingBudget => allocatedBudget - spentBudget;
  bool get isCompleted => totalSlots > 0 && acquiredCount >= totalSlots;
  double get slotProgress => totalSlots > 0 ? (acquiredCount / totalSlots).clamp(0.0, 1.0) : 0.0;
  double get budgetProgress => allocatedBudget > 0 ? (spentBudget / allocatedBudget).clamp(0.0, 1.0) : 0.0;

  /// Returns difference vs target budget.
  /// If completed: (allocatedBudget - spentBudget) — positive if underbudget/savings, negative if overbudget.
  /// If in progress: returns negative overrun if spentBudget > allocatedBudget, or (allocatedBudget - spentBudget) as available remaining.
  int get roleDelta {
    if (isCompleted || spentBudget > allocatedBudget) {
      return allocatedBudget - spentBudget;
    }
    return 0;
  }

  String get formattedDelta {
    final delta = roleDelta;
    if (delta > 0) return '+$delta cr';
    if (delta < 0) return '$delta cr';
    return '0 cr';
  }
}

class AuctionSummary {
  final int initialBudget;
  final int totalSpent;
  final int totalSlots;
  final int totalAcquired;
  final Map<String, RoleSummary> roleSummaries;

  const AuctionSummary({
    required this.initialBudget,
    required this.totalSpent,
    required this.totalSlots,
    required this.totalAcquired,
    required this.roleSummaries,
  });

  int get remainingBudget => initialBudget - totalSpent;
  int get remainingSlots => (totalSlots - totalAcquired).clamp(0, totalSlots);
  double get overallBudgetProgress => initialBudget > 0 ? (totalSpent / initialBudget).clamp(0.0, 1.0) : 0.0;
  double get overallSlotProgress => totalSlots > 0 ? (totalAcquired / totalSlots).clamp(0.0, 1.0) : 0.0;

  /// Net savings or overrun across completed roles and active role overruns.
  /// Positive value (+): underbudget (extra credits saved to spend on other players).
  /// Negative value (-): overbudget (budget overrun).
  int get totalOverUnderBudget {
    int delta = 0;
    for (final r in roleSummaries.values) {
      if (r.isCompleted || r.spentBudget > r.allocatedBudget) {
        delta += (r.allocatedBudget - r.spentBudget);
      }
    }
    return delta;
  }

  String get formattedTotalOverUnder {
    final delta = totalOverUnderBudget;
    if (delta > 0) return '+$delta cr';
    if (delta < 0) return '$delta cr';
    return '0 cr';
  }
}
