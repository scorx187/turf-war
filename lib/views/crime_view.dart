// المسار: lib/views/crime_view.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/quick_recovery_dialog.dart';
import '../utils/crime_data.dart';

class CrimeView extends StatefulWidget {
  final int courage;
  final Function(int reward, String crimeId, int energyUsed) onSuccess;
  final VoidCallback onFailure;

  const CrimeView({
    super.key,
    required this.courage,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<CrimeView> createState() => _CrimeViewState();
}

class _CrimeViewState extends State<CrimeView> {
  static final Random _random = Random();
  int? _selectedCategoryIndex;

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/ui/crime_bg.jpg',
            fit: BoxFit.cover,
            gaplessPlayback: true,
            color: Colors.black.withOpacity(0.7),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        Column(
          children: [
            _buildHeatMeter(player.heat),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _selectedCategoryIndex == null
                    ? _buildCategoriesList(player)
                    : _buildCrimesList(player, _selectedCategoryIndex!),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesList(PlayerProvider player) {
    return Column(
      key: const ValueKey('CategoriesList'),
      children: [
        _buildHeader('العالم السفلي 🎭', 'اختر فئة إجرامية للبدء بعملياتك', null),
        Expanded(
          child: ListView.builder(
            itemCount: CrimeData.categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemBuilder: (context, catIndex) {
              final category = CrimeData.categories[catIndex];

              bool isCategoryUnlocked = true;
              if (catIndex > 0) {
                String prevCatLastCrimeId = 'cat_${catIndex - 1}_crime_19';
                int prevCatLastCrimeCount = player.crimeSuccessCountsMap[prevCatLastCrimeId] ?? 0;
                isCategoryUnlocked = prevCatLastCrimeCount >= 10;
              }

              return Card(
                color: Colors.black87,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: isCategoryUnlocked ? category['color'].withOpacity(0.5) : Colors.white10, width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    if (!isCategoryUnlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 يجب إنهاء الفئة السابقة بالكامل لفتح هذه الفئة!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
                      return;
                    }
                    setState(() {
                      _selectedCategoryIndex = catIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isCategoryUnlocked ? category['color'].withOpacity(0.2) : Colors.white10),
                          child: Icon(category['icon'], color: isCategoryUnlocked ? category['color'] : Colors.white30, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category['name'], style: TextStyle(fontFamily: 'Changa', color: isCategoryUnlocked ? Colors.white : Colors.white30, fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(isCategoryUnlocked ? '20 مهمة متاحة للعب' : 'مغلق 🔒', style: TextStyle(fontFamily: 'Changa', color: isCategoryUnlocked ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: isCategoryUnlocked ? Colors.white54 : Colors.transparent, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCrimesList(PlayerProvider player, int catIndex) {
    final category = CrimeData.categories[catIndex];
    List<Map<String, dynamic>> crimes = CrimeData.getCrimesForCategory(catIndex);
    Color mainColor = category['color'];

    return Column(
      key: const ValueKey('CrimesList'),
      children: [
        _buildHeader(category['name'], 'أكمل الجريمة 10 مرات لتفتح التي تليها', () {
          setState(() {
            _selectedCategoryIndex = null;
          });
        }),
        Expanded(
          child: ListView.builder(
            itemCount: crimes.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemBuilder: (context, crimeIndex) {
              Map<String, dynamic> crime = crimes[crimeIndex];
              String crimeId = crime['id'];

              int successCount = player.crimeSuccessCountsMap[crimeId] ?? 0;
              int stars = successCount >= 50 ? 3 : successCount >= 25 ? 2 : successCount >= 10 ? 1 : 0;

              bool isCrimeUnlocked = true;
              if (crimeIndex > 0) {
                String prevCrimeId = crimes[crimeIndex - 1]['id'];
                isCrimeUnlocked = (player.crimeSuccessCountsMap[prevCrimeId] ?? 0) >= 10;
              }

              double heatPenalty = (player.heat / 100) * 0.3;
              double finalFailChance = (crime['failChance'] as double) + heatPenalty - (stars * 0.05);
              if (player.equippedMaskId != null) finalFailChance -= 0.1;

              if (player.equippedCrimeToolId != null) {
                double toolDurability = player.getItemDurability(player.equippedCrimeToolId!);
                double toolBonus = 0.0;
                if (player.equippedCrimeToolId == 'emp_device') toolBonus = 0.30;
                else if (player.equippedCrimeToolId == 'thermite' && catIndex >= 14) toolBonus = 0.25;
                else if (player.equippedCrimeToolId == 'slim_jim' && (catIndex == 3 || catIndex == 6)) toolBonus = 0.15;
                else if (player.equippedCrimeToolId == 'lockpick' && catIndex == 4) toolBonus = 0.15;
                else toolBonus = 0.10;

                if (toolDurability >= 10) finalFailChance -= toolBonus;
                else finalFailChance -= (toolBonus / 2);
              }

              finalFailChance = finalFailChance.clamp(0.00, 0.98);

              int successPercentage = ((1.0 - finalFailChance) * 100).toInt();

              Color successColor = successPercentage >= 80 ? Colors.greenAccent
                  : successPercentage >= 50 ? Colors.orangeAccent
                  : Colors.redAccent;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isCrimeUnlocked ? mainColor.withOpacity(0.5) : Colors.white10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  enabled: isCrimeUnlocked,
                  onTap: () => _handleCrimeClick(context, player, crime, isCrimeUnlocked, finalFailChance),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: stars == 3 ? 1.0 : (stars == 2 ? (successCount - 25) / 25 : stars == 1 ? (successCount - 10) / 15 : successCount / 10),
                        color: mainColor, backgroundColor: Colors.white10,
                      ),
                      Icon(category['icon'], color: isCrimeUnlocked ? Colors.white : Colors.white24, size: 20),
                    ],
                  ),

                  // 🟢 حل مشكلة التمدد بالاسم
                  title: Text(
                    crime['name'],
                    style: TextStyle(fontFamily: 'Changa', color: isCrimeUnlocked ? Colors.white : Colors.white30, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 🟢 حل مشكلة الـ Overflow باستخدام Wrap
                  subtitle: isCrimeUnlocked
                      ? Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6, // مسافة أفقية بين العناصر
                      runSpacing: 4, // مسافة عمودية في حال نزول عنصر لسطر جديد
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) => Icon(Icons.star, size: 14, color: i < stars ? const Color(0xFFE2C275) : Colors.white10)),
                        ),
                        Text(
                            'نجاح: $successCount',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Changa')
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: successColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: successColor.withOpacity(0.5)),
                          ),
                          child: Text(
                              'النسبة: $successPercentage%',
                              style: TextStyle(color: successColor, fontSize: 10, fontFamily: 'Changa', fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
                  )
                      : const Text('أنجز الجريمة السابقة 10 مرات 🔒', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: 'Changa')),

                  // 🟢 حل مشكلة الـ Vertical Overflow بإضافة mainAxisSize.min
                  trailing: isCrimeUnlocked ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${crime['minCash']} - \$${crime['maxCash']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('شجاعة: ${crime['courage']}', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ) : const Icon(Icons.lock, color: Colors.white24),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle, VoidCallback? onBack) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), border: const Border.symmetric(horizontal: BorderSide(color: Color(0xFF856024)))),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 48),

          Expanded(
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Changa', color: Color(0xFFE2C275), fontSize: 22, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontFamily: 'Changa', color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  void _handleCrimeClick(BuildContext context, PlayerProvider player, Map<String, dynamic> crime, bool isUnlocked, double finalFailChance) {
    if (!isUnlocked) return;

    int reqCourage = crime['courage'];

    if (player.courage < reqCourage) {
      QuickRecoveryDialog.show(context, 'courage', reqCourage - player.courage);
      return;
    }

    if (player.equippedCrimeToolId != null && player.getItemDurability(player.equippedCrimeToolId!) < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ أداة الجريمة معطلة! كفاءتها انخفضت للنصف وتحتاج إصلاح.', style: TextStyle(fontFamily: 'Changa'))));
    }

    player.setCourage(player.courage - reqCourage);

    if (_random.nextDouble() < finalFailChance) {
      player.increaseHeat(crime['heat'] * 1.5);
      widget.onFailure();
    } else {
      player.increaseHeat(crime['heat']);

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

      int reward = crime['minCash'] + _random.nextInt((crime['maxCash'] - crime['minCash']) + 1);
      _checkRandomEvent(context, player);

      player.addCrimeXP(crime['xp']);
      player.incrementCrimeSuccess(crime['id']);

      widget.onSuccess(reward, crime['id'], 0);
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

  Widget _buildHeatMeter(double heatValue) {
    Color heatColor = heatValue > 70 ? Colors.redAccent : heatValue > 40 ? Colors.orangeAccent : const Color(0xFFE2C275);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: heatColor.withOpacity(0.5), width: 1.5),
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
            child: LinearProgressIndicator(value: heatValue / 100, backgroundColor: Colors.grey[900], valueColor: AlwaysStoppedAnimation<Color>(heatColor), minHeight: 8),
          ),
        ],
      ),
    );
  }
}