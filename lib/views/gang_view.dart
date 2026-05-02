// المسار: lib/views/gang_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 🟢 استيراد البار العلوي
import '../widgets/top_bar.dart';
import 'gang_members_view.dart';
import 'gang_donation_view.dart';
import 'gang_management_view.dart';
import 'gang_skills_view.dart';
import 'gang_store_view.dart';
import 'gang_raids_view.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class GangView extends StatefulWidget {
  final VoidCallback? onBack; // 🟢 خليناها اختيارية عشان تدعم زر الرجوع للنافبار

  const GangView({super.key, this.onBack});

  @override
  State<GangView> createState() => _GangViewState();
}

class _GangViewState extends State<GangView> {
  final TextEditingController _gangNameController = TextEditingController();
  String _warLog = "اختر منطقة للهجوم عليها وبسط نفوذ عصابتك! 💀\nبانتظار الأوامر يا زعيم...";
  bool _isWarring = false;

  final List<Map<String, dynamic>> territories = [
    {'id': 'slums', 'name': 'العشوائيات', 'difficulty': 1.2, 'reward': 50000, 'icon': Icons.holiday_village},
    {'id': 'downtown', 'name': 'وسط المدينة', 'difficulty': 2.5, 'reward': 200000, 'icon': Icons.location_city},
    {'id': 'port', 'name': 'الميناء القديم', 'difficulty': 5.0, 'reward': 1000000, 'icon': Icons.directions_boat},
    {'id': 'rich_district', 'name': 'الحي الراقي', 'difficulty': 12.0, 'reward': 5000000, 'icon': Icons.domain},
    {'id': 'military', 'name': 'القاعدة العسكرية', 'difficulty': 30.0, 'reward': 25000000, 'icon': Icons.security},
  ];

  @override
  void dispose() {
    _gangNameController.dispose();
    super.dispose();
  }

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  void startGangWar(PlayerProvider player, AudioProvider audio, Map<String, dynamic> terr) async {
    if (player.energy < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تحتاج لـ 50 طاقة على الأقل لخوض حرب عصابات!', style: TextStyle(fontFamily: 'Changa'))));
      return;
    }

    setState(() {
      _isWarring = true;
      _warLog = "🛡️ بدأت الحرب في منطقة [ ${terr['name']} ]...\nجاري نشر الأفراد والأسلحة...\n";
    });

    audio.lowerBGMVolume();
    int playerHP = player.health;
    double enemyPower = ((terr['difficulty'] as num) * 100).toDouble();
    int enemyHP = enemyPower.toInt();

    StringBuffer log = StringBuffer(_warLog);
    int round = 1;

    while (playerHP > 0 && enemyHP > 0 && round <= 15) {
      log.writeln("--------------------------------");
      log.writeln("🔥 اشتباك الجولة $round 🔥");
      audio.playEffect('attack.mp3');

      int damage = (player.strength * 2 + player.skill).toInt();
      enemyHP -= damage;
      log.writeln("🔫 ألحقتم بالعصابة المعادية $damage ضرر.");

      if (enemyHP <= 0) break;

      int enemyDmg = ((terr['difficulty'] as num) * 15).toInt();
      playerHP -= enemyDmg;
      log.writeln("💥 أصيب أفراد عصابتكم بـ $enemyDmg ضرر.");

      round++;
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _warLog = log.toString());
    }

    log.writeln("================================");
    if (enemyHP <= 0) {
      log.writeln("🚩 نصر عظيم! سيطرت عصابتكم على ${terr['name']}!");
      player.winGangWar(terr['name']);
      player.addCash(terr['reward'], reason: "غنائم حرب العصابات في ${terr['name']}");
      player.setEnergy(player.energy - 50);
      player.setHealth(playerHP);
    } else {
      log.writeln("💀 هزيمة منكرة! انسحبت عصابتكم من ${terr['name']}.");
      player.setHealth(0);
      player.setEnergy(player.energy - 30);
    }

    audio.restoreBGMVolume();
    if (mounted) {
      setState(() {
        _isWarring = false;
        _warLog = log.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      // 🟢 تحويل الكونتينر إلى Scaffold بشاشة كاملة 🟢
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        body: SafeArea(
          top: false, // عشان التوب بار ياخذ راحته فوق
          child: Column(
            children: [
              // 🟢 إضافة التوب بار هنا عشان يظل ثابت وما يختفي 🟢
              const TopBar(),

              // الهيدر (العنوان وزر الرجوع)
              Container(
                padding: const EdgeInsets.only(top: 15, bottom: 15, right: 10, left: 15),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  border: Border(bottom: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 2)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        onPressed: () {
                          audio.playEffect('click.mp3');
                          // 🟢 برمجة ذكية لزر الرجوع: إذا فيه onBack يشغله، وإذا لا يسوي Pop للشاشة 🟢
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else {
                            Navigator.pop(context);
                          }
                        }
                    ),
                    const Expanded(
                      child: Text('شؤون العصابات 💀', style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Changa', shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
                    ),
                  ],
                ),
              ),

              // المحتوى (لوحة التحكم أو التأسيس)
              Expanded(
                child: player.isInGang ? _buildGangDashboard(player, audio) : _buildCreateJoin(player, audio),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateJoin(PlayerProvider player, AudioProvider audio) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.groups_3, size: 90, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          const Text('أنت ذئب وحيد حالياً!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          const SizedBox(height: 10),
          const Text('أسس إمبراطوريتك الخاصة لفرض سيطرتك على المدينة، أو انضم لعصابة أخرى لاحقاً.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Changa')),
          const SizedBox(height: 40),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.05), blurRadius: 15, spreadRadius: 2)]
            ),
            child: Column(
              children: [
                const Text('تأسيس عصابة جديدة 👑', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Changa')),
                const SizedBox(height: 15),
                TextField(
                  controller: _gangNameController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLength: 15,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: 'اسم العصابة...',
                    hintStyle: const TextStyle(color: Colors.white24, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    const Text('التكلفة: ', style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Changa')),
                    Text('\$1,000,000', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    icon: const Icon(Icons.add_moderator, color: Colors.white),
                    label: const Text('تأسيس الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa', fontSize: 16)),
                    onPressed: () {
                      audio.playEffect('click.mp3');
                      String name = _gangNameController.text.trim();
                      if (name.length < 3) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الاسم قصير جداً!', style: TextStyle(fontFamily: 'Changa'))));
                        return;
                      }
                      if (player.cash < 1000000) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك كاش كافي لتأسيس عصابة!', style: TextStyle(fontFamily: 'Changa'))));
                        return;
                      }
                      player.createGang(name);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGangDashboard(PlayerProvider player, AudioProvider audio) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildGangHeader(player),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                _buildGridItem(icon: Icons.people, title: 'الأعضاء', color: Colors.blueAccent, onTap: () {
                  audio.playEffect('click.mp3');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GangMembersView(gangName: player.gangName!)));
                }),
                _buildGridItem(icon: Icons.military_tech, title: 'الحروب', color: Colors.redAccent, onTap: () {
                  audio.playEffect('click.mp3');
                  _showWarsBottomSheet(player, audio);
                }),
                _buildGridItem(icon: Icons.psychology, title: 'المهارات', color: Colors.purpleAccent, onTap: () {
                  audio.playEffect('click.mp3');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GangSkillsView(gangName: player.gangName!)));
                }),
                _buildGridItem(icon: Icons.local_fire_department, title: 'الغارات', color: Colors.orangeAccent, onTap: () {
                  audio.playEffect('click.mp3');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GangRaidsView()));
                }),
                _buildGridItem(icon: Icons.shopping_cart, title: 'المتجر', color: Colors.amber, onTap: () {
                  audio.playEffect('click.mp3');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GangStoreView()));
                }),
                _buildGridItem(icon: Icons.volunteer_activism, title: 'التبرع', color: Colors.greenAccent, onTap: () {
                  audio.playEffect('click.mp3');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GangDonationView()));
                }),
                _buildGridItem(icon: Icons.settings, title: 'الإدارة', color: Colors.grey, onTap: () {
                  audio.playEffect('click.mp3');
                  // 🟢 تفتح شاشة الإدارة بشاشة كاملة تحت التوب بار 🟢
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GangManagementView(gangName: player.gangName!)));
                }),
                _buildGridItem(icon: Icons.exit_to_app, title: 'المغادرة', color: Colors.red, onTap: () {
                  audio.playEffect('click.mp3');
                  _showLeaveConfirmation(player);
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGridItem({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGangHeader(PlayerProvider player) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red.shade900, const Color(0xFF1A1A1D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border(bottom: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 2)),
      ),
      child: Column(
        children: [
          Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 2)),
              child: const Icon(Icons.security, color: Colors.amber, size: 40)
          ),
          const SizedBox(height: 15),
          Text(player.gangName!, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Changa', shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
            child: Text('الرتبة: ${player.gangRank}', style: const TextStyle(color: Colors.amberAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGangStat('مساهماتك', '\$${_formatWithCommas(player.gangContribution)}', Icons.monetization_on, Colors.greenAccent),
              Container(height: 40, width: 1, color: Colors.white24),
              _buildGangStat('حروب رابحة', player.gangWarWins.toString(), Icons.military_tech, Colors.amber),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGangStat(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 5),
        Text(val, textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Changa')),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Changa')),
      ],
    );
  }

  void _showWarsBottomSheet(PlayerProvider player, AudioProvider audio) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: const BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(20)), border: Border(top: BorderSide(color: Colors.redAccent, width: 2))),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.military_tech, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('حروب المناطق ⚔️', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 120,
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(10), border: Border.all(color: _isWarring ? Colors.redAccent : Colors.green.withValues(alpha: 0.5))),
                          child: SingleChildScrollView(
                            reverse: true,
                            child: Text(_warLog, style: TextStyle(color: _isWarring ? Colors.orangeAccent : Colors.greenAccent, fontSize: 11, fontFamily: 'monospace', height: 1.5)),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            itemCount: territories.length,
                            itemBuilder: (context, index) {
                              final terr = territories[index];
                              final owner = player.territoryOwners[terr['name']] ?? "غير مسيطر عليها";
                              bool isMyGang = owner == player.gangName;

                              return Card(
                                color: isMyGang ? Colors.green.withValues(alpha: 0.1) : Colors.black45,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isMyGang ? Colors.green.withValues(alpha: 0.5) : Colors.white10)),
                                child: ListTile(
                                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: isMyGang ? Colors.green : Colors.redAccent)), child: Icon(terr['icon'], color: isMyGang ? Colors.green : Colors.redAccent, size: 20)),
                                  title: Text(terr['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("المسيطر: $owner", style: TextStyle(color: isMyGang ? Colors.greenAccent : Colors.white54, fontSize: 11, fontFamily: 'Changa')),
                                      Text("مستوى الصعوبة: ${terr['difficulty']}x", style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontFamily: 'Changa')),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: _isWarring || isMyGang ? Colors.grey[800] : Colors.redAccent.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    onPressed: (_isWarring || isMyGang) ? null : () async {
                                      if (player.energy < 50) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طاقة غير كافية!')));
                                        return;
                                      }
                                      setModalState(() {
                                        _isWarring = true;
                                        _warLog = "🛡️ الهجوم على ${terr['name']}...\n";
                                      });

                                      int playerHP = player.health;
                                      int enemyHP = ((terr['difficulty'] as num) * 100).toInt();
                                      StringBuffer log = StringBuffer(_warLog);

                                      audio.playEffect('attack.mp3');
                                      for (int i = 1; i <= 10; i++) {
                                        log.writeln("🔥 جولة $i...");
                                        int myDmg = (player.strength * 2 + player.skill).toInt();
                                        enemyHP -= myDmg;

                                        if (enemyHP <= 0) break;

                                        int enemyDmg = ((terr['difficulty'] as num) * 15).toInt();
                                        playerHP -= enemyDmg;

                                        setModalState(() => _warLog = log.toString());
                                        await Future.delayed(const Duration(milliseconds: 500));
                                      }

                                      if (enemyHP <= 0) {
                                        log.writeln("🚩 سيطرنا على المنطقة!");
                                        player.winGangWar(terr['name']);
                                        player.addCash(terr['reward']);
                                        player.setHealth(playerHP);
                                      } else {
                                        log.writeln("💀 هُزمنا وانسحبنا!");
                                        player.setHealth(0);
                                      }
                                      player.setEnergy(player.energy - 50);

                                      setModalState(() {
                                        _isWarring = false;
                                        _warLog = log.toString();
                                      });
                                    },
                                    child: const Text("هجوم", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  void _showLeaveConfirmation(PlayerProvider player) {
    showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.redAccent)),
              title: const Text('تأكيد المغادرة ⚠️', style: TextStyle(color: Colors.redAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              content: const Text('هل أنت متأكد من مغادرة العصابة؟ ستفقد كل مناصبك ومساهماتك ولا يمكنك التراجع.', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', height: 1.5)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa'))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      player.leaveGang();
                      Navigator.pop(context);
                    },
                    child: const Text('نعم، غادر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa'))
                )
              ]
          ),
        )
    );
  }
}