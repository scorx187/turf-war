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
          bool useGold = false;
          String title = '';
          String icon = '';
          Color color = Colors.white;
          String itemName = '';
          String itemId = ''; // 🟢 معرف العنصر في المخزن

          if (type == 'energy') {
            cost = 50;
            useGold = true; // 🟢 استعادة الطاقة صارت تكلف ذهب
            title = 'استعادة الطاقة';
            icon = '⚡';
            color = Colors.amber;
            itemName = 'مشروب طاقة';
            itemId = 'energy_drink'; // اسم العنصر بالداتا بيز
          } else if (type == 'courage') {
            cost = 50;
            useGold = false; // الشجاعة تكلف كاش (يمكنك تغييرها لاحقاً إذا حبيت)
            title = 'استعادة الشجاعة';
            icon = '🔥';
            color = Colors.orangeAccent;
            itemName = 'قهوة مركزة';
            itemId = 'coffee';
          } else if (type == 'health') {
            cost = amountNeeded > 0 ? amountNeeded : 100;
            useGold = false;
            title = 'علاج سريع';
            icon = '❤️';
            color = Colors.redAccent;
            itemName = 'حقنة إسعافات';
            itemId = 'medkit';
          }

          // 🟢 فحص ذكي للمخزن
          int itemAmount = player.inventory[itemId] ?? 0;
          bool hasItem = itemAmount > 0;

          // 🟢 تغيير النص بناءً على توفر العنصر
          String contentText = hasItem
              ? 'لديك ($itemAmount) $itemName في المخزن.\nهل تريد استخدام واحد لاستعادة $title بالكامل؟'
              : (useGold
              ? 'لا تملك $itemName في المخزن!\nهل تريد الشراء والاستخدام الفوري مقابل $cost ذهب؟'
              : 'لا تملك $itemName في المخزن!\nهل تريد الشراء والاستخدام الفوري مقابل \$$cost كاش؟');

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: color, width: 2)),
              title: Text('$icon $title', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              content: Text(contentText, style: const TextStyle(color: Colors.white, fontFamily: 'Changa')),
              actions: [
                // 🟢 زر الشراء / الاستخدام
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () {
                    audio.playEffect('click.mp3');

                    if (hasItem) {
                      // 1. خصم العنصر من المخزن
                      player.inventory[itemId] = player.inventory[itemId]! - 1;
                      if (player.inventory[itemId] == 0) player.inventory.remove(itemId);

                      // 2. تحديث الإحصائيات (هذه الدوال تلقائياً تحفظ بيانات المخزن الجديدة في فايربيس)
                      if (type == 'energy') player.setEnergy(player.maxEnergy);
                      if (type == 'courage') player.setCourage(player.maxCourage);
                      if (type == 'health') player.setHealth(player.maxHealth);

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استخدام $itemName بنجاح! $icon', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                    } else {
                      // في حال عدم وجود العنصر -> الشراء بالعملة
                      if (useGold) {
                        if (player.gold >= cost) {
                          player.removeGold(cost); // يخصم الذهب ويحفظ في فايربيس
                          if (type == 'energy') player.setEnergy(player.maxEnergy);
                          if (type == 'courage') player.setCourage(player.maxCourage);
                          if (type == 'health') player.setHealth(player.maxHealth);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الشراء والاستخدام بنجاح! $icon', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                        } else {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذهب غير كافي!', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
                        }
                      } else {
                        if (player.cash >= cost) {
                          player.removeCash(cost, reason: 'شراء واستخدام $itemName');
                          if (type == 'energy') player.setEnergy(player.maxEnergy);
                          if (type == 'courage') player.setCourage(player.maxCourage);
                          if (type == 'health') player.setHealth(player.maxHealth);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الشراء والاستخدام بنجاح! $icon', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                        } else {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كاش غير كافي!', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
                        }
                      }
                    }
                  },
                  child: Text(hasItem ? 'استخدام الآن' : 'شراء واستخدام', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                ),
                // 🟢 زر الإلغاء
                TextButton(
                  onPressed: () {
                    audio.playEffect('click.mp3');
                    Navigator.pop(context);
                  },
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white54, fontFamily: 'Changa')),
                ),
              ],
            ),
          );
        }
    );
  }
}