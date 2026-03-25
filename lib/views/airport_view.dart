import 'package:flutter/material.dart';

class AirportView extends StatelessWidget {
  final int gold;
  final Function(int) onTravel;
  final VoidCallback onBack;

  const AirportView({
    super.key,
    required this.gold,
    required this.onTravel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ds = ['دبي', 'لندن', 'نيويورك'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack),
              const Text('المطار',
                  style: TextStyle(color: Colors.blue, fontSize: 22)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ds.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(ds[index], style: const TextStyle(color: Colors.white)),
              subtitle: const Text('التكلفة: 5 ذهب',
                  style: TextStyle(color: Colors.yellow)),
              onTap: () {
                if (gold >= 5) {
                  onTravel(5);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('سافرت إلى ${ds[index]}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا تملك ذهب كافٍ!')),
                  );
                }
              },
            ),
          ),
        )
      ],
    );
  }
}
