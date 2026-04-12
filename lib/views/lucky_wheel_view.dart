// المسار: lib/views/lucky_wheel_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/audio_provider.dart';
import '../providers/player_provider.dart';
import 'player_profile_view.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  // 🟢 1. تثبيت الستريم هنا لمنع رمش واختفاء الأسماء أثناء دوران العجلة
  late Stream<QuerySnapshot> _winnersStream;

  final List<Map<String, dynamic>> prizes = [
    {'id': 'gold_600', 'name': '600 ذهب', 'icon': Icons.monetization_on, 'color': Colors.yellow, 'chance': 0.20},
    {'id': 'cash_50m', 'name': '50 مليون', 'icon': Icons.money, 'color': Colors.lightGreenAccent, 'chance': 0.05},
    {'id': 'cash_10m', 'name': '10 مليون', 'icon': Icons.attach_money, 'color': Colors.green, 'chance': 0.25},
    {'id': 't_aladdin_lamp', 'name': 'المصباح السحري', 'icon': Icons.lightbulb, 'color': Colors.amberAccent, 'chance': 0.06},
    {'id': 't_aladdin_carpet', 'name': 'البساط الطائر', 'icon': Icons.map, 'color': Colors.purpleAccent, 'chance': 0.06},
    {'id': 't_magic_ring', 'name': 'خاتم السلطة', 'icon': Icons.radio_button_checked, 'color': Colors.orange, 'chance': 0.06},
    {'id': 'w_aladdin_damage', 'name': 'سيف الضرر', 'icon': Icons.hardware, 'color': Colors.redAccent, 'chance': 0.03},
    {'id': 'a_aladdin_evasion', 'name': 'عباءة مراوغة', 'icon': Icons.air, 'color': Colors.cyanAccent, 'chance': 0.03},
    {'id': 'a_aladdin_defense', 'name': 'درع دفاع', 'icon': Icons.shield, 'color': Colors.blue, 'chance': 0.03},
    {'id': 'w_aladdin_accuracy', 'name': 'خنجر الدقة', 'icon': Icons.flash_on, 'color': Colors.deepOrange, 'chance': 0.03},
    {'id': 'vip_7', 'name': 'VIP أسبوع', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'chance': 0.10},
    {'id': 'perk_point', 'name': 'نقطة امتياز', 'icon': Icons.star, 'color': Colors.blueAccent, 'chance': 0.10},
  ];

  @override
  void initState() {
    super.initState();
    // 🟢 2. تهيئة الستريم مرة واحدة فقط عند فتح الشاشة
    _winnersStream = FirebaseFirestore.instance
        .collection('wheel_winners')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  Future<void> _spin(int times, AudioProvider audio, PlayerProvider player) async {
    int cost = times == 1 ? 500 : 4500;

    if (player.gold < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافٍ!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() {
      _isSpinning = true;
      _statusText = ""; // 🟢 إخفاء النص عند بدء الدوران
    });

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('spinLuckyWheel');
      final result = await callable.call({
        'uid': player.uid,
        'times': times,
      });

      if (result.data['success'] == true) {
        List<dynamic> serverPrizes = result.data['wonPrizes'];
        List<Map<String, dynamic>> wonPrizes = [];

        for (var sp in serverPrizes) {
          wonPrizes.add({
            'id': sp['id'],
            'name': sp['name'],
            'color': Color(sp['colorValue']),
            'icon': prizes.firstWhere((p) => p['id'] == sp['id'], orElse: () => prizes.first)['icon'],
          });
        }

        // 🟢 3. رفع اسم الفائز في الخلفية مباشرة لضمان ظهوره وعدم تعليق الشاشة
        String safePlayerName = player.playerName.isEmpty ? "الزعيم" : player.playerName;
        FirebaseFirestore.instance.collection('wheel_winners').add({
          'uid': player.uid,
          'playerName': safePlayerName,
          'profilePicUrl': player.profilePicUrl ?? '',
          'isVIP': player.isVIP,
          'prizeName': wonPrizes.first['name'],
          'prizeColor': wonPrizes.first['color'].value,
          'timestamp': FieldValue.serverTimestamp(),
        }).catchError((e) => debugPrint("خطأ رفع الفائز: $e"));

        // 🟢 4. تشغيل حركة العجلة بمرونة
        int targetIndex = prizes.indexWhere((p) => p['id'] == wonPrizes.last['id']);
        if (targetIndex == -1) targetIndex = 0;

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

        audio.playEffect('click.mp3');

        // 🟢 5. بعد ما تخلص العجلة دوران، نحدث الأرقام محلياً (بدون استدعاء السيرفر لمنع خطأ التزامن)
        if (mounted) {
          player.gold -= cost;

          for (var p in wonPrizes) {
            if (p['id'] == 'cash_10m') player.cash += 10000000;
            else if (p['id'] == 'cash_50m') player.cash += 50000000;
            else if (p['id'] == 'gold_600') player.gold += 600;
            else if (p['id'] == 'perk_point') player.bonusPerkPoints += 1;
            else player.inventory[p['id']] = (player.inventory[p['id']] ?? 0) + 1;
          }

          // نرسل تحديث للشاشة فقط
          player.notifyListeners();

          setState(() {
            _isSpinning = false; // فك التعليق
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpinning = false; // فك التعليق في حال حدوث خطأ
          _statusText = "";
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ السيرفر: ${e.toString()}', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
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

  Widget _buildCell(int index) {
    var prize = prizes[index];
    bool isHighlighted = _currentIndex == index;

    return AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isHighlighted ? prize['color'].withOpacity(0.3) : Colors.black54,
              border: Border.all(
                  color: isHighlighted ? Colors.yellowAccent : Colors.white12,
                  width: isHighlighted ? 3 : 1
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isHighlighted ? [BoxShadow(color: Colors.yellowAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 2)] : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Icon(prize['icon'], color: prize['color'], size: 20)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        prize['name'],
                        style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]
              ),
            )
        )
    );
  }

  Widget _buildCenterTop(AudioProvider audio, PlayerProvider player) {
    return Container(
      margin: const EdgeInsets.all(1),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.orangeAccent)),
          padding: EdgeInsets.zero,
        ),
        onPressed: _isSpinning ? null : () => _spin(1, audio, player),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('لفة واحدة', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              Text('500 ذهب', style: TextStyle(color: Colors.yellowAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterBot(AudioProvider audio, PlayerProvider player) {
    return Container(
      margin: const EdgeInsets.all(1),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.redAccent)),
          padding: EdgeInsets.zero,
        ),
        onPressed: _isSpinning ? null : () => _spin(10, audio, player),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('10 لفات', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              Text('4500 ذهب', style: TextStyle(color: Colors.yellowAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

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
                // 🟢 استخدام الستريم المحفوظ لضمان الثبات
                stream: _winnersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2));
                  }

                  List<Widget> listItems = [];

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    var docs = snapshot.data!.docs;
                    for (var doc in docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      String timeStr = "الآن";
                      if (data['timestamp'] != null) {
                        timeStr = DateFormat('hh:mm a').format((data['timestamp'] as Timestamp).toDate());
                      }
                      Color prizeColor = Color(data['prizeColor'] ?? Colors.amber.value);
                      bool isMe = data['uid'] == player.uid;

                      listItems.add(
                          InkWell(
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
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.amber, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                        text: TextSpan(
                                            style: const TextStyle(fontFamily: 'Changa', fontSize: 11),
                                            children: [
                                              const TextSpan(text: 'كسب اللاعب ', style: TextStyle(color: Colors.white70)),
                                              TextSpan(text: '${data['playerName']}', style: TextStyle(color: isMe ? Colors.amber : Colors.blueAccent, fontWeight: FontWeight.bold)),
                                              const TextSpan(text: ' على ', style: TextStyle(color: Colors.white70)),
                                              TextSpan(text: '${data['prizeName']}', style: TextStyle(color: prizeColor, fontWeight: FontWeight.bold)),
                                            ]
                                        )
                                    ),
                                  ),
                                  Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Changa')),
                                ],
                              ),
                            ),
                          )
                      );
                    }
                  }

                  if (listItems.isEmpty) {
                    return const Center(child: Text("كن أول الفائزين!", style: TextStyle(color: Colors.white54, fontFamily: 'Changa')));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(4),
                    itemCount: listItems.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 4),
                    itemBuilder: (context, index) => listItems[index],
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

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 65),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [ Expanded(child: _buildCell(0)), Expanded(child: _buildCell(1)), Expanded(child: _buildCell(2)), Expanded(child: _buildCell(3)) ]),
                Row(
                  children: [
                    Expanded(child: Column(children: [ _buildCell(11), _buildCell(10) ])),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          AspectRatio(aspectRatio: 2 / 1, child: _buildCenterTop(audio, player)),
                          AspectRatio(aspectRatio: 2 / 1, child: _buildCenterBot(audio, player)),
                        ],
                      ),
                    ),
                    Expanded(child: Column(children: [ _buildCell(4), _buildCell(5) ])),
                  ],
                ),
                Row(children: [ Expanded(child: _buildCell(9)), Expanded(child: _buildCell(8)), Expanded(child: _buildCell(7)), Expanded(child: _buildCell(6)) ]),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (_statusText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(_statusText, style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ),

          _buildWinnersFeed(player),
        ],
      ),
    );
  }
}