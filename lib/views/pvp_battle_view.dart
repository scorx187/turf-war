// المسار: lib/views/pvp_battle_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/quick_recovery_dialog.dart';
import 'dart:math';

class PvpBattleView extends StatefulWidget {
  final Map<String, dynamic> enemyData;
  final VoidCallback onBack;

  const PvpBattleView({super.key, required this.enemyData, required this.onBack});

  @override
  State<PvpBattleView> createState() => _PvpBattleViewState();
}

class _PvpBattleViewState extends State<PvpBattleView> {
  String battleLog = "استعد للقتال! أنت تواجه لاعب حقيقي الآن.";
  bool isFighting = false;
  bool isX2Speed = false;

  // 🟢 دالة لإضافة الفواصل للأرقام
  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  // 🧮 معادلات الـ RPG المعقدة
  int calculateDamage(double atk, double def) {
    if (atk <= 0) return 10;
    double rawDamage = atk * (atk / (atk + def)) * 5.0;
    double variation = 0.9 + (Random().nextDouble() * 0.2);
    return max(1, (rawDamage * variation).toInt());
  }

  bool checkDodge(double attackerSpd, double defenderSkill) {
    if (defenderSkill <= 0) return false;
    double dodgeChance = (defenderSkill / (defenderSkill + attackerSpd + 1)) * 0.5;
    return Random().nextDouble() < dodgeChance;
  }

  bool checkCritical(double attackerSpd, double defenderSkill) {
    if (attackerSpd <= 0) return false;
    double critChance = (attackerSpd / (attackerSpd + defenderSkill + 1)) * 0.5;
    return Random().nextDouble() < critChance;
  }

  void startBattle(PlayerProvider player, AudioProvider audio) async {
    if (player.energy < 25) {
      QuickRecoveryDialog.show(context, 'energy', 25 - player.energy);
      return;
    }

    if (player.health < 20 || player.isHospitalized || player.isInPrison) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حالتك الصحية لا تسمح بالقتال الآن!', style: TextStyle(fontFamily: 'Changa'))));
      return;
    }

    setState(() {
      isFighting = true;
      battleLog = "🥊 بدأت المعركة ضد ${widget.enemyData['playerName']}...\n";
    });

    player.setEnergy(player.energy - 25);
    audio.playEffect('attack.mp3');

    int playerHP = player.health;
    int enemyHP = widget.enemyData['maxHealth'] ?? 100;

    double enemyStr = (widget.enemyData['strength'] ?? 10).toDouble();
    double enemyDef = (widget.enemyData['defense'] ?? 10).toDouble();
    double enemySkill = (widget.enemyData['skill'] ?? 10).toDouble();
    double enemySpd = (widget.enemyData['speed'] ?? 10).toDouble();

    StringBuffer log = StringBuffer(battleLog);

    int round = 1;

    // حلقة القتال (حد أقصى 20 جولة)
    while (playerHP > 0 && enemyHP > 0 && round <= 20) {
      log.writeln("--- الجولة $round ---");

      // ⚔️ [دور اللاعب في الهجوم]
      bool enemyDodged = checkDodge(player.speed, enemySkill);
      if (enemyDodged) {
        log.writeln("💨 ${widget.enemyData['playerName']} تفادى ضربتك بمهارته!");
      } else {
        int damage = calculateDamage(player.strength, enemyDef);
        bool isCrit = checkCritical(player.speed, enemySkill);

        if (isCrit) {
          damage = (damage * 1.5).toInt();
          log.writeln("💥 ضربة حرجة! سحقت الخصم بـ $damage ضرر.");
        } else {
          log.writeln("⚔️ ضربت الخصم بـ $damage ضرر.");
        }
        enemyHP -= damage;
      }

      if (enemyHP <= 0) break;

      // 🛡️ [دور الخصم في الهجوم]
      bool playerDodged = checkDodge(enemySpd, player.skill);
      if (playerDodged) {
        log.writeln("🛡️ تفاديت ضربة الخصم ببراعة!");
      } else {
        int damage = calculateDamage(enemyStr, player.defense);
        bool isCrit = checkCritical(enemySpd, player.skill);

        if (isCrit) {
          damage = (damage * 1.5).toInt();
          log.writeln("💥 الخصم سدد ضربة حرجة! انخصم منك $damage ضرر.");
        } else {
          log.writeln("🩸 الخصم ضربك بـ $damage ضرر.");
        }
        playerHP -= damage;
      }

      round++;
      int delayMs = isX2Speed ? 400 : 800;
      await Future.delayed(Duration(milliseconds: delayMs));

      if (mounted) setState(() => battleLog = log.toString());
    }

    // --- 📊 تحديد النتيجة النهائية وتنفيذ عقوبات المستشفى ---
    log.writeln("\n========================");

    String result;
    int reward = 0;

    if (enemyHP <= 0 && playerHP > 0) {
      // 🟢 حالة الفوز
      result = 'win';
      int enemyCash = widget.enemyData['cash'] ?? 0;
      reward = (enemyCash * 0.1).toInt(); // تسرق 10% من كاش الخصم كحد أقصى
      if (reward > 100000) reward = 100000;

      log.writeln("🏆 انتصار ساحق! قمت بتدمير ${widget.enemyData['playerName']}.");
      log.writeln("💰 غنيمة المعركة: ${_formatWithCommas(reward)}\$ كاش.");
      log.writeln("🏥 تم إرسال الخصم إلى المستشفى!");

    } else if (playerHP <= 0 && enemyHP > 0) {
      // 🔴 حالة الخسارة
      result = 'loss';
      log.writeln("💀 لقد سقطت في المعركة... تحتاج إلى مستشفى فوراً.");

    } else {
      // 🟡 حالة التعادل
      result = 'draw';
      log.writeln("🤝 انتهت 20 جولة! كلاكما منهك جداً، النتيجة: تعادل.");
      log.writeln("💡 تضررت صحتكما بشكل بالغ بسبب الاشتباك المستمر.");
    }

    // 🟢 إرسال النتيجة لقاعدة البيانات (اللي تبرمجت عشان تدخل المهزوم للمستشفى وترسل له إشعار)
    await player.recordPvpResult(
        widget.enemyData['uid'],
        widget.enemyData['playerName'] ?? 'مجهول',
        result,
        reward
    );

    if (mounted) {
      setState(() {
        isFighting = false;
        battleLog = log.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
                const Expanded(
                  child: Text('معركة لاعب ضد لاعب ⚔️', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                ),
                if (!isFighting)
                  TextButton(
                    style: TextButton.styleFrom(backgroundColor: isX2Speed ? Colors.amber : Colors.white10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => setState(() => isX2Speed = !isX2Speed),
                    child: Text("X2", style: TextStyle(color: isX2Speed ? Colors.black : Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCombatHeader(player),
                  const SizedBox(height: 10),
                  const Text("كل هجوم يستنزف 25 طاقة", style: TextStyle(color: Colors.orangeAccent, fontFamily: 'Changa', fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 200),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                    child: Text(battleLog, style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace', height: 1.5)),
                  ),
                  const SizedBox(height: 20),
                  if (!isFighting)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                      onPressed: () {
                        audio.playEffect('click.mp3');
                        startBattle(player, audio);
                      },
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      label: const Text("هجوم!", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Changa', color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatHeader(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCombatantInfo(player.playerName, player.health, player.strength, player.defense, player.skill, player.speed, Colors.blue),
        const Text("VS", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        _buildCombatantInfo(
            widget.enemyData['playerName'] ?? 'خصم مجهول',
            widget.enemyData['maxHealth'] ?? 100,
            (widget.enemyData['strength'] ?? 10).toDouble(),
            (widget.enemyData['defense'] ?? 10).toDouble(),
            (widget.enemyData['skill'] ?? 10).toDouble(),
            (widget.enemyData['speed'] ?? 10).toDouble(),
            Colors.red
        ),
      ],
    );
  }

  Widget _buildCombatantInfo(String name, int hp, double str, double def, double skill, double speed, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Changa', fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const Divider(color: Colors.white10),
          _buildMiniStat("❤️", "صحة", _formatWithCommas(hp)),
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
          Text(val, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}