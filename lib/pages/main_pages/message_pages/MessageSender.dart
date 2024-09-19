import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageSender {
  Future<void> sendMessage(String text, String userId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && text.isNotEmpty) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      String userName = userSnapshot.get('name');
      String userAvatar = userSnapshot.get('avatar');

      FirebaseFirestore.instance.collection('messages').add({
        'text': text,
        'sender': user.uid,
        'senderName': userName,
        'senderAvatar': userAvatar,
        'timestamp': FieldValue.serverTimestamp(),
        'isPrivate': false,
      });
    }
  }
}