class PlayerStatsState {
  final int cash;
  final int gold;
  final int energy;
  final int maxEnergy;
  final int courage;
  final int maxCourage;
  final int health;
  final int maxHealth;
  final int prestige;
  final int maxPrestige;
  final String playerName;
  final String? profilePicUrl;
  final int level;
  final int currentXp;
  final int maxXp;
  final bool isVIP;

  PlayerStatsState({
    this.cash = 0,
    this.gold = 0,
    this.energy = 0,
    this.maxEnergy = 100,
    this.courage = 0,
    this.maxCourage = 100,
    this.health = 0,
    this.maxHealth = 100,
    this.prestige = 0,
    this.maxPrestige = 100,
    this.playerName = 'لاعب جديد',
    this.profilePicUrl,
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 100,
    this.isVIP = false,
  });

  // دالة للنسخ وتحديث بعض القيم بسهولة
  PlayerStatsState copyWith({
    int? cash, int? gold, int? energy, int? maxEnergy, int? courage, int? maxCourage,
    int? health, int? maxHealth, int? prestige, int? maxPrestige, String? playerName,
    String? profilePicUrl, int? level, int? currentXp, int? maxXp, bool? isVIP,
  }) {
    return PlayerStatsState(
      cash: cash ?? this.cash,
      gold: gold ?? this.gold,
      energy: energy ?? this.energy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      courage: courage ?? this.courage,
      maxCourage: maxCourage ?? this.maxCourage,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      prestige: prestige ?? this.prestige,
      maxPrestige: maxPrestige ?? this.maxPrestige,
      playerName: playerName ?? this.playerName,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      isVIP: isVIP ?? this.isVIP,
    );
  }
}