// المسار: lib/views/gang_donation_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/top_bar.dart';

class GangDonationView extends StatefulWidget {
  const GangDonationView({super.key});

  @override
  State<GangDonationView> createState() => _GangDonationViewState();
}

class _GangDonationViewState extends State<GangDonationView> {
  bool _isGold = false; // التبديل بين كاش وذهب
  double _sliderValue = 0;
  final TextEditingController _amountController = TextEditingController();

  String _formatWithCommas(int number) {
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return number.toString().replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  void _onSliderChanged(double value, double maxLimit) {
    setState(() {
      _sliderValue = value;
      _amountController.text = value.toInt().toString();
    });
  }

  void _onTextChanged(String text, double maxLimit) {
    int val = int.tryParse(text) ?? 0;
    if (val > maxLimit) val = maxLimit.toInt();

    setState(() {
      _sliderValue = val.toDouble();
    });
  }

  void _submitDonation(PlayerProvider player, AudioProvider audio) {
    int amount = _sliderValue.toInt();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح!', style: TextStyle(fontFamily: 'Changa'))));
      return;
    }

    audio.playEffect('click.mp3');

    if (_isGold) {
      if (player.gold >= amount) {
        player.removeGold(amount);
        // نعتبر الذهب الواحد = 10,000 نقطة مساهمة (كمثال)
        player.contributeToGang(amount * 10000);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم التبرع بـ $amount ذهب بنجاح! 🪙', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذهب غير كافي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      }
    } else {
      if (player.cash >= amount) {
        player.contributeToGang(amount);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم التبرع بـ \$${_formatWithCommas(amount)} كاش بنجاح! 💵', style: const TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كاش غير كافي!', style: TextStyle(fontFamily: 'Changa')), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1D),
        body: SafeArea(
          top: false,
          child: Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final audio = Provider.of<AudioProvider>(context, listen: false);
                double maxLimit = _isGold ? player.gold.toDouble() : player.cash.toDouble();

                if (_sliderValue > maxLimit) {
                  _sliderValue = maxLimit;
                  _amountController.text = maxLimit.toInt().toString();
                }

                return Column(
                  children: [
                    TopBar(
                        cash: player.cash, gold: player.gold, energy: player.energy, maxEnergy: player.maxEnergy,
                        courage: player.courage, maxCourage: player.maxCourage, health: player.health, maxHealth: player.maxHealth,
                        prestige: player.prestige, maxPrestige: player.maxPrestige, playerName: player.playerName,
                        profilePicUrl: player.profilePicUrl, level: player.crimeLevel, currentXp: player.crimeXP,
                        maxXp: player.xpToNextLevel, isVIP: player.isVIP
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border(bottom: BorderSide(color: Colors.greenAccent.withOpacity(0.5), width: 2)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.greenAccent, size: 20),
                              onPressed: () { audio.playEffect('click.mp3'); Navigator.pop(context); }
                          ),
                          const Expanded(
                            child: Text('خزينة العصابة 💰', style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text('دعم الصندوق يرفع من شأنك بين أفراد العصابة ويزيد من قوتها في الحروب!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontFamily: 'Changa', fontSize: 14)),
                            const SizedBox(height: 30),

                            // أزرار التبديل (كاش / ذهب)
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () { audio.playEffect('click.mp3'); setState(() { _isGold = false; _sliderValue = 0; _amountController.clear(); }); },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isGold ? Colors.green.withOpacity(0.2) : Colors.black45,
                                        borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                                        border: Border.all(color: !_isGold ? Colors.greenAccent : Colors.white10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.attach_money, color: !_isGold ? Colors.greenAccent : Colors.white54, size: 20),
                                          const SizedBox(width: 5),
                                          Text('تبرع كاش', style: TextStyle(color: !_isGold ? Colors.greenAccent : Colors.white54, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () { audio.playEffect('click.mp3'); setState(() { _isGold = true; _sliderValue = 0; _amountController.clear(); }); },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isGold ? Colors.amber.withOpacity(0.2) : Colors.black45,
                                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                                        border: Border.all(color: _isGold ? Colors.amber : Colors.white10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.monetization_on, color: _isGold ? Colors.amber : Colors.white54, size: 20),
                                          const SizedBox(width: 5),
                                          Text('تبرع ذهب', style: TextStyle(color: _isGold ? Colors.amber : Colors.white54, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // شريط السحب والإدخال
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: _isGold ? Colors.amber.withOpacity(0.5) : Colors.greenAccent.withOpacity(0.5)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('المبلغ المتاح:', style: TextStyle(color: Colors.white70, fontFamily: 'Changa')),
                                      Text(_isGold ? _formatWithCommas(player.gold) : '\$${_formatWithCommas(player.cash)}', textDirection: TextDirection.ltr, style: TextStyle(color: _isGold ? Colors.amber : Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Changa', fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  TextField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                                    textAlign: TextAlign.center,
                                    onChanged: (val) => _onTextChanged(val, maxLimit),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: const TextStyle(color: Colors.white24),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      prefixIcon: Icon(_isGold ? Icons.monetization_on : Icons.attach_money, color: _isGold ? Colors.amber : Colors.greenAccent),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: _isGold ? Colors.amber : Colors.greenAccent,
                                      inactiveTrackColor: Colors.white10,
                                      thumbColor: _isGold ? Colors.amberAccent : Colors.green,
                                      overlayColor: (_isGold ? Colors.amber : Colors.green).withOpacity(0.2),
                                    ),
                                    child: Slider(
                                      value: _sliderValue,
                                      min: 0,
                                      max: maxLimit > 0 ? maxLimit : 1, // لمنع أخطاء التقسيم على صفر
                                      onChanged: maxLimit > 0 ? (val) => _onSliderChanged(val, maxLimit) : null,
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('0', style: TextStyle(color: Colors.white54, fontFamily: 'Changa')),
                                      Text('الكل', style: TextStyle(color: _isGold ? Colors.amber : Colors.greenAccent, fontFamily: 'Changa', fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isGold ? Colors.amber : Colors.greenAccent.shade700,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _submitDonation(player, audio),
                                child: Text(
                                  'تأكيد التبرع',
                                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                );
              }
          ),
        ),
      ),
    );
  }
}