import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import 'gym_state.dart';
export 'gym_state.dart'; // 🟢 تصدير لتسهيل الاستدعاء في الواجهة

class GymCubit extends Cubit<GymState> {
  GymCubit() : super(GymState());

  // 🟢 1. تنفيذ التدريب
  Future<void> trainStats(PlayerProvider player, int strE, int defE, int skillE, int spdE) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      double gained = await player.trainMultipleStats(strE, defE, skillE, spdE);

      if (gained > 0) {
        emit(state.copyWith(isLoading: false, gainedStats: gained));
        emit(state.copyWith(clearGainedStats: true)); // 🟢 تصفير القيمة بعد إرسالها للواجهة
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  // 🟢 2. التعاقد مع المدرب
  Future<void> hireCoach(PlayerProvider player, String id, int price, String coachName) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      await player.hireCoach(id, price);
      emit(state.copyWith(isLoading: false, successMessage: 'تم التعاقد مع $coachName بنجاح! 💪'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  // 🟢 3. شراء المنشطات
  Future<void> buySteroids(PlayerProvider player, int price) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      await player.buyAndUseSteroids(price);
      emit(state.copyWith(isLoading: false, successMessage: 'تم حقن المنشطات بنجاح! ⚡'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}