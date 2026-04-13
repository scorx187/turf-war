// المسار: lib/providers/player_titles_logic.dart
part of 'player_provider.dart';

extension PlayerTitlesLogic on PlayerProvider {
  List<Map<String, dynamic>> getAllTitles() {
    int wlth = _cash + _bankBalance;
    int cr = crimeSuccessCountsMap.values.fold(0, (sum, val) => sum + val);
    bool isHoused = _activePropertyId != null;

    return [
      {'name': 'مبتدئ في الشوارع 🚶', 'desc': 'اللقب الافتراضي (متاح للجميع)', 'unlocked': true},
      {'name': 'مبتدئ مالي 💵', 'desc': 'اجمع 100 ألف دولار', 'unlocked': wlth >= 100000},
      {'name': 'مليونير صاعد 💰', 'desc': 'اجمع 1 مليون دولار', 'unlocked': wlth >= 1000000},
      {'name': 'رجل أعمال ثري 🏦', 'desc': 'اجمع 10 مليون دولار', 'unlocked': wlth >= 10000000},
      {'name': 'حوت المافيا 🐋', 'desc': 'اجمع 100 مليون دولار', 'unlocked': wlth >= 100000000},
      {'name': 'نصف بليونير 💎', 'desc': 'اجمع 500 مليون دولار', 'unlocked': wlth >= 500000000},
      {'name': 'بليونير الشوارع 💸', 'desc': 'اجمع 1 مليار دولار', 'unlocked': wlth >= 1000000000},
      {'name': 'قارون المدينة 🪙', 'desc': 'اجمع 10 مليار دولار', 'unlocked': wlth >= 10000000000},
      {'name': 'إمبراطور الاقتصاد 🌍', 'desc': 'اجمع 100 مليار دولار', 'unlocked': wlth >= 100000000000},
      {'name': 'باحث عن الذهب ⛏️', 'desc': 'اجمع 100 ذهبة', 'unlocked': _gold >= 100},
      {'name': 'مكتنز الذهب 🪙', 'desc': 'اجمع 500 ذهبة', 'unlocked': _gold >= 500},
      {'name': 'تاجر الذهب ⚖️', 'desc': 'اجمع 1,000 ذهبة', 'unlocked': _gold >= 1000},
      {'name': 'بارون الذهب 👑', 'desc': 'اجمع 5,000 ذهبة', 'unlocked': _gold >= 5000},
      {'name': 'ملك السبائك 🧱', 'desc': 'اجمع 10,000 ذهبة', 'unlocked': _gold >= 10000},
      {'name': 'خزنة لا تنضب 🏦', 'desc': 'اجمع 50,000 ذهبة', 'unlocked': _gold >= 50000},
      {'name': 'أسطورة الذهب 🌟', 'desc': 'اجمع 100,000 ذهبة', 'unlocked': _gold >= 100000},
      {'name': 'إله الثروة ⚡', 'desc': 'اجمع 500,000 ذهبة', 'unlocked': _gold >= 500000},
      {'name': 'قاتل مأجور 🎯', 'desc': 'اقتل 10 لاعبين في الشوارع', 'unlocked': _pvpWins >= 10},
      {'name': 'سفاح خطير 🔪', 'desc': 'اقتل 50 لاعب في الشوارع', 'unlocked': _pvpWins >= 50},
      {'name': 'أسطورة الجريمة 👑🩸', 'desc': 'اقتل 200 لاعب في الشوارع', 'unlocked': _pvpWins >= 200},
      {'name': 'لص محترف 🥷', 'desc': 'نفذ 500 جريمة ناجحة', 'unlocked': cr >= 500},
      {'name': 'عقل مدبر 🧠', 'desc': 'نفذ 2,000 جريمة ناجحة', 'unlocked': cr >= 2000},
      {'name': 'زعيم المافيا 🎩', 'desc': 'نفذ 10,000 جريمة ناجحة', 'unlocked': cr >= 10000},
      {'name': 'كابوس المدينة 👹', 'desc': 'نفذ 50,000 جريمة ناجحة', 'unlocked': cr >= 50000},
      {'name': 'شيطان الشوارع 👹', 'desc': 'نفذ 100,000 جريمة ناجحة', 'unlocked': cr >= 100000},
      {'name': 'رجل أعمال سعيد 💼', 'desc': 'صل إلى 500 نقطة سعادة', 'unlocked': _happiness >= 500},
      {'name': 'مواطن VIP 🥂', 'desc': 'صل إلى 2,000 نقطة سعادة', 'unlocked': _happiness >= 2000},
      {'name': 'سيد الرفاهية 🏰', 'desc': 'صل إلى 5,000 نقطة سعادة', 'unlocked': _happiness >= 5000},
      {'name': 'إمبراطور النعيم 👑', 'desc': 'صل إلى 10,000 نقطة سعادة', 'unlocked': _happiness >= 10000},
      {'name': 'أسطورة السعادة 🌈', 'desc': 'صل إلى 50,000 نقطة سعادة', 'unlocked': _happiness >= 50000},
      {'name': 'مواطن مستقر 🏠', 'desc': 'اشتر أول عقار لك واسكن فيه', 'unlocked': _ownedProperties.isNotEmpty && isHoused},
      {'name': 'مستثمر عقاري 🏢', 'desc': 'اشتر 5 عقارات واسكن في أحدها', 'unlocked': _ownedProperties.length >= 5 && isHoused},
      {'name': 'ملك العقارات 🏙️', 'desc': 'اشتر جميع العقارات واسكن في أحدها', 'unlocked': _ownedProperties.length >= GameData.residentialProperties.length && isHoused},
      {'name': 'تاجر صغير 🏪', 'desc': 'اشتر مشروع تجاري واحد', 'unlocked': _ownedBusinesses.isNotEmpty},
      {'name': 'محتكر السوق 📈', 'desc': 'اشتر 5 مشاريع تجارية', 'unlocked': _ownedBusinesses.length >= 5},
      {'name': 'إمبراطور التجارة 🛳️', 'desc': 'اشتر 10 مشاريع تجارية', 'unlocked': _ownedBusinesses.length >= 10},
      {'name': 'هاوي محركات 🏎️', 'desc': 'امتلك سيارة واحدة', 'unlocked': _ownedCars.isNotEmpty},
      {'name': 'مجمع سيارات 🚘', 'desc': 'امتلك 5 سيارات', 'unlocked': _ownedCars.length >= 5},
      {'name': 'شريطي الشوارع 🏎️💨', 'desc': 'امتلك 10 سيارات', 'unlocked': _ownedCars.length >= 10},
      {'name': 'صاحب معرض 🏢', 'desc': 'امتلك 15 سيارة', 'unlocked': _ownedCars.length >= 15},
      {'name': 'إمبراطور الكراجات 👑🏎️', 'desc': 'امتلك 25 سيارة', 'unlocked': _ownedCars.length >= 25},
      {'name': 'ميكانيكي مبتدئ 🔧', 'desc': 'اجمع 100 قطعة غيار', 'unlocked': _spareParts >= 100},
      {'name': 'خبير تفكيك ⚙️', 'desc': 'اجمع 1,000 قطعة غيار', 'unlocked': _spareParts >= 1000},
      {'name': 'ملك السكراب 🚜', 'desc': 'اجمع 10,000 قطعة غيار', 'unlocked': _spareParts >= 10000},
      {'name': 'إمبراطور القطع 🏭', 'desc': 'اجمع 50,000 قطعة غيار', 'unlocked': _spareParts >= 50000},
      {'name': 'كيميائي هاوي 🧪', 'desc': 'قم بـ 10 عمليات تصنيع في المختبر', 'unlocked': _totalLabCrafts >= 10},
      {'name': 'طباخ محترف 👨‍🔬', 'desc': 'قم بـ 50 عملية تصنيع في المختبر', 'unlocked': _totalLabCrafts >= 50},
      {'name': 'خبير سموم ☠️', 'desc': 'قم بـ 200 عملية تصنيع في المختبر', 'unlocked': _totalLabCrafts >= 200},
      {'name': 'هايزنبرغ المدينة 🧪', 'desc': 'قم بـ 1,000 عملية تصنيع في المختبر', 'unlocked': _totalLabCrafts >= 1000},
      {'name': 'محب للمغامرة 🎰', 'desc': 'دور عجلة الحظ 10 مرات', 'unlocked': _luckyWheelSpins >= 10},
      {'name': 'مدمن قمار 🎲', 'desc': 'دور عجلة الحظ 50 مرة', 'unlocked': _luckyWheelSpins >= 50},
      {'name': 'ملك الحظ 🍀', 'desc': 'دور عجلة الحظ 200 مرة', 'unlocked': _luckyWheelSpins >= 200},
      {'name': 'حبيب الكازينو 🎰', 'desc': 'دور عجلة الحظ 1,000 مرة', 'unlocked': _luckyWheelSpins >= 1000},
      {'name': 'عضو داعم 🤝', 'desc': 'تبرع بـ 100,000 لعصابتك', 'unlocked': _gangContribution >= 100000},
      {'name': 'ذراع اليمين 🤝', 'desc': 'تبرع بـ 1,000,000 لعصابتك', 'unlocked': _gangContribution >= 1000000},
      {'name': 'ممول العصابة 💼', 'desc': 'تبرع بـ 10 مليون لعصابتك', 'unlocked': _gangContribution >= 10000000},
      {'name': 'بنك العصابة 🏦', 'desc': 'تبرع بـ 50 مليون لعصابتك', 'unlocked': _gangContribution >= 50000000},
      {'name': 'عراب الشوارع 🕴️', 'desc': 'تبرع بـ 100 مليون لعصابتك', 'unlocked': _gangContribution >= 100000000},
      {'name': 'خارج عن القانون 🔫', 'desc': 'صل للمستوى 10 في الجريمة', 'unlocked': _crimeLevel >= 10},
      {'name': 'مجرم مخضرم 🧨', 'desc': 'صل للمستوى 25 في الجريمة', 'unlocked': _crimeLevel >= 25},
      {'name': 'زعيم محنك 🎩', 'desc': 'صل للمستوى 50 في الجريمة', 'unlocked': _crimeLevel >= 50},
      {'name': 'شبح المدينة 👻', 'desc': 'صل للمستوى 100 في الجريمة', 'unlocked': _crimeLevel >= 100},
      {'name': 'كابوس السلطات 🚔', 'desc': 'صل للمستوى 150 في الجريمة', 'unlocked': _crimeLevel >= 150},
      {'name': 'أسطورة حية 🐉', 'desc': 'صل للمستوى 200 في الجريمة', 'unlocked': _crimeLevel >= 200},
      {'name': 'إله الجريمة 🌋', 'desc': 'صل للمستوى 300 في الجريمة', 'unlocked': _crimeLevel >= 300},
      {'name': 'الحاكم المطلق 👑🌍', 'desc': 'صل للمستوى 400 (الماكس لفل)', 'unlocked': _crimeLevel >= 400},
      {'name': 'موظف مجتهد 💼', 'desc': 'صل للمستوى 10 في العمل', 'unlocked': _workLevel >= 10},
      {'name': 'مدير تنفيذي 📊', 'desc': 'صل للمستوى 25 في العمل', 'unlocked': _workLevel >= 25},
      {'name': 'رئيس مجلس الإدارة 🏢', 'desc': 'صل للمستوى 50 في العمل', 'unlocked': _workLevel >= 50},
      {'name': 'وزير الاقتصاد 🏛️', 'desc': 'صل للمستوى 100 في العمل', 'unlocked': _workLevel >= 100},
      {'name': 'ملاكم شوارع 🥊', 'desc': 'صل للمستوى 10 في الحلبة', 'unlocked': _arenaLevel >= 10},
      {'name': 'بطل الحلبة 🥇', 'desc': 'صل للمستوى 50 في الحلبة', 'unlocked': _arenaLevel >= 50},
      {'name': 'جلاد الساحة 🩸', 'desc': 'صل للمستوى 100 في الحلبة', 'unlocked': _arenaLevel >= 100},
      {'name': 'زائر مميز 🌟', 'desc': 'فعل اشتراك VIP لمدة يوم', 'unlocked': _totalVipDays >= 1},
      {'name': 'شخصية هامة 🍷', 'desc': 'فعل اشتراك VIP لمدة أسبوع', 'unlocked': _totalVipDays >= 7},
      {'name': 'نجم المدينة 💎', 'desc': 'فعل اشتراك VIP لمدة شهر', 'unlocked': _totalVipDays >= 30},
      {'name': 'صاحب الفخامة 👑💎', 'desc': 'فعل اشتراك VIP لمدة سنة', 'unlocked': _totalVipDays >= 365},
    ];
  }

  void checkNewTitles() {
    if (_isLoading || _uid == null) return;
    List<Map<String, dynamic>> all = getAllTitles();
    List<String> currentUnlocked = all.where((t) => t['unlocked'] == true).map((t) => t['name'] as String).toList();
    bool hasNew = false;
    int newCount = 0;

    List<String> missingTitles = currentUnlocked.where((t) => !_unlockedTitlesList.contains(t)).toList();

    if (missingTitles.isNotEmpty) {
      if (missingTitles.length > 3 && _unlockedTitlesList.length <= 1) {
        _unlockedTitlesList = currentUnlocked;
        _syncWithFirestore();
        notifyListeners();
        _sendSystemNotification("تحديث الحساب 🌟", "تم تحديث حسابك ومنحك نقاط الامتياز والألقاب بأثر رجعي!", "update");
        return;
      }

      for (String t in missingTitles) {
        _unlockedTitlesList.add(t);
        _bonusPerkPoints += 1; // 🟢 إصلاح لوب الإشعارات المزعج هنا
        hasNew = true;
        newCount++;

        if (newCount <= 3) {
          _sendSystemNotification('لقب جديد 🏆', 'تهانينا! لقد كسبت لقب: ($t) وحصلت على نقطة امتياز جديدة.', 'trophy');
        }
      }

      if (newCount > 3) {
        _sendSystemNotification('ألقاب جديدة 🏆', 'حصلت على $newCount ألقاب جديدة! راجع خزانة الألقاب.', 'trophy');
      }
    }

    if (hasNew) {
      _syncWithFirestore();
      notifyListeners();
    }
  }
}