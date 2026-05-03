// المسار: lib/providers/player_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/game_data.dart';
import '../utils/local_notification_service.dart';

part 'player_real_estate_logic.dart';
part 'player_market_logic.dart';
part 'player_combat_logic.dart';
part 'player_inventory_logic.dart';
part 'player_social_logic.dart';
part 'player_titles_logic.dart';
part 'player_stats_logic.dart';
part 'player_firebase_logic.dart';
part 'player_game_loop.dart';
part 'player_actions_logic.dart';
part 'player_profile_logic.dart';

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
  StreamSubscription? _gameConfigSubscription;
  StreamSubscription? _eventsSubscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _isInitialDataLoaded = false;

  // 🟢 ===== إضافة وضع المطور ===== 🟢
  bool _isDevModeUnlocked = false;
  bool get isDevModeUnlocked => _isDevModeUnlocked;

  void toggleDevMode() {
    _isDevModeUnlocked = !_isDevModeUnlocked;
    notifyListeners();
  }
  // 🟢 ============================== 🟢

  int _bailPrice = 1500;
  int get bailPrice => _bailPrice;
  int _playerBailCost = 1500;
  int get playerBailCost => _playerBailCost;

  String? _gameId;
  String? get gameId => _gameId;
  String _lastCrimeName = "تسكع في الشوارع";
  String get lastCrimeName => _lastCrimeName;

  int _cash = 100;
  int _gold = 0;
  int _bankBalance = 0;

  double _crimeEventMultiplier = 1.0;
  double get crimeEventMultiplier => _crimeEventMultiplier;

  int _energy = 100;
  int _courage = 30;
  DateTime? _lastEnergyUpdate;
  DateTime? _lastCourageUpdate;

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
  final Map<String, Map<String, dynamic>> _profilesCache = {};

  static const int _maxProfilesCacheSize = 50;
  static const int _maxImagesCacheSize = 30;

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

  int get energy {
    if (_lastEnergyUpdate == null) return _energy;
    int secondsPassed = DateTime.now().difference(_lastEnergyUpdate!).inSeconds;
    if (secondsPassed < 0) return _energy;
    int interval = isVIP ? 9 : 18;
    return min(maxEnergy, _energy + (secondsPassed ~/ interval));
  }

  int get courage {
    if (_lastCourageUpdate == null) return _courage;
    int secondsPassed = DateTime.now().difference(_lastCourageUpdate!).inSeconds;
    if (secondsPassed < 0) return _courage;
    return min(maxCourage, _courage + (secondsPassed ~/ 36));
  }

  int get secondsToNextEnergy {
    if (energy >= maxEnergy) return 0;
    int interval = isVIP ? 9 : 18;
    if (_lastEnergyUpdate == null) return interval;
    int secondsPassed = DateTime.now().difference(_lastEnergyUpdate!).inSeconds;
    if (secondsPassed < 0) return interval;
    return interval - (secondsPassed % interval);
  }

  int get secondsToNextCourage {
    if (courage >= maxCourage) return 0;
    if (_lastCourageUpdate == null) return 36;
    int secondsPassed = DateTime.now().difference(_lastCourageUpdate!).inSeconds;
    if (secondsPassed < 0) return 36;
    return 36 - (secondsPassed % 36);
  }

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
  set cash(int value) => _cash = value;

  int get gold => _gold;
  set gold(int value) => _gold = value;

  int get bonusPerkPoints => _bonusPerkPoints;
  set bonusPerkPoints(int value) => _bonusPerkPoints = value;

  int get bankBalance => _bankBalance;
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
  int get xpToNextLevel => (250 * pow(1.02, _crimeLevel - 1)).toInt();
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
    _listenToEvents();
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

  void _showNotification(String message) {
    _notificationStream.add(message);
  }

  String _formatWithCommas(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void clearDataOnLogout() {
    _uid = null;
    _isInitialDataLoaded = false;
    _playerDataSubscription?.cancel();
    _gameLoopTimer?.cancel();
    _gameConfigSubscription?.cancel();
    _eventsSubscription?.cancel();

    _profilesCache.clear();

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
    _vipUntil = null;
    _isHospitalized = false; _isInPrison = false; _lockedBalance = 0; _lockedProfits = 0; _lockedUntil = null;
    _loanAmount = 0; _creditScore = 0; _loanTime = null;
    _chopShopEndTime = null; _isChopping = false; _labEndTime = null; _isCrafting = false; _craftingItemId = null;
    _activeSteroidEndTime = null; _activeCoach = null; _coachEndTime = null; _contractEndTime = null; _activeContractName = null;

    // 🟢 تصفير وضع المطور عند تسجيل الخروج
    _isDevModeUnlocked = false;

    _lastEnergyUpdate = null;
    _lastCourageUpdate = null;

    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerDataSubscription?.cancel();
    _gameConfigSubscription?.cancel();
    _eventsSubscription?.cancel();
    _gameLoopTimer?.cancel();
    _notificationStream.close();
    _sessionTimer.stop();
    super.dispose();
  }
}