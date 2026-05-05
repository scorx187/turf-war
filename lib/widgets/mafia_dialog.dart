// المسار: lib/widgets/mafia_dialog.dart

import 'package:flutter/material.dart';
import 'mafia_button.dart';

class MafiaDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String confirmText;
  final String cancelText;

  const MafiaDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
    this.confirmText = 'تأكيد',
    this.cancelText = 'إلغاء',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // نخفي لون فلاتر الافتراضي
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/ui/dialog_bg.png'), // خلفية المافيا الفخمة
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 15, spreadRadius: 5)
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min, // عشان النافذة تاخذ طول المحتوى بس
            children: [
              // 🟢 الجزء العلوي: العنوان + زر الإغلاق X 🟢
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancel,
                    child: Image.asset(
                      'assets/images/ui/btn_close.png',
                      width: 28, height: 28,
                      errorBuilder: (c,e,s) => const Icon(Icons.close, color: Colors.redAccent, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🟢 الفاصل الزخرفي 🟢
              Image.asset(
                'assets/images/ui/divider.png',
                height: 12, width: double.infinity, fit: BoxFit.contain,
                errorBuilder: (c,e,s) => const Divider(color: Colors.amber, thickness: 1),
              ),
              const SizedBox(height: 15),

              // 🟢 محتوى النافذة (النصوص أو الأرقام) 🟢
              content,

              const SizedBox(height: 25),

              // 🟢 أزرار المافيا (تأكيد / إلغاء) 🟢
              Row(
                children: [
                  Expanded(
                    child: MafiaButton(
                      label: cancelText,
                      isPrimary: false, // زر ثانوي رمادي
                      onPressed: onCancel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MafiaButton(
                      label: confirmText,
                      isPrimary: true, // زر أساسي بارز
                      onPressed: () {
                        onCancel(); // نقفل النافذة أول
                        onConfirm(); // بعدين ننفذ أمر الشراء
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}