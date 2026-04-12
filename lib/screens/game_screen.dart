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

// 🟢 النافبار السفلي الأساسي
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool isHospitalized;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.isHospitalized = false,
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
            mainAxisAlignment: isHospitalized ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: isHospitalized
                ? [
              Padding(
                padding: const EdgeInsets.only(right: 30.0),
                child: _buildNavItem(1, 'assets/images/icons/chat.png', 'الشات'),
              )
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

  // 🟢 المتغير لتخزين الخريطة ومنع إعادة رسمها
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

  void _showStylishNotification(String message) {
    bool isWarning = message.contains('⚠️') || message.contains('خطر') || message.contains('سجن') || message.contains('🎭') || message.contains('🏥');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Row(children: [
            Icon(message.contains('🎭') ? Icons.theater_comedy : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)))
          ]),
          duration: const Duration(seconds: 3),
          backgroundColor: message.contains('🎭') ? Colors.blueAccent.withOpacity(0.9) : (isWarning ? Colors.redAccent.withOpacity(0.9) : Colors.green.withOpacity(0.9)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(15),
          elevation: 10
      ),
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

  @override
  Widget build(BuildContext context) {
    // 🟢 الحل الجديد هنا: نطلب من الشاشة الاستماع *فقط* لمتغير isLoading
    // وبذلك الشاشة تعيد بناء نفسها عند انتهاء التحميل، ثم تتجاهل باقي التحديثات!
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
            // 🟢 استخدام Consumer حول الأجزاء التي تتغير فقط (البيانات العلوية)
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

      // 🟢 تغليف النافبار السفلي بـ Consumer للتحكم في ظهوره
      bottomNavigationBar: Consumer<PlayerProvider>(
          builder: (context, player, child) {
            if ((_selectedIndex == 2 && (_activeArea == 'العقارات' || _activeArea == 'صالة التدريب' || _activeArea == 'المتجر الأسود')) || _selectedIndex == 5) {
              return const SizedBox.shrink();
            }

            if (player.isInPrison || player.isHospitalized) {
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
    if (player.isInPrison) return const PrisonView();
    if (player.isHospitalized) return HospitalView(onBack: () => setState(() => _activeArea = 'الخريطة'));

    return _buildMainContent(player);
  }

  // 🟢 دالة لفصل وتخزين الخريطة ومنع بناءها أكثر من مرة
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
          player.addCash(reward, reason: "نجاح مهمة إجرامية");
          if (crimeId.startsWith('cat_3_') || crimeId.startsWith('cat_6_')) {
            if(Random().nextDouble() < 0.3) {
              player.addInventoryItem('stolen_car', 1);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حصلت على سيارة مسروقة! أرسلها للتشليح 🚗🔧', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.green));
            }
          }
        },
        onFailure: (minutes, crimeName, bailCost) {
          final audio = Provider.of<AudioProvider>(context, listen: false);
          audio.playEffect('click.mp3');
          player.handleCrimeFailure(minutes, crimeName, bailCost);
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
          child: _getMapLayer(), // 🟢 الخريطة المخزنة هنا، ولن تُبنى مرة أخرى!
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