// ignore_for_file: use_build_context_synchronously

import 'EditPostScreen.dart';
import 'MyLikesPage.dart';
import 'home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'login.dart';
import 'search.dart';
import 'post.dart';
import 'PostCard.dart';
import 'PostDetails.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Initialize Firebase App
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
        // add other providers if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    tired();
  }

  tired() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn');

    setState(() {
      _isLoggedIn = isLoggedIn ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    postProvider.fetchPosts();

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      initialRoute: _isLoggedIn ? '/home' : '/main',
      routes: {
        '/post': (context) => PostDetails(
            post: ModalRoute.of(context)?.settings.arguments as Post),
        '/search': (context) => const SearchPage(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
        '/favorites': (context) => const MyLikesPage(),
        '/edit_post': (context) => EditPostScreen(
            post: ModalRoute.of(context)?.settings.arguments as Post),
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 8),
            Text(
              'Sawwahh',
              style: TextStyle(
                fontFamily: 'PharaonicFont',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
          // const Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 16),
          //   child: SizedBox(
          //     width: 250,
          //   ),
          // ),
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
      body: Center(
        child: FutureBuilder<List<Post>>(
          future: postProvider.fetchPosts(),
          builder: (BuildContext context, AsyncSnapshot<List<Post>> snapshot) {
            if (snapshot.hasData) {
              return SizedBox(
                height: 1000,
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final post = snapshot.data![index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/post',
                            arguments: {'post': post});
                      },
                      child: PostCard(post: post),
                    );
                  },
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
