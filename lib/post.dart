import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  late String id;
  late String title;
  late String author;
  late String body;
  late List<String> imageUrl;
  late String userId;
  late String location;
  // List<Comment> comments;
  late List<String> likedBy;
  late String category;
  late String likescounter;
  Post({
    required this.id,
    required this.title,
    required this.author,
    required this.body,
    required this.imageUrl,
    required this.location,
    required this.userId,
    this.category = "",
    this.likedBy = const [],
  });

  factory Post.fromJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Post(
      author: data['author'] ?? '',
      title: data['title'] ?? '',
      id: doc.id,
      location: data['location'] ?? '',
      imageUrl: List<String>.from(data['imageUrl'] ?? []),
      body: data['body'] ?? '',
      userId: data['userId'] ?? '',
      likedBy: List<String>.from(data['likedBy'] ?? []),
      category: data['category'] ?? '',
    );
  }

  Future<Map<String, dynamic>> toJson() async => {
        'id': id,
        'location': location,
        'imageUrl': imageUrl,
        'body': body,
        // 'comments': comments.map((comment) => comment.toJson()).toList(),
        'title': title,
        'author': author,
        'userId': userId,
        'likedBy': likedBy,
        'category': category,
      };

  static Post fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Post(
      author: data['author'] ?? '',
      imageUrl: List<String>.from(data['imageUrls'] ?? []),
      location: data['location'] ?? '',
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      userId: data['userId'] ?? '',
      likedBy: List<String>.from(data['likedBy'] ?? []),
      category: data['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'location': location,
      'imageUrl': imageUrl,
      'userId': userId,
      'likedBy': likedBy,
      'category': category,
    };
  }
}

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];

  List<Post> get posts => [..._posts];

  void addPost(Post post) {
    _posts.add(post);
    notifyListeners();
  }

  void deletePost(String id) {
    _posts.removeWhere((post) => post.id == id);
    notifyListeners();
  }

  Future<List<Post>> fetchPosts() async {
    final postsRef = FirebaseFirestore.instance.collection('Posts');
    final snapshot = await postsRef.get();
    final List<Post> loadedPosts = [];
    for (var doc in snapshot.docs) {
      loadedPosts.add(Post.fromJson(doc));
    }
    _posts = loadedPosts;
    notifyListeners();

    return loadedPosts;
  }
}
