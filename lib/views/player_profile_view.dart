import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class PlayerProfileView extends StatefulWidget {
  final String targetUid;
  final bool showBackButton; // للتحكم بظهور زر الرجوع

  const PlayerProfileView({super.key, required this.targetUid, this.showBackButton = true});

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

  void _editBio(PlayerProvider player) {
    TextEditingController bioController = TextEditingController(text: playerData!['bio'] ?? '');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('تعديل البايو ✍️', style: TextStyle(color: Colors.amber)),
        content: TextField(
          controller: bioController,
          maxLength: 100, // الحد الأقصى للحروف
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'اكتب وصفك هنا (بحد أقصى 100 حرف)...',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
          ),
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
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: Colors.grey[900], title: const Text("تحذير نهائي ⚠️", style: TextStyle(color: Colors.white)), content: const Text("هل أنت متأكد من مسح كافة بياناتك؟ لا يمكن التراجع.", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.blue))), TextButton(onPressed: () { player.resetPlayerData(); Navigator.pop(context); }, child: const Text("نعم، امسح كل شيء", style: TextStyle(color: Colors.red)))]));
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    if (playerData == null) {
      return const Center(child: Text("اللاعب غير موجود!", style: TextStyle(color: Colors.white)));
    }

    bool isMe = widget.targetUid == player.uid;
    bool isVIP = playerData!['isVIP'] == true;

    return Directionality(
      textDirection: TextDirection.rtl, // إجبار الواجهة على اليمين
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 1. الغلاف والصورة (صورة البروفايل أقصى اليمين)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 160,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF000000)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                ),
                if (widget.showBackButton)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                Positioned(
                  bottom: -45,
                  right: 20, // الصورة أقصى اليمين
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: const Color(0xFF212121), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 10)]),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: isVIP ? Colors.amber : Colors.grey[800],
                      child: Icon(isVIP ? Icons.workspace_premium : Icons.person, size: 50, color: isVIP ? Colors.black : Colors.white54),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 55),

            // 2. الاسم والعصابة (محاذاة لليمين)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // يبدأ من اليمين بسبب الـ RTL
                  children: [
                    Row(
                      children: [
                        if (isVIP) const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                        if (isVIP) const SizedBox(width: 8),
                        Text(playerData!['playerName'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha:0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withValues(alpha:0.5))),
                      child: Text(playerData!['gangName'] != null ? 'عصابة: ${playerData!['gangName']}' : 'ذئب وحيد', style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // 3. البايو (الوصف الشخصي)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('البايو (الوصف):', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      if (isMe)
                        GestureDetector(onTap: () => _editBio(player), child: const Icon(Icons.edit, color: Colors.amber, size: 20)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(playerData!['bio'] ?? 'لا يوجد وصف حالياً...', style: const TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 4. الإحصائيات السريعة
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
            const SizedBox(height: 35),

            // 5. الأزرار
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
              // أزرار البروفايل الشخصي (إعدادات اللاعب)
              if (player.heat > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withValues(alpha:0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.local_police, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text("مستوى الملاحقة", style: TextStyle(color: Colors.white70))]), Text("${player.heat.toInt()}%", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: audio.isMuted ? Colors.redAccent.withValues(alpha:0.2) : Colors.green.withValues(alpha:0.2), side: BorderSide(color: audio.isMuted ? Colors.redAccent : Colors.green), minimumSize: const Size(double.infinity, 50)),
                      onPressed: () => audio.toggleMute(),
                      icon: Icon(audio.isMuted ? Icons.volume_off : Icons.volume_up, color: audio.isMuted ? Colors.redAccent : Colors.green),
                      label: Text(audio.isMuted ? "تشغيل الصوت" : "كتم الصوت", style: TextStyle(color: audio.isMuted ? Colors.redAccent : Colors.green)),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha:0.2), side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 50)),
                      onPressed: () { audio.playEffect('click.mp3'); _showResetConfirmation(player); },
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text("مسح البيانات والبدء من جديد", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String val, IconData icon, Color color) {
    return Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 6), Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha:0.15), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha:0.5))), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}