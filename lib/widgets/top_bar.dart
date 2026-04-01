import 'package:flutter/material.dart';
import 'dart:convert'; // 🟢 ضروري عشان نفك تشفير الصورة

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
  final String? profilePicUrl; // 🟢 جديد: لاستقبال صورة اللاعب
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
    this.profilePicUrl, // 🟢 إضافتها هنا
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 12, left: 10, right: 10),
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
            // --- الصف الأول: صورة البروفايل، الاسم، الكاش، والذهب ---
            Row(
              children: [
                // 🟢 دائرة البروفايل (تعرض الصورة إذا موجودة)
                Container(
                  width: 50,
                  height: 50,
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
                  child: ClipOval(
                    child: profilePicUrl != null && profilePicUrl!.isNotEmpty
                        ? Image.memory(
                      base64Decode(profilePicUrl!),
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white70, size: 30),
                    )
                        : const Icon(Icons.person, color: Colors.white70, size: 30),
                  ),
                ),
                const SizedBox(width: 10),

                // الاسم والـ VIP (ينضغطون لو طال الاسم) والكاش والذهب
                Expanded(
                  child: Row(
                    children: [
                      // الاسم والـ VIP في مساحة مرنة عشان ما يصير فيه فراغ بشع بينهم
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars, color: Colors.amber, size: 18),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // الكاش والذهب ثابتين على اليسار
                      _buildTopUpResource(
                        iconPath: 'assets/images/icons/cash.png',
                        value: _formatWithCommas(cash),
                        bgImagePath: 'assets/images/ui/cash_bg.png',
                        plusImagePath: 'assets/images/icons/plus.png',
                      ),
                      const SizedBox(width: 8),
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
            const SizedBox(height: 12),

            // --- الصف الثاني: الموارد (الصحة، الطاقة، الشجاعة، الشهامة) ---
            // 🟢 استخدام Expanded يوزع الموارد بالتساوي ويشيل الفراغات المزعجة
            Row(
              children: [
                Expanded(child: _buildResourceChip('assets/images/icons/health.png', '$health/$maxHealth', progress: hpProgress, barColor: Colors.redAccent)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('assets/images/icons/energy.png', '$energy/$maxEnergy', progress: enProgress, barColor: Colors.lightBlueAccent)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('assets/images/icons/courage.png', '$courage/$maxCourage', progress: crProgress, barColor: Colors.greenAccent)),
                const SizedBox(width: 4),
                Expanded(child: _buildResourceChip('assets/images/icons/prestige.png', _formatWithCommas(prestige))),
              ],
            ),
            const SizedBox(height: 12),

            // --- الصف الثالث: خط اللفل الأصفر ---
            Row(
              children: [
                Image.asset(
                  'assets/images/icons/lv.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 4),
                Text(
                  '$level',
                  style: const TextStyle(
                    fontFamily: 'Changa',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE2C275),
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1),
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
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 4)],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '$currentXp / $maxXp',
                            style: const TextStyle(
                              fontFamily: 'Changa',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
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

  // 🟢 دوال الرسم المحسنة
  Widget _buildTopUpResource({required String iconPath, required String value, required String bgImagePath, required String plusImagePath}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage(bgImagePath), fit: BoxFit.fill),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(iconPath, width: 14, height: 14, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, color: Colors.red, size: 14)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(value, style: const TextStyle(fontFamily: 'Changa', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        Positioned(
          left: -6, top: -5,
          child: Image.asset(plusImagePath, width: 14, height: 14, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.add, size: 10, color: Colors.white))),
        ),
      ],
    );
  }

  Widget _buildResourceChip(String imagePath, String value, {double? progress, Color? barColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), // بادينق ممتاز للتمدد
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
              Image.asset(imagePath, width: 14, height: 14, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, color: Colors.red, size: 14)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Changa', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          if (progress != null && barColor != null) ...[
            const SizedBox(height: 5),
            // 🟢 خليت شريط التعبئة يمتد تلقائياً على حسب مساحة المربع
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
}