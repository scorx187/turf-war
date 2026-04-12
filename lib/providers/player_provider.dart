// المسار: lib/providers/player_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/game_data.dart';
import '../utils/local_notification_service.dart';

part 'player_real_estate_logic.dart';
part 'player_market_logic.dart';
part 'player_combat_logic.dart';
part 'player_inventory_logic.dart';
part 'player_social_logic.dart';

part 'player_titles_logic.dart';
part 'player_stats_logic.dart';

class Transaction {
  final String title;
  final int amount;
  final DateTime date;
  final bool isPositive;
  final String? senderUid;

  Transaction({required this.title, required this.amount, required this.date, required this.isPositive, this.senderUid});

  Map<String, dynamic> toJson() => {'title': title, 'amount': amount, 'date': date.toIso8601String(), 'isPositive': isPositive, 'senderUid': senderUid};
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(title: json['title'], amount: json['amount'], date: DateTime.parse(json['date']), isPositive: json['isPositive'], senderUid: json['senderUid']);
}

class PlayerProvider with ChangeNotifier, WidgetsBindingObserver {
  String? _uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _playerDataSubscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _isInitialDataLoaded = false;

  int _bailPrice = 1500;
  int get bailPrice => _bailPrice;
  int _playerBailCost = 1500;
  int get playerBailCost => _playerBailCost; // 🟢 التعديل: إضافة قراءة قيمة الكفالة

  String? _gameId;
  String? get gameId => _gameId;
  String _lastCrimeName = "تسكع في الشوارع";
  String get lastCrimeName => _lastCrimeName; // 🟢 التعديل: إضافة قراءة اسم الجريمة

  int _cash = 100;
  int _gold = 0;
  int _bankBalance = 0;
  int _energy = 100;
  int _courage = 100;
  int _health = 100;
  int _baseMaxHealth = 100;
  int _prestige = 100;
  int _bonusPerkPoints = 0;

  double _fractionalHealth = 0.0;

  String _playerName = "لاعب جديد";
  String _bio = "لا يوجد وصف حالياً... رجل أفعال لا أقوال.";
  String get bio => _bio;

  String? _profilePicUrl;
  String? get profilePicUrl => _profilePicUrl;

  String? _backgroundPicUrl;
  String? get backgroundPicUrl => _backgroundPicUrl;

  String _currentCity = 'ملاذ';
  String get currentCity => _currentCity;

  double _heat = 0.0;
  int _spareParts = 0;
  Map<String, double> _durability = {};
  String? _equippedCrimeToolId;
  String? _equippedSpecialId;

  double _baseStrength = 5.0;
  double _baseDefense = 5.0;
  double _baseSkill = 5.0;
  double _baseSpeed = 5.0;

  DateTime? _activeSteroidEndTime;
  String? _activeCoach;
  DateTime? _coachEndTime;

  DateTime? get activeSteroidEndTime => _activeSteroidEndTime;
  String? get activeCoach => _activeCoach;
  DateTime? get coachEndTime => _coachEndTime;

  List<String> _ownedProperties = [];
  String? _activePropertyId;
  int _happiness = 0;

  List<String> _listedProperties = [];
  Map<String, dynamic> _rentedOutProperties = {};
  Map<String, dynamic>? _activeRentedProperty;

  List<String> get listedProperties => _listedProperties;
  Map<String, dynamic> get rentedOutProperties => _rentedOutProperties;
  Map<String, dynamic>? get activeRentedProperty => _activeRentedProperty;

  Map<String, int> _ownedBusinesses = {};
  Map<String, int> get ownedBusinesses => _ownedBusinesses;

  DateTime? _lastPassiveIncomeTime;

  bool _isInPrison = false;
  DateTime? _prisonReleaseTime;
  bool _isHospitalized = false;
  DateTime? _hospitalReleaseTime;

  int _lockedBalance = 0;
  int _lockedProfits = 0;
  DateTime? _lockedUntil;
  int _loanAmount = 0;
  int _creditScore = 0;
  DateTime? _loanTime;

  Map<String, int> _inventory = {};
  String? _equippedWeaponId;
  String? _equippedArmorId;
  String? _equippedMaskId;
  DateTime? _vipUntil;
  int _totalVipDays = 0;

  int _totalLabCrafts = 0;
  int _luckyWheelSpins = 0;
  List<String> _unlockedTitlesList = [];

  List<String> _ownedCars = [];
  String? _activeCarId;

  DateTime? _chopShopEndTime;
  bool _isChopping = false;

  DateTime? _labEndTime;
  bool _isCrafting = false;
  String? _craftingItemId;

  int _crimeLevel = 1;
  int _crimeXP = 0;
  int _workLevel = 1;
  int _workXP = 0;
  int _arenaLevel = 1;

  DateTime? _contractEndTime;
  DateTime? _lastContractRewardTime;
  int _contractSalary = 0;
  String? _activeContractName;

  String? _gangName;
  String _gangRank = "عضو";
  int _gangContribution = 0;
  int _gangWarWins = 0;
  Map<String, String> _territoryOwners = {};

  Map<String, int> crimeSuccessCountsMap = {};
  List<Transaction> _transactions = [];

  final Map<String, Uint8List> _decodedImagesCache = {};

  int _pvpWins = 0;
  int _totalStolenCash = 0;
  Map<String, int> _perks = {};

  String? _selectedTitle;
  String? get selectedTitle => _selectedTitle;

  DateTime? _lastServerTime;
  final Stopwatch _sessionTimer = Stopwatch();

  DateTime get secureNow {
    if (_lastServerTime == null) return DateTime.now();
    return _lastServerTime!.add(_sessionTimer.elapsed);
  }

  int get secondsToNextCourage => _courage >= maxCourage ? 0 : 4 - (_sessionTimer.elapsed.inSeconds % 4);
  int get secondsToNextEnergy => _energy >= maxEnergy ? 0 : 8 - (_sessionTimer.elapsed.inSeconds % 8);

  double get baseStrength => _baseStrength;
  double get baseDefense => _baseDefense;
  double get baseSkill => _baseSkill;
  double get baseSpeed => _baseSpeed;
  double get bonusStrength => strength - _baseStrength;
  double get bonusDefense => defense - _baseDefense;
  double get bonusSpeed => speed - _baseSpeed;
  double get bonusSkill => skill - _baseSkill;

  String? get uid => _uid;
  int get cash => _cash;
  int get gold => _gold;
  int get bankBalance => _bankBalance;
  int get energy => _energy;
  int get courage => _courage;
  int get health => _health;
  String get playerName => _playerName;
  bool get isInPrison => _isInPrison;
  DateTime? get prisonReleaseTime => _prisonReleaseTime;
  bool get isHospitalized => _isHospitalized;
  DateTime? get hospitalReleaseTime => _hospitalReleaseTime;
  Map<String, int> get inventory => _inventory;
  List<String> get ownedProperties => _ownedProperties;
  String? get activePropertyId => _activePropertyId;
  String? get equippedWeaponId => _equippedWeaponId;
  String? get equippedArmorId => _equippedArmorId;
  String? get equippedMaskId => _equippedMaskId;
  String? get equippedCrimeToolId => _equippedCrimeToolId;
  String? get equippedSpecialId => _equippedSpecialId;
  List<String> get ownedCars => _ownedCars;
  String? get activeCarId => _activeCarId;
  double get heat => _heat;
  int get spareParts => _spareParts;
  double getItemDurability(String id) => _durability[id] ?? 100.0;
  DateTime? get chopShopEndTime => _chopShopEndTime;
  bool get isChopping => _isChopping;
  DateTime? get labEndTime => _labEndTime;
  bool get isCrafting => _isCrafting;
  String? get craftingItemId => _craftingItemId;
  DateTime? get lockedUntil => _lockedUntil;
  int get lockedBalance => _lockedBalance;
  int get lockedProfits => _lockedProfits;
  int get loanAmount => _loanAmount;
  int get creditScore => _creditScore;
  DateTime? get loanTime => _loanTime;
  int get maxLoanLimit => 20000 + (_creditScore * 2000);
  bool get isInvestmentLocked => _lockedUntil != null && secureNow.isBefore(_lockedUntil!);
  int get crimeLevel => _crimeLevel;
  int get crimeXP => _crimeXP;
  int get xpToNextLevel => (100 * pow(1.05, _crimeLevel - 1)).toInt();
  int get workLevel => _workLevel;
  int get workXP => _workXP;
  int get workXPToNextLevel => max(150, _workLevel * 150);
  int get arenaLevel => _arenaLevel;
  bool get isUnderContract => _contractEndTime != null && secureNow.isBefore(_contractEndTime!);
  DateTime? get contractEndTime => _contractEndTime;
  String? get activeContractName => _activeContractName;
  bool get isInGang => _gangName != null;
  String? get gangName => _gangName;
  String get gangRank => _gangRank;
  int get gangContribution => _gangContribution;
  int get gangWarWins => _gangWarWins;
  Map<String, String> get territoryOwners => _territoryOwners;
  DateTime? get vipUntil => _vipUntil;
  bool get isVIP => _vipUntil != null && secureNow.isBefore(_vipUntil!);
  int get prestige => _prestige;
  int get maxPrestige => isVIP ? 200 : 100;
  List<Transaction> get transactions => _transactions;

  int get pvpWins => _pvpWins;
  int get totalStolenCash => _totalStolenCash;
  Map<String, int> get perks => _perks;
  int get totalVipDays => _totalVipDays;
  int get totalLabCrafts => _totalLabCrafts;
  int get luckyWheelSpins => _luckyWheelSpins;
  int get bonusPerkPoints => _bonusPerkPoints;

  final StreamController<String> _notificationStream = StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationStream.stream;

  Timer? _gameLoopTimer;

  String get currentResidenceName {
    final allProps = [...GameData.residentialProperties];
    String? id = _activePropertyId;
    if (id == null && _activeRentedProperty != null) id = _activeRentedProperty!['id'];
    if (id == null) return "مشرد في الشوارع";
    return allProps.firstWhere((p) => p['id'] == id, orElse: () => {'name': 'غير معروف'})['name'];
  }

  PlayerProvider() {
    WidgetsBinding.instance.addObserver(this);
    _startGameLoop();
    _listenToGameConfig();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) && _uid != null && !_isLoading) {
      _syncWithFirestore();
    }
  }

  void _sendSystemNotification(String title, String message, String iconType) {
    if (_uid != null && _uid!.isNotEmpty) {
      _firestore.collection('notifications').add({
        'uid': _uid,
        'title': title,
        'body': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'icon': iconType,
      });
    }
    LocalNotificationService.showNotification(title, message);
  }

  // 🟢 الدالة التي تسببت في الخطأ تم إرجاعها هنا
  void _showNotification(String message) {
    _notificationStream.add(message);
  }

  String _formatWithCommas(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Uint8List? getDecodedImage(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    if (_decodedImagesCache.containsKey(base64Str)) return _decodedImagesCache[base64Str]!;
    try {
      final bytes = base64Decode(base64Str);
      _decodedImagesCache[base64Str] = bytes;
      return bytes;
    } catch (e) { return null; }
  }

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
        _isLoading = false; await _syncWithFirestore();
      }
    } catch (e) {} finally { _isLoading = false; notifyListeners(); }
    _playerDataSubscription = _firestore.collection('players').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.metadata.hasPendingWrites == false) { _applyFirestoreData(snapshot.data()!); notifyListeners(); }
    });
  }

  void _listenToGameConfig() {
    _firestore.collection('config').doc('game_settings').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('bailPrice')) { _bailPrice = data['bailPrice']; notifyListeners(); }
      }
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

    if (!_isInitialDataLoaded) {
      _energy = data['energy'] ?? _energy;
      _courage = data['courage'] ?? _courage;
      _prestige = data['prestige'] ?? 100;
      _health = data['health'] ?? _health;
    } else if (data['health'] != null && data['health'] < _health) {
      _health = data['health'];
    }

    if (data['activeSteroidEndTime'] != null) _activeSteroidEndTime = DateTime.parse(data['activeSteroidEndTime']);
    _activeCoach = data['activeCoach'];
    if (data['coachEndTime'] != null) _coachEndTime = DateTime.parse(data['coachEndTime']);

    _ownedProperties = List<String>.from(data['ownedProperties'] ?? []); _activePropertyId = data['activePropertyId'];
    _listedProperties = List<String>.from(data['listedProperties'] ?? []);
    _rentedOutProperties = {};
    if (data['rentedOutProperties'] != null) {
      (data['rentedOutProperties'] as Map).forEach((k, v) {
        if (v is String) _rentedOutProperties[k.toString()] = {'expire': v, 'renterId': '', 'renterName': 'مجهول'};
        else _rentedOutProperties[k.toString()] = Map<String, dynamic>.from(v);
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
      _lastServerTime = serverTime;
      _sessionTimer.reset();
      _sessionTimer.start();

      int secondsPassed = secureNow.difference(serverTime).inSeconds;
      if (secondsPassed > 0) {
        int gainedCourage = secondsPassed ~/ 4; _courage = min(maxCourage, _courage + gainedCourage);
        int gainedPrestige = secondsPassed ~/ 6; _prestige = min(maxPrestige, _prestige + gainedPrestige);
        int gainedEnergy = secondsPassed ~/ 8; _energy = min(maxEnergy, _energy + gainedEnergy);
        double regenPerSecond = maxHealth / 1800.0; int gainedHealth = (secondsPassed * regenPerSecond).toInt();
        _health = min(maxHealth, _health + gainedHealth);
        double lostHeat = secondsPassed * 0.0278; _heat = max(0, _heat - lostHeat);
      }
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
      _unlockedTitlesList = List<String>.from(data['unlockedTitlesList']);
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
        'cash': _cash, 'gold': _gold, 'bankBalance': _bankBalance, 'energy': _energy, 'courage': _courage, 'prestige': _prestige, 'health': _health, 'maxHealth': _baseMaxHealth, 'happiness': _happiness, 'strength': _baseStrength, 'defense': _baseDefense, 'skill': _baseSkill, 'speed': _baseSpeed,
        'activeSteroidEndTime': _activeSteroidEndTime?.toIso8601String(), 'activeCoach': _activeCoach, 'coachEndTime': _coachEndTime?.toIso8601String(),
        'ownedProperties': _ownedProperties, 'activePropertyId': _activePropertyId, 'listedProperties': _listedProperties, 'rentedOutProperties': _rentedOutProperties, 'activeRentedProperty': _activeRentedProperty, 'ownedBusinesses': _ownedBusinesses, 'lastPassiveIncomeTime': _lastPassiveIncomeTime?.toIso8601String(),
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
    } catch (e) {}
  }

  void putInPrison(int minutes, String crimeName, int bailCost) {
    _isInPrison = true;
    _prisonReleaseTime = secureNow.add(Duration(minutes: minutes));
    _playerBailCost = bailCost;
    _lastCrimeName = crimeName;
    _syncWithFirestore();
    notifyListeners();
  }

  bool attemptEscape() {
    if (_courage < 10 || !_isInPrison) return false;
    _courage -= 10;
    bool success = Random().nextDouble() < 0.3;
    if (success) {
      _isInPrison = false;
      _prisonReleaseTime = null;
      _notificationStream.add("هروب ناجح 🏃‍♂️|لقد تمكنت من الهروب من السجن بنجاح!");
    }
    _syncWithFirestore();
    notifyListeners();
    return success;
  }

  void addEnergy(int amount) {
    _energy = min(maxEnergy, _energy + amount);
    _syncWithFirestore();
    notifyListeners();
  }

  void addInventoryItem(String itemId, int quantity) {
    _inventory[itemId] = (_inventory[itemId] ?? 0) + quantity;
    _syncWithFirestore();
    notifyListeners();
  }

  void addBonusPerkPoint(int amount) {
    _bonusPerkPoints += amount;
    _syncWithFirestore();
    notifyListeners();
  }

  void toggleSpecialItem(String itemId) {
    if (_equippedSpecialId == itemId) {
      _equippedSpecialId = null;
    } else {
      _equippedSpecialId = itemId;
    }
    _syncWithFirestore();
    notifyListeners();
  }

  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLoading) return;
      bool localChanged = false;

      if (timer.tick % 5 == 0) {
        checkNewTitles();
      }

      if (_activeSteroidEndTime != null && secureNow.isAfter(_activeSteroidEndTime!)) {
        _activeSteroidEndTime = null;
        localChanged = true;
      }

      if (_coachEndTime != null && secureNow.isAfter(_coachEndTime!)) {
        _activeCoach = null;
        _coachEndTime = null;
        localChanged = true;
      }

      int steroidCooldown = _inventory['steroid_cooldown'] ?? 0;
      if (steroidCooldown > 0 && secureNow.millisecondsSinceEpoch > steroidCooldown) {
        _inventory.remove('steroid_cooldown');
        if (_uid != null) {
          _firestore.collection('players').doc(_uid).update({'inventory.steroid_cooldown': FieldValue.delete()}).catchError((_) {});
        }
        _sendSystemNotification("سوق المنشطات 💉", "انتهت فترة الراحة للمنشطات! يمكنك شراء وحقن جرعة جديدة الآن.", "info");
        localChanged = true;
      }

      int coachCooldown = _inventory['coach_cooldown'] ?? 0;
      if (coachCooldown > 0 && secureNow.millisecondsSinceEpoch > coachCooldown) {
        _inventory.remove('coach_cooldown');
        if (_uid != null) {
          _firestore.collection('players').doc(_uid).update({'inventory.coach_cooldown': FieldValue.delete()}).catchError((_) {});
        }
        _sendSystemNotification("صالة التدريب 🥊", "المدربون متاحون الآن للتعاقد من جديد!", "info");
        localChanged = true;
      }

      if (_activeRentedProperty != null && secureNow.isAfter(DateTime.parse(_activeRentedProperty!['expire']))) {
        String propId = _activeRentedProperty!['id']; _activeRentedProperty = null;
        if (_activePropertyId == propId) { _activePropertyId = null; _happiness = 0; }
        _sendSystemNotification("إيجار السكن 🏠", "انتهى عقد إيجار سكنك الحالي!", "home");
        localChanged = true;
      }

      if (_rentedOutProperties.isNotEmpty) {
        List<String> expired = [];
        _rentedOutProperties.forEach((id, data) { if (secureNow.isAfter(DateTime.parse(data['expire']))) expired.add(id); });
        for (var id in expired) {
          _rentedOutProperties.remove(id);
          _sendSystemNotification("إدارة الأملاك 🔑", "انتهت مدة إيجار عقارك ($id) وعاد إليك!", "key");
          localChanged = true;
        }
      }

      if (_heat > 0) { _heat = max(0, _heat - 0.0278); localChanged = true; }
      if (timer.tick % 4 == 0 && _courage < maxCourage) { _courage++; localChanged = true; }
      if (timer.tick % 6 == 0 && _prestige < maxPrestige) { _prestige++; localChanged = true; }
      if (timer.tick % 8 == 0 && _energy < maxEnergy) { _energy++; localChanged = true; }

      if (_health < maxHealth) {
        double regenPerSecond = maxHealth / 1800.0; _fractionalHealth += regenPerSecond;
        if (_fractionalHealth >= 1.0) {
          int healAmount = _fractionalHealth.toInt(); _health = min(maxHealth, _health + healAmount); _fractionalHealth -= healAmount; localChanged = true;
          if (_health >= maxHealth && _isHospitalized) {
            _isHospitalized = false; _hospitalReleaseTime = null;
            _sendSystemNotification("المستشفى 🏥", "تعافيت بالكامل وخرجت من المستشفى!", "hospital");
          }
        }
      } else { _fractionalHealth = 0.0; }

      if (_lastPassiveIncomeTime != null && secureNow.difference(_lastPassiveIncomeTime!).inHours >= 24) {
        int passiveIncome = getTotalPassiveIncomePerDay() + getPropertyRentIncomePerDay();
        if (passiveIncome > 0) {
          _cash += passiveIncome;
          _sendSystemNotification("الأرباح اليومية 🏢", "استلمت أرباحك اليومية: \$${_formatWithCommas(passiveIncome)}", "money");
        }
        _lastPassiveIncomeTime = _lastPassiveIncomeTime!.add(const Duration(hours: 24)); localChanged = true;
      }

      if (timer.tick % 60 == 0) { for (var tool in GameData.crimeToolsList) { if ((_durability[tool] ?? 100) < 100) { _durability[tool] = min(100.0, (_durability[tool] ?? 100) + 1.0); localChanged = true; } } }
      if (_loanAmount > 0 && _loanTime != null) {
        if (secureNow.difference(_loanTime!).inHours >= 2) {
          _loanAmount = (_loanAmount * 1.1).floor(); _loanTime = secureNow;
          _sendSystemNotification("البنك 🏦", "تمت إضافة فوائد 10% على قرضك لتأخرك في السداد!", "bank");
          localChanged = true;
        }
      }
      if (_isInPrison && _prisonReleaseTime != null && secureNow.isAfter(_prisonReleaseTime!)) {
        _isInPrison = false; _prisonReleaseTime = null;
        _notificationStream.add("إفراج 🔓|تم الإفراج عنك من السجن بعد انتهاء مدة عقوبتك.");
        localChanged = true;
      }
      if (_isHospitalized && _hospitalReleaseTime != null && secureNow.isAfter(_hospitalReleaseTime!)) {
        _isHospitalized = false; _hospitalReleaseTime = null; _health = (maxHealth * 0.25).toInt();
        _sendSystemNotification("المستشفى 🏥", "تم خروجك من المستشفى!", "hospital");
        localChanged = true;
      }
      if (_lockedUntil != null && secureNow.isAfter(_lockedUntil!)) {
        int total = _lockedBalance + _lockedProfits; _bankBalance += total; _lockedBalance = 0; _lockedProfits = 0; _lockedUntil = null;
        _sendSystemNotification("الاستثمار 📈", "انتهى الاستثمار! استلمت $total كاش", "invest");
        localChanged = true;
      }
      if (isUnderContract && _lastContractRewardTime != null && secureNow.difference(_lastContractRewardTime!).inMinutes >= 1) {
        _cash += _contractSalary; _lastContractRewardTime = secureNow; _addTransaction("راتب عقد: $_activeContractName", _contractSalary, true); _workXP += 5;
        if (_workXP >= workXPToNextLevel) { _workXP -= workXPToNextLevel; _workLevel++; }
        localChanged = true;
      }

      if (localChanged) notifyListeners();
    });
  }

  void travelToCity(String city, int price) { if (_cash >= price) { _cash -= price; _currentCity = city; _syncWithFirestore(); notifyListeners(); _sendSystemNotification("السفر ✈️", "هبطت طائرتك بسلام في $city!", "info"); } }
  void updateBio(String newBio) { if (newBio.length <= 150) { _bio = newBio; _syncWithFirestore(); notifyListeners(); } }
  void updateProfilePic(String base64Image) { _profilePicUrl = base64Image; notifyListeners(); _syncWithFirestore(); _firestore.collection('chat').where('uid', isEqualTo: _uid).get().then((snapshot) { WriteBatch batch = _firestore.batch(); for (var doc in snapshot.docs) { batch.update(doc.reference, {'profilePicUrl': base64Image}); } batch.commit(); }); }
  void updateBackgroundPic(String base64Image) { _backgroundPicUrl = base64Image; _syncWithFirestore(); notifyListeners(); }
  void increaseHeat(double amount) { _heat = min(100, _heat + amount); notifyListeners(); }
  void reduceHeat(double amount) { _heat = max(0, _heat - amount); notifyListeners(); }
  void addCash(int amount, {String reason = "مكافأة", String? senderUid}) { _cash += amount; _addTransaction(reason, amount, true, senderUid: senderUid); _syncWithFirestore(); notifyListeners(); }
  void removeCash(int amount, {String reason = "خصم", String? senderUid}) { _cash = max(0, _cash - amount); _addTransaction(reason, amount, false, senderUid: senderUid); _syncWithFirestore(); notifyListeners(); }
  void addGold(int amount) { _gold += amount; _syncWithFirestore(); notifyListeners(); }
  void removeGold(int amount) { _gold = max(0, _gold - amount); _syncWithFirestore(); notifyListeners(); }
  void updateName(String newName) { if (_inventory.containsKey('name_change_card') && _inventory['name_change_card']! > 0) { _playerName = newName; _inventory['name_change_card'] = _inventory['name_change_card']! - 1; if (_inventory['name_change_card'] == 0) _inventory.remove('name_change_card'); _syncWithFirestore(); notifyListeners(); } }

  void addWorkXP(int amount) {
    _workXP += amount;
    if (_workXP >= workXPToNextLevel) {
      _workXP -= workXPToNextLevel;
      _workLevel++;
    }
    _syncWithFirestore();
    notifyListeners();
  }

  void addCrimeXP(int amount) {
    _crimeXP += amount;
    if (_crimeXP >= xpToNextLevel) {
      _crimeXP -= xpToNextLevel;
      _crimeLevel++;
      _notificationStream.add("ترقية 🔫|تهانينا! وصلت للمستوى $_crimeLevel في الجريمة");
    }
    _syncWithFirestore();
    notifyListeners();
  }

  void buyVIP(int days, int cost) {
    if (_gold >= cost) {
      _gold -= cost;
      _totalVipDays += days;
      DateTime start = isVIP ? _vipUntil! : secureNow;
      _vipUntil = start.add(Duration(days: days));
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void incrementLabCrafts() { _totalLabCrafts++; _syncWithFirestore(); notifyListeners(); }
  void incrementLuckyWheelSpins() { _luckyWheelSpins++; _syncWithFirestore(); notifyListeners(); }

  void _addTransaction(String title, int amount, bool isPositive, {String? senderUid}) { _transactions.insert(0, Transaction(title: title, amount: amount, date: secureNow, isPositive: isPositive, senderUid: senderUid)); if (_transactions.length > 20) _transactions.removeLast(); }

  void updateTitle(String newTitle) {
    _selectedTitle = newTitle;
    _syncWithFirestore();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getPlayerById(String targetUid) async {
    try {
      DocumentSnapshot serverDoc = await _firestore.collection('players').doc(targetUid).get(const GetOptions(source: Source.server));
      if (serverDoc.exists) { Map<String, dynamic> data = serverDoc.data() as Map<String, dynamic>; data['uid'] = serverDoc.id; return data; }
    } catch (e) { debugPrint("خطأ في جلب بيانات اللاعب: $e"); }
    return null;
  }

  Future<void> resetPlayerData() async {
    _cash = 500; _gold = 0; _bankBalance = 0; _energy = 100; _courage = 100; _prestige = 100; _baseStrength = 5; _baseDefense = 5; _baseSkill = 5; _baseSpeed = 5;
    _ownedProperties = []; _activePropertyId = null; _ownedBusinesses = {}; _happiness = 0; _inventory = {'name_change_card': 1};
    _equippedWeaponId = null; _equippedArmorId = null; _equippedMaskId = null; _equippedSpecialId = null; _vipUntil = null; _totalVipDays = 0; _totalLabCrafts = 0; _luckyWheelSpins = 0; _unlockedTitlesList = [];
    _isHospitalized = false; _hospitalReleaseTime = null; _crimeLevel = 1; _workLevel = 1; _crimeXP = 0; _workXP = 0; _isInPrison = false; _prisonReleaseTime = null; _lockedBalance = 0; _lockedProfits = 0; _lockedUntil = null;
    _arenaLevel = 1; _loanAmount = 0; _creditScore = 0; _loanTime = null; _gangName = null; _gangRank = "عضو"; _gangContribution = 0; _gangWarWins = 0; _territoryOwners = {};
    crimeSuccessCountsMap = {}; _transactions = []; _chopShopEndTime = null; _isChopping = false; _labEndTime = null; _isCrafting = false; _craftingItemId = null;
    _heat = 0.0; _spareParts = 0; _durability = {}; _equippedCrimeToolId = null; _bio = "لا يوجد وصف حالياً... رجل أفعال لا أقوال."; _profilePicUrl = null; _backgroundPicUrl = null; _currentCity = 'ملاذ';
    _listedProperties = []; _rentedOutProperties = {}; _activeRentedProperty = null; _lastPassiveIncomeTime = secureNow;
    _activeSteroidEndTime = null; _activeCoach = null; _coachEndTime = null; _pvpWins = 0; _totalStolenCash = 0; _perks = {}; _selectedTitle = null; _baseMaxHealth = 100; _bonusPerkPoints = 0;
    await _syncWithFirestore(); notifyListeners();
  }

  void clearDataOnLogout() {
    _uid = null;
    _playerDataSubscription?.cancel();

    _cash = 100; _gold = 0; _bankBalance = 0;
    _energy = 100; _courage = 100; _health = 100; _prestige = 100; _baseMaxHealth = 100; _bonusPerkPoints = 0;
    _baseStrength = 5.0; _baseDefense = 5.0; _baseSkill = 5.0; _baseSpeed = 5.0;

    _crimeLevel = 1; _crimeXP = 0; _workLevel = 1; _workXP = 0; _arenaLevel = 1;

    _ownedProperties = []; _activePropertyId = null; _listedProperties = []; _rentedOutProperties = {}; _activeRentedProperty = null;
    _ownedBusinesses = {}; _inventory = {}; _ownedCars = []; _activeCarId = null;

    _transactions = []; _unlockedTitlesList = []; _perks = {}; crimeSuccessCountsMap = {};
    _durability = {}; _equippedWeaponId = null; _equippedArmorId = null; _equippedMaskId = null; _equippedCrimeToolId = null; _equippedSpecialId = null;

    _playerName = "لاعب جديد"; _gameId = null; _bio = "لا يوجد وصف حالياً... رجل أفعال لا أقوال.";
    _profilePicUrl = null; _backgroundPicUrl = null; _gangName = null; _gangRank = "عضو";

    _pvpWins = 0; _totalStolenCash = 0; _totalVipDays = 0; _totalLabCrafts = 0; _luckyWheelSpins = 0;
    _isHospitalized = false; _isInPrison = false; _lockedBalance = 0; _lockedProfits = 0; _lockedUntil = null;
    _loanAmount = 0; _creditScore = 0; _loanTime = null;
    _chopShopEndTime = null; _isChopping = false; _labEndTime = null; _isCrafting = false; _craftingItemId = null;
    _activeSteroidEndTime = null; _activeCoach = null; _coachEndTime = null; _contractEndTime = null; _activeContractName = null;

    notifyListeners();
  }

  void upgradePerk(String perkId) {
    int currentLvl = _perks[perkId] ?? 0;
    int maxLvl = GameData.perksList.firstWhere((p) => p['id'] == perkId)['maxLevel'];
    if (currentLvl < maxLvl && unspentSkillPoints > 0) {
      _perks[perkId] = currentLvl + 1;
      _syncWithFirestore();
      notifyListeners();
      _sendSystemNotification("شجرة الامتيازات ⭐", "تم تفعيل الامتياز بنجاح!", "star");
    } else {
      _sendSystemNotification("نقاط غير كافية ⚠️", "حقق المزيد من الألقاب لجمع النقاط.", "warning");
    }
  }

  // دالة الخروج من المستشفى
  void releaseFromHospital() {
    _isHospitalized = false;
    _hospitalReleaseTime = null;
    notifyListeners();
    _syncWithFirestore();
  }

  // 🟢 دالة الإفراج الفوري من السجن لإنهاء الانتظار
  void releaseFromPrison() {
    _isInPrison = false;
    _prisonReleaseTime = null;
    notifyListeners();
  }

  // دالة تحديد مستوى الملاحقة الأمنية
  void setHeat(double value) {
    _heat = value;
    if (_heat < 0) _heat = 0;
    notifyListeners();
    _syncWithFirestore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerDataSubscription?.cancel();
    _gameLoopTimer?.cancel();
    _notificationStream.close();
    _sessionTimer.stop();
    super.dispose();
  }
}