// المسار: lib/providers/player_social_logic.dart

part of 'player_provider.dart';

extension PlayerSocialLogic on PlayerProvider {

  void createGang(String name) { if (!isInGang && _cash >= 1000000) { _cash -= 1000000; _gangName = name; _gangRank = "زعيم"; _syncWithFirestore(); notifyListeners(); } }
  void contributeToGang(int amount) { if (isInGang && _cash >= amount) { _cash -= amount; _gangContribution += amount; _syncWithFirestore(); notifyListeners(); } }
  void winGangWar(String territory) { if (isInGang) { _gangWarWins++; _territoryOwners[territory] = _gangName!; _syncWithFirestore(); notifyListeners(); } }
  void leaveGang() { _gangName = null; _gangRank = "عضو"; _gangContribution = 0; _syncWithFirestore(); notifyListeners(); }

  Future<void> sendFriendRequest(String tUid) async {
    if (_uid == null || _uid == tUid) return;
    try {
      await _firestore.collection('players').doc(tUid).collection('friend_requests').doc(_uid).set({
        'senderId': _uid,
        'senderName': _playerName,
        'picUrl': _profilePicUrl,
        'timestamp': FieldValue.serverTimestamp()
      });
      _showNotification("🤝 تم إرسال طلب الصداقة!");
    } catch (e) {}
  }

  Future<void> acceptFriend(String rUid, String rName) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('players').doc(_uid).collection('friend_requests').doc(rUid).delete();
      await _firestore.collection('players').doc(_uid).collection('friends').doc(rUid).set({'uid': rUid, 'name': rName, 'date': FieldValue.serverTimestamp()});
      await _firestore.collection('players').doc(rUid).collection('friends').doc(_uid).set({'uid': _uid, 'name': _playerName, 'date': FieldValue.serverTimestamp()});
      _showNotification("✅ تمت إضافة $rName كصديق!");
      notifyListeners();
    } catch (e) {}
  }

  Future<void> rejectFriend(String rUid) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('players').doc(_uid).collection('friend_requests').doc(rUid).delete();
      notifyListeners();
    } catch (e) {}
  }
}