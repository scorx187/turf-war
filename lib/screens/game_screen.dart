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
import 'dart:async';

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

  // 🔥 متغير جديد للتحكم بانتهاء أنميشن التحميل
  bool _visualLoadingComplete = false;

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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      final audio = Provider.of<AudioProvider>(context, listen: false);
      audio.playBGM();
      _notificationSubscription = player.notificationStream.listen((message) {
        if (mounted) _showStylishNotification(message);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = Provider.of<AudioProvider>(context, listen: false);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) { audio.pauseBGM(); }
    else if (state == AppLifecycleState.resumed) { audio.resumeBGM(); }
  }

  void _showStylishNotification(String message) {
    bool isWarning = message.contains('⚠️') || message.contains('خطر') || message.contains('سجن') || message.contains('🎭') || message.contains('🏥');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(children: [Icon(message.contains('🎭') ? Icons.theater_comedy : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline), color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14)))]), duration: const Duration(seconds: 3), backgroundColor: message.contains('🎭') ? Colors.blueAccent.withValues(alpha:0.9) : (isWarning ? Colors.redAccent.withValues(alpha:0.9) : Colors.green.withValues(alpha:0.9)), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), margin: const EdgeInsets.all(15), elevation: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // 🔥 شاشة التحميل الفخمة تظهر إذا كانت البيانات لسه تحمل، أو إذا الأنميشن ما خلص
    if (player.isLoading || !_visualLoadingComplete) {
      return GameLoadingView(
        isDataLoaded: !player.isLoading, // نبلغ الشاشة إذا البيانات جاهزة
        onVisualLoadingComplete: () {
          // هذي الدالة تتنفذ لما يوصل الشريط 100% والبيانات تكون جاهزة
          if (mounted) {
            setState(() {
              _visualLoadingComplete = true;
            });
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      body: SafeArea(
        child: Column(
          children: [
            TopBar(cash: player.cash, gold: player.gold, energy: player.energy, courage: player.courage, health: player.health, playerName: player.playerName, level: player.crimeLevel, xpPercent: player.crimeXP / player.xpToNextLevel, isVIP: player.isVIP),
            Expanded(child: _buildConditionalContent(player)),
          ],
        ),
      ),
      bottomNavigationBar: _selectedIndex == 5
          ? BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white54,
        currentIndex: _profileTabIndex,
        onTap: (index) {
          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
          setState(() => _profileTabIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('private_chats').where('participants', arrayContains: player.uid ?? '').snapshots(),
              builder: (context, snapshot) {
                int totalUnreadChats = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    if ((data['unread_${player.uid}'] ?? 0) > 0) totalUnreadChats++;
                  }
                }
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble),
                    if (totalUnreadChats > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: Text('$totalUnreadChats', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                );
              },
            ),
            label: 'الخاص',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'الأصدقاء'),
          const BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'المهارات'),
          const BottomNavigationBarItem(icon: Icon(Icons.security), label: 'التسليح'),
        ],
      )
          : BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (player.isInPrison || player.isHospitalized) return;
          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
          setState(() { _selectedIndex = index; _activeArea = 'الخريطة'; });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'المخزن'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'الشات'),
          BottomNavigationBarItem(icon: Icon(Icons.location_city), label: 'الخريطة'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'الجريمة'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'الجريدة'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'البروفايل'),
        ],
      ),
    );
  }

  Widget _buildConditionalContent(PlayerProvider player) {
    if (player.isInPrison) return PrisonView(prisonReleaseTime: player.prisonReleaseTime, cash: player.cash, onBailPaid: () { player.payBail(); });
    if (player.isHospitalized) return HospitalView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    return _buildMainContent(player);
  }

  Widget _buildMainContent(PlayerProvider player) {
    if (_selectedIndex == 0) return const InventoryView();
    if (_selectedIndex == 1) return ChatView();
    if (_selectedIndex == 3) {
      return CrimeView(
        courage: player.courage, crimeSuccessCounts: player.crimeSuccessCounts,
        onSuccess: (reward, index, energyUsed) {
          final audio = Provider.of<AudioProvider>(context, listen: false); audio.playEffect('click.mp3');
          final List<String> crimeNames = ['سرقة محفظة', 'سطو على متجر', 'سرقة سيارة', 'سطو على فيلا', 'سطو على البنك'];
          player.addCash(reward, reason: "نجاح: ${crimeNames[index]}"); player.incrementCrimeSuccess(index, crimeNames[index]);
          if (index == 2) { player.addInventoryItem('stolen_car', 1); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حصلت على سيارة مسروقة! أرسلها للتشليح 🚗🔧'), backgroundColor: Colors.green)); }
          int courageCost = index == 0 ? 5 : index == 1 ? 15 : index == 2 ? 30 : index == 3 ? 40 : 60;
          player.setCourage(player.courage - courageCost); if (energyUsed > 0) player.setEnergy(player.energy - energyUsed);
        },
        onFailure: () { final audio = Provider.of<AudioProvider>(context, listen: false); audio.playEffect('click.mp3'); player.handleCrimeFailure(2); },
      );
    }

    if (_selectedIndex == 5) return PlayerProfileView(
        targetUid: player.uid!,
        profileTabIndex: _profileTabIndex,
        previewName: player.playerName,
        previewPicUrl: player.profilePicUrl,
        previewIsVIP: player.isVIP,
        onBack: () => setState(() => _selectedIndex = 2)
    );

    if (_selectedIndex != 2) return const Center(child: Text('قيد التطوير', style: TextStyle(color: Colors.white)));

    if (_activeArea == 'المطار') return AirportView(gold: player.gold, onTravel: (cost) => player.removeGold(cost), onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'البنك') return BankView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'عجلة الحظ') return LuckyWheelView(cash: player.cash, maxEnergy: player.maxEnergy, maxCourage: player.maxCourage, onCashChanged: (val) => val > 0 ? player.addCash(val, reason: "عجلة الحظ") : player.removeCash(val.abs(), reason: "خسارة عجلة حظ"), onGoldChanged: (val) => player.addGold(val), onEnergyChanged: (val) => player.setEnergy(val), onCourageChanged: (val) => player.setCourage(val), onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'المستشفى') return HospitalView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'المتجر الأسود') return BlackMarketView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'المصنع') return FactoryView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'سباق الشوارع') return StreetRaceView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'صالة التدريب') return GymView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'ساحة القتال') return ArenaView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'ساحة اللاعبين') return PvpListView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'العقارات') return RealEstateView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'العصابات') return GangView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'التشليح') return ChopShopView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'المختبر السري') return LaboratoryView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    if (_activeArea == 'الورشة') return WorkshopView(onBack: () => setState(() => _activeArea = 'الخريطة'));

    return GridView.builder(
      padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8), itemCount: locations.length,
      itemBuilder: (context, index) {
        final loc = locations[index];
        return GestureDetector(
          onTap: () { Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3'); setState(() => _activeArea = loc['name']); },
          child: Container(decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: loc['color'], width: 1.5)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(loc['icon'], size: 40, color: loc['color']), const SizedBox(height: 10), Text(loc['name'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))])),
        );
      },
    );
  }
}

// 🧱 ويدجت شاشة التحميل الذكية ذات شريط التحميل (نضعها في نهاية الملف)
class GameLoadingView extends StatefulWidget {
  final bool isDataLoaded;
  final VoidCallback onVisualLoadingComplete;

  const GameLoadingView({
    super.key,
    required this.isDataLoaded,
    required this.onVisualLoadingComplete,
  });

  @override
  State<GameLoadingView> createState() => _GameLoadingViewState();
}

class _GameLoadingViewState extends State<GameLoadingView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // أنميشن شريط التحميل يستغرق 3 ثواني
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.isDataLoaded) {
        widget.onVisualLoadingComplete();
      }
    });
  }

  @override
  void didUpdateWidget(GameLoadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isDataLoaded && widget.isDataLoaded) {
      if (_controller.isCompleted) {
        widget.onVisualLoadingComplete();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/turfwar_loading_screen.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.0, -0.2),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // 🔥 التعتيم أصبح أسود داكن جداً في الأسفل ليتناسب مع اللون الأحمر
                  colors: [Colors.black54, Colors.black45, Colors.black],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'TURF WAR',
                  style: TextStyle(
                    color: Color(0xFFB30000), // 🔥 لون أحمر دموي/قرمزي داكن
                    fontSize: 52, // حجم أكبر للسيطرة
                    fontWeight: FontWeight.w900, // أقصى درجات العرض
                    fontStyle: FontStyle.italic, // ميلان لطابع الأكشن والخطورة
                    letterSpacing: 6.0, // تباعد واسع بين الحروف
                    shadows: [
                      // 🔥 ظلال سوداء داكنة جداً تعطي بروزاً مخيفاً للكلمة
                      Shadow(blurRadius: 20, color: Colors.black, offset: Offset(4, 4)),
                      Shadow(blurRadius: 5, color: Color(0xFF4A0000), offset: Offset(-2, -2)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'جاري التحميل', // 🔥 تم التعديل كما طلبت
                  style: TextStyle(
                      color: Colors.white54, // لون رمادي باهت لا يسرق الانتباه من الاسم
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                boxShadow: [
                                  // توهج خفيف أحمر تحت شريط التحميل
                                  BoxShadow(
                                    color: const Color(0xFFB30000).withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5), // حواف حادة أكثر (بدل 10)
                              child: LinearProgressIndicator(
                                value: _controller.value,
                                backgroundColor: Colors.black45, // خلفية داكنة للشريط
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB30000)), // أحمر دموي
                                minHeight: 10, // شريط أعرض ليعطي فخامة
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${(_controller.value * 100).toInt()}%',
                            style: const TextStyle(
                                color: Color(0xFFB30000),
                                fontWeight: FontWeight.w900,
                                fontSize: 22, // رقم النسبة مئوية بارز ومائل
                                fontStyle: FontStyle.italic
                            ),
                          )
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