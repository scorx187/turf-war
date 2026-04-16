import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'lucky_wheel_state.dart';

class LuckyWheelCubit extends Cubit<LuckyWheelState> {
  LuckyWheelCubit() : super(LuckyWheelState());

  // نقلنا قائمة الجوائز هنا عشان المنطق يقدر يقارنها بسهولة
  final List<Map<String, dynamic>> prizes = [
    {'id': 'gold_600', 'name': '600 ذهب', 'icon': Icons.monetization_on, 'color': Colors.yellow, 'chance': 0.20},
    {'id': 'cash_50m', 'name': '50 مليون', 'icon': Icons.money, 'color': Colors.lightGreenAccent, 'chance': 0.05},
    {'id': 'cash_10m', 'name': '10 مليون', 'icon': Icons.attach_money, 'color': Colors.green, 'chance': 0.25},
    {'id': 't_aladdin_lamp', 'name': 'المصباح السحري', 'icon': Icons.lightbulb, 'color': Colors.amberAccent, 'chance': 0.06},
    {'id': 't_aladdin_carpet', 'name': 'البساط الطائر', 'icon': Icons.map, 'color': Colors.purpleAccent, 'chance': 0.06},
    {'id': 't_magic_ring', 'name': 'خاتم السلطة', 'icon': Icons.radio_button_checked, 'color': Colors.orange, 'chance': 0.06},
    {'id': 'w_aladdin_damage', 'name': 'سيف الضرر', 'icon': Icons.hardware, 'color': Colors.redAccent, 'chance': 0.03},
    {'id': 'a_aladdin_evasion', 'name': 'عباءة مراوغة', 'icon': Icons.air, 'color': Colors.cyanAccent, 'chance': 0.03},
    {'id': 'a_aladdin_defense', 'name': 'درع دفاع', 'icon': Icons.shield, 'color': Colors.blue, 'chance': 0.03},
    {'id': 'w_aladdin_accuracy', 'name': 'خنجر الدقة', 'icon': Icons.flash_on, 'color': Colors.deepOrange, 'chance': 0.03},
    {'id': 'vip_7', 'name': 'VIP أسبوع', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'chance': 0.10},
    {'id': 'perk_point', 'name': 'نقطة امتياز', 'icon': Icons.star, 'color': Colors.blueAccent, 'chance': 0.10},
  ];

  void claimPendingPrizes(String uid) async {
    try {
      await FirebaseFunctions.instance.httpsCallable('claimLuckyWheel').call({'uid': uid});
    } catch (e) {
      // تجاهل بصمت
    }
  }

  Future<void> spin(int times, String uid, int currentGold, VoidCallback playSound) async {
    int cost = times == 1 ? 500 : 4500;

    if (currentGold < cost) {
      emit(state.copyWith(errorMessage: 'لا تملك ذهب كافٍ!'));
      emit(state.copyWith(errorMessage: '')); // تصفير الخطأ بعد إرساله
      return;
    }

    // بدأ الدوران
    emit(state.copyWith(isSpinning: true, statusText: "", errorMessage: '', wonPrizes: null));

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('spinLuckyWheel');
      final result = await callable.call({'uid': uid, 'times': times});

      if (result.data['success'] == true) {
        List<dynamic> serverPrizes = result.data['wonPrizes'];
        List<Map<String, dynamic>> wonPrizes = [];

        for (var sp in serverPrizes) {
          wonPrizes.add({
            'id': sp['id'],
            'name': sp['name'],
            'color': Color(sp['colorValue']),
            'icon': prizes.firstWhere((p) => p['id'] == sp['id'], orElse: () => prizes.first)['icon'],
          });
        }

        int targetIndex = prizes.indexWhere((p) => p['id'] == wonPrizes.last['id']);
        if (targetIndex == -1) targetIndex = 0;

        int totalSteps = (12 * 3) + targetIndex - state.currentIndex;
        if (totalSteps < 12) totalSteps += 12;

        int delay = 40;
        for(int i = 0; i < totalSteps; i++) {
          await Future.delayed(Duration(milliseconds: delay));

          // تحديث الواجهة خطوة بخطوة أثناء الدوران
          emit(state.copyWith(currentIndex: (state.currentIndex + 1) % 12));

          if (totalSteps - i < 15) delay += 15;
          if (totalSteps - i < 5) delay += 40;
        }

        playSound(); // تشغيل الصوت عند التوقف

        try {
          await FirebaseFunctions.instance.httpsCallable('claimLuckyWheel').call({'uid': uid});
        } catch(e) {
          debugPrint("خطأ في استلام الجوائز: $e");
        }

        // إنهاء الدوران وإرسال الجوائز للواجهة عشان تعرضها
        emit(state.copyWith(isSpinning: false, wonPrizes: wonPrizes));
      }
    } catch (e) {
      emit(state.copyWith(isSpinning: false, errorMessage: 'خطأ السيرفر: ${e.toString()}'));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  void resetPrizes() {
    emit(state.copyWith(wonPrizes: null));
  }
}