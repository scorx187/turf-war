// المسار: lib/views/lucky_wheel_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/audio_provider.dart';
import '../providers/player_provider.dart';
import 'player_profile_view.dart';
import '../controllers/lucky_wheel_cubit.dart';
import '../controllers/lucky_wheel_state.dart';

class LuckyWheelView extends StatelessWidget {
  final int cash;
  final int maxEnergy;
  final int maxCourage;
  final Function(int) onCashChanged;
  final Function(int) onGoldChanged;
  final Function(int) onEnergyChanged;
  final Function(int) onCourageChanged;
  final VoidCallback onBack;

  const LuckyWheelView({
    super.key,
    required this.cash,
    required this.maxEnergy,
    required this.maxCourage,
    required this.onCashChanged,
    required this.onGoldChanged,
    required this.onEnergyChanged,
    required this.onCourageChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = LuckyWheelCubit();
        final player = Provider.of<PlayerProvider>(context, listen: false);
        cubit.claimPendingPrizes(player.uid!);
        return cubit;
      },
      child: _LuckyWheelContent(onBack: onBack),
    );
  }
}

class _LuckyWheelContent extends StatefulWidget {
  final VoidCallback onBack;
  const _LuckyWheelContent({required this.onBack});

  @override
  State<_LuckyWheelContent> createState() => _LuckyWheelContentState();
}

class _LuckyWheelContentState extends State<_LuckyWheelContent> {
  late Stream<QuerySnapshot> _winnersStream;

  @override
  void initState() {
    super.initState();
    _winnersStream = FirebaseFirestore.instance
        .collection('wheel_winners')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  void _show10xRewardsDialog(List<Map<String, dynamic>> wonPrizes, LuckyWheelCubit cubit) {
    Map<String, int> counts = {};
    for (var w in wonPrizes) {
      counts[w['name']] = (counts[w['name']] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 2)),
          title: const Text('حصيلة الـ 10 لفات 🎰', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: counts.entries.map((e) {
              var prizeData = cubit.prizes.firstWhere((p) => p['name'] == e.key);
              return Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: prizeData['color'].withValues(alpha: 0.5))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(prizeData['icon'], color: prizeData['color'], size: 28),
                    const SizedBox(height: 5),
                    Text(e.key, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber[800], borderRadius: BorderRadius.circular(5)),
                      child: Text('x${e.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('جمع الغنائم', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ), // 🟢 هذا القوس اللي كان ناقص
    );
  }

  Widget _buildCell(int index, LuckyWheelState state, LuckyWheelCubit cubit) {
    var prize = cubit.prizes[index];
    bool isHighlighted = state.currentIndex == index;

    return AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isHighlighted ? prize['color'].withValues(alpha: 0.3) : Colors.black54,
              border: Border.all(
                  color: isHighlighted ? Colors.yellowAccent : Colors.white12,
                  width: isHighlighted ? 3 : 1
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isHighlighted ? [BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.8), blurRadius: 15, spreadRadius: 2)] : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Icon(prize['icon'], color: prize['color'], size: 20)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        prize['name'],
                        style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]
              ),
            )
        )
    );
  }

  Widget _buildCenterTop(AudioProvider audio, PlayerProvider player, LuckyWheelState state, LuckyWheelCubit cubit) {
    return Container(
      margin: const EdgeInsets.all(1),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.orangeAccent)),
          padding: EdgeInsets.zero,
        ),
        onPressed: state.isSpinning ? null : () => cubit.spin(1, player.uid!, player.gold, () => audio.playEffect('click.mp3')),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('لفة واحدة', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              Text('500 ذهب', style: TextStyle(color: Colors.yellowAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterBot(AudioProvider audio, PlayerProvider player, LuckyWheelState state, LuckyWheelCubit cubit) {
    return Container(
      margin: const EdgeInsets.all(1),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.redAccent)),
          padding: EdgeInsets.zero,
        ),
        onPressed: state.isSpinning ? null : () => cubit.spin(10, player.uid!, player.gold, () => audio.playEffect('click.mp3')),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('10 لفات', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              Text('4500 ذهب', style: TextStyle(color: Colors.yellowAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWinnersFeed(PlayerProvider player) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: const Text('🏆 اسماء اخر الفائزين 🏆', textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _winnersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2));
                  }

                  List<Widget> listItems = [];

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    var docs = snapshot.data!.docs;
                    for (var doc in docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      String timeStr = "الآن";
                      if (data['timestamp'] != null) {
                        timeStr = DateFormat('hh:mm a').format((data['timestamp'] as Timestamp).toDate());
                      }
                      Color prizeColor = Color(data['prizeColor'] ?? Colors.amber.toARGB32());
                      bool isMe = data['uid'] == player.uid;

                      listItems.add(
                          InkWell(
                            onTap: isMe ? null : () {
                              Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerProfileView(
                                targetUid: data['uid'],
                                profileTabIndex: 0,
                                previewName: data['playerName'],
                                previewPicUrl: data['profilePicUrl'],
                                previewIsVIP: data['isVIP'] ?? false,
                                onBack: () => Navigator.pop(context),
                              )));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.amber, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                        text: TextSpan(
                                            style: const TextStyle(fontFamily: 'Changa', fontSize: 11),
                                            children: [
                                              const TextSpan(text: 'كسب اللاعب ', style: TextStyle(color: Colors.white70)),
                                              TextSpan(text: '${data['playerName']}', style: TextStyle(color: isMe ? Colors.amber : Colors.blueAccent, fontWeight: FontWeight.bold)),
                                              const TextSpan(text: ' على ', style: TextStyle(color: Colors.white70)),
                                              TextSpan(text: '${data['prizeName']}', style: TextStyle(color: prizeColor, fontWeight: FontWeight.bold)),
                                            ]
                                        )
                                    ),
                                  ),
                                  Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Changa')),
                                ],
                              ),
                            ),
                          )
                      );
                    }
                  }

                  if (listItems.isEmpty) {
                    return const Center(child: Text("كن أول الفائزين!", style: TextStyle(color: Colors.white54, fontFamily: 'Changa')));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(4),
                    itemCount: listItems.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 4),
                    itemBuilder: (context, index) => listItems[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final cubit = context.read<LuckyWheelCubit>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<LuckyWheelCubit, LuckyWheelState>(
        listener: (context, state) {
          if (state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage, style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
          }
          if (state.wonPrizes != null && !state.isSpinning) {
            if (state.wonPrizes!.length == 1) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("مبروك! حصلت على ${state.wonPrizes!.first['name']}!", style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                backgroundColor: Colors.green,
              ));
            } else {
              _show10xRewardsDialog(state.wonPrizes!, cubit);
            }
            cubit.resetPrizes();
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0, right: 10, left: 10, bottom: 5),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                        onPressed: state.isSpinning ? null : widget.onBack),
                    const Text('عجلة الحظ الأسطورية',
                        style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 65),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [ Expanded(child: _buildCell(0, state, cubit)), Expanded(child: _buildCell(1, state, cubit)), Expanded(child: _buildCell(2, state, cubit)), Expanded(child: _buildCell(3, state, cubit)) ]),
                    Row(
                      children: [
                        Expanded(child: Column(children: [ _buildCell(11, state, cubit), _buildCell(10, state, cubit) ])),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              AspectRatio(aspectRatio: 2 / 1, child: _buildCenterTop(audio, player, state, cubit)),
                              AspectRatio(aspectRatio: 2 / 1, child: _buildCenterBot(audio, player, state, cubit)),
                            ],
                          ),
                        ),
                        Expanded(child: Column(children: [ _buildCell(4, state, cubit), _buildCell(5, state, cubit) ])),
                      ],
                    ),
                    Row(children: [ Expanded(child: _buildCell(9, state, cubit)), Expanded(child: _buildCell(8, state, cubit)), Expanded(child: _buildCell(7, state, cubit)), Expanded(child: _buildCell(6, state, cubit)) ]),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              if (state.statusText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(state.statusText, style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                ),

              _buildWinnersFeed(player),
            ],
          );
        },
      ),
    );
  }
}