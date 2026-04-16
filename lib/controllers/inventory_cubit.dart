import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import '../services/inventory_service.dart'; // 🟢 تم ربط الخدمة الجديدة
import 'inventory_state.dart';
export 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryService _inventoryService = InventoryService();

  InventoryCubit() : super(InventoryState());

  Future<void> useOrEquipItem(PlayerProvider player, String itemId, String itemName, bool isEquipAction, bool currentlyEquipped) async {
    try {
      if (isEquipAction) {
        // 🟢 التجهيز (أسلحة ودروع) يتم محلياً لأنه مجرد لبس/نزع وما يهم السيرفر لحظياً
        player.useItem(itemId);
        String msg = currentlyEquipped ? 'تم نزع $itemName 🎒' : 'تم تجهيز $itemName ⚔️';
        emit(state.copyWith(message: msg, isError: false));
        emit(state.copyWith(message: ''));
      } else {
        // 🟢 الاستهلاك (منشطات، قهوة) يروح للسيرفر عشان الأمان والمزامنة الفورية
        emit(state.copyWith(message: 'جاري استخدام $itemName... ⏳', isError: false));

        await _inventoryService.consumeItem(uid: player.uid!, itemId: itemId);

        // بعد ما ينجح السيرفر، نحدث الشاشة
        player.useItem(itemId);

        emit(state.copyWith(message: 'تم استخدام $itemName بنجاح ⚡', isError: false));
        emit(state.copyWith(message: ''));
      }
    } catch (e) {
      emit(state.copyWith(message: 'حدث خطأ: ${e.toString()}', isError: true));
      emit(state.copyWith(message: ''));
    }
  }

  void changePlayerName(PlayerProvider player, String newName) {
    if (newName.trim().length < 3) {
      emit(state.copyWith(message: 'الاسم يجب أن يكون 3 أحرف على الأقل ⚠️', isError: true));
      emit(state.copyWith(message: ''));
      return;
    }

    try {
      player.updateName(newName.trim());
      emit(state.copyWith(message: 'تم تغيير هويتك إلى $newName بنجاح! 🎭', isError: false));
      emit(state.copyWith(message: ''));
    } catch (e) {
      emit(state.copyWith(message: 'فشل تغيير الاسم: ${e.toString()}', isError: true));
      emit(state.copyWith(message: ''));
    }
  }
}