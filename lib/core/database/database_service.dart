import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

abstract class DatabaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'projeodevdb');

  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    final reference = firestore.doc(path);
    await reference.set(data, SetOptions(merge: merge));
  }

  Future<void> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    final reference = firestore.collection(collectionPath);
    await reference.add(data);
  }

  Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = firestore.doc(path);
    await reference.update(data);
  }

  Future<void> deleteDocument({required String path}) async {
    final reference = firestore.doc(path);
    await reference.delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String path,
  }) async {
    final reference = firestore.doc(path);
    return await reference.get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> collectionStream({
    required String path,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> documentStream({
    required String path,
  }) {
    final reference = firestore.doc(path);
    return reference.snapshots();
  }
}
