import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';

class TopBar extends StatelessWidget {
  final int cash;
  final int gold;
  final int energy;
  final int courage;
  final int health;
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
    required this.playerName,
    required this.level,
    required this.xpPercent,
    required this.isVIP,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return Container(
      width: double.infinity,
      height: 85, // الارتفاع المناسب ليظهر تصميمLeonardo كامل
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/top_nav_bg.png'), // تأكد من وجود الصورة بهذا الاسم
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          // 1. صورة البروفايل (أقصى اليسار) مع تنبيه الرسائل غير المقروءة
          Positioned(
            left: 12,
            top: 18,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('private_chats')
                  .where('participants', arrayContains: player.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                bool hasUnread = false;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    if ((data['unread_${player.uid}'] ?? 0) > 0) {
                      hasUnread = true;
                      break;
                    }
                  }
                }

                final imageBytes = player.getDecodedImage(player.profilePicUrl);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.5), width: 2),
                        image: DecorationImage(
                          image: imageBytes != null
                              ? MemoryImage(imageBytes) as ImageProvider
                              : const AssetImage('assets/images/profile_btn.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // 2. اسم اللاعب والمستوى (بجانب البروفايل)
          Positioned(
            left: 75,
            top: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isVIP) const Icon(Icons.workspace_premium, color: Colors.amber, size: 14),
                    Text(
                      playerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Changa',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // شريط الـ XP الصغير
                SizedBox(
                  width: 60,
                  height: 3,
                  child: LinearProgressIndicator(
                    value: xpPercent.clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
              ],
            ),
          ),

          // 3. ترتيب الموارد (من اليمين لليسار حسب طلبك)
          // [ الذهب | الكاش | الشهامة | الشجاعة | الطاقة | الصحة ]
          Positioned(
            right: 15,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildValueText(gold.toString(), 60),    // الذهب
                const SizedBox(width: 15),
                _buildValueText(cash.toString(), 80),    // الكاش
                const SizedBox(width: 15),
                _buildValueText("100", 50),             // الشهامة (قيمة افتراضية حالياً)
                const SizedBox(width: 15),
                _buildValueText(courage.toString(), 50), // الشجاعة
                const SizedBox(width: 15),
                _buildValueText(energy.toString(), 50),  // الطاقة
                const SizedBox(width: 15),
                _buildValueText(health.toString(), 50),  // الصحة
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueText(String value, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Changa',
          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}