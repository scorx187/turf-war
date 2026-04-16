import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import '../services/prison_service.dart'; // 🟢 تم ربط الخدمة
import 'prison_state.dart';
export 'prison_state.dart';

class PrisonCubit extends Cubit<PrisonState> {
  final PrisonService _prisonService = PrisonService();

  PrisonCubit() : super(PrisonState());

  Future<void> payBail(PlayerProvider player, String targetUid, int bailCost, String targetName) async {
    if (player.cash < bailCost) {
      emit(state.copyWith(errorMessage: 'لا تملك كاش كافي لدفع كفالة $targetName!'));
      emit(state.copyWith(errorMessage: ''));
      return;
    }

    emit(state.copyWith(isBailingOut: true, errorMessage: '', successMessage: ''));

    try {
      // نكلم السيرفر للتوثيق
      await _prisonService.payBail(uid: player.uid!, targetUid: targetUid, bailCost: bailCost);

      player.removeCash(bailCost, reason: 'دفع كفالة $targetName'); // 🟢 تحديث الكاش بالواجهة فوراً

      emit(state.copyWith(isBailingOut: false, successMessage: 'تم إخراج $targetName من السجن! لقد كسبت شهامة 🤝'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isBailingOut: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}