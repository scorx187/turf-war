// المسار: lib/views/journal_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class JournalView extends StatefulWidget {
  final VoidCallback onBack;

  const JournalView({super.key, required this.onBack});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> with SingleTickerProviderStateMixin {

  String _getApproximateHijriDate() {
    DateTime now = DateTime.now();
    int gYear = now.year;
    int gMonth = now.month;
    int gDay = now.day;

    int hYear = ((gYear - 622) * 33 / 32).floor();
    List<String> hijriMonths = ["محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"];

    int hMonthIndex = (gMonth + 2) % 12;
    return '$gDay ${hijriMonths[hMonthIndex]} $hYear هـ';
  }

  String _getGregorianDate() {
    DateTime now = DateTime.now();
    List<String> months = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"];
    return '${now.day} ${months[now.month - 1]} ${now.year} م';
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // 🟢 1. لون ثابت ومريح للعين بدلاً من الصورة المزعجة
        backgroundColor: const Color(0xFF1A1A1D),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 🟢 2. التوب بار ثابت ومصغر
            _buildStickyHeader(),

            const SliverToBoxAdapter(child: SizedBox(height: 15)),

            // 🟢 3. قسم الفعاليات (يعرض 3 فقط ونافذة موسعة)
            _buildEventsSection(audio),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // 🟢 4. المطلوبين للعدالة (مصغرة وغير مزعجة)
            _buildCompactBountiesSection(),

            // 5. أخبار الشوارع
            _buildNewsSection(),

            // 6. أزرار التصنيفات
            _buildLeaderboardsSection(audio),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(audio),
      ),
    );
  }

  // ==========================================
  // 📰 الترويسة (Header) ثابتة وصغيرة
  // ==========================================
  Widget _buildStickyHeader() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF1A1A1D),
      pinned: true, // يخليها ثابتة
      floating: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 75.0, // حجم مصغر جداً
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ui/header_wood_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
          border: Border(bottom: BorderSide(color: Color(0xFF856024), width: 2)),
          boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'صَـوْتُ المَــلاذ',
                style: TextStyle(
                  fontFamily: 'Changa',
                  fontSize: 22, // خط أصغر
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE2C275),
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getApproximateHijriDate(), style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 11)),
                    const Text('العدد #1042', style: TextStyle(color: Colors.redAccent, fontFamily: 'Changa', fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(_getGregorianDate(), style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🔥 قسم الفعاليات (3 نشطة فقط)
  // ==========================================
  Widget _buildEventsSection(AudioProvider audio) {
    // بيانات وهمية للفعاليات النشطة (3 فقط)
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
            // زر عرض كل الفعاليات (يفتح نافذة منبثقة)
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
  // 💀 المطلوبين للعدالة (شريط مصغر جداً)
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
            height: 65, // 🟢 تم تصغير الارتفاع جداً
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: bounties.length,
              itemBuilder: (context, index) {
                var target = bounties[index];
                return Container(
                  width: 140, // كرت عريض ومسطح
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
          }).toList(),

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
  // 📅 نافذة جدول الفعاليات (البوتوم شيت)
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
                      // تاب الفعاليات النشطة
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildEventModalCard('مضاعفة أرباح الجرائم', 'ينتهي اليوم 11:59 م', Colors.redAccent, true),
                          _buildEventModalCard('تخفيضات السوق الأسود', 'ينتهي اليوم 11:59 م', Colors.amber, true),
                          _buildEventModalCard('حملة تبرع بالدم', 'ينتهي غداً 11:59 م', Colors.greenAccent, true),
                        ],
                      ),
                      // تاب الفعاليات القادمة
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildEventModalCard('حرب العصابات الأسبوعية', 'تبدأ يوم الجمعة 08:00 م', Colors.purpleAccent, false),
                          _buildEventModalCard('وصول تاجر الأسلحة السري', 'يبدأ يوم السبت 12:00 م', Colors.blueAccent, false),
                        ],
                      ),
                      // تاب الفعاليات المنتهية
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
        border: Border.all(color: isActive ? color.withOpacity(0.5) : Colors.white10),
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