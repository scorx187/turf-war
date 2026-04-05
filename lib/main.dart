// المسار: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io'; // 🟢 ضروري جداً لفحص الإنترنت الحقيقي
import 'dart:async'; // 🟢 ضروري للمؤقت الزمني
import 'firebase_options.dart';
import 'screens/game_screen.dart';
import 'providers/player_provider.dart';
import 'providers/audio_provider.dart';

// 🔥 تعريف الألوان الخاصة باللعبة هنا لسهولة الوصول إليها
class GameColors {
  static const Color primary = Colors.amber;
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1E1E1E);
  static const Color accent = Colors.blueAccent;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: const MyGame(),
    ),
  );
}

class MyGame extends StatelessWidget {
  const MyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: GameColors.primary,
        scaffoldBackgroundColor: GameColors.background,
        fontFamily: 'Changa',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: FirebaseInitWrapper(),
      ),
    );
  }
}

// 🧱 ويدجت الخلفية المشتركة
class GameBackgroundScaffold extends StatelessWidget {
  final Widget child;
  final bool showOverlay;
  final bool resizeToAvoidBottomInset;

  const GameBackgroundScaffold({
    super.key,
    required this.child,
    this.showOverlay = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/turfwar_loading_screen.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0.0, -0.2),
            ),
          ),
          if (showOverlay)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.black12, Colors.black87],
                    stops: [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: SafeArea(
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// 🟢 التحديث الجذري هنا: حارس الشبكة الصارم (Kill-Switch) 🟢
class FirebaseInitWrapper extends StatefulWidget {
  const FirebaseInitWrapper({super.key});

  @override
  State<FirebaseInitWrapper> createState() => _FirebaseInitWrapperState();
}

class _FirebaseInitWrapperState extends State<FirebaseInitWrapper> {
  bool _initialized = false;
  bool _error = false;
  Timer? _networkTimer;

  // دالة تفحص الإنترنت الحقيقي (مو بس الواي فاي شغال)
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false; // فشل الاتصال = مافي نت
    }
  }

  void _initializeApp() async {
    setState(() {
      _error = false;
      _initialized = false;
    });

    // 1. فحص النت أولاً قبل أي شيء
    bool hasInternet = await _checkInternet();
    if (!hasInternet) {
      setState(() => _error = true);
      _startNetworkMonitoring(); // نشغل المراقب عشان يرجع يشبك لوحده
      return;
    }

    // 2. تهيئة فايربيس مع منع الكاش نهائياً
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, // تعطيل اللعب أوفلاين تماماً
      );

      setState(() {
        _initialized = true;
        _error = false;
      });
      _startNetworkMonitoring(); // بدء المراقبة المستمرة
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
      setState(() => _error = true);
    }
  }

  // 🟢 المراقب الدائم: يشتغل كل 3 ثواني 🟢
  void _startNetworkMonitoring() {
    _networkTimer?.cancel();
    _networkTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      bool hasInternet = await _checkInternet();
      if (mounted) {
        if (!hasInternet && !_error) {
          // إذا طفى النت فجأة، ارميه لشاشة الخطأ فوراً
          setState(() => _error = true);
        } else if (hasInternet && _error && _initialized) {
          // إذا رجع النت وكان الفايربيس شغال، اخفي شاشة الخطأ
          setState(() => _error = false);
        } else if (hasInternet && _error && !_initialized) {
          // إذا رجع النت وكان الفايربيس لسه ما اشتغل، شغله
          _initializeApp();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _networkTimer?.cancel(); // إيقاف المراقب عند الخروج
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return GameBackgroundScaffold(
        showOverlay: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 100, color: Colors.redAccent),
                const SizedBox(height: 25),
                const Text("لا يوجد اتصال بالإنترنت!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
                const SizedBox(height: 10),
                const Text("اللعبة تتطلب اتصال دائم ومستقر بالسيرفر.\nيُرجى التحقق من الشبكة.", style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Changa'), textAlign: TextAlign.center),
                const SizedBox(height: 40),
                GameActionButton(
                  onPressed: () {
                    setState(() { _error = false; _initialized = false; });
                    _initializeApp();
                  },
                  icon: Icons.refresh,
                  label: "إعادة المحاولة",
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const GameBackgroundScaffold(
        showOverlay: false,
        child: Center(
          child: CircularProgressIndicator(color: GameColors.primary),
        ),
      );
    }

    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Widget _loading() => const GameBackgroundScaffold(
    showOverlay: false,
    child: Center(child: CircularProgressIndicator(color: GameColors.primary)),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) return _loading();

        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('players').doc(user.uid).snapshots(),
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) return _loading();

              if (docSnapshot.hasData && docSnapshot.data!.exists) {
                final player = Provider.of<PlayerProvider>(context, listen: false);
                if (player.uid == null) {
                  player.initializePlayerOnServer(user.uid, "");
                }
                return const GameScreen();
              } else {
                if (user.isAnonymous) return _loading();
                return ChooseNameScreen(user: user);
              }
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginAnonymously() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسمك أولاً', style: TextStyle(fontFamily: 'Changa'))));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final player = Provider.of<PlayerProvider>(context, listen: false);
      await player.initializePlayerOnServer(userCredential.user!.uid, _nameController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الدخول كزائر: $e', style: const TextStyle(fontFamily: 'Changa'))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithStandardGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في تسجيل الدخول بحساب Google', style: TextStyle(fontFamily: 'Changa'))));
      debugPrint("Google Sign-In Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameBackgroundScaffold(
      resizeToAvoidBottomInset: false,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Text(
                  'TURF WAR',
                  style: TextStyle(
                    color: GameColors.primary,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    shadows: [
                      Shadow(blurRadius: 15, color: GameColors.accent.withOpacity(0.7), offset: const Offset(3, 3)),
                      const Shadow(blurRadius: 5, color: Colors.black, offset: Offset(-1, -1)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'أحكم السيطرة على المدينة...',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.normal, fontFamily: 'Changa'),
                ),
                const SizedBox(height: 60),

                TextField(
                  controller: _nameController,
                  maxLength: 14,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Changa'),
                  decoration: InputDecoration(
                    counterText: "",
                    prefixIcon: const Icon(Icons.person_outline, color: GameColors.primary),
                    hintText: 'ادخل اسمك المستعار...',
                    hintStyle: const TextStyle(color: Colors.white30, fontFamily: 'Changa'),
                    filled: true,
                    fillColor: Colors.black45,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: GameColors.primary, width: 2.0)),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 30),

                if (_isLoading)
                  const CircularProgressIndicator(color: GameColors.primary)
                else ...[
                  GameActionButton(
                    onPressed: _loginAnonymously,
                    label: 'دخول سريع (زائر)',
                    isPrimary: true,
                  ),
                  const SizedBox(height: 20),
                  GameActionButton(
                    onPressed: _loginWithStandardGoogle,
                    icon: Icons.g_mobiledata,
                    label: 'تسجيل الدخول بحساب Google',
                    isGoogle: true,
                  ),
                ],
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChooseNameScreen extends StatefulWidget {
  final User user;
  const ChooseNameScreen({super.key, required this.user});

  @override
  State<ChooseNameScreen> createState() => _ChooseNameScreenState();
}

class _ChooseNameScreenState extends State<ChooseNameScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? '';
  }

  void _confirmName() async {
    String chosenName = _nameController.text.trim();
    if (chosenName.isEmpty || chosenName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الاسم يجب أن يكون 3 حروف على الأقل!', style: TextStyle(fontFamily: 'Changa'))));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      await player.initializePlayerOnServer(widget.user.uid, chosenName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء حفظ الاسم', style: TextStyle(fontFamily: 'Changa'))));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameBackgroundScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100, color: GameColors.primary),
              const SizedBox(height: 20),
              const Text('أهلاً بك في عالم الجريمة', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Changa')),
              const SizedBox(height: 10),
              const Text('اختر اسماً يعرفك به الجميع في "ملاذ"\nهذا الاسم سيظهر للزعماء الآخرين.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'Changa')),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                maxLength: 14,
                style: const TextStyle(color: GameColors.primary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Changa'),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: 'أدخل اسمك...',
                  hintStyle: const TextStyle(color: Colors.white24, fontFamily: 'Changa'),
                  filled: true,
                  fillColor: Colors.black45,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: GameColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(color: GameColors.primary)
              else
                GameActionButton(
                  onPressed: _confirmName,
                  label: 'تأكيد الدخول',
                  isPrimary: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isPrimary;
  final bool isGoogle;

  const GameActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isPrimary = false,
    this.isGoogle = false,
  });

  @override
  Widget build(BuildContext context) {
    Color btnColor = GameColors.surface;
    Color textColor = Colors.white;

    if (isPrimary) {
      btnColor = GameColors.primary;
      textColor = Colors.black;
    } else if (isGoogle) {
      btnColor = Colors.blue[800]!;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: isPrimary ? 10 : 2,
        shadowColor: isPrimary ? GameColors.primary.withOpacity(0.5) : Colors.black54,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isGoogle ? 40 : 28, color: textColor),
            const SizedBox(width: 15),
          ],
          Text(
            label,
            style: TextStyle(
                fontSize: isPrimary ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Changa'
            ),
          ),
        ],
      ),
    );
  }
}