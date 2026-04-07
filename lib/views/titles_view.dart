// المسار: lib/views/titles_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class TitlesView extends StatelessWidget {
  final Map<String, dynamic> playerData;
  final bool isMe;
  final List<Map<String, dynamic>> allTitles;

  const TitlesView({super.key, required this.playerData, required this.isMe, required this.allTitles});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final audio = Provider.of<AudioProvider>(context, listen: false);
    String currentTitle = playerData['selectedTitle'] ?? 'مبتدئ في الشوارع 🚶';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('خزانة الألقاب 🏆', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(isMe ? "اضغط على أي لقب قمت بفتحه لتجهيزه كلقبك الرسمي." : "الألقاب التي فتحها هذا اللاعب:", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Changa')),
            const SizedBox(height: 20),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 12, runSpacing: 12,
                children: allTitles.map((titleData) {
                  bool isCurrent = titleData['name'] == currentTitle;
                  bool isUnlocked = titleData['unlocked'];

                  return GestureDetector(
                    onTap: () {
                      if (isMe && isUnlocked) {
                        audio.playEffect('click.mp3');
                        player.updateTitle(titleData['name']);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز اللقب بنجاح!'), backgroundColor: Colors.green));
                      }
                    },
                    child: Tooltip(
                      message: titleData['desc'],
                      triggerMode: TooltipTriggerMode.tap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                            color: isUnlocked ? (isCurrent ? Colors.amber.withOpacity(0.2) : Colors.white10) : Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isUnlocked ? (isCurrent ? Colors.amber : Colors.white24) : Colors.white10, width: isCurrent ? 2 : 1)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isCurrent ? Icons.military_tech : (isUnlocked ? Icons.emoji_events : Icons.lock), color: isUnlocked ? (isCurrent ? Colors.amber : Colors.white54) : Colors.white24, size: 20),
                            const SizedBox(width: 8),
                            Text(titleData['name'], style: TextStyle(color: isUnlocked ? (isCurrent ? Colors.amber : Colors.white70) : Colors.white24, fontSize: 14, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontFamily: 'Changa')),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}