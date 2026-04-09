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

  int _bailPrice = 1500;
  int get bailPrice => _bailPrice;
  int _playerBailCost = 1500;

  String? _gameId;
  String? get gameId => _gameId;
  String _lastCrimeName = "تسكع في الشوارع";

  int _cash = 100;
  int _gold = 0;
  int _bankBalance = 0;
  int _energy = 100;
  int _courage = 100;
  int _health = 100;
  int _baseMaxHealth = 100;
  int _prestige = 100;

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

  int get pvpWins => _pvpWins;
  int get totalStolenCash => _totalStolenCash;
  Map<String, int> get perks => _perks;
  int get totalVipDays => _totalVipDays;
  int get totalLabCrafts => _totalLabCrafts;
  int get luckyWheelSpins => _luckyWheelSpins;

  int get earnedPerkPoints { return getAllTitles().where((t) => t['unlocked'] == true).length - 1; }

  int get unspentSkillPoints {
    int spent = _perks.values.fold(0, (sum, val) => sum + val);
    return max(0, earnedPerkPoints - spent);
  }

  double get strength {
    double str = _baseStrength;
    if (_perks.containsKey('base_str')) str += str * (_perks['base_str']! * 0.01);
    double weaponBonus = (_equippedWeaponId != null && GameData.weaponStats.containsKey(_equippedWeaponId)) ? str * GameData.weaponStats[_equippedWeaponId]!['str']! : 0.0;
    if (_perks.containsKey('weapon_master')) weaponBonus += weaponBonus * (_perks['weapon_master']! * 0.05);
    return str + weaponBonus;
  }

  double get speed {
    double spd = _baseSpeed;
    if (_perks.containsKey('base_spd')) spd += spd * (_perks['base_spd']! * 0.01);
    double weaponBonus = (_equippedWeaponId != null && GameData.weaponStats.containsKey(_equippedWeaponId)) ? spd * GameData.weaponStats[_equippedWeaponId]!['spd']! : 0.0;
    if (_perks.containsKey('weapon_master')) weaponBonus += weaponBonus * (_perks['weapon_master']! * 0.05);
    return spd + weaponBonus;
  }

  double get defense {
    double def = _baseDefense;
    if (_perks.containsKey('base_def')) def += def * (_perks['base_def']! * 0.01);
    double armorBonus = (_equippedArmorId != null && GameData.armorStats.containsKey(_equippedArmorId)) ? def * GameData.armorStats[_equippedArmorId]!['def']! : 0.0;
    if (_perks.containsKey('armor_master')) armorBonus += armorBonus * (_perks['armor_master']! * 0.05);
    return def + armorBonus;
  }

  double get skill {
    double skl = _baseSkill;
    if (_perks.containsKey('base_skl')) skl += skl * (_perks['base_skl']! * 0.01);
    double armorBonus = (_equippedArmorId != null && GameData.armorStats.containsKey(_equippedArmorId)) ? skl * GameData.armorStats[_equippedArmorId]!['skl']! : 0.0;
    if (_perks.containsKey('armor_master')) armorBonus += armorBonus * (_perks['armor_master']! * 0.05);
    return skl + armorBonus;
  }

  int get maxHealth {
    double hp = _baseMaxHealth.toDouble();
    if (_perks.containsKey('max_hp_boost')) hp += hp * (_perks['max_hp_boost']! * 0.02);
    return hp.toInt();
  }

  int get maxEnergy {
    int nrg = isVIP ? 200 : 100;
    if (_perks.containsKey('max_energy_boost')) nrg += (_perks['max_energy_boost']! * 2);
    return nrg;
  }

  int get maxCourage {
    int crg = (isVIP ? 200 : 100) + _crimeLevel;
    if (_perks.containsKey('max_courage_boost')) crg += (_perks['max_courage_boost']! * 1);
    return crg;
  }

  double get crimeBonusMultiplier { return 1.0 + ((_perks['crime_master'] ?? 0) * 0.03); }
  int get hospitalTimeReductionPercent { return (_perks['fast_recovery'] ?? 0) * 5; }

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
    if (state == AppLifecycleState.resumed && _uid != null && !_isLoading) {
      _firestore.collection('players').doc(_uid).update({
        'lastUpdate': FieldValue.serverTimestamp()
      }).catchError((e) => debugPrint("Error updating time: $e"));
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
    _sendSystemNotification("تحديث جديد 🚨", message, "info");
  }

  List<Map<String, dynamic>> getAllTitles() {
    int wlth = _cash + _bankBalance;
    int cr = crimeSuccessCountsMap.values.fold(0, (sum, val) => sum + val);
    bool isHoused = _activePropertyId != null;

    return [
      {'name': 'مبتدئ في الشوارع 🚶', 'desc': 'اللقب الافتراضي (متاح للجميع)', 'unlocked': true},
      {'name': 'مبتدئ مالي 💵', 'desc': 'اجمع 100 ألف دولار', 'unlocked': wlth >= 100000},
      {'name': 'مليونير صاعد 💰', 'desc': 'اجمع 1 مليون دولار', 'unlocked': wlth >= 1000000},
      {'name': 'رجل أعمال ثري 🏦', 'desc': 'اجمع 10 مليون دولار', 'unlocked': wlth >= 10000000},
      {'name': 'حوت المافيا 🐋', 'desc': 'اجمع 100 مليون دولار', 'unlocked': wlth >= 100000000},
      {'name': 'نصف بليونير 💎', 'desc': 'اجمع 500 مليون دولار', 'unlocked': wlth >= 500000000},
      {'name': 'بليونير الشوارع 💸', 'desc': 'اجمع 1 مليار دولار', 'unlocked': wlth >= 1000000000},
      {'name': 'قارون المدينة 🪙', 'desc': 'اجمع 10 مليار دولار', 'unlocked': wlth >= 10000000000},
      {'name': 'إمبراطور الاقتصاد 🌍', 'desc': 'اجمع 100 مليار دولار', 'unlocked': wlth >= 100000000000},
      {'name': 'باحث عن الذهب ⛏️', 'desc': 'اجمع 100 ذهبة', 'unlocked': _gold >= 100},
      {'name': 'مكتنز الذهب 🪙', 'desc': 'اجمع 500 ذهبة', 'unlocked': _gold >= 500},
      {'name': 'تاجر الذهب ⚖️', 'desc': 'اجمع 1,000 ذهبة', 'unlocked': _gold >= 1000},
      {'name': 'بارون الذهب 👑', 'desc': 'اجمع 5,000 ذهبة', 'unlocked': _gold >= 5000},
      {'name': 'ملك السبائك 🧱', 'desc': 'اجمع 10,000 ذهبة', 'unlocked': _gold >= 10000},
      {'name': 'خزنة لا تنضب 🏦', 'desc': 'اجمع 50,000 ذهبة', 'unlocked': _gold >= 50000},
      {'name': 'أسطورة الذهب 🌟', 'desc': 'اجمع 100,000 ذهبة', 'unlocked': _gold >= 100000},
      {'name': 'إله الثروة ⚡', 'desc': 'اجمع 500,000 ذهبة', 'unlocked': _gold >= 500000},
      {'name': 'قاتل مأجور 🎯', 'desc': 'اقتل 10 لاعبين في الشوارع', 'unlocked': _pvpWins >= 10},
      {'name': 'سفاح خطير 🔪', 'desc': 'اقتل 50 لاعب في الشوارع', 'unlocked': _pvpWins >= 50},
      {'name': 'أسطورة الجريمة 👑🩸', 'desc': 'اقتل 200 لاعب في الشوارع', 'unlocked': _pvpWins >= 200},
      {'name': 'لص محترف 🥷', 'desc': 'نفذ 500 جريمة ناجحة', 'unlocked': cr >= 500},
      {'name': 'عقل مدبر 🧠', 'desc': 'نفذ 2,000 جريمة ناجحة', 'unlocked': cr >= 2000},
      {'name': 'زعيم المافيا 🎩', 'desc': 'نفذ 10,000 جريمة ناجحة', 'unlocked': cr >= 10000},
      {'name': 'كابوس المدينة 🦇', 'desc': 'نفذ 50,000 جريمة ناجحة', 'unlocked': cr >= 50000},
      {'name': 'شيطان الشوارع 👹', 'desc': 'نفذ 100,000 جريمة ناجحة', 'unlocked': cr >= 100000},
      {'name': 'رجل أعمال سعيد 💼', 'desc': 'صل إلى 500 نقطة سعادة', 'unlocked': _happiness >= 500},
      {'name': 'مواطن VIP 🥂', 'desc': 'صل إلى 2,000 نقطة سعادة', 'unlocked': _happiness >= 2000},
      {'name': 'سيد الرفاهية 🏰', 'desc': 'صل إلى 5,000 نقطة سعادة', 'unlocked': _happiness >= 5000},
      {'name': 'إمبراطور النعيم 👑', 'desc': 'صل إلى 10,000 نقطة سعادة', 'unlocked': _happiness >= 10000},
      {'name': 'أسطورة السعادة 🌈', 'desc': 'صل إلى 50,000 نقطة سعادة', 'unlocked': _happiness >= 50000},
      {'name': 'مواطن مستقر 🏠', 'desc': 'اشتر أول عقار لك واسكن فيه', 'unlocked': _ownedProperties.isNotEmpty && isHoused},
      {'name': 'مستثمر عقاري 🏢', 'desc': 'اشتر 5 عقارات واسكن في أحدها', 'unlocked': _ownedProperties.length >= 5 && isHoused},
      {'name': 'ملك العقارات 🏙️', 'desc': 'اشتر جميع العقارات واسكن في أحدها', 'unlocked': _ownedProperties.length >= GameData.residentialProperties.length && isHoused},
      {'name': 'تاجر صغير 🏪', 'desc': 'اشتر مشروع تجاري واحد', 'unlocked': _ownedBusinesses.isNotEmpty},
      {'name': 'محتكر السوق 📈', 'desc': 'اشتر 5 مشاريع تجارية', 'unlocked': _ownedBusinesses.length >= 5},
      {'name': 'إمبراطور التجارة 🛳️', 'desc': 'اشتر 10 مشاريع تجارية', 'unlocked': _ownedBusinesses.length >= 10},
      {'name': 'هاوي محركات 🏎️', 'desc': 'امتلك سيارة واحدة', 'unlocked': _ownedCars.isNotEmpty},
      {'name': 'مجمع سيارات 🚘', 'desc': 'امتلك 5 سيارات', 'unlocked': _ownedCars.length >= 5},
      {'name': 'شريطي الشوارع 🏎️💨', 'desc': 'امتلك 10 سيارات', 'unlocked': _ownedCars.length >= 10},
      {'name': 'صاحب معرض 🏁', 'desc': 'امتلك 15 سيارة', 'unlocked': _ownedCars.length >= 15},
      {'name': 'إمبراطور الكراجات 👑🏎️', 'desc': 'امتلك 25 سيارة', 'unlocked': _ownedCars.length >= 25},
      {'name': 'ميكانيكي مبتدئ 🔧', 'desc': 'اجمع 100 قطعة غيار', 'unlocked': _spareParts >= 100},
      {'name': 'خبير تفكيك ⚙️', 'desc': 'اجمع 1,000 قطعة غيار', 'unlocked': _spareParts >= 1000},
      {'name': 'ملك السكراب 🚜', 'desc': 'اجمع 10,000 قطعة غيار', 'unlocked': _spareParts >= 10000},
      {'name': 'إمبراطور القطع 🏭', 'desc': 'اجمع 50,000 قطعة غيار', 'unlocked': _spareParts >= 50000},
      {'name': 'كيميائي هاوي 🧪', 'desc': 'قم بـ 10 عمليات تصنيع في المختبر', 'unlocked': _totalLabCrafts >= 10},
      {'name': 'طباخ محترف 👨‍🔬', 'desc': 'قم بـ 50 عملية تصنيع في المختبر', 'unlocked': _totalLabCrafts >= 50},
      {'name': 'خبير سموم ☠️', 'desc': 'قم بـ 200 عملية تصنيع في المختبر', 'unlocked': _totalLabCrafts >= 200},
      {'name': 'هايزنبرغ المدينة 💎', 'desc': 'قم بـ 1,000 عملية تصنيع في المختبر', 'unlocked': _totalLabCrafts >= 1000},
      {'name': 'محب للمغامرة 🎡', 'desc': 'دور عجلة الحظ 10 مرات', 'unlocked': _luckyWheelSpins >= 10},
      {'name': 'مدمن قمار 🎲', 'desc': 'دور عجلة الحظ 50 مرة', 'unlocked': _luckyWheelSpins >= 50},
      {'name': 'ملك الحظ 🍀', 'desc': 'دور عجلة الحظ 200 مرة', 'unlocked': _luckyWheelSpins >= 200},
      {'name': 'حبيب الكازينو 🎰', 'desc': 'دور عجلة الحظ 1,000 مرة', 'unlocked': _luckyWheelSpins >= 1000},
      {'name': 'عضو داعم 🪙', 'desc': 'تبرع بـ 100,000 لعصابتك', 'unlocked': _gangContribution >= 100000},
      {'name': 'ذراع اليمين 🤝', 'desc': 'تبرع بـ 1,000,000 لعصابتك', 'unlocked': _gangContribution >= 1000000},
      {'name': 'ممول العصابة 💼', 'desc': 'تبرع بـ 10 مليون لعصابتك', 'unlocked': _gangContribution >= 10000000},
      {'name': 'بنك العصابة 🏦', 'desc': 'تبرع بـ 50 مليون لعصابتك', 'unlocked': _gangContribution >= 50000000},
      {'name': 'عراب الشوارع 🕴️', 'desc': 'تبرع بـ 100 مليون لعصابتك', 'unlocked': _gangContribution >= 100000000},
      {'name': 'خارج عن القانون 🔫', 'desc': 'صل للمستوى 10 في الجريمة', 'unlocked': _crimeLevel >= 10},
      {'name': 'مجرم مخضرم 🧨', 'desc': 'صل للمستوى 25 في الجريمة', 'unlocked': _crimeLevel >= 25},
      {'name': 'زعيم محنك 🎩', 'desc': 'صل للمستوى 50 في الجريمة', 'unlocked': _crimeLevel >= 50},
      {'name': 'شبح المدينة 👻', 'desc': 'صل للمستوى 100 في الجريمة', 'unlocked': _crimeLevel >= 100},
      {'name': 'كابوس السلطات 🚔', 'desc': 'صل للمستوى 150 في الجريمة', 'unlocked': _crimeLevel >= 150},
      {'name': 'أسطورة حية 🐉', 'desc': 'صل للمستوى 200 في الجريمة', 'unlocked': _crimeLevel >= 200},
      {'name': 'إله الجريمة 🌋', 'desc': 'صل للمستوى 300 في الجريمة', 'unlocked': _crimeLevel >= 300},
      {'name': 'الحاكم المطلق 👑🌍', 'desc': 'صل للمستوى 400 (الماكس لفل)', 'unlocked': _crimeLevel >= 400},
      {'name': 'موظف مجتهد 💼', 'desc': 'صل للمستوى 10 في العمل', 'unlocked': _workLevel >= 10},
      {'name': 'مدير تنفيذي 📊', 'desc': 'صل للمستوى 25 في العمل', 'unlocked': _workLevel >= 25},
      {'name': 'رئيس مجلس الإدارة 🏢', 'desc': 'صل للمستوى 50 في العمل', 'unlocked': _workLevel >= 50},
      {'name': 'وزير الاقتصاد 🏛️', 'desc': 'صل للمستوى 100 في العمل', 'unlocked': _workLevel >= 100},
      {'name': 'ملاكم شوارع 🥊', 'desc': 'صل للمستوى 10 في الحلبة', 'unlocked': _arenaLevel >= 10},
      {'name': 'بطل الحلبة 🥇', 'desc': 'صل للمستوى 50 في الحلبة', 'unlocked': _arenaLevel >= 50},
      {'name': 'جلاد الساحة 🩸', 'desc': 'صل للمستوى 100 في الحلبة', 'unlocked': _arenaLevel >= 100},
      {'name': 'زائر مميز 🌟', 'desc': 'فعل اشتراك VIP لمدة يوم', 'unlocked': _totalVipDays >= 1},
      {'name': 'شخصية هامة 🍷', 'desc': 'فعل اشتراك VIP لمدة أسبوع', 'unlocked': _totalVipDays >= 7},
      {'name': 'نجم المدينة 💎', 'desc': 'فعل اشتراك VIP لمدة شهر', 'unlocked': _totalVipDays >= 30},
      {'name': 'صاحب الفخامة 👑💎', 'desc': 'فعل اشتراك VIP لمدة سنة', 'unlocked': _totalVipDays >= 365},
    ];
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
    _energy = data['energy'] ?? _energy; _courage = data['courage'] ?? _courage; _prestige = data['prestige'] ?? 100;
    _health = data['health'] ?? _health; _baseMaxHealth = data['maxHealth'] ?? _baseMaxHealth; _happiness = data['happiness'] ?? _happiness;
    _baseStrength = (data['strength'] ?? 5.0).toDouble(); _baseDefense = (data['defense'] ?? 5.0).toDouble(); _baseSkill = (data['skill'] ?? 5.0).toDouble(); _baseSpeed = (data['speed'] ?? 5.0).toDouble();

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
    _isInPrison = data['isInPrison'] ?? false; if (data['prisonReleaseTime'] != null) _prisonReleaseTime = DateTime.parse(data['prisonReleaseTime']);
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
    _heat = (data['heat'] ?? 0.0).toDouble(); _spareParts = data['spareParts'] ?? 0; _equippedWeaponId = data['equippedWeaponId']; _equippedArmorId = data['equippedArmorId']; _equippedMaskId = data['equippedMaskId']; _equippedCrimeToolId = data['equippedCrimeToolId'];
    if (data['durability'] != null) _durability = Map<String, double>.from(data['durability'].map((k, v) => MapEntry(k, v.toDouble())));
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
  }

  Future<void> _syncWithFirestore() async {
    if (_uid == null || _isLoading) return;
    try {
      await _firestore.collection('players').doc(_uid).set({
        'playerName': _playerName, 'gameId': _gameId, 'bio': _bio, 'profilePicUrl': _profilePicUrl, 'backgroundPicUrl': _backgroundPicUrl, 'currentCity': _currentCity,
        'cash': _cash, 'gold': _gold, 'bankBalance': _bankBalance, 'energy': _energy, 'courage': _courage, 'prestige': _prestige, 'health': _health, 'maxHealth': _baseMaxHealth, 'happiness': _happiness, 'strength': _baseStrength, 'defense': _baseDefense, 'skill': _baseSkill, 'speed': _baseSpeed,
        'activeSteroidEndTime': _activeSteroidEndTime?.toIso8601String(), 'activeCoach': _activeCoach, 'coachEndTime': _coachEndTime?.toIso8601String(),
        'ownedProperties': _ownedProperties, 'activePropertyId': _activePropertyId, 'listedProperties': _listedProperties, 'rentedOutProperties': _rentedOutProperties, 'activeRentedProperty': _activeRentedProperty, 'ownedBusinesses': _ownedBusinesses, 'lastPassiveIncomeTime': _lastPassiveIncomeTime?.toIso8601String(),
        'inventory': _inventory, 'crimeLevel': _crimeLevel, 'crimeXP': _crimeXP, 'workLevel': _workLevel, 'workXP': _workXP, 'arenaLevel': _arenaLevel, 'isInPrison': _isInPrison, 'prisonReleaseTime': _prisonReleaseTime?.toIso8601String(), 'isHospitalized': _isHospitalized, 'hospitalReleaseTime': _hospitalReleaseTime?.toIso8601String(), 'lockedBalance': _lockedBalance, 'lockedProfits': _lockedProfits, 'lockedUntil': _lockedUntil?.toIso8601String(), 'vipUntil': _vipUntil?.toIso8601String(), 'totalVipDays': _totalVipDays, 'totalLabCrafts': _totalLabCrafts, 'luckyWheelSpins': _luckyWheelSpins, 'loanAmount': _loanAmount, 'creditScore': _creditScore, 'loanTime': _loanTime?.toIso8601String(), 'gangName': _gangName, 'gangRank': _gangRank, 'gangContribution': _gangContribution, 'gangWarWins': _gangWarWins, 'territoryOwners': _territoryOwners, 'crimeSuccessCountsMap': crimeSuccessCountsMap, 'contractEndTime': _contractEndTime?.toIso8601String(), 'activeContractName': _activeContractName, 'contractSalary': _contractSalary, 'lastUpdate': FieldValue.serverTimestamp(), 'ownedCars': _ownedCars, 'activeCarId': _activeCarId, 'chopShopEndTime': _chopShopEndTime?.toIso8601String(), 'isChopping': _isChopping, 'labEndTime': _labEndTime?.toIso8601String(), 'isCrafting': _isCrafting, 'craftingItemId': _craftingItemId, 'heat': _heat, 'spareParts': _spareParts, 'durability': _durability, 'equippedWeaponId': _equippedWeaponId, 'equippedArmorId': _equippedArmorId, 'equippedMaskId': _equippedMaskId, 'equippedCrimeToolId': _equippedCrimeToolId, 'transactions': _transactions.map((t) => t.toJson()).toList(), 'lastCrimeName': _lastCrimeName, 'bailCost': _playerBailCost,
        'pvpWins': _pvpWins,
        'totalStolenCash': _totalStolenCash,
        'perks': _perks,
        'selectedTitle': _selectedTitle,
        'unlockedTitlesList': _unlockedTitlesList,
      }, SetOptions(merge: true));
    } catch (e) {}
  }

  void _checkNewTitles() {
    if (_isLoading || _uid == null) return;
    List<Map<String, dynamic>> all = getAllTitles();
    List<String> currentUnlocked = all.where((t) => t['unlocked'] == true).map((t) => t['name'] as String).toList();
    bool hasNew = false;
    int newCount = 0;

    List<String> missingTitles = currentUnlocked.where((t) => !_unlockedTitlesList.contains(t)).toList();

    if (missingTitles.isNotEmpty) {
      if (missingTitles.length > 3 && _unlockedTitlesList.length <= 1) {
        _unlockedTitlesList = currentUnlocked;
        _syncWithFirestore();
        notifyListeners();
        _sendSystemNotification("تحديث الحساب 🌟", "تم تحديث حسابك ومنحك نقاط الامتياز والألقاب بأثر رجعي!", "update");
        return;
      }

      for (String t in missingTitles) {
        _unlockedTitlesList.add(t);
        hasNew = true;
        newCount++;

        if (newCount <= 3) {
          _sendSystemNotification('لقب جديد 🏆', 'تهانينا! لقد كسبت لقب: ($t) وحصلت على نقطة امتياز جديدة.', 'trophy');
        }
      }

      if (newCount > 3) {
        _sendSystemNotification('ألقاب جديدة 🏆', 'حصلت على $newCount ألقاب جديدة! راجع خزانة الألقاب.', 'trophy');
      }
    }

    if (hasNew) {
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    int syncCounter = 0;
    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLoading) return;
      bool localChanged = false;
      syncCounter++;

      if (timer.tick % 5 == 0) {
        _checkNewTitles();
      }

      // 🟢 إنهاء مفعول المنشط بصمت
      if (_activeSteroidEndTime != null && secureNow.isAfter(_activeSteroidEndTime!)) {
        _activeSteroidEndTime = null;
        localChanged = true;
      }

      // 🟢 إنهاء مفعول المدرب بصمت
      if (_coachEndTime != null && secureNow.isAfter(_coachEndTime!)) {
        _activeCoach = null;
        _coachEndTime = null;
        localChanged = true;
      }

      // 🟢 إرسال إشعار عند انتهاء الـ Cooldown وإزالته من المخزون
      int steroidCooldown = _inventory['steroid_cooldown'] ?? 0;
      if (steroidCooldown > 0 && secureNow.millisecondsSinceEpoch > steroidCooldown) {
        _inventory.remove('steroid_cooldown');
        _sendSystemNotification("سوق المنشطات 💉", "انتهت فترة الراحة للمنشطات! يمكنك شراء وحقن جرعة جديدة الآن.", "info");
        localChanged = true;
      }

      int coachCooldown = _inventory['coach_cooldown'] ?? 0;
      if (coachCooldown > 0 && secureNow.millisecondsSinceEpoch > coachCooldown) {
        _inventory.remove('coach_cooldown');
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
        _sendSystemNotification("السجن 🔒", "تم الإفراج عنك من السجن!", "prison");
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
      if (syncCounter >= 60) { _syncWithFirestore(); syncCounter = 0; }
    });
  }

  void travelToCity(String city, int price) { if (_cash >= price) { _cash -= price; _currentCity = city; _syncWithFirestore(); notifyListeners(); _showNotification("✈️ هبطت طائرتك بسلام في $city!"); } else { _showNotification("⚠️ لا تملك كاش كافي للسفر!"); } }
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
  void addWorkXP(int amount) { _workXP += amount; if (_workXP >= workXPToNextLevel) { _workXP -= workXPToNextLevel; _workLevel++; _showNotification("تمت ترقيتك للمستوى $_workLevel"); } _syncWithFirestore(); notifyListeners(); }

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
    _equippedWeaponId = null; _equippedArmorId = null; _equippedMaskId = null; _vipUntil = null; _totalVipDays = 0; _totalLabCrafts = 0; _luckyWheelSpins = 0; _unlockedTitlesList = [];
    _isHospitalized = false; _hospitalReleaseTime = null; _crimeLevel = 1; _workLevel = 1; _crimeXP = 0; _workXP = 0; _isInPrison = false; _prisonReleaseTime = null; _lockedBalance = 0; _lockedProfits = 0; _lockedUntil = null;
    _arenaLevel = 1; _loanAmount = 0; _creditScore = 0; _loanTime = null; _gangName = null; _gangRank = "عضو"; _gangContribution = 0; _gangWarWins = 0; _territoryOwners = {};
    crimeSuccessCountsMap = {}; _transactions = []; _chopShopEndTime = null; _isChopping = false; _labEndTime = null; _isCrafting = false; _craftingItemId = null;
    _heat = 0.0; _spareParts = 0; _durability = {}; _equippedCrimeToolId = null; _bio = "لا يوجد وصف حالياً... رجل أفعال لا أقوال."; _profilePicUrl = null; _backgroundPicUrl = null; _currentCity = 'ملاذ';
    _listedProperties = []; _rentedOutProperties = {}; _activeRentedProperty = null; _lastPassiveIncomeTime = secureNow;
    _activeSteroidEndTime = null; _activeCoach = null; _coachEndTime = null; _pvpWins = 0; _totalStolenCash = 0; _perks = {}; _selectedTitle = null; _baseMaxHealth = 100;
    await _syncWithFirestore(); notifyListeners();
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