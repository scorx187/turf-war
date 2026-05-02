// Ø§Ù„Ù…Ø³Ø§Ø±: lib/providers/player_combat_logic.dart

part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerCombatLogic on PlayerProvider {

  Future<void> buyAndUseSteroids(int price) async {
    int cooldownTime = _inventory['steroid_cooldown'] ?? 0;
    if (secureNow.millisecondsSinceEpoch < cooldownTime) return;

    if (_cash >= price) {
      _cash -= price;
      _activeSteroidEndTime = secureNow.add(const Duration(minutes: 20));
      _inventory['steroid_cooldown'] = secureNow.add(const Duration(hours: 6, minutes: 20)).millisecondsSinceEpoch;

      _addTransaction("Ø´Ø±Ø§Ø¡ Ù…Ù†Ø´Ø·Ø§Øª", price, false);
      await _syncWithFirestore();
      notifyListeners();
    }
  }

  Future<void> hireCoach(String coachId, int price) async {
    int cooldownTime = _inventory['coach_cooldown'] ?? 0;
    if (secureNow.millisecondsSinceEpoch < cooldownTime) return;

    if (_cash >= price) {
      _cash -= price;
      _activeCoach = coachId;
      _coachEndTime = secureNow.add(const Duration(minutes: 30));
      _inventory['coach_cooldown'] = secureNow.add(const Duration(hours: 6, minutes: 30)).millisecondsSinceEpoch;

      _addTransaction("Ø§Ø³ØªØ¦Ø¬Ø§Ø± Ù…Ø¯Ø±Ø¨ Ø®Ø§Øµ", price, false);
      await _syncWithFirestore();
      notifyListeners();
    }
  }

  void addCrimeXP(int amount) {
    if (_crimeLevel >= 500) return; // ðŸŸ¢ Ø§Ù„Ø­Ø¯ Ø§Ù„Ø£Ù‚ØµÙ‰ 500
    _crimeXP += amount;
    bool leveledUp = false;

    while (_crimeXP >= xpToNextLevel && _crimeLevel < 500) {
      _crimeXP -= xpToNextLevel;

      // ðŸŸ¢ ØªÙ… Ø­Ù„ Ù…Ø´ÙƒÙ„Ø© num Ø¥Ù„Ù‰ double Ø¨Ø¥Ø¶Ø§ÙØ© .toDouble()
      double oldBase = _crimeLevel <= 100
          ? (100 * pow(1.06, _crimeLevel - 1)).toDouble()
          : ((100 * pow(1.06, 99)) * pow(1.0194488, _crimeLevel - 100)).toDouble();

      _crimeLevel++;

      // ðŸŸ¢ ØªÙ… Ø­Ù„ Ø§Ù„Ù…Ø´ÙƒÙ„Ø© Ù‡Ù†Ø§ Ø£ÙŠØ¶Ø§Ù‹
      double newBase = _crimeLevel <= 100
          ? (100 * pow(1.06, _crimeLevel - 1)).toDouble()
          : ((100 * pow(1.06, 99)) * pow(1.0194488, _crimeLevel - 100)).toDouble();

      // ðŸŸ¢ Ù†Ø¶ÙŠÙ Ø§Ù„ÙØ±Ù‚ ÙÙ‚Ø· Ù„ÙƒÙŠ Ù†Ø­Ø§ÙØ¸ Ø¹Ù„Ù‰ ØµØ­Ø© Ø§Ù„Ù†Ø§Ø¯ÙŠ
      _baseMaxHealth += (newBase - oldBase).toInt();
      // ðŸŒŸ Ø§Ù„Ø³Ø·Ø± Ø§Ù„Ø³Ø­Ø±ÙŠ: ØªØµØ­ÙŠØ­ Ø£Ø®Ø·Ø§Ø¡ Ø§Ù„Ù„Ø§Ø¹Ø¨ÙŠÙ† Ø§Ù„Ù‚Ø¯Ø§Ù…Ù‰
      if (_baseMaxHealth < newBase.toInt()) {
        _baseMaxHealth = newBase.toInt();
      }
      if (_baseMaxHealth > 100000000) _baseMaxHealth = 100000000; // ðŸŸ¢ Ø³Ù‚Ù 100 Ù…Ù„ÙŠÙˆÙ†

      leveledUp = true;
    }

    if (leveledUp) _showNotification("ðŸŽ‰ Ù„ÙÙ„ Ø¥Ø¬Ø±Ø§Ù…ÙŠ Ø¬Ø¯ÙŠØ¯: $_crimeLevel");
    _syncWithFirestore();
    notifyListeners();
  }

  void incrementCrimeSuccess(String crimeId) {
    crimeSuccessCountsMap[crimeId] = (crimeSuccessCountsMap[crimeId] ?? 0) + 1;
    _syncWithFirestore();
    notifyListeners();
  }

  void handleCrimeFailure(int minutes, String crimeName, int bailCost) {
    double escapeChance = 0.0;
    if (_equippedMaskId == 'black_mask') { escapeChance = 0.35; }
    else if (_equippedMaskId == 'silicon_mask') { escapeChance = 0.55; }

    if (Random().nextDouble() < escapeChance) {
    } else {
      _lastCrimeName = crimeName;
      _playerBailCost = bailCost;
      startPrisonTimer(minutes);
    }
  }

  double get maxGymStats => 100.0 + (_crimeLevel * 50.0) + (pow(_crimeLevel, 2) * 2.0);
  double get currentBaseStats => _baseStrength + _baseDefense + _baseSkill + _baseSpeed;

  Future<double> trainMultipleStats(int strE, int defE, int skillE, int spdE) async {
    int totalEnergy = strE + defE + skillE + spdE;
    if (_energy < totalEnergy || totalEnergy <= 0) return 0.0;
    if (currentBaseStats >= maxGymStats) return 0.0;

    double gainPerEnergy = 0.01 + (_happiness * 0.0002);
    double steroidMultiplier = (_activeSteroidEndTime != null && secureNow.isBefore(_activeSteroidEndTime!)) ? 2.0 : 1.0;

    double coachStrMod = _activeCoach == 'russian' ? 1.5 : 1.0;
    double coachDefMod = _activeCoach == 'tactical' ? 1.5 : 1.0;
    double coachSpdMod = _activeCoach == 'ninja' ? 1.5 : 1.0;
    double coachSklMod = _activeCoach == 'ninja' ? 1.5 : 1.0;

    double strGain = strE * gainPerEnergy * steroidMultiplier * coachStrMod;
    double defGain = defE * gainPerEnergy * steroidMultiplier * coachDefMod;
    double skillGain = skillE * gainPerEnergy * steroidMultiplier * coachSklMod;
    double spdGain = spdE * gainPerEnergy * steroidMultiplier * coachSpdMod;

    double totalGain = strGain + defGain + skillGain + spdGain;
    double availableRoom = maxGymStats - currentBaseStats;

    if (totalGain > availableRoom) {
      double scale = availableRoom / totalGain;
      strGain *= scale; defGain *= scale; skillGain *= scale; spdGain *= scale;
      totalGain = availableRoom;
    }

    _energy -= totalEnergy;
    _baseStrength += strGain; _baseDefense += defGain; _baseSkill += skillGain; _baseSpeed += spdGain;

    if (defGain > 0) {
      double hpBoostChance = _activeCoach == 'tactical' ? 15.0 : 8.0;
      double randomMultiplier = hpBoostChance + Random().nextDouble() * 7.0;
      int hpBoost = (defGain * randomMultiplier).toInt();
      if (hpBoost > 0) {
        _baseMaxHealth = min(100000000, _baseMaxHealth + hpBoost); // ðŸŸ¢ Ø³Ù‚Ù 100 Ù…Ù„ÙŠÙˆÙ†
      }
    }

    await _syncWithFirestore();
    notifyListeners();
    return totalGain;
  }

  void incrementArenaLevel() { _arenaLevel++; _syncWithFirestore(); notifyListeners(); }

  void setHealth(int value) {
    _health = value.clamp(0, maxHealth);
    if (_health == 0 && !_isHospitalized) { enterHospital(15); }
    else if (_health > 0 && _isHospitalized) { _isHospitalized = false; _hospitalReleaseTime = null; }
    _syncWithFirestore(); notifyListeners();
  }

  void setEnergy(int value) {
    _energy = value.clamp(0, maxEnergy);
    _syncWithFirestore();
    notifyListeners();
  }

  void setCourage(int value) { _courage = value.clamp(0, maxCourage); _syncWithFirestore(); notifyListeners(); }

  void enterHospital(int minutes) {
    _isHospitalized = true;
    _health = 0;
    int reducedMinutes = minutes - ((minutes * hospitalTimeReductionPercent) ~/ 100);
    reducedMinutes = max(1, reducedMinutes);
    _hospitalReleaseTime = secureNow.add(Duration(minutes: reducedMinutes));
    _syncWithFirestore(); notifyListeners();
  }

  void quickHealHospital() {
    int missing = maxHealth - _health;
    if (missing <= 0) return;
    int cost = isVIP ? max(1, (missing * 0.8).toInt()) : missing;
    if (_cash >= cost) {
      _cash -= cost; _health = maxHealth; _isHospitalized = false; _hospitalReleaseTime = null;
      _addTransaction("ÙØ§ØªÙˆØ±Ø© Ø§Ù„Ù…Ø³ØªØ´ÙÙ‰", cost, false); _syncWithFirestore(); notifyListeners();
      _showNotification("ðŸ¥ ØªÙ… Ø§Ù„Ø¹Ù„Ø§Ø¬ Ø¨Ø§Ù„ÙƒØ§Ù…Ù„ Ù…Ù‚Ø§Ø¨Ù„ $cost ÙƒØ§Ø´!");
    } else {
      _showNotification("âš ï¸ ÙƒØ§Ø´ ØºÙŠØ± ÙƒØ§ÙÙŠ! ØªØ­ØªØ§Ø¬ $cost");
    }
  }

  void startPrisonTimer(int minutes) {
    _isInPrison = true;
    int reduction = (_perks['corrupt_lawyer'] ?? 0) * 15;
    int reducedMinutes = minutes - ((minutes * reduction) ~/ 100);
    reducedMinutes = max(1, reducedMinutes);
    _prisonReleaseTime = secureNow.add(Duration(minutes: reducedMinutes));
    _syncWithFirestore(); notifyListeners();
  }

  void payBail() { if (_cash >= _bailPrice) { _cash -= _bailPrice; _isInPrison = false; _prisonReleaseTime = null; _syncWithFirestore(); notifyListeners(); } }

  Future<void> bailOutPlayer(String targetUid, int cost, String targetName) async {
    if (_cash >= cost) {
      try {
        _cash -= cost;
        _addTransaction("Ø¯ÙØ¹ ÙƒÙØ§Ù„Ø© Ù„Ù€ $targetName", cost, false);
        _syncWithFirestore(); notifyListeners();
        await _firestore.collection('players').doc(targetUid).update({'isInPrison': false, 'prisonReleaseTime': null});
        _showNotification("ðŸ‘® ØªÙ…Øª Ø§Ù„Ø¹Ù…Ù„ÙŠØ©! Ø¯ÙØ¹Øª Ø§Ù„ÙƒÙØ§Ù„Ø© ÙˆØ®Ø±Ø¬ $targetName Ù…Ù† Ø§Ù„Ø³Ø¬Ù†.");
      } catch(e) { debugPrint("Ø®Ø·Ø£ ÙÙŠ Ø¯ÙØ¹ Ø§Ù„ÙƒÙØ§Ù„Ø©: $e"); }
    } else { _showNotification("âš ï¸ ÙƒØ§Ø´ ØºÙŠØ± ÙƒØ§ÙÙŠ Ù„Ø¯ÙØ¹ Ø§Ù„ÙƒÙØ§Ù„Ø©!"); }
  }

  Future<List<Map<String, dynamic>>> fetchRealOpponents() async {
    try {
      int minLevel = max(1, _arenaLevel - 2);
      int maxLevel = _arenaLevel + 2;
      QuerySnapshot snapshot = await _firestore.collection('players').where('arenaLevel', isGreaterThanOrEqualTo: minLevel).where('arenaLevel', isLessThanOrEqualTo: maxLevel).limit(10).get();

      List<Map<String, dynamic>> opponents = [];
      for (var doc in snapshot.docs) {
        if (doc.id != _uid) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          bool needsUpdate = false;
          Map<String, dynamic> updates = {};

          if (data['isHospitalized'] == true && data['hospitalReleaseTime'] != null) {
            if (secureNow.isAfter(DateTime.parse(data['hospitalReleaseTime']))) {
              data['isHospitalized'] = false; data['health'] = (data['maxHealth'] ?? 100) ~/ 4;
              updates['isHospitalized'] = false; updates['hospitalReleaseTime'] = null; updates['health'] = data['health'];
              needsUpdate = true;
            }
          }
          if (data['isInPrison'] == true && data['prisonReleaseTime'] != null) {
            if (secureNow.isAfter(DateTime.parse(data['prisonReleaseTime']))) {
              data['isInPrison'] = false; updates['isInPrison'] = false; updates['prisonReleaseTime'] = null;
              needsUpdate = true;
            }
          }
          if (needsUpdate) _firestore.collection('players').doc(doc.id).update(updates);
          data['uid'] = doc.id; opponents.add(data);
        }
      }
      return opponents;
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('players').orderBy('arenaLevel', descending: true).limit(10).get();
      List<Map<String, dynamic>> topPlayers = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id; topPlayers.add(data);
      }
      return topPlayers;
    } catch (e) { return []; }
  }

  Future<void> recordPvpResult(String enemyUid, String enemyName, String result, int reward, {int hospitalMinutes = 15}) async {
    try {
      final enemyRef = _firestore.collection('players').doc(enemyUid);
      final logRef = enemyRef.collection('attacks_log').doc();
      Map<String, dynamic> logData = {'attackerId': _uid, 'attackerName': _playerName, 'result': result, 'stolenAmount': reward, 'date': FieldValue.serverTimestamp(), 'hasAvenged': false};

      await _firestore.runTransaction((transaction) async {
        final enemySnap = await transaction.get(enemyRef);
        if (!enemySnap.exists) return;
        int enemyCash = enemySnap.data()?['cash'] ?? 0;
        int enemyHealth = enemySnap.data()?['health'] ?? 100;
        Map<String, dynamic> updates = {};

        if (result == 'win') {
          int finalReward = min(reward, enemyCash);
          updates['cash'] = enemyCash - finalReward; updates['health'] = 0; updates['isHospitalized'] = true; updates['hospitalReleaseTime'] = secureNow.add(Duration(minutes: hospitalMinutes)).toIso8601String();
          logData['stolenAmount'] = finalReward;
        } else if (result == 'draw') {
          int newHealth = max(1, enemyHealth - 20); updates['health'] = newHealth;
          if (newHealth <= 1) { updates['health'] = 0; updates['isHospitalized'] = true; updates['hospitalReleaseTime'] = secureNow.add(const Duration(minutes: 15)).toIso8601String(); }
        }
        if (updates.isNotEmpty) transaction.update(enemyRef, updates);
        transaction.set(logRef, logData);
      });

      if (result == 'win') {
        _pvpWins++;
        _totalStolenCash += reward;
        if (reward > 0) addCash(reward, reason: "ØºÙ†ÙŠÙ…Ø© Ù…Ù† $enemyName");
        _showNotification("âš”ï¸ Ø§Ù†ØªØµØ±Øª Ø¹Ù„Ù‰ $enemyName ÙˆØ£Ø±Ø³Ù„ØªÙ‡ Ù„Ù„Ù…Ø³ØªØ´ÙÙ‰!");
      }
      else if (result == 'loss') { enterHospital(15); _showNotification("ðŸ¥ Ù„Ù‚Ø¯ Ø®Ø³Ø±Øª Ø§Ù„Ù…Ø¹Ø±ÙƒØ© ÙˆØªÙ… Ù†Ù‚Ù„Ùƒ Ù„Ù„Ù…Ø³ØªØ´ÙÙ‰!"); }
      else if (result == 'draw') { setHealth(max(1, health - 20)); _showNotification("ðŸ¤ Ø§Ù†ØªÙ‡Øª Ø§Ù„Ù…Ø¹Ø±ÙƒØ© Ø¨Ø§Ù„ØªØ¹Ø§Ø¯Ù„! ØªØ¶Ø±Ø±Øª ØµØ­ØªÙƒ."); }
    } catch (e) { debugPrint("Ø®Ø·Ø£ ÙÙŠ Ø­ÙØ¸ Ù†ØªÙŠØ¬Ø© Ø§Ù„Ù…Ø¹Ø±ÙƒØ©: $e"); }
  }

  Future<List<Map<String, dynamic>>> fetchAttacksLog() async { if (_uid == null) return []; try { QuerySnapshot snapshot = await _firestore.collection('players').doc(_uid).collection('attacks_log').orderBy('date', descending: true).limit(20).get(); List<Map<String, dynamic>> logs = []; for (var doc in snapshot.docs) { Map<String, dynamic> data = doc.data() as Map<String, dynamic>; data['logId'] = doc.id; logs.add(data); } return logs; } catch (e) { return []; } }
  // ignore: empty_catches
  Future<void> markAsAvenged(String logId) async { if (_uid == null) return; try { await _firestore.collection('players').doc(_uid).collection('attacks_log').doc(logId).update({'hasAvenged': true}); } catch (e) {} }
  void unlockAllCrimesForDev() { for (int catIndex = 0; catIndex < 20; catIndex++) { for (int crimeIndex = 0; crimeIndex < 20; crimeIndex++) { String crimeId = 'cat_${catIndex}_crime_$crimeIndex'; crimeSuccessCountsMap[crimeId] = 10; } } _syncWithFirestore(); notifyListeners(); _showNotification("ðŸ› ï¸ (Ø£Ø¯Ø§Ø© Ø§Ù„Ù…Ø·ÙˆØ±): ØªÙ… ÙØªØ­ Ø¬Ù…ÙŠØ¹ Ø§Ù„Ø¬Ø±Ø§Ø¦Ù… Ø¨Ù†Ø¬Ø§Ø­!"); }
}