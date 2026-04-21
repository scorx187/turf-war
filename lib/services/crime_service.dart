// المسار: lib/services/crime_service.dart

import 'package:cloud_functions/cloud_functions.dart';

class CrimeService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // استدعاء دالة تنفيذ الجريمة في السيرفر
  Future<Map<String, dynamic>> commitCrime({
    required String uid,
    required String crimeId,
    required String crimeName,
    required int reqCourage,
    required double finalFailChance,
    required int minCash,
    required int maxCash,
    required int minXp, // 🟢 تم التعديل لاستقبال الحد الأدنى للخبرة
    required int maxXp, // 🟢 تم التعديل لاستقبال الحد الأقصى للخبرة
    required int maxCourage,
    required int maxEnergy,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('commitCrime');
      final result = await callable.call({
        'uid': uid,
        'crimeId': crimeId,
        'crimeName': crimeName,
        'reqCourage': reqCourage,
        'finalFailChance': finalFailChance,
        'minCash': minCash,
        'maxCash': maxCash,
        'minXp': minXp,
        'maxXp': maxXp,
        'maxCourage': maxCourage,
        'maxEnergy': maxEnergy,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception('فشل الاتصال بالسيرفر: ${e.toString()}');
    }
  }
}