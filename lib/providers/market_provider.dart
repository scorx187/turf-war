// المسار: lib/providers/market_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class MarketProvider with ChangeNotifier {
  int _goldPrice = 16000;
  int _oldGoldPrice = 16000;
  double _realEstateMultiplier = 1.0;
  int _currentMarketEpoch = 0;
  Timer? _marketTimer;

  int get goldPrice => _goldPrice;
  int get oldGoldPrice => _oldGoldPrice;
  double get realEstateMultiplier => _realEstateMultiplier;

  MarketProvider() {
    _updateMarketPrices();
    _startMarketLoop();
  }

  void _startMarketLoop() {
    _marketTimer?.cancel();
    // التحديث كل 10 ثواني للتأكد من دخول النافذة الزمنية الجديدة
    _marketTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateMarketPrices();
    });
  }

  void _updateMarketPrices() {
    // 21600000 ملي ثانية = 6 ساعات بالضبط عالمياً
    int newEpoch = DateTime.now().millisecondsSinceEpoch ~/ 21600000;

    if (_currentMarketEpoch != newEpoch) {
      _currentMarketEpoch = newEpoch;

      // جلب سعر النافذة السابقة
      Random oldRand = Random(newEpoch - 1);
      _oldGoldPrice = 12000 + oldRand.nextInt(6001);

      // جلب السعر الجديد للذهب والعقارات
      Random newRand = Random(newEpoch);
      _goldPrice = 12000 + newRand.nextInt(6001);
      _realEstateMultiplier = 0.60 + (newRand.nextDouble() * 0.80);

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _marketTimer?.cancel();
    super.dispose();
  }
}