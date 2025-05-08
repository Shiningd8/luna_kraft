import 'package:cloud_firestore/cloud_firestore.dart';

/// A service class to handle operations related to comments,
/// with special handling for permission issues
class CommentsService {
  /// Get the comment count for a post, excluding deleted comments
  static Future<int> getCommentCount(DocumentReference postRef) async {
    try {
      // Get all comments for this post
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('postref', isEqualTo: postRef)
          .get();

      // Filter out deleted comments
      final nonDeletedCount = commentsSnapshot.docs
          .where((doc) => doc.data()['deleted'] != true)
          .length;

      print(
          'Comment count for post ${postRef.id}: $nonDeletedCount (filtered from ${commentsSnapshot.docs.length} total)');
      return nonDeletedCount;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

  /// Soft delete a comment by marking it as deleted and adding to deleted_comments collection
  ///
  /// Returns true if the soft deletion was successful
  static Future<bool> deleteComment({
    required String commentId,
    String? postId,
    required bool isAuthor,
    required bool isPostOwner,
    String? userId,
  }) async {
    try {
      // Log the deletion attempt with details
      print('====================');
      print('Attempting to soft delete comment $commentId');
      print('Comment deletion context:');
      print('- User ID: $userId');
      print('- Post ID: $postId');
      print('- Is Author: $isAuthor');
      print('- Is Post Owner: $isPostOwner');

      // Allow deletion if user is either the author or the post owner
      if (!isAuthor && !isPostOwner) {
        print(
            'Permission denied: User is neither the comment author nor the post owner');
        return false;
      }

      final commentRef =
          FirebaseFirestore.instance.collection('comments').doc(commentId);

      // Get the comment data before updating
      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) {
        print('Comment not found');
        return false;
      }

      final commentData = commentDoc.data()!;

      // Create a batch for bulk operations
      final batch = FirebaseFirestore.instance.batch();

      // First, get any replies to this comment
      final repliesQuery = await FirebaseFirestore.instance
          .collection('comments')
          .where('parentCommentRef', isEqualTo: commentRef)
          .get();

      print('Found ${repliesQuery.docs.length} replies to soft delete');

      // Mark all replies as deleted
      for (var replyDoc in repliesQuery.docs) {
        batch.update(replyDoc.reference, {
          'deleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': userId,
          'deletedAs': isAuthor ? 'author' : 'post_owner',
        });

        // Also add to deleted_comments collection for admin reference
        final deletedRef =
            FirebaseFirestore.instance.collection('deleted_comments').doc();
        batch.set(deletedRef, {
          'commentId': replyDoc.id,
          'commentRef': replyDoc.reference,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': userId,
          'deletedAs': isAuthor ? 'author' : 'post_owner',
          'postId': postId,
          'comment': replyDoc.data()['comment'],
          'isReply': true,
          'parentCommentId': commentId,
        });
      }

      // Mark the comment itself as deleted
      batch.update(commentRef, {
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': userId,
        'deletedAs': isAuthor ? 'author' : 'post_owner',
      });

      // Add to deleted_comments collection for admin reference
      final deletedRef =
          FirebaseFirestore.instance.collection('deleted_comments').doc();
      batch.set(deletedRef, {
        'commentId': commentId,
        'commentRef': commentRef,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': userId,
        'deletedAs': isAuthor ? 'author' : 'post_owner',
        'postId': postId,
        'comment': commentData['comment'],
        'isReply': commentData['isReply'] ?? false,
        'parentCommentId': commentData['parentCommentRef']?.id,
      });

      // Commit the batch
      await batch.commit();
      print(
          'Successfully soft deleted comment and ${repliesQuery.docs.length} replies');

      // Log who performed the deletion
      if (isAuthor) {
        print('Comment was soft deleted by its author');
      } else if (isPostOwner) {
        print('Comment was soft deleted by the post owner');
      }

      return true;
    } catch (e) {
      print('Error in CommentsService.deleteComment: $e');
      return false;
    }
  }

  /// Get a comment by ID
  static Future<Map<String, dynamic>?> getComment(String commentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error in CommentsService.getComment: $e');
      return null;
    }
  }

  /// Create a comment
  static Future<String?> createComment({
    required String postId,
    required String userId,
    required String comment,
    String? parentCommentId,
  }) async {
    try {
      final data = {
        'comment': comment,
        'date': FieldValue.serverTimestamp(),
        'postref': FirebaseFirestore.instance.collection('posts').doc(postId),
        'userref': FirebaseFirestore.instance.collection('User').doc(userId),
        'likes': [],
        'isReply': parentCommentId != null,
        'deleted': false,
      };

      if (parentCommentId != null) {
        data['parentCommentRef'] = FirebaseFirestore.instance
            .collection('comments')
            .doc(parentCommentId);
      }

      final docRef =
          await FirebaseFirestore.instance.collection('comments').add(data);

      return docRef.id;
    } catch (e) {
      print('Error in CommentsService.createComment: $e');
      return null;
    }
  }

  /// Like or unlike a comment
  static Future<bool> toggleLike({
    required String commentId,
    required String userId,
  }) async {
    try {
      final commentRef =
          FirebaseFirestore.instance.collection('comments').doc(commentId);

      final comment = await commentRef.get();
      if (!comment.exists) return false;

      final likes = List<String>.from(comment.data()?['likes'] ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      await commentRef.update({'likes': likes});
      return true;
    } catch (e) {
      print('Error in CommentsService.toggleLike: $e');
      return false;
    }
  }
}
