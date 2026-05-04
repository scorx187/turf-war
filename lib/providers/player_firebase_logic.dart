// المسار: lib/providers/player_firebase_logic.dart
part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerFirebaseLogic on PlayerProvider {

  Future<void> initializePlayerOnServer(String uid, String name) async {
    _uid = uid; _isLoading = true; notifyListeners();
    _playerDataSubscription?.cancel();
    try {
      final initialDoc = await _firestore.collection('players').doc(uid).get();
      if (initialDoc.exists) {
        _applyFirestoreData(initialDoc.data()!);
        if (_gameId == null) {
          _gameId = (100000 + Random().nextInt(900000)).toString();
          _isLoading = false; await _syncWithFirestore();
        }
      } else if (name.isNotEmpty) {
        _playerName = name; _inventory['name_change_card'] = 1;
        _gameId = (100000 + Random().nextInt(900000)).toString();
        _lastPassiveIncomeTime = secureNow;
        _lastEnergyUpdate = DateTime.now();
        _lastCourageUpdate = DateTime.now();
        _isLoading = false; await _syncWithFirestore();
      }
      // ignore: empty_catches
    } catch (e) {} finally { _isLoading = false; notifyListeners(); }
    _playerDataSubscription = _firestore.collection('players').doc(uid).snapshots().listen(
          (snapshot) {
        if (snapshot.exists && snapshot.metadata.hasPendingWrites == false) {
          _applyFirestoreData(snapshot.data()!);
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("❌ خطأ في stream بيانات اللاعب: $error");
      },
    );
  }

  void _listenToGameConfig() {
    final docRef = _firestore.collection('config').doc('game_settings');
    docRef.get().then((doc) {
      if (!doc.exists) docRef.set({'bailPrice': 1500}, SetOptions(merge: true));
    }).catchError((_) {});
    _gameConfigSubscription = docRef.snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('bailPrice')) {
          _bailPrice = (data['bailPrice'] as num).toInt();
          notifyListeners();
        }
      }
    }, onError: (error) {
      debugPrint("❌ خطأ في قراءة إعدادات اللعبة: $error");
    });
  }

  void _listenToEvents() {
    final eventRef = _firestore.collection('events').doc('active_events');
    eventRef.get().then((doc) {
      if (!doc.exists) eventRef.set({'crimeMultiplier': 1.0}, SetOptions(merge: true));
    }).catchError((_) {});
    _eventsSubscription = eventRef.snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('crimeMultiplier')) {
          var val = data['crimeMultiplier'];
          _crimeEventMultiplier = (val as num?)?.toDouble() ?? 1.0;
        } else {
          _crimeEventMultiplier = 1.0;
        }
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint("❌ خطأ في قراءة الأحداث: $error");
    });
  }

  void _applyFirestoreData(Map<String, dynamic> data) {
    _playerName = data['playerName'] ?? _playerName; _gameId = data['gameId'] ?? _gameId; _bio = data['bio'] ?? _bio;
    _profilePicUrl = data['profilePicUrl']; _backgroundPicUrl = data['backgroundPicUrl']; _currentCity = data['currentCity'] ?? 'ملاذ';
    _cash = data['cash'] ?? _cash; _gold = data['gold'] ?? _gold; _bankBalance = data['bankBalance'] ?? _bankBalance;

    _baseMaxHealth = data['maxHealth'] ?? _baseMaxHealth;
    _happiness = data['happiness'] ?? _happiness;
    _baseStrength = (data['strength'] ?? 5.0).toDouble(); _baseDefense = (data['defense'] ?? 5.0).toDouble(); _baseSkill = (data['skill'] ?? 5.0).toDouble(); _baseSpeed = (data['speed'] ?? 5.0).toDouble();
    _bonusPerkPoints = data['bonusPerkPoints'] ?? 0;

    _energy = data['energy'] ?? _energy;
    if (data['lastEnergyUpdate'] != null) {
      _lastEnergyUpdate = (data['lastEnergyUpdate'] is Timestamp) ? (data['lastEnergyUpdate'] as Timestamp).toDate() : DateTime.parse(data['lastEnergyUpdate'].toString());
    } else {
      _lastEnergyUpdate ??= DateTime.now();
    }

    _courage = data['courage'] ?? _courage;
    if (data['lastCourageUpdate'] != null) {
      _lastCourageUpdate = (data['lastCourageUpdate'] is Timestamp) ? (data['lastCourageUpdate'] as Timestamp).toDate() : DateTime.parse(data['lastCourageUpdate'].toString());
    } else {
      _lastCourageUpdate ??= DateTime.now();
    }

    if (!_isInitialDataLoaded) {
      _prestige = data['prestige'] ?? 100;
      _health = data['health'] ?? _health;
    } else {
      if (data['health'] != null) {
        if (data['health'] < (_health - 2) || (data['health'] - _health) > 2) {
          _health = data['health'];
        }
      }
      if (data['prestige'] != null) {
        if (data['prestige'] < (_prestige - 2) || (data['prestige'] - _prestige) > 2) {
          _prestige = data['prestige'];
        }
      }
    }

    if (data['activeSteroidEndTime'] != null) _activeSteroidEndTime = DateTime.parse(data['activeSteroidEndTime']);
    _activeCoach = data['activeCoach'];
    if (data['coachEndTime'] != null) _coachEndTime = DateTime.parse(data['coachEndTime']);

    _ownedProperties = List<String>.from(data['ownedProperties'] ?? []); _activePropertyId = data['activePropertyId'];

    // 🟢 قراءة الكميات من السيرفر 🟢
    if (data['ownedPropertyCounts'] != null) {
      _ownedPropertyCounts = Map<String, int>.from(data['ownedPropertyCounts']);
    } else {
      _ownedPropertyCounts = {};
      for (var id in _ownedProperties) {
        _ownedPropertyCounts[id] = 1;
      }
    }

    // 🟢 قراءة الصيانة والترقيات من السيرفر 🟢
    if (data['propertyConditions'] != null) {
      _propertyConditions = Map<String, double>.from((data['propertyConditions'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
    } else {
      _propertyConditions = {};
    }

    if (data['propertyUpgrades'] != null) {
      _propertyUpgrades = {};
      (data['propertyUpgrades'] as Map).forEach((k, v) {
        _propertyUpgrades[k.toString()] = List<String>.from(v);
      });
    }

    _listedProperties = List<String>.from(data['listedProperties'] ?? []);
    _rentedOutProperties = {};
    if (data['rentedOutProperties'] != null) {
      (data['rentedOutProperties'] as Map).forEach((k, v) {
        if (v is String) { _rentedOutProperties[k.toString()] = {'propertyId': k.toString(), 'expire': v, 'renterId': '', 'renterName': 'مجهول'}; }
        else { _rentedOutProperties[k.toString()] = Map<String, dynamic>.from(v); }
      });
    }
    if (data['activeRentedProperty'] != null) _activeRentedProperty = Map<String, dynamic>.from(data['activeRentedProperty']);
    _ownedBusinesses = Map<String, int>.from(data['ownedBusinesses'] ?? {}); _inventory = Map<String, int>.from(data['inventory'] ?? {});
    _crimeLevel = data['crimeLevel'] ?? 1; _crimeXP = data['crimeXP'] ?? 0; _lastCrimeName = data['lastCrimeName'] ?? "تسكع في الشوارع"; _playerBailCost = data['bailCost'] ?? 1500;
    _workLevel = data['workLevel'] ?? 1; _workXP = data['workXP'] ?? 0; _arenaLevel = data['arenaLevel'] ?? 1;

    bool wasInPrison = _isInPrison;
    DateTime? oldRelease = _prisonReleaseTime;
    _isInPrison = data['isInPrison'] ?? false;

    if (data['prisonReleaseTime'] != null) {
      _prisonReleaseTime = DateTime.parse(data['prisonReleaseTime']);
    } else {
      _prisonReleaseTime = null;
    }

    if (wasInPrison && !_isInPrison && oldRelease != null && secureNow.isBefore(oldRelease)) {
      _notificationStream.add("💸 كفالة!|لقد تم دفع كفالتك وإخراجك من السجن!");
    }

    _isHospitalized = data['isHospitalized'] ?? false; if (data['hospitalReleaseTime'] != null) _hospitalReleaseTime = DateTime.parse(data['hospitalReleaseTime']);
    _lockedBalance = data['lockedBalance'] ?? 0; _lockedProfits = data['lockedProfits'] ?? 0; if (data['lockedUntil'] != null) _lockedUntil = DateTime.parse(data['lockedUntil']);
    if (data['vipUntil'] != null) _vipUntil = DateTime.parse(data['vipUntil']);
    _totalVipDays = data['totalVipDays'] ?? 0;
    _totalLabCrafts = data['totalLabCrafts'] ?? 0;
    _luckyWheelSpins = data['luckyWheelSpins'] ?? 0;
    _loanAmount = data['loanAmount'] ?? 0; _creditScore = data['creditScore'] ?? 0; if (data['loanTime'] != null) _loanTime = DateTime.parse(data['loanTime']);
    _gangName = data['gangName']; _gangRank = data['gangRank'] ?? "عضو"; _gangContribution = data['gangContribution'] ?? 0; _gangWarWins = data['gangWarWins'] ?? 0;
    if (data['territoryOwners'] != null) _territoryOwners = Map<String, String>.from(data['territoryOwners']);
    if (data['contractEndTime'] != null) _contractEndTime = DateTime.parse(data['contractEndTime']);
    _activeContractName = data['activeContractName']; _contractSalary = data['contractSalary'] ?? 0; _ownedCars = List<String>.from(data['ownedCars'] ?? []); _activeCarId = data['activeCarId'];
    if (data['chopShopEndTime'] != null) _chopShopEndTime = DateTime.parse(data['chopShopEndTime']); _isChopping = data['isChopping'] ?? false;
    if (data['labEndTime'] != null) _labEndTime = DateTime.parse(data['labEndTime']); _isCrafting = data['isCrafting'] ?? false; _craftingItemId = data['craftingItemId'];
    _heat = (data['heat'] ?? 0.0).toDouble(); _spareParts = data['spareParts'] ?? 0;
    _durability = data['durability'] != null ? Map<String, double>.from(data['durability'].map((k, v) => MapEntry(k, v.toDouble()))) : {};

    _equippedWeaponId = data['equippedWeaponId'];
    _equippedArmorId = data['equippedArmorId'];
    _equippedMaskId = data['equippedMaskId'];
    _equippedCrimeToolId = data['equippedCrimeToolId'];
    _equippedSpecialId = data['equippedSpecialId'];

    if (data['transactions'] != null) _transactions = (data['transactions'] as List).map((t) => Transaction.fromJson(Map<String, dynamic>.from(t))).toList();
    if (data['crimeSuccessCountsMap'] != null) crimeSuccessCountsMap = Map<String, int>.from(data['crimeSuccessCountsMap']);

    _pvpWins = (data['pvpWins'] as num?)?.toInt() ?? 0;
    _totalStolenCash = (data['totalStolenCash'] as num?)?.toInt() ?? 0;
    _selectedTitle = data['selectedTitle'];

    _perks = {};
    if (data['perks'] != null && data['perks'] is Map) {
      (data['perks'] as Map).forEach((k, v) {
        if (GameData.perksList.any((p) => p['id'] == k.toString())) {
          _perks[k.toString()] = (v as num).toInt();
        }
      });
    }

    if (data['lastUpdate'] != null) {
      DateTime serverTime = (data['lastUpdate'] is Timestamp) ? (data['lastUpdate'] as Timestamp).toDate() : DateTime.parse(data['lastUpdate'].toString());
      int secondsPassed = DateTime.now().difference(serverTime).inSeconds;

      if (!_isInitialDataLoaded && secondsPassed > 0) {
        bool isVipNow = _vipUntil != null && secureNow.isBefore(_vipUntil!);

        int gainedPrestige = secondsPassed ~/ (isVipNow ? 36 : 72);
        _prestige = min(maxPrestige, _prestige + gainedPrestige);

        double healthRegenTime = 1800.0 + (maxHealth * 0.0005);
        double regenPerSecond = maxHealth / healthRegenTime;
        int gainedHealth = (secondsPassed * regenPerSecond).toInt();
        _health = min(maxHealth, _health + gainedHealth);

        double lostHeat = secondsPassed * 0.0278; _heat = max(0, _heat - lostHeat);

        // 🟢 نظام تهالك العقارات (15% يومياً) 🟢
        double dailyDegradation = 15.0;
        double degPerSecond = dailyDegradation / 86400.0;

        for (var propId in _ownedProperties) {
          double currentCond = _propertyConditions[propId] ?? 100.0;
          List<String> ups = _propertyUpgrades[propId] ?? [];
          double actualDeg = degPerSecond;

          if (ups.contains('security_guards')) actualDeg *= 0.5;

          _propertyConditions[propId] = max(0.0, currentCond - (actualDeg * secondsPassed));
        }

        Future.microtask(() => _syncWithFirestore());
      }

      _lastServerTime = serverTime;
      _sessionTimer.reset();
      _sessionTimer.start();
    }

    if (data['lastPassiveIncomeTime'] != null) {
      _lastPassiveIncomeTime = DateTime.parse(data['lastPassiveIncomeTime'].toString());
      int hoursPassed = secureNow.difference(_lastPassiveIncomeTime!).inHours;
      if (hoursPassed >= 24) {
        int daysPassed = hoursPassed ~/ 24;
        int passiveIncome = (getTotalPassiveIncomePerDay() + getPropertyRentIncomePerDay()) * daysPassed;
        if (passiveIncome > 0) { _cash += passiveIncome; Future.microtask(() => _sendSystemNotification("الأرباح اليومية 🏢", "استلمت أرباحك بقيمة: \$${_formatWithCommas(passiveIncome)}", "money")); }
        _lastPassiveIncomeTime = _lastPassiveIncomeTime!.add(Duration(days: daysPassed));
      }
    } else { _lastPassiveIncomeTime = secureNow; }

    if (data['unlockedTitlesList'] != null) {
      final serverList = List<String>.from(data['unlockedTitlesList']);
      for (final t in serverList) {
        if (!_unlockedTitlesList.contains(t)) _unlockedTitlesList.add(t);
      }
    } else {
      _unlockedTitlesList = getAllTitles().where((t) => t['unlocked'] == true).map((t) => t['name'] as String).toList();
    }

    _isInitialDataLoaded = true;
  }

  Future<void> _syncWithFirestore() async {
    if (_uid == null || _isLoading) return;
    try {
      await _firestore.collection('players').doc(_uid).set({
        'playerName': _playerName, 'gameId': _gameId, 'bio': _bio, 'profilePicUrl': _profilePicUrl, 'backgroundPicUrl': _backgroundPicUrl, 'currentCity': _currentCity,
        'cash': _cash, 'gold': _gold, 'bankBalance': _bankBalance,
        'prestige': _prestige, 'health': _health, 'maxHealth': _baseMaxHealth, 'happiness': _happiness, 'strength': _baseStrength, 'defense': _baseDefense, 'skill': _baseSkill, 'speed': _baseSpeed,
        'activeSteroidEndTime': _activeSteroidEndTime?.toIso8601String(), 'activeCoach': _activeCoach, 'coachEndTime': _coachEndTime?.toIso8601String(),
        'ownedProperties': _ownedProperties, 'ownedPropertyCounts': _ownedPropertyCounts, 'propertyConditions': _propertyConditions, 'propertyUpgrades': _propertyUpgrades, 'activePropertyId': _activePropertyId, 'listedProperties': _listedProperties, 'rentedOutProperties': _rentedOutProperties, 'activeRentedProperty': _activeRentedProperty, 'ownedBusinesses': _ownedBusinesses, 'lastPassiveIncomeTime': _lastPassiveIncomeTime?.toIso8601String(),
        'inventory': _inventory, 'crimeLevel': _crimeLevel, 'crimeXP': _crimeXP, 'workLevel': _workLevel, 'workXP': _workXP, 'arenaLevel': _arenaLevel, 'isInPrison': _isInPrison, 'prisonReleaseTime': _prisonReleaseTime?.toIso8601String(), 'isHospitalized': _isHospitalized, 'hospitalReleaseTime': _hospitalReleaseTime?.toIso8601String(), 'lockedBalance': _lockedBalance, 'lockedProfits': _lockedProfits, 'lockedUntil': _lockedUntil?.toIso8601String(), 'vipUntil': _vipUntil?.toIso8601String(), 'totalVipDays': _totalVipDays, 'totalLabCrafts': _totalLabCrafts, 'luckyWheelSpins': _luckyWheelSpins, 'loanAmount': _loanAmount, 'creditScore': _creditScore, 'loanTime': _loanTime?.toIso8601String(), 'gangName': _gangName, 'gangRank': _gangRank, 'gangContribution': _gangContribution, 'gangWarWins': _gangWarWins, 'territoryOwners': _territoryOwners, 'crimeSuccessCountsMap': crimeSuccessCountsMap, 'contractEndTime': _contractEndTime?.toIso8601String(), 'activeContractName': _activeContractName, 'contractSalary': _contractSalary, 'lastUpdate': FieldValue.serverTimestamp(), 'ownedCars': _ownedCars, 'activeCarId': _activeCarId, 'chopShopEndTime': _chopShopEndTime?.toIso8601String(), 'isChopping': _isChopping, 'labEndTime': _labEndTime?.toIso8601String(), 'isCrafting': _isCrafting, 'craftingItemId': _craftingItemId, 'heat': _heat, 'spareParts': _spareParts, 'durability': _durability,
        'equippedWeaponId': _equippedWeaponId, 'equippedArmorId': _equippedArmorId, 'equippedMaskId': _equippedMaskId, 'equippedCrimeToolId': _equippedCrimeToolId, 'equippedSpecialId': _equippedSpecialId,
        'bonusPerkPoints': _bonusPerkPoints,
        'transactions': _transactions.map((t) => t.toJson()).toList(), 'lastCrimeName': _lastCrimeName, 'bailCost': _playerBailCost,
        'pvpWins': _pvpWins,
        'totalStolenCash': _totalStolenCash,
        'perks': _perks,
        'selectedTitle': _selectedTitle,
        'unlockedTitlesList': _unlockedTitlesList,
      }, SetOptions(merge: true));
      // ignore: empty_catches
    } catch (e) {}
  }
}