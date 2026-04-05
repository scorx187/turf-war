// المسار: lib/widgets/top_bar.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../views/store_view.dart';

class TopBar extends StatelessWidget {
  final int cash;
  final int gold;
  final int energy;
  final int maxEnergy;
  final int courage;
  final int maxCourage;
  final int health;
  final int maxHealth;
  final int prestige;
  final int maxPrestige;
  final String playerName;
  final String? profilePicUrl;
  final int level;
  final int currentXp;
  final int maxXp;
  final bool isVIP;

  const TopBar({
    super.key,
    required this.cash,
    required this.gold,
    required this.energy,
    required this.maxEnergy,
    required this.courage,
    required this.maxCourage,
    required this.health,
    required this.maxHealth,
    required this.prestige,
    required this.maxPrestige,
    required this.playerName,
    this.profilePicUrl,
    required this.level,
    required this.currentXp,
    required this.maxXp,
    required this.isVIP,
  });

  Uint8List? _getDecodedImage() {
    if (profilePicUrl == null || profilePicUrl!.isEmpty) return null;
    try {
      return base64Decode(profilePicUrl!);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    double safeXpPercent = (maxXp > 0) ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

    double hpProgress = (maxHealth > 0 && !health.isNaN) ? (health / maxHealth).clamp(0.0, 1.0) : 0.0;
    double enProgress = (maxEnergy > 0 && !energy.isNaN) ? (energy / maxEnergy).clamp(0.0, 1.0) : 0.0;
    double crProgress = (maxCourage > 0 && !courage.isNaN) ? (courage / maxCourage).clamp(0.0, 1.0) : 0.0;
    double prProgress = (maxPrestige > 0 && !prestige.isNaN) ? (prestige / maxPrestige).clamp(0.0, 1.0) : 0.0;

    int hpSeconds = maxHealth > 0 && health < maxHealth ? ((maxHealth - health) / maxHealth * 1800).toInt() : 0;
    int enSeconds = energy < maxEnergy ? (maxEnergy - energy) * 8 : 0;
    int crSeconds = courage < maxCourage ? (maxCourage - courage) * 4 : 0;
    int prSeconds = prestige < maxPrestige ? (maxPrestige - prestige) * 6 : 0;

    String displayName = playerName.length > 13 ? '${playerName.substring(0, 13)}..' : playerName;
    final imageBytes = _getDecodedImage();

    double topPadding = MediaQuery.of(context).padding.top;
    double safeTop = topPadding > 10 ? topPadding - 5 : 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        // 🟢 تقليل مسافات الحواف لتصغير المساحة الكلية
        padding: EdgeInsets.only(top: safeTop, bottom: 4, left: 8, right: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          image: const DecorationImage(
            image: AssetImage('assets/images/ui/header_wood_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
          border: const Border(
            bottom: BorderSide(color: Color(0xFF856024), width: 2.0), // تصغير سُمك الحدود
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.9), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- الصف الأول: صورة البروفايل، الاسم، الكاش، والذهب ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🟢 تصغير صورة الزعيم من 50 إلى 40
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
                    child: imageBytes != null
                        ? Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white70, size: 24),
                    )
                        : const Icon(Icons.person, color: Colors.white70, size: 24),
                  ),
                ),
                const SizedBox(width: 8), // تصغير المسافة

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
                                    fontSize: 14, // 🟢 تصغير خط الاسم
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                                  ),
                                ),
                              ),
                            ),
                            if (isVIP) ...[
                              const SizedBox(width: 3),
                              Image.asset(
                                'assets/images/icons/vip.png',
                                height: 14, // 🟢 تصغير أيقونة VIP
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars, color: Colors.amber, size: 14),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 6), // تقليل مسافة المنتصف

                      // 🟢 تصغير أزرار الكاش والذهب
                      _buildTopUpResource(
                          context: context,
                          iconPath: 'assets/images/icons/cash.png',
                          value: _formatWithCommas(cash),
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
                          value: _formatWithCommas(gold),
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
            const SizedBox(height: 6), // تصغير المسافة بين الصفوف

            // --- الصف الثاني: الموارد (تم تصغير المربعات والنصوص) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildResourceChip('الصحة', 'assets/images/icons/health.png', '${_formatCompact(health)}/${_formatCompact(maxHealth)}', progress: hpProgress, barColor: Colors.redAccent, totalSeconds: hpSeconds)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('الطاقة', 'assets/images/icons/energy.png', '${_formatCompact(energy)}/${_formatCompact(maxEnergy)}', progress: enProgress, barColor: Colors.lightBlueAccent, totalSeconds: enSeconds)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('الشجاعة', 'assets/images/icons/courage.png', '${_formatCompact(courage)}/${_formatCompact(maxCourage)}', progress: crProgress, barColor: Colors.greenAccent, totalSeconds: crSeconds)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('الشهامة', 'assets/images/icons/prestige.png', '${_formatCompact(prestige)}/${_formatCompact(maxPrestige)}', progress: prProgress, barColor: Colors.deepOrangeAccent, totalSeconds: prSeconds)),
              ],
            ),
            const SizedBox(height: 2), // تصغير المسافة

            // --- الصف الثالث: خط اللفل ---
            Row(
              children: [
                Image.asset(
                  'assets/images/icons/lv.png',
                  width: 18, // 🟢 تصغير نجمة اللفل
                  height: 18,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.amber, size: 18),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      fontFamily: 'Changa',
                      fontSize: 15, // 🟢 تصغير رقم اللفل
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE2C275),
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Container(
                    height: 14, // 🟢 تصغير ارتفاع شريط اللفل
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
                            child: Text(
                              '${_formatCompact(currentXp)} / ${_formatCompact(maxXp)}',
                              style: const TextStyle(
                                fontFamily: 'Changa',
                                fontSize: 9, // 🟢 تصغير خط الـ XP
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                                  Shadow(color: Colors.black, blurRadius: 2, offset: Offset(-1, -1)),
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
  }

  // 🟢 تم تصغير كل القيم هنا بشكل متناسق 🟢
  Widget _buildTopUpResource({required BuildContext context, required String iconPath, required String value, required String bgImagePath, required String plusImagePath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80, // تم التصغير من 95
            height: 24, // تم التصغير من 28
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

  // 🟢 تم تصغير الأيقونات والنصوص وأشرطة الموارد 🟢
  Widget _buildResourceChip(String title, String imagePath, String value, {double? progress, Color? barColor, int totalSeconds = 0}) {
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
                  child: Text(value, style: const TextStyle(fontFamily: 'Changa', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                ),
              ),
              if (progress != null && barColor != null) ...[
                const SizedBox(height: 3),
                Container(
                  width: double.infinity,
                  height: 2.5, // تصغير شريط التعبئة
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
          height: 16, // مساحة العداد الزمني صغرت
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
    _startTimer();
  }

  @override
  void didUpdateWidget(StatTimerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.initialSeconds - seconds).abs() > 8) {
      seconds = widget.initialSeconds;
    }
  }

  void _startTimer() {
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
              fontSize: 10, // 🟢 تصغير خط العداد الزمني
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