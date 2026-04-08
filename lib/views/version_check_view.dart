// المسار: lib/views/version_check_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// استدعِ شاشة تسجيل الدخول أو شاشتك الرئيسية هنا
// import 'login_view.dart';

class VersionCheckView extends StatefulWidget {
  const VersionCheckView({super.key});

  @override
  State<VersionCheckView> createState() => _VersionCheckViewState();
}

class _VersionCheckViewState extends State<VersionCheckView> {
  bool _isLoading = true;
  bool _needsUpdate = false;
  String _storeUrl = '';

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      // 1. جلب رقم إصدار التطبيق الحالي من جوال اللاعب
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. جلب الإصدار المطلوب من فايربيس
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance.collection('settings').doc('app_info').get();

      if (settingsDoc.exists) {
        String minVersion = settingsDoc['min_version'] ?? '1.0.0';
        _storeUrl = settingsDoc['play_store_url'] ?? 'https://play.google.com';

        // 3. مقارنة الإصدارات (بشكل مبسط)
        if (_isUpdateRequired(currentVersion, minVersion)) {
          setState(() {
            _needsUpdate = true;
            _isLoading = false;
          });
          return;
        }
      }

      // 🟢 إذا الإصدار سليم، ننتقل لشاشة اللعبة أو تسجيل الدخول 🟢
      _goToGame();

    } catch (e) {
      // في حال فشل الاتصال بالنت، نمشيه للعبة ونخلي الفايربيس يتعامل مع الأوفلاين
      _goToGame();
    }
  }

  // دالة لمقارنة الأرقام (مثلاً 1.0.1 مع 1.0.2)
  bool _isUpdateRequired(String current, String minimum) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> minParts = minimum.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length; i++) {
      if (currentParts[i] < minParts[i]) return true; // يحتاج تحديث
      if (currentParts[i] > minParts[i]) return false; // إصداره أحدث من المطلوب
    }
    return false; // متطابق
  }

  void _goToGame() {
    // ⚠️ هنا غير الـ LoginView باسم شاشة البداية حقتك
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginView()));
  }

  Future<void> _launchStore() async {
    final Uri url = Uri.parse(_storeUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('لا يمكن فتح الرابط');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.amber)
            : _needsUpdate
            ? Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update, size: 100, color: Colors.redAccent),
              const SizedBox(height: 20),
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
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _launchStore,
                  child: const Text("تحديث الآن", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                ),
              ),
            ],
          ),
        )
            : const SizedBox(),
      ),
    );
  }
}