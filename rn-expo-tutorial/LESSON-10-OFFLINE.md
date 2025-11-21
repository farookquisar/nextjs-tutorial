# Lesson 10: Offline Support & Storage

**Duration**: 85 minutes | **Difficulty**: Advanced | **Prerequisites**: Lessons 1-9

## Learning Objectives
- Implement comprehensive offline strategy
- Handle conflict resolution
- Detect network state
- Optimize background sync
- Manage storage quotas

## Installation

```bash
npx expo install @react-native-community/netinfo @react-native-async-storage/async-storage
```

## Implementation

### 1. Network State Detection

```typescript
// lib/network/state.ts
import NetInfo from '@react-native-community/netinfo';
import { useState, useEffect } from 'react';

export function useNetworkState() {
  const [isConnected, setIsConnected] = useState(true);
  const [isInternetReachable, setIsInternetReachable] = useState(true);

  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener(state => {
      setIsConnected(state.isConnected ?? false);
      setIsInternetReachable(state.isInternetReachable ?? false);
    });

    return () => unsubscribe();
  }, []);

  return { isConnected, isInternetReachable };
}
```

### 2. Offline Indicator UI

```typescript
// components/ui/OfflineIndicator.tsx
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNetworkState } from '@/lib/network/state';

export function OfflineIndicator() {
  const { isConnected } = useNetworkState();

  if (isConnected) return null;

  return (
    <View style={styles.container}>
      <Ionicons name="cloud-offline" size={16} color="#fff" />
      <Text style={styles.text}>Offline - Changes will sync when online</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FF9500',
    paddingVertical: 8,
    paddingHorizontal: 12,
    gap: 8,
  },
  text: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '500',
  },
});
```

### 3. Conflict Resolution Strategy

```typescript
// lib/sync/conflict-resolution.ts
import { Post } from '../database/types';

export enum ConflictStrategy {
  LOCAL_WINS = 'local_wins',
  REMOTE_WINS = 'remote_wins',
  LAST_WRITE_WINS = 'last_write_wins',
  USER_CHOOSES = 'user_chooses',
}

export function resolveConflict(
  local: Post,
  remote: Post,
  strategy: ConflictStrategy = ConflictStrategy.LAST_WRITE_WINS
): Post {
  switch (strategy) {
    case ConflictStrategy.LOCAL_WINS:
      return local;

    case ConflictStrategy.REMOTE_WINS:
      return remote;

    case ConflictStrategy.LAST_WRITE_WINS:
      return local.updated_at > remote.updated_at ? local : remote;

    case ConflictStrategy.USER_CHOOSES:
      // Show UI for user to choose
      throw new Error('User intervention required');

    default:
      return local;
  }
}

export async function mergeChanges(local: Post, remote: Post): Promise<Post> {
  // Field-level merge strategy
  return {
    ...remote, // Start with remote
    content: local.updated_at > remote.updated_at ? local.content : remote.content,
    likes_count: Math.max(local.likes_count, remote.likes_count),
    comments_count: Math.max(local.comments_count, remote.comments_count),
    version: Math.max(local.version, remote.version) + 1,
  };
}
```

### 4. Advanced Sync Queue

```typescript
// lib/sync/advanced-queue.ts
import { database } from '../database';
import NetInfo from '@react-native-community/netinfo';

interface SyncConfig {
  maxRetries: number;
  retryDelay: number;
  batchSize: number;
}

const DEFAULT_CONFIG: SyncConfig = {
  maxRetries: 3,
  retryDelay: 5000,
  batchSize: 10,
};

export class SyncManager {
  private isSyncing = false;
  private config: SyncConfig;

  constructor(config: Partial<SyncConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  async sync(): Promise<{ success: number; failed: number }> {
    if (this.isSyncing) {
      console.log('Sync already in progress');
      return { success: 0, failed: 0 };
    }

    const netInfo = await NetInfo.fetch();
    if (!netInfo.isConnected) {
      console.log('No internet connection');
      return { success: 0, failed: 0 };
    }

    this.isSyncing = true;
    let successCount = 0;
    let failedCount = 0;

    try {
      const db = database.getDatabase();
      const items = await db.getAllAsync<any>(
        `SELECT * FROM sync_queue
         WHERE status IN ('pending', 'failed')
         AND attempts < ?
         ORDER BY created_at ASC
         LIMIT ?`,
        [this.config.maxRetries, this.config.batchSize]
      );

      for (const item of items) {
        try {
          await this.syncItem(item);
          await this.markSuccess(item.id);
          successCount++;
        } catch (error: any) {
          await this.markFailed(item.id, error.message);
          failedCount++;

          // Exponential backoff
          if (item.attempts < this.config.maxRetries) {
            await this.scheduleRetry(item.id, item.attempts);
          }
        }
      }
    } finally {
      this.isSyncing = false;
    }

    return { success: successCount, failed: failedCount };
  }

  private async syncItem(item: any): Promise<void> {
    // Implement sync logic based on table_name and operation
    // Similar to processSyncQueue from Lesson 4
  }

  private async markSuccess(id: number): Promise<void> {
    const db = database.getDatabase();
    await db.runAsync(
      `UPDATE sync_queue SET status = 'success', synced_at = ? WHERE id = ?`,
      [Date.now(), id]
    );
  }

  private async markFailed(id: number, error: string): Promise<void> {
    const db = database.getDatabase();
    await db.runAsync(
      `UPDATE sync_queue
       SET status = 'failed', attempts = attempts + 1, last_error = ?
       WHERE id = ?`,
      [error, id]
    );
  }

  private async scheduleRetry(id: number, attempts: number): Promise<void> {
    const delay = this.config.retryDelay * Math.pow(2, attempts);
    setTimeout(() => {
      this.sync(); // Retry after delay
    }, delay);
  }
}
```

### 5. Storage Quota Management

```typescript
// lib/storage/quota.ts
import * as FileSystem from 'expo-file-system';
import AsyncStorage from '@react-native-async-storage/async-storage';

export async function checkStorageUsage(): Promise<{
  used: number;
  total: number;
  percentage: number;
}> {
  const info = await FileSystem.getFreeDiskStorageAsync();
  const total = await FileSystem.getTotalDiskCapacityAsync();
  const used = total - info;
  const percentage = (used / total) * 100;

  return { used, total, percentage };
}

export async function cleanupOldData(daysOld: number = 30): Promise<void> {
  const db = database.getDatabase();
  const cutoffDate = Date.now() - (daysOld * 24 * 60 * 60 * 1000);

  // Delete old synced items from sync queue
  await db.runAsync(
    `DELETE FROM sync_queue WHERE status = 'success' AND synced_at < ?`,
    [cutoffDate]
  );

  // Clear old cached user data
  await db.runAsync(
    `DELETE FROM users_cache WHERE cached_at < ?`,
    [cutoffDate]
  );

  console.log(`Cleaned up data older than ${daysOld} days`);
}

export async function getStorageStats(): Promise<{
  posts: number;
  media: number;
  cache: number;
}> {
  const db = database.getDatabase();

  const [posts, media, cache] = await Promise.all([
    db.getFirstAsync<{ count: number }>(`SELECT COUNT(*) as count FROM posts`),
    db.getFirstAsync<{ count: number }>(`SELECT COUNT(*) as count FROM posts WHERE media_url IS NOT NULL`),
    db.getFirstAsync<{ count: number }>(`SELECT COUNT(*) as count FROM users_cache`),
  ]);

  return {
    posts: posts?.count || 0,
    media: media?.count || 0,
    cache: cache?.count || 0,
  };
}
```

### 6. Background Sync with App State

```typescript
// lib/sync/background.ts
import { AppState, AppStateStatus } from 'react-native';
import { useEffect, useRef } from 'react';
import { SyncManager } from './advanced-queue';

export function useBackgroundSync() {
  const appState = useRef(AppState.currentState);
  const syncManager = useRef(new SyncManager());

  useEffect(() => {
    const subscription = AppState.addEventListener('change', nextAppState => {
      // Sync when app comes to foreground
      if (
        appState.current.match(/inactive|background/) &&
        nextAppState === 'active'
      ) {
        console.log('App foregrounded - starting sync');
        syncManager.current.sync();
      }

      appState.current = nextAppState;
    });

    return () => {
      subscription.remove();
    };
  }, []);
}
```

### 7. Sync Status Dashboard

```typescript
// app/settings/sync-status.tsx
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { useState, useEffect } from 'react';
import { database } from '@/lib/database';
import { SyncManager } from '@/lib/sync/advanced-queue';
import { Ionicons } from '@expo/vector-icons';

export default function SyncStatusScreen() {
  const [stats, setStats] = useState({
    pending: 0,
    failed: 0,
    success: 0,
  });
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    const db = database.getDatabase();
    const [pending, failed, success] = await Promise.all([
      db.getFirstAsync<{ count: number }>(`SELECT COUNT(*) as count FROM sync_queue WHERE status = 'pending'`),
      db.getFirstAsync<{ count: number }>(`SELECT COUNT(*) as count FROM sync_queue WHERE status = 'failed'`),
      db.getFirstAsync<{ count: number }>(`SELECT COUNT(*) as count FROM sync_queue WHERE status = 'success'`),
    ]);

    setStats({
      pending: pending?.count || 0,
      failed: failed?.count || 0,
      success: success?.count || 0,
    });
  };

  const handleSync = async () => {
    setSyncing(true);
    const manager = new SyncManager();
    await manager.sync();
    await loadStats();
    setSyncing(false);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Sync Status</Text>

      <View style={styles.stat}>
        <Ionicons name="time-outline" size={24} color="#FF9500" />
        <Text style={styles.statLabel}>Pending</Text>
        <Text style={styles.statValue}>{stats.pending}</Text>
      </View>

      <View style={styles.stat}>
        <Ionicons name="close-circle-outline" size={24} color="#FF3B30" />
        <Text style={styles.statLabel}>Failed</Text>
        <Text style={styles.statValue}>{stats.failed}</Text>
      </View>

      <View style={styles.stat}>
        <Ionicons name="checkmark-circle-outline" size={24} color="#34C759" />
        <Text style={styles.statLabel}>Success</Text>
        <Text style={styles.statValue}>{stats.success}</Text>
      </View>

      <Pressable
        style={styles.syncButton}
        onPress={handleSync}
        disabled={syncing}
      >
        <Text style={styles.syncButtonText}>
          {syncing ? 'Syncing...' : 'Sync Now'}
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#F2F2F7',
    borderRadius: 12,
    marginBottom: 12,
    gap: 12,
  },
  statLabel: {
    flex: 1,
    fontSize: 16,
    color: '#000',
  },
  statValue: {
    fontSize: 20,
    fontWeight: '600',
    color: '#007AFF',
  },
  syncButton: {
    marginTop: 20,
    padding: 16,
    backgroundColor: '#007AFF',
    borderRadius: 12,
    alignItems: 'center',
  },
  syncButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
```

## Key Features Implemented
✅ Network state detection
✅ Offline indicator UI
✅ Conflict resolution strategies
✅ Advanced sync queue with retry
✅ Storage quota management
✅ Background sync
✅ Sync status dashboard

## Best Practices
1. Always show offline indicators
2. Implement exponential backoff for retries
3. Use conflict resolution strategies
4. Clean up old synced data regularly
5. Monitor storage usage
6. Sync on app foreground
7. Provide sync status visibility

## Testing Checklist
- [ ] App works completely offline
- [ ] Offline indicator shows when disconnected
- [ ] Changes sync when back online
- [ ] Conflicts resolve correctly
- [ ] Failed syncs retry with backoff
- [ ] Storage cleanup works
- [ ] Sync status shows accurate counts

## Next: Lesson 11 - Performance & Testing 🚀
