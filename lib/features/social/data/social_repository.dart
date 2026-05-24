import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/database/database_service.dart';
import '../../../core/di/service_locator.dart';

class SocialRepository extends DatabaseService {
  final String postsCollection = 'social_posts';

  // Create a new post
  Future<void> createPost(String userId, Map<String, dynamic> postData) async {
    await addDocument(
      collectionPath: postsCollection,
      data: {
        'userId': userId,
        ...postData,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
      },
    );
    ServiceLocator.gamification.incrementAction(userId, 'recipesPostedCount');
    ServiceLocator.gamification.incrementDailyQuest(userId, 'dailyRecipesShared');
  }

  // Get posts feed
  Stream<QuerySnapshot<Map<String, dynamic>>> getFeedPosts() {
    return collectionStream(
      path: postsCollection,
      queryBuilder: (query) => query.orderBy('createdAt', descending: true),
    );
  }

  // Get user's posts
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPosts(String userId) {
    return collectionStream(
      path: postsCollection,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true),
    );
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    final docRef = firestore.collection(postsCollection).doc(postId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final likedBy = List<String>.from(snapshot.data()?['likedBy'] ?? []);
      if (likedBy.contains(userId)) {
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayRemove([userId]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        transaction.update(docRef, {
          'likedBy': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }

  // Comment on a post
  Future<void> addComment(String postId, String userId, String text, String authorName, String authorLetter) async {
    final commentsCol = firestore.collection('$postsCollection/$postId/comments');
    await commentsCol.add({
      'userId': userId,
      'authorName': authorName,
      'authorLetter': authorLetter,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await updateDocument(
      path: '$postsCollection/$postId',
      data: {'commentsCount': FieldValue.increment(1)},
    );
    
    ServiceLocator.gamification.incrementAction(userId, 'commentsCount');
    ServiceLocator.gamification.incrementDailyQuest(userId, 'dailyComments');
  }
  
  // Get comments
  Stream<QuerySnapshot<Map<String, dynamic>>> getComments(String postId) {
    return collectionStream(
      path: '$postsCollection/$postId/comments',
      queryBuilder: (query) => query.orderBy('createdAt', descending: false),
    );
  }

  // Upload Photo to Firebase Storage -> Returns Base64 String
  Future<String?> uploadImage(String userId, File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('Görsel yükleme/dönüştürme hatası: $e');
      return null;
    }
  }

  // Follow user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    final followingRef = firestore.collection('users').doc(currentUserId).collection('following').doc(targetUserId);
    final followersRef = firestore.collection('users').doc(targetUserId).collection('followers').doc(currentUserId);
    
    await followingRef.set({'createdAt': FieldValue.serverTimestamp()});
    await followersRef.set({'createdAt': FieldValue.serverTimestamp()});
    
    ServiceLocator.gamification.incrementAction(targetUserId, 'followersCount');
  }

  // Unfollow user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final followingRef = firestore.collection('users').doc(currentUserId).collection('following').doc(targetUserId);
    final followersRef = firestore.collection('users').doc(targetUserId).collection('followers').doc(currentUserId);
    
    await followingRef.delete();
    await followersRef.delete();
  }

  // Check if following
  Stream<bool> isFollowingStream(String currentUserId, String targetUserId) {
    if (currentUserId.isEmpty || targetUserId.isEmpty) return Stream.value(false);
    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
