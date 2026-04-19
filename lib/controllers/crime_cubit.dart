// المسار: lib/controllers/crime_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/crime_service.dart';
import 'dart:math';
import 'crime_state.dart';
export 'crime_state.dart';

class CrimeCubit extends Cubit<CrimeState> {
  final CrimeService _crimeService = CrimeService();
  static final Random _random = Random();

  CrimeCubit() : super(CrimeState());

  double calculateFailChance(Map<String, dynamic> crime, double heat, int successCount, int catIndex, String? equippedToolId, double toolDurability, String? equippedMaskId) {
    int stars = successCount >= 500 ? 3 : successCount >= 50 ? 2 : successCount >= 10 ? 1 : 0;
    double heatPenalty = (heat / 100) * 0.3;
    double finalFailChance = (crime['failChance'] as double) + heatPenalty - (stars * 0.05);

    if (equippedMaskId != null) finalFailChance -= 0.1;

    if (equippedToolId != null) {
      double toolBonus = 0.0;
      if (equippedToolId == 'emp_device') toolBonus = 0.30;
      else if (equippedToolId == 'thermite' && catIndex >= 14) toolBonus = 0.25;
      else if (equippedToolId == 'slim_jim' && (catIndex == 3 || catIndex == 6)) toolBonus = 0.15;
      else if (equippedToolId == 'lockpick' && catIndex == 4) toolBonus = 0.15;
      else toolBonus = 0.10;

      if (toolDurability >= 10) finalFailChance -= toolBonus; else finalFailChance -= (toolBonus / 2);
    }

    return finalFailChance.clamp(0.00, 0.98);
  }

  Future<void> attemptCrime({
    required String uid,
    required Map<String, dynamic> crime,
    required double finalFailChance,
    required int maxCourage,
    required int maxEnergy,
    required Function(int, String, int, int, int, int, bool, String?) onSuccessCallback, // 🟢 تم إضافة اللقب
    required Function(int, String, int) onFailureCallback,
  }) async {

    emit(state.copyWith(isLoading: true, errorMessage: '', eventMessage: ''));

    try {
      final data = await _crimeService.commitCrime(
        uid: uid,
        crimeId: crime['id'],
        crimeName: crime['name'],
        reqCourage: crime['courage'],
        finalFailChance: finalFailChance,
        minCash: crime['minCash'],
        maxCash: crime['maxCash'],
        xp: crime['xp'],
        maxCourage: maxCourage,
        maxEnergy: maxEnergy,
      );

      if (data['success'] == true) {
        bool evadedPolice = _random.nextDouble() < 0.15;
        // 🟢 تمرير اللقب (إن وجد)
        onSuccessCallback(data['reward'] ?? 0, crime['id'], crime['xp'], 0, data['droppedGold'] ?? 0, data['droppedEnergy'] ?? 0, evadedPolice, data['earnedTitle']);
        emit(state.copyWith(isLoading: false));
      } else {
        onFailureCallback(data['prisonMinutes'] ?? 0, crime['name'], data['bailCost'] ?? 0);
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      emit(state.copyWith(errorMessage: ''));
    }
  }
}