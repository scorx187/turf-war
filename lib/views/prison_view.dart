import 'package:flutter/material.dart';

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
    return Container(
      color: Colors.black87,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('أنت الآن خلف القضبان! ⛓️',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('حاول ألا تكرر الجريمة مرة أخرى..',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 30),

          // زر دفع الكفالة
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: onBailPaid,
            icon: const Icon(Icons.money_off, color: Colors.black),
            label: const Text('دفع كفالة خروج (1500 كاش)',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}