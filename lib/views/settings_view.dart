import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../main.dart'; // للوصول إلى AuthWrapper

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {

  Future<void> _deleteAccount(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.red, width: 2)
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('تحذير خطير!', style: TextStyle(color: Colors.red, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟\n\nسيتم مسح جميع بياناتك، أموالك، وتقدمك في "حرب النفوذ" ولا يمكن التراجع عن هذا الإجراء أبداً.',
            style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، احذف حسابي', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red))
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. حذف اللاعب من قاعدة البيانات
        await FirebaseFirestore.instance.collection('players').doc(user.uid).delete();

        // 2. حذف المستخدم من المصادقة وتسجيل الخروج
        await user.delete();
        await FirebaseAuth.instance.signOut();

        // 3. مسح الكاش من ذاكرة الجوال
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // 4. تصفير الذاكرة الحية (البروفايدر) 🟢 (هذا هو الحل لمشكلتك)
        if (context.mounted) {
          Provider.of<PlayerProvider>(context, listen: false).resetPlayerData();
        }

        if (context.mounted) Navigator.pop(context); // إغلاق التحميل

        // 5. إرجاع اللاعب لشاشة البداية (تسجيل الدخول) وإغلاق كل الشاشات السابقة
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لدواعي أمنية، يرجى تسجيل الخروج ثم الدخول مجدداً قبل محاولة حذف الحساب.', style: TextStyle(fontFamily: 'Changa')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: ${e.message}', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
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
        backgroundColor: Colors.black, // لون خلفية الشاشة
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
              // يمكنك إضافة إعدادات أخرى هنا مستقبلاً (مثل الصوت أو الإشعارات)
              const SizedBox(height: 20),

              const Text(
                'إدارة الحساب',
                style: TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),

              // زر حذف الحساب
              SizedBox(
                width: double.infinity, // ليكون الزر بعرض الشاشة
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
                  onPressed: () => _deleteAccount(context), // استدعاء دالة الحذف
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