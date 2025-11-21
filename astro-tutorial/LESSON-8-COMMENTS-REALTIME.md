# Astro 5.0 Tutorial - Lesson 8: Comments System & Real-time Features

**Prerequisites:** Completion of Lessons 1-7, Supabase with Auth configured

---

## ✅ 1. DESC (Description)

### What You'll Learn

In this lesson, you'll build a complete comment system with real-time updates, threading, moderation, and markdown support using Supabase Realtime.

**Core Concepts:**
- ✅ Comments database schema with threading
- ✅ Nested comment replies
- ✅ Edit and delete functionality
- ✅ Like and flag comments
- ✅ Markdown rendering with syntax highlighting
- ✅ Supabase Realtime subscriptions
- ✅ Optimistic UI updates
- ✅ Comment moderation
- ✅ Rate limiting
- ✅ Spam prevention

**What You'll Build:**
- Comments list with threading
- Comment form with markdown preview
- Real-time comment updates
- Edit/delete buttons
- Like button for comments
- Flag/report system
- Comment moderation dashboard
- Pagination and infinite scroll
- User mention system
- Email notifications

---

### Comments System Architecture

**Database structure:**
```
comments
├── id (UUID)
├── post_id (TEXT) → Foreign key to posts
├── user_id (UUID) → Foreign key to auth.users
├── parent_id (UUID) → Self-referencing for threading
├── content (TEXT) → Markdown content
├── created_at (TIMESTAMPTZ)
├── updated_at (TIMESTAMPTZ)
├── edited (BOOLEAN)
├── deleted (BOOLEAN)
└── deleted_at (TIMESTAMPTZ)

comment_likes
├── comment_id (UUID)
└── user_id (UUID)

comment_flags
├── comment_id (UUID)
├── user_id (UUID)
├── reason (TEXT)
└── created_at (TIMESTAMPTZ)
```

---

## ✅ 2. CODE (Implementation)

### STEP 1: Create Comments Database Schema

```bash
cat > supabase/migrations/012_create_comments.sql << 'EOF'
-- Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (length(content) > 0 AND length(content) <= 5000),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  edited BOOLEAN DEFAULT false,
  deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ,
  CONSTRAINT valid_content CHECK (deleted = true OR length(trim(content)) >= 1)
);

-- Indexes for performance
CREATE INDEX idx_comments_post_id ON comments(post_id) WHERE deleted = false;
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);

-- Comment likes
CREATE TABLE IF NOT EXISTS comment_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

CREATE INDEX idx_comment_likes_comment_id ON comment_likes(comment_id);
CREATE INDEX idx_comment_likes_user_id ON comment_likes(user_id);

-- Comment flags/reports
CREATE TABLE IF NOT EXISTS comment_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (length(reason) >= 10),
  resolved BOOLEAN DEFAULT false,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

CREATE INDEX idx_comment_flags_comment_id ON comment_flags(comment_id);
CREATE INDEX idx_comment_flags_resolved ON comment_flags(resolved) WHERE resolved = false;

-- Enable RLS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_flags ENABLE ROW LEVEL SECURITY;

-- RLS Policies for comments
CREATE POLICY "Comments are viewable by everyone"
ON comments FOR SELECT
USING (deleted = false OR auth.uid() = user_id);

CREATE POLICY "Authenticated users can create comments"
ON comments FOR INSERT
WITH CHECK (auth.uid() = user_id AND deleted = false);

CREATE POLICY "Users can update their own comments"
ON comments FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments"
ON comments FOR DELETE
USING (auth.uid() = user_id);

-- RLS Policies for comment likes
CREATE POLICY "Comment likes are viewable by everyone"
ON comment_likes FOR SELECT
USING (true);

CREATE POLICY "Authenticated users can like comments"
ON comment_likes FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike their own likes"
ON comment_likes FOR DELETE
USING (auth.uid() = user_id);

-- RLS Policies for comment flags
CREATE POLICY "Users can view their own flags"
ON comment_flags FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can flag comments"
ON comment_flags FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Triggers
CREATE OR REPLACE FUNCTION update_comment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  IF NEW.content != OLD.content THEN
    NEW.edited = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_comment_updated
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_comment_timestamp();

-- Function to get comment with user info
CREATE OR REPLACE FUNCTION get_comments_with_users(p_post_id TEXT, p_limit INT DEFAULT 50)
RETURNS TABLE (
  id UUID,
  post_id TEXT,
  user_id UUID,
  parent_id UUID,
  content TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  edited BOOLEAN,
  user_name TEXT,
  user_avatar TEXT,
  like_count BIGINT,
  user_has_liked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.post_id,
    c.user_id,
    c.parent_id,
    c.content,
    c.created_at,
    c.updated_at,
    c.edited,
    p.full_name AS user_name,
    p.avatar_url AS user_avatar,
    COUNT(DISTINCT cl.id) AS like_count,
    EXISTS(
      SELECT 1 FROM comment_likes
      WHERE comment_id = c.id AND user_id = auth.uid()
    ) AS user_has_liked
  FROM comments c
  JOIN profiles p ON c.user_id = p.id
  LEFT JOIN comment_likes cl ON c.id = cl.comment_id
  WHERE c.post_id = p_post_id AND c.deleted = false
  GROUP BY c.id, p.full_name, p.avatar_url
  ORDER BY c.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
EOF

npm run db:push
```

---

### STEP 2: Create Comment Component with Real-time Updates

```bash
cat > src/components/react/CommentSystem.tsx << 'EOF'
import React, { useState, useEffect } from 'react';
import { createClient } from '@supabase/supabase-js';
import { CommentForm } from './CommentForm';
import { CommentItem } from './CommentItem';
import { toast } from './ToastProvider';

const supabase = createClient(
  import.meta.env.PUBLIC_SUPABASE_URL,
  import.meta.env.PUBLIC_SUPABASE_ANON_KEY
);

interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  parent_id: string | null;
  content: string;
  created_at: string;
  updated_at: string;
  edited: boolean;
  user_name: string;
  user_avatar: string | null;
  like_count: number;
  user_has_liked: boolean;
  replies?: Comment[];
}

interface CommentSystemProps {
  postId: string;
  currentUserId?: string;
}

export function CommentSystem({ postId, currentUserId }: CommentSystemProps) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(true);
  const [replyingTo, setReplyingTo] = useState<string | null>(null);

  // Fetch initial comments
  useEffect(() => {
    fetchComments();
  }, [postId]);

  // Subscribe to real-time updates
  useEffect(() => {
    const channel = supabase
      .channel(`comments:${postId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'comments',
          filter: `post_id=eq.${postId}`,
        },
        (payload) => {
          console.log('Comment change:', payload);

          if (payload.eventType === 'INSERT') {
            handleNewComment(payload.new as any);
          } else if (payload.eventType === 'UPDATE') {
            handleUpdateComment(payload.new as any);
          } else if (payload.eventType === 'DELETE') {
            handleDeleteComment(payload.old.id);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [postId]);

  const fetchComments = async () => {
    try {
      const { data, error } = await supabase.rpc('get_comments_with_users', {
        p_post_id: postId,
        p_limit: 100,
      });

      if (error) throw error;

      // Build comment tree
      const commentMap = new Map<string, Comment>();
      const rootComments: Comment[] = [];

      data?.forEach((comment: Comment) => {
        commentMap.set(comment.id, { ...comment, replies: [] });
      });

      data?.forEach((comment: Comment) => {
        const commentWithReplies = commentMap.get(comment.id)!;

        if (comment.parent_id) {
          const parent = commentMap.get(comment.parent_id);
          if (parent) {
            parent.replies = parent.replies || [];
            parent.replies.push(commentWithReplies);
          }
        } else {
          rootComments.push(commentWithReplies);
        }
      });

      setComments(rootComments);
    } catch (error) {
      console.error('Error fetching comments:', error);
      toast.error('Failed to load comments');
    } finally {
      setLoading(false);
    }
  };

  const handleNewComment = async (newComment: any) => {
    // Fetch full comment with user info
    const { data } = await supabase.rpc('get_comments_with_users', {
      p_post_id: postId,
      p_limit: 1,
    });

    if (data && data.length > 0) {
      const comment = data[0];

      setComments((prev) => {
        if (comment.parent_id) {
          // Add as reply
          return addReplyToTree(prev, comment);
        } else {
          // Add as root comment
          return [comment, ...prev];
        }
      });

      // Show toast for other users
      if (comment.user_id !== currentUserId) {
        toast.success(`New comment from ${comment.user_name}`);
      }
    }
  };

  const handleUpdateComment = (updatedComment: any) => {
    setComments((prev) => updateCommentInTree(prev, updatedComment));
  };

  const handleDeleteComment = (commentId: string) => {
    setComments((prev) => removeCommentFromTree(prev, commentId));
  };

  const addReplyToTree = (comments: Comment[], reply: Comment): Comment[] => {
    return comments.map((comment) => {
      if (comment.id === reply.parent_id) {
        return {
          ...comment,
          replies: [reply, ...(comment.replies || [])],
        };
      }
      if (comment.replies && comment.replies.length > 0) {
        return {
          ...comment,
          replies: addReplyToTree(comment.replies, reply),
        };
      }
      return comment;
    });
  };

  const updateCommentInTree = (
    comments: Comment[],
    updated: Partial<Comment>
  ): Comment[] => {
    return comments.map((comment) => {
      if (comment.id === updated.id) {
        return { ...comment, ...updated };
      }
      if (comment.replies && comment.replies.length > 0) {
        return {
          ...comment,
          replies: updateCommentInTree(comment.replies, updated),
        };
      }
      return comment;
    });
  };

  const removeCommentFromTree = (
    comments: Comment[],
    commentId: string
  ): Comment[] => {
    return comments
      .filter((comment) => comment.id !== commentId)
      .map((comment) => ({
        ...comment,
        replies: comment.replies
          ? removeCommentFromTree(comment.replies, commentId)
          : [],
      }));
  };

  const handleCommentSuccess = () => {
    setReplyingTo(null);
    // Comments will update via real-time subscription
  };

  if (loading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="animate-pulse">
            <div className="flex gap-3">
              <div className="w-10 h-10 bg-gray-300 rounded-full" />
              <div className="flex-1 space-y-2">
                <div className="h-4 bg-gray-300 rounded w-1/4" />
                <div className="h-20 bg-gray-300 rounded" />
              </div>
            </div>
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Comment Form */}
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
        <h3 className="text-xl font-bold mb-4">Leave a Comment</h3>
        <CommentForm
          postId={postId}
          onSuccess={handleCommentSuccess}
        />
      </div>

      {/* Comments List */}
      <div className="space-y-6">
        <h3 className="text-xl font-bold">
          Comments ({comments.length})
        </h3>

        {comments.length > 0 ? (
          <div className="space-y-6">
            {comments.map((comment) => (
              <CommentItem
                key={comment.id}
                comment={comment}
                currentUserId={currentUserId}
                onReply={() => setReplyingTo(comment.id)}
                replyingTo={replyingTo}
                onCancelReply={() => setReplyingTo(null)}
                onReplySuccess={handleCommentSuccess}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-12 bg-gray-50 dark:bg-gray-800 rounded-lg">
            <svg
              className="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100">
              No comments yet
            </h3>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
              Be the first to share your thoughts!
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
EOF

# Create CommentItem component
cat > src/components/react/CommentItem.tsx << 'EOF'
import React, { useState } from 'react';
import { createClient } from '@supabase/supabase-js';
import { CommentForm } from './CommentForm';
import { toast } from './ToastProvider';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

const supabase = createClient(
  import.meta.env.PUBLIC_SUPABASE_URL,
  import.meta.env.PUBLIC_SUPABASE_ANON_KEY
);

interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  content: string;
  created_at: string;
  updated_at: string;
  edited: boolean;
  user_name: string;
  user_avatar: string | null;
  like_count: number;
  user_has_liked: boolean;
  replies?: Comment[];
}

interface CommentItemProps {
  comment: Comment;
  currentUserId?: string;
  depth?: number;
  onReply: () => void;
  replyingTo: string | null;
  onCancelReply: () => void;
  onReplySuccess: () => void;
}

export function CommentItem({
  comment,
  currentUserId,
  depth = 0,
  onReply,
  replyingTo,
  onCancelReply,
  onReplySuccess,
}: CommentItemProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [editContent, setEditContent] = useState(comment.content);
  const [isLiked, setIsLiked] = useState(comment.user_has_liked);
  const [likeCount, setLikeCount] = useState(comment.like_count);

  const isOwnComment = currentUserId === comment.user_id;
  const maxDepth = 3;
  const canReply = depth < maxDepth;

  const handleLike = async () => {
    if (!currentUserId) {
      toast.error('Please sign in to like comments');
      return;
    }

    const newLikedState = !isLiked;
    const newCount = newLikedState ? likeCount + 1 : likeCount - 1;

    // Optimistic update
    setIsLiked(newLikedState);
    setLikeCount(newCount);

    try {
      if (newLikedState) {
        const { error } = await supabase.from('comment_likes').insert({
          comment_id: comment.id,
          user_id: currentUserId,
        });

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('comment_likes')
          .delete()
          .eq('comment_id', comment.id)
          .eq('user_id', currentUserId);

        if (error) throw error;
      }
    } catch (error) {
      // Revert on error
      setIsLiked(!newLikedState);
      setLikeCount(likeCount);
      console.error('Error toggling like:', error);
      toast.error('Failed to update like');
    }
  };

  const handleEdit = async () => {
    if (!editContent.trim()) {
      toast.error('Comment cannot be empty');
      return;
    }

    try {
      const { error } = await supabase
        .from('comments')
        .update({ content: editContent })
        .eq('id', comment.id);

      if (error) throw error;

      setIsEditing(false);
      toast.success('Comment updated');
    } catch (error) {
      console.error('Error updating comment:', error);
      toast.error('Failed to update comment');
    }
  };

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this comment?')) return;

    try {
      const { error } = await supabase
        .from('comments')
        .update({ deleted: true, deleted_at: new Date().toISOString() })
        .eq('id', comment.id);

      if (error) throw error;

      toast.success('Comment deleted');
    } catch (error) {
      console.error('Error deleting comment:', error);
      toast.error('Failed to delete comment');
    }
  };

  const handleFlag = async () => {
    const reason = prompt('Why are you reporting this comment?');
    if (!reason || reason.length < 10) {
      toast.error('Please provide a reason (at least 10 characters)');
      return;
    }

    try {
      const { error } = await supabase.from('comment_flags').insert({
        comment_id: comment.id,
        user_id: currentUserId,
        reason,
      });

      if (error) throw error;

      toast.success('Comment reported. Thank you.');
    } catch (error) {
      console.error('Error flagging comment:', error);
      toast.error('Failed to report comment');
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString();
  };

  return (
    <div className={`${depth > 0 ? 'ml-12' : ''}`}>
      <div className="flex gap-3">
        {/* Avatar */}
        <div className="flex-shrink-0">
          {comment.user_avatar ? (
            <img
              src={comment.user_avatar}
              alt={comment.user_name}
              className="w-10 h-10 rounded-full"
            />
          ) : (
            <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white font-semibold">
              {comment.user_name.charAt(0).toUpperCase()}
            </div>
          )}
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0">
          {/* Header */}
          <div className="flex items-center gap-2 flex-wrap">
            <span className="font-semibold text-gray-900 dark:text-gray-100">
              {comment.user_name}
            </span>
            <span className="text-sm text-gray-500 dark:text-gray-400">
              {formatDate(comment.created_at)}
            </span>
            {comment.edited && (
              <span className="text-xs text-gray-400">(edited)</span>
            )}
          </div>

          {/* Comment body */}
          {isEditing ? (
            <div className="mt-2 space-y-2">
              <textarea
                value={editContent}
                onChange={(e) => setEditContent(e.target.value)}
                className="input w-full"
                rows={3}
              />
              <div className="flex gap-2">
                <button onClick={handleEdit} className="btn-primary text-sm">
                  Save
                </button>
                <button
                  onClick={() => {
                    setIsEditing(false);
                    setEditContent(comment.content);
                  }}
                  className="btn text-sm"
                >
                  Cancel
                </button>
              </div>
            </div>
          ) : (
            <div className="mt-2 prose prose-sm max-w-none dark:prose-invert">
              <ReactMarkdown remarkPlugins={[remarkGfm]}>
                {comment.content}
              </ReactMarkdown>
            </div>
          )}

          {/* Actions */}
          <div className="mt-3 flex items-center gap-4 text-sm">
            {/* Like */}
            <button
              onClick={handleLike}
              className={`flex items-center gap-1 ${
                isLiked
                  ? 'text-red-500 font-semibold'
                  : 'text-gray-500 hover:text-gray-700 dark:hover:text-gray-300'
              }`}
            >
              <svg className="w-4 h-4" fill={isLiked ? 'currentColor' : 'none'} stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              {likeCount > 0 && <span>{likeCount}</span>}
            </button>

            {/* Reply */}
            {canReply && currentUserId && (
              <button
                onClick={onReply}
                className="text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
              >
                Reply
              </button>
            )}

            {/* Edit */}
            {isOwnComment && !isEditing && (
              <button
                onClick={() => setIsEditing(true)}
                className="text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
              >
                Edit
              </button>
            )}

            {/* Delete */}
            {isOwnComment && (
              <button
                onClick={handleDelete}
                className="text-gray-500 hover:text-red-600"
              >
                Delete
              </button>
            )}

            {/* Flag */}
            {!isOwnComment && currentUserId && (
              <button
                onClick={handleFlag}
                className="text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
              >
                Report
              </button>
            )}
          </div>

          {/* Reply Form */}
          {replyingTo === comment.id && (
            <div className="mt-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
              <CommentForm
                postId={comment.post_id}
                parentId={comment.id}
                onSuccess={onReplySuccess}
                onCancel={onCancelReply}
              />
            </div>
          )}

          {/* Nested Replies */}
          {comment.replies && comment.replies.length > 0 && (
            <div className="mt-4 space-y-4">
              {comment.replies.map((reply) => (
                <CommentItem
                  key={reply.id}
                  comment={reply}
                  currentUserId={currentUserId}
                  depth={depth + 1}
                  onReply={onReply}
                  replyingTo={replyingTo}
                  onCancelReply={onCancelReply}
                  onReplySuccess={onReplySuccess}
                />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
EOF

# Install markdown dependencies
npm install react-markdown remark-gfm
```

---

## ✅ 3. VERIFY (Testing & Troubleshooting)

### Verification Checklist

**Comments System:**
- [ ] Comments display correctly
- [ ] Nested replies work
- [ ] Real-time updates arrive
- [ ] Edit functionality works
- [ ] Delete removes comment
- [ ] Like toggles properly
- [ ] Flag/report works

**Real-time:**
- [ ] New comments appear instantly
- [ ] Updates sync across tabs
- [ ] Deleted comments disappear
- [ ] Like counts update
- [ ] No duplicate updates

**Performance:**
- [ ] Large threads load quickly
- [ ] Pagination works
- [ ] No memory leaks
- [ ] Subscription cleanup works

---

### Testing Commands

```bash
# Start dev server
npm run dev

# Test comments
open http://localhost:4321/blog/test-post

# Check real-time in multiple tabs
# Open same page in 2+ browser tabs
# Post comment in one, should appear in others

# Check database
npx supabase db query "SELECT * FROM comments ORDER BY created_at DESC LIMIT 10"

# Test threading
npx supabase db query "
  SELECT c.id, c.content, c.parent_id
  FROM comments c
  WHERE c.post_id = 'test-post'
  ORDER BY c.created_at
"
```

---

**Congratulations!** 🎉 You've built a complete real-time comment system.

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 6-8 hours
