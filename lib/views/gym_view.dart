import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/quick_recovery_dialog.dart';

class GymView extends StatefulWidget {
  final VoidCallback onBack;

  const GymView({super.key, required this.onBack});

  @override
  State<GymView> createState() => _GymViewState();
}

class _GymViewState extends State<GymView> {
  double _selectedEnergy = 1.0;
  final TextEditingController _energyController = TextEditingController(text: '1');

  @override
  void dispose() {
    _energyController.dispose();
    super.dispose();
  }

  void _updateEnergyFromText(String value, int maxEnergy) {
    int? parsed = int.tryParse(value);
    if (parsed != null) {
      setState(() {
        _selectedEnergy = parsed.clamp(1, maxEnergy > 0 ? maxEnergy : 1).toDouble();
        if (parsed > maxEnergy) {
          _energyController.text = _selectedEnergy.toInt().toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final int currentEnergy = player.energy;

    // تحديث المؤشر إذا كانت طاقة اللاعب أقل من الرقم المحدد سابقاً
    if (_selectedEnergy > currentEnergy && currentEnergy > 0) {
      _selectedEnergy = currentEnergy.toDouble();
      _energyController.text = _selectedEnergy.toInt().toString();
    } else if (currentEnergy == 0) {
      _selectedEnergy = 0;
      _energyController.text = '0';
    }

    // حساب كم بيعطيك التدريب المختار بناءً على المعادلة الصعبة
    double gainPerEnergy = 0.01 + (player.happiness * 0.0002);
    double expectedGain = _selectedEnergy * gainPerEnergy;

    final List<Map<String, dynamic>> exercises = [
      {'id': 'strength', 'name': 'رفع الأثقال', 'stat': 'القوة', 'desc': 'تزيد من الضرر الهجومي', 'icon': Icons.fitness_center, 'color': Colors.redAccent, 'value': player.strength},
      {'id': 'defense', 'name': 'تمارين التحمل', 'stat': 'الدفاع', 'desc': 'تمتص وتقلل الضرر', 'icon': Icons.shield, 'color': Colors.blueAccent, 'value': player.defense},
      {'id': 'skill', 'name': 'تمارين اليوغا', 'stat': 'المهارة', 'desc': 'تزيد فرصة المراوغة', 'icon': Icons.psychology, 'color': Colors.greenAccent, 'value': player.skill},
      {'id': 'speed', 'name': 'الجري على الآلة', 'stat': 'السرعة', 'desc': 'ترفع دقة هجماتك', 'icon': Icons.speed, 'color': Colors.orangeAccent, 'value': player.speed},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
              const Text('صالة التدريب 🏋️', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // --- قسم الإحصائيات العلوية ---
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
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

              // عرض السعادة والسقف
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('السعادة: ${player.happiness} 🏡', style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('السقف: ${player.currentBaseStats.toInt()}/${player.maxGymStats.toInt()}', style: TextStyle(color: player.currentBaseStats >= player.maxGymStats ? Colors.red : Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),

        // --- وحدة التحكم بالطاقة (شريط السحب + الإدخال اليدوي) ---
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('كمية الطاقة المصروفة:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(
                    width: 70,
                    height: 35,
                    child: TextField(
                      controller: _energyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => _updateEnergyFromText(val, currentEnergy),
                    ),
                  ),
                ],
              ),
              Slider(
                value: currentEnergy == 0 ? 0 : _selectedEnergy,
                min: currentEnergy == 0 ? 0 : 1,
                max: currentEnergy == 0 ? 0 : currentEnergy.toDouble(),
                activeColor: Colors.amber,
                inactiveColor: Colors.white10,
                onChanged: currentEnergy == 0 ? null : (val) {
                  setState(() {
                    _selectedEnergy = val;
                    _energyController.text = val.toInt().toString();
                  });
                },
              ),
              Text(
                'الزيادة المتوقعة: +${expectedGain.toStringAsFixed(2)} نقطة',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // --- قائمة التمارين ---
        Expanded(
          child: ListView.builder(
            itemCount: exercises.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ex['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${ex['value'].toStringAsFixed(1)}', style: TextStyle(color: ex['color'], fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  subtitle: Text(ex['desc'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentEnergy == 0 ? Colors.grey : ex['color'].withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      int energyToSpend = _selectedEnergy.toInt();
                      if (currentEnergy < energyToSpend || energyToSpend == 0) {
                        QuickRecoveryDialog.show(context, 'energy', 10);
                        return;
                      }
                      player.trainStat(ex['id'], energyToSpend);
                    },
                    child: const Text('تأكيد التدريب', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}