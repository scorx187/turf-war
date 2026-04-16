import 'package:cloud_functions/cloud_functions.dart';

class HospitalService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // 🟢 دالة الاتصال بالسيرفر لطلب العلاج
  Future<Map<String, dynamic>> healPlayer({required String uid, required String healType}) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('healPlayer');
      final result = await callable.call({
        'uid': uid,
        'healType': healType, // 'cash', 'vip', 'medkit'
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}