import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import '../services/chop_shop_service.dart'; // 🟢 تم ربط الخدمة
import 'chop_shop_state.dart';
export 'chop_shop_state.dart';

class ChopShopCubit extends Cubit<ChopShopState> {
  final ChopShopService _chopShopService = ChopShopService();

  ChopShopCubit() : super(ChopShopState());

  Future<void> startChopping(PlayerProvider player, int stolenCarsCount) async {
    if (stolenCarsCount <= 0) {
      emit(state.copyWith(errorMessage: 'لا تملك سيارات مسروقة في المخزن!'));
      emit(state.copyWith(errorMessage: ''));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      await _chopShopService.startChopping(uid: player.uid!);

      emit(state.copyWith(isLoading: false, successMessage: 'تم إدخال السيارة للورشة وبدأ التفكيك! 🔧'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  Future<void> collectChoppedCar(PlayerProvider player) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      await _chopShopService.collectChoppedCar(uid: player.uid!);

      player.addCash(15000, reason: 'بيع قطع سيارة مسروقة'); // 🟢 تحديث فوري للكاش

      emit(state.copyWith(isLoading: false, successMessage: 'تم بيع القطع واستلام 15,000 كاش بنجاح! 💰'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}