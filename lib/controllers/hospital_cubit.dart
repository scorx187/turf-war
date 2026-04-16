import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/hospital_service.dart';
import 'hospital_state.dart';
export 'hospital_state.dart'; // 🟢 حطيت لك تصدير هنا عشان ما تحتاج تعدل ملف الواجهة (View) أبداً

class HospitalCubit extends Cubit<HospitalState> {
  final HospitalService _hospitalService = HospitalService();

  HospitalCubit() : super(HospitalState());

  int calculateHealCost(int maxHealth, int currentHealth, bool isVIP) {
    int missingHealth = maxHealth - currentHealth;
    return isVIP ? (missingHealth * 0.8).toInt() : missingHealth;
  }

  Future<void> processHealing({
    required String uid,
    required String healType,
    required int healCost,
    required int currentCash,
    required bool hasMedkit,
    required Function() onSuccessCallback,
  }) async {
    if (healType == 'cash' && currentCash < healCost) {
      _emitError('لا تملك كاش كافي!');
      return;
    } else if (healType == 'medkit' && !hasMedkit && currentCash < 2000) {
      _emitError('لا تملك كاش كافي لشراء حقيبة!');
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      final data = await _hospitalService.healPlayer(uid: uid, healType: healType);

      if (data['success'] == true) {
        onSuccessCallback();
        emit(state.copyWith(isLoading: false, successMessage: 'تم العلاج بنجاح! 🩹'));
        emit(state.copyWith(successMessage: ''));
      } else {
        _emitError('مرفوض من السيرفر');
      }
    } catch (e) {
      _emitError('مرفوض من السيرفر: $e');
    }
  }

  void _emitError(String msg) {
    emit(state.copyWith(isLoading: false, errorMessage: msg));
    emit(state.copyWith(errorMessage: ''));
  }
}