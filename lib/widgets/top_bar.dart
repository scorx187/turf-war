import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final int cash;
  final int gold;
  final int energy;
  final int courage;
  final int health;
  final int prestige; // ضفت لك الهيبة هنا
  final String playerName;
  final int level;
  final double xpPercent;
  final bool isVIP;

  const TopBar({
    super.key,
    required this.cash,
    required this.gold,
    required this.energy,
    required this.courage,
    required this.health,
    this.prestige = 0, // عطيناها قيمة افتراضية عشان ما يخرب كودك في game_screen
    required this.playerName,
    required this.level,
    required this.xpPercent,
    required this.isVIP,
  });

  @override
  Widget build(BuildContext context) {
    // التأكد من أن نسبة الخبرة سليمة
    double safeXpPercent = (xpPercent.isNaN || xpPercent.isInfinite) ? 0.0 : xpPercent.clamp(0.0, 1.0);

    return Directionality(
      textDirection: TextDirection.rtl, // لضمان الترتيب من اليمين لليسار
      child: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 12, left: 10, right: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          image: const DecorationImage(
            image: AssetImage('assets/images/ui/header_wood_bg.png'), // خلفيتك الفخمة
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
            // --- الصف الأول: معلومات الزعيم ---
            Row(
              children: [
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

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            playerName,
                            style: const TextStyle(
                              fontFamily: 'Changa',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                            ),
                          ),
                          if (isVIP) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFDAA520)]),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 4)],
                              ),
                              child: const Text(
                                'VIP',
                                style: TextStyle(fontFamily: 'Changa', fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

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

            // --- الصف الثاني: الموارد بأيقوناتك الخاصة ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // وزعناها بالتساوي عشان تكفي 6 عناصر
              children: [
                // ⚠️ تأكد من أن مسارات الصور تطابق اللي عندك بالمشروع بالضبط
                _buildResourceChip('assets/images/icons/cash.png', _formatNumber(cash)),
                _buildResourceChip('assets/images/icons/gold.png', _formatNumber(gold)),
                _buildResourceChip('assets/images/icons/health.png', health.toString()),
                _buildResourceChip('assets/images/icons/energy.png', energy.toString()),
                _buildResourceChip('assets/images/icons/courage.png', courage.toString()),
                _buildResourceChip('assets/images/icons/prestige.png', _formatNumber(prestige)), // الهيبة
              ],
            ),
          ],
        ),
      ),
    );
  }

  // دالة جديدة تقبل "مسار الصورة" بدل الأيقونة الجاهزة
  Widget _buildResourceChip(String imagePath, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4), // صغرنا الهوامش شوي عشان تكفي 6 عناصر في الشاشة
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // هنا نعرض صورتك الخاصة
          Image.asset(
            imagePath,
            width: 16, // حجم الأيقونة
            height: 16,
            fit: BoxFit.contain,
            // لو الصورة مو موجودة يحط لك علامة خطأ حمراء عشان تنتبه لها وتعدل الاسم
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error_outline, color: Colors.red, size: 16);
            },
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
                fontFamily: 'Changa',
                fontSize: 12, // الخط ناعم وواضح
                fontWeight: FontWeight.bold,
                color: Colors.white
            ),
          ),
        ],
      ),
    );
  }

  // الدالة الذكية بعد تطويرها لدعم المليار والتريليون
  String _formatNumber(int number) {
    if (number >= 1000000000000) {
      return '${(number / 1000000000000).toStringAsFixed(1)}T'; // تريليون
    } else if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B'; // مليار
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M'; // مليون
    } else if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(1)}K'; // ألف
    }
    return number.toString();
  }
}