import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/quick_recovery_dialog.dart';
import 'dart:math';

class StreetRaceView extends StatefulWidget {
  final VoidCallback onBack;
  const StreetRaceView({super.key, required this.onBack});

  @override
  State<StreetRaceView> createState() => _StreetRaceViewState();
}

class _StreetRaceViewState extends State<StreetRaceView> {
  String _activeTab = 'races'; // races, garage, shop

  // قائمة السيارات المتاحة في اللعبة
  final Map<String, Map<String, dynamic>> carShop = {
    'datsun_90': {'name': 'داتسون 90', 'speed': 45, 'price': 5000, 'icon': Icons.directions_car},
    'camry_2003': {'name': 'كامري 2003', 'speed': 78, 'price': 18000, 'icon': Icons.time_to_leave},
    'lumina_2008': {'name': 'لومينا 2008 (V6 3.6L)', 'speed': 88, 'price': 35000, 'icon': Icons.airport_shuttle},
    'gtr_r35': {'name': 'جي تي آر R35', 'speed': 125, 'price': 150000, 'icon': Icons.sports_motorsports},
  };

  // الخصوم في الشارع
  final List<Map<String, dynamic>> raceOpponents = [
    {'name': 'مبتدئ الحارة', 'carName': 'داتسون مهترئ', 'enemySpeed': 40, 'reward': 1000, 'energy': 10},
    {'name': 'خصم عنيد', 'carName': 'كامري 2003', 'enemySpeed': 75, 'reward': 3500, 'energy': 15, 'desc': 'انطلاقتها سريعة ومفاجئة، لا تستهن بها!'},
    {'name': 'ملك الخط', 'carName': 'لومينا 2008 V6', 'enemySpeed': 85, 'reward': 7000, 'energy': 20, 'desc': 'ثقيلة وقوية على الخط السريع.'},
    {'name': 'الزعيم السري', 'carName': 'جي تي آر معدل', 'enemySpeed': 120, 'reward': 25000, 'energy': 30, 'desc': 'وحش ياباني لا يرحم.'},
  ];

  void _startRace(PlayerProvider player, AudioProvider audio, Map<String, dynamic> opponent) async {
    if (player.activeCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك سيارة! اذهب للمعرض أولاً.')));
      return;
    }
    if (player.energy < opponent['energy']) {
      QuickRecoveryDialog.show(context, 'energy', opponent['energy'] - player.energy);
      return;
    }

    audio.playEffect('click.mp3');

    // سحب سرعة سيارة اللاعب
    int playerSpeed = carShop[player.activeCarId!]!['speed'];
    int enemySpeed = opponent['enemySpeed'];

    // حساب نسبة الفوز (شوية حظ معتمد على السرعة)
    double winChance = playerSpeed / (playerSpeed + enemySpeed);
    bool isWinner = Random().nextDouble() < winChance;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("🚦 استعداد...", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        content: const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(color: Colors.redAccent))),
      ),
    );

    // محاكاة وقت السباق
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pop(context); // إغلاق نافذة التحميل

    player.finishRace(isWinner, opponent['reward'], opponent['energy']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(isWinner ? "🏆 فزت بالسباق!" : "💀 خسارة قاسية!", style: TextStyle(color: isWinner ? Colors.green : Colors.red)),
        content: Text(
          isWinner
              ? "سيارتك أثبتت جدارتها بالشارع! حصلت على ${opponent['reward']} كاش."
              : "خصمك كان أسرع منك.. طور سيارتك أو اشترِ واحدة أفضل.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
              const Expanded(child: Text('سباقات الشوارع 🏁', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton('races', 'السباقات 🏁', Colors.redAccent),
              _buildTabButton('garage', 'كراجي 🚘', Colors.blueAccent),
              _buildTabButton('shop', 'المعرض 🏢', Colors.amber),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildActiveTabContent()),
      ],
    );
  }

  Widget _buildTabButton(String tabValue, String title, Color color) {
    bool isActive = _activeTab == tabValue;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(color: isActive ? color.withValues(alpha:0.2) : Colors.black54, border: Border.all(color: isActive ? color : Colors.white10), borderRadius: BorderRadius.circular(10)),
        child: Text(title, style: TextStyle(color: isActive ? color : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    if (_activeTab == 'shop') return _buildShopTab();
    if (_activeTab == 'garage') return _buildGarageTab();
    return _buildRacesTab();
  }

  Widget _buildRacesTab() {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: raceOpponents.length,
      itemBuilder: (context, index) {
        final opp = raceOpponents[index];
        return Card(
          color: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.redAccent, width: 0.5)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            title: Text(opp['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text("السيارة: ${opp['carName']}", style: const TextStyle(color: Colors.orangeAccent)),
                if (opp.containsKey('desc')) Text(opp['desc'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 5),
                Text("الغنيمة: ${opp['reward']} | الطاقة: ${opp['energy']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => _startRace(player, audio, opp),
              child: const Text("تحدي 🏁", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGarageTab() {
    final player = Provider.of<PlayerProvider>(context);
    if (player.ownedCars.isEmpty) return const Center(child: Text('كراجك فاضي! رح للمعرض واشتر سيارة.', style: TextStyle(color: Colors.white70)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: player.ownedCars.length,
      itemBuilder: (context, index) {
        final carId = player.ownedCars[index];
        final carData = carShop[carId]!;
        bool isActive = player.activeCarId == carId;

        return Card(
          color: isActive ? Colors.blueAccent.withValues(alpha:0.2) : Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isActive ? Colors.blueAccent : Colors.white10)),
          child: ListTile(
            leading: Icon(carData['icon'], color: isActive ? Colors.blueAccent : Colors.white, size: 40),
            title: Text(carData['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("السرعة: ${carData['speed']}", style: const TextStyle(color: Colors.white70)),
            trailing: isActive
                ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () { Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3'); player.setActiveCar(carId); },
              child: const Text("استخدام"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopTab() {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: carShop.length,
      itemBuilder: (context, index) {
        String carId = carShop.keys.elementAt(index);
        var carData = carShop[carId]!;
        bool isOwned = player.ownedCars.contains(carId);

        return Card(
          color: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 0.5)),
          child: ListTile(
            leading: Icon(carData['icon'], color: Colors.amber, size: 40),
            title: Text(carData['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("السرعة: ${carData['speed']} | السعر: ${carData['price']}", style: const TextStyle(color: Colors.white70)),
            trailing: isOwned
                ? const Text("مملوكة", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                if (player.cash >= carData['price']) {
                  audio.playEffect('click.mp3');
                  player.buyCar(carId, carData['price']);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مبروك! شريت ${carData['name']} 🚘')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كاشك ما يكفي!')));
                }
              },
              child: const Text("شراء 💰", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}