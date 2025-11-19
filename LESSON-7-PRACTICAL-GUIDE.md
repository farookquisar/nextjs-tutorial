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
- **Next.js 16** - Client Components for real-time features

---

## Architecture Overview

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

## Step 2: Extend Constants (Lesson 1 Pattern)

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

## Step 4: Create useRealtimeSubscription Hook

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

## Step 5: Create useTaskSubscription Hook

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

## Step 6: Create usePresence Hook

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

## Step 7: Create useBroadcast Hook

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

## Step 8: Create Connection Status Component

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

## Step 9: Create Online Users Component

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

## Step 10: Create Real-time Task List Component

Update the task list to use real-time subscriptions:

```bash
cat > src/components/features/tasks/TaskListRealtime.tsx << 'EOF'
'use client';

import { useEffect, useState } from 'react';
import { useTaskSubscription } from '@/hooks/realtime/useTaskSubscription';
import { getTasks } from '@/lib/actions/tasks';
import { ConnectionStatus } from '@/components/features/realtime/ConnectionStatus';
import { TaskCard } from './TaskCard';
import type { Database } from '@/lib/types/database';

type Task = Database['public']['Tables']['prj_tasks']['Row'];

type TaskListRealtimeProps = {
  projectId: string;
  initialTasks: Task[];
};

/**
 * Task list with real-time updates
 * Shows live task changes from other team members
 */
export function TaskListRealtime({ projectId, initialTasks }: TaskListRealtimeProps) {
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

  // Refresh tasks from server on mount
  useEffect(() => {
    const refreshTasks = async () => {
      const result = await getTasks({ projectId });
      if (result.success && result.data) {
        setTasks(result.data);
      }
    };
    refreshTasks();
  }, [projectId]);

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
- ✅ Real-time task updates (create, update, delete)
- ✅ Connection status indicator
- ✅ Toast notifications for changes
- ✅ Optimistic UI updates
- ✅ Server data refresh on mount

---

## Step 11: Create Real-time Project Page

Update the project tasks page to use real-time components:

```bash
cat > src/app/dashboard/projects/[id]/tasks/page-realtime.tsx << 'EOF'
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getTasks } from '@/lib/actions/tasks';
import { getProject } from '@/lib/actions/projects';
import { TaskListRealtime } from '@/components/features/tasks/TaskListRealtime';
import { OnlineUsers } from '@/components/features/realtime/OnlineUsers';
import { ROUTES } from '@/constants';
import Link from 'next/link';

type ProjectTasksPageProps = {
  params: Promise<{ id: string }>;
};

/**
 * Project tasks page with real-time updates
 * Server Component that fetches initial data, then Client Component handles real-time
 */
export default async function ProjectTasksPage({ params }: ProjectTasksPageProps) {
  const { id: projectId } = await params;

  // Auth check
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect(ROUTES.LOGIN);

  // Fetch initial data
  const [projectResult, tasksResult] = await Promise.all([
    getProject(projectId),
    getTasks({ projectId }),
  ]);

  if (!projectResult.success || !projectResult.data) {
    redirect(ROUTES.DASHBOARD_PROJECTS);
  }

  const project = projectResult.data;
  const initialTasks = tasksResult.success ? tasksResult.data || [] : [];

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

      {/* Real-time Task List */}
      <TaskListRealtime projectId={projectId} initialTasks={initialTasks} />
    </div>
  );
}

EOF
```

**Architecture:**
- ✅ **Server Component** - Fetches initial data with auth check
- ✅ **Client Component** - Handles real-time subscriptions (TaskListRealtime)
- ✅ **Presence Tracking** - Shows online users viewing this project
- ✅ **Optimistic UI** - Instant updates before server confirmation

---

## Step 12: Add Realtime to Main Tasks Page

To use the real-time version, update your existing tasks page:

```bash
# Backup original page
cp src/app/dashboard/projects/[id]/tasks/page.tsx src/app/dashboard/projects/[id]/tasks/page.backup.tsx

# Replace with real-time version
cp src/app/dashboard/projects/[id]/tasks/page-realtime.tsx src/app/dashboard/projects/[id]/tasks/page.tsx
```

Or manually update `src/app/dashboard/projects/[id]/tasks/page.tsx` to import and use `TaskListRealtime` instead of static `TaskList`.

---

## Step 13: Add Typing Indicator Example

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

## Step 14: Add CSS Animations

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

## Step 15: Export Realtime Hooks

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

### 1. Test Real-time Task Updates

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

### 2. Test Connection Status

**Browser DevTools:**
1. Open Network tab
2. Filter by "WS" (WebSocket)
3. **Expected:** See active WebSocket connection to Supabase ✅
4. Disconnect internet
5. **Expected:** Connection status shows "Disconnected" or "Error" ✅
6. Reconnect internet
7. **Expected:** Connection status shows "Connected" ✅

### 3. Test Presence Tracking

**Two browser windows:**
1. Window 1: Login and go to project page
2. Window 2: Login and go to same project page
3. **Expected:** Each window shows the other user as "Online Now" ✅
4. Close Window 2
5. **Expected:** Window 1 updates to show user is no longer online ✅

### 4. Verify Realtime in Supabase Dashboard

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

### 5. Test RLS Applies to Realtime

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

### Issue 1: "Channel not subscribed"

**Cause:** Trying to use channel before subscription completes

**Solution:** Check `connectionState.status` before using channel:
```tsx
if (connectionState.status !== CONNECTION_STATUS.CONNECTED) {
  return <div>Connecting...</div>;
}
```

### Issue 2: Duplicate events

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

### Issue 3: Not receiving events

**Checklist:**
1. ✅ Realtime enabled in Supabase Dashboard (Database → Replication)
2. ✅ RLS policies allow SELECT on the table
3. ✅ Correct filter applied (`project_id=eq.123`)
4. ✅ WebSocket connection active (check DevTools → Network → WS)

### Issue 4: Presence state not updating

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

✅ **Supabase Realtime Architecture** - PostgreSQL Changes, Broadcast, Presence
✅ **React Hooks for Subscriptions** - Custom hooks with automatic cleanup
✅ **Real-time Task Updates** - Live CRUD operations across clients
✅ **Presence Tracking** - Who's online and their state
✅ **Broadcast Events** - Ephemeral messaging (typing indicators)
✅ **Connection State Management** - Handle connect/disconnect gracefully
✅ **Security** - RLS applies to realtime, validate broadcast data
✅ **Performance** - Channel limits, memory management, payload optimization
✅ **SOLID Principles** - Single Responsibility hooks
✅ **Type Safety** - TypeScript types for all realtime features

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

**Files Created:**
- `src/constants/index.ts` - Realtime constants (EXTENDED)
- `src/types/realtime.ts` - TypeScript types for realtime
- `src/hooks/realtime/useRealtimeSubscription.ts` - Base subscription hook
- `src/hooks/realtime/useTaskSubscription.ts` - Task subscription hook
- `src/hooks/realtime/usePresence.ts` - Presence tracking hook
- `src/hooks/realtime/useBroadcast.ts` - Broadcast events hook
- `src/components/features/realtime/ConnectionStatus.tsx` - Connection UI
- `src/components/features/realtime/OnlineUsers.tsx` - Online users list
- `src/components/features/realtime/TypingIndicator.tsx` - Typing indicators
- `src/components/features/tasks/TaskListRealtime.tsx` - Real-time task list
- `src/app/dashboard/projects/[id]/tasks/page.tsx` - Real-time tasks page (UPDATED)
- `src/app/globals.css` - Animation styles (EXTENDED)

**Key Concepts:**
- WebSocket connections
- PostgreSQL replication (WAL)
- Ephemeral messaging
- Presence state synchronization
- Channel subscriptions
- Event broadcasting
- Connection lifecycle management

**Technologies:**
- Supabase Realtime
- WebSockets
- PostgreSQL WAL (Write-Ahead Log)
- React hooks
- TypeScript
- Next.js 16

**Supabase Realtime Docs:** https://supabase.com/docs/guides/realtime
