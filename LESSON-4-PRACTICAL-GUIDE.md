# Module 1, Lesson 4 — Project CRUD Operations with Server Actions

**Prerequisites:** Complete Lesson 1 (Next.js Setup), Lesson 2 (Supabase Setup), and Lesson 3 (Authentication)

---

## 📖 1. DESC

### What You'll Build

In this lesson, you'll implement **CRUD operations** (Create, Read, Update, Delete) for the **Projects** table that was created in Lesson 2.

**What is CRUD?**
- **C**reate - Add new projects
- **R**ead - View projects list and details
- **U**pdate - Edit existing projects
- **D**elete - Remove projects

### Building On Previous Lessons

**Lesson 1:** Next.js 16 setup with TypeScript
**Lesson 2:** Database schema with `prj_projects`, `prj_tasks`, `prj_project_members` tables
**Lesson 3:** Authentication with login, signup, and protected routes
**Lesson 4 (THIS LESSON):** Full project management with CRUD operations

### What You'll Implement

✅ **Project CRUD Operations** - Create, read, update, delete projects
✅ **Server Actions** - Secure, type-safe data mutations
✅ **RPC Functions** - Complex database queries for analytics
✅ **Form Validation** - Zod schemas for input validation
✅ **Optimistic Updates** - Instant UI feedback
✅ **Row Level Security** - User can only manage their own projects
✅ **Project Statistics** - Dashboard with project metrics
✅ **Date Handling** - Start date, end date, overdue detection

```
📁 Your App Structure (After This Lesson)
├── src/
│   ├── app/
│   │   ├── dashboard/
│   │   │   ├── page.tsx              ← Updated: Dashboard with projects
│   │   │   └── projects/
│   │   │       ├── page.tsx          ← NEW: Projects list
│   │   │       ├── new/
│   │   │       │   └── page.tsx      ← NEW: Create project
│   │   │       └── [id]/
│   │   │           ├── page.tsx      ← NEW: View project
│   │   │           └── edit/
│   │   │               └── page.tsx  ← NEW: Edit project
│   ├── components/
│   │   └── features/projects/
│   │       ├── ProjectList.tsx       ← NEW: Projects list
│   │       ├── ProjectCard.tsx       ← NEW: Project card
│   │       ├── ProjectForm.tsx       ← NEW: Create/Edit form
│   │       └── ProjectStats.tsx      ← NEW: Statistics
│   ├── lib/
│   │   ├── actions/
│   │   │   └── projects.ts           ← NEW: CRUD Server Actions
│   │   ├── validations/
│   │   │   └── project.ts            ← NEW: Zod schemas
│   │   └── types/
│   │       └── database.ts           ← NEW: Database types
│   └── hooks/
│       └── useProjects.ts            ← NEW: Projects data hook
```

### Why This Approach?

✅ **Secure** - RLS ensures users only see their own projects
✅ **Type-safe** - Full TypeScript with database types
✅ **Fast** - Server Actions eliminate API boilerplate
✅ **Validated** - Zod schemas prevent invalid data
✅ **Scalable** - RPC functions for complex queries
✅ **User-friendly** - Optimistic updates for instant feedback

---

## 🎯 2. STEPS

### 🎯 STEP 1 — Add RLS Policies for Projects

The `prj_projects` table was created in Lesson 2, but we need to add Row Level Security policies so users can only manage their own projects.

**Create RLS policies in Supabase SQL Editor:**

1. Go to Supabase Dashboard → SQL Editor
2. Run this SQL:

```sql
-- ============================================
-- ROW LEVEL SECURITY FOR PROJECTS
-- ============================================

-- Enable RLS on prj_projects table
ALTER TABLE prj_projects ENABLE ROW LEVEL SECURITY;

-- Add owner_id column to track project ownership
ALTER TABLE prj_projects ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON prj_projects(owner_id);

-- Policy: Users can view their own projects
CREATE POLICY "Users can view own projects"
  ON prj_projects
  FOR SELECT
  USING (auth.uid() = owner_id);

-- Policy: Users can create projects (sets owner_id automatically)
CREATE POLICY "Users can create projects"
  ON prj_projects
  FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

-- Policy: Users can update their own projects
CREATE POLICY "Users can update own projects"
  ON prj_projects
  FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Policy: Users can delete their own projects
CREATE POLICY "Users can delete own projects"
  ON prj_projects
  FOR DELETE
  USING (auth.uid() = owner_id);
```

3. Click "Run" to execute

**Verify the policies:**

```sql
-- Check that RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'prj_projects';

-- Check policies
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'prj_projects';
```

<details>
<summary>📖 <strong>Understanding Row Level Security (RLS)</strong></summary>

### What is RLS?

**Row Level Security** is a PostgreSQL feature that filters database rows based on the current user.

**Without RLS:**
```sql
-- User A can see ALL projects
SELECT * FROM prj_projects;
-- Returns: Project 1, Project 2, Project 3 (including other users' projects!)
```

**With RLS:**
```sql
-- User A can ONLY see their own projects
SELECT * FROM prj_projects;
-- Returns: Only projects where owner_id = User A's ID
```

### How It Works

1. **Enable RLS on table:**
   ```sql
   ALTER TABLE prj_projects ENABLE ROW LEVEL SECURITY;
   ```

2. **Create policies:**
   ```sql
   CREATE POLICY "policy_name"
     ON table_name
     FOR operation  -- SELECT, INSERT, UPDATE, DELETE
     USING (condition);  -- When can user access?
   ```

3. **Supabase auth.uid():**
   - Returns currently authenticated user's ID
   - Works with Supabase Auth automatically
   - NULL if user not logged in

### Policy Types

**SELECT (Read):**
```sql
USING (auth.uid() = owner_id)
-- User can only read rows they own
```

**INSERT (Create):**
```sql
WITH CHECK (auth.uid() = owner_id)
-- User can only insert rows with their ID
```

**UPDATE (Edit):**
```sql
USING (auth.uid() = owner_id)      -- Can only update own rows
WITH CHECK (auth.uid() = owner_id)  -- Can't change owner_id to someone else
```

**DELETE (Remove):**
```sql
USING (auth.uid() = owner_id)
-- User can only delete their own rows
```

### Why RLS is Critical

**Security at Database Level:**
- Even if client code is hacked, RLS protects data
- No way to bypass (unlike application-level checks)
- Single source of truth for permissions

**Example Attack Prevented:**
```javascript
// Attacker tries to delete someone else's project
await supabase.from('prj_projects').delete().eq('id', 'other-user-project-id')

// ❌ BLOCKED by RLS! Policy checks owner_id automatically
// Result: { error: "new row violates row-level security policy" }
```

</details>

---

### 🎯 STEP 2 — Create TypeScript Types

Generate TypeScript types for the database schema.

**Create database types file:**

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
      prj_projects: {
        Row: {
          id: string
          owner_id: string
          name: string
          description: string | null
          start_date: string
          end_date: string | null
          is_active: boolean
          status: 'active' | 'on_hold' | 'completed' | 'archived'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          owner_id: string
          name: string
          description?: string | null
          start_date: string
          end_date?: string | null
          is_active?: boolean
          status?: 'active' | 'on_hold' | 'completed' | 'archived'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          owner_id?: string
          name?: string
          description?: string | null
          start_date?: string
          end_date?: string | null
          is_active?: boolean
          status?: 'active' | 'on_hold' | 'completed' | 'archived'
          created_at?: string
          updated_at?: string
        }
      }
    }
    Functions: {
      get_project_stats: {
        Args: { user_id_input: string }
        Returns: {
          total: number
          active: number
          on_hold: number
          completed: number
          archived: number
          overdue: number
        }[]
      }
    }
  }
}

// Helper types
export type Project = Database['public']['Tables']['prj_projects']['Row']
export type ProjectInsert = Database['public']['Tables']['prj_projects']['Insert']
export type ProjectUpdate = Database['public']['Tables']['prj_projects']['Update']
EOF

# Verify file created
cat src/lib/types/database.ts | head -20
```

---

### 🎯 STEP 3 — Create Validation Schemas with Zod

Install Zod for runtime validation:

```bash
npm install zod
```

**Create validation schemas:**

```bash
cat > src/lib/validations/project.ts << 'EOF'
import { z } from 'zod'

// Project status enum
export const projectStatusSchema = z.enum(['active', 'on_hold', 'completed', 'archived'])

// Create project schema
export const createProjectSchema = z.object({
  name: z
    .string()
    .min(3, 'Project name must be at least 3 characters')
    .max(100, 'Project name must be less than 100 characters'),
  description: z
    .string()
    .max(1000, 'Description must be less than 1000 characters')
    .optional()
    .nullable(),
  start_date: z
    .string()
    .refine((date) => !isNaN(Date.parse(date)), 'Invalid start date'),
  end_date: z
    .string()
    .refine((date) => !isNaN(Date.parse(date)), 'Invalid end date')
    .optional()
    .nullable()
    .or(z.literal('')),
  status: projectStatusSchema.default('active'),
  is_active: z.boolean().default(true),
}).refine(
  (data) => {
    // If end_date exists, it must be after start_date
    if (data.end_date && data.end_date !== '') {
      return new Date(data.end_date) >= new Date(data.start_date)
    }
    return true
  },
  {
    message: 'End date must be after start date',
    path: ['end_date'],
  }
)

// Update project schema (all fields optional)
export const updateProjectSchema = z.object({
  name: z
    .string()
    .min(3, 'Project name must be at least 3 characters')
    .max(100, 'Project name must be less than 100 characters')
    .optional(),
  description: z
    .string()
    .max(1000, 'Description must be less than 1000 characters')
    .optional()
    .nullable(),
  start_date: z
    .string()
    .refine((date) => !isNaN(Date.parse(date)), 'Invalid start date')
    .optional(),
  end_date: z
    .string()
    .refine((date) => !isNaN(Date.parse(date)), 'Invalid end date')
    .optional()
    .nullable()
    .or(z.literal('')),
  status: projectStatusSchema.optional(),
  is_active: z.boolean().optional(),
}).refine(
  (data) => {
    // If both dates provided, end_date must be after start_date
    if (data.start_date && data.end_date && data.end_date !== '') {
      return new Date(data.end_date) >= new Date(data.start_date)
    }
    return true
  },
  {
    message: 'End date must be after start date',
    path: ['end_date'],
  }
)

// Types inferred from schemas
export type CreateProjectInput = z.infer<typeof createProjectSchema>
export type UpdateProjectInput = z.infer<typeof updateProjectSchema>
EOF

# Verify file created
cat src/lib/validations/project.ts | head -30
```

<details>
<summary>📖 <strong>Why Zod for Validation?</strong></summary>

### What is Zod?

**Zod** is a TypeScript-first schema validation library.

**Without Zod:**
```typescript
// Manual validation (error-prone)
if (!name || name.length < 3) {
  throw new Error('Name too short')
}
if (end_date && new Date(end_date) < new Date(start_date)) {
  throw new Error('Invalid dates')
}
// ... many more checks
```

**With Zod:**
```typescript
// Declarative validation (type-safe)
const schema = z.object({
  name: z.string().min(3),
  start_date: z.string(),
  end_date: z.string(),
}).refine((data) => new Date(data.end_date) >= new Date(data.start_date))

const result = schema.parse(input) // ✅ Valid or throws with helpful error
```

### Benefits

1. **Type Safety:**
   ```typescript
   type CreateProjectInput = z.infer<typeof createProjectSchema>
   // TypeScript automatically knows all fields and types!
   ```

2. **Runtime Validation:**
   - TypeScript only checks at compile time
   - Zod validates actual runtime values
   - Prevents bad data from reaching database

3. **Clear Error Messages:**
   ```typescript
   z.string().min(3, 'Project name must be at least 3 characters')
   // User gets helpful error, not generic "invalid input"
   ```

4. **Complex Validations:**
   ```typescript
   .refine((data) => {
     // Custom logic: end_date must be after start_date
     return new Date(data.end_date) >= new Date(data.start_date)
   }, {
     message: 'End date must be after start date',
     path: ['end_date']  // Error shows on specific field
   })
   ```

5. **Transformations:**
   ```typescript
   z.string().transform((val) => val.trim().toLowerCase())
   // Automatically clean user input
   ```

### Schema Patterns

**Required field:**
```typescript
name: z.string().min(1, 'Required')
```

**Optional field:**
```typescript
description: z.string().optional()
```

**Nullable field:**
```typescript
end_date: z.string().nullable()
```

**Optional OR nullable:**
```typescript
description: z.string().optional().nullable()
```

**Enum (specific values only):**
```typescript
status: z.enum(['active', 'completed'])
```

**Default value:**
```typescript
is_active: z.boolean().default(true)
```

**Date validation:**
```typescript
start_date: z.string().refine(
  (date) => !isNaN(Date.parse(date)),
  'Invalid date format'
)
```

**Cross-field validation:**
```typescript
.refine((data) => {
  return new Date(data.end_date) >= new Date(data.start_date)
}, {
  message: 'End date must be after start date',
  path: ['end_date']
})
```

</details>

---

### 🎯 STEP 4 — Create CRUD Server Actions

Create Server Actions for all CRUD operations on projects.

```bash
cat > src/lib/actions/projects.ts << 'EOF'
'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import {
  createProjectSchema,
  updateProjectSchema,
  type CreateProjectInput,
  type UpdateProjectInput,
} from '@/lib/validations/project'

// Response type for actions
type ActionResponse<T = void> =
  | { success: true; data: T }
  | { success: false; error: string }

/**
 * CREATE: Add a new project
 */
export async function createProject(
  input: CreateProjectInput
): Promise<ActionResponse<{ id: string }>> {
  try {
    // Validate input
    const validated = createProjectSchema.parse(input)

    // Get authenticated user
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized' }
    }

    // Convert empty string to null for end_date
    const end_date = validated.end_date === '' ? null : validated.end_date

    // Insert project
    const { data, error } = await supabase
      .from('prj_projects')
      .insert({
        owner_id: user.id,
        name: validated.name,
        description: validated.description,
        start_date: validated.start_date,
        end_date,
        status: validated.status,
        is_active: validated.is_active,
      })
      .select('id')
      .single()

    if (error) {
      console.error('Create project error:', error)
      return { success: false, error: 'Failed to create project' }
    }

    // Revalidate the projects page
    revalidatePath('/dashboard/projects')

    return { success: true, data: { id: data.id } }
  } catch (error) {
    console.error('Create project error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

/**
 * READ: Get all projects for current user
 */
export async function getProjects(filters?: {
  status?: string
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
      .from('prj_projects')
      .select('*')
      .eq('owner_id', user.id)
      .order('created_at', { ascending: false })

    // Apply filters
    if (filters?.status) {
      query = query.eq('status', filters.status)
    }
    if (filters?.search) {
      query = query.ilike('name', `%${filters.search}%`)
    }

    const { data, error } = await query

    if (error) {
      console.error('Get projects error:', error)
      return { success: false, error: 'Failed to fetch projects', data: null }
    }

    return { success: true, data, error: null }
  } catch (error) {
    console.error('Get projects error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      data: null,
    }
  }
}

/**
 * READ: Get a single project by ID
 */
export async function getProject(id: string) {
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
      .from('prj_projects')
      .select('*')
      .eq('id', id)
      .eq('owner_id', user.id)
      .single()

    if (error) {
      console.error('Get project error:', error)
      return { success: false, error: 'Project not found', data: null }
    }

    return { success: true, data, error: null }
  } catch (error) {
    console.error('Get project error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      data: null,
    }
  }
}

/**
 * UPDATE: Modify an existing project
 */
export async function updateProject(
  id: string,
  input: UpdateProjectInput
): Promise<ActionResponse> {
  try {
    // Validate input
    const validated = updateProjectSchema.parse(input)

    // Get authenticated user
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized' }
    }

    // Convert empty string to null for end_date
    const updateData = {
      ...validated,
      end_date: validated.end_date === '' ? null : validated.end_date,
    }

    // Update project (RLS ensures user can only update their own)
    const { error } = await supabase
      .from('prj_projects')
      .update(updateData)
      .eq('id', id)
      .eq('owner_id', user.id)

    if (error) {
      console.error('Update project error:', error)
      return { success: false, error: 'Failed to update project' }
    }

    // Revalidate relevant pages
    revalidatePath('/dashboard/projects')
    revalidatePath(`/dashboard/projects/${id}`)

    return { success: true, data: undefined }
  } catch (error) {
    console.error('Update project error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

/**
 * DELETE: Remove a project
 */
export async function deleteProject(id: string): Promise<ActionResponse> {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized' }
    }

    // Delete project (RLS ensures user can only delete their own)
    const { error } = await supabase
      .from('prj_projects')
      .delete()
      .eq('id', id)
      .eq('owner_id', user.id)

    if (error) {
      console.error('Delete project error:', error)
      return { success: false, error: 'Failed to delete project' }
    }

    // Revalidate projects page
    revalidatePath('/dashboard/projects')

    return { success: true, data: undefined }
  } catch (error) {
    console.error('Delete project error:', error)
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

/**
 * UPDATE: Toggle project active status
 */
export async function toggleProjectStatus(id: string): Promise<ActionResponse> {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized' }
    }

    // Get current project
    const { data: project, error: fetchError } = await supabase
      .from('prj_projects')
      .select('is_active')
      .eq('id', id)
      .eq('owner_id', user.id)
      .single()

    if (fetchError || !project) {
      return { success: false, error: 'Project not found' }
    }

    // Toggle is_active
    const { error: updateError } = await supabase
      .from('prj_projects')
      .update({ is_active: !project.is_active })
      .eq('id', id)
      .eq('owner_id', user.id)

    if (updateError) {
      console.error('Toggle status error:', updateError)
      return { success: false, error: 'Failed to update status' }
    }

    revalidatePath('/dashboard/projects')
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

# Verify file created
cat src/lib/actions/projects.ts | head -50
```

**Key concepts in Server Actions:**

1. **`'use server'`** - Marks file as Server Actions
2. **Validation** - Zod schemas validate inputs
3. **Authentication** - Check user before operations
4. **RLS** - Database policies filter by owner_id
5. **Revalidation** - `revalidatePath()` refreshes cache
6. **Error Handling** - Try/catch with clear error messages

---

### 🎯 STEP 5 — Create RPC Function for Project Statistics

RPC functions run SQL on the database server for complex analytics.

**Create the RPC function in Supabase SQL Editor:**

```sql
-- Function to get project statistics for a user
CREATE OR REPLACE FUNCTION public.get_project_stats(user_id_input UUID)
RETURNS TABLE(
  total BIGINT,
  active BIGINT,
  on_hold BIGINT,
  completed BIGINT,
  archived BIGINT,
  overdue BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total,
    COUNT(*) FILTER (WHERE status = 'active')::BIGINT AS active,
    COUNT(*) FILTER (WHERE status = 'on_hold')::BIGINT AS on_hold,
    COUNT(*) FILTER (WHERE status = 'completed')::BIGINT AS completed,
    COUNT(*) FILTER (WHERE status = 'archived')::BIGINT AS archived,
    COUNT(*) FILTER (WHERE end_date < CURRENT_DATE AND status NOT IN ('completed', 'archived'))::BIGINT AS overdue
  FROM public.prj_projects
  WHERE owner_id = user_id_input;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_project_stats TO authenticated;
```

**Add Server Action to call RPC function:**

Add this to `src/lib/actions/projects.ts`:

```typescript
/**
 * RPC: Get project statistics
 */
export async function getProjectStats() {
  try {
    const supabase = await createClient()
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: 'Unauthorized', data: null }
    }

    const { data, error } = await supabase.rpc('get_project_stats', {
      user_id_input: user.id,
    })

    if (error) {
      console.error('Get stats error:', error)
      return { success: false, error: 'Failed to fetch statistics', data: null }
    }

    // RPC returns array with single row
    const stats = data?.[0] || {
      total: 0,
      active: 0,
      on_hold: 0,
      completed: 0,
      archived: 0,
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

### 🎯 STEP 6 — Create Project Components

Build UI components for displaying and managing projects.

**Create ProjectCard component:**

```bash
cat > src/components/features/projects/ProjectCard.tsx << 'EOF'
import { Project } from '@/lib/types/database'
import Link from 'next/link'
import { deleteProject, toggleProjectStatus } from '@/lib/actions/projects'
import { useTransition } from 'react'

interface ProjectCardProps {
  project: Project
  onDelete?: () => void
  onUpdate?: () => void
}

export function ProjectCard({ project, onDelete, onUpdate }: ProjectCardProps) {
  const [isPending, startTransition] = useTransition()

  const handleDelete = async () => {
    if (!confirm('Are you sure you want to delete this project? This will also delete all associated tasks and data.')) return

    startTransition(async () => {
      const result = await deleteProject(project.id)
      if (result.success) {
        onDelete?.()
      } else {
        alert(result.error)
      }
    })
  }

  const handleToggleActive = async () => {
    startTransition(async () => {
      const result = await toggleProjectStatus(project.id)
      if (result.success) {
        onUpdate?.()
      } else {
        alert(result.error)
      }
    })
  }

  // Format dates
  const startDate = new Date(project.start_date)
  const endDate = project.end_date ? new Date(project.end_date) : null
  const isOverdue = endDate && endDate < new Date() && project.status !== 'completed' && project.status !== 'archived'

  // Status colors
  const statusColors = {
    active: 'bg-green-100 text-green-800',
    on_hold: 'bg-yellow-100 text-yellow-800',
    completed: 'bg-blue-100 text-blue-800',
    archived: 'bg-gray-100 text-gray-800',
  }

  return (
    <div
      className={`border rounded-lg p-4 hover:shadow-md transition-shadow ${
        isOverdue ? 'border-red-300 bg-red-50' : 'border-gray-200'
      } ${!project.is_active ? 'opacity-60' : ''}`}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-2">
            <span
              className={`px-3 py-1 rounded-full text-xs font-medium ${
                statusColors[project.status]
              }`}
            >
              {project.status.replace('_', ' ')}
            </span>
            {!project.is_active && (
              <span className="px-2 py-1 rounded bg-gray-200 text-gray-600 text-xs font-medium">
                Inactive
              </span>
            )}
            {isOverdue && (
              <span className="px-2 py-1 rounded bg-red-200 text-red-800 text-xs font-medium">
                Overdue
              </span>
            )}
          </div>

          <Link
            href={`/dashboard/projects/${project.id}`}
            className="block group"
          >
            <h3 className="font-semibold text-gray-900 group-hover:text-blue-600 transition-colors">
              {project.name}
            </h3>
            {project.description && (
              <p className="text-sm text-gray-600 mt-1 line-clamp-2">
                {project.description}
              </p>
            )}
          </Link>

          <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
            <span>Start: {startDate.toLocaleDateString()}</span>
            {endDate && (
              <span className={isOverdue ? 'text-red-600 font-medium' : ''}>
                End: {endDate.toLocaleDateString()}
              </span>
            )}
          </div>
        </div>

        <div className="flex flex-col gap-2">
          <Link
            href={`/dashboard/projects/${project.id}/edit`}
            className="text-blue-600 hover:text-blue-800 text-sm font-medium"
          >
            Edit
          </Link>
          <button
            onClick={handleToggleActive}
            disabled={isPending}
            className="text-gray-600 hover:text-gray-800 text-sm font-medium disabled:opacity-50"
          >
            {project.is_active ? 'Deactivate' : 'Activate'}
          </button>
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

# Verify file created
cat src/components/features/projects/ProjectCard.tsx | head -30
```

**Create ProjectList component:**

```bash
cat > src/components/features/projects/ProjectList.tsx << 'EOF'
'use client'

import { Project } from '@/lib/types/database'
import { ProjectCard } from './ProjectCard'
import { useState } from 'react'

interface ProjectListProps {
  initialProjects: Project[]
}

export function ProjectList({ initialProjects }: ProjectListProps) {
  const [projects, setProjects] = useState(initialProjects)

  const handleProjectDeleted = (deletedId: string) => {
    setProjects((prev) => prev.filter((project) => project.id !== deletedId))
  }

  const handleProjectUpdated = () => {
    // Rely on revalidation to update the list
  }

  if (projects.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500 text-lg">No projects yet</p>
        <p className="text-gray-400 text-sm mt-2">
          Create your first project to get started!
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {projects.map((project) => (
        <ProjectCard
          key={project.id}
          project={project}
          onDelete={() => handleProjectDeleted(project.id)}
          onUpdate={handleProjectUpdated}
        />
      ))}
    </div>
  )
}
EOF

# Verify file created
cat src/components/features/projects/ProjectList.tsx
```

**Create ProjectForm component:**

```bash
cat > src/components/features/projects/ProjectForm.tsx << 'EOF'
'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { createProject, updateProject } from '@/lib/actions/projects'
import { Project } from '@/lib/types/database'

interface ProjectFormProps {
  project?: Project
  mode: 'create' | 'edit'
}

export function ProjectForm({ project, mode }: ProjectFormProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  const [formData, setFormData] = useState({
    name: project?.name || '',
    description: project?.description || '',
    start_date: project?.start_date || new Date().toISOString().split('T')[0],
    end_date: project?.end_date || '',
    status: project?.status || 'active',
    is_active: project?.is_active ?? true,
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    startTransition(async () => {
      if (mode === 'create') {
        const result = await createProject(formData)
        if (result.success) {
          router.push('/dashboard/projects')
          router.refresh()
        } else {
          setError(result.error)
        }
      } else if (project) {
        const result = await updateProject(project.id, formData)
        if (result.success) {
          router.push(`/dashboard/projects/${project.id}`)
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
          htmlFor="name"
          className="block text-sm font-medium text-gray-700 mb-1"
        >
          Project Name *
        </label>
        <input
          type="text"
          id="name"
          required
          maxLength={100}
          value={formData.name}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, name: e.target.value }))
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          placeholder="Enter project name"
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
          maxLength={1000}
          value={formData.description}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, description: e.target.value }))
          }
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          placeholder="Add project description"
        />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label
            htmlFor="start_date"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            Start Date *
          </label>
          <input
            type="date"
            id="start_date"
            required
            value={formData.start_date}
            onChange={(e) =>
              setFormData((prev) => ({ ...prev, start_date: e.target.value }))
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div>
          <label
            htmlFor="end_date"
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            End Date
          </label>
          <input
            type="date"
            id="end_date"
            value={formData.end_date}
            onChange={(e) =>
              setFormData((prev) => ({ ...prev, end_date: e.target.value }))
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
                status: e.target.value as Project['status'],
              }))
            }
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="active">Active</option>
            <option value="on_hold">On Hold</option>
            <option value="completed">Completed</option>
            <option value="archived">Archived</option>
          </select>
        </div>

        <div className="flex items-center">
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={formData.is_active}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, is_active: e.target.checked }))
              }
              className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="text-sm font-medium text-gray-700">
              Active Project
            </span>
          </label>
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
              ? 'Create Project'
              : 'Update Project'}
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

# Verify file created
cat src/components/features/projects/ProjectForm.tsx | head -50
```

**Create ProjectStats component:**

```bash
cat > src/components/features/projects/ProjectStats.tsx << 'EOF'
interface ProjectStatsProps {
  stats: {
    total: number
    active: number
    on_hold: number
    completed: number
    archived: number
    overdue: number
  }
}

export function ProjectStats({ stats }: ProjectStatsProps) {
  const completionRate =
    stats.total > 0 ? Math.round((stats.completed / stats.total) * 100) : 0

  return (
    <div className="grid grid-cols-2 md:grid-cols-6 gap-4">
      <StatCard label="Total" value={stats.total} color="gray" />
      <StatCard label="Active" value={stats.active} color="green" />
      <StatCard label="On Hold" value={stats.on_hold} color="yellow" />
      <StatCard label="Completed" value={stats.completed} color="blue" />
      <StatCard label="Archived" value={stats.archived} color="gray" />
      <StatCard
        label="Overdue"
        value={stats.overdue}
        color="red"
        highlight={stats.overdue > 0}
      />

      <div className="col-span-2 md:col-span-6 p-4 bg-gray-50 rounded-lg border border-gray-200">
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
            className="bg-blue-600 h-2 rounded-full transition-all duration-300"
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
  color: 'gray' | 'green' | 'yellow' | 'blue' | 'red'
  highlight?: boolean
}

function StatCard({ label, value, color, highlight }: StatCardProps) {
  const colorClasses = {
    gray: 'bg-gray-50 border-gray-200 text-gray-900',
    green: 'bg-green-50 border-green-200 text-green-900',
    yellow: 'bg-yellow-50 border-yellow-200 text-yellow-900',
    blue: 'bg-blue-50 border-blue-200 text-blue-900',
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

# Verify file created
cat src/components/features/projects/ProjectStats.tsx
```

---

### 🎯 STEP 7 — Create Project Pages

Create the pages to display and manage projects.

**Create projects list page:**

```bash
cat > src/app/dashboard/projects/page.tsx << 'EOF'
import Link from 'next/link'
import { getProjects, getProjectStats } from '@/lib/actions/projects'
import { ProjectList } from '@/components/features/projects/ProjectList'
import { ProjectStats } from '@/components/features/projects/ProjectStats'
import { redirect } from 'next/navigation'

export const dynamic = 'force-dynamic'

export default async function ProjectsPage() {
  const [projectsResult, statsResult] = await Promise.all([
    getProjects(),
    getProjectStats(),
  ])

  // Redirect to login if not authenticated
  if (!projectsResult.success || !statsResult.success) {
    redirect('/login')
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">My Projects</h1>
          <p className="text-gray-600 mt-1">
            Manage your projects and track progress
          </p>
        </div>
        <Link
          href="/dashboard/projects/new"
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          + New Project
        </Link>
      </div>

      {statsResult.data && (
        <div className="mb-8">
          <ProjectStats stats={statsResult.data} />
        </div>
      )}

      <ProjectList initialProjects={projectsResult.data || []} />
    </div>
  )
}
EOF

# Verify file created
cat src/app/dashboard/projects/page.tsx
```

**Create new project page:**

```bash
cat > src/app/dashboard/projects/new/page.tsx << 'EOF'
import { ProjectForm } from '@/components/features/projects/ProjectForm'

export default function NewProjectPage() {
  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">Create New Project</h1>
      <ProjectForm mode="create" />
    </div>
  )
}
EOF

# Verify file created
cat src/app/dashboard/projects/new/page.tsx
```

**Create view project page:**

```bash
cat > src/app/dashboard/projects/[id]/page.tsx << 'EOF'
import { getProject } from '@/lib/actions/projects'
import { notFound } from 'next/navigation'
import Link from 'next/link'

export const dynamic = 'force-dynamic'

export default async function ProjectPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const result = await getProject(id)

  if (!result.success || !result.data) {
    notFound()
  }

  const project = result.data
  const startDate = new Date(project.start_date)
  const endDate = project.end_date ? new Date(project.end_date) : null
  const isOverdue = endDate && endDate < new Date() && project.status !== 'completed' && project.status !== 'archived'

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="mb-6">
        <Link
          href="/dashboard/projects"
          className="text-blue-600 hover:text-blue-800 text-sm"
        >
          ← Back to projects
        </Link>
      </div>

      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <div className="flex items-start justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">{project.name}</h1>
            <div className="flex items-center gap-2 mt-2">
              <span
                className={`px-3 py-1 rounded-full text-sm font-medium ${
                  project.status === 'completed'
                    ? 'bg-blue-100 text-blue-800'
                    : project.status === 'active'
                      ? 'bg-green-100 text-green-800'
                      : project.status === 'on_hold'
                        ? 'bg-yellow-100 text-yellow-800'
                        : 'bg-gray-100 text-gray-800'
                }`}
              >
                {project.status.replace('_', ' ')}
              </span>
              {!project.is_active && (
                <span className="px-3 py-1 rounded bg-gray-200 text-gray-600 text-sm font-medium">
                  Inactive
                </span>
              )}
              {isOverdue && (
                <span className="px-3 py-1 rounded bg-red-200 text-red-800 text-sm font-medium">
                  Overdue
                </span>
              )}
            </div>
          </div>
          <Link
            href={`/dashboard/projects/${id}/edit`}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Edit
          </Link>
        </div>

        <div className="space-y-4">
          {project.description && (
            <div>
              <h2 className="text-sm font-medium text-gray-600 mb-2">
                Description
              </h2>
              <p className="text-gray-900 whitespace-pre-wrap">
                {project.description}
              </p>
            </div>
          )}

          <div className="grid grid-cols-2 gap-4 pt-4 border-t">
            <div>
              <h3 className="text-sm font-medium text-gray-600">Start Date</h3>
              <p className="text-gray-900 mt-1">
                {startDate.toLocaleDateString()}
              </p>
            </div>
            {endDate && (
              <div>
                <h3 className="text-sm font-medium text-gray-600">End Date</h3>
                <p className={`mt-1 ${isOverdue ? 'text-red-600 font-medium' : 'text-gray-900'}`}>
                  {endDate.toLocaleDateString()}
                  {isOverdue && ' (Overdue)'}
                </p>
              </div>
            )}
            <div>
              <h3 className="text-sm font-medium text-gray-600">Created</h3>
              <p className="text-gray-900 mt-1">
                {new Date(project.created_at).toLocaleString()}
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-600">
                Last Updated
              </h3>
              <p className="text-gray-900 mt-1">
                {new Date(project.updated_at).toLocaleString()}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# Verify file created
cat src/app/dashboard/projects/[id]/page.tsx
```

**Create edit project page:**

```bash
cat > src/app/dashboard/projects/[id]/edit/page.tsx << 'EOF'
import { getProject } from '@/lib/actions/projects'
import { notFound } from 'next/navigation'
import { ProjectForm } from '@/components/features/projects/ProjectForm'

export const dynamic = 'force-dynamic'

export default async function EditProjectPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const result = await getProject(id)

  if (!result.success || !result.data) {
    notFound()
  }

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">Edit Project</h1>
      <ProjectForm project={result.data} mode="edit" />
    </div>
  )
}
EOF

# Verify file created
cat src/app/dashboard/projects/[id]/edit/page.tsx
```

**Update dashboard to link to projects:**

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
          href="/dashboard/projects"
          className="block p-6 bg-white border-2 border-gray-200 rounded-lg hover:border-blue-500 hover:shadow-md transition-all"
        >
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            📂 My Projects
          </h2>
          <p className="text-gray-600">
            Create and manage your projects, track progress, and collaborate with your team.
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

# Verify file created
cat src/app/dashboard/page.tsx
```

---

## 🎓 3. REVIEW

### What You Learned

In this lesson, you built a complete project management system with:

1. **Row Level Security (RLS)**
   - Added `owner_id` column to prj_projects
   - Created policies for SELECT, INSERT, UPDATE, DELETE
   - Users can only access their own projects

2. **Type Safety**
   - Created TypeScript types for database schema
   - Used Zod for runtime validation
   - Type-safe Server Actions

3. **Server Actions**
   - `createProject` - Create new projects
   - `getProjects` - List projects with filters
   - `getProject` - View single project
   - `updateProject` - Edit projects
   - `deleteProject` - Delete projects
   - `toggleProjectStatus` - Quick active/inactive toggle

4. **RPC Functions**
   - `get_project_stats` - Project analytics
   - Server-side aggregation for performance
   - Statistics dashboard

5. **UI Components**
   - ProjectCard - Individual project display
   - ProjectList - Projects listing
   - ProjectForm - Reusable create/edit form
   - ProjectStats - Analytics dashboard

6. **Pages & Routing**
   - `/dashboard/projects` - List all projects
   - `/dashboard/projects/new` - Create project
   - `/dashboard/projects/[id]` - View project
   - `/dashboard/projects/[id]/edit` - Edit project

### Key Concepts

**Server Actions:**
- Run on server, not client
- Type-safe with TypeScript
- Automatic CSRF protection
- No API routes needed

**Row Level Security:**
- Database-level security
- Automatically filters queries
- Prevents unauthorized access

**Zod Validation:**
- Runtime type checking
- Clear error messages
- Type inference for TypeScript

**Revalidation:**
- `revalidatePath()` refreshes cache
- Shows latest data after mutations

### Best Practices Applied

✅ **Validation** - Zod schemas on all inputs
✅ **Security** - RLS policies enforce ownership
✅ **Error Handling** - Clear error messages
✅ **Type Safety** - Full TypeScript coverage
✅ **Performance** - RPC for complex queries
✅ **UX** - Loading states and feedback

### Testing Your Implementation

1. **Create a project:**
   - Go to `/dashboard/projects/new`
   - Fill form and submit
   - Verify redirect to projects list

2. **View projects:**
   - Check project appears in list
   - Verify stats are correct
   - Click project to view details

3. **Edit a project:**
   - Click "Edit" on a project
   - Modify fields and save
   - Verify changes persist

4. **Delete a project:**
   - Click "Delete" on a project
   - Confirm deletion
   - Verify project removed

5. **Toggle active status:**
   - Click "Deactivate" on a project
   - Verify status changes
   - Project appears inactive

6. **Test RLS:**
   - Create projects as one user
   - Log out and login as different user
   - Verify you can't see other user's projects

### Common Issues & Solutions

**Issue: "Unauthorized" errors**
- Ensure user is logged in
- Check RLS policies are created
- Verify `owner_id` is being set correctly

**Issue: "Failed to create project"**
- Check Supabase logs in dashboard
- Verify RLS policies allow INSERT
- Ensure all required fields provided

**Issue: Data not refreshing**
- Check `revalidatePath()` is called
- Verify page has `export const dynamic = 'force-dynamic'`

### Next Steps

**Lesson 5** will cover:
- Task management (using `prj_tasks` table)
- Project members (using `prj_project_members` table)
- Real-time updates with Supabase subscriptions
- Advanced filtering and search

**Continue Learning:**
- Explore [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- Learn about [Next.js Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)

---

**Congratulations!** 🎉 You now have a fully functional project management system with CRUD operations, authentication, and security!
