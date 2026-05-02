// المسار: lib/widgets/quick_recovery_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audio_provider.dart';
import '../services/inventory_service.dart';
import '../services/black_market_service.dart';
import '../views/store_view.dart';

class QuickRecoveryDialog {
  static void show(BuildContext context, String type, int amountNeeded) {
    // 🟢 استخدام showGeneralDialog لإضافة الأنيميشن البسيط الفخم (نفس الجرائم بالضبط)
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _QuickRecoveryDialogContent(type: type, amountNeeded: amountNeeded),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        // 🟢 أنيميشن تكبير سلس بدون ارتداد (نفس الجريمة)
        return Transform.scale(
          scale: anim1.value,
          child: child,
        );
      },
    );
  }
}

class _QuickRecoveryDialogContent extends StatefulWidget {
  final String type;
  final int amountNeeded;

  const _QuickRecoveryDialogContent({required this.type, required this.amountNeeded});

  @override
  State<_QuickRecoveryDialogContent> createState() => _QuickRecoveryDialogContentState();
}

class _QuickRecoveryDialogContentState extends State<_QuickRecoveryDialogContent> {
  bool isLoading = false;
  bool showInsufficientBalanceUI = false; // للتحكم في تغيير محتوى النافذة لنقص الرصيد

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final audio = Provider.of<AudioProvider>(context, listen: false);

    int cost = 0;
    bool useGold = false;
    String title = '';
    IconData mainIcon = Icons.bolt;
    Color iconColor = Colors.amber;
    String itemName = '';
    String itemId = '';

    if (widget.type == 'energy') {
      cost = 50;
      useGold = true;
      title = 'استعادة الطاقة';
      mainIcon = Icons.bolt;
      iconColor = Colors.amber;
      itemName = 'حقنة منشط';
      itemId = 'steroids';
    } else if (widget.type == 'courage') {
      cost = 50;
      useGold = true;
      title = 'استعادة الشجاعة';
      mainIcon = Icons.local_fire_department;
      iconColor = Colors.orangeAccent;
      itemName = 'قهوة مركزة';
      itemId = 'coffee';
    } else if (widget.type == 'health') {
      cost = 2500;
      useGold = false;
      title = 'علاج سريع';
      mainIcon = Icons.favorite;
      iconColor = Colors.redAccent;
      itemName = 'حقنة إسعافات';
      itemId = 'medkit';
    }

    if (showInsufficientBalanceUI) {
      title = 'ذهب غير كافي';
      mainIcon = Icons.account_balance_wallet;
      iconColor = Colors.redAccent;
    }

    int itemAmount = player.inventory[itemId] ?? 0;
    bool hasItem = itemAmount > 0;

    String contentText = hasItem
        ? 'لديك ($itemAmount) $itemName في المخزن.\nهل تريد استخدام واحد لاستعادة $title بالكامل؟'
        : (useGold
        ? 'لا تملك $itemName في المخزن!\nهل تريد الشراء والاستخدام الفوري مقابل $cost ذهب؟'
        : 'لا تملك $itemName في المخزن!\nهل تريد الشراء والاستخدام الفوري مقابل \$$cost كاش؟');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(20),
        // 🟢 نفس إطار الجريمة بالضبط
        border: Border.all(color: const Color(0xFFC5A059), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFC5A059).withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mainIcon, color: iconColor, size: 60),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontFamily: 'Changa', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),

          if (isLoading)
            const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: Color(0xFFC5A059))))
          else
            Text(
              showInsufficientBalanceUI
                  ? (useGold ? 'ليس لديك ذهب كافي، هل تود شحن المزيد من الذهب؟' : 'ليس لديك كاش كافي، هل تود شحن المزيد من الكاش؟')
                  : contentText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Changa', fontSize: 16, color: Colors.white70),
            ),

          const SizedBox(height: 30),

          if (!isLoading)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5A059),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                    ),
                    onPressed: () async {
                      audio.playEffect('click.mp3');

                      // 🟢 إذا كان الزر للذهاب للشحن
                      if (showInsufficientBalanceUI) {
                        final nav = Navigator.of(context);
                        nav.pop();
                        nav.push(MaterialPageRoute(builder: (_) => StoreView(initialTab: useGold ? 1 : 0)));
                        return;
                      }

                      // 🟢 عملية الشراء والاستخدام
                      setState(() => isLoading = true);

                      try {
                        if (!hasItem) {
                          await BlackMarketService().buyItem(
                              uid: player.uid!,
                              itemId: itemId,
                              cost: cost,
                              currencyType: useGold ? 'gold' : 'cash',
                              amount: 1
                          );
                          if (useGold) {
                            player.removeGold(cost);
                          } else {
                            player.removeCash(cost, reason: 'شراء سريع $itemName');
                          }
                        }

                        await InventoryService().consumeItem(uid: player.uid!, itemId: itemId);

                        if (hasItem) {
                          player.inventory[itemId] = player.inventory[itemId]! - 1;
                          if (player.inventory[itemId] == 0) player.inventory.remove(itemId);
                        }

                        if (widget.type == 'energy') player.setEnergy(player.maxEnergy);
                        if (widget.type == 'courage') player.setCourage(player.maxCourage);
                        if (widget.type == 'health') player.setHealth(player.maxHealth);

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استعادة العملية بنجاح!', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (mounted) {
                          String errorMsg = e.toString();
                          String cleanError = errorMsg.replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\] '), '');

                          if (cleanError.contains('ذهب كافي') || cleanError.contains('كاش')) {
                            setState(() {
                              isLoading = false;
                              showInsufficientBalanceUI = true; // تحويل النافذة لنقص الرصيد
                            });
                          } else {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $cleanError', style: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.bold)), backgroundColor: Colors.red));
                          }
                        }
                      }
                    },
                    child: Text(
                        showInsufficientBalanceUI ? 'الذهاب للشحن' : (hasItem ? 'استخدام' : 'شراء واستخدام'),
                        style: const TextStyle(fontFamily: 'Changa', fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                    ),
                    onPressed: () {
                      audio.playEffect('click.mp3');
                      Navigator.pop(context);
                    },
                    child: const Text('إلغاء', style: TextStyle(fontFamily: 'Changa', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}