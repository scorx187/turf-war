import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class QuickRecoveryDialog extends StatelessWidget {
  final String type; // 'energy' or 'courage'
  final int missingAmount;

  const QuickRecoveryDialog({
    super.key,
    required this.type,
    required this.missingAmount,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    final bool isEnergy = type == 'energy';
    final String title = isEnergy ? "طاقة غير كافية! ⚡" : "شجاعة غير كافية! 🛡️";
    final String itemId = isEnergy ? 'steroids' : 'coffee';
    final String itemName = isEnergy ? 'حقنة منشط' : 'قهوة مركزة';
    final int cost = 50;

    final int ownedCount = player.inventory[itemId] ?? 0;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isEnergy ? Colors.yellow : Colors.orange, width: 2)
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "ينقصك $missingAmount ${isEnergy ? 'طاقة' : 'شجاعة'} للقيام بهذه الجريمة.",
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
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
                    Text(itemName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("تملك حالياً: $ownedCount", style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(isEnergy ? Icons.medical_services : Icons.coffee, color: isEnergy ? Colors.greenAccent : Colors.brown, size: 30),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (ownedCount > 0)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              player.useItem(itemId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاستخدام بنجاح! 🚀', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
            },
            child: const Text("استخدام الآن", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (player.gold >= cost) {
                player.buyItem(itemId, cost, isConsumable: true, currency: 'gold');
                player.useItem(itemId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الشراء والاستخدام بنجاح! 🚀', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا تملك ذهب كافي! ❌', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent));
              }
            },
            child: Text("شراء واستخدام ($cost ذهب)", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء", style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  static void show(BuildContext context, String type, int missingAmount) {
    showDialog(
      context: context,
      builder: (context) => QuickRecoveryDialog(type: type, missingAmount: missingAmount),
    );
  }
}