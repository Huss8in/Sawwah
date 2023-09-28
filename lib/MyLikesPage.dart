import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post.dart';
import 'PostCard.dart';

class MyLikesPage extends StatefulWidget {
  const MyLikesPage({Key? key}) : super(key: key);

  @override
  _MyLikesPageState createState() => _MyLikesPageState();
}

class _MyLikesPageState extends State<MyLikesPage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // User is not logged in, do something like show a login screen
      return;
    }

    // Fetch posts where the current user's UUID is in the likedBy array field
    _stream = FirebaseFirestore.instance
        .collection('Posts')
        .where('likedBy', arrayContains: currentUser.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Likes',
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final posts =
              snapshot.data!.docs.map((doc) => Post.fromJson(doc)).toList();

          if (posts.isEmpty) {
            return const Center(
              child: Text('You haven\'t liked any posts yet.'),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/post', arguments: post);
                  },
                  child: PostCard(post: post));
            },
          );
        },
      ),
    );
  }
}
