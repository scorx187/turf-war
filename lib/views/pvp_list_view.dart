import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import 'pvp_battle_view.dart';

class PvpListView extends StatefulWidget {
  final VoidCallback onBack;

  const PvpListView({super.key, required this.onBack});

  @override
  State<PvpListView> createState() => _PvpListViewState();
}

class _PvpListViewState extends State<PvpListView> {
  late Future<List<Map<String, dynamic>>> _opponentsFuture;
  Map<String, dynamic>? _selectedEnemy;
  String _activeTab = 'opponents'; // التبويب الفعال: opponents, leaderboard, logs

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    _opponentsFuture = player.fetchRealOpponents();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedEnemy != null) {
      return PvpBattleView(
        enemyData: _selectedEnemy!,
        onBack: () => setState(() => _selectedEnemy = null),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: widget.onBack),
              const Expanded(
                child: Text('ساحة اللاعبين 🌍', style: TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              if (_activeTab == 'opponents')
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => setState(() => _refreshData())),
            ],
          ),
        ),
        // أزرار التنقل العلوية
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton('opponents', 'الخصوم ⚔️', Colors.redAccent),
              _buildTabButton('leaderboard', 'الصدارة 🏆', Colors.amber),
              _buildTabButton('logs', 'الهجمات ⚠️', Colors.blueAccent),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _buildActiveTabContent(),
        ),
      ],
    );
  }

  // تصميم أزرار التبويبات
  Widget _buildTabButton(String tabValue, String title, Color color) {
    bool isActive = _activeTab == tabValue;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha:0.2) : Colors.black54,
          border: Border.all(color: isActive ? color : Colors.white10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(title, style: TextStyle(color: isActive ? color : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  // دالة تحديد الشاشة المعروضة
  Widget _buildActiveTabContent() {
    if (_activeTab == 'leaderboard') return _buildLeaderboard();
    if (_activeTab == 'logs') return _buildAttacksLog();
    return _buildOpponentsList(); // الافتراضي
  }

  // 1. شاشة الخصوم
  Widget _buildOpponentsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _opponentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
        if (snapshot.hasError) return const Center(child: Text("حدث خطأ في جلب اللاعبين", style: TextStyle(color: Colors.red)));

        final opponents = snapshot.data ?? [];
        if (opponents.isEmpty) return const Center(child: Text("لا يوجد لاعبين متاحين حالياً في مستواك.", style: TextStyle(color: Colors.white70)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: opponents.length,
          itemBuilder: (context, index) {
            final enemy = opponents[index];
            return Card(
              color: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.person, color: Colors.white)),
                title: Text(enemy['playerName'] ?? 'لاعب مجهول', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("مستوى الساحة: ${enemy['arenaLevel'] ?? 1}", style: const TextStyle(color: Colors.white70)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => setState(() => _selectedEnemy = enemy),
                  child: const Text("تحدي ⚔️", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. شاشة الصدارة
  Widget _buildLeaderboard() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: player.fetchLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final topPlayers = snapshot.data ?? [];
        if (topPlayers.isEmpty) return const Center(child: Text('لا يوجد لاعبين', style: TextStyle(color: Colors.white)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: topPlayers.length,
          itemBuilder: (context, index) {
            final p = topPlayers[index];
            bool isFirst = index == 0;
            return Card(
              color: isFirst ? Colors.amber.withValues(alpha:0.2) : Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isFirst ? Colors.amber : Colors.white10, width: isFirst ? 2 : 1)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isFirst ? Colors.amber : Colors.grey[700],
                  child: Text('${index + 1}', style: TextStyle(color: isFirst ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(p['playerName'] ?? 'مجهول', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('مستوى الساحة: ${p['arenaLevel'] ?? 1}', style: const TextStyle(color: Colors.white70)),
                trailing: isFirst ? const Icon(Icons.emoji_events, color: Colors.amber, size: 30) : const Icon(Icons.star, color: Colors.white38),
              ),
            );
          },
        );
      },
    );
  }

  // 3. شاشة سجل الهجمات (الجديدة كلياً!)
  Widget _buildAttacksLog() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: player.fetchAttacksLog(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) return const Center(child: Text('لم يهاجمك أحد حتى الآن 🛡️', style: TextStyle(color: Colors.white)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            bool hasAvenged = log['hasAvenged'] ?? false;

            return Card(
              color: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: hasAvenged ? Colors.green.withValues(alpha:0.5) : Colors.redAccent.withValues(alpha:0.5))),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.warning, color: Colors.white)),
                title: Text("هجوم من: ${log['attackerName']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("سرق منك: ${log['stolenAmount']} كاش 💸", style: const TextStyle(color: Colors.white70)),
                trailing: hasAvenged
                    ? const Text("تم الانتقام ✅", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري تتبع الخصم...')));

                    // نجيب بيانات اللي هجم عليك من قاعدة البيانات
                    var enemyData = await player.getPlayerById(log['attackerId']);

                    if (enemyData != null) {
                      // نقفل الهجمة عشان ما تقدر تنتقم منه أكثر من مرة على نفس الهجوم
                      await player.markAsAvenged(log['logId']);
                      // ندخلك حلبة القتال ضده!
                      setState(() => _selectedEnemy = enemyData);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اللاعب هرب ولم نتمكن من العثور عليه!')));
                    }
                  },
                  child: const Text("انتقام ⚔️", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}