import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import '../providers/player_provider.dart';
import 'street_race_state.dart';
export 'street_race_state.dart'; // 🟢 لتسهيل الاستدعاء

class StreetRaceCubit extends Cubit<StreetRaceState> {
  StreetRaceCubit() : super(StreetRaceState());

  // 🟢 نقلنا البيانات هنا لتنظيف الواجهة تماماً
  final Map<String, Map<String, dynamic>> carShop = {
    'datsun_90': {'name': 'داتسون 90', 'speed': 45, 'price': 5000, 'icon': Icons.directions_car},
    'camry_2003': {'name': 'كامري 2003', 'speed': 78, 'price': 18000, 'icon': Icons.time_to_leave},
    'lumina_2008': {'name': 'لومينا 2008 (V6 3.6L)', 'speed': 88, 'price': 35000, 'icon': Icons.airport_shuttle},
    'gtr_r35': {'name': 'جي تي آر R35', 'speed': 125, 'price': 150000, 'icon': Icons.sports_motorsports},
  };

  final List<Map<String, dynamic>> raceOpponents = [
    {'name': 'مبتدئ الحارة', 'carName': 'داتسون مهترئ', 'enemySpeed': 40, 'reward': 1000, 'energy': 10},
    {'name': 'خصم عنيد', 'carName': 'كامري 2003', 'enemySpeed': 75, 'reward': 3500, 'energy': 15, 'desc': 'انطلاقتها سريعة ومفاجئة، لا تستهن بها!'},
    {'name': 'ملك الخط', 'carName': 'لومينا 2008 V6', 'enemySpeed': 85, 'reward': 7000, 'energy': 20, 'desc': 'ثقيلة وقوية على الخط السريع.'},
    {'name': 'الزعيم السري', 'carName': 'جي تي آر معدل', 'enemySpeed': 120, 'reward': 25000, 'energy': 30, 'desc': 'وحش ياباني لا يرحم.'},
  ];

  // 🟢 1. دالة بدء السباق
  Future<void> startRace(PlayerProvider player, Map<String, dynamic> opponent) async {
    if (player.activeCarId == null) {
      emit(state.copyWith(errorMessage: 'لا تملك سيارة! اذهب للمعرض أولاً.'));
      emit(state.copyWith(errorMessage: ''));
      return;
    }

    if (player.energy < opponent['energy']) {
      // نرسل كود خاص عشان الواجهة تعرف وتطلع نافذة القهوة
      emit(state.copyWith(errorMessage: 'energy_shortage:${opponent['energy'] - player.energy}'));
      emit(state.copyWith(errorMessage: ''));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: '', clearRaceResult: true));

    try {
      int playerSpeed = carShop[player.activeCarId!]!['speed'];
      int enemySpeed = opponent['enemySpeed'];

      double winChance = playerSpeed / (playerSpeed + enemySpeed);
      bool isWinner = Random().nextDouble() < winChance;

      // محاكاة وقت السباق
      await Future.delayed(const Duration(seconds: 2));

      // تحديث بيانات اللاعب بالستيت
      player.finishRace(isWinner, opponent['reward'], opponent['energy']);

      // إرسال النتيجة للواجهة
      emit(state.copyWith(
          isLoading: false,
          raceResult: {
            'isWinner': isWinner,
            'reward': opponent['reward'],
            'message': isWinner
                ? "سيارتك أثبتت جدارتها بالشارع! حصلت على ${opponent['reward']} كاش."
                : "خصمك كان أسرع منك.. طور سيارتك أو اشترِ واحدة أفضل."
          }
      ));
      emit(state.copyWith(clearRaceResult: true)); // تصفير عشان ما تطلع النافذة مرتين
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'حدث خطأ: $e'));
      emit(state.copyWith(errorMessage: ''));
    }
  }

  // 🟢 2. دالة شراء سيارة
  void buyCar(PlayerProvider player, String carId, int price, String carName) {
    if (player.cash < price) {
      emit(state.copyWith(errorMessage: 'كاشك ما يكفي لشراء $carName!'));
      emit(state.copyWith(errorMessage: ''));
      return;
    }
    player.buyCar(carId, price);
    emit(state.copyWith(successMessage: 'مبروك! شريت $carName 🚘'));
    emit(state.copyWith(successMessage: ''));
  }

  // 🟢 3. دالة تحديد السيارة النشطة
  void useCar(PlayerProvider player, String carId) {
    player.setActiveCar(carId);
    emit(state.copyWith(successMessage: 'تم تحديد السيارة للسباقات القادمة 🏎️'));
    emit(state.copyWith(successMessage: ''));
  }
}