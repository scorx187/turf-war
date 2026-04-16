import 'package:flutter_bloc/flutter_bloc.dart';
import 'real_estate_state.dart';
export 'real_estate_state.dart'; // 🟢 تصدير لتسهيل الاستدعاء

class RealEstateCubit extends Cubit<RealEstateState> {
  RealEstateCubit() : super(RealEstateState());

  // 🟢 دالة موحدة تستقبل أي عملية عقارية وتنفذها مع حماية الشاشة
  Future<void> executeAction(Function actionTask, String successMsg) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      await Future.sync(() => actionTask());
      emit(state.copyWith(isLoading: false, successMessage: successMsg));
      emit(state.copyWith(successMessage: '')); // تصفير الرسالة بعد إرسالها
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: '')); // تصفير الخطأ بعد إرساله
    }
  }
}