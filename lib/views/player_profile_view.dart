// المسار: lib/views/player_profile_view.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import 'private_chat_view.dart';
import 'pvp_battle_view.dart';

class PlayerProfileView extends StatefulWidget {
  final String targetUid;
  final VoidCallback? onBack;
  final int profileTabIndex;

  final String? previewName;
  final String? previewPicUrl;
  final bool? previewIsVIP;

  const PlayerProfileView({
    super.key,
    required this.targetUid,
    this.onBack,
    this.profileTabIndex = 0,
    this.previewName,
    this.previewPicUrl,
    this.previewIsVIP,
  });

  @override
  State<PlayerProfileView> createState() => _PlayerProfileViewState();
}

class _PlayerProfileViewState extends State<PlayerProfileView> {
  Map<String, dynamic>? playerData;

  @override
  void initState() {
    super.initState();

    final player = Provider.of<PlayerProvider>(context, listen: false);
    bool isMe = widget.targetUid == player.uid;

    if (isMe) {
      playerData = {
        'playerName': player.playerName,
        'gameId': player.gameId,
        'profilePicUrl': player.profilePicUrl,
        'backgroundPicUrl': player.backgroundPicUrl,
        'isVIP': player.isVIP,
        'bio': player.bio,
        'arenaLevel': player.arenaLevel,
        'crimeLevel': player.crimeLevel,
        'workLevel': player.workLevel,
        'creditScore': player.creditScore,
        'gangName': player.gangName,
        'currentCity': player.currentCity,
      };
    } else {
      playerData = {
        'playerName': widget.previewName ?? 'جاري التحميل...',
        'gameId': '---',
        'profilePicUrl': widget.previewPicUrl,
        'backgroundPicUrl': null,
        'isVIP': widget.previewIsVIP ?? false,
        'bio': 'جاري تحديث البيانات...',
        'arenaLevel': 0,
        'crimeLevel': 0,
        'workLevel': 0,
        'creditScore': 0,
        'currentCity': 'ملاذ',
      };
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final data = await player.getPlayerById(widget.targetUid);
    if (mounted && data != null) {
      setState(() {
        playerData = data;
      });
    }
  }

  Future<void> _pickImage(PlayerProvider player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() {
        if (playerData != null) playerData!['profilePicUrl'] = base64Str;
      });
      player.updateProfilePic(base64Str);
    }
  }

  Future<void> _pickBackgroundImage(PlayerProvider player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Str = base64Encode(bytes);
      player.updateBackgroundPic(base64Str);
      setState(() {
        if (playerData != null) playerData!['backgroundPicUrl'] = base64Str;
      });
    }
  }

  void _editBio(PlayerProvider player) {
    TextEditingController bioController = TextEditingController(text: playerData!['bio'] ?? '');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('تعديل البايو ✍️', style: TextStyle(color: Colors.amber), textAlign: TextAlign.right),
        content: TextField(
          controller: bioController,
          maxLength: 100,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'اكتب وصفك هنا...', hintStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              player.updateBio(bioController.text.trim());
              setState(() => playerData!['bio'] = bioController.text.trim());
              Navigator.pop(c);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(PlayerProvider player) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: Colors.grey[900], title: const Text("تحذير نهائي ⚠️", style: TextStyle(color: Colors.white), textAlign: TextAlign.right), content: const Text("هل أنت متأكد من مسح كافة بياناتك؟ لا يمكن التراجع.", style: TextStyle(color: Colors.white70), textAlign: TextAlign.right), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.blue))), TextButton(onPressed: () { player.resetPlayerData(); Navigator.pop(context); }, child: const Text("نعم، امسح كل شيء", style: TextStyle(color: Colors.red)))]));
  }

  void _showTransferDialog(PlayerProvider player) {
    TextEditingController amountController = TextEditingController();
    bool isTransferring = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 2)),
              title: const Text('تحويل كاش 💸', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الرصيد المتاح: \$${player.cash}', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 16)),
                  const SizedBox(height: 15),
                  TextField(controller: amountController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontFamily: 'Changa'), textAlign: TextAlign.center, decoration: InputDecoration(hintText: 'أدخل المبلغ هنا...', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.amber)))),
                  if (isTransferring) ...[const SizedBox(height: 20), const CircularProgressIndicator(color: Colors.amber)]
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(onPressed: isTransferring ? null : () => Navigator.pop(c), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa'))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: isTransferring ? null : () async {
                    int? amount = int.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح!'), backgroundColor: Colors.redAccent)); return; }
                    if (amount > player.cash) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيدك لا يكفي!'), backgroundColor: Colors.redAccent)); return; }
                    setDialogState(() => isTransferring = true);
                    try {
                      final firestore = FirebaseFirestore.instance;
                      await firestore.runTransaction((transaction) async {
                        final senderRef = firestore.collection('players').doc(player.uid);
                        final receiverRef = firestore.collection('players').doc(widget.targetUid);

                        final senderSnap = await transaction.get(senderRef);
                        final receiverSnap = await transaction.get(receiverRef);

                        if (!senderSnap.exists || !receiverSnap.exists) throw Exception("اللاعب غير موجود!");
                        int senderCash = senderSnap.data()?['cash'] ?? 0;
                        if (senderCash < amount) throw Exception("رصيدك لا يكفي!");
                        int receiverCash = receiverSnap.data()?['cash'] ?? 0;

                        transaction.update(senderRef, {'cash': senderCash - amount});

                        List<dynamic> receiverTxs = receiverSnap.data()?['transactions'] ?? [];
                        receiverTxs.insert(0, {
                          'title': 'تحويل من ${player.playerName}',
                          'amount': amount,
                          'date': DateTime.now().toIso8601String(),
                          'isPositive': true,
                          'senderUid': player.uid,
                        });
                        if (receiverTxs.length > 20) receiverTxs.removeLast();

                        transaction.update(receiverRef, {
                          'cash': receiverCash + amount,
                          'transactions': receiverTxs
                        });
                      });

                      player.removeCash(amount, reason: 'تحويل مالي إلى ${playerData!['playerName']}');
                      if (mounted) { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحويل \$$amount بنجاح! 💸'), backgroundColor: Colors.green)); Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3'); }
                    } catch (e) {
                      setDialogState(() => isTransferring = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التحويل!'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('تأكيد التحويل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                ),
              ],
            );
          }
      ),
    );
  }

  void _showBountyDialog(PlayerProvider player) {
    TextEditingController amountController = TextEditingController();
    bool isAnonymous = false;
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.deepOrange, width: 2),
              ),
              title: const Text('وضع مكافأة 🎯', style: TextStyle(color: Colors.deepOrange, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('سيتم نشر إعلان في شات المدينة لكل اللاعبين للهجوم على هذا الهدف.', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  Text('الكاش المتاح: \$${player.cash}', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 13)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Changa'),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'مبلغ المكافأة...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black45,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepOrange)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withOpacity(0.5))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.visibility_off, color: Colors.amber, size: 18),
                            SizedBox(width: 5),
                            Text('إخفاء الاسم (5 ذهب)', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 12)),
                          ],
                        ),
                        Switch(
                          value: isAnonymous,
                          activeColor: Colors.amber,
                          onChanged: (val) {
                            setDialogState(() => isAnonymous = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Colors.deepOrange),
                  ]
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                    onPressed: isProcessing ? null : () => Navigator.pop(c),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa'))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: isProcessing ? null : () async {
                    int? amount = int.tryParse(amountController.text.trim());
                    if (amount == null || amount < 1000) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أقل مبلغ للمكافأة هو 1000!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
                      return;
                    }
                    if (amount > player.cash) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيدك لا يكفي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
                      return;
                    }
                    if (isAnonymous && player.gold < 5) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافي لإخفاء هويتك!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
                      return;
                    }

                    setDialogState(() => isProcessing = true);

                    try {
                      player.removeCash(amount, reason: 'إعلان مكافأة على ${playerData!['playerName']}');
                      if (isAnonymous) player.removeGold(5);

                      await FirebaseFirestore.instance.collection('chat').add({
                        'type': 'bounty',
                        'senderUid': player.uid,
                        'senderName': isAnonymous ? 'شخص مجهول 🕵️‍♂️' : player.playerName,
                        'targetUid': widget.targetUid,
                        'targetName': playerData!['playerName'],
                        'targetPicUrl': playerData!['profilePicUrl'],
                        'amount': amount,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      if (mounted) {
                        Navigator.pop(c);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المكافأة في المدينة بنجاح! 🚨', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                        Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                      }
                    } catch (e) {
                      setDialogState(() => isProcessing = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء النشر!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('نشر الإعلان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context);

    if (playerData == null) return const Center(child: CircularProgressIndicator(color: Colors.amber));

    bool isMe = widget.targetUid == player.uid;
    bool isVIP = playerData!['isVIP'] == true;

    Uint8List? profilePicData = player.getDecodedImage(isMe ? player.profilePicUrl : playerData!['profilePicUrl']);
    Uint8List? backgroundPicData = player.getDecodedImage(isMe ? player.backgroundPicUrl : playerData!['backgroundPicUrl']);

    bool isOnline = false;
    if (isMe) {
      isOnline = true;
    } else if (playerData!['lastUpdate'] != null) {
      DateTime lastUpdate = (playerData!['lastUpdate'] as Timestamp).toDate();
      if (DateTime.now().difference(lastUpdate).inMinutes < 5) isOnline = true;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // 1. الترويسة
          GestureDetector(
            onLongPress: isMe ? () => _pickBackgroundImage(player) : null,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: isVIP ? Colors.amber.withOpacity(0.4) : Colors.white10), image: backgroundPicData != null ? DecorationImage(image: MemoryImage(backgroundPicData), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken)) : null),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: isMe ? () => _pickImage(player) : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFF212121), shape: BoxShape.circle, border: isVIP ? Border.all(color: Colors.amberAccent, width: 3) : null, boxShadow: isVIP ? [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)] : [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]), child: CircleAvatar(radius: 40, backgroundColor: Colors.grey[800], backgroundImage: profilePicData != null ? MemoryImage(profilePicData) : null, child: profilePicData == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, size: 45, color: isVIP ? Colors.amber : Colors.white54) : null)),
                          Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Color(0xFF1A1A1D), shape: BoxShape.circle), child: CircleAvatar(radius: 7, backgroundColor: isOnline ? Colors.greenAccent : Colors.redAccent))),
                          if (isMe) const Positioned(top: 0, left: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.amber, child: Icon(Icons.camera_alt, size: 14, color: Colors.black)))
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [if (isVIP) const Icon(Icons.workspace_premium, color: Colors.amber, size: 24), if (isVIP) const SizedBox(width: 5), Flexible(child: Text(playerData!['playerName'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]), overflow: TextOverflow.ellipsis))]),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withOpacity(0.5))), child: Text(playerData!['gangName'] != null ? 'عصابة: ${playerData!['gangName']}' : 'ذئب وحيد', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.withOpacity(0.4))), child: Text('ID: ${playerData!['gameId'] ?? '------'}', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.withOpacity(0.4))), child: Text('📍 ${playerData!['currentCity'] ?? 'ملاذ'}', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isMe) GestureDetector(onTap: () => _pickBackgroundImage(player), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: const Icon(Icons.wallpaper, color: Colors.white, size: 18))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (playerData!['isHospitalized'] == true)
            Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.5))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.local_hospital, color: Colors.redAccent), SizedBox(width: 8), Text('هذا اللاعب يتعالج في المستشفى حالياً 🏥', style: TextStyle(color: Colors.redAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold))])),
          if (playerData!['isInPrison'] == true)
            Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.5))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock, color: Colors.grey), SizedBox(width: 8), Text('هذا اللاعب يقضي عقوبة في السجن 🔒', style: TextStyle(color: Colors.grey, fontFamily: 'Changa', fontWeight: FontWeight.bold))])),

          const SizedBox(height: 15),

          // 2. البايو
          GestureDetector(
            onTap: isMe ? () => _editBio(player) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(0.05) : Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: isMe ? Colors.amber.withOpacity(0.3) : Colors.white10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [if (isMe) const Icon(Icons.edit, color: Colors.amber, size: 16), if (isMe) const SizedBox(width: 5), const Text('البايو (الوصف):', style: TextStyle(color: Colors.white54, fontSize: 12))]),
                  const SizedBox(height: 10),
                  Text(playerData!['bio'] ?? 'لا يوجد وصف حالياً...', style: const TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic), textAlign: TextAlign.right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // 3. الإحصائيات العامة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProfileStat('الساحة', '${playerData!['arenaLevel'] ?? 0}', Icons.shield, Colors.redAccent),
                  _buildProfileStat('الإجرام', '${playerData!['crimeLevel'] ?? 0}', Icons.local_police, Colors.blueAccent),
                  _buildProfileStat('العمل', '${playerData!['workLevel'] ?? 0}', Icons.work, Colors.green),
                  _buildProfileStat('السمعة', '${playerData!['creditScore'] ?? 0}', Icons.star, Colors.amber),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          if (isMe) ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Align(alignment: Alignment.centerRight, child: Text("الإحصائيات القتالية ⚔️", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)))),
            const SizedBox(height: 10),
            Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Directionality(textDirection: TextDirection.rtl, child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildCombatStat("القوة", player.strength, Icons.fitness_center, Colors.redAccent), _buildCombatStat("السرعة", player.speed, Icons.speed, Colors.orangeAccent)]), const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildCombatStat("الدفاع", player.defense, Icons.shield, Colors.blueAccent), _buildCombatStat("المهارة", player.skill, Icons.psychology, Colors.greenAccent)])]))),
            const SizedBox(height: 25),
          ],

          // 4. الأزرار السفلية
          if (!isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
                children: [
                  _buildActionBtn(Icons.person_add, 'إضافة', Colors.blue, () => player.sendFriendRequest(widget.targetUid)),
                  _buildActionBtn(Icons.chat, 'مراسلة', Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatView(targetUid: widget.targetUid, targetName: playerData!['playerName'] ?? 'مجهول', targetPicUrl: playerData!['profilePicUrl'])));
                  }),
                  _buildActionBtn(Icons.my_location, 'هجوم', Colors.red, () {
                    if (!playerData!.containsKey('uid') || playerData!['uid'] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري التحميل...')));
                      return;
                    }

                    bool isHosp = playerData!['isHospitalized'] == true;
                    bool isPris = playerData!['isInPrison'] == true;
                    String targetCity = playerData!['currentCity'] ?? 'ملاذ';

                    if (isHosp) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب في المستشفى 🏥، لا يمكنك الهجوم عليه!', style: TextStyle(fontFamily: 'Changa'))));
                      return;
                    }
                    if (isPris) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب يقبع في السجن 🔒، لا يمكنك الوصول إليه!', style: TextStyle(fontFamily: 'Changa'))));
                      return;
                    }
                    if (player.currentCity != targetCity) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أنت في ${player.currentCity} والهدف في $targetCity ✈️! يجب أن تسافر إليه أولاً.', style: const TextStyle(fontFamily: 'Changa'))));
                      return;
                    }

                    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, body: SafeArea(child: PvpBattleView(enemyData: playerData!, onBack: () => Navigator.pop(context))))));
                  }),
                  _buildActionBtn(Icons.attach_money, 'تحويل', Colors.amber, () => _showTransferDialog(player)),
                  _buildActionBtn(Icons.track_changes, 'مكافأة', Colors.deepOrange, () => _showBountyDialog(player)),
                  _buildActionBtn(Icons.card_giftcard, 'هدية', Colors.pinkAccent, () {}),
                  _buildActionBtn(Icons.favorite, 'زواج', Colors.redAccent, () {}),
                  _buildActionBtn(Icons.block, 'حظر', Colors.grey, () {}),
                ],
              ),
            )
          else ...[
            if (widget.profileTabIndex == 0)
              _buildPlaceholder("قائمة الأصدقاء ستظهر هنا قريباً 👥")
            else if (widget.profileTabIndex == 1)
              _buildPlaceholder("شجرة المهارات ستظهر هنا قريباً 🧠")
            else if (widget.profileTabIndex == 2)
                _buildPlaceholder("مستودع التسليح سيظهر هنا قريباً 🔫"),

            const SizedBox(height: 20),

            if (player.heat > 0) Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withOpacity(0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.local_police, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text("مستوى الملاحقة", style: TextStyle(color: Colors.white70))]), Text("${player.heat.toInt()}%", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))])),

            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: audio.isMuted ? Colors.redAccent.withOpacity(0.2) : Colors.green.withOpacity(0.2), side: BorderSide(color: audio.isMuted ? Colors.redAccent : Colors.green), minimumSize: const Size(double.infinity, 50)), onPressed: () => audio.toggleMute(), icon: Icon(audio.isMuted ? Icons.volume_off : Icons.volume_up, color: audio.isMuted ? Colors.redAccent : Colors.green), label: Text(audio.isMuted ? "تشغيل الصوت" : "كتم الصوت", style: TextStyle(color: audio.isMuted ? Colors.redAccent : Colors.green))), const SizedBox(height: 15), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 50)), onPressed: () { audio.playEffect('click.mp3'); _showResetConfirmation(player); }, icon: const Icon(Icons.delete_forever, color: Colors.red), label: const Text("مسح البيانات", style: TextStyle(color: Colors.red)))])),
          ],

          const SizedBox(height: 30),
          Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 20, bottom: 30), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Icons.arrow_back, color: Colors.white), label: const Text('رجوع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), onPressed: widget.onBack ?? () => Navigator.pop(context)))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) { return Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(35), width: double.infinity, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Center(child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 16), textAlign: TextAlign.center))); }
  Widget _buildProfileStat(String label, String val, IconData icon, Color color) { return Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 6), Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]); }
  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) { return GestureDetector(onTap: onTap, child: SizedBox(width: 75, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 6), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]))); }
  Widget _buildCombatStat(String label, double val, IconData icon, Color color) { return SizedBox(width: 130, child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)), Text(val.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))])])); }
}