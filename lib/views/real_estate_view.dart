// المسار: lib/views/real_estate_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/market_provider.dart';
import '../utils/game_data.dart';
import 'player_profile_view.dart';
import '../controllers/real_estate_cubit.dart';

class RealEstateView extends StatefulWidget {
  final VoidCallback onBack;

  const RealEstateView({super.key, required this.onBack});

  @override
  State<RealEstateView> createState() => _RealEstateViewState();
}

class _RealEstateViewState extends State<RealEstateView> {
  String _currentFilter = 'date';
  int _marketTab = 0;

  final Map<String, bool> _filterAscending = {
    'date': false,
    'happy': false,
    'price': false,
  };

  Stream<QuerySnapshot>? _generalMarketStream;
  Stream<QuerySnapshot>? _myListingsStream;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب مجهول', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, body: SafeArea(child: PlayerProfileView(targetUid: uid, onBack: () => Navigator.pop(context))))));
  }

  void _confirmAction(BuildContext context, String title, Widget contentWidget, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
          title: Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          content: contentWidget,
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () { Navigator.pop(context); onConfirm(); },
              child: const Text('تأكيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
          title: const Text('شرح العقارات (تحديث المافيا) ℹ️', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏠 عقارات سكنية:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('تزيد من نسبة السعادة اللي تضاعف تدريبك بالنادي. نظام الكميات يسمح لك بامتلاك 5 نسخ من العقار، لتسكن في واحد وتأجر الباقي.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
                SizedBox(height: 10),
                Text('⭐ الصيانة والتهالك:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('المبنى يتهالك يومياً بنسبة 15%. إذا وصل 0% وكان مؤجراً، سيقوم المستأجر بالاستيلاء عليه!', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
                SizedBox(height: 10),
                Text('🤝 سوق الإيجارات:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                Text('تقدر تستأجر عقار من لاعب ثاني لفترة محددة. إذا فسخت العقد قبل وقته (الفلوس ما ترجع!).', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً فهمت', style: TextStyle(color: Colors.amber)))],
        ),
      ),
    );
  }

  // 🟢 نافذة التفاصيل الشاملة (Bottom Sheet) 🟢
  void _showPropertyDetailsBottomSheet(BuildContext context, Map<String, dynamic> prop, RealEstateCubit cubit, AudioProvider audio) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final String propId = prop['id'];
                int ownedCount = player.ownedPropertyCounts[propId] ?? (player.ownedProperties.contains(propId) ? 1 : 0);
                bool isOwned = ownedCount > 0;

                int listedCount = player.listedProperties.where((l) => l == propId || l.contains('_${propId}_')).length;
                int rentedOutCount = player.rentedOutProperties.values.where((v) => v['propertyId'] == propId || player.rentedOutProperties.keys.contains(propId)).length;

                bool isListed = listedCount > 0;
                bool isRentedOut = rentedOutCount > 0;
                bool isActive = player.activePropertyId == propId;
                bool isActiveRented = player.activeRentedProperty != null && player.activeRentedProperty!['id'] == propId;

                int usedCount = (isActive ? 1 : 0) + listedCount + rentedOutCount;
                int availableCount = ownedCount - usedCount;
                bool canLive = availableCount > 0 && !isActive;
                bool canRentOut = availableCount > 0;

                double currentCond = player.propertyConditions[propId] ?? 100.0;
                Color condColor = currentCond > 70 ? Colors.green : (currentCond > 30 ? Colors.orange : Colors.red);
                int maintCost = (prop['price'] * 0.02).toInt();
                List<String> currentUps = player.propertyUpgrades[propId] ?? [];

                return Container(
                  height: MediaQuery.of(context).size.height * 0.75, // ياخذ 75% من الشاشة عشان يعرض كل التفاصيل
                  decoration: const BoxDecoration(
                    color: Color(0xFF151515),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                    border: Border(top: BorderSide(color: Colors.amber, width: 2)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: Text('معلومات ${prop['name']}', style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa'))),
                          const Divider(color: Colors.white24, height: 30),

                          // 🟢 1. حالة المبنى والصيانة 🟢
                          if (isOwned) ...[
                            const Text('حالة العقار والصيانة 🛠️', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text('مستوى التهالك: ${currentCond.toStringAsFixed(0)}%', style: TextStyle(color: condColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Expanded(child: LinearProgressIndicator(value: currentCond / 100, backgroundColor: Colors.white10, color: condColor, minHeight: 6)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (currentCond < 100.0)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.build, size: 16, color: Colors.white),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, minimumSize: const Size(double.infinity, 40)),
                                onPressed: () {
                                  audio.playEffect('click.mp3');
                                  _confirmAction(context, 'صيانة المبنى', Wrap(
                                    children: [
                                      const Text('إعادة العقار لحالته الأصلية ستكلفك ', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                      _moneyText(maintCost, color: Colors.amber, fontSize: 13),
                                    ],
                                  ), () {
                                    cubit.executeAction(() => player.maintainProperty(propId, maintCost), 'تمت الصيانة بنجاح!');
                                  });
                                },
                                label: const Text('إجراء صيانة كاملة', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            const Divider(color: Colors.white24, height: 30),
                          ],

                          // 🟢 2. إدارة العقار (سكن / تأجير / عرض) 🟢
                          const Text('إدارة العقار والاستخدام 🔑', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          const SizedBox(height: 10),

                          if (isActiveRented) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🏠 هذا هو سكنك المؤجر الحالي', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text('المالك: ${player.activeRentedProperty!['ownerName'] ?? 'لاعب'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('ينتهي العقد: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(player.activeRentedProperty!['expire']))}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 10),
                                  FutureBuilder<double>(
                                      future: player.getOwnerPropertyCondition(player.activeRentedProperty!['ownerId'], propId),
                                      builder: (context, snapshot) {
                                        double ownerCond = snapshot.data ?? 100.0;
                                        if (ownerCond <= 0.0) {
                                          return ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 40)),
                                            onPressed: () {
                                              audio.playEffect('click.mp3');
                                              _confirmAction(context, 'وضع اليد 🏴‍☠️', const Text('هل تريد دفع 50,000 كاش لتسجيل هذا العقار المتهالك باسمك؟', style: TextStyle(color: Colors.white, fontFamily: 'Changa')), () {
                                                cubit.executeAction(() => player.takeoverProperty(), 'تمت عملية الاستيلاء بنجاح!');
                                              });
                                            },
                                            child: const Text('الاستيلاء على العقار (وضع اليد)!', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                                          );
                                        }
                                        return ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 40)),
                                          onPressed: () {
                                            audio.playEffect('click.mp3');
                                            _confirmAction(context, 'فسخ العقد ⚠️', const Text('هل أنت متأكد أنك تريد الخروج من العقار ولن تسترد المبلغ؟', style: TextStyle(color: Colors.white, fontFamily: 'Changa')), () {
                                              cubit.executeAction(() => player.cancelRentedProperty(), 'تم فسخ العقد');
                                            });
                                          },
                                          child: const Text('فسخ العقد والخروج', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                                        );
                                      }
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (isActive) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(10)),
                              child: const Text('👑 أنت تسكن حالياً في إحدى نسخ هذا العقار، وتستفيد من سعادته الكاملة لتدريباتك.', style: TextStyle(color: Colors.amber, fontSize: 12)),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (canLive)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.home, color: Colors.white),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 40)),
                              onPressed: () {
                                audio.playEffect('click.mp3');
                                _confirmAction(context, 'الانتقال للعقار', Text('هل تريد الانتقال للسكن هنا والحصول على السعادة؟', style: const TextStyle(color: Colors.white, fontFamily: 'Changa')), () {
                                  cubit.executeAction(() => player.setActiveProperty(propId, prop['happiness']), 'تم الانتقال للسكن الجديد بنجاح!');
                                  Navigator.pop(context); // إغلاق النافذة بعد الانتقال
                                });
                              },
                              label: const Text('الانتقال للسكن في العقار', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),

                          if (canRentOut)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.monetization_on, color: Colors.black),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 40)),
                                onPressed: () {
                                  audio.playEffect('click.mp3');
                                  Navigator.pop(context); // أغلق النافذة الحالية
                                  _showRentDialog(context, player, prop, cubit); // افتح نافذة الإيجار
                                },
                                label: const Text('عرض نسخة للإيجار في السوق', style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),

                          if (isListed)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.cancel, color: Colors.white),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 40)),
                                onPressed: () {
                                  audio.playEffect('click.mp3');
                                  _confirmAction(context, 'سحب العقار', const Text('هل أنت متأكد من سحب إعلانك من السوق؟', style: TextStyle(color: Colors.white, fontFamily: 'Changa')), () {
                                    cubit.executeAction(() => player.cancelRentalListing(propId), 'تم سحب العقار بنجاح!');
                                  });
                                },
                                label: const Text('سحب عقار معروض من السوق', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),

                          if (!isOwned && !isActiveRented)
                            const Text('أنت لا تملك هذا العقار حتى الآن. قم بشرائه من الواجهة الرئيسية لفتحه.', style: TextStyle(color: Colors.white54, fontSize: 12)),

                          const Divider(color: Colors.white24, height: 30),

                          // 🟢 3. الترقيات 🟢
                          if (isOwned) ...[
                            const Text('الترقيات والتحسينات ⭐', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                            const SizedBox(height: 10),
                            ...GameData.propertyUpgradesData.entries.map((entry) {
                              String upId = entry.key;
                              var upData = entry.value;
                              int cost = (prop['price'] * upData['priceMultiplier']).toInt();
                              bool isBought = currentUps.contains(upId);

                              return Card(
                                color: Colors.black45,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isBought ? Colors.green : Colors.white10)),
                                child: ListTile(
                                  leading: CircleAvatar(backgroundColor: Colors.amber.withOpacity(0.2), child: Icon(upData['icon'], color: Colors.amber)),
                                  title: Text(upData['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Changa')),
                                  subtitle: Text(upData['desc'], style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Changa')),
                                  trailing: isBought
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: player.cash >= cost ? Colors.orange : Colors.grey, minimumSize: const Size(60, 30)),
                                    onPressed: player.cash >= cost ? () {
                                      audio.playEffect('click.mp3');
                                      _confirmAction(context, 'شراء ${upData['name']}', Wrap(
                                        children: [
                                          const Text('هل أنت متأكد من الشراء بمبلغ ', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                          _moneyText(cost, color: Colors.amber, fontSize: 13),
                                        ],
                                      ), () {
                                        cubit.executeAction(() => player.buyPropertyUpgrade(prop['id'], upId, cost), 'تم الترقية بنجاح!');
                                      });
                                    } : null,
                                    child: _moneyText(cost, color: Colors.black),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  String _getFilterLabel(String code) {
    bool isAsc = _filterAscending[code] ?? false;
    if (code == 'date') return isAsc ? 'الأقدم' : 'الأحدث';
    if (code == 'happy') return isAsc ? 'السعادة الأقل' : 'السعادة الأعلى';
    if (code == 'price') return isAsc ? 'السعر الأقل' : 'السعر الأعلى';
    return '';
  }

  Widget _filterChip(String code) {
    bool isSel = _currentFilter == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_currentFilter == code) {
            _filterAscending[code] = !(_filterAscending[code]!);
          } else {
            _currentFilter = code;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isSel ? Colors.amber : Colors.transparent, border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(20)),
        child: Text(
            _getFilterLabel(code),
            style: TextStyle(color: isSel ? Colors.black : Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  // 🟢 دالة عرض البانر 21:9 بشكل مثالي 🟢
  Widget _buildPropertyImage(Map<String, dynamic> prop) {
    return AspectRatio(
      aspectRatio: 21 / 9, // النسبة المثالية لصور الميدجيرني العريضة
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/properties/${prop['id']}.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: (prop['color'] as Color).withOpacity(0.2),
                child: Center(
                  child: Icon(prop['icon'] as IconData, color: prop['color'], size: 45),
                ),
              );
            },
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 40,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final market = Provider.of<MarketProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    _generalMarketStream ??= FirebaseFirestore.instance.collection('property_rentals').snapshots();
    if (player.uid != null) {
      _myListingsStream ??= FirebaseFirestore.instance.collection('property_rentals').where('ownerId', isEqualTo: player.uid).snapshots();
    }

    return BlocProvider(
      create: (context) => RealEstateCubit(),
      child: BlocConsumer<RealEstateCubit, RealEstateState>(
        listener: (context, state) {
          if (state.errorMessage.isNotEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage, style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent)); }
          if (state.successMessage.isNotEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green)); }
        },
        builder: (context, state) {
          final cubit = context.read<RealEstateCubit>();

          return Stack(
            children: [
              Scaffold(
                backgroundColor: const Color(0xFF1A1A1D),
                body: SafeArea(
                  bottom: false,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        const Center(child: Text('إمبراطورية العقارات 🏙️', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 5),

                        Expanded(
                          child: DefaultTabController(
                            length: 3,
                            child: Column(
                              children: [
                                const TabBar(
                                  indicatorColor: Colors.amber, labelColor: Colors.amber, unselectedLabelColor: Colors.white54,
                                  tabs: [Tab(text: "عقاراتي"), Tab(text: "سوق الإيجارات"), Tab(text: "مشاريع تجارية")],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      _buildResidentialTab(context, player, audio, cubit),
                                      _buildRentalMarketTab(context, player, audio, cubit),
                                      _buildCommercialTab(context, player, market, audio, cubit),
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
                      image: const DecorationImage(image: AssetImage('assets/images/ui/bottom_navbar_bg.png'), fit: BoxFit.cover),
                      border: const Border(top: BorderSide(color: Color(0xFF856024), width: 2)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    padding: const EdgeInsets.only(top: 8, bottom: 20, left: 25, right: 25),
                    child: SafeArea(
                      bottom: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () { audio.playEffect('click.mp3'); widget.onBack(); },
                            behavior: HitTestBehavior.opaque,
                            child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_forward_ios, color: Color(0xFFE2C275), size: 24), SizedBox(height: 4), Text('رجوع', style: TextStyle(color: Color(0xFFE2C275), fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                          ),
                          GestureDetector(
                            onTap: () { audio.playEffect('click.mp3'); _showExplanationDialog(context); },
                            behavior: HitTestBehavior.opaque,
                            child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book, color: Colors.white70, size: 24), SizedBox(height: 4), Text('شرح', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (state.isLoading)
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 15),
                        Text('جاري التنفيذ... 📝', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // 🟢 بناء الكرت النظيف (عقاراتي) 🟢
  Widget _buildResidentialTab(BuildContext context, PlayerProvider player, AudioProvider audio, RealEstateCubit cubit) {
    return ListView.builder(
      itemCount: GameData.residentialProperties.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final prop = GameData.residentialProperties[index];
        final String propId = prop['id'];

        int ownedCount = player.ownedPropertyCounts[propId] ?? (player.ownedProperties.contains(propId) ? 1 : 0);
        bool isOwned = ownedCount > 0;
        bool canBuy = ownedCount < 5;

        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: isOwned ? Colors.blue : (prop['color'] as Color).withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyImage(prop),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(prop['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                        _moneyText(prop['price'], fontSize: 14, color: Colors.greenAccent),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(prop['description'], style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)), // النص أخذ راحته
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.sentiment_very_satisfied, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text('سعادة: ${prop['happiness']}', style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (isOwned) Text('الكمية: $ownedCount/5', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.shopping_cart, size: 16, color: Colors.black),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: player.cash >= prop['price'] && canBuy ? Colors.orange : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: player.cash >= prop['price'] && canBuy ? () {
                              audio.playEffect('click.mp3');
                              _confirmAction(context, 'شراء العقار', Wrap(
                                children: [
                                  Text('هل أنت متأكد من شراء نسخة من ${prop['name']} بمبلغ ', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                  _moneyText(prop['price'], color: Colors.amber, fontSize: 13),
                                  const Text(' كاش؟', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                ],
                              ), () {
                                cubit.executeAction(() => player.buyProperty(propId, prop['price'], prop['happiness']), 'مبروك! تم الشراء بنجاح 🏠');
                              });
                            } : null,
                            label: Text(isOwned ? 'شراء المزيد' : 'شراء العقار', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Changa')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.info_outline, size: 16, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              audio.playEffect('click.mp3');
                              _showPropertyDetailsBottomSheet(context, prop, cubit, audio);
                            },
                            label: const Text('معلومات العقار', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRentDialog(BuildContext context, PlayerProvider player, Map<String, dynamic> prop, RealEstateCubit cubit) {
    int dailyPrice = 50000;
    int rentDays = 7;

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setState) {
                int totalPrice = dailyPrice * rentDays;

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
                    title: Text('تأجير ${prop['name']} 🔑', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('تذكر إجراء الصيانة قبل التأجير، إذا تهالك المبنى 0% يمكن للمستأجر الاستيلاء عليه!', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                          const SizedBox(height: 20),
                          const Text('سعر الإيجار اليومي (كاش):', style: TextStyle(color: Colors.white, fontSize: 14)),
                          TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.greenAccent),
                            decoration: const InputDecoration(hintText: 'مثال: 50000', hintStyle: TextStyle(color: Colors.white24)),
                            onChanged: (val) { setState(() { dailyPrice = int.tryParse(val) ?? 0; }); },
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
                              cubit.executeAction(() => player.listPropertyForRent(prop['id'], dailyPrice, rentDays), 'تم نشر العقار في سوق الإيجارات بنجاح!');
                            });
                          }
                        },
                        child: const Text('نشر في السوق', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  Widget _buildRentalMarketTab(BuildContext context, PlayerProvider player, AudioProvider audio, RealEstateCubit cubit) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () { audio.playEffect('click.mp3'); setState(() => _marketTab = 0); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: _marketTab == 0 ? Colors.amber : Colors.black45, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
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
                    decoration: BoxDecoration(color: _marketTab == 1 ? Colors.amber : Colors.black45, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
                    child: Center(child: Text("إعلاناتي", style: TextStyle(color: _marketTab == 1 ? Colors.black : Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa'))),
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _filterChip('date'),
              _filterChip('happy'),
              _filterChip('price'),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _marketTab == 1 ? _myListingsStream : _generalMarketStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));

              if (snapshot.hasError) {
                return Center(child: Text("يوجد خطأ في الصلاحيات: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent, fontFamily: 'Changa')));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text(_marketTab == 0 ? "لا توجد عقارات معروضة للإيجار حالياً." : "ليس لديك أي إعلانات في السوق.", style: const TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'Changa')));
              }

              var docs = snapshot.data!.docs.map((d) {
                var map = Map<String, dynamic>.from(d.data() as Map<String, dynamic>);
                map['docId'] = d.id;
                return map;
              }).toList();

              if (_marketTab == 0) {
                docs = docs.where((d) => d['ownerId'] != player.uid).toList();
              }

              if (docs.isEmpty) {
                return Center(child: Text(_marketTab == 0 ? "السوق فارغ حالياً." : "ليس لديك أي إعلانات في السوق.", style: const TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'Changa')));
              }

              bool isAsc = _filterAscending[_currentFilter] ?? false;

              if (_currentFilter == 'date') {
                docs.sort((a, b) {
                  Timestamp tA = a['timestamp'] is Timestamp ? a['timestamp'] : Timestamp.now();
                  Timestamp tB = b['timestamp'] is Timestamp ? b['timestamp'] : Timestamp.now();
                  return isAsc ? tA.compareTo(tB) : tB.compareTo(tA);
                });
              } else if (_currentFilter == 'happy') {
                docs.sort((a, b) {
                  int hA = GameData.residentialProperties.firstWhere((p) => p['id'] == a['propertyId'], orElse: () => {'happiness': 0})['happiness'];
                  int hB = GameData.residentialProperties.firstWhere((p) => p['id'] == b['propertyId'], orElse: () => {'happiness': 0})['happiness'];
                  return isAsc ? hA.compareTo(hB) : hB.compareTo(hA);
                });
              } else if (_currentFilter == 'price') {
                docs.sort((a, b) {
                  int pA = (a['dailyPrice'] as num?)?.toInt() ?? 0;
                  int pB = (b['dailyPrice'] as num?)?.toInt() ?? 0;
                  return isAsc ? pA.compareTo(pB) : pB.compareTo(pA);
                });
              }

              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final listing = docs[index];
                  final prop = GameData.residentialProperties.firstWhere((p) => p['id'] == listing['propertyId'], orElse: () => GameData.residentialProperties[0]);

                  int dailyPrice = (listing['dailyPrice'] as num?)?.toInt() ?? 0;
                  int days = (listing['days'] as num?)?.toInt() ?? 0;
                  int totalPrice = dailyPrice * days;

                  bool isMyListing = listing['ownerId'] == player.uid;

                  return Card(
                    color: Colors.black45,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1.5)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPropertyImage(prop),

                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(prop['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        if (isMyListing)
                                          const Text('المالك: أنت 👑', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold))
                                        else
                                          FutureBuilder<Map<String, dynamic>?>(
                                              future: player.getPlayerById(listing['ownerId']),
                                              builder: (context, snapshot) {
                                                String? picUrl = snapshot.data?['profilePicUrl'];
                                                var imageBytes = player.getDecodedImage(picUrl);

                                                return GestureDetector(
                                                  onTap: () => _openProfile(context, listing['ownerId']),
                                                  child: Row(
                                                    children: [
                                                      Text('المالك: ${listing['ownerName']}', style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                                      const SizedBox(width: 4),
                                                      CircleAvatar(
                                                        radius: 9,
                                                        backgroundColor: Colors.grey[800],
                                                        backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                                                        child: imageBytes == null ? const Icon(Icons.person, size: 12, color: Colors.white54) : null,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('سعادة: +${prop['happiness']}', style: const TextStyle(color: Colors.yellow, fontSize: 11)),
                                    Row(
                                      children: [
                                        const Text('الإيجار اليومي: ', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                                        _moneyText(dailyPrice),
                                      ],
                                    ),
                                    Text('المدة: $days أيام', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text('الإجمالي', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                  _moneyText(totalPrice, fontSize: 12),
                                  const SizedBox(height: 4),
                                  if (isMyListing)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 30)),
                                      onPressed: () {
                                        audio.playEffect('click.mp3');
                                        _confirmAction(context, 'سحب الإعلان', const Text('هل متأكد أنك تريد سحب العقار من السوق؟', style: TextStyle(color: Colors.white)), () {
                                          cubit.executeAction(() => player.cancelRentalListing(prop['id']), 'تم سحب العقار من السوق بنجاح!');
                                        });
                                      },
                                      child: const Text('سحب الإعلان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                    )
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
                                          cubit.executeAction(() => player.rentPropertyFromMarket(listing, prop['happiness']), 'تم توثيق عقد الإيجار بنجاح 🤝');
                                        });
                                      } : null,
                                      child: const Text('استئجار', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildCommercialTab(BuildContext context, PlayerProvider player, MarketProvider market, AudioProvider audio, RealEstateCubit cubit) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final biz = GameData.businessData[index];

              final String bizId = biz['id'] ?? '';
              final int currentLevel = player.ownedBusinesses[bizId] ?? 0;
              final bool isOwned = currentLevel > 0;
              final int maxLevel = (biz['maxLevel'] as num?)?.toInt() ?? 10;
              final bool isMax = currentLevel >= maxLevel;

              final int basePrice = (biz['basePrice'] as num?)?.toInt() ?? 10000;
              final int baseIncome = (GameData.businessBaseIncome[bizId] ?? 0) * 12;

              final int originalCost = isOwned ? (basePrice + (basePrice * currentLevel * 0.25)).toInt() : basePrice;
              final int dynamicCost = (originalCost * marketTrend).toInt();

              final int currentIncome = baseIncome * currentLevel;
              final int nextIncome = baseIncome * (currentLevel + 1);

              final Color bizColor = biz['color'] as Color? ?? Colors.grey;
              final IconData bizIcon = biz['icon'] as IconData? ?? Icons.business;

              return Card(
                color: Colors.black45,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: isOwned ? bizColor.withOpacity(0.5) : Colors.white10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: bizColor.withOpacity(0.2),
                        child: Icon(bizIcon, color: bizColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(biz['name'] ?? 'مشروع', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                if (isOwned) ...[
                                  const SizedBox(width: 4),
                                  Text(isMax ? '(MAX)' : '(مستوى $currentLevel / $maxLevel)', style: TextStyle(color: isMax ? Colors.red : Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                ]
                              ],
                            ),
                            Text(biz['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (!isMax) _moneyText(dynamicCost, color: isCollapsed ? Colors.green : Colors.red),
                          const SizedBox(height: 4),
                          isMax ? const Text('مكتمل', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)) : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: player.cash >= dynamicCost ? (isOwned ? Colors.blue : Colors.orange) : Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: const Size(60, 25),
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
                                  cubit.executeAction(() => player.upgradeBusiness(bizId, dynamicCost), 'تم ترقية المشروع بنجاح! 📈');
                                });
                              } else {
                                _confirmAction(context, 'شراء مشروع', Wrap(
                                    children: [
                                      Text('هل أنت متأكد من شراء مشروع ${biz['name']} بمبلغ ', style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                      _moneyText(dynamicCost, color: Colors.amber, fontSize: 13),
                                      const Text(' كاش؟', style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Changa')),
                                    ]
                                ), () {
                                  cubit.executeAction(() => player.buyBusiness(bizId, dynamicCost), 'تم شراء المشروع التجاري بنجاح! 🏢');
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