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
  // تخزين الطاقة المخصصة لكل تمرين
  Map<String, double> _allocations = {
    'strength': 0,
    'defense': 0,
    'skill': 0,
    'speed': 0,
  };

  // متحكمات النصوص للتدخيل اليدوي
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var key in _allocations.keys) {
      _controllers[key] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // حساب إجمالي الطاقة المحددة
  int get _totalAllocated {
    return _allocations.values.fold(0, (sum, val) => sum + val.toInt());
  }

  void _updateAllocation(String key, double newValue, int maxEnergy) {
    int currentTotalExcludingThis = _totalAllocated - _allocations[key]!.toInt();
    int allowedMax = maxEnergy - currentTotalExcludingThis;

    // منع اللاعب من تجاوز طاقته المتبقية
    double clampedValue = newValue.clamp(0, allowedMax > 0 ? allowedMax : 0).toDouble();

    setState(() {
      _allocations[key] = clampedValue;
      if (_controllers[key]!.text != clampedValue.toInt().toString()) {
        _controllers[key]!.text = clampedValue.toInt().toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final int currentEnergy = player.energy;

    // تنظيف الأرقام إذا الطاقة تغيرت من برا (مثلاً صفرت)
    if (_totalAllocated > currentEnergy) {
      setState(() {
        for (var key in _allocations.keys) {
          _allocations[key] = 0;
          _controllers[key]!.text = '0';
        }
      });
    }

    double gainPerEnergy = 0.01 + (player.happiness * 0.0002);

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
                  // تم التعديل إلى toStringAsFixed(2) لعرض خانتين عشريتين
                  _buildStatMini(Icons.fitness_center, player.strength.toStringAsFixed(2), Colors.redAccent),
                  _buildStatMini(Icons.shield, player.defense.toStringAsFixed(2), Colors.blueAccent),
                  _buildStatMini(Icons.psychology, player.skill.toStringAsFixed(2), Colors.greenAccent),
                  _buildStatMini(Icons.speed, player.speed.toStringAsFixed(2), Colors.orangeAccent),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
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

        // --- قائمة التمارين المرنة ---
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              // أضفنا تمرير الرقم الحالي (player.strength وغيره) للبطاقة عشان ينعرض قدام اللاعب
              _buildTrainingCard('strength', 'رفع الأثقال (قوة)', player.strength, Icons.fitness_center, Colors.redAccent, currentEnergy, gainPerEnergy),
              _buildTrainingCard('defense', 'تمارين التحمل (دفاع)', player.defense, Icons.shield, Colors.blueAccent, currentEnergy, gainPerEnergy, isDefense: true),
              _buildTrainingCard('skill', 'تمارين اليوغا (مهارة)', player.skill, Icons.psychology, Colors.greenAccent, currentEnergy, gainPerEnergy),
              _buildTrainingCard('speed', 'الجري على الآلة (سرعة)', player.speed, Icons.speed, Colors.orangeAccent, currentEnergy, gainPerEnergy),
            ],
          ),
        ),

        // --- لوحة التحكم والتنفيذ السفلية ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            border: const Border(top: BorderSide(color: Colors.amber, width: 2)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الطاقة المحددة للتدريب:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('$_totalAllocated / $currentEnergy ⚡', style: TextStyle(color: _totalAllocated > 0 ? Colors.amber : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _totalAllocated > 0 ? Colors.green : Colors.grey,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (_totalAllocated <= 0) return;
                  if (currentEnergy < _totalAllocated) {
                    QuickRecoveryDialog.show(context, 'energy', _totalAllocated - currentEnergy);
                    return;
                  }

                  // تنفيذ التدريب الشامل بضغطة وحدة!
                  player.trainMultipleStats(
                    _allocations['strength']!.toInt(),
                    _allocations['defense']!.toInt(),
                    _allocations['skill']!.toInt(),
                    _allocations['speed']!.toInt(),
                  );

                  // تصفير الأشرطة بعد التدريب
                  setState(() {
                    for (var key in _allocations.keys) {
                      _allocations[key] = 0;
                      _controllers[key]!.text = '0';
                    }
                  });
                },
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text('تنفيذ التدريب الشامل', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // تم إضافة currentValue هنا لعرضه بصيغة 0.00
  Widget _buildTrainingCard(String key, String title, double currentValue, IconData icon, Color color, int maxEnergy, double gainPerEnergy, {bool isDefense = false}) {
    double allocated = _allocations[key]!;
    double expectedGain = allocated * gainPerEnergy;

    return Card(
      color: Colors.black45,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(icon, color: color)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          // هنا نعرض الرقم الحالي قدام كل تمرين وبخانتين عشريتين
                          Text(currentValue.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Row(
                        children: [
                          Text('+${expectedGain.toStringAsFixed(2)} نقطة', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                          if (isDefense && allocated > 0)
                            const Text(' (+ صحة عشوائية ❤️)', style: TextStyle(color: Colors.pinkAccent, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  height: 30,
                  child: TextField(
                    controller: _controllers[key],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(contentPadding: EdgeInsets.zero, filled: true, fillColor: Colors.black26, border: OutlineInputBorder()),
                    onChanged: (val) {
                      int? parsed = int.tryParse(val);
                      if (parsed != null) _updateAllocation(key, parsed.toDouble(), maxEnergy);
                    },
                  ),
                ),
              ],
            ),
            Slider(
              value: allocated,
              min: 0,
              max: maxEnergy.toDouble(),
              activeColor: color,
              inactiveColor: Colors.white10,
              onChanged: maxEnergy == 0 ? null : (val) {
                _updateAllocation(key, val, maxEnergy);
              },
            ),
          ],
        ),
      ),
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