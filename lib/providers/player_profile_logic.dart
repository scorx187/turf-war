// Ø§Ù„Ù…Ø³Ø§Ø±: lib/providers/player_profile_logic.dart
part of 'player_provider.dart';
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

extension PlayerProfileLogic on PlayerProvider {

  Uint8List? getDecodedImage(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    if (_decodedImagesCache.containsKey(base64Str)) return _decodedImagesCache[base64Str]!;
    try {
      final bytes = base64Decode(base64Str);
      if (_decodedImagesCache.length >= PlayerProvider._maxImagesCacheSize) {
        _decodedImagesCache.remove(_decodedImagesCache.keys.first);
      }
      _decodedImagesCache[base64Str] = bytes;
      return bytes;
    } catch (e) { return null; }
  }

  Future<String?> uploadAndSetProfilePic(Uint8List imageBytes) async {
    if (_uid == null) return null;
    try {
      Reference ref = FirebaseStorage.instance.ref().child('profile_pics/$_uid');
      UploadTask uploadTask = ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      if (_profilePicUrl != null && _profilePicUrl!.startsWith('http')) {
        await NetworkImage(_profilePicUrl!).evict();
      }

      downloadUrl = "$downloadUrl&v=${DateTime.now().millisecondsSinceEpoch}";
      _profilePicUrl = downloadUrl;
      await _syncWithFirestore();

      WriteBatch batch = _firestore.batch();
      var chatQuery = await _firestore.collection('chat').where('uid', isEqualTo: _uid).get();
      for (var doc in chatQuery.docs) {
        batch.update(doc.reference, {'profilePicUrl': downloadUrl});
      }
      await batch.commit();

      _sendSystemNotification("ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø­Ø³Ø§Ø¨ ðŸ“¸", "ØªÙ… Ø±ÙØ¹ ÙˆØªØ­Ø¯ÙŠØ« ØµÙˆØ±ØªÙƒ Ø§Ù„Ø´Ø®ØµÙŠØ© Ø¨Ù†Ø¬Ø§Ø­!", "info");
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      debugPrint("Ø®Ø·Ø£ ÙÙŠ Ø±ÙØ¹ Ø§Ù„ØµÙˆØ±Ø©: $e");
      _sendSystemNotification("Ø®Ø·Ø£ âš ï¸", "ÙØ´Ù„ Ø±ÙØ¹ Ø§Ù„ØµÙˆØ±Ø©ØŒ ØªØ£ÙƒØ¯ Ù…Ù† Ø§ØªØµØ§Ù„Ùƒ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª.", "error");
      return null;
    }
  }

  Future<String?> uploadAndSetBackgroundPic(Uint8List imageBytes) async {
    if (_uid == null) return null;
    try {
      Reference ref = FirebaseStorage.instance.ref().child('background_pics/$_uid');
      UploadTask uploadTask = ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      if (_backgroundPicUrl != null && _backgroundPicUrl!.startsWith('http')) {
        await NetworkImage(_backgroundPicUrl!).evict();
      }

      downloadUrl = "$downloadUrl&v=${DateTime.now().millisecondsSinceEpoch}";
      _backgroundPicUrl = downloadUrl;
      await _syncWithFirestore();

      _sendSystemNotification("ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø­Ø³Ø§Ø¨ ðŸ“¸", "ØªÙ… Ø±ÙØ¹ ÙˆØªØ­Ø¯ÙŠØ« ØµÙˆØ±Ø© Ø§Ù„ØºÙ„Ø§Ù Ø¨Ù†Ø¬Ø§Ø­!", "info");
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      debugPrint("Ø®Ø·Ø£ ÙÙŠ Ø±ÙØ¹ ØµÙˆØ±Ø© Ø§Ù„ØºÙ„Ø§Ù: $e");
      _sendSystemNotification("Ø®Ø·Ø£ âš ï¸", "ÙØ´Ù„ Ø±ÙØ¹ ØµÙˆØ±Ø© Ø§Ù„ØºÙ„Ø§Ù.", "error");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPlayerById(String targetUid) async {
    if (_profilesCache.containsKey(targetUid)) {
      return _profilesCache[targetUid];
    }
    try {
      DocumentSnapshot serverDoc = await _firestore.collection('players').doc(targetUid).get(const GetOptions(source: Source.server));
      if (serverDoc.exists) {
        Map<String, dynamic> data = serverDoc.data() as Map<String, dynamic>;
        data['uid'] = serverDoc.id;
        if (_profilesCache.length >= PlayerProvider._maxProfilesCacheSize) {
          _profilesCache.remove(_profilesCache.keys.first);
        }
        _profilesCache[targetUid] = data;
        return data;
      }
    } catch (e) {
      debugPrint("Ø®Ø·Ø£ ÙÙŠ Ø¬Ù„Ø¨ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù„Ø§Ø¹Ø¨: $e");
    }
    return null;
  }
}
