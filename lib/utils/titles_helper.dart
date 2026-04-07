// المسار: lib/utils/titles_helper.dart

import 'game_data.dart';

class TitlesHelper {
  static List<Map<String, dynamic>> getAllTitlesList(Map<String, dynamic> data) {
    int pvp = data['pvpWins'] ?? 0;
    int wlth = (data['cash'] ?? 0) + (data['bankBalance'] ?? 0);
    int gld = data['gold'] ?? 0;
    int cr = 0;
    if (data['crimeSuccessCountsMap'] != null) {
      (data['crimeSuccessCountsMap'] as Map).forEach((k, v) => cr += (v as int));
    }
    int hap = data['happiness'] ?? 0;
    List<String> ownedProps = List<String>.from(data['ownedProperties'] ?? []);
    bool isHoused = data['activePropertyId'] != null;
    int totalProps = GameData.residentialProperties.length;

    int carsOwned = List<String>.from(data['ownedCars'] ?? []).length;
    int gangCont = data['gangContribution'] ?? 0;
    int crimeLvl = data['crimeLevel'] ?? 1;
    int workLvl = data['workLevel'] ?? 1;
    int arenaLvl = data['arenaLevel'] ?? 1;
    int totalVipDays = data['totalVipDays'] ?? 0;
    int bizCount = (data['ownedBusinesses'] as Map?)?.length ?? 0;
    int spareParts = data['spareParts'] ?? 0;
    int labCrafts = data['totalLabCrafts'] ?? 0;
    int wheelSpins = data['luckyWheelSpins'] ?? 0;

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
      {'name': 'باحث عن الذهب ⛏️', 'desc': 'اجمع 100 ذهبة', 'unlocked': gld >= 100},
      {'name': 'مكتنز الذهب 🪙', 'desc': 'اجمع 500 ذهبة', 'unlocked': gld >= 500},
      {'name': 'تاجر الذهب ⚖️', 'desc': 'اجمع 1,000 ذهبة', 'unlocked': gld >= 1000},
      {'name': 'بارون الذهب 👑', 'desc': 'اجمع 5,000 ذهبة', 'unlocked': gld >= 5000},
      {'name': 'ملك السبائك 🧱', 'desc': 'اجمع 10,000 ذهبة', 'unlocked': gld >= 10000},
      {'name': 'خزنة لا تنضب 🏦', 'desc': 'اجمع 50,000 ذهبة', 'unlocked': gld >= 50000},
      {'name': 'أسطورة الذهب 🌟', 'desc': 'اجمع 100,000 ذهبة', 'unlocked': gld >= 100000},
      {'name': 'إله الثروة ⚡', 'desc': 'اجمع 500,000 ذهبة', 'unlocked': gld >= 500000},
      {'name': 'قاتل مأجور 🎯', 'desc': 'اقتل 10 لاعبين في الشوارع', 'unlocked': pvp >= 10},
      {'name': 'سفاح خطير 🔪', 'desc': 'اقتل 50 لاعب في الشوارع', 'unlocked': pvp >= 50},
      {'name': 'أسطورة الجريمة 👑🩸', 'desc': 'اقتل 200 لاعب في الشوارع', 'unlocked': pvp >= 200},
      {'name': 'لص محترف 🥷', 'desc': 'نفذ 500 جريمة ناجحة', 'unlocked': cr >= 500},
      {'name': 'عقل مدبر 🧠', 'desc': 'نفذ 2,000 جريمة ناجحة', 'unlocked': cr >= 2000},
      {'name': 'زعيم المافيا 🎩', 'desc': 'نفذ 10,000 جريمة ناجحة', 'unlocked': cr >= 10000},
      {'name': 'كابوس المدينة 🦇', 'desc': 'نفذ 50,000 جريمة ناجحة', 'unlocked': cr >= 50000},
      {'name': 'شيطان الشوارع 👹', 'desc': 'نفذ 100,000 جريمة ناجحة', 'unlocked': cr >= 100000},
      {'name': 'رجل أعمال سعيد 💼', 'desc': 'صل إلى 500 نقطة سعادة', 'unlocked': hap >= 500},
      {'name': 'مواطن VIP 🥂', 'desc': 'صل إلى 2,000 نقطة سعادة', 'unlocked': hap >= 2000},
      {'name': 'سيد الرفاهية 🏰', 'desc': 'صل إلى 5,000 نقطة سعادة', 'unlocked': hap >= 5000},
      {'name': 'إمبراطور النعيم 👑', 'desc': 'صل إلى 10,000 نقطة سعادة', 'unlocked': hap >= 10000},
      {'name': 'أسطورة السعادة 🌈', 'desc': 'صل إلى 50,000 نقطة سعادة', 'unlocked': hap >= 50000},
      {'name': 'مواطن مستقر 🏠', 'desc': 'اشتر أول عقار لك واسكن فيه', 'unlocked': ownedProps.isNotEmpty && isHoused},
      {'name': 'مستثمر عقاري 🏢', 'desc': 'اشتر 5 عقارات واسكن في أحدها', 'unlocked': ownedProps.length >= 5 && isHoused},
      {'name': 'ملك العقارات 🏙️', 'desc': 'اشتر جميع العقارات واسكن في أحدها', 'unlocked': ownedProps.length >= totalProps && isHoused},
      {'name': 'تاجر صغير 🏪', 'desc': 'اشتر مشروع تجاري واحد', 'unlocked': bizCount >= 1},
      {'name': 'محتكر السوق 📈', 'desc': 'اشتر 5 مشاريع تجارية', 'unlocked': bizCount >= 5},
      {'name': 'إمبراطور التجارة 🛳️', 'desc': 'اشتر 10 مشاريع تجارية', 'unlocked': bizCount >= 10},
      {'name': 'هاوي محركات 🏎️', 'desc': 'امتلك سيارة واحدة', 'unlocked': carsOwned >= 1},
      {'name': 'مجمع سيارات 🚘', 'desc': 'امتلك 5 سيارات', 'unlocked': carsOwned >= 5},
      {'name': 'إمبراطور الكراجات 👑🏎️', 'desc': 'امتلك 25 سيارة', 'unlocked': carsOwned >= 25},
      {'name': 'ميكانيكي مبتدئ 🔧', 'desc': 'اجمع 100 قطعة غيار', 'unlocked': spareParts >= 100},
      {'name': 'خبير تفكيك ⚙️', 'desc': 'اجمع 1,000 قطعة غيار', 'unlocked': spareParts >= 1000},
      {'name': 'ملك السكراب 🚜', 'desc': 'اجمع 10,000 قطعة غيار', 'unlocked': spareParts >= 10000},
      {'name': 'إمبراطور القطع 🏭', 'desc': 'اجمع 50,000 قطعة غيار', 'unlocked': spareParts >= 50000},
      {'name': 'كيميائي هاوي 🧪', 'desc': 'قم بـ 10 عمليات تصنيع في المختبر', 'unlocked': labCrafts >= 10},
      {'name': 'طباخ محترف 👨‍🔬', 'desc': 'قم بـ 50 عملية تصنيع في المختبر', 'unlocked': labCrafts >= 50},
      {'name': 'خبير سموم ☠️', 'desc': 'قم بـ 200 عملية تصنيع في المختبر', 'unlocked': labCrafts >= 200},
      {'name': 'هايزنبرغ المدينة 💎', 'desc': 'قم بـ 1,000 عملية تصنيع في المختبر', 'unlocked': labCrafts >= 1000},
      {'name': 'محب للمغامرة 🎡', 'desc': 'دور عجلة الحظ 10 مرات', 'unlocked': wheelSpins >= 10},
      {'name': 'مدمن قمار 🎲', 'desc': 'دور عجلة الحظ 50 مرة', 'unlocked': wheelSpins >= 50},
      {'name': 'ملك الحظ 🍀', 'desc': 'دور عجلة الحظ 200 مرة', 'unlocked': wheelSpins >= 200},
      {'name': 'حبيب الكازينو 🎰', 'desc': 'دور عجلة الحظ 1,000 مرة', 'unlocked': wheelSpins >= 1000},
      {'name': 'عضو داعم 🪙', 'desc': 'تبرع بـ 100,000 لعصابتك', 'unlocked': gangCont >= 100000},
      {'name': 'ذراع اليمين 🤝', 'desc': 'تبرع بـ 1,000,000 لعصابتك', 'unlocked': gangCont >= 1000000},
      {'name': 'عراب الشوارع 🕴️', 'desc': 'تبرع بـ 100 مليون لعصابتك', 'unlocked': gangCont >= 100000000},
      {'name': 'خارج عن القانون 🔫', 'desc': 'صل للمستوى 10 في الجريمة', 'unlocked': crimeLvl >= 10},
      {'name': 'شبح المدينة 👻', 'desc': 'صل للمستوى 100 في الجريمة', 'unlocked': crimeLvl >= 100},
      {'name': 'الحاكم المطلق 👑🌍', 'desc': 'صل للمستوى 400 (الماكس لفل)', 'unlocked': crimeLvl >= 400},
      {'name': 'موظف مجتهد 💼', 'desc': 'صل للمستوى 10 في العمل', 'unlocked': workLvl >= 10},
      {'name': 'وزير الاقتصاد 🏛️', 'desc': 'صل للمستوى 100 في العمل', 'unlocked': workLvl >= 100},
      {'name': 'ملاكم شوارع 🥊', 'desc': 'صل للمستوى 10 في الحلبة', 'unlocked': arenaLvl >= 10},
      {'name': 'جلاد الساحة 🩸', 'desc': 'صل للمستوى 100 في الحلبة', 'unlocked': arenaLvl >= 100},
      {'name': 'زائر مميز 🌟', 'desc': 'فعل اشتراك VIP لمدة يوم', 'unlocked': totalVipDays >= 1},
      {'name': 'شخصية هامة 🍷', 'desc': 'فعل اشتراك VIP لمدة أسبوع', 'unlocked': totalVipDays >= 7},
      {'name': 'نجم المدينة 💎', 'desc': 'فعل اشتراك VIP لمدة شهر', 'unlocked': totalVipDays >= 30},
      {'name': 'صاحب الفخامة 👑💎', 'desc': 'فعل اشتراك VIP لمدة سنة', 'unlocked': totalVipDays >= 365},
    ];
  }
}