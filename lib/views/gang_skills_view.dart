// المسار: lib/views/gang_skills_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';

class GangSkillsView extends StatefulWidget {
  final String gangName;

  const GangSkillsView({super.key, required this.gangName});

  @override
  State<GangSkillsView> createState() => _GangSkillsViewState();
}

class _GangSkillsViewState extends State<GangSkillsView> {
  // 🟢 بيانات وهمية مؤقتة لصندوق العصابة والمهارات (تُربط لاحقاً بفايربيس)
  int _gangFunds = 5000000;

  final List<Map<String, dynamic>> _skills = [
    {
      'id': 'money_laundry',
      'name': 'غسيل الأموال',
      'desc': 'يزيد من العوائد المالية لجميع جرائم الأعضاء بنسبة 5% لكل مستوى.',
      'icon': Icons.local_atm,
      'color': Colors.greenAccent,
      'level': 2,
      'maxLevel': 5,
      'baseCost': 250000,
    },
    {
      'id': 'brute_force',
      'name': 'القوة الغاشمة',
      'desc': 'يرفع قوة هجوم العصابة في حروب السيطرة على المناطق.',
      'icon': Icons.fitness_center,
      'color': Colors.redAccent,
      'level': 1,
      'maxLevel': 5,
      'baseCost': 500000,
    },
    {
      'id': 'corrupt_lawyers',
      'name': 'محامين فاسدين',
      'desc': 'يقلل من فرصة دخول السجن ويخفض تكلفة الكفالة للأعضاء.',
      'icon': Icons.gavel,
      'color': Colors.amber,
      'level': 0,
      'maxLevel': 5,
      'baseCost': 1000000,
    },
    {
      'id': 'black_market_docs',
      'name': 'أطباء الظل',
      'desc': 'يسرع من وقت الشفاء في المستشفى بعد المعارك الخاسرة.',
      'icon': Icons.local_hospital,
      'color': Colors.blueAccent,
      'level': 5,
      'maxLevel': 5,
      'baseCost': 400000,
    },
  ];

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  void _upgradeSkill(int index, PlayerProvider player, AudioProvider audio) {
    final skill = _skills[index];
    int cost = skill['baseCost'] * (skill['level'] + 1);

    // التحقق من الصلاحيات (الزعيم أو نائبه فقط)
    if (player.gangRank != 'الزعيم' && player.gangRank != 'نائب الزعيم') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الزعيم ونائبه فقط من يمكنهم ترقية المهارات!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
      return;
    }

    if (skill['level'] >= skill['maxLevel']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المهارة وصلت للحد الأقصى!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.amber));
      return;
    }

    if (_gangFunds < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('صندوق العصابة لا يكفي للترقية!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
      return;
    }

    audio.playEffect('click.mp3');

    // تأثير تحميل بسيط
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context); // إغلاق التحميل
        setState(() {
          _gangFunds -= cost;
          _skills[index]['level']++;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم ترقية [${skill['name']}] بنجاح! 🎉', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.green));
      }
    });
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
                    // 🟢 التوب بار الثابت
                    const TopBar(),

                    // 🟢 هيدر الشاشة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border(bottom: BorderSide(color: Colors.purpleAccent.withOpacity(0.5), width: 2)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.purpleAccent, size: 20),
                              onPressed: () { audio.playEffect('click.mp3'); Navigator.pop(context); }
                          ),
                          Expanded(
                            child: Row(
                              children: const [
                                Text('مهارات العصابة 🧠', style: TextStyle(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🟢 صندوق العصابة (الرصيد المتاح للترقية)
                    Container(
                      margin: const EdgeInsets.all(15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('صندوق العصابة:', style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                          Text('\$${_formatWithCommas(_gangFunds)}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa', shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
                        ],
                      ),
                    ),

                    // 🟢 شجرة المهارات
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        itemCount: _skills.length,
                        itemBuilder: (context, index) {
                          final skill = _skills[index];
                          int currentLevel = skill['level'];
                          int maxLevel = skill['maxLevel'];
                          int nextCost = skill['baseCost'] * (currentLevel + 1);
                          bool isMaxed = currentLevel >= maxLevel;
                          double progress = currentLevel / maxLevel;

                          return Card(
                            color: Colors.black45,
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: skill['color'].withOpacity(0.5))),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // أيقونة المهارة
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: skill['color'].withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: skill['color'].withOpacity(0.5))),
                                    child: Icon(skill['icon'], color: skill['color'], size: 30),
                                  ),
                                  const SizedBox(width: 15),

                                  // تفاصيل المهارة
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(skill['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                            Text('LVL $currentLevel/$maxLevel', style: TextStyle(color: isMaxed ? Colors.amber : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(skill['desc'], style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Changa', height: 1.4)),
                                        const SizedBox(height: 10),

                                        // شريط تقدم المهارة
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(5),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 6,
                                            backgroundColor: Colors.white10,
                                            valueColor: AlwaysStoppedAnimation<Color>(isMaxed ? Colors.amber : skill['color']),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // زر الترقية
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isMaxed ? Colors.grey[800] : Colors.purpleAccent.shade700,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          minimumSize: const Size(60, 35),
                                        ),
                                        onPressed: isMaxed ? null : () => _upgradeSkill(index, player, audio),
                                        child: Text(isMaxed ? 'مكتمل' : 'ترقية', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      if (!isMaxed) ...[
                                        const SizedBox(height: 4),
                                        Text('\$${_formatCompact(nextCost)}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                      ]
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

  // دالة لاختصار الأرقام الكبيرة (مثل 1.5M بدلاً من 1500000)
  String _formatCompact(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return number.toString();
  }
}