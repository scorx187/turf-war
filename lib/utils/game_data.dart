// المسار: lib/utils/game_data.dart

import 'package:flutter/material.dart';

class GameData {
  static const List<String> crimeToolsList = [
    'crowbar', 'slim_jim', 'jammer', 'lockpick', 'glass_cutter',
    'laptop', 'thermite', 'stethoscope', 'hydraulic', 'emp_device',
    't_aladdin_lamp', 't_aladdin_carpet' // 🟢 أدوات علاء الدين
  ];

  static const Map<String, int> businessBaseIncome = {
    'coffee_stand': 120, 'mini_market': 400, 'car_wash': 800, 'fast_food': 1800,
    'nightclub': 3000, 'auto_shop': 6000, 'light_weapons': 14000, 'security_firm': 25000,
    'shell_company': 40000, 'local_casino': 55000, 'smuggling_net': 85000,
    'private_bank': 140000, 'city_casino': 220000, 'shipping_port': 340000,
    'airline': 600000, 'heavy_weapons': 1100000, 'telecom': 2000000,
    'cartel': 3400000, 'oil_company': 6000000, 'shadow_bank': 18000000,
  };

  static const Map<String, int> propertyRentIncome = {
    'shack': 150, 'tent': 500, 'wooden_cabin': 1500, 'small_apt': 2500, 'apartment': 4500,
    'loft': 8000, 'penthouse': 15000, 'suburban': 25000, 'villa': 45000, 'classic_manor': 70000,
    'beach_house': 100000, 'horse_ranch': 140000, 'royal_mansion': 180000, 'private_estate': 250000,
    'skyscraper': 350000, 'island': 500000, 'castle': 1000000, 'resort': 1800000,
    'space_station': 4000000, 'mafia_empire': 10000000,
  };

  static const List<Map<String, dynamic>> residentialProperties = [
    {
      'id': 'shack', 'name': 'غرفة في زقاق', 'description': 'غرفة ضيقة ومظلمة في أحد الأزقة الخلفية، تكفي فقط لإخفاء رأسك من الشرطة.',
      'price': 5000, 'happiness': 50, 'icon': Icons.meeting_room, 'color': Colors.grey
    },
    {
      'id': 'tent', 'name': 'نزل شعبي رخيص', 'description': 'غرفة متواضعة في نزل قديم، جدرانها رقيقة بالكاد تمنع برد الشتاء.',
      'price': 25000, 'happiness': 100, 'icon': Icons.bed, 'color': Colors.brown
    },
    {
      'id': 'wooden_cabin', 'name': 'مقصورة خشبية مخفية', 'description': 'ملاذ ريفي بعيد عن صخب المدينة، ممتاز لتخزين البضائع المهربة والراحة.',
      'price': 75000, 'happiness': 180, 'icon': Icons.home_outlined, 'color': Colors.orangeAccent
    },
    {
      'id': 'small_apt', 'name': 'شقة في حي العمال', 'description': 'شقة صغيرة في مبنى مزدحم، توفر لك تغطية ممتازة بين عامة الناس.',
      'price': 150000, 'happiness': 250, 'icon': Icons.apartment, 'color': Colors.blueGrey
    },
    {
      'id': 'apartment', 'name': 'شقة بوسط المدينة', 'description': 'شقة أنيقة قريبة من مراكز الأعمال، مثالية لإدارة عملياتك اليومية.',
      'price': 300000, 'happiness': 350, 'icon': Icons.business, 'color': Colors.blueAccent
    },
    {
      'id': 'loft', 'name': 'دور علوي واسع (Loft)', 'description': 'مساحة واسعة في الطابق العلوي لمصنع قديم، تم تحويلها لمقر سري ومريح.',
      'price': 600000, 'happiness': 450, 'icon': Icons.weekend, 'color': Colors.teal
    },
    {
      'id': 'penthouse', 'name': 'جناح فندقي فاخر', 'description': 'إقامة دائمة في أرقى فنادق المدينة، مع خدمة ممتازة وخصوصية تامة للزعماء.',
      'price': 1200000, 'happiness': 600, 'icon': Icons.location_city, 'color': Colors.indigoAccent
    },
    {
      'id': 'suburban', 'name': 'منزل بضاحية هادئة', 'description': 'منزل أنيق بحديقة خلفية، يبعدك عن شبهات الشرطة ويمنحك واجهة محترمة.',
      'price': 2500000, 'happiness': 750, 'icon': Icons.house, 'color': Colors.lightGreen
    },
    {
      'id': 'villa', 'name': 'فيلا بطراز الآرت ديكو', 'description': 'فيلا فخمة بتصميم عصري لحقبة العشرينات، تعكس ذوقك الرفيع ومكانتك الصاعدة.',
      'price': 5000000, 'happiness': 900, 'icon': Icons.villa, 'color': Colors.green
    },
    {
      'id': 'classic_manor', 'name': 'قصر كلاسيكي عتيق', 'description': 'قصر مهيب بأسوار عالية وتصميم فيكتوري، يليق بزعيم يفرض احترامه على الجميع.',
      'price': 8000000, 'happiness': 1100, 'icon': Icons.account_balance, 'color': Colors.brown
    },
    {
      'id': 'beach_house', 'name': 'قصر شاطئي', 'description': 'ملاذ فاخر على الساحل، يوفر لك الهدوء وميناءً خاصاً لرسو قوارب التهريب ليلاً.',
      'price': 12000000, 'happiness': 1300, 'icon': Icons.beach_access, 'color': Colors.cyan
    },
    {
      'id': 'horse_ranch', 'name': 'مزرعة خيول شاسعة', 'description': 'مزرعة ضخمة للخيول الأصيلة، واجهة مثالية لغسيل الأموال وتوسيع نفوذك.',
      'price': 18000000, 'happiness': 1500, 'icon': Icons.agriculture, 'color': Colors.lime
    },
    {
      'id': 'royal_mansion', 'name': 'قصر مخملي', 'description': 'قصر ضخم مليء بالثريات والرخام، يستضيف كبار رجال السياسة والمال لتوقيع الصفقات.',
      'price': 25000000, 'happiness': 1800, 'icon': Icons.castle, 'color': Colors.purpleAccent
    },
    {
      'id': 'private_estate', 'name': 'عزبة خاصة محصنة', 'description': 'مساحة شاسعة من الأراضي بداخلها قصرك وحرسك الخاص، أشبه بدولة داخل دولة.',
      'price': 40000000, 'happiness': 2100, 'icon': Icons.landscape, 'color': Colors.green
    },
    {
      'id': 'skyscraper', 'name': 'برج تجاري كامل', 'description': 'ناطحة سحاب في قلب المدينة تملكها بالكامل، تطل على إمبراطوريتك من الأعلى.',
      'price': 65000000, 'happiness': 2400, 'icon': Icons.domain, 'color': Colors.blueGrey
    },
    {
      'id': 'island', 'name': 'جزيرة معزولة', 'description': 'جزيرة خاصة لا يجرؤ أحد على الاقتراب منها، ملاذك الآمن والمطلق لجمع رجالك.',
      'price': 100000000, 'happiness': 2800, 'icon': Icons.holiday_village, 'color': Colors.amber
    },
    {
      'id': 'castle', 'name': 'قلعة جبلية', 'description': 'قلعة تاريخية تم تجديدها، محصنة بقوة ضد أي هجوم مفاجئ من السلطات أو المنافسين.',
      'price': 250000000, 'happiness': 3100, 'icon': Icons.fort, 'color': Colors.deepPurple
    },
    {
      'id': 'resort', 'name': 'نادي ريفي حصري', 'description': 'نادي فاره لأثرياء العالم، أنت تملكه وتدير صفقات المافيا من خلف كواليسه الفخمة.',
      'price': 500000000, 'happiness': 3500, 'icon': Icons.pool, 'color': Colors.lightBlueAccent
    },
    {
      'id': 'space_station', 'name': 'مقر القيادة المحصن', 'description': 'مقر عمليات سري لا يمكن اكتشافه، مزود بأحدث تقنيات العشرينات الدفاعية.',
      'price': 1500000000, 'happiness': 3800, 'icon': Icons.security, 'color': Colors.deepOrange
    },
    {
      'id': 'mafia_empire', 'name': 'إمبراطورية الزعيم', 'description': 'عرش العالم السفلي! قصر أسطوري لا يمتلكه إلا الحاكم الفعلي والمطلق للمدينة.',
      'price': 5000000000, 'happiness': 4000, 'icon': Icons.star, 'color': Colors.redAccent
    },
  ];

  // 🟢 ترقيات العقارات السكنية 🟢
  static const Map<String, Map<String, dynamic>> propertyUpgradesData = {
    'luxury_furniture': {'name': 'أثاث فاخر', 'priceMultiplier': 0.1, 'desc': 'يمنحك السكن في هذا العقار 20% سعادة إضافية.', 'icon': Icons.weekend},
    'security_guards': {'name': 'حراسة مسلحة', 'priceMultiplier': 0.15, 'desc': 'يقلل سرعة تهالك وخراب العقار بنسبة 50%.', 'icon': Icons.security},
    'hidden_vault': {'name': 'قبو سري', 'priceMultiplier': 0.2, 'desc': 'يعطيك هيبة ونفوذ إضافي بين العصابات.', 'icon': Icons.lock},
  };

  static const List<Map<String, dynamic>> businessData = [
    {
      'id': 'coffee_stand', 'name': 'كشك لبيع الصحف والتبغ', 'description': 'واجهة مثالية لجمع المعلومات ومراقبة تحركات أفراد الشرطة في الشوارع.',
      'maxLevel': 75, 'basePrice': 10000, 'icon': Icons.menu_book, 'color': Colors.brown
    },
    {
      'id': 'mini_market', 'name': 'متجر بقالة محلي', 'description': 'متجر متواضع يستخدم كواجهة لغسيل الأموال الناتجة عن الجرائم الصغرى.',
      'maxLevel': 70, 'basePrice': 40000, 'icon': Icons.store, 'color': Colors.orange
    },
    {
      'id': 'car_wash', 'name': 'محطة وقود ومستودع', 'description': 'نقطة استراتيجية لتزويد مركبات العصابة بالوقود وتخزين البضائع المهربة.',
      'maxLevel': 65, 'basePrice': 100000, 'icon': Icons.local_gas_station, 'color': Colors.cyan
    },
    {
      'id': 'fast_food', 'name': 'مخبز وحلويات', 'description': 'واجهة كلاسيكية لأعمال المافيا الإيطالية، تدر أرباحاً هادئة ومستقرة.',
      'maxLevel': 60, 'basePrice': 250000, 'icon': Icons.bakery_dining, 'color': Colors.red
    },
    {
      'id': 'nightclub', 'name': 'الملهى الليلي', 'description': 'مكان صاخب يجتمع فيه كبار الشخصيات، ويعد مركزاً رئيسياً لعقد الصفقات المشبوهة.',
      'maxLevel': 55, 'basePrice': 500000, 'icon': Icons.nightlife, 'color': Colors.purpleAccent
    },
    {
      'id': 'auto_shop', 'name': 'ورشة إصلاح المركبات', 'description': 'ورشة متخصصة في تعديل سيارات الهروب وتزوير لوحاتها بعيداً عن الأعين.',
      'maxLevel': 50, 'basePrice': 1000000, 'icon': Icons.build, 'color': Colors.blueGrey
    },
    {
      'id': 'light_weapons', 'name': 'متجر أدوات الصيد', 'description': 'واجهة قانونية لبيع وتوزيع الأسلحة النارية الخفيفة على رجال العصابة الموثوقين.',
      'maxLevel': 45, 'basePrice': 2500000, 'icon': Icons.precision_manufacturing, 'color': Colors.redAccent
    },
    {
      'id': 'security_firm', 'name': 'وكالة حراسات ليلية', 'description': 'مؤسسة لفرض الإتاوات وتوفير الحماية الإجبارية لأصحاب المحلات التجارية.',
      'maxLevel': 40, 'basePrice': 5000000, 'icon': Icons.security, 'color': Colors.blue
    },
    {
      'id': 'shell_company', 'name': 'شركة استيراد وتصدير', 'description': 'الطريقة المثلى والتقليدية لإخفاء وتمرير الأموال الطائلة عبر الحدود.',
      'maxLevel': 35, 'basePrice': 8000000, 'icon': Icons.business_center, 'color': Colors.grey
    },
    {
      'id': 'local_casino', 'name': 'صالة مراهنات سرية', 'description': 'غرفة خفية تعج بألعاب الورق والمراهنات بعيداً عن أعين المحققين والسلطات.',
      'maxLevel': 30, 'basePrice': 12000000, 'icon': Icons.casino, 'color': Colors.amber
    },
    {
      'id': 'smuggling_net', 'name': 'شبكة تهريب دولية', 'description': 'منظومة معقدة لتهريب البضائع المحظورة والممنوعات وتوزيعها في الخفاء.',
      'maxLevel': 25, 'basePrice': 20000000, 'icon': Icons.local_shipping, 'color': Colors.teal
    },
    {
      'id': 'private_bank', 'name': 'مصرف ائتماني محلي', 'description': 'مؤسسة مالية صغيرة تغض الطرف عن مصادر أموالك المشبوهة وتسهل أعمالك.',
      'maxLevel': 20, 'basePrice': 35000000, 'icon': Icons.account_balance, 'color': Colors.green
    },
    {
      'id': 'city_casino', 'name': 'نادي القمار الفاخر', 'description': 'كازينو باذخ يرتاده الساسة وكبار تجار المدينة، يدر أرباحاً هائلة.',
      'maxLevel': 15, 'basePrice': 60000000, 'icon': Icons.monetization_on, 'color': Colors.amberAccent
    },
    {
      'id': 'shipping_port', 'name': 'أرصفة الشحن والتفريغ', 'description': 'السيطرة التامة على حركة السفن التجارية وعمليات التهريب البحري الكبرى.',
      'maxLevel': 12, 'basePrice': 100000000, 'icon': Icons.directions_boat, 'color': Colors.blueAccent
    },
    {
      'id': 'airline', 'name': 'شركة السكك الحديدية', 'description': 'شريان النقل البري الأساسي، يضمن لك السيطرة على خطوط الإمداد والتوزيع.',
      'maxLevel': 10, 'basePrice': 200000000, 'icon': Icons.train, 'color': Colors.lightBlue
    },
    {
      'id': 'heavy_weapons', 'name': 'مصنع صلب وذخائر', 'description': 'منشأة صناعية ضخمة لتزويد عصابات المدينة بالعتاد الثقيل والأسلحة.',
      'maxLevel': 8, 'basePrice': 400000000, 'icon': Icons.hardware, 'color': Colors.deepOrange
    },
    {
      'id': 'telecom', 'name': 'شبكة البرق والبريد', 'description': 'سنترال يتيح لك مراقبة اتصالات الشرطة واعتراض رسائل العصابات المنافسة.',
      'maxLevel': 6, 'basePrice': 800000000, 'icon': Icons.tty, 'color': Colors.lightGreen
    },
    {
      'id': 'cartel', 'name': 'نقابة الجريمة المنظمة', 'description': 'تحالف إجرامي واسع يفرض سيطرته المطلقة على اقتصاد الولاية بالكامل.',
      'maxLevel': 5, 'basePrice': 1500000000, 'icon': Icons.public, 'color': Colors.deepPurple
    },
    {
      'id': 'oil_company', 'name': 'شركة تنقيب عن النفط', 'description': 'الذهب الأسود الذي يصنع ثروات طائلة ويمنحك نفوذاً سياسياً واقتصادياً.',
      'maxLevel': 4, 'basePrice': 3000000000, 'icon': Icons.oil_barrel, 'color': Colors.black
    },
    {
      'id': 'shadow_bank', 'name': 'البنك المركزي السري', 'description': 'المركز المالي الخفي لأباطرة العالم السفلي، يتحكم في اقتصاد الظل بأسره.',
      'maxLevel': 3, 'basePrice': 10000000000, 'icon': Icons.account_balance_wallet, 'color': Colors.amber
    },
  ];

  static const Map<String, Map<String, double>> weaponStats = {
    'dagger': {'str': 0.15, 'spd': 0.25}, 'revolver': {'str': 0.40, 'spd': 0.40}, 'katana': {'str': 0.90, 'spd': 0.60}, 'shotgun': {'str': 1.90, 'spd': 0.60}, 'sniper': {'str': 2.70, 'spd': 0.80},
    'w_silver_heavy': {'str': 0.30, 'spd': 0.10}, 'w_silver_assault': {'str': 0.25, 'spd': 0.15}, 'w_silver_balanced': {'str': 0.20, 'spd': 0.20}, 'w_silver_tactical': {'str': 0.15, 'spd': 0.25}, 'w_silver_agile': {'str': 0.10, 'spd': 0.30}, 'w_green_heavy': {'str': 0.60, 'spd': 0.20}, 'w_green_assault': {'str': 0.50, 'spd': 0.30}, 'w_green_balanced': {'str': 0.40, 'spd': 0.40}, 'w_green_tactical': {'str': 0.30, 'spd': 0.50}, 'w_green_agile': {'str': 0.20, 'spd': 0.60}, 'w_blue_heavy': {'str': 1.10, 'spd': 0.40}, 'w_blue_assault': {'str': 0.90, 'spd': 0.60}, 'w_blue_balanced': {'str': 0.75, 'spd': 0.75}, 'w_blue_tactical': {'str': 0.60, 'spd': 0.90}, 'w_blue_agile': {'str': 0.40, 'spd': 1.10}, 'w_purple_heavy': {'str': 1.90, 'spd': 0.60}, 'w_purple_assault': {'str': 1.50, 'spd': 1.00}, 'w_purple_balanced': {'str': 1.25, 'spd': 1.25}, 'w_purple_tactical': {'str': 1.00, 'spd': 1.50}, 'w_purple_agile': {'str': 0.60, 'spd': 1.90}, 'w_gold_heavy': {'str': 2.70, 'spd': 0.80}, 'w_gold_assault': {'str': 2.10, 'spd': 1.40}, 'w_gold_balanced': {'str': 1.75, 'spd': 1.75}, 'w_gold_tactical': {'str': 1.40, 'spd': 2.10}, 'w_gold_agile': {'str': 0.80, 'spd': 2.70}, 'w_red_heavy': {'str': 3.60, 'spd': 0.90}, 'w_red_assault': {'str': 2.70, 'spd': 1.80}, 'w_red_balanced': {'str': 2.25, 'spd': 2.25}, 'w_red_tactical': {'str': 1.80, 'spd': 2.70}, 'w_red_agile': {'str': 0.90, 'spd': 3.60},
    'w_aladdin_damage': {'str': 5.00, 'spd': 1.00}, // سيف علاء الدين القاطع (ضرر هائل 500%)
    'w_aladdin_accuracy': {'str': 1.00, 'spd': 5.00}, // خنجر علاء الدين السحري (دقة 500%)
  };

  static const Map<String, Map<String, double>> armorStats = {
    'riot_shield': {'def': 0.60, 'skl': 0.20}, 'kevlar_vest': {'def': 0.75, 'skl': 0.75}, 'ninja_suit': {'def': 0.60, 'skl': 1.90}, 'steel_armor': {'def': 1.90, 'skl': 0.60}, 'exoskeleton': {'def': 1.75, 'skl': 1.75}, 'a_silver_heavy': {'def': 0.30, 'skl': 0.10}, 'a_silver_assault': {'def': 0.25, 'skl': 0.15}, 'a_silver_balanced': {'def': 0.20, 'skl': 0.20}, 'a_silver_tactical': {'def': 0.15, 'skl': 0.25}, 'a_silver_agile': {'def': 0.10, 'skl': 0.30}, 'a_green_heavy': {'def': 0.60, 'skl': 0.20}, 'a_green_assault': {'def': 0.50, 'skl': 0.30}, 'a_green_balanced': {'def': 0.40, 'skl': 0.40}, 'a_green_tactical': {'def': 0.30, 'skl': 0.50}, 'a_green_agile': {'def': 0.20, 'skl': 0.60}, 'a_blue_heavy': {'def': 1.10, 'skl': 0.40}, 'a_blue_assault': {'def': 0.90, 'skl': 0.60}, 'a_blue_balanced': {'def': 0.75, 'skl': 0.75}, 'a_blue_tactical': {'def': 0.60, 'skl': 0.90}, 'a_blue_agile': {'def': 0.40, 'skl': 1.10}, 'a_purple_heavy': {'def': 1.90, 'skl': 0.60}, 'a_purple_assault': {'def': 1.50, 'skl': 1.00}, 'a_purple_balanced': {'def': 1.25, 'skl': 1.25}, 'a_purple_tactical': {'def': 1.00, 'skl': 1.50}, 'a_purple_agile': {'def': 0.60, 'skl': 1.90}, 'a_gold_heavy': {'def': 2.70, 'skl': 0.80}, 'a_gold_assault': {'def': 2.10, 'skl': 1.40}, 'a_gold_balanced': {'def': 1.75, 'skl': 1.75}, 'a_gold_tactical': {'def': 1.40, 'skl': 2.10}, 'a_gold_agile': {'def': 0.80, 'skl': 2.70}, 'a_red_heavy': {'def': 3.60, 'skl': 0.90}, 'a_red_assault': {'def': 2.70, 'skl': 1.80}, 'a_red_balanced': {'def': 2.25, 'skl': 2.25}, 'a_red_tactical': {'def': 1.80, 'skl': 2.70}, 'a_red_agile': {'def': 0.90, 'skl': 3.60},
    'a_aladdin_defense': {'def': 5.00, 'skl': 1.00}, // درع الجني الفولاذي (دفاع جبار 500%)
    'a_aladdin_evasion': {'def': 1.00, 'skl': 5.00}, // عباءة علاء الدين (تفادي للضربات 500%)
  };

  // 🟢 شجرة الامتيازات (Perks) - تم إزالة القديم والإبقاء على الجديد فقط 🟢
  static const List<Map<String, dynamic>> perksList = [
    {'id': 'base_str', 'name': 'عضلات مفتولة', 'desc': 'يزيد قوتك الأساسية بنسبة 1% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.fitness_center, 'color': Colors.red},
    {'id': 'base_def', 'name': 'عظام صلبة', 'desc': 'يزيد دفاعك الأساسي بنسبة 1% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.shield, 'color': Colors.blue},
    {'id': 'base_spd', 'name': 'ردة فعل سريعة', 'desc': 'يزيد سرعتك الأساسية بنسبة 1% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.directions_run, 'color': Colors.orange},
    {'id': 'base_skl', 'name': 'عين الصقر', 'desc': 'يزيد مهارتك الأساسية بنسبة 1% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.my_location, 'color': Colors.green},
    {'id': 'weapon_master', 'name': 'خبير أسلحة', 'desc': 'يزيد ضرر السلاح المجهز بنسبة 5% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.hardware, 'color': Colors.deepOrange},
    {'id': 'armor_master', 'name': 'خبير دروع', 'desc': 'يزيد دفاع الدرع المجهز بنسبة 5% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.security, 'color': Colors.blueGrey},
    {'id': 'max_hp_boost', 'name': 'لياقة بدنية', 'desc': 'يزيد الصحة القصوى بنسبة 2% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.favorite, 'color': Colors.pink},
    {'id': 'max_energy_boost', 'name': 'طاقة لا تنضب', 'desc': 'يزيد الحد الأقصى للطاقة بمقدار +2 لكل مستوى.', 'maxLevel': 10, 'icon': Icons.bolt, 'color': Colors.yellowAccent},
    {'id': 'max_courage_boost', 'name': 'قلب ميت', 'desc': 'يزيد الحد الأقصى للشجاعة بمقدار +1 لكل مستوى.', 'maxLevel': 10, 'icon': Icons.local_fire_department, 'color': Colors.deepOrangeAccent},
    {'id': 'crime_master', 'name': 'عقل مدبر', 'desc': 'يزيد نسبة النجاح وعوائد الجريمة بنسبة 3% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.account_balance_wallet, 'color': Colors.teal},
    {'id': 'fast_recovery', 'name': 'تعافي سريع', 'desc': 'يقلل مدة البقاء في المستشفى بنسبة 5% لكل مستوى.', 'maxLevel': 10, 'icon': Icons.local_hospital, 'color': Colors.redAccent},
  ];
}