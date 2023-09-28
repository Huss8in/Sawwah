import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditPostScreen.dart';
import 'comment.dart';
import 'post.dart';

class PostDetails extends StatefulWidget {
  final Post post;

  const PostDetails({super.key, required this.post});

  @override
  State<PostDetails> createState() => _PostDetailsState();
}

class _PostDetailsState extends State<PostDetails> {
  int? selectedRating;

  @override
  void initState() {
    super.initState();
    // Set the initial value of selectedRating based on the database
    FirebaseFirestore.instance
        .collection('Rating')
        .doc(widget.post.id)
        .get()
        .then((snapshot) {
      if (snapshot.exists &&
          (snapshot.data() as Map<String, dynamic>).containsKey('rate')) {
        setState(() {
          selectedRating = snapshot.data()!['rate'];
        });
      }
    });
  }

  getuuid() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    final uid = user!.uid;
    return uid;
  }

  @override
  Widget build(BuildContext context) {
    selectedRating = null;

    final post = ModalRoute.of(context)!.settings.arguments as Post;

    final currentUser = FirebaseAuth.instance.currentUser;

    final bool isCurrentUserAuthor = post.userId == currentUser?.uid;

    final bool isCurrentUserLoggedIn = currentUser != null;

    Future<List<Comment>> fetchCommentsForPost(String postId) async {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('Comments')
          .where('postId',
              isEqualTo: //the post document id
                  postId)
          .get();
      final comments = commentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Comment(
          id: doc.id,
          postId: data['postId'],
          content: data['content'],
          userId: data['userId'],
        );
      }).toList();
      return comments;
    }

    Future<double> getPostRatingAverage(String postId) async {
      final QuerySnapshot<Map<String, dynamic>> ratingSnapshot =
          await FirebaseFirestore.instance
              .collection('Rating')
              .where('postId', isEqualTo: postId)
              .get();

      if (ratingSnapshot.docs.isEmpty) {
        return 0.0;
      }

      final List ratings =
          ratingSnapshot.docs.map((doc) => doc['rate']).toList();
      final double totalRating =
          ratings.map((rating) => rating.toDouble()).reduce((a, b) => a + b);

      final double averageRating = totalRating / ratings.length;

      return averageRating;
    }

    Stream<QuerySnapshot> getCommentsStream(String postId) {
      return FirebaseFirestore.instance
          .collection('Comments')
          .where('postId', isEqualTo: postId)
          .snapshots();
    }

    final TextEditingController commentController = TextEditingController();

// function to handle submission of comment
    Future<void> submitComment(
        String postId, String userId, String content, String id) async {
      // create a new comment object
      final newComment = Comment(
        postId: postId,
        userId: userId,
        content: content,
        id: id,
      );
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('Comments')
          .add(newComment.toMap());
    }

    Future<void> deleteComment(String postId, String commentId) async {
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('Comments')
          .doc(commentId)
          .delete();
    }

    Future<void> ratePost(String postId, int rate) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // If there is no user signed in, return without rating the post
        return;
      }

      final userId = currentUser.uid;

      // Check if the user has already rated the post with the same ID and user ID in the "Rating" collection
      final ratingSnapshot = await FirebaseFirestore.instance
          .collection('Rating')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();
      if (ratingSnapshot.docs.isNotEmpty) {
        final ratingDoc = ratingSnapshot.docs.first;
        await ratingDoc.reference.update({'rate': rate});
      } else {
        final newDocRef = FirebaseFirestore.instance.collection('Rating').doc();
        await newDocRef.set({'rate': rate, 'userId': userId, 'postId': postId});
      }
    }

    Widget _buildRatingButtons() {
      final ratings = [1, 2, 3, 4, 5];

      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Rating')
            .where('postId', isEqualTo: post.id)
            .where('userId', isEqualTo: getuuid())
            .snapshots()
            .map((snapshot) => snapshot.docs.first)
            .handleError((error) => null),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasData) {
            final ratingDoc = snapshot.data!;
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null &&
                ratingDoc.exists &&
                (ratingDoc.data() as Map<String, dynamic>)['userId'] ==
                    currentUser.uid) {
              selectedRating =
                  (ratingDoc.data() as Map<String, dynamic>)['rate'] as int;
            }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ratings.map((rating) {
              return GestureDetector(
                onTap: () async {
                  setState(() {
                    selectedRating = rating;
                  });
                  await ratePost(post.id, rating);
                },
                child: Icon(
                  rating <= (selectedRating ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  size: 36.0,
                  color: Colors.orange,
                ),
              );
            }).toList(),
          );
        },
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          title: Text(
            post.title,
            style: const TextStyle(
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
          actions: [
            if (isCurrentUserAuthor)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Post'),
                          content: const Text(
                              'Are you sure you want to delete this post?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Delete'),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('Posts')
                                    .doc(post.id)
                                    .delete();
                                Navigator.of(context).pop();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPostScreen(post: post),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 6),
                        Text('Delete Post'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 6),
                        Text('Edit Post'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // loop through images and display them in a row with a fixed height of 200
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: post.imageUrl.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    post.imageUrl[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    "User: ${post.author}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Location: ${post.location}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Category: ${post.category}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text(
                        "Rating: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      FutureBuilder<double>(
                        future: getPostRatingAverage(post.id),
                        builder: (context, snapshot) {
                          final averageRating = snapshot.data ?? 0.0;
                          return Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.grey),
                          );
                        },
                      ),
                      Icon(
                        Icons.star,
                        color: Colors.yellow[700],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "Description: ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.body,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Divider(
                    color: Colors.grey,
                    height: 10,
                    thickness: 1,
                  ),

                  if (isCurrentUserLoggedIn)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Row(
                        children: [
                          const Text(
                            'Rate this post:',
                            style: TextStyle(
                              fontSize: 18.0,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          _buildRatingButtons(),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // use FutureBuilder to asynchronously build the comments list
                  FutureBuilder<List<Comment>>(
                    future: fetchCommentsForPost(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        // show an error message if the data couldn't be fetched
                        return Center(
                          child: Text('An error occurred: ${snapshot.error}'),
                        );
                      } else {
                        // show the comments list if data is available
                        final comments = snapshot.data;
                        if (comments == null) {
                          return const Center(
                            child: Text('No comments yet!'),
                          );
                        } else {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];

                              final showDeleteButton =
                                  comment.userId == currentUser?.uid;

                              return ListTile(
                                title: Text(comment.content),
                                subtitle: Text('by ${comment.userId}'),
                                trailing: showDeleteButton
                                    ? IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Delete Comment'),
                                                content: const Text(
                                                    'Are you sure you want to delete this comment?'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text('Cancel'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: const Text('Delete'),
                                                    onPressed: () async {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'Comments')
                                                          .where('id',
                                                              isEqualTo:
                                                                  comment.id)
                                                          .get()
                                                          .then((snapshot) {
                                                        snapshot.docs.first
                                                            .reference
                                                            .delete();
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      )
                                    : null,
                              );
                            },
                          );
                        }
                      }
                    },
                  ),

                  if (isCurrentUserLoggedIn)
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Add a comment',
                      ),
                      onSubmitted: (value) async {
                        // Get a reference to the "Comments" collection
                        final commentsRef =
                            FirebaseFirestore.instance.collection('Comments');

                        // Generate a new ID for the comment
                        final commentId = commentsRef.doc().id;

                        // Create a new comment object
                        final newComment = Comment(
                          id: commentId,
                          postId: post
                              .id, // Replace "postId" with the actual ID of the post
                          userId:
                              getuuid(), // Replace "userId" with the actual ID of the current user
                          content: value,
                        );

                        // Add the new comment to the "Comments" collection
                        await commentsRef
                            .doc(commentId)
                            .set(newComment.toJson());

                        // Clear the text field
                        commentController.clear();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
