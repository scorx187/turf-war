// المسار: lib/views/gang_members_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';
import '../widgets/top_bar.dart'; // 🟢 استيراد البار العلوي

class GangMembersView extends StatelessWidget {
  final String gangName;

  const GangMembersView({super.key, required this.gangName});

  @override
  Widget build(BuildContext context) {
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
                    // 🟢 تثبيت البار العلوي في أعلى الشاشة 🟢
                    const TopBar(),

                    // هيدر الشاشة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border(bottom: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text('أعضاء العصابة 👥', style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          ),
                        ],
                      ),
                    ),

                    // قائمة الأعضاء
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('players').where('gangName', isEqualTo: gangName).snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

                            final members = snapshot.data!.docs.toList();

                            members.sort((a, b) {
                              int levelA = (a.data() as Map<String, dynamic>)['crimeLevel'] ?? 0;
                              int levelB = (b.data() as Map<String, dynamic>)['crimeLevel'] ?? 0;
                              return levelB.compareTo(levelA);
                            });

                            return ListView.builder(
                              padding: const EdgeInsets.all(15),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final memberData = members[index].data() as Map<String, dynamic>;
                                final String name = memberData['playerName'] ?? 'مجهول';
                                final String rank = memberData['gangRank'] ?? 'عضو';
                                final int level = memberData['crimeLevel'] ?? 1;
                                final String? picUrl = memberData['profilePicUrl'];
                                final bool isVIP = memberData['isVIP'] == true;

                                final imageBytes = player.getDecodedImage(picUrl);

                                return Card(
                                  color: Colors.black45,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3))),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                    leading: Container(
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: isVIP ? Border.all(color: Colors.amberAccent, width: 1.5) : null),
                                      child: CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.grey[800],
                                        backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                                        child: imageBytes == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, color: isVIP ? Colors.amber : Colors.white54) : null,
                                      ),
                                    ),
                                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa', fontSize: 16)),
                                    subtitle: Text('الرتبة: $rank', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontFamily: 'Changa')),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('المستوى', style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Changa')),
                                        Text('$level', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                      ),
                    ),
                  ],
                );
              }
          ),
        ),
      ),
    );
  }
}