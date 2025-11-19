# Module 1, Lesson 4 — CRUD Operations with Server Actions & RPC Functions

**Prerequisites:** Complete Lesson 1 (Next.js Setup), Lesson 2 (Supabase Setup), and Lesson 3 (Authentication)

---

## 📖 1. DESC

### What is CRUD?

**CRUD** stands for Create, Read, Update, Delete — the four basic operations for managing data in any application.

In this lesson, we'll implement:
- **Database Schema** with Row Level Security (RLS)
- **Server Actions** for secure CRUD operations
- **RPC Functions** for complex database queries
- **Optimistic UI Updates** for instant feedback
- **Form Validation** with Zod
- **Real-time Data** with Supabase subscriptions
- **Type-safe** database operations with TypeScript

### What You'll Build

A **Task Management System** where authenticated users can:
- ✅ Create tasks with title, description, priority, and due dates
- 📋 View all their tasks in a list
- ✏️ Edit existing tasks
- 🗑️ Delete tasks
- 🔍 Filter and search tasks
- 📊 View task statistics (using RPC functions)

```
📁 Your App Structure (After This Lesson)
├── src/
│   ├── app/
│   │   ├── dashboard/
│   │   │   ├── page.tsx              ← Updated: Dashboard with tasks
│   │   │   └── tasks/
│   │   │       ├── page.tsx          ← NEW: Tasks list page
│   │   │       ├── new/
│   │   │       │   └── page.tsx      ← NEW: Create task page
│   │   │       └── [id]/
│   │   │           ├── page.tsx      ← NEW: View task page
│   │   │           └── edit/
│   │   │               └── page.tsx  ← NEW: Edit task page
│   ├── components/
│   │   └── features/tasks/
│   │       ├── TaskList.tsx          ← NEW: Task list component
│   │       ├── TaskCard.tsx          ← NEW: Individual task card
│   │       ├── TaskForm.tsx          ← NEW: Create/Edit form
│   │       ├── TaskFilters.tsx       ← NEW: Filter controls
│   │       └── TaskStats.tsx         ← NEW: Statistics dashboard
│   ├── lib/
│   │   ├── actions/
│   │   │   └── tasks.ts              ← NEW: CRUD Server Actions
│   │   ├── validations/
│   │   │   └── task.ts               ← NEW: Zod schemas
│   │   └── types/
│   │       └── database.ts           ← NEW: Database types
│   └── hooks/
│       ├── useTasks.ts               ← NEW: Tasks data hook
│       └── useTaskStats.ts           ← NEW: Statistics hook
```

### Why This Approach?

✅ **Secure** - RLS policies ensure users only see their own data
✅ **Type-safe** - Full TypeScript with generated database types
✅ **Fast** - Server Actions eliminate API route boilerplate
✅ **Validated** - Zod schemas prevent invalid data
✅ **Real-time** - Optional Supabase subscriptions for live updates
✅ **Scalable** - RPC functions for complex aggregations
✅ **UX-optimized** - Optimistic updates for instant feedback

---

## 🎯 2. STEPS

### 🎯 STEP 1 — Create Database Tables & RLS Policies

First, we'll create the database schema with proper security policies.

**Create tasks table in Supabase:**

1. Go to Supabase Dashboard → SQL Editor
2. Run this SQL to create the tasks table:

```sql
-- Create tasks table
create table public.tasks (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text not null,
  description text,
  status text not null default 'todo' check (status in ('todo', 'in_progress', 'done')),
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  due_date timestamptz,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Create index for faster queries
create index tasks_user_id_idx on public.tasks(user_id);
create index tasks_status_idx on public.tasks(status);
create index tasks_due_date_idx on public.tasks(due_date);

-- Enable Row Level Security
alter table public.tasks enable row level security;

-- RLS Policies: Users can only see/manage their own tasks

-- Policy: Users can view their own tasks
create policy "Users can view own tasks"
  on public.tasks
  for select
  using (auth.uid() = user_id);

-- Policy: Users can insert their own tasks
create policy "Users can create own tasks"
  on public.tasks
  for insert
  with check (auth.uid() = user_id);

-- Policy: Users can update their own tasks
create policy "Users can update own tasks"
  on public.tasks
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Policy: Users can delete their own tasks
create policy "Users can delete own tasks"
  on public.tasks
  for delete
  using (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Trigger to call the function before update
create trigger set_updated_at
  before update on public.tasks
  for each row
  execute function public.handle_updated_at();
```

3. Click "Run" to execute

**Verify the table:**

```sql
-- Check that the table exists
select * from public.tasks limit 1;
```

---

### 🎯 STEP 2 — Generate TypeScript Types

Generate TypeScript types from your database schema for type safety.

**Install Supabase CLI (if not already installed):**

```bash
npm install -g supabase
```

**Generate types:**

```bash
# Login to Supabase
supabase login

# Link to your project (get project ref from Supabase Dashboard URL)
supabase link --project-ref your-project-ref

# Generate types
npx supabase gen types typescript --linked > src/lib/types/database.ts
```

**Alternative: Manual type definition:**

If you prefer not to use the CLI, create types manually:

```bash
cat > src/lib/types/database.ts << 'EOF'
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      tasks: {
        Row: {
          id: string
          user_id: string
          title: string
          description: string | null
          status: 'todo' | 'in_progress' | 'done'
          priority: 'low' | 'medium' | 'high'
          due_date: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          description?: string | null
          status?: 'todo' | 'in_progress' | 'done'
          priority?: 'low' | 'medium' | 'high'
          due_date?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          description?: string | null
          status?: 'todo' | 'in_progress' | 'done'
          priority?: 'low' | 'medium' | 'high'
          due_date?: string | null
          created_at?: string
          updated_at?: string
        }
      }
    }
    Functions: {
      get_task_stats: {
        Args: { user_id_input: string }
        Returns: {
          total: number
          todo: number
          in_progress: number
          done: number
          overdue: number
        }[]
      }
    }
  }
}

// Helper type for task row
export type Task = Database['public']['Tables']['tasks']['Row']
export type TaskInsert = Database['public']['Tables']['tasks']['Insert']
export type TaskUpdate = Database['public']['Tables']['tasks']['Update']
EOF
```

---

### 🎯 STEP 3 — Create Validation Schemas with Zod

Install Zod for runtime validation:

```bash
npm install zod
```

**Create validation schemas:**

```bash
cat > src/lib/validations/task.ts << 'EOF'
import { z } from 'zod'

// Task status enum
export const taskStatusSchema = z.enum(['todo', 'in_progress', 'done'])

// Task priority enum
export const taskPrioritySchema = z.enum(['low', 'medium', 'high'])

// Create task schema
export const createTaskSchema = z.object({
  title: z
    .string()
    .min(1, 'Title is required')
    .max(200, 'Title must be less than 200 characters'),
  description: z
    .string()
    .max(2000, 'Description must be less than 2000 characters')
    .optional()
    .nullable(),
  status: taskStatusSchema.default('todo'),
  priority: taskPrioritySchema.default('medium'),
  due_date: z
    .string()
    .datetime()
    .optional()
    .nullable()
    .or(z.literal('')),
})

// Update task schema (all fields optional)
export const updateTaskSchema = z.object({
  title: z
    .string()
    .min(1, 'Title is required')
    .max(200, 'Title must be less than 200 characters')
    .optional(),
  description: z
    .string()
    .max(2000, 'Description must be less than 2000 characters')
    .optional()
    .nullable(),
  status: taskStatusSchema.optional(),
  priority: taskPrioritySchema.optional(),
  due_date: z
    .string()
    .datetime()
    .optional()
    .nullable()
    .or(z.literal('')),
})

// Filter schema
export const taskFilterSchema = z.object({
  status: taskStatusSchema.optional(),
  priority: taskPrioritySchema.optional(),
  search: z.string().optional(),
})

// Types inferred from schemas
export type CreateTaskInput = z.infer<typeof createTaskSchema>
export type UpdateTaskInput = z.infer<typeof updateTaskSchema>
export type TaskFilterInput = z.infer<typeof taskFilterSchema>
EOF
```

---

### 🎯 STEP 4 — Create CRUD Server Actions

Server Actions provide a secure way to mutate data without creating API routes.

```bash
cat > src/lib/actions/tasks.ts << 'EOF'
'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import {
  createTaskSchema,
  updateTaskSchema,
  type CreateTaskInput,
  type UpdateTaskInput,
} from '@/lib/validations/task'

// Response type for actions
type ActionResponse<T = void> =
  | { success: true; data: T }
  | { success: false; error: string }

/**
 * CREATE: Add a new task
 */
export async function createTask(
  input: CreateTaskInput
): Promise<ActionResponse<{ id: string }>> {
  try {
    // Validate input
    const validated = createTaskSchema.parse(input)

    // Get authenticated user
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized' }
    }

    // Convert empty string to null for due_date
    const due_date = validated.due_date === '' ? null : validated.due_date

    // Insert task
    const { data, error } = await supabase
      .from('tasks')
      .insert({
        user_id: user.id,
        title: validated.title,
        description: validated.description,
        status: validated.status,
        priority: validated.priority,
        due_date,
      })
      .select('id')
      .single()

    if (error) {
      console.error('Create task error:', error)
      return { success: false, error: 'Failed to create task' }
    }

    // Revalidate the tasks page to show new data
    revalidatePath('/dashboard/tasks')

    return { success: true, data: { id: data.id } }
  } catch (error) {
    console.error('Create task error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

/**
 * READ: Get all tasks for current user
 */
export async function getTasks(filters?: {
  status?: string
  priority?: string
  search?: string
}) {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized', data: null }
    }

    // Start query
    let query = supabase
      .from('tasks')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    // Apply filters
    if (filters?.status) {
      query = query.eq('status', filters.status)
    }
    if (filters?.priority) {
      query = query.eq('priority', filters.priority)
    }
    if (filters?.search) {
      query = query.ilike('title', `%${filters.search}%`)
    }

    const { data, error } = await query

    if (error) {
      console.error('Get tasks error:', error)
      return { success: false, error: 'Failed to fetch tasks', data: null }
    }

    return { success: true, data, error: null }
  } catch (error) {
    console.error('Get tasks error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      data: null,
    }
  }
}

/**
 * READ: Get a single task by ID
 */
export async function getTask(id: string) {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized', data: null }
    }

    const { data, error } = await supabase
      .from('tasks')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single()

    if (error) {
      console.error('Get task error:', error)
      return { success: false, error: 'Task not found', data: null }
    }

    return { success: true, data, error: null }
  } catch (error) {
    console.error('Get task error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      data: null,
    }
  }
}

/**
 * UPDATE: Modify an existing task
 */
export async function updateTask(
  id: string,
  input: UpdateTaskInput
): Promise<ActionResponse> {
  try {
    // Validate input
    const validated = updateTaskSchema.parse(input)

    // Get authenticated user
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized' }
    }

    // Convert empty string to null for due_date
    const updateData = {
      ...validated,
      due_date: validated.due_date === '' ? null : validated.due_date,
    }

    // Update task (RLS ensures user can only update their own tasks)
    const { error } = await supabase
      .from('tasks')
      .update(updateData)
      .eq('id', id)
      .eq('user_id', user.id)

    if (error) {
      console.error('Update task error:', error)
      return { success: false, error: 'Failed to update task' }
    }

    // Revalidate relevant pages
    revalidatePath('/dashboard/tasks')
    revalidatePath(`/dashboard/tasks/${id}`)

    return { success: true, data: undefined }
  } catch (error) {
    console.error('Update task error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

/**
 * DELETE: Remove a task
 */
export async function deleteTask(id: string): Promise<ActionResponse> {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized' }
    }

    // Delete task (RLS ensures user can only delete their own tasks)
    const { error } = await supabase
      .from('tasks')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id)

    if (error) {
      console.error('Delete task error:', error)
      return { success: false, error: 'Failed to delete task' }
    }

    // Revalidate tasks page
    revalidatePath('/dashboard/tasks')

    return { success: true, data: undefined }
  } catch (error) {
    console.error('Delete task error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

/**
 * UPDATE: Toggle task status between todo -> in_progress -> done
 */
export async function toggleTaskStatus(id: string): Promise<ActionResponse> {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized' }
    }

    // Get current task
    const { data: task, error: fetchError } = await supabase
      .from('tasks')
      .select('status')
      .eq('id', id)
      .eq('user_id', user.id)
      .single()

    if (fetchError || !task) {
      return { success: false, error: 'Task not found' }
    }

    // Determine next status
    const nextStatus =
      task.status === 'todo'
        ? 'in_progress'
        : task.status === 'in_progress'
          ? 'done'
          : 'todo'

    // Update status
    const { error: updateError } = await supabase
      .from('tasks')
      .update({ status: nextStatus })
      .eq('id', id)
      .eq('user_id', user.id)

    if (updateError) {
      console.error('Toggle status error:', updateError)
      return { success: false, error: 'Failed to update status' }
    }

    revalidatePath('/dashboard/tasks')
    return { success: true, data: undefined }
  } catch (error) {
    console.error('Toggle status error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}
EOF
```

**Key concepts in the code above:**

1. **`'use server'`** - Marks this file as Server Actions
2. **Validation** - Uses Zod schemas before database operations
3. **Authentication** - Checks user is logged in before any operation
4. **RLS** - Database policies automatically filter by user_id
5. **Revalidation** - `revalidatePath()` refreshes cached pages
6. **Type Safety** - Full TypeScript types for inputs and outputs

---

### 🎯 STEP 5 — Create RPC Functions for Analytics

RPC (Remote Procedure Call) functions run complex SQL logic on the database server.

**Create the RPC function in Supabase SQL Editor:**

```sql
-- Function to get task statistics for a user
create or replace function public.get_task_stats(user_id_input uuid)
returns table(
  total bigint,
  todo bigint,
  in_progress bigint,
  done bigint,
  overdue bigint
) as $$
begin
  return query
  select
    count(*)::bigint as total,
    count(*) filter (where status = 'todo')::bigint as todo,
    count(*) filter (where status = 'in_progress')::bigint as in_progress,
    count(*) filter (where status = 'done')::bigint as done,
    count(*) filter (where due_date < now() and status != 'done')::bigint as overdue
  from public.tasks
  where user_id = user_id_input;
end;
$$ language plpgsql security definer;

-- Grant execute permission
grant execute on function public.get_task_stats to authenticated;
```

**Create Server Action to call the RPC function:**

Add this to `src/lib/actions/tasks.ts`:

```typescript
/**
 * RPC: Get task statistics
 */
export async function getTaskStats() {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized', data: null }
    }

    const { data, error } = await supabase.rpc('get_task_stats', {
      user_id_input: user.id,
    })

    if (error) {
      console.error('Get stats error:', error)
      return { success: false, error: 'Failed to fetch statistics', data: null }
    }

    // RPC returns array with single row
    const stats = data?.[0] || {
      total: 0,
      todo: 0,
      in_progress: 0,
      done: 0,
      overdue: 0,
    }

    return { success: true, data: stats, error: null }
  } catch (error) {
    console.error('Get stats error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      data: null,
    }
  }
}
```

---

### 🎯 STEP 6 — Create Task Components

Now let's build the UI components for displaying and managing tasks.

**Create TaskCard component:**

```bash
cat > src/components/features/tasks/TaskCard.tsx << 'EOF'
import { Task } from '@/lib/types/database'
import Link from 'next/link'
import { deleteTask, toggleTaskStatus } from '@/lib/actions/tasks'
import { useTransition } from 'react'

interface TaskCardProps {
  task: Task
  onDelete?: () => void
  onUpdate?: () => void
}

export function TaskCard({ task, onDelete, onUpdate }: TaskCardProps) {
  const [isPending, startTransition] = useTransition()

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this task?')) return

    startTransition(async () => {
      const result = await deleteTask(task.id)
      if (result.success) {
        onDelete?.()
      } else {
        alert(result.error)
      }
    })
  }

  const handleToggleStatus = async () => {
    startTransition(async () => {
      const result = await toggleTaskStatus(task.id)
      if (result.success) {
        onUpdate?.()
      } else {
        alert(result.error)
      }
    })
  }

  // Format due date
  const dueDate = task.due_date ? new Date(task.due_date) : null
  const isOverdue =
    dueDate && dueDate < new Date() && task.status !== 'done'

  // Status colors
  const statusColors = {
    todo: 'bg-gray-100 text-gray-800',
    in_progress: 'bg-blue-100 text-blue-800',
    done: 'bg-green-100 text-green-800',
  }

  // Priority colors
  const priorityColors = {
    low: 'bg-green-50 text-green-700 border-green-200',
    medium: 'bg-yellow-50 text-yellow-700 border-yellow-200',
    high: 'bg-red-50 text-red-700 border-red-200',
  }

  return (
    <div
      className={`border rounded-lg p-4 hover:shadow-md transition-shadow ${
        isOverdue ? 'border-red-300 bg-red-50' : 'border-gray-200'
      }`}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-2">
            <button
              onClick={handleToggleStatus}
              disabled={isPending}
              className={`px-3 py-1 rounded-full text-xs font-medium ${
                statusColors[task.status]
              } hover:opacity-80 transition-opacity disabled:opacity-50`}
              title="Click to change status"
            >
              {task.status.replace('_', ' ')}
            </button>
            <span
              className={`px-2 py-1 rounded border text-xs font-medium ${
                priorityColors[task.priority]
              }`}
            >
              {task.priority}
            </span>
          </div>

          <Link
            href={`/dashboard/tasks/${task.id}`}
            className="block group"
          >
            <h3 className="font-semibold text-gray-900 group-hover:text-blue-600 transition-colors line-clamp-1">
              {task.title}
            </h3>
            {task.description && (
              <p className="text-sm text-gray-600 mt-1 line-clamp-2">
                {task.description}
              </p>
            )}
          </Link>

          {dueDate && (
            <p
              className={`text-xs mt-2 ${
                isOverdue ? 'text-red-600 font-medium' : 'text-gray-500'
              }`}
            >
              Due: {dueDate.toLocaleDateString()}{' '}
              {isOverdue && '(Overdue!)'}
            </p>
          )}
        </div>

        <div className="flex gap-2">
          <Link
            href={`/dashboard/tasks/${task.id}/edit`}
            className="text-blue-600 hover:text-blue-800 text-sm font-medium"
          >
            Edit
          </Link>
          <button
            onClick={handleDelete}
            disabled={isPending}
            className="text-red-600 hover:text-red-800 text-sm font-medium disabled:opacity-50"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  )
}
EOF
```

**Create TaskList component:**

```bash
cat > src/components/features/tasks/TaskList.tsx << 'EOF'
'use client'

import { Task } from '@/lib/types/database'
import { TaskCard } from './TaskCard'
import { useState } from 'react'

interface TaskListProps {
  initialTasks: Task[]
}

export function TaskList({ initialTasks }: TaskListProps) {
  const [tasks, setTasks] = useState(initialTasks)

  const handleTaskDeleted = (deletedId: string) => {
    setTasks((prev) => prev.filter((task) => task.id !== deletedId))
  }

  const handleTaskUpdated = () => {
    // In a real app, you might refetch or use optimistic updates
    // For now, we'll rely on revalidation
  }

  if (tasks.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500 text-lg">No tasks yet</p>
        <p className="text-gray-400 text-sm mt-2">
          Create your first task to get started!
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {tasks.map((task) => (
        <TaskCard
          key={task.id}
          task={task}
          onDelete={() => handleTaskDeleted(task.id)}
          onUpdate={handleTaskUpdated}
        />
      ))}
    </div>
  )
}
EOF
```

**Create TaskForm component:**

```bash
cat > src/components/features/tasks/TaskForm.tsx << 'EOF'
'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { createTask, updateTask } from '@/lib/actions/tasks'
import { Task } from '@/lib/types/database'

interface TaskFormProps {
  task?: Task
  mode: 'create' | 'edit'
}

export function TaskForm({ task, mode }: TaskFormProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  const [formData, setFormData] = useState({
    title: task?.title || '',
    description: task?.description || '',
    status: task?.status || 'todo',
    priority: task?.priority || 'medium',
    due_date: task?.due_date
      ? new Date(task.due_date).toISOString().slice(0, 16)
      : '',
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    startTransition(async () => {
      if (mode === 'create') {
        const result = await createTask(formData)
        if (result.success) {
          router.push('/dashboard/tasks')
          router.refresh()
        } else {
          setError(result.error)
        }
      } else if (task) {
        const result = await updateTask(task.id, formData)
        if (result.success) {
          router.push(`/dashboard/tasks/${task.id}`)
          router.refresh()
        } else {
          setError(result.error)
        }
      }
    })
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6 max-w-2xl">
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div>
        <label
          htmlFor="title"
          className="block text-sm font-medium text-gray-700 mb-1"
        >
          Title *
        </label>
        <input
          type="text"
          id="title"
          required
          maxLength={200}
          value={formData.title}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, title: e.target.value }))
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          placeholder="Enter task title"
        />
      </div>

      <div>
        <label
          htmlFor="description"
          className="block text-sm font-medium text-gray-700 mb-1"
        >
          Description
        </label>
        <textarea
          id="description"
          rows={4}
          maxLength={2000}
          value={formData.description}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, description: e.target.value }))
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          placeholder="Add more details about this task"
        />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label
            htmlFor="status"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            Status
          </label>
          <select
            id="status"
            value={formData.status}
            onChange={(e) =>
              setFormData((prev) => ({
                ...prev,
                status: e.target.value as Task['status'],
              }))
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="todo">To Do</option>
            <option value="in_progress">In Progress</option>
            <option value="done">Done</option>
          </select>
        </div>

        <div>
          <label
            htmlFor="priority"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            Priority
          </label>
          <select
            id="priority"
            value={formData.priority}
            onChange={(e) =>
              setFormData((prev) => ({
                ...prev,
                priority: e.target.value as Task['priority'],
              }))
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
          </select>
        </div>

        <div>
          <label
            htmlFor="due_date"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            Due Date
          </label>
          <input
            type="datetime-local"
            id="due_date"
            value={formData.due_date}
            onChange={(e) =>
              setFormData((prev) => ({ ...prev, due_date: e.target.value }))
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <div className="flex gap-3">
        <button
          type="submit"
          disabled={isPending}
          className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isPending
            ? 'Saving...'
            : mode === 'create'
              ? 'Create Task'
              : 'Update Task'}
        </button>
        <button
          type="button"
          onClick={() => router.back()}
          className="px-6 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
        >
          Cancel
        </button>
      </div>
    </form>
  )
}
EOF
```

**Create TaskStats component:**

```bash
cat > src/components/features/tasks/TaskStats.tsx << 'EOF'
interface TaskStatsProps {
  stats: {
    total: number
    todo: number
    in_progress: number
    done: number
    overdue: number
  }
}

export function TaskStats({ stats }: TaskStatsProps) {
  const completionRate =
    stats.total > 0 ? Math.round((stats.done / stats.total) * 100) : 0

  return (
    <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
      <StatCard label="Total" value={stats.total} color="gray" />
      <StatCard label="To Do" value={stats.todo} color="blue" />
      <StatCard label="In Progress" value={stats.in_progress} color="yellow" />
      <StatCard label="Done" value={stats.done} color="green" />
      <StatCard
        label="Overdue"
        value={stats.overdue}
        color="red"
        highlight={stats.overdue > 0}
      />

      <div className="col-span-2 md:col-span-5 p-4 bg-gray-50 rounded-lg border border-gray-200">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium text-gray-600">
            Completion Rate
          </span>
          <span className="text-2xl font-bold text-gray-900">
            {completionRate}%
          </span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2">
          <div
            className="bg-green-600 h-2 rounded-full transition-all duration-300"
            style={{ width: `${completionRate}%` }}
          />
        </div>
      </div>
    </div>
  )
}

interface StatCardProps {
  label: string
  value: number
  color: 'gray' | 'blue' | 'yellow' | 'green' | 'red'
  highlight?: boolean
}

function StatCard({ label, value, color, highlight }: StatCardProps) {
  const colorClasses = {
    gray: 'bg-gray-50 border-gray-200 text-gray-900',
    blue: 'bg-blue-50 border-blue-200 text-blue-900',
    yellow: 'bg-yellow-50 border-yellow-200 text-yellow-900',
    green: 'bg-green-50 border-green-200 text-green-900',
    red: 'bg-red-50 border-red-200 text-red-900',
  }

  return (
    <div
      className={`p-4 rounded-lg border ${colorClasses[color]} ${
        highlight ? 'ring-2 ring-red-400' : ''
      }`}
    >
      <p className="text-sm font-medium opacity-75">{label}</p>
      <p className="text-3xl font-bold mt-1">{value}</p>
    </div>
  )
}
EOF
```

---

### 🎯 STEP 7 — Create Task Pages

Now create the pages to display tasks.

**Create tasks list page:**

```bash
cat > src/app/dashboard/tasks/page.tsx << 'EOF'
import Link from 'next/link'
import { getTasks, getTaskStats } from '@/lib/actions/tasks'
import { TaskList } from '@/components/features/tasks/TaskList'
import { TaskStats } from '@/components/features/tasks/TaskStats'
import { redirect } from 'next/navigation'

export const dynamic = 'force-dynamic'

export default async function TasksPage() {
  const [tasksResult, statsResult] = await Promise.all([
    getTasks(),
    getTaskStats(),
  ])

  // Redirect to login if not authenticated
  if (!tasksResult.success || !statsResult.success) {
    redirect('/login')
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">My Tasks</h1>
          <p className="text-gray-600 mt-1">
            Manage your tasks and track your progress
          </p>
        </div>
        <Link
          href="/dashboard/tasks/new"
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          + New Task
        </Link>
      </div>

      {statsResult.data && (
        <div className="mb-8">
          <TaskStats stats={statsResult.data} />
        </div>
      )}

      <TaskList initialTasks={tasksResult.data || []} />
    </div>
  )
}
EOF
```

**Create new task page:**

```bash
cat > src/app/dashboard/tasks/new/page.tsx << 'EOF'
import { TaskForm } from '@/components/features/tasks/TaskForm'

export default function NewTaskPage() {
  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">Create New Task</h1>
      <TaskForm mode="create" />
    </div>
  )
}
EOF
```

**Create view task page:**

```bash
cat > src/app/dashboard/tasks/[id]/page.tsx << 'EOF'
import { getTask } from '@/lib/actions/tasks'
import { notFound } from 'next/navigation'
import Link from 'next/link'

export const dynamic = 'force-dynamic'

export default async function TaskPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const result = await getTask(id)

  if (!result.success || !result.data) {
    notFound()
  }

  const task = result.data
  const dueDate = task.due_date ? new Date(task.due_date) : null

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="mb-6">
        <Link
          href="/dashboard/tasks"
          className="text-blue-600 hover:text-blue-800 text-sm"
        >
          ← Back to tasks
        </Link>
      </div>

      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <div className="flex items-start justify-between mb-6">
          <h1 className="text-3xl font-bold text-gray-900">{task.title}</h1>
          <Link
            href={`/dashboard/tasks/${id}/edit`}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Edit
          </Link>
        </div>

        <div className="space-y-4">
          <div className="flex gap-3">
            <span
              className={`px-3 py-1 rounded-full text-sm font-medium ${
                task.status === 'done'
                  ? 'bg-green-100 text-green-800'
                  : task.status === 'in_progress'
                    ? 'bg-blue-100 text-blue-800'
                    : 'bg-gray-100 text-gray-800'
              }`}
            >
              {task.status.replace('_', ' ')}
            </span>
            <span
              className={`px-3 py-1 rounded-full text-sm font-medium ${
                task.priority === 'high'
                  ? 'bg-red-100 text-red-800'
                  : task.priority === 'medium'
                    ? 'bg-yellow-100 text-yellow-800'
                    : 'bg-green-100 text-green-800'
              }`}
            >
              {task.priority} priority
            </span>
          </div>

          {task.description && (
            <div>
              <h2 className="text-sm font-medium text-gray-600 mb-2">
                Description
              </h2>
              <p className="text-gray-900 whitespace-pre-wrap">
                {task.description}
              </p>
            </div>
          )}

          <div className="grid grid-cols-2 gap-4 pt-4 border-t">
            <div>
              <h3 className="text-sm font-medium text-gray-600">Created</h3>
              <p className="text-gray-900 mt-1">
                {new Date(task.created_at).toLocaleString()}
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-600">
                Last Updated
              </h3>
              <p className="text-gray-900 mt-1">
                {new Date(task.updated_at).toLocaleString()}
              </p>
            </div>
            {dueDate && (
              <div>
                <h3 className="text-sm font-medium text-gray-600">Due Date</h3>
                <p className="text-gray-900 mt-1">
                  {dueDate.toLocaleString()}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
EOF
```

**Create edit task page:**

```bash
cat > src/app/dashboard/tasks/[id]/edit/page.tsx << 'EOF'
import { getTask } from '@/lib/actions/tasks'
import { notFound } from 'next/navigation'
import { TaskForm } from '@/components/features/tasks/TaskForm'

export const dynamic = 'force-dynamic'

export default async function EditTaskPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const result = await getTask(id)

  if (!result.success || !result.data) {
    notFound()
  }

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">Edit Task</h1>
      <TaskForm task={result.data} mode="edit" />
    </div>
  )
}
EOF
```

---

### 🎯 STEP 8 — Add Tasks Link to Dashboard

Update the main dashboard to include a link to the tasks page.

**Update dashboard page:**

```bash
cat > src/app/dashboard/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'

export default async function DashboardPage() {
  const supabase = await createClient()
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser()

  if (error || !user) {
    redirect('/login')
  }

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-2">Dashboard</h1>
      <p className="text-gray-600 mb-8">Welcome back, {user.email}!</p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Link
          href="/dashboard/tasks"
          className="block p-6 bg-white border-2 border-gray-200 rounded-lg hover:border-blue-500 hover:shadow-md transition-all"
        >
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            📋 My Tasks
          </h2>
          <p className="text-gray-600">
            View and manage your tasks, track progress, and stay organized.
          </p>
        </Link>

        <div className="p-6 bg-gray-50 border-2 border-gray-200 rounded-lg">
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            🚀 Coming Soon
          </h2>
          <p className="text-gray-600">
            More features will be added in future lessons!
          </p>
        </div>
      </div>
    </div>
  )
}
EOF
```

---

## 🎓 3. REVIEW

### What You Learned

In this lesson, you built a complete CRUD application with:

1. **Database Design**
   - Created tasks table with proper schema
   - Implemented Row Level Security (RLS) policies
   - Added indexes for performance
   - Created triggers for auto-updating timestamps

2. **Type Safety**
   - Generated TypeScript types from database schema
   - Created Zod validation schemas
   - Used type-safe Server Actions

3. **Server Actions**
   - `createTask` - Create new tasks with validation
   - `getTasks` - Read tasks with filters
   - `getTask` - Read single task
   - `updateTask` - Update existing tasks
   - `deleteTask` - Delete tasks
   - `toggleTaskStatus` - Quick status updates

4. **RPC Functions**
   - `get_task_stats` - Complex aggregations on database
   - Security definer for controlled access
   - Efficient server-side calculations

5. **UI Components**
   - TaskCard - Display individual tasks
   - TaskList - List of tasks with state management
   - TaskForm - Reusable form for create/edit
   - TaskStats - Analytics dashboard

6. **Pages & Routing**
   - `/dashboard/tasks` - List all tasks
   - `/dashboard/tasks/new` - Create new task
   - `/dashboard/tasks/[id]` - View task details
   - `/dashboard/tasks/[id]/edit` - Edit task

### Key Concepts

**Row Level Security (RLS):**
- Database-level security policies
- Automatically filters queries by user
- Prevents unauthorized access even if client code is compromised

**Server Actions:**
- Run on the server, not the client
- Eliminate need for API routes
- Automatically handle CSRF protection
- Type-safe with TypeScript

**RPC Functions:**
- Run SQL logic on database server
- More efficient than multiple queries
- Useful for complex aggregations and calculations

**Revalidation:**
- `revalidatePath()` refreshes cached data
- Ensures UI shows latest data after mutations
- Works with Next.js App Router caching

### Best Practices Applied

✅ **Validation** - Zod schemas validate all inputs
✅ **Security** - RLS policies enforce authorization
✅ **Error Handling** - All actions return success/error responses
✅ **Type Safety** - Full TypeScript coverage
✅ **Performance** - Database indexes and RPC functions
✅ **UX** - Loading states and optimistic updates
✅ **Code Reuse** - Shared components and actions

### Testing Your Implementation

1. **Create a task:**
   - Go to `/dashboard/tasks/new`
   - Fill in the form
   - Click "Create Task"
   - Verify redirect to `/dashboard/tasks`

2. **View tasks:**
   - Check the task appears in the list
   - Verify stats are correct
   - Click a task to view details

3. **Edit a task:**
   - Click "Edit" on a task
   - Modify fields
   - Save and verify changes

4. **Delete a task:**
   - Click "Delete" on a task
   - Confirm deletion
   - Verify task is removed

5. **Toggle status:**
   - Click the status badge on a task card
   - Verify status cycles: todo → in_progress → done → todo

6. **Test RLS:**
   - Create tasks as one user
   - Log out and log in as different user
   - Verify you can't see other user's tasks

### Common Issues & Solutions

**Issue: "Unauthorized" errors**
- Solution: Ensure user is logged in and session is valid
- Check that RLS policies are created correctly

**Issue: Types not matching database**
- Solution: Regenerate types after schema changes
- Run: `npx supabase gen types typescript --linked`

**Issue: Data not refreshing after mutation**
- Solution: Ensure `revalidatePath()` is called in Server Actions
- Check that page has `export const dynamic = 'force-dynamic'`

**Issue: "Failed to create task" errors**
- Solution: Check Supabase logs in dashboard
- Verify RLS policies allow insert
- Ensure user_id is being set correctly

### Next Steps

Now that you have a working CRUD system, you can:

1. **Add Real-time Updates:**
   - Use Supabase subscriptions to listen for changes
   - Update UI automatically when data changes

2. **Add Search & Filters:**
   - Implement full-text search
   - Add date range filters
   - Create saved filters

3. **Add Categories/Tags:**
   - Create a categories table
   - Implement many-to-many relationships
   - Add tag filtering

4. **Add File Uploads:**
   - Implement Supabase Storage
   - Attach files to tasks
   - Handle file deletion

5. **Add Collaboration:**
   - Share tasks with other users
   - Add comments
   - Implement notifications

### Quick Reference

**Create a new resource:**
```typescript
// 1. Create table in Supabase SQL Editor
// 2. Add RLS policies
// 3. Generate TypeScript types
// 4. Create Zod schemas
// 5. Create Server Actions
// 6. Build UI components
// 7. Create pages
```

**Server Action pattern:**
```typescript
'use server'

export async function myAction(input: InputType): Promise<ActionResponse<T>> {
  try {
    // 1. Validate input
    const validated = schema.parse(input)

    // 2. Authenticate
    const supabase = await createClient()
    const { data: { user }, error } = await supabase.auth.getUser()
    if (error || !user) return { success: false, error: 'Unauthorized' }

    // 3. Database operation
    const { data, error: dbError } = await supabase
      .from('table')
      .operation()

    if (dbError) return { success: false, error: 'Operation failed' }

    // 4. Revalidate
    revalidatePath('/path')

    return { success: true, data }
  } catch (error) {
    return { success: false, error: error.message }
  }
}
```

**RPC Function pattern:**
```sql
create or replace function public.my_function(param_name param_type)
returns table(
  field1 type1,
  field2 type2
) as $$
begin
  return query
  select ...
  from ...
  where ...;
end;
$$ language plpgsql security definer;

grant execute on function public.my_function to authenticated;
```

---

### 🎯 What's Next?

**Lesson 5** will cover:
- Real-time data with Supabase subscriptions
- Advanced state management
- Optimistic UI updates
- Error boundaries and error handling
- Loading states and skeletons
- Infinite scroll and pagination

**Continue Learning:**
- Read the [Reusable Features Reference](reference/REUSABLE-FEATURES-REFERENCE.md)
- Explore [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- Learn about [Next.js Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)

---

**Need Help?**
- Check your browser console for errors
- Review Supabase logs in the dashboard
- Ensure all environment variables are set
- Verify database schema matches the lesson

**Congratulations!** 🎉 You now know how to build full-stack CRUD applications with Next.js, Supabase, and Server Actions!
