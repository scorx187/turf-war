import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class WorkshopView extends StatelessWidget {
  final VoidCallback onBack;

  const WorkshopView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // [Diamond Standard] القاموس المحدث: يضم فقط عتاد الجريمة الـ 10
    final Map<String, Map<String, dynamic>> itemDetails = {
      'crowbar': {'name': 'عتلة فولاذية', 'icon': Icons.hardware, 'color': Colors.grey},
      'slim_jim': {'name': 'مفتاح مسطرة', 'icon': Icons.horizontal_rule, 'color': Colors.blueGrey},
      'jammer': {'name': 'جهاز تشويش', 'icon': Icons.vibration, 'color': Colors.teal},
      'lockpick': {'name': 'طقم مفاتيح', 'icon': Icons.vpn_key_outlined, 'color': Colors.amber},
      'glass_cutter': {'name': 'قاطع زجاج', 'icon': Icons.architecture, 'color': Colors.cyan},
      'laptop': {'name': 'لابتوب تهكير', 'icon': Icons.laptop_mac, 'color': Colors.deepPurpleAccent},
      'thermite': {'name': 'ثيرميت حارق', 'icon': Icons.whatshot, 'color': Colors.deepOrange},
      'stethoscope': {'name': 'سماعة طبية', 'icon': Icons.hearing, 'color': Colors.blue},
      'hydraulic': {'name': 'قاطع هيدروليك', 'icon': Icons.content_cut, 'color': Colors.redAccent},
      'emp_device': {'name': 'جهاز EMP', 'icon': Icons.electric_bolt, 'color': Colors.yellowAccent},
    };

    final List<Map<String, dynamic>> damagedItems = [];

    player.inventory.forEach((id, count) {
      if (itemDetails.containsKey(id)) {
        double dur = player.getItemDurability(id);
        if (dur < 100) {
          damagedItems.add({
            'id': id,
            'name': itemDetails[id]!['name'],
            'icon': itemDetails[id]!['icon'],
            'color': itemDetails[id]!['color'],
            'durability': dur,
          });
        }
      }
    });

    return Column(
      children: [
        // --- هيدر الورشة ---
        _buildWorkshopHeader(player.spareParts),

        Expanded(
          child: damagedItems.isEmpty
              ? _buildAllFixedState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: damagedItems.length,
            itemBuilder: (context, index) {
              final item = damagedItems[index];
              return _buildRepairCard(player, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkshopHeader(int spareParts) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
          color: Color.fromRGBO(96, 125, 139, 0.15), // بديل نظيف لـ withOpacity
          border: Border(bottom: BorderSide(color: Colors.blueAccent, width: 2))
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
          const Expanded(
            child: Text('ورشة الصيانة 🛠️', style: TextStyle(color: Colors.blueAccent, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text('$spareParts قطعة غيار', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFixedState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, size: 80, color: Color.fromRGBO(76, 175, 80, 0.2)),
          SizedBox(height: 16),
          Text('جميع معدات العمليات سليمة 100%', style: TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRepairCard(PlayerProvider player, Map<String, dynamic> item) {
    bool canAfford = player.spareParts >= 10;
    Color durColor = item['durability'] > 70 ? Colors.green : item['durability'] > 30 ? Colors.orange : Colors.red;
    Color itemColor = item['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: itemColor.withValues(alpha: 0.3)), // تم التنظيف هنا
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: itemColor.withValues(alpha: 0.1), // تم التنظيف هنا
            child: Icon(item['icon'], color: itemColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: item['durability'] / 100,
                  backgroundColor: Colors.white10,
                  color: durColor,
                  minHeight: 5,
                ),
                const SizedBox(height: 4),
                Text('الحالة: ${item['durability'].toInt()}%', style: TextStyle(color: durColor, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? Colors.blueAccent : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: canAfford ? () => player.repairItem(item['id']) : null,
                child: const Text('إصلاح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const Text('10 قطع غيار', style: TextStyle(color: Colors.white38, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}