// المسار: lib/providers/player_real_estate_logic.dart

part of 'player_provider.dart'; // 🟢 هذا السطر السحري يربطه بالملف الأساسي

extension PlayerRealEstateLogic on PlayerProvider {

  // ==========================================
  // 1. دوال الدخل والأرباح اليومية
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
  // 2. دوال الملكية والسكن الأساسية
  // ==========================================
  void buyProperty(String id, int price, int happinessGain) {
    if (_cash >= price && !_ownedProperties.contains(id)) {
      _cash -= price;
      _ownedProperties.add(id);
      if (_activePropertyId == null && _activeRentedProperty == null) {
        setActiveProperty(id, happinessGain);
      }
      _syncWithFirestore();
      notifyListeners();
    }
  }

  void setActiveProperty(String id, int happinessGain) {
    bool isMine = _ownedProperties.contains(id) && !_rentedOutProperties.containsKey(id) && !_listedProperties.contains(id);
    bool isRentedByMe = _activeRentedProperty != null && _activeRentedProperty!['id'] == id;

    if (isMine || isRentedByMe) {
      _activePropertyId = id;
      _happiness = happinessGain;
      _syncWithFirestore();
      notifyListeners();
    } else {
      _showNotification("⚠️ لا يمكنك السكن في عقار مؤجر أو معروض بالسوق!");
    }
  }

  // ==========================================
  // 3. دوال سوق الإيجارات بين اللاعبين (P2P)
  // ==========================================
  Future<void> listPropertyForRent(String propertyId, int dailyPrice, int days) async {
    if (_listedProperties.contains(propertyId) || _rentedOutProperties.containsKey(propertyId)) return;

    if (_activePropertyId == propertyId) {
      _activePropertyId = null;
      _happiness = 0;
    }

    _listedProperties.add(propertyId);
    _syncWithFirestore();
    notifyListeners();

    await _firestore.collection('property_rentals').doc('${_uid}_$propertyId').set({
      'ownerId': _uid,
      'ownerName': _playerName,
      'propertyId': propertyId,
      'dailyPrice': dailyPrice,
      'days': days,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _showNotification("تم عرض العقار في سوق الإيجارات بنجاح!");
  }

  Future<void> cancelRentalListing(String propertyId) async {
    if (_listedProperties.contains(propertyId)) {
      _listedProperties.remove(propertyId);
      _syncWithFirestore();
      notifyListeners();
      await _firestore.collection('property_rentals').doc('${_uid}_$propertyId').delete();
      _showNotification("تم سحب العقار من السوق.");
    }
  }

  Future<void> rentPropertyFromMarket(Map<String, dynamic> listing, int happinessGain) async {
    int totalPrice = listing['dailyPrice'] * listing['days'];
    if (_cash < totalPrice) {
      _showNotification("⚠️ كاش غير كافي لاستئجار العقار!");
      return;
    }
    if (_activeRentedProperty != null) {
      _showNotification("⚠️ أنت مستأجر عقاراً حالياً! انتظر انتهاء العقد.");
      return;
    }

    try {
      final listingRef = _firestore.collection('property_rentals').doc('${listing['ownerId']}_${listing['propertyId']}');
      final ownerRef = _firestore.collection('players').doc(listing['ownerId']);
      final meRef = _firestore.collection('players').doc(_uid);

      DateTime expireDate = DateTime.now().add(Duration(days: listing['days']));

      await _firestore.runTransaction((transaction) async {
        final listingSnap = await transaction.get(listingRef);
        if (!listingSnap.exists) throw Exception("العقار لم يعد متاحاً!");
        final ownerSnap = await transaction.get(ownerRef);

        transaction.update(meRef, {
          'cash': FieldValue.increment(-totalPrice),
          'activeRentedProperty': {
            'id': listing['propertyId'],
            'expire': expireDate.toIso8601String(),
            'ownerId': listing['ownerId'],
            'ownerName': listing['ownerName'],
          }
        });

        if (ownerSnap.exists) {
          transaction.update(ownerRef, {
            'cash': FieldValue.increment(totalPrice),
            'rentedOutProperties.${listing['propertyId']}': {
              'expire': expireDate.toIso8601String(),
              'renterId': _uid,
              'renterName': _playerName
            },
            'listedProperties': FieldValue.arrayRemove([listing['propertyId']])
          });
        }
        transaction.delete(listingRef);
      });

      _cash -= totalPrice;
      _activeRentedProperty = {
        'id': listing['propertyId'],
        'expire': expireDate.toIso8601String(),
        'ownerId': listing['ownerId'],
        'ownerName': listing['ownerName'],
      };

      setActiveProperty(listing['propertyId'], happinessGain);
      _addTransaction("استئجار عقار", totalPrice, false);
      _showNotification("🏠 مبروك! استأجرت العقار لمدة ${listing['days']} يوم.");
      notifyListeners();
    } catch (e) {
      _showNotification("⚠️ حدث خطأ: العقار تم استئجاره من لاعب آخر للتو!");
    }
  }

  Future<void> cancelRentedProperty() async {
    if (_activeRentedProperty == null) return;

    String propId = _activeRentedProperty!['id'];
    String ownerId = _activeRentedProperty!['ownerId'] ?? '';

    if (ownerId.isNotEmpty) {
      try {
        final ownerRef = _firestore.collection('players').doc(ownerId);
        final meRef = _firestore.collection('players').doc(_uid);

        await _firestore.runTransaction((transaction) async {
          final ownerSnap = await transaction.get(ownerRef);
          if (ownerSnap.exists) {
            transaction.update(ownerRef, {
              'rentedOutProperties.$propId': FieldValue.delete(),
            });
          }
          transaction.update(meRef, {
            'activeRentedProperty': FieldValue.delete(),
          });
        });
      } catch (e) {
        debugPrint("Error canceling rent: $e");
      }
    } else {
      await _firestore.collection('players').doc(_uid).update({
        'activeRentedProperty': FieldValue.delete(),
      });
    }

    _activeRentedProperty = null;
    if (_activePropertyId == propId) {
      _activePropertyId = null;
      _happiness = 0;
    }

    _showNotification("تم فسخ العقد! خسرت المبلغ المدفوع وعاد العقار لمالكه الأصلي.");
    _syncWithFirestore();
    notifyListeners();
  }

  // ==========================================
  // 4. المشاريع التجارية
  // ==========================================
  void buyBusiness(String id, int price) {
    if (_cash >= price && !_ownedBusinesses.containsKey(id)) {
      _cash -= price;
      _ownedBusinesses[id] = 1;
      _addTransaction("شراء مشروع تجاري", price, false);
      _syncWithFirestore();
      notifyListeners();
    } else {
      _showNotification("⚠️ كاش غير كافي لشراء المشروع!");
    }
  }

  void upgradeBusiness(String id, int upgradeCost) {
    if (_cash >= upgradeCost && _ownedBusinesses.containsKey(id)) {
      _cash -= upgradeCost;
      _ownedBusinesses[id] = _ownedBusinesses[id]! + 1;
      _addTransaction("ترقية مشروع تجاري", upgradeCost, false);
      _syncWithFirestore();
      notifyListeners();
    } else {
      _showNotification("⚠️ كاش غير كافي للترقية!");
    }
  }
}