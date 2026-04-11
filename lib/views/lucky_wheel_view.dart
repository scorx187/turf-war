// المسار: lib/views/lucky_wheel_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/audio_provider.dart';
import '../providers/player_provider.dart';
import 'player_profile_view.dart';
import 'dart:math';
import 'dart:async';

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
  int _currentIndex = 0;
  String _statusText = "";

  // 🟢 الترتيب الهندسي للجوائز والنسب 🟢
  final List<Map<String, dynamic>> prizes = [
    {'id': 'gold_600', 'name': '600 ذهب', 'icon': Icons.monetization_on, 'color': Colors.yellow, 'chance': 0.20}, // 20%
    {'id': 'cash_50m', 'name': '50 مليون', 'icon': Icons.money, 'color': Colors.lightGreenAccent, 'chance': 0.05}, // 5%
    {'id': 'cash_10m', 'name': '10 مليون', 'icon': Icons.attach_money, 'color': Colors.green, 'chance': 0.25}, // 25%
    {'id': 't_aladdin_lamp', 'name': 'المصباح السحري', 'icon': Icons.lightbulb, 'color': Colors.amberAccent, 'chance': 0.06}, // 6%
    {'id': 't_aladdin_carpet', 'name': 'البساط الطائر', 'icon': Icons.map, 'color': Colors.purpleAccent, 'chance': 0.06}, // 6%
    {'id': 't_magic_ring', 'name': 'خاتم السلطة', 'icon': Icons.radio_button_checked, 'color': Colors.orange, 'chance': 0.06}, // 6%
    {'id': 'w_aladdin_damage', 'name': 'سيف الضرر', 'icon': Icons.hardware, 'color': Colors.redAccent, 'chance': 0.03}, // 3%
    {'id': 'a_aladdin_evasion', 'name': 'عباءة مراوغة', 'icon': Icons.air, 'color': Colors.cyanAccent, 'chance': 0.03}, // 3%
    {'id': 'a_aladdin_defense', 'name': 'درع دفاع', 'icon': Icons.shield, 'color': Colors.blue, 'chance': 0.03}, // 3%
    {'id': 'w_aladdin_accuracy', 'name': 'خنجر الدقة', 'icon': Icons.flash_on, 'color': Colors.deepOrange, 'chance': 0.03}, // 3%
    {'id': 'vip_7', 'name': 'VIP أسبوع', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'chance': 0.10}, // 10%
    {'id': 'perk_point', 'name': 'نقطة امتياز', 'icon': Icons.star, 'color': Colors.blueAccent, 'chance': 0.10}, // 10%
  ];

  Future<void> _spin(int times, AudioProvider audio, PlayerProvider player) async {
    int cost = times == 1 ? 500 : 4500;

    if (player.gold < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافٍ!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() {
      _isSpinning = true;
      _statusText = "🎰 جاري تدوير العجلة...";
    });

    player.removeGold(cost);
    for(int i = 0; i < times; i++) {
      player.incrementLuckyWheelSpins();
    }

    List<Map<String, dynamic>> wonPrizes = [];
    for(int i = 0; i < times; i++) {
      double r = Random().nextDouble();
      double cumulative = 0;
      Map<String, dynamic>? selected;
      for (var p in prizes) {
        cumulative += p['chance'];
        if (r <= cumulative) {
          selected = p;
          break;
        }
      }
      wonPrizes.add(selected ?? prizes.last);
    }

    int targetIndex = prizes.indexOf(wonPrizes.last);
    int totalSteps = (12 * 3) + targetIndex - _currentIndex;
    if (totalSteps < 12) totalSteps += 12;

    int delay = 40;
    for(int i = 0; i < totalSteps; i++) {
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % 12;
      });

      if (totalSteps - i < 15) delay += 15;
      if (totalSteps - i < 5) delay += 40;
    }

    // 🟢 إضافة الأسماء في القاعدة بعد ما توقف العجلة (الأسماء راح تظهر فجأة بدون لودينج) 🟢
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var p in wonPrizes) {
      var docRef = FirebaseFirestore.instance.collection('wheel_winners').doc();
      batch.set(docRef, {
        'uid': player.uid,
        'playerName': player.playerName,
        'profilePicUrl': player.profilePicUrl,
        'isVIP': player.isVIP,
        'prizeName': p['name'],
        'prizeColor': p['color'].value,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    for (var p in wonPrizes) {
      if (p['id'] == 'cash_10m') player.addCash(10000000, reason: "عجلة الحظ");
      else if (p['id'] == 'cash_50m') player.addCash(50000000, reason: "عجلة الحظ");
      else if (p['id'] == 'gold_600') player.addGold(600);
      else if (p['id'] == 'perk_point') player.addBonusPerkPoint(1);
      else player.addInventoryItem(p['id'], 1);
    }

    audio.playEffect('click.mp3');

    if (mounted) {
      setState(() {
        _isSpinning = false;
        _statusText = "";
      });

      if (times == 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("مبروك! حصلت على ${wonPrizes.first['name']}!", style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
        ));
      } else {
        _show10xRewardsDialog(wonPrizes);
      }
    }
  }

  void _show10xRewardsDialog(List<Map<String, dynamic>> wonPrizes) {
    Map<String, int> counts = {};
    for(var w in wonPrizes) {
      counts[w['name']] = (counts[w['name']] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 2)),
          title: const Text('حصيلة الـ 10 لفات 🎰', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: counts.entries.map((e) {
              var prizeData = prizes.firstWhere((p) => p['name'] == e.key);
              return Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: prizeData['color'].withOpacity(0.5))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(prizeData['icon'], color: prizeData['color'], size: 28),
                    const SizedBox(height: 5),
                    Text(e.key, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber[800], borderRadius: BorderRadius.circular(5)),
                      child: Text('x${e.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('جمع الغنائم', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 استرجاع الـ Expanded داخل الخلايا عشان تتوزع بالتساوي 100% 🟢
  Widget _buildCell(int index) {
    var prize = prizes[index];
    bool isHighlighted = _currentIndex == index;

    return Expanded(
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isHighlighted ? prize['color'].withOpacity(0.3) : Colors.black54,
            border: Border.all(
                color: isHighlighted ? Colors.yellowAccent : Colors.white12,
                width: isHighlighted ? 3 : 1
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isHighlighted ? [BoxShadow(color: Colors.yellowAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2)] : [],
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(prize['icon'], color: prize['color'], size: 26),
                const SizedBox(height: 4),
                Text(
                  prize['name'],
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]
          )
      ),
    );
  }

  // 🟢 أزرار الشراء صارت تتوزع بشكل متساوي ومرتب 🟢
  Widget _buildCenterTop(AudioProvider audio, PlayerProvider player) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 2, left: 2, right: 2, bottom: 1),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.orangeAccent)),
            padding: EdgeInsets.zero,
          ),
          onPressed: _isSpinning ? null : () => _spin(1, audio, player),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('لفة واحدة', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 11)),
              Text('500 ذهب', style: TextStyle(color: Colors.yellowAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterBot(AudioProvider audio, PlayerProvider player) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 1, left: 2, right: 2, bottom: 2),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[800],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.redAccent)),
            padding: EdgeInsets.zero,
          ),
          onPressed: _isSpinning ? null : () => _spin(10, audio, player),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('10 لفات', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 11)),
              Text('4500 ذهب', style: TextStyle(color: Colors.yellowAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 شريط الفائزين: لا يظهر أي لودنج، ثابت تماماً ويتحدث فجأة عند انتهاء اللفة 🟢
  Widget _buildWinnersFeed(PlayerProvider player) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: const Text('🏆 اسماء اخر الفائزين 🏆', textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('wheel_winners')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  // إخفاء دائرة التحميل بالكامل عشان الأسماء تفضل موجودة وما ترمش
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: SizedBox()); // شاشة صامتة ثواني بسيطة أول ما يفتح فقط
                    }
                    return const Center(child: Text("كن أول الفائزين!", style: TextStyle(color: Colors.white54, fontFamily: 'Changa')));
                  }

                  var docs = snapshot.data!.docs;
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String timeStr = "الآن";
                      if (data['timestamp'] != null) {
                        timeStr = DateFormat('hh:mm a').format((data['timestamp'] as Timestamp).toDate());
                      }
                      Color prizeColor = Color(data['prizeColor'] ?? Colors.amber.value);
                      bool isMe = data['uid'] == player.uid;

                      return InkWell(
                        onTap: isMe ? null : () {
                          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerProfileView(
                            targetUid: data['uid'],
                            profileTabIndex: 0,
                            previewName: data['playerName'],
                            previewPicUrl: data['profilePicUrl'],
                            previewIsVIP: data['isVIP'] ?? false,
                            onBack: () => Navigator.pop(context),
                          )));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.stars, color: Colors.amber, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: RichText(
                                    text: TextSpan(
                                        style: const TextStyle(fontFamily: 'Changa', fontSize: 10),
                                        children: [
                                          const TextSpan(text: 'كسب اللاعب ', style: TextStyle(color: Colors.white70)),
                                          TextSpan(text: '${data['playerName']}', style: TextStyle(color: isMe ? Colors.amber : Colors.blueAccent, fontWeight: FontWeight.bold)),
                                          const TextSpan(text: ' على ', style: TextStyle(color: Colors.white70)),
                                          TextSpan(text: '${data['prizeName']}', style: TextStyle(color: prizeColor, fontWeight: FontWeight.bold)),
                                        ]
                                    )
                                ),
                              ),
                              Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 8, fontFamily: 'Changa')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0, right: 10, left: 10, bottom: 5),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                    onPressed: _isSpinning ? null : widget.onBack),
                const Text('عجلة الحظ الأسطورية',
                    style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              ],
            ),
          ),

          // 🟢 العجلة تم إرجاعها مربعة ومتساوية تماماً باستخدام AspectRatio(1.0) 🟢
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
            ),
            child: AspectRatio(
              aspectRatio: 1.0, // هذا السطر يضمن أن العجلة مربعة تماماً وكل خلية متساوية!
              child: Column(
                children: [
                  Expanded(
                    child: Row(children: [ _buildCell(0), _buildCell(1), _buildCell(2), _buildCell(3) ]),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(child: Column(children: [ _buildCell(11), _buildCell(10) ])),
                        Expanded(flex: 2, child: Column(children: [ _buildCenterTop(audio, player), _buildCenterBot(audio, player) ])),
                        Expanded(child: Column(children: [ _buildCell(4), _buildCell(5) ])),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(children: [ _buildCell(9), _buildCell(8), _buildCell(7), _buildCell(6) ]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 5),

          if (_statusText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Text(_statusText, style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ),

          // 🟢 شريط الفائزين 🟢
          _buildWinnersFeed(player),
        ],
      ),
    );
  }
}