import 'package:flutter/material.dart';

class SeePostScreen extends StatelessWidget {
  final String userName;
  final String postPhotoUrl; // Placeholder for image URL
  final String postText;

  const SeePostScreen({
    super.key,
    required this.userName,
    required this.postPhotoUrl,
    required this.postText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Birthday Post'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                postText,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              // Placeholder for "Love HB/holiday wishes" functionality
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You liked $userName\'s post!')),
                    );
                  },
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Love this post!'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
