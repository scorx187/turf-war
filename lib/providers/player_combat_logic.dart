// المسار: lib/providers/player_combat_logic.dart

part of 'player_provider.dart';

extension PlayerCombatLogic on PlayerProvider {

  // 🟢 1. شراء وتفعيل المنشطات 🟢
  void buyAndUseSteroids(int price) {
    if (_cash >= price) {
      _cash -= price;
      // تفعيل لمدة ساعة
      _activeSteroidEndTime = DateTime.now().add(const Duration(hours: 1));
      _addTransaction("شراء منشطات", price, false);
      _showNotification("💉 حقنت نفسك بالمنشطات! التدريب سيتضاعف لمدة ساعة.");
      _syncWithFirestore();
      notifyListeners();
    } else {
      _showNotification("⚠️ كاش غير كافي لشراء المنشطات!");
    }
  }

  // 🟢 2. استئجار مدرب 🟢
  void hireCoach(String coachId, int price) {
    if (_cash >= price) {
      _cash -= price;
      _activeCoach = coachId;
      // عقد لمدة 24 ساعة
      _coachEndTime = DateTime.now().add(const Duration(hours: 24));
      _addTransaction("استئجار مدرب خاص", price, false);
      _showNotification("🥊 تم التعاقد مع المدرب بنجاح لمدة 24 ساعة!");
      _syncWithFirestore();
      notifyListeners();
    } else {
      _showNotification("⚠️ كاش غير كافي لاستئجار المدرب!");
    }
  }

  void addCrimeXP(int amount) {
    if (_crimeLevel >= 450) return;
    _crimeXP += amount;
    bool leveledUp = false;
    while (_crimeXP >= xpToNextLevel && _crimeLevel < 450) {
      _crimeXP -= xpToNextLevel;
      int oldBase = (100 * pow(1.029665, _crimeLevel - 1)).toInt();
      _crimeLevel++;
      int newBase = (100 * pow(1.029665, _crimeLevel - 1)).toInt();
      _maxHealth += (newBase - oldBase);
      if (_maxHealth > 50000000) _maxHealth = 50000000;
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
    if (_equippedMaskId == 'black_mask') escapeChance = 0.35;
    else if (_equippedMaskId == 'silicon_mask') escapeChance = 0.55;

    if (Random().nextDouble() < escapeChance) {
      _showNotification("🎭 هربت بفضل القناع!");
    } else {
      _showNotification("⚠️ تم القبض عليك بتهمة: $crimeName!");
      _lastCrimeName = crimeName;
      _playerBailCost = bailCost;
      startPrisonTimer(minutes);
    }
  }

  double get maxGymStats => 100.0 + (_crimeLevel * 50.0) + (pow(_crimeLevel, 2) * 2.0);
  double get currentBaseStats => _strength + _defense + _skill + _speed;

  // 🟢 3. تعديل التدريب لدعم المنشطات والمدربين 🟢
  void trainMultipleStats(int strE, int defE, int skillE, int spdE) {
    int totalEnergy = strE + defE + skillE + spdE;
    if (_energy < totalEnergy || totalEnergy <= 0) return;
    if (currentBaseStats >= maxGymStats) { _showNotification("🚨 وصلت للحد الأقصى لجسمك في هذا المستوى! ارفع لفلك."); return; }

    // الأساسي
    double gainPerEnergy = 0.01 + (_happiness * 0.0002);

    // مضاعف المنشطات (الضعف 200%)
    double steroidMultiplier = (_activeSteroidEndTime != null && DateTime.now().isBefore(_activeSteroidEndTime!)) ? 2.0 : 1.0;

    // مضاعفات المدربين
    double coachStrMod = _activeCoach == 'russian' ? 1.5 : 1.0; // الروسي يركز على القوة
    double coachDefMod = _activeCoach == 'tactical' ? 1.5 : 1.0; // التكتيكي يركز على الدفاع
    double coachSpdMod = _activeCoach == 'ninja' ? 1.5 : 1.0; // النينجا يركز على السرعة والمهارة
    double coachSklMod = _activeCoach == 'ninja' ? 1.5 : 1.0;

    // حساب المكسب النهائي لكل مهارة
    double strGain = strE * gainPerEnergy * steroidMultiplier * coachStrMod;
    double defGain = defE * gainPerEnergy * steroidMultiplier * coachDefMod;
    double skillGain = skillE * gainPerEnergy * steroidMultiplier * coachSklMod;
    double spdGain = spdE * gainPerEnergy * steroidMultiplier * coachSpdMod;

    double totalGain = strGain + defGain + skillGain + spdGain;
    double availableRoom = maxGymStats - currentBaseStats;

    // التأكد إنه ما يتجاوز الليمت
    if (totalGain > availableRoom) {
      double scale = availableRoom / totalGain;
      strGain *= scale; defGain *= scale; skillGain *= scale; spdGain *= scale;
    }

    _energy -= totalEnergy;
    _strength += strGain; _defense += defGain; _skill += skillGain; _speed += spdGain;

    // تأثير المدرب التكتيكي على رفع الـ Max Health (الفرصة تتضاعف)
    if (defGain > 0) {
      double hpBoostChance = _activeCoach == 'tactical' ? 15.0 : 8.0;
      double randomMultiplier = hpBoostChance + Random().nextDouble() * 7.0;
      int hpBoost = (defGain * randomMultiplier).toInt();
      if (hpBoost > 0) {
        _maxHealth = min(50000000, _maxHealth + hpBoost);
        _showNotification("🛡️ تمرين الدفاع زاد صحتك القصوى بمقدار +$hpBoost نقطة!");
      }
    }
    _syncWithFirestore(); notifyListeners();
  }

  void incrementArenaLevel() { _arenaLevel++; _syncWithFirestore(); notifyListeners(); }

  void setHealth(int value) {
    _health = value.clamp(0, maxHealth);
    if (_health == 0 && !_isHospitalized) { enterHospital(1); }
    else if (_health > 0 && _isHospitalized) { _isHospitalized = false; _hospitalReleaseTime = null; }
    _syncWithFirestore(); notifyListeners();
  }

  void setEnergy(int value) { _energy = value.clamp(0, maxEnergy); _syncWithFirestore(); notifyListeners(); }
  void setCourage(int value) { _courage = value.clamp(0, maxCourage); _syncWithFirestore(); notifyListeners(); }
  void enterHospital(int minutes) { _isHospitalized = true; _health = 0; _hospitalReleaseTime = DateTime.now().add(Duration(minutes: minutes)); _syncWithFirestore(); notifyListeners(); }

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

  void startPrisonTimer(int minutes) { _isInPrison = true; _prisonReleaseTime = DateTime.now().add(Duration(minutes: minutes)); _syncWithFirestore(); notifyListeners(); }
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
            if (DateTime.now().isAfter(DateTime.parse(data['hospitalReleaseTime']))) {
              data['isHospitalized'] = false; data['health'] = (data['maxHealth'] ?? 100) ~/ 4;
              updates['isHospitalized'] = false; updates['hospitalReleaseTime'] = null; updates['health'] = data['health'];
              needsUpdate = true;
            }
          }
          if (data['isInPrison'] == true && data['prisonReleaseTime'] != null) {
            if (DateTime.now().isAfter(DateTime.parse(data['prisonReleaseTime']))) {
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
          updates['cash'] = enemyCash - finalReward; updates['health'] = 0; updates['isHospitalized'] = true; updates['hospitalReleaseTime'] = DateTime.now().add(Duration(minutes: hospitalMinutes)).toIso8601String();
          logData['stolenAmount'] = finalReward;
        } else if (result == 'draw') {
          int newHealth = max(1, enemyHealth - 20); updates['health'] = newHealth;
          if (newHealth <= 1) { updates['health'] = 0; updates['isHospitalized'] = true; updates['hospitalReleaseTime'] = DateTime.now().add(const Duration(minutes: 15)).toIso8601String(); }
        }
        if (updates.isNotEmpty) transaction.update(enemyRef, updates);
        transaction.set(logRef, logData);
      });

      if (result == 'win') { if (reward > 0) addCash(reward, reason: "غنيمة من $enemyName"); _showNotification("⚔️ انتصرت على $enemyName وأرسلته للمستشفى!"); }
      else if (result == 'loss') { enterHospital(15); _showNotification("🏥 لقد خسرت المعركة وتم نقلك للمستشفى!"); }
      else if (result == 'draw') { setHealth(max(1, health - 20)); _showNotification("🤝 انتهت المعركة بالتعادل! تضررت صحتك."); }
    } catch (e) { debugPrint("خطأ في حفظ نتيجة المعركة: $e"); }
  }

  Future<List<Map<String, dynamic>>> fetchAttacksLog() async { if (_uid == null) return []; try { QuerySnapshot snapshot = await _firestore.collection('players').doc(_uid).collection('attacks_log').orderBy('date', descending: true).limit(20).get(); List<Map<String, dynamic>> logs = []; for (var doc in snapshot.docs) { Map<String, dynamic> data = doc.data() as Map<String, dynamic>; data['logId'] = doc.id; logs.add(data); } return logs; } catch (e) { return []; } }
  Future<void> markAsAvenged(String logId) async { if (_uid == null) return; try { await _firestore.collection('players').doc(_uid).collection('attacks_log').doc(logId).update({'hasAvenged': true}); } catch (e) {} }
  void unlockAllCrimesForDev() { for (int catIndex = 0; catIndex < 20; catIndex++) { for (int crimeIndex = 0; crimeIndex < 20; crimeIndex++) { String crimeId = 'cat_${catIndex}_crime_$crimeIndex'; crimeSuccessCountsMap[crimeId] = 10; } } _syncWithFirestore(); notifyListeners(); _showNotification("🛠️ (أداة المطور): تم فتح جميع الجرائم بنجاح!"); }
}