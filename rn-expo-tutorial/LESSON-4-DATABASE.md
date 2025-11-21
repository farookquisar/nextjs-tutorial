# Lesson 4: Local-First Database with SQLite & Supabase Sync

**Duration**: 95 minutes
**Difficulty**: Intermediate to Advanced
**Prerequisites**: Completed Lessons 1-3

## Learning Objectives

By the end of this lesson, you will:
- Understand local-first architecture for mobile apps
- Implement SQLite database with expo-sqlite
- Create CRUD operations that work offline
- Implement optimistic UI updates
- Build a sync queue for cloud synchronization
- Handle conflict resolution between local and remote data
- Design a production-ready data layer

---

## DESCRIBE: Local-First Architecture

### Why Local-First for Mobile?

Mobile apps need to work seamlessly regardless of network conditions:

**Traditional Approach** (Cloud-First):
```
User Action → API Request → Wait for Response → Update UI
❌ Slow feedback
❌ Fails without internet
❌ Poor user experience
```

**Local-First Approach**:
```
User Action → Save to Local DB → Update UI Immediately → Sync in Background
✅ Instant feedback
✅ Works offline
✅ Great user experience
```

### Key Principles

1. **Local Database as Source of Truth**
   - All reads from local SQLite database
   - Instant data access, no network delay
   - App works 100% offline

2. **Optimistic Updates**
   - Write to local DB immediately
   - Show success to user right away
   - Sync to cloud in background

3. **Background Sync Queue**
   - Queue pending changes
   - Retry failed syncs automatically
   - Handle conflicts gracefully

4. **Conflict Resolution**
   - Last-write-wins strategy
   - Version-based merging
   - User-directed resolution

### Architecture Overview

```
┌─────────────────────────────────────────────┐
│  User Interface (React Native)              │
└────────────┬────────────────────────────────┘
             │
     ┌───────▼────────┐
     │  Data Hooks    │  (useQuery, useMutation)
     └───────┬────────┘
             │
┌────────────▼─────────────────────────────────┐
│  Local Database Layer (SQLite)               │
│  - Posts, Comments, Users, Likes             │
│  - Sync Queue                                │
│  - Timestamps & Versions                     │
└────────────┬─────────────────────────────────┘
             │
     ┌───────▼────────┐
     │  Sync Manager  │  (Background sync)
     └───────┬────────┘
             │
┌────────────▼─────────────────────────────────┐
│  Supabase (Cloud Database)                   │
│  - Backup & Sync                             │
│  - Cross-device sync                         │
│  - Real-time updates                         │
└──────────────────────────────────────────────┘
```

### expo-sqlite Overview

Expo SDK 54 provides a modern SQLite interface:
- **Synchronous API**: Faster than async for local operations
- **Transactions**: Atomic batch operations
- **Migrations**: Version-controlled schema changes
- **Type Safety**: Use with TypeScript for compile-time checks

---

## CODE: Implementing Local-First Database

### Step 1: Install Dependencies

```bash
# Install expo-sqlite for local database
npx expo install expo-sqlite

# Install network info for online/offline detection
npx expo install @react-native-community/netinfo

# Install async storage for simple key-value data
npx expo install @react-native-async-storage/async-storage
```

### Step 2: Create Database Schema

```bash
mkdir -p lib/database
cat > lib/database/schema.ts << 'EOF'
export const DB_NAME = 'mediasocial.db';
export const DB_VERSION = 1;

// SQL schema definitions
export const CREATE_POSTS_TABLE = `
  CREATE TABLE IF NOT EXISTS posts (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    content TEXT NOT NULL,
    media_url TEXT,
    media_type TEXT CHECK(media_type IN ('image', 'video', 'audio')),
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    synced_at INTEGER,
    is_deleted INTEGER DEFAULT 0,
    version INTEGER DEFAULT 1
  );
`;

export const CREATE_COMMENTS_TABLE = `
  CREATE TABLE IF NOT EXISTS comments (
    id TEXT PRIMARY KEY NOT NULL,
    post_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    synced_at INTEGER,
    is_deleted INTEGER DEFAULT 0,
    version INTEGER DEFAULT 1,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
  );
`;

export const CREATE_LIKES_TABLE = `
  CREATE TABLE IF NOT EXISTS likes (
    id TEXT PRIMARY KEY NOT NULL,
    post_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    synced_at INTEGER,
    is_deleted INTEGER DEFAULT 0,
    UNIQUE(post_id, user_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
  );
`;

export const CREATE_USERS_CACHE_TABLE = `
  CREATE TABLE IF NOT EXISTS users_cache (
    id TEXT PRIMARY KEY NOT NULL,
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    cached_at INTEGER NOT NULL
  );
`;

export const CREATE_SYNC_QUEUE_TABLE = `
  CREATE TABLE IF NOT EXISTS sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    operation TEXT NOT NULL CHECK(operation IN ('create', 'update', 'delete')),
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL,
    data TEXT,
    created_at INTEGER NOT NULL,
    attempts INTEGER DEFAULT 0,
    last_error TEXT,
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'syncing', 'failed', 'success'))
  );
`;

// Indexes for better query performance
export const CREATE_INDEXES = `
  CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
  CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
  CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
  CREATE INDEX IF NOT EXISTS idx_likes_post_id ON likes(post_id);
  CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
  CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status);
`;
EOF
```

### Step 3: Create Database Instance

```bash
cat > lib/database/index.ts << 'EOF'
import * as SQLite from 'expo-sqlite';
import {
  DB_NAME,
  CREATE_POSTS_TABLE,
  CREATE_COMMENTS_TABLE,
  CREATE_LIKES_TABLE,
  CREATE_USERS_CACHE_TABLE,
  CREATE_SYNC_QUEUE_TABLE,
  CREATE_INDEXES,
} from './schema';

class Database {
  private db: SQLite.SQLiteDatabase | null = null;

  async init() {
    try {
      this.db = await SQLite.openDatabaseAsync(DB_NAME);
      await this.createTables();
      console.log('✅ Database initialized successfully');
    } catch (error) {
      console.error('❌ Database initialization failed:', error);
      throw error;
    }
  }

  private async createTables() {
    if (!this.db) throw new Error('Database not initialized');

    try {
      await this.db.execAsync(`
        ${CREATE_POSTS_TABLE}
        ${CREATE_COMMENTS_TABLE}
        ${CREATE_LIKES_TABLE}
        ${CREATE_USERS_CACHE_TABLE}
        ${CREATE_SYNC_QUEUE_TABLE}
        ${CREATE_INDEXES}
      `);
      console.log('✅ Tables created successfully');
    } catch (error) {
      console.error('❌ Error creating tables:', error);
      throw error;
    }
  }

  getDatabase() {
    if (!this.db) {
      throw new Error('Database not initialized. Call init() first.');
    }
    return this.db;
  }

  async close() {
    if (this.db) {
      await this.db.closeAsync();
      this.db = null;
    }
  }

  // Drop all tables (useful for development/testing)
  async reset() {
    if (!this.db) throw new Error('Database not initialized');

    await this.db.execAsync(`
      DROP TABLE IF EXISTS posts;
      DROP TABLE IF EXISTS comments;
      DROP TABLE IF EXISTS likes;
      DROP TABLE IF EXISTS users_cache;
      DROP TABLE IF EXISTS sync_queue;
    `);

    await this.createTables();
    console.log('✅ Database reset complete');
  }
}

export const database = new Database();
EOF
```

### Step 4: Create Database Types

```bash
cat > lib/database/types.ts << 'EOF'
export interface Post {
  id: string;
  user_id: string;
  content: string;
  media_url: string | null;
  media_type: 'image' | 'video' | 'audio' | null;
  likes_count: number;
  comments_count: number;
  created_at: number;
  updated_at: number;
  synced_at: number | null;
  is_deleted: number;
  version: number;
}

export interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  content: string;
  created_at: number;
  updated_at: number;
  synced_at: number | null;
  is_deleted: number;
  version: number;
}

export interface Like {
  id: string;
  post_id: string;
  user_id: string;
  created_at: number;
  synced_at: number | null;
  is_deleted: number;
}

export interface UserCache {
  id: string;
  email: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  cached_at: number;
}

export interface SyncQueueItem {
  id: number;
  operation: 'create' | 'update' | 'delete';
  table_name: string;
  record_id: string;
  data: string | null;
  created_at: number;
  attempts: number;
  last_error: string | null;
  status: 'pending' | 'syncing' | 'failed' | 'success';
}

export type CreatePostInput = Omit<
  Post,
  'id' | 'likes_count' | 'comments_count' | 'created_at' | 'updated_at' | 'synced_at' | 'is_deleted' | 'version'
>;

export type UpdatePostInput = Partial<Pick<Post, 'content' | 'media_url' | 'media_type'>>;

export type CreateCommentInput = Omit<
  Comment,
  'id' | 'created_at' | 'updated_at' | 'synced_at' | 'is_deleted' | 'version'
>;
EOF
```

### Step 5: Create Posts Repository (CRUD Operations)

```bash
mkdir -p lib/database/repositories
cat > lib/database/repositories/posts.ts << 'EOF'
import { database } from '../index';
import { Post, CreatePostInput, UpdatePostInput } from '../types';
import { nanoid } from 'nanoid/non-secure';
import { addToSyncQueue } from '../sync-queue';

export class PostsRepository {
  // Create a new post (local-first)
  static async create(input: CreatePostInput): Promise<Post> {
    const db = database.getDatabase();
    const now = Date.now();

    const post: Post = {
      id: nanoid(),
      user_id: input.user_id,
      content: input.content,
      media_url: input.media_url || null,
      media_type: input.media_type || null,
      likes_count: 0,
      comments_count: 0,
      created_at: now,
      updated_at: now,
      synced_at: null,
      is_deleted: 0,
      version: 1,
    };

    await db.runAsync(
      `INSERT INTO posts (id, user_id, content, media_url, media_type, likes_count, comments_count, created_at, updated_at, synced_at, is_deleted, version)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        post.id,
        post.user_id,
        post.content,
        post.media_url,
        post.media_type,
        post.likes_count,
        post.comments_count,
        post.created_at,
        post.updated_at,
        post.synced_at,
        post.is_deleted,
        post.version,
      ]
    );

    // Add to sync queue for cloud backup
    await addToSyncQueue('create', 'posts', post.id, post);

    console.log('✅ Post created locally:', post.id);
    return post;
  }

  // Get all posts (ordered by created_at DESC)
  static async getAll(limit = 50, offset = 0): Promise<Post[]> {
    const db = database.getDatabase();

    const posts = await db.getAllAsync<Post>(
      `SELECT * FROM posts
       WHERE is_deleted = 0
       ORDER BY created_at DESC
       LIMIT ? OFFSET ?`,
      [limit, offset]
    );

    return posts;
  }

  // Get a single post by ID
  static async getById(id: string): Promise<Post | null> {
    const db = database.getDatabase();

    const post = await db.getFirstAsync<Post>(
      `SELECT * FROM posts WHERE id = ? AND is_deleted = 0`,
      [id]
    );

    return post || null;
  }

  // Get posts by user ID
  static async getByUserId(userId: string, limit = 50): Promise<Post[]> {
    const db = database.getDatabase();

    const posts = await db.getAllAsync<Post>(
      `SELECT * FROM posts
       WHERE user_id = ? AND is_deleted = 0
       ORDER BY created_at DESC
       LIMIT ?`,
      [userId, limit]
    );

    return posts;
  }

  // Update a post
  static async update(id: string, updates: UpdatePostInput): Promise<Post | null> {
    const db = database.getDatabase();
    const now = Date.now();

    const post = await this.getById(id);
    if (!post) return null;

    const updatedPost: Post = {
      ...post,
      ...updates,
      updated_at: now,
      version: post.version + 1,
    };

    await db.runAsync(
      `UPDATE posts
       SET content = ?, media_url = ?, media_type = ?, updated_at = ?, version = ?
       WHERE id = ?`,
      [
        updatedPost.content,
        updatedPost.media_url,
        updatedPost.media_type,
        updatedPost.updated_at,
        updatedPost.version,
        id,
      ]
    );

    // Add to sync queue
    await addToSyncQueue('update', 'posts', id, updatedPost);

    console.log('✅ Post updated locally:', id);
    return updatedPost;
  }

  // Delete a post (soft delete)
  static async delete(id: string): Promise<boolean> {
    const db = database.getDatabase();
    const now = Date.now();

    const result = await db.runAsync(
      `UPDATE posts SET is_deleted = 1, updated_at = ? WHERE id = ?`,
      [now, id]
    );

    if (result.changes > 0) {
      // Add to sync queue
      await addToSyncQueue('delete', 'posts', id, null);
      console.log('✅ Post deleted locally:', id);
      return true;
    }

    return false;
  }

  // Toggle like on a post (optimistic update)
  static async toggleLike(postId: string, userId: string): Promise<boolean> {
    const db = database.getDatabase();

    // Check if already liked
    const existingLike = await db.getFirstAsync<{ id: string }>(
      `SELECT id FROM likes WHERE post_id = ? AND user_id = ? AND is_deleted = 0`,
      [postId, userId]
    );

    if (existingLike) {
      // Unlike
      await db.runAsync(
        `UPDATE likes SET is_deleted = 1 WHERE post_id = ? AND user_id = ?`,
        [postId, userId]
      );
      await db.runAsync(
        `UPDATE posts SET likes_count = likes_count - 1 WHERE id = ?`,
        [postId]
      );
      await addToSyncQueue('delete', 'likes', existingLike.id, null);
      return false;
    } else {
      // Like
      const likeId = nanoid();
      const now = Date.now();

      await db.runAsync(
        `INSERT INTO likes (id, post_id, user_id, created_at, synced_at, is_deleted)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [likeId, postId, userId, now, null, 0]
      );
      await db.runAsync(
        `UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?`,
        [postId]
      );
      await addToSyncQueue('create', 'likes', likeId, { id: likeId, post_id: postId, user_id: userId, created_at: now });
      return true;
    }
  }

  // Increment comment count
  static async incrementCommentCount(postId: string): Promise<void> {
    const db = database.getDatabase();
    await db.runAsync(
      `UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?`,
      [postId]
    );
  }

  // Mark post as synced
  static async markAsSynced(id: string): Promise<void> {
    const db = database.getDatabase();
    const now = Date.now();

    await db.runAsync(
      `UPDATE posts SET synced_at = ? WHERE id = ?`,
      [now, id]
    );
  }
}
EOF
```

### Step 6: Create Sync Queue Manager

```bash
cat > lib/database/sync-queue.ts << 'EOF'
import { database } from './index';
import { SyncQueueItem } from './types';
import NetInfo from '@react-native-community/netinfo';
import { supabase } from '../supabase/client';
import { PostsRepository } from './repositories/posts';

// Add item to sync queue
export async function addToSyncQueue(
  operation: 'create' | 'update' | 'delete',
  tableName: string,
  recordId: string,
  data: any
): Promise<void> {
  const db = database.getDatabase();
  const now = Date.now();

  await db.runAsync(
    `INSERT INTO sync_queue (operation, table_name, record_id, data, created_at, attempts, status)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [operation, tableName, recordId, JSON.stringify(data), now, 0, 'pending']
  );

  console.log(`📥 Added to sync queue: ${operation} ${tableName}/${recordId}`);
}

// Get pending sync items
export async function getPendingSyncItems(): Promise<SyncQueueItem[]> {
  const db = database.getDatabase();

  const items = await db.getAllAsync<SyncQueueItem>(
    `SELECT * FROM sync_queue
     WHERE status IN ('pending', 'failed')
     ORDER BY created_at ASC
     LIMIT 50`
  );

  return items;
}

// Process sync queue
export async function processSyncQueue(): Promise<{
  success: number;
  failed: number;
}> {
  // Check if online
  const netInfo = await NetInfo.fetch();
  if (!netInfo.isConnected) {
    console.log('⚠️ Offline - skipping sync');
    return { success: 0, failed: 0 };
  }

  const items = await getPendingSyncItems();
  if (items.length === 0) {
    console.log('✅ Sync queue is empty');
    return { success: 0, failed: 0 };
  }

  console.log(`🔄 Processing ${items.length} sync items...`);

  let successCount = 0;
  let failedCount = 0;

  for (const item of items) {
    try {
      await markSyncItemAsProcessing(item.id);

      // Sync based on table
      if (item.table_name === 'posts') {
        await syncPost(item);
      } else if (item.table_name === 'likes') {
        await syncLike(item);
      }
      // Add more tables as needed

      await markSyncItemAsSuccess(item.id);
      successCount++;
    } catch (error: any) {
      console.error(`❌ Sync failed for item ${item.id}:`, error);
      await markSyncItemAsFailed(item.id, error.message);
      failedCount++;
    }
  }

  console.log(`✅ Sync complete: ${successCount} success, ${failedCount} failed`);
  return { success: successCount, failed: failedCount };
}

// Sync a post to Supabase
async function syncPost(item: SyncQueueItem): Promise<void> {
  const data = JSON.parse(item.data || '{}');

  if (item.operation === 'create') {
    const { error } = await supabase.from('posts').insert({
      id: data.id,
      user_id: data.user_id,
      content: data.content,
      media_url: data.media_url,
      media_type: data.media_type,
      likes_count: data.likes_count,
      comments_count: data.comments_count,
      created_at: new Date(data.created_at).toISOString(),
      updated_at: new Date(data.updated_at).toISOString(),
    });

    if (error) throw error;
    await PostsRepository.markAsSynced(data.id);
  } else if (item.operation === 'update') {
    const { error } = await supabase
      .from('posts')
      .update({
        content: data.content,
        media_url: data.media_url,
        media_type: data.media_type,
        updated_at: new Date(data.updated_at).toISOString(),
      })
      .eq('id', item.record_id);

    if (error) throw error;
    await PostsRepository.markAsSynced(item.record_id);
  } else if (item.operation === 'delete') {
    const { error } = await supabase.from('posts').delete().eq('id', item.record_id);

    if (error) throw error;
  }
}

// Sync a like to Supabase
async function syncLike(item: SyncQueueItem): Promise<void> {
  const data = JSON.parse(item.data || '{}');

  if (item.operation === 'create') {
    const { error } = await supabase.from('likes').insert({
      id: data.id,
      post_id: data.post_id,
      user_id: data.user_id,
      created_at: new Date(data.created_at).toISOString(),
    });

    if (error) throw error;
  } else if (item.operation === 'delete') {
    const { error } = await supabase.from('likes').delete().eq('id', item.record_id);

    if (error) throw error;
  }
}

// Mark sync item status
async function markSyncItemAsProcessing(id: number): Promise<void> {
  const db = database.getDatabase();
  await db.runAsync(`UPDATE sync_queue SET status = 'syncing' WHERE id = ?`, [id]);
}

async function markSyncItemAsSuccess(id: number): Promise<void> {
  const db = database.getDatabase();
  await db.runAsync(`UPDATE sync_queue SET status = 'success' WHERE id = ?`, [id]);
}

async function markSyncItemAsFailed(id: number, error: string): Promise<void> {
  const db = database.getDatabase();
  await db.runAsync(
    `UPDATE sync_queue SET status = 'failed', attempts = attempts + 1, last_error = ? WHERE id = ?`,
    [error, id]
  );
}

// Auto-sync on app state change and network reconnection
export function setupAutoSync() {
  // Sync when app comes online
  const unsubscribe = NetInfo.addEventListener(state => {
    if (state.isConnected) {
      console.log('📡 Network reconnected - starting sync...');
      processSyncQueue();
    }
  });

  return unsubscribe;
}
EOF
```

### Step 7: Create React Hooks for Data Access

```bash
mkdir -p lib/hooks
cat > lib/hooks/usePosts.ts << 'EOF'
import { useState, useEffect, useCallback } from 'react';
import { Post, CreatePostInput, UpdatePostInput } from '../database/types';
import { PostsRepository } from '../database/repositories/posts';
import { processSyncQueue } from '../database/sync-queue';

export function usePosts() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadPosts = useCallback(async () => {
    try {
      const data = await PostsRepository.getAll();
      setPosts(data);
    } catch (error) {
      console.error('Error loading posts:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadPosts();
  }, [loadPosts]);

  const refresh = async () => {
    setRefreshing(true);
    await loadPosts();
    await processSyncQueue(); // Sync with cloud
    setRefreshing(false);
  };

  const createPost = async (input: CreatePostInput) => {
    const post = await PostsRepository.create(input);
    setPosts(prev => [post, ...prev]); // Optimistic update
    processSyncQueue(); // Sync in background
    return post;
  };

  const updatePost = async (id: string, updates: UpdatePostInput) => {
    const updated = await PostsRepository.update(id, updates);
    if (updated) {
      setPosts(prev => prev.map(p => (p.id === id ? updated : p)));
      processSyncQueue();
    }
    return updated;
  };

  const deletePost = async (id: string) => {
    const success = await PostsRepository.delete(id);
    if (success) {
      setPosts(prev => prev.filter(p => p.id !== id)); // Optimistic update
      processSyncQueue();
    }
    return success;
  };

  const toggleLike = async (postId: string, userId: string) => {
    const liked = await PostsRepository.toggleLike(postId, userId);

    // Optimistic update
    setPosts(prev =>
      prev.map(p =>
        p.id === postId
          ? { ...p, likes_count: liked ? p.likes_count + 1 : p.likes_count - 1 }
          : p
      )
    );

    processSyncQueue();
    return liked;
  };

  return {
    posts,
    loading,
    refreshing,
    refresh,
    createPost,
    updatePost,
    deletePost,
    toggleLike,
  };
}
EOF
```

### Step 8: Initialize Database in App

```bash
cat > app/_layout.tsx << 'EOF'
import { Stack } from 'expo-router';
import { useEffect, useState } from 'react';
import { View, Text, ActivityIndicator, StyleSheet } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { AuthProvider } from '@/lib/auth/AuthContext';
import { database } from '@/lib/database';
import { setupAutoSync } from '@/lib/database/sync-queue';

export default function RootLayout() {
  const [dbReady, setDbReady] = useState(false);

  useEffect(() => {
    async function initDatabase() {
      try {
        await database.init();
        setDbReady(true);

        // Set up auto-sync
        const unsubscribe = setupAutoSync();
        return () => unsubscribe();
      } catch (error) {
        console.error('Failed to initialize database:', error);
      }
    }

    initDatabase();
  }, []);

  if (!dbReady) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>Initializing app...</Text>
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <AuthProvider>
        <Stack
          screenOptions={{
            headerStyle: {
              backgroundColor: '#007AFF',
            },
            headerTintColor: '#fff',
            headerTitleStyle: {
              fontWeight: '600',
            },
          }}
        >
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen name="(auth)" options={{ headerShown: false, presentation: 'modal' }} />
          <Stack.Screen name="modal/compose" options={{ presentation: 'modal', title: 'New Post' }} />
          <Stack.Screen name="+not-found" />
        </Stack>
      </AuthProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fff',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: '#8E8E93',
  },
});
EOF
```

### Step 9: Update Home Screen to Use Local Database

```bash
cat > app/'(tabs)'/index.tsx << 'EOF'
import { View, Text, StyleSheet, Pressable, FlatList, RefreshControl } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { usePosts } from '@/lib/hooks/usePosts';
import { useAuth } from '@/lib/auth/AuthContext';

export default function HomeScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const { posts, loading, refreshing, refresh, toggleLike, deletePost } = usePosts();

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.loadingText}>Loading posts...</Text>
      </View>
    );
  }

  if (posts.length === 0) {
    return (
      <View style={styles.centerContainer}>
        <Ionicons name="chatbubbles-outline" size={64} color="#E5E5EA" />
        <Text style={styles.emptyTitle}>No posts yet</Text>
        <Text style={styles.emptyText}>Be the first to share something!</Text>
        <Pressable
          style={styles.composeButton}
          onPress={() => router.push('/modal/compose')}
        >
          <Text style={styles.composeButtonText}>Create Post</Text>
        </Pressable>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={posts}
        keyExtractor={item => item.id}
        renderItem={({ item }) => (
          <PostCard
            post={item}
            onLike={() => user && toggleLike(item.id, user.id)}
            onDelete={user?.id === item.user_id ? () => deletePost(item.id) : undefined}
          />
        )}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={refresh} tintColor="#007AFF" />
        }
        contentContainerStyle={styles.listContent}
      />

      <Pressable
        style={styles.fab}
        onPress={() => router.push('/modal/compose')}
      >
        <Ionicons name="add" size={28} color="#fff" />
      </Pressable>
    </View>
  );
}

function PostCard({
  post,
  onLike,
  onDelete,
}: {
  post: any;
  onLike: () => void;
  onDelete?: () => void;
}) {
  return (
    <View style={styles.postCard}>
      <View style={styles.postHeader}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>U</Text>
        </View>
        <View style={styles.postInfo}>
          <Text style={styles.username}>User</Text>
          <Text style={styles.timestamp}>
            {new Date(post.created_at).toLocaleDateString()}
          </Text>
        </View>
        {onDelete && (
          <Pressable onPress={onDelete} style={styles.deleteButton}>
            <Ionicons name="trash-outline" size={20} color="#FF3B30" />
          </Pressable>
        )}
      </View>

      <Text style={styles.postContent}>{post.content}</Text>

      <View style={styles.postActions}>
        <Pressable style={styles.actionButton} onPress={onLike}>
          <Ionicons name="heart-outline" size={20} color="#8E8E93" />
          <Text style={styles.actionCount}>{post.likes_count}</Text>
        </Pressable>
        <Pressable style={styles.actionButton}>
          <Ionicons name="chatbubble-outline" size={20} color="#8E8E93" />
          <Text style={styles.actionCount}>{post.comments_count}</Text>
        </Pressable>

        {!post.synced_at && (
          <View style={styles.syncBadge}>
            <Ionicons name="cloud-upload-outline" size={16} color="#FF9500" />
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 40,
    backgroundColor: '#f5f5f5',
  },
  loadingText: {
    fontSize: 16,
    color: '#8E8E93',
  },
  emptyTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: '#000',
    marginTop: 16,
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 16,
    color: '#8E8E93',
    textAlign: 'center',
    marginBottom: 24,
  },
  composeButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    backgroundColor: '#007AFF',
    borderRadius: 20,
  },
  composeButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  listContent: {
    paddingBottom: 80,
  },
  postCard: {
    backgroundColor: '#fff',
    marginBottom: 12,
    padding: 16,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#E5E5EA',
  },
  postHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    color: '#fff',
    fontWeight: '600',
  },
  postInfo: {
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
  },
  deleteButton: {
    padding: 8,
  },
  postContent: {
    fontSize: 15,
    lineHeight: 21,
    color: '#000',
    marginBottom: 12,
  },
  postActions: {
    flexDirection: 'row',
    gap: 20,
    alignItems: 'center',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  actionCount: {
    fontSize: 14,
    color: '#8E8E93',
  },
  syncBadge: {
    marginLeft: 'auto',
  },
  fab: {
    position: 'absolute',
    right: 20,
    bottom: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
});
EOF
```

### Step 10: Update Compose Modal

```bash
cat > app/modal/compose.tsx << 'EOF'
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  Pressable,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { useState } from 'react';
import { useRouter } from 'expo-router';
import { useAuth } from '@/lib/auth/AuthContext';
import { usePosts } from '@/lib/hooks/usePosts';
import { Ionicons } from '@expo/vector-icons';

export default function ComposeModal() {
  const router = useRouter();
  const { user } = useAuth();
  const { createPost } = usePosts();
  const [content, setContent] = useState('');
  const [posting, setPosting] = useState(false);

  const handlePost = async () => {
    if (!content.trim() || !user) return;

    setPosting(true);
    try {
      await createPost({
        user_id: user.id,
        content: content.trim(),
        media_url: null,
        media_type: null,
      });

      Alert.alert('Success', 'Post created! It will sync to cloud when online.');
      router.back();
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setPosting(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <View style={styles.header}>
        <Pressable onPress={() => router.back()} disabled={posting}>
          <Text style={styles.cancelText}>Cancel</Text>
        </Pressable>
        <Pressable
          onPress={handlePost}
          style={[styles.postButton, (!content.trim() || posting) && styles.postButtonDisabled]}
          disabled={!content.trim() || posting}
        >
          <Text style={styles.postButtonText}>
            {posting ? 'Posting...' : 'Post'}
          </Text>
        </Pressable>
      </View>

      <TextInput
        style={styles.input}
        placeholder="What's on your mind?"
        value={content}
        onChangeText={setContent}
        multiline
        autoFocus
        maxLength={500}
        placeholderTextColor="#8E8E93"
      />

      <Text style={styles.characterCount}>{content.length}/500</Text>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
  },
  cancelText: {
    fontSize: 16,
    color: '#007AFF',
  },
  postButton: {
    paddingHorizontal: 20,
    paddingVertical: 8,
    backgroundColor: '#007AFF',
    borderRadius: 20,
  },
  postButtonDisabled: {
    backgroundColor: '#E5E5EA',
  },
  postButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  input: {
    flex: 1,
    padding: 16,
    fontSize: 16,
    color: '#000',
    textAlignVertical: 'top',
  },
  characterCount: {
    padding: 16,
    fontSize: 13,
    color: '#8E8E93',
    textAlign: 'right',
  },
});
EOF
```

---

## VERIFY: Testing Local-First Database

### Step 1: Install nanoid

```bash
npm install nanoid
```

### Step 2: Create Supabase Tables

Run this SQL in your Supabase SQL Editor:

```sql
-- Posts table
CREATE TABLE posts (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  media_url TEXT,
  media_type TEXT CHECK(media_type IN ('image', 'video', 'audio')),
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Likes table
CREATE TABLE likes (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Posts are viewable by everyone"
  ON posts FOR SELECT
  USING (true);

CREATE POLICY "Users can create their own posts"
  ON posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts"
  ON posts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts"
  ON posts FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Likes are viewable by everyone"
  ON likes FOR SELECT
  USING (true);

CREATE POLICY "Users can create likes"
  ON likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own likes"
  ON likes FOR DELETE
  USING (auth.uid() = user_id);
```

### Step 3: Test Offline-First Functionality

1. **Start the app**:
```bash
npm start
npm run ios # or npm run android
```

2. **Create posts offline**:
   - Turn off Wi-Fi/mobile data
   - Create 3-5 posts
   - Notice instant feedback (no waiting)
   - Posts appear immediately in feed
   - See "cloud upload" icon (not synced yet)

3. **Test optimistic updates**:
   - Like a post while offline
   - Like count updates immediately
   - All actions feel instant

4. **Test sync**:
   - Turn Wi-Fi back on
   - Pull to refresh
   - Watch console logs for sync process
   - Cloud icons disappear (synced)
   - Check Supabase dashboard - posts should appear

5. **Test persistence**:
   - Close app completely
   - Reopen app
   - Posts still there (loaded from SQLite)

---

## TROUBLESHOOTING

### Issue: "Database not initialized"

**Solution**: Ensure database.init() is called before any queries:
```typescript
await database.init();
```

### Issue: Sync not working

**Solution**: Check network state and Supabase credentials:
```bash
# Test network detection
import NetInfo from '@react-native-community/netinfo';
const state = await NetInfo.fetch();
console.log('Connected:', state.isConnected);
```

### Issue: "UNIQUE constraint failed"

**Solution**: Handle duplicate inserts gracefully:
```sql
INSERT OR IGNORE INTO posts ...
-- or
INSERT OR REPLACE INTO posts ...
```

---

## BEST PRACTICES

### 1. Always Use Transactions for Multi-Step Operations
```typescript
await db.execAsync('BEGIN TRANSACTION');
try {
  await db.runAsync('INSERT INTO posts ...');
  await db.runAsync('UPDATE users ...');
  await db.execAsync('COMMIT');
} catch (error) {
  await db.execAsync('ROLLBACK');
  throw error;
}
```

### 2. Use Indexes for Performance
```sql
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
```

### 3. Implement Proper Error Handling
```typescript
try {
  await PostsRepository.create(input);
} catch (error) {
  if (error.message.includes('UNIQUE')) {
    // Handle duplicate
  } else {
    // Other error
  }
}
```

---

## KEY CONCEPTS RECAP

### 1. Local-First Benefits
- ✅ Instant user feedback
- ✅ Works 100% offline
- ✅ Great user experience
- ✅ Reduced server costs

### 2. Sync Strategy
- Write to local DB first
- Queue changes for cloud sync
- Retry failed syncs automatically
- Handle conflicts gracefully

### 3. Architecture
- SQLite as source of truth
- Supabase as backup/sync layer
- Background sync queue
- Optimistic UI updates

---

## NEXT STEPS

In **Lesson 5**, we'll add:
- Image capture and upload
- expo-image-picker
- expo-camera
- Image optimization
- Progress indicators

**Congratulations!** You now have a production-ready local-first database! 🚀
