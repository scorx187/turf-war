import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../providers/player_provider.dart';
import '../widgets/top_bar.dart';
import 'player_profile_view.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final player = Provider.of<PlayerProvider>(context, listen: false);
    _firestore.collection('chat').add({
      'user': player.playerName,
      'uid': player.uid,
      'message': _controller.text.trim(),
      'isVIP': player.isVIP,
      'profilePicUrl': player.profilePicUrl, // إرسال الصورة مع الرسالة
      'timestamp': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  void _openPlayerProfile(BuildContext context, String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1D),
          body: SafeArea(
            child: Consumer<PlayerProvider>(
                builder: (context, player, child) {
                  return Column(
                    children: [
                      TopBar(
                        cash: player.cash, gold: player.gold, energy: player.energy,
                        courage: player.courage, health: player.health,
                        playerName: player.playerName, level: player.crimeLevel,
                        xpPercent: player.crimeXP / player.xpToNextLevel, isVIP: player.isVIP,
                      ),
                      Expanded(child: PlayerProfileView(targetUid: uid, onBack: () => Navigator.pop(context))),
                    ],
                  );
                }
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(16), width: double.infinity, decoration: const BoxDecoration(color: Colors.black26, border: Border(bottom: BorderSide(color: Colors.white10))), child: const Text('شات المدينة أونلاين 🌐', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('chat').orderBy('timestamp', descending: true).limit(50).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('خطأ في الاتصال', style: const TextStyle(color: Colors.redAccent)));
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد رسائل...', style: TextStyle(color: Colors.white54)));

              final messages = snapshot.data!.docs;
              final currentUserUid = Provider.of<PlayerProvider>(context, listen: false).uid;

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  final bool isVIP = msg['isVIP'] ?? false;
                  final String senderUid = msg['uid'] ?? '';
                  final bool isMe = senderUid == currentUserUid;
                  final String senderName = msg['user'] ?? 'مجهول';
                  final String? picUrl = msg['profilePicUrl']; // جلب صورة المرسل

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) _buildAvatar(senderUid, isVIP, isMe, picUrl),
                          if (!isMe) const SizedBox(width: 8),
                          Flexible(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF1E3A2F) : const Color(0xFF2A2A2D),
                                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(15), topRight: const Radius.circular(15), bottomLeft: isMe ? const Radius.circular(15) : Radius.zero, bottomRight: isMe ? Radius.zero : const Radius.circular(15)),
                                  border: Border.all(color: isMe ? Colors.green.withValues(alpha:0.3) : Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isMe ? 'أنت' : senderName, style: TextStyle(color: isMe ? Colors.greenAccent : (isVIP ? Colors.amber : Colors.white70), fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(msg['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 8),
                          if (isMe) _buildAvatar(senderUid, isVIP, isMe, picUrl),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: Color(0xFF1A1A1D), border: Border(top: BorderSide(color: Colors.white10))),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _controller, style: const TextStyle(color: Colors.white), onSubmitted: (_) => _sendMessage(), decoration: InputDecoration(hintText: 'اكتب رسالة للجميع...', hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10)))),
              const SizedBox(width: 10),
              GestureDetector(onTap: _sendMessage, child: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.send, color: Colors.black, size: 20))),
            ],
          ),
        ),
      ],
    );
  }

  // [الدايموند 💎] ويدجت الصورة في الشات يعرض الصورة المخصصة وإطار الـ VIP الذهبي
  Widget _buildAvatar(String uid, bool isVIP, bool isMe, String? picUrl) {
    return GestureDetector(
      onTap: isMe ? null : () => _openPlayerProfile(context, uid),
      child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle, border: Border.all(color: isVIP ? Colors.amber : Colors.transparent, width: 2)),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: picUrl != null ? MemoryImage(base64Decode(picUrl)) : null,
            child: picUrl == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, color: isVIP ? Colors.amber : Colors.white54, size: 20) : null,
          )
      ),
    );
  }
}