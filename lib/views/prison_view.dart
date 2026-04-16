// المسار: lib/views/prison_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🟢 استدعاء البلوك
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart'; // 🟢 أضفنا الصوت
import '../controllers/prison_cubit.dart'; // 🟢 استدعاء الكيوبت

class PrisonView extends StatefulWidget {
  final VoidCallback? onBack;

  const PrisonView({super.key, this.onBack});

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

    // 🟢 تغليف الشاشة كاملة بالكيوبت
    return BlocProvider(
      create: (context) => PrisonCubit(),
      child: BlocConsumer<PrisonCubit, PrisonState>(
        listener: (context, state) {
          if (state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent));
          }
          if (state.successMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('السجن المركزي', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: Colors.grey[900],
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: widget.onBack != null && !playerProvider.isInPrison
                  ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () {
                Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                widget.onBack!();
              })
                  : const SizedBox.shrink(),
            ),
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[850],
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('المساجين الحاليين', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _prisonStream,
                        builder: (context, snapshot) {
                          List<Map<String, dynamic>> prisonersList = [];
                          Set<String> addedIds = {};

                          if (playerProvider.isInPrison && playerProvider.uid != null) {
                            prisonersList.add({
                              'uid': playerProvider.uid,
                              'playerName': playerProvider.playerName,
                              'crimeLevel': playerProvider.crimeLevel,
                              'lastCrimeName': playerProvider.lastCrimeName,
                              'bailCost': playerProvider.playerBailCost,
                              'prisonReleaseTime': playerProvider.prisonReleaseTime?.toIso8601String(),
                              'profilePicUrl': playerProvider.profilePicUrl,
                            });
                            addedIds.add(playerProvider.uid!);
                          }

                          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                            for (var doc in snapshot.data!.docs) {
                              if (!addedIds.contains(doc.id)) {
                                var data = doc.data() as Map<String, dynamic>;
                                data['uid'] = doc.id;
                                prisonersList.add(data);
                                addedIds.add(doc.id);
                              }
                            }
                          }

                          if (snapshot.connectionState == ConnectionState.waiting && prisonersList.isEmpty) {
                            return const Center(child: CircularProgressIndicator(color: Colors.orange));
                          }

                          if (prisonersList.isEmpty) {
                            return const Center(
                              child: Text(
                                'السجن خالي حالياً! \nيبدو أن الجميع ملتزمون بالقانون.',
                                style: TextStyle(color: Colors.grey, fontSize: 18, fontFamily: 'Changa'),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: prisonersList.length,
                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                            itemBuilder: (context, index) {
                              var data = prisonersList[index];
                              String docId = data['uid'] ?? '';
                              // 🟢 تمرير الكيوبت للكارد عشان نقدر نستدعيه لما نضغط زر الكفالة
                              return PrisonPlayerCard(data: data, docId: docId, playerProvider: playerProvider, cubit: context.read<PrisonCubit>());
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // 🟢 شاشة تحميل خفيفة تغطي الشاشة أثناء دفع الكفالة
                if (state.isBailingOut)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.orange),
                          SizedBox(height: 10),
                          Text('جاري دفع الكفالة والإفراج...', style: TextStyle(color: Colors.orange, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PrisonPlayerCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final PlayerProvider playerProvider;
  final PrisonCubit cubit; // 🟢 الكيوبت ممرر هنا

  const PrisonPlayerCard({super.key, required this.data, required this.docId, required this.playerProvider, required this.cubit});

  @override
  State<PrisonPlayerCard> createState() => _PrisonPlayerCardState();
}

class _PrisonPlayerCardState extends State<PrisonPlayerCard> {
  Timer? _timer;
  String _formattedTime = "00:00:00";
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    if (widget.data['profilePicUrl'] != null && widget.data['profilePicUrl'].toString().isNotEmpty) {
      try {
        _avatarBytes = base64Decode(widget.data['profilePicUrl']);
      } catch (e) {
        _avatarBytes = null;
      }
    }
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) { _updateTime(); });
  }

  void _updateTime() {
    if (!mounted) return;
    String? releaseTimeStr = widget.data['prisonReleaseTime'];
    if (releaseTimeStr != null) {
      DateTime releaseTime = DateTime.parse(releaseTimeStr);
      Duration diff = releaseTime.difference(widget.playerProvider.secureNow);

      if (diff.isNegative) {
        setState(() { _formattedTime = "يتم الإفراج..."; });
        _timer?.cancel();
      } else {
        String hours = diff.inHours.toString().padLeft(2, '0');
        String minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        String seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
        setState(() { _formattedTime = "$hours:$minutes:$seconds"; });
      }
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    String name = widget.data['playerName'] ?? 'مجهول';
    int level = widget.data['crimeLevel'] ?? 1;
    String crimeName = widget.data['lastCrimeName'] ?? 'تهمة مجهولة';
    int bailCost = widget.data['bailCost'] ?? 1500;
    bool isMe = widget.docId == widget.playerProvider.uid;
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26, backgroundColor: Colors.black54,
              backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : const AssetImage('assets/images/icons/profile.png') as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa', fontSize: 16)),
                  Row(
                    children: [
                      Text('المستوى: $level | ', style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'Changa', fontSize: 12)),
                      Text('باقي: $_formattedTime', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('التهمة: $crimeName', style: const TextStyle(color: Colors.grey, fontFamily: 'Changa', fontSize: 12)),
                ],
              ),
            ),
            isMe
                ? const Padding(padding: EdgeInsets.all(8.0), child: Text('تنتظر الكفالة...', style: TextStyle(color: Colors.redAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13)))
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 10)),
              onPressed: () {
                audio.playEffect('click.mp3');
                // 🟢 استدعاء الدفع عن طريق الكيوبت
                widget.cubit.payBail(widget.playerProvider, widget.docId, bailCost, name);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('دفع الكفالة', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('\$$bailCost', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}