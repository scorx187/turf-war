// المسار: lib/views/black_market_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../utils/game_data.dart'; // 🟢 استدعاء مستودع البيانات
import 'package:intl/intl.dart';

class BlackMarketView extends StatelessWidget {
  final VoidCallback onBack;

  const BlackMarketView({super.key, required this.onBack});

  // --- 🧠 مولد العتاد الذكي (يسحب الأرقام من مستودع GameData) ---
  List<Map<String, dynamic>> _generateEquipment(PlayerProvider player) {
    List<Map<String, dynamic>> equipment = [];
    final rarities = [
      {'id': 'silver', 'name': 'فضي', 'color': Colors.blueGrey, 'price': 5000, 'curr': 'cash'},
      {'id': 'green', 'name': 'أخضر', 'color': Colors.green, 'price': 25000, 'curr': 'cash'},
      {'id': 'blue', 'name': 'أزرق', 'color': Colors.blue, 'price': 100000, 'curr': 'cash'},
      {'id': 'purple', 'name': 'بنفسجي', 'color': Colors.deepPurple, 'price': 500000, 'curr': 'cash'},
      {'id': 'gold', 'name': 'ذهبي', 'color': Colors.amber, 'price': 2000, 'curr': 'gold'},
      {'id': 'red', 'name': 'أحمر', 'color': Colors.redAccent, 'price': 10000, 'curr': 'gold'},
    ];

    final weaponTypes = [
      {'id': 'heavy', 'name': 'مدفع', 'icon': Icons.hardware},
      {'id': 'assault', 'name': 'رشاش', 'icon': Icons.security},
      {'id': 'balanced', 'name': 'بندقية', 'icon': Icons.sync_alt},
      {'id': 'tactical', 'name': 'قناصة', 'icon': Icons.track_changes},
      {'id': 'agile', 'name': 'خنجر', 'icon': Icons.flash_on},
    ];

    final armorTypes = [
      {'id': 'heavy', 'name': 'درع طليعة', 'icon': Icons.shield},
      {'id': 'assault', 'name': 'سترة هجومية', 'icon': Icons.security_update_good},
      {'id': 'balanced', 'name': 'بدلة قتال', 'icon': Icons.accessibility_new},
      {'id': 'tactical', 'name': 'عتاد تكتيكي', 'icon': Icons.directions_run},
      {'id': 'agile', 'name': 'زي تسلل', 'icon': Icons.speed},
    ];

    for (var r in rarities) {
      for (var w in weaponTypes) {
        String itemId = 'w_${r['id']}_${w['id']}';
        // 🟢 التعديل: سحب الأرقام من GameData
        int strVal = ((GameData.weaponStats[itemId]?['str'] ?? 0.0) * 100).toInt();
        int spdVal = ((GameData.weaponStats[itemId]?['spd'] ?? 0.0) * 100).toInt();

        equipment.add({
          'id': itemId,
          'name': '${w['name']} ${r['name']}',
          'description': 'قوة: +$strVal%\nسرعة: +$spdVal%',
          'price': r['price'],
          'currency': r['curr'],
          'icon': w['icon'],
          'color': r['color'],
          'type': 'weapon',
          'isConsumable': false
        });
      }
      for (var a in armorTypes) {
        String itemId = 'a_${r['id']}_${a['id']}';
        // 🟢 التعديل: سحب الأرقام من GameData
        int defVal = ((GameData.armorStats[itemId]?['def'] ?? 0.0) * 100).toInt();
        int sklVal = ((GameData.armorStats[itemId]?['skl'] ?? 0.0) * 100).toInt();

        equipment.add({
          'id': itemId,
          'name': '${a['name']} ${r['name']}',
          'description': 'دفاع: +$defVal%\nمهارة: +$sklVal%',
          'price': r['price'],
          'currency': r['curr'],
          'icon': a['icon'],
          'color': r['color'],
          'type': 'armor',
          'isConsumable': false
        });
      }
    }
    return equipment;
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // --- قائمة بضاعة المتجر الكاملة ---
    final List<Map<String, dynamic>> items = [
      ..._generateEquipment(player),

      {'id': 'dagger', 'name': 'خنجر كلاسيكي', 'description': 'قوة: +15%\nسرعة: +25%', 'price': 1500, 'currency': 'cash', 'icon': Icons.colorize, 'color': Colors.grey, 'type': 'weapon', 'isConsumable': false},
      {'id': 'revolver', 'name': 'مسدس كلاسيكي', 'description': 'قوة: +40%\nسرعة: +40%', 'price': 15000, 'currency': 'cash', 'icon': Icons.shutter_speed, 'color': Colors.blueGrey, 'type': 'weapon', 'isConsumable': false},
      {'id': 'katana', 'name': 'كاتانا كلاسيكي', 'description': 'قوة: +90%\nسرعة: +60%', 'price': 85000, 'currency': 'cash', 'icon': Icons.colorize_outlined, 'color': Colors.indigo, 'type': 'weapon', 'isConsumable': false},
      {'id': 'shotgun', 'name': 'شوزن كلاسيكي', 'description': 'قوة: +190%\nسرعة: +60%', 'price': 250000, 'currency': 'cash', 'icon': Icons.settings_overscan, 'color': Colors.orange, 'type': 'weapon', 'isConsumable': false},
      {'id': 'sniper', 'name': 'قناصة كلاسيكية', 'description': 'قوة: +270%\nسرعة: +80%', 'price': 1200, 'currency': 'gold', 'icon': Icons.track_changes, 'color': Colors.red, 'type': 'weapon', 'isConsumable': false},
// 🟢 حزمة علاء الدين الخيالية (أسطوري - لون أحمر) 🟢
      {'id': 'w_aladdin_damage', 'name': 'سيف علاء الدين القاطع', 'description': 'سلاح أسطوري يمزق الأعداء\nقوة: +500% | سرعة: +100%', 'price': 50000, 'currency': 'gold', 'icon': Icons.hardware, 'color': Colors.redAccent, 'type': 'weapon', 'isConsumable': false},
      {'id': 'w_aladdin_accuracy', 'name': 'خنجر علاء الدين السحري', 'description': 'دقة وسرعة لا مثيل لها\nقوة: +100% | سرعة: +500%', 'price': 50000, 'currency': 'gold', 'icon': Icons.flash_on, 'color': Colors.redAccent, 'type': 'weapon', 'isConsumable': false},
      {'id': 'a_aladdin_defense', 'name': 'درع الجني الفولاذي', 'description': 'دفاع صلب لا يمكن اختراقه\nدفاع: +500% | مهارة: +100%', 'price': 50000, 'currency': 'gold', 'icon': Icons.shield, 'color': Colors.redAccent, 'type': 'armor', 'isConsumable': false},
      {'id': 'a_aladdin_evasion', 'name': 'عباءة علاء الدين', 'description': 'تفادي جميع الضربات بخفة\nدفاع: +100% | مهارة: +500%', 'price': 50000, 'currency': 'gold', 'icon': Icons.air, 'color': Colors.redAccent, 'type': 'armor', 'isConsumable': false},
      {'id': 't_aladdin_lamp', 'name': 'المصباح السحري', 'description': 'أداة أسطورية لاستدعاء الجني\n(المزايا قيد التطوير)', 'price': 25000, 'currency': 'gold', 'icon': Icons.lightbulb, 'color': Colors.redAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 't_aladdin_carpet', 'name': 'البساط الطائر', 'description': 'وسيلة تنقل وهروب خيالية\n(المزايا قيد التطوير)', 'price': 25000, 'currency': 'gold', 'icon': Icons.map, 'color': Colors.redAccent, 'type': 'crime_tool', 'isConsumable': false},

      {'id': 'riot_shield', 'name': 'درع شغب كلاسيكي', 'description': 'دفاع: +60%\nمهارة: +20%', 'price': 3000, 'currency': 'cash', 'icon': Icons.shield_outlined, 'color': Colors.blue, 'type': 'armor', 'isConsumable': false},
      {'id': 'kevlar_vest', 'name': 'سترة كلاسيكية', 'description': 'دفاع: +75%\nمهارة: +75%', 'price': 25000, 'currency': 'cash', 'icon': Icons.shield, 'color': Colors.green, 'type': 'armor', 'isConsumable': false},
      {'id': 'steel_armor', 'name': 'فولاذ كلاسيكي', 'description': 'دفاع: +190%\nمهارة: +60%', 'price': 120000, 'currency': 'cash', 'icon': Icons.security, 'color': Colors.grey, 'type': 'armor', 'isConsumable': false},
      {'id': 'ninja_suit', 'name': 'نينجا كلاسيكي', 'description': 'دفاع: +60%\nمهارة: +190%', 'price': 500000, 'currency': 'cash', 'icon': Icons.accessibility_new, 'color': Colors.black, 'type': 'armor', 'isConsumable': false},
      {'id': 'exoskeleton', 'name': 'بدلة خارقة كلاسيكية', 'description': 'دفاع: +175%\nمهارة: +175%', 'price': 2500, 'currency': 'gold', 'icon': Icons.precision_manufacturing, 'color': Colors.amber, 'type': 'armor', 'isConsumable': false},

      {'id': 'black_mask', 'name': 'قناع أسود', 'description': 'مطلوب لسرقة السيارات ويهربك 35%', 'price': 15000, 'currency': 'cash', 'icon': Icons.theater_comedy, 'color': Colors.black, 'type': 'mask', 'isConsumable': false},
      {'id': 'silicon_mask', 'name': 'قناع سيليكون', 'description': 'مطلوب لسطو البنك ويهربك 55%', 'price': 120000, 'currency': 'cash', 'icon': Icons.face_retouching_natural, 'color': Colors.pinkAccent, 'type': 'mask', 'isConsumable': false},
      {'id': 'crowbar', 'name': 'عتلة فولاذية', 'description': 'تخفض فشل السطو 5%', 'price': 2500, 'currency': 'cash', 'icon': Icons.hardware, 'color': Colors.grey, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'slim_jim', 'name': 'مفتاح مسطرة', 'description': 'تخفض فشل السيارات 10%', 'price': 5000, 'currency': 'cash', 'icon': Icons.horizontal_rule, 'color': Colors.blueGrey, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'jammer', 'name': 'جهاز تشويش', 'description': 'يعطل الإنذار (فشل -12%)', 'price': 12000, 'currency': 'cash', 'icon': Icons.vibration, 'color': Colors.teal, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'lockpick', 'name': 'طقم مفاتيح', 'description': 'للخزائن (فشل السطو -15%)', 'price': 20000, 'currency': 'cash', 'icon': Icons.vpn_key_outlined, 'color': Colors.amber, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'glass_cutter', 'name': 'قاطع زجاج', 'description': 'صامت (فشل -18%)', 'price': 35000, 'currency': 'cash', 'icon': Icons.architecture, 'color': Colors.cyan, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'stethoscope', 'name': 'سماعة طبية', 'description': 'فتح الخزائن (فشل السطو -10%)', 'price': 40000, 'currency': 'cash', 'icon': Icons.hearing, 'color': Colors.blue, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'laptop', 'name': 'لابتوب تهكير', 'description': 'للبنك والسيارات (فشل -22%)', 'price': 75000, 'currency': 'cash', 'icon': Icons.laptop_mac, 'color': Colors.deepPurpleAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'hydraulic', 'name': 'قاطع هيدروليك', 'description': 'قص الأسوار (فشل -15%)', 'price': 90000, 'currency': 'cash', 'icon': Icons.content_cut, 'color': Colors.redAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'thermite', 'name': 'ثيرميت حارق', 'description': 'يصهر الأبواب (فشل البنك -25%)', 'price': 150000, 'currency': 'cash', 'icon': Icons.whatshot, 'color': Colors.deepOrange, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'emp_device', 'name': 'جهاز EMP', 'description': 'يعطل الكاميرات (فشل عام -30%)', 'price': 500, 'currency': 'gold', 'icon': Icons.electric_bolt, 'color': Colors.yellowAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'master_key', 'name': 'المفتاح الرئيسي', 'description': 'مطلوب للسطو على الفلل الفاخرة', 'price': 150000, 'currency': 'cash', 'icon': Icons.vpn_key, 'color': Colors.amber, 'type': 'passive', 'isConsumable': false},
      {'id': 'bribe_small', 'name': 'رشوة محقق', 'description': 'تبريد الحرارة (20 درجة)', 'price': 10000, 'currency': 'cash', 'icon': Icons.handshake, 'color': Colors.teal, 'type': 'consumable', 'isConsumable': true},
      {'id': 'fake_plates', 'name': 'لوحات مزورة', 'description': 'تبريد الحرارة (40 درجة)', 'price': 25000, 'currency': 'cash', 'icon': Icons.subtitles, 'color': Colors.lightBlue, 'type': 'consumable', 'isConsumable': true},
      {'id': 'bribe_big', 'name': 'رشوة كبرى', 'description': 'تصفر الملاحقة فوراً', 'price': 100, 'currency': 'gold', 'icon': Icons.account_balance_sharp, 'color': Colors.amber, 'type': 'consumable', 'isConsumable': true},
      {'id': 'bandage', 'name': 'ضمادات', 'description': 'استعادة 25% من الصحة', 'price': 500, 'currency': 'cash', 'icon': Icons.healing, 'color': Colors.redAccent, 'type': 'consumable', 'isConsumable': true},
      {'id': 'medkit', 'name': 'حقيبة إسعاف', 'description': 'صحة 100% فوراً', 'price': 2500, 'currency': 'cash', 'icon': Icons.medical_information, 'color': Colors.redAccent, 'type': 'consumable', 'isConsumable': true},
      {'id': 'steroids', 'name': 'حقنة منشط', 'description': 'طاقة 100%', 'price': 50, 'currency': 'gold', 'icon': Icons.medical_services, 'color': Colors.greenAccent, 'type': 'consumable', 'isConsumable': true},
      {'id': 'coffee', 'name': 'قهوة مركزة', 'description': 'شجاعة 100%', 'price': 50, 'currency': 'gold', 'icon': Icons.coffee, 'color': Colors.brown, 'type': 'consumable', 'isConsumable': true},
      {'id': 'smoke_bomb', 'name': 'قنبلة دخانية', 'description': 'هروب فوري من السجن', 'price': 25, 'currency': 'gold', 'icon': Icons.air, 'color': Colors.grey, 'type': 'consumable', 'isConsumable': true},
    ];

    final weapons = items.where((item) => item['type'] == 'weapon').toList();
    final armors = items.where((item) => item['type'] == 'armor').toList();
    final crimeGear = items.where((item) => item['type'] == 'crime_tool' || item['type'] == 'mask' || item['id'] == 'master_key').toList();
    final tools = items.where((item) => item['type'] == 'consumable').toList();

    final List<Map<String, dynamic>> vips = [
      {'id': 'vip_1', 'name': 'عضوية يوم', 'days': 1, 'price': 50},
      {'id': 'vip_7', 'name': 'عضوية أسبوع', 'days': 7, 'price': 300},
      {'id': 'vip_30', 'name': 'عضوية شهر', 'days': 30, 'price': 1000},
      {'id': 'vip_365', 'name': 'عضوية سنة', 'days': 365, 'price': 10000},
    ];

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
                const Text('المتجر الأسود 🌑', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'الأسلحة', icon: Icon(Icons.colorize)),
              Tab(text: 'الدروع', icon: Icon(Icons.shield)),
              Tab(text: 'عتاد الجرائم', icon: Icon(Icons.engineering)),
              Tab(text: 'أدوات', icon: Icon(Icons.medical_services)),
              Tab(text: 'VIP', icon: Icon(Icons.workspace_premium)),
            ],
            indicatorColor: Colors.redAccent,
            labelColor: Colors.redAccent,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildItemsList(player, weapons),
                _buildItemsList(player, armors),
                _buildItemsList(player, crimeGear),
                _buildItemsList(player, tools),
                _buildVIPList(player, vips),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(PlayerProvider player, List<Map<String, dynamic>> items) {
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isConsumable = item['isConsumable'] ?? false;
        final bool hasItem = player.inventory.containsKey(item['id']);
        final String currency = item['currency'];

        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: (item['color'] as Color).withValues(alpha: 0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: (item['color'] as Color).withValues(alpha: 0.2),
              child: Icon(item['icon'] as IconData, color: item['color'], size: 20),
            ),
            title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(item['description'], style: const TextStyle(color: Colors.white54, height: 1.5, fontSize: 11)),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    '${item['price']} ${currency == 'cash' ? 'كاش' : 'ذهب'}',
                    style: TextStyle(color: currency == 'cash' ? Colors.amber : Colors.yellow, fontWeight: FontWeight.bold, fontSize: 11)
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!isConsumable && hasItem) ? Colors.grey : Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      if (!isConsumable && hasItem) return;
                      bool canBuy = currency == 'cash' ? player.cash >= item['price'] : player.gold >= item['price'];
                      if (canBuy) {
                        player.buyItem(item['id'], item['price'], isConsumable: isConsumable, currency: currency);
                      }
                    },
                    child: Text((!isConsumable && hasItem) ? 'مملوك' : 'شراء', style: const TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVIPList(PlayerProvider player, List<Map<String, dynamic>> vips) {
    return Column(
      children: [
        if (player.isVIP)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber)
            ),
            child: Column(
              children: [
                const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text('عضوية VIP مفعلة', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14))
                    ]
                ),
                const SizedBox(height: 2),
                if (player.vipUntil != null)
                  Text('تنتهي في: ${DateFormat('yyyy-MM-dd HH:mm').format(player.vipUntil!)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: vips.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final vip = vips[index];
              return Card(
                color: Colors.black45,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.amber.withValues(alpha: 0.3))
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  leading: const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                  title: Text(vip['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('طاقة وشجاعة قصوى 200', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${vip['price']} ذهب', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: player.isVIP ? Colors.grey : Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 8)
                          ),
                          onPressed: player.isVIP ? null : () => player.buyVIP(vip['days'], vip['price']),
                          child: const Text('تفعيل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}