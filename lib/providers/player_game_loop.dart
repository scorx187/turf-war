// المسار: lib/providers/player_game_loop.dart
part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerGameLoop on PlayerProvider {

  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLoading) return;
      bool changed = false;

      if (timer.tick % 5 == 0) checkNewTitles();

      changed |= _tickBuffExpiry();
      changed |= _tickCooldowns();
      changed |= _tickPropertyExpiry();
      changed |= _tickHealthRegen();
      changed |= _tickPassiveIncome();
      changed |= _tickLoanInterest();
      changed |= _tickPrisonRelease();
      changed |= _tickHospitalRelease();
      changed |= _tickInvestmentUnlock();
      changed |= _tickContractSalary();
      if (timer.tick % 60 == 0) changed |= _tickDurabilityRegen();

      if (_heat > 0) { _heat = max(0, _heat - 0.0278); changed = true; }
      if (timer.tick % (isVIP ? 36 : 72) == 0 && _prestige < maxPrestige) { _prestige++; changed = true; }
      if (energy < maxEnergy || courage < maxCourage) changed = true;

      if (changed) notifyListeners();
    });
  }

  bool _tickBuffExpiry() {
    bool changed = false;
    if (_activeSteroidEndTime != null && secureNow.isAfter(_activeSteroidEndTime!)) {
      _activeSteroidEndTime = null;
      changed = true;
    }
    if (_coachEndTime != null && secureNow.isAfter(_coachEndTime!)) {
      _activeCoach = null;
      _coachEndTime = null;
      changed = true;
    }
    return changed;
  }

  bool _tickCooldowns() {
    bool changed = false;
    int steroidCooldown = _inventory['steroid_cooldown'] ?? 0;
    if (steroidCooldown > 0 && secureNow.millisecondsSinceEpoch > steroidCooldown) {
      _inventory.remove('steroid_cooldown');
      if (_uid != null) {
        _firestore.collection('players').doc(_uid).update({'inventory.steroid_cooldown': FieldValue.delete()}).catchError((_) {});
      }
      _sendSystemNotification("سوق المنشطات 💉", "انتهت فترة الراحة للمنشطات! يمكنك شراء وحقن جرعة جديدة الآن.", "info");
      changed = true;
    }
    int coachCooldown = _inventory['coach_cooldown'] ?? 0;
    if (coachCooldown > 0 && secureNow.millisecondsSinceEpoch > coachCooldown) {
      _inventory.remove('coach_cooldown');
      if (_uid != null) {
        _firestore.collection('players').doc(_uid).update({'inventory.coach_cooldown': FieldValue.delete()}).catchError((_) {});
      }
      _sendSystemNotification("صالة التدريب 🥊", "المدربون متاحون الآن للتعاقد من جديد!", "info");
      changed = true;
    }
    return changed;
  }

  bool _tickPropertyExpiry() {
    bool changed = false;
    if (_activeRentedProperty != null && secureNow.isAfter(DateTime.parse(_activeRentedProperty!['expire']))) {
      String propId = _activeRentedProperty!['id'];
      _activeRentedProperty = null;
      if (_activePropertyId == propId) { _activePropertyId = null; _happiness = 0; }
      _sendSystemNotification("إيجار السكن 🏠", "انتهى عقد إيجار سكنك الحالي!", "home");
      changed = true;
    }
    if (_rentedOutProperties.isNotEmpty) {
      List<String> expired = [];
      _rentedOutProperties.forEach((id, data) {
        if (secureNow.isAfter(DateTime.parse(data['expire']))) expired.add(id);
      });
      for (var id in expired) {
        _rentedOutProperties.remove(id);
        _sendSystemNotification("إدارة الأملاك 🔑", "انتهت مدة إيجار عقارك ($id) وعاد إليك!", "key");
        changed = true;
      }
    }
    return changed;
  }

  bool _tickHealthRegen() {
    if (_health >= maxHealth) { _fractionalHealth = 0.0; return false; }
    double healthRegenTime = 1800.0 + (maxHealth * 0.0005);
    _fractionalHealth += maxHealth / healthRegenTime;
    if (_fractionalHealth >= 1.0) {
      int healAmount = _fractionalHealth.toInt();
      _health = min(maxHealth, _health + healAmount);
      _fractionalHealth -= healAmount;
      if (_health >= maxHealth && _isHospitalized) {
        _isHospitalized = false;
        _hospitalReleaseTime = null;
        _sendSystemNotification("المستشفى 🏥", "تعافيت بالكامل وخرجت من المستشفى!", "hospital");
      }
      return true;
    }
    return false;
  }

  bool _tickPassiveIncome() {
    if (_lastPassiveIncomeTime == null) return false;
    if (secureNow.difference(_lastPassiveIncomeTime!).inHours < 24) return false;
    int passiveIncome = getTotalPassiveIncomePerDay() + getPropertyRentIncomePerDay();
    if (passiveIncome > 0) {
      _cash += passiveIncome;
      _sendSystemNotification("الأرباح اليومية 🏢", "استلمت أرباحك اليومية: \$${_formatWithCommas(passiveIncome)}", "money");
    }
    _lastPassiveIncomeTime = _lastPassiveIncomeTime!.add(const Duration(hours: 24));
    return true;
  }

  bool _tickDurabilityRegen() {
    bool changed = false;
    for (var tool in GameData.crimeToolsList) {
      if ((_durability[tool] ?? 100) < 100) {
        _durability[tool] = min(100.0, (_durability[tool] ?? 100) + 1.0);
        changed = true;
      }
    }
    return changed;
  }

  bool _tickLoanInterest() {
    if (_loanAmount <= 0 || _loanTime == null) return false;
    if (secureNow.difference(_loanTime!).inHours < 2) return false;
    _loanAmount = (_loanAmount * 1.1).floor();
    _loanTime = secureNow;
    _sendSystemNotification("البنك 🏦", "تمت إضافة فوائد 10% على قرضك لتأخرك في السداد!", "bank");
    return true;
  }

  bool _tickPrisonRelease() {
    if (!_isInPrison || _prisonReleaseTime == null) return false;
    if (!secureNow.isAfter(_prisonReleaseTime!)) return false;
    _isInPrison = false;
    _prisonReleaseTime = null;
    _notificationStream.add("إفراج 🔓|تم الإفراج عنك من السجن بعد انتهاء مدة عقوبتك.");
    return true;
  }

  bool _tickHospitalRelease() {
    if (!_isHospitalized || _hospitalReleaseTime == null) return false;
    if (!secureNow.isAfter(_hospitalReleaseTime!)) return false;
    _isHospitalized = false;
    _hospitalReleaseTime = null;
    _health = (maxHealth * 0.25).toInt();
    _sendSystemNotification("المستشفى 🏥", "تم خروجك من المستشفى!", "hospital");
    return true;
  }

  bool _tickInvestmentUnlock() {
    if (_lockedUntil == null || !secureNow.isAfter(_lockedUntil!)) return false;
    int total = _lockedBalance + _lockedProfits;
    _bankBalance += total;
    _lockedBalance = 0;
    _lockedProfits = 0;
    _lockedUntil = null;
    _sendSystemNotification("الاستثمار 📈", "انتهى الاستثمار! استلمت $total كاش", "invest");
    return true;
  }

  bool _tickContractSalary() {
    if (!isUnderContract || _lastContractRewardTime == null) return false;
    if (secureNow.difference(_lastContractRewardTime!).inMinutes < 1) return false;
    _cash += _contractSalary;
    _lastContractRewardTime = secureNow;
    _addTransaction("راتب عقد: $_activeContractName", _contractSalary, true);
    _workXP += 5;
    if (_workXP >= workXPToNextLevel) { _workXP -= workXPToNextLevel; _workLevel++; }
    return true;
  }
}
