// المسار: lib/widgets/quick_recovery_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';

class QuickRecoveryDialog {
  static void show(BuildContext context, String type, int amountNeeded) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final player = Provider.of<PlayerProvider>(context, listen: false);
          final audio = Provider.of<AudioProvider>(context, listen: false);

          int cost = 0;
          String title = '';
          String icon = '';
          Color color = Colors.white;
          String itemName = '';

          if (type == 'energy') {
            cost = 100; // يمكنك تعديل السعر حسب توازن لعبتك
            title = 'استعادة الطاقة';
            icon = '⚡';
            color = Colors.amber;
            itemName = 'مشروب طاقة';
          } else if (type == 'courage') {
            cost = 50;
            title = 'استعادة الشجاعة';
            icon = '🔥';
            color = Colors.orangeAccent;
            itemName = 'قهوة مركزة';
          } else if (type == 'health') {
            cost = amountNeeded > 0 ? amountNeeded : 100;
            title = 'علاج سريع';
            icon = '❤️';
            color = Colors.redAccent;
            itemName = 'حقنة إسعافات';
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: color, width: 2)),
              title: Text('$icon $title', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              content: Text('هل تريد شراء واستخدام $itemName مقابل \$$cost كاش؟\n(سيتم استعادة $type بالكامل)', style: const TextStyle(color: Colors.white, fontFamily: 'Changa')),
              actions: [
                // 🟢 زر الإلغاء صار الأول عشان يظهر بنفس ترتيب النادي
                TextButton(
                  onPressed: () {
                    audio.playEffect('click.mp3');
                    Navigator.pop(context);
                  },
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa')),
                ),
                // 🟢 زر التأكيد صار الثاني
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () {
                    audio.playEffect('click.mp3');
                    if (player.cash >= cost) {
                      player.removeCash(cost, reason: 'استخدام $itemName');
                      if (type == 'energy') player.setEnergy(player.maxEnergy);
                      if (type == 'courage') player.setCourage(player.maxCourage);
                      if (type == 'health') player.setHealth(player.maxHealth);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت استعادة $title بنجاح! $icon', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كاش غير كافي!', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('تأكيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                ),
              ],
            ),
          );
        }
    );
  }
}