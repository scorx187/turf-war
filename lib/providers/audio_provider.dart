import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioProvider with ChangeNotifier {
  // استخدمنا late عشان ما ننشئهم إلا بعد ما نضبط إعدادات الدمج
  late AudioPlayer _bgPlayer;
  late AudioPlayer _clickPlayer;
  late AudioPlayer _combatPlayer;

  bool _isMuted = false;
  bool _bgStarted = false;

  bool get isMuted => _isMuted;

  final double _bgNormalVolume = 0.3;
  final double _bgLowVolume = 0.1;

  AudioProvider() {
    _initAudio();
  }

  void _initAudio() {
    try {
      // 1. الأهم: إخبار الجوال بالسماح بدمج الأصوات (Mix) وعدم إيقاف الخلفية
      // هذا الكود لازم يشتغل قبل إنشاء أي مشغل صوت
      AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, // السر هنا: يمنع سحب الصوت من الخلفية
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient, // يسمح بتداخل الأصوات في الآيفون
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ));

      // 2. الآن ننشئ المشغلات عشان تاخذ الإعدادات الجديدة الصحيحة
      _bgPlayer = AudioPlayer();
      _clickPlayer = AudioPlayer();
      _combatPlayer = AudioPlayer();

      // تكرار موسيقى الخلفية
      _bgPlayer.setReleaseMode(ReleaseMode.loop);

    } catch (e) {
      debugPrint("Audio Init Error: $e");
    }
  }

  Future<void> playBGM() async {
    if (_isMuted) return;
    try {
      await _bgPlayer.setVolume(_bgNormalVolume);
      await _bgPlayer.play(AssetSource('audio/bg_music.mp3'));
      _bgStarted = true;
    } catch (e) {
      debugPrint("BGM Error: $e");
    }
  }

  Future<void> lowerBGMVolume() async {
    if (_isMuted) return;
    try {
      await _bgPlayer.setVolume(_bgLowVolume);
    } catch (e) {}
  }

  Future<void> restoreBGMVolume() async {
    if (_isMuted) return;
    try {
      await _bgPlayer.setVolume(_bgNormalVolume);
    } catch (e) {}
  }

  Future<void> playEffect(String fileName) async {
    if (_isMuted) return;

    if (!_bgStarted) {
      playBGM();
    }

    try {
      AudioPlayer currentPlayer = (fileName == 'attack.mp3') ? _combatPlayer : _clickPlayer;

      // إيقاف الصوت لو كان شغال، وإعادة تشغيله بسرعة
      await currentPlayer.stop();
      await currentPlayer.setVolume(1.0);
      await currentPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      debugPrint("Effect Error: $e");
    }
  }

  Future<void> pauseBGM() async {
    try {
      await _bgPlayer.pause();
    } catch (e) {}
  }

  Future<void> resumeBGM() async {
    if (!_isMuted) {
      try {
        await _bgPlayer.resume();
      } catch (e) {}
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    try {
      if (_isMuted) {
        _bgPlayer.pause();
        _clickPlayer.stop();
        _combatPlayer.stop();
      } else {
        _bgPlayer.resume();
        if (!_bgStarted) playBGM();
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Mute Toggle Error: $e");
    }
  }

  @override
  void dispose() {
    _bgPlayer.dispose();
    _clickPlayer.dispose();
    _combatPlayer.dispose();
    super.dispose();
  }
}