// المسار: lib/views/gang_store_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart'; // 🟢 مكتبة السيرفر
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';

class GangStoreView extends StatefulWidget {
  const GangStoreView({super.key});

  @override
  State<GangStoreView> createState() => _GangStoreViewState();
}

class _GangStoreViewState extends State<GangStoreView> {
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _storeItems = [
    {
      'id': 'mafia_gun',
      'name': 'رشاش تومي (Tommy Gun)',
      'desc': 'سلاح كلاسيكي للمافيا. يرفع من قوتك الهجومية في حروب الشوارع.',
      'price': 1500000,
      'isGold': false,
      'icon': Icons.hardware,
      'color': Colors.redAccent,
    },
    {
      'id': 'tactical_armor',
      'name': 'درع تكتيكي مهرب',
      'desc': 'درع مسروق من القوات الخاصة. يرفع من دفاعك ويحميك من الضربات القاضية.',
      'price': 1200000,
      'isGold': false,
      'icon': Icons.security,
      'color': Colors.blueAccent,
    },
    {
      'id': 'energy_drink',
      'name': 'حقنة أدرينالين',
      'desc': 'تستعيد طاقتك (Energy) بالكامل فوراً للعودة إلى تنفيذ الجرائم.',
      'price': 15,
      'isGold': true,
      'icon': Icons.bolt,
      'color': Colors.yellowAccent,
    },
    {
      'id': 'bribe_cop',
      'name': 'رشوة ضابط فاسد',
      'desc': 'يمسح سجل الملاحقة الأمنية (Heat) بالكامل لتبعد الشبهات عنك.',
      'price': 30,
      'isGold': true,
      'icon': Icons.local_police,
      'color': Colors.tealAccent,
    },
  ];

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  // 🟢 دالة الشراء الآمنة من متجر العصابة
  void _buyItem(Map<String, dynamic> item, PlayerProvider player, AudioProvider audio) async {
    int price = item['price'];
    bool isGold = item['isGold'];
    String currencyType = isGold ? 'gold' : 'cash';

    if (isGold && player.gold < price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      return;
    } else if (!isGold && player.cash < price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك كاش كافي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      return;
    }

    audio.playEffect('click.mp3');
    setState(() { _isProcessing = true; });

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)));

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('buyItem');
      final result = await callable.call({
        'uid': player.uid,
        'itemId': item['id'],
        'cost': price,
        'currencyType': currencyType,
        'amount': 1,
      });

      Navigator.pop(context);

      if (result.data['success'] == true) {
        if (isGold) {
          player.removeGold(price);
        } else {
          player.removeCash(price, reason: 'شراء ${item['name']} من متجر العصابة');
        }

        // إذا كان العنصر يؤثر فوراً (المفترض يتم استخدامه من المخزن، لكن للسرعة نحدثه شكلياً)
        if (item['id'] == 'energy_drink') {
          player.setEnergy(100);
        } else if (item['id'] == 'bribe_cop') {
          player.setHeat(0);
        } else {
          player.addInventoryItem(item['id'], 1);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الشراء بنجاح! تم تخزين ${item['name']} في المخزن.', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مرفوض من السيرفر: ${e.toString()}', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1D),
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.amber), onPressed: () { audio.playEffect('click.mp3'); Navigator.pop(context); }),
                const Text('سوق العصابة السري 💼', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                const SizedBox(width: 48),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Text('مرحباً بك في السوق السري.. هنا نوفر لرجال العصابة ما لا يتوفر في السوق العادي. الأسعار غالية، لكن البضاعة تستحق!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 13)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _storeItems.length,
                itemBuilder: (context, index) {
                  final item = _storeItems[index];
                  return Card(
                    color: Colors.black45,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: item['color'].withValues(alpha: 0.5), width: 1.5)),
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: item['color'].withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(item['icon'], color: item['color'], size: 30)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(item['desc'], style: const TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 11)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(item['isGold'] ? Icons.monetization_on : Icons.attach_money, color: item['isGold'] ? Colors.amber : Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Text(_formatWithCommas(item['price']), style: TextStyle(color: item['isGold'] ? Colors.amber : Colors.green, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: item['color'], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: _isProcessing ? null : () => _buyItem(item, player, audio),
                            child: const Text('شراء', style: TextStyle(color: Colors.black, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}