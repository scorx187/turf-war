import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String playerName;
  final dynamic level;
  final dynamic cash;
  final dynamic gold;
  final dynamic energy;
  final dynamic courage;
  final dynamic health;
  final dynamic xpPercent; // ضفنا نسبة الخبرة
  final dynamic isVIP;     // ضفنا حالة الـ VIP

  const TopBar({
    Key? key,
    required this.playerName,
    required this.level,
    required this.cash,
    required this.gold,
    required this.energy,
    required this.courage,
    required this.health,
    required this.xpPercent, // عرفناها هنا
    required this.isVIP,     // وعرّفناها هنا
  }) : super(key: key);

  // دالة تأثير النص الذهبي المحفور
  Widget _buildGoldText(String text, double fontSize, {bool isBold = false}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFE2C275), Color(0xFF856024)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 2.0,
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(1.0, 1.0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 10,
        right: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
         image: const DecorationImage(
           image: AssetImage('assets/images/ui/header_wood_bg.png'),
           fit: BoxFit.cover,
         ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // صورة اللاعب
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC5A059), width: 2),
                  color: Colors.grey[800],
                ),
                child: const Icon(Icons.person, color: Color(0xFFC5A059)),
              ),
              const SizedBox(width: 15),
              // معلومات اللاعب وشريط الخبرة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildGoldText(playerName, 18, isBold: true),
                        const SizedBox(width: 8),
                        // شارة الـ VIP تظهر فقط إذا كان اللاعب VIP
                        if (isVIP == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE2C275), Color(0xFF856024)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildGoldText('المستوى $level', 12),
                        const SizedBox(width: 10),
                        // شريط التقدم للخبرة (XP)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (xpPercent is num) ? xpPercent.toDouble() : 0.0,
                              backgroundColor: Colors.grey[800],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A059)),
                              minHeight: 6,
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
          // الموارد
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildResourceItem(Icons.favorite, health.toString()),
              _buildResourceItem(Icons.bolt, energy.toString()),
              _buildResourceItem(Icons.shield, courage.toString()),
              _buildResourceItem(Icons.attach_money, cash.toString()),
              _buildResourceItem(Icons.monetization_on, gold.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF856024).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFE2C275), size: 16),
          const SizedBox(width: 4),
          _buildGoldText(value, 14, isBold: true),
        ],
      ),
    );
  }
}