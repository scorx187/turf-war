// المسار: lib/views/gym_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/quick_recovery_dialog.dart';
import '../controllers/gym_cubit.dart';

class GymView extends StatelessWidget {
  final VoidCallback onBack;
  const GymView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GymCubit(),
      child: _GymViewContent(onBack: onBack),
    );
  }
}

class _GymViewContent extends StatefulWidget {
  final VoidCallback onBack;
  const _GymViewContent({required this.onBack});

  @override
  State<_GymViewContent> createState() => _GymViewContentState();
}

class _GymViewContentState extends State<_GymViewContent> {
  int strE = 0;
  int defE = 0;
  int skillE = 0;
  int spdE = 0;
  Timer? _timer;

  bool _showFloatingEffect = false;
  String _floatingMessage = '';
  double _floatBottom = 80.0;
  double _floatOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !context.read<GymCubit>().state.isLoading) setState(() {});
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

  String _formatTimeLeft(DateTime? endTime, DateTime secureNow) {
    if (endTime == null) return '';
    Duration diff = endTime.difference(secureNow);
    if (diff.isNegative) return '00:00:00';

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(diff.inHours);
    String minutes = twoDigits(diff.inMinutes.remainder(60));
    String seconds = twoDigits(diff.inSeconds.remainder(60));

    return '$hours:$minutes:$seconds';
  }

  void _triggerFloatingAnimation(double gained) {
    setState(() {
      _showFloatingEffect = true;
      _floatingMessage = '+${gained.toStringAsFixed(1)} إحصائيات';
      _floatBottom = 80.0;
      _floatOpacity = 1.0;
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _floatBottom = MediaQuery.of(context).size.height * 0.5);
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _floatOpacity = 0.0);
    });

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _showFloatingEffect = false);
    });
  }

  // 🟢 الـ Pop-Up لما اللاعب يضرب الحد الأقصى - يقرأ المحطة القادمة من الـ provider مباشرة
  void _showMaxStatsDialog(BuildContext context, AudioProvider audio, PlayerProvider player) {
    int nextLevel = player.nextStatMilestone;
    double nextMaxStats = player.nextMaxGymStats;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent, width: 2),
                boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block, color: Colors.redAccent, size: 60),
                    const SizedBox(height: 10),
                    const Text('تم قفل التدريب!', style: TextStyle(fontFamily: 'Changa', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text(
                      'جسمك ما عاد يتحمل تدريب أكثر، وصلت للحد الأقصى للإحصائيات في مستواك الحالي (${player.crimeLevel})!\n\n'
                          'ارفع مستواك الإجرامي لـ ($nextLevel) عشان يفتح لك السقف وتقدر توصل لـ ${nextMaxStats.toStringAsFixed(0)} إحصائية.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Changa', fontSize: 15, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () {
                            audio.playEffect('click.mp3');
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check, color: Colors.black),
                          label: const Text('فهمت، بروح أرفع مستواي', style: TextStyle(fontFamily: 'Changa', color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: child);
      },
    );
  }

  void _showNumberInputDialog(BuildContext context, String statName, int currentValue, int maxAllowed, Function(int) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue > 0 ? currentValue.toString() : '');
    showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 2)),
              title: Text('تحديد طاقة $statName', style: const TextStyle(color: Colors.amber, fontFamily: 'Changa')),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'Changa'),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.black54,
                  border: OutlineInputBorder(),
                  hintText: 'أدخل الرقم هنا',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
              actions: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    onPressed: () {
                      int val = int.tryParse(controller.text) ?? 0;
                      if (val < 0) val = 0;
                      if (val > maxAllowed) val = maxAllowed;
                      onSave(val);
                      Navigator.pop(context);
                    },
                    child: const Text('تأكيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa'))
                ),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa'))
                ),
              ]
          ),
        )
    );
  }

  void _confirmAction(BuildContext context, String title, Widget content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 2)),
          title: Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          content: content,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('تأكيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ],
        ),
      ),
    );
  }

  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
          title: const Text('شرح صالة التدريب 🏋️‍♂️', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('💪 الإحصائيات:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('اسحب الشريط لتخصيص الطاقة، أو اضغط زر (تدريب MAX) لضخ طاقتك بالكامل في إحصائية واحدة فوراً.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
                SizedBox(height: 10),
                Text('🥊 المدربون الفاسدون:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('استأجر مدرباً لـ 30 دقيقة. يتطلب 6 ساعات فترة راحة بعد ذلك.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
                SizedBox(height: 10),
                Text('💉 المنشطات:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('تضاعف تدريباتك (100%) لـ 20 دقيقة، وتحتاج فترة راحة 6 ساعات.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً فهمت', style: TextStyle(color: Colors.amber)))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final cubit = context.read<GymCubit>();

    return BlocConsumer<GymCubit, GymState>(
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          if (state.errorMessage.contains('الحد_الأقصى')) {
            _showMaxStatsDialog(context, Provider.of<AudioProvider>(context, listen: false), player);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage, style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
          }
        }
        if (state.successMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
        }

        if (state.gainedStats != null) {
          _triggerFloatingAnimation(state.gainedStats!);
          setState(() {
            strE = 0; defE = 0; skillE = 0; spdE = 0;
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
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
                        const SizedBox(height: 10),
                        const Center(child: Text('صالة التدريب القتالي 🏋️‍♂️', style: TextStyle(color: Colors.amber, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Changa', shadows: [Shadow(color: Colors.black, blurRadius: 10)])),),
                        const SizedBox(height: 10),

                        Expanded(
                          child: DefaultTabController(
                            length: 3,
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                                  child: const TabBar(
                                    indicator: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.all(Radius.circular(10))),
                                    labelColor: Colors.black,
                                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                                    unselectedLabelColor: Colors.white54,
                                    tabs: [Tab(text: "صالة الحديد"), Tab(text: "المدربون"), Tab(text: "المنشطات")],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      _buildGymTab(player, audio, cubit),
                                      _buildCoachesTab(player, audio, cubit),
                                      _buildSteroidsTab(player, audio, cubit),
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

              if (state.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 20),
                        Text('جاري التنفيذ والحفظ...', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ),

              if (_showFloatingEffect)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  bottom: _floatBottom,
                  left: 0, right: 0,
                  child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _floatOpacity,
                      child: Center(
                          child: Text(
                              _floatingMessage,
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 35,
                                  fontFamily: 'Changa',
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 15, offset: Offset(0, 3)), Shadow(color: Colors.black, blurRadius: 2, offset: Offset(2, 2))]
                              )
                          )
                      )
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                image: const DecorationImage(image: AssetImage('assets/images/ui/bottom_navbar_bg.png'), fit: BoxFit.cover),
                border: const Border(top: BorderSide(color: Color(0xFF856024), width: 2)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10, offset: const Offset(0, -5))],
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
      },
    );
  }

  Widget _buildGymTab(PlayerProvider player, AudioProvider audio, GymCubit cubit) {
    int totalAllocated = strE + defE + skillE + spdE;
    double maxStats = player.maxGymStats;
    double currentStats = player.currentBaseStats;
    double progress = (currentStats / maxStats).clamp(0.0, 1.0);

    // 🟢 نقرأ المحطة القادمة من الـ provider مباشرة (مصدر واحد للحقيقة)
    int nextLevel = player.nextStatMilestone;
    double nextMaxStats = player.nextMaxGymStats;

    bool hasSteroid = player.activeSteroidEndTime != null;
    String coachName = player.activeCoach == 'russian' ? 'الروسي (+قوة)' : (player.activeCoach == 'tactical' ? 'التكتيكي (+دفاع)' : (player.activeCoach == 'ninja' ? 'النينجا (+سرعة ومهارة)' : 'لا يوجد'));

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('طاقتك الحالية:', style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Changa')),
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: Colors.yellow, size: 28),
                              Text('${player.energy} / ${player.maxEnergy}', style: const TextStyle(color: Colors.yellow, fontSize: 26, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(children: [Icon(Icons.home, color: Colors.greenAccent, size: 16), SizedBox(width: 5), Text('مكافأة السعادة:', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                          Text('+${player.happiness}', style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(children: [Icon(Icons.person, color: Colors.orangeAccent, size: 16), SizedBox(width: 5), Text('تأثير المدرب:', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                          Text(coachName, style: TextStyle(color: player.activeCoach != null ? Colors.orangeAccent : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (hasSteroid) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(children: [Icon(Icons.warning, color: Colors.redAccent, size: 16), SizedBox(width: 5), Text('تأثير المنشطات (100%):', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                            Text(_formatTimeLeft(player.activeSteroidEndTime, player.secureNow), style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('مجموع الإحصائيات (الحالي / الأقصى)', style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Changa')),
                              Text('${currentStats.toStringAsFixed(1)} / ${maxStats.toStringAsFixed(1)}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black45, valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber), minHeight: 10)),

                          if (progress >= 1.0) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'ارفع مستواك لـ $nextLevel لفتح الحد الأقصى (${nextMaxStats.toStringAsFixed(0)})',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildStatCard(context, player, audio, cubit, 'القوة', Icons.fitness_center, Colors.redAccent, player.baseStrength, strE, totalAllocated, (v) => setState(() => strE = v), () {
                  int available = player.energy;
                  if (available > 0) cubit.trainStats(player, available, 0, 0, 0);
                }),
                _buildStatCard(context, player, audio, cubit, 'الدفاع', Icons.shield, Colors.blueAccent, player.baseDefense, defE, totalAllocated, (v) => setState(() => defE = v), () {
                  int available = player.energy;
                  if (available > 0) cubit.trainStats(player, 0, available, 0, 0);
                }),
                _buildStatCard(context, player, audio, cubit, 'السرعة', Icons.speed, Colors.orangeAccent, player.baseSpeed, spdE, totalAllocated, (v) => setState(() => spdE = v), () {
                  int available = player.energy;
                  if (available > 0) cubit.trainStats(player, 0, 0, 0, available);
                }),
                _buildStatCard(context, player, audio, cubit, 'المهارة', Icons.psychology, Colors.greenAccent, player.baseSkill, skillE, totalAllocated, (v) => setState(() => skillE = v), () {
                  int available = player.energy;
                  if (available > 0) cubit.trainStats(player, 0, 0, available, 0);
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1D),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: totalAllocated > 0 ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)] : [],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: totalAllocated > 0 ? Colors.amber : Colors.grey.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: totalAllocated > 0 ? () {
                audio.playEffect('click.mp3');
                if (totalAllocated > player.energy) {
                  QuickRecoveryDialog.show(context, 'energy', totalAllocated - player.energy);
                } else {
                  _confirmAction(context, 'تأكيد التدريب', Text('هل أنت متأكد أنك تريد استهلاك $totalAllocated طاقة للتدريب المخصص؟', style: const TextStyle(color: Colors.white, fontFamily: 'Changa')), () {
                    cubit.trainStats(player, strE, defE, skillE, spdE);
                  });
                }
              } : null,
              child: Text(
                  totalAllocated > 0 ? 'بدء التدريب المخصص ($totalAllocated طاقة)' : 'حدد الطاقة للبدء',
                  style: TextStyle(color: totalAllocated > 0 ? Colors.black : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, PlayerProvider player, AudioProvider audio, GymCubit cubit, String name, IconData icon, Color color, double currentStat, int allocated, int totalAllocated, Function(int) onChanged, VoidCallback onQuickTrain) {
    int otherAllocated = totalAllocated - allocated;
    int maxAllowed = player.energy - otherAllocated;
    if (maxAllowed < 0) maxAllowed = 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), Colors.black45], begin: Alignment.centerRight, end: Alignment.centerLeft),
        borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Changa')),
                    Text('الحالي: ${currentStat.toStringAsFixed(1)}', style: TextStyle(color: color, fontSize: 12)),
                  ],
                ),
              ),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.2),
                    foregroundColor: color,
                    elevation: 0,
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 32)
                ),
                onPressed: player.energy > 0 ? () {
                  audio.playEffect('click.mp3');
                  onQuickTrain();
                } : () {
                  audio.playEffect('click.mp3');
                  QuickRecoveryDialog.show(context, 'energy', 10);
                },
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text('تدريب MAX', style: TextStyle(fontFamily: 'Changa', fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(onPressed: allocated > 0 ? () => onChanged(allocated - 1) : null, icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 5),

              GestureDetector(
                onTap: () => _showNumberInputDialog(context, name, allocated, maxAllowed, onChanged),
                child: Container(
                  width: 45, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withValues(alpha: 0.4))),
                  child: Text(allocated.toString(), style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(width: 5),
              IconButton(onPressed: allocated < maxAllowed ? () => onChanged(allocated + 1) : null, icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 8),

              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), overlayShape: const RoundSliderOverlayShape(overlayRadius: 16), activeTrackColor: color, inactiveTrackColor: Colors.white12, thumbColor: Colors.white),
                  child: Slider(
                    value: allocated.toDouble(), min: 0, max: maxAllowed > 0 ? maxAllowed.toDouble() : 1.0,
                    onChanged: maxAllowed > 0 ? (val) => onChanged(val.toInt()) : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🟢 2. المدربون
  Widget _buildCoachesTab(PlayerProvider player, AudioProvider audio, GymCubit cubit) {
    bool hasCoach = player.activeCoach != null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (hasCoach)
          Container(
            padding: const EdgeInsets.all(15), margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade900.withValues(alpha: 0.7), Colors.black87]), border: Border.all(color: Colors.greenAccent), borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [Icon(Icons.timer, color: Colors.greenAccent, size: 20), SizedBox(width: 8), Text('ينتهي العقد بعد:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa'))]),
                Text(_formatTimeLeft(player.coachEndTime, player.secureNow), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
              ],
            ),
          ),
        _buildCoachCard(context, player, audio, cubit, 'russian', 'المدرب الروسي 🐻', 'يزيد من مكاسب (القوة) بنسبة 50%.', 250000, Icons.fitness_center, Colors.redAccent),
        _buildCoachCard(context, player, audio, cubit, 'tactical', 'المدرب التكتيكي 🛡️', 'يزيد من مكاسب (الدفاع) 50%، ويضاعف فرصة زيادة صحتك القصوى.', 300000, Icons.shield, Colors.blueAccent),
        _buildCoachCard(context, player, audio, cubit, 'ninja', 'مدرب النينجا 🥷', 'يزيد من مكاسب (السرعة والمهارة) بنسبة 50%.', 200000, Icons.speed, Colors.purpleAccent),
      ],
    );
  }

  Widget _buildCoachCard(BuildContext context, PlayerProvider player, AudioProvider audio, GymCubit cubit, String id, String name, String desc, int price, IconData icon, Color color) {
    bool isActive = player.activeCoach == id;
    bool hasAnyCoach = player.activeCoach != null;

    int coachCooldown = player.inventory['coach_cooldown'] ?? 0;
    bool isCooldown = !hasAnyCoach && player.secureNow.millisecondsSinceEpoch < coachCooldown;
    DateTime cooldownEnd = DateTime.fromMillisecondsSinceEpoch(coachCooldown);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black54, borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isActive ? Colors.greenAccent : (isCooldown ? Colors.redAccent : color.withValues(alpha: 0.5)), width: isActive || isCooldown ? 2 : 1),
        boxShadow: isActive ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.2), blurRadius: 10)] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Changa')),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Changa')),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.attach_money, color: Colors.green, size: 14), Text(_formatNumber(price), textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isActive)
              const Column(children: [Icon(Icons.check_circle, color: Colors.greenAccent, size: 28), SizedBox(height: 4), Text('نشط', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))])
            else if (isCooldown)
              Column(children: [const Icon(Icons.timer_off, color: Colors.redAccent, size: 28), const SizedBox(height: 4), Text(_formatTimeLeft(cooldownEnd, player.secureNow), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2))])
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: player.cash >= price ? Colors.amber : Colors.grey.shade700, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: player.cash >= price ? () {
                  audio.playEffect('click.mp3');
                  _confirmAction(context, 'استئجار $name', Wrap(children: [
                    const Text('هل تريد استئجاره لمدة 30 دقيقة بمبلغ ', style: TextStyle(color: Colors.white, fontFamily: 'Changa')),
                    Text('\$${_formatNumber(price)}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.amber, fontFamily: 'Changa')),
                    const Text('؟\n\n', style: TextStyle(color: Colors.white, fontFamily: 'Changa')),
                    const Text('⚠️ احذر: لن تتمكن من استئجار أي مدرب آخر لمدة 6 ساعات بعد الانتهاء!', style: TextStyle(color: Colors.redAccent, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                  ]), () {
                    cubit.hireCoach(player, id, price, name);
                  });
                } : null,
                child: const Text('استئجار', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              ),
          ],
        ),
      ),
    );
  }

  // 🟢 3. المنشطات
  Widget _buildSteroidsTab(PlayerProvider player, AudioProvider audio, GymCubit cubit) {
    bool hasSteroid = player.activeSteroidEndTime != null;
    int steroidCooldown = player.inventory['steroid_cooldown'] ?? 0;
    bool isCooldown = !hasSteroid && player.secureNow.millisecondsSinceEpoch < steroidCooldown;
    DateTime cooldownEnd = DateTime.fromMillisecondsSinceEpoch(steroidCooldown);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 2)),
            child: const Icon(Icons.science, color: Colors.redAccent, size: 60),
          ),
          const SizedBox(height: 15),
          const Text('سوق المنشطات السري', style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          const SizedBox(height: 30),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: hasSteroid ? [Colors.green.shade900, Colors.black87] : [Colors.red.shade900.withValues(alpha: 0.5), Colors.black87], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: hasSteroid ? Colors.greenAccent : (isCooldown ? Colors.grey : Colors.redAccent), width: 2),
              boxShadow: [BoxShadow(color: (hasSteroid ? Colors.green : Colors.redAccent).withValues(alpha: 0.3), blurRadius: 15)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('حقنة الأدرينالين الخالصة 💉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Changa')),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                    child: const Column(
                      children: [
                        Row(children: [Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 16), SizedBox(width: 8), Expanded(child: Text('تضاعف نتائج التدريب (100%) لمدة 20 دقيقة.', style: TextStyle(color: Colors.white70, fontSize: 12)))]),
                        SizedBox(height: 8),
                        Row(children: [Icon(Icons.hourglass_empty, color: Colors.orangeAccent, size: 16), SizedBox(width: 8), Expanded(child: Text('يجب أن يرتاح جسمك لمدة 6 ساعات بعد الانتهاء.', style: TextStyle(color: Colors.white70, fontSize: 12)))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('السعر: \$15,000 كاش', textDirection: TextDirection.ltr, style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  if (hasSteroid)
                    Column(
                      children: [
                        const Text('مفعول المنشط نشط الآن! ⚡', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                        const SizedBox(height: 5),
                        Text(_formatTimeLeft(player.activeSteroidEndTime, player.secureNow), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                      ],
                    )
                  else if (isCooldown)
                    Column(
                      children: [
                        const Text('الجسم في فترة راحة ⏳', style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                        const SizedBox(height: 5),
                        Text(_formatTimeLeft(cooldownEnd, player.secureNow), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: player.cash >= 15000 ? Colors.redAccent : Colors.grey.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: player.cash >= 15000 ? () {
                          audio.playEffect('click.mp3');
                          _confirmAction(context, 'شراء وحقن المنشط ⚠️', const Text('هل أنت متأكد؟ سيتضاعف تدريبك لمدة 20 دقيقة، ولن تستطيع استخدامه مجدداً لمدة 6 ساعات.', style: TextStyle(color: Colors.white, fontFamily: 'Changa')), () {
                            cubit.buySteroids(player, 15000);
                          });
                        } : null,
                        child: const Text('شراء وحقن الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Changa')),
                      ),
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