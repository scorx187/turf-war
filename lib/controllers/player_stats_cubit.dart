import 'package:flutter_bloc/flutter_bloc.dart';
import 'player_stats_state.dart';

class PlayerStatsCubit extends Cubit<PlayerStatsState> {
  // نعطي قيم ابتدائية عند التشغيل
  PlayerStatsCubit() : super(PlayerStatsState());

  // دالة تجريبية لتحديث الفلوس عشان تتأكد إن الواجهة مفصولة وشغالة
  void updateCash(int newCash) {
    emit(state.copyWith(cash: newCash));
  }

  // مستقبلاً: بننقل هنا أكواد Firebase و الـ Game Loop الخاصة بالموارد
  void syncWithServerData(PlayerStatsState serverData) {
    emit(serverData);
  }
}