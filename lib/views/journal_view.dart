// المسار: lib/views/journal_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/audio_provider.dart';

class JournalView extends StatefulWidget {
  final VoidCallback onBack;

  const JournalView({super.key, required this.onBack});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> with SingleTickerProviderStateMixin {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  bool _is24HourFormat = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getFormattedTime() {
    int hour = _currentTime.hour;
    int minute = _currentTime.minute;
    int second = _currentTime.second;

    String minuteStr = minute.toString().padLeft(2, '0');
    String secondStr = second.toString().padLeft(2, '0');

    if (_is24HourFormat) {
      String hourStr = hour.toString().padLeft(2, '0');
      return '$hourStr:$minuteStr:$secondStr';
    } else {
      String period = hour >= 12 ? 'PM' : 'AM';
      int hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;
      String hourStr = hour12.toString().padLeft(2, '0');
      return '$hourStr:$minuteStr:$secondStr $period';
    }
  }

  String _getApproximateHijriDate(DateTime date) {
    int jd = date.difference(DateTime.utc(1970, 1, 1)).inDays + 2440588;
    int l = jd - 1948440 + 10632;
    int n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    int j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;

    int month = (24 * l) ~/ 709;
    int day = l - (709 * month) ~/ 24;
    int year = 30 * n + j - 30;

    List<String> hijriMonths = ["محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"];
    return '$day ${hijriMonths[month - 1]} $year هـ';
  }

  String _getGregorianDate(DateTime date) {
    List<String> months = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"];
    return '${date.day} ${months[date.month - 1]} ${date.year} م';
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 🟢 التوب بار المصغر جداً والمعدل
            _buildStickyHeader(audio),

            const SliverToBoxAdapter(child: SizedBox(height: 15)),

            _buildEventsSection(audio),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            _buildCompactBountiesSection(),

            _buildNewsSection(),

            _buildLeaderboardsSection(audio),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(audio),
      ),
    );
  }

// ==========================================
  // 📰 الترويسة (Header) - ملمومة وبدون فراغات (مثل الجرائم)
  // ==========================================
  Widget _buildStickyHeader(AudioProvider audio) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF111111), // أسود مطفي فخم
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      centerTitle: true,
      titleSpacing: 0.0,
      toolbarHeight: 65.0, // 🟢 مقاس صغير جداً وملموم
      shape: const Border(bottom: BorderSide(color: Color(0xFF856024), width: 1.5)), // الخط الذهبي السفلي
      title: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. التواريخ (مرفوعة لأقصى نقطة فوق)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getApproximateHijriDate(_currentTime), style: const TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 10)),
                    Text(_getGregorianDate(_currentTime), style: const TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 10)),
                  ],
                ),
              ),
            ),

            // 2. العنوان والساعة (في الوسط تماماً بدون فراغات)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12), // مسافة بسيطة جداً لإبعادها عن التاريخ
                const Text(
                  'الجريدة',
                  style: TextStyle(
                    fontFamily: 'Changa',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE2C275),
                    height: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    audio.playEffect('click.mp3');
                    setState(() {
                      _is24HourFormat = !_is24HourFormat;
                    });
                  },
                  child: Text(
                    _getFormattedTime(),
                    style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🔥 قسم الفعاليات
  // ==========================================
  Widget _buildEventsSection(AudioProvider audio) {
    List<Map<String, dynamic>> activeEvents = [
      {'title': 'مضاعفة أرباح الجرائم', 'desc': 'جميع الجرائم تعطي 2x كاش وخبرة.', 'icon': Icons.local_fire_department, 'color': Colors.redAccent},
      {'title': 'تخفيضات السوق الأسود', 'desc': 'خصم 20% على جميع الأسلحة.', 'icon': Icons.shopping_cart, 'color': Colors.amber},
      {'title': 'حملة تبرع بالدم', 'desc': 'الاستشفاء في المستشفى أسرع بنسبة 50%.', 'icon': Icons.local_hospital, 'color': Colors.greenAccent},
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, left: 12),
              child: Row(
                children: const [
                  Icon(Icons.event_available, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 8),
                  Text('الفعاليات النشطة', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(color: Colors.white10, thickness: 1),
            ...activeEvents.map((event) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(event['icon'], color: event['color'], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '${event['title']}: ', style: TextStyle(color: event['color'], fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                          TextSpan(text: event['desc'], style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 5),
            InkWell(
              onTap: () {
                audio.playEffect('click.mp3');
                _showEventsScheduleModal(context);
              },
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: const Center(
                  child: Text('عرض جدول الفعاليات 📅', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 💀 المطلوبين للعدالة
  // ==========================================
  Widget _buildCompactBountiesSection() {
    List<Map<String, dynamic>> bounties = [
      {'name': 'الزعيم العقرب', 'bounty': '50M', 'image': 'assets/images/icons/profile.png'},
      {'name': 'شبح الليل', 'bounty': '15.5M', 'image': 'assets/images/icons/profile.png'},
      {'name': 'السفاح', 'bounty': '8M', 'image': 'assets/images/icons/profile.png'},
      {'name': 'الكابوس', 'bounty': '5M', 'image': 'assets/images/icons/profile.png'},
    ];

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Text('🎯 مطلوبين للعدالة', style: TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 65,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: bounties.length,
              itemBuilder: (context, index) {
                var target = bounties[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2318),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF856024), width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black,
                        backgroundImage: AssetImage(target['image']),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(target['name'], style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('\$${target['bounty']}', style: const TextStyle(color: Colors.redAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🗞️ أخبار الشوارع
  // ==========================================
  Widget _buildNewsSection() {
    List<Map<String, dynamic>> newsList = [
      {'title': 'سطو مسلح ناجح!', 'body': 'اللاعب [السفاح] يقتحم البنك المركزي ويهرب بمبلغ 150 مليون كاش!', 'icon': Icons.account_balance, 'color': Colors.redAccent, 'time': 'قبل 5 دقائق'},
      {'title': 'عصابة جديدة', 'body': 'تأسيس عصابة [الذئاب] بقيادة الزعيم [أبو جلمبو].. احذروا منهم!', 'icon': Icons.group, 'color': Colors.blueAccent, 'time': 'قبل ساعة'},
      {'title': 'الجائزة الكبرى', 'body': 'اللاعب [المجهول] يبتسم له الحظ ويفوز بـ 50 مليون من الكازينو!', 'icon': Icons.casino, 'color': Colors.amber, 'time': 'قبل ساعتين'},
      {'title': 'إعلان مدفوع', 'body': 'عصابة [الصقور] تفتح باب الانضمام للمستوى 50 فما فوق، رواتب يومية!', 'icon': Icons.campaign, 'color': Colors.greenAccent, 'time': 'قبل 3 ساعات'},
      {'title': 'ترقية خطيرة', 'body': 'اللاعب [العقرب] يصل لمستوى 100 ويحصل على لقب (عراب الشوارع)!', 'icon': Icons.military_tech, 'color': Colors.purpleAccent, 'time': 'قبل 5 ساعات'},
    ];

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const Text('🗞️ أصداء الشارع', style: TextStyle(color: Color(0xFFE2C275), fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...newsList.map((news) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: const Border(right: BorderSide(color: Color(0xFF856024), width: 3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(news['icon'], color: news['color'], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(news['title'], style: TextStyle(color: news['color'], fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(news['time'], style: const TextStyle(color: Colors.white30, fontFamily: 'Changa', fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(news['body'], style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 11, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('قراءة الأرشيف القديم 📂', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  // ==========================================
  // 🏆 أزرار التصنيفات
  // ==========================================
  Widget _buildLeaderboardsSection(AudioProvider audio) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => audio.playEffect('click.mp3'),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC5A059), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text('أقوى الزعماء', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: () => audio.playEffect('click.mp3'),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purpleAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield, color: Colors.purpleAccent, size: 24),
                      SizedBox(width: 8),
                      Text('أخطر العصابات', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🔙 الشريط السفلي
  // ==========================================
  Widget _buildBottomNavBar(AudioProvider audio) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black87,
        image: DecorationImage(image: AssetImage('assets/images/ui/bottom_navbar_bg.png'), fit: BoxFit.cover),
        border: Border(top: BorderSide(color: Color(0xFF856024), width: 2)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 20, left: 15, right: 15),
      child: SafeArea(
        bottom: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                audio.playEffect('click.mp3');
                widget.onBack();
              },
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
              onTap: () => audio.playEffect('click.mp3'),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_document, color: Colors.white70, size: 24),
                  SizedBox(height: 4),
                  Text('نشر إعلان مدفوع', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 📅 نافذة جدول الفعاليات
  // ==========================================
  void _showEventsScheduleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.amber, width: 1.5),
      ),
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 3,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 10),
                const TabBar(
                  indicatorColor: Colors.amber,
                  labelColor: Colors.amber,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: [
                    Tab(text: 'النشطة 🟢'),
                    Tab(text: 'القادمة ⏳'),
                    Tab(text: 'المنتهية 🔴'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildEventModalCard('مضاعفة أرباح الجرائم', 'ينتهي اليوم 11:59 م', Colors.redAccent, true),
                          _buildEventModalCard('تخفيضات السوق الأسود', 'ينتهي اليوم 11:59 م', Colors.amber, true),
                          _buildEventModalCard('حملة تبرع بالدم', 'ينتهي غداً 11:59 م', Colors.greenAccent, true),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildEventModalCard('حرب العصابات الأسبوعية', 'تبدأ يوم الجمعة 08:00 م', Colors.purpleAccent, false),
                          _buildEventModalCard('وصول تاجر الأسلحة السري', 'يبدأ يوم السبت 12:00 م', Colors.blueAccent, false),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildEventModalCard('موسم سباق الشوارع', 'انتهى منذ يومين', Colors.grey, false),
                          _buildEventModalCard('توزيع الذهب المجاني', 'انتهى الأسبوع الماضي', Colors.grey, false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventModalCard(String title, String timeText, Color color, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? color.withValues(alpha: 0.5) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.local_fire_department : Icons.event_note, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 14, fontWeight: FontWeight.bold, decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough)),
                const SizedBox(height: 2),
                Text(timeText, style: TextStyle(color: color, fontFamily: 'Changa', fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}