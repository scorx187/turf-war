import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/player_provider.dart';
import 'black_market_state.dart';
export 'black_market_state.dart'; // 🟢 تصدير لتسهيل الاستدعاء في الواجهة

class BlackMarketCubit extends Cubit<BlackMarketState> {
  BlackMarketCubit() : super(BlackMarketState());

  // 🟢 دالة الشراء الآمنة من السيرفر
  Future<void> buyItem(PlayerProvider player, String itemId, int cost, String currencyType, int amount, String itemName) async {
    // 1. حماية مبدئية محلية
    if (currencyType == 'cash' && player.cash < cost) {
      _emitError('كاش غير كافي لشراء $itemName!');
      return;
    } else if (currencyType == 'gold' && player.gold < cost) {
      _emitError('ذهب غير كافي لشراء $itemName!');
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('buyItem');
      final result = await callable.call({
        'uid': player.uid,
        'itemId': itemId,
        'cost': cost,
        'currencyType': currencyType,
        'amount': amount,
      });

      if (result.data['success'] == true) {
        // 2. تحديث بيانات اللاعب محلياً بعد نجاح العملية بالسيرفر
        if (currencyType == 'cash') {
          player.removeCash(cost, reason: "شراء من المتجر الأسود");
        } else {
          player.removeGold(cost);
        }
        player.addInventoryItem(itemId, amount);

        emit(state.copyWith(isLoading: false, successMessage: 'تم شراء $itemName بنجاح 🤝'));
        emit(state.copyWith(successMessage: '')); // تصفير
      } else {
        _emitError('فشلت العملية من السيرفر');
      }
    } catch (e) {
      _emitError('مرفوض من السيرفر: ${e.toString()}');
    }
  }

  // 🟢 دالة شراء عضوية VIP
  Future<void> buyVip(PlayerProvider player, int days, int price) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      // نعتمد على الدالة الأصلية في الـ Provider لكن نغلفها بالكيوبت عشان شاشة التحميل
      await Future.sync(() => player.buyVIP(days, price));
      emit(state.copyWith(isLoading: false, successMessage: 'تم تفعيل عضوية VIP بنجاح! 👑'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      _emitError(e.toString());
    }
  }

  void _emitError(String msg) {
    emit(state.copyWith(isLoading: false, errorMessage: msg));
    emit(state.copyWith(errorMessage: '')); // تصفير الخطأ
  }
}