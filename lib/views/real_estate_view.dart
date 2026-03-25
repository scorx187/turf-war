import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class RealEstateView extends StatelessWidget {
  final VoidCallback onBack;

  const RealEstateView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    final List<Map<String, dynamic>> properties = [
      {
        'id': 'shack',
        'name': 'غرفة بسيطة',
        'description': 'بداية متواضعة جداً لأي طموح.',
        'price': 5000,
        'happiness': 2,
        'icon': Icons.meeting_room, 
        'color': Colors.grey,
      },
      {
        'id': 'tent',
        'name': 'خيمة بسيطة',
        'description': 'بداية متواضعة، توفر لك الحد الأدنى من السعادة.',
        'price': 50000,
        'happiness': 5,
        'icon': Icons.holiday_village_outlined, 
        'color': Colors.brown,
      },
      {
        'id': 'wooden_cabin',
        'name': 'كوخ خشبي',
        'description': 'كوخ ريفي هادئ بعيداً عن ضجيج المدينة.',
        'price': 150000,
        'happiness': 10,
        'icon': Icons.home_outlined,
        'color': Colors.orangeAccent,
      },
      {
        'id': 'apartment',
        'name': 'شقة وسط المدينة',
        'description': 'مريحة وعملية لنمط حياة المدن السريع.',
        'price': 500000,
        'happiness': 20,
        'icon': Icons.apartment,
        'color': Colors.blueGrey,
      },
      {
        'id': 'penthouse',
        'name': 'بنتهاوس فاخر',
        'description': 'شقة في أعلى ناطحة سحاب مع إطلالة خلابة.',
        'price': 1500000,
        'happiness': 35,
        'icon': Icons.location_city,
        'color': Colors.indigoAccent,
      },
      {
        'id': 'villa',
        'name': 'فيلا حديثة',
        'description': 'منزل واسع مع حديقة ومسابح، تزيد سعادتك بشكل ملحوظ.',
        'price': 5000000,
        'happiness': 50,
        'icon': Icons.villa,
        'color': Colors.teal,
      },
      {
        'id': 'beach_house',
        'name': 'منزل شاطئي',
        'description': 'استيقظ على صوت الأمواج ومنظر المحيط.',
        'price': 12000000,
        'happiness': 65,
        'icon': Icons.beach_access,
        'color': Colors.blue,
      },
      {
        'id': 'mansion',
        'name': 'قصر ملكي',
        'description': 'عنوان الفخامة والرقي، سكن العظماء والمشاهير.',
        'price': 25000000,
        'happiness': 80,
        'icon': Icons.castle,
        'color': Colors.purpleAccent,
      },
      {
        'id': 'private_estate',
        'name': 'عزبة خاصة',
        'description': 'مساحات شاسعة، خيول، وخصوصية تامة.',
        'price': 45000000,
        'happiness': 90,
        'icon': Icons.landscape,
        'color': Colors.green,
      },
      {
        'id': 'island',
        'name': 'جزيرة خاصة',
        'description': 'جنة على الأرض، أعلى مستويات السعادة والخصوصية.',
        'price': 75000000,
        'happiness': 100,
        'icon': Icons.holiday_village,
        'color': Colors.amber,
      },
      {
        'id': 'space_station',
        'name': 'محطة فضائية',
        'description': 'العيش خارج حدود الأرض، قمة الترف والمستقبل.',
        'price': 250000000,
        'happiness': 150,
        'icon': Icons.rocket_launch,
        'color': Colors.deepPurple,
      },
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
              const Text('سوق العقارات 🏠', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
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
                  side: BorderSide(color: isActive ? Colors.green : (isOwned ? Colors.blue : (prop['color'] as Color).withValues(alpha:0.3))),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (prop['color'] as Color).withValues(alpha:0.2),
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
                                Text(' سعادة: ${prop['happiness']}%', style: const TextStyle(color: Colors.yellow, fontSize: 11)),
                                if (!isOwned) ...[
                                  const SizedBox(width: 10),
                                  const Icon(Icons.payments, color: Colors.green, size: 14),
                                  Text(' ${prop['price']}', style: const TextStyle(color: Colors.green, fontSize: 11)),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPropertyAction(player, prop, isOwned, isActive),
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

  Widget _buildPropertyAction(PlayerProvider player, Map<String, dynamic> prop, bool isOwned, bool isActive) {
    if (isActive) {
      return const Text('سكنك الحالي', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold));
    }
    
    if (isOwned) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 30)),
        onPressed: () => player.setActiveProperty(prop['id'], prop['happiness']),
        child: const Text('انتقال', style: TextStyle(fontSize: 10)),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: player.cash >= prop['price'] ? Colors.orange : Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(60, 30),
      ),
      onPressed: player.cash >= prop['price'] ? () => player.buyProperty(prop['id'], prop['price'], prop['happiness']) : null,
      child: const Text('شراء', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
