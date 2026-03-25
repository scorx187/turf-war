import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class PrisonView extends StatelessWidget {
  final DateTime? prisonReleaseTime;
  final int cash;
  final VoidCallback onBailPaid;

  const PrisonView({
    super.key,
    required this.prisonReleaseTime,
    required this.cash,
    required this.onBailPaid,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    int left = prisonReleaseTime != null
        ? prisonReleaseTime!.difference(DateTime.now()).inSeconds
        : 0;
    if (left < 0) left = 0;

    final int bailPrice = player.bailPrice;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.grey),
            const SizedBox(height: 10),
            const Text('أنت الآن خلف القضبان!', 
              style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'الوقت المتبقي: ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.money_off, color: Colors.white),
                label: Text('دفع كفالة ($bailPrice كاش)', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: cash >= bailPrice ? onBailPaid : null,
              ),
            ),
            if (cash < bailPrice)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('تحتاج لـ $bailPrice كاش للخروج!', 
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
