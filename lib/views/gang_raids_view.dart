// المسار: lib/views/gang_raids_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';

class GangRaidsView extends StatefulWidget {
  const GangRaidsView({super.key});

  @override
  State<GangRaidsView> createState() => _GangRaidsViewState();
}

class _GangRaidsViewState extends State<GangRaidsView> {
  bool _isExecuting = false;

  final int _gangTotalPower = 15000;

  final List<Map<String, dynamic>> _raids = [
    {
      'id': 'raid_1',
      'name': 'قافلة أسلحة مهربة',
      'desc': 'اعتراض قافلة أسلحة مسلحة تابعة للمافيا الروسية.',
      'energy': 40,
      'courage': 50,
      'reqPower': 5000,
      'reward': 2000000,
      'icon': Icons.local_shipping,
      'color': Colors.orangeAccent,
    },
    {
      'id': 'raid_2',
      'name': 'مقر الكارتل المنافس',
      'desc': 'اقتحام المقر الرئيسي لعصابة الكارتل وتصفية حراسهم.',
      'energy': 80,
      'courage': 100,
      'reqPower': 12000,
      'reward': 6000000,
      'icon': Icons.domain_disabled,
      'color': Colors.redAccent,
    },
    {
      'id': 'raid_3',
      'name': 'البنك الفيدرالي',
      'desc': 'أكبر عملية سطو في تاريخ المدينة، تتطلب قوة عصابة هائلة وحنكة عالية.',
      'energy': 150,
      'courage': 200,
      'reqPower': 30000,
      'reward': 25000000,
      'icon': Icons.account_balance,
      'color': Colors.amber,
    },
  ];

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  void _executeRaid(Map<String, dynamic> raid, PlayerProvider player, AudioProvider audio) async {
    if (_isExecuting) return;

    int raidEnergy = raid['energy'] as int;
    int raidCourage = raid['courage'] as int;
    int raidReqPower = raid['reqPower'] as int;
    int raidReward = raid['reward'] as int;

    if (player.energy < raidEnergy) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طاقة غير كافية لشن الغارة!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      return;
    }
    if (player.courage < raidCourage) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شجاعة غير كافية! الأعضاء يحتاجون قائد مقدام.', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isExecuting = true);
    audio.playEffect('attack.mp3');

    // خصم الموارد محلياً
    player.setEnergy(player.energy - raidEnergy);
    player.setCourage(player.courage - raidCourage);

    BuildContext? loadingDialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        loadingDialogContext = c;
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(15), border: Border.all(color: raid['color'], width: 2)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: raid['color']),
                const SizedBox(height: 15),
                Text('جاري اقتحام [ ${raid['name']} ]... 🧨', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16, decoration: TextDecoration.none)),
                const SizedBox(height: 5),
                const Text('يتم تبادل إطلاق النار...', style: TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 12, decoration: TextDecoration.none)),
              ],
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // إغلاق نافذة التحميل بأمان تام
    if (loadingDialogContext != null) {
      Navigator.pop(loadingDialogContext!);
    }

    int successChance = 50;
    if (_gangTotalPower >= raidReqPower) {
      successChance += 35;
    } else {
      successChance -= 30;
    }

    int roll = Random().nextInt(100) + 1;

    if (roll <= successChance) {
      audio.playEffect('click.mp3');
      player.addCash(raidReward, reason: 'غنائم الغارة المشتركة على ${raid['name']}');

      int gangCut = (raidReward * 0.1).toInt();
      player.contributeToGang(gangCut);

      // نمرر isLoss: false لأننا فزنا
      _showResultDialog('نصر كاسح! 🚩', 'نجحت الغارة وحطمنا دفاعاتهم. غنمنا \$${_formatWithCommas(raidReward)} كاش، وتم تحويل 10% منها لصندوق العصابة!', Colors.green, isLoss: false);
    } else {
      audio.playEffect('attack.mp3');
      player.setHealth(0);

      // 🟢 التعديل الأهم: نمرر isLoss: true عشان نضمن الطرد للمستشفى بدون ما نعتمد على قراءة السيرفر
      _showResultDialog('كمين محكم! 💀', 'كانت دفاعاتهم أقوى من المتوقع، تكبدنا خسائر فادحة وأنت الآن في المستشفى تتلقى العلاج.', Colors.redAccent, isLoss: true);
    }

    setState(() => _isExecuting = false);
  }

  // 🟢 استقبال حالة الخسارة مباشرة من الدالة بدل قراءتها من الـ Provider
  void _showResultDialog(String title, String message, Color color, {required bool isLoss}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: color, width: 2)),
            title: Text(title, style: TextStyle(color: color, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            content: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', height: 1.5)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () {
                  // 1. قفل الرسالة المنبثقة
                  Navigator.pop(c);

                  // 2. الانتقال الفوري والمؤكد للخريطة/المستشفى لو كانت الغارة خاسرة
                  if (isLoss) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                child: const Text('حسناً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              )
            ],
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        body: SafeArea(
          top: false,
          child: Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final audio = Provider.of<AudioProvider>(context, listen: false);

                return Column(
                  children: [
                    const TopBar(),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border(bottom: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 2)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.orangeAccent, size: 20),
                              onPressed: () { audio.playEffect('click.mp3'); Navigator.pop(context); }
                          ),
                          const Expanded(
                            child: Text('الغارات المشتركة 🧨', style: TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.all(15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('قوة العصابة الإجمالية:', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 14)),
                          Row(
                            children: [
                              const Icon(Icons.flash_on, color: Colors.amber, size: 18),
                              const SizedBox(width: 5),
                              Text(_formatWithCommas(_gangTotalPower), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Changa')),
                            ],
                          )
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        itemCount: _raids.length,
                        itemBuilder: (context, index) {
                          final raid = _raids[index];
                          bool hasEnoughPower = _gangTotalPower >= raid['reqPower'];
                          bool canAfford = player.energy >= raid['energy'] && player.courage >= raid['courage'];

                          return Card(
                            color: Colors.black45,
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: raid['color'].withValues(alpha: 0.4), width: 1.5)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: raid['color'].withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: raid['color'].withValues(alpha: 0.5))),
                                        child: Icon(raid['icon'], color: raid['color'], size: 28),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(raid['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                            Text('القوة المطلوبة: ${_formatWithCommas(raid['reqPower'])}', style: TextStyle(color: hasEnoughPower ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('الغنيمة', style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Changa')),
                                          Text('\$${_formatCompact(raid['reward'])}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(raid['desc'], style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Changa', height: 1.4)),
                                  const SizedBox(height: 12),
                                  const Divider(color: Colors.white10, height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.bolt, color: Colors.lightBlueAccent, size: 16),
                                          Text('${raid['energy']}', style: TextStyle(color: player.energy >= raid['energy'] ? Colors.lightBlueAccent : Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 15),
                                          const Icon(Icons.shield, color: Colors.greenAccent, size: 16),
                                          Text('${raid['courage']}', style: TextStyle(color: player.courage >= raid['courage'] ? Colors.greenAccent : Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: canAfford ? raid['color'] : Colors.grey[800],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          minimumSize: const Size(80, 35),
                                        ),
                                        onPressed: _isExecuting || !canAfford ? null : () => _executeRaid(raid, player, audio),
                                        child: const Text('بدأ الغارة', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
          ),
        ),
      ),
    );
  }

  String _formatCompact(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return number.toString();
  }
}