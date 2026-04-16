import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import 'inventory_state.dart';
export 'inventory_state.dart'; // 🟢 تصدير لتسهيل الاستدعاء

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit() : super(InventoryState());

  // 🟢 دالة استخدام أو تجهيز العنصر
  void useOrEquipItem(PlayerProvider player, String itemId, String itemName, bool isEquipAction, bool currentlyEquipped) {
    try {
      player.useItem(itemId); // الـ Provider يتكفل بالمنطق والسيرفر

      String msg = '';
      if (isEquipAction) {
        msg = currentlyEquipped ? 'تم نزع $itemName 🎒' : 'تم تجهيز $itemName ⚔️';
      } else {
        msg = 'تم استخدام $itemName بنجاح ⚡';
      }

      emit(state.copyWith(message: msg, isError: false));
      emit(state.copyWith(message: '')); // تصفير
    } catch (e) {
      emit(state.copyWith(message: 'حدث خطأ: ${e.toString()}', isError: true));
      emit(state.copyWith(message: '')); // تصفير
    }
  }

  // 🟢 دالة تغيير الاسم
  void changePlayerName(PlayerProvider player, String newName) {
    if (newName.trim().length < 3) {
      emit(state.copyWith(message: 'الاسم يجب أن يكون 3 أحرف على الأقل ⚠️', isError: true));
      emit(state.copyWith(message: ''));
      return;
    }

    try {
      player.updateName(newName.trim()); // الـ Provider يكلم السيرفر ويخصم البطاقة
      emit(state.copyWith(message: 'تم تغيير هويتك إلى $newName بنجاح! 🎭', isError: false));
      emit(state.copyWith(message: ''));
    } catch (e) {
      emit(state.copyWith(message: 'فشل تغيير الاسم: ${e.toString()}', isError: true));
      emit(state.copyWith(message: ''));
    }
  }
}