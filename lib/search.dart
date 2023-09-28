import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'PostCard.dart';
import 'post.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late List<Post> _searchResults;

  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchResults = [];
    _searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final posts = Provider.of<PostProvider>(context).posts;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.blue],
              begin: Alignment.bottomLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              // Update the search query here
              //search for posts
              _searchResults = posts
                  .where((post) =>
                      post.title.toLowerCase().contains(value.toLowerCase()) ||
                      post.body.toLowerCase().contains(value.toLowerCase()) ||
                      post.location
                          .toLowerCase()
                          .contains(value.toLowerCase()) ||
                      post.author.toLowerCase().contains(value.toLowerCase()))
                  .toList();
            });
          },
        ),
      ),
      body: _searchResults.isNotEmpty
          ? ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) =>
                  PostCard(post: _searchResults[index]),
            )
          : const Center(
              child: Text('No search results'),
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
