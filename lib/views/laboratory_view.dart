import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class LaboratoryView extends StatefulWidget {
  final VoidCallback onBack;
  const LaboratoryView({super.key, required this.onBack});

  @override
  State<LaboratoryView> createState() => _LaboratoryViewState();
}

class _LaboratoryViewState extends State<LaboratoryView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    bool isCrafting = player.isCrafting;
    DateTime? endTime = player.labEndTime;
    bool isDone = false;
    Duration remainingTime = Duration.zero;

    if (isCrafting && endTime != null) {
      if (DateTime.now().isAfter(endTime)) {
        isDone = true;
      } else {
        remainingTime = endTime.difference(DateTime.now());
      }
    }

    final List<Map<String, dynamic>> recipes = [
      {
        'id': 'steroids',
        'name': 'حقنة منشط (طاقة)',
        'icon': Icons.medical_services,
        'color': Colors.greenAccent,
        'cost': 2500,
        'time': 15, // بالدقائق
      },
      {
        'id': 'coffee',
        'name': 'قهوة مركزة (شجاعة)',
        'icon': Icons.coffee,
        'color': Colors.brown,
        'cost': 2500,
        'time': 15,
      },
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
              const Text('المختبر السري 🧪', style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        Expanded(
          child: isCrafting ? _buildCraftingProcess(player, audio, isDone, remainingTime) : _buildRecipesList(player, audio, recipes),
        ),
      ],
    );
  }

  Widget _buildRecipesList(PlayerProvider player, AudioProvider audio, List<Map<String, dynamic>> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        bool canAfford = player.cash >= recipe['cost'];

        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: recipe['color'].withValues(alpha:0.5))),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: CircleAvatar(backgroundColor: recipe['color'].withValues(alpha:0.2), child: Icon(recipe['icon'], color: recipe['color'])),
            title: Text(recipe['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("التكلفة: ${recipe['cost']} كاش\nالمدة: ${recipe['time']} دقيقة", style: const TextStyle(color: Colors.white70)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: canAfford ? recipe['color'] : Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: canAfford ? () {
                audio.playEffect('click.mp3');
                player.startCrafting(recipe['id'], recipe['cost'] as int, recipe['time'] as int);
              } : null,
              child: const Text("صناعة", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCraftingProcess(PlayerProvider player, AudioProvider audio, bool isDone, Duration remainingTime) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isDone ? Icons.science : Icons.science_outlined, size: 80, color: isDone ? Colors.green : Colors.amber),
          const SizedBox(height: 20),
          if (!isDone) ...[
            const Text("جاري تركيب المواد الكيميائية...", style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(_formatDuration(remainingTime), style: const TextStyle(color: Colors.white, fontSize: 40, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.greenAccent),
          ] else ...[
            const Text("تم التصنيع بنجاح! 🧪", style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () {
                audio.playEffect('click.mp3');
                player.collectCraftedItem();
              },
              icon: const Icon(Icons.inventory_2, color: Colors.white),
              label: const Text("نقل إلى المخزن", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ]
        ],
      ),
    );
  }
}