// المسار: lib/views/prison_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import '../providers/player_provider.dart';

class PrisonView extends StatefulWidget {
  final VoidCallback? onBack;

  const PrisonView({Key? key, this.onBack}) : super(key: key);

  @override
  State<PrisonView> createState() => _PrisonViewState();
}

class _PrisonViewState extends State<PrisonView> {
  late Stream<QuerySnapshot> _prisonStream;

  @override
  void initState() {
    super.initState();
    _prisonStream = FirebaseFirestore.instance
        .collection('players')
        .where('isInPrison', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('السجن المركزي', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: widget.onBack != null && !playerProvider.isInPrison
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack)
            : const SizedBox.shrink(),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[850],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('المساجين الحاليين', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _prisonStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'السجن خالي حالياً! \nيبدو أن الجميع ملتزمون بالقانون.',
                      style: TextStyle(color: Colors.grey, fontSize: 18, fontFamily: 'Tajawal'),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final prisoners = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: prisoners.length,
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  itemBuilder: (context, index) {
                    var data = prisoners[index].data() as Map<String, dynamic>;
                    String docId = prisoners[index].id;

                    // 🟢 استدعاء ويدجت خاصة لكل سجين عشان تحسب الوقت بدون ما تخلي الشاشة كلها ترمش
                    return PrisonPlayerCard(
                      data: data,
                      docId: docId,
                      playerProvider: playerProvider,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🟢 ويدجت ذكية ورايقة: تفك تشفير الصورة مرة وحدة وتشغل مؤقت لحالها عشان تمنع الوميض! 🟢
class PrisonPlayerCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final PlayerProvider playerProvider;

  const PrisonPlayerCard({Key? key, required this.data, required this.docId, required this.playerProvider}) : super(key: key);

  @override
  State<PrisonPlayerCard> createState() => _PrisonPlayerCardState();
}

class _PrisonPlayerCardState extends State<PrisonPlayerCard> {
  Timer? _timer;
  String _formattedTime = "00:00:00";
  Uint8List? _avatarBytes; // نحفظ الصورة هنا عشان ما ترمش

  @override
  void initState() {
    super.initState();

    // فك تشفير الصورة مرة وحدة بس!
    if (widget.data['profilePicUrl'] != null) {
      _avatarBytes = base64Decode(widget.data['profilePicUrl']);
    }

    _updateTime(); // التحديث الأول
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (!mounted) return;

    String? releaseTimeStr = widget.data['prisonReleaseTime'];
    if (releaseTimeStr != null) {
      DateTime releaseTime = DateTime.parse(releaseTimeStr);
      Duration diff = releaseTime.difference(DateTime.now());

      if (diff.isNegative) {
        setState(() {
          _formattedTime = "يتم الإفراج...";
        });
        _timer?.cancel();
      } else {
        // 🟢 تحويل الوقت إلى صيغة HH:MM:SS
        String hours = diff.inHours.toString().padLeft(2, '0');
        String minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        String seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');

        setState(() {
          _formattedTime = "$hours:$minutes:$seconds";
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.data['playerName'] ?? 'مجهول';
    int level = widget.data['crimeLevel'] ?? 1;
    String crimeName = widget.data['lastCrimeName'] ?? 'تهمة مجهولة';
    int bailCost = widget.data['bailCost'] ?? 1500;

    bool isMe = widget.docId == widget.playerProvider.uid;

    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // الصورة ثابتة وما راح ترمش لأننا حفظناها في الـ State
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.black54,
              backgroundImage: _avatarBytes != null
                  ? MemoryImage(_avatarBytes!)
                  : const AssetImage('assets/images/icons/profile.png') as ImageProvider,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 16)),
                  Row(
                    children: [
                      Text('المستوى: $level | ', style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'Tajawal', fontSize: 12)),
                      Text('باقي: $_formattedTime', style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold)), // الوقت الحي
                    ],
                  ),
                  Text('التهمة: $crimeName', style: const TextStyle(color: Colors.grey, fontFamily: 'Tajawal', fontSize: 12)),
                ],
              ),
            ),

            isMe
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('تنتظر الكفالة...', style: TextStyle(color: Colors.redAccent, fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
            )
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 10)),
              onPressed: () {
                widget.playerProvider.bailOutPlayer(widget.docId, bailCost, name);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('دفع الكفالة', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('\$$bailCost', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Tajawal', fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}