// المسار: lib/controllers/player_stats_cubit.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'player_stats_state.dart';

class PlayerStatsCubit extends Cubit<PlayerStatsState> {
  StreamSubscription? _authSubscription;
  StreamSubscription? _playerSubscription;
  Timer? _timer;
  Map<String, dynamic> _serverData = {};

  DateTime? _lastTick;
  bool _isInitialized = false;

  double _exactHealth = 100;
  double _exactEnergy = 100;
  double _exactCourage = 30;
  double _exactPrestige = 100;

  int _lastSeenServerHealth = -1;
  int _lastSeenServerEnergy = -1;
  int _lastSeenServerCourage = -1;
  int _lastSeenServerPrestige = -1;

  PlayerStatsCubit() : super(PlayerStatsState()) {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToPlayer(user.uid);
      } else {
        _clearData();
      }
    });
  }

  void initialize(String uid) {
    _listenToPlayer(uid);
  }

  double getBaseHealthForLevel(int level) {
    if (level <= 100) {
      return (100 * pow(1.06, level - 1)).toDouble();
    } else {
      double hpAt100 = (100 * pow(1.06, 99)).toDouble();
      return (hpAt100 * pow(1.0194488, level - 100)).toDouble();
    }
  }

  void _listenToPlayer(String uid) {
    _playerSubscription?.cancel();
    _playerSubscription = FirebaseFirestore.instance.collection('players').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _serverData = snapshot.data() as Map<String, dynamic>;
        DateTime now = DateTime.now();

        // 🟢 1. حساب الحد الأقصى للموارد أولاً لضمان عدم تجاوزه
        int crimeLevel = _serverData['crimeLevel'] ?? 1;
        int maxEnergy = 100;
        bool isVIP = false;
        if (_serverData['vipUntil'] != null) {
          isVIP = DateTime.parse(_serverData['vipUntil']).isAfter(now);
          if (isVIP) {
            maxEnergy = 200;
          }
        }
        int maxCourage = 29 + crimeLevel + (isVIP ? 50 : 0);

        // 🟢 2. الحسبة السحرية: تعويض الموارد بناءً على فترة الغياب (Offline Progress)
        double realEnergy = (_serverData['energy'] ?? 100).toDouble();
        if (_serverData['lastEnergyUpdate'] != null) {
          DateTime lastE = (_serverData['lastEnergyUpdate'] is Timestamp)
              ? (_serverData['lastEnergyUpdate'] as Timestamp).toDate()
              : DateTime.parse(_serverData['lastEnergyUpdate'].toString());
          int sec = now.difference(lastE).inSeconds;
          if (sec > 0) realEnergy += (sec / (isVIP ? 9.0 : 18.0)); // 30 دقيقة فل
        }
        realEnergy = min(realEnergy, maxEnergy.toDouble());

        double realCourage = (_serverData['courage'] ?? 30).toDouble();
        if (_serverData['lastCourageUpdate'] != null) {
          DateTime lastC = (_serverData['lastCourageUpdate'] is Timestamp)
              ? (_serverData['lastCourageUpdate'] as Timestamp).toDate()
              : DateTime.parse(_serverData['lastCourageUpdate'].toString());
          int secC = now.difference(lastC).inSeconds;
          if (secC > 0) realCourage += (secC / 36.0); // 50 نقطة كل نص ساعة
        }
        realCourage = min(realCourage, maxCourage.toDouble());

        if (!_isInitialized) {
          _exactHealth = (_serverData['health'] ?? 100).toDouble();

          // 🟢 نمرر الموارد الحقيقية اللي حسبناها بعد الغياب
          _exactEnergy = realEnergy;
          _exactCourage = realCourage;
          _exactPrestige = (_serverData['prestige'] ?? 100).toDouble();

          _lastSeenServerHealth = _exactHealth.toInt();
          _lastSeenServerEnergy = (_serverData['energy'] ?? 100).toInt();
          _lastSeenServerCourage = (_serverData['courage'] ?? 30).toInt();
          _lastSeenServerPrestige = _exactPrestige.toInt();

          _lastTick = now;
          _isInitialized = true;
        } else {
          int srvEnergy = (_serverData['energy'] ?? 100).toInt();
          if (srvEnergy != _lastSeenServerEnergy) {
            _exactEnergy = realEnergy; // تحديث دقيق
            _lastSeenServerEnergy = srvEnergy;
          }

          int srvCourage = (_serverData['courage'] ?? 30).toInt();
          if (srvCourage != _lastSeenServerCourage) {
            _exactCourage = realCourage; // تحديث دقيق
            _lastSeenServerCourage = srvCourage;
          }

          int srvHealth = (_serverData['health'] ?? 100).toInt();
          if (srvHealth != _lastSeenServerHealth) {
            _exactHealth = srvHealth.toDouble();
            _lastSeenServerHealth = srvHealth;
          }

          int srvPrestige = (_serverData['prestige'] ?? 100).toInt();
          if (srvPrestige != _lastSeenServerPrestige) {
            _exactPrestige = srvPrestige.toDouble();
            _lastSeenServerPrestige = srvPrestige;
          }
        }

        _updateState();

        if (_timer == null || !_timer!.isActive) {
          _startLoop();
        }
      }
    });
  }

  void _startLoop() {
    _timer?.cancel();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isInitialized) {
        _tickRegeneration();
      }
    });
  }

  void _tickRegeneration() {
    DateTime now = DateTime.now();
    double deltaSeconds = now.difference(_lastTick ?? now).inMilliseconds / 1000.0;
    _lastTick = now;

    int crimeLevel = _serverData['crimeLevel'] ?? 1;

    int baseMaxHealth = _serverData['maxHealth'] ?? 100;
    double finalHp = baseMaxHealth.toDouble();
    Map<dynamic, dynamic> perks = _serverData['perks'] ?? {};
    String? equippedSpecial = _serverData['equippedSpecialId'];

    if (perks['max_hp_boost'] != null) {
      finalHp += finalHp * ((perks['max_hp_boost'] as num).toInt() * 0.02);
    }
    if (equippedSpecial == 't_golden_apple') {
      finalHp += baseMaxHealth * 0.10;
    }
    if (equippedSpecial == 't_phoenix_feather') {
      finalHp += baseMaxHealth * 0.05;
    }
    int maxHealth = finalHp.toInt();

    int maxEnergy = 100;
    int maxPrestige = 100;

    bool isVIP = false;
    if (_serverData['vipUntil'] != null) {
      isVIP = DateTime.parse(_serverData['vipUntil']).isAfter(now);
      if (isVIP) {
        maxEnergy = 200;
        maxPrestige = 200;
      }
    }

    int maxCourage = 29 + crimeLevel + (isVIP ? 50 : 0);

    // 🟢 تطبيق المعادلات الرياضية الجديدة للوقت
    if (_exactHealth < maxHealth) {
      double healthRegenTime = 1800.0 + (maxHealth * 0.0005); // كلما زاد الدم طال الوقت
      _exactHealth += (maxHealth / healthRegenTime) * deltaSeconds;
      if (_exactHealth > maxHealth) _exactHealth = maxHealth.toDouble();
    }

    if (_exactEnergy < maxEnergy) {
      _exactEnergy += (1.0 / (isVIP ? 9.0 : 18.0)) * deltaSeconds;
      if (_exactEnergy > maxEnergy) _exactEnergy = maxEnergy.toDouble();
    }

    if (_exactCourage < maxCourage) {
      _exactCourage += (1.0 / 36.0) * deltaSeconds;
      if (_exactCourage > maxCourage) _exactCourage = maxCourage.toDouble();
    }

    if (_exactPrestige < maxPrestige) {
      _exactPrestige += (1.0 / (isVIP ? 36.0 : 72.0)) * deltaSeconds;
      if (_exactPrestige > maxPrestige) _exactPrestige = maxPrestige.toDouble();
    }

    _updateState();
  }

  void _updateState() {
    int crimeLevel = _serverData['crimeLevel'] ?? 1;

    int baseMaxHealth = _serverData['maxHealth'] ?? 100;
    double finalHp = baseMaxHealth.toDouble();
    Map<dynamic, dynamic> perks = _serverData['perks'] ?? {};
    String? equippedSpecial = _serverData['equippedSpecialId'];

    if (perks['max_hp_boost'] != null) {
      finalHp += finalHp * ((perks['max_hp_boost'] as num).toInt() * 0.02);
    }
    if (equippedSpecial == 't_golden_apple') {
      finalHp += baseMaxHealth * 0.10;
    }
    if (equippedSpecial == 't_phoenix_feather') {
      finalHp += baseMaxHealth * 0.05;
    }
    int maxHealth = finalHp.toInt();

    int maxEnergy = 100;
    int maxPrestige = 100;

    bool isVIP = false;
    if (_serverData['vipUntil'] != null) {
      isVIP = DateTime.parse(_serverData['vipUntil']).isAfter(DateTime.now());
      if (isVIP) {
        maxEnergy = 200;
        maxPrestige = 200;
      }
    }

    int maxCourage = 29 + crimeLevel + (isVIP ? 50 : 0);

    int currentXp = _serverData['crimeXP'] ?? 0;
    int maxXp = (250 * pow(1.02, crimeLevel - 1)).toInt();

    emit(state.copyWith(
      cash: _serverData['cash'] ?? 0,
      gold: _serverData['gold'] ?? 0,
      health: _exactHealth.toInt(),
      maxHealth: maxHealth,
      energy: _exactEnergy.toInt(),
      maxEnergy: maxEnergy,
      courage: _exactCourage.toInt(),
      maxCourage: maxCourage,
      prestige: _exactPrestige.toInt(),
      maxPrestige: maxPrestige,
      currentXp: currentXp,
      maxXp: maxXp,
      level: crimeLevel,
      playerName: _serverData['playerName'] ?? 'لاعب',
      profilePicUrl: _serverData['profilePicUrl'],
      isVIP: isVIP,
    ));
  }

  void _clearData() {
    _playerSubscription?.cancel();
    _timer?.cancel();
    _serverData.clear();
    _isInitialized = false;
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _clearData();
    return super.close();
  }
}