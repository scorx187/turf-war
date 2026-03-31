import 'package:flutter/material.dart';

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
  final int level;
  final double xpPercent;
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
    required this.level,
    required this.xpPercent,
    required this.isVIP,
  });

  @override
  Widget build(BuildContext context) {
    double safeXpPercent = (xpPercent.isNaN || xpPercent.isInfinite) ? 0.0 : xpPercent.clamp(0.0, 1.0);

    // حساب نسب الامتلاء بشكل آمن
    double hpProgress = (maxHealth > 0 && !health.isNaN) ? (health / maxHealth).clamp(0.0, 1.0) : 0.0;
    double enProgress = (maxEnergy > 0 && !energy.isNaN) ? (energy / maxEnergy).clamp(0.0, 1.0) : 0.0;
    double crProgress = (maxCourage > 0 && !courage.isNaN) ? (courage / maxCourage).clamp(0.0, 1.0) : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 12, left: 10, right: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          image: const DecorationImage(
            // 🟢 تم تغيير الخلفية هنا لتكون الخلفية الخشبية اللي طلبتها
            image: AssetImage('assets/images/ui/header_wood_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
          border: const Border(
            bottom: BorderSide(color: Color(0xFF856024), width: 2.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- الصف الأول: الزعيم، الكاش، والذهب ---
            Row(
              children: [
                // شارة المستوى
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2C275), width: 2),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF856024), Colors.black],
                      center: Alignment.topLeft,
                      radius: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.5), blurRadius: 8, spreadRadius: 1),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        fontFamily: 'Changa',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // اسم اللاعب وصورة الـ VIP والكاش والذهب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              playerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Changa',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                              ),
                            ),
                          ),
                          if (isVIP) ...[
                            const SizedBox(width: 6),
                            Image.asset(
                              'assets/images/icons/vip.png',
                              height: 18,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.stars, color: Colors.amber, size: 18);
                              },
                            ),
                          ],
                          const Spacer(),

                          _buildTopResource('assets/images/icons/cash.png', _formatWithCommas(cash), Colors.green),
                          const SizedBox(width: 8),
                          _buildTopResource('assets/images/icons/gold.png', _formatWithCommas(gold), Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // شريط الخبرة (XP)
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: safeXpPercent,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.6), blurRadius: 6)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- الصف الثاني: الموارد (الصحة، الطاقة، الشجاعة، الهيبة) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResourceChip('assets/images/icons/health.png', '$health/$maxHealth', progress: hpProgress, barColor: Colors.redAccent),
                _buildResourceChip('assets/images/icons/energy.png', '$energy/$maxEnergy', progress: enProgress, barColor: Colors.lightBlueAccent),
                _buildResourceChip('assets/images/icons/courage.png', '$courage/$maxCourage', progress: crProgress, barColor: Colors.greenAccent),
                _buildResourceChip('assets/images/icons/prestige.png', _formatWithCommas(prestige)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 دالة مخصصة للكاش والذهب في الأعلى
  Widget _buildTopResource(String imagePath, String value, Color shadowColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, color: Colors.red, size: 16),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Changa',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: shadowColor, blurRadius: 6)],
          ),
        ),
      ],
    );
  }

  // دالة الموارد السفلية مع العدادات
  Widget _buildResourceChip(String imagePath, String value, {double? progress, Color? barColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            children: [
              Image.asset(
                imagePath,
                width: 14,
                height: 14,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error_outline, color: Colors.red, size: 14);
                },
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                    fontFamily: 'Changa',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                ),
              ),
            ],
          ),

          if (progress != null && barColor != null) ...[
            const SizedBox(height: 4),
            Container(
              width: 55,
              height: 3,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Container(
                width: 55 * progress,
                height: 3,
                decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: barColor.withOpacity(0.8), blurRadius: 4),
                    ]
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // 🟢 دالة الفواصل اللي تخلي مليون ينكتب كذا: 1,000,000
  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }
}