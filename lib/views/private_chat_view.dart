import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../providers/player_provider.dart';
import '../widgets/top_bar.dart';

class PrivateChatView extends StatefulWidget {
  final String targetUid;
  final String targetName;
  final String? targetPicUrl;

  const PrivateChatView({
    super.key,
    required this.targetUid,
    required this.targetName,
    this.targetPicUrl,
  });

  @override
  State<PrivateChatView> createState() => _PrivateChatViewState();
}

class _PrivateChatViewState extends State<PrivateChatView> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserId;
  String? chatId;

  @override
  void initState() {
    super.initState();
    // تصفير العداد (قراءة الرسائل) بمجرد دخول الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentUserId = Provider.of<PlayerProvider>(context, listen: false).uid;
      if (currentUserId != null) {
        chatId = getChatId(currentUserId!, widget.targetUid);
        _markAsRead();
      }
    });
  }

  String getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // دالة لإزالة النقطة الحمراء والأرقام
  void _markAsRead() {
    if (chatId != null && currentUserId != null) {
      _firestore.collection('private_chats').doc(chatId).set({
        'unread_$currentUserId': 0, // تصفير الرسائل غير المقروءة الخاصة بك
      }, SetOptions(merge: true));
    }
  }

  void _sendMessage(String currentUserUid) {
    if (_controller.text.trim().isEmpty) return;

    final id = getChatId(currentUserUid, widget.targetUid);
    final msgText = _controller.text.trim();

    // إضافة الرسالة
    _firestore.collection('private_chats').doc(id).collection('messages').add({
      'senderId': currentUserUid,
      'message': msgText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // تحديث المحادثة الرئيسية لزيادة عداد الطرف الآخر
    _firestore.collection('private_chats').doc(id).set({
      'participants': [currentUserUid, widget.targetUid],
      'lastMessage': msgText,
      'timestamp': FieldValue.serverTimestamp(),
      'unread_${widget.targetUid}': FieldValue.increment(1), // الإشعار للشخص الآخر
    }, SetOptions(merge: true));

    _controller.clear();
    _markAsRead(); // تأكيد التصفير لجهتك
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final cId = getChatId(player.uid ?? '', widget.targetUid);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              cash: player.cash, gold: player.gold, energy: player.energy,
              courage: player.courage, health: player.health,
              playerName: player.playerName, level: player.crimeLevel,
              xpPercent: player.crimeXP / player.xpToNextLevel, isVIP: player.isVIP,
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Colors.black45, border: Border(bottom: BorderSide(color: Colors.white10))),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text(widget.targetName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  CircleAvatar(radius: 20, backgroundColor: Colors.grey[800], backgroundImage: widget.targetPicUrl != null ? MemoryImage(base64Decode(widget.targetPicUrl!)) : null, child: widget.targetPicUrl == null ? const Icon(Icons.person, color: Colors.white54) : null),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('private_chats').doc(cId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  final messages = snapshot.data!.docs;
                  if (messages.isEmpty) return const Center(child: Text('لا توجد رسائل سابقة.. ابدأ المحادثة الآن!', style: TextStyle(color: Colors.white54)));

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data() as Map<String, dynamic>;
                      final bool isMe = msg['senderId'] == player.uid;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF1E3A2F) : const Color(0xFF2A2A2D),
                                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(15), topRight: const Radius.circular(15), bottomLeft: isMe ? const Radius.circular(15) : Radius.zero, bottomRight: isMe ? Radius.zero : const Radius.circular(15)),
                                ),
                                child: Text(msg['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15), textDirection: TextDirection.rtl),
                              ),
                            ),
                          ],
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
                  Expanded(child: TextField(controller: _controller, style: const TextStyle(color: Colors.white), textDirection: TextDirection.rtl, onSubmitted: (_) => _sendMessage(player.uid!), decoration: InputDecoration(hintText: 'اكتب رسالتك...', hintStyle: const TextStyle(color: Colors.white24), filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10)))),
                  const SizedBox(width: 10),
                  GestureDetector(onTap: () => _sendMessage(player.uid!), child: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.send, color: Colors.black, size: 20))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}