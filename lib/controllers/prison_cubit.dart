import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import 'prison_state.dart';
export 'prison_state.dart'; // 🟢 تصدير لتسهيل الاستدعاء

class PrisonCubit extends Cubit<PrisonState> {
  PrisonCubit() : super(PrisonState());

  // 🟢 دالة دفع الكفالة
  Future<void> payBail(PlayerProvider player, String targetUid, int bailCost, String targetName) async {
    // 1. حماية قبل إرسال الطلب
    if (player.cash < bailCost) {
      emit(state.copyWith(errorMessage: 'لا تملك كاش كافي لدفع كفالة $targetName!'));
      emit(state.copyWith(errorMessage: '')); // تصفير
      return;
    }

    emit(state.copyWith(isBailingOut: true, errorMessage: '', successMessage: ''));

    try {
      // 2. ننادي الدالة الأصلية في الـ Provider لتكلم السيرفر
      await player.bailOutPlayer(targetUid, bailCost, targetName);

      // 3. نجاح العملية
      emit(state.copyWith(isBailingOut: false, successMessage: 'تم إخراج $targetName من السجن! لقد كسبت شهامة 🤝'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isBailingOut: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}