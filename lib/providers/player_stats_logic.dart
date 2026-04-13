// المسار: lib/providers/player_stats_logic.dart
part of 'player_provider.dart';

extension PlayerStatsLogic on PlayerProvider {

  int get earnedPerkPoints {
    return getAllTitles().where((t) => t['unlocked'] == true).length - 1;
  }

  int get unspentSkillPoints {
    int spent = _perks.values.fold(0, (sum, val) => sum + val);
    return max(0, earnedPerkPoints + _bonusPerkPoints - spent);
  }

  double get strength {
    double str = _baseStrength;
    if (_perks.containsKey('base_str')) str += str * (_perks['base_str']! * 0.01);
    if (_equippedSpecialId == 't_aladdin_lamp') str += _baseStrength * 0.07;
    if (_equippedSpecialId == 't_crystal_skull') str += _baseStrength * 0.03;
    if (_equippedSpecialId == 't_lion_mane') str += _baseStrength * 0.04;
    if (_equippedSpecialId == 't_time_hourglass') str += _baseStrength * 0.03;

    double weaponBonus = (_equippedWeaponId != null && GameData.weaponStats.containsKey(_equippedWeaponId)) ? str * GameData.weaponStats[_equippedWeaponId]!['str']! : 0.0;
    if (_perks.containsKey('weapon_master')) weaponBonus += weaponBonus * (_perks['weapon_master']! * 0.05);
    return str + weaponBonus;
  }

  double get speed {
    double spd = _baseSpeed;
    if (_perks.containsKey('base_spd')) spd += spd * (_perks['base_spd']! * 0.01);
    if (_equippedSpecialId == 't_aladdin_lamp') spd += _baseSpeed * 0.03;
    if (_equippedSpecialId == 't_aladdin_carpet') spd += _baseSpeed * 0.08;
    if (_equippedSpecialId == 't_time_hourglass') spd += _baseSpeed * 0.03;

    double weaponBonus = (_equippedWeaponId != null && GameData.weaponStats.containsKey(_equippedWeaponId)) ? spd * GameData.weaponStats[_equippedWeaponId]!['spd']! : 0.0;
    if (_perks.containsKey('weapon_master')) weaponBonus += weaponBonus * (_perks['weapon_master']! * 0.05);
    return spd + weaponBonus;
  }

  double get defense {
    double def = _baseDefense;
    if (_perks.containsKey('base_def')) def += def * (_perks['base_def']! * 0.01);
    if (_equippedSpecialId == 't_aladdin_carpet') def += _baseDefense * 0.02;
    if (_equippedSpecialId == 't_magic_ring') def += _baseDefense * 0.06;
    if (_equippedSpecialId == 't_golden_apple') def += _baseDefense * 0.04;
    if (_equippedSpecialId == 't_time_hourglass') def += _baseDefense * 0.03;

    double armorBonus = (_equippedArmorId != null && GameData.armorStats.containsKey(_equippedArmorId)) ? def * GameData.armorStats[_equippedArmorId]!['def']! : 0.0;
    if (_perks.containsKey('armor_master')) armorBonus += armorBonus * (_perks['armor_master']! * 0.05);
    return def + armorBonus;
  }

  double get skill {
    double skl = _baseSkill;
    if (_perks.containsKey('base_skl')) skl += skl * (_perks['base_skl']! * 0.01);
    if (_equippedSpecialId == 't_crystal_skull') skl += _baseSkill * 0.07;
    if (_equippedSpecialId == 't_time_hourglass') skl += _baseSkill * 0.03;

    double armorBonus = (_equippedArmorId != null && GameData.armorStats.containsKey(_equippedArmorId)) ? skl * GameData.armorStats[_equippedArmorId]!['skl']! : 0.0;
    if (_perks.containsKey('armor_master')) armorBonus += armorBonus * (_perks['armor_master']! * 0.05);
    return skl + armorBonus;
  }

  int get maxHealth {
    double hp = _baseMaxHealth.toDouble();
    if (_perks.containsKey('max_hp_boost')) hp += hp * (_perks['max_hp_boost']! * 0.02);
    if (_equippedSpecialId == 't_golden_apple') hp += _baseMaxHealth * 0.10;
    if (_equippedSpecialId == 't_phoenix_feather') hp += _baseMaxHealth * 0.05;
    return hp.toInt();
  }

  int get maxEnergy {
    int nrg = isVIP ? 200 : 100;
    if (_perks.containsKey('max_energy_boost')) nrg += (_perks['max_energy_boost']! * 2);
    if (_equippedSpecialId == 't_magic_ring') nrg += 15;
    if (_equippedSpecialId == 't_dragon_heart') nrg += 20;
    return nrg;
  }

  int get maxCourage {
    // 🟢 الأساس 29 للاعب العادي (29 + مستوى 1 = 30)
    // 🟢 إذا كان اللاعب VIP جعلنا الأساس 60 كـ ميزة إضافية
    int crg = (isVIP ? 60 : 29) + _crimeLevel;

    if (_perks.containsKey('max_courage_boost')) crg += (_perks['max_courage_boost']! * 1);
    if (_equippedSpecialId == 't_dragon_heart') crg += 10;
    if (_equippedSpecialId == 't_lion_mane') crg += 15;
    if (_equippedSpecialId == 't_midas_touch') crg += 5;
    return crg;
  }

  int get happiness {
    int total = _happiness;
    if (_equippedSpecialId == 't_aladdin_lamp') total += 300;
    if (_equippedSpecialId == 't_aladdin_carpet') total += 300;
    if (_equippedSpecialId == 't_magic_ring') total += 200;
    if (_equippedSpecialId == 't_dragon_heart') total += 500;
    if (_equippedSpecialId == 't_crystal_skull') total += 250;
    if (_equippedSpecialId == 't_golden_apple') total += 400;
    if (_equippedSpecialId == 't_lion_mane') total += 200;
    if (_equippedSpecialId == 't_phoenix_feather') total += 600;
    if (_equippedSpecialId == 't_time_hourglass') total += 550;
    if (_equippedSpecialId == 't_midas_touch') total += 600;
    return total;
  }

  double get crimeBonusMultiplier {
    double multi = 1.0 + ((_perks['crime_master'] ?? 0) * 0.03);
    if (_equippedSpecialId == 't_midas_touch') multi += 0.15;
    return multi;
  }

  int get hospitalTimeReductionPercent {
    int reduction = (_perks['fast_recovery'] ?? 0) * 5;
    if (_equippedSpecialId == 't_phoenix_feather') reduction += 15;
    if (_equippedSpecialId == 't_time_hourglass') reduction += 5;
    return reduction;
  }
}