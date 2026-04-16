import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/bank_service.dart';
import '../providers/player_provider.dart';
import 'bank_state.dart';
export 'bank_state.dart';

class BankCubit extends Cubit<BankState> {
  final BankService _bankService = BankService();

  BankCubit() : super(BankState());

  int calculateAdminFee(int amount) => (amount * 0.05).floor();
  int calculateNetReceive(int amount) => amount - calculateAdminFee(amount);
  int calculateMaxGoldBuyable(int cash, int price) => price > 0 ? (cash / price).floor() : 0;

  Future<void> executeBankAction({
    required Future<void> Function() serverTask,
    required Function() localUpdateTask,
    required String successMsg,
  }) async {
    emit(BankState(isLoading: true, message: '', isSuccess: false));
    try {
      await serverTask();
      localUpdateTask();
      emit(BankState(isLoading: false, message: successMsg, isSuccess: true));
    } catch (e) {
      emit(BankState(isLoading: false, message: e.toString(), isSuccess: false));
    }
  }

  void deposit(PlayerProvider player, int amount) {
    executeBankAction(
      serverTask: () => _bankService.deposit(uid: player.uid!, amount: amount),
      localUpdateTask: () => player.removeCash(amount, reason: 'إيداع بنكي'),
      successMsg: 'تم إيداع \$$amount بنجاح!',
    );
  }

  void withdraw(PlayerProvider player, int amount) {
    executeBankAction(
      serverTask: () => _bankService.withdraw(uid: player.uid!, amount: amount),
      localUpdateTask: () => player.addCash(amount, reason: 'سحب بنكي'),
      successMsg: 'تم سحب \$$amount بنجاح!',
    );
  }

  void buyGold(PlayerProvider player, int amount, int price) {
    executeBankAction(
      serverTask: () => _bankService.buyGold(uid: player.uid!, amount: amount, price: price),
      localUpdateTask: () {
        player.removeCash(amount * price, reason: 'شراء ذهب');
        player.addGold(amount);
      },
      successMsg: 'تم شراء $amount سبيكة ذهب!',
    );
  }

  void sellGold(PlayerProvider player, int amount, int price) {
    executeBankAction(
      serverTask: () => _bankService.sellGold(uid: player.uid!, amount: amount, price: price),
      localUpdateTask: () {
        player.removeGold(amount);
        player.addCash(amount * price, reason: 'بيع ذهب');
      },
      successMsg: 'تم بيع $amount سبيكة ذهب بنجاح!',
    );
  }

  void takeLoan(PlayerProvider player, int amount) {
    int netReceive = calculateNetReceive(amount);
    executeBankAction(
      serverTask: () => _bankService.takeLoan(uid: player.uid!, amount: amount),
      localUpdateTask: () => player.addCash(netReceive, reason: 'قرض بنكي'),
      successMsg: 'تم استلام القرض بنجاح!',
    );
  }

  void repayLoan(PlayerProvider player, int amount) {
    executeBankAction(
      serverTask: () => _bankService.repayLoan(uid: player.uid!, amount: amount),
      localUpdateTask: () => player.removeCash(amount, reason: 'سداد قرض'),
      successMsg: 'تم سداد الدفعة وتحسين سمعتك!',
    );
  }

  void startLockedInvestment(PlayerProvider player, int amount, int minutes, double rate) {
    executeBankAction(
      serverTask: () => _bankService.startLockedInvestment(uid: player.uid!, amount: amount, minutes: minutes, rate: rate),
      localUpdateTask: () => player.removeCash(amount, reason: 'استثمار مقيد'),
      successMsg: 'تم تجميد مبلغ الاستثمار بنجاح!',
    );
  }
}