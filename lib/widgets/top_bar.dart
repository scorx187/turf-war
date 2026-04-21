// المسار: lib/widgets/top_bar.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/audio_provider.dart';
import '../views/store_view.dart';
import '../controllers/player_stats_cubit.dart';
import '../controllers/player_stats_state.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  Uint8List? _getDecodedImage(String? profilePicUrl) {
    if (profilePicUrl == null || profilePicUrl.isEmpty) return null;
    try {
      return base64Decode(profilePicUrl);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerStatsCubit, PlayerStatsState>(
      builder: (context, state) {
        double safeXpPercent = (state.maxXp > 0) ? (state.currentXp / state.maxXp).clamp(0.0, 1.0) : 0.0;

        double hpProgress = (state.maxHealth > 0 && !state.health.isNaN) ? (state.health / state.maxHealth).clamp(0.0, 1.0) : 0.0;
        double enProgress = (state.maxEnergy > 0 && !state.energy.isNaN) ? (state.energy / state.maxEnergy).clamp(0.0, 1.0) : 0.0;
        double crProgress = (state.maxCourage > 0 && !state.courage.isNaN) ? (state.courage / state.maxCourage).clamp(0.0, 1.0) : 0.0;
        double prProgress = (state.maxPrestige > 0 && !state.prestige.isNaN) ? (state.prestige / state.maxPrestige).clamp(0.0, 1.0) : 0.0;

        int hpSeconds = state.maxHealth > 0 && state.health < state.maxHealth ? ((state.maxHealth - state.health) / state.maxHealth * 1800).toInt() : 0;
        int enSeconds = state.energy < state.maxEnergy ? (state.maxEnergy - state.energy) * 8 : 0;
        int crSeconds = state.courage < state.maxCourage ? (state.maxCourage - state.courage) * 4 : 0;
        int prSeconds = state.prestige < state.maxPrestige ? (state.maxPrestige - state.prestige) * 6 : 0;

        String displayName = state.playerName.length > 13 ? '${state.playerName.substring(0, 13)}..' : state.playerName;
        final imageBytes = _getDecodedImage(state.profilePicUrl);

        double topPadding = MediaQuery.of(context).padding.top;
        double safeTop = topPadding > 10 ? topPadding - 5 : 2;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(top: safeTop, bottom: 4, left: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              image: const DecorationImage(
                image: AssetImage('assets/images/ui/header_wood_bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF856024), width: 2.0),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.9), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2C275), width: 2.0),
                        gradient: const RadialGradient(
                          colors: [Color(0xFF856024), Colors.black],
                          center: Alignment.topLeft,
                          radius: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
                        ],
                      ),
                        child: ClipOval(
                          child: state.profilePicUrl != null && state.profilePicUrl!.startsWith('http')
                              ? Image.network(
                            state.profilePicUrl!,
                            key: ValueKey(state.profilePicUrl),
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white70, size: 24),
                          )
                              : (_getDecodedImage(state.profilePicUrl) != null
                              ? Image.memory(
                            _getDecodedImage(state.profilePicUrl)!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white70, size: 24),
                          )
                              : const Icon(Icons.person, color: Colors.white70, size: 24)),
                        ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontFamily: 'Changa',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                                      ),
                                    ),
                                  ),
                                ),
                                if (state.isVIP) ...[
                                  const SizedBox(width: 3),
                                  Image.asset(
                                    'assets/images/icons/vip.png',
                                    height: 14,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars, color: Colors.amber, size: 14),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          _buildTopUpResource(
                              context: context,
                              iconPath: 'assets/images/icons/cash.png',
                              value: _formatWithCommas(state.cash),
                              bgImagePath: 'assets/images/ui/cash_bg.png',
                              plusImagePath: 'assets/images/icons/plus.png',
                              onTap: () {
                                Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreView(initialTab: 0)));
                              }
                          ),
                          const SizedBox(width: 5),

                          _buildTopUpResource(
                              context: context,
                              iconPath: 'assets/images/icons/gold.png',
                              value: _formatWithCommas(state.gold),
                              bgImagePath: 'assets/images/ui/gold_bg.png',
                              plusImagePath: 'assets/images/icons/plus.png',
                              onTap: () {
                                Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreView(initialTab: 1)));
                              }
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildResourceChip('الصحة', 'assets/images/icons/health.png', state.health, state.maxHealth, progress: hpProgress, barColor: Colors.redAccent, totalSeconds: hpSeconds)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildResourceChip('الطاقة', 'assets/images/icons/energy.png', state.energy, state.maxEnergy, progress: enProgress, barColor: Colors.lightBlueAccent, totalSeconds: enSeconds)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildResourceChip('الشجاعة', 'assets/images/icons/courage.png', state.courage, state.maxCourage, progress: crProgress, barColor: Colors.greenAccent, totalSeconds: crSeconds)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildResourceChip('الشهامة', 'assets/images/icons/prestige.png', state.prestige, state.maxPrestige, progress: prProgress, barColor: Colors.deepOrangeAccent, totalSeconds: prSeconds)),
                  ],
                ),
                const SizedBox(height: 2),

                Row(
                  children: [
                    Image.asset(
                      'assets/images/icons/lv.png',
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.amber, size: 18),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '${state.level}',
                        style: const TextStyle(
                          fontFamily: 'Changa',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE2C275),
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF856024), width: 1.0),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: safeXpPercent,
                                heightFactor: 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 6)],
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0),
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_formatCompact(state.currentXp), style: const TextStyle(fontFamily: 'Changa', fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)), Shadow(color: Colors.black, blurRadius: 2, offset: Offset(-1, -1))])),
                                      const Text(' / ', style: TextStyle(fontFamily: 'Changa', fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)), Shadow(color: Colors.black, blurRadius: 2, offset: Offset(-1, -1))])),
                                      Text(_formatCompact(state.maxXp), style: const TextStyle(fontFamily: 'Changa', fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)), Shadow(color: Colors.black, blurRadius: 2, offset: Offset(-1, -1))])),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopUpResource({required BuildContext context, required String iconPath, required String value, required String bgImagePath, required String plusImagePath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 24,
            padding: const EdgeInsets.only(right: 4, left: 8, top: 2, bottom: 2),
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(bgImagePath), fit: BoxFit.fill),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 3, offset: const Offset(0, 1))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(iconPath, width: 14, height: 14, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, color: Colors.red, size: 14)),
                const SizedBox(width: 2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                          value,
                          style: const TextStyle(fontFamily: 'Changa', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 2)])
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: -4, top: -4,
            child: Image.asset(plusImagePath, width: 12, height: 12, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.add, size: 8, color: Colors.white))),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChip(String title, String imagePath, int currentVal, int maxVal, {double? progress, Color? barColor, int totalSeconds = 0}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(imagePath, width: 18, height: 18, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, color: Colors.red, size: 18)),
                  const SizedBox(width: 3),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(title, style: const TextStyle(fontFamily: 'Changa', fontSize: 9, color: Colors.white70)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatCompact(currentVal), style: const TextStyle(fontFamily: 'Changa', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                        const Text('/', style: TextStyle(fontFamily: 'Changa', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                        Text(_formatCompact(maxVal), style: const TextStyle(fontFamily: 'Changa', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                      ],
                    ),
                  ),
                ),
              ),
              if (progress != null && barColor != null) ...[
                const SizedBox(height: 3),
                Container(
                  width: double.infinity,
                  height: 2.5,
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    heightFactor: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [BoxShadow(color: barColor.withOpacity(0.8), blurRadius: 3)],
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
        SizedBox(
          height: 16,
          child: StatTimerText(initialSeconds: totalSeconds),
        ),
      ],
    );
  }

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  String _formatCompact(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1).replaceAll('.0', '')}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    }
    return number.toString();
  }
}

// 🟢 الذكاء الجديد كلياً للمؤقت!
class StatTimerText extends StatefulWidget {
  final int initialSeconds;
  const StatTimerText({super.key, required this.initialSeconds});

  @override
  State<StatTimerText> createState() => _StatTimerTextState();
}

class _StatTimerTextState extends State<StatTimerText> {
  late int seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    seconds = widget.initialSeconds;
    if (seconds > 0) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(StatTimerText oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool shouldUpdate = false;
    int diff = oldWidget.initialSeconds - widget.initialSeconds;

    // 1. إذا زاد الوقت فجأة (بمعنى أن اللاعب استهلك طاقة/شجاعة) -> نحدث فوراً
    if (diff < 0) {
      shouldUpdate = true;
    }
    // 2. إذا نقص الوقت بشكل هائل جداً (بمعنى اللاعب اشترى تعبئة) -> نحدث فوراً
    else if (diff > 20) {
      shouldUpdate = true;
    }
    // 3. التحديث الطبيعي القادم من الكيوبت (كل 8 ثواني مثلاً)
    else if (diff > 0) {
      // نترك العداد ينزل بثبات، ولا نتدخل فيه إلا إذا انحرف العداد المحلي عن السيرفر بأكثر من 4 ثواني
      if ((seconds - widget.initialSeconds).abs() > 4) {
        shouldUpdate = true;
      }
    }
    // 4. لا يوجد تغيير في الرقم القادم، لكن العداد المحلي ابتعد كثيراً لسبب ما (التطبيق كان مغلق)
    else {
      if ((widget.initialSeconds - seconds).abs() > 20) {
        shouldUpdate = true;
      }
    }

    if (shouldUpdate) {
      seconds = widget.initialSeconds;

      // 🟢 إذا كان المؤقت متوقفاً والوقت أصبح أكبر من صفر، نشغله من جديد تلقائياً!
      if (seconds > 0 && (_timer == null || !_timer!.isActive)) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && seconds > 0) {
        setState(() {
          seconds--;
        });
      } else if (seconds <= 0) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (seconds <= 0) return const Text('');

    int m = seconds ~/ 60;
    int s = seconds % 60;
    String timeText = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Text(
          timeText,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Changa',
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1))
              ]
          )
      ),
    );
  }
}