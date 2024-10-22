import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HashtagPostsPage extends StatelessWidget {
  final String hashtag;

  const HashtagPostsPage({Key? key, required this.hashtag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          'Posts for $hashtag',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 25,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('hashtags', arrayContains: hashtag)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id; // 포스트 ID
              return _buildPostItem(context, post, postId);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostItem(
      BuildContext context, Map<String, dynamic> post, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = (post['likes'] ?? []).contains(user?.uid);

    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post['author'] ?? 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(post['content'] ?? ''),
            if (post['hashtags'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: List<Widget>.from(post['hashtags'].map<Widget>((hashtag) {
                    return GestureDetector(
                      onTap: () {
                        // Handle hashtag tap here if needed
                      },
                      child: Text(
                        hashtag,
                        style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    );
                  })),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null),
                  onPressed: () => _toggleLike(postId, post['likes'] ?? []),
                ),
                Text('${(post['likes'] ?? []).length}'),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () => _showPostDialog(context, post, postId),
                ),
                Text('${post['commentCount'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /*Widget _buildPostItem(
      BuildContext context, Map<String, dynamic> post, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = (post['likes'] ?? []).contains(user?.uid);

    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post['author'] ?? 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(post['content'] ?? ''),
            if (post['hashtags'] != null)
              Wrap(
                spacing: 8.0,
                children:
                    List<Widget>.from(post['hashtags'].map<Widget>((hashtag) {
                  return Chip(label: Text(hashtag));
                })),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null),
                  onPressed: () => _toggleLike(postId, post['likes'] ?? []),
                ),
                Text('${(post['likes'] ?? []).length}'),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () => _showPostDialog(context, post, postId),
                ),
                Text('${post['commentCount'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }*/

  Future<void> _toggleLike(String postId, List likes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isLiked = likes.contains(user.uid);
      final postRef =
      FirebaseFirestore.instance.collection('posts').doc(postId);

      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    }
  }

  // 댓글 다이얼로그 구현
  void _showPostDialog(
      BuildContext context, Map<String, dynamic> post, String postId) {
    final TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Comments", style: TextStyle(fontSize: 20)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildCommentsSection(postId),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    child: const Text("Post Comment"),
                    onPressed: () {
                      _addComment(postId, _commentController.text);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addComment(String postId, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && comment.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'author': user.email,
        'content': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    }
  }

  Widget _buildCommentsSection(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(comment['author'] ?? 'Anonymous'),
              subtitle: Text(comment['content'] ?? ''),
            );
          },
        );
      },
    );
  }
}
