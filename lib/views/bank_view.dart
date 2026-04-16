// المسار: lib/views/bank_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🟢 استدعاء البلوك
import '../providers/player_provider.dart';
import '../providers/market_provider.dart';
import 'package:intl/intl.dart';
import '../controllers/bank_cubit.dart'; // 🟢 استدعاء الكيوبت
import '../controllers/bank_state.dart'; // 🟢 استدعاء الحالة

class BankView extends StatefulWidget {
  final VoidCallback onBack;

  const BankView({
    super.key,
    required this.onBack,
  });

  @override
  State<BankView> createState() => _BankViewState();
}

class _BankViewState extends State<BankView> {
  double _depositSliderValue = 0;
  double _withdrawSliderValue = 0;
  double _loanTakeSliderValue = 0;
  double _loanRepaySliderValue = 0;
  double _goldBuySliderValue = 0;
  double _goldSellSliderValue = 0;
  double _lockedInvestSliderValue = 0;

  final TextEditingController _depositController = TextEditingController(text: '0');
  final TextEditingController _withdrawController = TextEditingController(text: '0');
  final TextEditingController _loanTakeController = TextEditingController(text: '0');
  final TextEditingController _loanRepayController = TextEditingController(text: '0');
  final TextEditingController _goldBuyController = TextEditingController(text: '0');
  final TextEditingController _goldSellController = TextEditingController(text: '0');
  final TextEditingController _lockedInvestController = TextEditingController(text: '0');

  @override
  void dispose() {
    _depositController.dispose();
    _withdrawController.dispose();
    _loanTakeController.dispose();
    _loanRepayController.dispose();
    _goldBuyController.dispose();
    _goldSellController.dispose();
    _lockedInvestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final market = Provider.of<MarketProvider>(context);

    // 🟢 ربط الواجهة بالكيوبت
    return BlocProvider(
      create: (context) => BankCubit(),
      child: BlocConsumer<BankCubit, BankState>(
        listener: (context, state) {
          // 🟢 عرض رسائل النجاح أو الخطأ تلقائياً
          if (state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)),
              backgroundColor: state.isSuccess ? Colors.green : Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          final cubit = context.read<BankCubit>();

          return Stack(
            children: [
              DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: widget.onBack),
                          const Text('بنك المدينة الاحترافي',
                              style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(icon: Icon(Icons.account_balance), text: 'العمليات'),
                        Tab(icon: Icon(Icons.history), text: 'السجل'),
                        Tab(icon: Icon(Icons.monetization_on), text: 'القروض'),
                        Tab(icon: Icon(Icons.trending_up), text: 'بورصة الذهب'),
                      ],
                      indicatorColor: Colors.green,
                      labelColor: Colors.green,
                      unselectedLabelColor: Colors.grey,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildMainOperations(player, cubit), // 🟢 تمرير الكيوبت للدوال
                          _buildTransactionHistory(player),
                          _buildLoanSection(player, cubit),
                          _buildGoldMarket(player, market, cubit),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 🟢 شاشة تحميل تظهر وقت تنفيذ العملية لتمنع التكرار
              if (state.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainOperations(PlayerProvider player, BankCubit cubit) {
    int depAmt = _depositSliderValue.toInt();
    int withAmt = _withdrawSliderValue.toInt();
    int lockAmt = _lockedInvestSliderValue.toInt();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFinancialReportCard(player),
          _buildBalanceCard(player),
          _buildLockedInvestmentSection(player, lockAmt, cubit),

          _buildBankActionCard(
            title: 'إيداع كاش (مجرد حفظ)',
            sliderValue: _depositSliderValue,
            maxValue: player.cash.toDouble(),
            controller: _depositController,
            onSliderChanged: (val) {
              setState(() {
                _depositSliderValue = val;
                _depositController.text = val.toInt().toString();
              });
            },
            onTextChanged: (text) {
              int v = int.tryParse(text) ?? 0;
              if (v > player.cash) v = player.cash;
              setState(() => _depositSliderValue = v.toDouble());
            },
            actionText: 'إيداع $depAmt',
            infoText: 'ضريبة إيداع: 10% | لا توجد أرباح',
            buttonColor: Colors.green,
            onPressed: () {
              if (depAmt > 0) {
                // 🟢 التنفيذ عبر الكيوبت
                cubit.executeTransaction(() async {
                  await Future.sync(() => player.depositToBank(depAmt));
                  if (mounted) setState(() { _depositSliderValue = 0; _depositController.text = '0'; });
                }, 'تم إيداع \$${depAmt} بنجاح!');
              }
            },
          ),

          _buildBankActionCard(
            title: 'سحب كاش',
            sliderValue: _withdrawSliderValue,
            maxValue: player.bankBalance.toDouble(),
            controller: _withdrawController,
            onSliderChanged: (val) {
              setState(() {
                _withdrawSliderValue = val;
                _withdrawController.text = val.toInt().toString();
              });
            },
            onTextChanged: (text) {
              int v = int.tryParse(text) ?? 0;
              if (v > player.bankBalance) v = player.bankBalance;
              setState(() => _withdrawSliderValue = v.toDouble());
            },
            actionText: 'سحب $withAmt',
            infoText: 'سحب مجاني فوري',
            buttonColor: Colors.blueGrey,
            onPressed: () {
              if (withAmt > 0) {
                cubit.executeTransaction(() async {
                  await Future.sync(() => player.withdrawFromBank(withAmt));
                  if (mounted) setState(() { _withdrawSliderValue = 0; _withdrawController.text = '0'; });
                }, 'تم سحب \$${withAmt} بنجاح!');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialReportCard(PlayerProvider player) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('التقرير المالي والائتماني', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildReportRow('السمعة الائتمانية:', '${player.creditScore}', Colors.blueAccent),
          _buildReportRow('حد القرض المتاح:', '${player.maxLoanLimit}', Colors.amber),
          _buildReportRow('إجمالي الديون الحالية:', '-${player.loanAmount}', Colors.redAccent),
          const Divider(color: Colors.white10),
          _buildReportRow('أرباح الاستثمار المتوقعة:', '+${player.lockedProfits}', Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLockedInvestmentSection(PlayerProvider player, int amount, BankCubit cubit) {
    bool isLocked = player.isInvestmentLocked;
    String timeLeftStr = "";
    if (isLocked && player.lockedUntil != null) {
      final diff = player.lockedUntil!.difference(DateTime.now());
      if (diff.isNegative) {
        timeLeftStr = "تجهيز...";
      } else {
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String minutes = twoDigits(diff.inMinutes.remainder(60));
        String seconds = twoDigits(diff.inSeconds.remainder(60));
        timeLeftStr = "$minutes:$seconds";
      }
    }

    double maxVal = player.cash.toDouble() > 0 ? player.cash.toDouble() : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isLocked ? Colors.cyan.withValues(alpha: 0.1) : Colors.black26,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isLocked ? Colors.cyan : Colors.white10)
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الاستثمارات المقيدة', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              if (isLocked) Text('متبقي: $timeLeftStr', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          if (!isLocked) ...[
            const SizedBox(height: 10),
            _buildInvestOption(player, cubit, "سريع", 1, 0.02, Colors.green),
            _buildInvestOption(player, cubit, "متوسط", 3, 0.07, Colors.orange),
            _buildInvestOption(player, cubit, "طويل", 5, 0.15, Colors.redAccent),
            const SizedBox(height: 10),
            Slider(
              value: _lockedInvestSliderValue.clamp(0.0, maxVal),
              min: 0,
              max: maxVal,
              activeColor: Colors.cyan,
              onChanged: (val) {
                setState(() {
                  _lockedInvestSliderValue = val;
                  _lockedInvestController.text = val.toInt().toString();
                });
              },
            ),
            Text('المبلغ المختار: ${_lockedInvestSliderValue.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ] else ...[
            const SizedBox(height: 10),
            Text('المبلغ الأصلي: ${player.lockedBalance}', style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text('أرباح المتوقعة: ${player.lockedProfits}', style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10),
            Text('المجموع عند الاستلام: ${player.lockedBalance + player.lockedProfits}', style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    );
  }

  Widget _buildInvestOption(PlayerProvider player, BankCubit cubit, String name, int mins, double rate, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.2),
            side: BorderSide(color: color),
            minimumSize: const Size(double.infinity, 40)
        ),
        onPressed: _lockedInvestSliderValue > 0 ? () {
          cubit.executeTransaction(() async {
            await Future.sync(() => player.startLockedInvestment(_lockedInvestSliderValue.toInt(), mins, rate));
            if (mounted) setState(() { _lockedInvestSliderValue = 0; _lockedInvestController.text = '0'; });
          }, 'تم تجميد مبلغ الاستثمار بنجاح!');
        } : null,
        child: Text('$name: $mins دقائق (ربح ${(rate * 100).toInt()}%)', style: TextStyle(color: color)),
      ),
    );
  }

  Widget _buildGoldMarket(PlayerProvider player, MarketProvider market, BankCubit cubit) {
    bool isPriceUp = market.goldPrice >= market.oldGoldPrice;

    // 🟢 استخدام الكيوبت لحساب أقصى شراء
    int maxBuyable = cubit.calculateMaxGoldBuyable(player.cash, market.goldPrice);
    int buyAmt = _goldBuySliderValue.toInt();
    int sellAmt = _goldSellSliderValue.toInt();

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.amber.shade900, Colors.black]),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber, width: 2)),
            child: Column(
              children: [
                const Text('السعر الحالي للذهب', style: TextStyle(color: Colors.white70, fontSize: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${market.goldPrice} كاش',
                        style: const TextStyle(color: Colors.amber, fontSize: 36, fontWeight: FontWeight.bold)),
                    Icon(
                      isPriceUp ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPriceUp ? Colors.green : Colors.red,
                      size: 30,
                    ),
                  ],
                ),
                Text(
                  'التغير: ${isPriceUp ? '+' : ''}${market.goldPrice - market.oldGoldPrice}',
                  style: TextStyle(color: isPriceUp ? Colors.green : Colors.red, fontSize: 14),
                ),
                const Divider(color: Colors.white24),
                Text('ذهب في محفظتك: ${player.gold}', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          _buildBankActionCard(
            title: 'شراء ذهب',
            sliderValue: _goldBuySliderValue,
            maxValue: maxBuyable.toDouble(),
            controller: _goldBuyController,
            onSliderChanged: (val) {
              setState(() {
                _goldBuySliderValue = val;
                _goldBuyController.text = val.toInt().toString();
              });
            },
            onTextChanged: (text) {
              int v = int.tryParse(text) ?? 0;
              if (v > maxBuyable) v = maxBuyable;
              setState(() => _goldBuySliderValue = v.toDouble());
            },
            actionText: 'تكلفة: ${buyAmt * market.goldPrice}',
            infoText: 'سيتم الخصم من الكاش',
            buttonColor: Colors.amber.shade700,
            onPressed: () {
              if (buyAmt > 0) {
                cubit.executeTransaction(() async {
                  await Future.sync(() => player.buyGold(buyAmt, market.goldPrice));
                  if (mounted) setState(() { _goldBuySliderValue = 0; _goldBuyController.text = '0'; });
                }, 'تم شراء $buyAmt سبيكة ذهب!');
              }
            },
          ),
          _buildBankActionCard(
            title: 'بيع ذهب',
            sliderValue: _goldSellSliderValue,
            maxValue: player.gold.toDouble(),
            controller: _goldSellController,
            onSliderChanged: (val) {
              setState(() {
                _goldSellSliderValue = val;
                _goldSellController.text = val.toInt().toString();
              });
            },
            onTextChanged: (text) {
              int v = int.tryParse(text) ?? 0;
              if (v > player.gold) v = player.gold;
              setState(() => _goldSellSliderValue = v.toDouble());
            },
            actionText: 'عائد: ${sellAmt * market.goldPrice}',
            infoText: 'ستحصل على كاش فوري',
            buttonColor: Colors.orange.shade900,
            onPressed: () {
              if (sellAmt > 0) {
                cubit.executeTransaction(() async {
                  await Future.sync(() => player.sellGold(sellAmt, market.goldPrice));
                  if (mounted) setState(() { _goldSellSliderValue = 0; _goldSellController.text = '0'; });
                }, 'تم بيع $sellAmt سبيكة ذهب بنجاح!');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoanSection(PlayerProvider player, BankCubit cubit) {
    int takeAmt = _loanTakeSliderValue.toInt();
    int repayAmt = _loanRepaySliderValue.toInt();
    int remainingLimit = player.maxLoanLimit - player.loanAmount;

    // 🟢 الحسابات انتقلت للكيوبت
    int adminFee = cubit.calculateAdminFee(takeAmt);
    int netReceive = cubit.calculateNetReceive(takeAmt);

    bool canRepay = player.canRepayLoan();
    String repayInfoText = 'سداد الديون يزيد من سمعتك (+10)';

    if (!canRepay && player.loanTime != null) {
      final diff = DateTime.now().difference(player.loanTime!);
      final int remSec = 300 - diff.inSeconds;
      if (remSec > 0) {
        int m = remSec ~/ 60;
        int s = remSec % 60;
        repayInfoText = 'يُسمح بالسداد بعد: $m:${s.toString().padLeft(2, '0')} ⏳';
      } else {
        canRepay = true;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red.shade900, Colors.black]),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.redAccent, width: 2)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي الديون', style: TextStyle(color: Colors.white70)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blueAccent)
                      ),
                      child: Text('السمعة: ${player.creditScore}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Text('${player.loanAmount} كاش',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 36, fontWeight: FontWeight.bold)),
                Text('الحد الحالي: ${player.maxLoanLimit}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const Divider(color: Colors.white24),
                Text('المتبقي للاقتراض: $remainingLimit', style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          _buildBankActionCard(
            title: 'طلب قرض جديد',
            sliderValue: _loanTakeSliderValue,
            maxValue: remainingLimit.toDouble(),
            controller: _loanTakeController,
            onSliderChanged: (val) {
              setState(() {
                _loanTakeSliderValue = val;
                _loanTakeController.text = val.toInt().toString();
              });
            },
            onTextChanged: (text) {
              int v = int.tryParse(text) ?? 0;
              if (v > remainingLimit) v = remainingLimit;
              setState(() => _loanTakeSliderValue = v.toDouble());
            },
            actionText: 'استلام $netReceive',
            infoText: 'رسوم: $adminFee | غرامة تأخير: 10% كل ساعتين',
            buttonColor: Colors.redAccent,
            onPressed: () {
              if (takeAmt > 0) {
                cubit.executeTransaction(() async {
                  await Future.sync(() => player.takeLoan(takeAmt));
                  if (mounted) setState(() { _loanTakeSliderValue = 0; _loanTakeController.text = '0'; });
                }, 'تم استلام القرض بنجاح!');
              }
            },
          ),
          _buildBankActionCard(
            title: 'سداد القرض',
            sliderValue: canRepay ? _loanRepaySliderValue : 0.0,
            maxValue: canRepay ? (player.cash < player.loanAmount ? player.cash : player.loanAmount).toDouble() : 0.0,
            controller: _loanRepayController,
            onSliderChanged: (val) {
              setState(() {
                _loanRepaySliderValue = val;
                _loanRepayController.text = val.toInt().toString();
              });
            },
            onTextChanged: (text) {
              int limit = player.cash < player.loanAmount ? player.cash : player.loanAmount;
              int v = int.tryParse(text) ?? 0;
              if (v > limit) v = limit;
              setState(() => _loanRepaySliderValue = v.toDouble());
            },
            actionText: 'سداد $repayAmt',
            infoText: repayInfoText,
            buttonColor: canRepay ? Colors.orange : Colors.grey,
            onPressed: canRepay ? () {
              if (repayAmt > 0) {
                cubit.executeTransaction(() async {
                  await Future.sync(() => player.repayLoan(repayAmt));
                  if (mounted) setState(() { _loanRepaySliderValue = 0; _loanRepayController.text = '0'; });
                }, 'تم سداد الدفعة وتحسين سمعتك!');
              }
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(PlayerProvider player) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.green.shade900, Colors.black]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green, width: 2)),
      child: Column(
        children: [
          const Text('رصيدك البنكي (للحفظ فقط)', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Text('${player.bankBalance} كاش',
              style: const TextStyle(color: Colors.green, fontSize: 36, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [const Text('في جيبك', style: TextStyle(color: Colors.white54)), Text('${player.cash}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              const VerticalDivider(color: Colors.white24),
              Column(children: [const Text('الذهب', style: TextStyle(color: Colors.white54)), Text('${player.gold}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))]),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(PlayerProvider player) {
    if (player.transactions.isEmpty) {
      return const Center(child: Text('لا توجد عمليات مسجلة حالياً', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      itemCount: player.transactions.length,
      itemBuilder: (context, index) {
        final tx = player.transactions[index];
        final timeStr = DateFormat('HH:mm:ss').format(tx.date);
        return Card(
          color: Colors.black26,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(tx.isPositive ? Icons.add_circle : Icons.remove_circle,
                color: tx.isPositive ? Colors.green : Colors.red),
            title: Text(tx.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Text(
              '${tx.isPositive ? '+' : '-'}${tx.amount}',
              style: TextStyle(color: tx.isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBankActionCard({
    required String title,
    required double sliderValue,
    required double maxValue,
    required TextEditingController controller,
    required Function(double) onSliderChanged,
    required Function(String) onTextChanged,
    required String actionText,
    required String infoText,
    required Color buttonColor,
    required VoidCallback? onPressed,
  }) {
    double safeMax = maxValue > 0 ? maxValue : 1.0;
    double safeValue = sliderValue.clamp(0.0, safeMax);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.black38, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Slider(
                    value: safeValue,
                    min: 0,
                    max: safeMax,
                    divisions: safeMax.toInt() > 0 ? safeMax.toInt() : 1,
                    activeColor: buttonColor,
                    onChanged: (maxValue > 0 && onPressed != null) ? onSliderChanged : null),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()),
                  enabled: onPressed != null,
                  onChanged: onTextChanged,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(infoText, style: TextStyle(color: onPressed != null ? Colors.white54 : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(actionText, style: TextStyle(color: buttonColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3)
                ),
                onPressed: (maxValue > 0 && sliderValue > 0 && onPressed != null) ? onPressed : null,
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}