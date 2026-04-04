// المسار: lib/views/notifications_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';
// 🟢 ضروري نضيف هذي عشان تفتح البروفايل والتوب بار معاه
import 'player_profile_view.dart';
import '../widgets/top_bar.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  // 🟢 دالة تفتح بروفايل اللاعب (المرسل أو الهاجم) 🟢
  void _openProfile(BuildContext context, String uid) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));

    final playerProv = Provider.of<PlayerProvider>(context, listen: false);
    final targetData = await playerProv.getPlayerById(uid);

    if (context.mounted) {
      Navigator.pop(context);
      if (targetData != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
                backgroundColor: const Color(0xFF1A1A1D),
                body: SafeArea(
                    top: false,
                    child: Consumer<PlayerProvider>(
                        builder: (context, player, child) => Column(
                            children: [
                              TopBar(
                                  cash: player.cash, gold: player.gold, energy: player.energy, maxEnergy: player.maxEnergy, courage: player.courage, maxCourage: player.maxCourage, health: player.health, maxHealth: player.maxHealth, prestige: player.prestige, maxPrestige: player.maxPrestige, playerName: player.playerName, profilePicUrl: player.profilePicUrl, level: player.crimeLevel, currentXp: player.crimeXP, maxXp: player.xpToNextLevel, isVIP: player.isVIP
                              ),
                              Expanded(child: PlayerProfileView(
                                  targetUid: uid,
                                  previewName: targetData['playerName'],
                                  previewPicUrl: targetData['profilePicUrl'],
                                  previewIsVIP: targetData['isVIP'] == true,
                                  onBack: () => Navigator.pop(context)
                              )),
                            ]
                        )
                    )
                )
            )
        )));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب غير موجود!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('الإشعارات 🔔', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 10,
        shadowColor: Colors.black,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<Map<String, dynamic>>>(
            future: player.fetchAttacksLog(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              List<Map<String, dynamic>> allNotifications = [];

              if (snapshot.hasData) {
                for (var attack in snapshot.data!) {
                  allNotifications.add({
                    'type': 'attack',
                    'data': attack,
                    'date': (attack['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  });
                }
              }

              for (var t in player.transactions) {
                if (t.isPositive && (t.title.contains('تحويل') || t.title.contains('غنيمة') || t.title.contains('هبة'))) {
                  allNotifications.add({
                    'type': 'transfer',
                    'data': t,
                    'date': t.date,
                  });
                }
              }

              allNotifications.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

              if (allNotifications.isEmpty) {
                return const Center(child: Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.white54, fontSize: 18, fontFamily: 'Changa')));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: allNotifications.length,
                itemBuilder: (context, index) {
                  final item = allNotifications[index];

                  if (item['type'] == 'attack') {
                    final data = item['data'];
                    return Card(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        // 🟢 الدخول لبروفايل اللي هجم عليك 🟢
                        onTap: () => _openProfile(context, data['attackerId']),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.warning, color: Colors.white)),
                        title: const Text('تعرضت لهجوم! ⚔️', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                        subtitle: Text('اللاعب ${data['attackerName']} قام بالهجوم عليك وسرق \$${data['stolenAmount']}', style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', height: 1.5)),
                      ),
                    );
                  } else {
                    final t = item['data'];
                    return Card(
                      color: Colors.green.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.withOpacity(0.5))),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        // 🟢 الدخول لبروفايل اللي حول لك كاش 🟢
                        onTap: () {
                          if (t.senderUid != null) {
                            _openProfile(context, t.senderUid!);
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.attach_money, color: Colors.white)),
                        title: const Text('إشعار مالي 💸', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                        subtitle: Text('${t.title} بمقدار \$${t.amount}', style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', height: 1.5)),
                      ),
                    );
                  }
                },
              );
            }
        ),
      ),
    );
  }
}