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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد رسائل بعد...', style: TextStyle(color: Colors.white54)));
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  final bool isVIP = msg['isVIP'] ?? false;
                  final bool isMe = msg['uid'] == Provider.of<PlayerProvider>(context, listen: false).uid;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: isVIP ? Colors.amber : Colors.grey[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isVIP ? Icons.workspace_premium : Icons.person, 
                            color: isVIP ? Colors.black : Colors.white54
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['user'] ?? 'مجهول',
                                style: TextStyle(color: isMe ? Colors.blueAccent : (isVIP ? Colors.amber : Colors.white70), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blueAccent.withValues(alpha:0.15) : Colors.white.withValues(alpha:0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  msg['message'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
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
          decoration: const BoxDecoration(color: Colors.black45),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
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
}
