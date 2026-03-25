import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; 
import 'screens/game_screen.dart';
import 'providers/player_provider.dart';
import 'providers/audio_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        fontFamily: 'Cairo',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: FirebaseInitWrapper(),
      ),
    );
  }
}

class FirebaseInitWrapper extends StatefulWidget {
  const FirebaseInitWrapper({super.key});

  @override
  State<FirebaseInitWrapper> createState() => _FirebaseInitWrapperState();
}

class _FirebaseInitWrapperState extends State<FirebaseInitWrapper> {
  bool _initialized = false;
  bool _error = false;

  void _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setState(() {
        _initialized = true;
        _error = false;
      });
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text(
                  "لا يوجد اتصال بالسيرفر!",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "تأكد من اتصالك بالإنترنت أو أن مشروع فيربيس مفعل بشكل صحيح.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _initializeFirebase,
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  label: const Text("إعادة المحاولة", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 20),
              Text("جاري الاتصال بمدينة الإجرام...", style: TextStyle(color: Colors.amber, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));
        }
        
        if (snapshot.hasData) {
          // تأكد من تهيئة اللاعب عند وجود جلسة نشطة
          final player = Provider.of<PlayerProvider>(context, listen: false);
          if (player.uid == null) {
            player.initializePlayerOnServer(snapshot.data!.uid, "");
          }
          return const GameScreen();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسمك')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final player = Provider.of<PlayerProvider>(context, listen: false);
      await player.initializePlayerOnServer(userCredential.user!.uid, _nameController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الدخول: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text('مدينة الإجرام أونلاين', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل اسمك المستعار...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.amber)
              else
                ElevatedButton(
                  onPressed: _loginAnonymously,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('بدء اللعبة', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
