// المسار: lib/views/chat_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';
import '../widgets/top_bar.dart';
import 'player_profile_view.dart';
import 'pvp_battle_view.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // إذا لم يكن في عصابة، نعرض الشات العام فقط مباشرة
    if (!player.isInGang || player.gangName == null) {
      return const _ChatListWidget(collectionPath: 'chat', isGlobal: true);
    }

    // إذا كان في عصابة، نعرض تبويبات (عام وعصابة)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.black87,
              child: const TabBar(
                  indicatorColor: Colors.amber,
                  labelColor: Colors.amber,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: [
                    Tab(text: "الشات العام 🌐"),
                    Tab(text: "شات العصابة 🛡️")
                  ]
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _ChatListWidget(collectionPath: 'chat', isGlobal: true),
                  // ننشئ مسار خاص للعصابة في الفايربيس
                  _ChatListWidget(collectionPath: 'gang_chats/${player.gangName}/messages', isGlobal: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🟢 ويدجت الشات القابل لإعادة الاستخدام (عام أو عصابة) مع ميزة الكاش السريع 🟢
class _ChatListWidget extends StatefulWidget {
  final String collectionPath;
  final bool isGlobal;

  const _ChatListWidget({required this.collectionPath, required this.isGlobal});

  @override
  State<_ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<_ChatListWidget> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Stream<QuerySnapshot> _chatStream;
  final ScrollController _scrollController = ScrollController();

  // ماب لحفظ الرسايل لكل مسار بشكل منفصل عشان السرعة الصاروخية
  static final Map<String, List<QueryDocumentSnapshot>> _instantCaches = {};
  static Map<String, dynamic>? _cachedAdminMsg;

  int _messageLimit = 30;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _setupStreamOnly();
    if (widget.isGlobal) _fetchAdminMessage();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
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
        .collection(widget.collectionPath)
        .orderBy('timestamp', descending: true)
        .limit(_messageLimit)
        .snapshots();
  }

  Future<void> _fetchAdminMessage() async {
    if (_cachedAdminMsg != null) return;
    try {
      final query = await _firestore.collection('chat').where('type', isEqualTo: 'admin').limit(1).get();
      if (query.docs.isNotEmpty) {
        if (mounted) setState(() => _cachedAdminMsg = query.docs.first.data());
      }
    } catch (e) {}
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

    _firestore.collection(widget.collectionPath).add({
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
                        TopBar(cash: player.cash, gold: player.gold, energy: player.energy, maxEnergy: player.maxEnergy, courage: player.courage, maxCourage: player.maxCourage, health: player.health, maxHealth: player.maxHealth, prestige: player.prestige, maxPrestige: player.maxPrestige, playerName: player.playerName, profilePicUrl: player.profilePicUrl, level: player.crimeLevel, currentXp: player.crimeXP, maxXp: player.xpToNextLevel, isVIP: player.isVIP),
                        Expanded(child: PlayerProfileView(targetUid: uid, previewName: name, previewPicUrl: picUrl, previewIsVIP: isVIP, onBack: () => Navigator.pop(context))),
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

  Widget _buildBountyCard(BuildContext context, Map<String, dynamic> msg, String currentUserUid) {
    final playerProv = Provider.of<PlayerProvider>(context, listen: false);
    final imageBytes = playerProv.getDecodedImage(msg['targetPicUrl']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.deepOrange.withOpacity(0.6), width: 1.5)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 20), SizedBox(width: 5), Text('مطلوب حياً أو ميتاً! 🚨', style: TextStyle(color: Colors.deepOrange, fontFamily: 'Changa', fontSize: 14, fontWeight: FontWeight.bold))]),
            const Divider(color: Colors.white10, height: 10),
            Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: Colors.grey[800], backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null, child: imageBytes == null ? const Icon(Icons.person, color: Colors.white54, size: 20) : null),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الهدف: ${msg['targetName'] ?? 'مجهول'}', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 14, fontWeight: FontWeight.bold)), Text('المكافأة: \$${msg['amount']}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 13, fontWeight: FontWeight.bold))])),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), minimumSize: Size.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('هجوم', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (msg['targetUid'] == currentUserUid) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكنك الهجوم على نفسك!', style: TextStyle(fontFamily: 'Changa')))); return; }
                    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));
                    final enemyData = await playerProv.getPlayerById(msg['targetUid']);
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (enemyData != null) { Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, body: SafeArea(top: false, child: PvpBattleView(enemyData: enemyData, onBack: () => Navigator.pop(context)))))); }
                      else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل العثور على بيانات الهدف!'))); }
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
        if (widget.isGlobal)
          Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.black45, border: Border(bottom: BorderSide(color: Colors.white10))),
              child: const Text('شات المدينة 🌐', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa'), textAlign: TextAlign.center)
          )
        else
          Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), border: const Border(bottom: BorderSide(color: Colors.redAccent))),
              child: const Text('المحادثات سرية ومشفرة 🔒', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Changa'), textAlign: TextAlign.center)
          ),

        if (widget.isGlobal && _cachedAdminMsg != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), border: Border(bottom: BorderSide(color: Colors.amber.withOpacity(0.3)))),
            child: Directionality(textDirection: TextDirection.rtl, child: Row(children: [const Icon(Icons.campaign, color: Colors.amber, size: 20), const SizedBox(width: 8), Expanded(child: Text(_cachedAdminMsg!['message'] ?? '', style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)))])),
          ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _instantCaches[widget.collectionPath] = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _isFetchingMore = false;
                    _hasMore = _instantCaches[widget.collectionPath]!.length >= _messageLimit;
                  }
                });
              }

              if (!_instantCaches.containsKey(widget.collectionPath) && snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              final messages = _instantCaches[widget.collectionPath] ?? [];
              if (messages.isEmpty) {
                return const Center(child: Text('لا توجد رسائل...', style: TextStyle(color: Colors.white54, fontFamily: 'Changa')));
              }

              final currentUserUid = Provider.of<PlayerProvider>(context, listen: false).uid ?? '';

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                itemCount: messages.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) return const Padding(padding: EdgeInsets.all(10.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2))));

                  final msg = messages[index].data() as Map<String, dynamic>;
                  final String msgType = msg['type'] ?? 'player';

                  if (msgType == 'admin') return const SizedBox.shrink();
                  if (msgType == 'bounty') return _buildBountyCard(context, msg, currentUserUid);

                  final bool isVIP = msg['isVIP'] ?? false;
                  final String senderUid = msg['uid'] ?? '';
                  final bool isMe = senderUid == currentUserUid;
                  final String senderName = msg['user'] ?? 'مجهول';
                  final String? picUrl = msg['profilePicUrl'];
                  Color bubbleColor = isMe ? const Color(0xFF1B3B2B) : const Color(0xFF28282B);
                  if (!widget.isGlobal && isMe) bubbleColor = Colors.red.withOpacity(0.3); // لون مميز لرسائلك في العصابة

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(isMe ? 'أنت' : senderName, style: TextStyle(color: isMe ? (widget.isGlobal ? Colors.greenAccent : Colors.redAccent) : (isVIP ? Colors.amber : Colors.white54), fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: bubbleColor,
                                      borderRadius: BorderRadius.only(topLeft: const Radius.circular(12), topRight: const Radius.circular(12), bottomLeft: isMe ? const Radius.circular(12) : Radius.zero, bottomRight: isMe ? Radius.zero : const Radius.circular(12)),
                                      border: Border.all(color: isMe ? (widget.isGlobal ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.4)) : Colors.white10, width: 0.5),
                                    ),
                                    child: Text(msg['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.2)),
                                  ),
                                ],
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(color: Color(0xFF121212), border: Border(top: BorderSide(color: Colors.white10))),
          child: Row(
            children: [
              Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                            hintText: widget.isGlobal ? 'اكتب رسالة للجميع...' : 'رسالة سرية لأفراد العصابة...',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13, fontFamily: 'Changa'),
                            filled: true,
                            fillColor: Colors.black45,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0)
                        )
                    ),
                  )
              ),
              const SizedBox(width: 10),
              GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(radius: 20, backgroundColor: widget.isGlobal ? Colors.amber : Colors.redAccent, child: const Icon(Icons.send, color: Colors.black, size: 18))
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
        showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)));
        await playerProv.getPlayerById(uid);
        if (context.mounted) {
          Navigator.pop(context);
          _openPlayerProfile(context, uid, name, picUrl, isVIP);
        }
      },
      child: Container(
          width: 35, height: 35,
          decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle, border: isVIP ? Border.all(color: Colors.amberAccent, width: 1.5) : null),
          child: CircleAvatar(backgroundColor: Colors.transparent, backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null, child: imageBytes == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, color: isVIP ? Colors.amber : Colors.white54, size: 18) : null)
      ),
    );
  }
}