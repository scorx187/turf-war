// المسار: lib/views/gang_management_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';

class GangManagementView extends StatefulWidget {
  final String gangName;

  const GangManagementView({super.key, required this.gangName});

  @override
  State<GangManagementView> createState() => _GangManagementViewState();
}

class _GangManagementViewState extends State<GangManagementView> {
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _saveSettings(AudioProvider audio) {
    audio.playEffect('click.mp3');
    setState(() => _isLoading = true);

    // محاكاة الحفظ في الفايربيس
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات العصابة بنجاح! 🛡️', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.green));
        _bioController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        body: SafeArea(
          top: false,
          child: Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final audio = Provider.of<AudioProvider>(context, listen: false);

                return Column(
                  children: [
                    // 🟢 التوب بار الثابت 🟢
                    TopBar(
                        cash: player.cash, gold: player.gold, energy: player.energy, maxEnergy: player.maxEnergy,
                        courage: player.courage, maxCourage: player.maxCourage, health: player.health, maxHealth: player.maxHealth,
                        prestige: player.prestige, maxPrestige: player.maxPrestige, playerName: player.playerName,
                        profilePicUrl: player.profilePicUrl, level: player.crimeLevel, currentXp: player.crimeXP,
                        maxXp: player.xpToNextLevel, isVIP: player.isVIP
                    ),

                    // 🟢 هيدر الشاشة 🟢
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 2)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 20),
                              onPressed: () { audio.playEffect('click.mp3'); Navigator.pop(context); }
                          ),
                          const Expanded(
                            child: Text('إدارة العصابة ⚙️', style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          ),
                        ],
                      ),
                    ),

                    // 🟢 التبويبات (طلبات، ترقيات، إعدادات) 🟢
                    Expanded(
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            const TabBar(
                              indicatorColor: Colors.grey,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white54,
                              labelStyle: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13),
                              tabs: [
                                Tab(text: "طلبات الانضمام"),
                                Tab(text: "صلاحيات الأعضاء"),
                                Tab(text: "الإعدادات"),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildRequestsTab(audio),
                                  _buildRanksTab(player, audio),
                                  _buildSettingsTab(audio),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              }
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 1. تبويب طلبات الانضمام
  // ----------------------------------------------------
  Widget _buildRequestsTab(AudioProvider audio) {
    // بيانات وهمية للطلبات (سيتم ربطها لاحقاً بالفايربيس)
    final List<Map<String, dynamic>> dummyRequests = [
      {'name': 'شبح الليل', 'level': 12, 'power': 1500},
      {'name': 'العقرب', 'level': 8, 'power': 900},
    ];

    if (dummyRequests.isEmpty) {
      return const Center(child: Text('لا توجد طلبات انضمام حالياً.', style: TextStyle(color: Colors.white54, fontFamily: 'Changa')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: dummyRequests.length,
      itemBuilder: (context, index) {
        final req = dummyRequests[index];
        return Card(
          color: Colors.black45,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
            title: Text(req['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
            subtitle: Text('المستوى: ${req['level']} | القوة: ${req['power']}', style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Changa')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {
                    audio.playEffect('click.mp3');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم قبول ${req['name']} في العصابة!', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.green));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  onPressed: () {
                    audio.playEffect('click.mp3');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفض طلب ${req['name']}.', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // 2. تبويب ترقيات الأعضاء (جلب حقيقي من الأعضاء)
  // ----------------------------------------------------
  Widget _buildRanksTab(PlayerProvider player, AudioProvider audio) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('players').where('gangName', isEqualTo: widget.gangName).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.grey));

          final members = snapshot.data!.docs.where((doc) => doc.id != player.uid).toList(); // نستثني الزعيم نفسه

          if (members.isEmpty) {
            return const Center(child: Text('لا يوجد أعضاء آخرين لترقيتهم.', style: TextStyle(color: Colors.white54, fontFamily: 'Changa')));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index].data() as Map<String, dynamic>;
              final String name = member['playerName'] ?? 'مجهول';
              final String currentRank = member['gangRank'] ?? 'عضو';

              return Card(
                color: Colors.black45,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                child: ListTile(
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                  subtitle: Text('الرتبة الحالية: $currentRank', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontFamily: 'Changa')),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
                      audio.playEffect('click.mp3');
                      _showPromotionDialog(name, currentRank, audio);
                    },
                    child: const Text('تعديل الرتبة', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 12)),
                  ),
                ),
              );
            },
          );
        }
    );
  }

  void _showPromotionDialog(String memberName, String currentRank, AudioProvider audio) {
    showDialog(
        context: context,
        builder: (c) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.grey)),
            title: Text('ترقية $memberName', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRankOption('نائب الزعيم', Icons.star, Colors.amber, audio, c),
                _buildRankOption('كابتن', Icons.shield, Colors.blueAccent, audio, c),
                _buildRankOption('عضو', Icons.person, Colors.white54, audio, c),
                const Divider(color: Colors.white24),
                _buildRankOption('طرد من العصابة', Icons.block, Colors.redAccent, audio, c),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildRankOption(String title, IconData icon, Color color, AudioProvider audio, BuildContext dialogContext) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
      onTap: () {
        audio.playEffect('click.mp3');
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title == 'طرد من العصابة' ? 'تم الطرد بنجاح!' : 'تم التعديل إلى $title', style: const TextStyle(fontFamily: 'Changa'))));
      },
    );
  }

  // ----------------------------------------------------
  // 3. تبويب الإعدادات
  // ----------------------------------------------------
  Widget _buildSettingsTab(AudioProvider audio) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رسالة العصابة (تظهر للأعضاء):', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _bioController,
            maxLines: 3,
            maxLength: 100,
            style: const TextStyle(color: Colors.white, fontFamily: 'Changa'),
            decoration: InputDecoration(
              hintText: 'اكتب إعلان أو قوانين العصابة هنا...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
              label: Text(_isLoading ? 'جاري الحفظ...' : 'حفظ الإعدادات', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: _isLoading ? null : () => _saveSettings(audio),
            ),
          ),
        ],
      ),
    );
  }
}