// Ø§Ù„Ù…Ø³Ø§Ø±: lib/providers/player_actions_logic.dart
part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerActionsLogic on PlayerProvider {

  void putInPrison(int minutes, String crimeName, int bailCost) {
    _isInPrison = true;
    _prisonReleaseTime = secureNow.add(Duration(minutes: minutes));
    _playerBailCost = bailCost;
    _lastCrimeName = crimeName;
    _syncWithFirestore();
    notifyListeners();
  }

  bool attemptEscape() {
    if (courage < 10 || !_isInPrison) return false;
    _courage = courage - 10;
    _lastCourageUpdate = DateTime.now();
    bool success = Random().nextDouble() < 0.3;
    if (success) {
      _isInPrison = false;
      _prisonReleaseTime = null;
      _notificationStream.add("Ù‡Ø±ÙˆØ¨ Ù†Ø§Ø¬Ø­ ðŸƒâ€â™‚ï¸|Ù„Ù‚Ø¯ ØªÙ…ÙƒÙ†Øª Ù…Ù† Ø§Ù„Ù‡Ø±ÙˆØ¨ Ù…Ù† Ø§Ù„Ø³Ø¬Ù† Ø¨Ù†Ø¬Ø§Ø­!");
    }
    _syncWithFirestore();
    notifyListeners();
    return success;
  }

  void addEnergy(int amount) {
    _energy = min(maxEnergy, energy + amount);
    _lastEnergyUpdate = DateTime.now();
    _syncWithFirestore();
    notifyListeners();
  }

  void addBonusPerkPoint(int amount) {
    _bonusPerkPoints += amount;
    _syncWithFirestore();
    notifyListeners();
  }

  void toggleSpecialItem(String itemId) {
    if (_equippedSpecialId == itemId) {
      _equippedSpecialId = null;
    } else {
      _equippedSpecialId = itemId;
    }
    _syncWithFirestore();
    notifyListeners();
  }

  void travelToCity(String city, int price) {
    if (_cash >= price) {
      _cash -= price;
      _currentCity = city;
      _syncWithFirestore();
      notifyListeners();
      _sendSystemNotification("Ø§Ù„Ø³ÙØ± âœˆï¸", "Ù‡Ø¨Ø·Øª Ø·Ø§Ø¦Ø±ØªÙƒ Ø¨Ø³Ù„Ø§Ù… ÙÙŠ $city!", "info");
    }
  }

  void updateBio(String newBio) {
    if (newBio.length <= 150) {
      _bio = newBio;
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void increaseHeat(double amount) { _heat = min(100, _heat + amount); notifyListeners(); }
  void reduceHeat(double amount) { _heat = max(0, _heat - amount); notifyListeners(); }

  void addCash(int amount, {String reason = "Ù…ÙƒØ§ÙØ£Ø©", String? senderUid}) {
    _cash += amount;
    _addTransaction(reason, amount, true, senderUid: senderUid);
    _syncWithFirestore();
    notifyListeners();
  }

  void removeCash(int amount, {String reason = "Ø®ØµÙ…", String? senderUid}) {
    _cash = max(0, _cash - amount);
    _addTransaction(reason, amount, false, senderUid: senderUid);
    _syncWithFirestore();
    notifyListeners();
  }

  void addGold(int amount) { _gold += amount; _syncWithFirestore(); notifyListeners(); }
  void removeGold(int amount) { _gold = max(0, _gold - amount); _syncWithFirestore(); notifyListeners(); }

  void updateName(String newName) {
    if (_inventory.containsKey('name_change_card') && _inventory['name_change_card']! > 0) {
      _playerName = newName;
      _inventory['name_change_card'] = _inventory['name_change_card']! - 1;
      if (_inventory['name_change_card'] == 0) _inventory.remove('name_change_card');
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void addWorkXP(int amount) {
    _workXP += amount;
    if (_workXP >= workXPToNextLevel) {
      _workXP -= workXPToNextLevel;
      _workLevel++;
    }
    _syncWithFirestore();
    notifyListeners();
  }

  void addCrimeXP(int amount) {
    _crimeXP += amount;
    if (_crimeXP >= xpToNextLevel) {
      _crimeXP -= xpToNextLevel;
      _crimeLevel++;
      _notificationStream.add("ØªØ±Ù‚ÙŠØ© ðŸ”«|ØªÙ‡Ø§Ù†ÙŠÙ†Ø§! ÙˆØµÙ„Øª Ù„Ù„Ù…Ø³ØªÙˆÙ‰ $_crimeLevel ÙÙŠ Ø§Ù„Ø¬Ø±ÙŠÙ…Ø©");
    }
    _syncWithFirestore();
    notifyListeners();
  }

  void buyVIP(int days, int cost) {
    if (_gold >= cost) {
      _gold -= cost;
      _totalVipDays += days;
      DateTime start = isVIP ? _vipUntil! : secureNow;
      _vipUntil = start.add(Duration(days: days));
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void incrementLabCrafts() { _totalLabCrafts++; _syncWithFirestore(); notifyListeners(); }
  void incrementLuckyWheelSpins() { _luckyWheelSpins++; _syncWithFirestore(); notifyListeners(); }

  void _addTransaction(String title, int amount, bool isPositive, {String? senderUid}) {
    _transactions.insert(0, Transaction(title: title, amount: amount, date: secureNow, isPositive: isPositive, senderUid: senderUid));
    if (_transactions.length > 20) _transactions.removeLast();
  }

  void updateTitle(String newTitle) {
    _selectedTitle = newTitle;
    _syncWithFirestore();
    notifyListeners();
  }

  Future<void> resetPlayerData() async {
    _cash = 500; _gold = 0; _bankBalance = 0; _energy = 100; _courage = 30; _prestige = 100; _baseStrength = 5; _baseDefense = 5; _baseSkill = 5; _baseSpeed = 5;
    _ownedProperties = []; _activePropertyId = null; _ownedBusinesses = {}; _happiness = 0; _inventory = {'name_change_card': 1};
    _equippedWeaponId = null; _equippedArmorId = null; _equippedMaskId = null; _equippedSpecialId = null; _vipUntil = null; _totalVipDays = 0; _totalLabCrafts = 0; _luckyWheelSpins = 0; _unlockedTitlesList = [];
    _isHospitalized = false; _hospitalReleaseTime = null; _crimeLevel = 1; _workLevel = 1; _crimeXP = 0; _workXP = 0; _isInPrison = false; _prisonReleaseTime = null; _lockedBalance = 0; _lockedProfits = 0; _lockedUntil = null;
    _arenaLevel = 1; _loanAmount = 0; _creditScore = 0; _loanTime = null; _gangName = null; _gangRank = "Ø¹Ø¶Ùˆ"; _gangContribution = 0; _gangWarWins = 0; _territoryOwners = {};
    crimeSuccessCountsMap = {}; _transactions = []; _chopShopEndTime = null; _isChopping = false; _labEndTime = null; _isCrafting = false; _craftingItemId = null;
    _heat = 0.0; _spareParts = 0; _durability = {}; _equippedCrimeToolId = null; _bio = "Ù„Ø§ ÙŠÙˆØ¬Ø¯ ÙˆØµÙ Ø­Ø§Ù„ÙŠØ§Ù‹... Ø±Ø¬Ù„ Ø£ÙØ¹Ø§Ù„ Ù„Ø§ Ø£Ù‚ÙˆØ§Ù„."; _profilePicUrl = null; _backgroundPicUrl = null; _currentCity = 'Ù…Ù„Ø§Ø°';
    _listedProperties = []; _rentedOutProperties = {}; _activeRentedProperty = null; _lastPassiveIncomeTime = secureNow;
    _activeSteroidEndTime = null; _activeCoach = null; _coachEndTime = null; _pvpWins = 0; _totalStolenCash = 0; _perks = {}; _selectedTitle = null; _baseMaxHealth = 100; _bonusPerkPoints = 0;
    _lastEnergyUpdate = DateTime.now();
    _lastCourageUpdate = DateTime.now();
    await _syncWithFirestore();
    notifyListeners();
  }

  void upgradePerk(String perkId) {
    int currentLvl = _perks[perkId] ?? 0;
    int maxLvl = GameData.perksList.firstWhere((p) => p['id'] == perkId)['maxLevel'];
    if (currentLvl < maxLvl && unspentSkillPoints > 0) {
      _perks[perkId] = currentLvl + 1;
      _syncWithFirestore();
      notifyListeners();
      _sendSystemNotification("Ø´Ø¬Ø±Ø© Ø§Ù„Ø§Ù…ØªÙŠØ§Ø²Ø§Øª â­", "ØªÙ… ØªÙØ¹ÙŠÙ„ Ø§Ù„Ø§Ù…ØªÙŠØ§Ø² Ø¨Ù†Ø¬Ø§Ø­!", "star");
    } else {
      _sendSystemNotification("Ù†Ù‚Ø§Ø· ØºÙŠØ± ÙƒØ§ÙÙŠØ© âš ï¸", "Ø­Ù‚Ù‚ Ø§Ù„Ù…Ø²ÙŠØ¯ Ù…Ù† Ø§Ù„Ø£Ù„Ù‚Ø§Ø¨ Ù„Ø¬Ù…Ø¹ Ø§Ù„Ù†Ù‚Ø§Ø·.", "warning");
    }
  }

  void releaseFromHospital() {
    _isHospitalized = false;
    _hospitalReleaseTime = null;
    notifyListeners();
    _syncWithFirestore();
  }

  void releaseFromPrison() {
    _isInPrison = false;
    _prisonReleaseTime = null;
    notifyListeners();
  }

  void setHeat(double value) {
    _heat = value;
    if (_heat < 0) _heat = 0;
    notifyListeners();
    _syncWithFirestore();
  }
}
