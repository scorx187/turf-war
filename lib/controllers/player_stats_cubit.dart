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

  // 🟢 القيم الكسرية الدقيقة للتجديد المحلي
  double _exactHealth = 100;
  double _exactEnergy = 100;
  double _exactCourage = 30;
  double _exactPrestige = 100;

  // 🟢 السر هنا: نحفظ "آخر رقم رأيناه من السيرفر" لكي لا نمسح التجديد المحلي بالخطأ
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

  void _listenToPlayer(String uid) {
    _playerSubscription?.cancel();
    _playerSubscription = FirebaseFirestore.instance.collection('players').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _serverData = snapshot.data() as Map<String, dynamic>;

        if (!_isInitialized) {
          // أول مرة يفتح اللاعب اللعبة، نأخذ الأرقام كأساس
          _exactHealth = (_serverData['health'] ?? 100).toDouble();
          _exactEnergy = (_serverData['energy'] ?? 100).toDouble();
          _exactCourage = (_serverData['courage'] ?? 30).toDouble();
          _exactPrestige = (_serverData['prestige'] ?? 100).toDouble();

          // نسجل الأرقام الأساسية
          _lastSeenServerHealth = _exactHealth.toInt();
          _lastSeenServerEnergy = _exactEnergy.toInt();
          _lastSeenServerCourage = _exactCourage.toInt();
          _lastSeenServerPrestige = _exactPrestige.toInt();

          _lastTick = DateTime.now();
          _isInitialized = true;
        } else {
          // 🟢 التحديث الذكي: لن نعدل الرقم المحلي إلا إذا السيرفر "غيره" فعلياً!
          // هذا يمنع الجرائم من تصفير أو تفويل الطاقة بالخطأ

          int srvEnergy = (_serverData['energy'] ?? 100).toInt();
          if (srvEnergy != _lastSeenServerEnergy) {
            _exactEnergy = srvEnergy.toDouble(); // نعتمد تحديث السيرفر
            _lastSeenServerEnergy = srvEnergy;   // نحفظ الرقم الجديد
          }

          int srvCourage = (_serverData['courage'] ?? 30).toInt();
          if (srvCourage != _lastSeenServerCourage) {
            _exactCourage = srvCourage.toDouble();
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

    int crimeLevel = _serverData['crimeLevel'] ?? 1; // 🟢 جلبنا اللفل
    int maxHealth = _serverData['maxHealth'] ?? 100;
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

    // 🟢 حساب الحد الأقصى الديناميكي للشجاعة
    int maxCourage = (isVIP ? 60 : 29) + crimeLevel;

    if (_exactHealth < maxHealth) {
      _exactHealth += (maxHealth / 1800.0) * deltaSeconds;
      if (_exactHealth > maxHealth) _exactHealth = maxHealth.toDouble();
    }

    if (_exactEnergy < maxEnergy) {
      _exactEnergy += (1.0 / 8.0) * deltaSeconds;
      if (_exactEnergy > maxEnergy) _exactEnergy = maxEnergy.toDouble();
    }

    if (_exactCourage < maxCourage) {
      _exactCourage += (1.0 / 4.0) * deltaSeconds; // يمكن جعلها 1.0/1.0 لتزيد كل ثانية
      if (_exactCourage > maxCourage) _exactCourage = maxCourage.toDouble();
    }

    if (_exactPrestige < maxPrestige) {
      _exactPrestige += (1.0 / 6.0) * deltaSeconds;
      if (_exactPrestige > maxPrestige) _exactPrestige = maxPrestige.toDouble();
    }

    _updateState();
  }

  void _updateState() {
    int crimeLevel = _serverData['crimeLevel'] ?? 1; // 🟢 جلبنا اللفل
    int maxHealth = _serverData['maxHealth'] ?? 100;
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

    // 🟢 حساب الحد الأقصى الديناميكي للشجاعة
    int maxCourage = (isVIP ? 60 : 29) + crimeLevel;

    int currentXp = _serverData['crimeXP'] ?? 0;
    int maxXp = (250 * pow(1.06, crimeLevel - 1)).toInt();

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