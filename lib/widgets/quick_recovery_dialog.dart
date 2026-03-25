import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class QuickRecoveryDialog extends StatelessWidget {
  final String type; // 'energy' or 'courage'
  final int requiredAmount;

  const QuickRecoveryDialog({
    super.key,
    required this.type,
    required this.requiredAmount,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    final bool isEnergy = type == 'energy';
    final String title = isEnergy ? "نفدت الطاقة! ⚡" : "نفدت الشجاعة! 🛡️";
    final String itemId = isEnergy ? 'steroids' : 'coffee';
    final String itemName = isEnergy ? 'حقنة منشط' : 'قهوة مركزة';

    // التعديل هنا: السعر صار 50 للجميع
    final int itemPrice = 50;
    final int ownedCount = player.inventory[itemId] ?? 0;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amber, width: 1)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "تحتاج إلى $requiredAmount ${isEnergy ? 'طاقة' : 'شجاعة'} إضافية للقيام بهذا العمل.",
            style: const TextStyle(color: Colors.white70),
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
                    Text("تملك حالياً: $ownedCount", style: const TextStyle(color: Colors.amber, fontSize: 12)),
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
            },
            child: const Text("استخدام الآن", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            // التعديل هنا: يشيك على الذهب ويشتري بالذهب
            onPressed: player.gold >= itemPrice ? () {
              player.buyItem(itemId, itemPrice, isConsumable: true, currency: 'gold');
              player.useItem(itemId);
              Navigator.pop(context);
            } : null,
            child: Text("شراء واستخدام ($itemPrice ذهب)", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء", style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  static void show(BuildContext context, String type, int requiredAmount) {
    showDialog(
      context: context,
      builder: (context) => QuickRecoveryDialog(type: type, requiredAmount: requiredAmount),
    );
  }
}