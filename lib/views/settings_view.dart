// المسار: lib/views/settings_view.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // لاستخدام GameColors و GameBackgroundScaffold

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. حذف بيانات اللاعب من Firestore أولاً
        await FirebaseFirestore.instance.collection('players').doc(user.uid).delete();

        // 2. حذف المستخدم من Firebase Auth
        await user.delete();

        // 3. العودة لشاشة تسجيل الدخول
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e - قد تحتاج لتسجيل الدخول مجدداً لحذف الحساب')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameBackgroundScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الإعدادات', style: TextStyle(fontFamily: 'Changa')),
          backgroundColor: Colors.black54,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: GameColors.primary.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.white, fontFamily: 'Changa')),
                  subtitle: const Text('سيتم مسح كل تقدمك في مدينة ملاذ ولا يمكن التراجع', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () => _confirmDelete(context),
                ),
              ),
              const SizedBox(height: 20),
              const Text("نسخة اللعبة: 0.1.0", style: TextStyle(color: Colors.white24)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontFamily: 'Changa')),
        content: const Text('هل أنت متأكد؟ سيتم حذف حسابك وجميع ممتلكاتك فوراً.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(onPressed: () { Navigator.pop(context); _deleteAccount(context); },
              child: const Text('حذف الآن', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}