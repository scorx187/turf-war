// المسار: lib/views/friends_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import 'player_profile_view.dart';
import '../widgets/top_bar.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final fs = FirebaseFirestore.instance;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1D),
          appBar: AppBar(
            backgroundColor: Colors.black87,
            title: const Text('الأصدقاء 👥', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.amber),
            bottom: const TabBar(
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white54,
              labelStyle: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'قائمة الأصدقاء'),
                Tab(text: 'طلبات الصداقة'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // 1. قائمة الأصدقاء الحالية
              StreamBuilder<QuerySnapshot>(
                stream: fs.collection('players').doc(player.uid).collection('friends').snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  if (snap.data!.docs.isEmpty) return const Center(child: Text('لا يوجد لديك أصدقاء حالياً.', style: TextStyle(color: Colors.white54, fontFamily: 'Changa')));

                  return ListView.builder(
                    itemCount: snap.data!.docs.length,
                    itemBuilder: (ctx, i) {
                      final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                      final targetUid = d['uid'] ?? '';

                      return FutureBuilder<Map<String, dynamic>?>(
                          future: player.getPlayerById(targetUid),
                          builder: (context, futureSnap) {
                            final targetData = futureSnap.data;
                            final picUrl = targetData?['profilePicUrl'];
                            final imageBytes = player.getDecodedImage(picUrl);

                            return Card(
                              color: Colors.black45,
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                                  child: imageBytes == null ? const Icon(Icons.person, color: Colors.white54) : null,
                                ),
                                title: Text(targetData?['playerName'] ?? d['name'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                subtitle: Text(targetData != null ? 'مستوى الإجرام: ${targetData['crimeLevel']}' : 'جاري التحميل...', style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Changa')),
                                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                                onTap: () => _openProfile(context, targetUid),
                              ),
                            );
                          }
                      );
                    },
                  );
                },
              ),

              // 2. طلبات الصداقة
              StreamBuilder<QuerySnapshot>(
                stream: fs.collection('players').doc(player.uid).collection('friend_requests').snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  if (snap.data!.docs.isEmpty) return const Center(child: Text('لا توجد طلبات معلقة.', style: TextStyle(color: Colors.white54, fontFamily: 'Changa')));

                  return ListView.builder(
                    itemCount: snap.data!.docs.length,
                    itemBuilder: (ctx, i) {
                      final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                      final imageBytes = player.getDecodedImage(d['picUrl']);

                      return Card(
                        color: Colors.black45,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[800],
                            backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                            child: imageBytes == null ? const Icon(Icons.person_add, color: Colors.white54) : null,
                          ),
                          title: Text(d['senderName'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          subtitle: const Text('يريد إضافتك كصديق', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontFamily: 'Changa')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => player.acceptFriend(d['senderId'], d['senderName'])),
                              IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => player.rejectFriend(d['senderId'])),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context, String uid) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));
    final p = Provider.of<PlayerProvider>(context, listen: false);
    final d = await p.getPlayerById(uid);

    if (context.mounted) {
      Navigator.pop(context);
      if (d != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: const Color(0xFF1A1A1D),
                body: SafeArea(
                  top: false,
                  child: Consumer<PlayerProvider>(
                      builder: (context, player, child) => Column(
                        children: [
                          const TopBar(),
                          Expanded(child: PlayerProfileView(targetUid: uid, previewName: d['playerName'], previewPicUrl: d['profilePicUrl'], previewIsVIP: d['isVIP'] == true, onBack: () => Navigator.pop(context)))
                        ],
                      )
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
  }
}