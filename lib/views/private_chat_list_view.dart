// المسار: lib/views/private_chat_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';
import 'private_chat_view.dart';

class PrivateChatListView extends StatelessWidget {
  const PrivateChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final myUid = player.uid!;

    // 🟢 التعديل الأهم: اختطاف زر الرجوع الخاص بالجوال لمنع إعادة تشغيل اللعبة 🟢
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text('رسائل الخاص 💬', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          centerTitle: true,
          // 🟢 زر رجوع مخصص ومطابق لتصميم اللعبة لضمان الخروج الآمن 🟢
          leadingWidth: 40,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.amber, size: 22),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          elevation: 10,
          shadowColor: Colors.black,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('private_chats').where('participants', arrayContains: myUid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              if (snapshot.data!.docs.isEmpty) return const Center(child: Text("صندوق الوارد فارغ..", style: TextStyle(color: Colors.white54, fontSize: 18, fontFamily: 'Changa')));

              final chatDocs = snapshot.data!.docs.toList();
              chatDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['timestamp'] as Timestamp?;
                final bTime = bData['timestamp'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: chatDocs.length,
                itemBuilder: (context, index) {
                  final chatData = chatDocs[index].data() as Map<String, dynamic>;
                  List parts = chatData['participants'] ?? [];
                  String targetUid = parts.firstWhere((id) => id != myUid, orElse: () => '');
                  int unreadCount = chatData['unread_$myUid'] ?? 0;
                  String lastMessage = chatData['lastMessage'] ?? '';
                  Timestamp? lastTime = chatData['timestamp'];

                  String timeString = '';
                  if (lastTime != null) {
                    final diff = DateTime.now().difference(lastTime.toDate());
                    if (diff.inMinutes < 60) { timeString = 'منذ ${diff.inMinutes} دقيقة'; }
                    else if (diff.inHours < 24) { timeString = 'منذ ${diff.inHours} ساعة'; }
                    else { timeString = 'منذ ${diff.inDays} يوم'; }
                  }

                  if (targetUid.isEmpty) return const SizedBox();

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: Provider.of<PlayerProvider>(context, listen: false).getPlayerById(targetUid),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) {
                        return const Card(
                          color: Colors.black26,
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.black45),
                            title: Text('جاري التحميل...', style: TextStyle(color: Colors.white24, fontFamily: 'Changa')),
                          ),
                        );
                      }

                      final targetData = userSnap.data!;
                      String targetName = targetData['playerName'] ?? 'مجهول';
                      String? targetPic = targetData['profilePicUrl'];
                      bool isVIP = targetData['isVIP'] == true;

                      final imageBytes = Provider.of<PlayerProvider>(context, listen: false).getDecodedImage(targetPic);

                      return Card(
                        color: unreadCount > 0 ? Colors.amber.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.03),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: unreadCount > 0 ? Colors.amber.withValues(alpha: 0.5) : Colors.white10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatView(targetUid: targetUid, targetName: targetName, targetPicUrl: targetPic)));
                          },
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: isVIP ? Border.all(color: Colors.amberAccent, width: 2) : null,
                                ),
                                child: CircleAvatar(radius: 25, backgroundColor: Colors.grey[800], backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null, child: imageBytes == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, color: isVIP ? Colors.amber : Colors.white54) : null),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                    top: -2,
                                    left: -2,
                                    child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                    )
                                ),
                            ],
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(targetName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa', fontSize: 16)),
                              Text(timeString, style: const TextStyle(color: Colors.white30, fontSize: 10, fontFamily: 'Changa')),
                            ],
                          ),
                          subtitle: Text(lastMessage, style: TextStyle(color: unreadCount > 0 ? Colors.white : Colors.white54, fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal, fontFamily: 'Changa'), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}