// المسار: lib/views/armory_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';
import '../utils/game_data.dart';

class ArmoryView extends StatelessWidget {
  final VoidCallback? onBack;

  const ArmoryView({super.key, this.onBack});

  // 🟢 ترجمة أسماء الأسلحة والدروع (مع إضافة حزمة علاء الدين) 🟢
  String _translateItemId(String id) {
    Map<String, String> names = {
      'dagger': 'خنجر', 'revolver': 'مسدس', 'katana': 'سيف كاتانا', 'shotgun': 'بندقية صيد', 'sniper': 'قناصة',
      'riot_shield': 'درع مكافحة شغب', 'kevlar_vest': 'سترة كيفلار', 'ninja_suit': 'بدلة نينجا', 'steel_armor': 'درع فولاذي', 'exoskeleton': 'هيكل خارجي',
      'w_aladdin_damage': 'سيف علاء الدين القاطع',
      'w_aladdin_accuracy': 'خنجر علاء الدين السحري',
      'a_aladdin_defense': 'درع الجني الفولاذي',
      'a_aladdin_evasion': 'عباءة علاء الدين',
      't_aladdin_lamp': 'المصباح السحري',
      't_aladdin_carpet': 'البساط الطائر',
    };
    if (names.containsKey(id)) return names[id]!;

    if (id.startsWith('w_') || id.startsWith('a_')) {
      String type = id.startsWith('w_') ? 'سلاح' : 'درع';
      String color = '';
      if (id.contains('_silver_')) color = 'فضي';
      else if (id.contains('_green_')) color = 'أخضر';
      else if (id.contains('_blue_')) color = 'أزرق';
      else if (id.contains('_purple_')) color = 'بنفسجي';
      else if (id.contains('_gold_')) color = 'ذهبي';
      else if (id.contains('_red_')) color = 'أحمر';

      String style = '';
      if (id.endsWith('_heavy')) style = 'ثقيل';
      else if (id.endsWith('_assault')) style = 'هجومي';
      else if (id.endsWith('_balanced')) style = 'متوازن';
      else if (id.endsWith('_tactical')) style = 'تكتيكي';
      else if (id.endsWith('_agile')) style = 'خفيف';

      return '$type $color $style'.trim();
    }
    return id;
  }

  // 🟢 أيقونات الأسلحة والدروع والأدوات 🟢
  IconData _getItemIcon(String id) {
    if (id == 't_aladdin_lamp') return Icons.lightbulb;
    if (id == 't_aladdin_carpet') return Icons.map;
    if (id == 'a_aladdin_evasion') return Icons.air;
    if (id.startsWith('w_') || ['dagger','revolver','katana','shotgun','sniper'].contains(id)) return Icons.hardware;
    if (id.startsWith('a_') || ['riot_shield','kevlar_vest','ninja_suit','steel_armor','exoskeleton'].contains(id)) return Icons.shield;
    return Icons.category;
  }

  Widget _buildEquipSlot(String title, String? equippedId, IconData defaultIcon, Color color) {
    bool isEquipped = equippedId != null;
    return SizedBox(
      width: 75,
      child: Column(
        children: [
          Container(
            width: 65, height: 65,
            decoration: BoxDecoration(
              color: isEquipped ? color.withOpacity(0.2) : Colors.black45,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isEquipped ? color : Colors.white24, width: 2),
              boxShadow: isEquipped ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)] : [],
            ),
            child: Center(
              child: isEquipped
                  ? Icon(_getItemIcon(equippedId), color: color, size: 35)
                  : Icon(defaultIcon, color: Colors.white24, size: 30),
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          if (isEquipped)
            Text(_translateItemId(equippedId), style: TextStyle(color: color, fontSize: 9, fontFamily: 'Changa', fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }

  // 🟢 تعديل المربعات لتكون من اليمين إلى اليسار 🟢
  Widget _buildEquippedSlotsRow(PlayerProvider player) {
    return Directionality(
      textDirection: TextDirection.rtl, // هذا التعديل خلى السلاح يمين، والدرع جنبه، وهكذا!
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEquipSlot('سلاح', player.equippedWeaponId, Icons.hardware, Colors.deepOrange),
            _buildEquipSlot('درع', player.equippedArmorId, Icons.shield, Colors.blue),
            _buildEquipSlot('أداة خاصة', player.equippedCrimeToolId, Icons.build, Colors.amber),
            _buildEquipSlot('كيمياء', null, Icons.science, Colors.green), // قيد الإنشاء
          ],
        ),
      ),
    );
  }

  // قائمة بناء الأسلحة والدروع
  Widget _buildInventoryList(PlayerProvider player, AudioProvider audio, Map<String, Map<String, double>> itemStats, String? currentEquippedId, Color themeColor) {
    var items = player.inventory.entries.where((e) => itemStats.containsKey(e.key)).toList();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 15),
            const Text("لا تملك أي عناصر هنا", style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 16)),
            const SizedBox(height: 5),
            const Text("قم بزيارة السوق السوداء لشراء العتاد", style: TextStyle(color: Colors.white30, fontFamily: 'Changa', fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: items.length,
        itemBuilder: (context, index) {
          String itemId = items[index].key;
          int count = items[index].value;
          bool isEquipped = currentEquippedId == itemId;
          var stats = itemStats[itemId]!;

          String statText = stats.entries.map((e) {
            String keyAr = e.key == 'str' ? 'قوة' : e.key == 'spd' ? 'سرعة' : e.key == 'def' ? 'دفاع' : 'مهارة';
            return "$keyAr +${(e.value * 100).toInt()}%";
          }).join(" | ");

          return Card(
            color: isEquipped ? themeColor.withOpacity(0.15) : Colors.black45,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isEquipped ? themeColor : Colors.white10)),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: themeColor.withOpacity(0.5))),
                child: Icon(_getItemIcon(itemId), color: themeColor),
              ),
              title: Text(_translateItemId(itemId), style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(statText, style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontFamily: 'Changa')),
                  const SizedBox(height: 2),
                  Text("الكمية: $count", style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Changa')),
                ],
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: isEquipped ? Colors.grey[800] : themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () {
                  audio.playEffect('click.mp3');
                  player.useItem(itemId);
                },
                child: Text(isEquipped ? 'خلع' : 'تجهيز', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }
    );
  }

  // 🟢 قائمة جديدة مخصصة للأدوات الخاصة (عشان البساط والمصباح يظهرون فيها وتقدر تجهزهم) 🟢
  Widget _buildToolsInventoryList(PlayerProvider player, AudioProvider audio, List<String> toolIds, String? currentEquippedId, Color themeColor) {
    var items = player.inventory.entries.where((e) => toolIds.contains(e.key)).toList();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 15),
            const Text("لا تملك أي أدوات هنا", style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: items.length,
        itemBuilder: (context, index) {
          String itemId = items[index].key;
          int count = items[index].value;
          bool isEquipped = currentEquippedId == itemId;

          return Card(
            color: isEquipped ? themeColor.withOpacity(0.15) : Colors.black45,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isEquipped ? themeColor : Colors.white10)),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: themeColor.withOpacity(0.5))),
                child: Icon(_getItemIcon(itemId), color: themeColor),
              ),
              title: Text(_translateItemId(itemId), style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text("أداة خاصة (المزايا قيد التطوير)", style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontFamily: 'Changa')),
                  const SizedBox(height: 2),
                  Text("الكمية: $count", style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Changa')),
                ],
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: isEquipped ? Colors.grey[800] : themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () {
                  audio.playEffect('click.mp3');
                  player.useItem(itemId);
                },
                child: Text(isEquipped ? 'خلع' : 'تجهيز', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }
    );
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 15),
          Text("سوق $title قيد الإنشاء", style: const TextStyle(color: Colors.white54, fontSize: 18, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("قريباً ستتمكن من تجهيزها من هنا", style: TextStyle(color: Colors.white30, fontSize: 13, fontFamily: 'Changa')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        body: Column(
          children: [
            TopBar(
              cash: player.cash, gold: player.gold, level: player.crimeLevel, currentXp: player.crimeXP, maxXp: player.xpToNextLevel,
              health: player.health, maxHealth: player.maxHealth, energy: player.energy, maxEnergy: player.maxEnergy,
              courage: player.courage, maxCourage: player.maxCourage, prestige: player.prestige, maxPrestige: player.maxPrestige,
              playerName: player.playerName, profilePicUrl: player.profilePicUrl, isVIP: player.isVIP,
            ),

            const Padding(padding: EdgeInsets.only(top: 15.0, bottom: 5.0), child: Center(child: Text('التسليح', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Changa')))),

            _buildEquippedSlotsRow(player),
            const Divider(color: Colors.white24, thickness: 1, height: 10),

            Directionality(
              textDirection: TextDirection.rtl,
              child: TabBar(
                isScrollable: true, indicatorColor: Colors.amber, indicatorWeight: 3, labelColor: Colors.amber, unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13), dividerColor: Colors.transparent,
                onTap: (index) => audio.playEffect('click.mp3'),
                tabs: const [
                  Tab(text: 'الأسلحة', icon: Icon(Icons.hardware)),
                  Tab(text: 'الدروع', icon: Icon(Icons.shield)),
                  Tab(text: 'أدوات خاصة', icon: Icon(Icons.construction)),
                  Tab(text: 'كيمياء', icon: Icon(Icons.science)),
                ],
              ),
            ),

            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: TabBarView(
                  children: [
                    _buildInventoryList(player, audio, GameData.weaponStats, player.equippedWeaponId, Colors.deepOrange),
                    _buildInventoryList(player, audio, GameData.armorStats, player.equippedArmorId, Colors.blue),
                    _buildToolsInventoryList(player, audio, GameData.crimeToolsList, player.equippedCrimeToolId, Colors.amber),
                    _buildPlaceholder('الكيمياء', Icons.science),
                  ],
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(color: Colors.black87, image: DecorationImage(image: AssetImage('assets/images/ui/bottom_navbar_bg.png'), fit: BoxFit.cover), border: Border(top: BorderSide(color: Color(0xFF856024), width: 2))),
            padding: const EdgeInsets.only(top: 10, bottom: 20, left: 15, right: 15),
            child: SafeArea(
              bottom: true, top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () { audio.playEffect('click.mp3'); if (onBack != null) onBack!(); else Navigator.pop(context); },
                    child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_forward_ios, color: Color(0xFFE2C275), size: 24), SizedBox(height: 4), Text('رجوع', style: TextStyle(color: Color(0xFFE2C275), fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                  ),
                  GestureDetector(
                    onTap: () { audio.playEffect('click.mp3'); showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1A1A1D), shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.amber, width: 2), borderRadius: BorderRadius.circular(15)), title: const Text('شرح التسليح', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.right), content: const Text('المربعات العلوية تظهر عتادك المجهز حالياً.\n\nتجهيز الأسلحة سيزيد من قوتك في الهجوم ضد اللاعبين، وتجهيز الدروع سيقلل الأضرار التي تتلقاها.', style: TextStyle(color: Colors.white, fontFamily: 'Changa', height: 1.5), textAlign: TextAlign.right), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('فهمت', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)))])); },
                    child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.help_outline, color: Colors.white70, size: 24), SizedBox(height: 4), Text('شرح', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}