import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'projeodevdb');

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> sendMockWelcomeNotification(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'AuraCook\'a Hoş Geldiniz!',
      'message': 'Gelişmiş Aura AI özellikleri, hedefleriniz ve diyet listelerinizle harika bir yolculuğa çıkmaya hazırsınız.',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}
