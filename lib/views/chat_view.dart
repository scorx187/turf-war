import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';

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
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  // [الدايموند 💎] دالة عرض الملف الشخصي عند الضغط على صورة اللاعب
  void _showPlayerProfile(BuildContext context, String uid, String name) async {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    // إظهار شاشة تحميل مؤقتة
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    // جلب بيانات اللاعب من السيرفر
    final data = await player.getPlayerById(uid);
    Navigator.pop(context); // إغلاق التحميل

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن العثور على بيانات اللاعب!')));
      return;
    }

    // عرض بيانات اللاعب
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amber, width: 2)),
          title: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.person, color: Colors.black)),
              const SizedBox(width: 10),
              Expanded(child: Text(data['playerName'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('مستوى الساحة', '${data['arenaLevel'] ?? 1}', Icons.shield, Colors.redAccent),
              _buildStatRow('مستوى الإجرام', '${data['crimeLevel'] ?? 1}', Icons.local_police, Colors.blueAccent),
              _buildStatRow('مستوى العمل', '${data['workLevel'] ?? 1}', Icons.work, Colors.green),
              _buildStatRow('العصابة', data['gangName'] ?? 'لا ينتمي لعصابة', Icons.group, Colors.orange),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(c),
              child: const Text('إغلاق', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        )
    );
  }

  Widget _buildStatRow(String label, String val, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.black26,
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: const Text(
            'شات المدينة أونلاين 🌐',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('chat').orderBy('timestamp', descending: true).limit(50).snapshots(),
            builder: (context, snapshot) {

              // [إصلاح التعليق اللانهائي] عرض الخطأ إن وجد لمعرفة السبب الحقيقي
              if (snapshot.hasError) {
                return Center(
                  child: Text('خطأ في الاتصال: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد رسائل بعد...\nكن أول من يكتب في الشات!', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center));
              }

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

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Directionality(
                      // تثبيت الاتجاه لتنسيق أماكن الرسائل: رسائلك يمين والآخرين يسار
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) _buildAvatar(senderUid, senderName, isVIP),
                          if (!isMe) const SizedBox(width: 8),

                          // صندوق الرسالة
                          Flexible(
                            child: Directionality(
                              // محتوى الرسالة نفسه يكون من اليمين لليسار (عربي)
                              textDirection: TextDirection.rtl,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.green.withValues(alpha: 0.2) : Colors.black45,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(15),
                                    topRight: const Radius.circular(15),
                                    // ذيل الرسالة يختلف حسب المرسل
                                    bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                                    bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                                  ),
                                  border: Border.all(color: isMe ? Colors.green.withValues(alpha: 0.5) : Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? 'أنت' : senderName,
                                      style: TextStyle(
                                          color: isMe ? Colors.greenAccent : (isVIP ? Colors.amber : Colors.white70),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      msg['message'] ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          if (isMe) const SizedBox(width: 8),
                          if (isMe) _buildAvatar(senderUid, senderName, isVIP),
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
          decoration: const BoxDecoration(color: Colors.black45),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة للجميع...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: const CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.send, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ويدجت منفصل لصورة اللاعب
  Widget _buildAvatar(String uid, String name, bool isVIP) {
    return GestureDetector(
      onTap: () => _showPlayerProfile(context, uid, name),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: isVIP ? Colors.amber : Colors.grey[800],
          shape: BoxShape.circle,
          border: Border.all(color: isVIP ? Colors.orange : Colors.transparent, width: 2),
        ),
        child: Icon(
          isVIP ? Icons.workspace_premium : Icons.person,
          color: isVIP ? Colors.black : Colors.white54,
          size: 20,
        ),
      ),
    );
  }
}