// المسار: lib/widgets/quick_recovery_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../services/inventory_service.dart'; // 🟢 استدعاء خدمة المخزن
import '../services/black_market_service.dart'; // 🟢 استدعاء خدمة المتجر الأسود

class QuickRecoveryDialog {
  static void show(BuildContext context, String type, int amountNeeded) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return _QuickRecoveryDialogContent(type: type, amountNeeded: amountNeeded);
        }
    );
  }
}

// 🟢 حولناها إلى StatefulWidget عشان نقدر نعرض شاشة التحميل (Loading)
class _QuickRecoveryDialogContent extends StatefulWidget {
  final String type;
  final int amountNeeded;

  const _QuickRecoveryDialogContent({required this.type, required this.amountNeeded});

  @override
  State<_QuickRecoveryDialogContent> createState() => _QuickRecoveryDialogContentState();
}

class _QuickRecoveryDialogContentState extends State<_QuickRecoveryDialogContent> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    int cost = 0;
    bool useGold = false;
    String title = '';
    String icon = '';
    Color color = Colors.white;
    String itemName = '';
    String itemId = '';

    // 🟢 ربطنا الآيديهات والأسعار الصحيحة بقاعدة البيانات
    if (widget.type == 'energy') {
      cost = 50;
      useGold = true;
      title = 'استعادة الطاقة';
      icon = '⚡';
      color = Colors.amber;
      itemName = 'حقنة منشط';
      itemId = 'steroids'; // 🟢 الـ ID الصحيح بالداتا بيز
    } else if (widget.type == 'courage') {
      cost = 50;
      useGold = true; // الشجاعة صارت بذهب حسب المتجر الأسود
      title = 'استعادة الشجاعة';
      icon = '🔥';
      color = Colors.orangeAccent;
      itemName = 'قهوة مركزة';
      itemId = 'coffee';
    } else if (widget.type == 'health') {
      cost = 2500; // سعر حقنة الإسعافات كاش
      useGold = false;
      title = 'علاج سريع';
      icon = '❤️';
      color = Colors.redAccent;
      itemName = 'حقنة إسعافات';
      itemId = 'medkit';
    }

    int itemAmount = player.inventory[itemId] ?? 0;
    bool hasItem = itemAmount > 0;

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
        content: isLoading
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Colors.amber))) // 🟢 مؤشر التحميل
            : Text(contentText, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', height: 1.5)),
        actions: isLoading ? [] : [
          // 🟢 زر الشراء / الاستخدام
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () async {
              audio.playEffect('click.mp3');
              setState(() => isLoading = true); // تشغيل مؤشر التحميل

              try {
                if (!hasItem) {
                  // 1. إذا ما عنده العنصر، نشتريه أولاً من السيرفر
                  await BlackMarketService().buyItem(
                      uid: player.uid!,
                      itemId: itemId,
                      cost: cost,
                      currencyType: useGold ? 'gold' : 'cash',
                      amount: 1
                  );

                  // خصم محلي مؤقت للفلوس عشان تتحدث الشاشة فوراً
                  if (useGold) {
                    player.removeGold(cost);
                  } else {
                    player.removeCash(cost, reason: 'شراء سريع $itemName');
                  }
                }

                // 2. استهلاك العنصر من السيرفر (هنا السيرفر بيعبي طاقتك رسمياً 100%)
                await InventoryService().consumeItem(uid: player.uid!, itemId: itemId);

                // 3. التحديثات المحلية في الواجهة عشان تختفي النافذة واللاعب يقدر يتدرب طوالي
                if (hasItem) {
                  player.inventory[itemId] = player.inventory[itemId]! - 1;
                  if (player.inventory[itemId] == 0) player.inventory.remove(itemId);
                }

                if (widget.type == 'energy') player.setEnergy(player.maxEnergy);
                if (widget.type == 'courage') player.setCourage(player.maxCourage);
                if (widget.type == 'health') player.setHealth(player.maxHealth);

                if (mounted) {
                  Navigator.pop(context); // إغلاق النافذة
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استعادة $title بنجاح! $icon', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  setState(() => isLoading = false);
                  // 🟢 تنظيف رسالة الخطأ
                  String errorMsg = e.toString().replaceAll('Exception: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $errorMsg', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
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
}