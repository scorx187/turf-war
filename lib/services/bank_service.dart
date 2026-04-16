import 'package:cloud_functions/cloud_functions.dart';

class BankService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // 1. الإيداع
  Future<void> deposit({required String uid, required int amount}) async {
    try {
      await _functions.httpsCallable('depositToBank').call({'uid': uid, 'amount': amount});
    } catch (e) {
      throw Exception('فشل الإيداع: $e');
    }
  }

  // 2. السحب
  Future<void> withdraw({required String uid, required int amount}) async {
    try {
      await _functions.httpsCallable('withdrawFromBank').call({'uid': uid, 'amount': amount});
    } catch (e) {
      throw Exception('فشل السحب: $e');
    }
  }

  // 3. شراء الذهب
  Future<void> buyGold({required String uid, required int amount, required int price}) async {
    try {
      await _functions.httpsCallable('buyGold').call({'uid': uid, 'amount': amount, 'price': price});
    } catch (e) {
      throw Exception('فشل شراء الذهب: $e');
    }
  }

  // 4. بيع الذهب
  Future<void> sellGold({required String uid, required int amount, required int price}) async {
    try {
      await _functions.httpsCallable('sellGold').call({'uid': uid, 'amount': amount, 'price': price});
    } catch (e) {
      throw Exception('فشل بيع الذهب: $e');
    }
  }

  // 5. أخذ قرض
  Future<void> takeLoan({required String uid, required int amount}) async {
    try {
      await _functions.httpsCallable('takeLoan').call({'uid': uid, 'amount': amount});
    } catch (e) {
      throw Exception('فشل الحصول على القرض: $e');
    }
  }

  // 6. سداد قرض
  Future<void> repayLoan({required String uid, required int amount}) async {
    try {
      await _functions.httpsCallable('repayLoan').call({'uid': uid, 'amount': amount});
    } catch (e) {
      throw Exception('فشل سداد القرض: $e');
    }
  }

  // 7. الاستثمار المقيد
  Future<void> startLockedInvestment({required String uid, required int amount, required int minutes, required double rate}) async {
    try {
      await _functions.httpsCallable('startLockedInvestment').call({
        'uid': uid,
        'amount': amount,
        'minutes': minutes,
        'rate': rate
      });
    } catch (e) {
      throw Exception('فشل تجميد الاستثمار: $e');
    }
  }
}