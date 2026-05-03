// المسار: lib/controllers/gym_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import '../services/gym_service.dart';
import 'gym_state.dart';
export 'gym_state.dart';

class GymCubit extends Cubit<GymState> {
  final GymService _gymService = GymService();

  GymCubit() : super(GymState());

  Future<void> trainStats(PlayerProvider player, int strE, int defE, int skillE, int spdE) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      // 🟢 تعديل: استقبال النتيجة كـ Map لقراءة الطاقة المسترجعة
      final result = await _gymService.trainStats(
          uid: player.uid!,
          strE: strE,
          defE: defE,
          skillE: skillE,
          spdE: spdE,
          maxEnergy: player.maxEnergy
      );

      double gained = (result['gained'] as num).toDouble();
      int refunded = (result['refunded'] as num?)?.toInt() ?? 0;

      if (gained > 0) {
        String finalMessage = 'تم التدريب بنجاح! اكتسبت +$gained إحصائيات. 💪';

        // 🟢 إذا السيرفر رجع طاقة، نضيفها للرسالة
        if (refunded > 0) {
          finalMessage += '\nتم استرجاع $refunded طاقة لم يتم استخدامها لأنك وصلت للحد الأقصى! ⚡';
        }

        emit(state.copyWith(isLoading: false, successMessage: finalMessage, gainedStats: gained));
        emit(state.copyWith(successMessage: '', clearGainedStats: true));
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
      // 🟢 السيرفر يقوم بخصم الفلوس وضبط وقت المدرب بدقة، فلا تتدخل من التطبيق
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
      // 🟢 السيرفر يقوم باللازم بشكل آمن!
      emit(state.copyWith(isLoading: false, successMessage: 'تم حقن المنشطات بنجاح! ⚡'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}