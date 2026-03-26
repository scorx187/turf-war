import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class HospitalView extends StatelessWidget {
  final VoidCallback? onBack;

  const HospitalView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    int left = player.hospitalReleaseTime != null
        ? player.hospitalReleaseTime!.difference(DateTime.now()).inSeconds
        : 0;
    if (left < 0) left = 0;

    // حساب تكلفة العلاج بناءً على الصحة الناقصة وخصم الـ VIP
    int missingHealth = player.maxHealth - player.health;
    int healCost = player.isVIP ? (missingHealth * 0.8).toInt() : missingHealth;
    if (healCost < 1) healCost = 1; // أقل تكلفة ممكنة 1 دولار

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  if (!player.isHospitalized && onBack != null)
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
                  const Text('مستشفى المدينة 🏥', style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.local_hospital, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              player.isHospitalized
                  ? 'أنت تتلقى العلاج الطارئ!'
              // تم تعديل عرض الصحة لتظهر كرقم مقسوم بدل النسبة المئوية
                  : 'صحتك الحالية: ${player.health} / ${player.maxHealth}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (player.isHospitalized) ...[
              const SizedBox(height: 10),
              Text(
                'الوقت المتبقي للخروج: ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.amber, fontSize: 20),
              ),
              const SizedBox(height: 30),
              const Text('يمكنك الانتظار لتتعافى تدريجياً، أو الدفع للخروج فوراً',
                  style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),

            // إظهار أزرار العلاج فقط إذا كانت الصحة ليست كاملة
            if (player.health < player.maxHealth)
              Column(
                children: [
                  // زر العلاج السريع بالكاش
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.attach_money),
                      label: Text(player.isVIP
                          ? 'علاج سريع: $healCost كاش (خصم VIP)'
                          : 'علاج سريع: $healCost كاش'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        player.quickHealHospital();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // زر استخدام الحقيبة الإسعافية
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.medical_information),
                      label: Text(player.inventory.containsKey('medkit')
                          ? 'استخدم حقيبة إسعاف (تملك ${player.inventory['medkit']})'
                          : 'اشترِ حقيبة إسعاف (2000 كاش)'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        if (player.inventory.containsKey('medkit')) {
                          player.useItem('medkit');
                        } else if (player.cash >= 2000) {
                          player.buyItem('medkit', 2000, isConsumable: true);
                          player.useItem('medkit');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك مالاً أو حقائب!')));
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}