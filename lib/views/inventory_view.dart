import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // --- قاعدة بيانات الأدوات الماسية المدمجة الشاملة ---
    final List<Map<String, dynamic>> allPossibleItems = [
      // --- أسلحة الـ PVP (أبدية - لا تظهر لها متانة) ---
      {'id': 'dagger', 'name': 'خنجر صدئ', 'description': 'قوة (+5) سرعة (+2)', 'icon': Icons.colorize, 'color': Colors.grey, 'type': 'weapon'},
      {'id': 'revolver', 'name': 'مسدس ريفولفر', 'description': 'قوة (+20) سرعة (+5)', 'icon': Icons.shutter_speed, 'color': Colors.blueGrey, 'type': 'weapon'},
      {'id': 'katana', 'name': 'كاتانا الساموراي', 'description': 'تزيد القوة (+40) والسرعة (+30)', 'icon': Icons.colorize_outlined, 'color': Colors.indigo, 'type': 'weapon'},
      {'id': 'shotgun', 'name': 'بندقية شوزن', 'description': 'تزيد القوة (+100) والسرعة (-10)', 'icon': Icons.settings_overscan, 'color': Colors.orange, 'type': 'weapon'},
      {'id': 'sniper', 'name': 'قناصة الصقر', 'description': 'تزيد القوة (+300) والسرعة (+50)', 'icon': Icons.track_changes, 'color': Colors.red, 'type': 'weapon'},

      // --- دروع وأقنعة الـ PVP (أبدية) ---
      {'id': 'riot_shield', 'name': 'درع مكافحة الشغب', 'description': 'دفاع (+15) مهارة (+5)', 'icon': Icons.shield_outlined, 'color': Colors.blue, 'type': 'armor'},
      {'id': 'kevlar_vest', 'name': 'سترة واقية', 'description': 'دفاع (+40) مهارة (+15)', 'icon': Icons.shield, 'color': Colors.green, 'type': 'armor'},
      {'id': 'steel_armor', 'name': 'درع فولاذي', 'description': 'دفاع (+120) مهارة (-5)', 'icon': Icons.security, 'color': Colors.grey, 'type': 'armor'},
      {'id': 'ninja_suit', 'name': 'زي النينجا الأسود', 'description': 'دفاع (+80) مهارة (+60)', 'icon': Icons.accessibility_new, 'color': Colors.black, 'type': 'armor'},
      {'id': 'exoskeleton', 'name': 'البدلة الخارقة', 'description': 'دفاع (+400) مهارة (+100)', 'icon': Icons.precision_manufacturing, 'color': Colors.amber, 'type': 'armor'},
      {'id': 'black_mask', 'name': 'قناع أسود', 'description': '35% هرب من السجن', 'icon': Icons.theater_comedy, 'color': Colors.black, 'type': 'mask'},
      {'id': 'silicon_mask', 'name': 'قناع سيليكون', 'description': '55% هرب من السجن', 'icon': Icons.face_retouching_natural, 'color': Colors.pinkAccent, 'type': 'mask'},

      // --- عتاد الجريمة الجديد (لها متانة وتستهلك وتصلح بالورشة) ---
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

      // --- المستهلكات والبطاقات ورشاوي الحرارة ---
      {'id': 'bribe_small', 'name': 'رشوة محقق', 'description': 'تبريد الحرارة (20 درجة)', 'icon': Icons.handshake, 'color': Colors.teal, 'type': 'consumable'},
      {'id': 'fake_plates', 'name': 'لوحات مزورة', 'description': 'تبريد الحرارة (40 درجة)', 'icon': Icons.subtitles, 'color': Colors.lightBlue, 'type': 'consumable'},
      {'id': 'bribe_big', 'name': 'رشوة كبرى', 'description': 'تصفر الملاحقة فوراً', 'icon': Icons.account_balance_sharp, 'color': Colors.amber, 'type': 'consumable'},
      {'id': 'master_key', 'name': 'المفتاح الرئيسي', 'description': 'يفتح أبواب الفلل الفاخرة', 'icon': Icons.vpn_key, 'color': Colors.amber, 'type': 'passive'},
      {'id': 'stolen_car', 'name': 'سيارة مسروقة', 'description': 'جاهزة للفك في التشليح لقطع غيار', 'icon': Icons.directions_car, 'color': Colors.deepOrange, 'type': 'passive'},
      {'id': 'name_change_card', 'name': 'بطاقة تغيير الاسم', 'description': 'تغيير هوية اللاعب فوراً', 'icon': Icons.badge, 'color': Colors.cyan, 'type': 'consumable'},
      {'id': 'bandage', 'name': 'ضمادات', 'description': 'استعادة 25% من الصحة', 'icon': Icons.healing, 'color': Colors.redAccent, 'type': 'consumable'},
      {'id': 'medkit', 'name': 'حقيبة إسعاف', 'description': 'صحة 100%', 'icon': Icons.medical_information, 'color': Colors.redAccent, 'type': 'consumable'},
      {'id': 'steroids', 'name': 'حقنة منشط', 'description': 'طاقة 100%', 'icon': Icons.medical_services, 'color': Colors.greenAccent, 'type': 'consumable'},
      {'id': 'coffee', 'name': 'قهوة مركزة', 'description': 'شجاعة 100%', 'icon': Icons.coffee, 'color': Colors.brown, 'type': 'consumable'},
      {'id': 'smoke_bomb', 'name': 'قنبلة دخانية', 'description': 'هروب فوري من السجن', 'icon': Icons.air, 'color': Colors.grey, 'type': 'consumable'},
    ];

    // تصفية العناصر بناءً على المخزن والتبويبات
    final weapons = allPossibleItems.where((item) => item['type'] == 'weapon' && player.inventory.containsKey(item['id'])).toList();
    final defense = allPossibleItems.where((item) => (item['type'] == 'armor' || item['type'] == 'mask') && player.inventory.containsKey(item['id'])).toList();
    final crimeTools = allPossibleItems.where((item) => item['type'] == 'crime_tool' && player.inventory.containsKey(item['id'])).toList();
    final consumables = allPossibleItems.where((item) => (item['type'] == 'consumable' || item['type'] == 'passive') && player.inventory.containsKey(item['id'])).toList();

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // هيدر المخزن مع عرض قطع الغيار
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
                _buildItemList(player, weapons, 'لا تملك أسلحة قتالية.'),
                _buildItemList(player, defense, 'لا تملك دروع أو أقنعة.'),
                _buildItemList(player, crimeTools, 'لا تملك أدوات عمليات.'),
                _buildItemList(player, consumables, 'المخزن فارغ من الأدوات.'),
              ],
            ),
          ),
        ],
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
          const Text('مخزن المعدات 📦', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha:0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent.withValues(alpha:0.5))),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 6),
                Text('قطع غيار: $spareParts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(PlayerProvider player, List<Map<String, dynamic>> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.white24, fontSize: 16)));
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

        // التحقق من التجهيز بناءً على الصنف
        bool isEquipped = false;
        if (type == 'weapon') isEquipped = player.equippedWeaponId == id;
        else if (type == 'armor') isEquipped = player.equippedArmorId == id;
        else if (type == 'mask') isEquipped = player.equippedMaskId == id;
        else if (type == 'crime_tool') isEquipped = player.equippedCrimeToolId == id;

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
                  Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  if (isEquipped) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, color: Colors.amber, size: 16)],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['description'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 8),
                  // --- [نظام المتانة الماسي] يظهر فقط لعتاد الجريمة ---
                  if (type == 'crime_tool')
                    _buildDurabilityBar(durability),
                ],
              ),
              trailing: _buildActionBtn(context, player, item, type, isEquipped),
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
            const Text('المتانة:', style: TextStyle(color: Colors.white38, fontSize: 9)),
            Text('${durability.toInt()}%', style: TextStyle(color: barColor, fontSize: 9, fontWeight: FontWeight.bold)),
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

  Widget _buildActionBtn(BuildContext context, PlayerProvider player, Map<String, dynamic> item, String type, bool isEquipped) {
    final id = item['id'];

    if (id == 'name_change_card') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.withValues(alpha:0.2), side: const BorderSide(color: Colors.cyan), minimumSize: const Size(60, 30)),
        onPressed: () => _showNameChangeDialog(context, player),
        child: const Text('استخدام', style: TextStyle(color: Colors.cyan, fontSize: 11)),
      );
    }

    if (type == 'consumable') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withValues(alpha:0.2), side: const BorderSide(color: Colors.green), minimumSize: const Size(60, 30)),
        onPressed: () => player.useItem(id),
        child: const Text('استخدام', style: TextStyle(color: Colors.green, fontSize: 11)),
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
        onPressed: () => player.useItem(id),
        child: Text(isEquipped ? 'نزع' : 'تجهيز', style: TextStyle(color: btnColor, fontSize: 11)),
      );
    }

    return const Icon(Icons.check_circle_outline, color: Colors.white10, size: 20);
  }

  void _showNameChangeDialog(BuildContext context, PlayerProvider player) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.cyan)),
        title: const Text('تغيير اسم اللاعب 📛', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'الاسم الجديد...', hintStyle: TextStyle(color: Colors.white24))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  player.updateName(nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('تغيير', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}