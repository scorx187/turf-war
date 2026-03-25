import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';
import '../views/lucky_wheel_view.dart';
import '../views/crime_view.dart';
import '../views/bank_view.dart';
// [إصلاح التعارض هنا] تجاهلنا كلاس السجن المكرر في هذا الملف
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
import 'dart:async';
import 'package:intl/intl.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

// أضفنا WidgetsBindingObserver لمراقبة حالة الجوال (هوم، إغلاق، إلخ)
class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  int _selectedIndex = 2;
  String _activeArea = 'الخريطة';
  StreamSubscription? _notificationSubscription;

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
    // تسجيل المراقب
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      final audio = Provider.of<AudioProvider>(context, listen: false);
      audio.playBGM();

      _notificationSubscription = player.notificationStream.listen((message) {
        if (mounted) {
          _showStylishNotification(message);
        }
      });
    });
  }

  @override
  void dispose() {
    // حذف المراقب عند الإغلاق
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // التحكم في الموسيقى عند الخروج للهوم أو الرجوع
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
        content: Row(
          children: [
            Icon(message.contains('🎭') ? Icons.theater_comedy : (isWarning ? Icons.warning_amber_rounded : Icons.info_outline), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14))),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: message.contains('🎭') ? Colors.blueAccent.withValues(alpha:0.9) : (isWarning ? Colors.redAccent.withValues(alpha:0.9) : Colors.green.withValues(alpha:0.9)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(15),
        elevation: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // [الدايموند 💎] شاشة تحميل لمنع التصفير!
    if (player.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.redAccent),
              SizedBox(height: 20),
              Text('جاري الاتصال بالعالم السفلي...', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              cash: player.cash,
              gold: player.gold,
              energy: player.energy,
              courage: player.courage,
              health: player.health,
              playerName: player.playerName,
              level: player.crimeLevel,
              xpPercent: player.crimeXP / player.xpToNextLevel,
              isVIP: player.isVIP,
            ),
            Expanded(child: _buildConditionalContent(player)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (index) {
          // منع التنقل إذا كان اللاعب في السجن أو المستشفى
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
    // السجن والمستشفى حالات إجبارية تظهر فوق كل شيء لضمان عدم الهروب
    if (player.isInPrison) {
      return PrisonView(
        prisonReleaseTime: player.prisonReleaseTime,
        cash: player.cash,
        onBailPaid: () {
          player.payBail();
          // تم مسح الكود اللي يرجعك للخريطة إجبارياً
          // الآن اللعبة بتخليك في نفس المكان اللي كنت فيه (مثل صفحة الجرائم)
        },
      );
    }
    if (player.isHospitalized) {
      return HospitalView(onBack: () => setState(() => _activeArea = 'الخريطة'));
    }
    return _buildMainContent(player);
  }

  Widget _buildMainContent(PlayerProvider player) {
    if (_selectedIndex == 0) return const InventoryView();
    if (_selectedIndex == 1) return const ChatView();
    if (_selectedIndex == 3) {
      return CrimeView(
        courage: player.courage,
        crimeSuccessCounts: player.crimeSuccessCounts,
        onSuccess: (reward, index, energyUsed) {
          final audio = Provider.of<AudioProvider>(context, listen: false);
          audio.playEffect('click.mp3');
          final List<String> crimeNames = ['سرقة محفظة', 'سطو على متجر', 'سرقة سيارة', 'سطو على فيلا', 'سطو على البنك'];
          player.addCash(reward, reason: "نجاح: ${crimeNames[index]}");
          player.incrementCrimeSuccess(index, crimeNames[index]);

          if (index == 2) {
            player.addInventoryItem('stolen_car', 1);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حصلت على سيارة مسروقة! أرسلها للتشليح 🚗🔧'), backgroundColor: Colors.green));
          }

          int courageCost = index == 0 ? 5 : index == 1 ? 15 : index == 2 ? 30 : index == 3 ? 40 : 60;
          player.setCourage(player.courage - courageCost);
          if (energyUsed > 0) player.setEnergy(player.energy - energyUsed);
        },
        onFailure: () {
          final audio = Provider.of<AudioProvider>(context, listen: false);
          audio.playEffect('click.mp3');
          player.handleCrimeFailure(2);
        },
      );
    }
    if (_selectedIndex == 5) return _buildProfileView(player);
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
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final loc = locations[index];
        return GestureDetector(
          onTap: () {
            Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
            setState(() => _activeArea = loc['name']);
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: loc['color'], width: 1.5)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(loc['icon'], size: 40, color: loc['color']), const SizedBox(height: 10), Text(loc['name'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))]),
          ),
        );
      },
    );
  }

  String _getItemName(String id) {
    switch (id) {
      case 'dagger': return 'خنجر صدئ';
      case 'revolver': return 'مسدس ريفولفر';
      case 'katana': return 'كاتانا الساموراي';
      case 'shotgun': return 'بندقية شوزن';
      case 'sniper': return 'قناصة الصقر';
      case 'riot_shield': return 'درع مكافحة الشغب';
      case 'kevlar_vest': return 'سترة واقية';
      case 'steel_armor': return 'درع فولاذي';
      case 'ninja_suit': return 'زي النينجا الأسود';
      case 'exoskeleton': return 'البدلة الخارقة';
      case 'black_mask': return 'قناع أسود';
      case 'silicon_mask': return 'قناع سيليكون';
      case 'name_change_card': return 'بطاقة تغيير الاسم';
      case 'master_key': return 'المفتاح الرئيسي';
    // أدوات الجريمة الجديدة
      case 'crowbar': return 'عتلة فولاذية';
      case 'slim_jim': return 'مفتاح مسطرة';
      case 'jammer': return 'جهاز تشويش';
      case 'lockpick': return 'طقم مفاتيح';
      case 'glass_cutter': return 'قاطع زجاج';
      case 'laptop': return 'لابتوب تهكير';
      case 'thermite': return 'ثيرميت حارق';
      case 'stethoscope': return 'سماعة طبية';
      case 'hydraulic': return 'قاطع هيدروليك';
      case 'emp_device': return 'جهاز EMP';
      default: return 'غير معروف';
    }
  }

  Widget _buildProfileView(PlayerProvider player) {
    final audio = Provider.of<AudioProvider>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(radius: 50, backgroundColor: player.isVIP ? Colors.amber : Colors.grey[700], child: Icon(player.isVIP ? Icons.workspace_premium : Icons.person, size: 60, color: player.isVIP ? Colors.black : Colors.white54)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (player.isVIP) const Icon(Icons.workspace_premium, color: Colors.amber, size: 28), const SizedBox(width: 8), Text(player.playerName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))]),

          // [Diamond] عرض مستوى الملاحقة (Heat) في البروفايل
          Container(
            margin: const EdgeInsets.symmetric(vertical: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withValues(alpha:0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [Icon(Icons.local_police, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text("مستوى الملاحقة", style: TextStyle(color: Colors.white70))]),
                Text("${player.heat.toInt()}%", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 10),
          if (player.isVIP) _buildProfileItem(Icons.workspace_premium, "عضوية VIP", "تنتهي في: ${DateFormat('yyyy-MM-dd HH:mm').format(player.vipUntil!)}", Colors.amber),
          if (player.isInGang) _buildProfileItem(Icons.security, "العصابة", player.gangName!, Colors.redAccent),
          _buildProfileItem(Icons.settings, "قطع غيار للإصلاح", "${player.spareParts}", Colors.blueAccent), // [Diamond]
          _buildProfileItem(Icons.sentiment_very_satisfied, "نسبة السعادة", "${player.happiness}%", Colors.yellow),
          _buildProfileItem(Icons.star, "المستوى الإجرامي", player.crimeLevel.toString(), Colors.amber),
          _buildProfileItem(Icons.credit_score, "السمعة الائتمانية", player.creditScore.toString(), Colors.blueAccent),
          _buildProfileItem(Icons.account_balance_wallet, "الرصيد الكلي", (player.cash + player.bankBalance).toString(), Colors.green),

          const SizedBox(height: 20),
          const Text("إحصائيات القتال", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildProfileItem(Icons.fitness_center, "القوة", player.strength.toStringAsFixed(1), Colors.redAccent),
          _buildProfileItem(Icons.shield, "الدفاع", player.defense.toStringAsFixed(1), Colors.blueAccent),
          _buildProfileItem(Icons.psychology, "المهارة", player.skill.toStringAsFixed(1), Colors.greenAccent),
          _buildProfileItem(Icons.speed, "السرعة", player.speed.toStringAsFixed(1), Colors.orangeAccent),

          const SizedBox(height: 20),
          const Text("المعدات المجهزة", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (player.equippedWeaponId != null) _buildProfileItem(Icons.colorize, "السلاح القتالي", _getItemName(player.equippedWeaponId!), Colors.orange),
          if (player.equippedArmorId != null) _buildProfileItem(Icons.shield, "الدرع القتالي", _getItemName(player.equippedArmorId!), Colors.blue),
          if (player.equippedCrimeToolId != null) _buildProfileItem(Icons.engineering, "أداة الجريمة", _getItemName(player.equippedCrimeToolId!), Colors.teal), // [Diamond]
          if (player.equippedMaskId != null) _buildProfileItem(Icons.theater_comedy, "القناع المجهز", _getItemName(player.equippedMaskId!), Colors.pink),

          if (player.equippedWeaponId == null && player.equippedArmorId == null && player.equippedMaskId == null && player.equippedCrimeToolId == null)
            const Text("لا توجد معدات مجهزة", style: TextStyle(color: Colors.white38)),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: audio.isMuted ? Colors.redAccent.withValues(alpha:0.2) : Colors.green.withValues(alpha:0.2),
              side: BorderSide(color: audio.isMuted ? Colors.redAccent : Colors.green),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => audio.toggleMute(),
            icon: Icon(audio.isMuted ? Icons.volume_off : Icons.volume_up, color: audio.isMuted ? Colors.redAccent : Colors.green),
            label: Text(audio.isMuted ? "تشغيل الصوت" : "كتم الصوت", style: TextStyle(color: audio.isMuted ? Colors.redAccent : Colors.green)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha:0.2), side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 50)), onPressed: () { audio.playEffect('click.mp3'); _showResetConfirmation(player); }, icon: const Icon(Icons.delete_forever, color: Colors.red), label: const Text("مسح كافة البيانات والبدء من جديد", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value, Color color) {
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(label, style: const TextStyle(color: Colors.white70))]), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))]));
  }

  void _showResetConfirmation(PlayerProvider player) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: Colors.grey[900], title: const Text("تحذير نهائي ⚠️", style: TextStyle(color: Colors.white)), content: const Text("هل أنت متأكد من مسح كافة بياناتك? لا يمكن التراجع عن هذا الإجراء.", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.blue))), TextButton(onPressed: () { player.resetPlayerData(); Navigator.pop(context); setState(() => _selectedIndex = 2); }, child: const Text("نعم، امسح كل شيء", style: TextStyle(color: Colors.red)))]));
  }
}