// Ø§Ù„Ù…Ø³Ø§Ø±: lib/providers/player_real_estate_logic.dart

part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerRealEstateLogic on PlayerProvider {

  // ==========================================
  // 1. Ø§Ù„Ø¯Ø®Ù„ Ø§Ù„Ø³Ù„Ø¨ÙŠ (ÙŠØ¸Ù„ ÙƒÙ…Ø§ Ù‡Ùˆ Ù„Ø£Ù†Ù‡ Ù„Ù„Ø¹Ø±Ø¶ ÙˆØ§Ù„Ø­Ø³Ø§Ø¨Ø§Øª ÙÙ‚Ø·)
  // ==========================================
  int getTotalPassiveIncomePerDay() {
    int total = 0;
    _ownedBusinesses.forEach((id, level) {
      total += ((GameData.businessBaseIncome[id] ?? 0) * 12 * level).toInt();
    });
    return total;
  }

  int getPropertyRentIncomePerDay() {
    int total = 0;
    for (var id in _ownedProperties) {
      if (!_listedProperties.contains(id) && !_rentedOutProperties.containsKey(id) && _activePropertyId != id) {
        total += (GameData.propertyRentIncome[id] ?? 0) * 12;
      }
    }
    return total;
  }

  // ==========================================
  // 2. Ø¯ÙˆØ§Ù„ Ø§Ù„Ù…Ù„ÙƒÙŠØ© ÙˆØ§Ù„Ø³ÙƒÙ† Ø§Ù„Ø£Ø³Ø§Ø³ÙŠØ© (Ø´Ø±Ø§Ø¡ Ù…Ù† Ø§Ù„Ø³ÙŠØ±ÙØ±)
  // ==========================================
  Future<void> buyProperty(String id, int price, int happinessGain) async {
    // ØªØ­Ù‚Ù‚ Ø£ÙˆÙ„ÙŠ Ø¨Ø³ÙŠØ· ÙˆØ³Ø±ÙŠØ¹ Ù„ÙƒÙŠ Ù„Ø§ Ù†ÙØªØ¹Ø¨ Ø§Ù„Ø³ÙŠØ±ÙØ± Ø¥Ø°Ø§ ÙƒØ§Ù† Ø§Ù„Ù„Ø§Ø¹Ø¨ Ù…ÙÙ„Ø³Ø§Ù‹ Ø£ØµÙ„Ø§Ù‹
    if (_cash < price) {
      _showNotification("âš ï¸ ÙƒØ§Ø´ ØºÙŠØ± ÙƒØ§ÙÙŠ!");
      return;
    }
    if (_ownedProperties.contains(id)) {
      _showNotification("âš ï¸ Ø£Ù†Øª ØªÙ…Ù„Ùƒ Ù‡Ø°Ø§ Ø§Ù„Ø¹Ù‚Ø§Ø± Ù…Ø³Ø¨Ù‚Ø§Ù‹!");
      return;
    }

    try {
      _showNotification("â³ Ø¬Ø§Ø±ÙŠ ØªÙˆØ«ÙŠÙ‚ Ø§Ù„Ø´Ø±Ø§Ø¡ Ø¹Ø¨Ø± Ø§Ù„Ø³ÙŠØ±ÙØ±...");
      final callable = FirebaseFunctions.instance.httpsCallable('buyRealEstate');
      final response = await callable.call({
        'uid': _uid,
        'propertyId': id,
        'price': price,
        'happinessGain': happinessGain,
      });

      if (response.data['success'] == true) {
        _showNotification("ðŸ  Ù…Ø¨Ø±ÙˆÙƒ! ØªÙ… Ø´Ø±Ø§Ø¡ Ø§Ù„Ø¹Ù‚Ø§Ø± Ø¨Ù†Ø¬Ø§Ø­.");
      }
    } on FirebaseFunctionsException catch (e) {
      _showNotification("âš ï¸ ÙØ´Ù„ Ø§Ù„Ø´Ø±Ø§Ø¡: ${e.message}");
    } catch (e) {
      _showNotification("âš ï¸ Ø­Ø¯Ø« Ø®Ø·Ø£ ÙÙŠ Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø³ÙŠØ±ÙØ±!");
    }
  }

  // ØªØºÙŠÙŠØ± Ø§Ù„Ø³ÙƒÙ† Ù„Ø§ ÙŠÙƒÙ„Ù Ø´ÙŠØ¦Ø§Ù‹ Ù„Ø°Ù„Ùƒ Ù†ØªØ±ÙƒÙ‡ Ù…Ø­Ù„ÙŠØ§Ù‹ ÙƒÙ€ ØªÙØ¶ÙŠÙ„ Ù„Ù„Ø§Ø¹Ø¨
  void setActiveProperty(String id, int happinessGain) {
    bool isMine = _ownedProperties.contains(id) && !_rentedOutProperties.containsKey(id) && !_listedProperties.contains(id);
    bool isRentedByMe = _activeRentedProperty != null && _activeRentedProperty!['id'] == id;

    if (isMine || isRentedByMe) {
      _activePropertyId = id;
      _happiness = happinessGain;
      _syncWithFirestore();
      notifyListeners();
    } else {
      _showNotification("âš ï¸ Ù„Ø§ ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„Ø³ÙƒÙ† ÙÙŠ Ø¹Ù‚Ø§Ø± Ù…Ø¤Ø¬Ø± Ø£Ùˆ Ù…Ø¹Ø±ÙˆØ¶ Ø¨Ø§Ù„Ø³ÙˆÙ‚!");
    }
  }

  // ==========================================
  // 3. Ø¯ÙˆØ§Ù„ Ø³ÙˆÙ‚ Ø§Ù„Ø¥ÙŠØ¬Ø§Ø±Ø§Øª Ø¨ÙŠÙ† Ø§Ù„Ù„Ø§Ø¹Ø¨ÙŠÙ† (P2P) (Ø§Ù„Ø³Ù„Ø·Ø© Ù„Ù„Ø³ÙŠØ±ÙØ±)
  // ==========================================
  Future<void> listPropertyForRent(String propertyId, int dailyPrice, int days) async {
    if (_listedProperties.contains(propertyId) || _rentedOutProperties.containsKey(propertyId)) return;
    try {
      _showNotification("â³ Ø¬Ø§Ø±ÙŠ Ø¹Ø±Ø¶ Ø§Ù„Ø¹Ù‚Ø§Ø± ÙÙŠ Ø§Ù„Ø³ÙˆÙ‚...");
      final callable = FirebaseFunctions.instance.httpsCallable('listPropertyForRent');
      await callable.call({
        'uid': _uid, 'propertyId': propertyId, 'dailyPrice': dailyPrice, 'days': days, 'playerName': _playerName,
      });
      _showNotification("ðŸ“œ ØªÙ… Ø¹Ø±Ø¶ Ø§Ù„Ø¹Ù‚Ø§Ø± Ø¨Ù†Ø¬Ø§Ø­!");
    } catch (e) {
      _showNotification("âš ï¸ Ø­Ø¯Ø« Ø®Ø·Ø£!");
    }
  }

  Future<void> cancelRentalListing(String propertyId) async {
    if (!_listedProperties.contains(propertyId)) return;
    try {
      _showNotification("â³ Ø¬Ø§Ø±ÙŠ Ø³Ø­Ø¨ Ø§Ù„Ø¹Ù‚Ø§Ø±...");
      final callable = FirebaseFunctions.instance.httpsCallable('cancelRentalListing');
      await callable.call({'uid': _uid, 'propertyId': propertyId});
      _showNotification("ðŸš« ØªÙ… Ø³Ø­Ø¨ Ø§Ù„Ø¹Ù‚Ø§Ø± Ù…Ù† Ø§Ù„Ø³ÙˆÙ‚.");
    } catch (e) {
      _showNotification("âš ï¸ Ø­Ø¯Ø« Ø®Ø·Ø£!");
    }
  }

  Future<void> rentPropertyFromMarket(Map<String, dynamic> listing, int happinessGain) async {
    int totalPrice = listing['dailyPrice'] * listing['days'];
    if (_cash < totalPrice) {
      _showNotification("âš ï¸ ÙƒØ§Ø´ ØºÙŠØ± ÙƒØ§ÙÙŠ Ù„Ù„Ø§Ø³ØªØ¦Ø¬Ø§Ø±!");
      return;
    }
    if (_activeRentedProperty != null) {
      _showNotification("âš ï¸ Ø£Ù†Øª Ù…Ø³ØªØ£Ø¬Ø± Ø¹Ù‚Ø§Ø±Ø§Ù‹ Ø­Ø§Ù„ÙŠØ§Ù‹! Ø§Ù†ØªØ¸Ø± Ø§Ù†ØªÙ‡Ø§Ø¡ Ø§Ù„Ø¹Ù‚Ø¯.");
      return;
    }

    try {
      _showNotification("â³ Ø¬Ø§Ø±ÙŠ ØªÙˆÙ‚ÙŠØ¹ Ø¹Ù‚Ø¯ Ø§Ù„Ø¥ÙŠØ¬Ø§Ø±...");
      final callable = FirebaseFunctions.instance.httpsCallable('rentPropertyFromMarket');
      final response = await callable.call({
        'uid': _uid,
        'listingId': '${listing['ownerId']}_${listing['propertyId']}',
        'ownerId': listing['ownerId'],
        'propertyId': listing['propertyId'],
        'dailyPrice': listing['dailyPrice'],
        'days': listing['days'],
        'happinessGain': happinessGain,
        'renterName': _playerName,
      });

      if (response.data['success'] == true) {
        _showNotification("ðŸ  Ù…Ø¨Ø±ÙˆÙƒ! Ø§Ø³ØªØ£Ø¬Ø±Øª Ø§Ù„Ø¹Ù‚Ø§Ø± Ù„Ù…Ø¯Ø© ${response.data['days']} ÙŠÙˆÙ….");
      }
    } on FirebaseFunctionsException catch (e) {
      _showNotification("âš ï¸ ÙØ´Ù„ Ø§Ù„Ø§Ø³ØªØ¦Ø¬Ø§Ø±: ${e.message}");
    } catch (e) {
      _showNotification("âš ï¸ Ø­Ø¯Ø« Ø®Ø·Ø£: Ù‚Ø¯ ÙŠÙƒÙˆÙ† Ø§Ù„Ø¹Ù‚Ø§Ø± Ø£ÙØ¬Ø± Ù„Ù„Ø§Ø¹Ø¨ Ø¢Ø®Ø± Ù„Ù„ØªÙˆ!");
    }
  }

  Future<void> cancelRentedProperty() async {
    if (_activeRentedProperty == null) return;
    try {
      _showNotification("â³ Ø¬Ø§Ø±ÙŠ ÙØ³Ø® Ø§Ù„Ø¹Ù‚Ø¯...");
      final callable = FirebaseFunctions.instance.httpsCallable('cancelRentedProperty');
      await callable.call({'uid': _uid});
      _showNotification("ØªÙ… ÙØ³Ø® Ø§Ù„Ø¹Ù‚Ø¯ ÙˆØ¹Ø§Ø¯ Ø§Ù„Ø¹Ù‚Ø§Ø± Ù„Ù…Ø§Ù„ÙƒÙ‡ Ø§Ù„Ø£ØµÙ„ÙŠ.");
    } catch (e) {
      _showNotification("âš ï¸ Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ù…Ø­Ø§ÙˆÙ„Ø© ÙØ³Ø® Ø§Ù„Ø¹Ù‚Ø¯!");
    }
  }

  // ==========================================
  // 4. Ø§Ù„Ù…Ø´Ø§Ø±ÙŠØ¹ Ø§Ù„ØªØ¬Ø§Ø±ÙŠØ© (Ø´Ø±Ø§Ø¡ ÙˆØªØ±Ù‚ÙŠØ© Ù…Ù† Ø§Ù„Ø³ÙŠØ±ÙØ±)
  // ==========================================
  Future<void> buyBusiness(String id, int price) async {
    if (_cash < price) { _showNotification("âš ï¸ ÙƒØ§Ø´ ØºÙŠØ± ÙƒØ§ÙÙŠ!"); return; }
    try {
      _showNotification("â³ Ø¬Ø§Ø±ÙŠ Ø§Ø³ØªØ®Ø±Ø§Ø¬ Ø§Ù„ØªØµØ§Ø±ÙŠØ­ Ù„Ù„Ù…Ø´Ø±ÙˆØ¹...");
      final callable = FirebaseFunctions.instance.httpsCallable('manageBusiness');
      await callable.call({'uid': _uid, 'businessId': id, 'cost': price, 'actionType': 'buy'});
      _showNotification("ðŸ¢ Ù…Ø¨Ø±ÙˆÙƒ! ØªÙ… Ø´Ø±Ø§Ø¡ Ø§Ù„Ù…Ø´Ø±ÙˆØ¹ Ø§Ù„ØªØ¬Ø§Ø±ÙŠ Ø¨Ù†Ø¬Ø§Ø­.");
    } on FirebaseFunctionsException catch (e) {
      _showNotification("âš ï¸ ${e.message}");
    } catch (e) {
      _showNotification("âš ï¸ ÙØ´Ù„ Ø§Ù„Ø´Ø±Ø§Ø¡ Ø¨Ø³Ø¨Ø¨ Ø®Ø·Ø£ ÙÙŠ Ø§Ù„Ø§ØªØµØ§Ù„.");
    }
  }

  Future<void> upgradeBusiness(String id, int upgradeCost) async {
    if (_cash < upgradeCost) { _showNotification("âš ï¸ ÙƒØ§Ø´ ØºÙŠØ± ÙƒØ§ÙÙŠ Ù„Ù„ØªØ±Ù‚ÙŠØ©!"); return; }
    try {
      _showNotification("â³ Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ±Ù‚ÙŠØ© ÙˆØ§Ù„ØªØ·ÙˆÙŠØ±...");
      final callable = FirebaseFunctions.instance.httpsCallable('manageBusiness');
      await callable.call({'uid': _uid, 'businessId': id, 'cost': upgradeCost, 'actionType': 'upgrade'});
      _showNotification("ðŸ“ˆ ØªÙ… ØªØ±Ù‚ÙŠØ© Ø§Ù„Ù…Ø´Ø±ÙˆØ¹ Ø§Ù„ØªØ¬Ø§Ø±ÙŠ Ø¨Ù†Ø¬Ø§Ø­!");
    } on FirebaseFunctionsException catch (e) {
      _showNotification("âš ï¸ ${e.message}");
    } catch (e) {
      _showNotification("âš ï¸ ÙØ´Ù„ Ø§Ù„ØªØ±Ù‚ÙŠØ© Ø¨Ø³Ø¨Ø¨ Ø®Ø·Ø£ ÙÙŠ Ø§Ù„Ø§ØªØµØ§Ù„.");
    }
  }
}