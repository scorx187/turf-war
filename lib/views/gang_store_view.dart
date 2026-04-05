// المسار: lib/views/gang_store_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // 🟢 قائمة الأدوات الحصرية لمتجر العصابة 🟢
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

  void _buyItem(Map<String, dynamic> item, PlayerProvider player, AudioProvider audio) async {
    int price = item['price'];
    bool isGold = item['isGold'];

    // التحقق من الرصيد
    if (isGold && player.gold < price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      return;
    } else if (!isGold && player.cash < price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك كاش كافي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      return;
    }

    // تأكيد الشراء
    showDialog(
        context: context,
        builder: (c) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: item['color'])),
            title: Text('تأكيد الشراء 🛒', style: TextStyle(color: item['color'], fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            content: Text('هل أنت متأكد من شراء [${item['name']}] مقابل ${isGold ? '$price ذهب 🪙' : '\$${_formatWithCommas(price)} كاش 💵'}؟', style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', height: 1.5)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa'))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: item['color']),
                onPressed: () {
                  Navigator.pop(c);
                  _processPurchase(item, player, audio);
                },
                child: const Text('شراء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              ),
            ],
          ),
        )
    );
  }

  void _processPurchase(Map<String, dynamic> item, PlayerProvider player, AudioProvider audio) async {
    setState(() => _isProcessing = true);
    audio.playEffect('click.mp3');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
    );

    // محاكاة وقت الشراء
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context); // إغلاق التحميل

      // خصم المبلغ
      if (item['isGold']) {
        player.removeGold(item['price']);
      } else {
        player.removeCash(item['price'], reason: 'شراء ${item['name']} من متجر العصابة');
      }

      // تنفيذ تأثير الأداة
      if (item['id'] == 'energy_drink') {
        player.setEnergy(player.maxEnergy);
      } else if (item['id'] == 'bribe_cop') {
        // إذا كان عندك دالة setHeat استخدمها، وهنا نفترض إنك بتمسحها
        // player.setHeat(0);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح سجلك الأمني بنجاح! 🚔', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.teal));
      } else {
        // للأسلحة والدروع
        player.addInventoryItem(item['id'], 1);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم شراء [${item['name']}] بنجاح! 🎉', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        body: SafeArea(
          top: false,
          child: Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final audio = Provider.of<AudioProvider>(context, listen: false);

                return Column(
                  children: [
                    // 🟢 التوب بار الثابت 🟢
                    TopBar(
                        cash: player.cash, gold: player.gold, energy: player.energy, maxEnergy: player.maxEnergy,
                        courage: player.courage, maxCourage: player.maxCourage, health: player.health, maxHealth: player.maxHealth,
                        prestige: player.prestige, maxPrestige: player.maxPrestige, playerName: player.playerName,
                        profilePicUrl: player.profilePicUrl, level: player.crimeLevel, currentXp: player.crimeXP,
                        maxXp: player.xpToNextLevel, isVIP: player.isVIP
                    ),

                    // 🟢 هيدر الشاشة 🟢
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border(bottom: BorderSide(color: Colors.amber.withOpacity(0.5), width: 2)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.amber, size: 20),
                              onPressed: () { audio.playEffect('click.mp3'); Navigator.pop(context); }
                          ),
                          const Expanded(
                            child: Text('متجر العصابة السري 🛒', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          ),
                        ],
                      ),
                    ),

                    // 🟢 قائمة الأدوات 🟢
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: _storeItems.length,
                        itemBuilder: (context, index) {
                          final item = _storeItems[index];
                          bool isGold = item['isGold'];
                          bool canAfford = isGold ? player.gold >= item['price'] : player.cash >= item['price'];

                          return Card(
                            color: Colors.black45,
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: item['color'].withOpacity(0.4), width: 1.5)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // أيقونة الأداة
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: item['color'].withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: item['color'].withOpacity(0.5))),
                                    child: Icon(item['icon'], color: item['color'], size: 30),
                                  ),
                                  const SizedBox(width: 15),

                                  // تفاصيل الأداة
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                        const SizedBox(height: 4),
                                        Text(item['desc'], style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Changa', height: 1.4)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(isGold ? Icons.monetization_on : Icons.attach_money, color: isGold ? Colors.amber : Colors.greenAccent, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              isGold ? '${item['price']}' : '\$${_formatWithCommas(item['price'])}',
                                              textDirection: TextDirection.ltr,
                                              style: TextStyle(color: isGold ? Colors.amber : Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa', fontSize: 14),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),

                                  // زر الشراء
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canAfford ? item['color'] : Colors.grey[800],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                    ),
                                    onPressed: _isProcessing || !canAfford ? null : () => _buyItem(item, player, audio),
                                    child: Text('شراء', style: TextStyle(color: canAfford ? Colors.white : Colors.white54, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
          ),
        ),
      ),
    );
  }
}