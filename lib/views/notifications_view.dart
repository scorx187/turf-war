// المسار: lib/views/notifications_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';

class NotificationsView extends StatelessWidget {
  final VoidCallback? onBack;

  const NotificationsView({super.key, this.onBack});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'قبل ثواني';
    if (diff.inHours < 1) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'قبل ${diff.inHours} ساعة';
    return 'قبل ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    // ملاحظة: الـ PlayerProvider يقرأ البيانات الحية عشان تتحدث الأرقام وأنت فاتح الإشعارات
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      // 🟢 حذفنا SafeArea من هنا عشان التوب بار يلزق في أعلى الشاشة زي الخريطة 🟢
      body: Column(
        children: [
          // 🟢 التوب بار الأصلي (مع تمرير كافة البيانات عشان ما يعطي كراش) 🟢
          const TopBar(),

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
          child: SafeArea( // خلينا الـ SafeArea تحت بس عشان تحمي الأزرار من أطراف الشاشة السفلية
            bottom: true,
            top: false,
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