import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class WorkshopView extends StatelessWidget {
  final VoidCallback onBack;
  const WorkshopView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // حصر الأغراض التي تحتاج إصلاح (الأسلحة والدروع التي متانتها أقل من 100)
    final List<Map<String, dynamic>> brokenItems = [];

    // قائمة المراجع لكل الأغراض الممكنة لجلب أسمائها وأيقوناتها
    final Map<String, Map<String, dynamic>> itemData = {
      'dagger': {'name': 'خنجر صدئ', 'icon': Icons.colorize, 'color': Colors.grey},
      'revolver': {'name': 'مسدس ريفولفر', 'icon': Icons.shutter_speed, 'color': Colors.blueGrey},
      'katana': {'name': 'كاتانا الساموراي', 'icon': Icons.colorize_outlined, 'color': Colors.indigo},
      'shotgun': {'name': 'بندقية شوزن', 'icon': Icons.settings_overscan, 'color': Colors.orange},
      'sniper': {'name': 'قناصة الصقر', 'icon': Icons.track_changes, 'color': Colors.red},
      'riot_shield': {'name': 'درع مكافحة الشغب', 'icon': Icons.shield_outlined, 'color': Colors.blue},
      'kevlar_vest': {'name': 'سترة واقية', 'icon': Icons.shield, 'color': Colors.green},
      'steel_armor': {'name': 'درع فولاذي', 'icon': Icons.security, 'color': Colors.grey},
      'ninja_suit': {'name': 'زي النينجا الأسود', 'icon': Icons.accessibility_new, 'color': Colors.black},
      'exoskeleton': {'name': 'البدلة الخارقة', 'icon': Icons.precision_manufacturing, 'color': Colors.amber},
      'black_mask': {'name': 'قناع أسود', 'icon': Icons.theater_comedy, 'color': Colors.black},
      'silicon_mask': {'name': 'قناع سيليكون', 'icon': Icons.face_retouching_natural, 'color': Colors.pinkAccent},
    };

    player.inventory.forEach((id, count) {
      if (itemData.containsKey(id)) {
        double dur = player.getItemDurability(id);
        if (dur < 100) {
          brokenItems.add({
            'id': id,
            'durability': dur,
            ...itemData[id]!,
          });
        }
      }
    });

    return Column(
      children: [
        // هيدر الورشة
        _buildHeader(context, player.spareParts),

        Expanded(
          child: brokenItems.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: brokenItems.length,
            itemBuilder: (context, index) {
              final item = brokenItems[index];
              return _buildRepairCard(context, player, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int spareParts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha:0.2),
          border: const Border(bottom: BorderSide(color: Colors.blueAccent, width: 1))
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
          const Expanded(
            child: Text('ورشة الصيانة 🔧', style: TextStyle(color: Colors.blueAccent, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text('$spareParts قطعة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withValues(alpha:0.3)),
          const SizedBox(height: 16),
          const Text('كل معداتك في حالة ممتازة!', style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRepairCard(BuildContext context, PlayerProvider player, Map<String, dynamic> item) {
    bool canAfford = player.spareParts >= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (item['color'] as Color).withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (item['color'] as Color).withValues(alpha:0.2),
            child: Icon(item['icon'], color: item['color']),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: item['durability'] / 100,
                  backgroundColor: Colors.white10,
                  color: _getDurabilityColor(item['durability']),
                  minHeight: 6,
                ),
                Text('الحالة: ${item['durability'].toInt()}%', style: TextStyle(color: _getDurabilityColor(item['durability']), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? Colors.blueAccent : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            ),
            onPressed: canAfford ? () => player.repairItem(item['id']) : null,
            child: Column(
              children: [
                const Text('إصلاح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('10 قطع', style: TextStyle(color: Colors.white.withValues(alpha:0.7), fontSize: 9)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Color _getDurabilityColor(double val) {
    if (val > 70) return Colors.green;
    if (val > 30) return Colors.orange;
    return Colors.red;
  }
}