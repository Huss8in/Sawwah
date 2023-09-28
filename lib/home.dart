import 'AddPostScreen.dart';
import 'PostCard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'post.dart';
import 'search.dart';
import 'MyPostsPage.dart';
import 'MyLikesPage.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _searchController;
  int _currentCategoryIndex = 0;
  final List<String> categories = [
    'All',
    'Museum',
    'Club',
    'Restaurant',
    'Other'
  ];
  late User _currentUser; // Add this line

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _currentUser =
        FirebaseAuth.instance.currentUser!; // Retrieve the current user
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final CollectionReference postsCollection =
      FirebaseFirestore.instance.collection('Posts');

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> unsubscribeFromTopic() async {
    await messaging.unsubscribeFromTopic('all_users');
  }

  //make function to extract the characters before the @ sign in the email
  String extractUsername(String email) {
    return email.split('@')[0];
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPostScreen()),
              );
              if (result != null) {
                setState(() {
                  // add new post to the list of posts
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // User details section
            UserAccountsDrawerHeader(
              accountName: Text(
                extractUsername(_currentUser.email ?? ''),
                style: const TextStyle(
                  color: Colors.white, // Set the text color
                ),
              ),
              accountEmail: Text(
                _currentUser.email ?? '',
                style: const TextStyle(
                  color: Colors.white, // Set the text color
                ),
              ),
              // currentAccountPicture: const CircleAvatar(
              //     // W,
              //     ),
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

            // Add space above drawer header
            // const SizedBox(height: 0),

            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('My Posts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyPostsPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Likes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyLikesPage()),
                );
              },
            ),

            // Button to sign out
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                unsubscribeFromTopic();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool('isLoggedIn', false);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/main', (route) => false);
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: CarouselSlider(
              items: categories.map((category) {
                return Builder(
                  builder: (BuildContext context) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _currentCategoryIndex = categories.indexOf(category);
                        });
                      },
                      child: Container(
                        width: double.infinity, // Take full width
                        height: 40.0,
                        // Set a larger height as desired
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              color: _currentCategoryIndex ==
                                      categories.indexOf(category)
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
              options: CarouselOptions(
                height: 50.0, // Set a larger height as desired
                viewportFraction: 1.0, // Take full width of the page
                initialPage: _currentCategoryIndex,
                enableInfiniteScroll: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCategoryIndex = index;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Post>>(
              future: postProvider.fetchPosts(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Post>> snapshot) {
                if (snapshot.hasData) {
                  List<Post> filteredPosts;
                  if (_currentCategoryIndex == 0) {
                    filteredPosts = snapshot.data!;
                  } else {
                    String selectedCategory = categories[_currentCategoryIndex];
                    filteredPosts = snapshot.data!
                        .where((post) => post.category == selectedCategory)
                        .toList();
                  }
                  return ListView.builder(
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/post',
                              arguments: {'post': post});
                        },
                        child: Padding(
                          padding: EdgeInsets.zero,
                          child: Card(
                            elevation: 20.0,
                            child: PostCard(post: post),
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     final result = await Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const AddPostScreen()),
      //     );
      //     if (result != null) {
      //       setState(() {
      //         //add new post to the list of posts
      //       });
      //     }
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
