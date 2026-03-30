import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/quick_recovery_dialog.dart';

class CrimeView extends StatelessWidget {
  final int courage;
  final List<dynamic> crimeSuccessCounts; // خليتها dynamic عشان تتوافق مع بيانات الفايربيس
  final Function(int reward, int index, int energyUsed) onSuccess;
  final VoidCallback onFailure;

  static final Random _random = Random();

  const CrimeView({
    super.key,
    required this.courage,
    required this.crimeSuccessCounts,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // قائمة الجرائم بمنطقك البرمجي الكامل
    final List<Map<String, dynamic>> crimes = [
      {'name': 'سرقة محفظة', 'courage': 5, 'energy': 0, 'minCash': 50, 'maxCash': 100, 'failChance': 0.1, 'xp': 10, 'icon': Icons.account_balance_wallet, 'color': const Color(0xFFC5A059), 'heat': 2.0},
      {'name': 'سطو على متجر', 'courage': 15, 'energy': 0, 'minCash': 300, 'maxCash': 500, 'failChance': 0.25, 'xp': 25, 'icon': Icons.store, 'color': Colors.blueAccent, 'heat': 5.0},
      {'name': 'سرقة سيارة', 'courage': 30, 'energy': 10, 'minCash': 1000, 'maxCash': 2000, 'failChance': 0.45, 'xp': 60, 'icon': Icons.directions_car, 'color': Colors.orangeAccent, 'requireItem': 'black_mask', 'itemName': 'قناع أسود', 'heat': 10.0},
      {'name': 'سطو على فيلا', 'courage': 45, 'energy': 20, 'minCash': 4000, 'maxCash': 7500, 'failChance': 0.6, 'xp': 120, 'icon': Icons.home, 'color': Colors.purpleAccent, 'requireItem': 'master_key', 'itemName': 'المفتاح الرئيسي', 'heat': 15.0},
      {'name': 'سطو على البنك', 'courage': 70, 'energy': 40, 'minCash': 18000, 'maxCash': 40000, 'failChance': 0.8, 'xp': 350, 'icon': Icons.account_balance, 'color': Colors.redAccent, 'requireCar': true, 'requireItem': 'silicon_mask', 'itemName': 'قناع سيليكون وسيارة', 'heat': 25.0},
    ];

    return Container(
      // 1. إضافة الخلفية السينمائية
      decoration: BoxDecoration(
        color: Colors.black,
        image: const DecorationImage(
          image: AssetImage('assets/images/ui/crime_bg.jpg'), // مسار الصورة حسب ملفاتك
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken), // تغميق لبروز النصوص
        ),
      ),
      child: Column(
        children: [
          // عداد الملاحقة (Heat)
          _buildHeatMeter(player.heat),

          // العنوان الفخم
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              border: const Border(
                top: BorderSide(color: Color(0xFF856024), width: 1),
                bottom: BorderSide(color: Color(0xFF856024), width: 1),
              ),
            ),
            child: const Column(
              children: [
                Text('السجل الإجرامي 🎭', style: TextStyle(fontFamily: 'Changa', color: Color(0xFFE2C275), fontSize: 22, fontWeight: FontWeight.bold)),
                Text('احترافك للجرائم يزيد من أرباحك ويقلل المخاطر', style: TextStyle(fontFamily: 'Changa', color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),

          // قائمة المهام
          Expanded(
            child: ListView.builder(
              itemCount: crimes.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final crime = crimes[index];
                int successCount = index < crimeSuccessCounts.length ? (crimeSuccessCounts[index] as num).toInt() : 0;

                int stars = successCount >= 50 ? 3 : successCount >= 25 ? 2 : successCount >= 10 ? 1 : 0;
                double progress = stars == 3 ? 1.0 : (stars == 2 ? (successCount - 25) / 25 : stars == 1 ? (successCount - 10) / 15 : successCount / 10);

                bool isSequenceUnlocked = index == 0 || (index > 0 && crimeSuccessCounts[index - 1] >= 10);
                bool hasItem = crime.containsKey('requireItem') ? player.inventory.containsKey(crime['requireItem']) : true;
                bool hasCar = crime.containsKey('requireCar') ? player.activeCarId != null : true;
                bool isUnlocked = isSequenceUnlocked && hasItem && hasCar;

                double heatPenalty = (player.heat / 100) * 0.3;
                double finalFailChance = (crime['failChance'] as double) + heatPenalty - (stars * 0.05);

                if (player.equippedMaskId != null) finalFailChance -= 0.1;

                // نظام متانة الأدوات الخاص بك (Durability Logic)
                if (player.equippedCrimeToolId != null) {
                  double toolDurability = player.getItemDurability(player.equippedCrimeToolId!);
                  double toolBonus = 0.0;

                  if (player.equippedCrimeToolId == 'emp_device') toolBonus = 0.30;
                  else if (player.equippedCrimeToolId == 'thermite' && crime['name'] == 'سطو على البنك') toolBonus = 0.25;
                  else if (player.equippedCrimeToolId == 'slim_jim' && crime['name'] == 'سرقة سيارة') toolBonus = 0.15;
                  else if (player.equippedCrimeToolId == 'lockpick' && crime['name'] == 'سطو على فيلا') toolBonus = 0.15;
                  else toolBonus = 0.10;

                  if (toolDurability >= 10) {
                    finalFailChance -= toolBonus;
                  } else {
                    finalFailChance -= (toolBonus / 2); // الأداة معطلة
                  }
                }

                finalFailChance = finalFailChance.clamp(0.02, 0.98);

                return _buildGoldCrimeCard(context, player, index, crime, isUnlocked, stars, progress, finalFailChance, hasItem, hasCar);
              },
            ),
          )
        ],
      ),
    );
  }

  // 2. تزيين عداد الملاحقة بستايل المافيا
  Widget _buildHeatMeter(double heatValue) {
    Color heatColor = heatValue > 70 ? Colors.redAccent : heatValue > 40 ? Colors.orangeAccent : const Color(0xFFE2C275);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: heatColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: heatColor.withOpacity(0.1), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.local_police, color: heatColor, size: 20),
                const SizedBox(width: 8),
                const Text('مستوى ملاحقة الشرطة', style: TextStyle(fontFamily: 'Changa', color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
              ]),
              Text('${heatValue.toInt()}%', style: TextStyle(fontFamily: 'Changa', color: heatColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
                value: heatValue / 100,
                backgroundColor: Colors.grey[900],
                valueColor: AlwaysStoppedAnimation<Color>(heatColor),
                minHeight: 8
            ),
          ),
        ],
      ),
    );
  }

  // 3. تصميم بطاقة الجريمة كأنها "ملف سري" ذهبي
  Widget _buildGoldCrimeCard(BuildContext context, PlayerProvider player, int index, Map<String, dynamic> crime, bool isUnlocked, int stars, double progress, double failChance, bool hasItem, bool hasCar) {
    Color mainColor = isUnlocked ? crime['color'] : Colors.grey[800]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isUnlocked ? mainColor.withOpacity(0.6) : Colors.white10, width: 1.5),
        boxShadow: isUnlocked ? [BoxShadow(color: mainColor.withOpacity(0.15), blurRadius: 8)] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleCrimeClick(context, player, index, crime, isUnlocked, hasItem, hasCar, failChance),
            highlightColor: mainColor.withOpacity(0.2),
            splashColor: mainColor.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // الأيقونة مع دائرة التقدم
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(width: 55, height: 55, child: CircularProgressIndicator(value: progress, color: mainColor, backgroundColor: Colors.white10, strokeWidth: 3.5)),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: mainColor.withOpacity(0.1)),
                            child: Icon(crime['icon'], color: isUnlocked ? Colors.white : Colors.white24, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      // اسم الجريمة والنجوم
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(crime['name'], style: TextStyle(fontFamily: 'Changa', color: isUnlocked ? Colors.white : Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(children: List.generate(3, (i) => Icon(Icons.star, size: 16, color: i < stars ? const Color(0xFFE2C275) : Colors.white10))),
                          ],
                        ),
                      ),
                      // الكاش المتوقع
                      if (isUnlocked)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${crime['minCash']} - \$${crime['maxCash']}', style: const TextStyle(fontFamily: 'Changa', color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                            const Text('كاش متوقع', style: TextStyle(fontFamily: 'Changa', color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // تفاصيل وتكاليف الجريمة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSmallInfo(Icons.shield, '${crime['courage']}', Colors.orangeAccent),
                        if (crime['energy'] > 0) _buildSmallInfo(Icons.bolt, '${crime['energy']}', Colors.yellowAccent),
                        _buildSmallInfo(Icons.dangerous, '${(failChance * 100).toInt()}% خطر', failChance > 0.5 ? Colors.redAccent : Colors.greenAccent),
                        if (!isUnlocked)
                          Expanded(
                            child: Text(
                              _getLockReason(index, hasItem, hasCar, crime['itemName'] ?? ''),
                              style: const TextStyle(fontFamily: 'Changa', color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text, Color color) {
    return Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontFamily: 'Changa', color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))
        ]
    );
  }

  String _getLockReason(int index, bool hasItem, bool hasCar, String itemName) {
    if (index > 0 && crimeSuccessCounts[index - 1] < 10) return 'أكمل السابقة 10 مرات';
    if (!hasItem) return 'مطلوب: $itemName';
    if (!hasCar) return 'مطلوب سيارة';
    return 'مغلق';
  }

  // --- التفاعل والمنطق الخلفي (لم يتم تغييره) ---
  void _handleCrimeClick(BuildContext context, PlayerProvider player, int index, Map<String, dynamic> crime, bool isUnlocked, bool hasItem, bool hasCar, double finalFailChance) {
    if (!isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكمل المتطلبات أولاً! 🔒', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
      return;
    }

    int reqCourage = crime['courage'] as int;
    int reqEnergy = crime['energy'] as int;

    if (player.courage < reqCourage) {
      QuickRecoveryDialog.show(context, 'courage', reqCourage - player.courage);
      return;
    }
    if (player.energy < reqEnergy) {
      QuickRecoveryDialog.show(context, 'energy', reqEnergy - player.energy);
      return;
    }

    if (player.equippedCrimeToolId != null && player.getItemDurability(player.equippedCrimeToolId!) < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ أداة الجريمة معطلة! كفاءتها انخفضت للنصف وتحتاج إصلاح.', style: TextStyle(fontFamily: 'Changa'))));
    }

    double crimeHeat = crime['heat'] as double;

    if (_random.nextDouble() < finalFailChance) {
      player.increaseHeat(crimeHeat * 1.5);
      player.setCourage(player.courage - reqCourage);
      if (reqEnergy > 0) player.setEnergy(player.energy - reqEnergy);
      onFailure();
    } else {
      player.increaseHeat(crimeHeat);

      if (player.equippedCrimeToolId != null) {
        double durabilityLoss = 5.0;
        switch (player.equippedCrimeToolId) {
          case 'crowbar': durabilityLoss = 10.0; break;
          case 'slim_jim': durabilityLoss = 8.0; break;
          case 'jammer': durabilityLoss = 6.0; break;
          case 'lockpick': durabilityLoss = 5.0; break;
          case 'glass_cutter': durabilityLoss = 4.0; break;
          case 'stethoscope': durabilityLoss = 4.0; break;
          case 'laptop': durabilityLoss = 3.0; break;
          case 'hydraulic': durabilityLoss = 3.0; break;
          case 'thermite': durabilityLoss = 2.0; break;
          case 'emp_device': durabilityLoss = 1.0; break;
        }
        player.reduceDurability(player.equippedCrimeToolId, durabilityLoss);
      }

      int reward = (crime['minCash'] as int) + _random.nextInt((crime['maxCash'] as int) - (crime['minCash'] as int) + 1);

      _checkRandomEvent(context, player);

      player.addCrimeXP(crime['xp'] as int);
      onSuccess(reward, index, reqEnergy);
    }
  }

  void _checkRandomEvent(BuildContext context, PlayerProvider player) {
    if (_random.nextDouble() < 0.15) {
      int eventType = _random.nextInt(4);
      if (eventType == 0) {
        player.addGold(1);
        _showEventSnackBar(context, "💎 وجدت قطعة ذهب أثناء الهروب!", Colors.blueAccent);
      } else if (eventType == 1) {
        int bonus = 500 + _random.nextInt(1001);
        player.addCash(bonus, reason: "كاش إضافي من حدث عشوائي");
        _showEventSnackBar(context, "💰 وجدت محفظة إضافية ملقاة! +$bonus كاش", Colors.green);
      } else if (eventType == 2) {
        player.setEnergy(min(player.maxEnergy, player.energy + 10));
        _showEventSnackBar(context, "⚡ جرعة أدريناين! استعدت 10 طاقة فوراً", Colors.orange);
      } else {
        player.reduceHeat(10.0);
        _showEventSnackBar(context, "👮 ضيعت عيون الشرطة! انخفض مستوى الملاحقة.", Colors.teal);
      }
    }
  }

  void _showEventSnackBar(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: color, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }
}