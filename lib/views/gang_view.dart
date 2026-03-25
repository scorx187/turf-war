import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class GangView extends StatefulWidget {
  final VoidCallback onBack;

  const GangView({super.key, required this.onBack});

  @override
  State<GangView> createState() => _GangViewState();
}

class _GangViewState extends State<GangView> {
  final TextEditingController _gangNameController = TextEditingController();
  String _warLog = "اختر منطقة للهجوم عليها وبسط نفوذ عصابتك!";
  bool _isWarring = false;

  final List<Map<String, dynamic>> territories = [
    {'id': 'slums', 'name': 'العشوائيات', 'difficulty': 1.2, 'reward': 50000, 'icon': Icons.holiday_village},
    {'id': 'downtown', 'name': 'وسط المدينة', 'difficulty': 2.5, 'reward': 200000, 'icon': Icons.location_city},
    {'name': 'الميناء القديم', 'id': 'port', 'difficulty': 5.0, 'reward': 1000000, 'icon': Icons.directions_boat},
    {'name': 'الحي الراقي', 'id': 'rich_district', 'difficulty': 12.0, 'reward': 5000000, 'icon': Icons.domain},
    {'name': 'القاعدة العسكرية', 'id': 'military', 'difficulty': 30.0, 'reward': 25000000, 'icon': Icons.security},
  ];

  @override
  void dispose() {
    _gangNameController.dispose();
    super.dispose();
  }

  void startGangWar(PlayerProvider player, AudioProvider audio, Map<String, dynamic> terr) async {
    if (player.energy < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تحتاج لـ 50 طاقة على الأقل لخوض حرب عصابات!')));
      return;
    }

    setState(() {
      _isWarring = true;
      _warLog = "🛡️ بدأت الحرب في منطقة ${terr['name']}...\n";
    });

    audio.lowerBGMVolume();
    int playerHP = player.health;
    double enemyPower = (100 * terr['difficulty']).toDouble();
    int enemyHP = enemyPower.toInt();
    
    StringBuffer log = StringBuffer(_warLog);
    int round = 1;

    while (playerHP > 0 && enemyHP > 0 && round <= 15) {
      log.writeln("--- اشتباك $round ---");
      audio.playEffect('attack.mp3');

      // هجوم العصابة (بناءً على القوة والمهارة)
      int damage = (player.strength * 2 + player.skill).toInt();
      enemyHP -= damage;
      log.writeln("⚔️ ألحقتم بالعصابة المعادية $damage ضرر.");

      if (enemyHP <= 0) break;

      // هجوم الخصم
      int enemyDmg = (terr['difficulty'] * 15).toInt();
      playerHP -= enemyDmg;
      log.writeln("💥 أصيب أفراد عصابتكم بـ $enemyDmg ضرر.");

      round++;
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _warLog = log.toString());
    }

    if (enemyHP <= 0) {
      log.writeln("\n🚩 نصر عظيم! سيطرت عصابتكم على ${terr['name']}!");
      player.winGangWar(terr['name']);
      player.addCash(terr['reward'], reason: "غنائم حرب العصابات");
      player.setEnergy(player.energy - 50);
      player.setHealth(playerHP);
    } else {
      log.writeln("\n💀 هزيمة منكرة! انسحبت عصابتكم من ${terr['name']}.");
      player.setHealth(0); // دخول المستشفى
      player.setEnergy(player.energy - 30);
    }

    audio.restoreBGMVolume();
    setState(() {
      _isWarring = false;
      _warLog = log.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
              const Text('شؤون العصابات 💀', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: player.isInGang ? _buildGangDashboard(player) : _buildCreateJoin(player),
        ),
      ],
    );
  }

  Widget _buildCreateJoin(PlayerProvider player) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.groups_3, size: 100, color: Colors.white24),
          const SizedBox(height: 20),
          const Text('لست عضواً في أي عصابة حالياً', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
            child: Column(
              children: [
                const Text('أسس عصابتك الخاصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  controller: _gangNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'اسم العصابة...', hintStyle: TextStyle(color: Colors.white24), border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                const Text('التكلفة: 1,000,000 كاش', style: TextStyle(color: Colors.amber, fontSize: 12)),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      if (_gangNameController.text.isNotEmpty) {
                        player.createGang(_gangNameController.text);
                      }
                    },
                    child: const Text('تأسيس الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGangDashboard(PlayerProvider player) {
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: const [Tab(text: "الإدارة"), Tab(text: "حروب المناطق")], indicatorColor: Colors.redAccent),
          Expanded(
            child: TabBarView(
              children: [
                // شاشة الإدارة
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildGangHeader(player),
                      const SizedBox(height: 20),
                      _buildActionCard(
                        title: 'دعم الصندوق',
                        subtitle: 'ساهم بـ 100,000 كاش',
                        icon: Icons.attach_money,
                        color: Colors.green,
                        onTap: () => player.contributeToGang(100000),
                      ),
                      _buildActionCard(
                        title: 'مغادرة العصابة',
                        subtitle: 'فقدان النفوذ والمكانة',
                        icon: Icons.exit_to_app,
                        color: Colors.grey,
                        onTap: () => _showLeaveConfirmation(player),
                      ),
                    ],
                  ),
                ),
                // شاشة حروب العصابات
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.black26,
                      child: Text(_warLog, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace')),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: territories.length,
                        itemBuilder: (context, index) {
                          final terr = territories[index];
                          final owner = player.territoryOwners[terr['name']] ?? "غير مسيطر عليها";
                          return Card(
                            color: Colors.black38,
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: Icon(terr['icon'], color: owner == player.gangName ? Colors.green : Colors.red),
                              title: Text(terr['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("المسيطر: $owner | الصعوبة: ${terr['difficulty']}x", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: _isWarring ? Colors.grey : Colors.red),
                                onPressed: _isWarring ? null : () => startGangWar(player, audio, terr),
                                child: const Text("هجوم", style: TextStyle(fontSize: 10)),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGangHeader(PlayerProvider player) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red.shade900, Colors.black]), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent, width: 2)),
      child: Column(
        children: [
          const Icon(Icons.security, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(player.gangName!, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          Text('رتبتك: ${player.gangRank}', style: const TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGangStat('المساهمة', player.gangContribution.toString(), Icons.volunteer_activism),
              _buildGangStat('حروب رابحة', player.gangWarWins.toString(), Icons.military_tech),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGangStat(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.redAccent, size: 20),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(color: Colors.black45, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: Icon(icon, color: color), title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)), onTap: onTap));
  }

  void _showLeaveConfirmation(PlayerProvider player) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: Colors.grey[900], title: const Text('تأكيد المغادرة'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), TextButton(onPressed: () { player.leaveGang(); Navigator.pop(context); }, child: const Text('نعم، غادر', style: TextStyle(color: Colors.red)))]));
  }
}
