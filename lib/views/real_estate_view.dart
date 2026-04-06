// المسار: lib/views/real_estate_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class RealEstateView extends StatelessWidget {
  final VoidCallback onBack;

  const RealEstateView({super.key, required this.onBack});

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white), onPressed: onBack),
                  const Expanded(
                    child: Text('سوق العقارات والمشاريع 🏙️', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 48), // لموازنة العنوان
                ],
              ),
            ),
            Container(
              color: Colors.black87,
              child: const TabBar(
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 16),
                tabs: [
                  Tab(text: "عقارات سكنية 🏠", icon: Icon(Icons.holiday_village)),
                  Tab(text: "مشاريع تجارية 🏢", icon: Icon(Icons.monetization_on)),
                ],
              ),
            ),

            // محتوى التبويبات
            Expanded(
              child: TabBarView(
                children: [
                  _buildResidentialTab(player, audio),
                  _buildCommercialTab(player, audio),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 التبويب الأول: العقارات السكنية (نظامك القديم الرهيب) 🟢
  Widget _buildResidentialTab(PlayerProvider player, AudioProvider audio) {
    final List<Map<String, dynamic>> properties = [
      {'id': 'shack', 'name': 'غرفة بسيطة', 'description': 'بداية متواضعة جداً لأي طموح.', 'price': 5000, 'happiness': 2, 'icon': Icons.meeting_room, 'color': Colors.grey},
      {'id': 'tent', 'name': 'خيمة بسيطة', 'description': 'بداية متواضعة، توفر لك الحد الأدنى من السعادة.', 'price': 50000, 'happiness': 5, 'icon': Icons.holiday_village_outlined, 'color': Colors.brown},
      {'id': 'wooden_cabin', 'name': 'كوخ خشبي', 'description': 'كوخ ريفي هادئ بعيداً عن ضجيج المدينة.', 'price': 150000, 'happiness': 10, 'icon': Icons.home_outlined, 'color': Colors.orangeAccent},
      {'id': 'apartment', 'name': 'شقة وسط المدينة', 'description': 'مريحة وعملية لنمط حياة المدن السريع.', 'price': 500000, 'happiness': 20, 'icon': Icons.apartment, 'color': Colors.blueGrey},
      {'id': 'penthouse', 'name': 'بنتهاوس فاخر', 'description': 'شقة في أعلى ناطحة سحاب مع إطلالة خلابة.', 'price': 1500000, 'happiness': 35, 'icon': Icons.location_city, 'color': Colors.indigoAccent},
      {'id': 'villa', 'name': 'فيلا حديثة', 'description': 'منزل واسع مع حديقة ومسابح، تزيد سعادتك بشكل ملحوظ.', 'price': 5000000, 'happiness': 50, 'icon': Icons.villa, 'color': Colors.teal},
      {'id': 'beach_house', 'name': 'منزل شاطئي', 'description': 'استيقظ على صوت الأمواج ومنظر المحيط.', 'price': 12000000, 'happiness': 65, 'icon': Icons.beach_access, 'color': Colors.blue},
      {'id': 'mansion', 'name': 'قصر ملكي', 'description': 'عنوان الفخامة والرقي، سكن العظماء والمشاهير.', 'price': 25000000, 'happiness': 80, 'icon': Icons.castle, 'color': Colors.purpleAccent},
      {'id': 'private_estate', 'name': 'عزبة خاصة', 'description': 'مساحات شاسعة، خيول، وخصوصية تامة.', 'price': 45000000, 'happiness': 90, 'icon': Icons.landscape, 'color': Colors.green},
      {'id': 'island', 'name': 'جزيرة خاصة', 'description': 'جنة على الأرض، أعلى مستويات السعادة والخصوصية.', 'price': 75000000, 'happiness': 100, 'icon': Icons.holiday_village, 'color': Colors.amber},
      {'id': 'space_station', 'name': 'محطة فضائية', 'description': 'العيش خارج حدود الأرض، قمة الترف والمستقبل.', 'price': 250000000, 'happiness': 150, 'icon': Icons.rocket_launch, 'color': Colors.deepPurple},
      {'id': 'mafia_empire', 'name': 'إمبراطورية الزعيم', 'description': 'المقر الرئيسي لأعظم زعيم في السيرفر. قوة، سيطرة، وسعادة لا نهائية!', 'price': 5000000000, 'happiness': 4000, 'icon': Icons.account_balance, 'color': Colors.redAccent},
    ];

    return ListView.builder(
      itemCount: properties.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final prop = properties[index];
        final bool isOwned = player.ownedProperties.contains(prop['id']);
        final bool isActive = player.activePropertyId == prop['id'];

        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: isActive ? Colors.green : (isOwned ? Colors.blue : (prop['color'] as Color).withOpacity(0.3))),
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
                      Text(prop['name'], style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                      Text(prop['description'], style: const TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.sentiment_very_satisfied, color: Colors.yellow, size: 14),
                          Text(' سعادة: ${prop['happiness']}', style: const TextStyle(color: Colors.yellow, fontFamily: 'Changa', fontSize: 12)),
                          if (!isOwned) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.payments, color: Colors.green, size: 14),
                            Text(' ${_formatNumber(prop['price'])}', style: const TextStyle(color: Colors.green, fontFamily: 'Changa', fontSize: 12)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildPropertyAction(player, prop, isOwned, isActive, audio),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyAction(PlayerProvider player, Map<String, dynamic> prop, bool isOwned, bool isActive, AudioProvider audio) {
    if (isActive) {
      return const Text('سكنك الحالي', style: TextStyle(color: Colors.green, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold));
    }
    if (isOwned) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 30)),
        onPressed: () { audio.playEffect('click.mp3'); player.setActiveProperty(prop['id'], prop['happiness']); },
        child: const Text('انتقال', style: TextStyle(fontSize: 12, fontFamily: 'Changa', color: Colors.white)),
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: player.cash >= prop['price'] ? Colors.orange : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(60, 30),
      ),
      onPressed: player.cash >= prop['price'] ? () { audio.playEffect('click.mp3'); player.buyProperty(prop['id'], prop['price'], prop['happiness']); } : null,
      child: const Text('شراء', style: TextStyle(fontSize: 12, fontFamily: 'Changa', fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }

  // 🟢 التبويب الثاني: المشاريع التجارية (الدخل السلبي) 🟢
  Widget _buildCommercialTab(PlayerProvider player, AudioProvider audio) {
    final List<Map<String, dynamic>> businesses = [
      {'id': 'nightclub', 'name': 'ملهى ليلي', 'description': 'مشروع ترفيهي ممتاز لغسيل أموالك وكسب دخل ثابت.', 'basePrice': 250000, 'baseIncome': 250, 'icon': Icons.nightlife, 'color': Colors.purpleAccent},
      {'id': 'weapons_factory', 'name': 'مصنع أسلحة', 'description': 'تصنيع وتوريد للمجرمين، أرباح خيالية وخطورة عالية.', 'basePrice': 1500000, 'baseIncome': 1200, 'icon': Icons.precision_manufacturing, 'color': Colors.grey},
      {'id': 'money_laundering', 'name': 'شركة واجهة', 'description': 'شركة استيراد وتصدير كواجهة مثالية لأعمالك المشبوهة.', 'basePrice': 7500000, 'baseIncome': 5000, 'icon': Icons.local_shipping, 'color': Colors.blueAccent},
      {'id': 'casino', 'name': 'كازينو المدينة', 'description': 'منجم ذهب حرفياً، يسحب أموال الناس لجيوبك بصمت.', 'basePrice': 40000000, 'baseIncome': 25000, 'icon': Icons.casino, 'color': Colors.amber},
    ];

    int totalIncome = player.getTotalPassiveIncomePerMinute();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.green.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text('إجمالي الأرباح التلقائية: \$${_formatNumber(totalIncome)} / دقيقة', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: businesses.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final biz = businesses[index];
              final String bizId = biz['id'];
              final int currentLevel = player.ownedBusinesses[bizId] ?? 0;
              final bool isOwned = currentLevel > 0;

              final int basePrice = biz['basePrice'];
              final int baseIncome = biz['baseIncome'];

              // تكلفة الترقية: السعر الأساسي * المستوى الحالي * 1.5
              final int upgradeCost = isOwned ? (basePrice * currentLevel * 1.5).toInt() : basePrice;
              final int currentIncome = baseIncome * currentLevel;
              final int nextIncome = baseIncome * (currentLevel + 1);

              return Card(
                color: Colors.black45,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: isOwned ? (biz['color'] as Color).withOpacity(0.8) : Colors.white10, width: isOwned ? 2 : 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: (biz['color'] as Color).withOpacity(0.2), shape: BoxShape.circle),
                            child: Icon(biz['icon'] as IconData, color: biz['color'], size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(biz['name'], style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 16)),
                                    if (isOwned) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)), child: Text('مستوى $currentLevel', style: const TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 11, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                Text(biz['description'], style: const TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isOwned ? 'أرباحك الحالية:' : 'أرباح المستوى 1:', style: const TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 11)),
                                Text('\$${_formatNumber(isOwned ? currentIncome : nextIncome)} / دقيقة', style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: player.cash >= upgradeCost ? (isOwned ? Colors.blueAccent : Colors.orange) : Colors.grey,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              onPressed: player.cash >= upgradeCost ? () {
                                audio.playEffect('click.mp3');
                                if (isOwned) {
                                  player.upgradeBusiness(bizId, upgradeCost);
                                } else {
                                  player.buyBusiness(bizId, upgradeCost);
                                }
                              } : null,
                              icon: Icon(isOwned ? Icons.upgrade : Icons.shopping_cart, color: Colors.white, size: 16),
                              label: Text(
                                isOwned ? 'ترقية (\$${_formatNumber(upgradeCost)})' : 'شراء (\$${_formatNumber(upgradeCost)})',
                                style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
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
}