import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import '../providers/player_provider.dart';
import '../main.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {

  Future<void> _deleteAccount(BuildContext context) async {
    // إظهار رسالة التأكيد
    bool confirm = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteConfirmDialog(),
    ) ?? false;

    if (!confirm) return;

    // إظهار دائرة التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        // 1. تصفير الذاكرة الحية (البروفايدر)
        if (context.mounted) {
          Provider.of<PlayerProvider>(context, listen: false).clearDataOnLogout();
        }

        // 2. مسح الكاش من ذاكرة الجوال
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // 3. 🧹 الحذف الشامل العميق باستخدام Batch
        WriteBatch batch = FirebaseFirestore.instance.batch();

        var notifications = await FirebaseFirestore.instance.collection('notifications').where('uid', isEqualTo: uid).get();
        for (var doc in notifications.docs) batch.delete(doc.reference);

        var publicChats = await FirebaseFirestore.instance.collection('chat').where('uid', isEqualTo: uid).get();
        for (var doc in publicChats.docs) batch.delete(doc.reference);

        var privateChats = await FirebaseFirestore.instance.collection('private_chats').where('participants', arrayContains: uid).get();
        for (var doc in privateChats.docs) batch.delete(doc.reference);

        // هذا السطر يمسح العقارات المعروضة للسوق ولم تُستأجر بعد
        var rentedProperties = await FirebaseFirestore.instance.collection('property_rentals').where('ownerId', isEqualTo: uid).get();
        for (var doc in rentedProperties.docs) batch.delete(doc.reference);

        // مسح الأصدقاء
        // ==========================================
        // 🧹 الحذف الشامل للأصدقاء والطلبات (النسف الشامل)
        // ==========================================

        // 1. إذا كنت تحفظ الأصدقاء في مصفوفات (Arrays) داخل كولكشن players
        try {
          // مسحك من قائمة أصدقاء اللاعبين الآخرين
          var friendsArrays = await FirebaseFirestore.instance.collection('players').where('friends', arrayContains: uid).get();
          for (var doc in friendsArrays.docs) {
            batch.update(doc.reference, {'friends': FieldValue.arrayRemove([uid])});
          }

          // مسح طلبات الصداقة التي أرسلتها وموجودة عند الآخرين
          var requestsArrays = await FirebaseFirestore.instance.collection('players').where('friendRequests', arrayContains: uid).get();
          for (var doc in requestsArrays.docs) {
            batch.update(doc.reference, {'friendRequests': FieldValue.arrayRemove([uid])});
          }

          // مسح الطلبات التي أرسلوها لك وهم ينتظرون ردك
          var sentRequestsArrays = await FirebaseFirestore.instance.collection('players').where('sentRequests', arrayContains: uid).get();
          for (var doc in sentRequestsArrays.docs) {
            batch.update(doc.reference, {'sentRequests': FieldValue.arrayRemove([uid])});
          }
        } catch (_) {
          debugPrint('تجاهل أخطاء مصفوفات الأصدقاء');
        }

        // 2. إذا كنت تحفظ الأصدقاء في كولكشن منفصل باستخدام participants
        try {
          var friendsAsParts = await FirebaseFirestore.instance.collection('friends').where('participants', arrayContains: uid).get();
          for (var doc in friendsAsParts.docs) batch.delete(doc.reference);

          var reqAsParts = await FirebaseFirestore.instance.collection('friend_requests').where('participants', arrayContains: uid).get();
          for (var doc in reqAsParts.docs) batch.delete(doc.reference);
        } catch (_) {}

        // 3. إذا كنت تحفظها باستخدام senderId و receiverId (الكود القديم للاحتياط)
        try {
          var fSender = await FirebaseFirestore.instance.collection('friends').where('senderId', isEqualTo: uid).get();
          for (var doc in fSender.docs) batch.delete(doc.reference);

          var fReceiver = await FirebaseFirestore.instance.collection('friends').where('receiverId', isEqualTo: uid).get();
          for (var doc in fReceiver.docs) batch.delete(doc.reference);

          var rSender = await FirebaseFirestore.instance.collection('friend_requests').where('senderId', isEqualTo: uid).get();
          for (var doc in rSender.docs) batch.delete(doc.reference);

          var rReceiver = await FirebaseFirestore.instance.collection('friend_requests').where('receiverId', isEqualTo: uid).get();
          for (var doc in rReceiver.docs) batch.delete(doc.reference);
        } catch (_) {}
        // ==========================================

        // 🟢 الجديد: مصادرة العقارات المؤجرة للبنك المركزي (حماية المستأجرين)
        try {
          var renters = await FirebaseFirestore.instance.collection('players')
              .where('activeRentedProperty.ownerId', isEqualTo: uid).get();

          for (var doc in renters.docs) {
            batch.update(doc.reference, {
              'activeRentedProperty.ownerName': 'البنك المركزي 🏛️', // يظهر للمستأجر أن البنك هو المالك
              'activeRentedProperty.ownerId': 'bank_system', // آيدي وهمي لفك الارتباط
            });
          }
        } catch (_) {}

        await batch.commit();

        // 4. حذف بيانات اللاعب الأساسية
        await FirebaseFirestore.instance.collection('players').doc(uid).delete();

        // 5. محاولة حذف المستخدم من المصادقة
        try {
          await user.delete();
        } catch (e) {
          debugPrint('تم تجاهل خطأ حذف المصادقة');
        }

        // 6. فصل ارتباط جوجل
        try {
          final googleSignIn = GoogleSignIn();
          await googleSignIn.disconnect();
        } catch (_) {
          try {
            await GoogleSignIn().signOut();
          } catch (_) {}
        }

        // 7. تسجيل الخروج من فايربيز
        await FirebaseAuth.instance.signOut();

        // 8. التوجيه الفوري لشاشة البداية
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع: $e', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('الإعدادات', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.grey[900],
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'إدارة الحساب',
                style: TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text(
                    'حذف الحساب والبيانات نهائياً',
                    style: TextStyle(fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () => _deleteAccount(context),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                '* ملاحظة: هذا الإجراء مطلوب حسب سياسات متجر جوجل بلاي ولا يمكن التراجع عنه.',
                style: TextStyle(color: Colors.white38, fontFamily: 'Changa', fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({Key? key}) : super(key: key);

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: const Row(
          children: [
            Text('تحذير !', style: TextStyle(color: Colors.red, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟\n\nسيتم مسح جميع بياناتك، أموالك، أصدقائك، وتقدمك في "حرب النفوذ" ولا يمكن التراجع عن هذا الإجراء أبداً.',
          style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16),
        ),
        actions: [
          // 🟢 زر التأكيد على اليمين (لأنه العنصر الأول في اتجاه اليمين لليسار)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _secondsLeft > 0 ? Colors.grey[600] : Colors.red[800],
            ),
            onPressed: _secondsLeft > 0 ? null : () => Navigator.pop(context, true),
            child: Text(
              _secondsLeft > 0 ? 'نعم، احذف حسابي ($_secondsLeft)' : 'نعم، احذف حسابي',
              style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold),
            ),
          ),
          // زر الإلغاء على اليسار
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 16)),
          ),
        ],
      ),
    );
  }
}