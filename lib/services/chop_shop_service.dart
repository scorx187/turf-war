import 'package:cloud_functions/cloud_functions.dart';

class ChopShopService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> startChopping({required String uid}) async {
    try {
      await _functions.httpsCallable('startChoppingCar').call({'uid': uid});
    } catch (e) {
      throw Exception('فشل بدء التفكيك: $e');
    }
  }

  Future<void> collectChoppedCar({required String uid}) async {
    try {
      await _functions.httpsCallable('collectChoppedCar').call({'uid': uid});
    } catch (e) {
      throw Exception('فشل استلام الأرباح: $e');
    }
  }
}