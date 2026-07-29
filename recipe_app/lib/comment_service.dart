import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String email;
  final String message;
  final DateTime? createdAt;

  const Comment({
    required this.id,
    required this.email,
    required this.message,
    this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      email: data['email']?.toString() ?? 'unknown@email.com',
      message: data['message']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Comment copyWith({
    String? id,
    String? email,
    String? message,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      email: email ?? this.email,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
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
    final docRef = await _collection(recipeName).add({
      'email': email,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Comment(id: docRef.id, email: email, message: message);
  }

  static Future<void> updateComment(
    String recipeName,
    String id,
    String email,
    String message,
  ) async {
    await _collection(recipeName).doc(id).update({
      'email': email,
      'message': message,
    });
  }

  static Future<void> deleteComment(String recipeName, String id) async {
    await _collection(recipeName).doc(id).delete();
  }
}
