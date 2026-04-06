// المسار: lib/views/public_gang_profile_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class PublicGangProfileView extends StatefulWidget {
  final String gangName;

  const PublicGangProfileView({Key? key, required this.gangName}) : super(key: key);

  @override
  State<PublicGangProfileView> createState() => _PublicGangProfileViewState();
}

class _PublicGangProfileViewState extends State<PublicGangProfileView> {
  bool _isRequesting = false;

  Future<void> _sendJoinRequest(PlayerProvider player) async {
    if (player.isInGang) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أنت منضم لعصابة بالفعل! يجب الخروج منها أولاً.', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isRequesting = true);

    try {
      // إرسال طلب الانضمام إلى مجموعة الطلبات الخاصة بالعصابة
      await FirebaseFirestore.instance
          .collection('gangs')
          .doc(widget.gangName)
          .collection('join_requests')
          .doc(player.uid)
          .set({
        'uid': player.uid,
        'playerName': player.playerName,
        'level': player.crimeLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الانضمام لزعيم العصابة بنجاح! 🛡️', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
        Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب.', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        appBar: AppBar(
          title: const Text('ملف العصابة', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.grey[900],
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.amber),
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('gangs').doc(widget.gangName).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('هذه العصابة لم تعد موجودة أو تم حلها.', style: TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 18)));
            }

            var gangData = snapshot.data!.data() as Map<String, dynamic>;
            String leaderName = gangData['leaderName'] ?? 'مجهول';
            int level = gangData['level'] ?? 1;
            int reputation = gangData['reputation'] ?? 0;
            int membersCount = (gangData['members'] as List?)?.length ?? 1;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.shield, color: Colors.amber, size: 60),
                        const SizedBox(height: 10),
                        Text(widget.gangName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                        const SizedBox(height: 5),
                        Text('بقيادة الزعيم: $leaderName', style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontFamily: 'Changa')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('المستوى', level.toString(), Icons.star, Colors.blueAccent),
                      _buildStatCard('السمعة', reputation.toString(), Icons.military_tech, Colors.greenAccent),
                      _buildStatCard('الأعضاء', '$membersCount / 50', Icons.group, Colors.deepOrange),
                    ],
                  ),

                  const Spacer(),

                  if (!player.isInGang)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _isRequesting ? null : () => _sendJoinRequest(player),
                        child: _isRequesting
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('إرسال طلب انضمام 📝', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('لا يمكنك الانضمام لعصابتين في نفس الوقت.', style: TextStyle(color: Colors.redAccent, fontFamily: 'Changa')),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Changa')),
      ],
    );
  }
}