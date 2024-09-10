import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class PostingPage extends StatefulWidget {
  const PostingPage({super.key});

  @override
  State<PostingPage> createState() => _PostingPageState();
}

class _PostingPageState extends State<PostingPage> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  XFile? _selectedImage;

  @override
  void dispose() {
    _postController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _postController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('posts').add({
        'author': user.email,  // Store the user's email instead of displayName
        'content': _postController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': _selectedImage?.path ?? '',
      });
      setState(() {
        _postController.clear();
        _selectedImage = null;
      });
    }
  }

  Future<void> _addComment(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _commentController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'author': user.email,  // Store the email instead of displayName
        'content': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 댓글 수 증가
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
          Expanded(child: _buildPostList()),
        ],
      ),
    );
  }

  Widget _buildPostInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            onPressed: _pickImage,
            icon: Icon(Icons.image, color: Theme.of(context).colorScheme.primary),
          ),
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
                Text(post['author'] ?? 'Anonymous',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (post['author'] == user?.email || post['author'] == user?.displayName)
                  IconButton(
                    icon: Icon(Icons.delete_outline_outlined, color: Colors.black),
                    onPressed: () => _deletePost(postId),
                  ),
              ],
            ),
            SizedBox(height: 5),
            Text(post['content'] ?? ''),
            if (post['imageUrl'] != null && post['imageUrl'] != '')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.network(post['imageUrl']),
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


  void _showPostDialog(Map<String, dynamic> post, String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7, // max height for the dialog
              minWidth: MediaQuery.of(context).size.width * 0.8,   // width for the dialog
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("Comments:", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: Container(
                          height: 200,
                          child: _buildCommentsSection(postId),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: "Add a comment",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // add comment button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      child: Text("Post Comment"),
                      onPressed: () {
                        _addComment(postId); // add comment
                        Navigator.of(context).pop(); // close dialog
                      },
                    ),
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
        final user = FirebaseAuth.instance.currentUser;

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index].data() as Map<String, dynamic>;
            final commentId = comments[index].id;

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
                    Text(comment['author'] ?? 'Anonymous', style: TextStyle(fontSize: 10),),
                    if (comment['author'] == user?.email)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20,),
                        onPressed: () => _deleteComment(postId, commentId),
                      ),
                  ],
                ),
                subtitle: Text(comment['content'] ?? ''),
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteComment(String postId, String commentId) async {
    try {
      // Delete comment from Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // decrease number of comments
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }
}
