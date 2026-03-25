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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: Colors.amber, width: 1.5)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            if (player.uid != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
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

                    // استخدم الكاش المركزي للصور
                    final imageBytes = player.getDecodedImage(player.profilePicUrl);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                          child: imageBytes == null ? const Icon(Icons.person, color: Colors.white54, size: 20) : null,
                        ),
                        if (hasUnread)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1.5)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isVIP) const Icon(Icons.workspace_premium, color: Colors.amber, size: 14),
                      if (isVIP) const SizedBox(width: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                        child: Text('Lvl $level', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 4),
                      Flexible(child: Text(playerName, style: TextStyle(color: isVIP ? Colors.amber : Colors.white, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SizedBox(width: 60, height: 3, child: LinearProgressIndicator(value: xpPercent.clamp(0.0, 1.0), backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber)))
                ],
              ),
            ),

            _buildTopStatItem(Icons.payments, cash.toString(), Colors.green),
            _buildTopStatItem(Icons.monetization_on, gold.toString(), Colors.yellow),
            _buildTopStatItem(Icons.bolt, energy.toString(), Colors.orange),
            _buildTopStatItem(Icons.shield, courage.toString(), Colors.purple),
            _buildTopStatItem(Icons.favorite, health.toString(), Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatItem(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}