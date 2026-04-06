// المسار: lib/views/real_estate_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/market_provider.dart';
import '../utils/game_data.dart';
import 'player_profile_view.dart';

class RealEstateView extends StatefulWidget {
  final VoidCallback onBack;

  const RealEstateView({super.key, required this.onBack});

  @override
  State<RealEstateView> createState() => _RealEstateViewState();
}

class _RealEstateViewState extends State<RealEstateView> {
  String _currentFilter = 'newest';

  // 🟢 متغير جديد عشان نفصل إعلاناتك عن السوق العام 🟢
  int _marketTab = 0; // 0 = السوق العام، 1 = إعلاناتي

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _moneyText(int amount, {double fontSize = 11, Color color = Colors.greenAccent, FontWeight fontWeight = FontWeight.bold}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        '\$${_formatNumber(amount)}',
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight, fontFamily: 'Changa'),
      ),
    );
  }

  void _openProfile(BuildContext context, String? uid) {
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اللاعب مجهول (هذا العقد تم قبل التحديث الأخير)', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
          )
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: PlayerProfileView(
            targetUid: uid,
            onBack: () => Navigator.pop(context),
          ),
        ),
      ),
    ));
  }

  void _confirmAction(BuildContext context, String title, Widget contentWidget, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
        title: Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
        content: contentWidget,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('تأكيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
        title: const Text('شرح سوق العقارات ℹ️', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏠 عقارات سكنية:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('تزيد من نسبة السعادة اللي تضاعف تدريبك بالنادي. تقدر تسكن فيها أو تعرضها للإيجار.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              SizedBox(height: 10),
              Text('🤝 سوق الإيجارات:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('تقدر تستأجر عقار من لاعب ثاني لفترة محددة. إذا فسخت العقد قبل وقته (قانون المافيا: الفلوس ما ترجع!).', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              SizedBox(height: 10),
              Text('🏢 مشاريع تجارية:', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('تدر عليك كاش تلقائي كل يوم. أسعارها تتأثر بحالة السوق العالمية (كل 6 ساعات).', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً فهمت', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final market = Provider.of<MarketProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const SizedBox(height: 5),
              const Center(
                child: Text('إمبراطورية العقارات 🏙️', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 5),

              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        indicatorColor: Colors.amber,
                        labelColor: Colors.amber,
                        unselectedLabelColor: Colors.white54,
                        tabs: [
                          Tab(text: "عقاراتي"),
                          Tab(text: "سوق الإيجارات"),
                          Tab(text: "مشاريع تجارية"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildResidentialTab(context, player, audio),
                            _buildRentalMarketTab(context, player, audio),
                            _buildCommercialTab(context, player, market, audio),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
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
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 20, left: 25, right: 25),
          child: SafeArea(
            bottom: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    audio.playEffect('click.mp3');
                    widget.onBack();
                  },
                  behavior: HitTestBehavior.opaque,
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
                  behavior: HitTestBehavior.opaque,
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
      ),
    );
  }

  Widget _buildResidentialTab(BuildContext context, PlayerProvider player, AudioProvider audio) {
    return ListView.builder(
      itemCount: GameData.residentialProperties.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final prop = GameData.residentialProperties[index];
        final bool isOwned = player.ownedProperties.contains(prop['id']);
        final bool isListed = player.listedProperties.contains(prop['id']);
        final bool isRentedOut = player.rentedOutProperties.containsKey(prop['id']);

        bool isActive = player.activePropertyId == prop['id'];
        bool isActiveRented = player.activeRentedProperty != null && player.activeRentedProperty!['id'] == prop['id'];

        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: (isActive || isActiveRented) ? Colors.green : (isListed ? Colors.amber : (isOwned ? Colors.blue : (prop['color'] as Color).withOpacity(0.3))),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (prop['color'] as Color).withOpacity(0.2),
                  child: Icon(prop['icon'] as IconData, color: prop['color']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prop['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(prop['description'], style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.sentiment_very_satisfied, color: Colors.yellow, size: 14),
                          Text(' سعادة: ${prop['happiness']}', style: const TextStyle(color: Colors.yellow, fontSize: 11)),
                          if (!isOwned && !isActiveRented) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.payments, color: Colors.green, size: 14),
                            const SizedBox(width: 4),
                            _moneyText(prop['price']),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                if (isActiveRented)
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => _openProfile(context, player.activeRentedProperty!['ownerId']),
                        child: Row(
                          children: [
                            Text('مؤجر من: ${player.activeRentedProperty!['ownerName'] ?? 'لاعب'}', style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                            const SizedBox(width: 4),
                            const Icon(Icons.account_circle, color: Colors.blueAccent, size: 14),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(DateFormat('MM-dd HH:mm').format(DateTime.parse(player.activeRentedProperty!['expire'])), style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(60, 25)),
                        onPressed: () {
                          audio.playEffect('click.mp3');
                          _confirmAction(context, 'فسخ العقد ⚠️', const Text('حسب قانون المافيا: إذا فسخت العقد لن تسترد أي مبلغ دفعته! هل أنت متأكد أنك تريد الخروج من العقار؟', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')), () {
                            player.cancelRentedProperty();
                          });
                        },
                        child: const Text('فسخ العقد', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                else if (isActive)
                  const Text('سكنك الحالي', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))
                else if (isRentedOut)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            String renterId = player.rentedOutProperties[prop['id']]['renterId'] ?? '';
                            _openProfile(context, renterId);
                          },
                          child: Row(
                            children: [
                              Text('مؤجر لـ: ${player.rentedOutProperties[prop['id']]['renterName'] ?? 'مجهول'}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                              const SizedBox(width: 4),
                              const Icon(Icons.account_circle, color: Colors.orangeAccent, size: 14),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('MM-dd HH:mm').format(DateTime.parse(player.rentedOutProperties[prop['id']]['expire'])), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    )
                  else if (isListed)
                      Column(
                        children: [
                          const Text('معروض بالسوق', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(60, 25)),
                            onPressed: () {
                              audio.playEffect('click.mp3');
                              _confirmAction(context, 'سحب العقار', Text('هل أنت متأكد من سحب ${prop['name']} من سوق الإيجارات؟', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')), () {
                                player.cancelRentalListing(prop['id']);
                              });
                            },
                            child: const Text('سحب العرض', style: TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ],
                      )
                    else if (isOwned)
                        Column(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 25)),
                              onPressed: () {
                                audio.playEffect('click.mp3');
                                _confirmAction(context, 'الانتقال للعقار', Text('هل تريد السكن في ${prop['name']} والحصول على +${prop['happiness']} سعادة؟', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')), () {
                                  player.setActiveProperty(prop['id'], prop['happiness']);
                                });
                              },
                              child: const Text('انتقال', style: TextStyle(fontSize: 10, color: Colors.white)),
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 25)),
                              onPressed: () { audio.playEffect('click.mp3'); _showRentDialog(context, player, prop); },
                              child: const Text('تأجير للاعبين', style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: player.cash >= prop['price'] ? Colors.orange : Colors.grey,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(60, 30),
                          ),
                          onPressed: player.cash >= prop['price'] ? () {
                            audio.playEffect('click.mp3');
                            _confirmAction(context, 'شراء عقار', Wrap(
                              children: [
                                Text('هل أنت متأكد من شراء ${prop['name']} بمبلغ ', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                _moneyText(prop['price'], color: Colors.amber, fontSize: 13),
                                const Text(' كاش؟', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                              ],
                            ), () {
                              player.buyProperty(prop['id'], prop['price'], prop['happiness']);
                            });
                          } : null,
                          child: const Text('شراء', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                        )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRentDialog(BuildContext context, PlayerProvider player, Map<String, dynamic> prop) {
    int dailyPrice = 50000;
    int rentDays = 7;

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) {
                int totalPrice = dailyPrice * rentDays;

                return AlertDialog(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
                  title: Text('تأجير ${prop['name']} 🔑', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('اعرض عقارك في السوق ليراه كل اللاعبين!', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 20),
                        const Text('سعر الإيجار اليومي (كاش):', style: TextStyle(color: Colors.white, fontSize: 14)),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.greenAccent),
                          decoration: const InputDecoration(hintText: 'مثال: 50000', hintStyle: TextStyle(color: Colors.white24)),
                          onChanged: (val) {
                            setState(() { dailyPrice = int.tryParse(val) ?? 0; });
                          },
                        ),
                        const SizedBox(height: 20),
                        Text('مدة الإيجار: $rentDays يوم', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        Slider(
                          value: rentDays.toDouble(),
                          min: 1, max: 30,
                          activeColor: Colors.amber,
                          onChanged: (val) { setState(() { rentDays = val.toInt(); }); },
                        ),
                        const Divider(color: Colors.white24),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('إجمالي ما ستحصل عليه: ', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            _moneyText(totalPrice, fontSize: 14),
                          ],
                        ),
                        const Text('(سيدفعها المستأجر مقدماً لضمان حقك)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                      onPressed: () {
                        if (dailyPrice > 0) {
                          Navigator.pop(context);
                          _confirmAction(context, 'نشر الإعلان', const Text('متأكد من نشر العقار في السوق ليراه اللاعبين؟', style: TextStyle(color: Colors.white)), () {
                            player.listPropertyForRent(prop['id'], dailyPrice, rentDays);
                          });
                        }
                      },
                      child: const Text('نشر في السوق', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  Widget _filterChip(String label, String code) {
    bool isSel = _currentFilter == code;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isSel ? Colors.amber : Colors.transparent, border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSel ? Colors.black : Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRentalMarketTab(BuildContext context, PlayerProvider player, AudioProvider audio) {
    return Column(
      children: [
        // 🟢 الأزرار الجديدة لفصل إعلاناتي عن السوق العام 🟢
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () { audio.playEffect('click.mp3'); setState(() => _marketTab = 0); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: _marketTab == 0 ? Colors.amber : Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber)
                    ),
                    child: Center(child: Text("السوق العام", style: TextStyle(color: _marketTab == 0 ? Colors.black : Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa'))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () { audio.playEffect('click.mp3'); setState(() => _marketTab = 1); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: _marketTab == 1 ? Colors.amber : Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber)
                    ),
                    child: Center(child: Text("إعلاناتي", style: TextStyle(color: _marketTab == 1 ? Colors.black : Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa'))),
                  ),
                ),
              ),
            ],
          ),
        ),

        // الفلاتر
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _filterChip('الأحدث', 'newest'),
              _filterChip('السعادة الأعلى', 'happy_desc'),
              _filterChip('السعر الأعلى', 'price_desc'),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('property_rentals').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("لا توجد عقارات معروضة للإيجار حالياً.", style: TextStyle(color: Colors.white54, fontSize: 16)));
              }

              var docs = snapshot.data!.docs.map((d) {
                var map = d.data() as Map<String, dynamic>;
                map['docId'] = d.id;
                return map;
              }).toList();

              // 🟢 تطبيق فلتر (السوق العام / إعلاناتي) 🟢
              if (_marketTab == 0) {
                // نعرض كل السوق ما عدا إعلانات اللاعب الحالي
                docs = docs.where((d) => d['ownerId'] != player.uid).toList();
              } else {
                // نعرض إعلانات اللاعب الحالي فقط
                docs = docs.where((d) => d['ownerId'] == player.uid).toList();
              }

              if (docs.isEmpty) {
                return Center(child: Text(_marketTab == 0 ? "السوق فارغ حالياً." : "ليس لديك أي إعلانات في السوق.", style: const TextStyle(color: Colors.white54, fontSize: 16)));
              }

              // تطبيق فلاتر الترتيب
              if (_currentFilter == 'newest') {
                docs.sort((a, b) => (b['timestamp'] as Timestamp?)?.compareTo(a['timestamp'] as Timestamp? ?? Timestamp.now()) ?? 0);
              } else if (_currentFilter == 'happy_desc') {
                docs.sort((a, b) {
                  int hA = GameData.residentialProperties.firstWhere((p) => p['id'] == a['propertyId'], orElse: () => {'happiness': 0})['happiness'];
                  int hB = GameData.residentialProperties.firstWhere((p) => p['id'] == b['propertyId'], orElse: () => {'happiness': 0})['happiness'];
                  return hB.compareTo(hA);
                });
              } else if (_currentFilter == 'price_desc') {
                docs.sort((a, b) => (b['dailyPrice'] as int).compareTo(a['dailyPrice'] as int));
              }

              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final listing = docs[index];
                  final prop = GameData.residentialProperties.firstWhere((p) => p['id'] == listing['propertyId'], orElse: () => GameData.residentialProperties[0]);
                  int totalPrice = listing['dailyPrice'] * listing['days'];
                  bool isMyListing = listing['ownerId'] == player.uid;

                  return Card(
                    color: Colors.black45,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.amber.withOpacity(0.5))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: (prop['color'] as Color).withOpacity(0.2), child: Icon(prop['icon'] as IconData, color: prop['color'])),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(prop['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    // 🟢 إذا كان الإعلان لي، أمنع الضغط وأشيل الخط 🟢
                                    if (isMyListing)
                                      const Text('المالك: أنت 👑', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold))
                                    else
                                      GestureDetector(
                                        onTap: () => _openProfile(context, listing['ownerId']),
                                        child: Row(
                                          children: [
                                            Text('المالك: ${listing['ownerName']}', style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.account_circle, color: Colors.blueAccent, size: 14),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('سعادة: +${prop['happiness']}', style: const TextStyle(color: Colors.yellow, fontSize: 11)),
                                Row(
                                  children: [
                                    const Text('الإيجار اليومي: ', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                                    _moneyText(listing['dailyPrice']),
                                  ],
                                ),
                                Text('المدة: ${listing['days']} أيام', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              const Text('الإجمالي', style: TextStyle(color: Colors.white54, fontSize: 10)),
                              _moneyText(totalPrice, fontSize: 12),
                              const SizedBox(height: 4),
                              if (isMyListing)
                                const Text('عقارك', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12))
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: player.cash >= totalPrice ? Colors.amber : Colors.grey, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 30)),
                                  onPressed: player.cash >= totalPrice ? () {
                                    audio.playEffect('click.mp3');
                                    _confirmAction(context, 'استئجار عقار', Wrap(
                                        children: [
                                          Text('هل أنت متأكد أنك تريد استئجار ${prop['name']} بمبلغ إجمالي ', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                          _moneyText(totalPrice, color: Colors.amber, fontSize: 13),
                                          const Text(' كاش؟ (لا يمكن استرداد المبلغ إذا قمت بفسخ العقد)', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                        ]
                                    ), () {
                                      player.rentPropertyFromMarket(listing, prop['happiness']);
                                    });
                                  } : null,
                                  child: const Text('استئجار', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommercialTab(BuildContext context, PlayerProvider player, MarketProvider market, AudioProvider audio) {
    int totalIncome = player.getTotalPassiveIncomePerDay();

    double marketTrend = market.realEstateMultiplier;
    double trendPercent = ((marketTrend - 1.0) * 100).abs();
    bool isCollapsed = marketTrend < 1.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black38,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي الأرباح:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Row(
                    children: [
                      _moneyText(totalIncome, fontSize: 14),
                      const Text(' / يوم', style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('حالة السوق الآن:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(isCollapsed ? 'منهار بنسبة ${trendPercent.toStringAsFixed(1)}% 📉' : 'مرتفع بنسبة ${trendPercent.toStringAsFixed(1)}% 📈', style: TextStyle(color: isCollapsed ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: GameData.businessData.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final biz = GameData.businessData[index];
              final String bizId = biz['id'];
              final int currentLevel = player.ownedBusinesses[bizId] ?? 0;
              final bool isOwned = currentLevel > 0;
              final bool isMax = currentLevel >= biz['maxLevel'];

              final int basePrice = biz['basePrice'];
              final int baseIncome = (GameData.businessBaseIncome[bizId] ?? 0) * 12;

              final int originalCost = isOwned ? (basePrice + (basePrice * currentLevel * 0.25)).toInt() : basePrice;
              final int dynamicCost = (originalCost * marketTrend).toInt();

              final int currentIncome = baseIncome * currentLevel;
              final int nextIncome = baseIncome * (currentLevel + 1);

              return Card(
                color: Colors.black45,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: isOwned ? (biz['color'] as Color).withOpacity(0.5) : Colors.white10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (biz['color'] as Color).withOpacity(0.2),
                        child: Icon(biz['icon'] as IconData, color: biz['color']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(biz['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                if (isOwned) ...[
                                  const SizedBox(width: 4),
                                  Text(isMax ? '(MAX)' : '(مستوى $currentLevel / ${biz['maxLevel']})', style: TextStyle(color: isMax ? Colors.red : Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                ]
                              ],
                            ),
                            Text(biz['description'], style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 4),
                                const Text('الدخل: ', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                                _moneyText(isOwned ? currentIncome : nextIncome),
                                const Text('/يوم', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          if (!isMax) _moneyText(dynamicCost, color: isCollapsed ? Colors.green : Colors.red),
                          const SizedBox(height: 4),
                          isMax ? const Text('مكتمل', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)) : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: player.cash >= dynamicCost ? (isOwned ? Colors.blue : Colors.orange) : Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: const Size(60, 30),
                            ),
                            onPressed: player.cash >= dynamicCost ? () {
                              audio.playEffect('click.mp3');
                              if (isOwned) {
                                _confirmAction(context, 'ترقية المشروع', Wrap(
                                    children: [
                                      Text('هل أنت متأكد من ترقية ${biz['name']} للمستوى ${currentLevel+1} بمبلغ ', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                      _moneyText(dynamicCost, color: Colors.amber, fontSize: 13),
                                      const Text(' كاش؟', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                    ]
                                ), () {
                                  player.upgradeBusiness(bizId, dynamicCost);
                                });
                              } else {
                                _confirmAction(context, 'شراء مشروع', Wrap(
                                    children: [
                                      Text('هل أنت متأكد من شراء مشروع ${biz['name']} بمبلغ ', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                      _moneyText(dynamicCost, color: Colors.amber, fontSize: 13),
                                      const Text(' كاش؟', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                    ]
                                ), () {
                                  player.buyBusiness(bizId, dynamicCost);
                                });
                              }
                            } : null,
                            child: Text(isOwned ? 'ترقية' : 'شراء', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      )
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
}