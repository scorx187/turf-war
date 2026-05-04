// المسار: lib/providers/player_real_estate_logic.dart

part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerRealEstateLogic on PlayerProvider {

  // ==========================================
  // 1. الدخل السلبي
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
      int ownedCount = _ownedPropertyCounts[id] ?? 1;
      int listedCount = _listedProperties.where((l) => l == id || l.contains('_${id}_')).length;
      int rentedOutCount = _rentedOutProperties.values.where((v) => v['propertyId'] == id || _rentedOutProperties.keys.contains(id)).length;
      int activeCount = _activePropertyId == id ? 1 : 0;

      int usedCount = activeCount + listedCount + rentedOutCount;
      int idleCount = ownedCount - usedCount;

      if (idleCount > 0) {
        total += (GameData.propertyRentIncome[id] ?? 0) * 12 * idleCount;
      }
    }
    return total;
  }

  // ==========================================
  // 2. شراء وسكن العقارات
  // ==========================================
  Future<void> buyProperty(String id, int price, int happinessGain) async {
    int currentCount = _ownedPropertyCounts[id] ?? (_ownedProperties.contains(id) ? 1 : 0);

    if (_cash < price) {
      _showNotification("⚠️ كاش غير كافي!");
      return;
    }
    if (currentCount >= 5) {
      _showNotification("⚠️ وصلت للحد الأقصى (5 نسخ) من هذا العقار!");
      return;
    }

    try {
      _showNotification("⏳ جاري توثيق الشراء عبر السيرفر...");
      final callable = FirebaseFunctions.instance.httpsCallable('buyRealEstate');
      final response = await callable.call({
        'uid': _uid,
        'propertyId': id,
        'price': price,
        'happinessGain': happinessGain,
      });

      if (response.data['success'] == true) {
        _showNotification("🏠 مبروك! تم شراء العقار بنجاح.");
        _ownedPropertyCounts[id] = currentCount + 1;
        if (!_ownedProperties.contains(id)) _ownedProperties.add(id);
        _cash -= price;
        notifyListeners();
      }
    } on FirebaseFunctionsException catch (e) {
      _showNotification("⚠️ فشل الشراء: ${e.message}");
    } catch (e) {
      _showNotification("⚠️ حدث خطأ في الاتصال بالسيرفر!");
    }
  }

  void setActiveProperty(String id, int baseHappiness) {
    int ownedCount = _ownedPropertyCounts[id] ?? (_ownedProperties.contains(id) ? 1 : 0);
    int listedCount = _listedProperties.where((l) => l == id || l.contains('_${id}_')).length;
    int rentedOutCount = _rentedOutProperties.values.where((v) => v['propertyId'] == id || _rentedOutProperties.keys.contains(id)).length;
    int activeCount = _activePropertyId == id ? 1 : 0;

    int availableCount = ownedCount - listedCount - rentedOutCount - activeCount;
    bool isRentedByMe = _activeRentedProperty != null && _activeRentedProperty!['id'] == id;

    if (availableCount > 0 || isRentedByMe) {
      _activePropertyId = id;

      int finalHappiness = baseHappiness;
      // تطبيق زيادة السعادة إذا كان اللاعب مشتري ترقية الأثاث الفاخر
      if ((_propertyUpgrades[id] ?? []).contains('luxury_furniture')) {
        finalHappiness = (finalHappiness * 1.2).toInt();
      }

      _happiness = finalHappiness;
      _syncWithFirestore();
      notifyListeners();
    } else {
      _showNotification("⚠️ لا يوجد لديك نسخة شاغرة من هذا العقار للسكن فيها!");
    }
  }

  // ==========================================
  // 3. الصيانة، الترقيات ووضع اليد
  // ==========================================
  Future<void> maintainProperty(String id, int cost) async {
    if (_cash < cost) { _showNotification("⚠️ كاش غير كافي!"); return; }
    try {
      _showNotification("⏳ جاري صيانة العقار وتجديده...");
      final callable = FirebaseFunctions.instance.httpsCallable('maintainProperty');
      await callable.call({'uid': _uid, 'propertyId': id, 'cost': cost});
      _propertyConditions[id] = 100.0;
      _cash -= cost;
      notifyListeners();
      _showNotification("🛠️ تم ترميم العقار وعاد بحالة ممتازة 100%");
    } catch (e) {
      _showNotification("⚠️ فشلت عملية الصيانة.");
    }
  }

  Future<void> buyPropertyUpgrade(String propId, String upgradeId, int cost) async {
    if (_cash < cost) { _showNotification("⚠️ كاش غير كافي!"); return; }
    try {
      _showNotification("⏳ جاري الترقية...");
      final callable = FirebaseFunctions.instance.httpsCallable('upgradeProperty');
      await callable.call({'uid': _uid, 'propertyId': propId, 'upgradeId': upgradeId, 'cost': cost});

      if (_propertyUpgrades[propId] == null) _propertyUpgrades[propId] = [];
      _propertyUpgrades[propId]!.add(upgradeId);
      _cash -= cost;
      notifyListeners();
      _showNotification("⭐ تمت إضافة الترقية للعقار بنجاح!");
    } catch (e) {
      _showNotification("⚠️ فشلت عملية الشراء.");
    }
  }

  Future<void> takeoverProperty() async {
    try {
      _showNotification("⏳ جاري إرسال رجالك للسيطرة على العقار المهجور...");
      final callable = FirebaseFunctions.instance.httpsCallable('takeoverProperty');
      await callable.call({'uid': _uid});
      _showNotification("🏴‍☠️ مبروك! فرضت سيطرتك، العقار أصبح ملكك وتم نقل الملكية!");
    } on FirebaseFunctionsException catch (e) {
      _showNotification("⚠️ فشل الاستيلاء: ${e.message}");
    } catch (e) {
      _showNotification("⚠️ فشل الاستيلاء! قد يكون المالك قام بترميمه في اللحظة الأخيرة.");
    }
  }

  Future<double> getOwnerPropertyCondition(String ownerId, String propId) async {
    try {
      var doc = await FirebaseFirestore.instance.collection('players').doc(ownerId).get();
      var conds = doc.data()?['propertyConditions'];
      if (conds != null && conds[propId] != null) {
        return (conds[propId] as num).toDouble();
      }
    } catch (e) {}
    return 100.0;
  }

  // ==========================================
  // 4. سوق الإيجارات بين اللاعبين (P2P)
  // ==========================================
  Future<void> listPropertyForRent(String propertyId, int dailyPrice, int days) async {
    int ownedCount = _ownedPropertyCounts[propertyId] ?? (_ownedProperties.contains(propertyId) ? 1 : 0);
    int listedCount = _listedProperties.where((l) => l == propertyId || l.contains('_${propertyId}_')).length;
    int rentedOutCount = _rentedOutProperties.values.where((v) => v['propertyId'] == propertyId || _rentedOutProperties.keys.contains(propertyId)).length;
    int activeCount = _activePropertyId == propertyId ? 1 : 0;

    int usedCount = activeCount + listedCount + rentedOutCount;

    if (ownedCount - usedCount <= 0) {
      _showNotification("⚠️ لا تملك نسخة شاغرة لعرضها للإيجار!");
      return;
    }

    try {
      _showNotification("⏳ جاري عرض العقار في السوق...");
      final callable = FirebaseFunctions.instance.httpsCallable('listPropertyForRent');
      await callable.call({
        'uid': _uid, 'propertyId': propertyId, 'dailyPrice': dailyPrice, 'days': days, 'playerName': _playerName,
      });
      _showNotification("📜 تم عرض العقار بنجاح!");
    } catch (e) {
      _showNotification("⚠️ حدث خطأ!");
    }
  }

  Future<void> cancelRentalListing(String propertyId) async {
    String? actualListingId;
    try {
      actualListingId = _listedProperties.firstWhere((l) => l == propertyId || l.contains('_${propertyId}_'));
    } catch (e) {
      return;
    }

    try {
      _showNotification("⏳ جاري سحب العقار...");
      final callable = FirebaseFunctions.instance.httpsCallable('cancelRentalListing');
      await callable.call({'uid': _uid, 'propertyId': propertyId, 'listingId': actualListingId});
      _showNotification("🚫 تم سحب العقار من السوق.");
    } catch (e) {
      _showNotification("⚠️ حدث خطأ!");
    }
  }

  Future<void> rentPropertyFromMarket(Map<String, dynamic> listing, int happinessGain) async {
    int totalPrice = listing['dailyPrice'] * listing['days'];
    if (_cash < totalPrice) {
      _showNotification("⚠️ كاش غير كافي للاستئجار!");
      return;
    }
    if (_activeRentedProperty != null) {
      _showNotification("⚠️ أنت مستأجر عقاراً حالياً! انتظر انتهاء العقد.");
      return;
    }

    try {
      _showNotification("⏳ جاري توقيع عقد الإيجار...");
      final callable = FirebaseFunctions.instance.httpsCallable('rentPropertyFromMarket');
      final response = await callable.call({
        'uid': _uid,
        'listingId': listing['docId'],
        'ownerId': listing['ownerId'],
        'propertyId': listing['propertyId'],
        'dailyPrice': listing['dailyPrice'],
        'days': listing['days'],
        'happinessGain': happinessGain,
        'renterName': _playerName,
      });

      if (response.data['success'] == true) {
        _showNotification("🏠 مبروك! استأجرت العقار لمدة ${response.data['days']} يوم.");
      }
    } on FirebaseFunctionsException catch (e) {
      _showNotification("⚠️ فشل الاستئجار: ${e.message}");
    } catch (e) {
      _showNotification("⚠️ حدث خطأ: قد يكون العقار أُجر للاعب آخر للتو!");
    }
  }

  Future<void> cancelRentedProperty() async {
    if (_activeRentedProperty == null) return;
    try {
      _showNotification("⏳ جاري فسخ العقد...");
      final callable = FirebaseFunctions.instance.httpsCallable('cancelRentedProperty');
      await callable.call({'uid': _uid});
      _showNotification("تم فسخ العقد وعاد العقار لمالكه الأصلي.");
    } catch (e) {
      _showNotification("⚠️ حدث خطأ أثناء محاولة فسخ العقد!");
    }
  }

  // ==========================================
  // 5. المشاريع التجارية
  // ==========================================
  Future<void> buyBusiness(String id, int price) async {
    if (_cash < price) { _showNotification("⚠️ كاش غير كافي!"); return; }
    try {
      _showNotification("⏳ جاري استخراج التصاريح للمشروع...");
      final callable = FirebaseFunctions.instance.httpsCallable('manageBusiness');
      await callable.call({'uid': _uid, 'businessId': id, 'cost': price, 'actionType': 'buy'});
      _showNotification("🏢 مبروك! تم شراء المشروع التجاري بنجاح.");
    } on FirebaseFunctionsException catch (e) {
      _showNotification("⚠️ ${e.message}");
    } catch (e) {
      _showNotification("⚠️ فشل الشراء بسبب خطأ في الاتصال.");
    }
  }

  Future<void> upgradeBusiness(String id, int upgradeCost) async {
    if (_cash < upgradeCost) { _showNotification("⚠️ كاش غير كافي للترقية!"); return; }
    try {
      _showNotification("⏳ جاري الترقية والتطوير...");
      final callable = FirebaseFunctions.instance.httpsCallable('manageBusiness');
      await callable.call({'uid': _uid, 'businessId': id, 'cost': upgradeCost, 'actionType': 'upgrade'});
      _showNotification("📈 تم ترقية المشروع التجاري بنجاح!");
    } on FirebaseFunctionsException catch (e) {
      _showNotification("⚠️ ${e.message}");
    } catch (e) {
      _showNotification("⚠️ فشل الترقية بسبب خطأ في الاتصال.");
    }
  }
}