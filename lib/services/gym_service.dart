// المسار: lib/services/gym_service.dart

import 'package:cloud_functions/cloud_functions.dart';

class GymService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // 🟢 تعديل: إرجاع Map بدلاً من double لاستقبال الطاقة المسترجعة
  Future<Map<String, dynamic>> trainStats({
    required String uid,
    required int strE,
    required int defE,
    required int skillE,
    required int spdE,
    required int maxEnergy, // 🟢 أضفنا هذا المتغير هنا ليستقبله من الكوبيت
  }) async {
    try {
      final result = await _functions.httpsCallable('trainMultipleStats').call({
        'uid': uid,
        'strE': strE,
        'defE': defE,
        'skillE': skillE,
        'spdE': spdE,
        'maxEnergy': maxEnergy, // 🟢 ونقوم بتمريره هنا للسيرفر (index.js)
      });

      // 🟢 نرجع البيانات كاملة كـ Map ليقرأها الكيوبت
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      throw Exception('فشل التدريب: $e');
    }
  }

  Future<void> hireCoach({required String uid, required String coachId, required int price}) async {
    try {
      await _functions.httpsCallable('hireCoach').call({'uid': uid, 'coachId': coachId, 'price': price});
    } catch (e) {
      throw Exception('فشل التعاقد: $e');
    }
  }

  Future<void> buyAndUseSteroids({required String uid, required int price}) async {
    try {
      await _functions.httpsCallable('buyAndUseSteroids').call({'uid': uid, 'price': price});
    } catch (e) {
      throw Exception('فشل شراء المنشطات: $e');
    }
  }
}