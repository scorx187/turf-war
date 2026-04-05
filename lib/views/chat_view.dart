// المسار: lib/views/chat_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';
import '../widgets/top_bar.dart';
import 'player_profile_view.dart';
import 'pvp_battle_view.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Stream<QuerySnapshot> _chatStream;
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _cachedAdminMsg;

  int _messageLimit = 20;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _setupStreamOnly();
    _fetchAdminMessage();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        _loadMore();
      }
    });
  }

  void _loadMore() {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
      _messageLimit += 20;
      _setupStreamOnly();
    });
  }

  void _setupStreamOnly() {
    _chatStream = _firestore
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots();
  }

  Future<void> _fetchAdminMessage() async {
    if (_cachedAdminMsg != null) return;

    try {
      final query = await _firestore.collection('chat')
          .where('type', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docs = query.docs.toList();
        docs.sort((a, b) {
          final t1 = a.data()['timestamp'] as Timestamp?;
          final t2 = b.data()['timestamp'] as Timestamp?;
          if (t1 == null || t2 == null) return 0;
          return t2.compareTo(t1);
        });

        if (mounted) {
          setState(() {
            _cachedAdminMsg = docs.first.data();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching admin message: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final player = Provider.of<PlayerProvider>(context, listen: false);

    _firestore.collection('chat').add({
      'type': 'player',
      'user': player.playerName,
      'uid': player.uid,
      'message': _controller.text.trim(),
      'isVIP': player.isVIP,
      'profilePicUrl': player.profilePicUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _controller.clear();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _openPlayerProfile(BuildContext context, String uid, String name, String? picUrl, bool isVIP) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFF1A1A1D),
            body: SafeArea(
              top: false,
              child: Consumer<PlayerProvider>(
                  builder: (context, player, child) {
                    return Column(
                      children: [
                        TopBar(
                            cash: player.cash,
                            gold: player.gold,
                            energy: player.energy,
                            maxEnergy: player.maxEnergy,
                            courage: player.courage,
                            maxCourage: player.maxCourage,
                            health: player.health,
                            maxHealth: player.maxHealth,
                            prestige: player.prestige,
                            maxPrestige: player.maxPrestige,
                            playerName: player.playerName,
                            profilePicUrl: player.profilePicUrl,
                            level: player.crimeLevel,
                            currentXp: player.crimeXP,
                            maxXp: player.xpToNextLevel,
                            isVIP: player.isVIP
                        ),
                        Expanded(child: PlayerProfileView(
                            targetUid: uid,
                            previewName: name,
                            previewPicUrl: picUrl,
                            previewIsVIP: isVIP,
                            onBack: () => Navigator.pop(context)
                        )),
                      ],
                    );
                  }
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSystemBroadcast(String senderName, String message, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, spreadRadius: 1)],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '[$senderName] ', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                      TextSpan(text: message, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 تم حل مشكلة رمشة الصورة هنا 🟢
  Widget _buildBountyCard(BuildContext context, Map<String, dynamic> msg, String currentUserUid) {
    final playerProv = Provider.of<PlayerProvider>(context, listen: false);
    final imageBytes = playerProv.getDecodedImage(msg['targetPicUrl']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.deepOrange.withOpacity(0.8), width: 2),
          boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)]
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 24),
                SizedBox(width: 8),
                Text('مطلوب حياً أو ميتاً! 🚨', style: TextStyle(color: Colors.deepOrange, fontFamily: 'Changa', fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 24),
              ],
            ),
            const Divider(color: Colors.white24),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                  child: imageBytes == null ? const Icon(Icons.person, color: Colors.white54) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الهدف: ${msg['targetName'] ?? 'مجهول'}', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('المكافأة: \$${msg['amount']}', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('بواسطة: ${msg['senderName'] ?? 'شخص مجهول'}', style: const TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  icon: const Icon(Icons.my_location, color: Colors.white, size: 16),
                  label: const Text('هجوم', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (msg['targetUid'] == currentUserUid) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكنك الهجوم على نفسك!', style: TextStyle(fontFamily: 'Changa'))));
                      return;
                    }

                    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));

                    final enemyData = await playerProv.getPlayerById(msg['targetUid']);

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (enemyData != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: Colors.black,
                              body: SafeArea(
                                top: false,
                                child: PvpBattleView(
                                  enemyData: enemyData,
                                  onBack: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل العثور على بيانات الهدف!')));
                      }
                    }
                  },
                )
              ],
            ),
          ],
        ),
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
            decoration: const BoxDecoration(color: Colors.black26, border: Border(bottom: BorderSide(color: Colors.white10))),
            child: const Text('شات المدينة أونلاين 🌐', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
        ),

        if (_cachedAdminMsg != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              border: Border(bottom: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1)),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cachedAdminMsg!['message'] ?? '',
                      style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('خطأ في الاتصال', style: TextStyle(color: Colors.redAccent)));

              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد رسائل...', style: TextStyle(color: Colors.white54)));
              }

              final messages = snapshot.data!.docs;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _isFetchingMore = false;
                  _hasMore = messages.length >= _messageLimit;
                }
              });

              final currentUserUid = Provider.of<PlayerProvider>(context, listen: false).uid ?? '';

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {

                  if (index == messages.length) {
                    return const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2.5))),
                    );
                  }

                  final msg = messages[index].data() as Map<String, dynamic>;
                  final String msgType = msg['type'] ?? 'player';

                  if (msgType == 'admin') {
                    return const SizedBox.shrink();
                  } else if (msgType == 'system') {
                    return _buildSystemBroadcast('النظام', msg['message'] ?? '', Colors.redAccent, Icons.gavel);
                  }
                  else if (msgType == 'bounty') {
                    return _buildBountyCard(context, msg, currentUserUid);
                  }

                  final bool isVIP = msg['isVIP'] ?? false;
                  final String senderUid = msg['uid'] ?? '';
                  final bool isMe = senderUid == currentUserUid;
                  final String senderName = msg['user'] ?? 'مجهول';
                  final String? picUrl = msg['profilePicUrl'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) _buildAvatar(senderUid, isVIP, isMe, picUrl, senderName),
                          if (!isMe) const SizedBox(width: 8),
                          Flexible(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF1E3A2F) : const Color(0xFF2A2A2D),
                                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(15), topRight: const Radius.circular(15), bottomLeft: isMe ? const Radius.circular(15) : Radius.zero, bottomRight: isMe ? Radius.zero : const Radius.circular(15)),
                                  border: Border.all(color: isMe ? Colors.green.withOpacity(0.3) : Colors.white10),
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
                          if (isMe) _buildAvatar(senderUid, isVIP, isMe, picUrl, senderName),
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
              Expanded(
                  child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                          hintText: 'اكتب رسالة للجميع...',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.black45,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10)
                      )
                  )
              ),
              const SizedBox(width: 10),
              GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.send, color: Colors.black, size: 20))
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String uid, bool isVIP, bool isMe, String? picUrl, String name) {
    final playerProv = Provider.of<PlayerProvider>(context, listen: false);
    final imageBytes = playerProv.getDecodedImage(picUrl);

    return GestureDetector(
      onTap: isMe ? null : () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        );

        await playerProv.getPlayerById(uid);

        if (context.mounted) {
          Navigator.pop(context);
          _openPlayerProfile(context, uid, name, picUrl, isVIP);
        }
      },
      child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.grey[800], shape: BoxShape.circle,
            border: isVIP ? Border.all(color: Colors.amberAccent, width: 2.5) : null,
            boxShadow: isVIP ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)] : [],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
            child: imageBytes == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, color: isVIP ? Colors.amber : Colors.white54, size: 20) : null,
          )
      ),
    );
  }
}