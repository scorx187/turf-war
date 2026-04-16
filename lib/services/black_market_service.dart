import 'package:cloud_functions/cloud_functions.dart';

class BlackMarketService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> buyItem({
    required String uid,
    required String itemId,
    required int cost,
    required String currencyType,
    required int amount,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('buyItem');
      final result = await callable.call({
        'uid': uid,
        'itemId': itemId,
        'cost': cost,
        'currencyType': currencyType,
        'amount': amount,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}