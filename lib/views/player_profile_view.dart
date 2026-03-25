import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

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

  // [الدايموند 💎] دالة اختيار الصورة
  Future<void> _pickImage(PlayerProvider player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Str = base64Encode(bytes);
      player.updateProfilePic(base64Str);
      setState(() {
        playerData!['profilePicUrl'] = base64Str;
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
    String? profilePicStr = playerData!['profilePicUrl'];

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

          // 1. الترويسة العلوية (الصورة والاسم يمين بجانب بعض متراصين)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isVIP) const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                        if (isVIP) const SizedBox(width: 5),
                        Text(playerData!['playerName'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                      child: Text(playerData!['gangName'] != null ? 'عصابة: ${playerData!['gangName']}' : 'ذئب وحيد', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(width: 15),

                // الصورة مع مؤشر الاتصال والـ VIP
                GestureDetector(
                  onTap: isMe ? () => _pickImage(player) : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF212121),
                            shape: BoxShape.circle,
                            border: Border.all(color: isVIP ? Colors.amber : Colors.transparent, width: isVIP ? 3 : 0), // الإطار الذهبي للـ VIP
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)]
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: profilePicStr != null ? MemoryImage(base64Decode(profilePicStr)) : null,
                          child: profilePicStr == null
                              ? Icon(isVIP ? Icons.workspace_premium : Icons.person, size: 45, color: isVIP ? Colors.amber : Colors.white54)
                              : null,
                        ),
                      ),
                      // الدائرة الخضراء/الحمراء
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Color(0xFF1A1A1D), shape: BoxShape.circle), child: CircleAvatar(radius: 7, backgroundColor: isOnline ? Colors.greenAccent : Colors.redAccent)),
                      ),
                      // أيقونة تعديل الصورة لحسابك
                      if (isMe)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: CircleAvatar(radius: 12, backgroundColor: Colors.amber, child: Icon(Icons.camera_alt, size: 14, color: Colors.black)),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // 2. البايو (كامل المربع قابل للضغط)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isMe) const Icon(Icons.edit, color: Colors.amber, size: 16),
                      if (isMe) const SizedBox(width: 5),
                      const Text('البايو (الوصف):', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(playerData!['bio'] ?? 'لا يوجد وصف حالياً...', style: const TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic), textAlign: TextAlign.right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // 3. الإحصائيات السريعة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
          const SizedBox(height: 30),

          // 4. القوائم أو الأزرار
          if (!isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
                children: [
                  _buildActionBtn(Icons.person_add, 'إضافة', Colors.blue, () { }),
                  _buildActionBtn(Icons.chat, 'مراسلة', Colors.green, () { }),
                  _buildActionBtn(Icons.my_location, 'هجوم', Colors.red, () { }),
                  _buildActionBtn(Icons.attach_money, 'تحويل', Colors.amber, () { }),
                  _buildActionBtn(Icons.group, 'العصابة', Colors.deepPurpleAccent, () { }),
                  _buildActionBtn(Icons.card_giftcard, 'هدية', Colors.pinkAccent, () { }),
                  _buildActionBtn(Icons.favorite, 'زواج', Colors.redAccent, () { }),
                  _buildActionBtn(Icons.block, 'حظر', Colors.grey, () { }),
                ],
              ),
            )
          else ...[
            Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.all(25), width: double.infinity, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))), child: Center(child: Text(widget.profileTabIndex == 0 ? "قائمة الأصدقاء ستظهر هنا قريباً 👥" : widget.profileTabIndex == 1 ? "شجرة المهارات ستظهر هنا قريباً 🧠" : "مستودع التسليح سيظهر هنا قريباً 🔫", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center))),
            const SizedBox(height: 20),
            if (player.heat > 0) Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withValues(alpha:0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.local_police, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text("مستوى الملاحقة", style: TextStyle(color: Colors.white70))]), Text("${player.heat.toInt()}%", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: audio.isMuted ? Colors.redAccent.withValues(alpha:0.2) : Colors.green.withValues(alpha:0.2), side: BorderSide(color: audio.isMuted ? Colors.redAccent : Colors.green), minimumSize: const Size(double.infinity, 50)), onPressed: () => audio.toggleMute(), icon: Icon(audio.isMuted ? Icons.volume_off : Icons.volume_up, color: audio.isMuted ? Colors.redAccent : Colors.green), label: Text(audio.isMuted ? "تشغيل الصوت" : "كتم الصوت", style: TextStyle(color: audio.isMuted ? Colors.redAccent : Colors.green))), const SizedBox(height: 15), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha:0.2), side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 50)), onPressed: () { audio.playEffect('click.mp3'); _showResetConfirmation(player); }, icon: const Icon(Icons.delete_forever, color: Colors.red), label: const Text("مسح البيانات", style: TextStyle(color: Colors.red)))])),
          ],

          const SizedBox(height: 30),

          // 5. زر الرجوع الأنيق أقصى اليسار تحت
          Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 20, bottom: 30), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Icons.arrow_back, color: Colors.white), label: const Text('رجوع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), onPressed: widget.onBack ?? () => Navigator.pop(context)))),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String val, IconData icon, Color color) { return Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 6), Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]); }
  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) { return GestureDetector(onTap: onTap, child: SizedBox(width: 75, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha:0.15), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha:0.5))), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 6), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]))); }
}