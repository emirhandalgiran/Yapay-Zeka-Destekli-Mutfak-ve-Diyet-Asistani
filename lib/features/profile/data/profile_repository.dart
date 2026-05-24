import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/database/database_service.dart';

class ProfileRepository extends DatabaseService {
  final String collectionPath = 'users';

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await getDocument(path: '$collectionPath/$userId');
    return doc.data();
  }

  // Get user profile stream
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return documentStream(path: '$collectionPath/$userId')
        .map((snapshot) => snapshot.data());
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await setDocument(path: '$collectionPath/$userId', data: data, merge: true);
  }

  // Get saved recipes for user
  Stream<QuerySnapshot<Map<String, dynamic>>> getSavedRecipes(String userId) {
    return collectionStream(
      path: '$collectionPath/$userId/saved_recipes',
    );
  }

  // Save a recipe
  Future<void> saveRecipe(String userId, String recipeId, Map<String, dynamic> recipeData) async {
    await setDocument(
      path: '$collectionPath/$userId/saved_recipes/$recipeId',
      data: recipeData,
      merge: true,
    );
  }

  // Remove a saved recipe
  Future<void> removeSavedRecipe(String userId, String recipeId) async {
    await deleteDocument(path: '$collectionPath/$userId/saved_recipes/$recipeId');
  }

  // Get followers count stream
  Stream<int> getFollowersCount(String userId) {
    return firestore
        .collection(collectionPath)
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get following count stream
  Stream<int> getFollowingCount(String userId) {
    return firestore
        .collection(collectionPath)
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get user's own items count stream (recipes/posts)
  Stream<int> getUserRecipesCount(String userId) {
    return firestore
        .collection('social_posts') // Using social posts as they are the shared items
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
