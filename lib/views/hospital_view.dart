// المسار: lib/views/hospital_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🟢 استدعاء البلوك
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../controllers/hospital_cubit.dart'; // 🟢 استدعاء الكيوبت

class HospitalView extends StatelessWidget {
  final VoidCallback? onBack;

  const HospitalView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    // 🟢 نوفر الكيوبت لهذي الشاشة فقط
    return BlocProvider(
      create: (context) => HospitalCubit(),
      child: _HospitalViewContent(onBack: onBack),
    );
  }
}

class _HospitalViewContent extends StatefulWidget {
  final VoidCallback? onBack;

  const _HospitalViewContent({this.onBack});

  @override
  State<_HospitalViewContent> createState() => _HospitalViewContentState();
}

class _HospitalViewContentState extends State<_HospitalViewContent> {
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  // 🟢 مؤقت الواجهة يبقى كما هو لأنه يخص العرض فقط
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final player = Provider.of<PlayerProvider>(context, listen: false);

        if (player.isHospitalized && player.hospitalReleaseTime != null) {
          final diff = player.hospitalReleaseTime!.difference(player.secureNow).inSeconds;
          setState(() {
            _secondsLeft = diff > 0 ? diff : 0;
          });

          if (_secondsLeft <= 0) {
            timer.cancel();
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

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final cubit = context.read<HospitalCubit>();

    int healCost = cubit.calculateHealCost(player.maxHealth, player.health, player.isVIP);
    bool hasMedkit = player.inventory.containsKey('medkit') && player.inventory['medkit']! > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<HospitalCubit, HospitalState>(
        listener: (context, state) {
          if (state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage, style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
          }
          if (state.successMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Center(
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

                      if (player.health < player.maxHealth) ...[
                        // 🟢 زر الدفع بالكاش
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: (player.cash >= healCost && !state.isLoading)
                                ? () => cubit.processHealing(
                              uid: player.uid!,
                              healType: 'cash',
                              healCost: healCost,
                              currentCash: player.cash,
                              hasMedkit: hasMedkit,
                              onSuccessCallback: () {
                                audio.playEffect('click.mp3');
                                player.setHealth(player.maxHealth);
                                if (player.isHospitalized) player.releaseFromHospital();
                                player.removeCash(healCost, reason: 'علاج بالمستشفى');
                              },
                            )
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
                            onPressed: (player.isVIP && !state.isLoading)
                                ? () => cubit.processHealing(
                              uid: player.uid!,
                              healType: 'vip',
                              healCost: 0,
                              currentCash: player.cash,
                              hasMedkit: hasMedkit,
                              onSuccessCallback: () {
                                audio.playEffect('click.mp3');
                                player.setHealth(player.maxHealth);
                                if (player.isHospitalized) player.releaseFromHospital();
                              },
                            )
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
                            onPressed: state.isLoading
                                ? null
                                : () => cubit.processHealing(
                              uid: player.uid!,
                              healType: 'medkit',
                              healCost: 2000,
                              currentCash: player.cash,
                              hasMedkit: hasMedkit,
                              onSuccessCallback: () {
                                audio.playEffect('click.mp3');
                                player.setHealth(player.maxHealth);
                                if (player.isHospitalized) player.releaseFromHospital();

                                if (hasMedkit) {
                                  player.inventory['medkit'] = player.inventory['medkit']! - 1;
                                  if (player.inventory['medkit'] == 0) player.inventory.remove('medkit');
                                } else {
                                  player.removeCash(2000, reason: 'شراء حقيبة طبية');
                                }
                              },
                            ),
                            icon: const Icon(Icons.medical_services, color: Colors.white),
                            label: Text(
                              hasMedkit
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

              // 🟢 شاشة التحميل تظهر بسلاسة فوق الواجهة أثناء الاتصال بالسيرفر
              if (state.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}