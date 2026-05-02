// المسار: lib/views/inventory_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🟢 استدعاء البلوك
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart'; // 🟢 أضفنا الصوت للضغطة
import '../utils/game_data.dart';
import '../controllers/inventory_cubit.dart'; // 🟢 استدعاء الكيوبت

class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  List<Map<String, dynamic>> _generateEquipment(PlayerProvider player) {
    List<Map<String, dynamic>> equipment = [];
    final rarities = [
      {'id': 'silver', 'name': 'فضي', 'color': Colors.blueGrey},
      {'id': 'green', 'name': 'أخضر', 'color': Colors.green},
      {'id': 'blue', 'name': 'أزرق', 'color': Colors.blue},
      {'id': 'purple', 'name': 'بنفسجي', 'color': Colors.deepPurple},
      {'id': 'gold', 'name': 'ذهبي', 'color': Colors.amber},
      {'id': 'red', 'name': 'أحمر', 'color': Colors.redAccent},
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
        int strVal = ((GameData.weaponStats[itemId]?['str'] ?? 0.0) * 100).toInt();
        int spdVal = ((GameData.weaponStats[itemId]?['spd'] ?? 0.0) * 100).toInt();

        equipment.add({
          'id': itemId,
          'name': '${w['name']} ${r['name']}',
          'description': 'قوة: +$strVal%\nسرعة: +$spdVal%',
          'icon': w['icon'],
          'color': r['color'],
          'type': 'weapon',
        });
      }
      for (var a in armorTypes) {
        String itemId = 'a_${r['id']}_${a['id']}';
        int defVal = ((GameData.armorStats[itemId]?['def'] ?? 0.0) * 100).toInt();
        int sklVal = ((GameData.armorStats[itemId]?['skl'] ?? 0.0) * 100).toInt();

        equipment.add({
          'id': itemId,
          'name': '${a['name']} ${r['name']}',
          'description': 'دفاع: +$defVal%\nمهارة: +$sklVal%',
          'icon': a['icon'],
          'color': r['color'],
          'type': 'armor',
        });
      }
    }
    return equipment;
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    final List<Map<String, dynamic>> allPossibleItems = [
      ..._generateEquipment(player),

      {'id': 'dagger', 'name': 'خنجر كلاسيكي', 'description': 'قوة: +15%\nسرعة: +25%', 'icon': Icons.colorize, 'color': Colors.grey, 'type': 'weapon'},
      {'id': 'revolver', 'name': 'مسدس كلاسيكي', 'description': 'قوة: +40%\nسرعة: +40%', 'icon': Icons.shutter_speed, 'color': Colors.blueGrey, 'type': 'weapon'},
      {'id': 'katana', 'name': 'كاتانا كلاسيكي', 'description': 'قوة: +90%\nسرعة: +60%', 'icon': Icons.colorize_outlined, 'color': Colors.indigo, 'type': 'weapon'},
      {'id': 'shotgun', 'name': 'شوزن كلاسيكي', 'description': 'قوة: +190%\nسرعة: +60%', 'icon': Icons.settings_overscan, 'color': Colors.orange, 'type': 'weapon'},
      {'id': 'sniper', 'name': 'قناصة كلاسيكية', 'description': 'قوة: +270%\nسرعة: +80%', 'icon': Icons.track_changes, 'color': Colors.red, 'type': 'weapon'},

      {'id': 'riot_shield', 'name': 'درع شغب كلاسيكي', 'description': 'دفاع: +60%\nمهارة: +20%', 'icon': Icons.shield_outlined, 'color': Colors.blue, 'type': 'armor'},
      {'id': 'kevlar_vest', 'name': 'سترة كلاسيكية', 'description': 'دفاع: +75%\nمهارة: +75%', 'icon': Icons.shield, 'color': Colors.green, 'type': 'armor'},
      {'id': 'steel_armor', 'name': 'فولاذ كلاسيكي', 'description': 'دفاع: +190%\nمهارة: +60%', 'icon': Icons.security, 'color': Colors.grey, 'type': 'armor'},
      {'id': 'ninja_suit', 'name': 'نينجا كلاسيكي', 'description': 'دفاع: +60%\nمهارة: +190%', 'icon': Icons.accessibility_new, 'color': Colors.black, 'type': 'armor'},
      {'id': 'exoskeleton', 'name': 'بدلة خارقة كلاسيكية', 'description': 'دفاع: +175%\nمهارة: +175%', 'icon': Icons.precision_manufacturing, 'color': Colors.amber, 'type': 'armor'},

      {'id': 'black_mask', 'name': 'قناع أسود', 'description': '35% هرب من السجن', 'icon': Icons.theater_comedy, 'color': Colors.black, 'type': 'mask'},
      {'id': 'silicon_mask', 'name': 'قناع سيليكون', 'description': '55% هرب من السجن', 'icon': Icons.face_retouching_natural, 'color': Colors.pinkAccent, 'type': 'mask'},
      {'id': 'crowbar', 'name': 'عتلة فولاذية', 'description': 'تخفض فشل السطو 5%', 'icon': Icons.hardware, 'color': Colors.grey, 'type': 'crime_tool'},
      {'id': 'slim_jim', 'name': 'مفتاح مسطرة', 'description': 'تخفض فشل السيارات 10%', 'icon': Icons.horizontal_rule, 'color': Colors.blueGrey, 'type': 'crime_tool'},
      {'id': 'jammer', 'name': 'جهاز تشويش', 'description': 'يعطل الإنذار (فشل -12%)', 'icon': Icons.vibration, 'color': Colors.teal, 'type': 'crime_tool'},
      {'id': 'lockpick', 'name': 'طقم مفاتيح', 'description': 'للخزائن (فشل السطو -15%)', 'icon': Icons.vpn_key_outlined, 'color': Colors.amber, 'type': 'crime_tool'},
      {'id': 'glass_cutter', 'name': 'قاطع زجاج', 'description': 'صامت (فشل -18%)', 'icon': Icons.architecture, 'color': Colors.cyan, 'type': 'crime_tool'},
      {'id': 'laptop', 'name': 'لابتوب تهكير', 'description': 'للبنك والسيارات (فشل -22%)', 'icon': Icons.laptop_mac, 'color': Colors.deepPurpleAccent, 'type': 'crime_tool'},
      {'id': 'thermite', 'name': 'ثيرميت حارق', 'description': 'يصهر الأبواب (فشل البنك -25%)', 'icon': Icons.whatshot, 'color': Colors.deepOrange, 'type': 'crime_tool'},
      {'id': 'stethoscope', 'name': 'سماعة طبية', 'description': 'فتح الخزائن (فشل السطو -10%)', 'icon': Icons.hearing, 'color': Colors.blue, 'type': 'crime_tool'},
      {'id': 'hydraulic', 'name': 'قاطع هيدروليك', 'description': 'قص الأسوار (فشل -15%)', 'icon': Icons.content_cut, 'color': Colors.redAccent, 'type': 'crime_tool'},
      {'id': 'emp_device', 'name': 'جهاز EMP', 'description': 'يعطل الكاميرات (فشل عام -30%)', 'icon': Icons.electric_bolt, 'color': Colors.yellowAccent, 'type': 'crime_tool'},

      {'id': 'bribe_small', 'name': 'رشوة محقق', 'description': 'تبريد الحرارة (20 درجة)', 'icon': Icons.handshake, 'color': Colors.teal, 'type': 'consumable'},
      {'id': 'fake_plates', 'name': 'لوحات مزورة', 'description': 'تبريد الحرارة (40 درجة)', 'icon': Icons.subtitles, 'color': Colors.lightBlue, 'type': 'consumable'},
      {'id': 'bribe_big', 'name': 'رشوة كبرى', 'description': 'تصفر الملاحقة فوراً', 'icon': Icons.account_balance_sharp, 'color': Colors.amber, 'type': 'consumable'},
      {'id': 'vip_7', 'name': 'بطاقة VIP (أسبوع)', 'description': 'تضيف 7 أيام لاشتراكك الحالي', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'type': 'consumable'},
      {'id': 'master_key', 'name': 'المفتاح الرئيسي', 'description': 'يفتح أبواب الفلل الفاخرة', 'icon': Icons.vpn_key, 'color': Colors.amber, 'type': 'passive'},
      {'id': 'stolen_car', 'name': 'سيارة مسروقة', 'description': 'جاهزة للفك في التشليح لقطع غيار', 'icon': Icons.directions_car, 'color': Colors.deepOrange, 'type': 'passive'},
      {'id': 'name_change_card', 'name': 'بطاقة تغيير الاسم', 'description': 'تغيير هوية اللاعب فوراً', 'icon': Icons.badge, 'color': Colors.cyan, 'type': 'consumable'},
      {'id': 'bandage', 'name': 'ضمادات', 'description': 'استعادة 25% من الصحة', 'icon': Icons.healing, 'color': Colors.redAccent, 'type': 'consumable'},
      {'id': 'medkit', 'name': 'حقيبة إسعاف', 'description': 'صحة 100%', 'icon': Icons.medical_information, 'color': Colors.redAccent, 'type': 'consumable'},
      {'id': 'steroids', 'name': 'حقنة منشط', 'description': 'طاقة 100%', 'icon': Icons.medical_services, 'color': Colors.greenAccent, 'type': 'consumable'},
      {'id': 'coffee', 'name': 'قهوة مركزة', 'description': 'شجاعة 100%', 'icon': Icons.coffee, 'color': Colors.brown, 'type': 'consumable'},
      {'id': 'smoke_bomb', 'name': 'قنبلة دخانية', 'description': 'هروب فوري من السجن', 'icon': Icons.air, 'color': Colors.grey, 'type': 'consumable'},
    ];

    final weapons = allPossibleItems.where((item) => item['type'] == 'weapon' && player.inventory.containsKey(item['id'])).toList();
    final defense = allPossibleItems.where((item) => (item['type'] == 'armor' || item['type'] == 'mask') && player.inventory.containsKey(item['id'])).toList();
    final crimeTools = allPossibleItems.where((item) => item['type'] == 'crime_tool' && player.inventory.containsKey(item['id'])).toList();
    final consumables = allPossibleItems.where((item) => (item['type'] == 'consumable' || item['type'] == 'passive') && player.inventory.containsKey(item['id'])).toList();

    // 🟢 تغليف الشاشة بالكيوبت لمراقبة الأحداث
    return BlocProvider(
      create: (context) => InventoryCubit(),
      child: BlocConsumer<InventoryCubit, InventoryState>(
        listener: (context, state) {
          if (state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              backgroundColor: state.isError ? Colors.redAccent : Colors.green,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          final cubit = context.read<InventoryCubit>();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  _buildInventoryHeader(player.spareParts),
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'الأسلحة', icon: Icon(Icons.colorize)),
                      Tab(text: 'الدفاع', icon: Icon(Icons.shield)),
                      Tab(text: 'العمليات', icon: Icon(Icons.engineering)),
                      Tab(text: 'أدوات', icon: Icon(Icons.inventory_2)),
                    ],
                    indicatorColor: Colors.amber,
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.grey,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildItemList(player, cubit, weapons, 'لا تملك أسلحة قتالية.'),
                        _buildItemList(player, cubit, defense, 'لا تملك دروع أو أقنعة.'),
                        _buildItemList(player, cubit, crimeTools, 'لا تملك أدوات عمليات.'),
                        _buildItemList(player, cubit, consumables, 'المخزن فارغ من الأدوات.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryHeader(int spareParts) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.black26,
          border: Border(bottom: BorderSide(color: Colors.amber.withValues(alpha:0.3)))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('مخزن المعدات 📦', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha:0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent.withValues(alpha:0.5))),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 6),
                Text('قطع غيار: $spareParts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Changa')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(PlayerProvider player, InventoryCubit cubit, List<Map<String, dynamic>> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.white24, fontSize: 16, fontFamily: 'Changa')));
    }
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id'];
        final quantity = player.inventory[id] ?? 0;
        final type = item['type'];
        final durability = player.getItemDurability(id);

        bool isEquipped = false;
        if (type == 'weapon') { isEquipped = player.equippedWeaponId == id; }
        else if (type == 'armor') { isEquipped = player.equippedArmorId == id; }
        else if (type == 'mask') { isEquipped = player.equippedMaskId == id; }
        else if (type == 'crime_tool') { isEquipped = player.equippedCrimeToolId == id; }

        return Card(
          color: isEquipped ? Colors.amber.withValues(alpha:0.1) : Colors.black45,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: isEquipped ? Colors.amber : (item['color'] as Color).withValues(alpha:0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Badge(
                label: Text(quantity.toString()),
                isLabelVisible: quantity > 1 || type == 'consumable',
                backgroundColor: Colors.amber,
                child: Icon(item['icon'] as IconData, color: item['color'], size: 35),
              ),
              title: Row(
                children: [
                  Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                  if (isEquipped) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, color: Colors.amber, size: 16)],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['description'], style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 11, fontFamily: 'Changa')),
                  const SizedBox(height: 8),
                  if (type == 'crime_tool')
                    _buildDurabilityBar(durability),
                ],
              ),
              trailing: _buildActionBtn(context, player, cubit, item, type, isEquipped),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDurabilityBar(double durability) {
    Color barColor = durability > 70 ? Colors.green : durability > 30 ? Colors.orange : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('المتانة:', style: TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'Changa')),
            Text('${durability.toInt()}%', style: TextStyle(color: barColor, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: durability / 100,
            backgroundColor: Colors.white10,
            color: barColor,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, PlayerProvider player, InventoryCubit cubit, Map<String, dynamic> item, String type, bool isEquipped) {
    final id = item['id'];
    final itemName = item['name'];

    if (id == 'name_change_card') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.withValues(alpha:0.2), side: const BorderSide(color: Colors.cyan), minimumSize: const Size(60, 30)),
        onPressed: () {
          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
          _showNameChangeDialog(context, player, cubit);
        },
        child: const Text('استخدام', style: TextStyle(color: Colors.cyan, fontSize: 11, fontFamily: 'Changa')),
      );
    }

    if (type == 'consumable') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withValues(alpha:0.2), side: const BorderSide(color: Colors.green), minimumSize: const Size(60, 30)),
        onPressed: () {
          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
          cubit.useOrEquipItem(player, id, itemName, false, false);
        },
        child: const Text('استخدام', style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'Changa')),
      );
    }

    if (['weapon', 'armor', 'mask', 'crime_tool'].contains(type)) {
      Color btnColor = isEquipped ? Colors.red : Colors.blue;
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: btnColor.withValues(alpha:0.2),
            side: BorderSide(color: btnColor),
            minimumSize: const Size(70, 30)
        ),
        onPressed: () {
          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
          cubit.useOrEquipItem(player, id, itemName, true, isEquipped);
        },
        child: Text(isEquipped ? 'نزع' : 'تجهيز', style: TextStyle(color: btnColor, fontSize: 11, fontFamily: 'Changa')),
      );
    }

    return const Icon(Icons.check_circle_outline, color: Colors.white10, size: 20);
  }

  void _showNameChangeDialog(BuildContext context, PlayerProvider player, InventoryCubit cubit) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.cyan)),
          title: const Text('تغيير اسم اللاعب 📛', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          content: TextField(
              controller: nameController,
              maxLength: 14,
              style: const TextStyle(color: Colors.white, fontFamily: 'Changa'),
              decoration: const InputDecoration(
                  counterText: "",
                  hintText: 'الاسم الجديد...',
                  hintStyle: TextStyle(color: Colors.white24, fontFamily: 'Changa')
              )
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa'))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    cubit.changePlayerName(player, nameController.text.trim());
                  }
                },
                child: const Text('تغيير', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa'))
            ),
          ],
        ),
      ),
    );
  }
}