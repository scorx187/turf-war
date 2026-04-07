import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/player_provider.dart';
import 'dart:math';

class LuckyWheelView extends StatefulWidget {
  final int cash;
  final int maxEnergy;
  final int maxCourage;
  final Function(int) onCashChanged;
  final Function(int) onGoldChanged;
  final Function(int) onEnergyChanged;
  final Function(int) onCourageChanged;
  final VoidCallback onBack;

  const LuckyWheelView({
    super.key,
    required this.cash,
    required this.maxEnergy,
    required this.maxCourage,
    required this.onCashChanged,
    required this.onGoldChanged,
    required this.onEnergyChanged,
    required this.onCourageChanged,
    required this.onBack,
  });

  @override
  State<LuckyWheelView> createState() => _LuckyWheelViewState();
}

class _LuckyWheelViewState extends State<LuckyWheelView> {
  bool _isSpinning = false;
  String _statusText = "تكلفة الدورة: 500 ذهب";

  Future<void> _spinWheel(AudioProvider audio, PlayerProvider player) async {
    if (player.gold < 500) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافٍ!'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() {
      _isSpinning = true;
      _statusText = "🎰 جاري تدوير العجلة... انتظر قليلاً";
    });

    player.removeGold(500);
    player.incrementLuckyWheelSpins(); // 🟢 هنا تنحسب الدورة في رصيد الألقاب
    audio.playEffect('click.mp3');

    await Future.delayed(const Duration(seconds: 3));

    final List<Map<String, dynamic>> prizes = [
      {'id': 'sniper', 'name': 'قناصة الصقر', 'icon': Icons.track_changes, 'color': Colors.red, 'chance': 0.01},
      {'id': 'exoskeleton', 'name': 'البدلة الخارقة', 'icon': Icons.precision_manufacturing, 'color': Colors.amber, 'chance': 0.01},
      {'id': 'steel_armor', 'name': 'درع فولاذي', 'icon': Icons.security, 'color': Colors.grey, 'chance': 0.03},
      {'id': 'riot_shield', 'name': 'درع مكافحة الشغب', 'icon': Icons.shield_outlined, 'color': Colors.blue, 'chance': 0.05},
      {'id': 'vip_7', 'name': 'VIP أسبوع', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'chance': 0.05},
      {'id': 'happiness_booster', 'name': 'مشروب السعادة', 'icon': Icons.auto_awesome, 'color': Colors.yellowAccent, 'chance': 0.15},
      {'id': 'coffee', 'name': 'قهوة مركزة', 'icon': Icons.coffee, 'color': Colors.brown, 'chance': 0.20},
      {'id': 'none', 'name': 'حظ أوفر', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.white54, 'chance': 0.50},
    ];

    double r = Random().nextDouble();
    double cumulativeChance = 0;
    Map<String, dynamic>? selectedPrize;

    for (var prize in prizes) {
      cumulativeChance += prize['chance'];
      if (r <= cumulativeChance) {
        selectedPrize = prize;
        break;
      }
    }

    selectedPrize ??= prizes.last;
    String msg = "";

    if (selectedPrize['id'] == 'none') {
      msg = "للأسف، لم تربح شيئاً هذه المرة.";
    } else if (selectedPrize['id'] == 'vip_7') {
      player.buyVIP(7, 0); // Activate VIP directly without cost
      msg = "مبروك! فزت بعضوية VIP لمدة أسبوع!";
    } else {
      player.addItemDirectly(selectedPrize['id']);
      msg = "مبروك! حصلت على ${selectedPrize['name']}!";
    }

    if (mounted) {
      setState(() {
        _isSpinning = false;
        _statusText = "انتهت الدورة: $msg";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: selectedPrize['id'] == 'none' ? Colors.redAccent : Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final player = Provider.of<PlayerProvider>(context, listen: false);

    final List<Map<String, dynamic>> prizes = [
      {'name': 'قناصة الصقر', 'icon': Icons.track_changes, 'color': Colors.red},
      {'name': 'البدلة الخارقة', 'icon': Icons.precision_manufacturing, 'color': Colors.amber},
      {'name': 'درع فولاذي', 'icon': Icons.security, 'color': Colors.grey},
      {'name': 'درع مكافحة الشغب', 'icon': Icons.shield_outlined, 'color': Colors.blue},
      {'name': 'VIP أسبوع', 'icon': Icons.workspace_premium, 'color': Colors.amber},
      {'name': 'مشروب السعادة', 'icon': Icons.auto_awesome, 'color': Colors.yellowAccent},
      {'name': 'قهوة مركزة', 'icon': Icons.coffee, 'color': Colors.brown},
      {'name': 'حظ أوفر', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.white54},
    ];

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack),
                  const Text('عجلة الحظ',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.casino, size: 80, color: Colors.orange),
            const SizedBox(height: 10),
            const Text('جرب حظك الآن!',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(_statusText,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            if (_isSpinning)
              const CircularProgressIndicator(color: Colors.orange),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.withValues(alpha:0.3))),
              child: Column(
                children: [
                  const Text('الجوائز المحتملة:',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: prizes
                        .map((p) => Container(
                      width: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Icon(p['icon'], color: p['color'], size: 24),
                          const SizedBox(height: 5),
                          Text(p['name'],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ))
                        .toList(),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _isSpinning ? Colors.grey : Colors.orange,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
              onPressed: _isSpinning ? null : () => _spinWheel(audio, player),
              child: const Text('أدر العجلة الآن!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}