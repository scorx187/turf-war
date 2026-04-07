import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class WorkshopView extends StatelessWidget {
  final VoidCallback onBack;

  const WorkshopView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    final List<Map<String, dynamic>> tools = [
      {'id': 'crowbar', 'name': 'عتلة', 'repairCost': 2, 'icon': Icons.build},
      {'id': 'glass_cutter', 'name': 'قاطع زجاج', 'repairCost': 3, 'icon': Icons.content_cut},
      {'id': 'lockpick', 'name': 'أداة فك أقفال', 'repairCost': 4, 'icon': Icons.lock_open},
      {'id': 'slim_jim', 'name': 'أداة فتح سيارات', 'repairCost': 5, 'icon': Icons.vpn_key},
      {'id': 'stethoscope', 'name': 'سماعة طبيب', 'repairCost': 6, 'icon': Icons.medical_services},
      {'id': 'jammer', 'name': 'جهاز تشويش', 'repairCost': 8, 'icon': Icons.cell_tower},
      {'id': 'laptop', 'name': 'لابتوب اختراق', 'repairCost': 10, 'icon': Icons.laptop_mac},
      {'id': 'hydraulic', 'name': 'مقص هيدروليكي', 'repairCost': 12, 'icon': Icons.handyman},
      {'id': 'thermite', 'name': 'ثيرمايت', 'repairCost': 15, 'icon': Icons.whatshot},
      {'id': 'emp_device', 'name': 'جهاز EMP', 'repairCost': 20, 'icon': Icons.flash_on},
    ];

    // إظهار الأدوات التي يمتلكها اللاعب فقط في الورشة
    final ownedTools = tools.where((t) => (player.inventory[t['id']] ?? 0) > 0).toList();

    return Column(
      children: [
        // زر الرجوع للخريطة
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: onBack,
          ),
        ),

        // بانر الورشة
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
            boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الورشة السرية 🛠️', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('العتاد القوي يحتاج قطع غيار أكثر للصيانة.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 8),
                    // 🟢 تلميح الألقاب للورشة
                    Text('💡 جمع المزيد من القطع لفتح ألقاب أسطورية!', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.build_circle, color: Colors.grey, size: 35),
                  const SizedBox(height: 5),
                  Text('${player.spareParts} قطعة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),

        // قائمة عتاد الجريمة المملوك
        Expanded(
          child: ownedTools.isEmpty
              ? const Center(child: Text("لا تملك أي عتاد إجرامي حالياً!", style: TextStyle(color: Colors.white54, fontSize: 18)))
              : ListView.builder(
            itemCount: ownedTools.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemBuilder: (context, index) {
              final tool = ownedTools[index];
              double durability = player.getItemDurability(tool['id']);
              int cost = tool['repairCost'];
              bool needsRepair = durability < 100.0;
              bool canAfford = player.spareParts >= cost;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: needsRepair ? Colors.orange.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(tool['icon'], size: 40, color: Colors.white70),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tool['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: durability / 100,
                                  backgroundColor: Colors.white10,
                                  color: durability > 50 ? Colors.green : (durability > 20 ? Colors.orange : Colors.red),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('${durability.toInt()}%', style: TextStyle(color: durability > 20 ? Colors.white70 : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    if (needsRepair)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.build, size: 16, color: Colors.black),
                        label: Text('$cost قطع', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford ? Colors.amber : Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: canAfford ? () => player.repairItem(tool['id'], cost) : null,
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('سليم ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}