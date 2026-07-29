import 'package:flutter/material.dart';

import 'comment_service.dart';

class CommentsSection extends StatefulWidget {
  final String recipeName;

  const CommentsSection({super.key, required this.recipeName});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? _editingCommentId;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _startEdit(Comment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _emailController.text = comment.email;
      _messageController.text = comment.message;
    });
  }

  void _clearForm() {
    setState(() {
      _editingCommentId = null;
      _errorMessage = null;
      _emailController.clear();
      _messageController.clear();
    });
  }

  Future<void> _submitComment() async {
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    if (email.isEmpty || message.isEmpty) {
      setState(() {
        _errorMessage = 'Email and message are required';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_editingCommentId != null) {
        await CommentService.updateComment(
          widget.recipeName,
          _editingCommentId!,
          email,
          message,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment updated')),
          );
        }
      } else {
        await CommentService.addComment(widget.recipeName, email, message);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment added')),
          );
        }
      }
      _clearForm();
    } catch (error) {
      setState(() {
        _errorMessage = 'Error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String id) async {
    try {
      await CommentService.deleteComment(widget.recipeName, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error deleting: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Comment form
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email',
              hintText: 'your@email.com',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Comment',
              hintText: 'Share your thoughts...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitComment,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _editingCommentId != null ? Icons.edit : Icons.add,
                      ),
                label: Text(
                  _editingCommentId != null ? 'Update' : 'Add Comment',
                ),
              ),
              if (_editingCommentId != null)
                ElevatedButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Comments list — driven by a real-time Firestore stream
          const Text(
            'All Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Comment>>(
            stream: CommentService.commentsStream(widget.recipeName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }

              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No comments yet. Be the first to comment!'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  comment.email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _startEdit(comment);
                                  } else if (value == 'delete') {
                                    _deleteComment(comment.id);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(comment.message),
                          if (comment.createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(comment.createdAt!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
