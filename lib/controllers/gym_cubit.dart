import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import '../services/gym_service.dart';
import 'gym_state.dart';
export 'gym_state.dart';

class GymCubit extends Cubit<GymState> {
  final GymService _gymService = GymService();

  GymCubit() : super(GymState());

  Future<void> trainStats(PlayerProvider player, int strE, int defE, int skillE, int spdE) async {
    int totalEnergy = strE + defE + skillE + spdE;
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      double gained = await _gymService.trainStats(uid: player.uid!, strE: strE, defE: defE, skillE: skillE, spdE: spdE);

      if (gained > 0) {
        // 🟢 هنا التعديل: استخدمنا دالة setEnergy الموجودة مسبقاً
        player.setEnergy(player.energy - totalEnergy);
        emit(state.copyWith(isLoading: false, gainedStats: gained));
        emit(state.copyWith(clearGainedStats: true));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  Future<void> hireCoach(PlayerProvider player, String id, int price, String coachName) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      await _gymService.hireCoach(uid: player.uid!, coachId: id, price: price);
      player.removeCash(price, reason: 'استئجار مدرب $coachName');

      emit(state.copyWith(isLoading: false, successMessage: 'تم التعاقد مع $coachName بنجاح! 💪'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  Future<void> buySteroids(PlayerProvider player, int price) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      await _gymService.buyAndUseSteroids(uid: player.uid!, price: price);
      player.removeCash(price, reason: 'شراء منشطات');

      emit(state.copyWith(isLoading: false, successMessage: 'تم حقن المنشطات بنجاح! ⚡'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}