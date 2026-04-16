import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import '../services/black_market_service.dart'; // 🟢 استدعينا الخدمة
import 'black_market_state.dart';
export 'black_market_state.dart';

class BlackMarketCubit extends Cubit<BlackMarketState> {
  final BlackMarketService _blackMarketService = BlackMarketService();

  BlackMarketCubit() : super(BlackMarketState());

  Future<void> buyItem(PlayerProvider player, String itemId, int cost, String currencyType, int amount, String itemName) async {
    if (currencyType == 'cash' && player.cash < cost) {
      _emitError('كاش غير كافي لشراء $itemName!');
      return;
    } else if (currencyType == 'gold' && player.gold < cost) {
      _emitError('ذهب غير كافي لشراء $itemName!');
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));

    try {
      // 🟢 نكلم السيرفر عن طريق ملف الخدمة
      final data = await _blackMarketService.buyItem(
        uid: player.uid!,
        itemId: itemId,
        cost: cost,
        currencyType: currencyType,
        amount: amount,
      );

      if (data['success'] == true) {
        if (currencyType == 'cash') {
          player.removeCash(cost, reason: "شراء من المتجر الأسود");
        } else {
          player.removeGold(cost);
        }
        player.addInventoryItem(itemId, amount);

        emit(state.copyWith(isLoading: false, successMessage: 'تم شراء $itemName بنجاح 🤝'));
        emit(state.copyWith(successMessage: ''));
      } else {
        _emitError('فشلت العملية من السيرفر');
      }
    } catch (e) {
      _emitError('مرفوض من السيرفر: ${e.toString()}');
    }
  }

  Future<void> buyVip(PlayerProvider player, int days, int price) async {
    emit(state.copyWith(isLoading: true, errorMessage: '', successMessage: ''));
    try {
      await Future.sync(() => player.buyVIP(days, price));
      emit(state.copyWith(isLoading: false, successMessage: 'تم تفعيل عضوية VIP بنجاح! 👑'));
      emit(state.copyWith(successMessage: ''));
    } catch (e) {
      _emitError(e.toString());
    }
  }

  void _emitError(String msg) {
    emit(state.copyWith(isLoading: false, errorMessage: msg));
    emit(state.copyWith(errorMessage: ''));
  }
}