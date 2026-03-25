import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class QuickRecoveryDialog {
  static void show(BuildContext context, String type, int missingAmount) {
    bool isCourage = type == 'courage';
    String itemName = isCourage ? 'قهوة مركزة ☕' : 'حقنة منشط 💉';
    String itemId = isCourage ? 'coffee' : 'steroids';
    int cost = 50;

    showDialog(
      context: context,
      builder: (context) {
        // نستخدم Consumer عشان النافذة تتحدث فوراً إذا اشترى اللاعب أو استخدم
        return Consumer<PlayerProvider>(
          builder: (context, player, child) {
            bool hasItem = (player.inventory[itemId] ?? 0) > 0;

            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isCourage ? Colors.orange : Colors.yellow, width: 2)
              ),
              title: Row(
                children: [
                  Icon(isCourage ? Icons.bolt : Icons.flash_on, color: isCourage ? Colors.orange : Colors.yellow, size: 28),
                  const SizedBox(width: 10),
                  Text(isCourage ? 'شجاعة غير كافية!' : 'طاقة غير كافية!', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'ينقصك $missingAmount ${isCourage ? 'شجاعة' : 'طاقة'} للقيام بهذه الجريمة.\n\nيمكنك استخدام $itemName لاستعادة المقياس بالكامل فوراً، أو الانتظار قليلاً.',
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                ),
                if (hasItem)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      player.useItem(itemId);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم استخدام $itemName بنجاح! 🚀', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
                      );
                    },
                    child: Text('استخدام (لديك ${player.inventory[itemId]})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCourage ? Colors.orange : Colors.yellow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (player.gold >= cost) {
                        player.buyItem(itemId, cost, isConsumable: true, currency: 'gold');
                        player.useItem(itemId);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم شراء واستخدام $itemName بنجاح! 🚀', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
                        );
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('لا تملك ذهب كافي! تحتاج 50 ذهب.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    child: Text('شراء واستخدام ($cost ذهب)', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}