// المسار: lib/utils/game_data.dart

import 'package:flutter/material.dart'; // 🟢 ضروري عشان الألوان والأيقونات 🟢

class GameData {
  static const List<String> crimeToolsList = [
    'crowbar', 'slim_jim', 'jammer', 'lockpick', 'glass_cutter',
    'laptop', 'thermite', 'stethoscope', 'hydraulic', 'emp_device'
  ];

  // 🟢 الدخل الأساسي للمشاريع التجارية (بالساعة)
  static const Map<String, int> businessBaseIncome = {
    'coffee_stand': 300, 'mini_market': 1000, 'car_wash': 2200, 'fast_food': 4500,
    'nightclub': 8000, 'auto_shop': 15000, 'light_weapons': 35000, 'security_firm': 65000,
    'shell_company': 100000, 'local_casino': 140000, 'smuggling_net': 220000,
    'private_bank': 350000, 'city_casino': 550000, 'shipping_port': 850000,
    'airline': 1500000, 'heavy_weapons': 2800000, 'telecom': 5000000,
    'cartel': 8500000, 'oil_company': 15000000, 'shadow_bank': 45000000,
  };

  // 🟢 دخل إيجار العقارات السكنية للنظام (بالساعة)
  static const Map<String, int> propertyRentIncome = {
    'shack': 150, 'tent': 500, 'wooden_cabin': 1500, 'small_apt': 2500, 'apartment': 4500,
    'loft': 8000, 'penthouse': 15000, 'suburban': 25000, 'villa': 45000, 'classic_manor': 70000,
    'beach_house': 100000, 'horse_ranch': 140000, 'royal_mansion': 180000, 'private_estate': 250000,
    'skyscraper': 350000, 'island': 500000, 'castle': 1000000, 'resort': 1800000,
    'space_station': 4000000, 'mafia_empire': 10000000,
  };

  // 🟢 قائمة العقارات السكنية 🟢
  static const List<Map<String, dynamic>> residentialProperties = [
    {'id': 'shack', 'name': 'غرفة بسيطة', 'description': 'بداية متواضعة جداً.', 'price': 5000, 'happiness': 50, 'icon': Icons.meeting_room, 'color': Colors.grey},
    {'id': 'tent', 'name': 'خيمة بسيطة', 'description': 'توفر لك الحد الأدنى.', 'price': 25000, 'happiness': 100, 'icon': Icons.holiday_village_outlined, 'color': Colors.brown},
    {'id': 'wooden_cabin', 'name': 'كوخ خشبي', 'description': 'كوخ ريفي هادئ.', 'price': 75000, 'happiness': 180, 'icon': Icons.home_outlined, 'color': Colors.orangeAccent},
    {'id': 'small_apt', 'name': 'شقة صغيرة', 'description': 'شقة في حي شعبي.', 'price': 150000, 'happiness': 250, 'icon': Icons.apartment, 'color': Colors.blueGrey},
    {'id': 'apartment', 'name': 'شقة وسط المدينة', 'description': 'مريحة وعملية.', 'price': 300000, 'happiness': 350, 'icon': Icons.business, 'color': Colors.blueAccent},
    {'id': 'loft', 'name': 'دور علوي', 'description': 'مساحة مفتوحة حديثة.', 'price': 600000, 'happiness': 450, 'icon': Icons.weekend, 'color': Colors.teal},
    {'id': 'penthouse', 'name': 'بنتهاوس فاخر', 'description': 'إطلالة خلابة.', 'price': 1200000, 'happiness': 600, 'icon': Icons.location_city, 'color': Colors.indigoAccent},
    {'id': 'suburban', 'name': 'منزل ريفي', 'description': 'هادئ مع حديقة.', 'price': 2500000, 'happiness': 750, 'icon': Icons.house, 'color': Colors.lightGreen},
    {'id': 'villa', 'name': 'فيلا حديثة', 'description': 'حديقة ومسابح.', 'price': 5000000, 'happiness': 900, 'icon': Icons.villa, 'color': Colors.green},
    {'id': 'classic_manor', 'name': 'قصر كلاسيكي', 'description': 'تصميم قديم وأصيل.', 'price': 8000000, 'happiness': 1100, 'icon': Icons.account_balance, 'color': Colors.brown},
    {'id': 'beach_house', 'name': 'منزل شاطئي', 'description': 'صوت الأمواج.', 'price': 12000000, 'happiness': 1300, 'icon': Icons.beach_access, 'color': Colors.cyan},
    {'id': 'horse_ranch', 'name': 'مزرعة خيول', 'description': 'لعشاق الخيول.', 'price': 18000000, 'happiness': 1500, 'icon': Icons.agriculture, 'color': Colors.lime},
    {'id': 'royal_mansion', 'name': 'قصر ملكي', 'description': 'سكن العظماء.', 'price': 25000000, 'happiness': 1800, 'icon': Icons.castle, 'color': Colors.purpleAccent},
    {'id': 'private_estate', 'name': 'عزبة خاصة', 'description': 'خصوصية تامة.', 'price': 40000000, 'happiness': 2100, 'icon': Icons.landscape, 'color': Colors.green},
    {'id': 'skyscraper', 'name': 'ناطحة سحاب', 'description': 'برج كامل لك.', 'price': 65000000, 'happiness': 2400, 'icon': Icons.domain, 'color': Colors.blueGrey},
    {'id': 'island', 'name': 'جزيرة خاصة', 'description': 'جنة على الأرض.', 'price': 100000000, 'happiness': 2800, 'icon': Icons.holiday_village, 'color': Colors.amber},
    {'id': 'castle', 'name': 'قلعة تاريخية', 'description': 'حصن في الجبل.', 'price': 250000000, 'happiness': 3100, 'icon': Icons.fort, 'color': Colors.deepPurple},
    {'id': 'resort', 'name': 'منتجع سياحي', 'description': 'لراحتك الشخصية.', 'price': 500000000, 'happiness': 3500, 'icon': Icons.pool, 'color': Colors.lightBlueAccent},
    {'id': 'space_station', 'name': 'محطة فضائية', 'description': 'قمة الترف.', 'price': 1500000000, 'happiness': 3800, 'icon': Icons.rocket_launch, 'color': Colors.deepOrange},
    {'id': 'mafia_empire', 'name': 'إمبراطورية الزعيم', 'description': 'المقر الرئيسي.', 'price': 5000000000, 'happiness': 4000, 'icon': Icons.star, 'color': Colors.redAccent},
  ];

  // 🟢 قائمة المشاريع التجارية 🟢
  static const List<Map<String, dynamic>> businessData = [
    {'id': 'coffee_stand', 'name': 'كشك قهوة', 'maxLevel': 75, 'basePrice': 10000, 'icon': Icons.coffee, 'color': Colors.brown},
    {'id': 'mini_market', 'name': 'بقالة صغيرة', 'maxLevel': 70, 'basePrice': 40000, 'icon': Icons.store, 'color': Colors.orange},
    {'id': 'car_wash', 'name': 'مغسلة سيارات', 'maxLevel': 65, 'basePrice': 100000, 'icon': Icons.local_car_wash, 'color': Colors.cyan},
    {'id': 'fast_food', 'name': 'مطعم وجبات', 'maxLevel': 60, 'basePrice': 250000, 'icon': Icons.fastfood, 'color': Colors.red},
    {'id': 'nightclub', 'name': 'ملهى ليلي', 'maxLevel': 55, 'basePrice': 500000, 'icon': Icons.nightlife, 'color': Colors.purpleAccent},
    {'id': 'auto_shop', 'name': 'ورشة سيارات', 'maxLevel': 50, 'basePrice': 1000000, 'icon': Icons.build, 'color': Colors.blueGrey},
    {'id': 'light_weapons', 'name': 'أسلحة خفيفة', 'maxLevel': 45, 'basePrice': 2500000, 'icon': Icons.precision_manufacturing, 'color': Colors.redAccent},
    {'id': 'security_firm', 'name': 'شركة حراسات', 'maxLevel': 40, 'basePrice': 5000000, 'icon': Icons.security, 'color': Colors.blue},
    {'id': 'shell_company', 'name': 'شركة واجهة', 'maxLevel': 35, 'basePrice': 8000000, 'icon': Icons.business_center, 'color': Colors.grey},
    {'id': 'local_casino', 'name': 'كازينو محلي', 'maxLevel': 30, 'basePrice': 12000000, 'icon': Icons.casino, 'color': Colors.amber},
    {'id': 'smuggling_net', 'name': 'شبكة تهريب', 'maxLevel': 25, 'basePrice': 20000000, 'icon': Icons.local_shipping, 'color': Colors.teal},
    {'id': 'private_bank', 'name': 'بنك خاص', 'maxLevel': 20, 'basePrice': 35000000, 'icon': Icons.account_balance, 'color': Colors.green},
    {'id': 'city_casino', 'name': 'كازينو المدينة', 'maxLevel': 15, 'basePrice': 60000000, 'icon': Icons.monetization_on, 'color': Colors.amberAccent},
    {'id': 'shipping_port', 'name': 'ميناء شحن', 'maxLevel': 12, 'basePrice': 100000000, 'icon': Icons.directions_boat, 'color': Colors.blueAccent},
    {'id': 'airline', 'name': 'شركة طيران', 'maxLevel': 10, 'basePrice': 200000000, 'icon': Icons.flight, 'color': Colors.lightBlue},
    {'id': 'heavy_weapons', 'name': 'أسلحة ثقيلة', 'maxLevel': 8, 'basePrice': 400000000, 'icon': Icons.hardware, 'color': Colors.deepOrange},
    {'id': 'telecom', 'name': 'شبكة اتصالات', 'maxLevel': 6, 'basePrice': 800000000, 'icon': Icons.cell_tower, 'color': Colors.lightGreen},
    {'id': 'cartel', 'name': 'كارتل دولي', 'maxLevel': 5, 'basePrice': 1500000000, 'icon': Icons.public, 'color': Colors.deepPurple},
    {'id': 'oil_company', 'name': 'شركة نفط', 'maxLevel': 4, 'basePrice': 3000000000, 'icon': Icons.oil_barrel, 'color': Colors.black},
    {'id': 'shadow_bank', 'name': 'البنك الموازي', 'maxLevel': 3, 'basePrice': 10000000000, 'icon': Icons.account_balance_wallet, 'color': Colors.amber},
  ];

  static const Map<String, Map<String, double>> weaponStats = {
    'dagger': {'str': 0.15, 'spd': 0.25}, 'revolver': {'str': 0.40, 'spd': 0.40}, 'katana': {'str': 0.90, 'spd': 0.60}, 'shotgun': {'str': 1.90, 'spd': 0.60}, 'sniper': {'str': 2.70, 'spd': 0.80},
    'w_silver_heavy': {'str': 0.30, 'spd': 0.10}, 'w_silver_assault': {'str': 0.25, 'spd': 0.15}, 'w_silver_balanced': {'str': 0.20, 'spd': 0.20}, 'w_silver_tactical': {'str': 0.15, 'spd': 0.25}, 'w_silver_agile': {'str': 0.10, 'spd': 0.30}, 'w_green_heavy': {'str': 0.60, 'spd': 0.20}, 'w_green_assault': {'str': 0.50, 'spd': 0.30}, 'w_green_balanced': {'str': 0.40, 'spd': 0.40}, 'w_green_tactical': {'str': 0.30, 'spd': 0.50}, 'w_green_agile': {'str': 0.20, 'spd': 0.60}, 'w_blue_heavy': {'str': 1.10, 'spd': 0.40}, 'w_blue_assault': {'str': 0.90, 'spd': 0.60}, 'w_blue_balanced': {'str': 0.75, 'spd': 0.75}, 'w_blue_tactical': {'str': 0.60, 'spd': 0.90}, 'w_blue_agile': {'str': 0.40, 'spd': 1.10}, 'w_purple_heavy': {'str': 1.90, 'spd': 0.60}, 'w_purple_assault': {'str': 1.50, 'spd': 1.00}, 'w_purple_balanced': {'str': 1.25, 'spd': 1.25}, 'w_purple_tactical': {'str': 1.00, 'spd': 1.50}, 'w_purple_agile': {'str': 0.60, 'spd': 1.90}, 'w_gold_heavy': {'str': 2.70, 'spd': 0.80}, 'w_gold_assault': {'str': 2.10, 'spd': 1.40}, 'w_gold_balanced': {'str': 1.75, 'spd': 1.75}, 'w_gold_tactical': {'str': 1.40, 'spd': 2.10}, 'w_gold_agile': {'str': 0.80, 'spd': 2.70}, 'w_red_heavy': {'str': 3.60, 'spd': 0.90}, 'w_red_assault': {'str': 2.70, 'spd': 1.80}, 'w_red_balanced': {'str': 2.25, 'spd': 2.25}, 'w_red_tactical': {'str': 1.80, 'spd': 2.70}, 'w_red_agile': {'str': 0.90, 'spd': 3.60},
  };

  static const Map<String, Map<String, double>> armorStats = {
    'riot_shield': {'def': 0.60, 'skl': 0.20}, 'kevlar_vest': {'def': 0.75, 'skl': 0.75}, 'ninja_suit': {'def': 0.60, 'skl': 1.90}, 'steel_armor': {'def': 1.90, 'skl': 0.60}, 'exoskeleton': {'def': 1.75, 'skl': 1.75}, 'a_silver_heavy': {'def': 0.30, 'skl': 0.10}, 'a_silver_assault': {'def': 0.25, 'skl': 0.15}, 'a_silver_balanced': {'def': 0.20, 'skl': 0.20}, 'a_silver_tactical': {'def': 0.15, 'skl': 0.25}, 'a_silver_agile': {'def': 0.10, 'skl': 0.30}, 'a_green_heavy': {'def': 0.60, 'skl': 0.20}, 'a_green_assault': {'def': 0.50, 'skl': 0.30}, 'a_green_balanced': {'def': 0.40, 'skl': 0.40}, 'a_green_tactical': {'def': 0.30, 'skl': 0.50}, 'a_green_agile': {'def': 0.20, 'skl': 0.60}, 'a_blue_heavy': {'def': 1.10, 'skl': 0.40}, 'a_blue_assault': {'def': 0.90, 'skl': 0.60}, 'a_blue_balanced': {'def': 0.75, 'skl': 0.75}, 'a_blue_tactical': {'def': 0.60, 'skl': 0.90}, 'a_blue_agile': {'def': 0.40, 'skl': 1.10}, 'a_purple_heavy': {'def': 1.90, 'skl': 0.60}, 'a_purple_assault': {'def': 1.50, 'skl': 1.00}, 'a_purple_balanced': {'def': 1.25, 'skl': 1.25}, 'a_purple_tactical': {'def': 1.00, 'skl': 1.50}, 'a_purple_agile': {'def': 0.60, 'skl': 1.90}, 'a_gold_heavy': {'def': 2.70, 'skl': 0.80}, 'a_gold_assault': {'def': 2.10, 'skl': 1.40}, 'a_gold_balanced': {'def': 1.75, 'skl': 1.75}, 'a_gold_tactical': {'def': 1.40, 'skl': 2.10}, 'a_gold_agile': {'def': 0.80, 'skl': 2.70}, 'a_red_heavy': {'def': 3.60, 'skl': 0.90}, 'a_red_assault': {'def': 2.70, 'skl': 1.80}, 'a_red_balanced': {'def': 2.25, 'skl': 2.25}, 'a_red_tactical': {'def': 1.80, 'skl': 2.70}, 'a_red_agile': {'def': 0.90, 'skl': 3.60},
  };

  // 🟢 شجرة الامتيازات (Perks) 🟢
  static const List<Map<String, dynamic>> perksList = [
    {'id': 'negotiator', 'name': 'مفاوض ذكي', 'desc': 'يقلل أسعار المتجر الأسود بنسبة 5% لكل مستوى.', 'maxLevel': 5, 'icon': Icons.handshake, 'color': Colors.amber},
    {'id': 'iron_body', 'name': 'جسد فولاذي', 'desc': 'يزيد مكاسب التدريب في النادي بنسبة 10% لكل مستوى.', 'maxLevel': 5, 'icon': Icons.fitness_center, 'color': Colors.redAccent},
    {'id': 'corrupt_lawyer', 'name': 'محامي فاسد', 'desc': 'يقلل وقت البقاء في السجن بنسبة 15% لكل مستوى.', 'maxLevel': 3, 'icon': Icons.gavel, 'color': Colors.blueGrey},
    {'id': 'ghost', 'name': 'شبح الشوارع', 'desc': 'يزيد نسبة الهروب من الشرطة (الفشل) بنسبة 5% لكل مستوى.', 'maxLevel': 4, 'icon': Icons.visibility_off, 'color': Colors.purpleAccent},
    {'id': 'thief', 'name': 'نشّال محترف', 'desc': 'يزيد العوائد المالية من الجرائم بنسبة 10% لكل مستوى.', 'maxLevel': 5, 'icon': Icons.money, 'color': Colors.green},
  ];
}