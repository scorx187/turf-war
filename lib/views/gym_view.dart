// المسار: lib/views/gym_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:async';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class GymView extends StatefulWidget {
  final VoidCallback onBack;
  const GymView({super.key, required this.onBack});

  @override
  State<GymView> createState() => _GymViewState();
}

class _GymViewState extends State<GymView> {
  int strE = 0;
  int defE = 0;
  int skillE = 0;
  int spdE = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // تحديث الشاشة عشان العدادات التنازلية
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  String _formatTimeLeft(DateTime? endTime) {
    if (endTime == null) return '';
    Duration diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return 'منتهي';
    return '${diff.inHours}س ${diff.inMinutes.remainder(60)}د ${diff.inSeconds.remainder(60)}ث';
  }

  void _confirmAction(BuildContext context, String title, Widget content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
        title: Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
        content: content,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () { Navigator.pop(context); onConfirm(); },
            child: const Text('تأكيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
        title: const Text('شرح صالة التدريب 🏋️‍♂️', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💪 الإحصائيات:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('استخدم طاقتك لرفع إحصائياتك. السعادة من عقارك تضاعف النتائج.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              SizedBox(height: 10),
              Text('🥊 المدربون الفاسدون:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('استأجر مدرباً ليزيد من مكاسبك في مهارة معينة لـ 24 ساعة.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              SizedBox(height: 10),
              Text('💉 المنشطات:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('تضاعف كل تدريباتك (200%) لمدة ساعة! لكن احذر، عند انتهاء المفعول ستخسر نصف صحتك.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً فهمت', style: TextStyle(color: Colors.amber)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Scaffold(
      // 🟢 إضافة الخلفية الفخمة هنا بدل اللون الأسود 🟢
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ui/crime_bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const SizedBox(height: 5),
                const Center(child: Text('صالة التدريب القتالي 🏋️‍♂️', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold))),
                const SizedBox(height: 5),

                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(
                          indicatorColor: Colors.amber,
                          labelColor: Colors.amber,
                          unselectedLabelColor: Colors.white54,
                          tabs: [
                            Tab(text: "صالة الحديد"),
                            Tab(text: "المدربون"),
                            Tab(text: "المنشطات"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildGymTab(player, audio),
                              _buildCoachesTab(player, audio),
                              _buildSteroidsTab(player, audio),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            image: const DecorationImage(image: AssetImage('assets/images/ui/bottom_navbar_bg.png'), fit: BoxFit.cover),
            border: const Border(top: BorderSide(color: Color(0xFF856024), width: 2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 20, left: 25, right: 25),
          child: SafeArea(
            bottom: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () { audio.playEffect('click.mp3'); widget.onBack(); },
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_forward_ios, color: Color(0xFFE2C275), size: 24), SizedBox(height: 4), Text('رجوع', style: TextStyle(color: Color(0xFFE2C275), fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                ),
                GestureDetector(
                  onTap: () { audio.playEffect('click.mp3'); _showExplanationDialog(context); },
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book, color: Colors.white70, size: 24), SizedBox(height: 4), Text('شرح', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 1. صالة الحديد الأساسية 🟢
  Widget _buildGymTab(PlayerProvider player, AudioProvider audio) {
    int totalAllocated = strE + defE + skillE + spdE;
    int energyLeft = player.energy - totalAllocated;
    double maxStats = player.maxGymStats;
    double currentStats = player.currentBaseStats;
    double progress = (currentStats / maxStats).clamp(0.0, 1.0);

    bool hasSteroid = player.activeSteroidEndTime != null;
    String coachName = player.activeCoach == 'russian' ? 'الروسي (+قوة)' : (player.activeCoach == 'tactical' ? 'التكتيكي (+دفاع)' : (player.activeCoach == 'ninja' ? 'النينجا (+سرعة ومهارة)' : 'لا يوجد'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // لوحة المعلومات
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.5))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الطاقة المتاحة:', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    Text('⚡ $energyLeft', style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('مكافأة السعادة (عقارك):', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('+${player.happiness}', style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تأثير المدرب:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(coachName, style: TextStyle(color: player.activeCoach != null ? Colors.orangeAccent : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (hasSteroid) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المنشطات (مضاعفة 200%):', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(_formatTimeLeft(player.activeSteroidEndTime), style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('اكتمال الجسم للمستوى الحالي:', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(value: progress, backgroundColor: Colors.black45, valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber), minHeight: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // العدادات
          _buildStatRow('القوة', Icons.fitness_center, Colors.redAccent, player.strength, strE, energyLeft, (v) => setState(() => strE = v)),
          _buildStatRow('الدفاع', Icons.shield, Colors.blueAccent, player.defense, defE, energyLeft, (v) => setState(() => defE = v)),
          _buildStatRow('السرعة', Icons.speed, Colors.orangeAccent, player.speed, spdE, energyLeft, (v) => setState(() => spdE = v)),
          _buildStatRow('المهارة', Icons.psychology, Colors.greenAccent, player.skill, skillE, energyLeft, (v) => setState(() => skillE = v)),

          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: totalAllocated > 0 ? Colors.amber : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: totalAllocated > 0 ? () {
              audio.playEffect('click.mp3');
              player.trainMultipleStats(strE, defE, skillE, spdE);
              setState(() { strE = 0; defE = 0; skillE = 0; spdE = 0; });
            } : null,
            child: const Text('بدء التدريب الشاق', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String name, IconData icon, Color color, double currentStat, int allocated, int energyLeft, Function(int) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(currentStat.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(onPressed: allocated > 0 ? () => onChanged(allocated - 1) : null, icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              Container(width: 40, alignment: Alignment.center, child: Text(allocated.toString(), style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(onPressed: energyLeft > 0 ? () => onChanged(allocated + 1) : null, icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: energyLeft > 0 ? () => onChanged(allocated + energyLeft) : null,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: energyLeft > 0 ? Colors.amber.withOpacity(0.2) : Colors.white10, borderRadius: BorderRadius.circular(5), border: Border.all(color: energyLeft > 0 ? Colors.amber : Colors.white24)), child: Text('MAX', style: TextStyle(color: energyLeft > 0 ? Colors.amber : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🟢 2. المدربون 🟢
  Widget _buildCoachesTab(PlayerProvider player, AudioProvider audio) {
    bool hasCoach = player.activeCoach != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasCoach)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ينتهي عقد المدرب بعد:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(_formatTimeLeft(player.coachEndTime), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        _buildCoachCard(context, player, audio, 'russian', 'المدرب الروسي 🐻', 'يزيد من مكاسب (القوة) بنسبة 50%.', 250000, Icons.fitness_center, Colors.redAccent),
        _buildCoachCard(context, player, audio, 'tactical', 'المدرب التكتيكي 🛡️', 'يزيد من مكاسب (الدفاع) 50%، ويضاعف فرصة زيادة صحتك القصوى.', 300000, Icons.shield, Colors.blueAccent),
        _buildCoachCard(context, player, audio, 'ninja', 'مدرب النينجا 🥷', 'يزيد من مكاسب (السرعة والمهارة) بنسبة 50%.', 200000, Icons.speed, Colors.purpleAccent),
      ],
    );
  }

  Widget _buildCoachCard(BuildContext context, PlayerProvider player, AudioProvider audio, String id, String name, String desc, int price, IconData icon, Color color) {
    bool isActive = player.activeCoach == id;
    bool hasAnyCoach = player.activeCoach != null;

    return Card(
      color: Colors.black45,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isActive ? Colors.green : color.withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(children: [const Text('السعر لـ 24 ساعة: ', style: TextStyle(color: Colors.white54, fontSize: 10)), Text('\$${_formatNumber(price)}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isActive ? const Text('نشط حالياً ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)) : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: (!hasAnyCoach && player.cash >= price) ? Colors.amber : Colors.grey, padding: const EdgeInsets.symmetric(horizontal: 12)),
              onPressed: (!hasAnyCoach && player.cash >= price) ? () {
                audio.playEffect('click.mp3');
                _confirmAction(context, 'استئجار $name', Wrap(children: [Text('هل تريد استئجاره لمدة 24 ساعة بمبلغ ', style: const TextStyle(color: Colors.white, fontFamily: 'Changa')), Text('\$${_formatNumber(price)}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.amber, fontFamily: 'Changa'))]), () {
                  player.hireCoach(id, price);
                });
              } : null,
              child: const Text('استئجار', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 3. المنشطات 🟢
  Widget _buildSteroidsTab(PlayerProvider player, AudioProvider audio) {
    bool hasSteroid = player.activeSteroidEndTime != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 60),
          const SizedBox(height: 10),
          const Text('سوق المنشطات الأسود', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('احذر، هذه المواد ممنوعة وخطيرة!', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 30),

          Card(
            color: Colors.black45,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: hasSteroid ? Colors.green : Colors.redAccent.withOpacity(0.5))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('حقنة الأدرينالين الخالصة 💉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  const Text('الفوائد: تضاعف نتائج تدريبك (200%) لمدة 1 ساعة كاملة.\nالمخاطر: عند انتهاء المفعول، ستفقد 50% من صحتك الحالية بسبب الإرهاق الشديد.', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  const Text('السعر: \$15,000 كاش', textDirection: TextDirection.ltr, style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  if (hasSteroid)
                    Column(
                      children: [
                        const Text('مفعول المنشط نشط الآن! ينتهي بعد:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text(_formatTimeLeft(player.activeSteroidEndTime), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: player.cash >= 15000 ? Colors.redAccent : Colors.grey, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                      onPressed: player.cash >= 15000 ? () {
                        audio.playEffect('click.mp3');
                        _confirmAction(context, 'شراء وحقن المنشط ⚠️', const Text('هل أنت متأكد؟ سيتضاعف تدريبك لساعة، ولكن ستخسر نصف صحتك لاحقاً!', style: TextStyle(color: Colors.white, fontFamily: 'Changa')), () {
                          player.buyAndUseSteroids(15000);
                        });
                      } : null,
                      child: const Text('شراء وحقن الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}