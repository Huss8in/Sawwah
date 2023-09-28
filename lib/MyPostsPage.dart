import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post.dart';
import 'PostCard.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({Key? key}) : super(key: key);

  @override
  _MyPostsPageState createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  late String _userId;
  late List<Post> _posts;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _posts = [];
    _fetchPosts();
  }

  void _fetchPosts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Posts')
        .where('userId', isEqualTo: _userId)
        .get();

    final List<Post> loadedPosts = [];
    for (var doc in snapshot.docs) {
      loadedPosts.add(Post.fromJson(doc));
    }

    setState(() {
      _posts = loadedPosts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Posts',
          style: TextStyle(
            fontFamily: 'PharaonicFont',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple,
                Colors.blue,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];

          // ignore: unnecessary_null_comparison
          if (post == null) {
            return const Center(
              child: Text('You haven\'t posted yet :('),
            );
          } else {
            return PostCard(post: post);
          }
        },
      ),
    );
  }
}
