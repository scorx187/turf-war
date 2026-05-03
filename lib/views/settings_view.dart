import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/player_provider.dart';
import '../main.dart';
import '../utils/crime_data.dart';

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

        // 3. رمي المهمة الثقيلة على السيرفر ليتخطى كل قواعد الحماية وينسف الداتا
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deletePlayerAccount');
        await callable.call({'uid': uid});

        // 4. فصل ارتباط جوجل وتسجيل الخروج محلياً
        try {
          final googleSignIn = GoogleSignIn();
          await googleSignIn.disconnect();
        } catch (_) {
          try {
            await GoogleSignIn().signOut();
          } catch (_) {}
        }

        await FirebaseAuth.instance.signOut();

        // 5. التوجيه الفوري لشاشة البداية
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
          SnackBar(content: Text('خطأ في السيرفر أثناء الحذف: $e', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red),
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

              const SizedBox(height: 24),
              const Text(
                'أدوات المطور',
                style: TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),

              // 🟢 زر أدوات المطور الجديد لفتح وإغلاق الجرائم للتجربة 🟢
              Consumer<PlayerProvider>(
                  builder: (context, player, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: player.isDevModeUnlocked ? Colors.green[800] : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(
                            player.isDevModeUnlocked ? Icons.lock_open : Icons.lock,
                            color: Colors.amber
                        ),
                        label: Text(
                          player.isDevModeUnlocked ? 'إغلاق وضع المطور (تفعيل الأقفال)' : 'فتح جميع الجرائم للتجربة (مطور)',
                          style: const TextStyle(fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        onPressed: () {
                          player.toggleDevMode();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                player.isDevModeUnlocked
                                    ? 'تم فتح جميع الجرائم للتجربة 🔓'
                                    : 'تم إعادة الأقفال لوضعها الطبيعي 🔒',
                                style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: player.isDevModeUnlocked ? Colors.green : Colors.orange,
                            ),
                          );
                        },
                      ),
                    );
                  }
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog();

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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 16)),
          ),
        ],
      ),
    );
  }
}