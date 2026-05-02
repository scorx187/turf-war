// المسار: lib/views/perks_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../utils/game_data.dart';

class PerksView extends StatefulWidget {
  const PerksView({super.key});

  @override
  State<PerksView> createState() => _PerksViewState();
}

class _PerksViewState extends State<PerksView> {
  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);
    int unspent = player.unspentSkillPoints;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('شجرة الامتيازات 🌟', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.amber), onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF2A2D34), Color(0xFF0D0D0D)],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              color: Colors.black54,
              child: Column(
                children: [
                  Text('النقاط المتاحة: $unspent', style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                  const SizedBox(height: 5),
                  const Text('افتح ألقاب جديدة لتربح نقاط امتياز! (كل لقب = نقطة واحدة)', style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Changa')),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: GameData.perksList.length,
                itemBuilder: (context, index) {
                  final perk = GameData.perksList[index];
                  int currentLvl = player.perks[perk['id']] ?? 0;
                  bool isMax = currentLvl >= perk['maxLevel'];

                  return Card(
                    color: Colors.black45,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: currentLvl > 0 ? perk['color'] : Colors.white10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          children: [
                            CircleAvatar(radius: 25, backgroundColor: perk['color'].withValues(alpha: 0.2), child: Icon(perk['icon'], color: perk['color'], size: 25)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(perk['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                  Text(perk['desc'], style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Changa')),
                                  const SizedBox(height: 6),
                                  Text('المستوى: $currentLvl / ${perk['maxLevel']}', style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (isMax)
                              const Text('MAX', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18))
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: unspent > 0 ? Colors.amber : Colors.grey, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                onPressed: unspent > 0 ? () {
                                  audio.playEffect('click.mp3');
                                  player.upgradePerk(perk['id']);
                                } : null,
                                child: const Text('ترقية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}