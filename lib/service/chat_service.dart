import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // Global Chat
  // ---------------------------------------------------------------------------

  Stream<QuerySnapshot> getGlobalChatStream() {
    return _firestore
        .collection('global_chat')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> sendGlobalMessage(String text, {String? replyToMessageId, Map<String, dynamic>? tagData}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Harus login untuk mengirim pesan");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final displayName = userDoc.data()?['displayName'] ?? 'User';
    final photoUrl = userDoc.data()?['photoUrl'] ?? '';

    final payload = <String, dynamic>{
      'senderId': user.uid,
      'senderName': displayName,
      'senderPhotoUrl': photoUrl,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'replyToMessageId': replyToMessageId,
    };
    
    if (tagData != null) {
      payload['tagData'] = tagData;
    }

    await _firestore.collection('global_chat').add(payload);
  }

  Future<void> editGlobalMessage(String messageId, String newText) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('global_chat').doc(messageId).update({
      'text': newText.trim(),
      'isEdited': true,
    });
  }

  Future<void> deleteGlobalMessage(String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('global_chat').doc(messageId).delete();
  }

  // ---------------------------------------------------------------------------
  // Private Chat
  // ---------------------------------------------------------------------------

  String _getChatRoomId(String userId1, String userId2) {
    // Pastikan ID selalu konsisten (diurutkan alfabet)
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Stream<QuerySnapshot> getChatHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Harus login");

    return _firestore
        .collection('private_chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPrivateChatStream(String peerId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final roomId = _getChatRoomId(user.uid, peerId);

    return _firestore
        .collection('private_chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> sendPrivateMessage(String peerId, String text, {String? replyToMessageId, Map<String, dynamic>? tagData}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Harus login untuk mengirim pesan");

    final roomId = _getChatRoomId(user.uid, peerId);
    
    final payload = <String, dynamic>{
      'senderId': user.uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'replyToMessageId': replyToMessageId,
    };

    if (tagData != null) {
      payload['tagData'] = tagData;
    }

    // Kita simpan pesan di subcollection 'messages'
    await _firestore
        .collection('private_chats')
        .doc(roomId)
        .collection('messages')
        .add(payload);

    // Kita juga bisa menyimpan metadata chat room untuk list obrolan
    await _firestore.collection('private_chats').doc(roomId).set({
      'participants': [user.uid, peerId],
      'lastMessage': text.trim(),
      'lastTimestamp': FieldValue.serverTimestamp(),
      'lastSenderId': user.uid,
    }, SetOptions(merge: true));
  }

  Future<void> editPrivateMessage(String peerId, String messageId, String newText) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final roomId = _getChatRoomId(user.uid, peerId);
    await _firestore
        .collection('private_chats')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText.trim(),
      'isEdited': true,
    });
  }

  Future<void> deletePrivateMessage(String peerId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final roomId = _getChatRoomId(user.uid, peerId);
    await _firestore
        .collection('private_chats')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
