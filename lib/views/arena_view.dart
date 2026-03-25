import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/quick_recovery_dialog.dart';
import 'dart:math';

class ArenaView extends StatefulWidget {
  final VoidCallback onBack;

  const ArenaView({super.key, required this.onBack});

  @override
  State<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  String battleLog = "استعد للقتال! كلما فزت زادت قوة الخصوم.";
  bool isFighting = false;
  bool isX2Speed = false; // حالة السرعة المضاعفة
  Map<String, dynamic>? currentEnemy;

  void generateEnemy(int arenaLevel) {
    Random r = Random();
    double totalStatPoints = 40.0 + (arenaLevel * 5);
    List<double> stats = [0, 0, 0, 0];
    for (int i = 0; i < totalStatPoints.toInt(); i++) {
      stats[r.nextInt(4)] += 1.0;
    }

    setState(() {
      currentEnemy = {
        'name': 'خصم مستوى $arenaLevel',
        'health': 100 + (arenaLevel * 25),
        'strength': stats[0],
        'defense': stats[1],
        'skill': stats[2],
        'speed': stats[3],
      };
    });
  }

  void startBattle(PlayerProvider player, AudioProvider audio) async {
    if (player.energy < 20) {
      QuickRecoveryDialog.show(context, 'energy', 20 - player.energy);
      return;
    }

    if (currentEnemy == null) generateEnemy(player.arenaLevel);
    
    setState(() {
      isFighting = true;
      battleLog = "🥊 بدأت المعركة ضد ${currentEnemy!['name']}...\n";
    });

    player.setEnergy(player.energy - 20);
    audio.lowerBGMVolume();

    int playerHP = player.health;
    int enemyHP = currentEnemy!['health'];
    StringBuffer log = StringBuffer(battleLog);

    int round = 1;
    while (playerHP > 0 && enemyHP > 0 && round <= 20) {
      log.writeln("--- الجولة $round ---");
      audio.playEffect('attack.mp3');

      bool enemyDodged = checkDodge(player.speed, currentEnemy!['skill']);
      if (enemyDodged) {
        log.writeln("💨 الخصم تفادى ضربتك!");
      } else {
        int damage = calculateDamage(player.strength, currentEnemy!['defense']);
        enemyHP -= damage;
        log.writeln("⚔️ ضربت الخصم بـ $damage ضرر.");
      }

      if (enemyHP <= 0) break;

      bool playerDodged = checkDodge(currentEnemy!['speed'], player.skill);
      if (playerDodged) {
        log.writeln("🛡️ تفاديت ضربة الخصم!");
      } else {
        int damage = calculateDamage(currentEnemy!['strength'], player.defense);
        playerHP -= damage;
        log.writeln("💥 الخصم ضربك بـ $damage ضرر.");
      }

      round++;
      
      // تبطيء سرعة القتال، واستخدام الماعمل X2 إذا كان مفعلاً
      int delayMs = isX2Speed ? 400 : 800; 
      await Future.delayed(Duration(milliseconds: delayMs));
      
      if (mounted) {
        setState(() => battleLog = log.toString());
      }
    }

    if (enemyHP <= 0) {
      log.writeln("\n🏆 انتصار ساحق! ارتفع مستواك في الساحة.");
      player.incrementArenaLevel();
      player.addCash(500 * player.arenaLevel, reason: "جائزة الساحة");
      player.setHealth(playerHP);
      currentEnemy = null;
    } else if (playerHP <= 0) {
      log.writeln("\n💀 هزيمة مرة... تم نقلك للمستشفى.");
      player.setHealth(0); 
    } else {
      log.writeln("\n⏱️ تعادل! انتهى الوقت.");
      player.setHealth(playerHP);
    }

    audio.restoreBGMVolume();

    if (mounted) {
      setState(() {
        isFighting = false;
        battleLog = log.toString();
      });
    }
  }

  int calculateDamage(double attackerStr, double defenderDef) {
    int baseDmg = (attackerStr * 2.5).toInt();
    int reduction = (defenderDef / 1.5).toInt();
    return max(10, baseDmg - reduction + Random().nextInt(15));
  }

  bool checkDodge(double attackerSpd, double defenderSkill) {
    double dodgeChance = (defenderSkill / (attackerSpd + defenderSkill + 1)) * 0.7;
    return Random().nextDouble() < dodgeChance;
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);
    
    if (currentEnemy == null && !isFighting) generateEnemy(player.arenaLevel);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
              const Expanded(
                child: Text('ساحة القتال ⚔️', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              // زر السرعة X2
              if (!isFighting)
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: isX2Speed ? Colors.amber : Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      isX2Speed = !isX2Speed;
                    });
                  },
                  child: Text(
                    "X2", 
                    style: TextStyle(color: isX2Speed ? Colors.black : Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (currentEnemy != null) _buildCombatHeader(player),
                const SizedBox(height: 10),
                const Text("كل هجوم يستهلك 20 طاقة", style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                  child: Text(battleLog, style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace')),
                ),
                const SizedBox(height: 20),
                if (!isFighting)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                    onPressed: () {
                      audio.playEffect('click.mp3');
                      startBattle(player, audio);
                    },
                    icon: const Icon(Icons.flash_on),
                    label: Text("هجوم (مستوى ${player.arenaLevel})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCombatHeader(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCombatantInfo(player.playerName, player.health, player.strength, player.defense, player.skill, player.speed, Colors.blue),
        const Text("VS", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        _buildCombatantInfo(currentEnemy!['name'], currentEnemy!['health'], currentEnemy!['strength'], currentEnemy!['defense'], currentEnemy!['skill'], currentEnemy!['speed'], Colors.red),
      ],
    );
  }

  Widget _buildCombatantInfo(String name, int hp, double str, double def, double skill, double speed, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha:0.3))),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const Divider(color: Colors.white10),
          _buildMiniStat("❤️", "صحة", hp.toString()),
          _buildMiniStat("⚔️", "قوة", str.toStringAsFixed(0)),
          _buildMiniStat("🛡️", "دفاع", def.toStringAsFixed(0)),
          _buildMiniStat("🧠", "مهارة", skill.toStringAsFixed(0)),
          _buildMiniStat("⚡", "سرعة", speed.toStringAsFixed(0)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
