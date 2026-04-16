import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import 'laboratory_state.dart';
export 'laboratory_state.dart'; // 🟢 تصدير لتسهيل الاستدعاء

class LaboratoryCubit extends Cubit<LaboratoryState> {
  LaboratoryCubit() : super(LaboratoryState());

  // 🟢 دالة بدء التصنيع
  Future<void> startCrafting(PlayerProvider player, String recipeId, int cost, int timeInMinutes, String recipeName) async {
    if (player.cash < cost) {
      emit(state.copyWith(errorMessage: 'لا تملك كاش كافي لبدء التصنيع!'));
      emit(state.copyWith(errorMessage: '')); // تصفير
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      // الـ Provider بيتواصل مع السيرفر ويبدأ المؤقت
      await Future.sync(() => player.startCrafting(recipeId, cost, timeInMinutes));

      emit(state.copyWith(isLoading: false, successMessage: 'تم بدء تصنيع $recipeName 🧪'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'خطأ: ${e.toString()}'));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  // 🟢 دالة جمع المادة بعد الانتهاء
  Future<void> collectItem(PlayerProvider player) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      await Future.sync(() {
        player.collectCraftedItem();
        player.incrementLabCrafts(); // زيادة العداد لفتح الألقاب
      });

      emit(state.copyWith(isLoading: false, successMessage: 'تم نقل المادة إلى المخزن بنجاح 📦'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'خطأ: ${e.toString()}'));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}