// المسار: lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';
import '../views/lucky_wheel_view.dart';
import '../views/crime_view.dart';
import '../views/bank_view.dart';
import '../views/airport_view.dart';
import '../views/hospital_view.dart';
import '../views/black_market_view.dart';
import '../views/inventory_view.dart';
import '../views/factory_view.dart';
import '../views/gym_view.dart';
import '../views/arena_view.dart';
import '../views/real_estate_view.dart';
import '../views/gang_view.dart';
import '../views/chat_view.dart';
import '../views/pvp_list_view.dart';
import '../views/street_race_view.dart';
import '../views/chop_shop_view.dart';
import '../views/laboratory_view.dart';
import '../views/workshop_view.dart';
import '../views/prison_view.dart';
import '../views/player_profile_view.dart';
import '../views/notifications_view.dart';
import '../views/private_chat_list_view.dart';
import '../views/friends_view.dart';
import '../views/settings_view.dart';
import 'dart:async';
import 'dart:math';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isHospitalized;
  final bool isInPrison;
  final VoidCallback? onEscapeTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.isHospitalized = false,
    this.isInPrison = false,
    this.onEscapeTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        image: const DecorationImage(
          image: AssetImage('assets/images/ui/bottom_navbar_bg.png'),
          fit: BoxFit.cover,
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFF856024), width: 2),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 26),
      child: SafeArea(
        bottom: true,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisAlignment: (isHospitalized || isInPrison) ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: isHospitalized
                ? [
              _buildNavItem(1, 'assets/images/icons/chat.png', 'الشات'),
            ]
                : isInPrison
                ? [
              _buildNavItem(1, 'assets/images/icons/chat.png', 'الشات'),
              // 🟢 زر الهروب الذكي
              GestureDetector(
                onTap: onEscapeTapped,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)],
                      ),
                      child: const Icon(Icons.directions_run, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 6),
                    const Text('هروب (-10)', style: TextStyle(fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ],
                ),
              ),
            ]
                : [
              _buildNavItem(0, 'assets/images/icons/inventory.png', 'المخزن'),
              _buildNavItem(1, 'assets/images/icons/chat.png', 'الشات'),
              _buildNavItem(2, 'assets/images/icons/map.png', 'الخريطة'),
              _buildNavItem(3, 'assets/images/icons/crime.png', 'الجرائم'),
              _buildNavItem(4, 'assets/images/icons/news.png', 'الأخبار'),
              _buildNavItem(5, 'assets/images/icons/profile.png', 'الزعيم'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String imagePath, String label) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.6), blurRadius: 10, spreadRadius: 1)] : [],
              border: isSelected ? Border.all(color: const Color(0xFFC5A059), width: 1.5) : null,
            ),
            child: Opacity(
              opacity: isSelected ? 1.0 : 0.75,
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  width: isSelected ? 39 : 35,
                  height: isSelected ? 39 : 35,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.red, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Changa',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFE2C275) : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  int _selectedIndex = 2;
  int _profileTabIndex = 0;
  String _activeArea = 'الخريطة';
  StreamSubscription? _notificationSubscription;

  bool _visualLoadingComplete = false;
  bool _isMapInitialized = false;

  final TransformationController _mapTransformationController = TransformationController();

  Widget? _cachedMapWidget;

  final List<Map<String, dynamic>> locations = [
    {'name': 'المطار', 'icon': Icons.airplanemode_active, 'color': Colors.blue},
    {'name': 'عجلة الحظ', 'icon': Icons.casino, 'color': Colors.orange},
    {'name': 'البنك', 'icon': Icons.account_balance, 'color': Colors.green},
    {'name': 'المستشفى', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'name': 'السجن', 'icon': Icons.lock, 'color': Colors.grey},
    {'name': 'المصنع', 'icon': Icons.precision_manufacturing, 'color': Colors.brown},
    {'name': 'سباق الشوارع', 'icon': Icons.directions_car, 'color': Colors.red},
    {'name': 'المتجر الأسود', 'icon': Icons.shopping_basket, 'color': Colors.black},
    {'name': 'صالة التدريب', 'icon': Icons.fitness_center, 'color': Colors.blueGrey},
    {'name': 'ساحة القتال', 'icon': Icons.sports_mma, 'color': Colors.redAccent},
    {'name': 'ساحة اللاعبين', 'icon': Icons.public, 'color': Colors.orangeAccent},
    {'name': 'العقارات', 'icon': Icons.home_work, 'color': Colors.amber},
    {'name': 'العصابات', 'icon': Icons.groups, 'color': Colors.deepOrange},
    {'name': 'التشليح', 'icon': Icons.car_crash, 'color': Colors.deepOrange},
    {'name': 'المختبر السري', 'icon': Icons.science, 'color': Colors.greenAccent},
    {'name': 'الورشة', 'icon': Icons.build_circle, 'color': Colors.blueAccent},
  ];

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 300;

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImages();

      final player = Provider.of<PlayerProvider>(context, listen: false);
      final audio = Provider.of<AudioProvider>(context, listen: false);
      audio.playBGM();
      _notificationSubscription = player.notificationStream.listen((message) {
        if (mounted) _showStylishNotification(message);
      });
    });
  }

  void _precacheImages() {
    final images = ['assets/images/top_nav_bg.png', 'assets/images/ui/bottom_navbar_bg.png', 'assets/images/city_map.jpg', 'assets/images/ui/crime_bg.jpg'];
    for (var path in images) { precacheImage(AssetImage(path), context); }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _mapTransformationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = Provider.of<AudioProvider>(context, listen: false);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      audio.pauseBGM();
    } else if (state == AppLifecycleState.resumed) {
      audio.resumeBGM();
    }
  }

  // 🟢 نافذة تفاصيل اللقب (عند الضغط عليه في الإشعارات)
  void _showTitleDetails(String titleName) {
    final titles = Provider.of<PlayerProvider>(context, listen: false).getAllTitles();
    final titleData = titles.firstWhere((t) => t['name'] == titleName, orElse: () => {});
    if (titleData.isEmpty) return;

    showDialog(
        context: context,
        builder: (c) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
              title: Text(titleData['name'], style: const TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: Text(titleData['desc'], style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 18), textAlign: TextAlign.center),
              actions: [
                Center(
                  child: TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('عظيم!', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 18))
                  ),
                )
              ]
          ),
        )
    );
  }

  void _showStylishNotification(String message) {
    String textToShow = message;
    String? titleToView;

    if (message.contains('|')) {
      List<String> parts = message.split('|');
      textToShow = parts[1];
    }

    if (textToShow.contains('لقب:')) {
      try { titleToView = textToShow.split('(')[1].split(')')[0]; } catch(e) {}
    }

    bool isWarning = textToShow.contains('⚠️') || textToShow.contains('خطر') || textToShow.contains('سجن') || textToShow.contains('🎭') || textToShow.contains('🏥');

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(textToShow.contains('🎭') ? Icons.theater_comedy : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline), color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(textToShow, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)))
        ]),
        duration: const Duration(seconds: 4),
        backgroundColor: textToShow.contains('🎭') ? Colors.blueAccent.withOpacity(0.9) : (isWarning ? Colors.redAccent.withOpacity(0.9) : Colors.green.withOpacity(0.9)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(15),
        elevation: 10,
        action: titleToView != null ? SnackBarAction(
          label: 'التفاصيل',
          textColor: Colors.amberAccent,
          onPressed: () {
            Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
            setState(() {
              _selectedIndex = 5;
              _profileTabIndex = 1;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              _showTitleDetails(titleToView!);
            });
          },
        ) : null,
      ),
    );
  }

  // 🟢 حركة الطيران الخرافية للموارد (أنيميشن)
  void _playFlyingAnimation({required String iconPath, required String text, required Color color, required Offset startOffset, required Offset endOffset}) {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1300),
          curve: Curves.easeInOutCubic,
          onEnd: () {
            overlayEntry?.remove();
          },
          builder: (context, double value, child) {
            double currentX = startOffset.dx;
            double currentY = startOffset.dy;

            // يرتفع للأعلى ببطء أولاً ثم يطير باتجاه البار العلوي
            if (value < 0.3) {
              currentY = startOffset.dy - (60 * (value / 0.3));
            } else {
              double p = (value - 0.3) / 0.7;
              currentX = startOffset.dx + (endOffset.dx - startOffset.dx) * p;
              currentY = (startOffset.dy - 60) + (endOffset.dy - (startOffset.dy - 60)) * p;
            }

            double scale = 1.0 - (value * 0.4);
            double opacity = value < 0.8 ? 1.0 : 1.0 - ((value - 0.8) * 5);

            return Positioned(
              left: currentX,
              top: currentY,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(iconPath, width: 40, height: 40),
                      const SizedBox(width: 5),
                      Text(
                          text,
                          style: TextStyle(
                              fontFamily: 'Changa',
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: color,
                              shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1,1))]
                          )
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
  }

  void _playRewardAnimations(int cash, int xp) {
    // طيران الكاش لليسار
    _playFlyingAnimation(
      iconPath: 'assets/images/icons/cash.png',
      text: '+\$${_formatNumber(cash)}',
      color: Colors.greenAccent,
      startOffset: Offset(MediaQuery.of(context).size.width * 0.3, MediaQuery.of(context).size.height * 0.5),
      endOffset: Offset(MediaQuery.of(context).size.width * 0.1, 40),
    );
    // طيران الخبرة لليمين
    _playFlyingAnimation(
      iconPath: 'assets/images/icons/lv.png',
      text: '+$xp',
      color: Colors.blueAccent,
      startOffset: Offset(MediaQuery.of(context).size.width * 0.7, MediaQuery.of(context).size.height * 0.5),
      endOffset: Offset(MediaQuery.of(context).size.width * 0.9, 40),
    );
  }

  // 🟢 نافذة الغنائم والنجاح
  void _showCrimeSuccessPopup(PlayerProvider player, int reward, String crimeId, int xpGained, bool gotCar, int bonusGold, int bonusEnergy) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC5A059), width: 2),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                  ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
                  const SizedBox(height: 10),
                  const Text('تمت العملية بنجاح!', style: TextStyle(fontFamily: 'Changa', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPopupRewardItem('كاش', '+\$${_formatNumber(reward)}', Colors.green, 'assets/images/icons/cash.png', isImage: true),
                      _buildPopupRewardItem('خبرة', '+$xpGained XP', Colors.blue, 'assets/images/icons/lv.png', isImage: true),
                    ],
                  ),

                  // الغنائم الإضافية المتغيرة
                  if (bonusGold > 0 || bonusEnergy > 0 || gotCar) ...[
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const Text('غنائم إضافية 🎁', style: TextStyle(fontFamily: 'Changa', fontSize: 16, color: Colors.amber)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (bonusGold > 0) _buildPopupRewardItem('ذهب', '+$bonusGold', Colors.amber, 'assets/images/icons/gold.png', isImage: true),
                        if (bonusEnergy > 0) _buildPopupRewardItem('طاقة', '+$bonusEnergy', Colors.orange, 'assets/images/icons/energy.png', isImage: true),
                        if (gotCar) _buildPopupRewardItem('سيارة', 'مسروقة!', Colors.redAccent, 'assets/images/icons/inventory.png', isImage: true),
                      ],
                    )
                  ],

                  const SizedBox(height: 30),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC5A059),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                          ),
                          onPressed: () {
                            Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                            Navigator.pop(context);

                            // منح المكافآت عند الضغط
                            player.addCash(reward, reason: "نجاح مهمة إجرامية");
                            player.addCrimeXP(xpGained);
                            if (bonusGold > 0) player.addGold(bonusGold);
                            if (bonusEnergy > 0) player.addEnergy(bonusEnergy);
                            if (gotCar) player.addInventoryItem('stolen_car', 1);

                            // تشغيل الأنيميشن
                            _playRewardAnimations(reward, xpGained);
                          },
                          child: const Text('استمرار', style: TextStyle(fontFamily: 'Changa', fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                          ),
                          onPressed: () {
                            Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                            Navigator.pop(context);

                            player.addCash(reward, reason: "نجاح مهمة إجرامية");
                            player.addCrimeXP(xpGained);
                            if (bonusGold > 0) player.addGold(bonusGold);
                            if (bonusEnergy > 0) player.addEnergy(bonusEnergy);
                            if (gotCar) player.addInventoryItem('stolen_car', 1);

                            _playRewardAnimations(reward, xpGained);

                            setState(() {
                              _selectedIndex = 2;
                              _activeArea = 'الخريطة';
                            });
                          },
                          child: const Text('الخريطة', style: TextStyle(fontFamily: 'Changa', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: child);
      },
    );
  }

  // 🟢 نافذة الفشل ودخول السجن
  void _showCrimeFailurePopup(int minutes, String crimeName, int bailCost) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                  ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_police, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 10),
                  const Text('فشلت العملية!', style: TextStyle(fontFamily: 'Changa', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text('تم القبض عليك أثناء $crimeName', style: const TextStyle(fontFamily: 'Changa', fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPopupRewardItem('مدة السجن', '$minutes دقائق', Colors.redAccent, Icons.timer, isImage: false),
                      _buildPopupRewardItem('قيمة الكفالة', '\$${_formatNumber(bailCost)}', Colors.orange, 'assets/images/icons/cash.png', isImage: true),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10)
                    ),
                    onPressed: () {
                      Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 2; // إجبار اللعبة للذهاب للماب (الذي سيعرض السجن لأننا في السجن)
                        _activeArea = 'السجن';
                      });
                    },
                    child: const Text('الذهاب للسجن', style: TextStyle(fontFamily: 'Changa', fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(scale: anim1.value, child: child);
      },
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildPopupRewardItem(String title, String value, Color color, dynamic iconData, {required bool isImage}) {
    return Column(
      children: [
        isImage ? Image.asset(iconData as String, width: 40, height: 40) : Icon(iconData as IconData, color: color, size: 40),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontFamily: 'Changa', color: Colors.white70, fontSize: 14)),
        Text(value, style: TextStyle(fontFamily: 'Changa', color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showQuickMenuDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 2)),
          title: const Text('القائمة السريعة', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuOption(Icons.notifications, 'الإشعارات', () { Navigator.pop(c); Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsView())); }),
              const Divider(color: Colors.white10),
              _buildMenuOption(Icons.message, 'الرسائل', () { Navigator.pop(c); Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivateChatListView())); }),
              const Divider(color: Colors.white10),
              _buildMenuOption(Icons.group, 'الأصدقاء', () { Navigator.pop(c); Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsView())); }),
              const Divider(color: Colors.white10),
              _buildMenuOption(Icons.settings, 'الإعدادات', () { Navigator.pop(c); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsView()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: Colors.amber, size: 28), title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 18, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16), onTap: onTap);
  }

  // 🟢 تنفيذ محاولة الهروب
  void _attemptPrisonEscape(PlayerProvider player) {
    Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
    if (player.courage < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تحتاج إلى 10 شجاعة كحد أدنى للمحاولة!', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
      return;
    }
    bool success = player.attemptEscape();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشلت محاولة الهروب! ابق في زنزانتك.', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
    } else {
      setState(() {
        _selectedIndex = 2; // التوجه للخريطة بمجرد نجاح الهروب
        _activeArea = 'الخريطة';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDataLoading = context.select<PlayerProvider, bool>((player) => player.isLoading);

    if (isDataLoading || !_visualLoadingComplete) {
      return GameLoadingView(
        isDataLoaded: !isDataLoading,
        onVisualLoadingComplete: () {
          if (mounted) { setState(() => _visualLoadingComplete = true); }
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Consumer<PlayerProvider>(
                builder: (context, player, child) {
                  return TopBar(
                      cash: player.cash, gold: player.gold, energy: player.energy, maxEnergy: player.maxEnergy,
                      courage: player.courage, maxCourage: player.maxCourage, health: player.health, maxHealth: player.maxHealth,
                      prestige: player.prestige, maxPrestige: player.maxPrestige, playerName: player.playerName,
                      profilePicUrl: player.profilePicUrl, level: player.crimeLevel, currentXp: player.crimeXP,
                      maxXp: player.xpToNextLevel, isVIP: player.isVIP
                  );
                }
            ),

            Expanded(
                child: Consumer<PlayerProvider>(
                    builder: (context, player, child) {
                      return _buildConditionalContent(player);
                    }
                )
            ),
          ],
        ),
      ),

      bottomNavigationBar: Consumer<PlayerProvider>(
          builder: (context, player, child) {
            if ((_selectedIndex == 2 && (_activeArea == 'العقارات' || _activeArea == 'صالة التدريب' || _activeArea == 'المتجر الأسود')) || _selectedIndex == 5) {
              return const SizedBox.shrink();
            }

            if (player.isInPrison) {
              return BottomNavBar(
                selectedIndex: _selectedIndex,
                isInPrison: true,
                onEscapeTapped: () => _attemptPrisonEscape(player),
                onItemTapped: (index) {
                  Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                  if (index == 1) {
                    setState(() => _selectedIndex = _selectedIndex == 1 ? 2 : 1);
                  }
                },
              );
            }

            if (player.isHospitalized) {
              return BottomNavBar(
                selectedIndex: _selectedIndex,
                isHospitalized: true,
                onItemTapped: (index) {
                  Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                  if (index == 1) {
                    setState(() => _selectedIndex = _selectedIndex == 1 ? 2 : 1);
                  }
                },
              );
            }

            return BottomNavBar(
              selectedIndex: _selectedIndex,
              isHospitalized: false,
              isInPrison: false,
              onItemTapped: (index) {
                Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                setState(() {
                  _selectedIndex = index;
                  if (index == 2) _activeArea = 'الخريطة';
                });
              },
            );
          }
      ),
    );
  }

  Widget _buildConditionalContent(PlayerProvider player) {
    if (_selectedIndex == 1) return const ChatView();
    // 🟢 التأكيد القاطع أنه لا يمكنك رؤية أي شيء آخر إذا كنت مسجوناً
    if (player.isInPrison) return const PrisonView();
    if (player.isHospitalized) return HospitalView(onBack: () => setState(() => _activeArea = 'الخريطة'));

    return _buildMainContent(player);
  }

  Widget _getMapLayer() {
    _cachedMapWidget ??= LayoutBuilder(
      builder: (context, constraints) {
        final double imageWidth = 4096;
        final double imageHeight = 4096;

        double minScaleX = constraints.maxWidth / imageWidth;
        double minScaleY = constraints.maxHeight / imageHeight;
        double calculatedMinScale = minScaleX > minScaleY ? minScaleX : minScaleY;

        if (!_isMapInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              double dx = (constraints.maxWidth - (imageWidth * calculatedMinScale)) / 2;
              double dy = (constraints.maxHeight - (imageHeight * calculatedMinScale)) / 2;

              _mapTransformationController.value = Matrix4.identity()
                ..translate(dx, dy)
                ..scale(calculatedMinScale);
            }
          });
          _isMapInitialized = true;
        }

        return InteractiveViewer(
          transformationController: _mapTransformationController,
          minScale: calculatedMinScale,
          maxScale: 3.0,
          constrained: false,
          boundaryMargin: EdgeInsets.zero,
          child: SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/city_map.jpg',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                ),
                _buildMapHotspot('المطار', 3500, 2600, 300, 300, Colors.blue),
                _buildMapHotspot('عجلة الحظ', 1400, 300, 300, 300, Colors.orange),
                _buildMapHotspot('البنك', 600, 600, 300, 300, Colors.green),
                _buildMapHotspot('المستشفى', 3500, 1400, 300, 300, Colors.red),
                _buildMapHotspot('السجن', 2600, 600, 300, 300, Colors.grey),
                _buildMapHotspot('المصنع', 3200, 350, 300, 300, Colors.brown),
                _buildMapHotspot('سباق الشوارع', 350, 1200, 300, 300, Colors.pink),
                _buildMapHotspot('المتجر الأسود', 800, 1600, 300, 300, Colors.black),
                _buildMapHotspot('صالة التدريب', 1800, 2400, 300, 300, Colors.blueGrey),
                _buildMapHotspot('ساحة القتال', 1900, 1800, 300, 300, Colors.redAccent),
                _buildMapHotspot('ساحة اللاعبين', 2200, 400, 300, 300, Colors.orangeAccent),
                _buildMapHotspot('العقارات', 500, 2300, 300, 300, Colors.amber),
                _buildMapHotspot('العصابات', 1800, 3300, 300, 300, Colors.deepOrange),
                _buildMapHotspot('التشليح', 3400, 3200, 300, 300, Colors.lime),
                _buildMapHotspot('المختبر السري', 2600, 3600, 300, 300, Colors.greenAccent),
                _buildMapHotspot('الورشة', 2650, 2850, 300, 300, Colors.blueAccent),
              ],
            ),
          ),
        );
      },
    );
    return _cachedMapWidget!;
  }

  Widget _buildMainContent(PlayerProvider player) {
    if (_selectedIndex == 0) return const InventoryView();

    if (_selectedIndex == 3) {
      return CrimeView(
        courage: player.courage,
        onSuccess: (reward, crimeId, energyUsed) {
          final audio = Provider.of<AudioProvider>(context, listen: false);
          audio.playEffect('click.mp3');

          int xpGained = 15;

          // توليد غنائم عشوائية
          int bonusGold = (Random().nextDouble() < 0.1) ? Random().nextInt(2) + 1 : 0;
          int bonusEnergy = (Random().nextDouble() < 0.15) ? Random().nextInt(10) + 5 : 0;

          bool gotCar = false;
          if (crimeId.startsWith('cat_3_') || crimeId.startsWith('cat_6_')) {
            if(Random().nextDouble() < 0.3) {
              gotCar = true;
            }
          }

          // 🟢 إظهار نافذة الغنائم (الدالة نفسها ستعطيك الكاش وتلعب الأنيميشن)
          _showCrimeSuccessPopup(player, reward, crimeId, xpGained, gotCar, bonusGold, bonusEnergy);
        },
        onFailure: (minutes, crimeName, bailCost) {
          final audio = Provider.of<AudioProvider>(context, listen: false);
          audio.playEffect('click.mp3');

          // 🟢 الدخول الآمن للسجن وإظهار النافذة
          player.putInPrison(minutes, crimeName, bailCost);
          _showCrimeFailurePopup(minutes, crimeName, bailCost);
        },
      );
    }

    if (_selectedIndex == 5) {
      return PlayerProfileView(
          targetUid: player.uid!,
          profileTabIndex: _profileTabIndex,
          previewName: player.playerName,
          previewPicUrl: player.profilePicUrl,
          previewIsVIP: player.isVIP,
          onBack: () => setState(() => _selectedIndex = 2)
      );
    }

    if (_selectedIndex != 2) return const Center(child: Text('قيد التطوير', style: TextStyle(color: Colors.white)));

    if (_activeArea == 'المطار') return AirportView(gold: player.gold, onTravel: (cost) => player.removeGold(cost), onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'البنك') return BankView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'السجن') return PrisonView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'عجلة الحظ') return LuckyWheelView(cash: player.cash, maxEnergy: player.maxEnergy, maxCourage: player.maxCourage, onCashChanged: (val) => val > 0 ? player.addCash(val, reason: "عجلة الحظ") : player.removeCash(val.abs(), reason: "خسارة عجلة حظ"), onGoldChanged: (val) => player.addGold(val), onEnergyChanged: (val) => player.setEnergy(val), onCourageChanged: (val) => player.setCourage(val), onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'المستشفى') return HospitalView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'المتجر الأسود') return BlackMarketView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'المصنع') return FactoryView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'سباق الشوارع') return StreetRaceView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'صالة التدريب') return GymView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'ساحة القتال') return ArenaView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'ساحة اللاعبين') return PvpListView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'العقارات') return RealEstateView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'التشليح') return ChopShopView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'المختبر السري') return LaboratoryView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'الورشة') return WorkshopView(onBack: () => setState(() => _activeArea = 'الخريطة'));

    return Stack(
      children: [
        Positioned.fill(
          child: _getMapLayer(),
        ),
        Positioned(
          top: 15,
          right: 15,
          child: GestureDetector(
            onTap: () {
              Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
              _showQuickMenuDialog(context);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4)),
                  BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: const Icon(Icons.menu, color: Colors.amber, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapHotspot(String areaName, double left, double top, double width, double height, Color debugColor) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');

          if (areaName == 'العصابات') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GangView()));
          } else {
            setState(() => _activeArea = areaName);
          }
        },
        child: Container(
          color: debugColor.withOpacity(0.5),
          child: Center(
            child: Text(
              areaName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, backgroundColor: Colors.black54, fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class GameLoadingView extends StatefulWidget {
  final bool isDataLoaded;
  final VoidCallback onVisualLoadingComplete;

  const GameLoadingView({super.key, required this.isDataLoaded, required this.onVisualLoadingComplete});

  @override
  State<GameLoadingView> createState() => _GameLoadingViewState();
}

class _GameLoadingViewState extends State<GameLoadingView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.isDataLoaded) widget.onVisualLoadingComplete();
    });
  }

  @override
  void didUpdateWidget(GameLoadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isDataLoaded && widget.isDataLoaded && _controller.isCompleted) widget.onVisualLoadingComplete();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/turfwar_loading_screen.jpg', fit: BoxFit.cover, alignment: const Alignment(0.0, -0.2))),
          Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.black45, Colors.black], stops: [0.0, 0.4, 1.0])))),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('حرب النفوذ', style: TextStyle(fontFamily: 'Changa', color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 15, color: Color(0xFFFFD700)), Shadow(blurRadius: 4, color: Color(0xFFB8860B), offset: Offset(2, 2)), Shadow(blurRadius: 15, color: Colors.black, offset: Offset(4, 4))])),
                const SizedBox(height: 15),
                const Text('جاري التحميل', style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: const Color(0xFFB30000).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 2))]), child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: _controller.value, backgroundColor: Colors.black45, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB30000)), minHeight: 10))),
                          const SizedBox(height: 12),
                          Text('${(_controller.value * 100).toInt()}%', style: const TextStyle(color: Color(0xFFB30000), fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic))
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          )
        ],
      ),
    );
  }
}