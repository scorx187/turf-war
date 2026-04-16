import 'package:cloud_functions/cloud_functions.dart';

class InventoryService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> consumeItem({required String uid, required String itemId}) async {
    try {
      await _functions.httpsCallable('consumeItem').call({'uid': uid, 'itemId': itemId});
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        throw Exception(e.message ?? 'خطأ في السيرفر');
      }
      throw Exception(e.toString());
    }
  }
}