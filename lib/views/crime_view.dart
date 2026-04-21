// المسار: lib/views/crime_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/quick_recovery_dialog.dart';
import '../utils/crime_data.dart';
import '../controllers/crime_cubit.dart';

class CrimeView extends StatelessWidget {
  final int courage;
  final VoidCallback onBack;
  final Function(int reward, String crimeId, int xpGained, int energyUsed, int droppedGold, int droppedEnergy, bool evadedPolice, String? earnedTitle, VoidCallback onRetry) onSuccess;
  final Function(int minutes, String crimeName, int bailCost) onFailure;

  const CrimeView({
    super.key,
    required this.courage,
    required this.onBack,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CrimeCubit(),
      child: _CrimeViewContent(
        courage: courage,
        onBack: onBack,
        onSuccess: onSuccess,
        onFailure: onFailure,
      ),
    );
  }
}

class _CrimeViewContent extends StatefulWidget {
  final int courage;
  final VoidCallback onBack;
  final Function(int reward, String crimeId, int xpGained, int energyUsed, int droppedGold, int droppedEnergy, bool evadedPolice, String? earnedTitle, VoidCallback onRetry) onSuccess;
  final Function(int minutes, String crimeName, int bailCost) onFailure;

  const _CrimeViewContent({
    required this.courage,
    required this.onBack,
    required this.onSuccess,
    required this.onFailure
  });

  @override
  State<_CrimeViewContent> createState() => _CrimeViewContentState();
}

class _CrimeViewContentState extends State<_CrimeViewContent> {
  int? _selectedCategoryIndex;

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final cubit = context.read<CrimeCubit>();

    return BlocConsumer<CrimeCubit, CrimeState>(
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          String errorMsg = state.errorMessage;
          if (errorMsg.contains('شجاعة')) {
            QuickRecoveryDialog.show(context, 'courage', 10);
          } else if (errorMsg.contains('السجن')) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أنت مسجون حالياً!', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $errorMsg', style: const TextStyle(fontFamily: 'Changa', fontSize: 12)), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)));
          }
        }
      },
      builder: (context, state) {
        final audio = Provider.of<AudioProvider>(context, listen: false);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
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
                  const SizedBox(height: 20),

                  // 🟢 لافتة (Banner) الحدث المزدوج تظهر تلقائياً لو غيرت الرقم في الفايربيس
                  if (player.crimeEventMultiplier > 1.0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '🔥 حدث دبل الجرائم نشط! (x${player.crimeEventMultiplier}) 🔥',
                            style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

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
                          : _buildCrimesList(player, _selectedCategoryIndex!, cubit),
                    ),
                  )
                ],
              ),

              if (state.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE2C275)),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavBar(context, audio),
        );
      },
    );
  }

  Widget _buildBottomNavBar(BuildContext context, AudioProvider audio) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          image: DecorationImage(
            image: AssetImage('assets/images/ui/bottom_navbar_bg.png'),
            fit: BoxFit.cover,
          ),
          border: Border(top: BorderSide(color: Color(0xFF856024), width: 2)),
        ),
        padding: const EdgeInsets.only(top: 10, bottom: 20, left: 15, right: 15),
        child: SafeArea(
          bottom: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  audio.playEffect('click.mp3');
                  if (_selectedCategoryIndex != null) {
                    setState(() {
                      _selectedCategoryIndex = null;
                    });
                  } else {
                    widget.onBack();
                  }
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward_ios, color: Color(0xFFE2C275), size: 24),
                    SizedBox(height: 4),
                    Text('رجوع', style: TextStyle(color: Color(0xFFE2C275), fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  audio.playEffect('click.mp3');
                  _showExplanationDialog(context);
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book, color: Colors.white70, size: 24),
                    SizedBox(height: 4),
                    Text('شرح', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.amber),
        ),
        title: const Text(
          'دليل الجرائم',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('🔫 كيف تبدأ؟', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('اختر فئة إجرامية للبدء. كلما نفذت الجريمة بنجاح، زادت نجومك وتقدمك فيها.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
                SizedBox(height: 10),
                Text('🔓 فتح جرائم جديدة:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('يجب عليك تنفيذ الجريمة بنجاح 10 مرات على الأقل لتتمكن من فتح الجريمة التي تليها.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
                SizedBox(height: 10),
                Text('🛠️ أدوات الجريمة:', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('استخدم الأقنعة وأدوات الجريمة من (التسليح) لتقليل نسبة الفشل بشكل كبير.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً فهمت', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(PlayerProvider player) {
    return Column(
      key: const ValueKey('CategoriesList'),
      children: [
        _buildHeader('الجرائم', 'اختر فئة للبدء بعملياتك'),
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

              int activeCrimesCount = 0;
              if (isCategoryUnlocked) {
                List<Map<String, dynamic>> catCrimes = CrimeData.getCrimesForCategory(catIndex, eventMultiplier: player.crimeEventMultiplier);
                for (int i = 0; i < catCrimes.length; i++) {
                  String cId = catCrimes[i]['id'];
                  int cSuccess = player.crimeSuccessCountsMap[cId] ?? 0;

                  bool unlocked = true;
                  if (i > 0) {
                    String prevId = catCrimes[i - 1]['id'];
                    if ((player.crimeSuccessCountsMap[prevId] ?? 0) < 10) {
                      unlocked = false;
                    }
                  }

                  if (unlocked) {
                    if (cSuccess < 500) activeCrimesCount++;
                  } else {
                    break;
                  }
                }
              }

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (catIndex * 100)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Card(
                  color: Colors.black87,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isCategoryUnlocked ? 8 : 0,
                  shadowColor: isCategoryUnlocked ? category['color'].withOpacity(0.4) : Colors.transparent,
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
                      setState(() { _selectedCategoryIndex = catIndex; });
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
                                Text(isCategoryUnlocked ? (activeCrimesCount > 0 ? '$activeCrimesCount أهداف بانتظارك.. خلّص عليهم' : 'نظفت المنطقة بالكامل 👑') : 'مو مستواك للحين 🔒', style: TextStyle(fontFamily: 'Changa', color: isCategoryUnlocked ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: isCategoryUnlocked ? Colors.white54 : Colors.transparent, size: 18),
                        ],
                      ),
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

  Widget _buildCrimesList(PlayerProvider player, int catIndex, CrimeCubit cubit) {
    final category = CrimeData.categories[catIndex];
    List<Map<String, dynamic>> crimes = CrimeData.getCrimesForCategory(catIndex, eventMultiplier: player.crimeEventMultiplier);
    Color mainColor = category['color'];

    return Column(
      key: const ValueKey('CrimesList'),
      children: [
        _buildHeader(category['name'], 'أكمل الجريمة 10 مرات لتفتح التي تليها'),
        Expanded(
          child: ListView.builder(
            itemCount: crimes.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemBuilder: (context, crimeIndex) {
              Map<String, dynamic> crime = crimes[crimeIndex];
              String crimeId = crime['id'];

              int successCount = player.crimeSuccessCountsMap[crimeId] ?? 0;
              int stars = successCount >= 500 ? 3 : successCount >= 50 ? 2 : successCount >= 10 ? 1 : 0;

              double progressValue = 0.0;
              if (stars == 3) progressValue = 1.0;
              else if (stars == 2) progressValue = (successCount - 50) / 450;
              else if (stars == 1) progressValue = (successCount - 10) / 40;
              else progressValue = successCount / 10;
              progressValue = progressValue.clamp(0.0, 1.0);

              bool isCrimeUnlocked = true;
              if (crimeIndex > 0) {
                String prevCrimeId = crimes[crimeIndex - 1]['id'];
                isCrimeUnlocked = (player.crimeSuccessCountsMap[prevCrimeId] ?? 0) >= 10;
              }

              double toolDurability = player.equippedCrimeToolId != null ? player.getItemDurability(player.equippedCrimeToolId!) : 0;
              double finalFailChance = cubit.calculateFailChance(crime, 0, successCount, catIndex, player.equippedCrimeToolId, toolDurability, player.equippedMaskId);

              int successPercentage = ((1.0 - finalFailChance) * 100).toInt();
              Color successColor = successPercentage >= 80 ? Colors.greenAccent : successPercentage >= 50 ? Colors.orangeAccent : Colors.redAccent;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200 + (crimeIndex * 50)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isCrimeUnlocked ? mainColor.withOpacity(0.5) : Colors.white10),
                    boxShadow: isCrimeUnlocked ? [BoxShadow(color: mainColor.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)] : [],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    enabled: isCrimeUnlocked,
                    onTap: () => _handleCrimeClick(context, player, cubit, crime, isCrimeUnlocked, finalFailChance),
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progressValue),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return CircularProgressIndicator(value: value, color: mainColor, backgroundColor: Colors.white10);
                          },
                        ),
                        Icon(category['icon'], color: isCrimeUnlocked ? Colors.white : Colors.white24, size: 20),
                      ],
                    ),
                    title: Text(crime['name'], style: TextStyle(fontFamily: 'Changa', color: isCrimeUnlocked ? Colors.white : Colors.white30, fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: isCrimeUnlocked
                        ? Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Icon(Icons.star, size: 14, color: i < stars ? const Color(0xFFE2C275) : Colors.white10))),
                          Text('نجاح: $successCount', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Changa')),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: successColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: successColor.withOpacity(0.5))), child: Text('النسبة: $successPercentage%', style: TextStyle(color: successColor, fontSize: 10, fontFamily: 'Changa', fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ) : const Text('أنجز الجريمة السابقة للتقدم', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: 'Changa')),
                    trailing: isCrimeUnlocked ? Column(
                      mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\$${crime['minCash']} - \$${crime['maxCash']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('+${crime['minXp']}-${crime['maxXp']} XP', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                            const SizedBox(width: 8),
                            Text('شجاعة: ${crime['courage']}', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          ],
                        ),
                      ],
                    ) : const Icon(Icons.lock, color: Colors.white24),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), border: const Border.symmetric(horizontal: BorderSide(color: Color(0xFF856024)))),
      child: Center(
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Changa', color: Color(0xFFE2C275), fontSize: 22, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontFamily: 'Changa', color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _handleCrimeClick(BuildContext context, PlayerProvider player, CrimeCubit cubit, Map<String, dynamic> crime, bool isUnlocked, double finalFailChance) async {
    if (!isUnlocked || cubit.state.isLoading) return;

    int reqCourage = crime['courage'];
    if (player.courage < reqCourage) { QuickRecoveryDialog.show(context, 'courage', reqCourage - player.courage); return; }
    if (player.equippedCrimeToolId != null && player.getItemDurability(player.equippedCrimeToolId!) < 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ أداة الجريمة معطلة! كفاءتها انخفضت للنصف.', style: TextStyle(fontFamily: 'Changa')))); }

    if (player.uid == null || player.uid!.isEmpty) return;

    cubit.attemptCrime(
      uid: player.uid!,
      crime: crime,
      finalFailChance: finalFailChance,
      maxCourage: player.maxCourage,
      maxEnergy: player.maxEnergy,
      onSuccessCallback: (reward, crimeId, xpGained, energyUsed, droppedGold, droppedEnergy, evadedPolice, earnedTitle) {
        if (player.equippedCrimeToolId != null) player.reduceDurability(player.equippedCrimeToolId, 5.0);

        widget.onSuccess(reward, crimeId, xpGained, energyUsed, droppedGold, droppedEnergy, evadedPolice, earnedTitle, () {
          _handleCrimeClick(context, player, cubit, crime, isUnlocked, finalFailChance);
        });
      },
      onFailureCallback: (prisonMinutes, crimeName, bailCost) {
        widget.onFailure(prisonMinutes, crimeName, bailCost);
      },
    );
  }
}