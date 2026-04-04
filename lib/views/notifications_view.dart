// المسار: lib/views/notifications_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('الإشعارات 🔔', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 10,
        shadowColor: Colors.black,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          // نسحب سجل الهجمات من الفايربيس
            future: player.fetchAttacksLog(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              List<Map<String, dynamic>> allNotifications = [];

              // 1. إضافة الهجمات للقائمة
              if (snapshot.hasData) {
                for (var attack in snapshot.data!) {
                  allNotifications.add({
                    'type': 'attack',
                    'data': attack,
                    'date': (attack['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  });
                }
              }

              // 2. إضافة الإشعارات المالية (التحويلات والغنائم)
              for (var t in player.transactions) {
                if (t.isPositive && (t.title.contains('تحويل') || t.title.contains('غنيمة') || t.title.contains('هبة'))) {
                  allNotifications.add({
                    'type': 'transfer',
                    'data': t,
                    'date': t.date,
                  });
                }
              }

              // 3. ترتيب الإشعارات من الأحدث إلى الأقدم
              allNotifications.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

              if (allNotifications.isEmpty) {
                return const Center(child: Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.white54, fontSize: 18, fontFamily: 'Changa')));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: allNotifications.length,
                itemBuilder: (context, index) {
                  final item = allNotifications[index];

                  if (item['type'] == 'attack') {
                    final data = item['data'];
                    return Card(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.warning, color: Colors.white)),
                        title: const Text('تعرضت لهجوم! ⚔️', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                        subtitle: Text('اللاعب ${data['attackerName']} قام بالهجوم عليك وسرق \$${data['stolenAmount']}', style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', height: 1.5)),
                      ),
                    );
                  } else {
                    final t = item['data'];
                    return Card(
                      color: Colors.green.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.withOpacity(0.5))),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.attach_money, color: Colors.white)),
                        title: const Text('إشعار مالي 💸', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                        subtitle: Text('${t.title} بمقدار \$${t.amount}', style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', height: 1.5)),
                      ),
                    );
                  }
                },
              );
            }
        ),
      ),
    );
  }
}