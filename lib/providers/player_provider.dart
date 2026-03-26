import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String title;
  final int amount;
  final DateTime date;
  final bool isPositive;

  Transaction({required this.title, required this.amount, required this.date, required this.isPositive});

  Map<String, dynamic> toJson() => {'title': title, 'amount': amount, 'date': date.toIso8601String(), 'isPositive': isPositive};
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(title: json['title'], amount: json['amount'], date: DateTime.parse(json['date']), isPositive: json['isPositive']);
}

class PlayerProvider with ChangeNotifier {
  String? _uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _playerDataSubscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int _bailPrice = 1500;
  int get bailPrice => _bailPrice;

  String? _gameId;
  String? get gameId => _gameId;

  int _cash = 5000;
  int _gold = 0;
  int _bankBalance = 0;
  int _energy = 100;
  int _courage = 100;
  int _health = 100;
  int _maxHealth = 100;

  double _fractionalHealth = 0.0;

  String _playerName = "لاعب جديد";
  String _bio = "لا يوجد وصف حالياً... رجل أفعال لا أقوال.";
  String get bio => _bio;

  String? _profilePicUrl;
  String? get profilePicUrl => _profilePicUrl;

  String? _backgroundPicUrl;
  String? get backgroundPicUrl => _backgroundPicUrl;

  double _heat = 0.0;
  int _spareParts = 0;
  Map<String, double> _durability = {};
  String? _equippedCrimeToolId;

  final List<String> _crimeToolsList = ['crowbar', 'slim_jim', 'jammer', 'lockpick', 'glass_cutter', 'laptop', 'thermite', 'stethoscope', 'hydraulic', 'emp_device'];

  // البداية بـ 5 نقاط كما اتفقنا
  double _strength = 5.0;
  double _defense = 5.0;
  double _skill = 5.0;
  double _speed = 5.0;

  List<String> _ownedProperties = [];
  String? _activePropertyId;
  int _happiness = 0;

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
  int _goldPrice = 16000;
  int _oldGoldPrice = 16000;

  Map<String, int> _inventory = {};
  String? _equippedWeaponId;
  String? _equippedArmorId;
  String? _equippedMaskId;
  DateTime? _vipUntil;

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

  List<int> crimeSuccessCounts = [0, 0, 0, 0, 0];
  List<Transaction> _transactions = [];

  final Map<String, Uint8List> _decodedImagesCache = {};

  // ==========================================
  // ⚔️ [قاعدة بيانات الأسلحة والنسب المئوية] ⚔️
  // تم دمج الأسلحة القديمة مع النظام الجديد
  // ==========================================
  final Map<String, Map<String, double>> weaponStats = {
    // --- الأسلحة القديمة (بنسب مئوية معدلة) ---
    'dagger': {'str': 0.15, 'spd': 0.25}, // خفيف (يعادل فضي تكتيكي)
    'revolver': {'str': 0.40, 'spd': 0.40}, // متوازن (يعادل أخضر متوازن)
    'katana': {'str': 0.90, 'spd': 0.60}, // هجومي (يعادل أزرق هجومي)
    'shotgun': {'str': 1.90, 'spd': 0.60}, // مدمر (يعادل بنفسجي مدمر)
    'sniper': {'str': 2.70, 'spd': 0.80}, // مدمر (يعادل ذهبي مدمر)

    // --- الأسلحة الجديدة (30 سلاح) ---
    // 1. فضي (سقف 40%)
    'w_silver_heavy': {'str': 0.30, 'spd': 0.10},
    'w_silver_assault': {'str': 0.25, 'spd': 0.15},
    'w_silver_balanced': {'str': 0.20, 'spd': 0.20},
    'w_silver_tactical': {'str': 0.15, 'spd': 0.25},
    'w_silver_agile': {'str': 0.10, 'spd': 0.30},
    // 2. أخضر (سقف 80%)
    'w_green_heavy': {'str': 0.60, 'spd': 0.20},
    'w_green_assault': {'str': 0.50, 'spd': 0.30},
    'w_green_balanced': {'str': 0.40, 'spd': 0.40},
    'w_green_tactical': {'str': 0.30, 'spd': 0.50},
    'w_green_agile': {'str': 0.20, 'spd': 0.60},
    // 3. أزرق (سقف 150%)
    'w_blue_heavy': {'str': 1.10, 'spd': 0.40},
    'w_blue_assault': {'str': 0.90, 'spd': 0.60},
    'w_blue_balanced': {'str': 0.75, 'spd': 0.75},
    'w_blue_tactical': {'str': 0.60, 'spd': 0.90},
    'w_blue_agile': {'str': 0.40, 'spd': 1.10},
    // 4. بنفسجي (سقف 250%)
    'w_purple_heavy': {'str': 1.90, 'spd': 0.60},
    'w_purple_assault': {'str': 1.50, 'spd': 1.00},
    'w_purple_balanced': {'str': 1.25, 'spd': 1.25},
    'w_purple_tactical': {'str': 1.00, 'spd': 1.50},
    'w_purple_agile': {'str': 0.60, 'spd': 1.90},
    // 5. ذهبي (سقف 350%)
    'w_gold_heavy': {'str': 2.70, 'spd': 0.80},
    'w_gold_assault': {'str': 2.10, 'spd': 1.40},
    'w_gold_balanced': {'str': 1.75, 'spd': 1.75},
    'w_gold_tactical': {'str': 1.40, 'spd': 2.10},
    'w_gold_agile': {'str': 0.80, 'spd': 2.70},
    // 6. أحمر (سقف 450%)
    'w_red_heavy': {'str': 3.60, 'spd': 0.90},
    'w_red_assault': {'str': 2.70, 'spd': 1.80},
    'w_red_balanced': {'str': 2.25, 'spd': 2.25},
    'w_red_tactical': {'str': 1.80, 'spd': 2.70},
    'w_red_agile': {'str': 0.90, 'spd': 3.60},
  };

  // ==========================================
  // 🛡️ [قاعدة بيانات الدروع والنسب المئوية] 🛡️
  // تم دمج الدروع القديمة مع النظام الجديد
  // ==========================================
  final Map<String, Map<String, double>> armorStats = {
    // --- الدروع القديمة (بنسب مئوية معدلة) ---
    'riot_shield': {'def': 0.60, 'skl': 0.20}, // ثقيل (يعادل أخضر ثقيل)
    'kevlar_vest': {'def': 0.75, 'skl': 0.75}, // متوازن (يعادل أزرق متوازن)
    'ninja_suit': {'def': 0.60, 'skl': 1.90}, // رشيق (يعادل بنفسجي رشيق)
    'steel_armor': {'def': 1.90, 'skl': 0.60}, // ثقيل (يعادل بنفسجي ثقيل)
    'exoskeleton': {'def': 1.75, 'skl': 1.75}, // متوازن (يعادل ذهبي متوازن)

    // --- الدروع الجديدة (30 درع) ---
    // 1. فضي (سقف 40%)
    'a_silver_heavy': {'def': 0.30, 'skl': 0.10},
    'a_silver_assault': {'def': 0.25, 'skl': 0.15},
    'a_silver_balanced': {'def': 0.20, 'skl': 0.20},
    'a_silver_tactical': {'def': 0.15, 'skl': 0.25},
    'a_silver_agile': {'def': 0.10, 'skl': 0.30},
    // 2. أخضر (سقف 80%)
    'a_green_heavy': {'def': 0.60, 'skl': 0.20},
    'a_green_assault': {'def': 0.50, 'skl': 0.30},
    'a_green_balanced': {'def': 0.40, 'skl': 0.40},
    'a_green_tactical': {'def': 0.30, 'skl': 0.50},
    'a_green_agile': {'def': 0.20, 'skl': 0.60},
    // 3. أزرق (سقف 150%)
    'a_blue_heavy': {'def': 1.10, 'skl': 0.40},
    'a_blue_assault': {'def': 0.90, 'skl': 0.60},
    'a_blue_balanced': {'def': 0.75, 'skl': 0.75},
    'a_blue_tactical': {'def': 0.60, 'skl': 0.90},
    'a_blue_agile': {'def': 0.40, 'skl': 1.10},
    // 4. بنفسجي (سقف 250%)
    'a_purple_heavy': {'def': 1.90, 'skl': 0.60},
    'a_purple_assault': {'def': 1.50, 'skl': 1.00},
    'a_purple_balanced': {'def': 1.25, 'skl': 1.25},
    'a_purple_tactical': {'def': 1.00, 'skl': 1.50},
    'a_purple_agile': {'def': 0.60, 'skl': 1.90},
    // 5. ذهبي (سقف 350%)
    'a_gold_heavy': {'def': 2.70, 'skl': 0.80},
    'a_gold_assault': {'def': 2.10, 'skl': 1.40},
    'a_gold_balanced': {'def': 1.75, 'skl': 1.75},
    'a_gold_tactical': {'def': 1.40, 'skl': 2.10},
    'a_gold_agile': {'def': 0.80, 'skl': 2.70},
    // 6. أحمر (سقف 450%)
    'a_red_heavy': {'def': 3.60, 'skl': 0.90},
    'a_red_assault': {'def': 2.70, 'skl': 1.80},
    'a_red_balanced': {'def': 2.25, 'skl': 2.25},
    'a_red_tactical': {'def': 1.80, 'skl': 2.70},
    'a_red_agile': {'def': 0.90, 'skl': 3.60},
  };

  // --- دوال القوة الجديدة تعتمد فقط على النسبة المئوية ---
  double get strength {
    double multiplier = 0.0;
    if (_equippedWeaponId != null && weaponStats.containsKey(_equippedWeaponId)) {
      multiplier = weaponStats[_equippedWeaponId]!['str']!;
    }
    return _strength * (1.0 + multiplier);
  }

  double get speed {
    double multiplier = 0.0;
    if (_equippedWeaponId != null && weaponStats.containsKey(_equippedWeaponId)) {
      multiplier = weaponStats[_equippedWeaponId]!['spd']!;
    }
    return _speed * (1.0 + multiplier);
  }

  double get defense {
    double multiplier = 0.0;
    if (_equippedArmorId != null && armorStats.containsKey(_equippedArmorId)) {
      multiplier = armorStats[_equippedArmorId]!['def']!;
    }
    return _defense * (1.0 + multiplier);
  }

  double get skill {
    double multiplier = 0.0;
    if (_equippedArmorId != null && armorStats.containsKey(_equippedArmorId)) {
      multiplier = armorStats[_equippedArmorId]!['skl']!;
    }
    return _skill * (1.0 + multiplier);
  }


  Uint8List? getDecodedImage(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    if (_decodedImagesCache.containsKey(base64Str)) return _decodedImagesCache[base64Str]!;
    try {
      final bytes = base64Decode(base64Str);
      _decodedImagesCache[base64Str] = bytes;
      return bytes;
    } catch (e) {
      return null;
    }
  }

  final Map<String, Map<String, dynamic>> _playersCache = {};
  final Map<String, DateTime> _playersCacheTime = {};

  Future<Map<String, dynamic>?> getPlayerById(String uid) async {
    if (_playersCache.containsKey(uid) && _playersCacheTime.containsKey(uid)) {
      if (DateTime.now().difference(_playersCacheTime[uid]!).inMinutes < 5) {
        return _playersCache[uid];
      }
    }

    try {
      DocumentSnapshot cacheDoc = await _firestore.collection('players').doc(uid).get(const GetOptions(source: Source.cache));
      if (cacheDoc.exists) {
        Map<String, dynamic> data = cacheDoc.data() as Map<String, dynamic>;
        data['uid'] = cacheDoc.id;
        _playersCache[uid] = data;
        _playersCacheTime[uid] = DateTime.now();

        _firestore.collection('players').doc(uid).get(const GetOptions(source: Source.server)).then((serverDoc) {
          if (serverDoc.exists) {
            Map<String, dynamic> serverData = serverDoc.data() as Map<String, dynamic>;
            serverData['uid'] = serverDoc.id;
            _playersCache[uid] = serverData;
            _playersCacheTime[uid] = DateTime.now();
          }
        });
        return data;
      }
    } catch (e) {
      debugPrint("اللاعب ليس في الكاش، سيتم جلبه من السيرفر...");
    }

    try {
      DocumentSnapshot serverDoc = await _firestore.collection('players').doc(uid).get(const GetOptions(source: Source.server));
      if (serverDoc.exists) {
        Map<String, dynamic> data = serverDoc.data() as Map<String, dynamic>;
        data['uid'] = serverDoc.id;
        _playersCache[uid] = data;
        _playersCacheTime[uid] = DateTime.now();
        return data;
      }
    } catch (e) {
      debugPrint("خطأ في السيرفر: $e");
    }

    return null;
  }

  Future<String> _generateUniqueGameId() async {
    String newId = '';
    bool isUnique = false;
    while (!isUnique) {
      newId = (100000 + Random().nextInt(900000)).toString();
      final check = await _firestore.collection('players').where('gameId', isEqualTo: newId).limit(1).get();
      if (check.docs.isEmpty) {
        isUnique = true;
      }
    }
    return newId;
  }

  String? get uid => _uid;
  int get cash => _cash;
  int get gold => _gold;
  int get bankBalance => _bankBalance;
  int get energy => _energy;
  int get courage => _courage;
  int get health => _health;
  int get maxHealth => _maxHealth;
  int get happiness => _happiness;
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
  int get goldPrice => _goldPrice;
  int get oldGoldPrice => _oldGoldPrice;
  int get maxLoanLimit => 20000 + (_creditScore * 2000);
  bool get isInvestmentLocked => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  int get crimeLevel => _crimeLevel;
  int get crimeXP => _crimeXP;

  int get xpToNextLevel {
    return (100 * pow(1.05, _crimeLevel - 1)).toInt();
  }

  int get workLevel => _workLevel;
  int get workXP => _workXP;
  int get workXPToNextLevel => max(150, _workLevel * 150);
  int get arenaLevel => _arenaLevel;
  bool get isUnderContract => _contractEndTime != null && DateTime.now().isBefore(_contractEndTime!);
  DateTime? get contractEndTime => _contractEndTime;
  String? get activeContractName => _activeContractName;
  bool get isInGang => _gangName != null;
  String? get gangName => _gangName;
  String get gangRank => _gangRank;
  int get gangContribution => _gangContribution;
  int get gangWarWins => _gangWarWins;
  Map<String, String> get territoryOwners => _territoryOwners;
  DateTime? get vipUntil => _vipUntil;
  bool get isVIP => _vipUntil != null && DateTime.now().isBefore(_vipUntil!);
  int get maxCourage => isVIP ? 200 : 100;
  int get maxEnergy => isVIP ? 200 : 100;

  List<Transaction> get transactions => _transactions;
  final StreamController<String> _notificationStream = StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationStream.stream;

  Timer? _gameLoopTimer;
  Timer? _goldMarketTimer;

  PlayerProvider() {
    _startGameLoop();
    _startGoldMarketTimer();
    _listenToGameConfig();
  }

  void _listenToGameConfig() {
    _firestore.collection('config').doc('game_settings').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('bailPrice')) { _bailPrice = data['bailPrice']; notifyListeners(); }
      }
    });
  }

  Future<void> initializePlayerOnServer(String uid, String name) async {
    _uid = uid;
    _isLoading = true;
    notifyListeners();

    _playerDataSubscription?.cancel();
    final initialDoc = await _firestore.collection('players').doc(uid).get();

    if (initialDoc.exists) {
      _applyFirestoreData(initialDoc.data()!);
      if (_gameId == null) {
        _gameId = await _generateUniqueGameId();
        await _syncWithFirestore();
      }
    } else if (name.isNotEmpty) {
      _playerName = name;
      _inventory['name_change_card'] = 1;
      _gameId = await _generateUniqueGameId();
      _isLoading = false;
      await _syncWithFirestore();
    }

    _isLoading = false;
    notifyListeners();

    _playerDataSubscription = _firestore.collection('players').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.metadata.hasPendingWrites == false) {
        _applyFirestoreData(snapshot.data()!);
        notifyListeners();
      }
    });
  }

  void _applyFirestoreData(Map<String, dynamic> data) {
    _playerName = data['playerName'] ?? _playerName;
    _gameId = data['gameId'] ?? _gameId;
    _bio = data['bio'] ?? _bio;
    _profilePicUrl = data['profilePicUrl'];
    _backgroundPicUrl = data['backgroundPicUrl'];
    _cash = data['cash'] ?? _cash;
    _gold = data['gold'] ?? _gold;
    _bankBalance = data['bankBalance'] ?? _bankBalance;
    _energy = data['energy'] ?? _energy;
    _courage = data['courage'] ?? _courage;
    _health = data['health'] ?? _health;
    _maxHealth = data['maxHealth'] ?? _maxHealth;
    _happiness = data['happiness'] ?? _happiness;
    _strength = (data['strength'] ?? 5.0).toDouble();
    _defense = (data['defense'] ?? 5.0).toDouble();
    _skill = (data['skill'] ?? 5.0).toDouble();
    _speed = (data['speed'] ?? 5.0).toDouble();
    _ownedProperties = List<String>.from(data['ownedProperties'] ?? []);
    _activePropertyId = data['activePropertyId'];
    _inventory = Map<String, int>.from(data['inventory'] ?? {});
    _crimeLevel = data['crimeLevel'] ?? 1;
    _crimeXP = data['crimeXP'] ?? 0;
    _workLevel = data['workLevel'] ?? 1;
    _workXP = data['workXP'] ?? 0;
    _arenaLevel = data['arenaLevel'] ?? 1;
    _isInPrison = data['isInPrison'] ?? false;
    if (data['prisonReleaseTime'] != null) _prisonReleaseTime = DateTime.parse(data['prisonReleaseTime']);
    _isHospitalized = data['isHospitalized'] ?? false;
    if (data['hospitalReleaseTime'] != null) _hospitalReleaseTime = DateTime.parse(data['hospitalReleaseTime']);
    _lockedBalance = data['lockedBalance'] ?? 0;
    _lockedProfits = data['lockedProfits'] ?? 0;
    if (data['lockedUntil'] != null) _lockedUntil = DateTime.parse(data['lockedUntil']);
    if (data['vipUntil'] != null) _vipUntil = DateTime.parse(data['vipUntil']);
    _loanAmount = data['loanAmount'] ?? 0;
    _creditScore = data['creditScore'] ?? 0;
    if (data['loanTime'] != null) _loanTime = DateTime.parse(data['loanTime']);
    _gangName = data['gangName'];
    _gangRank = data['gangRank'] ?? "عضو";
    _gangContribution = data['gangContribution'] ?? 0;
    _gangWarWins = data['gangWarWins'] ?? 0;
    if (data['territoryOwners'] != null) _territoryOwners = Map<String, String>.from(data['territoryOwners']);
    if (data['crimeSuccessCounts'] != null) crimeSuccessCounts = List<int>.from(data['crimeSuccessCounts']);
    if (data['contractEndTime'] != null) _contractEndTime = DateTime.parse(data['contractEndTime']);
    _activeContractName = data['activeContractName'];
    _contractSalary = data['contractSalary'] ?? 0;
    _ownedCars = List<String>.from(data['ownedCars'] ?? []);
    _activeCarId = data['activeCarId'];
    if (data['chopShopEndTime'] != null) _chopShopEndTime = DateTime.parse(data['chopShopEndTime']);
    _isChopping = data['isChopping'] ?? false;
    if (data['labEndTime'] != null) _labEndTime = DateTime.parse(data['labEndTime']);
    _isCrafting = data['isCrafting'] ?? false;
    _craftingItemId = data['craftingItemId'];
    _heat = (data['heat'] ?? 0.0).toDouble();
    _spareParts = data['spareParts'] ?? 0;
    _equippedWeaponId = data['equippedWeaponId'];
    _equippedArmorId = data['equippedArmorId'];
    _equippedMaskId = data['equippedMaskId'];
    _equippedCrimeToolId = data['equippedCrimeToolId'];
    if (data['durability'] != null) _durability = Map<String, double>.from(data['durability'].map((k, v) => MapEntry(k, v.toDouble())));
    if (data['transactions'] != null) _transactions = (data['transactions'] as List).map((t) => Transaction.fromJson(Map<String, dynamic>.from(t))).toList();
  }

  Future<void> _syncWithFirestore() async {
    if (_uid == null || _isLoading) return;
    try {
      await _firestore.collection('players').doc(_uid).set({
        'playerName': _playerName,
        'gameId': _gameId,
        'bio': _bio,
        'profilePicUrl': _profilePicUrl,
        'backgroundPicUrl': _backgroundPicUrl,
        'cash': _cash,
        'gold': _gold,
        'bankBalance': _bankBalance,
        'energy': _energy,
        'courage': _courage,
        'health': _health,
        'maxHealth': _maxHealth,
        'happiness': _happiness,
        'strength': _strength,
        'defense': _defense,
        'skill': _skill,
        'speed': _speed,
        'ownedProperties': _ownedProperties,
        'activePropertyId': _activePropertyId,
        'inventory': _inventory,
        'crimeLevel': _crimeLevel,
        'crimeXP': _crimeXP,
        'workLevel': _workLevel,
        'workXP': _workXP,
        'arenaLevel': _arenaLevel,
        'isInPrison': _isInPrison,
        'prisonReleaseTime': _prisonReleaseTime?.toIso8601String(),
        'isHospitalized': _isHospitalized,
        'hospitalReleaseTime': _hospitalReleaseTime?.toIso8601String(),
        'lockedBalance': _lockedBalance,
        'lockedProfits': _lockedProfits,
        'lockedUntil': _lockedUntil?.toIso8601String(),
        'vipUntil': _vipUntil?.toIso8601String(),
        'loanAmount': _loanAmount,
        'creditScore': _creditScore,
        'loanTime': _loanTime?.toIso8601String(),
        'gangName': _gangName,
        'gangRank': _gangRank,
        'gangContribution': _gangContribution,
        'gangWarWins': _gangWarWins,
        'territoryOwners': _territoryOwners,
        'crimeSuccessCounts': crimeSuccessCounts,
        'contractEndTime': _contractEndTime?.toIso8601String(),
        'activeContractName': _activeContractName,
        'contractSalary': _contractSalary,
        'lastUpdate': FieldValue.serverTimestamp(),
        'ownedCars': _ownedCars,
        'activeCarId': _activeCarId,
        'chopShopEndTime': _chopShopEndTime?.toIso8601String(),
        'isChopping': _isChopping,
        'labEndTime': _labEndTime?.toIso8601String(),
        'isCrafting': _isCrafting,
        'craftingItemId': _craftingItemId,
        'heat': _heat,
        'spareParts': _spareParts,
        'durability': _durability,
        'equippedWeaponId': _equippedWeaponId,
        'equippedArmorId': _equippedArmorId,
        'equippedMaskId': _equippedMaskId,
        'equippedCrimeToolId': _equippedCrimeToolId,
        'transactions': _transactions.map((t) => t.toJson()).toList(),
      }, SetOptions(merge: true));
    } catch (e) { debugPrint("Sync failed: $e"); }
  }

  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    int syncCounter = 0;
    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLoading) return;
      bool localChanged = false;
      syncCounter++;

      if (_heat > 0) { _heat = max(0, _heat - 0.0278); localChanged = true; }
      if (timer.tick % 4 == 0 && _courage < maxCourage) { _courage++; localChanged = true; }
      if (timer.tick % 8 == 0 && _energy < maxEnergy) { _energy++; localChanged = true; }

      if (_health < maxHealth) {
        double regenPerSecond = maxHealth / 1800.0;
        _fractionalHealth += regenPerSecond;
        if (_fractionalHealth >= 1.0) {
          int healAmount = _fractionalHealth.toInt();
          _health = min(maxHealth, _health + healAmount);
          _fractionalHealth -= healAmount;
          localChanged = true;

          if (_health >= maxHealth && _isHospitalized) {
            _isHospitalized = false;
            _hospitalReleaseTime = null;
            _showNotification("تعافيت بالكامل وخرجت من المستشفى!");
          }
        }
      } else {
        _fractionalHealth = 0.0;
      }

      if (timer.tick % 60 == 0) { for (var tool in _crimeToolsList) { if ((_durability[tool] ?? 100) < 100) { _durability[tool] = min(100.0, (_durability[tool] ?? 100) + 1.0); localChanged = true; } } }
      if (_loanAmount > 0 && _loanTime != null) { if (DateTime.now().difference(_loanTime!).inHours >= 2) { _loanAmount = (_loanAmount * 1.1).floor(); _loanTime = DateTime.now(); _showNotification("البنك 🏦: تمت إضافة فوائد 10% على قرضك لتأخرك في السداد!"); localChanged = true; } }
      if (_isInPrison && _prisonReleaseTime != null) { if (DateTime.now().isAfter(_prisonReleaseTime!)) { _isInPrison = false; _prisonReleaseTime = null; _showNotification("تم الإفراج عنك من السجن!"); localChanged = true; } }
      if (_isHospitalized && _hospitalReleaseTime != null) { if (DateTime.now().isAfter(_hospitalReleaseTime!)) { _isHospitalized = false; _hospitalReleaseTime = null; _health = (maxHealth * 0.25).toInt(); _showNotification("تم خروجك من المستشفى!"); localChanged = true; } }
      if (_lockedUntil != null && DateTime.now().isAfter(_lockedUntil!)) { int total = _lockedBalance + _lockedProfits; _bankBalance += total; _lockedBalance = 0; _lockedProfits = 0; _lockedUntil = null; _showNotification("انتهى الاستثمار! استلمت $total كاش"); localChanged = true; }
      if (isUnderContract && _lastContractRewardTime != null && DateTime.now().difference(_lastContractRewardTime!).inMinutes >= 1) { _cash += _contractSalary; _lastContractRewardTime = DateTime.now(); _addTransaction("راتب عقد: $_activeContractName", _contractSalary, true); _workXP += 5; if (_workXP >= workXPToNextLevel) { _workXP -= workXPToNextLevel; _workLevel++; } localChanged = true; }

      if (localChanged) notifyListeners();
      if (syncCounter >= 60) { _syncWithFirestore(); syncCounter = 0; }
    });
  }

  void updateBio(String newBio) { if (newBio.length <= 150) { _bio = newBio; _syncWithFirestore(); notifyListeners(); } }

  void updateProfilePic(String base64Image) {
    _profilePicUrl = base64Image;
    notifyListeners();
    _syncWithFirestore();

    _firestore.collection('chat').where('uid', isEqualTo: _uid).get().then((snapshot) {
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'profilePicUrl': base64Image});
      }
      batch.commit();
    }).catchError((e) => debugPrint("خطأ في تحديث صور الشات: $e"));
  }

  void updateBackgroundPic(String base64Image) {
    _backgroundPicUrl = base64Image;
    _syncWithFirestore();
    notifyListeners();
  }

  void increaseHeat(double amount) { _heat = min(100, _heat + amount); notifyListeners(); }
  void reduceHeat(double amount) { _heat = max(0, _heat - amount); notifyListeners(); }
  void reduceDurability(String? itemId, double amount) { if (itemId == null || !_crimeToolsList.contains(itemId)) return; _durability[itemId] = max(0, (_durability[itemId] ?? 100.0) - amount); if ((_durability[itemId] ?? 100) < 10) _showNotification("⚠️ عتاد الجريمة يحتاج إصلاح في الورشة!"); notifyListeners(); }
  void repairItem(String itemId, int requiredParts) { if (_crimeToolsList.contains(itemId) && _spareParts >= requiredParts && (_durability[itemId] ?? 100) < 100) { _spareParts -= requiredParts; _durability[itemId] = 100.0; _showNotification("🛠️ تم إصلاح الأداة بنجاح!"); _syncWithFirestore(); notifyListeners(); } }
  void collectChoppedCar() { if (_isChopping && _chopShopEndTime != null && DateTime.now().isAfter(_chopShopEndTime!)) { _isChopping = false; _chopShopEndTime = null; addCash(15000, reason: "بيع قطع غيار من التشليح 🚗"); _spareParts += 15; _showNotification("حصلت على 15 قطعة غيار للإصلاح!"); _syncWithFirestore(); notifyListeners(); } }

  void addCash(int amount, {String reason = "مكافأة"}) { _cash += amount; _addTransaction(reason, amount, true); _syncWithFirestore(); notifyListeners(); }
  void removeCash(int amount, {String reason = "خصم"}) { _cash = max(0, _cash - amount); _addTransaction(reason, amount, false); _syncWithFirestore(); notifyListeners(); }
  void addGold(int amount) { _gold += amount; _syncWithFirestore(); notifyListeners(); }
  void removeGold(int amount) { _gold = max(0, _gold - amount); _syncWithFirestore(); notifyListeners(); }

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

  void addWorkXP(int amount) { _workXP += amount; if (_workXP >= workXPToNextLevel) { _workXP -= workXPToNextLevel; _workLevel++; _showNotification("تمت ترقيتك للمستوى $_workLevel"); } _syncWithFirestore(); notifyListeners(); }
  void incrementCrimeSuccess(int index, String crimeName) { if (index < crimeSuccessCounts.length) { crimeSuccessCounts[index]++; _syncWithFirestore(); notifyListeners(); } }

  void handleCrimeFailure(int minutes) { double escapeChance = 0.0; if (_equippedMaskId == 'black_mask') escapeChance = 0.35; else if (_equippedMaskId == 'silicon_mask') escapeChance = 0.55; if (Random().nextDouble() < escapeChance) { _showNotification("🎭 هربت بفضل القناع!"); } else { _showNotification("⚠️ تم القبض عليك!"); startPrisonTimer(minutes); } }

  void depositToBank(int amount) { if (_cash >= amount) { _cash -= amount; _bankBalance += (amount * 0.9).floor(); _syncWithFirestore(); notifyListeners(); } }
  void withdrawFromBank(int amount) { if (_bankBalance >= amount) { _bankBalance -= amount; _cash += amount; _syncWithFirestore(); notifyListeners(); } }
  void buyGold(int amount) { int cost = amount * _goldPrice; if (_cash >= cost) { _cash -= cost; _gold += amount; _syncWithFirestore(); notifyListeners(); } }
  void sellGold(int amount) { if (_gold >= amount) { _cash += amount * _goldPrice; _gold -= amount; _syncWithFirestore(); notifyListeners(); } }

  void takeLoan(int amount) { if (_loanAmount + amount <= maxLoanLimit) { if (_loanAmount == 0) _loanTime = DateTime.now(); _loanAmount += amount; _cash += (amount * 0.95).floor(); _syncWithFirestore(); notifyListeners(); } }
  bool canRepayLoan() { if (_loanTime == null) return true; return DateTime.now().difference(_loanTime!).inMinutes >= 5; }
  void repayLoan(int amount) { if (canRepayLoan() && amount <= _cash && amount <= _loanAmount) { _cash -= amount; _loanAmount -= amount; if (_loanAmount == 0) { _loanTime = null; _creditScore += 10; _showNotification("البنك 🏦: سددت قرضك بالكامل! زادت سمعتك."); } _syncWithFirestore(); notifyListeners(); } }
  void startLockedInvestment(int amount, int minutes, double rate) { if (_cash >= amount) { _cash -= amount; _lockedBalance = amount; _lockedProfits = (amount * rate).floor(); _lockedUntil = DateTime.now().add(Duration(minutes: minutes)); _syncWithFirestore(); notifyListeners(); } }
  void startWorkContract(String name, int durationMinutes, int salaryPerMinute) { if (isUnderContract) return; _activeContractName = name; _contractSalary = salaryPerMinute; _lastContractRewardTime = DateTime.now(); _contractEndTime = DateTime.now().add(Duration(minutes: durationMinutes)); _syncWithFirestore(); notifyListeners(); }
  void trainStat(String statType, int energyCost) { if (_energy >= energyCost) { _energy -= energyCost; double baseGain = 0.5 + (Random().nextDouble() * 0.5); if (statType == 'strength') _strength += baseGain; else if (statType == 'defense') { _defense += baseGain; } else if (statType == 'skill') _skill += baseGain; else if (statType == 'speed') _speed += baseGain; _syncWithFirestore(); notifyListeners(); } }
  void incrementArenaLevel() { _arenaLevel++; _syncWithFirestore(); notifyListeners(); }
  void buyProperty(String id, int price, int happinessGain) { if (_cash >= price && !_ownedProperties.contains(id)) { _cash -= price; _ownedProperties.add(id); if (_activePropertyId == null) setActiveProperty(id, happinessGain); _syncWithFirestore(); notifyListeners(); } }
  void setActiveProperty(String id, int happinessGain) { if (_ownedProperties.contains(id)) { _activePropertyId = id; _happiness = happinessGain; _syncWithFirestore(); notifyListeners(); } }
  void createGang(String name) { if (!isInGang && _cash >= 1000000) { _cash -= 1000000; _gangName = name; _gangRank = "زعيم"; _syncWithFirestore(); notifyListeners(); } }
  void contributeToGang(int amount) { if (isInGang && _cash >= amount) { _cash -= amount; _gangContribution += amount; _syncWithFirestore(); notifyListeners(); } }
  void winGangWar(String territory) { if (isInGang) { _gangWarWins++; _territoryOwners[territory] = _gangName!; _syncWithFirestore(); notifyListeners(); } }
  void leaveGang() { _gangName = null; _gangRank = "عضو"; _gangContribution = 0; _syncWithFirestore(); notifyListeners(); }
  void setHealth(int value) { _health = value.clamp(0, maxHealth); if (_health == 0 && !_isHospitalized) { enterHospital(1); } else if (_health > 0 && _isHospitalized) { _isHospitalized = false; _hospitalReleaseTime = null; } _syncWithFirestore(); notifyListeners(); }
  void setEnergy(int value) { _energy = value.clamp(0, maxEnergy); _syncWithFirestore(); notifyListeners(); }
  void setCourage(int value) { _courage = value.clamp(0, maxCourage); _syncWithFirestore(); notifyListeners(); }
  void enterHospital(int minutes) { _isHospitalized = true; _health = 0; _hospitalReleaseTime = DateTime.now().add(Duration(minutes: minutes)); _syncWithFirestore(); notifyListeners(); }

  void quickHealHospital() {
    int missing = maxHealth - _health;
    if (missing <= 0) return;
    int cost = isVIP ? max(1, (missing * 0.8).toInt()) : missing;

    if (_cash >= cost) {
      _cash -= cost;
      _health = maxHealth;
      _isHospitalized = false;
      _hospitalReleaseTime = null;
      _addTransaction("فاتورة المستشفى", cost, false);
      _syncWithFirestore();
      notifyListeners();
      _showNotification("🏥 تم العلاج بالكامل مقابل $cost كاش!");
    } else {
      _showNotification("⚠️ كاش غير كافي! تحتاج $cost");
    }
  }

  void updateName(String newName) { if (_inventory.containsKey('name_change_card') && _inventory['name_change_card']! > 0) { _playerName = newName; _inventory['name_change_card'] = _inventory['name_change_card']! - 1; if (_inventory['name_change_card'] == 0) _inventory.remove('name_change_card'); _syncWithFirestore(); notifyListeners(); } }
  void startPrisonTimer(int minutes) { _isInPrison = true; _prisonReleaseTime = DateTime.now().add(Duration(minutes: minutes)); _syncWithFirestore(); notifyListeners(); }

  void buyItem(String itemId, int price, {bool isConsumable = false, String currency = 'cash'}) { bool canBuy = currency == 'cash' ? _cash >= price : _gold >= price; if (canBuy) { if (currency == 'cash') _cash -= price; else _gold -= price; _inventory[itemId] = (_inventory[itemId] ?? 0) + 1; _syncWithFirestore(); notifyListeners(); } }

  void useItem(String itemId) {
    if ((_inventory[itemId] ?? 0) > 0) {
      if (_crimeToolsList.contains(itemId)) {
        _equippedCrimeToolId = (_equippedCrimeToolId == itemId) ? null : itemId;
      } else if (weaponStats.containsKey(itemId)) {
        _equippedWeaponId = (_equippedWeaponId == itemId) ? null : itemId;
      } else if (armorStats.containsKey(itemId)) {
        _equippedArmorId = (_equippedArmorId == itemId) ? null : itemId;
      } else if (['black_mask', 'silicon_mask'].contains(itemId)) {
        _equippedMaskId = (_equippedMaskId == itemId) ? null : itemId;
      } else {
        if (itemId == 'medkit') _health = maxHealth;
        else if (itemId == 'steroids') _energy = maxEnergy;
        else if (itemId == 'coffee') _courage = maxCourage;
        else if (itemId == 'bribe_small') reduceHeat(20.0);
        else if (itemId == 'fake_plates') reduceHeat(40.0);
        else if (itemId == 'bribe_big') _heat = 0.0;

        if (['medkit', 'bandage', 'painkillers'].contains(itemId) && _isHospitalized) {
          _isHospitalized = false;
          _hospitalReleaseTime = null;
          _showNotification("🏥 تم استخدام العلاج وخرجت من المستشفى فوراً!");
        }
        if (['medkit', 'bandage', 'painkillers', 'steroids', 'coffee', 'energy_bar', 'fast_food', 'tea', 'juice', 'happiness_booster', 'smoke_bomb', 'bribe_small', 'bribe_big', 'fake_plates'].contains(itemId)) {
          _inventory[itemId] = _inventory[itemId]! - 1;
          if (_inventory[itemId] == 0) _inventory.remove(itemId);
        }
      }
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void addItemDirectly(String itemId, {int quantity = 1}) { _inventory[itemId] = (_inventory[itemId] ?? 0) + quantity; _syncWithFirestore(); notifyListeners(); }
  void buyVIP(int days, int cost) { if (_gold >= cost) { _gold -= cost; DateTime start = isVIP ? _vipUntil! : DateTime.now(); _vipUntil = start.add(Duration(days: days)); _syncWithFirestore(); notifyListeners(); } }
  void _showNotification(String message) => _notificationStream.add(message);
  void _addTransaction(String title, int amount, bool isPositive) { _transactions.insert(0, Transaction(title: title, amount: amount, date: DateTime.now(), isPositive: isPositive)); if (_transactions.length > 20) _transactions.removeLast(); }
  void _startGoldMarketTimer() { _goldMarketTimer = Timer.periodic(const Duration(hours: 2), (timer) { _oldGoldPrice = _goldPrice; _goldPrice = 15000 + Random().nextInt(2001); notifyListeners(); }); }
  void payBail() { if (_cash >= _bailPrice) { _cash -= _bailPrice; _isInPrison = false; _prisonReleaseTime = null; _syncWithFirestore(); notifyListeners(); } }

  Future<void> resetPlayerData() async { _cash = 5000; _gold = 0; _bankBalance = 0; _energy = 100; _courage = 100; _strength = 5; _defense = 5; _skill = 5; _speed = 5; _ownedProperties = []; _activePropertyId = null; _happiness = 0; _inventory = {'name_change_card': 1}; _equippedWeaponId = null; _equippedArmorId = null; _equippedMaskId = null; _vipUntil = null; _isHospitalized = false; _hospitalReleaseTime = null; _crimeLevel = 1; _workLevel = 1; _crimeXP = 0; _workXP = 0; _isInPrison = false; _prisonReleaseTime = null; _lockedBalance = 0; _lockedProfits = 0; _lockedUntil = null; _arenaLevel = 1; _loanAmount = 0; _creditScore = 0; _loanTime = null; _gangName = null; _gangRank = "عضو"; _gangContribution = 0; _gangWarWins = 0; _territoryOwners = {}; crimeSuccessCounts = [0, 0, 0, 0, 0]; _transactions = []; _chopShopEndTime = null; _isChopping = false; _labEndTime = null; _isCrafting = false; _craftingItemId = null; _heat = 0.0; _spareParts = 0; _durability = {}; _equippedCrimeToolId = null; _bio = "لا يوجد وصف حالياً... رجل أفعال لا أقوال."; _profilePicUrl = null; _backgroundPicUrl = null; await _syncWithFirestore(); notifyListeners(); }

  Future<List<Map<String, dynamic>>> fetchRealOpponents() async { try { int minLevel = max(1, _arenaLevel - 2); int maxLevel = _arenaLevel + 2; QuerySnapshot snapshot = await _firestore.collection('players').where('arenaLevel', isGreaterThanOrEqualTo: minLevel).where('arenaLevel', isLessThanOrEqualTo: maxLevel).limit(10).get(); List<Map<String, dynamic>> opponents = []; for (var doc in snapshot.docs) { if (doc.id != _uid) { Map<String, dynamic> data = doc.data() as Map<String, dynamic>; data['uid'] = doc.id; opponents.add(data); } } return opponents; } catch (e) { return []; } }
  Future<List<Map<String, dynamic>>> fetchLeaderboard() async { try { QuerySnapshot snapshot = await _firestore.collection('players').orderBy('arenaLevel', descending: true).limit(10).get(); List<Map<String, dynamic>> topPlayers = []; for (var doc in snapshot.docs) { Map<String, dynamic> data = doc.data() as Map<String, dynamic>; data['uid'] = doc.id; topPlayers.add(data); } return topPlayers; } catch (e) { return []; } }
  Future<void> recordPvpVictory(String enemyUid, String enemyName, int reward) async { addCash(reward, reason: "غنيمة من $enemyName"); try { await _firestore.collection('players').doc(enemyUid).update({ 'cash': FieldValue.increment(-reward) }); await _firestore.collection('players').doc(enemyUid).collection('attacks_log').add({ 'attackerId': _uid, 'attackerName': _playerName, 'stolenAmount': reward, 'date': FieldValue.serverTimestamp(), 'hasAvenged': false }); } catch (e) {} }
  Future<List<Map<String, dynamic>>> fetchAttacksLog() async { if (_uid == null) return []; try { QuerySnapshot snapshot = await _firestore.collection('players').doc(_uid).collection('attacks_log').orderBy('date', descending: true).limit(20).get(); List<Map<String, dynamic>> logs = []; for (var doc in snapshot.docs) { Map<String, dynamic> data = doc.data() as Map<String, dynamic>; data['logId'] = doc.id; logs.add(data); } return logs; } catch (e) { return []; } }
  Future<void> markAsAvenged(String logId) async { if (_uid == null) return; try { await _firestore.collection('players').doc(_uid).collection('attacks_log').doc(logId).update({'hasAvenged': true}); } catch (e) {} }
  void buyCar(String carId, int price) { if (_cash >= price && !_ownedCars.contains(carId)) { _cash -= price; _ownedCars.add(carId); _activeCarId ??= carId; _syncWithFirestore(); notifyListeners(); } }
  void setActiveCar(String carId) { if (_ownedCars.contains(carId)) { _activeCarId = carId; _syncWithFirestore(); notifyListeners(); } }
  void finishRace(bool won, int reward, int energyCost) { setEnergy(_energy - energyCost); if (won) addCash(reward, reason: "فوز بسباق 🏎️"); }
  void startChopping() { if ((_inventory['stolen_car'] ?? 0) > 0 && !_isChopping) { _inventory['stolen_car'] = _inventory['stolen_car']! - 1; _isChopping = true; _chopShopEndTime = DateTime.now().add(const Duration(minutes: 30)); _syncWithFirestore(); notifyListeners(); } }
  void startCrafting(String itemId, int costCash, int durationMinutes) { if (!_isCrafting && _cash >= costCash) { _cash -= costCash; _isCrafting = true; _craftingItemId = itemId; _labEndTime = DateTime.now().add(Duration(minutes: durationMinutes)); _syncWithFirestore(); notifyListeners(); } }
  void collectCraftedItem() { if (_isCrafting && _labEndTime != null && DateTime.now().isAfter(_labEndTime!)) { _isCrafting = false; _labEndTime = null; if (_craftingItemId != null) { _inventory[_craftingItemId!] = (_inventory[_craftingItemId!] ?? 0) + 1; _craftingItemId = null; } _syncWithFirestore(); notifyListeners(); } }
  void addInventoryItem(String itemId, int amount) { _inventory[itemId] = (_inventory[itemId] ?? 0) + amount; _syncWithFirestore(); notifyListeners(); }

  @override
  void dispose() { _playerDataSubscription?.cancel(); _gameLoopTimer?.cancel(); _goldMarketTimer?.cancel(); _notificationStream.close(); super.dispose(); }
}