// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'post.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class PostCard extends StatelessWidget {
  final Post post;
  Future<double> getPostRatingAverage(String postId) async {
    final QuerySnapshot<Map<String, dynamic>> ratingSnapshot =
        await FirebaseFirestore.instance
            .collection('Rating')
            .where('postId', isEqualTo: postId)
            .get();

    if (ratingSnapshot.docs.isEmpty) {
      return 0.0;
    }

    final List ratings = ratingSnapshot.docs.map((doc) => doc['rate']).toList();
    final double totalRating =
        ratings.map((rating) => rating.toDouble()).reduce((a, b) => a + b);

    final double averageRating = totalRating / ratings.length;

    return averageRating;
  }

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    Future<void> likePost(Post post) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final postRef =
            FirebaseFirestore.instance.collection('Posts').doc(post.id);
        final postDoc = await postRef.get();
        final likedBy = postDoc.data()?['likedBy'] ?? [];
        if (likedBy.contains(currentUser.uid)) {
          await postRef.update({
            'likedBy': FieldValue.arrayRemove([currentUser.uid]),
            'likes': FieldValue.increment(-1),
          });
        } else {
          await postRef.update({
            'likedBy': FieldValue.arrayUnion([currentUser.uid]),
            'likes': FieldValue.increment(1),
          });
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/post', arguments: post);
      },
      child: Card(
        elevation: 4,
        child: SizedBox(
          height: 400, // set a fixed height
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    post.imageUrl.isNotEmpty ? post.imageUrl[0] : '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      post.author,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          likePost(post);
                        } else {
                          Navigator.pushNamed(context, '/login');
                        }
                      },
                      icon: Icon(
                        // Check if the current user's ID is in the likedBy array of the post
                        post.likedBy.contains(
                                FirebaseAuth.instance.currentUser?.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.likedBy.contains(
                                FirebaseAuth.instance.currentUser?.uid)
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    Text(
                      post.likedBy.length.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    IconButton(
                      onPressed: () {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          Navigator.pushNamed(context, '/post',
                              arguments: post);
                        } else {
                          Navigator.pushNamed(context, '/login');
                        }
                      },
                      icon: const Icon(
                        Icons.insert_comment_outlined,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          // Share post title and image URL to other apps
                          await Share.share(
                              '${post.title}\n${post.imageUrl.isNotEmpty ? post.imageUrl[0] : ''} \n${'Check this place out in Egypt!'}');

                          // Show snackbar after 1 second delay
                          Future.delayed(const Duration(seconds: 5), () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Post shared!'),
                              ),
                            );
                          });
                        } else {
                          Navigator.pushNamed(context, '/login');
                        }
                      },
                      icon: const Icon(
                        Icons.share,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.yellow[700],
                        ),
                        const SizedBox(width: 5),
                        FutureBuilder<double>(
                          future: getPostRatingAverage(post.id),
                          builder: (context, snapshot) {
                            // if (snapshot.connectionState ==
                            //     ConnectionState.waiting) {
                            //   return Text(
                            //     "Calculating rating...",
                            //     style: TextStyle(color: Colors.grey),
                            //   );
                            // }
                            final averageRating = snapshot.data ?? 0.0;
                            return Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.grey),
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
