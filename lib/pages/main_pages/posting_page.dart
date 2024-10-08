import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'HashtagPostsPage.dart';

class PostingPage extends StatefulWidget {
  final int? initialScrollToIndex;

  const PostingPage({super.key, this.initialScrollToIndex});

  @override
  State<PostingPage> createState() => _PostingPageState();
}

class _PostingPageState extends State<PostingPage> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialScrollToIndex != null) {
        _scrollToIndex(widget.initialScrollToIndex!);
      }
    });
  }

  void _scrollToIndex(int index) {
    // 스크롤 이동 로직
    double position = index * 100.0;
    _scrollController.animateTo(position,
        duration: Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _postController.text.isNotEmpty) {
      List<String> hashtags = _extractHashtags(_postController.text);
      String postContent = _removeHashtags(_postController.text);

      // Create the post in Firestore
      try {
        await FirebaseFirestore.instance.collection('posts').add({
          'author': user.email,
          'content': postContent,
          'hashtags': hashtags,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
          'commentCount': 0,
        });

        print("Post created successfully");
      } catch (e) {
        print("Error creating post in Firestore: ${e.toString()}");
      }

      setState(() {
        _postController.clear();
      });
    } else {
      print("User is not authenticated or post content is empty.");
    }
  }

  List<String> _extractHashtags(String content) {
    final RegExp hashtagRegExp = RegExp(r'#\w+');
    return hashtagRegExp.allMatches(content).map((match) => match.group(0)!).toList();
  }

  String _removeHashtags(String content) {
    final RegExp hashtagRegExp = RegExp(r'#\w+\s*');
    return content.replaceAll(hashtagRegExp, '').trim();
  }

  Future<void> _addComment(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _commentController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'author': user.email,
        'content': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      setState(() {
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          "Posting Hub",
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
      ),
      body: Column(
        children: [
          _buildPostInputArea(),
          Expanded(child: _buildPostList()), // ListView.builder에 controller 추가
        ],
      ),
    );
  }

  Widget _buildPostInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            onPressed: _createPost,
            icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;
            return GestureDetector(
              onTap: () => _showPostDialog(post, postId),
              child: _buildPostItem(post, postId),
            );
          },
        );
      },
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = (post['likes'] ?? []).contains(user?.uid);

    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(post['author'] ?? 'Anonymous', style: TextStyle(fontWeight: FontWeight.bold)),
                if (post['author'] == user?.email)
                  IconButton(
                    icon: Icon(Icons.delete_outline_outlined, color: Colors.black),
                    onPressed: () => _deletePost(postId),
                  ),
              ],
            ),
            SizedBox(height: 5),
            Text(post['content'] ?? ''),
            if (post['hashtags'] != null)
              Wrap(
                spacing: 8.0,
                children: List<Widget>.from(post['hashtags'].map<Widget>((hashtag) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HashtagPostsPage(hashtag: hashtag),
                        ),
                      );
                    },
                    child: Chip(label: Text(hashtag)),
                  );
                })),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  post['timestamp'] != null
                      ? post['timestamp'].toDate().toString()
                      : 'Just now',
                  style: TextStyle(color: Colors.grey),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
                      onPressed: () => _toggleLike(postId, post['likes'] ?? []),
                    ),
                    Text('${(post['likes'] ?? []).length}'),
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () => _showPostDialog(post, postId),
                    ),
                    Text('${post['commentCount'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(String postId, List likes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isLiked = likes.contains(user.uid);
      final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

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

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  Future<void> _deleteComment(String postId, String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // commentCount를 감소시키는 부분 추가
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }

  void _showPostDialog(Map<String, dynamic> post, String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: 400),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Comments", style: TextStyle(fontSize: 20)),
                      IconButton(
                        icon: Icon(Icons.close),
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
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    child: Text("Post Comment"),
                    onPressed: () {
                      _addComment(postId);
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
          return Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index].data() as Map<String, dynamic>;
            final commentId = comments[index].id; // 댓글 ID를 가져옵니다.
            return _buildCommentItem(comment, postId, commentId);
          },
        );
      },
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, String postId, String commentId) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      margin: EdgeInsets.all(7),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(comment['author'] ?? 'Anonymous', style: TextStyle(fontSize: 10)),
            if (comment['author'] == user?.email)
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteComment(postId, commentId), // 댓글 삭제 호출
              ),
          ],
        ),
        subtitle: Text(comment['content'] ?? ''),
        contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      ),
    );
  }
}
