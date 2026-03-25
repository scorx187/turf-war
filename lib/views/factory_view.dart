import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/quick_recovery_dialog.dart';

class FactoryView extends StatelessWidget {
  final VoidCallback onBack;

  const FactoryView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
                    const Text('المصنع المتطور 🏭', style: TextStyle(color: Colors.brown, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildWorkXPBar(player),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'وظائف يومية', icon: Icon(Icons.work)),
              Tab(text: 'عقود عمل', icon: Icon(Icons.description)),
            ],
            indicatorColor: Colors.brown,
            labelColor: Colors.brown,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildJobsList(player),
                _buildContractsList(player),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkXPBar(PlayerProvider player) {
    double progress = player.workXPToNextLevel > 0 ? (player.workXP / player.workXPToNextLevel) : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.brown.withValues(alpha:0.3))
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المستوى المهني: ${player.workLevel}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${player.workXP} / ${player.workXPToNextLevel} XP', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(Colors.brown)),
        ],
      ),
    );
  }

  Widget _buildJobsList(PlayerProvider player) {
    final List<Map<String, dynamic>> jobs = [
      {'id': 'cleaner', 'name': 'عامل نظافة', 'energy': 20, 'reward': 150, 'xp': 15, 'lvl': 1, 'icon': Icons.cleaning_services, 'color': Colors.blueGrey},
      {'id': 'packer', 'name': 'عامل تعبئة', 'energy': 35, 'reward': 300, 'xp': 35, 'lvl': 5, 'icon': Icons.inventory, 'color': Colors.orangeAccent},
      {'id': 'operator', 'name': 'مشغل آلات', 'energy': 45, 'reward': 500, 'xp': 50, 'lvl': 8, 'icon': Icons.settings, 'color': Colors.cyan},
      {'id': 'technician', 'name': 'فني صيانة', 'energy': 55, 'reward': 750, 'xp': 70, 'lvl': 12, 'icon': Icons.build, 'color': Colors.greenAccent},
      {'id': 'inspector', 'name': 'مفتش جودة', 'energy': 65, 'reward': 1000, 'xp': 100, 'lvl': 18, 'icon': Icons.fact_check, 'color': Colors.yellowAccent},
      {'id': 'supervisor', 'name': 'مدير خط إنتاج', 'energy': 80, 'reward': 1500, 'xp': 150, 'lvl': 25, 'icon': Icons.admin_panel_settings, 'color': Colors.redAccent},
    ];

    return ListView.builder(
      itemCount: jobs.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final job = jobs[index];
        bool isLocked = player.workLevel < job['lvl'];
        bool hasEnoughEnergy = player.energy >= job['energy'];

        return Card(
          color: isLocked ? Colors.black26 : Colors.black45,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), 
            side: BorderSide(color: isLocked ? Colors.transparent : (job['color'] as Color).withValues(alpha:0.3))
          ),
          child: ListTile(
            leading: Icon(isLocked ? Icons.lock : job['icon'], color: isLocked ? Colors.grey : job['color']),
            title: Text(job['name'], style: TextStyle(color: isLocked ? Colors.white24 : Colors.white, fontWeight: FontWeight.bold)),
            subtitle: isLocked 
              ? Text('يفتح عند مستوى مهني ${job['lvl']}', style: const TextStyle(color: Colors.redAccent, fontSize: 11))
              : Text('طاقة: ${job['energy']} | ربح: ${job['reward']} كاش', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: isLocked ? null : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              onPressed: () {
                if (!hasEnoughEnergy) {
                  QuickRecoveryDialog.show(context, 'energy', (job['energy'] as int) - player.energy);
                  return;
                }
                player.setEnergy(player.energy - (job['energy'] as int));
                player.addCash(job['reward'], reason: "عمل: ${job['name']}");
                player.addWorkXP(job['xp']);
              },
              child: const Text('عمل'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContractsList(PlayerProvider player) {
    final List<Map<String, dynamic>> contracts = [
      {'name': 'عقد تدريب', 'min': 30, 'salary': 300, 'lvl': 3, 'color': Colors.blue},
      {'name': 'عقد دوام جزئي', 'min': 60, 'salary': 800, 'lvl': 10, 'color': Colors.green},
      {'name': 'عقد دوام كامل', 'min': 180, 'salary': 2500, 'lvl': 20, 'color': Colors.purple},
    ];

    if (player.isUnderContract) {
      final timeLeft = player.contractEndTime != null ? player.contractEndTime!.difference(DateTime.now()) : Duration.zero;
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.brown.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: Colors.brown)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, color: Colors.green, size: 50),
              const SizedBox(height: 10),
              Text('أنت تعمل حالياً تحت: ${player.activeContractName ?? ""}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('يتبقى على انتهاء العقد: ${timeLeft.inMinutes} دقيقة', style: const TextStyle(color: Colors.amber)),
              const SizedBox(height: 20),
              const Text('تستلم راتبك تلقائياً كل دقيقة واحدة 💰', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: contracts.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        bool isLocked = player.workLevel < contract['lvl'];

        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(contract['name'], style: TextStyle(color: isLocked ? Colors.white24 : Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('المدة: ${contract['min']} دقيقة | الراتب: ${contract['salary']}/دقيقة', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            trailing: isLocked 
              ? Text('Lvl ${contract['lvl']}', style: const TextStyle(color: Colors.grey))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => player.startWorkContract(contract['name'], contract['min'], contract['salary']),
                  child: const Text('توقيع'),
                ),
          ),
        );
      },
    );
  }
}
