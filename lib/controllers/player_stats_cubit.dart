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

  // 🟢 السر هنا: متغيرات كسرية دقيقة تحسب الزيادة بأجزاء الثانية لمنع القفزات!
  double _exactHealth = 100;
  double _exactEnergy = 100;
  double _exactCourage = 30;
  double _exactPrestige = 100;

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

  void _listenToPlayer(String uid) {
    _playerSubscription?.cancel();
    _playerSubscription = FirebaseFirestore.instance.collection('players').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _serverData = snapshot.data() as Map<String, dynamic>;

        if (!_isInitialized) {
          // أول مرة يفتح اللاعب اللعبة، نأخذ الأرقام من السيرفر كقاعدة أساسية
          _exactHealth = (_serverData['health'] ?? 100).toDouble();
          _exactEnergy = (_serverData['energy'] ?? 100).toDouble();
          _exactCourage = (_serverData['courage'] ?? 30).toDouble();
          _exactPrestige = (_serverData['prestige'] ?? 100).toDouble();
          _lastTick = DateTime.now();
          _isInitialized = true;
        } else {
          // 🟢 هنا نمنع القفزات! إذا السيرفر أرسل رقم أقل (يعني صرفت طاقة/شجاعة) نأخذه فوراً
          // أو إذا أرسل رقم أعلى بكثير (مكافأة أو شراء)
          int srvEnergy = _serverData['energy'] ?? 100;
          if (srvEnergy < _exactEnergy.toInt() || srvEnergy > _exactEnergy.toInt() + 2) {
            _exactEnergy = srvEnergy.toDouble();
          }

          int srvCourage = _serverData['courage'] ?? 30;
          if (srvCourage < _exactCourage.toInt() || srvCourage > _exactCourage.toInt() + 2) {
            _exactCourage = srvCourage.toDouble();
          }

          int srvHealth = _serverData['health'] ?? 100;
          if (srvHealth < _exactHealth.toInt() || srvHealth > _exactHealth.toInt() + 2) {
            _exactHealth = srvHealth.toDouble();
          }

          int srvPrestige = _serverData['prestige'] ?? 100;
          if (srvPrestige < _exactPrestige.toInt() || srvPrestige > _exactPrestige.toInt() + 2) {
            _exactPrestige = srvPrestige.toDouble();
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
    // نحسب كم ثانية وجزء من الثانية مر بدقة شديدة
    double deltaSeconds = now.difference(_lastTick ?? now).inMilliseconds / 1000.0;
    _lastTick = now;

    int maxHealth = _serverData['maxHealth'] ?? 100;
    int maxEnergy = 100;
    int maxCourage = 30;
    int maxPrestige = 100;

    bool isVIP = false;
    if (_serverData['vipUntil'] != null) {
      isVIP = DateTime.parse(_serverData['vipUntil']).isAfter(now);
      if (isVIP) {
        maxEnergy = 200;
        maxCourage = 60;
        maxPrestige = 200;
      }
    }

    // 🟢 الحساب الرياضي السلس (يجمع كسور الثواني بالتدريج بدون قفزات)
    // 1. الصحة (تمتلئ في 30 دقيقة)
    if (_exactHealth < maxHealth) {
      _exactHealth += (maxHealth / 1800.0) * deltaSeconds;
      if (_exactHealth > maxHealth) _exactHealth = maxHealth.toDouble();
    }

    // 2. الطاقة (الحالي: نقطة كل 8 ثواني) -> إذا تبغاها كل ثانية غيّر الـ 8.0 إلى 1.0
    if (_exactEnergy < maxEnergy) {
      _exactEnergy += (1.0 / 8.0) * deltaSeconds;
      if (_exactEnergy > maxEnergy) _exactEnergy = maxEnergy.toDouble();
    }

    // 3. الشجاعة (الحالي: نقطة كل 4 ثواني) -> إذا تبغاها كل ثانية غيّر الـ 4.0 إلى 1.0
    if (_exactCourage < maxCourage) {
      _exactCourage += (1.0 / 4.0) * deltaSeconds;
      if (_exactCourage > maxCourage) _exactCourage = maxCourage.toDouble();
    }

    // 4. الهيبة (الحالي: نقطة كل 6 ثواني) -> إذا تبغاها كل ثانية غيّر الـ 6.0 إلى 1.0
    if (_exactPrestige < maxPrestige) {
      _exactPrestige += (1.0 / 6.0) * deltaSeconds;
      if (_exactPrestige > maxPrestige) _exactPrestige = maxPrestige.toDouble();
    }

    _updateState();
  }

  void _updateState() {
    int maxHealth = _serverData['maxHealth'] ?? 100;
    int maxEnergy = 100;
    int maxCourage = 30;
    int maxPrestige = 100;

    bool isVIP = false;
    if (_serverData['vipUntil'] != null) {
      isVIP = DateTime.parse(_serverData['vipUntil']).isAfter(DateTime.now());
      if (isVIP) {
        maxEnergy = 200;
        maxCourage = 60;
        maxPrestige = 200;
      }
    }

    int crimeLevel = _serverData['crimeLevel'] ?? 1;
    int currentXp = _serverData['crimeXP'] ?? 0;
    int maxXp = (100 * pow(1.05, crimeLevel - 1)).toInt();

    // نرسل الأرقام كأعداد صحيحة (.toInt) للواجهة بعد أن نكون جمعنا الكسور بالخفاء
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