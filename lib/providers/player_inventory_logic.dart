// Ø§Ù„Ù…Ø³Ø§Ø±: lib/providers/player_inventory_logic.dart

part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerInventoryLogic on PlayerProvider {

  void buyItem(String itemId, int price, {bool isConsumable = false, String currency = 'cash'}) {
    bool canBuy = currency == 'cash' ? _cash >= price : _gold >= price;
    if (canBuy) {
      if (currency == 'cash') { _cash -= price; } else { _gold -= price; }
      _inventory[itemId] = (_inventory[itemId] ?? 0) + 1;
      _syncWithFirestore(); notifyListeners();
    }
  }

  void useItem(String itemId) {
    if ((_inventory[itemId] ?? 0) > 0) {
      if (GameData.crimeToolsList.contains(itemId)) { _equippedCrimeToolId = (_equippedCrimeToolId == itemId) ? null : itemId; }
      else if (GameData.weaponStats.containsKey(itemId)) { _equippedWeaponId = (_equippedWeaponId == itemId) ? null : itemId; }
      else if (GameData.armorStats.containsKey(itemId)) { _equippedArmorId = (_equippedArmorId == itemId) ? null : itemId; }
      else if (['black_mask', 'silicon_mask'].contains(itemId)) { _equippedMaskId = (_equippedMaskId == itemId) ? null : itemId; }
      else {
        bool isConsumed = false;
        if (itemId == 'medkit') { _health = maxHealth; isConsumed = true; }
        else if (itemId == 'bandage') { _health = min(maxHealth, _health + (maxHealth * 0.25).toInt()); isConsumed = true; }
        else if (itemId == 'steroids') { _energy = maxEnergy; isConsumed = true; }
        else if (itemId == 'coffee') { _courage = maxCourage; isConsumed = true; }
        else if (itemId == 'bribe_small') { reduceHeat(20.0); isConsumed = true; }
        else if (itemId == 'fake_plates') { reduceHeat(40.0); isConsumed = true; }
        else if (itemId == 'bribe_big') { _heat = 0.0; isConsumed = true; }
        else if (itemId == 'vip_7') {
          buyVIP(7, 0); // Ø§Ø³ØªØ¯Ø¹Ø§Ø¡ Ø¯Ø§Ù„Ø© Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù€ VIP Ø¨Ø¯ÙˆÙ† ØªÙƒÙ„ÙØ© Ø°Ù‡Ø¨
          isConsumed = true;
          _showNotification("ðŸ‘‘ ØªÙ… ØªÙØ¹ÙŠÙ„ Ø£Ùˆ ØªÙ…Ø¯ÙŠØ¯ Ø§Ø´ØªØ±Ø§Ùƒ VIP Ù„Ù…Ø¯Ø© 7 Ø£ÙŠØ§Ù…!");
        }
        else if (itemId == 'smoke_bomb') {
          if (_isInPrison) { _isInPrison = false; _prisonReleaseTime = null; _showNotification("ðŸ’¨ Ø§Ø³ØªØ®Ø¯Ù…Øª Ø§Ù„Ù‚Ù†Ø¨Ù„Ø© Ø§Ù„Ø¯Ø®Ø§Ù†ÙŠØ© ÙˆÙ‡Ø±Ø¨Øª Ù…Ù† Ø§Ù„Ø³Ø¬Ù†!"); isConsumed = true; }
          else { _showNotification("Ù„Ø§ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ø³ØªØ®Ø¯Ø§Ù… Ù‡Ø°Ø§ Ø¥Ù„Ø§ ÙÙŠ Ø§Ù„Ø³Ø¬Ù†!"); }
        }
        if (['medkit', 'bandage'].contains(itemId) && _isHospitalized) { _isHospitalized = false; _hospitalReleaseTime = null; _showNotification("ðŸ¥ ØªØ¹Ø§ÙÙŠØª ÙˆØ®Ø±Ø¬Øª Ù…Ù† Ø§Ù„Ù…Ø³ØªØ´ÙÙ‰!"); }
        if (isConsumed) { _inventory[itemId] = _inventory[itemId]! - 1; if (_inventory[itemId] == 0) _inventory.remove(itemId); }
      }
      _syncWithFirestore(); notifyListeners();
    }
  }

  void addItemDirectly(String itemId, {int quantity = 1}) { _inventory[itemId] = (_inventory[itemId] ?? 0) + quantity; _syncWithFirestore(); notifyListeners(); }
  void reduceDurability(String? itemId, double amount) { if (itemId == null || !GameData.crimeToolsList.contains(itemId)) return; _durability[itemId] = max(0, (_durability[itemId] ?? 100.0) - amount); if ((_durability[itemId] ?? 100) < 10) _showNotification("âš ï¸ Ø¹ØªØ§Ø¯ Ø§Ù„Ø¬Ø±ÙŠÙ…Ø© ÙŠØ­ØªØ§Ø¬ Ø¥ØµÙ„Ø§Ø­ ÙÙŠ Ø§Ù„ÙˆØ±Ø´Ø©!"); notifyListeners(); }
  void repairItem(String itemId, int requiredParts) { if (GameData.crimeToolsList.contains(itemId) && _spareParts >= requiredParts && (_durability[itemId] ?? 100) < 100) { _spareParts -= requiredParts; _durability[itemId] = 100.0; _showNotification("ðŸ› ï¸ ØªÙ… Ø¥ØµÙ„Ø§Ø­ Ø§Ù„Ø£Ø¯Ø§Ø© Ø¨Ù†Ø¬Ø§Ø­!"); _syncWithFirestore(); notifyListeners(); } }

  void buyCar(String carId, int price) { if (_cash >= price && !_ownedCars.contains(carId)) { _cash -= price; _ownedCars.add(carId); _activeCarId ??= carId; _syncWithFirestore(); notifyListeners(); } }
  void setActiveCar(String carId) { if (_ownedCars.contains(carId)) { _activeCarId = carId; _syncWithFirestore(); notifyListeners(); } }
  void finishRace(bool won, int reward, int energyCost) { setEnergy(_energy - energyCost); if (won) addCash(reward, reason: "ÙÙˆØ² Ø¨Ø³Ø¨Ø§Ù‚ ðŸŽï¸"); }

  void startChopping() { if ((_inventory['stolen_car'] ?? 0) > 0 && !_isChopping) { _inventory['stolen_car'] = _inventory['stolen_car']! - 1; _isChopping = true; _chopShopEndTime = DateTime.now().add(const Duration(minutes: 30)); _syncWithFirestore(); notifyListeners(); } }
  void collectChoppedCar() { if (_isChopping && _chopShopEndTime != null && DateTime.now().isAfter(_chopShopEndTime!)) { _isChopping = false; _chopShopEndTime = null; addCash(15000, reason: "Ø¨ÙŠØ¹ Ù‚Ø·Ø¹ ØºÙŠØ§Ø± Ù…Ù† Ø§Ù„ØªØ´Ù„ÙŠØ­ ðŸš—"); _spareParts += 15; _showNotification("Ø­ØµÙ„Øª Ø¹Ù„Ù‰ 15 Ù‚Ø·Ø¹Ø© ØºÙŠØ§Ø± Ù„Ù„Ø¥ØµÙ„Ø§Ø­!"); _syncWithFirestore(); notifyListeners(); } }

  void startCrafting(String itemId, int costCash, int durationMinutes) { if (!_isCrafting && _cash >= costCash) { _cash -= costCash; _isCrafting = true; _craftingItemId = itemId; _labEndTime = DateTime.now().add(Duration(minutes: durationMinutes)); _syncWithFirestore(); notifyListeners(); } }
  void collectCraftedItem() { if (_isCrafting && _labEndTime != null && DateTime.now().isAfter(_labEndTime!)) { _isCrafting = false; _labEndTime = null; if (_craftingItemId != null) { _inventory[_craftingItemId!] = (_inventory[_craftingItemId!] ?? 0) + 1; _craftingItemId = null; } _syncWithFirestore(); notifyListeners(); } }
  void addInventoryItem(String itemId, int amount) { _inventory[itemId] = (_inventory[itemId] ?? 0) + amount; _syncWithFirestore(); notifyListeners(); }
}