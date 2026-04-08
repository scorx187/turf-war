// المسار: lib/views/notifications_view.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class NotificationsView extends StatelessWidget {
  final VoidCallback? onBack;

  const NotificationsView({super.key, this.onBack});

  // دالة لتنسيق الأرقام
  String _formatWithCommas(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  // دالة لتنسيق الوقت
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'قبل ثواني';
    if (diff.inHours < 1) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'قبل ${diff.inHours} ساعة';
    return 'قبل ${diff.inDays} يوم';
  }

  // 🟢 دالة بناء أشرطة الإحصائيات (صحة، طاقة، شجاعة، احترام) 🟢
  Widget _buildStatBar(String label, int val, int maxVal, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Container(
              height: 10,
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white24, width: 0.5)
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: maxVal > 0 ? val / maxVal : 0,
                  backgroundColor: Colors.transparent,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text('$val/$maxVal', style: const TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'Changa', fontWeight: FontWeight.bold), textDirection: TextDirection.ltr),
          ],
        ),
      ),
    );
  }

  // 🟢 دالة بناء التوب بار الكامل (نفس شاشة اللعبة بالضبط) 🟢
  Widget _buildTopBar(PlayerProvider player) {
    Uint8List? profilePicData = player.getDecodedImage(player.profilePicUrl);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black87,
        image: DecorationImage(image: AssetImage('assets/images/ui/top_bar_bg.png'), fit: BoxFit.cover, opacity: 0.6),
        border: Border(bottom: BorderSide(color: Color(0xFF856024), width: 2)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. صورة البروفايل، الاسم، والمستوى
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: player.isVIP ? Border.all(color: Colors.amber, width: 2) : null,
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: profilePicData != null ? MemoryImage(profilePicData) : null,
                          child: profilePicData == null ? Icon(player.isVIP ? Icons.workspace_premium : Icons.person, color: player.isVIP ? Colors.amber : Colors.white54) : null,
                        ),
                      ),
                      if (player.isVIP)
                        const Positioned(bottom: -2, right: -2, child: Icon(Icons.workspace_premium, color: Colors.amber, size: 14)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.playerName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                      Text('مستوى ${player.crimeLevel}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontFamily: 'Changa')),
                    ],
                  ),
                ],
              ),

              // 2. الكاش والذهب
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${_formatWithCommas(player.cash)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Changa'), textDirection: TextDirection.ltr),
                      const SizedBox(width: 4),
                      const Icon(Icons.attach_money, color: Colors.greenAccent, size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatWithCommas(player.gold), style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Changa'), textDirection: TextDirection.ltr),
                      const SizedBox(width: 4),
                      const Icon(Icons.monetization_on, color: Colors.orangeAccent, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. أشرطة الصحة، الطاقة، الشجاعة، الاحترام
          Row(
            children: [
              _buildStatBar('الصحة', player.health, player.maxHealth, Colors.redAccent),
              _buildStatBar('الطاقة', player.energy, player.maxEnergy, Colors.blueAccent),
              _buildStatBar('الشجاعة', player.courage, player.maxCourage, Colors.orangeAccent),
              _buildStatBar('الاحترام', player.prestige, player.maxPrestige, Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D), // خلفية الشاشة الأساسية
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // 🟢 التوب بار الكامل 🟢
            _buildTopBar(player),

            // عنوان صفحة الإشعارات
            const Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 10.0),
              child: Center(
                child: Text(
                    'سجل الإشعارات',
                    style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')
                ),
              ),
            ),

            // 🟢 قائمة الإشعارات 🟢
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('uid', isEqualTo: player.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("لا توجد إشعارات جديدة", style: TextStyle(color: Colors.white54, fontSize: 18, fontFamily: 'Changa')),
                    );
                  }

                  var docs = snapshot.data!.docs.toList();
                  docs.sort((a, b) {
                    var tA = (a.data() as Map)['timestamp'] as Timestamp?;
                    var tB = (b.data() as Map)['timestamp'] as Timestamp?;
                    if (tA == null || tB == null) return 0;
                    return tB.compareTo(tA);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      bool isRead = data['isRead'] ?? false;

                      return Card(
                        color: isRead ? Colors.black45 : Colors.amber.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: isRead ? Colors.white10 : Colors.amber.withOpacity(0.5)),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (!isRead) {
                              FirebaseFirestore.instance.collection('notifications').doc(docs[index].id).update({'isRead': true});
                            }
                          },
                          leading: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.notifications, color: Colors.amber),
                          ),
                          title: Text(
                            data['title'] ?? 'إشعار',
                            style: TextStyle(color: isRead ? Colors.white70 : Colors.amberAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                          ),
                          subtitle: Text(
                            data['body'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Changa'),
                          ),
                          trailing: Text(
                            _formatTimestamp(data['timestamp'] as Timestamp?),
                            style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Changa'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 🟢 النافبار السفلي 🟢
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            image: DecorationImage(image: AssetImage('assets/images/ui/bottom_navbar_bg.png'), fit: BoxFit.cover),
            border: Border(top: BorderSide(color: Color(0xFF856024), width: 2)),
          ),
          padding: const EdgeInsets.only(top: 10, bottom: 20, left: 15, right: 15),
          child: SafeArea(
            bottom: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    audio.playEffect('click.mp3');
                    if (onBack != null) onBack!();
                    else Navigator.pop(context);
                  },
                  child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_forward_ios, color: Color(0xFFE2C275), size: 24),
                        SizedBox(height: 4),
                        Text('رجوع', style: TextStyle(color: Color(0xFFE2C275), fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))
                      ]
                  ),
                ),
                const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, color: Colors.white70, size: 24),
                      SizedBox(height: 4),
                      Text('السجل', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))
                    ]
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}