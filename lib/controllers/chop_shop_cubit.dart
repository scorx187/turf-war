import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import 'chop_shop_state.dart';
export 'chop_shop_state.dart'; // 🟢 تصدير لتسهيل الاستدعاء

class ChopShopCubit extends Cubit<ChopShopState> {
  ChopShopCubit() : super(ChopShopState());

  // 🟢 دالة بدء تفكيك السيارة
  Future<void> startChopping(PlayerProvider player, int stolenCarsCount) async {
    if (stolenCarsCount <= 0) {
      emit(state.copyWith(errorMessage: 'لا تملك سيارات مسروقة في المخزن!'));
      emit(state.copyWith(errorMessage: '')); // تصفير
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      await Future.sync(() => player.startChopping());
      emit(state.copyWith(isLoading: false, successMessage: 'تم إدخال السيارة للورشة وبدأ التفكيك! 🔧'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'خطأ: ${e.toString()}'));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  // 🟢 دالة استلام أرباح التفكيك
  Future<void> collectChoppedCar(PlayerProvider player) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      await Future.sync(() => player.collectChoppedCar());
      emit(state.copyWith(isLoading: false, successMessage: 'تم بيع القطع واستلام 15,000 كاش بنجاح! 💰'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'خطأ: ${e.toString()}'));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}