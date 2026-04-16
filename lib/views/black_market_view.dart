// المسار: lib/views/black_market_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart'; // 🟢 استدعاء البلوك
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../utils/game_data.dart';
import '../controllers/black_market_cubit.dart'; // 🟢 استدعاء الكيوبت

class BlackMarketView extends StatefulWidget {
  final VoidCallback onBack;

  const BlackMarketView({super.key, required this.onBack});

  @override
  State<BlackMarketView> createState() => _BlackMarketViewState();
}

class _BlackMarketViewState extends State<BlackMarketView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _activeGroupName;
  List<Map<String, dynamic>>? _activeGroupItems;
  Color _activeGroupColor = Colors.redAccent;
  IconData _activeGroupIcon = Icons.list;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _activeGroupName != null) {
        setState(() {
          _activeGroupName = null;
          _activeGroupItems = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openGroup(String name, List<Map<String, dynamic>> items, Color color, IconData icon) {
    setState(() {
      _activeGroupName = name;
      _activeGroupItems = items;
      _activeGroupColor = color;
      _activeGroupIcon = icon;
    });
  }

  void _handleBack() {
    if (_activeGroupName != null) {
      setState(() {
        _activeGroupName = null;
        _activeGroupItems = null;
      });
    } else {
      widget.onBack();
    }
  }

  List<Map<String, dynamic>> _generateEquipment(PlayerProvider player) {
    List<Map<String, dynamic>> equipment = [];
    final rarities = [
      {'id': 'silver', 'name': 'فضي', 'color': Colors.blueGrey, 'price': 5000, 'curr': 'cash'},
      {'id': 'green', 'name': 'أخضر', 'color': Colors.green, 'price': 25000, 'curr': 'cash'},
      {'id': 'blue', 'name': 'أزرق', 'color': Colors.blue, 'price': 100000, 'curr': 'cash'},
      {'id': 'purple', 'name': 'بنفسجي', 'color': Colors.deepPurple, 'price': 500000, 'curr': 'cash'},
      {'id': 'gold', 'name': 'ذهبي', 'color': Colors.amber, 'price': 2000, 'curr': 'gold'},
      {'id': 'red', 'name': 'أحمر', 'color': Colors.redAccent, 'price': 10000, 'curr': 'gold'},
    ];

    final weaponTypes = [
      {'id': 'heavy', 'name': 'مدفع', 'icon': Icons.hardware},
      {'id': 'assault', 'name': 'رشاش', 'icon': Icons.security},
      {'id': 'balanced', 'name': 'بندقية', 'icon': Icons.sync_alt},
      {'id': 'tactical', 'name': 'قناصة', 'icon': Icons.track_changes},
      {'id': 'agile', 'name': 'خنجر', 'icon': Icons.flash_on},
    ];

    final armorTypes = [
      {'id': 'heavy', 'name': 'درع طليعة', 'icon': Icons.shield},
      {'id': 'assault', 'name': 'سترة هجومية', 'icon': Icons.security_update_good},
      {'id': 'balanced', 'name': 'بدلة قتال', 'icon': Icons.accessibility_new},
      {'id': 'tactical', 'name': 'عتاد تكتيكي', 'icon': Icons.directions_run},
      {'id': 'agile', 'name': 'زي تسلل', 'icon': Icons.speed},
    ];

    for (var r in rarities) {
      for (var w in weaponTypes) {
        String itemId = 'w_${r['id']}_${w['id']}';
        int strVal = ((GameData.weaponStats[itemId]?['str'] ?? 0.0) * 100).toInt();
        int spdVal = ((GameData.weaponStats[itemId]?['spd'] ?? 0.0) * 100).toInt();
        equipment.add({'id': itemId, 'name': '${w['name']} ${r['name']}', 'description': 'قوة: +$strVal%\nسرعة: +$spdVal%', 'price': r['price'], 'currency': r['curr'], 'icon': w['icon'], 'color': r['color'], 'type': 'weapon', 'isConsumable': false});
      }
      for (var a in armorTypes) {
        String itemId = 'a_${r['id']}_${a['id']}';
        int defVal = ((GameData.armorStats[itemId]?['def'] ?? 0.0) * 100).toInt();
        int sklVal = ((GameData.armorStats[itemId]?['skl'] ?? 0.0) * 100).toInt();
        equipment.add({'id': itemId, 'name': '${a['name']} ${r['name']}', 'description': 'دفاع: +$defVal%\nمهارة: +$sklVal%', 'price': r['price'], 'currency': r['curr'], 'icon': a['icon'], 'color': r['color'], 'type': 'armor', 'isConsumable': false});
      }
    }
    return equipment;
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.redAccent)),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.amber),
              SizedBox(width: 10),
              Text('شرح المتجر الأسود', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'المتجر الأسود هو الملاذ السري لزعماء المافيا لشراء أقوى العتاد والأسلحة:\n\n'
                  '🗡️ الأسلحة والدروع: مقسمة لمجموعات لسهولة التصفح. تزيد من قوتك ودفاعك.\n'
                  '✨ الأدوات الخاصة: مقتنيات أسطورية تمنحك سعادة وخصائص دائمة بمجرد تجهيزها.\n'
                  '🛠️ عتاد الجرائم: أدوات وأقنعة تقلل نسبة فشلك وتسهل هروبك.\n'
                  '💊 الأدوات: علاجات ومنشطات مؤقتة تستخدمها وقت الحاجة.\n'
                  '👑 VIP: تمنحك طاقة إضافية وميزات حصرية.',
              style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 14, height: 1.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList(List<Map<String, dynamic>> groups) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final Color color = group['color'];
        return Card(
          color: const Color(0xFF262630),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
              _openGroup(group['name'], group['items'], color, group['icon']);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(group['icon'], size: 28, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group['name'], style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('متوفر ${group['items'].length} عناصر', style: const TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBody(PlayerProvider player, List<Map<String, dynamic>> groups, int currentTabIndex, BlackMarketCubit cubit) {
    if (_activeGroupName != null && _activeGroupItems != null && _tabController.index == currentTabIndex) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.black45,
            child: Row(
              children: [
                Icon(_activeGroupIcon, color: _activeGroupColor, size: 24),
                const SizedBox(width: 10),
                Text(_activeGroupName!, style: TextStyle(color: _activeGroupColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                const Spacer(),
                Text('${_activeGroupItems!.length} عناصر', style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Changa')),
              ],
            ),
          ),
          Expanded(child: _buildItemsList(player, _activeGroupItems!, cubit)),
        ],
      );
    }
    return _buildGroupList(groups);
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    final List<Map<String, dynamic>> items = [
      ..._generateEquipment(player),
      {'id': 'dagger', 'name': 'خنجر كلاسيكي', 'description': 'قوة: +15%\nسرعة: +25%', 'price': 1500, 'currency': 'cash', 'icon': Icons.colorize, 'color': Colors.grey, 'type': 'weapon', 'isConsumable': false},
      {'id': 'revolver', 'name': 'مسدس كلاسيكي', 'description': 'قوة: +40%\nسرعة: +40%', 'price': 15000, 'currency': 'cash', 'icon': Icons.shutter_speed, 'color': Colors.blueGrey, 'type': 'weapon', 'isConsumable': false},
      {'id': 'katana', 'name': 'كاتانا كلاسيكي', 'description': 'قوة: +90%\nسرعة: +60%', 'price': 85000, 'currency': 'cash', 'icon': Icons.colorize_outlined, 'color': Colors.indigo, 'type': 'weapon', 'isConsumable': false},
      {'id': 'shotgun', 'name': 'شوزن كلاسيكي', 'description': 'قوة: +190%\nسرعة: +60%', 'price': 250000, 'currency': 'cash', 'icon': Icons.settings_overscan, 'color': Colors.orange, 'type': 'weapon', 'isConsumable': false},
      {'id': 'sniper', 'name': 'قناصة كلاسيكية', 'description': 'قوة: +270%\nسرعة: +80%', 'price': 1200, 'currency': 'gold', 'icon': Icons.track_changes, 'color': Colors.red, 'type': 'weapon', 'isConsumable': false},
      {'id': 'w_aladdin_damage', 'name': 'سيف علاء الدين القاطع', 'description': 'سلاح أسطوري يمزق الأعداء\nقوة: +500% | سرعة: +100%', 'price': 50000, 'currency': 'gold', 'icon': Icons.hardware, 'color': Colors.redAccent, 'type': 'weapon', 'isConsumable': false},
      {'id': 'w_aladdin_accuracy', 'name': 'خنجر علاء الدين السحري', 'description': 'دقة وسرعة لا مثيل لها\nقوة: +100% | سرعة: +500%', 'price': 50000, 'currency': 'gold', 'icon': Icons.flash_on, 'color': Colors.redAccent, 'type': 'weapon', 'isConsumable': false},
      {'id': 'riot_shield', 'name': 'درع شغب كلاسيكي', 'description': 'دفاع: +60%\nمهارة: +20%', 'price': 3000, 'currency': 'cash', 'icon': Icons.shield_outlined, 'color': Colors.blue, 'type': 'armor', 'isConsumable': false},
      {'id': 'kevlar_vest', 'name': 'سترة كلاسيكية', 'description': 'دفاع: +75%\nمهارة: +75%', 'price': 25000, 'currency': 'cash', 'icon': Icons.shield, 'color': Colors.green, 'type': 'armor', 'isConsumable': false},
      {'id': 'steel_armor', 'name': 'فولاذ كلاسيكي', 'description': 'دفاع: +190%\nمهارة: +60%', 'price': 120000, 'currency': 'cash', 'icon': Icons.security, 'color': Colors.grey, 'type': 'armor', 'isConsumable': false},
      {'id': 'exoskeleton', 'name': 'بدلة خارقة كلاسيكية', 'description': 'دفاع: +175%\nمهارة: +175%', 'price': 2500, 'currency': 'gold', 'icon': Icons.precision_manufacturing, 'color': Colors.amber, 'type': 'armor', 'isConsumable': false},
      {'id': 'a_aladdin_defense', 'name': 'درع الجني الفولاذي', 'description': 'دفاع صلب لا يمكن اختراقه\nدفاع: +500% | مهارة: +100%', 'price': 50000, 'currency': 'gold', 'icon': Icons.shield, 'color': Colors.redAccent, 'type': 'armor', 'isConsumable': false},
      {'id': 'ninja_suit', 'name': 'نينجا كلاسيكي', 'description': 'دفاع: +60%\nمهارة: +190%', 'price': 500000, 'currency': 'cash', 'icon': Icons.accessibility_new, 'color': Colors.cyanAccent, 'type': 'armor', 'isConsumable': false},
      {'id': 'a_aladdin_evasion', 'name': 'عباءة علاء الدين', 'description': 'تفادي جميع الضربات بخفة\nدفاع: +100% | مهارة: +500%', 'price': 50000, 'currency': 'gold', 'icon': Icons.air, 'color': Colors.cyanAccent, 'type': 'armor', 'isConsumable': false},
      {'id': 't_aladdin_lamp', 'name': 'المصباح السحري', 'description': 'سعادة: +300\nقوة: +7% | سرعة: +3%', 'price': 800, 'currency': 'gold', 'icon': Icons.lightbulb, 'color': Colors.amberAccent, 'type': 'special', 'isConsumable': false},
      {'id': 't_aladdin_carpet', 'name': 'البساط الطائر', 'description': 'سعادة: +300\nسرعة: +8% | دفاع: +2%', 'price': 800, 'currency': 'gold', 'icon': Icons.map, 'color': Colors.purpleAccent, 'type': 'special', 'isConsumable': false},
      {'id': 't_magic_ring', 'name': 'خاتم السلطة', 'description': 'سعادة: +200\nدفاع: +6% | طاقة: +15', 'price': 500, 'currency': 'gold', 'icon': Icons.radio_button_checked, 'color': Colors.orange, 'type': 'special', 'isConsumable': false},
      {'id': 't_dragon_heart', 'name': 'قلب التنين', 'description': 'سعادة: +500\nطاقة: +20 | شجاعة: +10', 'price': 1200, 'currency': 'gold', 'icon': Icons.favorite, 'color': Colors.red, 'type': 'special', 'isConsumable': false},
      {'id': 't_crystal_skull', 'name': 'جمجمة كريستال', 'description': 'سعادة: +250\nمهارة: +7% | قوة: +3%', 'price': 600, 'currency': 'gold', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.cyanAccent, 'type': 'special', 'isConsumable': false},
      {'id': 't_golden_apple', 'name': 'تفاحة ذهبية', 'description': 'سعادة: +400\nصحة: +10% | دفاع: +4%', 'price': 700, 'currency': 'gold', 'icon': Icons.apple, 'color': Colors.yellow, 'type': 'special', 'isConsumable': false},
      {'id': 't_lion_mane', 'name': 'عرف الأسد', 'description': 'سعادة: +200\nشجاعة: +15 | قوة: +4%', 'price': 400, 'currency': 'gold', 'icon': Icons.pets, 'color': Colors.orangeAccent, 'type': 'special', 'isConsumable': false},
      {'id': 't_phoenix_feather', 'name': 'ريشة العنقاء', 'description': 'سعادة: +600\nتعافي: +15% | صحة: +5%', 'price': 1500, 'currency': 'gold', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange, 'type': 'special', 'isConsumable': false},
      {'id': 't_time_hourglass', 'name': 'ساعة الزمن', 'description': 'سعادة: +550\nجميع الخصائص: +3% | تعافي: +5%', 'price': 2000, 'currency': 'gold', 'icon': Icons.hourglass_empty, 'color': Colors.blueAccent, 'type': 'special', 'isConsumable': false},
      {'id': 't_midas_touch', 'name': 'قفاز ميداس', 'description': 'سعادة: +600\nعائد الجرائم: +15% | شجاعة: +5', 'price': 2500, 'currency': 'gold', 'icon': Icons.front_hand, 'color': Colors.amber, 'type': 'special', 'isConsumable': false},
      {'id': 'black_mask', 'name': 'قناع تنكر', 'description': 'مطلوب لسرقة السيارات ويهربك 35%', 'price': 15000, 'currency': 'cash', 'icon': Icons.theater_comedy, 'color': Colors.deepPurpleAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'silicon_mask', 'name': 'قناع سيليكون', 'description': 'مطلوب لسطو البنك ويهربك 55%', 'price': 120000, 'currency': 'cash', 'icon': Icons.face_retouching_natural, 'color': Colors.pinkAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'crowbar', 'name': 'عتلة فولاذية', 'description': 'تخفض فشل السطو 5%', 'price': 2500, 'currency': 'cash', 'icon': Icons.hardware, 'color': Colors.grey, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'slim_jim', 'name': 'مفتاح مسطرة', 'description': 'تخفض فشل السيارات 10%', 'price': 5000, 'currency': 'cash', 'icon': Icons.horizontal_rule, 'color': Colors.blueGrey, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'jammer', 'name': 'جهاز تشويش', 'description': 'يعطل الإنذار (فشل -12%)', 'price': 12000, 'currency': 'cash', 'icon': Icons.vibration, 'color': Colors.teal, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'lockpick', 'name': 'طقم مفاتيح', 'description': 'للخزائن (فشل السطو -15%)', 'price': 20000, 'currency': 'cash', 'icon': Icons.vpn_key_outlined, 'color': Colors.amber, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'glass_cutter', 'name': 'قاطع زجاج', 'description': 'صامت (فشل -18%)', 'price': 35000, 'currency': 'cash', 'icon': Icons.architecture, 'color': Colors.cyan, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'stethoscope', 'name': 'سماعة طبية', 'description': 'فتح الخزائن (فشل السطو -10%)', 'price': 40000, 'currency': 'cash', 'icon': Icons.hearing, 'color': Colors.blue, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'laptop', 'name': 'لابتوب تهكير', 'description': 'للبنك والسيارات (فشل -22%)', 'price': 75000, 'currency': 'cash', 'icon': Icons.laptop_mac, 'color': Colors.deepPurpleAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'hydraulic', 'name': 'قاطع هيدروليك', 'description': 'قص الأسوار (فشل -15%)', 'price': 90000, 'currency': 'cash', 'icon': Icons.content_cut, 'color': Colors.redAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'thermite', 'name': 'ثيرميت حارق', 'description': 'يصهر الأبواب (فشل البنك -25%)', 'price': 150000, 'currency': 'cash', 'icon': Icons.whatshot, 'color': Colors.deepOrange, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'emp_device', 'name': 'جهاز EMP', 'description': 'يعطل الكاميرات (فشل عام -30%)', 'price': 500, 'currency': 'gold', 'icon': Icons.electric_bolt, 'color': Colors.yellowAccent, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'master_key', 'name': 'المفتاح الرئيسي', 'description': 'مطلوب للسطو على الفلل الفاخرة', 'price': 150000, 'currency': 'cash', 'icon': Icons.vpn_key, 'color': Colors.amber, 'type': 'crime_tool', 'isConsumable': false},
      {'id': 'bribe_small', 'name': 'رشوة محقق', 'description': 'تبريد الحرارة (20 درجة)', 'price': 10000, 'currency': 'cash', 'icon': Icons.handshake, 'color': Colors.teal, 'type': 'consumable', 'isConsumable': true},
      {'id': 'fake_plates', 'name': 'لوحات مزورة', 'description': 'تبريد الحرارة (40 درجة)', 'price': 25000, 'currency': 'cash', 'icon': Icons.subtitles, 'color': Colors.lightBlue, 'type': 'consumable', 'isConsumable': true},
      {'id': 'bribe_big', 'name': 'رشوة كبرى', 'description': 'تصفر الملاحقة فوراً', 'price': 100, 'currency': 'gold', 'icon': Icons.account_balance_sharp, 'color': Colors.amber, 'type': 'consumable', 'isConsumable': true},
      {'id': 'bandage', 'name': 'ضمادات', 'description': 'استعادة 25% من الصحة', 'price': 500, 'currency': 'cash', 'icon': Icons.healing, 'color': Colors.redAccent, 'type': 'consumable', 'isConsumable': true},
      {'id': 'medkit', 'name': 'حقيبة إسعاف', 'description': 'صحة 100% فوراً', 'price': 2500, 'currency': 'cash', 'icon': Icons.medical_information, 'color': Colors.redAccent, 'type': 'consumable', 'isConsumable': true},
      {'id': 'steroids', 'name': 'حقنة منشط', 'description': 'طاقة 100%', 'price': 50, 'currency': 'gold', 'icon': Icons.medical_services, 'color': Colors.greenAccent, 'type': 'consumable', 'isConsumable': true},
      {'id': 'coffee', 'name': 'قهوة مركزة', 'description': 'شجاعة 100%', 'price': 50, 'currency': 'gold', 'icon': Icons.coffee, 'color': Colors.brown, 'type': 'consumable', 'isConsumable': true},
      {'id': 'smoke_bomb', 'name': 'قنبلة دخانية', 'description': 'هروب فوري من السجن', 'price': 25, 'currency': 'gold', 'icon': Icons.air, 'color': Colors.grey, 'type': 'consumable', 'isConsumable': true},
    ];

    List<Map<String, dynamic>> filterItems(List<String> keywords) {
      return items.where((item) => keywords.any((kw) => item['id'].toString().contains(kw))).toList();
    }

    final weaponGroups = [
      {'name': 'مسدسات', 'icon': Icons.shutter_speed, 'color': Colors.blueGrey, 'items': filterItems(['revolver'])},
      {'name': 'خناجر', 'icon': Icons.colorize, 'color': Colors.grey, 'items': filterItems(['dagger', 'agile', 'w_aladdin_accuracy'])},
      {'name': 'سيوف', 'icon': Icons.colorize_outlined, 'color': Colors.indigo, 'items': filterItems(['katana', 'w_aladdin_damage'])},
      {'name': 'بنادق صيد', 'icon': Icons.settings_overscan, 'color': Colors.orange, 'items': filterItems(['shotgun', 'balanced'])},
      {'name': 'قناصات', 'icon': Icons.track_changes, 'color': Colors.red, 'items': filterItems(['sniper', 'tactical'])},
      {'name': 'أسلحة ثقيلة', 'icon': Icons.hardware, 'color': Colors.deepOrange, 'items': filterItems(['heavy'])},
    ];

    final armorGroups = [
      {'name': 'دروع خفيفة', 'icon': Icons.speed, 'color': Colors.cyanAccent, 'items': filterItems(['ninja_suit', 'agile', 'a_aladdin_evasion'])},
      {'name': 'دروع تكتيكية', 'icon': Icons.directions_run, 'color': Colors.green, 'items': filterItems(['kevlar_vest', 'tactical'])},
      {'name': 'دروع متوازنة', 'icon': Icons.accessibility_new, 'color': Colors.blue, 'items': filterItems(['balanced'])},
      {'name': 'دروع ثقيلة', 'icon': Icons.security, 'color': Colors.grey, 'items': filterItems(['riot_shield', 'steel_armor', 'heavy'])},
      {'name': 'دروع خارقة', 'icon': Icons.precision_manufacturing, 'color': Colors.amber, 'items': filterItems(['exoskeleton', 'a_aladdin_defense'])},
    ];

    final specialGroups = [
      {'name': 'تحف أسطورية', 'icon': Icons.auto_awesome, 'color': Colors.amberAccent, 'items': filterItems(['t_aladdin_lamp', 't_aladdin_carpet', 't_golden_apple', 't_phoenix_feather', 't_time_hourglass'])},
      {'name': 'مجوهرات وتمائم', 'icon': Icons.radio_button_checked, 'color': Colors.cyanAccent, 'items': filterItems(['t_magic_ring', 't_crystal_skull', 't_midas_touch'])},
      {'name': 'غنائم وحوش', 'icon': Icons.pets, 'color': Colors.redAccent, 'items': filterItems(['t_dragon_heart', 't_lion_mane'])},
    ];

    final crimeGroups = [
      {'name': 'أقنعة وتنكر', 'icon': Icons.theater_comedy, 'color': Colors.pinkAccent, 'items': filterItems(['black_mask', 'silicon_mask'])},
      {'name': 'أدوات اقتحام', 'icon': Icons.hardware, 'color': Colors.redAccent, 'items': filterItems(['crowbar', 'glass_cutter', 'hydraulic', 'thermite'])},
      {'name': 'أجهزة إلكترونية', 'icon': Icons.laptop_mac, 'color': Colors.deepPurpleAccent, 'items': filterItems(['jammer', 'laptop', 'emp_device'])},
      {'name': 'مفاتيح متخصصة', 'icon': Icons.vpn_key, 'color': Colors.amber, 'items': filterItems(['slim_jim', 'lockpick', 'stethoscope', 'master_key'])},
    ];

    final consumableGroups = [
      {'name': 'مستلزمات طبية', 'icon': Icons.medical_services, 'color': Colors.redAccent, 'items': filterItems(['bandage', 'medkit', 'steroids'])},
      {'name': 'رشاوي وتزوير', 'icon': Icons.handshake, 'color': Colors.teal, 'items': filterItems(['bribe_small', 'fake_plates', 'bribe_big'])},
      {'name': 'منشطات وهروب', 'icon': Icons.coffee, 'color': Colors.brown, 'items': filterItems(['coffee', 'smoke_bomb'])},
    ];

    final List<Map<String, dynamic>> vips = [
      {'id': 'vip_1', 'name': 'عضوية يوم', 'days': 1, 'price': 50},
      {'id': 'vip_7', 'name': 'عضوية أسبوع', 'days': 7, 'price': 300},
      {'id': 'vip_30', 'name': 'عضوية شهر', 'days': 30, 'price': 1000},
      {'id': 'vip_365', 'name': 'عضوية سنة', 'days': 365, 'price': 10000},
    ];

    // 🟢 ربط الواجهة بالكيوبت
    return BlocProvider(
      create: (context) => BlackMarketCubit(),
      child: BlocConsumer<BlackMarketCubit, BlackMarketState>(
        listener: (context, state) {
          if (state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
          }
          if (state.successMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
          }
        },
        builder: (context, state) {
          final cubit = context.read<BlackMarketCubit>();

          return Stack(
            children: [
              Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/ui/crime_bg.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),

                        if (_activeGroupName == null) ...[
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_checkout, color: Colors.redAccent, size: 24),
                              SizedBox(width: 8),
                              Text('المتجر الأسود 🌑', style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                            ],
                          ),
                          const SizedBox(height: 5),

                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Container(
                              width: double.infinity,
                              alignment: Alignment.centerRight,
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                padding: EdgeInsets.zero,
                                indicatorPadding: EdgeInsets.zero,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                                indicatorColor: Colors.redAccent,
                                labelColor: Colors.redAccent,
                                unselectedLabelColor: Colors.white54,
                                labelStyle: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold),
                                tabs: const [
                                  Tab(text: 'الأسلحة', icon: Icon(Icons.colorize)),
                                  Tab(text: 'الدروع', icon: Icon(Icons.shield)),
                                  Tab(text: 'الأدوات الخاصة', icon: Icon(Icons.auto_awesome)),
                                  Tab(text: 'عتاد الجرائم', icon: Icon(Icons.engineering)),
                                  Tab(text: 'أدوات', icon: Icon(Icons.medical_services)),
                                  Tab(text: 'VIP', icon: Icon(Icons.workspace_premium)),
                                ],
                              ),
                            ),
                          ),

                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildTabBody(player, weaponGroups, 0, cubit),
                                _buildTabBody(player, armorGroups, 1, cubit),
                                _buildTabBody(player, specialGroups, 2, cubit),
                                _buildTabBody(player, crimeGroups, 3, cubit),
                                _buildTabBody(player, consumableGroups, 4, cubit),
                                _buildVIPList(player, vips, cubit),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_activeGroupIcon, color: _activeGroupColor, size: 28),
                              const SizedBox(width: 8),
                              Text(_activeGroupName!, style: TextStyle(color: _activeGroupColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: _buildItemsList(player, _activeGroupItems!, cubit),
                          )
                        ]
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
                              Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                              _handleBack();
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
                            onTap: () => _showHelpDialog(context),
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
              ),

              // 🟢 شاشة التحميل (تغطي كامل الشاشة لمنع التكرار)
              if (state.isLoading)
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsList(PlayerProvider player, List<Map<String, dynamic>> items, BlackMarketCubit cubit) {
    if (items.isEmpty) {
      return const Center(
        child: Text("لا توجد عناصر في هذا القسم حالياً", style: TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 16)),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isConsumable = item['isConsumable'] ?? false;
        final bool hasItem = player.inventory.containsKey(item['id']);
        final String currency = item['currency'];
        final bool isSpecial = item['type'] == 'special';

        return Card(
          color: const Color(0xFF262630),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSpecial ? 8 : 2,
          shadowColor: isSpecial ? (item['color'] as Color).withOpacity(0.5) : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: isSpecial ? (item['color'] as Color) : (item['color'] as Color).withOpacity(0.5), width: isSpecial ? 1.5 : 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: (item['color'] as Color).withOpacity(0.2),
              child: Icon(item['icon'] as IconData, color: item['color'], size: 28),
            ),
            title: Text(item['name'], style: TextStyle(color: isSpecial ? item['color'] : Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Changa')),
            subtitle: Text(item['description'], style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 12, fontFamily: 'Changa')),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    '${item['price']} ${currency == 'cash' ? 'كاش' : 'ذهب'}',
                    style: TextStyle(color: currency == 'cash' ? Colors.greenAccent : Colors.amber, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Changa')
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 30,
                  width: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!isConsumable && hasItem) ? Colors.grey[700] : (isSpecial ? Colors.amber[800] : Colors.red[800]),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (!isConsumable && hasItem) return;
                      Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');

                      // 🟢 استدعاء الشراء عبر الكيوبت
                      cubit.buyItem(player, item['id'], item['price'], currency, 1, item['name']);
                    },
                    child: Text((!isConsumable && hasItem) ? 'مملوك' : 'شراء', style: const TextStyle(fontSize: 12, fontFamily: 'Changa', fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVIPList(PlayerProvider player, List<Map<String, dynamic>> vips, BlackMarketCubit cubit) {
    return Column(
      children: [
        if (player.isVIP)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber)
            ),
            child: Column(
              children: [
                const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text('عضوية VIP مفعلة', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Changa'))
                    ]
                ),
                const SizedBox(height: 2),
                if (player.vipUntil != null)
                  Text('تنتهي في: ${DateFormat('yyyy-MM-dd HH:mm').format(player.vipUntil!)}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: vips.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (context, index) {
              final vip = vips[index];
              return Card(
                color: const Color(0xFF262630),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1.5)
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(backgroundColor: Colors.black45, child: Icon(Icons.workspace_premium, color: Colors.amber, size: 28)),
                  title: Text(vip['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Changa')),
                  subtitle: const Text('طاقة وشجاعة قصوى 200', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${vip['price']} ذهب', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Changa')),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 30,
                        width: 70,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: player.isVIP ? Colors.grey[700] : Colors.amber[800],
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          onPressed: player.isVIP ? null : () {
                            Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
                            // 🟢 استدعاء الـ VIP عبر الكيوبت عشان نستفيد من شاشة التحميل
                            cubit.buyVip(player, vip['days'], vip['price']);
                          },
                          child: const Text('تفعيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Changa')),
                        ),
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