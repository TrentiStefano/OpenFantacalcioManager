enum PlayerStatus {
  available,
  mine,
  others;

  String toDbString() => name;
  static PlayerStatus fromDbString(String? val) {
    switch (val) {
      case 'mine':
        return PlayerStatus.mine;
      case 'others':
        return PlayerStatus.others;
      default:
        return PlayerStatus.available;
    }
  }
}

class Player {
  final int id;
  final String role; // P, D, C, A
  final String roleMantra; // Por, E, M;C, etc.
  final String name;
  final String team;
  final double qtA;
  final double qtI;
  final double diff;
  final double qtAM;
  final double qtIM;
  final double diffM;
  final double fvm;
  final double fvmM;
  final bool isCeduto;

  // Editable Strategy Fields
  final double budgetPercent; // e.g. 0.11 (11%)
  final String tier; // TOP, SEMITOP, etc.
  final bool isFavorite;
  final int? targetPrice;
  final String notes;

  // Live Auction State
  final PlayerStatus status;
  final int? purchasePrice; // When status == mine

  const Player({
    required this.id,
    required this.role,
    this.roleMantra = '',
    required this.name,
    required this.team,
    this.qtA = 0.0,
    this.qtI = 0.0,
    this.diff = 0.0,
    this.qtAM = 0.0,
    this.qtIM = 0.0,
    this.diffM = 0.0,
    this.fvm = 0.0,
    this.fvmM = 0.0,
    this.isCeduto = false,
    this.budgetPercent = 0.0,
    this.tier = 'ALTRI',
    this.isFavorite = false,
    this.targetPrice,
    this.notes = '',
    this.status = PlayerStatus.available,
    this.purchasePrice,
  });

  /// Computed starting auction value: ROUND(% Budget * Budget Iniziale)
  int calculateBaseValue(int initialBudget) {
    return (budgetPercent * initialBudget).round();
  }

  Player copyWith({
    int? id,
    String? role,
    String? roleMantra,
    String? name,
    String? team,
    double? qtA,
    double? qtI,
    double? diff,
    double? qtAM,
    double? qtIM,
    double? diffM,
    double? fvm,
    double? fvmM,
    bool? isCeduto,
    double? budgetPercent,
    String? tier,
    bool? isFavorite,
    int? targetPrice,
    bool clearTargetPrice = false,
    String? notes,
    PlayerStatus? status,
    int? purchasePrice,
    bool clearPurchasePrice = false,
  }) {
    return Player(
      id: id ?? this.id,
      role: role ?? this.role,
      roleMantra: roleMantra ?? this.roleMantra,
      name: name ?? this.name,
      team: team ?? this.team,
      qtA: qtA ?? this.qtA,
      qtI: qtI ?? this.qtI,
      diff: diff ?? this.diff,
      qtAM: qtAM ?? this.qtAM,
      qtIM: qtIM ?? this.qtIM,
      diffM: diffM ?? this.diffM,
      fvm: fvm ?? this.fvm,
      fvmM: fvmM ?? this.fvmM,
      isCeduto: isCeduto ?? this.isCeduto,
      budgetPercent: budgetPercent ?? this.budgetPercent,
      tier: tier ?? this.tier,
      isFavorite: isFavorite ?? this.isFavorite,
      targetPrice: clearTargetPrice ? null : (targetPrice ?? this.targetPrice),
      notes: notes ?? this.notes,
      status: status ?? this.status,
      purchasePrice: clearPurchasePrice ? null : (purchasePrice ?? this.purchasePrice),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'role_mantra': roleMantra,
      'name': name,
      'team': team,
      'qt_a': qtA,
      'qt_i': qtI,
      'diff': diff,
      'qt_a_m': qtAM,
      'qt_i_m': qtIM,
      'diff_m': diffM,
      'fvm': fvm,
      'fvm_m': fvmM,
      'is_ceduto': isCeduto ? 1 : 0,
      'budget_percent': budgetPercent,
      'tier': tier,
      'is_favorite': isFavorite ? 1 : 0,
      'target_price': targetPrice,
      'notes': notes,
      'status': status.toDbString(),
      'purchase_price': purchasePrice,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: (map['id'] as num).toInt(),
      role: (map['role'] ?? 'A').toString(),
      roleMantra: (map['role_mantra'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      team: (map['team'] ?? '').toString(),
      qtA: (map['qt_a'] as num?)?.toDouble() ?? 0.0,
      qtI: (map['qt_i'] as num?)?.toDouble() ?? 0.0,
      diff: (map['diff'] as num?)?.toDouble() ?? 0.0,
      qtAM: (map['qt_a_m'] as num?)?.toDouble() ?? 0.0,
      qtIM: (map['qt_i_m'] as num?)?.toDouble() ?? 0.0,
      diffM: (map['diff_m'] as num?)?.toDouble() ?? 0.0,
      fvm: (map['fvm'] as num?)?.toDouble() ?? 0.0,
      fvmM: (map['fvm_m'] as num?)?.toDouble() ?? 0.0,
      isCeduto: (map['is_ceduto'] == 1 || map['is_ceduto'] == true),
      budgetPercent: (map['budget_percent'] as num?)?.toDouble() ?? 0.0,
      tier: (map['tier'] ?? 'ALTRI').toString(),
      isFavorite: (map['is_favorite'] == 1 || map['is_favorite'] == true),
      targetPrice: (map['target_price'] as num?)?.toInt(),
      notes: (map['notes'] ?? '').toString(),
      status: PlayerStatus.fromDbString(map['status'] as String?),
      purchasePrice: (map['purchase_price'] as num?)?.toInt(),
    );
  }
}
