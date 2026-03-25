import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class ChopShopView extends StatefulWidget {
  final VoidCallback onBack;
  const ChopShopView({super.key, required this.onBack});

  @override
  State<ChopShopView> createState() => _ChopShopViewState();
}

class _ChopShopViewState extends State<ChopShopView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // تحديث الشاشة كل ثانية عشان العداد التنازلي يشتغل لايف
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    int stolenCarsCount = player.inventory['stolen_car'] ?? 0;
    bool isChopping = player.isChopping;
    DateTime? endTime = player.chopShopEndTime;

    bool isDone = false;
    Duration remainingTime = Duration.zero;

    if (isChopping && endTime != null) {
      if (DateTime.now().isAfter(endTime)) {
        isDone = true;
      } else {
        remainingTime = endTime.difference(DateTime.now());
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
              const Expanded(child: Text('تشليح السيارات 🔧', style: TextStyle(color: Colors.deepOrange, fontSize: 24, fontWeight: FontWeight.bold))),
            ],
          ),
        ),

        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة الكراج
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.deepOrange, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.deepOrange.withValues(alpha:0.2), blurRadius: 20, spreadRadius: 5)
                        ]
                    ),
                    child: const Icon(Icons.car_crash, size: 80, color: Colors.deepOrange),
                  ),
                  const SizedBox(height: 30),

                  // عدد السيارات في المخزن
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car, color: Colors.white70),
                        const SizedBox(width: 10),
                        Text("سيارات مسروقة جاهزة للتفكيك: $stolenCarsCount", style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // حالة العمل والزر
                  if (!isChopping) ...[
                    const Text("الكراج فاضي. جيب سيارة من الجرائم وخلينا نشتغل!", style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: stolenCarsCount > 0 ? Colors.deepOrange : Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      onPressed: stolenCarsCount > 0 ? () {
                        audio.playEffect('click.mp3');
                        player.startChopping();
                      } : null,
                      icon: const Icon(Icons.build, color: Colors.white),
                      label: const Text("ابدأ التفكيك (يستغرق 30 دقيقة)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ]
                  else if (isChopping && !isDone) ...[
                    const Text("جاري تفكيك السيارة واستخراج القطع الثمينة...", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Text(_formatDuration(remainingTime), style: const TextStyle(color: Colors.white, fontSize: 40, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Colors.deepOrange),
                  ]
                  else if (isChopping && isDone) ...[
                      const Icon(Icons.check_circle, color: Colors.green, size: 60),
                      const SizedBox(height: 15),
                      const Text("تم التفكيك بنجاح! القطع جاهزة للبيع.", style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        onPressed: () {
                          audio.playEffect('click.mp3');
                          player.collectChoppedCar();
                        },
                        icon: const Icon(Icons.attach_money, color: Colors.white),
                        label: const Text("استلام الأرباح (15,000 كاش)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}