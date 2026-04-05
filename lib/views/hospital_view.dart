// المسار: lib/views/hospital_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class HospitalView extends StatefulWidget {
  final VoidCallback? onBack;

  const HospitalView({super.key, this.onBack});

  @override
  State<HospitalView> createState() => _HospitalViewState();
}

class _HospitalViewState extends State<HospitalView> {
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    // 🟢 الـ Timer هذا يحدث الشاشة كل ثانية عشان ينزل العداد بسلاسة 🟢
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final player = Provider.of<PlayerProvider>(context, listen: false);

        if (player.isHospitalized && player.hospitalReleaseTime != null) {
          final diff = player.hospitalReleaseTime!.difference(DateTime.now()).inSeconds;
          setState(() {
            _secondsLeft = diff > 0 ? diff : 0;
          });

          // إذا انتهى الوقت، المفروض البروفايدر يطلعه، بس كاحتياط نوقف العداد
          if (_secondsLeft <= 0) {
            timer.cancel();
          }
        } else {
          // لو تعالج، نوقف التايمر ونصفر العداد
          setState(() {
            _secondsLeft = 0;
          });
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    // تحديث مبدئي إذا التايمر لسه ما لقط القيمة
    if (player.isHospitalized && player.hospitalReleaseTime != null && _secondsLeft == 0) {
      _secondsLeft = player.hospitalReleaseTime!.difference(DateTime.now()).inSeconds;
      if (_secondsLeft < 0) _secondsLeft = 0;
    }

    int missingHealth = player.maxHealth - player.health;
    int healCost = player.isVIP ? (missingHealth * 0.8).toInt() : missingHealth;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_hospital, color: Colors.redAccent, size: 100),
              const SizedBox(height: 20),
              const Text(
                'أنت تتعالج في المستشفى! 🏥',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Changa'
                ),
              ),
              const SizedBox(height: 10),

              // 🟢 استخدام المتغير اللحظي _secondsLeft 🟢
              if (player.isHospitalized && _secondsLeft > 0)
                Text(
                  'الوقت المتبقي للخروج: ${(_secondsLeft / 60).floor()} دقيقة و ${_secondsLeft % 60} ثانية',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontFamily: 'Changa'
                  ),
                ),

              const SizedBox(height: 30),

              Text(
                player.isHospitalized
                    ? 'إصابتك بالغة، يجب أن تنتظر أو تدفع للتسرع.'
                    : 'صحتك الحالية: ${player.health} / ${player.maxHealth}',
                style: const TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'Changa'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (player.isHospitalized) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: player.cash >= healCost
                        ? () {
                      audio.playEffect('click.mp3');
                      player.quickHealHospital();
                    }
                        : null,
                    icon: const Icon(Icons.attach_money, color: Colors.white),
                    label: Text(
                      'خروج فوري (علاج كامل)\nالتكلفة: \$$healCost',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              if (player.health < player.maxHealth)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: player.isVIP ? Colors.amber : Colors.grey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: player.isVIP
                        ? () {
                      audio.playEffect('click.mp3');
                      player.quickHealHospital();
                    }
                        : null,
                    icon: Icon(Icons.workspace_premium, color: player.isVIP ? Colors.black : Colors.white),
                    label: Text(
                      player.isVIP ? 'علاج VIP مجاني (قريباً)' : 'علاج مجاني (فقط للـ VIP)',
                      style: TextStyle(color: player.isVIP ? Colors.black : Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              if (player.isHospitalized)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (player.inventory.containsKey('medkit')) {
                        audio.playEffect('click.mp3');
                        player.useItem('medkit');
                      } else if (player.cash >= 2000) {
                        audio.playEffect('click.mp3');
                        // 🟢 تصحيح الخطأ القديم (حذفنا isConsumable)
                        player.buyItem('medkit', 2000);
                        player.useItem('medkit');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك كاش كافي لشراء حقيبة!', style: TextStyle(fontFamily: 'Changa'))));
                      }
                    },
                    icon: const Icon(Icons.medical_services, color: Colors.white),
                    label: Text(
                      player.inventory.containsKey('medkit')
                          ? 'استخدم حقيبة إسعاف (تملك ${player.inventory['medkit']})'
                          : 'شراء واستخدام حقيبة إسعاف (\$2000)',
                      style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              if (!player.isHospitalized && widget.onBack != null) ...[
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                  onPressed: () {
                    audio.playEffect('click.mp3');
                    widget.onBack!();
                  },
                  child: const Text('مغادرة المستشفى', style: TextStyle(color: Colors.white, fontFamily: 'Changa')),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}