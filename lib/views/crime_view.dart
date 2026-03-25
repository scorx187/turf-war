import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class CrimeView extends StatelessWidget {
  final int courage;
  final List<int> crimeSuccessCounts;
  final Function(int reward, int index, int energyUsed) onSuccess;
  final VoidCallback onFailure;

  // تعريف كائن Random مرة واحدة لتوزيع الاحتمالات بشكل عادل ودقيق
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

    // --- إعدادات الجرائم المدمجة (Diamond Standard) ---
    final List<Map<String, dynamic>> crimes = [
      {
        'name': 'سرقة محفظة',
        'courage': 5,
        'energy': 0,
        'minCash': 50,
        'maxCash': 100,
        'failChance': 0.1,
        'xp': 10,
        'icon': Icons.account_balance_wallet,
        'color': Colors.grey,
        'heat': 2.0,
      },
      {
        'name': 'سطو على متجر',
        'courage': 15,
        'energy': 0,
        'minCash': 300,
        'maxCash': 500,
        'failChance': 0.25,
        'xp': 25,
        'icon': Icons.store,
        'color': Colors.blue,
        'heat': 5.0,
      },
      {
        'name': 'سرقة سيارة',
        'courage': 30,
        'energy': 10,
        'minCash': 1000,
        'maxCash': 2000,
        'failChance': 0.45,
        'xp': 60,
        'icon': Icons.directions_car,
        'color': Colors.orange,
        'requireItem': 'black_mask',
        'itemName': 'قناع أسود',
        'heat': 10.0,
      },
      {
        'name': 'سطو على فيلا',
        'courage': 45,
        'energy': 20,
        'minCash': 4000,
        'maxCash': 7500,
        'failChance': 0.6,
        'xp': 120,
        'icon': Icons.home,
        'color': Colors.purple,
        'requireItem': 'master_key',
        'itemName': 'المفتاح الرئيسي',
        'heat': 15.0,
      },
      {
        'name': 'سطو على البنك',
        'courage': 70,
        'energy': 40,
        'minCash': 18000,
        'maxCash': 40000,
        'failChance': 0.8,
        'xp': 350,
        'icon': Icons.account_balance,
        'color': Colors.red,
        'requireCar': true,
        'requireItem': 'silicon_mask',
        'itemName': 'قناع سيليكون وسيارة',
        'heat': 25.0,
      },
    ];

    return Column(
      children: [
        _buildHeatMeter(player.heat),

        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Text('السجل الإجرامي الأسطوري 🎭',
                  style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('احترافك للجرائم يزيد من أرباحك ويقلل المخاطر',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: crimes.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final crime = crimes[index];
              int successCount = index < crimeSuccessCounts.length ? crimeSuccessCounts[index] : 0;

              // حساب النجوم (الاحتراف)
              int stars = successCount >= 50 ? 3 : successCount >= 25 ? 2 : successCount >= 10 ? 1 : 0;
              double progress = stars == 3 ? 1.0 : (stars == 2 ? (successCount - 25) / 25 : stars == 1 ? (successCount - 10) / 15 : successCount / 10);

              // شروط الفتح
              bool isSequenceUnlocked = index == 0 || (index > 0 && crimeSuccessCounts[index - 1] >= 10);
              bool hasItem = crime.containsKey('requireItem') ? player.inventory.containsKey(crime['requireItem']) : true;
              bool hasCar = crime.containsKey('requireCar') ? player.activeCarId != null : true;
              bool isUnlocked = isSequenceUnlocked && hasItem && hasCar;

              // [توحيد حساب النسبة] يتم هنا عرض النسبة الحقيقية اللي بتطبق وقت الضغط
              double heatPenalty = (player.heat / 100) * 0.3; // زيادة تصل لـ 30% فشل بسبب الحرارة
              double finalFailChance = (crime['failChance'] as double) + heatPenalty - (stars * 0.05);

              // خصم القناع
              if (player.equippedMaskId != null) finalFailChance -= 0.1;

              // تأثير أداة الجريمة المجهزة (الخصم أو العقوبة)
              if (player.equippedCrimeToolId != null) {
                double toolDurability = player.getItemDurability(player.equippedCrimeToolId!);
                if (toolDurability >= 10) {
                  // الأداة سليمة: تعطي الخصم
                  if (player.equippedCrimeToolId == 'emp_device') {
                    finalFailChance -= 0.30;
                  } else if (player.equippedCrimeToolId == 'thermite' && crime['name'] == 'سطو على البنك') {
                    finalFailChance -= 0.25;
                  } else if (player.equippedCrimeToolId == 'slim_jim' && crime['name'] == 'سرقة سيارة') {
                    finalFailChance -= 0.15;
                  } else if (player.equippedCrimeToolId == 'lockpick' && crime['name'] == 'سطو على فيلا') {
                    finalFailChance -= 0.15;
                  } else {
                    finalFailChance -= 0.10;
                  }
                } else {
                  // الأداة معطلة: تزيد نسبة الفشل بـ 20% وتظهر للمستخدم في الشاشة
                  finalFailChance += 0.20;
                }
              }

              // التأكد إن النسبة ما تنزل عن 2% وما تتعدى 98%
              finalFailChance = finalFailChance.clamp(0.02, 0.98);

              return _buildGoldCrimeCard(context, player, index, crime, isUnlocked, stars, progress, finalFailChance, hasItem, hasCar);
            },
          ),
        )
      ],
    );
  }

  Widget _buildHeatMeter(double heatValue) {
    Color heatColor = heatValue > 70 ? Colors.red : heatValue > 40 ? Colors.orange : Colors.yellow;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: heatColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(Icons.local_police, color: heatColor, size: 18), const SizedBox(width: 8), const Text('مستوى ملاحقة الشرطة', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))]),
              Text('${heatValue.toInt()}%', style: TextStyle(color: heatColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: heatValue / 100, backgroundColor: Colors.white10, color: heatColor, minHeight: 6),
        ],
      ),
    );
  }

  Widget _buildGoldCrimeCard(BuildContext context, PlayerProvider player, int index, Map<String, dynamic> crime, bool isUnlocked, int stars, double progress, double failChance, bool hasItem, bool hasCar) {
    Color mainColor = isUnlocked ? crime['color'] : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUnlocked ? mainColor.withValues(alpha: 0.5) : Colors.white10, width: 1.5),
        boxShadow: isUnlocked ? [BoxShadow(color: mainColor.withValues(alpha: 0.1), blurRadius: 10)] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _handleCrimeClick(context, player, index, crime, isUnlocked, hasItem, hasCar, failChance),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(width: 50, height: 50, child: CircularProgressIndicator(value: progress, color: mainColor, backgroundColor: Colors.white10, strokeWidth: 3)),
                        Icon(crime['icon'], color: isUnlocked ? Colors.white : Colors.white24, size: 24),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(crime['name'], style: TextStyle(color: isUnlocked ? Colors.white : Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: List.generate(3, (i) => Icon(Icons.star, size: 16, color: i < stars ? Colors.amber : Colors.white10)),
                          ),
                        ],
                      ),
                    ),
                    if (isUnlocked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${crime['minCash']}-${crime['maxCash']}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('كاش متوقع', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSmallInfo(Icons.bolt, '${crime['courage']}', Colors.orange),
                    if (crime['energy'] > 0) _buildSmallInfo(Icons.flash_on, '${crime['energy']}', Colors.yellow),
                    _buildSmallInfo(Icons.dangerous, '${(failChance * 100).toInt()}%', failChance > 0.5 ? Colors.redAccent : Colors.greenAccent),
                    if (!isUnlocked)
                      Text(_getLockReason(index, hasItem, hasCar, crime['itemName'] ?? ''), style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  String _getLockReason(int index, bool hasItem, bool hasCar, String itemName) {
    if (index > 0 && crimeSuccessCounts[index - 1] < 10) return 'أكمل السابقة 10 مرات';
    if (!hasItem) return 'مطلوب: $itemName';
    if (!hasCar) return 'مطلوب سيارة مجهزة';
    return 'مغلق';
  }

  // دالة مخصصة لعرض الـ Dialog داخل الشاشة مباشرة لضمان عملها 100%
  void _showRecoveryDialog(BuildContext context, String type, int missingAmount) {
    bool isCourage = type == 'courage';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isCourage ? Colors.orange : Colors.yellow, width: 2)),
        title: Row(
          children: [
            Icon(isCourage ? Icons.bolt : Icons.flash_on, color: isCourage ? Colors.orange : Colors.yellow, size: 28),
            const SizedBox(width: 10),
            Text(isCourage ? 'شجاعة غير كافية!' : 'طاقة غير كافية!', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'ينقصك $missingAmount ${isCourage ? 'شجاعة' : 'طاقة'} للقيام بهذه الجريمة.\n\nاذهب إلى المخزن واستخدم ${isCourage ? '(قهوة مركزة ☕)' : '(حقنة منشط 💉)'} لتعويض النقص فوراً، أو انتظر قليلاً.',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCourage ? Colors.orange : Colors.yellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleCrimeClick(BuildContext context, PlayerProvider player, int index, Map<String, dynamic> crime, bool isUnlocked, bool hasItem, bool hasCar, double finalFailChance) {
    if (!isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكمل المتطلبات أولاً! 🔒'), backgroundColor: Colors.redAccent));
      return;
    }

    int reqCourage = crime['courage'] as int;
    int reqEnergy = crime['energy'] as int;

    // استدعاء الدالة المدمجة المخصصة
    if (player.courage < reqCourage) {
      _showRecoveryDialog(context, 'courage', reqCourage - player.courage);
      return;
    }
    if (player.energy < reqEnergy) {
      _showRecoveryDialog(context, 'energy', reqEnergy - player.energy);
      return;
    }

    if (player.equippedCrimeToolId != null && player.getItemDurability(player.equippedCrimeToolId!) < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ أداة الجريمة معطلة وتحتاج إصلاح! نسبة الفشل لديك مرتفعة.')));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}