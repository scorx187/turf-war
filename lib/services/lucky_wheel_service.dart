import 'package:cloud_functions/cloud_functions.dart';

class LuckyWheelService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> spinWheel({required String uid, required int times}) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('spinLuckyWheel');
      final result = await callable.call({'uid': uid, 'times': times});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> claimPrizes({required String uid}) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('claimLuckyWheel');
      await callable.call({'uid': uid});
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}