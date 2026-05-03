// المسار: lib/providers/player_market_logic.dart

part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerMarketLogic on PlayerProvider {

  void depositToBank(int amount) {
    if (_cash >= amount) {
      _cash -= amount;
      _bankBalance += (amount * 0.9).floor();
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void withdrawFromBank(int amount) {
    if (_bankBalance >= amount) {
      _bankBalance -= amount;
      _cash += amount;
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void buyGold(int amount, int currentPrice) {
    int cost = amount * currentPrice;
    if (_cash >= cost) {
      _cash -= cost;
      _gold += amount;
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void sellGold(int amount, int currentPrice) {
    if (_gold >= amount) {
      _cash += amount * currentPrice;
      _gold -= amount;
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void takeLoan(int amount) {
    if (_loanAmount + amount <= maxLoanLimit) {
      if (_loanAmount == 0) _loanTime = DateTime.now();
      _loanAmount += amount;
      _cash += (amount * 0.95).floor();
      _syncWithFirestore();
      notifyListeners();
    }
  }

  bool canRepayLoan() {
    if (_loanTime == null) return true;
    return DateTime.now().difference(_loanTime!).inMinutes >= 5;
  }

  void repayLoan(int amount) {
    if (canRepayLoan() && amount <= _cash && amount <= _loanAmount) {
      _cash -= amount;
      _loanAmount -= amount;
      if (_loanAmount == 0) {
        _loanTime = null;
        _creditScore += 10;
        _showNotification("البنك 🏦: سددت قرضك بالكامل! زادت سمعتك.");
      }
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void startLockedInvestment(int amount, int minutes, double rate) {
    if (_cash >= amount) {
      _cash -= amount;
      _lockedBalance = amount;
      _lockedProfits = (amount * rate).floor();
      _lockedUntil = DateTime.now().add(Duration(minutes: minutes));
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void startWorkContract(String name, int durationMinutes, int salaryPerMinute) {
    if (isUnderContract) return;
    _activeContractName = name;
    _contractSalary = salaryPerMinute;
    _lastContractRewardTime = DateTime.now();
    _contractEndTime = DateTime.now().add(Duration(minutes: durationMinutes));
    _syncWithFirestore();
    notifyListeners();
  }
}