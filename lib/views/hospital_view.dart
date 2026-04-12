// المسار: lib/views/hospital_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart'; // 🟢 مكتبة الكلاود فنكشن
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final player = Provider.of<PlayerProvider>(context, listen: false);

        if (player.isHospitalized && player.hospitalReleaseTime != null) {
          // 🟢 تعديل أمني: استخدام secureNow لمزامنة الوقت مع السيرفر
          final diff = player.hospitalReleaseTime!.difference(player.secureNow).inSeconds;
          setState(() {
            _secondsLeft = diff > 0 ? diff : 0;
          });

          if (_secondsLeft <= 0) {
            timer.cancel();
            // خروج تلقائي إذا انتهى الوقت فعلاً
            player.releaseFromHospital();
          }
        } else {
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

  // 🟢 الدالة الآمنة للعلاج عبر السيرفر
  Future<void> _secureHeal(PlayerProvider player, AudioProvider audio, String healType) async {
    int missingHealth = player.maxHealth - player.health;
    int healCost = player.isVIP ? (missingHealth * 0.8).toInt() : missingHealth;

    // حماية شكلية سريعة عشان ما نرسل طلب خاسر للسيرفر
    if (healType == 'cash' && player.cash < healCost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك كاش كافي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      return;
    } else if (healType == 'medkit' && !player.inventory.containsKey('medkit') && player.cash < 2000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك كاش كافي لشراء حقيبة!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)));

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('healPlayer');
      final result = await callable.call({
        'uid': player.uid,
        'healType': healType, // 'cash', 'vip', 'medkit'
      });

      Navigator.pop(context);

      if (result.data['success'] == true) {
        audio.playEffect('click.mp3');
        // السيرفر عالجه وخصم الفلوس، هنا نُحدث الشاشة فقط لتنعكس الأرقام فوراً
        player.setHealth(player.maxHealth);
        if (player.isHospitalized) player.releaseFromHospital();

        if (healType == 'cash') {
          player.removeCash(healCost, reason: 'علاج بالمستشفى');
        } else if (healType == 'medkit') {
          if (player.inventory.containsKey('medkit') && player.inventory['medkit']! > 0) {
            player.inventory['medkit'] = player.inventory['medkit']! - 1;
            if (player.inventory['medkit'] == 0) player.inventory.remove('medkit');
          } else {
            player.removeCash(2000, reason: 'شراء حقيبة طبية');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم العلاج بنجاح! 🩹', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مرفوض من السيرفر: ${e.toString()}', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

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
              Text(
                player.isHospitalized ? 'أنت تتعالج في المستشفى! 🏥' : 'عيادة الطوارئ 🏥',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Changa'
                ),
              ),
              const SizedBox(height: 10),

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
                    ? 'إصابتك بالغة، يجب أن تنتظر أو تدفع للتسرع.\n(يمكنك الضغط على الشات في الأسفل للتحدث مع المرضى)'
                    : 'صحتك الحالية: ${player.health} / ${player.maxHealth}',
                style: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Changa', height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 🟢 زر الدفع بالكاش
              if (player.health < player.maxHealth) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: player.cash >= healCost
                        ? () => _secureHeal(player, audio, 'cash')
                        : null,
                    icon: const Icon(Icons.attach_money, color: Colors.white),
                    label: Text(
                      'علاج كامل\nالتكلفة: \$$healCost',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // 🟢 زر العلاج المجاني للـ VIP
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: player.isVIP ? Colors.amber : Colors.grey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: player.isVIP
                        ? () => _secureHeal(player, audio, 'vip')
                        : null,
                    icon: Icon(Icons.workspace_premium, color: player.isVIP ? Colors.black : Colors.white),
                    label: Text(
                      player.isVIP ? 'علاج VIP مجاني' : 'علاج مجاني (فقط للـ VIP)',
                      style: TextStyle(color: player.isVIP ? Colors.black : Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 🟢 زر استخدام/شراء الحقيبة الطبية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _secureHeal(player, audio, 'medkit'),
                    icon: const Icon(Icons.medical_services, color: Colors.white),
                    label: Text(
                      player.inventory.containsKey('medkit')
                          ? 'استخدم حقيبة إسعاف (تملك ${player.inventory['medkit']})'
                          : 'شراء واستخدام حقيبة إسعاف (\$2000)',
                      style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              if (!player.isHospitalized && widget.onBack != null && player.health == player.maxHealth) ...[
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: () {
                    audio.playEffect('click.mp3');
                    widget.onBack!();
                  },
                  child: const Text('مغادرة المستشفى', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}