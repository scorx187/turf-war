// المسار: lib/utils/crime_data.dart

import 'package:flutter/material.dart';
import 'dart:math';

class CrimeData {
  static final List<Map<String, dynamic>> categories = [
    {'name': 'جرائم الشوارع', 'icon': Icons.directions_walk, 'color': Colors.brown},
    {'name': 'السرقات البسيطة', 'icon': Icons.shopping_bag, 'color': Colors.grey},
    {'name': 'النشل والسرقة السريعة', 'icon': Icons.account_balance_wallet, 'color': Colors.teal},
    {'name': 'سرقة السيارات الكلاسيكية', 'icon': Icons.directions_car, 'color': Colors.orangeAccent},
    {'name': 'السطو على المنازل', 'icon': Icons.home, 'color': Colors.purpleAccent},
    {'name': 'تهريب البضائع', 'icon': Icons.local_shipping, 'color': Colors.blueGrey},
    {'name': 'سرقة السيارات الفارهة', 'icon': Icons.time_to_leave, 'color': Colors.deepOrange},
    {'name': 'تزوير الوثائق', 'icon': Icons.description, 'color': Colors.lightBlue},
    {'name': 'الجرائم الإلكترونية', 'icon': Icons.computer, 'color': Colors.cyan},
    {'name': 'الابتزاز المالي', 'icon': Icons.monetization_on, 'color': Colors.green},
    {'name': 'السطو المسلح على المتاجر', 'icon': Icons.storefront, 'color': Colors.redAccent},
    {'name': 'تجارة السوق الأسود', 'icon': Icons.shopping_cart, 'color': Colors.black87},
    {'name': 'غسيل الأموال', 'icon': Icons.local_laundry_service, 'color': Colors.indigo},
    {'name': 'اختراق الحسابات البنكية', 'icon': Icons.security, 'color': Colors.blue},
    {'name': 'السطو على البنوك المحلية', 'icon': Icons.account_balance, 'color': Colors.red},
    {'name': 'تهريب الأسلحة', 'icon': Icons.construction, 'color': Colors.brown.shade800},
    {'name': 'السيطرة على الكازينوهات', 'icon': Icons.casino, 'color': Colors.amber},
    {'name': 'اختطاف الشخصيات الهامة', 'icon': Icons.person_off, 'color': Colors.deepPurple},
    {'name': 'السطو على البنوك المركزية', 'icon': Icons.museum, 'color': Colors.red.shade900},
    {'name': 'الجرائم الدولية', 'icon': Icons.public, 'color': Colors.yellowAccent},
  ];

  // دالة ذكية لتوليد أسماء الجرائم بناءً على نوع الفئة ومستوى الجريمة (0-19)
  static String _getThematicCrimeName(int catIndex, int i) {
    String catName = categories[catIndex]['name'];

    // قائمة بمستويات الأهداف تتدرج من الأسهل للأصعب (20 مستوى)
    List<String> targetLevels = [
      'هدف سهل', 'هدف بسيط', 'هدف مبتدئ', 'هدف عادي', 'هدف محلي',
      'هدف معروف', 'هدف تجاري', 'هدف محروس', 'هدف صعب', 'هدف معقد',
      'هدف متقدم', 'هدف خطير', 'هدف مهم', 'شديد الحراسة', 'هدف إقليمي',
      'هدف وطني', 'هدف دولي', 'فائق الخطورة', 'هدف أسطوري', 'عملية مستحيلة'
    ];

    if (catName.contains('سيار')) {
      return 'سرقة سيارة - ${targetLevels[i]}';
    } else if (catName.contains('بنك') || catName.contains('كازينو') || catName.contains('سطو')) {
      return 'عملية سطو - ${targetLevels[i]}';
    } else if (catName.contains('إلكترون') || catName.contains('اختراق')) {
      return 'هجوم سيبراني - ${targetLevels[i]}';
    } else if (catName.contains('تهريب') || catName.contains('تجارة')) {
      return 'صفقة تهريب - ${targetLevels[i]}';
    } else if (catName.contains('تزوير') || catName.contains('ابتزاز') || catName.contains('غسيل')) {
      return 'عملية سرية - ${targetLevels[i]}';
    } else {
      return '$catName (${targetLevels[i]})';
    }
  }

  static List<Map<String, dynamic>> getCrimesForCategory(int catIndex) {
    List<Map<String, dynamic>> crimes = [];

    for (int i = 0; i < 20; i++) {
      int reqCourage = 5 + (catIndex * 15) + (i * 2);
      int reqEnergy = (catIndex > 2) ? (catIndex * 5) + (i * 1) : 0;

      double multiplier = pow(1.3, catIndex).toDouble();
      int minCash = (50 * multiplier).toInt() + (i * 20 * (catIndex + 1));
      int maxCash = (100 * multiplier).toInt() + (i * 40 * (catIndex + 1));
      int xp = (10 * multiplier).toInt() + (i * 2);

      double baseFailChance = 0.10 + (catIndex * 0.03) + (i * 0.01);
      double heat = 2.0 + (catIndex * 1.5) + (i * 0.2);

      crimes.add({
        'id': 'cat_${catIndex}_crime_$i',
        'name': _getThematicCrimeName(catIndex, i), // استخدام الدالة الجديدة
        'courage': reqCourage,
        'energy': reqEnergy,
        'minCash': minCash,
        'maxCash': maxCash,
        'failChance': min(baseFailChance, 0.90),
        'xp': xp,
        'heat': heat,
      });
    }
    return crimes;
  }
}