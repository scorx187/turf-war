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
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        // Padding يضمن إن النص ما يلمس الإطار
        padding: const EdgeInsets.only(top: 40, bottom: 25, left: 25, right: 25),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/ui/dialog_bg.png'),
            // 🟢 الحسبة النهائية لنافذة مقاس 400x530 🟢
            centerSlice: Rect.fromLTRB(50, 50, 350, 480),
            fit: BoxFit.fill,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 15, spreadRadius: 5)
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onCancel,
                    child: Image.asset(
                      'assets/images/ui/btn_close.png',
                      width: 30, height: 30,
                      errorBuilder: (c,e,s) => const Icon(Icons.close, color: Colors.redAccent, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa', height: 1.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Image.asset(
                'assets/images/ui/divider.png',
                height: 15, width: double.infinity, fit: BoxFit.contain,
                errorBuilder: (c,e,s) => const Divider(color: Colors.amber, thickness: 1),
              ),
              const SizedBox(height: 15),

              content,

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: MafiaButton(
                      label: confirmText,
                      isPrimary: true,
                      onPressed: () {
                        onCancel();
                        onConfirm();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MafiaButton(
                      label: cancelText,
                      isPrimary: false,
                      onPressed: onCancel,
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