import 'package:flutter_bloc/flutter_bloc.dart';
import 'bank_state.dart';

class BankCubit extends Cubit<BankState> {
  BankCubit() : super(BankState());

  // 🟢 دوال مساعدة نقلناها من الواجهة عشان ننظف كود التصميم
  int calculateAdminFee(int amount) => (amount * 0.05).floor();
  int calculateNetReceive(int amount) => amount - calculateAdminFee(amount);
  int calculateMaxGoldBuyable(int cash, int price) => price > 0 ? (cash / price).floor() : 0;

  // 🟢 دالة موحدة لتنفيذ أي عملية (إيداع، سحب، قروض، استثمار)
  Future<void> executeTransaction(Function transactionTask, String successMsg) async {
    // 1. تشغيل مؤشر التحميل
    emit(BankState(isLoading: true, message: '', isSuccess: false));

    try {
      // 2. تنفيذ العملية (سواء كانت سريعة أو تحتاج وقت من السيرفر)
      await Future.sync(() => transactionTask());

      // 3. إيقاف التحميل وإرسال رسالة النجاح
      emit(BankState(isLoading: false, message: successMsg, isSuccess: true));
    } catch (e) {
      // 4. في حال فشل السيرفر، إيقاف التحميل وعرض الخطأ
      emit(BankState(isLoading: false, message: e.toString(), isSuccess: false));
    }
  }
}