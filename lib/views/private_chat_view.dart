// المسار: lib/views/private_chat_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../providers/player_provider.dart';
import '../widgets/top_bar.dart';
import 'player_profile_view.dart';

class PrivateChatView extends StatefulWidget {
  final String targetUid;
  final String targetName;
  final String? targetPicUrl;

  const PrivateChatView({super.key, required this.targetUid, required this.targetName, this.targetPicUrl});

  @override
  State<PrivateChatView> createState() => _PrivateChatViewState();
}

class _PrivateChatViewState extends State<PrivateChatView> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String chatId;
  bool _isBurnMessage = false;

  @override
  void initState() {
    super.initState();
    final myUid = Provider.of<PlayerProvider>(context, listen: false).uid!;
    chatId = myUid.compareTo(widget.targetUid) > 0 ? '${myUid}_${widget.targetUid}' : '${widget.targetUid}_$myUid';
  }

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  void _sendMessage({String type = 'text', int? amount}) async {
    String msgText = _controller.text.trim();
    if (type == 'text' && msgText.isEmpty) return;

    final myUid = Provider.of<PlayerProvider>(context, listen: false).uid!;
    _controller.clear();

    final chatRef = _firestore.collection('private_chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    Map<String, dynamic> messageData = {
      'senderId': myUid,
      'type': type,
      'message': type == 'transfer' ? 'قام بتحويل ${_formatWithCommas(amount ?? 0)}\$ 💸' : msgText,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'isBurn': _isBurnMessage,
    };

    if (type == 'transfer') messageData['amount'] = amount;

    await msgRef.set(messageData);

    await chatRef.set({
      'participants': [myUid, widget.targetUid],
      'lastMessage': type == 'transfer' ? 'تحويل مالي 💸' : (_isBurnMessage ? '💣 رسالة سرية' : msgText),
      'timestamp': FieldValue.serverTimestamp(),
      'unread_${widget.targetUid}': FieldValue.increment(1),
      'unread_$myUid': 0,
    }, SetOptions(merge: true));

    if (mounted) setState(() => _isBurnMessage = false);
  }

  void _quickTransfer() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    showDialog(
        context: context,
        builder: (c) {
          TextEditingController amtCtrl = TextEditingController();
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('تحويل سريع 💸', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الكاش المتاح: ${_formatWithCommas(player.cash)}\$', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 15)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Changa'),
                    decoration: const InputDecoration(hintText: 'المبلغ..', filled: true, fillColor: Colors.black45),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Changa', color: Colors.white54))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: () async {
                    int? amt = int.tryParse(amtCtrl.text.trim());
                    if (amt != null && amt > 0 && amt <= player.cash) {
                      try {
                        await _firestore.runTransaction((transaction) async {
                          final senderRef = _firestore.collection('players').doc(player.uid);
                          final receiverRef = _firestore.collection('players').doc(widget.targetUid);

                          final senderSnap = await transaction.get(senderRef);
                          final receiverSnap = await transaction.get(receiverRef);

                          if (!senderSnap.exists || !receiverSnap.exists) throw Exception("اللاعب غير موجود!");
                          int senderCash = senderSnap.data()?['cash'] ?? 0;
                          if (senderCash < amt) throw Exception("رصيدك لا يكفي!");
                          int receiverCash = receiverSnap.data()?['cash'] ?? 0;

                          transaction.update(senderRef, {'cash': senderCash - amt});

                          List<dynamic> receiverTxs = receiverSnap.data()?['transactions'] ?? [];
                          receiverTxs.insert(0, {
                            'title': 'تحويل من ${player.playerName}',
                            'amount': amt,
                            'date': DateTime.now().toIso8601String(),
                            'isPositive': true,
                            'senderUid': player.uid,
                          });
                          if (receiverTxs.length > 20) receiverTxs.removeLast();

                          transaction.update(receiverRef, {
                            'cash': receiverCash + amt,
                            'transactions': receiverTxs,
                          });
                        });

                        player.removeCash(amt, reason: 'تحويل سريع لـ ${widget.targetName}');
                        _sendMessage(type: 'transfer', amount: amt);
                        if (mounted) Navigator.pop(c);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل التحويل!')));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرصيد غير كافي!')));
                    }
                  },
                  child: const Text('أرسل', style: TextStyle(color: Colors.black, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }
    );
  }

  void _goToProfile(Map<String, dynamic> targetData) {
    FocusScope.of(context).unfocus();
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
                            cash: player.cash, gold: player.gold, energy: player.energy, maxEnergy: player.maxEnergy, courage: player.courage, maxCourage: player.maxCourage, health: player.health, maxHealth: player.maxHealth, prestige: player.prestige, maxPrestige: player.maxPrestige, playerName: player.playerName, profilePicUrl: player.profilePicUrl, level: player.crimeLevel, currentXp: player.crimeXP, maxXp: player.xpToNextLevel, isVIP: player.isVIP
                        ),
                        Expanded(child: PlayerProfileView(
                            targetUid: widget.targetUid,
                            previewName: targetData['playerName'] ?? widget.targetName,
                            previewPicUrl: targetData['profilePicUrl'] ?? widget.targetPicUrl,
                            previewIsVIP: targetData['isVIP'] ?? false,
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

  @override
  Widget build(BuildContext context) {
    final myUid = Provider.of<PlayerProvider>(context, listen: false).uid!;

    _firestore.collection('private_chats').doc(chatId).set({'unread_$myUid': 0}, SetOptions(merge: true));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1D),
          appBar: AppBar(
            backgroundColor: Colors.black87,
            titleSpacing: 0,
            // 🟢 التعديل هنا: زر الرجوع أصبح في اليمين (مدمج مع الصورة) نفس الواتساب 🟢
            leadingWidth: 40,
            leading: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.amber, size: 22),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
              },
            ),
            title: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('players').doc(widget.targetUid).snapshots(),
              builder: (context, snapshot) {
                String name = widget.targetName;
                String? pic = widget.targetPicUrl;
                String bio = '';
                bool isVIP = false;
                String statusText = 'غير متصل';
                Color statusColor = Colors.white54;
                Map<String, dynamic> targetData = {};

                if (snapshot.hasData && snapshot.data!.exists) {
                  targetData = snapshot.data!.data() as Map<String, dynamic>;
                  name = targetData['playerName'] ?? name;
                  pic = targetData['profilePicUrl'] ?? pic;
                  bio = targetData['bio'] ?? '';
                  isVIP = targetData['isVIP'] == true;

                  if (targetData['lastUpdate'] != null) {
                    DateTime lastUpdate = (targetData['lastUpdate'] as Timestamp).toDate();
                    final diff = DateTime.now().difference(lastUpdate);

                    if (diff.inMinutes <= 1) {
                      statusText = 'متصل الآن';
                      statusColor = Colors.greenAccent;
                    } else if (diff.inHours < 1) {
                      statusText = 'آخر ظهور منذ ${diff.inMinutes} دقيقة';
                    } else if (diff.inDays < 1) {
                      statusText = 'آخر ظهور منذ ${diff.inHours} ساعة';
                    } else {
                      statusText = 'آخر ظهور منذ ${diff.inDays} يوم';
                    }
                  }
                }

                final imageBytes = Provider.of<PlayerProvider>(context, listen: false).getDecodedImage(pic);

                return GestureDetector(
                  onTap: () => _goToProfile(targetData),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isVIP ? Border.all(color: Colors.amberAccent, width: 1.5) : null,
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                          child: imageBytes == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, color: isVIP ? Colors.amber : Colors.white54, size: 20) : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (bio.isNotEmpty)
                              Text(bio, style: const TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(statusText, style: TextStyle(color: statusColor, fontFamily: 'Changa', fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('private_chats').doc(chatId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final msgs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final doc = msgs[index];
                        final msg = doc.data() as Map<String, dynamic>;
                        bool isMe = msg['senderId'] == myUid;
                        bool isRead = msg['isRead'] ?? false;
                        bool isBurn = msg['isBurn'] ?? false;
                        String type = msg['type'] ?? 'text';

                        if (!isMe && !isRead) {
                          doc.reference.update({'isRead': true});
                        }

                        if (isBurn) {
                          return BurnMessageBubble(
                            message: msg['message'],
                            isMe: isMe,
                            isRead: isRead,
                            docRef: doc.reference,
                          );
                        }

                        if (type == 'transfer') {
                          int amount = msg['amount'] ?? 0;
                          String formattedAmount = _formatWithCommas(amount);

                          String transferMsg = isMe ? 'قمت بتحويل $formattedAmount\$ 💸' : 'قام ${widget.targetName} بتحويل $formattedAmount\$ 💸';

                          return TransferBubble(message: transferMsg, isMe: isMe);
                        }

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.green[900] : Colors.grey[800],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(msg['message'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                                if (isMe) ...[
                                  const SizedBox(height: 2),
                                  Icon(Icons.done_all, size: 14, color: isRead ? Colors.lightBlueAccent : Colors.white54),
                                ]
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
                decoration: const BoxDecoration(color: Colors.black26),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.local_fire_department, color: _isBurnMessage ? Colors.redAccent : Colors.white54),
                      onPressed: () {
                        setState(() => _isBurnMessage = !_isBurnMessage);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isBurnMessage ? '💣 تم تفعيل وضع الرسائل القابلة للتدمير' : 'تم إيقاف وضع التدمير'), duration: const Duration(seconds: 1)));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_money, color: Colors.green),
                      onPressed: _quickTransfer,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _isBurnMessage ? 'اكتب رسالة سرية لتدميرها...' : 'رسالة...',
                          hintStyle: TextStyle(color: _isBurnMessage ? Colors.redAccent : Colors.white54),
                          filled: true,
                          fillColor: Colors.black45,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.amber),
                      onPressed: () => _sendMessage(),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class BurnMessageBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final bool isRead;
  final DocumentReference docRef;

  const BurnMessageBubble({super.key, required this.message, required this.isMe, required this.isRead, required this.docRef});

  @override
  State<BurnMessageBubble> createState() => _BurnMessageBubbleState();
}

class _BurnMessageBubbleState extends State<BurnMessageBubble> {
  int secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isRead) _startCountdown();
  }

  @override
  void didUpdateWidget(covariant BurnMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isRead && widget.isRead) _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => secondsLeft--);
        if (secondsLeft <= 0) {
          timer.cancel();
          widget.docRef.delete();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.red[900], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.whatshot, color: Colors.orangeAccent, size: 18),
                const SizedBox(width: 5),
                Text(widget.message, style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic)),
              ],
            ),
            if (widget.isRead)
              Text('تنفجر بعد: $secondsLeft ثواني', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            if (widget.isMe) Icon(Icons.done_all, size: 14, color: widget.isRead ? Colors.lightBlueAccent : Colors.white54),
          ],
        ),
      ),
    );
  }
}

class TransferBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const TransferBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)),
        child: Text(message, style: const TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }
}