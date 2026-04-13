// المسار: lib/providers/player_real_estate_logic.dart

part of 'player_provider.dart';

extension PlayerRealEstateLogic on PlayerProvider {

  // ==========================================
  // 1. الدخل السلبي (يظل كما هو لأنه للعرض والحسابات فقط)
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
  // 2. دوال الملكية والسكن الأساسية (شراء من السيرفر)
  // ==========================================
  Future<void> buyProperty(String id, int price, int happinessGain) async {
    // تحقق أولي بسيط وسريع لكي لا نُتعب السيرفر إذا كان اللاعب مفلساً أصلاً
    if (_cash < price) {
      _showNotification("⚠️ كاش غير كافي!");
      return;
    }
    if (_ownedProperties.contains(id)) {
      _showNotification("⚠️ أنت تملك هذا العقار مسبقاً!");
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
      }
    } on FirebaseFunctionsException catch (e) {
      _showNotification("⚠️ فشل الشراء: ${e.message}");
    } catch (e) {
      _showNotification("⚠️ حدث خطأ في الاتصال بالسيرفر!");
    }
  }

  // تغيير السكن لا يكلف شيئاً لذلك نتركه محلياً كـ تفضيل للاعب
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
  // 3. دوال سوق الإيجارات بين اللاعبين (P2P) (السلطة للسيرفر)
  // ==========================================
  Future<void> listPropertyForRent(String propertyId, int dailyPrice, int days) async {
    if (_listedProperties.contains(propertyId) || _rentedOutProperties.containsKey(propertyId)) return;
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
    if (!_listedProperties.contains(propertyId)) return;
    try {
      _showNotification("⏳ جاري سحب العقار...");
      final callable = FirebaseFunctions.instance.httpsCallable('cancelRentalListing');
      await callable.call({'uid': _uid, 'propertyId': propertyId});
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
        'listingId': '${listing['ownerId']}_${listing['propertyId']}',
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
  // 4. المشاريع التجارية (شراء وترقية من السيرفر)
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