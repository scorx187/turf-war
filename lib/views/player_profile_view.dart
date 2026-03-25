import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class PlayerProfileView extends StatefulWidget {
  final String targetUid;

  const PlayerProfileView({super.key, required this.targetUid});

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
    setState(() {
      playerData = data;
      isLoading = false;
    });
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
          maxLength: 100, // حد الحروف يمنع الطول المبالغ فيه
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

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1D),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (playerData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text("اللاعب غير موجود!", style: TextStyle(color: Colors.white))),
      );
    }

    bool isMe = widget.targetUid == player.uid;
    bool isVIP = playerData!['isVIP'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. الغلاف (Header) وزر الرجوع والصورة يمين
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // الصورة في أعلى اليمين
                  Positioned(
                    bottom: -50,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1D),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: isVIP ? Colors.amber : Colors.grey[800],
                        child: Icon(isVIP ? Icons.workspace_premium : Icons.person, size: 55, color: isVIP ? Colors.black : Colors.white54),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // 2. الاسم والعصابة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(playerData!['playerName'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withValues(alpha: 0.5))),
                            child: Text(playerData!['gangName'] != null ? 'عصابة: ${playerData!['gangName']}' : 'ذئب وحيد', style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 3. البايو (الوصف الشخصي) مع زر التعديل إذا كان بروفايلي
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
                          GestureDetector(
                            onTap: () => _editBio(player),
                            child: const Icon(Icons.edit, color: Colors.amber, size: 20),
                          ),
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

              // 5. الأزرار (إذا ما كان بروفايلك)
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    alignment: WrapAlignment.center,
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
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5))),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}