import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _combatPlayer = AudioPlayer();

  bool _isMuted = false;
  bool _bgStarted = false;

  bool get isMuted => _isMuted;

  final double _bgNormalVolume = 0.3;
  final double _bgLowVolume = 0.1;

  AudioProvider() {
    _initAudio();
  }

  void _initAudio() {
    _bgPlayer.setReleaseMode(ReleaseMode.loop);

    // 💡 التعديل الوحيد: خلينا مشغلات المؤثرات "سريعة الاستجابة" عشان ما توقف الموسيقى
    _clickPlayer.setPlayerMode(PlayerMode.lowLatency);
    _combatPlayer.setPlayerMode(PlayerMode.lowLatency);

    // كودك الأصلي مثل ما هو (بدون كلمة const اللي خربت الدنيا)
    AudioPlayer.global.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    ));
  }

  Future<void> playBGM() async {
    if (_isMuted) return;
    try {
      await _bgPlayer.setSource(AssetSource('audio/bg_music.mp3'));
      await _bgPlayer.setVolume(_bgNormalVolume);
      await _bgPlayer.resume();
      _bgStarted = true;
    } catch (e) {
      debugPrint("BGM Error: $e");
    }
  }

  Future<void> lowerBGMVolume() async {
    if (_isMuted) return;
    await _bgPlayer.setVolume(_bgLowVolume);
  }

  Future<void> restoreBGMVolume() async {
    if (_isMuted) return;
    await _bgPlayer.setVolume(_bgNormalVolume);
  }

  Future<void> playEffect(String fileName) async {
    if (_isMuted) return;

    if (!_bgStarted) {
      playBGM();
    }

    try {
      AudioPlayer currentPlayer;
      if (fileName == 'attack.mp3') {
        currentPlayer = _combatPlayer;
      } else {
        currentPlayer = _clickPlayer;
      }

      await currentPlayer.stop();
      await currentPlayer.setVolume(1.0);
      await currentPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      debugPrint("Effect Error: $e");
    }
  }

  // --- [إضافة جديدة] دالة إيقاف الموسيقى عند الخروج من التطبيق ---
  Future<void> pauseBGM() async {
    await _bgPlayer.pause();
  }

  // --- [إضافة جديدة] دالة استئناف الموسيقى عند العودة للتطبيق ---
  Future<void> resumeBGM() async {
    if (!_isMuted) {
      await _bgPlayer.resume();
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgPlayer.pause();
      _clickPlayer.stop();
      _combatPlayer.stop();
    } else {
      _bgPlayer.resume();
      if (!_bgStarted) playBGM();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _bgPlayer.dispose();
    _clickPlayer.dispose();
    _combatPlayer.dispose();
    super.dispose();
  }
}