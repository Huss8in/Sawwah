import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  // final Timestamp time;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    // required this.time,
  });

  factory Comment.fromJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      //  time: json['time'],
    );
  }

  String get userImage => userImage;

  String get username => username;

  String get comment => comment;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'content': content,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'content': content,
    };
  }
}

class CommentProvider with ChangeNotifier {
  List<Comment> _comments = [];

  List<Comment> get comments => [..._comments];

  Future<void> addComment(Comment comment) async {
    final commentsRef = FirebaseFirestore.instance.collection('Comments');
    await commentsRef.add(comment.toJson());
    notifyListeners();
  }

  Future<void> deleteComment(String id) async {
    final commentsRef = FirebaseFirestore.instance.collection('Comments');
    await commentsRef.doc(id).delete();
    notifyListeners();
  }

  Future<void> updateComment(Comment comment) async {
    final commentsRef = FirebaseFirestore.instance.collection('Comments');
    await commentsRef.doc(comment.id).update(comment.toJson());
    notifyListeners();
  }

  Future<void> fetchComments(String postId) async {
    final commentsRef = FirebaseFirestore.instance.collection('Comments');
    final snapshot = await commentsRef.where('postId', isEqualTo: postId).get();

    final comments = snapshot.docs
        .map((doc) => Comment.fromJson(doc.data() as DocumentSnapshot<Object?>))
        .toList();

    _comments = comments;
    notifyListeners();
  }
}

class CommentWidget extends StatelessWidget {
  final Comment comment;

  const CommentWidget({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(comment.userImage),
      ),
      title: Text(comment.username),
      subtitle: Text(comment.comment),
    );
  }
}
