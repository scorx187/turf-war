import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/quick_recovery_dialog.dart';

class GymView extends StatelessWidget {
  final VoidCallback onBack;

  const GymView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    final List<Map<String, dynamic>> exercises = [
      {
        'id': 'strength',
        'name': 'رفع الأثقال',
        'stat': 'القوة',
        'description': 'تزيد من الضرر الهجومي على اللاعبين',
        'energy': 10,
        'icon': Icons.fitness_center,
        'color': Colors.redAccent,
        'value': player.strength,
      },
      {
        'id': 'defense',
        'name': 'تمارين التحمل',
        'stat': 'الدفاع',
        'description': 'ترفع من مستوى الصحة وتقليل الضرر',
        'energy': 10,
        'icon': Icons.shield,
        'color': Colors.blueAccent,
        'value': player.defense,
      },
      {
        'id': 'skill',
        'name': 'تمارين اليوغا',
        'stat': 'المهارة',
        'description': 'تزيد من فرصة تفادي هجمات الخصوم',
        'energy': 10,
        'icon': Icons.psychology,
        'color': Colors.greenAccent,
        'value': player.skill,
      },
      {
        'id': 'speed',
        'name': 'الجري على الآلة',
        'stat': 'السرعة',
        'description': 'تقلل من فرصة تفادي الخصم لهجماتك',
        'energy': 10,
        'icon': Icons.speed,
        'color': Colors.orangeAccent,
        'value': player.speed,
      },
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
              const Text('صالة التدريب (Gym) 🏋️', style: TextStyle(color: Colors.blueGrey, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatMini(Icons.fitness_center, player.strength.toStringAsFixed(1), Colors.redAccent),
                  _buildStatMini(Icons.shield, player.defense.toStringAsFixed(1), Colors.blueAccent),
                  _buildStatMini(Icons.psychology, player.skill.toStringAsFixed(1), Colors.greenAccent),
                  _buildStatMini(Icons.speed, player.speed.toStringAsFixed(1), Colors.orangeAccent),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sentiment_very_satisfied, color: Colors.yellow, size: 16),
                  const SizedBox(width: 5),
                  Text('نسبة السعادة: ${player.happiness}% (عامل تطوير: x${(1 + player.happiness/100).toStringAsFixed(1)})', 
                    style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: exercises.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final ex = exercises[index];
              return Card(
                color: Colors.black45,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: ex['color'].withValues(alpha: 0.3))),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: ex['color'].withValues(alpha: 0.2),
                    child: Icon(ex['icon'] as IconData, color: ex['color']),
                  ),
                  title: Text(ex['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex['description'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('${ex['stat']}: ${ex['value'].toStringAsFixed(1)}', style: TextStyle(color: ex['color'], fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    onPressed: () {
                      if (player.energy < ex['energy']) {
                        QuickRecoveryDialog.show(context, 'energy', ex['energy'] - player.energy);
                        return;
                      }
                      player.trainStat(ex['id'], ex['energy']);
                    },
                    child: Text('تدريب (-${ex['energy']})', style: const TextStyle(fontSize: 10)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatMini(IconData icon, String val, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
