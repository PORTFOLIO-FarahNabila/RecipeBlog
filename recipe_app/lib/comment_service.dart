import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Comment {
  final String id;
  final String userId;
  final String email;
  final String message;
  final DateTime? createdAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.email,
    required this.message,
    this.createdAt,
  });

  /// Whether the currently signed-in user is the one who wrote this comment.
  /// Comments created before ownership tracking was added (no userId
  /// stored) will not be editable/deletable by anyone.
  bool get isOwnedByCurrentUser {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return userId.isNotEmpty && uid != null && userId == uid;
  }

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      email: data['email']?.toString() ?? 'unknown@email.com',
      message: data['message']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class CommentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _collection(
    String recipeName,
  ) {
    return _db
        .collection('comments')
        .doc(recipeName)
        .collection('entries');
  }

  static Stream<List<Comment>> commentsStream(String recipeName) {
    return _collection(recipeName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList(),
        );
  }

  static Future<Comment> addComment(
    String recipeName,
    String email,
    String message,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final docRef = await _collection(recipeName).add({
      'userId': uid,
      'email': email,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Comment(id: docRef.id, userId: uid, email: email, message: message);
  }

  /// Only the comment's original author may update it. Enforced here for
  /// defense in depth, but this MUST also be enforced with Firestore
  /// Security Rules (see note below), since a client-side check alone
  /// can't stop a modified/rogue client from calling the API directly.
  static Future<void> updateComment(
    String recipeName,
    String id,
    String email,
    String message,
  ) async {
    await _requireOwnership(recipeName, id);
    await _collection(recipeName).doc(id).update({
      'email': email,
      'message': message,
    });
  }

  static Future<void> deleteComment(String recipeName, String id) async {
    await _requireOwnership(recipeName, id);
    await _collection(recipeName).doc(id).delete();
  }

  static Future<void> _requireOwnership(String recipeName, String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc = await _collection(recipeName).doc(id).get();
    final ownerId = doc.data()?['userId']?.toString();

    if (uid == null || ownerId == null || ownerId.isEmpty || uid != ownerId) {
      throw Exception('You can only edit or delete your own comments.');
    }
  }
}
