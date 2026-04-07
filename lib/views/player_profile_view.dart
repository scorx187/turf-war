// المسار: lib/views/player_profile_view.dart

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
        'bio': player.bio,
        'gangName': player.gangName,
        'currentCity': player.currentCity,
        'isHospitalized': player.isHospitalized,
        'isInPrison': player.isInPrison,
        'pvpWins': player.pvpWins,
        'totalStolenCash': player.totalStolenCash,
        'crimeSuccessCountsMap': player.crimeSuccessCountsMap,
        'perks': player.perks,
        'baseStrength': player.baseStrength, 'bonusStrength': player.bonusStrength,
        'baseDefense': player.baseDefense, 'bonusDefense': player.bonusDefense,
        'baseSpeed': player.baseSpeed, 'bonusSpeed': player.bonusSpeed,
        'baseSkill': player.baseSkill, 'bonusSkill': player.bonusSkill,
        'happiness': player.happiness,
        'cash': player.cash,
        'bankBalance': player.bankBalance,
      };
    } else {
      playerData = {
        'playerName': widget.previewName ?? 'جاري التحميل...',
        'gameId': '---',
        'profilePicUrl': widget.previewPicUrl,
        'backgroundPicUrl': null,
        'isVIP': widget.previewIsVIP ?? false,
        'bio': 'جاري تحديث البيانات...',
        'currentCity': 'ملاذ', 'isHospitalized': false, 'isInPrison': false,
        'pvpWins': 0, 'totalStolenCash': 0, 'crimeSuccessCountsMap': {}, 'perks': {},
        'baseStrength': 5.0, 'bonusStrength': 0.0,
        'baseDefense': 5.0, 'bonusDefense': 0.0,
        'baseSpeed': 5.0, 'bonusSpeed': 0.0,
        'baseSkill': 5.0, 'bonusSkill': 0.0,
        'happiness': 0, 'cash': 0, 'bankBalance': 0,
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

  String _getPlayerTitle(Map<String, dynamic> data) {
    int pvp = data['pvpWins'] ?? 0;
    int hap = data['happiness'] ?? 0;
    int cr = 0;
    if (data['crimeSuccessCountsMap'] != null) { (data['crimeSuccessCountsMap'] as Map).forEach((k, v) => cr += (v as int)); }
    int wlth = (data['cash'] ?? 0) + (data['bankBalance'] ?? 0);

    if (pvp >= 200) return 'أسطورة الجريمة 👑🩸';
    if (wlth >= 100000000) return 'حوت المافيا 🐋';
    if (hap >= 4000) return 'إمبراطور المدينة 🏙️';
    if (cr >= 2000) return 'عقل مدبر 🧠';
    if (pvp >= 50) return 'سفاح خطير 🔪';
    if (wlth >= 1000000) return 'مليونير صاعد 💰';
    if (cr >= 500) return 'محترف سطو 🥷';
    if (hap >= 500) return 'رجل أعمال ناجح 💼';
    if (pvp >= 10) return 'قاتل مأجور 🎯';
    return 'مبتدئ في الشوارع 🚶';
  }

  Future<void> _pickImage(PlayerProvider player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => playerData!['profilePicUrl'] = base64Str);
      player.updateProfilePic(base64Str);
    }
  }

  Future<void> _pickBackgroundImage(PlayerProvider player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Str = base64Encode(bytes);
      player.updateBackgroundPic(base64Str);
      setState(() => playerData!['backgroundPicUrl'] = base64Str);
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

  void _showPerksSheet(PlayerProvider player, AudioProvider audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int unspent = player.unspentSkillPoints;
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    const Text('شجرة الامتيازات 🌟', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                    const SizedBox(height: 10),
                    Text('النقاط المتاحة: $unspent', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('أكمل المزيد من الإنجازات للحصول على نقاط (سعادة أعلى، فلوس، جرام، الخ).', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const Divider(color: Colors.white24, height: 30),
                    Expanded(
                      child: ListView.builder(
                        itemCount: GameData.perksList.length,
                        itemBuilder: (context, index) {
                          final perk = GameData.perksList[index];
                          int currentLvl = player.perks[perk['id']] ?? 0;
                          bool isMax = currentLvl >= perk['maxLevel'];

                          return Card(
                            color: Colors.black45,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: currentLvl > 0 ? perk['color'] : Colors.white10)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(backgroundColor: perk['color'].withOpacity(0.2), child: Icon(perk['icon'], color: perk['color'])),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(perk['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        Text(perk['desc'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: List.generate(perk['maxLevel'], (i) => Icon(i < currentLvl ? Icons.star : Icons.star_border, color: i < currentLvl ? Colors.amber : Colors.white24, size: 14)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isMax)
                                    const Text('MAX', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
                                  else
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: unspent > 0 ? Colors.amber : Colors.grey, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                      onPressed: unspent > 0 ? () {
                                        audio.playEffect('click.mp3');
                                        player.upgradePerk(perk['id']);
                                        setModalState(() {});
                                        setState(() {});
                                      } : null,
                                      child: const Text('ترقية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber)),
        title: const Text('شرح ملف الزعيم ℹ️', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('👤 هويتك الإجرامية:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('اختر صورتك ووصفك بعناية لترهب خصومك. اللقب الخاص بك سيتغير كلما حققت إنجازات جديدة.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              SizedBox(height: 10),
              Text('🌟 الامتيازات (شجرة المهارات):', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('كلما كسرت رقماً قياسياً (في السعادة، الفلوس، الجرائم، أو القتال) ستحصل على نقطة مهارة لترقية امتيازاتك.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
              SizedBox(height: 10),
              Text('⚔️ الإحصائيات القتالية:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              Text('الرقم الأبيض هو قوتك الأساسية، والرقم الأخضر هو الزيادة من السلاح والدرع الذي ترتديه!', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Changa')),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً فهمت', style: TextStyle(color: Colors.amber)))],
      ),
    );
  }

  // 🟢 5. دالة بناء الامتيازات النشطة لعرضها في البروفايل 🟢
  Widget _buildActivePerks(Map<String, dynamic> data) {
    Map<String, dynamic> perks = data['perks'] ?? {};
    if (perks.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
        child: const Center(child: Text("لا توجد امتيازات نشطة حالياً.", style: TextStyle(color: Colors.white54, fontSize: 12))),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber.withOpacity(0.3))),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: perks.entries.map((e) {
            final perkId = e.key;
            final level = e.value;
            if (level == 0) return const SizedBox.shrink();

            final perkData = GameData.perksList.firstWhere((p) => p['id'] == perkId, orElse: () => {'name': 'مجهول', 'icon': Icons.star, 'color': Colors.grey});

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: (perkData['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: perkData['color'])
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(perkData['icon'], color: perkData['color'], size: 16),
                  const SizedBox(width: 6),
                  Text('${perkData['name']} (مستوى $level)', style: TextStyle(color: perkData['color'], fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final audio = Provider.of<AudioProvider>(context);

    if (playerData == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.amber)));

    bool isMe = widget.targetUid == player.uid;
    bool isVIP = playerData!['isVIP'] == true;

    Uint8List? profilePicData = player.getDecodedImage(isMe ? player.profilePicUrl : playerData!['profilePicUrl']);
    Uint8List? backgroundPicData = player.getDecodedImage(isMe ? player.backgroundPicUrl : playerData!['backgroundPicUrl']);

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
    String playerTitle = _getPlayerTitle(playerData!);

    double bStr = playerData!['baseStrength'] ?? 5.0;
    double pStr = playerData!['bonusStrength'] ?? 0.0;
    double bDef = playerData!['baseDefense'] ?? 5.0;
    double pDef = playerData!['bonusDefense'] ?? 0.0;
    double bSpd = playerData!['baseSpeed'] ?? 5.0;
    double pSpd = playerData!['bonusSpeed'] ?? 0.0;
    double bSkl = playerData!['baseSkill'] ?? 5.0;
    double pSkl = playerData!['bonusSkill'] ?? 0.0;

    return Scaffold(
      // 🟢 الخلفية الفخمة 🟢
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
          child: SingleChildScrollView(
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
                      decoration: BoxDecoration(color: const Color(0xFF1E1E1E).withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: isVIP ? Colors.amber.withOpacity(0.4) : Colors.white10), image: backgroundPicData != null ? DecorationImage(image: MemoryImage(backgroundPicData), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken)) : null),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: isMe ? () => _pickImage(player) : null,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFF212121), shape: BoxShape.circle, border: isVIP ? Border.all(color: Colors.amberAccent, width: 3) : null, boxShadow: isVIP ? [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)] : [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]), child: CircleAvatar(radius: 40, backgroundColor: Colors.grey[800], backgroundImage: profilePicData != null ? MemoryImage(profilePicData) : null, child: profilePicData == null ? Icon(isVIP ? Icons.workspace_premium : Icons.person, size: 45, color: isVIP ? Colors.amber : Colors.white54) : null)),
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

                                Text(playerTitle, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
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

                // 4. الإحصائيات القتالية
                const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Align(alignment: Alignment.centerRight, child: Text("الإحصائيات القتالية ⚔️", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)))),
                const SizedBox(height: 10),
                Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                    child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildCombatStatDetailed("القوة", bStr, pStr, Icons.fitness_center, Colors.redAccent),
                                    _buildCombatStatDetailed("السرعة", bSpd, pSpd, Icons.speed, Colors.orangeAccent)
                                  ]
                              ),
                              const SizedBox(height: 15),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildCombatStatDetailed("الدفاع", bDef, pDef, Icons.shield, Colors.blueAccent),
                                    _buildCombatStatDetailed("المهارة", bSkl, pSkl, Icons.psychology, Colors.greenAccent)
                                  ]
                              )
                            ]
                        )
                    )
                ),
                const SizedBox(height: 25),

                // 5. الامتيازات النشطة
                const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Align(alignment: Alignment.centerRight, child: Text("الامتيازات النشطة 🌟", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)))),
                const SizedBox(height: 10),
                _buildActivePerks(playerData!),
                const SizedBox(height: 25),

                // 6. الأزرار التفاعلية
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    child: Wrap(
                      spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
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
                      ],
                    ),
                  ),
                const SizedBox(height: 50),
              ],
            ),
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
              children: [
                GestureDetector(
                  onTap: () {
                    audio.playEffect('click.mp3');
                    if(widget.onBack != null) widget.onBack!();
                    else Navigator.pop(context);
                  },
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_forward_ios, color: Color(0xFFE2C275), size: 24), SizedBox(height: 4), Text('رجوع', style: TextStyle(color: Color(0xFFE2C275), fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                ),

                if (isMe)
                  GestureDetector(
                    onTap: () { audio.playEffect('click.mp3'); _showPerksSheet(player, audio); },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.stars, color: Colors.amber, size: 28), SizedBox(height: 4), Text('الامتيازات', style: TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                        if (player.unspentSkillPoints > 0)
                          Positioned(top: -5, right: -5, child: CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Text('${player.unspentSkillPoints}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),

                GestureDetector(
                  onTap: () { audio.playEffect('click.mp3'); _showExplanationDialog(context); },
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book, color: Colors.white70, size: 24), SizedBox(height: 4), Text('شرح', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold))]),
                ),
              ],
            ),
          ),
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

  Widget _buildCombatStatDetailed(String label, double base, double bonus, IconData icon, Color color) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Row(
                children: [
                  Text(base.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (bonus > 0) Text(' (+${bonus.toStringAsFixed(1)})', style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) { return GestureDetector(onTap: onTap, child: SizedBox(width: 75, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 6), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]))); }
}