import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import 'private_chat_view.dart';

class PlayerProfileView extends StatefulWidget {
  final String targetUid;
  final VoidCallback? onBack;
  final int profileTabIndex;

  const PlayerProfileView({super.key, required this.targetUid, this.onBack, this.profileTabIndex = 0});

  @override
  State<PlayerProfileView> createState() => _PlayerProfileViewState();
}

class _PlayerProfileViewState extends State<PlayerProfileView> {
  Map<String, dynamic>? playerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final data = await player.getPlayerById(widget.targetUid);
    if (mounted) {
      setState(() {
        playerData = data;
        isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context);

    if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    if (playerData == null) return const Center(child: Text("اللاعب غير موجود!", style: TextStyle(color: Colors.white)));

    bool isMe = widget.targetUid == player.uid;
    bool isVIP = playerData!['isVIP'] == true;

    // [تعديل] استخدام الكاش المركزي للصور والخلفية
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
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isVIP ? Colors.amber.withValues(alpha: 0.4) : Colors.white10),
                  image: backgroundPicData != null ? DecorationImage(image: MemoryImage(backgroundPicData), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken)) : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: isMe ? () => _pickImage(player) : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFF212121), shape: BoxShape.circle, border: isVIP ? Border.all(color: Colors.amberAccent, width: 3) : null, boxShadow: isVIP ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 2)] : [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)]),
                            child: CircleAvatar(radius: 40, backgroundColor: Colors.grey[800], backgroundImage: profilePicData != null ? MemoryImage(profilePicData) : null, child: profilePicData == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, size: 45, color: isVIP ? Colors.amber : Colors.white54) : null),
                          ),
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
                          const SizedBox(height: 5),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))), child: Text(playerData!['gangName'] != null ? 'عصابة: ${playerData!['gangName']}' : 'ذئب وحيد', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    if (isMe) GestureDetector(onTap: () => _pickBackgroundImage(player), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: const Icon(Icons.wallpaper, color: Colors.white, size: 18))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          // 2. البايو
          GestureDetector(
            onTap: isMe ? () => _editBio(player) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(color: isMe ? Colors.white.withValues(alpha: 0.05) : Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: isMe ? Colors.amber.withValues(alpha: 0.3) : Colors.white10)),
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

          // 3. الإحصائيات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProfileStat('الساحة', '${playerData!['arenaLevel'] ?? 1}', Icons.shield, Colors.redAccent),
                  _buildProfileStat('الإجرام', '${playerData!['crimeLevel'] ?? 1}', Icons.local_police, Colors.blueAccent),
                  _buildProfileStat('العمل', '${playerData!['workLevel'] ?? 1}', Icons.work, Colors.green),
                  _buildProfileStat('السمعة', '${playerData!['creditScore'] ?? 0}', Icons.star, Colors.amber),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // 4. أزرار التفاعل (للاعبين الآخرين) أو التبويبات (لك)
          if (!isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
                children: [
                  _buildActionBtn(Icons.person_add, 'إضافة', Colors.blue, () {}),
                  _buildActionBtn(Icons.chat, 'مراسلة', Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatView(targetUid: widget.targetUid, targetName: playerData!['playerName'] ?? 'مجهول', targetPicUrl: playerData!['profilePicUrl'])));
                  }),
                  _buildActionBtn(Icons.my_location, 'هجوم', Colors.red, () {}),
                  _buildActionBtn(Icons.attach_money, 'تحويل', Colors.amber, () {}),
                  _buildActionBtn(Icons.group, 'العصابة', Colors.deepPurpleAccent, () {}),
                  _buildActionBtn(Icons.card_giftcard, 'هدية', Colors.pinkAccent, () {}),
                  _buildActionBtn(Icons.favorite, 'زواج', Colors.redAccent, () {}),
                  _buildActionBtn(Icons.block, 'حظر', Colors.grey, () {}),
                ],
              ),
            )
          else ...[
            if (widget.profileTabIndex == 0)
              _buildChatList(player.uid!)
            else if (widget.profileTabIndex == 1)
              _buildPlaceholder("قائمة الأصدقاء ستظهر هنا قريباً 👥")
            else if (widget.profileTabIndex == 2)
                _buildPlaceholder("شجرة المهارات ستظهر هنا قريباً 🧠")
              else if (widget.profileTabIndex == 3)
                  _buildPlaceholder("مستودع التسليح سيظهر هنا قريباً 🔫"),

            const SizedBox(height: 20),

            if (player.heat > 0) Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withValues(alpha:0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.local_police, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text("مستوى الملاحقة", style: TextStyle(color: Colors.white70))]), Text("${player.heat.toInt()}%", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: audio.isMuted ? Colors.redAccent.withValues(alpha:0.2) : Colors.green.withValues(alpha:0.2), side: BorderSide(color: audio.isMuted ? Colors.redAccent : Colors.green), minimumSize: const Size(double.infinity, 50)), onPressed: () => audio.toggleMute(), icon: Icon(audio.isMuted ? Icons.volume_off : Icons.volume_up, color: audio.isMuted ? Colors.redAccent : Colors.green), label: Text(audio.isMuted ? "تشغيل الصوت" : "كتم الصوت", style: TextStyle(color: audio.isMuted ? Colors.redAccent : Colors.green))), const SizedBox(height: 15), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha:0.2), side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 50)), onPressed: () { audio.playEffect('click.mp3'); _showResetConfirmation(player); }, icon: const Icon(Icons.delete_forever, color: Colors.red), label: const Text("مسح البيانات", style: TextStyle(color: Colors.red)))])),
          ],

          const SizedBox(height: 30),
          Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 20, bottom: 30), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Icons.arrow_back, color: Colors.white), label: const Text('رجوع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), onPressed: widget.onBack ?? () => Navigator.pop(context)))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(35),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 16), textAlign: TextAlign.center))
    );
  }

  Widget _buildChatList(String myUid) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 350,
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('private_chats').where('participants', arrayContains: myUid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد رسائل خاصة..", style: TextStyle(color: Colors.white54)));

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
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              List parts = chatData['participants'] ?? [];
              String targetUid = parts.firstWhere((id) => id != myUid, orElse: () => '');
              int unreadCount = chatData['unread_$myUid'] ?? 0;
              String lastMessage = chatData['lastMessage'] ?? '';

              if (targetUid.isEmpty) return const SizedBox();

              return FutureBuilder<Map<String, dynamic>?>(
                future: Provider.of<PlayerProvider>(context, listen: false).getPlayerById(targetUid),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();
                  final targetData = userSnap.data!;
                  String targetName = targetData['playerName'] ?? 'مجهول';
                  String? targetPic = targetData['profilePicUrl'];

                  // [تعديل] استخدام الكاش لصور قائمة الدردشات
                  final imageBytes = Provider.of<PlayerProvider>(context, listen: false).getDecodedImage(targetPic);

                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatView(targetUid: targetUid, targetName: targetName, targetPicUrl: targetPic)));
                      },
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(backgroundColor: Colors.grey[800], backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null, child: imageBytes == null ? const Icon(Icons.person, color: Colors.white54) : null),
                          if (unreadCount > 0)
                            Positioned(
                                top: -5,
                                left: -5,
                                child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                )
                            ),
                        ],
                      ),
                      title: Text(targetName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(lastMessage, style: TextStyle(color: unreadCount > 0 ? Colors.white : Colors.white54, fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileStat(String label, String val, IconData icon, Color color) { return Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 6), Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]); }
  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) { return GestureDetector(onTap: onTap, child: SizedBox(width: 75, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha:0.15), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha:0.5))), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 6), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]))); }
}