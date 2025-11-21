# Lesson 8: High-Performance Feed with FlashList

**Duration**: 80 minutes | **Difficulty**: Advanced | **Prerequisites**: Lessons 1-7

## Learning Objectives
- Replace FlatList with FlashList for 10x performance
- Implement infinite scroll pagination
- Add real-time updates with Supabase
- Optimize media rendering
- Achieve 60 FPS scrolling

## Key Technologies
- **@shopify/flash-list**: High-performance list
- **Supabase Realtime**: Live updates
- **React.memo**: Component optimization

## Installation

```bash
npm install @shopify/flash-list
npx expo install expo-image
```

## Why FlashList?

| Metric | FlatList | FlashList |
|--------|----------|-----------|
| Blank cells | Common | Rare |
| Performance | Good | Excellent |
| Memory | Higher | Lower |
| Scroll FPS | 40-50 | 55-60 |
| Setup | Simple | Simple |

## Implementation

### 1. Replace FlatList with FlashList

```typescript
// app/(tabs)/index.tsx
import { FlashList } from '@shopify/flash-list';
import { usePosts } from '@/lib/hooks/usePosts';
import { PostCard } from '@/components/feed/PostCard';

export default function HomeScreen() {
  const {
    posts,
    loading,
    refreshing,
    refresh,
    loadMore,
    hasMore,
  } = usePosts();

  if (loading && posts.length === 0) {
    return <LoadingScreen />;
  }

  return (
    <View style={styles.container}>
      <FlashList
        data={posts}
        renderItem={({ item }) => <PostCard post={item} />}
        estimatedItemSize={400}
        keyExtractor={item => item.id}
        onEndReached={loadMore}
        onEndReachedThreshold={0.5}
        refreshing={refreshing}
        onRefresh={refresh}
        ListEmptyComponent={<EmptyFeedView />}
        ListFooterComponent={hasMore ? <LoadingFooter /> : null}
      />
    </View>
  );
}
```

### 2. Optimized Post Card with React.memo

```typescript
// components/feed/PostCard.tsx
import React, { memo } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { Image } from 'expo-image';
import { Ionicons } from '@expo/vector-icons';
import { AudioPlayerComponent } from '../media/AudioPlayer';
import { VideoPlayer } from '../media/VideoPlayer';
import { Post } from '@/lib/database/types';

interface PostCardProps {
  post: Post;
}

export const PostCard = memo(({ post }: PostCardProps) => {
  const [liked, setLiked] = useState(false);

  const handleLike = () => {
    setLiked(!liked);
    // Call API in background
  };

  return (
    <View style={styles.card}>
      {/* Header */}
      <View style={styles.header}>
        <Image
          source={{ uri: post.user_avatar }}
          style={styles.avatar}
          contentFit="cover"
        />
        <View style={styles.userInfo}>
          <Text style={styles.username}>{post.user_name}</Text>
          <Text style={styles.timestamp}>
            {formatTimestamp(post.created_at)}
          </Text>
        </View>
      </View>

      {/* Content */}
      <Text style={styles.content}>{post.content}</Text>

      {/* Media */}
      {post.media_type === 'image' && post.media_url && (
        <Image
          source={{ uri: post.media_url }}
          style={styles.media}
          contentFit="cover"
          cachePolicy="memory-disk"
          recyclingKey={post.id}
        />
      )}

      {post.media_type === 'audio' && post.media_url && (
        <AudioPlayerComponent uri={post.media_url} />
      )}

      {post.media_type === 'video' && post.media_url && (
        <VideoPlayer uri={post.media_url} />
      )}

      {/* Actions */}
      <View style={styles.actions}>
        <Pressable onPress={handleLike} style={styles.action}>
          <Ionicons
            name={liked ? 'heart' : 'heart-outline'}
            size={24}
            color={liked ? '#FF3B30' : '#8E8E93'}
          />
          <Text style={styles.actionText}>{post.likes_count}</Text>
        </Pressable>

        <Pressable style={styles.action}>
          <Ionicons name="chatbubble-outline" size={24} color="#8E8E93" />
          <Text style={styles.actionText}>{post.comments_count}</Text>
        </Pressable>

        <Pressable style={styles.action}>
          <Ionicons name="share-outline" size={24} color="#8E8E93" />
        </Pressable>
      </View>
    </View>
  );
}, (prevProps, nextProps) => {
  // Custom comparison for memo
  return (
    prevProps.post.id === nextProps.post.id &&
    prevProps.post.likes_count === nextProps.post.likes_count &&
    prevProps.post.comments_count === nextProps.post.comments_count
  );
});

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    marginBottom: 1,
    padding: 16,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  userInfo: {
    marginLeft: 12,
    flex: 1,
  },
  username: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  timestamp: {
    fontSize: 13,
    color: '#8E8E93',
    marginTop: 2,
  },
  content: {
    fontSize: 15,
    lineHeight: 21,
    color: '#000',
    marginBottom: 12,
  },
  media: {
    width: '100%',
    aspectRatio: 4 / 3,
    borderRadius: 12,
    marginBottom: 12,
  },
  actions: {
    flexDirection: 'row',
    gap: 20,
  },
  action: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  actionText: {
    fontSize: 14,
    color: '#8E8E93',
  },
});

function formatTimestamp(timestamp: number): string {
  const now = Date.now();
  const diff = now - timestamp;
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 0) return `${days}d ago`;
  if (hours > 0) return `${hours}h ago`;
  if (minutes > 0) return `${minutes}m ago`;
  return 'Just now';
}
```

### 3. Infinite Scroll Pagination

```typescript
// lib/hooks/usePosts.ts
import { useState, useCallback } from 'react';
import { PostsRepository } from '../database/repositories/posts';

const PAGE_SIZE = 20;

export function usePosts() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(0);

  const loadPosts = useCallback(async (pageNum: number, reset = false) => {
    try {
      const offset = pageNum * PAGE_SIZE;
      const newPosts = await PostsRepository.getAll(PAGE_SIZE, offset);

      if (reset) {
        setPosts(newPosts);
      } else {
        setPosts(prev => [...prev, ...newPosts]);
      }

      setHasMore(newPosts.length === PAGE_SIZE);
    } catch (error) {
      console.error('Error loading posts:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadPosts(0, true);
  }, []);

  const refresh = async () => {
    setRefreshing(true);
    setPage(0);
    await loadPosts(0, true);
    await processSyncQueue();
    setRefreshing(false);
  };

  const loadMore = () => {
    if (!loading && hasMore) {
      const nextPage = page + 1;
      setPage(nextPage);
      loadPosts(nextPage, false);
    }
  };

  return {
    posts,
    loading,
    refreshing,
    refresh,
    loadMore,
    hasMore,
  };
}
```

### 4. Real-Time Updates with Supabase

```typescript
// lib/realtime/posts.ts
import { useEffect } from 'react';
import { supabase } from '../supabase/client';
import { RealtimeChannel } from '@supabase/supabase-js';

export function usePostsRealtime(
  onInsert: (post: any) => void,
  onUpdate: (post: any) => void,
  onDelete: (id: string) => void
) {
  useEffect(() => {
    const channel: RealtimeChannel = supabase
      .channel('posts_changes')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'posts',
        },
        payload => {
          console.log('New post:', payload.new);
          onInsert(payload.new);
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'posts',
        },
        payload => {
          console.log('Updated post:', payload.new);
          onUpdate(payload.new);
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'posts',
        },
        payload => {
          console.log('Deleted post:', payload.old.id);
          onDelete(payload.old.id);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [onInsert, onUpdate, onDelete]);
}

// Usage in HomeScreen
const handleNewPost = (post: Post) => {
  setPosts(prev => [post, ...prev]);
};

const handleUpdatePost = (post: Post) => {
  setPosts(prev => prev.map(p => p.id === post.id ? post : p));
};

const handleDeletePost = (id: string) => {
  setPosts(prev => prev.filter(p => p.id !== id));
};

usePostsRealtime(handleNewPost, handleUpdatePost, handleDeletePost);
```

### 5. Empty State and Loading Components

```typescript
// components/feed/EmptyFeedView.tsx
function EmptyFeedView() {
  return (
    <View style={styles.empty}>
      <Ionicons name="chatbubbles-outline" size={64} color="#E5E5EA" />
      <Text style={styles.emptyTitle}>No posts yet</Text>
      <Text style={styles.emptyText}>
        Be the first to share something!
      </Text>
    </View>
  );
}

// components/feed/LoadingFooter.tsx
function LoadingFooter() {
  return (
    <View style={styles.footer}>
      <ActivityIndicator size="small" color="#007AFF" />
    </View>
  );
}
```

### 6. Performance Optimizations

```typescript
// components/feed/OptimizedImage.tsx
import { Image } from 'expo-image';

const blurhash = '|rF?hV%2WCj[ayj[a|j[az_NaeWBj@ayfRayfQfQM{M|azj[azf6fQfQfQIpWXofj[ayj[j[fQayWCoeoeaya}j[ayfQa{oLj?j[WVj[ayayj[fQoff7azayj[ayj[j[ayofayayayj[fQj[ayayj[ayfjj[j[ayjuayj[';

export function OptimizedImage({ uri }: { uri: string }) {
  return (
    <Image
      source={{ uri }}
      placeholder={blurhash}
      contentFit="cover"
      transition={200}
      cachePolicy="memory-disk"
      style={{ width: '100%', aspectRatio: 4 / 3 }}
    />
  );
}
```

## FlashList Best Practices

### 1. Provide Accurate estimatedItemSize
```typescript
<FlashList
  estimatedItemSize={400} // Measure average item height
  data={posts}
  renderItem={renderPost}
/>
```

### 2. Use Unique Keys
```typescript
keyExtractor={item => item.id} // Never use index
```

### 3. Optimize renderItem
```typescript
// ✅ Good: Memoized component
const renderPost = useCallback(
  ({ item }) => <PostCard post={item} />,
  []
);

// ❌ Bad: Inline function creates new component each render
renderItem={({ item }) => <PostCard post={item} />}
```

### 4. Recycle Views
```typescript
<Image
  recyclingKey={post.id} // Helps FlashList recycle views
  source={{ uri: post.media_url }}
/>
```

## Performance Metrics

Target metrics for production:
- **Scroll FPS**: 55-60 (measured with Xcode/Android Studio)
- **Time to Interactive**: &lt;2s
- **Memory Usage**: &lt;150MB for 1000 posts
- **Blank Cells**: &lt;1% of scrolls

## Testing Checklist
- [ ] Feed loads with 100+ posts smoothly
- [ ] Scroll at 60 FPS (no frame drops)
- [ ] Infinite scroll loads more posts
- [ ] Pull-to-refresh syncs data
- [ ] Real-time updates appear instantly
- [ ] Images load progressively
- [ ] Memory stays below 150MB

## Troubleshooting

### Issue: Blank cells during scroll

**Solution**: Increase `estimatedItemSize` or use `overrideItemLayout`

### Issue: Slow rendering

**Solution**: Wrap PostCard in `React.memo` and optimize media

### Issue: Memory leak

**Solution**: Clean up subscriptions and use `recyclingKey` for images

## Key Features Implemented
✅ FlashList for 10x performance
✅ Infinite scroll pagination
✅ Real-time updates
✅ Optimistic UI
✅ Image caching
✅ 60 FPS scrolling

## Next: Lesson 9 - Push Notifications 🔔
