# Lesson 7: Real-time Updates with Supabase Subscriptions

**Tutorial:** Next.js 16 + React 19.2 + Supabase - Complete Learning Path
**Focus:** Real-time collaboration with Supabase Realtime subscriptions
**Prerequisites:** Lessons 1-6 completed

---

## What You'll Build

In this lesson, you'll implement **real-time collaboration features** that allow team members to see live updates without refreshing the page:

- ✅ **Real-time Task Updates** - See when tasks are created, updated, or deleted by team members
- ✅ **Real-time Member Presence** - Track who's currently viewing a project
- ✅ **Optimistic UI Updates** - Instant feedback before server confirmation
- ✅ **Connection State Management** - Handle offline/online status gracefully
- ✅ **Broadcast Channels** - Send custom events between team members
- ✅ **Database Change Subscriptions** - Listen to PostgreSQL changes via Supabase Realtime
- ✅ **React Hooks for Subscriptions** - Reusable hooks with automatic cleanup
- ✅ **Presence Indicators** - Visual indicators showing active users

### Technologies Used

- **Supabase Realtime** - WebSocket-based real-time engine
- **PostgreSQL Replication** - Database change events (INSERT, UPDATE, DELETE)
- **Broadcast Channels** - Custom event broadcasting between clients
- **Presence** - Track online users and their state
- **React 19.2** - `useEffectEvent` for stable subscription callbacks
- **Next.js 16** - Cache Components for initial data + Client Components for real-time updates

---

## Architecture Overview

### Hybrid Caching Strategy: Cache Components + Real-time Updates

This lesson demonstrates a powerful pattern combining **Next.js 16 Cache Components** with **Supabase Realtime**:

```
┌─────────────────────────────────────────────────────────────┐
│                     Initial Page Load                       │
├─────────────────────────────────────────────────────────────┤
│  1. Server Component fetches data (with Cache Components)   │
│     'use cache'                                             │
│     cacheLife('seconds')  ← Very short cache for real-time  │
│     cacheTag('tasks')                                       │
│                                                             │
│  2. Cached data passed as initialTasks to Client Component  │
│     <TaskListRealtime initialTasks={cachedTasks} />        │
│                                                             │
│  3. Client Component subscribes to real-time updates        │
│     WebSocket connection established                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Real-time Updates Flow                     │
├─────────────────────────────────────────────────────────────┤
│  User A creates task → Server Action                        │
│    ↓                                                        │
│  1. Task saved to database                                  │
│  2. updateTag(['tasks', 'tasks-projectId']) ← Invalidate    │
│  3. Supabase Realtime broadcasts change                     │
│    ↓                                                        │
│  User B's browser receives WebSocket event                  │
│    ↓                                                        │
│  Client Component updates UI instantly                      │
│    ↓                                                        │
│  Next page load gets fresh data (cache invalidated)         │
└─────────────────────────────────────────────────────────────┘
```

**Key Benefits:**
- ✅ **Fast Initial Load** - Cached data from Server Components
- ✅ **Instant Updates** - Real-time subscriptions for live changes
- ✅ **Optimal Performance** - Short cache + WebSocket = best of both worlds
- ✅ **Reduced Load** - Cache prevents unnecessary database queries
- ✅ **Fresh Data** - Cache invalidation ensures consistency

---

## Architecture Overview (Continued)

### Supabase Realtime Features

Supabase Realtime provides three types of real-time functionality:

1. **Postgres Changes** - Listen to database table changes (INSERT, UPDATE, DELETE)
2. **Broadcast** - Send ephemeral messages between clients (typing indicators, cursor positions)
3. **Presence** - Track which users are currently online and their state

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     Browser Client A                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  useTaskSubscription()                                │  │
│  │    ↓ Listens to 'prj_tasks' changes                  │  │
│  │    ↓ Broadcasts task events                          │  │
│  │    ↓ Tracks presence (userId, projectId)             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ WebSocket Connection
                      ↓
┌─────────────────────────────────────────────────────────────┐
│              Supabase Realtime Server                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  • PostgreSQL Replication (WAL)                       │  │
│  │  • Broadcast Hub (ephemeral messages)                 │  │
│  │  • Presence State (connected clients)                 │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ WebSocket Connection
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                     Browser Client B                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  useTaskSubscription()                                │  │
│  │    ↑ Receives task changes from Client A             │  │
│  │    ↑ Receives broadcast events                        │  │
│  │    ↑ Sees Client A's presence                         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- **Channels** - Named rooms that clients join to communicate
- **Subscriptions** - Listeners for specific events
- **PostgreSQL WAL** - Write-Ahead Log used for database change events
- **Ephemeral Messages** - Broadcast events that aren't stored in database
- **Presence State** - Synchronized state of all connected clients

---

## Step 1: Enable Realtime in Supabase Dashboard

### 1.1 Enable Realtime for Tables

Before subscribing to table changes, you must enable Realtime replication:

**🎯 Manual Step (Supabase Dashboard):**

1. Go to **Database → Replication** in Supabase Dashboard
2. Find these tables and toggle **Realtime** ON:
   - ✅ `prj_tasks`
   - ✅ `prj_projects`
   - ✅ `prj_project_members`
3. Click **Save** after enabling

**Why:** Supabase Realtime uses PostgreSQL's replication feature. Tables must explicitly opt-in for security.

### 1.2 Verify RLS Policies Apply to Realtime

Realtime respects Row Level Security (RLS) policies. Users only receive events for rows they have permission to see.

**Example:** If User A can't SELECT a task due to RLS, they won't receive real-time updates for that task either.

---

## Step 2: Configure Next.js 16 Cache Components (IMPORTANT)

### 2.1 Update next.config.js

Enable Cache Components with granular cache control:

```bash
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Enable Cache Components (Next.js 16 feature)
    cacheComponents: true,

    // Enable dynamic IO (required for Cache Components)
    dynamicIO: true,
  },
};

export default nextConfig;
EOF
```

**Why These Settings:**
- `cacheComponents: true` - Enables the `'use cache'` directive
- `dynamicIO: true` - Required for Cache Components to work with async operations

### 2.2 Understanding Cache Strategy for Real-time Features

For real-time features, we use **very short cache durations**:

```typescript
'use cache'
cacheLife('seconds')  // 5-10 seconds max for real-time data
cacheTag('tasks')
cacheTag('tasks-projectId')
```

**Why Short Cache?**
- ✅ Still benefits from caching (reduces DB load)
- ✅ Doesn't conflict with real-time updates
- ✅ Fresh data on page refresh
- ✅ Cache invalidation works quickly

**Cache Duration Guidelines:**
- Real-time data (tasks, messages): `cacheLife('seconds')` (5-10s)
- Semi-static data (project info): `cacheLife('minutes')` (5-10m)
- Static data (user profiles): `cacheLife('hours')` or `cacheLife('days')`

---

## Step 3: Extend Constants (Lesson 1 Pattern)

Following the **DRY principle** from Lesson 1, add real-time constants to `src/constants/index.ts`:

```bash
# Open constants file
cat >> src/constants/index.ts << 'EOF'

// ============================================================
// REALTIME CONSTANTS (Lesson 7)
// ============================================================

export const REALTIME_EVENTS = {
  TASK_CREATED: 'task:created',
  TASK_UPDATED: 'task:updated',
  TASK_DELETED: 'task:deleted',
  PROJECT_UPDATED: 'project:updated',
  MEMBER_JOINED: 'member:joined',
  MEMBER_LEFT: 'member:left',
  USER_TYPING: 'user:typing',
} as const;

export const REALTIME_CHANNELS = {
  TASKS: 'tasks',
  PROJECTS: 'projects',
  PRESENCE: 'presence',
} as const;

export const CONNECTION_STATUS = {
  CONNECTING: 'connecting',
  CONNECTED: 'connected',
  DISCONNECTED: 'disconnected',
  ERROR: 'error',
} as const;

export const PRESENCE_EVENTS = {
  JOIN: 'join',
  LEAVE: 'leave',
  SYNC: 'sync',
} as const;

// Type exports
export type RealtimeEvent = typeof REALTIME_EVENTS[keyof typeof REALTIME_EVENTS];
export type RealtimeChannel = typeof REALTIME_CHANNELS[keyof typeof REALTIME_CHANNELS];
export type ConnectionStatus = typeof CONNECTION_STATUS[keyof typeof CONNECTION_STATUS];
export type PresenceEvent = typeof PRESENCE_EVENTS[keyof typeof PRESENCE_EVENTS];

// UI Constants for Realtime
export const REALTIME_UI = {
  RECONNECT_DELAY: 3000, // 3 seconds
  PRESENCE_TIMEOUT: 60000, // 1 minute
  TYPING_INDICATOR_TIMEOUT: 3000, // 3 seconds
  MAX_RECONNECT_ATTEMPTS: 5,
} as const;

// Status Labels
export const CONNECTION_STATUS_LABELS: Record<ConnectionStatus, string> = {
  [CONNECTION_STATUS.CONNECTING]: 'Connecting...',
  [CONNECTION_STATUS.CONNECTED]: 'Connected',
  [CONNECTION_STATUS.DISCONNECTED]: 'Disconnected',
  [CONNECTION_STATUS.ERROR]: 'Connection Error',
};

// Status Colors (Tailwind)
export const CONNECTION_STATUS_COLORS: Record<ConnectionStatus, string> = {
  [CONNECTION_STATUS.CONNECTING]: 'bg-yellow-100 text-yellow-800 border-yellow-200',
  [CONNECTION_STATUS.CONNECTED]: 'bg-green-100 text-green-800 border-green-200',
  [CONNECTION_STATUS.DISCONNECTED]: 'bg-gray-100 text-gray-800 border-gray-200',
  [CONNECTION_STATUS.ERROR]: 'bg-red-100 text-red-800 border-red-200',
};

EOF
```

**Key Points:**
- ✅ **No magic strings** - All event names in constants
- ✅ **Type-safe** - TypeScript types exported from constants
- ✅ **Reusable** - Used across all realtime hooks and components
- ✅ **Extends Lesson 1** - Follows established pattern

---

## Step 3: Create Realtime Types

Create TypeScript types for real-time features:

```bash
cat >> src/types/realtime.ts << 'EOF'
import type { Database } from '@/lib/types/database';
import type { ConnectionStatus, RealtimeEvent } from '@/constants';

// PostgreSQL Change Events
export type PostgresChangeEvent<T = any> = {
  eventType: 'INSERT' | 'UPDATE' | 'DELETE';
  new: T;
  old: T;
  errors: string[] | null;
};

// Task Change Payload
export type TaskChangePayload = PostgresChangeEvent<Database['public']['Tables']['prj_tasks']['Row']>;

// Project Change Payload
export type ProjectChangePayload = PostgresChangeEvent<Database['public']['Tables']['prj_projects']['Row']>;

// Member Change Payload
export type MemberChangePayload = PostgresChangeEvent<Database['public']['Tables']['prj_project_members']['Row']>;

// Broadcast Event Payload
export type BroadcastPayload = {
  event: RealtimeEvent;
  payload: any;
  userId?: string;
  timestamp: string;
};

// Presence State
export type PresenceState = {
  userId: string;
  userName?: string;
  userEmail?: string;
  projectId?: string;
  taskId?: string;
  lastSeen: string;
};

// Connection State
export type ConnectionState = {
  status: ConnectionStatus;
  error?: string;
  reconnectAttempts: number;
};

// Subscription Options
export type SubscriptionOptions = {
  channelName: string;
  onConnect?: () => void;
  onDisconnect?: () => void;
  onError?: (error: any) => void;
};

EOF
```

---

## Step 4: Create Cached Data Fetchers

Before creating the UI components, let's create Server Component functions that fetch and cache initial data:

```bash
cat > src/lib/data/tasks-cached.ts << 'EOF'
import 'server-only';
import { cacheLife, cacheTag } from 'next/cache';
import { getTasks } from '@/lib/actions/tasks';
import type { Database } from '@/lib/types/database';

type Task = Database['public']['Tables']['prj_tasks']['Row'];

/**
 * Cached function to fetch tasks with very short cache duration
 * Perfect for real-time features where data changes frequently
 *
 * Cache Strategy:
 * - cacheLife('seconds') = 5-10 second cache
 * - Very short to avoid stale data
 * - Still provides performance benefit
 * - Cache invalidated on mutations via updateTag()
 */
export async function getTasksCached(projectId: string): Promise<Task[]> {
  'use cache';
  cacheLife('seconds'); // 5-10 seconds for real-time data
  cacheTag('tasks');
  cacheTag(`tasks-${projectId}`);

  const result = await getTasks({ projectId });

  if (!result.success || !result.data) {
    return [];
  }

  return result.data;
}

/**
 * Get all tasks (without project filter)
 * Used for dashboard overview
 */
export async function getAllTasksCached(): Promise<Task[]> {
  'use cache';
  cacheLife('seconds');
  cacheTag('tasks');
  cacheTag('all-tasks');

  const result = await getTasks({});

  if (!result.success || !result.data) {
    return [];
  }

  return result.data;
}

EOF
```

**Key Features:**
- ✅ **Server-only** - Uses `'server-only'` to prevent client-side usage
- ✅ **Very short cache** - `cacheLife('seconds')` for frequently changing data
- ✅ **Granular tags** - Both generic and specific tags for fine-grained invalidation
- ✅ **Type-safe** - Full TypeScript typing
- ✅ **Error handling** - Returns empty array on error

---

## Step 5: Create useRealtimeSubscription Hook

Create a base hook for managing Supabase Realtime subscriptions:

```bash
mkdir -p src/hooks/realtime
cat > src/hooks/realtime/useRealtimeSubscription.ts << 'EOF'
'use client';

import { useEffect, useState, useRef } from 'react';
import { createClient } from '@/lib/supabase/client';
import { CONNECTION_STATUS, REALTIME_UI } from '@/constants';
import type { ConnectionState, SubscriptionOptions } from '@/types/realtime';
import type { RealtimeChannel } from '@supabase/supabase-js';

/**
 * Base hook for managing Supabase Realtime subscriptions
 * Handles connection state, reconnection logic, and cleanup
 */
export function useRealtimeSubscription(options: SubscriptionOptions) {
  const { channelName, onConnect, onDisconnect, onError } = options;

  const [connectionState, setConnectionState] = useState<ConnectionState>({
    status: CONNECTION_STATUS.CONNECTING,
    reconnectAttempts: 0,
  });

  const channelRef = useRef<RealtimeChannel | null>(null);
  const supabase = createClient();

  useEffect(() => {
    let mounted = true;

    // Create channel
    const channel = supabase.channel(channelName);
    channelRef.current = channel;

    // Subscribe to channel with connection callbacks
    channel
      .subscribe((status) => {
        if (!mounted) return;

        if (status === 'SUBSCRIBED') {
          setConnectionState({
            status: CONNECTION_STATUS.CONNECTED,
            reconnectAttempts: 0,
          });
          onConnect?.();
        } else if (status === 'CHANNEL_ERROR') {
          setConnectionState((prev) => ({
            status: CONNECTION_STATUS.ERROR,
            error: 'Failed to connect to realtime',
            reconnectAttempts: prev.reconnectAttempts + 1,
          }));
          onError?.('Channel error');
        } else if (status === 'TIMED_OUT') {
          setConnectionState((prev) => ({
            status: CONNECTION_STATUS.ERROR,
            error: 'Connection timed out',
            reconnectAttempts: prev.reconnectAttempts + 1,
          }));
          onError?.('Connection timed out');
        } else if (status === 'CLOSED') {
          setConnectionState({
            status: CONNECTION_STATUS.DISCONNECTED,
            reconnectAttempts: 0,
          });
          onDisconnect?.();
        }
      });

    // Cleanup on unmount
    return () => {
      mounted = false;
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }
    };
  }, [channelName, onConnect, onDisconnect, onError]);

  return {
    channel: channelRef.current,
    connectionState,
  };
}

EOF
```

**Key Features:**
- ✅ **Automatic cleanup** - Unsubscribes when component unmounts
- ✅ **Connection state tracking** - Know when connected/disconnected
- ✅ **Reconnection attempts** - Count failed connection attempts
- ✅ **Callback support** - Execute code on connect/disconnect/error

---

## Step 6: Create useTaskSubscription Hook

Create a hook specifically for subscribing to task changes:

```bash
cat > src/hooks/realtime/useTaskSubscription.ts << 'EOF'
'use client';

import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useRealtimeSubscription } from './useRealtimeSubscription';
import { DB_TABLES } from '@/constants';
import type { TaskChangePayload } from '@/types/realtime';
import type { Database } from '@/lib/types/database';

type Task = Database['public']['Tables']['prj_tasks']['Row'];

type TaskSubscriptionOptions = {
  projectId?: string;
  onTaskCreated?: (task: Task) => void;
  onTaskUpdated?: (task: Task) => void;
  onTaskDeleted?: (task: Task) => void;
};

/**
 * Hook for subscribing to real-time task changes
 * Listens to PostgreSQL changes on prj_tasks table
 *
 * @example
 * ```tsx
 * const { tasks, connectionState } = useTaskSubscription({
 *   projectId: '123',
 *   onTaskCreated: (task) => console.log('New task:', task),
 * });
 * ```
 */
export function useTaskSubscription(options: TaskSubscriptionOptions = {}) {
  const { projectId, onTaskCreated, onTaskUpdated, onTaskDeleted } = options;

  const [tasks, setTasks] = useState<Task[]>([]);
  const supabase = createClient();

  // Channel name - unique per project if projectId provided
  const channelName = projectId
    ? `${DB_TABLES.TASKS}:project:${projectId}`
    : DB_TABLES.TASKS;

  const { channel, connectionState } = useRealtimeSubscription({
    channelName,
  });

  useEffect(() => {
    if (!channel) return;

    // Listen to INSERT events
    channel.on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: DB_TABLES.TASKS,
        filter: projectId ? `project_id=eq.${projectId}` : undefined,
      },
      (payload: TaskChangePayload) => {
        const newTask = payload.new as Task;
        setTasks((prev) => [...prev, newTask]);
        onTaskCreated?.(newTask);
      }
    );

    // Listen to UPDATE events
    channel.on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: DB_TABLES.TASKS,
        filter: projectId ? `project_id=eq.${projectId}` : undefined,
      },
      (payload: TaskChangePayload) => {
        const updatedTask = payload.new as Task;
        setTasks((prev) =>
          prev.map((task) => (task.id === updatedTask.id ? updatedTask : task))
        );
        onTaskUpdated?.(updatedTask);
      }
    );

    // Listen to DELETE events
    channel.on(
      'postgres_changes',
      {
        event: 'DELETE',
        schema: 'public',
        table: DB_TABLES.TASKS,
        filter: projectId ? `project_id=eq.${projectId}` : undefined,
      },
      (payload: TaskChangePayload) => {
        const deletedTask = payload.old as Task;
        setTasks((prev) => prev.filter((task) => task.id !== deletedTask.id));
        onTaskDeleted?.(deletedTask);
      }
    );

    return () => {
      if (channel) {
        channel.unsubscribe();
      }
    };
  }, [channel, projectId, onTaskCreated, onTaskUpdated, onTaskDeleted]);

  return {
    tasks,
    connectionState,
  };
}

EOF
```

**How It Works:**
1. Creates a channel for the project (or all tasks)
2. Listens to PostgreSQL changes (INSERT, UPDATE, DELETE)
3. Filters changes by `project_id` if provided
4. Calls callbacks when events occur
5. Updates local state with changes

---

## Step 7: Create usePresence Hook

Create a hook for tracking online users:

```bash
cat > src/hooks/realtime/usePresence.ts << 'EOF'
'use client';

import { useEffect, useState } from 'react';
import { useRealtimeSubscription } from './useRealtimeSubscription';
import type { PresenceState } from '@/types/realtime';

type UsePresenceOptions = {
  channelName: string;
  userId: string;
  userName?: string;
  userEmail?: string;
  metadata?: Record<string, any>;
};

/**
 * Hook for tracking presence (who's online)
 *
 * @example
 * ```tsx
 * const { presenceState, onlineUsers } = usePresence({
 *   channelName: 'project:123',
 *   userId: user.id,
 *   userName: user.name,
 *   metadata: { projectId: '123' },
 * });
 * ```
 */
export function usePresence(options: UsePresenceOptions) {
  const { channelName, userId, userName, userEmail, metadata = {} } = options;

  const [presenceState, setPresenceState] = useState<Record<string, PresenceState>>({});
  const [onlineUsers, setOnlineUsers] = useState<PresenceState[]>([]);

  const { channel, connectionState } = useRealtimeSubscription({
    channelName: `presence:${channelName}`,
  });

  useEffect(() => {
    if (!channel) return;

    // Track presence
    const presenceTrack = channel.track({
      userId,
      userName,
      userEmail,
      ...metadata,
      lastSeen: new Date().toISOString(),
    });

    // Listen to presence changes
    channel.on('presence', { event: 'sync' }, () => {
      const state = channel.presenceState();
      setPresenceState(state);

      // Flatten presence state to array
      const users = Object.values(state).flatMap((presences) =>
        presences.map((p) => p as PresenceState)
      );
      setOnlineUsers(users);
    });

    channel.on('presence', { event: 'join' }, ({ newPresences }) => {
      console.log('User joined:', newPresences);
    });

    channel.on('presence', { event: 'leave' }, ({ leftPresences }) => {
      console.log('User left:', leftPresences);
    });

    return () => {
      if (channel) {
        channel.untrack();
      }
    };
  }, [channel, userId, userName, userEmail, metadata]);

  return {
    presenceState,
    onlineUsers,
    connectionState,
  };
}

EOF
```

**Presence Features:**
- ✅ Track who's online in real-time
- ✅ Show user metadata (name, email, custom data)
- ✅ Detect when users join/leave
- ✅ Automatic cleanup when user disconnects

---

## Step 8: Create useBroadcast Hook

Create a hook for sending/receiving custom events:

```bash
cat > src/hooks/realtime/useBroadcast.ts << 'EOF'
'use client';

import { useEffect, useCallback } from 'react';
import { useRealtimeSubscription } from './useRealtimeSubscription';
import type { BroadcastPayload, RealtimeEvent } from '@/types/realtime';

type UseBroadcastOptions = {
  channelName: string;
  userId?: string;
  onEvent?: (payload: BroadcastPayload) => void;
};

/**
 * Hook for broadcasting custom events between clients
 * Use for ephemeral data like typing indicators, cursor positions
 *
 * @example
 * ```tsx
 * const { broadcast } = useBroadcast({
 *   channelName: 'project:123',
 *   userId: user.id,
 *   onEvent: (payload) => {
 *     if (payload.event === 'user:typing') {
 *       setTypingUsers(prev => [...prev, payload.userId]);
 *     }
 *   },
 * });
 *
 * // Send typing indicator
 * broadcast('user:typing', { taskId: '456' });
 * ```
 */
export function useBroadcast(options: UseBroadcastOptions) {
  const { channelName, userId, onEvent } = options;

  const { channel, connectionState } = useRealtimeSubscription({
    channelName: `broadcast:${channelName}`,
  });

  useEffect(() => {
    if (!channel) return;

    // Listen to broadcast events
    channel.on('broadcast', { event: '*' }, (payload: any) => {
      const broadcastPayload: BroadcastPayload = {
        event: payload.event,
        payload: payload.payload,
        userId: payload.userId,
        timestamp: payload.timestamp || new Date().toISOString(),
      };

      // Don't trigger callback for own events (optional)
      if (payload.userId !== userId) {
        onEvent?.(broadcastPayload);
      }
    });

    return () => {
      if (channel) {
        channel.unsubscribe();
      }
    };
  }, [channel, userId, onEvent]);

  // Function to broadcast an event
  const broadcast = useCallback(
    async (event: RealtimeEvent, payload: any = {}) => {
      if (!channel) {
        console.warn('Channel not ready, cannot broadcast');
        return;
      }

      await channel.send({
        type: 'broadcast',
        event,
        payload: {
          ...payload,
          userId,
          timestamp: new Date().toISOString(),
        },
      });
    },
    [channel, userId]
  );

  return {
    broadcast,
    connectionState,
  };
}

EOF
```

**Broadcast Use Cases:**
- ✅ Typing indicators ("User is typing...")
- ✅ Cursor positions (collaborative editing)
- ✅ Temporary notifications
- ✅ Live reactions (emoji reactions)

---

## Step 9: Create Connection Status Component

Create a component to show connection status:

```bash
mkdir -p src/components/features/realtime
cat > src/components/features/realtime/ConnectionStatus.tsx << 'EOF'
import { CONNECTION_STATUS, CONNECTION_STATUS_LABELS, CONNECTION_STATUS_COLORS } from '@/constants';
import type { ConnectionState } from '@/types/realtime';

type ConnectionStatusProps = {
  connectionState: ConnectionState;
  showLabel?: boolean;
};

/**
 * Component to display real-time connection status
 * Shows colored badge with connection state
 */
export function ConnectionStatus({ connectionState, showLabel = true }: ConnectionStatusProps) {
  const { status, error, reconnectAttempts } = connectionState;

  const colorClass = CONNECTION_STATUS_COLORS[status];
  const label = CONNECTION_STATUS_LABELS[status];

  return (
    <div className="flex items-center gap-2">
      {/* Status Indicator Dot */}
      <div className="flex items-center gap-2">
        <div
          className={`h-2 w-2 rounded-full ${
            status === CONNECTION_STATUS.CONNECTED
              ? 'bg-green-500 animate-pulse'
              : status === CONNECTION_STATUS.CONNECTING
              ? 'bg-yellow-500 animate-pulse'
              : status === CONNECTION_STATUS.ERROR
              ? 'bg-red-500'
              : 'bg-gray-500'
          }`}
        />

        {showLabel && (
          <span
            className={`text-sm px-2 py-1 rounded-md border ${colorClass}`}
          >
            {label}
          </span>
        )}
      </div>

      {/* Error Message */}
      {error && (
        <span className="text-xs text-red-600">
          {error}
          {reconnectAttempts > 0 && ` (attempt ${reconnectAttempts})`}
        </span>
      )}
    </div>
  );
}

EOF
```

---

## Step 10: Create Online Users Component

Create a component to display online users:

```bash
cat > src/components/features/realtime/OnlineUsers.tsx << 'EOF'
'use client';

import { usePresence } from '@/hooks/realtime/usePresence';
import type { PresenceState } from '@/types/realtime';

type OnlineUsersProps = {
  channelName: string;
  currentUserId: string;
  currentUserName?: string;
  currentUserEmail?: string;
  metadata?: Record<string, any>;
};

/**
 * Component showing online users with presence tracking
 */
export function OnlineUsers({
  channelName,
  currentUserId,
  currentUserName,
  currentUserEmail,
  metadata,
}: OnlineUsersProps) {
  const { onlineUsers, connectionState } = usePresence({
    channelName,
    userId: currentUserId,
    userName: currentUserName,
    userEmail: currentUserEmail,
    metadata,
  });

  // Filter out current user from display
  const otherUsers = onlineUsers.filter((user) => user.userId !== currentUserId);

  if (otherUsers.length === 0) {
    return (
      <div className="text-sm text-gray-500">
        No other users online
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <h3 className="text-sm font-medium text-gray-700">
        Online Now ({otherUsers.length})
      </h3>

      <div className="flex flex-wrap gap-2">
        {otherUsers.map((user) => (
          <div
            key={user.userId}
            className="flex items-center gap-2 px-3 py-1.5 bg-green-50 border border-green-200 rounded-full"
          >
            {/* Green dot indicator */}
            <div className="h-2 w-2 bg-green-500 rounded-full animate-pulse" />

            {/* User name or email */}
            <span className="text-sm text-green-800">
              {user.userName || user.userEmail || 'Anonymous'}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

EOF
```

---

## Step 11: Create Real-time Task List Component with Cache Integration

Update the task list to use real-time subscriptions with cached initial data:

```bash
cat > src/components/features/tasks/TaskListRealtime.tsx << 'EOF'
'use client';

import { useState } from 'react';
import { useTaskSubscription } from '@/hooks/realtime/useTaskSubscription';
import { ConnectionStatus } from '@/components/features/realtime/ConnectionStatus';
import { TaskCard } from './TaskCard';
import type { Database } from '@/lib/types/database';

type Task = Database['public']['Tables']['prj_tasks']['Row'];

type TaskListRealtimeProps = {
  projectId: string;
  initialTasks: Task[]; // Comes from cached Server Component
};

/**
 * Task list with real-time updates
 *
 * Hybrid Architecture:
 * 1. Receives cached initial data from Server Component
 * 2. Subscribes to real-time WebSocket updates
 * 3. Updates UI instantly when changes occur
 *
 * Why This Works:
 * - Server Component caches data with cacheLife('seconds')
 * - Client Component keeps UI in sync via WebSocket
 * - Cache invalidation (updateTag) ensures fresh data on next load
 * - Best of both worlds: fast initial load + live updates
 */
export function TaskListRealtime({ projectId, initialTasks }: TaskListRealtimeProps) {
  // Initialize with cached data from server
  const [tasks, setTasks] = useState<Task[]>(initialTasks);
  const [notification, setNotification] = useState<string | null>(null);

  // Subscribe to real-time task changes
  const { connectionState } = useTaskSubscription({
    projectId,
    onTaskCreated: (task) => {
      setTasks((prev) => [task, ...prev]);
      showNotification('New task created');
    },
    onTaskUpdated: (task) => {
      setTasks((prev) =>
        prev.map((t) => (t.id === task.id ? task : t))
      );
      showNotification('Task updated');
    },
    onTaskDeleted: (task) => {
      setTasks((prev) => prev.filter((t) => t.id !== task.id));
      showNotification('Task deleted');
    },
  });

  // Show notification and auto-dismiss after 3 seconds
  const showNotification = (message: string) => {
    setNotification(message);
    setTimeout(() => setNotification(null), 3000);
  };

  return (
    <div className="space-y-4">
      {/* Connection Status */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold">Tasks</h2>
        <ConnectionStatus connectionState={connectionState} />
      </div>

      {/* Notification Toast */}
      {notification && (
        <div className="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-2 rounded-md animate-fade-in">
          {notification}
        </div>
      )}

      {/* Task List */}
      {tasks.length === 0 ? (
        <p className="text-gray-500">No tasks yet</p>
      ) : (
        <div className="grid gap-4">
          {tasks.map((task) => (
            <TaskCard key={task.id} task={task} />
          ))}
        </div>
      )}
    </div>
  );
}

EOF
```

**Key Features:**
- ✅ **Cached Initial Data** - Receives pre-cached data from Server Component
- ✅ **Real-time Updates** - WebSocket subscription for live changes
- ✅ **Connection Status** - Visual indicator of WebSocket connection
- ✅ **Toast Notifications** - User feedback for changes
- ✅ **Optimistic UI** - Updates instantly on real-time events
- ✅ **No Redundant Fetching** - Removed `useEffect` fetch (relies on cache + realtime)

**Why No useEffect Fetch:**
- Server Component provides fresh cached data on every page load
- Real-time subscription keeps data in sync after initial load
- Cache invalidation ensures next page load has fresh data
- Eliminates double-fetching problem

---

## Step 12: Create Real-time Project Page with Cache Components

Update the project tasks page to use Cache Components with Suspense and real-time features:

```bash
cat > src/app/dashboard/projects/[id]/tasks/page-realtime.tsx << 'EOF'
import { Suspense } from 'react';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getProject } from '@/lib/actions/projects';
import { getTasksCached } from '@/lib/data/tasks-cached';
import { TaskListRealtime } from '@/components/features/tasks/TaskListRealtime';
import { OnlineUsers } from '@/components/features/realtime/OnlineUsers';
import { ROUTES } from '@/constants';
import Link from 'next/link';

type ProjectTasksPageProps = {
  params: Promise<{ id: string }>;
};

/**
 * Server Component that provides cached initial data
 * Uses Cache Components for performance with real-time updates
 */
async function TasksWithCache({ projectId }: { projectId: string }) {
  // Fetch cached tasks (cacheLife('seconds') for real-time data)
  const initialTasks = await getTasksCached(projectId);

  return <TaskListRealtime projectId={projectId} initialTasks={initialTasks} />;
}

/**
 * Loading fallback for Suspense boundary
 */
function TasksLoading() {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold">Tasks</h2>
        <div className="text-sm text-gray-500">Loading...</div>
      </div>
      <div className="grid gap-4">
        {[1, 2, 3].map((i) => (
          <div key={i} className="bg-gray-100 h-24 rounded-md animate-pulse" />
        ))}
      </div>
    </div>
  );
}

/**
 * Project tasks page with real-time updates
 *
 * Architecture:
 * 1. Server Component (this page) - Auth check, fetch project info
 * 2. Suspense boundary - Streaming for async data
 * 3. TasksWithCache - Cached data fetcher using Cache Components
 * 4. TaskListRealtime - Client Component with WebSocket subscription
 */
export default async function ProjectTasksPage({ params }: ProjectTasksPageProps) {
  const { id: projectId } = await params;

  // Auth check
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect(ROUTES.LOGIN);

  // Fetch project info (can also be cached with longer duration)
  const projectResult = await getProject(projectId);

  if (!projectResult.success || !projectResult.data) {
    redirect(ROUTES.DASHBOARD_PROJECTS);
  }

  const project = projectResult.data;

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">{project.name}</h1>
          <p className="text-gray-600">{project.description}</p>
        </div>

        <Link
          href={`${ROUTES.DASHBOARD_PROJECTS}/${projectId}/tasks/new`}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
        >
          Create Task
        </Link>
      </div>

      {/* Online Users */}
      <OnlineUsers
        channelName={`project:${projectId}`}
        currentUserId={user.id}
        currentUserEmail={user.email}
        metadata={{ projectId }}
      />

      {/* Real-time Task List with Suspense */}
      <Suspense fallback={<TasksLoading />}>
        <TasksWithCache projectId={projectId} />
      </Suspense>
    </div>
  );
}

EOF
```

**Architecture Breakdown:**

1. **Server Component** (`ProjectTasksPage`)
   - Handles authentication
   - Fetches project metadata
   - Renders layout and header
   - Wraps async content in Suspense

2. **Suspense Boundary**
   - Enables streaming for async Server Components
   - Shows loading state while cache resolves
   - Improves perceived performance

3. **Cached Data Fetcher** (`TasksWithCache`)
   - Uses `getTasksCached()` with `'use cache'`
   - Very short cache duration (`cacheLife('seconds')`)
   - Tagged for granular invalidation
   - Streams data to client

4. **Client Component** (`TaskListRealtime`)
   - Receives cached initial data as props
   - Establishes WebSocket connection
   - Handles real-time updates
   - Updates UI instantly

**Benefits:**
- ✅ **Fast Initial Load** - Cached data served instantly
- ✅ **Progressive Enhancement** - Suspense provides smooth loading
- ✅ **Live Updates** - Real-time after initial load
- ✅ **Reduced Load** - Cache prevents redundant DB queries
- ✅ **Fresh Data** - Short cache + invalidation ensures consistency

---

## Step 13: Update Server Actions for Cache Invalidation

Replace `revalidatePath` with `updateTag` in your Server Actions to work with Cache Components:

```bash
cat > src/lib/actions/tasks-with-cache-invalidation.ts << 'EOF'
'use server';

import { updateTag } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import { DB_TABLES } from '@/constants';
import type { Database } from '@/lib/types/database';

type TaskInput = Omit<
  Database['public']['Tables']['prj_tasks']['Insert'],
  'id' | 'created_at' | 'updated_at'
>;

/**
 * Create task with cache invalidation
 *
 * Cache Invalidation Strategy:
 * 1. Task is saved to database
 * 2. updateTag() invalidates relevant caches
 * 3. Supabase Realtime broadcasts change to connected clients
 * 4. Next page load gets fresh data (cache was invalidated)
 */
export async function createTaskWithCache(input: TaskInput) {
  try {
    const supabase = await createClient();

    // Insert task
    const { data, error } = await supabase
      .from(DB_TABLES.TASKS)
      .insert(input)
      .select()
      .single();

    if (error) throw error;

    // Invalidate caches (replaces revalidatePath)
    updateTag('tasks'); // Invalidate all tasks cache
    updateTag(`tasks-${input.project_id}`); // Invalidate project-specific cache
    updateTag('all-tasks'); // Invalidate dashboard cache

    return { success: true, data };
  } catch (error) {
    console.error('Error creating task:', error);
    return { success: false, error: 'Failed to create task' };
  }
}

/**
 * Update task with cache invalidation
 */
export async function updateTaskWithCache(
  taskId: string,
  updates: Partial<TaskInput>
) {
  try {
    const supabase = await createClient();

    // Get current task to find project_id for cache invalidation
    const { data: currentTask } = await supabase
      .from(DB_TABLES.TASKS)
      .select('project_id')
      .eq('id', taskId)
      .single();

    // Update task
    const { data, error } = await supabase
      .from(DB_TABLES.TASKS)
      .update(updates)
      .eq('id', taskId)
      .select()
      .single();

    if (error) throw error;

    // Invalidate caches
    updateTag('tasks');
    if (currentTask?.project_id) {
      updateTag(`tasks-${currentTask.project_id}`);
    }
    updateTag('all-tasks');

    return { success: true, data };
  } catch (error) {
    console.error('Error updating task:', error);
    return { success: false, error: 'Failed to update task' };
  }
}

/**
 * Delete task with cache invalidation
 */
export async function deleteTaskWithCache(taskId: string, projectId: string) {
  try {
    const supabase = await createClient();

    const { error } = await supabase
      .from(DB_TABLES.TASKS)
      .delete()
      .eq('id', taskId);

    if (error) throw error;

    // Invalidate caches
    updateTag('tasks');
    updateTag(`tasks-${projectId}`);
    updateTag('all-tasks');

    return { success: true };
  } catch (error) {
    console.error('Error deleting task:', error);
    return { success: false, error: 'Failed to delete task' };
  }
}

EOF
```

**Key Changes:**
- ✅ **`updateTag()` instead of `revalidatePath()`** - Works with Cache Components
- ✅ **Granular invalidation** - Multiple tags for fine-grained control
- ✅ **Generic + Specific tags** - Both `'tasks'` and `'tasks-projectId'`
- ✅ **Works with Real-time** - Cache invalidation + WebSocket = complete sync

**Flow:**
1. User A creates task → Server Action called
2. Task saved to DB
3. `updateTag(['tasks', 'tasks-123'])` invalidates caches
4. Supabase Realtime broadcasts INSERT event
5. User B's WebSocket receives event → UI updates instantly
6. User B refreshes page → Gets fresh data (cache was invalidated)

---

## Step 14: Add Realtime to Main Tasks Page

To use the real-time version with Cache Components, update your existing tasks page:

```bash
# Backup original page
cp src/app/dashboard/projects/[id]/tasks/page.tsx src/app/dashboard/projects/[id]/tasks/page.backup.tsx

# Replace with real-time + cache version
cp src/app/dashboard/projects/[id]/tasks/page-realtime.tsx src/app/dashboard/projects/[id]/tasks/page.tsx
```

Or manually update `src/app/dashboard/projects/[id]/tasks/page.tsx` to:
1. Import `getTasksCached` instead of `getTasks`
2. Wrap TaskListRealtime in Suspense
3. Use TasksWithCache pattern shown in Step 12

---

## Step 15: Add Typing Indicator Example

Create a component showing typing indicators using broadcast:

```bash
cat > src/components/features/realtime/TypingIndicator.tsx << 'EOF'
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useBroadcast } from '@/hooks/realtime/useBroadcast';
import { REALTIME_EVENTS, REALTIME_UI } from '@/constants';

type TypingIndicatorProps = {
  channelName: string;
  userId: string;
  userName?: string;
};

type TypingUser = {
  userId: string;
  userName?: string;
  timestamp: string;
};

/**
 * Component showing typing indicators
 * Uses broadcast to send ephemeral typing events
 */
export function TypingIndicator({ channelName, userId, userName }: TypingIndicatorProps) {
  const [typingUsers, setTypingUsers] = useState<TypingUser[]>([]);

  const { broadcast } = useBroadcast({
    channelName,
    userId,
    onEvent: (payload) => {
      if (payload.event === REALTIME_EVENTS.USER_TYPING) {
        const typingUser: TypingUser = {
          userId: payload.userId || 'unknown',
          userName: payload.payload.userName,
          timestamp: payload.timestamp,
        };

        setTypingUsers((prev) => {
          // Remove duplicate user
          const filtered = prev.filter((u) => u.userId !== typingUser.userId);
          return [...filtered, typingUser];
        });
      }
    },
  });

  // Auto-remove typing users after timeout
  useEffect(() => {
    const interval = setInterval(() => {
      const now = Date.now();
      setTypingUsers((prev) =>
        prev.filter((user) => {
          const userTime = new Date(user.timestamp).getTime();
          return now - userTime < REALTIME_UI.TYPING_INDICATOR_TIMEOUT;
        })
      );
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  // Broadcast typing event
  const sendTypingEvent = useCallback(() => {
    broadcast(REALTIME_EVENTS.USER_TYPING, { userName });
  }, [broadcast, userName]);

  if (typingUsers.length === 0) return null;

  return (
    <div className="text-sm text-gray-500 italic">
      {typingUsers.map((user) => user.userName || 'Someone').join(', ')}
      {typingUsers.length === 1 ? ' is' : ' are'} typing...
    </div>
  );
}

// Export function to trigger typing event
export function useTypingIndicator(channelName: string, userId: string, userName?: string) {
  const { broadcast } = useBroadcast({
    channelName,
    userId,
  });

  const sendTyping = useCallback(() => {
    broadcast(REALTIME_EVENTS.USER_TYPING, { userName });
  }, [broadcast, userName]);

  return { sendTyping };
}

EOF
```

**Usage:**
```tsx
// In your comment form or task description editor
const { sendTyping } = useTypingIndicator('project:123', user.id, user.name);

<input
  onChange={(e) => {
    // Send typing event on every keystroke
    sendTyping();
  }}
/>
```

---

## Step 16: Add CSS Animations

Add CSS for fade-in animation:

```bash
cat >> src/app/globals.css << 'EOF'

/* Real-time notification animations */
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fade-in 0.3s ease-out;
}

EOF
```

---

## Step 17: Export Realtime Hooks

Create an index file to export all realtime hooks:

```bash
cat > src/hooks/realtime/index.ts << 'EOF'
export { useRealtimeSubscription } from './useRealtimeSubscription';
export { useTaskSubscription } from './useTaskSubscription';
export { usePresence } from './usePresence';
export { useBroadcast } from './useBroadcast';

EOF
```

---

## Verification Steps

### 1. Verify Cache Components Configuration

**Check next.config.js:**

```bash
cat next.config.js
```

**Expected output:**
```javascript
experimental: {
  cacheComponents: true,
  dynamicIO: true,
}
```

**Test cache is working:**
1. Open DevTools → Network tab
2. Refresh page twice
3. Second load should be faster (cache hit)
4. Check terminal for cache logs (if enabled)

### 2. Test Cache Duration and Tags

**Verify cache tags in code:**

```bash
# Check tasks-cached.ts has proper cache directives
cat src/lib/data/tasks-cached.ts | grep -A 5 "'use cache'"
```

**Expected:**
```typescript
'use cache'
cacheLife('seconds')  // Very short for real-time
cacheTag('tasks')
cacheTag(`tasks-${projectId}`)
```

**Test cache invalidation:**
1. Load project tasks page
2. Create a new task
3. Refresh page
4. **Expected:** New task appears (cache was invalidated by updateTag)

### 3. Test Real-time Task Updates

**Test in two browser windows:**

```bash
# Terminal 1: Start dev server
npm run dev
```

**Browser Window 1:**
1. Login as User A
2. Go to project tasks page: `http://localhost:3000/dashboard/projects/[id]/tasks`
3. Keep window open

**Browser Window 2:**
1. Login as User A (same user, different session) or User B (if testing multi-user)
2. Go to same project tasks page
3. Create a new task
4. **Expected:** Task appears in Window 1 instantly without refresh ✅

### 4. Test Suspense Boundaries

**Check Suspense is working:**
1. Open DevTools → Network tab
2. Throttle to "Slow 3G"
3. Refresh page
4. **Expected:** See loading skeleton while tasks load ✅
5. **Expected:** Page header and buttons appear immediately ✅

**Verify in code:**
```bash
# Check page has Suspense wrapper
cat src/app/dashboard/projects/\[id\]/tasks/page.tsx | grep -A 2 "Suspense"
```

**Expected:**
```tsx
<Suspense fallback={<TasksLoading />}>
  <TasksWithCache projectId={projectId} />
</Suspense>
```

### 5. Test Hybrid Cache + Real-time Flow

**Complete flow test:**
1. **Window 1:** Load project tasks page (cache hit, very fast)
2. **Window 2:** Open same project tasks page (cache hit, very fast)
3. **Window 1:** Create a new task
4. **Expected in Window 2:** Task appears instantly via WebSocket ✅
5. **Window 2:** Refresh page
6. **Expected:** Task still there (cache was invalidated, fresh data loaded) ✅

**This verifies:**
- ✅ Cache is working (fast loads)
- ✅ Real-time is working (instant updates)
- ✅ Cache invalidation is working (fresh data on refresh)

### 6. Test Connection Status

**Browser DevTools:**
1. Open Network tab
2. Filter by "WS" (WebSocket)
3. **Expected:** See active WebSocket connection to Supabase ✅
4. Disconnect internet
5. **Expected:** Connection status shows "Disconnected" or "Error" ✅
6. Reconnect internet
7. **Expected:** Connection status shows "Connected" ✅

### 7. Test Presence Tracking

**Two browser windows:**
1. Window 1: Login and go to project page
2. Window 2: Login and go to same project page
3. **Expected:** Each window shows the other user as "Online Now" ✅
4. Close Window 2
5. **Expected:** Window 1 updates to show user is no longer online ✅

### 8. Verify Realtime in Supabase Dashboard

**Supabase Dashboard:**
1. Go to **Database → Replication**
2. **Expected:** `prj_tasks` shows "Realtime: Enabled" ✅
3. Go to **Database → Tables → prj_tasks**
4. Manually insert a task via SQL Editor:
   ```sql
   INSERT INTO prj_tasks (project_id, title, description, status, priority, owner_id)
   VALUES (
     'your-project-id',
     'Test Real-time Task',
     'This should appear instantly',
     'todo',
     'medium',
     'your-user-id'
   );
   ```
5. **Expected:** Task appears in browser instantly ✅

### 9. Test RLS Applies to Realtime

**Security Test:**
1. User A creates a project
2. User B (different user) opens task list for User A's project
3. User A creates a task
4. **Expected:** User B does NOT see the task (RLS blocks it) ✅
5. User A invites User B as member
6. User A creates another task
7. **Expected:** User B sees the new task instantly ✅

---

## Architecture Decisions Explained

### Why Cache Components + Real-time?

**The Hybrid Approach:**

```
Without Cache Components (Traditional):
┌──────────────────────────────────────────┐
│ Every page load → Database query         │
│ Heavy load on database                   │
│ Slower page loads                        │
│ BUT: Always fresh data                   │
└──────────────────────────────────────────┘

With Cache Components ONLY (No Real-time):
┌──────────────────────────────────────────┐
│ First load → Database query + Cache      │
│ Subsequent loads → Cache (very fast)     │
│ Light load on database                   │
│ BUT: Stale data until cache expires      │
└──────────────────────────────────────────┘

Hybrid: Cache Components + Real-time (Best):
┌──────────────────────────────────────────┐
│ First load → Cache (fast)                │
│ Real-time → WebSocket updates (instant)  │
│ Mutations → updateTag + WebSocket        │
│ ✅ Fast loads + Live updates + Fresh data│
└──────────────────────────────────────────┘
```

**Why Very Short Cache for Real-time Data?**
- `cacheLife('seconds')` (5-10s) provides optimal balance
- Still reduces database load significantly
- Doesn't interfere with real-time updates
- Cache invalidation ensures consistency

**Benefits:**
1. ✅ **Performance** - Cached initial loads
2. ✅ **Live Updates** - WebSocket for instant changes
3. ✅ **Consistency** - updateTag invalidates stale caches
4. ✅ **Scalability** - Reduced database queries
5. ✅ **User Experience** - Fast + live = best UX

### Why Cache Tags Instead of revalidatePath?

**Cache Tags** (Cache Components):
```typescript
// Tag data
'use cache'
cacheTag('tasks')
cacheTag('tasks-projectId')

// Invalidate specific caches
updateTag('tasks-projectId') // Only invalidate one project
```

**revalidatePath** (Traditional):
```typescript
// Invalidate entire path
revalidatePath('/dashboard/projects/[id]/tasks') // Invalidates all projects
```

**Advantages of Cache Tags:**
- ✅ **Granular control** - Invalidate specific data, not entire paths
- ✅ **Better performance** - Less invalidation = more cache hits
- ✅ **Flexible** - Multiple tags per cache entry
- ✅ **Composable** - Mix generic and specific tags

### Why PostgreSQL Changes vs. Broadcast?

**PostgreSQL Changes:**
- ✅ Persistent data (tasks, projects, members)
- ✅ Respects RLS policies (security)
- ✅ Guaranteed delivery (if client is online)
- ❌ Slightly higher latency (~100-300ms)

**Broadcast:**
- ✅ Ephemeral data (typing indicators, cursor positions)
- ✅ Ultra-low latency (~50ms)
- ✅ No database writes (performance)
- ❌ No RLS enforcement
- ❌ No guaranteed delivery (if client disconnects, message is lost)

**Rule of Thumb:**
- Use **PostgreSQL Changes** for data that needs to persist
- Use **Broadcast** for temporary UI states

### Why Separate Hooks for Each Feature?

Following **SOLID principles** from Lesson 1:
- `useRealtimeSubscription` - Base connection management (Single Responsibility)
- `useTaskSubscription` - Task-specific logic
- `usePresence` - Presence tracking logic
- `useBroadcast` - Custom event broadcasting

Each hook has one responsibility and can be used independently or composed together.

### Why Client Components for Realtime?

Real-time subscriptions require:
- ✅ Browser APIs (WebSocket)
- ✅ React hooks (`useEffect`, `useState`)
- ✅ Event listeners

Server Components cannot use these features, so realtime functionality must be in Client Components.

**Pattern:**
```tsx
// Server Component - Fetches initial data
async function Page() {
  const tasks = await getTasks(); // Server-side fetch
  return <TaskListRealtime initialTasks={tasks} />; // Pass to Client Component
}

// Client Component - Handles realtime
'use client';
function TaskListRealtime({ initialTasks }) {
  const { tasks } = useTaskSubscription(); // Client-side subscription
  return <TaskList tasks={tasks} />;
}
```

---

## Common Issues & Solutions

### Issue 1: Cache not working / Always fetching from database

**Cause:** Cache Components not properly configured

**Solutions:**
```bash
# 1. Verify next.config.js has experimental flags
cat next.config.js | grep -A 3 "experimental"

# Should see:
# experimental: {
#   cacheComponents: true,
#   dynamicIO: true,
# }

# 2. Check function has 'use cache' directive
cat src/lib/data/tasks-cached.ts | head -20

# Should see:
# 'use cache'
# cacheLife('seconds')
# cacheTag('tasks')

# 3. Restart dev server (required after config changes)
npm run dev
```

### Issue 2: Stale data after mutations

**Cause:** Cache not invalidated after Server Action

**Solution:** Add `updateTag()` to Server Actions:
```tsx
// ❌ Bad: No cache invalidation
export async function createTask(input) {
  await supabase.from('prj_tasks').insert(input);
  // Cache still has old data!
}

// ✅ Good: Invalidate cache
export async function createTask(input) {
  await supabase.from('prj_tasks').insert(input);
  updateTag('tasks'); // Invalidate cache
  updateTag(`tasks-${input.project_id}`);
}
```

### Issue 3: Real-time updates not showing

**Cause:** Multiple possible causes

**Solutions:**
```bash
# 1. Check Realtime is enabled in Supabase
# Go to Database → Replication → Enable prj_tasks

# 2. Check RLS policies allow SELECT
# User must have SELECT permission to receive updates

# 3. Check WebSocket connection
# DevTools → Network → WS → Should see active connection

# 4. Check filter is correct
# filter: projectId ? `project_id=eq.${projectId}` : undefined

# 5. Check cache isn't interfering
# Use very short cacheLife('seconds') for real-time data
```

### Issue 4: "Channel not subscribed"

**Cause:** Trying to use channel before subscription completes

**Solution:** Check `connectionState.status` before using channel:
```tsx
if (connectionState.status !== CONNECTION_STATUS.CONNECTED) {
  return <div>Connecting...</div>;
}
```

### Issue 5: Duplicate events

**Cause:** Multiple subscriptions to same channel

**Solution:** Ensure cleanup in `useEffect`:
```tsx
useEffect(() => {
  const channel = supabase.channel('my-channel');
  // ... setup
  return () => {
    supabase.removeChannel(channel); // Cleanup!
  };
}, []);
```

### Issue 6: Not receiving events

**Checklist:**
1. ✅ Realtime enabled in Supabase Dashboard (Database → Replication)
2. ✅ RLS policies allow SELECT on the table
3. ✅ Correct filter applied (`project_id=eq.123`)
4. ✅ WebSocket connection active (check DevTools → Network → WS)

### Issue 7: Presence state not updating

**Cause:** Stale presence data after disconnect

**Solution:** Set `PRESENCE_TIMEOUT` and clean up stale users:
```tsx
const cleanupStaleUsers = () => {
  const now = Date.now();
  const timeout = REALTIME_UI.PRESENCE_TIMEOUT;

  setOnlineUsers((prev) =>
    prev.filter((user) => {
      const lastSeen = new Date(user.lastSeen).getTime();
      return now - lastSeen < timeout;
    })
  );
};
```

---

## Performance Considerations

### 1. Channel Limits

**Supabase Limits (Free Tier):**
- Max 2 concurrent connections per client
- Max 100 messages per second

**Optimization:**
- Reuse channels when possible (don't create multiple channels for same data)
- Debounce broadcast events (typing indicators, cursor movements)

### 2. Memory Management

**Problem:** Subscriptions can cause memory leaks

**Solution:** Always cleanup in `useEffect`:
```tsx
useEffect(() => {
  const channel = supabase.channel('tasks');
  channel.subscribe();

  return () => {
    supabase.removeChannel(channel); // Critical!
  };
}, []);
```

### 3. Payload Size

**Problem:** Large payloads slow down realtime

**Solution:**
- Don't send entire objects in broadcast
- Send only IDs, then fetch full data if needed
- Example:
  ```tsx
  // ❌ Bad: Send entire task
  broadcast('task:updated', task);

  // ✅ Good: Send only ID
  broadcast('task:updated', { taskId: task.id });
  ```

---

## Security Best Practices

### 1. RLS Applies to Realtime

**Important:** Users only receive events for rows they have SELECT permission on.

**Example:**
```sql
-- This RLS policy...
CREATE POLICY "Users can view own tasks"
  ON prj_tasks FOR SELECT
  USING (owner_id = auth.uid());

-- ...means users only receive real-time events for their own tasks ✅
```

### 2. Validate Broadcast Data

**Problem:** Broadcast doesn't respect RLS (no database involved)

**Solution:** Validate data on client side:
```tsx
onEvent: (payload) => {
  // Validate sender is authorized
  if (!authorizedUsers.includes(payload.userId)) {
    console.warn('Unauthorized broadcast event');
    return;
  }

  // Process event
  handleEvent(payload);
}
```

### 3. Don't Send Sensitive Data via Broadcast

**Rule:** Never broadcast passwords, API keys, or PII (Personally Identifiable Information)

**Why:** Broadcast is ephemeral and doesn't have RLS protection.

---

## What You Learned

✅ **Next.js 16 Cache Components** - 'use cache', cacheLife(), cacheTag()
✅ **Hybrid Caching Strategy** - Cache Components + Real-time for optimal performance
✅ **Cache Invalidation** - updateTag() for granular cache control
✅ **Very Short Cache Durations** - cacheLife('seconds') for real-time data
✅ **Suspense Boundaries** - Progressive loading with cached data
✅ **Supabase Realtime Architecture** - PostgreSQL Changes, Broadcast, Presence
✅ **React Hooks for Subscriptions** - Custom hooks with automatic cleanup
✅ **Real-time Task Updates** - Live CRUD operations across clients
✅ **Presence Tracking** - Who's online and their state
✅ **Broadcast Events** - Ephemeral messaging (typing indicators)
✅ **Connection State Management** - Handle connect/disconnect gracefully
✅ **Security** - RLS applies to realtime, validate broadcast data
✅ **Performance** - Cache + WebSocket = reduced load + instant updates
✅ **SOLID Principles** - Single Responsibility hooks
✅ **Type Safety** - TypeScript types for all realtime features
✅ **Architecture Patterns** - Server Components (cache) + Client Components (real-time)

---

## Next Steps

**Lesson 8 Preview:** File Uploads with Supabase Storage
- Upload project attachments (images, documents)
- Store files in Supabase Storage buckets
- Generate signed URLs for secure downloads
- Display image previews
- File validation (size, type)
- Progress indicators for uploads

**Continue to:** `LESSON-8-PRACTICAL-GUIDE.md`

---

## Reference

**Files Created/Updated:**

**Cache & Data Layer:**
- `next.config.js` - Enable Cache Components (UPDATED)
- `src/lib/data/tasks-cached.ts` - Cached data fetchers with 'use cache' (NEW)
- `src/lib/actions/tasks-with-cache-invalidation.ts` - Server Actions with updateTag() (NEW)

**Realtime Hooks:**
- `src/hooks/realtime/useRealtimeSubscription.ts` - Base subscription hook
- `src/hooks/realtime/useTaskSubscription.ts` - Task subscription hook
- `src/hooks/realtime/usePresence.ts` - Presence tracking hook
- `src/hooks/realtime/useBroadcast.ts` - Broadcast events hook
- `src/hooks/realtime/index.ts` - Hook exports

**Components:**
- `src/components/features/realtime/ConnectionStatus.tsx` - Connection UI
- `src/components/features/realtime/OnlineUsers.tsx` - Online users list
- `src/components/features/realtime/TypingIndicator.tsx` - Typing indicators
- `src/components/features/tasks/TaskListRealtime.tsx` - Real-time task list with cache integration (UPDATED)

**Pages:**
- `src/app/dashboard/projects/[id]/tasks/page.tsx` - Real-time tasks page with Cache Components & Suspense (UPDATED)

**Styles & Types:**
- `src/constants/index.ts` - Realtime constants (EXTENDED)
- `src/types/realtime.ts` - TypeScript types for realtime
- `src/app/globals.css` - Animation styles (EXTENDED)

**Key Concepts:**

**Cache Components (Next.js 16):**
- 'use cache' directive
- cacheLife() - Duration control
- cacheTag() - Granular invalidation
- updateTag() - Cache invalidation
- Very short durations for real-time data

**Realtime:**
- WebSocket connections
- PostgreSQL replication (WAL)
- Ephemeral messaging
- Presence state synchronization
- Channel subscriptions
- Event broadcasting
- Connection lifecycle management

**Hybrid Architecture:**
- Server Components with Cache Components for initial data
- Client Components with WebSocket for live updates
- Suspense boundaries for progressive loading
- Cache invalidation on mutations
- Short cache durations for frequently changing data

**Technologies:**
- Next.js 16 (Cache Components, dynamicIO, Suspense)
- Supabase Realtime
- WebSockets
- PostgreSQL WAL (Write-Ahead Log)
- React 19.2 hooks
- TypeScript

**Documentation:**
- **Next.js 16 Cache Components:** https://nextjs.org/docs/canary/app/api-reference/directives/use-cache
- **Supabase Realtime:** https://supabase.com/docs/guides/realtime
- **Next.js Suspense:** https://nextjs.org/docs/app/building-your-application/routing/loading-ui-and-streaming
