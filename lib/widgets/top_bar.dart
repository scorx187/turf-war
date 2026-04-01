import 'package:flutter/material.dart';
import 'dart:convert';

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
    this.prestige = 0,
    required this.playerName,
    this.profilePicUrl,
    required this.level,
    required this.currentXp,
    required this.maxXp,
    required this.isVIP,
  });

  @override
  Widget build(BuildContext context) {
    double safeXpPercent = (maxXp > 0) ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

    double hpProgress = (maxHealth > 0 && !health.isNaN) ? (health / maxHealth).clamp(0.0, 1.0) : 0.0;
    double enProgress = (maxEnergy > 0 && !energy.isNaN) ? (energy / maxEnergy).clamp(0.0, 1.0) : 0.0;
    double crProgress = (maxCourage > 0 && !courage.isNaN) ? (courage / maxCourage).clamp(0.0, 1.0) : 0.0;

    String displayName = playerName.length > 13 ? '${playerName.substring(0, 13)}..' : playerName;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.only(top: 14, bottom: 8, left: 10, right: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          image: const DecorationImage(
            image: AssetImage('assets/images/ui/header_wood_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
          border: const Border(
            bottom: BorderSide(color: Color(0xFF856024), width: 2.5),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.9), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- الصف الأول: صورة البروفايل، الاسم، الكاش، والذهب ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(top: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2C275), width: 2.5),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF856024), Colors.black],
                      center: Alignment.topLeft,
                      radius: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.6), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: ClipOval(
                    child: profilePicUrl != null && profilePicUrl!.isNotEmpty
                        ? Image.memory(
                      base64Decode(profilePicUrl!),
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white70, size: 30),
                    )
                        : const Icon(Icons.person, color: Colors.white70, size: 30),
                  ),
                ),
                const SizedBox(width: 10),

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
                                  playerName,
                                  style: const TextStyle(
                                    fontFamily: 'Changa',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                                  ),
                                ),
                              ),
                            ),
                            if (isVIP) ...[
                              const SizedBox(width: 4),
                              Image.asset(
                                'assets/images/icons/vip.png',
                                height: 18,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars, color: Colors.amber, size: 18),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      _buildTopUpResource(
                        iconPath: 'assets/images/icons/cash.png',
                        value: _formatWithCommas(cash),
                        bgImagePath: 'assets/images/ui/cash_bg.png',
                        plusImagePath: 'assets/images/icons/plus.png',
                      ),
                      const SizedBox(width: 6),
                      _buildTopUpResource(
                        iconPath: 'assets/images/icons/gold.png',
                        value: _formatWithCommas(gold),
                        bgImagePath: 'assets/images/ui/gold_bg.png',
                        plusImagePath: 'assets/images/icons/plus.png',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // --- الصف الثاني: الموارد ---
            Row(
              children: [
                Expanded(child: _buildResourceChip('assets/images/icons/health.png', '${_formatCompact(health)}/${_formatCompact(maxHealth)}', progress: hpProgress, barColor: Colors.redAccent)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('assets/images/icons/energy.png', '${_formatCompact(energy)}/${_formatCompact(maxEnergy)}', progress: enProgress, barColor: Colors.lightBlueAccent)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('assets/images/icons/courage.png', '${_formatCompact(courage)}/${_formatCompact(maxCourage)}', progress: crProgress, barColor: Colors.greenAccent)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('assets/images/icons/prestige.png', _formatCompact(prestige))),
              ],
            ),
            const SizedBox(height: 2),

            // --- الصف الثالث: خط اللفل ---
            Row(
              children: [
                Image.asset(
                  'assets/images/icons/lv.png',
                  width: 24, // 🟢 كبرنا أيقونة اللفل من 22 إلى 24
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      fontFamily: 'Changa',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE2C275),
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF856024), width: 1.5),
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
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 6)],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              '${_formatCompact(currentXp)} / ${_formatCompact(maxXp)}',
                              style: const TextStyle(
                                fontFamily: 'Changa',
                                fontSize: 11,
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

  // الكاش والذهب
  Widget _buildTopUpResource({required String iconPath, required String value, required String bgImagePath, required String plusImagePath}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 95,
          height: 28, // 🟢 كبرنا الارتفاع من 26 إلى 28 عشان يستوعب الأيقونة الكبيرة
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage(bgImagePath), fit: BoxFit.fill),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🟢 كبرنا الأيقونة الأساسية للكاش والذهب من 14 إلى 18
              Image.asset(iconPath, width: 18, height: 18, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, color: Colors.red, size: 18)),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                        value,
                        style: const TextStyle(fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 4)])
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: -5, top: -5,
          child: Image.asset(plusImagePath, width: 14, height: 14, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.add, size: 10, color: Colors.white))),
        ),
      ],
    );
  }

  // الموارد السفلية
  Widget _buildResourceChip(String imagePath, String value, {double? progress, Color? barColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(6),
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
              // 🟢 كبرنا أيقونات الصحة والطاقة من 12 إلى 16
              Image.asset(imagePath, width: 16, height: 16, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, color: Colors.red, size: 16)),
              const SizedBox(width: 4), // 🟢 زِدنا المسافة نتفة عشان ما تلصق بالرقم
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value, style: const TextStyle(fontFamily: 'Changa', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                  ),
                ),
              ),
            ],
          ),
          if (progress != null && barColor != null) ...[
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              height: 3,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                widthFactor: progress,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: barColor.withOpacity(0.8), blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
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