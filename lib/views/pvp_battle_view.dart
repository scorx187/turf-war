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
  // 🟢 تم تصحيح اسم المتغير هنا ليتطابق مع باقي الكود
  bool _isBattling = false;
  bool isX2Speed = false;
  String? _result;

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

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
      _isBattling = true;
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

    while (playerHP > 0 && enemyHP > 0 && round <= 20) {
      log.writeln("--- الجولة $round ---");

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

    log.writeln("\n========================");

    String result;

    if (enemyHP <= 0 && playerHP > 0) {
      // 🟢 حالة الفوز: ننتظر من اللاعب اختيار مصير الخصم
      result = 'win_pending_choice';
      log.writeln("🏆 الخصم سقط أرضاً وهو ينزف...");

    } else if (playerHP <= 0 && enemyHP > 0) {
      result = 'loss';
      log.writeln("💀 لقد سقطت في المعركة... سيتم نقلك للمستشفى فوراً.");
      await player.recordPvpResult(widget.enemyData['uid'], widget.enemyData['playerName'] ?? 'مجهول', result, 0);

    } else {
      result = 'draw';
      log.writeln("🤝 انتهت 20 جولة! كلاكما منهك جداً، النتيجة: تعادل.");
      log.writeln("💡 تضررت صحتكما بشكل بالغ بسبب الاشتباك المستمر.");
      await player.recordPvpResult(widget.enemyData['uid'], widget.enemyData['playerName'] ?? 'مجهول', result, 0);
    }

    if (mounted) {
      setState(() {
        _result = result;
        _isBattling = false;
        battleLog = log.toString();
      });
    }
  }

  // 🟢 دالة تطبيق خيار الفوز اللي يختاره اللاعب
  void _applyWinChoice(String choice, PlayerProvider player) async {
    setState(() => _isBattling = true); // إظهار تحميل بسيط

    int reward = 0;
    int hospitalTime = 15;
    String summary = "";

    if (choice == 'leave') {
      reward = 0;
      hospitalTime = 15;
      summary = "اخترت الرحمة.. غادرت المكان وتم نقل الخصم للمستشفى.";
    } else if (choice == 'rob') {
      int enemyCash = widget.enemyData['cash'] ?? 0;
      reward = (enemyCash * 0.1).toInt(); // سرقة 10% من كاش الخصم
      if (reward > 100000) reward = 100000;
      hospitalTime = 15;
      summary = "قمت بتفتيش جيوب الخصم وسرقت ${_formatWithCommas(reward)}\$ 💸";
    } else if (choice == 'execute') {
      reward = 0;
      hospitalTime = 60; // عقوبة غيبوبة لمدة 60 دقيقة
      summary = "سددت ضربة وحشية للخصم! 🩸 تم إدخاله العناية المركزة لـ 60 دقيقة.";
    }

    // تسجيل النتيجة في الفايربيس بالمدة والمكافأة المحددة
    await player.recordPvpResult(
        widget.enemyData['uid'],
        widget.enemyData['playerName'] ?? 'مجهول',
        'win',
        reward,
        hospitalMinutes: hospitalTime
    );

    if (mounted) {
      setState(() {
        _result = 'win';
        battleLog += "\n\n$summary";
        _isBattling = false;
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
                if (!_isBattling && _result == null)
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

                  if (_isBattling)
                    const CircularProgressIndicator(color: Colors.redAccent)
                  else if (_result == null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                      onPressed: () {
                        audio.playEffect('click.mp3');
                        startBattle(player, audio);
                      },
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      label: const Text("هجوم!", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Changa', color: Colors.white)),
                    )
                  // 🟢 حالة الفوز المبدئي: تظهر أزرار الخيارات 🟢
                  else if (_result == 'win_pending_choice') ...[
                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 60),
                      const SizedBox(height: 10),
                      const Text('الخصم يسقط أمامك! 🩸', style: TextStyle(color: Colors.orangeAccent, fontSize: 26, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                      const Text('ماذا تريد أن تفعل به؟', style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Changa')),
                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], minimumSize: const Size(double.infinity, 50)),
                        icon: const Icon(Icons.directions_run, color: Colors.white),
                        label: const Text("المغادرة (نقل للمستشفى 15 دقيقة)", style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                        onPressed: () => _applyWinChoice('leave', player),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800], minimumSize: const Size(double.infinity, 50)),
                        icon: const Icon(Icons.attach_money, color: Colors.white),
                        label: const Text("سلب الأموال (سرقة كاش + مستشفى 15 دقيقة)", style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                        onPressed: () => _applyWinChoice('rob', player),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], minimumSize: const Size(double.infinity, 50)),
                        icon: const Icon(Icons.dangerous, color: Colors.white),
                        label: const Text("ضربة قاضية (غيبوبة 60 دقيقة)", style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                        onPressed: () => _applyWinChoice('execute', player),
                      ),
                    ]
                    // 🟢 إظهار النتيجة النهائية 🟢
                    else ...[
                        if (_result == 'win') ...[
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
                          const SizedBox(height: 10),
                          const Text('انتصاااار! 🎉', style: TextStyle(color: Colors.amber, fontSize: 32, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                        ] else if (_result == 'loss') ...[
                          const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red, size: 60),
                          const SizedBox(height: 10),
                          const Text('هزيمة ساحقة! ☠️', style: TextStyle(color: Colors.red, fontSize: 32, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                        ] else ...[
                          const Icon(Icons.handshake, color: Colors.orange, size: 60),
                          const SizedBox(height: 10),
                          const Text('النتيجة تعادل! 🤝', style: TextStyle(color: Colors.orange, fontSize: 32, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                        ],
                        const SizedBox(height: 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                          onPressed: widget.onBack,
                          child: const Text('عودة للخريطة', style: TextStyle(color: Colors.white, fontFamily: 'Changa')),
                        )
                      ]
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
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