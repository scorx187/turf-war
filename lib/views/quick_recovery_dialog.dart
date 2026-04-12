// المسار: lib/views/quick_recovery_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/player_provider.dart';

class QuickRecoveryDialog extends StatefulWidget {
  final String type; // 'energy' or 'courage'
  final int missingAmount;

  const QuickRecoveryDialog({
    super.key,
    required this.type,
    required this.missingAmount,
  });

  @override
  State<QuickRecoveryDialog> createState() => _QuickRecoveryDialogState();

  static void show(BuildContext context, String type, int missingAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuickRecoveryDialog(type: type, missingAmount: missingAmount),
    );
  }
}

class _QuickRecoveryDialogState extends State<QuickRecoveryDialog> {
  bool _isLoading = false;

  // 🟢 الاتصال الفعلي بالسيرفر لمنع القلتشات
  Future<void> _recover(PlayerProvider player, bool hasItem, int cost) async {
    setState(() { _isLoading = true; });

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('recoverResource');
      final result = await callable.call({
        'uid': player.uid,
        'type': widget.type,
        'maxCourage': player.maxCourage, // نرسل الحد الأقصى للسيرفر
        'maxEnergy': player.maxEnergy,
      });

      if (result.data['success'] == true) {
        // تحديث الأرقام بالشاشة محلياً كمنظر (السيرفر خلاص حفظها)
        if (widget.type == 'energy') {
          player.setEnergy(player.maxEnergy);
        } else {
          player.setCourage(player.maxCourage);
        }

        if (hasItem) {
          String itemId = widget.type == 'energy' ? 'steroids' : 'coffee';
          if (player.inventory.containsKey(itemId) && player.inventory[itemId]! > 0) {
            player.inventory[itemId] = player.inventory[itemId]! - 1;
          }
        } else {
          player.removeGold(cost);
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاستعادة بنجاح! 🚀', style: TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ السيرفر: ${e.toString()}', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final bool isEnergy = widget.type == 'energy';
    final String title = isEnergy ? "طاقة غير كافية! ⚡" : "شجاعة غير كافية! 🛡️";
    final String itemId = isEnergy ? 'steroids' : 'coffee';
    final String itemName = isEnergy ? 'حقنة منشط' : 'قهوة مركزة';
    final int cost = 50; // 🟢 السعر 50 ذهب
    final int ownedCount = player.inventory[itemId] ?? 0;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isEnergy ? Colors.yellow : Colors.orange, width: 2)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("ينقصك ${widget.missingAmount} ${isEnergy ? 'طاقة' : 'شجاعة'} للقيام بهذه العملية.", style: const TextStyle(color: Colors.white70, fontFamily: 'Changa', fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemName, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("تملك حالياً: $ownedCount", style: const TextStyle(color: Colors.amber, fontFamily: 'Changa', fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(isEnergy ? Icons.medical_services : Icons.coffee, color: isEnergy ? Colors.greenAccent : Colors.brown, size: 30),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: _isLoading
          ? [const CircularProgressIndicator(color: Colors.amber)]
          : [
        if (ownedCount > 0)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => _recover(player, true, cost),
            child: const Text("استخدام الآن", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Changa', color: Colors.white)),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (player.gold >= cost) {
                _recover(player, false, cost);
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافي! ❌', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Changa')), backgroundColor: Colors.redAccent));
              }
            },
            // 🟢 الزر الفخم مع أيقونة الذهب
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("شراء واستخدام (50 ", style: TextStyle(color: Colors.black, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13)),
                Image.asset('assets/images/icons/gold.png', width: 16, height: 16),
                const Text(")", style: TextStyle(color: Colors.black, fontFamily: 'Changa', fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء", style: TextStyle(color: Colors.white54, fontFamily: 'Changa')),
        ),
      ],
    );
  }
}