// المسار: lib/views/player_profile_view.dart

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../utils/game_data.dart';
import 'private_chat_view.dart';
import 'pvp_battle_view.dart';
import 'public_gang_profile_view.dart';
import '../widgets/radar_painter.dart';
import 'titles_view.dart';
import 'perks_view.dart';
import 'armory_view.dart'; // 🟢 استدعاء شاشة التسليح 🟢

class PlayerProfileView extends StatefulWidget {
  final String targetUid;
  final VoidCallback? onBack;
  final int profileTabIndex;

  final String? previewName;
  final String? previewPicUrl;
  final bool? previewIsVIP;

  const PlayerProfileView({
    super.key,
    required this.targetUid,
    this.onBack,
    this.profileTabIndex = 0,
    this.previewName,
    this.previewPicUrl,
    this.previewIsVIP,
  });

  @override
  State<PlayerProfileView> createState() => _PlayerProfileViewState();
}

class _PlayerProfileViewState extends State<PlayerProfileView> {
  Map<String, dynamic>? playerData;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    bool isMe = widget.targetUid == player.uid;

    if (isMe) {
      playerData = {
        'uid': player.uid,
        'playerName': player.playerName,
        'gameId': player.gameId,
        'profilePicUrl': player.profilePicUrl,
        'backgroundPicUrl': player.backgroundPicUrl,
        'isVIP': player.isVIP,
        'totalVipDays': player.totalVipDays,
        'bio': player.bio,
        'gangName': player.gangName,
        'gangContribution': player.gangContribution,
        'currentCity': player.currentCity,
        'isHospitalized': player.isHospitalized,
        'isInPrison': player.isInPrison,
        'pvpWins': player.pvpWins,
        'totalStolenCash': player.totalStolenCash,
        'crimeSuccessCountsMap': player.crimeSuccessCountsMap,
        'crimeLevel': player.crimeLevel,
        'workLevel': player.workLevel,
        'arenaLevel': player.arenaLevel,
        'perks': player.perks,
        'selectedTitle': player.selectedTitle,
        'baseStrength': player.baseStrength, 'bonusStrength': player.strength - player.baseStrength,
        'baseDefense': player.baseDefense, 'bonusDefense': player.defense - player.baseDefense,
        'baseSpeed': player.baseSpeed, 'bonusSpeed': player.speed - player.baseSpeed,
        'baseSkill': player.baseSkill, 'bonusSkill': player.skill - player.baseSkill,
        'happiness': player.happiness,
        'cash': player.cash,
        'bankBalance': player.bankBalance,
        'gold': player.gold,
        'ownedProperties': player.ownedProperties,
        'activePropertyId': player.activePropertyId,
        'ownedCars': player.ownedCars,
        'ownedBusinesses': player.ownedBusinesses,
        'spareParts': player.spareParts,
        'totalLabCrafts': player.totalLabCrafts,
        'luckyWheelSpins': player.luckyWheelSpins,
      };
    } else {
      playerData = {
        'playerName': widget.previewName ?? 'جاري التحميل...',
        'gameId': '---',
        'profilePicUrl': widget.previewPicUrl,
        'backgroundPicUrl': null,
        'isVIP': widget.previewIsVIP ?? false,
        'totalVipDays': 0,
        'bio': 'جاري تحديث البيانات...',
        'currentCity': 'ملاذ', 'isHospitalized': false, 'isInPrison': false,
        'pvpWins': 0, 'totalStolenCash': 0, 'crimeSuccessCountsMap': {}, 'perks': {},
        'baseStrength': 5.0, 'bonusStrength': 0.0,
        'baseDefense': 5.0, 'bonusDefense': 0.0,
        'baseSpeed': 5.0, 'bonusSpeed': 0.0,
        'baseSkill': 5.0, 'bonusSkill': 0.0,
        'happiness': 0, 'cash': 0, 'bankBalance': 0,
        'gold': 0, 'ownedProperties': [], 'activePropertyId': null, 'ownedCars': [], 'gangContribution': 0,
        'crimeLevel': 1, 'workLevel': 1, 'arenaLevel': 1, 'ownedBusinesses': {},
        'spareParts': 0, 'totalLabCrafts': 0, 'luckyWheelSpins': 0,
      };
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final data = await player.getPlayerById(widget.targetUid);
    if (mounted && data != null) {
      double baseStr = (data['strength'] ?? 5.0).toDouble();
      double baseDef = (data['defense'] ?? 5.0).toDouble();
      double baseSpd = (data['speed'] ?? 5.0).toDouble();
      double baseSkl = (data['skill'] ?? 5.0).toDouble();
      double bStr = (data['equippedWeaponId'] != null && GameData.weaponStats.containsKey(data['equippedWeaponId'])) ? baseStr * GameData.weaponStats[data['equippedWeaponId']]!['str']! : 0.0;
      double bSpd = (data['equippedWeaponId'] != null && GameData.weaponStats.containsKey(data['equippedWeaponId'])) ? baseSpd * GameData.weaponStats[data['equippedWeaponId']]!['spd']! : 0.0;
      double bDef = (data['equippedArmorId'] != null && GameData.armorStats.containsKey(data['equippedArmorId'])) ? baseDef * GameData.armorStats[data['equippedArmorId']]!['def']! : 0.0;
      double bSkl = (data['equippedArmorId'] != null && GameData.armorStats.containsKey(data['equippedArmorId'])) ? baseSkl * GameData.armorStats[data['equippedArmorId']]!['skl']! : 0.0;

      data['baseStrength'] = baseStr; data['bonusStrength'] = bStr;
      data['baseDefense'] = baseDef; data['bonusDefense'] = bDef;
      data['baseSpeed'] = baseSpd; data['bonusSpeed'] = bSpd;
      data['baseSkill'] = baseSkl; data['bonusSkill'] = bSkl;

      setState(() => playerData = data);
    }
  }

  String _formatWithCommas(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},');
  }

  List<Map<String, dynamic>> _getAllTitlesLocal(Map<String, dynamic> data) {
    int pvp = data['pvpWins'] ?? 0;
    int wlth = (data['cash'] ?? 0) + (data['bankBalance'] ?? 0);
    int gld = data['gold'] ?? 0;
    int cr = 0;
    if (data['crimeSuccessCountsMap'] != null) {
      (data['crimeSuccessCountsMap'] as Map).forEach((k, v) => cr += (v as int));
    }
    int hap = data['happiness'] ?? 0;
    List<String> ownedProps = List<String>.from(data['ownedProperties'] ?? []);
    bool isHoused = data['activePropertyId'] != null;
    int totalProps = GameData.residentialProperties.length;

    int carsOwned = List<String>.from(data['ownedCars'] ?? []).length;
    int gangCont = data['gangContribution'] ?? 0;
    int crimeLvl = data['crimeLevel'] ?? 1;
    int workLvl = data['workLevel'] ?? 1;
    int arenaLvl = data['arenaLevel'] ?? 1;
    int totalVipDays = data['totalVipDays'] ?? 0;
    int bizCount = (data['ownedBusinesses'] as Map?)?.length ?? 0;
    int spareParts = data['spareParts'] ?? 0;
    int labCrafts = data['totalLabCrafts'] ?? 0;
    int wheelSpins = data['luckyWheelSpins'] ?? 0;

    return [
      {'name': 'مبتدئ في الشوارع 🚶', 'desc': 'اللقب الافتراضي (متاح للجميع)', 'unlocked': true},
      {'name': 'مبتدئ مالي 💵', 'desc': 'اجمع 100 ألف دولار', 'unlocked': wlth >= 100000},
      {'name': 'مليونير صاعد 💰', 'desc': 'اجمع 1 مليون دولار', 'unlocked': wlth >= 1000000},
      {'name': 'رجل أعمال ثري 🏦', 'desc': 'اجمع 10 مليون دولار', 'unlocked': wlth >= 10000000},
      {'name': 'حوت المافيا 🐋', 'desc': 'اجمع 100 مليون دولار', 'unlocked': wlth >= 100000000},
      {'name': 'نصف بليونير 💎', 'desc': 'اجمع 500 مليون دولار', 'unlocked': wlth >= 500000000},
      {'name': 'بليونير الشوارع 💸', 'desc': 'اجمع 1 مليار دولار', 'unlocked': wlth >= 1000000000},
      {'name': 'قارون المدينة 🪙', 'desc': 'اجمع 10 مليار دولار', 'unlocked': wlth >= 10000000000},
      {'name': 'إمبراطور الاقتصاد 🌍', 'desc': 'اجمع 100 مليار دولار', 'unlocked': wlth >= 100000000000},
      {'name': 'باحث عن الذهب ⛏️', 'desc': 'اجمع 100 ذهبة', 'unlocked': gld >= 100},
      {'name': 'مكتنز الذهب 🪙', 'desc': 'اجمع 500 ذهبة', 'unlocked': gld >= 500},
      {'name': 'تاجر الذهب ⚖️', 'desc': 'اجمع 1,000 ذهبة', 'unlocked': gld >= 1000},
      {'name': 'بارون الذهب 👑', 'desc': 'اجمع 5,000 ذهبة', 'unlocked': gld >= 5000},
      {'name': 'ملك السبائك 🧱', 'desc': 'اجمع 10,000 ذهبة', 'unlocked': gld >= 10000},
      {'name': 'خزنة لا تنضب 🏦', 'desc': 'اجمع 50,000 ذهبة', 'unlocked': gld >= 50000},
      {'name': 'أسطورة الذهب 🌟', 'desc': 'اجمع 100,000 ذهبة', 'unlocked': gld >= 100000},
      {'name': 'إله الثروة ⚡', 'desc': 'اجمع 500,000 ذهبة', 'unlocked': gld >= 500000},
      {'name': 'قاتل مأجور 🎯', 'desc': 'اقتل 10 لاعبين في الشوارع', 'unlocked': pvp >= 10},
      {'name': 'سفاح خطير 🔪', 'desc': 'اقتل 50 لاعب في الشوارع', 'unlocked': pvp >= 50},
      {'name': 'أسطورة الجريمة 👑🩸', 'desc': 'اقتل 200 لاعب في الشوارع', 'unlocked': pvp >= 200},
      {'name': 'لص محترف 🥷', 'desc': 'نفذ 500 جريمة ناجحة', 'unlocked': cr >= 500},
      {'name': 'عقل مدبر 🧠', 'desc': 'نفذ 2,000 جريمة ناجحة', 'unlocked': cr >= 2000},
      {'name': 'زعيم المافيا 🎩', 'desc': 'نفذ 10,000 جريمة ناجحة', 'unlocked': cr >= 10000},
      {'name': 'كابوس المدينة 🦇', 'desc': 'نفذ 50,000 جريمة ناجحة', 'unlocked': cr >= 50000},
      {'name': 'شيطان الشوارع 👹', 'desc': 'نفذ 100,000 جريمة ناجحة', 'unlocked': cr >= 100000},
      {'name': 'رجل أعمال سعيد 💼', 'desc': 'صل إلى 500 نقطة سعادة', 'unlocked': hap >= 500},
      {'name': 'مواطن VIP 🥂', 'desc': 'صل إلى 2,000 نقطة سعادة', 'unlocked': hap >= 2000},
      {'name': 'سيد الرفاهية 🏰', 'desc': 'صل إلى 5,000 نقطة سعادة', 'unlocked': hap >= 5000},
      {'name': 'إمبراطور النعيم 👑', 'desc': 'صل إلى 10,000 نقطة سعادة', 'unlocked': hap >= 10000},
      {'name': 'أسطورة السعادة 🌈', 'desc': 'صل إلى 50,000 نقطة سعادة', 'unlocked': hap >= 50000},
      {'name': 'مواطن مستقر 🏠', 'desc': 'اشتر أول عقار لك واسكن فيه', 'unlocked': ownedProps.isNotEmpty && isHoused},
      {'name': 'مستثمر عقاري 🏢', 'desc': 'اشتر 5 عقارات واسكن في أحدها', 'unlocked': ownedProps.length >= 5 && isHoused},
      {'name': 'ملك العقارات 🏙️', 'desc': 'اشتر جميع العقارات واسكن في أحدها', 'unlocked': ownedProps.length >= totalProps && isHoused},
      {'name': 'تاجر صغير 🏪', 'desc': 'اشتر مشروع تجاري واحد', 'unlocked': bizCount >= 1},
      {'name': 'محتكر السوق 📈', 'desc': 'اشتر 5 مشاريع تجارية', 'unlocked': bizCount >= 5},
      {'name': 'إمبراطور التجارة 🛳️', 'desc': 'اشتر 10 مشاريع تجارية', 'unlocked': bizCount >= 10},
      {'name': 'هاوي محركات 🏎️', 'desc': 'امتلك سيارة واحدة', 'unlocked': carsOwned >= 1},
      {'name': 'مجمع سيارات 🚘', 'desc': 'امتلك 5 سيارات', 'unlocked': carsOwned >= 5},
      {'name': 'إمبراطور الكراجات 👑🏎️', 'desc': 'امتلك 25 سيارة', 'unlocked': carsOwned >= 25},
      {'name': 'ميكانيكي مبتدئ 🔧', 'desc': 'اجمع 100 قطعة غيار', 'unlocked': spareParts >= 100},
      {'name': 'خبير تفكيك ⚙️', 'desc': 'اجمع 1,000 قطعة غيار', 'unlocked': spareParts >= 1000},
      {'name': 'ملك السكراب 🚜', 'desc': 'اجمع 10,000 قطعة غيار', 'unlocked': spareParts >= 10000},
      {'name': 'إمبراطور القطع 🏭', 'desc': 'اجمع 50,000 قطعة غيار', 'unlocked': spareParts >= 50000},
      {'name': 'كيميائي هاوي 🧪', 'desc': 'قم بـ 10 عمليات تصنيع في المختبر', 'unlocked': labCrafts >= 10},
      {'name': 'طباخ محترف 👨‍🔬', 'desc': 'قم بـ 50 عملية تصنيع في المختبر', 'unlocked': labCrafts >= 50},
      {'name': 'خبير سموم ☠️', 'desc': 'قم بـ 200 عملية تصنيع في المختبر', 'unlocked': labCrafts >= 200},
      {'name': 'هايزنبرغ المدينة 💎', 'desc': 'قم بـ 1,000 عملية تصنيع في المختبر', 'unlocked': labCrafts >= 1000},
      {'name': 'محب للمغامرة 🎡', 'desc': 'دور عجلة الحظ 10 مرات', 'unlocked': wheelSpins >= 10},
      {'name': 'مدمن قمار 🎲', 'desc': 'دور عجلة الحظ 50 مرة', 'unlocked': wheelSpins >= 50},
      {'name': 'ملك الحظ 🍀', 'desc': 'دور عجلة الحظ 200 مرة', 'unlocked': wheelSpins >= 200},
      {'name': 'حبيب الكازينو 🎰', 'desc': 'دور عجلة الحظ 1,000 مرة', 'unlocked': wheelSpins >= 1000},
      {'name': 'عضو داعم 🪙', 'desc': 'تبرع بـ 100,000 لعصابتك', 'unlocked': gangCont >= 100000},
      {'name': 'ذراع اليمين 🤝', 'desc': 'تبرع بـ 1,000,000 لعصابتك', 'unlocked': gangCont >= 1000000},
      {'name': 'عراب الشوارع 🕴️', 'desc': 'تبرع بـ 100 مليون لعصابتك', 'unlocked': gangCont >= 100000000},
      {'name': 'خارج عن القانون 🔫', 'desc': 'صل للمستوى 10 في الجريمة', 'unlocked': crimeLvl >= 10},
      {'name': 'شبح المدينة 👻', 'desc': 'صل للمستوى 100 في الجريمة', 'unlocked': crimeLvl >= 100},
      {'name': 'الحاكم المطلق 👑🌍', 'desc': 'صل للمستوى 400 (الماكس لفل)', 'unlocked': crimeLvl >= 400},
      {'name': 'موظف مجتهد 💼', 'desc': 'صل للمستوى 10 في العمل', 'unlocked': workLvl >= 10},
      {'name': 'وزير الاقتصاد 🏛️', 'desc': 'صل للمستوى 100 في العمل', 'unlocked': workLvl >= 100},
      {'name': 'ملاكم شوارع 🥊', 'desc': 'صل للمستوى 10 في الحلبة', 'unlocked': arenaLvl >= 10},
      {'name': 'جلاد الساحة 🩸', 'desc': 'صل للمستوى 100 في الحلبة', 'unlocked': arenaLvl >= 100},
      {'name': 'زائر مميز 🌟', 'desc': 'فعل اشتراك VIP لمدة يوم', 'unlocked': totalVipDays >= 1},
      {'name': 'شخصية هامة 🍷', 'desc': 'فعل اشتراك VIP لمدة أسبوع', 'unlocked': totalVipDays >= 7},
      {'name': 'نجم المدينة 💎', 'desc': 'فعل اشتراك VIP لمدة شهر', 'unlocked': totalVipDays >= 30},
      {'name': 'صاحب الفخامة 👑💎', 'desc': 'فعل اشتراك VIP لمدة سنة', 'unlocked': totalVipDays >= 365},
    ];
  }

  // 🟢 رفع الصورة كـ (Bytes) وعرض دائرة تحميل صغيرة 🟢
  Future<void> _pickImage(PlayerProvider player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      // إظهار دائرة التحميل
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));

      // رفع الصورة وجلب الرابط
      String? newUrl = await player.uploadAndSetProfilePic(bytes);

      if (mounted) {
        Navigator.pop(context); // إغلاق دائرة التحميل
        if (newUrl != null) {
          setState(() {
            playerData!['profilePicUrl'] = newUrl; // تحديث الصورة فوراً في الواجهة
          });
        }
      }
    }
  }

  // 🟢 رفع الغلاف وعرض دائرة تحميل 🟢
  Future<void> _pickBackgroundImage(PlayerProvider player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      // إظهار دائرة التحميل
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.amber)));

      String? newUrl = await player.uploadAndSetBackgroundPic(bytes);

      if (mounted) {
        Navigator.pop(context); // إغلاق دائرة التحميل
        if (newUrl != null) {
          setState(() {
            playerData!['backgroundPicUrl'] = newUrl; // تحديث الغلاف فوراً
          });
        }
      }
    }
  }

  void _editBio(PlayerProvider player) {
    TextEditingController bioController = TextEditingController(text: playerData!['bio'] ?? '');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('تعديل البايو ✍️', style: TextStyle(color: Colors.amber), textAlign: TextAlign.right),
        content: TextField(controller: bioController, maxLength: 100, style: const TextStyle(color: Colors.white), textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'اكتب وصفك هنا...', hintStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), onPressed: () { player.updateBio(bioController.text.trim()); setState(() => playerData!['bio'] = bioController.text.trim()); Navigator.pop(c); }, child: const Text('حفظ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showTransferDialog(PlayerProvider player) {
    TextEditingController amountController = TextEditingController();
    bool isTransferring = false;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 2)), title: const Text('تحويل كاش 💸', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.center, textDirection: TextDirection.rtl, children: [const Text('الرصيد المتاح: ', style: TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 16)), Text('\$${_formatWithCommas(player.cash)}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold))]), const SizedBox(height: 15), TextField(controller: amountController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontFamily: 'Changa'), textAlign: TextAlign.center, decoration: InputDecoration(hintText: 'أدخل المبلغ هنا...', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.amber)))), if (isTransferring) ...[const SizedBox(height: 20), const CircularProgressIndicator(color: Colors.amber)]]),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(onPressed: isTransferring ? null : () => Navigator.pop(c), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa'))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: isTransferring ? null : () async {
                    int? amount = int.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح!'), backgroundColor: Colors.redAccent)); return; }
                    if (amount > player.cash) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيدك لا يكفي!'), backgroundColor: Colors.redAccent)); return; }
                    setDialogState(() => isTransferring = true);
                    try {
                      final firestore = FirebaseFirestore.instance;
                      await firestore.runTransaction((transaction) async {
                        final senderRef = firestore.collection('players').doc(player.uid);
                        final receiverRef = firestore.collection('players').doc(widget.targetUid);
                        final senderSnap = await transaction.get(senderRef);
                        final receiverSnap = await transaction.get(receiverRef);
                        if (!senderSnap.exists || !receiverSnap.exists) throw Exception("اللاعب غير موجود!");
                        int senderCash = senderSnap.data()?['cash'] ?? 0;
                        if (senderCash < amount) throw Exception("رصيدك لا يكفي!");
                        int receiverCash = receiverSnap.data()?['cash'] ?? 0;
                        transaction.update(senderRef, {'cash': senderCash - amount});
                        List<dynamic> receiverTxs = receiverSnap.data()?['transactions'] ?? [];
                        receiverTxs.insert(0, {'title': 'تحويل من ${player.playerName}', 'amount': amount, 'date': DateTime.now().toIso8601String(), 'isPositive': true, 'senderUid': player.uid});
                        if (receiverTxs.length > 20) receiverTxs.removeLast();
                        transaction.update(receiverRef, {'cash': receiverCash + amount, 'transactions': receiverTxs});
                      });
                      player.removeCash(amount, reason: 'تحويل مالي إلى ${playerData!['playerName']}');
                      if (mounted) { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحويل \$${_formatWithCommas(amount)} بنجاح! 💸', textDirection: TextDirection.rtl), backgroundColor: Colors.green)); Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3'); }
                    } catch (e) {
                      setDialogState(() => isTransferring = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التحويل!'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('تأكيد التحويل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                ),
              ],
            );
          }
      ),
    );
  }

  void _showBountyDialog(PlayerProvider player) {
    TextEditingController amountController = TextEditingController();
    bool isAnonymous = false;
    bool isProcessing = false;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.deepOrange, width: 2)), title: const Text('وضع مكافأة 🎯', style: TextStyle(color: Colors.deepOrange, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('سيتم نشر إعلان في شات المدينة لكل اللاعبين للهجوم على هذا الهدف.', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12), textAlign: TextAlign.center), const SizedBox(height: 15), Row(mainAxisAlignment: MainAxisAlignment.center, textDirection: TextDirection.rtl, children: [const Text('الكاش المتاح: ', style: TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 13)), Text('\$${_formatWithCommas(player.cash)}', textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Changa', fontSize: 13, fontWeight: FontWeight.bold))]), const SizedBox(height: 10), TextField(controller: amountController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontFamily: 'Changa'), textAlign: TextAlign.center, decoration: InputDecoration(hintText: 'مبلغ المكافأة...', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.deepOrange)))), const SizedBox(height: 15), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withOpacity(0.5))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.visibility_off, color: Colors.amber, size: 18), SizedBox(width: 5), Text('إخفاء الاسم (5 ذهب)', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 12))]), Switch(value: isAnonymous, activeColor: Colors.amber, onChanged: (val) { setDialogState(() => isAnonymous = val); })])), if (isProcessing) ...[const SizedBox(height: 20), const CircularProgressIndicator(color: Colors.deepOrange)]]),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(onPressed: isProcessing ? null : () => Navigator.pop(c), child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa'))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: isProcessing ? null : () async {
                    int? amount = int.tryParse(amountController.text.trim());
                    if (amount == null || amount < 1000) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أقل مبلغ للمكافأة هو 1000!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent)); return; }
                    if (amount > player.cash) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيدك لا يكفي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent)); return; }
                    if (isAnonymous && player.gold < 5) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافي لإخفاء هويتك!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.redAccent)); return; }
                    setDialogState(() => isProcessing = true);
                    try {
                      player.removeCash(amount, reason: 'إعلان مكافأة على ${playerData!['playerName']}');
                      if (isAnonymous) player.removeGold(5);
                      await FirebaseFirestore.instance.collection('chat').add({'type': 'bounty', 'senderUid': player.uid, 'senderName': isAnonymous ? 'شخص مجهول 🕵️‍♂️' : player.playerName, 'targetUid': widget.targetUid, 'targetName': playerData!['playerName'], 'targetPicUrl': playerData!['profilePicUrl'], 'amount': amount, 'timestamp': FieldValue.serverTimestamp()});
                      if (mounted) { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المكافأة في المدينة بنجاح! 🚨', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green)); Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3'); }
                    } catch (e) { setDialogState(() => isProcessing = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء النشر!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red)); }
                  },
                  child: const Text('نشر الإعلان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                ),
              ],
            );
          }
      ),
    );
  }

  void _showExplanationDialog(BuildContext context, bool isMe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
        title: Text(isMe ? 'شرح ملف الزعيم ℹ️' : 'شرح التفاعل ℹ️', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: isMe ? [
              const Text('👤 هويتك الإجرامية:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const Text('اللقب الخاص بك يمكنك اختياره من خلال شاشة (الألقاب) بعد تحقيق الإنجازات المطلوبة.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              const SizedBox(height: 10),
              const Text('🌟 الامتيازات (شجرة المهارات):', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const Text('كل لقب جديد تفتحه يعطيك (نقطة امتياز واحدة). استخدمها لترقية مهاراتك من شاشة (الامتيازات).', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              const SizedBox(height: 10),
              const Text('⚔️ الإحصائيات القتالية:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const Text('الرسم البياني يوضح إجمالي قوتك (الأساسي + الزيادة من السلاح والدرع والامتيازات). لا يمكن للآخرين رؤيته!', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
            ] : [
              const Text('💬 المراسلة:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const Text('إرسال رسالة خاصة ومباشرة لهذا اللاعب.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              const SizedBox(height: 10),
              const Text('⚔️ الهجوم:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const Text('الدخول في معركة دموية ضده لسرقة أمواله، تأكد من عتادك قبل الهجوم!', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              const SizedBox(height: 10),
              const Text('💸 التحويل:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const Text('إرسال مبلغ مالي من الكاش الخاص بك كهدية أو دعم له.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              const SizedBox(height: 10),
              const Text('🎯 المكافأة:', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const Text('وضع جائزة مالية على رأسه ليقوم باقي اللاعبين بمطاردته والهجوم عليه.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              const SizedBox(height: 10),
              const Text('➕ إضافة:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const Text('إرسال طلب صداقة ليكون من ضمن حلفائك في اللعبة.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً فهمت', style: TextStyle(color: Colors.amber)))],
      ),
    );
  }

  Widget _buildAchievements(Map<String, dynamic> data) {
    List<Map<String, dynamic>> allTitles = _getAllTitlesLocal(data);
    List<Map<String, dynamic>> unlockedTitles = allTitles.where((t) => t['unlocked'] == true).toList();
    String currentTitle = data['selectedTitle'] ?? 'مبتدئ في الشوارع 🚶';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.3))),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          spacing: 10, runSpacing: 10,
          children: unlockedTitles.map((titleData) {
            bool isCurrent = titleData['name'] == currentTitle;

            return Tooltip(
              message: titleData['desc'],
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber, width: 1)),
              textStyle: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 13, fontWeight: FontWeight.bold),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: isCurrent ? Colors.amber.withOpacity(0.2) : Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: isCurrent ? Colors.amber : Colors.white24)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isCurrent ? Icons.military_tech : Icons.emoji_events, color: isCurrent ? Colors.amber : Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(titleData['name'], style: TextStyle(color: isCurrent ? Colors.amber : Colors.white70, fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecordRow(String title, String value, Color valColor, {bool isLtr = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          Directionality(
            textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
            child: Text(value, style: TextStyle(color: valColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLabel(String text, Color color) {
    return Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, height: 1.2));
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: SizedBox(
            width: 55,
            child: Column(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))), child: Icon(icon, color: color, size: 20)),
                  const SizedBox(height: 6),
                  Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)
                ]
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context);

    if (playerData == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.amber)));

    bool isMe = widget.targetUid == player.uid;
    bool isVIP = playerData!['isVIP'] == true;

    // 🟢 نظام ذكي لقراءة الصورة: إذا كانت رابط يحملها من النت، وإذا كانت Base64 يفك تشفيرها
    ImageProvider? getProfileImageProvider(String? url) {
      if (url == null || url.isEmpty) return null;
      if (url.startsWith('http')) return NetworkImage(url);
      final bytes = player.getDecodedImage(url);
      return bytes != null ? MemoryImage(bytes) : null;
    }

    ImageProvider? profileImage = getProfileImageProvider(isMe ? player.profilePicUrl : playerData!['profilePicUrl']);
    ImageProvider? backgroundImage = getProfileImageProvider(isMe ? player.backgroundPicUrl : playerData!['backgroundPicUrl']);

    bool isOnline = false;
    if (isMe) {
      isOnline = true;
    } else if (playerData!['lastUpdate'] != null) {
      DateTime lastUpdate = (playerData!['lastUpdate'] is Timestamp) ? (playerData!['lastUpdate'] as Timestamp).toDate() : DateTime.parse(playerData!['lastUpdate'].toString());
      if (DateTime.now().difference(lastUpdate).inMinutes < 5) isOnline = true;
    }

    bool isHosp = playerData!['isHospitalized'] == true;
    bool isPris = playerData!['isInPrison'] == true;
    String currentCity = playerData!['currentCity'] ?? 'ملاذ';

    String locationText = '📍 $currentCity';
    Color locColor = Colors.tealAccent;
    Color locBg = Colors.teal.withOpacity(0.2);
    Color locBorder = Colors.teal.withOpacity(0.4);

    if (isHosp) { locationText = '🏥 مستشفى $currentCity'; locColor = Colors.redAccent; locBg = Colors.red.withOpacity(0.2); locBorder = Colors.red.withOpacity(0.4); }
    else if (isPris) { locationText = '🔒 سجن $currentCity'; locColor = Colors.grey; locBg = Colors.grey.withOpacity(0.2); locBorder = Colors.grey.withOpacity(0.4); }

    int pvpWins = playerData!['pvpWins'] ?? 0;
    int totalStolen = playerData!['totalStolenCash'] ?? 0;
    int totalCrimes = 0;
    if (playerData!['crimeSuccessCountsMap'] != null) {
      (playerData!['crimeSuccessCountsMap'] as Map).forEach((k, v) => totalCrimes += (v as int));
    }

    String playerTitle = playerData!['selectedTitle'] ?? 'مبتدئ في الشوارع 🚶';

    double bStr = playerData!['baseStrength'] ?? 5.0;
    double pStr = playerData!['bonusStrength'] ?? 0.0;
    double bDef = playerData!['baseDefense'] ?? 5.0;
    double pDef = playerData!['bonusDefense'] ?? 0.0;
    double bSpd = playerData!['baseSpeed'] ?? 5.0;
    double pSpd = playerData!['bonusSpeed'] ?? 0.0;
    double bSkl = playerData!['baseSkill'] ?? 5.0;
    double pSkl = playerData!['bonusSkill'] ?? 0.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/ui/crime_bg.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: isMe ? 20 : 160),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(isMe ? 'ملف الزعيم 👑' : 'الملف الإجرامي 🕵️‍♂️', style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),

                    // 1. الترويسة
                    GestureDetector(
                      onLongPress: isMe ? () => _pickBackgroundImage(player) : null,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                          decoration: BoxDecoration(color: const Color(0xFF1E1E1E).withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: isVIP ? Colors.amber.withOpacity(0.4) : Colors.white10), image: backgroundImage != null ? DecorationImage(image: backgroundImage, fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken)) : null),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: isMe ? () => _pickImage(player) : null,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFF212121), shape: BoxShape.circle, border: isVIP ? Border.all(color: Colors.amberAccent, width: 3) : null, boxShadow: isVIP ? [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)] : [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]), child: CircleAvatar(radius: 40, backgroundColor: Colors.grey[800], backgroundImage: profileImage, child: profileImage == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, size: 45, color: isVIP ? Colors.amber : Colors.white54) : null)),
                                    Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Color(0xFF1A1A1D), shape: BoxShape.circle), child: CircleAvatar(radius: 7, backgroundColor: isOnline ? Colors.greenAccent : Colors.redAccent))),
                                    if (isMe) const Positioned(top: 0, left: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.amber, child: Icon(Icons.camera_alt, size: 14, color: Colors.black)))
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [if (isVIP) const Icon(Icons.workspace_premium, color: Colors.amber, size: 24), if (isVIP) const SizedBox(width: 5), Flexible(child: Text(playerData!['playerName'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]), overflow: TextOverflow.ellipsis))]),

                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(playerTitle, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    Wrap(
                                      spacing: 8, runSpacing: 8,
                                      children: [
                                        GestureDetector(
                                          onTap: () { if (playerData!['gangName'] != null) { audio.playEffect('click.mp3'); Navigator.push(context, MaterialPageRoute(builder: (_) => PublicGangProfileView(gangName: playerData!['gangName']))); } },
                                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withOpacity(0.5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(playerData!['gangName'] != null ? 'عصابة: ${playerData!['gangName']}' : 'ذئب وحيد', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)), if (playerData!['gangName'] != null) const SizedBox(width: 4), if (playerData!['gangName'] != null) const Icon(Icons.touch_app, color: Colors.orangeAccent, size: 12)])),
                                        ),
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: locBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: locBorder)), child: Text(locationText, style: TextStyle(color: locColor, fontSize: 12, fontWeight: FontWeight.bold))),
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withOpacity(0.4))), child: Text('السكن: ${isMe ? player.currentResidenceName : (playerData!['activePropertyId'] != null ? 'عقار خاص' : 'غير معروف')}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe) GestureDetector(onTap: () => _pickBackgroundImage(player), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: const Icon(Icons.wallpaper, color: Colors.white, size: 18))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 2. البايو
                    GestureDetector(
                      onTap: isMe ? () => _editBio(player) : null,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(15),
                        width: double.infinity,
                        decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(0.05) : Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: isMe ? Colors.amber.withOpacity(0.3) : Colors.white10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.end, children: [if (isMe) const Icon(Icons.edit, color: Colors.amber, size: 16), if (isMe) const SizedBox(width: 5), const Text('البايو (الوصف):', style: TextStyle(color: Colors.white54, fontSize: 12))]),
                            const SizedBox(height: 10),
                            Text(playerData!['bio'] ?? 'لا يوجد وصف حالياً...', style: const TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic), textAlign: TextAlign.right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. السجل الإجرامي
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("السجل الإجرامي 📜", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                              child: Column(
                                children: [
                                  _buildRecordRow("عدد الضحايا (الضربة القاضية):", "$pvpWins 💀", Colors.white),
                                  const Divider(color: Colors.white24),
                                  _buildRecordRow("إجمالي الجرائم الناجحة:", "$totalCrimes 🚨", Colors.white),
                                  const Divider(color: Colors.white24),
                                  _buildRecordRow("أموال مسروقة من اللاعبين:", "\$${_formatWithCommas(totalStolen)}", Colors.greenAccent, isLtr: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 4. الإحصائيات القتالية (تظهر فقط إذا كان بروفايلك)
                    if (isMe) ...[
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Align(alignment: Alignment.centerRight, child: Text("الإحصائيات القتالية ⚔️", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)))),
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 15),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                        child: Center(
                          child: SizedBox(
                            width: 200, height: 200,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(160, 160),
                                  painter: RadarPainter(str: bStr+pStr, spd: bSpd+pSpd, def: bDef+pDef, skl: bSkl+pSkl),
                                ),
                                Positioned(top: -30, child: _buildStatLabel("قوة\n${(bStr+pStr).toStringAsFixed(1)}", Colors.redAccent)),
                                Positioned(bottom: -30, child: _buildStatLabel("دفاع\n${(bDef+pDef).toStringAsFixed(1)}", Colors.blueAccent)),
                                Positioned(left: -35, child: _buildStatLabel("سرعة\n${(bSpd+pSpd).toStringAsFixed(1)}", Colors.orangeAccent)),
                                Positioned(right: -35, child: _buildStatLabel("مهارة\n${(bSkl+pSkl).toStringAsFixed(1)}", Colors.greenAccent)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],

                    // 5. الألقاب المكتسبة (تظهر فقط للآخرين، ومخفية من شاشتك)
                    if (!isMe) ...[
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Align(alignment: Alignment.centerRight, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text("اضغط على أي لقب لمعرفة تفاصيله 👆", style: TextStyle(color: Colors.white54, fontSize: 10)), SizedBox(width: 10), Text("الألقاب المكتسبة 🏆", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14))]))),
                      const SizedBox(height: 10),
                      _buildAchievements(playerData!),
                      const SizedBox(height: 25),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 6. الأزرار التفاعلية العائمة (تظهر فقط إذا كان بروفايل شخص ثاني)
          if (!isMe)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.95),
                  border: const Border(top: BorderSide(color: Colors.amber, width: 1)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Wrap(
                  spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                  children: [
                    _buildActionBtn(Icons.person_add, 'إضافة', Colors.blue, () => player.sendFriendRequest(widget.targetUid)),
                    _buildActionBtn(Icons.chat, 'مراسلة', Colors.green, () { Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatView(targetUid: widget.targetUid, targetName: playerData!['playerName'] ?? 'مجهول', targetPicUrl: playerData!['profilePicUrl']))); }),
                    _buildActionBtn(Icons.my_location, 'هجوم', Colors.red, () {
                      if (!playerData!.containsKey('uid') || playerData!['uid'] == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري التحميل...'))); return; }
                      if (isHosp) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب في المستشفى 🏥', style: TextStyle(fontFamily: 'Changa')))); return; }
                      if (isPris) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب في السجن 🔒', style: TextStyle(fontFamily: 'Changa')))); return; }
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, body: SafeArea(child: PvpBattleView(enemyData: playerData!, onBack: () => Navigator.pop(context))))));
                    }),
                    _buildActionBtn(Icons.attach_money, 'تحويل', Colors.amber, () => _showTransferDialog(player)),
                    _buildActionBtn(Icons.track_changes, 'مكافأة', Colors.deepOrange, () => _showBountyDialog(player)),
                    _buildActionBtn(Icons.card_giftcard, 'هدية', Colors.pinkAccent, () {}),
                    _buildActionBtn(Icons.favorite, 'زواج', Colors.pink, () {}),
                    _buildActionBtn(Icons.block, 'حظر', Colors.grey, () {}),
                  ],
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
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
                    if(widget.onBack != null) widget.onBack!();
                    else Navigator.pop(context);
                  },
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_forward_ios, color: Color(0xFFE2C275), size: 24), SizedBox(height: 4), Text('رجوع', style: TextStyle(color: Color(0xFFE2C275), fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                ),

                // 🟢 زر الألقاب 🟢
                if (isMe)
                  GestureDetector(
                    onTap: () {
                      audio.playEffect('click.mp3');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TitlesView(playerData: playerData!, isMe: isMe, allTitles: player.getAllTitles())));
                    },
                    child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.emoji_events, color: Colors.blueAccent, size: 28), SizedBox(height: 4), Text('الألقاب', style: TextStyle(color: Colors.blueAccent, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                  ),

                // 🟢 زر الامتيازات 🟢
                if (isMe)
                  GestureDetector(
                    onTap: () {
                      audio.playEffect('click.mp3');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PerksView()));
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.stars, color: Colors.amber, size: 28), SizedBox(height: 4), Text('الامتيازات', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                        if (player.unspentSkillPoints > 0)
                          Positioned(top: -5, right: -5, child: CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Text('${player.unspentSkillPoints}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),

                // 🟢 زر التسليح 🟢
                if (isMe)
                  GestureDetector(
                    onTap: () {
                      audio.playEffect('click.mp3');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ArmoryView()));
                    },
                    child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield, color: Colors.redAccent, size: 28),
                          SizedBox(height: 4),
                          Text('التسليح', style: TextStyle(color: Colors.redAccent, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))
                        ]
                    ),
                  ),

                GestureDetector(
                  onTap: () { audio.playEffect('click.mp3'); _showExplanationDialog(context, isMe); },
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book, color: Colors.white70, size: 24), SizedBox(height: 4), Text('شرح', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}