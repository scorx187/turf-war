// المسار: lib/views/store_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class StoreView extends StatelessWidget {
  final int initialTab; // 0 للكاش، 1 للذهب

  const StoreView({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1D),
          appBar: AppBar(
            backgroundColor: Colors.black87,
            title: const Text('السوق السوداء (شراء موارد) 💎', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.amber),
            bottom: const TabBar(
              indicatorColor: Colors.amber,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white54,
              labelStyle: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                Tab(text: 'شراء كاش 💵'),
                Tab(text: 'شراء ذهب 🪙'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _CashStoreTab(),
              _GoldStoreTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- قسم الكاش -----------------
class _CashStoreTab extends StatelessWidget {
  const _CashStoreTab();

  // 🟢 ترتيب من الأرخص للأغلى مع استخدام صورة الكاش الأصلية
  final List<Map<String, dynamic>> cashPackages = const [
    {'amount': 25000, 'price': 5, 'bonus': null, 'image': 'assets/images/icons/cash.png'},
    {'amount': 120000, 'price': 19, 'bonus': '+10% كاش إضافي', 'image': 'assets/images/icons/cash.png'},
    {'amount': 350000, 'price': 49, 'bonus': '+15% كاش إضافي', 'image': 'assets/images/icons/cash.png'},
    {'amount': 800000, 'price': 99, 'bonus': '+20% كاش إضافي', 'image': 'assets/images/icons/cash.png'},
    {'amount': 2000000, 'price': 199, 'bonus': '+35% كاش إضافي', 'image': 'assets/images/icons/cash.png'},
    {'amount': 6000000, 'price': 499, 'bonus': '+50% إضافي (عرض الزعيم)', 'image': 'assets/images/icons/cash.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder( // 🟢 تم التغيير إلى ListView للقائمة الطولية
      padding: const EdgeInsets.all(15),
      itemCount: cashPackages.length,
      itemBuilder: (context, index) {
        final pkg = cashPackages[index];
        return _StoreCard(
          isGold: false,
          amount: pkg['amount'],
          price: pkg['price'],
          bonus: pkg['bonus'],
          imagePath: pkg['image'],
        );
      },
    );
  }
}

// ----------------- قسم الذهب -----------------
class _GoldStoreTab extends StatelessWidget {
  const _GoldStoreTab();

  // 🟢 ترتيب من الأرخص للأغلى مع استخدام صورة الذهب الأصلية
  final List<Map<String, dynamic>> goldPackages = const [
    {'amount': 50, 'price': 5, 'bonus': null, 'image': 'assets/images/icons/gold.png'},
    {'amount': 250, 'price': 19, 'bonus': '+15% ذهب إضافي', 'image': 'assets/images/icons/gold.png'},
    {'amount': 700, 'price': 49, 'bonus': '+20% ذهب إضافي', 'image': 'assets/images/icons/gold.png'},
    {'amount': 1600, 'price': 99, 'bonus': '+30% ذهب إضافي', 'image': 'assets/images/icons/gold.png'},
    {'amount': 3500, 'price': 199, 'bonus': '+40% ذهب إضافي', 'image': 'assets/images/icons/gold.png'},
    {'amount': 10000, 'price': 499, 'bonus': '+60% إضافي (عرض الزعيم)', 'image': 'assets/images/icons/gold.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder( // 🟢 تم التغيير إلى ListView للقائمة الطولية
      padding: const EdgeInsets.all(15),
      itemCount: goldPackages.length,
      itemBuilder: (context, index) {
        final pkg = goldPackages[index];
        return _StoreCard(
          isGold: true,
          amount: pkg['amount'],
          price: pkg['price'],
          bonus: pkg['bonus'],
          imagePath: pkg['image'],
        );
      },
    );
  }
}

// ----------------- تصميم بطاقة الشراء (أفقية وعريضة) -----------------
class _StoreCard extends StatelessWidget {
  final bool isGold;
  final int amount;
  final int price;
  final String? bonus;
  final String imagePath;

  const _StoreCard({required this.isGold, required this.amount, required this.price, this.bonus, required this.imagePath});

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  void _simulatePurchase(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context, listen: false);
    audio.playEffect('click.mp3');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 20),
            Text('جاري الاتصال بمتجر الدفع...', style: TextStyle(color: Colors.white, fontFamily: 'Changa')),
          ],
        ),
      ),
    );

    // محاكاة الاتصال بالمتجر (تأخير ثانيتين)
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context); // إغلاق دائرة التحميل

        final player = Provider.of<PlayerProvider>(context, listen: false);
        if (isGold) {
          player.addGold(amount);
        } else {
          player.addCash(amount, reason: 'شراء من المتجر 🛒');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت عملية الشراء بنجاح! حصلت على ${_formatWithCommas(amount)} ${isGold ? 'ذهب 🪙' : 'كاش 💵'}', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = isGold ? Colors.orangeAccent : Colors.greenAccent;
    Color bgColor = isGold ? Colors.orange.withOpacity(0.05) : Colors.green.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 15), // مسافة بين الباكجات
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: mainColor.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: mainColor.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // 1. الأيقونة (الصورة الأصلية من ملفات اللعبة)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: mainColor.withOpacity(0.5)),
                  ),
                  child: Image.asset(
                    imagePath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(isGold ? Icons.monetization_on : Icons.attach_money, color: mainColor, size: 40),
                  ),
                ),
                const SizedBox(width: 15),

                // 2. التفاصيل (الكمية والبونص)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatWithCommas(amount),
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Changa', shadows: [Shadow(color: mainColor, blurRadius: 5)]),
                      ),
                      Text(
                        isGold ? 'سبيكة ذهبية' : 'دولار كاش',
                        style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Changa'),
                      ),
                      if (bonus != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          bonus!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                        ),
                      ]
                    ],
                  ),
                ),

                // 3. زر الشراء
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                    shadowColor: mainColor.withOpacity(0.5),
                  ),
                  onPressed: () => _simulatePurchase(context),
                  child: Text(
                    '$price ر.س',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa', fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // شريط "الأفضل" للباكج الأخير
          if (bonus != null && bonus!.contains('الأفضل'))
            Positioned(
              top: -10,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 4)],
                ),
                child: const Text(
                  '💎 الخيار الأفضل',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}