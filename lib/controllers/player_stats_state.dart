// المسار: lib/controllers/player_stats_state.dart

class PlayerStatsState {
  final int cash;
  final int gold;
  final int health;
  final int maxHealth;
  final int energy;
  final int maxEnergy;
  final int courage;
  final int maxCourage;
  final int prestige;
  final int maxPrestige;
  final int currentXp;
  final int maxXp;
  final int level;
  final String playerName;
  final String? profilePicUrl;
  final bool isVIP;

  PlayerStatsState({
    this.cash = 0,
    this.gold = 0,
    this.health = 100,
    this.maxHealth = 100,
    this.energy = 100,
    this.maxEnergy = 100,
    this.courage = 30,
    this.maxCourage = 30,
    this.prestige = 100,
    this.maxPrestige = 100,
    this.currentXp = 0,
    this.maxXp = 100,
    this.level = 1,
    this.playerName = '...',
    this.profilePicUrl,
    this.isVIP = false,
  });

  PlayerStatsState copyWith({
    int? cash, int? gold,
    int? health, int? maxHealth,
    int? energy, int? maxEnergy,
    int? courage, int? maxCourage,
    int? prestige, int? maxPrestige,
    int? currentXp, int? maxXp,
    int? level, String? playerName,
    String? profilePicUrl, bool? isVIP,
  }) {
    return PlayerStatsState(
      cash: cash ?? this.cash,
      gold: gold ?? this.gold,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      energy: energy ?? this.energy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      courage: courage ?? this.courage,
      maxCourage: maxCourage ?? this.maxCourage,
      prestige: prestige ?? this.prestige,
      maxPrestige: maxPrestige ?? this.maxPrestige,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      level: level ?? this.level,
      playerName: playerName ?? this.playerName,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      isVIP: isVIP ?? this.isVIP,
    );
  }
}