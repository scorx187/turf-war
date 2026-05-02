# 🎮 Turf War - لعبة عصابات RPG Management

## 📌 نظرة عامة على المشروع

**Turf War** لعبة Flutter من نوع **RPG Management بثيم العصابات والجريمة المنظمة**.
- اللعبة باللغة العربية (RTL)
- Multiplayer كاملة عبر Firebase
- Real-time interactions (chat, PvP, gangs)
- نظام ضغط على صور للحصول على نتائج (لا توجد حركات قتال مباشرة)

## 🛠️ التقنيات المستخدمة

### Frontend
- **Framework**: Flutter 3.x + Dart 3.11.1
- **State Management**: مزيج من:
  - `provider` ^6.1.1 (للحالات العامة - PlayerProvider, AudioProvider, MarketProvider)
  - `flutter_bloc` ^8.1.5 / Cubit (لحالات الموارد والأنشطة - PlayerStatsCubit, BankCubit, إلخ)
- **Font**: Changa (عربي)
- **Direction**: RTL إجباري
- **Theme**: Dark mode (أسود + ذهبي + أزرق)

### Backend
- **Auth**: Firebase Auth + Google Sign-In
- **Database**: Cloud Firestore (real-time)
- **Functions**: Cloud Functions (Node.js في functions/index.js)
- **Storage**: Firebase Storage (للصور الشخصية)
- **Notifications**: awesome_notifications + Firebase Messaging

### Audio
- **Package**: audioplayers ^6.1.0
- **الموسيقى**: bg_music.mp3 + The ledger's wight.mp3
- **Effects**: click.mp3, attack.mp3

## 📁 هيكل المشروع

```
lib/
├── main.dart                          # نقطة البداية + Firebase init + Providers/Blocs
├── firebase_options.dart              # إعدادات Firebase
│
├── controllers/                       # Cubits لإدارة حالات الميزات
│   ├── player_stats_cubit.dart       # ⭐ الموارد الأساسية (Health, Energy, Courage, Prestige)
│   ├── crime_cubit.dart              # نظام الجرائم
│   ├── bank_cubit.dart               # البنك
│   ├── gym_cubit.dart                # الجيم
│   ├── hospital_cubit.dart           # المستشفى
│   ├── prison_cubit.dart             # السجن
│   ├── black_market_cubit.dart       # السوق السوداء
│   ├── chop_shop_cubit.dart          # ورشة السيارات
│   ├── laboratory_cubit.dart         # المختبر
│   ├── lucky_wheel_cubit.dart        # عجلة الحظ
│   ├── street_race_cubit.dart        # سباقات الشوارع
│   ├── real_estate_cubit.dart        # العقارات
│   ├── inventory_cubit.dart          # المخزون
│   └── *_state.dart                  # الـ states المرتبطة
│
├── providers/                         # ChangeNotifiers للحالات العامة
│   ├── player_provider.dart          # ⭐ الـ Provider الرئيسي للاعب (46KB - كبير!)
│   ├── audio_provider.dart           # تشغيل الأصوات والموسيقى
│   ├── market_provider.dart          # السوق
│   ├── player_combat_logic.dart      # منطق القتال (PvP)
│   ├── player_inventory_logic.dart   # منطق المخزون
│   ├── player_market_logic.dart      # منطق السوق
│   ├── player_real_estate_logic.dart # منطق العقارات
│   ├── player_social_logic.dart      # منطق الاجتماعيات
│   ├── player_stats_logic.dart       # منطق الإحصائيات
│   └── player_titles_logic.dart      # نظام الألقاب
│
├── screens/
│   └── game_screen.dart              # الشاشة الرئيسية للعبة
│
├── views/                             # شاشات الميزات (Tabs)
│   ├── crime_view.dart               # شاشة الجرائم
│   ├── gym_view.dart                 # الجيم
│   ├── bank_view.dart                # البنك
│   ├── hospital_view.dart            # المستشفى
│   ├── prison_view.dart              # السجن
│   ├── black_market_view.dart        # السوق السوداء
│   ├── chop_shop_view.dart           # ورشة السيارات
│   ├── laboratory_view.dart          # المختبر
│   ├── factory_view.dart             # المصنع
│   ├── lucky_wheel_view.dart         # عجلة الحظ
│   ├── arena_view.dart               # الساحة
│   ├── armory_view.dart              # مخزن الأسلحة
│   ├── inventory_view.dart           # المخزون
│   ├── real_estate_view.dart         # العقارات
│   ├── store_view.dart               # المتجر
│   ├── airport_view.dart             # المطار
│   ├── perks_view.dart               # المميزات
│   │
│   # PvP والقتال
│   ├── pvp_battle_view.dart          # شاشة القتال
│   ├── pvp_list_view.dart            # قائمة الخصوم
│   │
│   # العصابات
│   ├── gang_view.dart                # شاشة العصابة الرئيسية
│   ├── gang_management_view.dart     # إدارة العصابة
│   ├── gang_members_view.dart        # الأعضاء
│   ├── gang_donation_view.dart       # التبرعات
│   ├── gang_raids_view.dart          # الغارات
│   ├── gang_skills_view.dart         # المهارات
│   ├── gang_store_view.dart          # متجر العصابة
│   ├── public_gang_profile_view.dart # ملف العصابة العام
│   │
│   # الاجتماعيات
│   ├── chat_view.dart                # المحادثة العامة
│   ├── private_chat_view.dart        # المحادثة الخاصة
│   ├── private_chat_list_view.dart   # قائمة المحادثات
│   ├── friends_view.dart             # الأصدقاء
│   ├── player_profile_view.dart      # ⭐ ملف اللاعب (74KB - أكبر ملف!)
│   ├── notifications_view.dart       # الإشعارات
│   ├── journal_view.dart             # السجل/الأخبار
│   │
│   # أخرى
│   ├── settings_view.dart            # الإعدادات
│   ├── version_check_view.dart       # فحص الإصدار
│   └── quick_recovery_dialog.dart    # حوار الشفاء السريع
│
├── services/                          # خدمات Firebase (CRUD operations)
│   ├── bank_service.dart
│   ├── crime_service.dart
│   ├── gym_service.dart
│   ├── hospital_service.dart
│   ├── prison_service.dart
│   ├── black_market_service.dart
│   ├── chop_shop_service.dart
│   ├── inventory_service.dart
│   └── lucky_wheel_service.dart
│
├── utils/
│   ├── crime_data.dart               # بيانات الجرائم الثابتة
│   ├── game_data.dart                # بيانات اللعبة العامة
│   ├── titles_helper.dart            # مساعد الألقاب
│   └── local_notification_service.dart # الإشعارات المحلية
│
└── models/
    └── player_state.dart             # (فارغ حالياً)

assets/
├── audio/                            # الموسيقى والمؤثرات
├── fonts/Changa-Regular.ttf + Bold   # الخط العربي
└── images/
    ├── icons/                        # 16 أيقونة (cash, gold, energy, إلخ)
    ├── ui/                           # خلفيات UI
    └── (city_map, app_icon, إلخ)
```

## 🎯 المفاهيم الأساسية للعبة

### الموارد الأربعة الرئيسية للاعب:
1. **Health (الصحة)** - تتجدد بمرور الوقت أو في المستشفى
2. **Energy (الطاقة)** - تستخدم في الجرائم والأنشطة
3. **Courage (الشجاعة)** - تستخدم في PvP
4. **Prestige (الهيبة)** - مهم للترقي

### العملات:
- **Cash** (المال) - العملة الأساسية
- **Gold** (الذهب) - العملة المميزة

### نظام الـ Tick:
- Timer كل ثانية في PlayerStatsCubit
- يعيد توليد الموارد بمعدلات محسوبة من المستوى
- _exactHealth, _exactEnergy, إلخ بـ double للدقة

## 📋 معايير الكود المهمة

### ✅ المتبع حالياً
- التعليقات بالعربية (مفيدة!)
- استخدام Cubit للميزات + Provider للـ Player
- RTL في كل مكان
- Dark theme
- Firebase real-time للـ multiplayer
- Localization عربي في android/values-ar/

### ⚠️ نقاط تحتاج تحسين (لاحظتها)
1. `player_provider.dart` كبير جداً (46KB) - يحتاج تقسيم
2. `player_profile_view.dart` كبير جداً (74KB) - يحتاج تقسيم لـ widgets أصغر
3. `models/player_state.dart` فارغ - لم يتم استخدامه
4. مزيج Provider و Cubit قد يربك - يفضل توحيد الأسلوب
5. لا يوجد مجلد `lib/widgets/` لـ widgets المشتركة
6. لا يوجد `theme/` منفصل (الألوان في main.dart فقط)

## 🚨 قواعد مهمة عند العمل على المشروع

### عند إضافة feature جديدة:
1. أنشئ `*_cubit.dart` و `*_state.dart` في `controllers/`
2. أنشئ `*_service.dart` في `services/` للتعامل مع Firebase
3. أنشئ `*_view.dart` في `views/`
4. أضف الـ Cubit في `MultiBlocProvider` في `main.dart`
5. اربط بـ navigation في `game_screen.dart`

### عند تعديل الموارد:
- لا تعدّل _exactHealth/_exactEnergy مباشرة
- استخدم methods الموجودة في PlayerStatsCubit
- تذكر sync مع Firebase

### Firebase rules:
- جميع البيانات الحساسة في Cloud Functions
- لا تثق في client-side validation فقط
- استخدم batch writes للعمليات المركبة

### ممنوع:
- ❌ كسر الـ RTL
- ❌ استخدام نصوص hardcoded - استخدم الـ utils
- ❌ تعديل player stats من خارج PlayerStatsCubit أو Cloud Functions
- ❌ إضافة packages بدون موافقة (المشروع كبير ومستقر)
- ❌ تغيير firebase_options.dart يدوياً

### مطلوب:
- ✅ التعليقات بالعربية مرحب بها
- ✅ اتبع نمط `// المسار: lib/...` في بداية الملفات
- ✅ استخدم Changa font للنصوص
- ✅ استخدم Colors الموجودة في GameColors class
- ✅ اختبر على RTL دائماً

## 🎨 الألوان الرسمية

```dart
class GameColors {
  static const Color primary = Colors.amber;        // الذهبي
  static const Color background = Colors.black;     // الأسود
  static const Color surface = Color(0xFF1E1E1E);  // الرمادي الداكن
  static const Color accent = Colors.blueAccent;    // الأزرق
}
```

## 📦 Packages المثبتة (لا تضيف بدون داعي)

```yaml
provider: ^6.1.1
flutter_bloc: ^8.1.5
intl: ^0.20.2
shared_preferences: ^2.3.5
audioplayers: ^6.1.0
firebase_core: ^4.6.0
firebase_auth: ^6.3.0
google_sign_in: ^6.2.1
cloud_firestore: ^6.2.0
cloud_functions: 6.1.0
firebase_storage: ^13.3.0
image_picker: ^1.2.1
cached_network_image: ^3.3.1
shimmer: ^3.0.0
awesome_notifications: ^0.11.0
package_info_plus: ^9.0.1
url_launcher: ^6.3.2
```

## 🚀 أوامر مهمة

```bash
# تشغيل
flutter run

# تحليل
flutter analyze

# تنظيف
flutter clean && flutter pub get

# بناء APK
flutter build apk --release

# بناء AAB للنشر
flutter build appbundle --release
```

## 📝 ملاحظات إضافية

- المشروع في إصدار 0.1.0+3
- Min SDK Android: 21
- اسم الحزمة: com.ofoqgames.turfwar
- Firebase project مرتبط ومفعّل
- في functions/index.js منطق server-side مهم (لا تتجاهله)
