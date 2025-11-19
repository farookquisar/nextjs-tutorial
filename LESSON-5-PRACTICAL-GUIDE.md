# Module 1, Lesson 5 — Task Management with Best Practices

**Prerequisites:** Complete Lesson 1 (Next.js Setup), Lesson 2 (Supabase Setup), Lesson 3 (Authentication), and Lesson 4 (Project CRUD)

---

## 📖 1. DESC

### What You'll Build

In this lesson, you'll implement **Task Management** for projects using the **prj_tasks** table created in Lesson 2, while introducing **production-grade best practices**:

✅ **Constants Extension** - Add task constants to `constants.ts` (from Lesson 1)
✅ **Next.js 16 Cache Components** - Use `use cache` directive for performance
✅ **React 19.2 useEffectEvent** - Avoid stale closures in effects
✅ **Task CRUD Operations** - Create, read, update, delete tasks
✅ **RPC Functions** - Complex task queries and statistics
✅ **SOLID Principles** - Single Responsibility, DRY code
✅ **Type-safe Everything** - Zero magic values, full TypeScript

**What is Task Management?**
- Link tasks to projects (foreign key relationship)
- Assign priorities (Low, Medium, High, Urgent)
- Track status (Todo, In Progress, Done, Blocked)
- Set due dates with overdue detection
- Get task statistics per project

### Building On Previous Lessons

**Lesson 1:** Next.js 16 setup with TypeScript
**Lesson 2:** Database schema with `prj_projects`, `prj_tasks` tables
**Lesson 3:** Authentication with protected routes and UI components
**Lesson 4:** Project CRUD operations with Server Actions and Zod validation
**Lesson 5 (THIS LESSON):** Task management with best practices and Next.js 16 features

### What You'll Implement

✅ **Constants Extension** - Extend `src/lib/constants.ts` (from Lesson 1) with task constants
✅ **Cache Components** - Next.js 16 `use cache` for task lists
✅ **useEffectEvent** - React 19.2 hook for non-reactive effect logic
✅ **Task CRUD** - Full task management with validation
✅ **RPC Functions** - `get_tasks_by_project()`, `get_task_stats()`
✅ **Task Filtering** - By status, priority, overdue, project
✅ **Reusable Components** - TaskCard, TaskList, TaskForm, TaskStats
✅ **SOLID Architecture** - Single-purpose functions and components

```
📁 Your App Structure (After This Lesson)
├── src/
│   ├── lib/
│   │   ├── constants.ts                  ← UPDATE: Add task constants (created in Lesson 1)
│   │   ├── actions/
│   │   │   └── tasks.ts                  ← NEW: Task CRUD Server Actions
│   │   ├── validations/
│   │   │   └── task.ts                   ← NEW: Zod task schemas
│   │   └── types/
│   │       └── database.ts               ← UPDATE: Add task types
│   ├── app/
│   │   ├── dashboard/
│   │   │   └── projects/[id]/
│   │   │       ├── tasks/
│   │   │       │   ├── page.tsx          ← NEW: Tasks list (uses cache)
│   │   │       │   ├── new/
│   │   │       │   │   └── page.tsx      ← NEW: Create task
│   │   │       │   └── [taskId]/
│   │   │       │       ├── page.tsx      ← NEW: View task
│   │   │       │       └── edit/
│   │   │       │           └── page.tsx  ← NEW: Edit task
│   │   └── next.config.ts                ← UPDATE: Enable cacheComponents
│   ├── components/
│   │   └── features/tasks/
│   │       ├── TaskList.tsx              ← NEW: Tasks list component
│   │       ├── TaskCard.tsx              ← NEW: Task card component
│   │       ├── TaskForm.tsx              ← NEW: Create/Edit form
│   │       ├── TaskStats.tsx             ← NEW: Task statistics
│   │       └── TaskFilters.tsx           ← NEW: Filter tasks
│   └── hooks/
│       └── useTaskTimer.ts               ← NEW: Demo useEffectEvent
├── supabase/migrations/
│   └── 003_task_rls_and_rpc.sql          ← NEW: RLS + RPC functions
└── next.config.ts                         ← UPDATE: Enable cache components
```

### Why This Approach?

✅ **Maintainable** - Constants file makes updates easy, no hunt for hardcoded values
✅ **Performant** - Cache components reduce database queries dramatically
✅ **Clean Code** - SOLID principles, DRY, single responsibility
✅ **Type-safe** - TypeScript + Zod + database types = zero runtime errors
✅ **Future-proof** - Next.js 16 and React 19.2 latest features
✅ **Scalable** - RPC functions handle complex queries efficiently

---

## 🎯 2. STEPS

### 🎯 STEP 1 — Extend Constants File (from Lesson 1)

**In Lesson 1, we created `src/lib/constants.ts` for all static values.**

Now we'll **extend it** with task-specific constants (status, priority, labels, colors).

**Why constants?**
- ❌ **Bad:** `if (status === 'done')` - What if you typo "dne"?
- ✅ **Good:** `if (status === TASK_STATUS.DONE)` - TypeScript autocomplete + compile-time safety

**Update the constants file (add task constants to existing file):**

```bash
# Backup existing constants (optional)
cp src/lib/constants.ts src/lib/constants.ts.backup

# Extend with task constants
cat > src/lib/constants.ts << 'EOF'
// ============================================
// CONSTANTS - ALL STATIC VALUES IN ONE PLACE
// No magic strings or numbers allowed!
// ============================================

// ============================================
// TASK CONSTANTS
// ============================================

export const TASK_STATUS = {
  TODO: 'todo',
  IN_PROGRESS: 'in_progress',
  DONE: 'done',
  BLOCKED: 'blocked',
} as const;

export const TASK_PRIORITY = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  URGENT: 'urgent',
} as const;

// Labels for display in UI
export const TASK_STATUS_LABELS: Record<TaskStatus, string> = {
  [TASK_STATUS.TODO]: 'To Do',
  [TASK_STATUS.IN_PROGRESS]: 'In Progress',
  [TASK_STATUS.DONE]: 'Done',
  [TASK_STATUS.BLOCKED]: 'Blocked',
};

export const TASK_PRIORITY_LABELS: Record<TaskPriority, string> = {
  [TASK_PRIORITY.LOW]: 'Low',
  [TASK_PRIORITY.MEDIUM]: 'Medium',
  [TASK_PRIORITY.HIGH]: 'High',
  [TASK_PRIORITY.URGENT]: 'Urgent',
};

// CSS classes for task status badges
export const TASK_STATUS_COLORS: Record<TaskStatus, string> = {
  [TASK_STATUS.TODO]: 'bg-gray-100 text-gray-800',
  [TASK_STATUS.IN_PROGRESS]: 'bg-blue-100 text-blue-800',
  [TASK_STATUS.DONE]: 'bg-green-100 text-green-800',
  [TASK_STATUS.BLOCKED]: 'bg-red-100 text-red-800',
};

// CSS classes for task priority badges
export const TASK_PRIORITY_COLORS: Record<TaskPriority, string> = {
  [TASK_PRIORITY.LOW]: 'bg-slate-100 text-slate-800',
  [TASK_PRIORITY.MEDIUM]: 'bg-yellow-100 text-yellow-800',
  [TASK_PRIORITY.HIGH]: 'bg-orange-100 text-orange-800',
  [TASK_PRIORITY.URGENT]: 'bg-red-100 text-red-800',
};

// ============================================
// PROJECT CONSTANTS
// ============================================

export const PROJECT_STATUS = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  COMPLETED: 'completed',
  ON_HOLD: 'on_hold',
} as const;

// ============================================
// ROUTES
// ============================================

export const ROUTES = {
  HOME: '/',
  LOGIN: '/login',
  SIGNUP: '/signup',
  DASHBOARD: '/dashboard',
  PROJECTS: '/dashboard/projects',
  PROJECT_NEW: '/dashboard/projects/new',
  PROJECT_VIEW: (id: string) => `/dashboard/projects/${id}`,
  PROJECT_EDIT: (id: string) => `/dashboard/projects/${id}/edit`,
  PROJECT_TASKS: (projectId: string) => `/dashboard/projects/${projectId}/tasks`,
  TASK_NEW: (projectId: string) => `/dashboard/projects/${projectId}/tasks/new`,
  TASK_VIEW: (projectId: string, taskId: string) => `/dashboard/projects/${projectId}/tasks/${taskId}`,
  TASK_EDIT: (projectId: string, taskId: string) => `/dashboard/projects/${projectId}/tasks/${taskId}/edit`,
} as const;

// ============================================
// DATABASE TABLE NAMES
// ============================================

export const TABLES = {
  PROJECTS: 'prj_projects',
  TASKS: 'prj_tasks',
  PROJECT_MEMBERS: 'prj_project_members',
  PROJECT_PAYMENTS: 'prj_project_payments',
  PROJECT_TERMS: 'prj_project_terms',
} as const;

// ============================================
// CACHE CONFIGURATION (Next.js 16)
// ============================================

export const CACHE_TAGS = {
  PROJECTS: 'projects',
  TASKS: 'tasks',
  PROJECT_STATS: 'project-stats',
  TASK_STATS: 'task-stats',
} as const;

// Cache durations in seconds
export const CACHE_DURATION = {
  SHORT: 60,        // 1 minute
  MEDIUM: 300,      // 5 minutes
  LONG: 3600,       // 1 hour
  DAY: 86400,       // 24 hours
} as const;

// ============================================
// ERROR MESSAGES
// ============================================

export const ERROR_MESSAGES = {
  AUTH: {
    UNAUTHORIZED: 'You must be logged in to perform this action',
    INVALID_CREDENTIALS: 'Invalid email or password',
    EMAIL_ALREADY_EXISTS: 'An account with this email already exists',
    WEAK_PASSWORD: 'Password must be at least 8 characters',
  },
  TASK: {
    NOT_FOUND: 'Task not found',
    CREATE_FAILED: 'Failed to create task',
    UPDATE_FAILED: 'Failed to update task',
    DELETE_FAILED: 'Failed to delete task',
    INVALID_STATUS: 'Invalid task status',
    INVALID_PRIORITY: 'Invalid task priority',
    DUE_DATE_PAST: 'Due date cannot be in the past',
  },
  PROJECT: {
    NOT_FOUND: 'Project not found',
    CREATE_FAILED: 'Failed to create project',
    UPDATE_FAILED: 'Failed to update project',
    DELETE_FAILED: 'Failed to delete project',
    END_BEFORE_START: 'End date must be after start date',
  },
  GENERIC: {
    SOMETHING_WENT_WRONG: 'Something went wrong. Please try again.',
    NETWORK_ERROR: 'Network error. Please check your connection.',
    VALIDATION_FAILED: 'Validation failed. Please check your inputs.',
  },
} as const;

// ============================================
// SUCCESS MESSAGES
// ============================================

export const SUCCESS_MESSAGES = {
  TASK: {
    CREATED: 'Task created successfully',
    UPDATED: 'Task updated successfully',
    DELETED: 'Task deleted successfully',
    STATUS_CHANGED: 'Task status updated',
  },
  PROJECT: {
    CREATED: 'Project created successfully',
    UPDATED: 'Project updated successfully',
    DELETED: 'Project deleted successfully',
    STATUS_TOGGLED: 'Project status toggled',
  },
  AUTH: {
    SIGNED_IN: 'Signed in successfully',
    SIGNED_UP: 'Account created successfully',
    SIGNED_OUT: 'Signed out successfully',
  },
} as const;

// ============================================
// UI LABELS
// ============================================

export const UI_LABELS = {
  BUTTONS: {
    SAVE: 'Save',
    CANCEL: 'Cancel',
    DELETE: 'Delete',
    EDIT: 'Edit',
    CREATE: 'Create',
    SUBMIT: 'Submit',
    BACK: 'Back',
    SIGN_IN: 'Sign In',
    SIGN_UP: 'Sign Up',
    SIGN_OUT: 'Sign Out',
  },
  PLACEHOLDERS: {
    TASK_TITLE: 'Enter task title...',
    TASK_DESCRIPTION: 'Enter task description...',
    PROJECT_NAME: 'Enter project name...',
    EMAIL: 'you@example.com',
    PASSWORD: '••••••••',
  },
  FORM_FIELDS: {
    TITLE: 'Title',
    DESCRIPTION: 'Description',
    STATUS: 'Status',
    PRIORITY: 'Priority',
    DUE_DATE: 'Due Date',
    PROJECT: 'Project',
  },
} as const;

// ============================================
// PAGINATION
// ============================================

export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 10,
  PAGE_SIZE_OPTIONS: [10, 25, 50, 100],
  MAX_PAGE_SIZE: 100,
} as const;

// ============================================
// VALIDATION LIMITS
// ============================================

export const VALIDATION = {
  TASK: {
    TITLE_MIN_LENGTH: 1,
    TITLE_MAX_LENGTH: 200,
    DESCRIPTION_MAX_LENGTH: 2000,
  },
  PROJECT: {
    NAME_MIN_LENGTH: 1,
    NAME_MAX_LENGTH: 100,
    DESCRIPTION_MAX_LENGTH: 1000,
  },
  PASSWORD: {
    MIN_LENGTH: 8,
    MAX_LENGTH: 128,
  },
} as const;

// ============================================
// TYPE EXPORTS (for TypeScript inference)
// ============================================

export type TaskStatus = typeof TASK_STATUS[keyof typeof TASK_STATUS];
export type TaskPriority = typeof TASK_PRIORITY[keyof typeof TASK_PRIORITY];
export type ProjectStatus = typeof PROJECT_STATUS[keyof typeof PROJECT_STATUS];
EOF

# Verify
cat src/lib/constants.ts
```

**Verify the file was created:**

```bash
# File should exist and contain all constants
ls -lh src/lib/constants.ts

# Check it compiles
npx tsc --noEmit src/lib/constants.ts
```

<details>
<summary>📖 <strong>Why Constants Are Critical for Production Apps</strong></summary>

### The Problem with Magic Strings

**Bad code (magic strings):**
```typescript
// ❌ Typo creates a bug - no compile error!
if (task.status === 'dne') { ... }

// ❌ What values are allowed? Unknown!
const status = 'completed'; // Is this valid?

// ❌ Change status name = find/replace nightmare
// If you change 'done' to 'completed', search entire codebase
```

**Good code (constants):**
```typescript
// ✅ TypeScript autocomplete shows all options
if (task.status === TASK_STATUS.DONE) { ... }

// ✅ Typo = compile error immediately
if (task.status === TASK_STATUS.DNE) { // Error: Property 'DNE' does not exist

// ✅ Change name = change one constant
export const TASK_STATUS = {
  DONE: 'completed', // Change here, updates everywhere
} as const;
```

### Benefits

1. **Type Safety** - Autocomplete and compile-time checks
2. **Single Source of Truth** - Change once, update everywhere
3. **Documentation** - See all valid values in one place
4. **Refactoring** - Rename safely with IDE
5. **No Typos** - Compiler catches mistakes

### SOLID Principles Applied

- **Single Responsibility Principle (SRP)** - Constants file has one job: define static values
- **DRY (Don't Repeat Yourself)** - No duplicated strings across files

</details>

---

### 🎯 STEP 2 — Enable Next.js 16 Cache Components

Next.js 16 introduces **Cache Components** with the `use cache` directive for lightning-fast performance.

**Update next.config.ts to enable cache components:**

```bash
cat > next.config.ts << 'EOF'
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // ============================================
  // NEXT.JS 16 CACHE COMPONENTS
  // ============================================
  experimental: {
    // Enable cache components (PPR + use cache)
    cacheComponents: true,
  },

  // Existing config...
};

export default nextConfig;
EOF

# Verify
cat next.config.ts
```

**Verify:**

```bash
# Check the config file
cat next.config.ts | grep -A 2 "cacheComponents"
```

<details>
<summary>📖 <strong>Understanding Next.js 16 Cache Components</strong></summary>

### What Are Cache Components?

Cache Components in Next.js 16 allow you to cache:
- Entire Server Components
- Server Action results
- Async function results

Using the `use cache` directive at the top of functions or components.

### How It Works

```typescript
// ✅ Cache this Server Component
'use cache';

export default async function TaskList({ projectId }: Props) {
  const tasks = await getTasks(projectId);
  return <div>{/* ... */}</div>;
}
```

```typescript
// ✅ Cache this async function
'use cache';

export async function getTasks(projectId: string) {
  // This result is cached
  const { data } = await supabase.from('prj_tasks').select('*');
  return data;
}
```

### Benefits

- **Faster Page Loads** - Cached data served instantly
- **Reduced Database Queries** - Cache hits don't query database
- **Automatic Revalidation** - Use `cacheTag` to invalidate on mutations
- **Better UX** - Instant navigation with cached data

### PPR (Partial Prerendering)

Cache Components enable PPR, which combines:
- **Static content** - Cached and served fast
- **Dynamic content** - Streamed with Suspense

```tsx
<Suspense fallback={<TaskSkeleton />}>
  <CachedTaskList projectId={id} />
</Suspense>
```

Static shell loads instantly, dynamic content streams in.

</details>

---

### 🎯 STEP 3 — Add RLS Policies and RPC Functions for Tasks

The `prj_tasks` table was created in Lesson 2, but we need Row Level Security and RPC functions.

**Create migration file:**

```bash
mkdir -p supabase/migrations

cat > supabase/migrations/003_task_rls_and_rpc.sql << 'EOF'
-- ============================================
-- LESSON 5: TASK RLS POLICIES AND RPC FUNCTIONS
-- ============================================

-- ============================================
-- ROW LEVEL SECURITY FOR TASKS
-- ============================================

-- Enable RLS on prj_tasks
ALTER TABLE prj_tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view tasks for their own projects
CREATE POLICY "Users can view tasks for own projects"
  ON prj_tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM prj_projects
      WHERE prj_projects.id = prj_tasks.project_id
      AND prj_projects.owner_id = auth.uid()
    )
  );

-- Policy: Users can create tasks for their own projects
CREATE POLICY "Users can create tasks for own projects"
  ON prj_tasks
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM prj_projects
      WHERE prj_projects.id = prj_tasks.project_id
      AND prj_projects.owner_id = auth.uid()
    )
  );

-- Policy: Users can update tasks for their own projects
CREATE POLICY "Users can update tasks for own projects"
  ON prj_tasks
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM prj_projects
      WHERE prj_projects.id = prj_tasks.project_id
      AND prj_projects.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM prj_projects
      WHERE prj_projects.id = prj_tasks.project_id
      AND prj_projects.owner_id = auth.uid()
    )
  );

-- Policy: Users can delete tasks for their own projects
CREATE POLICY "Users can delete tasks for own projects"
  ON prj_tasks
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM prj_projects
      WHERE prj_projects.id = prj_tasks.project_id
      AND prj_projects.owner_id = auth.uid()
    )
  );

-- Create index for faster task queries
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON prj_tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON prj_tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON prj_tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON prj_tasks(due_date);

-- ============================================
-- RPC FUNCTION: GET TASKS BY PROJECT
-- ============================================

CREATE OR REPLACE FUNCTION get_tasks_by_project(
  p_project_id UUID,
  p_status TEXT DEFAULT NULL,
  p_priority TEXT DEFAULT NULL,
  p_overdue_only BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id UUID,
  title VARCHAR(200),
  description TEXT,
  status VARCHAR(50),
  priority VARCHAR(50),
  due_date DATE,
  project_id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  is_overdue BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.project_id,
    t.created_at,
    t.updated_at,
    -- Check if task is overdue
    (t.due_date < CURRENT_DATE AND t.status != 'done') AS is_overdue
  FROM prj_tasks t
  INNER JOIN prj_projects p ON t.project_id = p.id
  WHERE
    t.project_id = p_project_id
    AND p.owner_id = auth.uid()
    AND (p_status IS NULL OR t.status = p_status)
    AND (p_priority IS NULL OR t.priority = p_priority)
    AND (
      p_overdue_only = FALSE
      OR (t.due_date < CURRENT_DATE AND t.status != 'done')
    )
  ORDER BY
    -- Sort: Urgent first, then by due date
    CASE t.priority
      WHEN 'urgent' THEN 1
      WHEN 'high' THEN 2
      WHEN 'medium' THEN 3
      WHEN 'low' THEN 4
    END,
    t.due_date ASC NULLS LAST,
    t.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RPC FUNCTION: GET TASK STATISTICS
-- ============================================

CREATE OR REPLACE FUNCTION get_task_stats(p_project_id UUID)
RETURNS TABLE (
  total_tasks BIGINT,
  todo_count BIGINT,
  in_progress_count BIGINT,
  done_count BIGINT,
  blocked_count BIGINT,
  overdue_count BIGINT,
  completion_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_tasks,
    COUNT(*) FILTER (WHERE status = 'todo')::BIGINT AS todo_count,
    COUNT(*) FILTER (WHERE status = 'in_progress')::BIGINT AS in_progress_count,
    COUNT(*) FILTER (WHERE status = 'done')::BIGINT AS done_count,
    COUNT(*) FILTER (WHERE status = 'blocked')::BIGINT AS blocked_count,
    COUNT(*) FILTER (WHERE due_date < CURRENT_DATE AND status != 'done')::BIGINT AS overdue_count,
    -- Completion rate: (done / total) * 100
    CASE
      WHEN COUNT(*) > 0 THEN
        ROUND((COUNT(*) FILTER (WHERE status = 'done')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
      ELSE 0
    END AS completion_rate
  FROM prj_tasks t
  INNER JOIN prj_projects p ON t.project_id = p.id
  WHERE
    t.project_id = p_project_id
    AND p.owner_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
EOF

# Verify file created
cat supabase/migrations/003_task_rls_and_rpc.sql
```

**Run the migration in Supabase:**

1. Go to Supabase Dashboard → SQL Editor
2. Copy the contents of `supabase/migrations/003_task_rls_and_rpc.sql`
3. Paste and click "Run"

**Verify RLS policies:**

```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'prj_tasks';

-- Check policies exist
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'prj_tasks';

-- Check RPC functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_name IN ('get_tasks_by_project', 'get_task_stats');
```

<details>
<summary>📖 <strong>Understanding RPC Functions for Tasks</strong></summary>

### Why RPC Functions?

RPC (Remote Procedure Call) functions run **on the database server**, not your Next.js app.

### Benefits

1. **Performance** - Complex queries execute in database (faster)
2. **Security** - Business logic in database, not exposed to client
3. **Reusability** - One function, multiple callers
4. **Type Safety** - Supabase generates types for RPC functions

### get_tasks_by_project()

This function:
- Filters tasks by project ID
- Optionally filters by status, priority, overdue
- Calculates `is_overdue` flag
- Sorts by priority and due date
- Enforces RLS (only owner's projects)

### get_task_stats()

This function returns:
- Total tasks
- Count by status (todo, in_progress, done, blocked)
- Overdue count
- Completion rate percentage

Perfect for dashboards and analytics!

</details>

---

### 🎯 STEP 4 — Create Task Types and Validation Schemas

**Update database types:**

```bash
cat > src/lib/types/database.ts << 'EOF'
// ============================================
// DATABASE TYPES
// ============================================

import type { TaskStatus, TaskPriority, ProjectStatus } from '@/lib/constants';

// ============================================
// PROJECT TYPES
// ============================================

export interface Project {
  id: string;
  name: string;
  description: string | null;
  start_date: string | null;
  end_date: string | null;
  is_active: boolean;
  owner_id: string;
  created_at: string;
  updated_at: string;
}

export interface ProjectStats {
  total_projects: number;
  active_projects: number;
  completed_projects: number;
  overdue_projects: number;
  completion_rate: number;
}

// ============================================
// TASK TYPES
// ============================================

export interface Task {
  id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  due_date: string | null;
  project_id: string;
  created_at: string;
  updated_at: string;
}

export interface TaskWithOverdue extends Task {
  is_overdue: boolean;
}

export interface TaskStats {
  total_tasks: number;
  todo_count: number;
  in_progress_count: number;
  done_count: number;
  blocked_count: number;
  overdue_count: number;
  completion_rate: number;
}

// ============================================
// FORM TYPES
// ============================================

export interface CreateTaskInput {
  title: string;
  description?: string;
  status: TaskStatus;
  priority: TaskPriority;
  due_date?: string;
  project_id: string;
}

export interface UpdateTaskInput {
  title?: string;
  description?: string;
  status?: TaskStatus;
  priority?: TaskPriority;
  due_date?: string;
}
EOF

# Verify
cat src/lib/types/database.ts
```

**Create Zod validation schemas for tasks:**

```bash
mkdir -p src/lib/validations

cat > src/lib/validations/task.ts << 'EOF'
// ============================================
// TASK VALIDATION SCHEMAS
// ============================================

import { z } from 'zod';
import {
  TASK_STATUS,
  TASK_PRIORITY,
  ERROR_MESSAGES,
  VALIDATION,
} from '@/lib/constants';

// ============================================
// SCHEMA: CREATE TASK
// ============================================

export const createTaskSchema = z.object({
  title: z
    .string()
    .min(VALIDATION.TASK.TITLE_MIN_LENGTH, {
      message: `Title must be at least ${VALIDATION.TASK.TITLE_MIN_LENGTH} character`,
    })
    .max(VALIDATION.TASK.TITLE_MAX_LENGTH, {
      message: `Title must be at most ${VALIDATION.TASK.TITLE_MAX_LENGTH} characters`,
    })
    .trim(),

  description: z
    .string()
    .max(VALIDATION.TASK.DESCRIPTION_MAX_LENGTH, {
      message: `Description must be at most ${VALIDATION.TASK.DESCRIPTION_MAX_LENGTH} characters`,
    })
    .trim()
    .optional(),

  status: z.enum(
    [TASK_STATUS.TODO, TASK_STATUS.IN_PROGRESS, TASK_STATUS.DONE, TASK_STATUS.BLOCKED],
    { errorMap: () => ({ message: ERROR_MESSAGES.TASK.INVALID_STATUS }) }
  ),

  priority: z.enum(
    [TASK_PRIORITY.LOW, TASK_PRIORITY.MEDIUM, TASK_PRIORITY.HIGH, TASK_PRIORITY.URGENT],
    { errorMap: () => ({ message: ERROR_MESSAGES.TASK.INVALID_PRIORITY }) }
  ),

  due_date: z
    .string()
    .refine(
      (date) => {
        if (!date) return true; // Optional field
        const dueDate = new Date(date);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        return dueDate >= today;
      },
      { message: ERROR_MESSAGES.TASK.DUE_DATE_PAST }
    )
    .optional(),

  project_id: z.string().uuid({ message: 'Invalid project ID' }),
});

// ============================================
// SCHEMA: UPDATE TASK
// ============================================

export const updateTaskSchema = z.object({
  title: z
    .string()
    .min(VALIDATION.TASK.TITLE_MIN_LENGTH)
    .max(VALIDATION.TASK.TITLE_MAX_LENGTH)
    .trim()
    .optional(),

  description: z
    .string()
    .max(VALIDATION.TASK.DESCRIPTION_MAX_LENGTH)
    .trim()
    .optional(),

  status: z
    .enum([TASK_STATUS.TODO, TASK_STATUS.IN_PROGRESS, TASK_STATUS.DONE, TASK_STATUS.BLOCKED])
    .optional(),

  priority: z
    .enum([TASK_PRIORITY.LOW, TASK_PRIORITY.MEDIUM, TASK_PRIORITY.HIGH, TASK_PRIORITY.URGENT])
    .optional(),

  due_date: z
    .string()
    .refine(
      (date) => {
        if (!date) return true;
        const dueDate = new Date(date);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        return dueDate >= today;
      },
      { message: ERROR_MESSAGES.TASK.DUE_DATE_PAST }
    )
    .optional(),
});

// ============================================
// TYPE INFERENCE
// ============================================

export type CreateTaskInput = z.infer<typeof createTaskSchema>;
export type UpdateTaskInput = z.infer<typeof updateTaskSchema>;
EOF

# Verify
cat src/lib/validations/task.ts
```

**Verify TypeScript compiles:**

```bash
npx tsc --noEmit src/lib/types/database.ts src/lib/validations/task.ts
```

<details>
<summary>📖 <strong>SOLID Principles in Validation</strong></summary>

### Single Responsibility Principle (SRP)

Each file has ONE job:
- `constants.ts` - Define static values
- `database.ts` - Define types
- `task.ts` - Validate task inputs

**Benefits:**
- Easy to find code
- Easy to test
- Easy to change

### DRY (Don't Repeat Yourself)

Notice we use constants for validation:
```typescript
// ❌ BAD: Magic numbers repeated
.min(1, { message: 'Title must be at least 1 character' })
.max(200, { message: 'Title must be at most 200 characters' })

// ✅ GOOD: Single source of truth
.min(VALIDATION.TASK.TITLE_MIN_LENGTH, {
  message: `Title must be at least ${VALIDATION.TASK.TITLE_MIN_LENGTH} character`,
})
```

Change the limit once in constants, validation message updates automatically!

</details>

---

### 🎯 STEP 5 — Create Task Server Actions with Cache

Server Actions with Next.js 16 `use cache` directive for performance.

```bash
mkdir -p src/lib/actions

cat > src/lib/actions/tasks.ts << 'EOF'
'use server';

// ============================================
// TASK SERVER ACTIONS
// Next.js 16 Cache Components + React 19.2
// ============================================

import { revalidateTag } from 'next/cache';
import { createServerClient } from '@/lib/supabase/server';
import { createTaskSchema, updateTaskSchema } from '@/lib/validations/task';
import type { CreateTaskInput, UpdateTaskInput, Task, TaskWithOverdue, TaskStats } from '@/lib/types/database';
import {
  ERROR_MESSAGES,
  SUCCESS_MESSAGES,
  CACHE_TAGS,
  TABLES,
} from '@/lib/constants';

// ============================================
// HELPER: GET AUTHENTICATED USER
// ============================================

async function getAuthenticatedUser() {
  const supabase = await createServerClient();
  const { data: { user }, error } = await supabase.auth.getUser();

  if (error || !user) {
    throw new Error(ERROR_MESSAGES.AUTH.UNAUTHORIZED);
  }

  return user;
}

// ============================================
// CREATE TASK
// ============================================

export async function createTask(input: CreateTaskInput): Promise<{ success: boolean; data?: Task; error?: string }> {
  try {
    // Authenticate user
    await getAuthenticatedUser();

    // Validate input
    const validated = createTaskSchema.parse(input);

    // Create task
    const supabase = await createServerClient();
    const { data, error } = await supabase
      .from(TABLES.TASKS)
      .insert({
        title: validated.title,
        description: validated.description || null,
        status: validated.status,
        priority: validated.priority,
        due_date: validated.due_date || null,
        project_id: validated.project_id,
      })
      .select()
      .single();

    if (error) {
      console.error('Create task error:', error);
      return { success: false, error: ERROR_MESSAGES.TASK.CREATE_FAILED };
    }

    // Revalidate cache
    revalidateTag(CACHE_TAGS.TASKS);
    revalidateTag(CACHE_TAGS.TASK_STATS);

    return { success: true, data };
  } catch (error) {
    console.error('Create task error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.TASK.CREATE_FAILED,
    };
  }
}

// ============================================
// GET TASKS BY PROJECT (WITH CACHE)
// ============================================

export async function getTasksByProject(
  projectId: string,
  filters?: {
    status?: string;
    priority?: string;
    overdueOnly?: boolean;
  }
): Promise<{ success: boolean; data?: TaskWithOverdue[]; error?: string }> {
  'use cache'; // ← Next.js 16 Cache Directive

  try {
    await getAuthenticatedUser();

    const supabase = await createServerClient();
    const { data, error } = await supabase.rpc('get_tasks_by_project', {
      p_project_id: projectId,
      p_status: filters?.status || null,
      p_priority: filters?.priority || null,
      p_overdue_only: filters?.overdueOnly || false,
    });

    if (error) {
      console.error('Get tasks error:', error);
      return { success: false, error: ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG };
    }

    return { success: true, data: data || [] };
  } catch (error) {
    console.error('Get tasks error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG,
    };
  }
}

// ============================================
// GET TASK BY ID (WITH CACHE)
// ============================================

export async function getTask(taskId: string): Promise<{ success: boolean; data?: Task; error?: string }> {
  'use cache'; // ← Next.js 16 Cache Directive

  try {
    await getAuthenticatedUser();

    const supabase = await createServerClient();
    const { data, error } = await supabase
      .from(TABLES.TASKS)
      .select('*')
      .eq('id', taskId)
      .single();

    if (error) {
      console.error('Get task error:', error);
      return { success: false, error: ERROR_MESSAGES.TASK.NOT_FOUND };
    }

    return { success: true, data };
  } catch (error) {
    console.error('Get task error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.TASK.NOT_FOUND,
    };
  }
}

// ============================================
// UPDATE TASK
// ============================================

export async function updateTask(
  taskId: string,
  input: UpdateTaskInput
): Promise<{ success: boolean; data?: Task; error?: string }> {
  try {
    await getAuthenticatedUser();

    // Validate input
    const validated = updateTaskSchema.parse(input);

    // Update task
    const supabase = await createServerClient();
    const { data, error } = await supabase
      .from(TABLES.TASKS)
      .update({
        ...validated,
        updated_at: new Date().toISOString(),
      })
      .eq('id', taskId)
      .select()
      .single();

    if (error) {
      console.error('Update task error:', error);
      return { success: false, error: ERROR_MESSAGES.TASK.UPDATE_FAILED };
    }

    // Revalidate cache
    revalidateTag(CACHE_TAGS.TASKS);
    revalidateTag(CACHE_TAGS.TASK_STATS);

    return { success: true, data };
  } catch (error) {
    console.error('Update task error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.TASK.UPDATE_FAILED,
    };
  }
}

// ============================================
// DELETE TASK
// ============================================

export async function deleteTask(taskId: string): Promise<{ success: boolean; error?: string }> {
  try {
    await getAuthenticatedUser();

    const supabase = await createServerClient();
    const { error } = await supabase
      .from(TABLES.TASKS)
      .delete()
      .eq('id', taskId);

    if (error) {
      console.error('Delete task error:', error);
      return { success: false, error: ERROR_MESSAGES.TASK.DELETE_FAILED };
    }

    // Revalidate cache
    revalidateTag(CACHE_TAGS.TASKS);
    revalidateTag(CACHE_TAGS.TASK_STATS);

    return { success: true };
  } catch (error) {
    console.error('Delete task error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.TASK.DELETE_FAILED,
    };
  }
}

// ============================================
// GET TASK STATISTICS (WITH CACHE)
// ============================================

export async function getTaskStats(projectId: string): Promise<{ success: boolean; data?: TaskStats; error?: string }> {
  'use cache'; // ← Next.js 16 Cache Directive

  try {
    await getAuthenticatedUser();

    const supabase = await createServerClient();
    const { data, error } = await supabase.rpc('get_task_stats', {
      p_project_id: projectId,
    });

    if (error) {
      console.error('Get task stats error:', error);
      return { success: false, error: ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG };
    }

    return { success: true, data: data?.[0] || null };
  } catch (error) {
    console.error('Get task stats error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG,
    };
  }
}

// ============================================
// TOGGLE TASK STATUS (TODO ↔ DONE)
// ============================================

export async function toggleTaskStatus(taskId: string, currentStatus: string): Promise<{ success: boolean; error?: string }> {
  try {
    await getAuthenticatedUser();

    // Simple toggle: if done, set to todo; otherwise set to done
    const newStatus = currentStatus === 'done' ? 'todo' : 'done';

    const supabase = await createServerClient();
    const { error } = await supabase
      .from(TABLES.TASKS)
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', taskId);

    if (error) {
      console.error('Toggle task status error:', error);
      return { success: false, error: ERROR_MESSAGES.TASK.UPDATE_FAILED };
    }

    // Revalidate cache
    revalidateTag(CACHE_TAGS.TASKS);
    revalidateTag(CACHE_TAGS.TASK_STATS);

    return { success: true };
  } catch (error) {
    console.error('Toggle task status error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.TASK.UPDATE_FAILED,
    };
  }
}
EOF

# Verify
cat src/lib/actions/tasks.ts
```

**Verify TypeScript compiles:**

```bash
npx tsc --noEmit src/lib/actions/tasks.ts
```

<details>
<summary>📖 <strong>Next.js 16 'use cache' Directive Explained</strong></summary>

### What is 'use cache'?

The `'use cache'` directive tells Next.js to cache the return value of an async function.

### How It Works

```typescript
export async function getTasksByProject(projectId: string) {
  'use cache'; // ← Cache this function's result

  const { data } = await supabase.rpc('get_tasks_by_project', { p_project_id: projectId });
  return data;
}
```

**First call:** Query database, return data, store in cache
**Subsequent calls:** Return cached data (NO database query!)

### Cache Invalidation

When you mutate data (create/update/delete), invalidate the cache:

```typescript
import { revalidateTag } from 'next/cache';

export async function createTask(input) {
  // ... create task ...

  // Invalidate cache so next read gets fresh data
  revalidateTag(CACHE_TAGS.TASKS);
  revalidateTag(CACHE_TAGS.TASK_STATS);
}
```

### Benefits

- **Faster** - Cached reads skip database entirely
- **Scalable** - Reduces database load
- **Automatic** - No manual cache management

### When NOT to Use

- Functions with user-specific data that changes frequently
- Real-time data requirements
- Functions with side effects (use for reads, not writes)

</details>

---

### 🎯 STEP 6 — Create Task Components

Create reusable task components following SOLID principles (Single Responsibility).

**Create TaskCard component:**

```bash
mkdir -p src/components/features/tasks

cat > src/components/features/tasks/TaskCard.tsx << 'EOF'
// ============================================
// TASK CARD COMPONENT
// Single Responsibility: Display one task
// ============================================

import Link from 'next/link';
import { TASK_STATUS_LABELS, TASK_PRIORITY_LABELS, TASK_STATUS_COLORS, TASK_PRIORITY_COLORS, ROUTES } from '@/lib/constants';
import type { TaskWithOverdue } from '@/lib/types/database';

interface TaskCardProps {
  task: TaskWithOverdue;
  projectId: string;
}

export function TaskCard({ task, projectId }: TaskCardProps) {
  return (
    <Link
      href={ROUTES.TASK_VIEW(projectId, task.id)}
      className="block p-4 bg-white border rounded-lg hover:shadow-md transition-shadow"
    >
      {/* Task Title */}
      <h3 className="text-lg font-semibold text-gray-900">{task.title}</h3>

      {/* Task Description */}
      {task.description && (
        <p className="mt-1 text-sm text-gray-600 line-clamp-2">{task.description}</p>
      )}

      {/* Badges: Status, Priority, Overdue */}
      <div className="mt-3 flex flex-wrap gap-2">
        {/* Status Badge */}
        <span className={`px-2 py-1 text-xs font-medium rounded-full ${TASK_STATUS_COLORS[task.status]}`}>
          {TASK_STATUS_LABELS[task.status]}
        </span>

        {/* Priority Badge */}
        <span className={`px-2 py-1 text-xs font-medium rounded-full ${TASK_PRIORITY_COLORS[task.priority]}`}>
          {TASK_PRIORITY_LABELS[task.priority]}
        </span>

        {/* Overdue Badge */}
        {task.is_overdue && (
          <span className="px-2 py-1 text-xs font-medium rounded-full bg-red-600 text-white">
            Overdue
          </span>
        )}
      </div>

      {/* Due Date */}
      {task.due_date && (
        <p className="mt-2 text-xs text-gray-500">
          Due: {new Date(task.due_date).toLocaleDateString()}
        </p>
      )}
    </Link>
  );
}
EOF

# Verify
cat src/components/features/tasks/TaskCard.tsx
```

**Create TaskList component:**

```bash
cat > src/components/features/tasks/TaskList.tsx << 'EOF'
// ============================================
// TASK LIST COMPONENT
// Single Responsibility: Display list of tasks
// ============================================

import { TaskCard } from './TaskCard';
import type { TaskWithOverdue } from '@/lib/types/database';

interface TaskListProps {
  tasks: TaskWithOverdue[];
  projectId: string;
}

export function TaskList({ tasks, projectId }: TaskListProps) {
  if (tasks.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">No tasks found. Create your first task!</p>
      </div>
    );
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {tasks.map((task) => (
        <TaskCard key={task.id} task={task} projectId={projectId} />
      ))}
    </div>
  );
}
EOF

# Verify
cat src/components/features/tasks/TaskList.tsx
```

**Create TaskStats component:**

```bash
cat > src/components/features/tasks/TaskStats.tsx << 'EOF'
// ============================================
// TASK STATS COMPONENT
// Single Responsibility: Display task statistics
// ============================================

import type { TaskStats } from '@/lib/types/database';

interface TaskStatsProps {
  stats: TaskStats;
}

export function TaskStats({ stats }: TaskStatsProps) {
  const statItems = [
    { label: 'Total Tasks', value: stats.total_tasks, color: 'text-gray-600' },
    { label: 'To Do', value: stats.todo_count, color: 'text-gray-600' },
    { label: 'In Progress', value: stats.in_progress_count, color: 'text-blue-600' },
    { label: 'Done', value: stats.done_count, color: 'text-green-600' },
    { label: 'Blocked', value: stats.blocked_count, color: 'text-red-600' },
    { label: 'Overdue', value: stats.overdue_count, color: 'text-orange-600' },
  ];

  return (
    <div className="bg-white p-6 rounded-lg border">
      <h2 className="text-xl font-semibold text-gray-900 mb-4">Task Statistics</h2>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {statItems.map((item) => (
          <div key={item.label} className="text-center">
            <p className={`text-3xl font-bold ${item.color}`}>{item.value}</p>
            <p className="text-sm text-gray-500 mt-1">{item.label}</p>
          </div>
        ))}
      </div>

      {/* Completion Rate */}
      <div className="mt-6 pt-6 border-t">
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium text-gray-700">Completion Rate</span>
          <span className="text-2xl font-bold text-green-600">{stats.completion_rate}%</span>
        </div>

        {/* Progress Bar */}
        <div className="mt-2 w-full bg-gray-200 rounded-full h-2">
          <div
            className="bg-green-600 h-2 rounded-full transition-all"
            style={{ width: `${stats.completion_rate}%` }}
          />
        </div>
      </div>
    </div>
  );
}
EOF

# Verify
cat src/components/features/tasks/TaskStats.tsx
```

**Create TaskForm component:**

```bash
cat > src/components/features/tasks/TaskForm.tsx << 'EOF'
'use client';

// ============================================
// TASK FORM COMPONENT
// Single Responsibility: Create/Edit task form
// ============================================

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createTask, updateTask } from '@/lib/actions/tasks';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import {
  TASK_STATUS,
  TASK_PRIORITY,
  TASK_STATUS_LABELS,
  TASK_PRIORITY_LABELS,
  UI_LABELS,
  ERROR_MESSAGES,
  SUCCESS_MESSAGES,
  ROUTES,
} from '@/lib/constants';
import type { Task } from '@/lib/types/database';

interface TaskFormProps {
  projectId: string;
  task?: Task;
  mode: 'create' | 'edit';
}

export function TaskForm({ projectId, task, mode }: TaskFormProps) {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [title, setTitle] = useState(task?.title || '');
  const [description, setDescription] = useState(task?.description || '');
  const [status, setStatus] = useState(task?.status || TASK_STATUS.TODO);
  const [priority, setPriority] = useState(task?.priority || TASK_PRIORITY.MEDIUM);
  const [dueDate, setDueDate] = useState(task?.due_date || '');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const input = {
        title,
        description: description || undefined,
        status,
        priority,
        due_date: dueDate || undefined,
        project_id: projectId,
      };

      const result = mode === 'create'
        ? await createTask(input)
        : await updateTask(task!.id, input);

      if (result.success) {
        router.push(ROUTES.PROJECT_TASKS(projectId));
        router.refresh();
      } else {
        setError(result.error || ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG);
      }
    } catch (err) {
      setError(ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Status options
  const statusOptions = Object.values(TASK_STATUS).map((value) => ({
    value,
    label: TASK_STATUS_LABELS[value],
  }));

  // Priority options
  const priorityOptions = Object.values(TASK_PRIORITY).map((value) => ({
    value,
    label: TASK_PRIORITY_LABELS[value],
  }));

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Title */}
      <Input
        label={UI_LABELS.FORM_FIELDS.TITLE}
        type="text"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder={UI_LABELS.PLACEHOLDERS.TASK_TITLE}
        required
      />

      {/* Description */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          {UI_LABELS.FORM_FIELDS.DESCRIPTION}
        </label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder={UI_LABELS.PLACEHOLDERS.TASK_DESCRIPTION}
          rows={4}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Status */}
      <Select
        label={UI_LABELS.FORM_FIELDS.STATUS}
        value={status}
        onChange={(e) => setStatus(e.target.value as any)}
        options={statusOptions}
      />

      {/* Priority */}
      <Select
        label={UI_LABELS.FORM_FIELDS.PRIORITY}
        value={priority}
        onChange={(e) => setPriority(e.target.value as any)}
        options={priorityOptions}
      />

      {/* Due Date */}
      <Input
        label={UI_LABELS.FORM_FIELDS.DUE_DATE}
        type="date"
        value={dueDate}
        onChange={(e) => setDueDate(e.target.value)}
      />

      {/* Buttons */}
      <div className="flex gap-4">
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Saving...' : UI_LABELS.BUTTONS.SAVE}
        </Button>

        <Button
          type="button"
          variant="secondary"
          onClick={() => router.push(ROUTES.PROJECT_TASKS(projectId))}
        >
          {UI_LABELS.BUTTONS.CANCEL}
        </Button>
      </div>
    </form>
  );
}
EOF

# Verify
cat src/components/features/tasks/TaskForm.tsx
```

**Verify all components compile:**

```bash
npx tsc --noEmit src/components/features/tasks/*.tsx
```

<details>
<summary>📖 <strong>Single Responsibility Principle (SRP) in Components</strong></summary>

### What is SRP?

Each component should have **one reason to change**.

### Examples

**TaskCard** - Display one task
- If task display changes, update TaskCard
- No logic for fetching, creating, or deleting tasks

**TaskList** - Display list of tasks
- If list layout changes, update TaskList
- Delegates individual task display to TaskCard

**TaskForm** - Create/edit task form
- If form fields change, update TaskForm
- Delegates submission to Server Actions

**TaskStats** - Display statistics
- If stats layout changes, update TaskStats
- No logic for calculating stats (done in RPC function)

### Benefits

1. **Easy to maintain** - Changes are localized
2. **Easy to test** - Test one thing at a time
3. **Reusable** - Components can be used in different contexts
4. **Readable** - Clear what each component does

</details>

---

### 🎯 STEP 7 — Create Task Pages with Cache

Create task pages using Next.js 16 Server Components with `use cache`.

**Create tasks list page:**

```bash
mkdir -p src/app/dashboard/projects/\[id\]/tasks

cat > 'src/app/dashboard/projects/[id]/tasks/page.tsx' << 'EOF'
// ============================================
// TASKS LIST PAGE (Server Component with Cache)
// ============================================

import Link from 'next/link';
import { getTasksByProject, getTaskStats } from '@/lib/actions/tasks';
import { TaskList } from '@/components/features/tasks/TaskList';
import { TaskStats } from '@/components/features/tasks/TaskStats';
import { Button } from '@/components/ui/Button';
import { ROUTES, UI_LABELS } from '@/lib/constants';

interface TasksPageProps {
  params: Promise<{ id: string }>;
}

export default async function TasksPage({ params }: TasksPageProps) {
  const { id: projectId } = await params;

  // Fetch tasks and stats (both use 'use cache' in Server Actions)
  const [tasksResult, statsResult] = await Promise.all([
    getTasksByProject(projectId),
    getTaskStats(projectId),
  ]);

  if (!tasksResult.success || !statsResult.success) {
    return (
      <div className="p-6">
        <p className="text-red-600">{tasksResult.error || statsResult.error}</p>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Tasks</h1>

        <div className="flex gap-4">
          <Link href={ROUTES.TASK_NEW(projectId)}>
            <Button>{UI_LABELS.BUTTONS.CREATE} Task</Button>
          </Link>

          <Link href={ROUTES.PROJECT_VIEW(projectId)}>
            <Button variant="secondary">{UI_LABELS.BUTTONS.BACK} to Project</Button>
          </Link>
        </div>
      </div>

      {/* Task Statistics */}
      {statsResult.data && <TaskStats stats={statsResult.data} />}

      {/* Task List */}
      <TaskList tasks={tasksResult.data || []} projectId={projectId} />
    </div>
  );
}
EOF

# Verify file created
cat 'src/app/dashboard/projects/[id]/tasks/page.tsx'
```

**Create new task page:**

```bash
mkdir -p 'src/app/dashboard/projects/[id]/tasks/new'

cat > 'src/app/dashboard/projects/[id]/tasks/new/page.tsx' << 'EOF'
// ============================================
// CREATE TASK PAGE
// ============================================

import { TaskForm } from '@/components/features/tasks/TaskForm';

interface NewTaskPageProps {
  params: Promise<{ id: string }>;
}

export default async function NewTaskPage({ params }: NewTaskPageProps) {
  const { id: projectId } = await params;

  return (
    <div className="max-w-2xl mx-auto p-6">
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Create New Task</h1>
      <TaskForm projectId={projectId} mode="create" />
    </div>
  );
}
EOF

# Verify
cat 'src/app/dashboard/projects/[id]/tasks/new/page.tsx'
```

**Create view task page:**

```bash
mkdir -p 'src/app/dashboard/projects/[id]/tasks/[taskId]'

cat > 'src/app/dashboard/projects/[id]/tasks/[taskId]/page.tsx' << 'EOF'
// ============================================
// VIEW TASK PAGE (Server Component with Cache)
// ============================================

import Link from 'next/link';
import { getTask, deleteTask } from '@/lib/actions/tasks';
import { Button } from '@/components/ui/Button';
import {
  TASK_STATUS_LABELS,
  TASK_PRIORITY_LABELS,
  TASK_STATUS_COLORS,
  TASK_PRIORITY_COLORS,
  ROUTES,
  UI_LABELS,
  ERROR_MESSAGES,
} from '@/lib/constants';

interface ViewTaskPageProps {
  params: Promise<{ id: string; taskId: string }>;
}

export default async function ViewTaskPage({ params }: ViewTaskPageProps) {
  const { id: projectId, taskId } = await params;

  const result = await getTask(taskId);

  if (!result.success || !result.data) {
    return (
      <div className="p-6">
        <p className="text-red-600">{result.error || ERROR_MESSAGES.TASK.NOT_FOUND}</p>
      </div>
    );
  }

  const task = result.data;

  return (
    <div className="max-w-3xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">{task.title}</h1>

        <Link href={ROUTES.PROJECT_TASKS(projectId)}>
          <Button variant="secondary">{UI_LABELS.BUTTONS.BACK}</Button>
        </Link>
      </div>

      {/* Task Details */}
      <div className="bg-white p-6 rounded-lg border space-y-4">
        {/* Description */}
        {task.description && (
          <div>
            <h2 className="text-sm font-medium text-gray-500 mb-2">Description</h2>
            <p className="text-gray-900">{task.description}</p>
          </div>
        )}

        {/* Badges */}
        <div>
          <h2 className="text-sm font-medium text-gray-500 mb-2">Status & Priority</h2>
          <div className="flex gap-2">
            <span className={`px-3 py-1 text-sm font-medium rounded-full ${TASK_STATUS_COLORS[task.status]}`}>
              {TASK_STATUS_LABELS[task.status]}
            </span>
            <span className={`px-3 py-1 text-sm font-medium rounded-full ${TASK_PRIORITY_COLORS[task.priority]}`}>
              {TASK_PRIORITY_LABELS[task.priority]}
            </span>
          </div>
        </div>

        {/* Due Date */}
        {task.due_date && (
          <div>
            <h2 className="text-sm font-medium text-gray-500 mb-2">Due Date</h2>
            <p className="text-gray-900">{new Date(task.due_date).toLocaleDateString()}</p>
          </div>
        )}

        {/* Timestamps */}
        <div className="pt-4 border-t">
          <p className="text-xs text-gray-500">Created: {new Date(task.created_at).toLocaleString()}</p>
          <p className="text-xs text-gray-500">Updated: {new Date(task.updated_at).toLocaleString()}</p>
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-4">
        <Link href={ROUTES.TASK_EDIT(projectId, taskId)}>
          <Button>{UI_LABELS.BUTTONS.EDIT}</Button>
        </Link>
      </div>
    </div>
  );
}
EOF

# Verify
cat 'src/app/dashboard/projects/[id]/tasks/[taskId]/page.tsx'
```

**Create edit task page:**

```bash
mkdir -p 'src/app/dashboard/projects/[id]/tasks/[taskId]/edit'

cat > 'src/app/dashboard/projects/[id]/tasks/[taskId]/edit/page.tsx' << 'EOF'
// ============================================
// EDIT TASK PAGE
// ============================================

import { getTask } from '@/lib/actions/tasks';
import { TaskForm } from '@/components/features/tasks/TaskForm';
import { ERROR_MESSAGES } from '@/lib/constants';

interface EditTaskPageProps {
  params: Promise<{ id: string; taskId: string }>;
}

export default async function EditTaskPage({ params }: EditTaskPageProps) {
  const { id: projectId, taskId } = await params;

  const result = await getTask(taskId);

  if (!result.success || !result.data) {
    return (
      <div className="max-w-2xl mx-auto p-6">
        <p className="text-red-600">{result.error || ERROR_MESSAGES.TASK.NOT_FOUND}</p>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto p-6">
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Edit Task</h1>
      <TaskForm projectId={projectId} task={result.data} mode="edit" />
    </div>
  );
}
EOF

# Verify
cat 'src/app/dashboard/projects/[id]/tasks/[taskId]/edit/page.tsx'
```

**Verify all pages compile:**

```bash
npx tsc --noEmit 'src/app/dashboard/projects/[id]/tasks/**/*.tsx'
```

---

### 🎯 STEP 8 — (OPTIONAL) Demo React 19.2 useEffectEvent

Create a demo hook using React 19.2's `useEffectEvent` to avoid stale closures.

```bash
mkdir -p src/hooks

cat > src/hooks/useTaskTimer.ts << 'EOF'
'use client';

// ============================================
// DEMO: React 19.2 useEffectEvent Hook
// Use case: Timer that logs latest task count without re-creating interval
// ============================================

import { useEffect, useState, useEffectEvent } from 'react';

/**
 * Demo hook showing useEffectEvent usage
 * This timer logs task count every 5 seconds WITHOUT re-creating the interval
 * even though taskCount changes.
 */
export function useTaskTimer(taskCount: number) {
  const [elapsedSeconds, setElapsedSeconds] = useState(0);

  // ============================================
  // React 19.2 useEffectEvent
  // This function always sees latest taskCount
  // but does NOT cause effect to re-run
  // ============================================
  const logTaskCount = useEffectEvent(() => {
    console.log(`[Timer ${elapsedSeconds}s] Current task count: ${taskCount}`);
  });

  useEffect(() => {
    // Start timer
    const interval = setInterval(() => {
      setElapsedSeconds((prev) => prev + 1);

      // Call Effect Event - always sees latest taskCount
      // WITHOUT this being in dependency array!
      logTaskCount();
    }, 5000);

    return () => clearInterval(interval);

    // Notice: taskCount is NOT in dependency array!
    // Without useEffectEvent, this would use stale taskCount
    // With useEffectEvent, logTaskCount always sees latest value
  }, []); // Empty dependencies - effect never re-runs!

  return elapsedSeconds;
}
EOF

# Verify
cat src/hooks/useTaskTimer.ts
```

**Verify TypeScript compiles:**

```bash
npx tsc --noEmit src/hooks/useTaskTimer.ts
```

<details>
<summary>📖 <strong>React 19.2 useEffectEvent Explained</strong></summary>

### The Stale Closure Problem

**Without useEffectEvent:**

```typescript
function BadTimer({ taskCount }) {
  useEffect(() => {
    const interval = setInterval(() => {
      // ❌ BUG: This uses taskCount from when effect was created
      // If taskCount changes, this still sees old value!
      console.log(taskCount);
    }, 1000);

    return () => clearInterval(interval);
  }, []); // Empty deps = taskCount is stale
}
```

**Old solution:** Add `taskCount` to dependencies
- ❌ Problem: Effect re-runs on every change, re-creates interval

### With useEffectEvent

```typescript
function GoodTimer({ taskCount }) {
  // ✅ Effect Event always sees latest value
  const logCount = useEffectEvent(() => {
    console.log(taskCount); // Always latest!
  });

  useEffect(() => {
    const interval = setInterval(logCount, 1000);
    return () => clearInterval(interval);
  }, []); // Effect never re-runs, but logCount sees latest taskCount!
}
```

### When to Use

✅ **Use useEffectEvent when:**
- You need latest props/state in callback
- But don't want effect to re-run when those values change

❌ **Don't use when:**
- You DO want effect to re-run on changes
- Callback is not used in effect

### Benefits

1. **No stale closures** - Always see latest values
2. **Fewer re-runs** - Effect doesn't re-run unnecessarily
3. **Better performance** - Avoids recreating timers, subscriptions, etc.

</details>

---

## ✅ 3. VERIFY

### Verification Checklist

**🎯 Step 1: Constants File**
- [ ] `src/lib/constants.ts` created with all static values
- [ ] No magic strings in constants file (all typed as const)
- [ ] TypeScript compiles without errors
- [ ] Task status, priority, routes, error messages defined

**🎯 Step 2: Cache Components**
- [ ] `next.config.ts` updated with `experimental.cacheComponents: true`
- [ ] Config file has no syntax errors

**🎯 Step 3: Database**
- [ ] Migration file `003_task_rls_and_rpc.sql` created
- [ ] RLS enabled on `prj_tasks` table
- [ ] 4 RLS policies created (SELECT, INSERT, UPDATE, DELETE)
- [ ] RPC function `get_tasks_by_project()` created
- [ ] RPC function `get_task_stats()` created
- [ ] Indexes created for performance

**🎯 Step 4: Types & Validation**
- [ ] `src/lib/types/database.ts` updated with Task types
- [ ] `src/lib/validations/task.ts` created with Zod schemas
- [ ] TypeScript compiles without errors
- [ ] Validation uses constants (no magic numbers)

**🎯 Step 5: Server Actions**
- [ ] `src/lib/actions/tasks.ts` created
- [ ] `use cache` directive on read functions
- [ ] `revalidateTag()` called after mutations
- [ ] All error messages use constants
- [ ] TypeScript compiles without errors

**🎯 Step 6: Components**
- [ ] `TaskCard.tsx` created (displays one task)
- [ ] `TaskList.tsx` created (displays list)
- [ ] `TaskStats.tsx` created (displays statistics)
- [ ] `TaskForm.tsx` created (create/edit form)
- [ ] All components use constants for labels, routes, colors
- [ ] TypeScript compiles without errors

**🎯 Step 7: Pages**
- [ ] Tasks list page created at `[id]/tasks/page.tsx`
- [ ] New task page created at `[id]/tasks/new/page.tsx`
- [ ] View task page created at `[id]/tasks/[taskId]/page.tsx`
- [ ] Edit task page created at `[id]/tasks/[taskId]/edit/page.tsx`
- [ ] All pages use Server Components
- [ ] TypeScript compiles without errors

**🎯 Step 8: React 19.2 Demo (Optional)**
- [ ] `src/hooks/useTaskTimer.ts` created
- [ ] Uses `useEffectEvent` hook
- [ ] TypeScript compiles without errors

### Manual Testing

**Test Task CRUD:**

1. **Start dev server:**
   ```bash
   npm run dev
   ```

2. **Create a task:**
   - Navigate to a project
   - Click "Tasks" tab
   - Click "Create Task"
   - Fill form and submit
   - Verify task appears in list

3. **View task:**
   - Click a task card
   - Verify all details display correctly
   - Check status and priority badges

4. **Edit task:**
   - On task view page, click "Edit"
   - Change title, status, or priority
   - Submit and verify changes

5. **Check statistics:**
   - Navigate to tasks list
   - Verify task stats dashboard shows correct counts
   - Verify completion rate updates

6. **Test filters (if implemented):**
   - Filter by status
   - Filter by priority
   - Filter overdue tasks only

### Code Quality Checks

**No magic strings:**
```bash
# This should return NO results (no hardcoded status strings)
grep -r "status === 'done'" src/
grep -r '"todo"' src/ --exclude="constants.ts"
```

**All imports from constants:**
```bash
# This should show constants imported everywhere
grep -r "from '@/lib/constants'" src/
```

**Cache directive used:**
```bash
# Should see 'use cache' in Server Actions
grep -r "use cache" src/lib/actions/
```

### Performance Testing

**Check cache is working:**

1. Open browser DevTools → Network tab
2. Navigate to tasks list
3. Note database query (or check Supabase dashboard)
4. Navigate away and back to tasks list
5. Verify: **NO new database query** (served from cache!)

---

## 🎓 4. KEY CONCEPTS SUMMARY

### Best Practices Learned

✅ **Constants Management**
- All static values in `constants.ts`
- Type-safe with `as const` and exported types
- Single source of truth for the entire app
- Change once, update everywhere

✅ **Next.js 16 Cache Components**
- `use cache` directive for async functions
- Automatic caching of Server Component results
- `revalidateTag()` for cache invalidation
- Dramatic performance improvement for read-heavy operations

✅ **React 19.2 useEffectEvent**
- Avoid stale closures in effects
- Access latest props/state without re-running effect
- Perfect for timers, subscriptions, event listeners

✅ **SOLID Principles**
- **S**ingle Responsibility - Each file/component has one job
- **D**RY - Don't Repeat Yourself, use constants

✅ **RPC Functions**
- Complex queries run on database server
- Better performance than client-side filtering
- Enforces RLS automatically
- Type-safe with Supabase client

✅ **Type Safety**
- TypeScript + Zod + database types
- No runtime errors from invalid data
- IDE autocomplete for all static values
- Compile-time checks catch bugs early

### File Organization

```
src/
├── lib/
│   ├── constants.ts          ← ALL static values
│   ├── actions/
│   │   └── tasks.ts          ← Server Actions (with cache)
│   ├── validations/
│   │   └── task.ts           ← Zod schemas (use constants)
│   └── types/
│       └── database.ts       ← TypeScript types
├── components/
│   └── features/tasks/
│       ├── TaskCard.tsx      ← Display one task
│       ├── TaskList.tsx      ← Display list
│       ├── TaskForm.tsx      ← Create/edit form
│       └── TaskStats.tsx     ← Statistics dashboard
└── app/
    └── dashboard/projects/[id]/tasks/
        ├── page.tsx          ← List (Server Component with cache)
        ├── new/page.tsx      ← Create
        └── [taskId]/
            ├── page.tsx      ← View (Server Component with cache)
            └── edit/page.tsx ← Edit
```

### Next Steps

With Lesson 5 complete, you now have:
- ✅ Production-grade best practices (constants, SOLID, DRY)
- ✅ Next.js 16 cache components for performance
- ✅ React 19.2 features (useEffectEvent)
- ✅ Full task management system
- ✅ RPC functions for complex queries
- ✅ Zero magic strings or numbers

**Possible next lessons:**
- **Lesson 6:** Project Members (M:N relationships with `prj_project_members`)
- **Lesson 7:** Real-time Updates (Supabase subscriptions)
- **Lesson 8:** File Uploads (Supabase Storage)
- **Lesson 9:** Advanced Filtering & Search
- **Lesson 10:** Deployment to Vercel

---

## 📚 Additional Resources

**Next.js 16 Documentation:**
- [Cache Components Guide](https://nextjs.org/docs/app/getting-started/cache-components)
- [use cache Directive](https://nextjs.org/docs/app/api-reference/directives/use-cache)
- [Partial Prerendering (PPR)](https://nextjs.org/docs/app/building-your-application/rendering/partial-prerendering)

**React 19.2 Documentation:**
- [useEffectEvent Hook](https://react.dev/reference/react/useEffectEvent)
- [React 19.2 Release Notes](https://react.dev/blog/2025/10/01/react-19-2)

**Supabase:**
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [RPC Functions](https://supabase.com/docs/guides/database/functions)

**Best Practices:**
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [DRY Principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)

---

**🎉 Congratulations!** You've completed Lesson 5 and learned production-grade Next.js 16 + React 19.2 development with best practices!
