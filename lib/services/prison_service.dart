import 'package:cloud_functions/cloud_functions.dart';

class PrisonService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> payBail({required String uid, required String targetUid, required int bailCost}) async {
    try {
      await _functions.httpsCallable('bailOutPlayer').call({
        'uid': uid, // اللاعب اللي بيدفع
        'targetUid': targetUid, // اللاعب المسجون
        'bailCost': bailCost
      });
    } catch (e) {
      throw Exception('فشل دفع الكفالة: $e');
    }
  }
}