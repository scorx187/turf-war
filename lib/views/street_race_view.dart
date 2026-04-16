// المسار: lib/views/street_race_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🟢 استدعاء البلوك
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/quick_recovery_dialog.dart';
import '../controllers/street_race_cubit.dart'; // 🟢 استدعاء الكيوبت

class StreetRaceView extends StatelessWidget {
  final VoidCallback onBack;
  const StreetRaceView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    // 🟢 تغليف الشاشة بالكيوبت
    return BlocProvider(
      create: (context) => StreetRaceCubit(),
      child: _StreetRaceViewContent(onBack: onBack),
    );
  }
}

class _StreetRaceViewContent extends StatefulWidget {
  final VoidCallback onBack;
  const _StreetRaceViewContent({required this.onBack});

  @override
  State<_StreetRaceViewContent> createState() => _StreetRaceViewContentState();
}

class _StreetRaceViewContentState extends State<_StreetRaceViewContent> {
  String _activeTab = 'races'; // races, garage, shop

  void _showRaceResultDialog(Map<String, dynamic> result) {
    bool isWinner = result['isWinner'];
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isWinner ? Colors.green : Colors.redAccent)),
          title: Text(isWinner ? "🏆 فزت بالسباق!" : "💀 خسارة قاسية!", style: TextStyle(color: isWinner ? Colors.green : Colors.red, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          content: Text(
            result['message'],
            style: const TextStyle(color: Colors.white70, fontFamily: 'Changa'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("حسناً", style: TextStyle(color: Colors.white, fontFamily: 'Changa'))
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StreetRaceCubit, StreetRaceState>(
      listener: (context, state) {
        // 🟢 معالجة الأخطاء (بما فيها نقص الطاقة عشان نطلع نافذة القهوة)
        if (state.errorMessage.isNotEmpty) {
          if (state.errorMessage.startsWith('energy_shortage:')) {
            int missing = int.parse(state.errorMessage.split(':')[1]);
            QuickRecoveryDialog.show(context, 'energy', missing);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent));
          }
        }

        // 🟢 معالجة رسائل النجاح
        if (state.successMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
        }

        // 🟢 معالجة نتيجة السباق وإظهار النافذة
        if (state.raceResult != null) {
          _showRaceResultDialog(state.raceResult!);
        }
      },
      builder: (context, state) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20), onPressed: widget.onBack),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('سباقات الشوارع 🏁', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa'))),
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
                  Expanded(child: _buildActiveTabContent(context)),
                ],
              ),

              // 🟢 شاشة التحميل وقت السباق (تغطي الشاشة عشان تمنع التكرار)
              if (state.isLoading)
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.redAccent),
                        SizedBox(height: 20),
                        Text('🚦 استعداد للسباق...', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String tabValue, String title, Color color) {
    bool isActive = _activeTab == tabValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
          setState(() => _activeTab = tabValue);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isActive ? color.withOpacity(0.2) : Colors.black54, border: Border.all(color: isActive ? color : Colors.white10), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: isActive ? color : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Changa')),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(BuildContext context) {
    if (_activeTab == 'shop') return _buildShopTab(context);
    if (_activeTab == 'garage') return _buildGarageTab(context);
    return _buildRacesTab(context);
  }

  Widget _buildRacesTab(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final cubit = context.read<StreetRaceCubit>();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cubit.raceOpponents.length,
      itemBuilder: (context, index) {
        final opp = cubit.raceOpponents[index];
        return Card(
          color: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.redAccent, width: 0.5)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            title: Text(opp['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Changa')),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text("السيارة: ${opp['carName']}", style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'Changa', fontSize: 12)),
                if (opp.containsKey('desc')) Text(opp['desc'], style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Changa')),
                const SizedBox(height: 5),
                Text("الغنيمة: ${opp['reward']} | الطاقة: ${opp['energy']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                audio.playEffect('click.mp3');
                // 🟢 استدعاء السباق من الكيوبت
                cubit.startRace(player, opp);
              },
              child: const Text("تحدي 🏁", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Changa')),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGarageTab(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final cubit = context.read<StreetRaceCubit>();

    if (player.ownedCars.isEmpty) return const Center(child: Text('كراجك فاضي! رح للمعرض واشتر سيارة.', style: TextStyle(color: Colors.white70, fontFamily: 'Changa')));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: player.ownedCars.length,
      itemBuilder: (context, index) {
        final carId = player.ownedCars[index];
        final carData = cubit.carShop[carId]!;
        bool isActive = player.activeCarId == carId;

        return Card(
          color: isActive ? Colors.blueAccent.withOpacity(0.2) : Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isActive ? Colors.blueAccent : Colors.white10)),
          child: ListTile(
            leading: Icon(carData['icon'], color: isActive ? Colors.blueAccent : Colors.white, size: 40),
            title: Text(carData['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
            subtitle: Text("السرعة: ${carData['speed']}", style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12)),
            trailing: isActive
                ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                // 🟢 تحديد السيارة عبر الكيوبت
                cubit.useCar(player, carId);
              },
              child: const Text("استخدام", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopTab(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final cubit = context.read<StreetRaceCubit>();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cubit.carShop.length,
      itemBuilder: (context, index) {
        String carId = cubit.carShop.keys.elementAt(index);
        var carData = cubit.carShop[carId]!;
        bool isOwned = player.ownedCars.contains(carId);

        return Card(
          color: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 0.5)),
          child: ListTile(
            leading: Icon(carData['icon'], color: Colors.amber, size: 40),
            title: Text(carData['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
            subtitle: Text("السرعة: ${carData['speed']} | السعر: ${carData['price']}", style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12)),
            trailing: isOwned
                ? const Text("مملوكة", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontFamily: 'Changa'))
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                audio.playEffect('click.mp3');
                // 🟢 استدعاء الشراء عبر الكيوبت
                cubit.buyCar(player, carId, carData['price'], carData['name']);
              },
              child: const Text("شراء 💰", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
            ),
          ),
        );
      },
    );
  }
}