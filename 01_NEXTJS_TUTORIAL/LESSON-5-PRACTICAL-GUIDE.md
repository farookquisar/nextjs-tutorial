# Module 1, Lesson 5 — Task Management with Best Practices

**Prerequisites:** Complete Lesson 1 (Next.js Setup), Lesson 2 (Supabase Setup), Lesson 3 (Authentication), and Lesson 4 (Project CRUD)

---

## 📖 1. DESC

### What You'll Build

In this lesson, you'll implement **Task Management** for projects using the **prj_tasks** table created in Lesson 2, while applying **production-grade best practices**:

✅ **Constants Extension** - Add task-specific constants to `src/constants/index.ts` (created in Lesson 1)
✅ **Next.js 16 Cache Components** - Cached async components with `'use cache'`, `cacheLife()`, and `cacheTag()`
✅ **Tag-Based Revalidation** - Use `updateTag()` instead of `revalidatePath()` for surgical cache updates
✅ **Suspense Boundaries** - Skeleton loaders for instant feedback and streaming
✅ **React 19.2 useEffectEvent** - Avoid stale closures in effects
✅ **Task CRUD Operations** - Create, read, update, delete tasks with optimized caching
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

✅ **Constants Extension** - Add task-specific constants to `src/constants/index.ts` (created in Lesson 1)
✅ **Cache Components** - Separate cached async components with `'use cache'`, `cacheLife()`, `cacheTag()`
✅ **Tag-Based Revalidation** - `updateTag()` in Server Actions for surgical cache invalidation
✅ **Suspense Boundaries** - Skeleton loaders and streaming with React Suspense
✅ **useEffectEvent** - React 19.2 hook for non-reactive effect logic
✅ **Task CRUD** - Full task management with validation and optimized caching
✅ **RPC Functions** - `get_tasks_by_project()`, `get_task_stats()`
✅ **Task Filtering** - By status, priority, overdue, project
✅ **Reusable Components** - TaskCard, TaskList, TaskForm, TaskStats
✅ **SOLID Architecture** - Single-purpose functions and components

```
📁 Your App Structure (After This Lesson)
├── src/
│   ├── constants/
│   │   └── index.ts                      ← UPDATE: Add task constants (created in Lesson 1)
│   ├── lib/
│   │   ├── actions/
│   │   │   └── tasks.ts                  ← NEW: Task CRUD Server Actions (with 'use cache')
│   │   ├── validations/
│   │   │   └── task.ts                   ← NEW: Zod task schemas
│   │   └── types/
│   │       └── database.ts               ← UPDATE: Add task types
│   ├── app/
│   │   └── dashboard/
│   │       └── projects/[id]/
│   │           └── tasks/
│   │               ├── page.tsx          ← NEW: Tasks list (Server Component with cache)
│   │               ├── new/
│   │               │   └── page.tsx      ← NEW: Create task
│   │               └── [taskId]/
│   │                   ├── page.tsx      ← NEW: View task (Server Component with cache)
│   │                   └── edit/
│   │                       └── page.tsx  ← NEW: Edit task
│   ├── components/
│   │   └── features/tasks/
│   │       ├── TaskList.tsx              ← NEW: Tasks list component
│   │       ├── TaskCard.tsx              ← NEW: Task card component
│   │       ├── TaskForm.tsx              ← NEW: Create/Edit form
│   │       └── TaskStats.tsx             ← NEW: Task statistics
│   └── hooks/
│       └── useTaskTimer.ts               ← NEW: Demo useEffectEvent
└── supabase/migrations/
    └── 003_task_rls_and_rpc.sql          ← NEW: RLS + RPC functions
```

### Why This Approach?

✅ **Maintainable** - Constants file makes updates easy, no hunt for hardcoded values
✅ **Performant** - Cache Components with `'use cache'` reduce database queries dramatically
✅ **Surgical Updates** - `updateTag()` revalidates only affected caches, not entire routes
✅ **Better UX** - Suspense boundaries provide instant feedback with skeleton loaders
✅ **Clean Code** - SOLID principles, DRY, single responsibility
✅ **Type-safe** - TypeScript + Zod + database types = zero runtime errors
✅ **Future-proof** - Next.js 16 and React 19.2 latest features
✅ **Scalable** - RPC functions handle complex queries efficiently

---

## 🎯 2. STEPS

### 🎯 STEP 1 — Add Task-Specific Constants to Existing File

**In Lesson 1, we already created `src/constants/index.ts` with foundational constants like:**
- `DB_TABLES` (database table names)
- `TASK_STATUS` (todo, in_progress, review, done, cancelled)
- `PROJECT_STATUS` (active, inactive, etc.)
- `ROUTES` (basic routes)
- `VALIDATION` limits
- `ERROR_MESSAGES` and `SUCCESS_MESSAGES`

**In this lesson, we'll ADD these NEW task-specific constants:**

1. **TASK_PRIORITY** - Low, Medium, High, Urgent (NEW!)
2. **TASK_STATUS_LABELS** - Display labels for UI (NEW!)
3. **TASK_PRIORITY_LABELS** - Display labels for UI (NEW!)
4. **TASK_STATUS_COLORS** - Tailwind CSS classes for badges (NEW!)
5. **TASK_PRIORITY_COLORS** - Tailwind CSS classes for badges (NEW!)
6. **UI_LABELS** - Button labels, placeholders, form field labels (NEW!)
7. **Task routes** - ADD to existing ROUTES object

**Why constants?**
- ❌ **Bad:** `if (status === 'done')` - What if you typo "dne"?
- ✅ **Good:** `if (status === TASK_STATUS.DONE)` - TypeScript autocomplete + compile-time safety

**Add these NEW constants to `src/constants/index.ts`:**

```bash
# Open your constants file and ADD these new sections:

# 1. ADD TASK_PRIORITY (after TASK_STATUS)
export const TASK_PRIORITY = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  URGENT: 'urgent',
} as const;

# 2. ADD Display Labels for Status (NEW)
export const TASK_STATUS_LABELS: Record<TaskStatus, string> = {
  [TASK_STATUS.TODO]: 'To Do',
  [TASK_STATUS.IN_PROGRESS]: 'In Progress',
  [TASK_STATUS.REVIEW]: 'Review',
  [TASK_STATUS.DONE]: 'Done',
  [TASK_STATUS.CANCELLED]: 'Cancelled',
};

# 3. ADD Display Labels for Priority (NEW)
export const TASK_PRIORITY_LABELS: Record<TaskPriority, string> = {
  [TASK_PRIORITY.LOW]: 'Low',
  [TASK_PRIORITY.MEDIUM]: 'Medium',
  [TASK_PRIORITY.HIGH]: 'High',
  [TASK_PRIORITY.URGENT]: 'Urgent',
};

# 4. ADD CSS Colors for Status Badges (NEW)
export const TASK_STATUS_COLORS: Record<TaskStatus, string> = {
  [TASK_STATUS.TODO]: 'bg-gray-100 text-gray-800',
  [TASK_STATUS.IN_PROGRESS]: 'bg-blue-100 text-blue-800',
  [TASK_STATUS.REVIEW]: 'bg-yellow-100 text-yellow-800',
  [TASK_STATUS.DONE]: 'bg-green-100 text-green-800',
  [TASK_STATUS.CANCELLED]: 'bg-red-100 text-red-800',
};

# 5. ADD CSS Colors for Priority Badges (NEW)
export const TASK_PRIORITY_COLORS: Record<TaskPriority, string> = {
  [TASK_PRIORITY.LOW]: 'bg-slate-100 text-slate-800',
  [TASK_PRIORITY.MEDIUM]: 'bg-yellow-100 text-yellow-800',
  [TASK_PRIORITY.HIGH]: 'bg-orange-100 text-orange-800',
  [TASK_PRIORITY.URGENT]: 'bg-red-100 text-red-800',
};

# 6. ADD UI Labels (NEW)
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

# 7. ADD Task Routes to existing ROUTES (UPDATE ROUTES object)
# Add these task routes to your existing ROUTES constant:
  PROJECT_TASKS: (projectId: string) => `/dashboard/projects/${projectId}/tasks`,
  TASK_NEW: (projectId: string) => `/dashboard/projects/${projectId}/tasks/new`,
  TASK_VIEW: (projectId: string, taskId: string) => `/dashboard/projects/${projectId}/tasks/${taskId}`,
  TASK_EDIT: (projectId: string, taskId: string) => `/dashboard/projects/${projectId}/tasks/${taskId}/edit`,

# 8. UPDATE Type Exports (add TaskPriority)
export type TaskPriority = typeof TASK_PRIORITY[keyof typeof TASK_PRIORITY];
```

**Verify the constants compile:**

```bash
# Check TypeScript compiles without errors
npx tsc --noEmit src/constants/index.ts
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

### 🎯 STEP 2 — Add RLS Policies and RPC Functions for Tasks

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

### 🎯 STEP 3 — Create Task Types and Validation Schemas

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

### 🎯 STEP 4 — Create Task Server Actions with Cache

Server Actions with Next.js 16 `use cache` directive for performance.

```bash
mkdir -p src/lib/actions

cat > src/lib/actions/tasks.ts << 'EOF'
'use server';

// ============================================
// TASK SERVER ACTIONS
// Next.js 16 Cache Components + React 19.2
// ============================================

import { updateTag } from 'next/cache';
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
    updateTag(CACHE_TAGS.TASKS);
    updateTag(CACHE_TAGS.TASK_STATS);

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
    updateTag(CACHE_TAGS.TASKS);
    updateTag(CACHE_TAGS.TASK_STATS);

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
    updateTag(CACHE_TAGS.TASKS);
    updateTag(CACHE_TAGS.TASK_STATS);

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
    updateTag(CACHE_TAGS.TASKS);
    updateTag(CACHE_TAGS.TASK_STATS);

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
<summary>📖 <strong>Next.js 16 Cache Components Explained</strong></summary>

### What are Cache Components?

Cache Components use the `'use cache'` directive in async component functions to cache rendered output with fine-grained control.

### How It Works

```typescript
// Cached async component (NOT a Server Action)
async function TasksListSection({ projectId }: { projectId: string }) {
  'use cache'                      // ← Enable caching for this component
  cacheLife('hours')              // ← Cache for 1 hour
  cacheTag('tasks')               // ← Tag for selective revalidation
  cacheTag(`tasks-${projectId}`)  // ← Project-specific tag

  const result = await getTasksByProject(projectId);
  return <TaskList tasks={result.data || []} />
}
```

**First render:** Fetch data, render component, store in cache
**Subsequent renders:** Return cached result (NO database query, NO re-render!)

### Cache Invalidation

When you mutate data (create/update/delete), invalidate specific cache tags:

```typescript
import { updateTag } from 'next/cache';

export async function createTask(input) {
  // ... create task ...

  // Invalidate only affected caches
  updateTag('tasks');              // All task lists
  updateTag(`tasks-${projectId}`); // This project's tasks
  updateTag('task-stats');         // Task statistics
}
```

### Benefits

- **Faster** - Cached components served instantly from edge
- **Scalable** - Reduces database load dramatically
- **Selective** - Only invalidate what changed with tags
- **Automatic** - Works with Suspense and PPR

### Key Difference from Server Actions

- **'use cache' in Components** - Cache rendered output (UI)
- **Server Actions** - Always run on server, use `updateTag()` to invalidate

</details>

---

### 🎯 STEP 5 — Create Task Components

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

### 🎯 STEP 6 — Configure Next.js for Cache Components

Before creating pages with Cache Components, ensure your `next.config.js` has the required experimental flag enabled.

**Note:** If you completed Lesson 4, this configuration should already be in place. This step verifies the setup.

**Update or verify `next.config.js`:**

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    cacheComponents: true
  }
}

module.exports = nextConfig
```

This enables Next.js 16's Cache Components feature, allowing you to use `'use cache'` directives for component-level caching with fine-grained revalidation using `updateTag()`.

**Verify the configuration:**

```bash
# Check that next.config.js exists and has the experimental flag
cat next.config.js | grep -A 2 "experimental"
```

---

### 🎯 STEP 7 — Create Task Pages with Cache Components

Create task pages using Next.js 16 Server Components with separate cached async components and Suspense boundaries.

**Create tasks list page:**

```bash
mkdir -p src/app/dashboard/projects/\[id\]/tasks

cat > 'src/app/dashboard/projects/[id]/tasks/page.tsx' << 'EOF'
// ============================================
// TASKS LIST PAGE (Server Component with Cache)
// ============================================

import { Suspense } from 'react';
import Link from 'next/link';
import { getTasksByProject, getTaskStats } from '@/lib/actions/tasks';
import { TaskList } from '@/components/features/tasks/TaskList';
import { TaskStats } from '@/components/features/tasks/TaskStats';
import { Button } from '@/components/ui/Button';
import { ROUTES, UI_LABELS } from '@/lib/constants';
import { cacheLife, cacheTag } from 'next/cache';

interface TasksPageProps {
  params: Promise<{ id: string }>;
}

// Cached async component for task statistics
async function TaskStatsSection({ projectId }: { projectId: string }) {
  'use cache'
  cacheLife('hours')
  cacheTag('task-stats')
  cacheTag(`task-stats-${projectId}`)

  const statsResult = await getTaskStats(projectId);

  if (!statsResult.success || !statsResult.data) {
    return null;
  }

  return <TaskStats stats={statsResult.data} />;
}

// Cached async component for tasks list
async function TasksListSection({ projectId }: { projectId: string }) {
  'use cache'
  cacheLife('hours')
  cacheTag('tasks')
  cacheTag(`tasks-${projectId}`)

  const tasksResult = await getTasksByProject(projectId);

  if (!tasksResult.success) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600">{tasksResult.error}</p>
      </div>
    );
  }

  return <TaskList tasks={tasksResult.data || []} projectId={projectId} />;
}

// Skeleton loaders
function TaskStatsSkeleton() {
  return (
    <div className="animate-pulse">
      <div className="h-48 bg-gray-200 rounded-lg"></div>
    </div>
  );
}

function TasksListSkeleton() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {[1, 2, 3, 4, 5, 6].map((i) => (
        <div key={i} className="animate-pulse">
          <div className="h-40 bg-gray-200 rounded-lg"></div>
        </div>
      ))}
    </div>
  );
}

export default async function TasksPage({ params }: TasksPageProps) {
  const { id: projectId } = await params;

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

      {/* Task Statistics with Suspense */}
      <Suspense fallback={<TaskStatsSkeleton />}>
        <TaskStatsSection projectId={projectId} />
      </Suspense>

      {/* Task List with Suspense */}
      <Suspense fallback={<TasksListSkeleton />}>
        <TasksListSection projectId={projectId} />
      </Suspense>
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

import { Suspense } from 'react';
import Link from 'next/link';
import { getTask } from '@/lib/actions/tasks';
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
import { cacheLife, cacheTag } from 'next/cache';

interface ViewTaskPageProps {
  params: Promise<{ id: string; taskId: string }>;
}

// Cached async component for task details
async function TaskDetails({ taskId, projectId }: { taskId: string; projectId: string }) {
  'use cache'
  cacheLife('hours')
  cacheTag('tasks')
  cacheTag(`task-${taskId}`)

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

// Skeleton loader
function TaskDetailsSkeleton() {
  return (
    <div className="max-w-3xl mx-auto p-6 space-y-6 animate-pulse">
      <div className="h-10 bg-gray-200 rounded w-1/3"></div>
      <div className="h-64 bg-gray-200 rounded"></div>
    </div>
  );
}

export default async function ViewTaskPage({ params }: ViewTaskPageProps) {
  const { id: projectId, taskId } = await params;

  return (
    <Suspense fallback={<TaskDetailsSkeleton />}>
      <TaskDetails taskId={taskId} projectId={projectId} />
    </Suspense>
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

import { Suspense } from 'react';
import { getTask } from '@/lib/actions/tasks';
import { TaskForm } from '@/components/features/tasks/TaskForm';
import { ERROR_MESSAGES } from '@/lib/constants';
import { cacheLife, cacheTag } from 'next/cache';

interface EditTaskPageProps {
  params: Promise<{ id: string; taskId: string }>;
}

// Cached async component for task form data
async function TaskFormSection({ taskId, projectId }: { taskId: string; projectId: string }) {
  'use cache'
  cacheLife('hours')
  cacheTag('tasks')
  cacheTag(`task-${taskId}`)

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

// Skeleton loader
function TaskFormSkeleton() {
  return (
    <div className="max-w-2xl mx-auto p-6 space-y-6 animate-pulse">
      <div className="h-10 bg-gray-200 rounded w-1/3"></div>
      <div className="h-96 bg-gray-200 rounded"></div>
    </div>
  );
}

export default async function EditTaskPage({ params }: EditTaskPageProps) {
  const { id: projectId, taskId } = await params;

  return (
    <Suspense fallback={<TaskFormSkeleton />}>
      <TaskFormSection taskId={taskId} projectId={projectId} />
    </Suspense>
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

### 🎯 STEP 9 — Understanding Cache Components for Tasks

Next.js 16's Cache Components feature provides fine-grained control over caching with component-level granularity and tag-based revalidation. This step explains the caching strategy used in the task management system.

#### What We're Caching

**Task Statistics** (`'use cache'` with `cacheLife('hours')`):
- Task statistics are computed from aggregated data (RPC function)
- Don't change frequently (only when tasks are created/updated/deleted)
- Cache for 1 hour to reduce database load
- Tagged with `'task-stats'` and `'task-stats-{projectId}'` for selective revalidation

**Tasks List** (`'use cache'` with `cacheLife('hours')`):
- Task listings cached per project
- Revalidated when tasks are created/updated/deleted
- Uses multiple tags: `'tasks'` and `'tasks-{projectId}'`
- Ensures fast page loads while staying fresh

**Individual Tasks** (`'use cache'` with task-specific tag):
- Each task cached independently
- Uses tags: `'tasks'` and `'task-{taskId}'`
- Allows selective revalidation of specific tasks
- Edit form data also cached for instant load

#### Cache Revalidation Strategy

**When creating a task:**
```typescript
updateTag('tasks')                    // Revalidate all task-related caches
updateTag(`tasks-${projectId}`)       // Revalidate this project's tasks
updateTag('task-stats')               // Revalidate global task stats
updateTag(`task-stats-${projectId}`)  // Revalidate this project's stats
```

**When updating a task:**
```typescript
updateTag('tasks')                    // Revalidate all task-related caches
updateTag(`task-${taskId}`)           // Revalidate specific task
updateTag(`tasks-${projectId}`)       // Revalidate project's task list
updateTag('task-stats')               // Revalidate stats
updateTag(`task-stats-${projectId}`)  // Revalidate project stats
```

**When deleting a task:**
```typescript
updateTag('tasks')                    // Revalidate all task-related caches
updateTag(`tasks-${projectId}`)       // Revalidate project's task list
updateTag('task-stats')               // Revalidate stats
updateTag(`task-stats-${projectId}`)  // Revalidate project stats
```

#### Benefits of Cache Components

✅ **Performance**: Cached responses served instantly from the edge
✅ **Reduced Load**: Fewer database queries means lower costs
✅ **User Experience**: Instant navigation with Partial Prerendering (PPR)
✅ **Selective Updates**: Only revalidate what changed, not entire routes
✅ **Read Your Own Writes**: `updateTag` ensures users see their changes immediately
✅ **Granular Control**: Different cache durations per component

#### How Cache Components Work with Tasks

1. **Cache Directive**: `'use cache'` marks an async component for caching
2. **Cache Duration**: `cacheLife('hours')` sets how long to cache (seconds, minutes, hours, days)
3. **Cache Tags**: `cacheTag('tag-name')` allows selective revalidation
4. **Tag Updates**: `updateTag('tag-name')` invalidates specific caches in Server Actions
5. **Suspense Boundaries**: Skeleton loaders provide instant feedback while loading

**Example from Task List Page:**
```typescript
// Cached async component
async function TasksListSection({ projectId }: { projectId: string }) {
  'use cache'                      // Enable caching for this component
  cacheLife('hours')              // Cache for 1 hour
  cacheTag('tasks')               // Tag for all tasks
  cacheTag(`tasks-${projectId}`)  // Tag for this project's tasks

  const tasksResult = await getTasksByProject(projectId)
  return <TaskList tasks={tasksResult.data || []} projectId={projectId} />
}

// In the page component
export default async function TasksPage({ params }) {
  const { id: projectId } = await params

  return (
    <Suspense fallback={<TasksListSkeleton />}>
      <TasksListSection projectId={projectId} />
    </Suspense>
  )
}

// Later, when a task is created in a Server Action:
updateTag('tasks')                // Invalidate all task caches
updateTag(`tasks-${projectId}`)   // Invalidate this project's tasks
```

#### Comparison with Previous Approach

**Before (revalidatePath):**
- Invalidates entire route
- All components on the page refetch
- More database queries
- Slower after mutations
- Coarse-grained control

**After (updateTag):**
- Invalidates only tagged components
- Only affected components refetch
- Fewer database queries
- Faster, more surgical updates
- Fine-grained control with multiple tags

#### Cache Tags Strategy for Tasks

The task management system uses a hierarchical tagging strategy:

- `'tasks'` - All task-related caches (global)
- `'tasks-{projectId}'` - Tasks for a specific project
- `'task-{taskId}'` - A specific task
- `'task-stats'` - All task statistics (global)
- `'task-stats-{projectId}'` - Statistics for a specific project

This allows you to invalidate:
- All tasks across all projects: `updateTag('tasks')`
- All tasks in one project: `updateTag('tasks-{projectId}')`
- One specific task: `updateTag('task-{taskId}')`
- All statistics: `updateTag('task-stats')`
- Statistics for one project: `updateTag('task-stats-{projectId}')`

For more details on Cache Components and PPR, see `NEXTJS16-CACHE-REFERENCE.md` in the project root.

---

## ✅ 3. VERIFY

### Verification Checklist

**🎯 Step 1: Add Task Constants**
- [ ] Task-specific constants added to `src/constants/index.ts`
- [ ] TASK_PRIORITY, labels, colors added (NEW in Lesson 5)
- [ ] Task routes added to existing ROUTES object
- [ ] UI_LABELS added for buttons, placeholders, form fields
- [ ] TypeScript compiles without errors
- [ ] No magic strings (all values from constants)

**🎯 Step 2: Database**
- [ ] Migration file `003_task_rls_and_rpc.sql` created
- [ ] RLS enabled on `prj_tasks` table
- [ ] 4 RLS policies created (SELECT, INSERT, UPDATE, DELETE)
- [ ] RPC function `get_tasks_by_project()` created
- [ ] RPC function `get_task_stats()` created
- [ ] Indexes created for performance

**🎯 Step 3: Types & Validation**
- [ ] `src/lib/types/database.ts` updated with Task types
- [ ] `src/lib/validations/task.ts` created with Zod schemas
- [ ] TypeScript compiles without errors
- [ ] Validation uses constants (no magic numbers)

**🎯 Step 4: Server Actions**
- [ ] `src/lib/actions/tasks.ts` created
- [ ] Server Actions do NOT have `'use cache'` (only in components)
- [ ] `updateTag()` called after mutations (not `revalidateTag()`)
- [ ] All error messages use constants
- [ ] TypeScript compiles without errors

**🎯 Step 5: Components**
- [ ] `TaskCard.tsx` created (displays one task)
- [ ] `TaskList.tsx` created (displays list)
- [ ] `TaskStats.tsx` created (displays statistics)
- [ ] `TaskForm.tsx` created (create/edit form)
- [ ] All components use constants for labels, routes, colors
- [ ] TypeScript compiles without errors

**🎯 Step 6: Configure Next.js**
- [ ] `next.config.js` has `experimental: { cacheComponents: true }`
- [ ] Configuration verified with grep command

**🎯 Step 7: Pages with Cache Components**
- [ ] Tasks list page created at `[id]/tasks/page.tsx`
- [ ] Separate cached async components: `TaskStatsSection`, `TasksListSection`
- [ ] Each cached component has `'use cache'`, `cacheLife()`, `cacheTag()`
- [ ] Suspense boundaries with skeleton loaders
- [ ] New task page created at `[id]/tasks/new/page.tsx`
- [ ] View task page created with cached `TaskDetails` component
- [ ] Edit task page created with cached `TaskFormSection` component
- [ ] TypeScript compiles without errors

**🎯 Step 8: React 19.2 Demo (Optional)**
- [ ] `src/hooks/useTaskTimer.ts` created (if implementing)
- [ ] Uses `useEffectEvent` hook
- [ ] TypeScript compiles without errors

**🎯 Step 9: Understanding Cache Components**
- [ ] Read and understand the caching strategy section
- [ ] Understand tag hierarchy and revalidation patterns
- [ ] Understand difference between `'use cache'` and Server Actions


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

**Cache Components pattern used:**
```bash
# Should see 'use cache' in page components (NOT Server Actions)
grep -r "use cache" src/app/

# Should see updateTag in Server Actions (NOT revalidateTag)
grep -r "updateTag" src/lib/actions/

# Should see cacheLife and cacheTag in components
grep -r "cacheLife\|cacheTag" src/app/
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
- `'use cache'` directive in async component functions (NOT Server Actions)
- `cacheLife()` to set cache duration (seconds, minutes, hours, days)
- `cacheTag()` to tag caches for selective invalidation
- `updateTag()` in Server Actions to invalidate specific caches
- Suspense boundaries with skeleton loaders for instant feedback
- Dramatic performance improvement with surgical cache updates

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
├── constants/
│   └── index.ts              ← ALL static values (created in Lesson 1, extended in Lesson 5)
├── lib/
│   ├── actions/
│   │   └── tasks.ts          ← Server Actions (with 'use cache')
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
        ├── page.tsx          ← List (Cached components with Suspense)
        ├── new/page.tsx      ← Create
        └── [taskId]/
            ├── page.tsx      ← View (Cached component with Suspense)
            └── edit/page.tsx ← Edit (Cached component with Suspense)
```

### Next Steps

With Lesson 5 complete, you now have:
- ✅ Production-grade best practices (constants, SOLID, DRY)
- ✅ Next.js 16 Cache Components with tag-based revalidation
- ✅ Suspense boundaries with skeleton loaders for instant UX
- ✅ React 19.2 features (useEffectEvent)
- ✅ Full task management system with optimized caching
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
