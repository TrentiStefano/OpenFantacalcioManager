class RoleSummary {
  final String role;
  final int totalSlots;
  final int acquiredCount;
  final int allocatedBudget;
  final int spentBudget;

  const RoleSummary({
    required this.role,
    required this.totalSlots,
    required this.acquiredCount,
    required this.allocatedBudget,
    required this.spentBudget,
  });

  int get remainingSlots => (totalSlots - acquiredCount).clamp(0, totalSlots);
  int get remainingBudget => allocatedBudget - spentBudget;
  double get slotProgress => totalSlots > 0 ? (acquiredCount / totalSlots).clamp(0.0, 1.0) : 0.0;
  double get budgetProgress => allocatedBudget > 0 ? (spentBudget / allocatedBudget).clamp(0.0, 1.0) : 0.0;
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
}
