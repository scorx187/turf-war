// المسار: lib/providers/player_combat_logic.dart

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

      _addTransaction("شراء منشطات", price, false);
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

      _addTransaction("استئجار مدرب خاص", price, false);
      await _syncWithFirestore();
      notifyListeners();
    }
  }

  void addCrimeXP(int amount) {
    if (_crimeLevel >= 500) return; // 🟢 الحد الأقصى 500
    _crimeXP += amount;
    bool leveledUp = false;

    while (_crimeXP >= xpToNextLevel && _crimeLevel < 500) {
      _crimeXP -= xpToNextLevel;

      // 🟢 تم حل مشكلة num إلى double بإضافة .toDouble()
      double oldBase = _crimeLevel <= 100
          ? (100 * pow(1.06, _crimeLevel - 1)).toDouble()
          : ((100 * pow(1.06, 99)) * pow(1.0194488, _crimeLevel - 100)).toDouble();

      _crimeLevel++;

      // 🟢 تم حل المشكلة هنا أيضاً
      double newBase = _crimeLevel <= 100
          ? (100 * pow(1.06, _crimeLevel - 1)).toDouble()
          : ((100 * pow(1.06, 99)) * pow(1.0194488, _crimeLevel - 100)).toDouble();

      // 🟢 نضيف الفرق فقط لكي نحافظ على صحة النادي
      _baseMaxHealth += (newBase - oldBase).toInt();
      // 🌟 السطر السحري: تصحيح أخطاء اللاعبين القدامى
      if (_baseMaxHealth < newBase.toInt()) {
        _baseMaxHealth = newBase.toInt();
      }
      if (_baseMaxHealth > 100000000) _baseMaxHealth = 100000000; // 🟢 سقف 100 مليون

      leveledUp = true;
    }

    if (leveledUp) _showNotification("🎉 لفل إجرامي جديد: $_crimeLevel");
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
        _baseMaxHealth = min(100000000, _baseMaxHealth + hpBoost); // 🟢 سقف 100 مليون
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
      _addTransaction("فاتورة المستشفى", cost, false); _syncWithFirestore(); notifyListeners();
      _showNotification("🏥 تم العلاج بالكامل مقابل $cost كاش!");
    } else {
      _showNotification("⚠️ كاش غير كافي! تحتاج $cost");
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
        _addTransaction("دفع كفالة لـ $targetName", cost, false);
        _syncWithFirestore(); notifyListeners();
        await _firestore.collection('players').doc(targetUid).update({'isInPrison': false, 'prisonReleaseTime': null});
        _showNotification("👮 تمت العملية! دفعت الكفالة وخرج $targetName من السجن.");
      } catch(e) { debugPrint("خطأ في دفع الكفالة: $e"); }
    } else { _showNotification("⚠️ كاش غير كافي لدفع الكفالة!"); }
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
        if (reward > 0) addCash(reward, reason: "غنيمة من $enemyName");
        _showNotification("⚔️ انتصرت على $enemyName وأرسلته للمستشفى!");
      }
      else if (result == 'loss') { enterHospital(15); _showNotification("🏥 لقد خسرت المعركة وتم نقلك للمستشفى!"); }
      else if (result == 'draw') { setHealth(max(1, health - 20)); _showNotification("🤝 انتهت المعركة بالتعادل! تضررت صحتك."); }
    } catch (e) { debugPrint("خطأ في حفظ نتيجة المعركة: $e"); }
  }

  Future<List<Map<String, dynamic>>> fetchAttacksLog() async { if (_uid == null) return []; try { QuerySnapshot snapshot = await _firestore.collection('players').doc(_uid).collection('attacks_log').orderBy('date', descending: true).limit(20).get(); List<Map<String, dynamic>> logs = []; for (var doc in snapshot.docs) { Map<String, dynamic> data = doc.data() as Map<String, dynamic>; data['logId'] = doc.id; logs.add(data); } return logs; } catch (e) { return []; } }
  // ignore: empty_catches
  Future<void> markAsAvenged(String logId) async { if (_uid == null) return; try { await _firestore.collection('players').doc(_uid).collection('attacks_log').doc(logId).update({'hasAvenged': true}); } catch (e) {} }
  void unlockAllCrimesForDev() { for (int catIndex = 0; catIndex < 20; catIndex++) { for (int crimeIndex = 0; crimeIndex < 20; crimeIndex++) { String crimeId = 'cat_${catIndex}_crime_$crimeIndex'; crimeSuccessCountsMap[crimeId] = 10; } } _syncWithFirestore(); notifyListeners(); _showNotification("🛠️ (أداة المطور): تم فتح جميع الجرائم بنجاح!"); }
}