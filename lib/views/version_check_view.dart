// المسار: lib/views/version_check_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // لاستخدام الألوان وشاشة AuthWrapper

class VersionCheckView extends StatefulWidget {
  const VersionCheckView({super.key});

  @override
  State<VersionCheckView> createState() => _VersionCheckViewState();
}

class _VersionCheckViewState extends State<VersionCheckView> {
  String _currentVersion = '';
  bool _isLoadingVersion = true;

  @override
  void initState() {
    super.initState();
    _initAppVersion();
  }

  // جلب إصدار التطبيق من جوال اللاعب لمرة واحدة عند تشغيل اللعبة
  Future<void> _initAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentVersion = packageInfo.version;
          _isLoadingVersion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentVersion = '1.0.0'; // قيمة افتراضية في حال فشل الجلب
          _isLoadingVersion = false;
        });
      }
    }
  }

  // مقارنة الإصدارات (اللاعب ضد السيرفر)
  bool _isUpdateRequired(String current, String minimum) {
    if (current.isEmpty) return false;

    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> minParts = minimum.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < currentParts.length; i++) {
      int c = currentParts[i];
      int m = i < minParts.length ? minParts[i] : 0;
      if (c < m) return true; // يحتاج تحديث
      if (c > m) return false; // إصدار أحدث
    }
    return false; // متطابق
  }

  Future<void> _launchStore(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('لا يمكن فتح الرابط');
    }
  }

  @override
  Widget build(BuildContext context) {
    // انتظار تحميل رقم الإصدار من الجوال
    if (_isLoadingVersion) {
      return const GameBackgroundScaffold(
        showOverlay: true,
        child: Center(child: CircularProgressIndicator(color: GameColors.primary)),
      );
    }

    // 🟢 السحر هنا: استخدام StreamBuilder لمراقبة التحديثات بشكل حي ومباشر 🟢
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('app_info').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data != null) {
            String minVersion = data['min_version'] ?? '1.0.0';
            String storeUrl = data['play_store_url'] ?? 'https://play.google.com';

            bool needsUpdate = _isUpdateRequired(_currentVersion, minVersion);

            // 🔴 إذا نزل تحديث، الشاشة هذي بتمسح اللعبة من قدام اللاعب وتطلع له التنبيه فوراً 🔴
            if (needsUpdate) {
              return GameBackgroundScaffold(
                showOverlay: true,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "تحديث هام متاح! 🚨",
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "أضفنا ميزات جديدة وأصلحنا بعض الأخطاء.\nيجب عليك تحديث اللعبة للاستمرار في اللعب.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Changa'),
                        ),
                        const SizedBox(height: 40),
                        GameActionButton(
                          onPressed: () => _launchStore(storeUrl),
                          label: "تحديث الآن",
                          isPrimary: true,
                          icon: Icons.download,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }
        }

        // 🟢 إذا ما يحتاج تحديث، اللعبة تستمر بشكل طبيعي 🟢
        // استخدمنا const عشان الفلاتر ما يسوي إعادة بناء للعبة بالكامل بدون سبب
        return const AuthWrapper();
      },
    );
  }
}