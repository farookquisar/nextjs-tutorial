# 🔧 Reusable Features Reference

**Version:** Module 1, Lessons 1-3
**Last Updated:** 2025-11-19
**Purpose:** Copy-paste ready code patterns and configurations for other projects

> **💡 Tip:** This document grows with each lesson. Use Ctrl+F to find specific features.

---

## 📑 Table of Contents

### Next.js 16 Features
1. [Cache Components Configuration](#1-cache-components-configuration)
2. [Custom Cache Profiles](#2-custom-cache-profiles)
3. [Import Alias (@/) Configuration](#3-import-alias-configuration)
4. [Proxy.ts for Session Refresh](#4-proxyts-for-session-refresh)

### Code Organization Patterns
5. [Constants Pattern (DRY Principle)](#5-constants-pattern-dry-principle)
6. [TypeScript Types Organization](#6-typescript-types-organization)
7. [Folder Structure (SOLID Principles)](#7-folder-structure-solid-principles)

### Supabase Integration
8. [Environment Variables Setup](#8-environment-variables-setup)
9. [Browser Client (Client Components)](#9-browser-client-client-components)
10. [Server Client (Server Components)](#10-server-client-server-components)
11. [Middleware Helper for Session Refresh](#11-middleware-helper-for-session-refresh)
12. [Database Schema with RLS](#12-database-schema-with-rls)
13. [RPC Functions Pattern](#13-rpc-functions-pattern)
14. [Database TypeScript Types](#14-database-typescript-types)

### Security Patterns
15. [Row Level Security (RLS) Policies](#15-row-level-security-rls-policies)
16. [Role-Based Permissions](#16-role-based-permissions)
17. [Protected Route Helpers](#17-protected-route-helpers)

### Development Best Practices
18. [UUID vs Auto-increment IDs](#18-uuid-vs-auto-increment-ids)
19. [Database Triggers for Updated_at](#19-database-triggers-for-updated_at)
20. [Migration File Naming](#20-migration-file-naming)

### UI Components (Lesson 3)
21. [Reusable Button Component](#21-reusable-button-component)
22. [Reusable Input Component](#22-reusable-input-component)
23. [Reusable Select Component](#23-reusable-select-component)
24. [Reusable Dropdown Component](#24-reusable-dropdown-component)
25. [Reusable Modal Component](#25-reusable-modal-component)

---

## Next.js 16 Features

### 1. Cache Components Configuration

**What:** Enable Next.js 16's Cache Components feature for optimized rendering.

**When to use:** All new Next.js 16 projects for better performance.

**File:** `next.config.ts`

```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Enable Cache Components (Next.js 16+)
  cacheComponents: true,

  // Define custom cache profiles
  cacheLife: {
    weekly: {
      stale: 60 * 60 * 24 * 7,      // 7 days
      revalidate: 60 * 60 * 24 * 7,  // 7 days
      expire: 60 * 60 * 24 * 7,      // 7 days
    },
    daily: {
      stale: 60 * 60 * 24,           // 1 day
      revalidate: 60 * 60 * 24,      // 1 day
      expire: 60 * 60 * 24,          // 1 day
    },
  },
};

export default nextConfig;
```

**Benefits:**
- ✅ Automatic component-level caching
- ✅ Custom cache lifetimes
- ✅ Better performance
- ✅ Replaces old PPR configuration

---

### 2. Custom Cache Profiles

**What:** Use custom cache profiles in your Server Components.

**When to use:** Data that doesn't change frequently (blog posts, product catalogs).

**Usage in components:**

```typescript
// app/blog/page.tsx
export const dynamic = 'force-cache'
export const cacheLife = 'weekly'  // Uses profile from next.config.ts

export default async function BlogPage() {
  const posts = await fetchBlogPosts()
  return <div>{/* Cached for 1 week */}</div>
}
```

**Available profiles:**
- `weekly` - Cache for 7 days
- `daily` - Cache for 1 day
- Custom - Add your own in `next.config.ts`

---

### 3. Import Alias (@/) Configuration

**What:** Use `@/` instead of relative paths (`../../`).

**When to use:** All projects for cleaner imports.

**File:** `tsconfig.json`

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

**Before:**
```typescript
import { DB_TABLES } from '../../../constants'
import { createClient } from '../../lib/supabase/client'
```

**After:**
```typescript
import { DB_TABLES } from '@/constants'
import { createClient } from '@/lib/supabase/client'
```

**Benefits:**
- ✅ No more `../../../` confusion
- ✅ Easier refactoring (move files without updating imports)
- ✅ Cleaner code

---

### 4. Proxy.ts for Session Refresh

**What:** Next.js 16 proxy (replaces middleware.ts) for automatic session refresh.

**When to use:** All projects with authentication.

**File:** `proxy.ts` (at project root)

```typescript
import { type NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

/**
 * Next.js 16 Proxy - Automatic session refresh
 */
export async function proxy(request: NextRequest) {
  return await updateSession(request)
}

/**
 * Matcher: Run on all routes except static files
 */
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

**Migration from middleware.ts:**
```bash
# Rename file
mv middleware.ts proxy.ts

# Update function name
# Old: export function middleware(request)
# New: export function proxy(request)
```

**Benefits:**
- ✅ Node.js runtime (more predictable than Edge)
- ✅ Automatic session refresh
- ✅ Clearer naming
- ✅ Works with Supabase auth

---

## Code Organization Patterns

### 5. Constants Pattern (DRY Principle)

**What:** Centralize all magic strings and numbers in one file.

**When to use:** All projects to avoid scattered hardcoded values.

**File:** `src/constants/index.ts`

```typescript
// Database table names
export const DB_TABLES = {
  PROJECTS: 'prj_projects',
  TASKS: 'prj_tasks',
  USERS: 'users',
} as const

// Cache tags for revalidation
export const CACHE_TAGS = {
  PROJECTS: 'projects',
  TASKS: 'tasks',
} as const

// Route paths
export const ROUTES = {
  HOME: '/',
  DASHBOARD: '/dashboard',
  LOGIN: '/login',
  SIGNUP: '/signup',
} as const

// Status enums
export const PROJECT_STATUS = {
  ACTIVE: 'active',
  ON_HOLD: 'on_hold',
  COMPLETED: 'completed',
  ARCHIVED: 'archived',
} as const

export const TASK_STATUS = {
  TODO: 'todo',
  IN_PROGRESS: 'in_progress',
  IN_REVIEW: 'in_review',
  DONE: 'done',
} as const

// Validation rules
export const VALIDATION = {
  PROJECT_NAME_MIN_LENGTH: 3,
  PROJECT_NAME_MAX_LENGTH: 100,
  TASK_TITLE_MIN_LENGTH: 3,
  TASK_TITLE_MAX_LENGTH: 200,
  PASSWORD_MIN_LENGTH: 8,
} as const

// Extract types from constants
export type ProjectStatus = typeof PROJECT_STATUS[keyof typeof PROJECT_STATUS]
export type TaskStatus = typeof TASK_STATUS[keyof typeof TASK_STATUS]
```

**Usage:**
```typescript
import { DB_TABLES, PROJECT_STATUS, VALIDATION } from '@/constants'

// ✅ Good - using constants
const projects = await supabase
  .from(DB_TABLES.PROJECTS)
  .select('*')
  .eq('status', PROJECT_STATUS.ACTIVE)

// ❌ Bad - magic strings
const projects = await supabase
  .from('prj_projects')
  .select('*')
  .eq('status', 'active')
```

**Benefits:**
- ✅ Change once, update everywhere
- ✅ No typos
- ✅ Autocomplete everywhere
- ✅ Type safety

---

### 6. TypeScript Types Organization

**What:** Separate file for all TypeScript interfaces and types.

**When to use:** All TypeScript projects.

**File:** `src/types/index.ts`

```typescript
import { TaskStatus, ProjectStatus } from '@/constants'

// Domain entities
export interface Project {
  id: string
  name: string
  description: string | null
  start_date: string
  end_date: string | null
  is_active: boolean
  status: ProjectStatus
  created_at: string
  updated_at: string
}

export interface Task {
  id: string
  project_id: string
  title: string
  description: string | null
  status: TaskStatus
  due_date: string | null
  assigned_to: string | null
  created_by: string
  created_at: string
  updated_at: string
}

// Form input types (client-side)
export interface CreateProjectInput {
  name: string
  description: string
  start_date: string
  end_date: string
}

export interface UpdateProjectInput {
  name?: string
  description?: string
  end_date?: string
  is_active?: boolean
  status?: ProjectStatus
}

// API response types
export interface ApiResponse<T> {
  data: T | null
  error: string | null
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
}
```

**Benefits:**
- ✅ Single source of truth for types
- ✅ Reusable across components
- ✅ Easy to maintain
- ✅ Consistent naming

---

### 7. Folder Structure (SOLID Principles)

**What:** Organized folder structure following Single Responsibility Principle.

**When to use:** All projects for maintainability.

**Structure:**

```
src/
├── app/                    # Next.js App Router pages
│   ├── (auth)/            # Route group for auth pages
│   │   ├── login/
│   │   └── signup/
│   ├── (dashboard)/       # Route group for protected pages
│   │   ├── projects/
│   │   └── tasks/
│   ├── layout.tsx         # Root layout
│   ├── page.tsx           # Home page
│   └── globals.css        # Global styles
│
├── components/            # Reusable components
│   ├── ui/               # Generic UI components
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   └── Card.tsx
│   ├── projects/         # Project-specific components
│   │   ├── ProjectCard.tsx
│   │   └── ProjectForm.tsx
│   └── layout/           # Layout components
│       ├── Header.tsx
│       └── Sidebar.tsx
│
├── lib/                  # Utilities and integrations
│   ├── supabase/        # Supabase clients
│   │   ├── client.ts
│   │   ├── server.ts
│   │   ├── middleware.ts
│   │   └── rpc-examples.ts
│   └── utils/           # Helper functions
│       ├── date.ts
│       └── validation.ts
│
├── constants/           # Constants and enums
│   └── index.ts
│
├── types/              # TypeScript types
│   ├── index.ts
│   └── database.ts
│
└── hooks/              # Custom React hooks (coming in Lesson 3)
    └── useAuth.ts
```

**Benefits:**
- ✅ Easy to find files
- ✅ Clear separation of concerns
- ✅ Scalable structure
- ✅ Team-friendly

---

## Supabase Integration

### 8. Environment Variables Setup

**What:** Secure environment variables for Supabase.

**When to use:** All Supabase projects.

**File:** `.env.local`

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=your-publishable-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# App Configuration
NEXT_PUBLIC_APP_NAME=Your App Name
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

**File:** `.env.local.example` (commit this to git)

```bash
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=your-publishable-default-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# App Configuration
NEXT_PUBLIC_APP_NAME=Project Management App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

**File:** `.gitignore` (ensure this exists)

```
# Environment variables
.env*.local
.env
```

**Security rules:**
- ✅ `NEXT_PUBLIC_*` - Safe to expose in browser
- ❌ `SUPABASE_SERVICE_ROLE_KEY` - NEVER use in client code
- ✅ `.env.local` - NEVER commit to git
- ✅ `.env.local.example` - Commit as template

---

### 9. Browser Client (Client Components)

**What:** Supabase client for Client Components.

**When to use:** Forms, interactive UI, client-side mutations.

**File:** `src/lib/supabase/client.ts`

```typescript
import { createBrowserClient } from '@supabase/ssr'
import { Database } from '@/types/database'

/**
 * Supabase client for browser (Client Components)
 *
 * Use in components with 'use client' directive
 */
export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!
  )
}
```

**Usage:**

```typescript
'use client'

import { createClient } from '@/lib/supabase/client'
import { useState } from 'react'

export function CreateProjectForm() {
  const [name, setName] = useState('')
  const supabase = createClient()

  async function handleSubmit() {
    const { data, error } = await supabase
      .from('prj_projects')
      .insert({ name })

    if (error) console.error(error)
    else console.log('Created:', data)
  }

  return <form onSubmit={handleSubmit}>...</form>
}
```

---

### 10. Server Client (Server Components)

**What:** Supabase client for Server Components.

**When to use:** Initial data fetching, Server Actions, API routes.

**File:** `src/lib/supabase/server.ts`

```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { Database } from '@/types/database'

/**
 * Supabase client for server (Server Components, Server Actions)
 *
 * Handles cookies automatically for SSR
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // The `setAll` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
      },
    }
  )
}
```

**Usage:**

```typescript
// app/projects/page.tsx
import { createClient } from '@/lib/supabase/server'

export default async function ProjectsPage() {
  const supabase = await createClient()

  const { data: projects } = await supabase
    .from('prj_projects')
    .select('*')

  return (
    <div>
      {projects?.map(project => (
        <div key={project.id}>{project.name}</div>
      ))}
    </div>
  )
}
```

---

### 11. Middleware Helper for Session Refresh

**What:** Helper function to refresh Supabase sessions automatically.

**When to use:** All projects with authentication.

**File:** `src/lib/supabase/middleware.ts`

```typescript
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

/**
 * Updates and refreshes Supabase session
 *
 * Call this from proxy.ts to keep users logged in
 */
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // Refresh session if expired
  const { data: { user } } = await supabase.auth.getUser()

  // Add user info to headers (optional)
  if (user) {
    supabaseResponse.headers.set('x-user-id', user.id)
    supabaseResponse.headers.set('x-user-email', user.email || '')
  }

  return supabaseResponse
}

/**
 * Check if route requires authentication
 */
export function isProtectedRoute(pathname: string): boolean {
  const protectedPaths = ['/dashboard', '/projects', '/profile', '/settings']
  return protectedPaths.some(path => pathname.startsWith(path))
}

/**
 * Check if route is public-only (redirect if authenticated)
 */
export function isPublicOnlyRoute(pathname: string): boolean {
  const publicOnlyPaths = ['/login', '/signup', '/forgot-password']
  return publicOnlyPaths.some(path => pathname.startsWith(path))
}
```

**Usage in proxy.ts:**

```typescript
import { updateSession, isProtectedRoute } from '@/lib/supabase/middleware'

export async function proxy(request: NextRequest) {
  const response = await updateSession(request)

  // Optional: Redirect unauthenticated users from protected routes
  if (isProtectedRoute(request.nextUrl.pathname) && !response.headers.get('x-user-id')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return response
}
```

---

### 12. Database Schema with RLS

**What:** PostgreSQL schema with Row Level Security.

**When to use:** All Supabase projects for security.

**File:** `supabase/migrations/001_initial_schema.sql`

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Projects table
CREATE TABLE prj_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),

  CONSTRAINT prj_projects_name_length CHECK (char_length(name) >= 3),
  CONSTRAINT prj_projects_status_check CHECK (status IN ('active', 'on_hold', 'completed', 'archived'))
);

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_prj_projects_updated_at
  BEFORE UPDATE ON prj_projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Indexes
CREATE INDEX idx_prj_projects_status ON prj_projects(status);
CREATE INDEX idx_prj_projects_is_active ON prj_projects(is_active);
```

**Key patterns:**
- ✅ UUID primary keys (better for distributed systems)
- ✅ `created_at` and `updated_at` timestamps
- ✅ Triggers for auto-updating `updated_at`
- ✅ Constraints for data validation
- ✅ Indexes for performance

---

### 13. RPC Functions Pattern

**What:** PostgreSQL functions for type-safe, secure data access.

**When to use:** Complex queries, joins, business logic.

**File:** `supabase/migrations/003_rpc_functions.sql`

```sql
-- Get user's projects with role
CREATE OR REPLACE FUNCTION get_user_projects()
RETURNS TABLE (
  id UUID,
  name VARCHAR(100),
  description TEXT,
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN,
  status VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  user_role VARCHAR(20)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.description,
    p.start_date,
    p.end_date,
    p.is_active,
    p.status,
    p.created_at,
    p.updated_at,
    pm.role as user_role
  FROM prj_projects p
  INNER JOIN prj_project_members pm ON p.id = pm.project_id
  WHERE pm.user_id = auth.uid()
  ORDER BY p.created_at DESC;
END;
$$;

-- Create project (atomic transaction)
CREATE OR REPLACE FUNCTION create_project(
  project_name VARCHAR(100),
  project_description TEXT,
  project_start_date DATE,
  project_end_date DATE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_project_id UUID;
BEGIN
  -- Insert project
  INSERT INTO prj_projects (name, description, start_date, end_date)
  VALUES (project_name, project_description, project_start_date, project_end_date)
  RETURNING id INTO new_project_id;

  -- Add creator as owner
  INSERT INTO prj_project_members (project_id, user_id, role)
  VALUES (new_project_id, auth.uid(), 'owner');

  RETURN new_project_id;
END;
$$;
```

**Usage in TypeScript:**

```typescript
// Get projects
const { data: projects } = await supabase.rpc('get_user_projects')

// Create project
const { data: projectId } = await supabase.rpc('create_project', {
  project_name: 'My Project',
  project_description: 'Project description',
  project_start_date: '2025-01-01',
  project_end_date: '2025-12-31',
})
```

**Benefits:**
- ✅ Single database call (no N+1 queries)
- ✅ Atomic transactions
- ✅ Type-safe with TypeScript
- ✅ Security: SECURITY DEFINER bypasses RLS safely
- ✅ Business logic in one place

---

### 14. Database TypeScript Types

**What:** Auto-generated types from Supabase schema.

**When to use:** All Supabase projects for type safety.

**File:** `src/types/database.ts`

```typescript
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
          name: string
          description: string | null
          start_date: string
          end_date: string | null
          is_active: boolean
          status: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string | null
          start_date: string
          end_date?: string | null
          is_active?: boolean
          status?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string | null
          start_date?: string
          end_date?: string | null
          is_active?: boolean
          status?: string
          created_at?: string
          updated_at?: string
        }
      }
    }
    Functions: {
      get_user_projects: {
        Args: Record<string, never>
        Returns: Array<{
          id: string
          name: string
          description: string | null
          user_role: string
          // ... other fields
        }>
      }
    }
  }
}
```

**Auto-generation (recommended):**

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Generate types
supabase gen types typescript --project-id YOUR_PROJECT_ID > src/types/database.ts
```

**Usage:**

```typescript
import { createClient } from '@/lib/supabase/client'
import { Database } from '@/types/database'

const supabase = createClient<Database>()

// TypeScript knows exact table structure
const { data } = await supabase
  .from('prj_projects')  // ✅ Autocomplete
  .select('name, description')  // ✅ Type-checked

// data has correct types!
```

---

## Security Patterns

### 15. Row Level Security (RLS) Policies

**What:** Database-level security that cannot be bypassed.

**When to use:** All tables with user data.

**File:** `supabase/migrations/002_rls_policies.sql`

```sql
-- Enable RLS
ALTER TABLE prj_projects ENABLE ROW LEVEL SECURITY;

-- Users can view their projects
CREATE POLICY "Users can view their projects"
  ON prj_projects FOR SELECT
  USING (
    id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can create projects
CREATE POLICY "Users can create projects"
  ON prj_projects FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Only owners can update
CREATE POLICY "Owners can update projects"
  ON prj_projects FOR UPDATE
  USING (
    id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role = 'owner'
    )
  );

-- Only owners can delete
CREATE POLICY "Only owners can delete projects"
  ON prj_projects FOR DELETE
  USING (
    id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role = 'owner'
    )
  );
```

**Benefits:**
- ✅ Security enforced at database level
- ✅ Cannot be bypassed from client
- ✅ Works with direct queries and RPC
- ✅ Works with real-time subscriptions

---

### 16. Role-Based Permissions

**What:** Different permissions for different user roles.

**When to use:** Multi-tenant apps, team collaboration tools.

**Pattern:**

```sql
-- Member roles table
CREATE TABLE prj_project_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES prj_projects(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(20) DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),

  CONSTRAINT prj_project_members_role_check CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  UNIQUE(project_id, user_id)
);

-- RLS based on roles
CREATE POLICY "Admins and owners can manage members"
  ON prj_project_members FOR ALL
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );
```

**Role hierarchy:**
- **Owner** - Full control, can delete project
- **Admin** - Can manage members, tasks, payments
- **Member** - Can create/edit tasks
- **Viewer** - Read-only access

---

### 17. Protected Route Helpers

**What:** Helper functions to check route protection.

**When to use:** Apps with authentication.

**Already included in:** `src/lib/supabase/middleware.ts` (see #11)

**Usage in proxy.ts:**

```typescript
import { updateSession, isProtectedRoute, isPublicOnlyRoute } from '@/lib/supabase/middleware'
import { NextResponse } from 'next/server'

export async function proxy(request: NextRequest) {
  const response = await updateSession(request)
  const userId = response.headers.get('x-user-id')

  // Redirect to login if accessing protected route while logged out
  if (isProtectedRoute(request.nextUrl.pathname) && !userId) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // Redirect to dashboard if accessing login while logged in
  if (isPublicOnlyRoute(request.nextUrl.pathname) && userId) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return response
}
```

---

## Development Best Practices

### 18. UUID vs Auto-increment IDs

**What:** Use UUID for primary keys instead of auto-increment integers.

**When to use:** Distributed systems, multi-region apps, APIs.

**Pattern:**

```sql
-- ✅ Good - UUID
CREATE TABLE prj_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- ...
);

-- ❌ Avoid - Auto-increment (unless single-server)
CREATE TABLE projects (
  id SERIAL PRIMARY KEY,
  -- ...
);
```

**Benefits of UUID:**
- ✅ Globally unique (no conflicts in distributed systems)
- ✅ Can generate client-side
- ✅ No sequential predictability (security)
- ✅ Merge databases easily

**Drawbacks:**
- ❌ Larger storage (16 bytes vs 4 bytes)
- ❌ Harder to read/debug

---

### 19. Database Triggers for Updated_at

**What:** Automatically update `updated_at` on every row change.

**When to use:** All tables with timestamp tracking.

**Pattern:**

```sql
-- Create trigger function (once per database)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to each table
CREATE TRIGGER update_prj_projects_updated_at
  BEFORE UPDATE ON prj_projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

**Benefits:**
- ✅ Never forget to update timestamp
- ✅ Consistent across all updates
- ✅ Works with any update method (SQL, RPC, client)

---

### 20. Migration File Naming

**What:** Consistent naming for database migrations.

**When to use:** All projects with migrations.

**Pattern:**

```
supabase/migrations/
├── 001_initial_schema.sql
├── 002_rls_policies.sql
├── 003_rpc_functions.sql
├── 004_add_notifications.sql
└── 005_add_payments_table.sql
```

**Naming convention:**
```
<number>_<descriptive_name>.sql

- Number: 001, 002, 003 (sequential)
- Name: snake_case, descriptive
- Extension: .sql
```

**Benefits:**
- ✅ Files run in correct order
- ✅ Easy to see migration history
- ✅ Clear purpose from filename

---

## UI Components (Lesson 3)

### 21. Reusable Button Component

**What:** Production-ready button component with variants, sizes, and loading states.

**When to use:** All buttons in your app for consistency.

**File:** `src/components/ui/Button.tsx`

```typescript
import { ButtonHTMLAttributes, forwardRef } from 'react'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'outline' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  isLoading?: boolean
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({
    children,
    variant = 'default',
    size = 'md',
    isLoading = false,
    disabled,
    className = '',
    ...props
  }, ref) => {
    const baseStyles = 'inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none'

    const variants = {
      default: 'bg-blue-600 text-white hover:bg-blue-700 focus-visible:ring-blue-500',
      outline: 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus-visible:ring-gray-500',
      ghost: 'text-gray-700 hover:bg-gray-100 focus-visible:ring-gray-500',
      danger: 'bg-red-600 text-white hover:bg-red-700 focus-visible:ring-red-500',
    }

    const sizes = {
      sm: 'px-3 py-1.5 text-sm rounded-md',
      md: 'px-4 py-2 text-base rounded-md',
      lg: 'px-6 py-3 text-lg rounded-lg',
    }

    return (
      <button
        ref={ref}
        disabled={disabled || isLoading}
        className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${className}`}
        {...props}
      >
        {isLoading ? (
          <>
            <svg className="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Loading...
          </>
        ) : (
          children
        )}
      </button>
    )
  }
)

Button.displayName = 'Button'
```

**Usage:**

```typescript
import { Button } from '@/components/ui/Button'

<Button onClick={handleClick}>Click Me</Button>
<Button variant="outline">Secondary</Button>
<Button variant="danger">Delete</Button>
<Button size="lg" isLoading={loading}>Submit</Button>
```

**Benefits:**
- ✅ Consistent styling across all buttons
- ✅ Built-in loading spinner
- ✅ Accessible with focus states
- ✅ Type-safe with TypeScript
- ✅ Easy to customize with className

---

### 22. Reusable Input Component

**What:** Form input with label, error handling, and helper text.

**When to use:** All text inputs in forms.

**File:** `src/components/ui/Input.tsx`

```typescript
import { InputHTMLAttributes, forwardRef } from 'react'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  helperText?: string
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, className = '', ...props }, ref) => {
    const inputId = props.id || props.name

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={`
            w-full px-3 py-2 border rounded-md shadow-sm
            focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
            disabled:bg-gray-100 disabled:cursor-not-allowed
            ${error ? 'border-red-500' : 'border-gray-300'}
            ${className}
          `}
          {...props}
        />
        {error && (
          <p className="mt-1 text-sm text-red-600">{error}</p>
        )}
        {helperText && !error && (
          <p className="mt-1 text-sm text-gray-500">{helperText}</p>
        )}
      </div>
    )
  }
)

Input.displayName = 'Input'
```

**Usage:**

```typescript
import { Input } from '@/components/ui/Input'

<Input
  name="email"
  label="Email Address"
  type="email"
  error={errors.email}
  helperText="We'll never share your email"
/>
```

**Benefits:**
- ✅ Automatic label association
- ✅ Error state handling
- ✅ Helper text support
- ✅ Accessible with proper ARIA
- ✅ Type-safe

---

### 23. Reusable Select Component

**What:** Dropdown select with options array and error handling.

**When to use:** Dropdown selections in forms.

**File:** `src/components/ui/Select.tsx`

```typescript
import { SelectHTMLAttributes, forwardRef } from 'react'

interface SelectOption {
  value: string
  label: string
  disabled?: boolean
}

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string
  error?: string
  helperText?: string
  options: SelectOption[]
  placeholder?: string
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, helperText, options, placeholder, className = '', ...props }, ref) => {
    const selectId = props.id || props.name

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={selectId}
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {label}
          </label>
        )}
        <select
          ref={ref}
          id={selectId}
          className={`
            w-full px-3 py-2 border rounded-md shadow-sm
            focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
            disabled:bg-gray-100 disabled:cursor-not-allowed
            ${error ? 'border-red-500' : 'border-gray-300'}
            ${className}
          `}
          {...props}
        >
          {placeholder && (
            <option value="" disabled>
              {placeholder}
            </option>
          )}
          {options.map((option) => (
            <option
              key={option.value}
              value={option.value}
              disabled={option.disabled}
            >
              {option.label}
            </option>
          ))}
        </select>
        {error && (
          <p className="mt-1 text-sm text-red-600">{error}</p>
        )}
        {helperText && !error && (
          <p className="mt-1 text-sm text-gray-500">{helperText}</p>
        )}
      </div>
    )
  }
)

Select.displayName = 'Select'
```

**Usage:**

```typescript
import { Select } from '@/components/ui/Select'

<Select
  name="role"
  label="User Role"
  placeholder="Select a role"
  options={[
    { value: 'owner', label: 'Owner' },
    { value: 'admin', label: 'Admin' },
    { value: 'member', label: 'Member' },
    { value: 'viewer', label: 'Viewer', disabled: true },
  ]}
  error={errors.role}
/>
```

**Benefits:**
- ✅ Type-safe options array
- ✅ Disabled options support
- ✅ Error handling
- ✅ Placeholder support
- ✅ Consistent with Input component

---

### 24. Reusable Dropdown Component

**What:** Dropdown menu with click-outside detection and keyboard support.

**When to use:** Action menus, user menus, context menus.

**File:** `src/components/ui/Dropdown.tsx`

```typescript
'use client'

import { useState, useRef, useEffect, ReactNode } from 'react'

interface DropdownItem {
  label: string
  onClick: () => void
  icon?: ReactNode
  danger?: boolean
  disabled?: boolean
}

interface DropdownProps {
  trigger: ReactNode
  items: DropdownItem[]
  align?: 'left' | 'right'
}

export function Dropdown({ trigger, items, align = 'right' }: DropdownProps) {
  const [isOpen, setIsOpen] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside)
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isOpen])

  // Close on Escape key
  useEffect(() => {
    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setIsOpen(false)
      }
    }

    if (isOpen) {
      document.addEventListener('keydown', handleEscape)
    }

    return () => {
      document.removeEventListener('keydown', handleEscape)
    }
  }, [isOpen])

  return (
    <div className="relative inline-block" ref={dropdownRef}>
      <div onClick={() => setIsOpen(!isOpen)}>
        {trigger}
      </div>

      {isOpen && (
        <div
          className={`
            absolute z-50 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5
            ${align === 'right' ? 'right-0' : 'left-0'}
          `}
        >
          <div className="py-1" role="menu">
            {items.map((item, index) => (
              <button
                key={index}
                onClick={() => {
                  if (!item.disabled) {
                    item.onClick()
                    setIsOpen(false)
                  }
                }}
                disabled={item.disabled}
                className={`
                  w-full text-left px-4 py-2 text-sm flex items-center gap-2
                  transition-colors
                  ${item.danger
                    ? 'text-red-700 hover:bg-red-50'
                    : 'text-gray-700 hover:bg-gray-100'
                  }
                  ${item.disabled
                    ? 'opacity-50 cursor-not-allowed'
                    : 'cursor-pointer'
                  }
                `}
                role="menuitem"
              >
                {item.icon && <span>{item.icon}</span>}
                <span>{item.label}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
```

**Usage:**

```typescript
import { Dropdown } from '@/components/ui/Dropdown'
import { Button } from '@/components/ui/Button'

<Dropdown
  trigger={<Button>Actions</Button>}
  items={[
    { label: 'Edit', onClick: () => handleEdit() },
    { label: 'Duplicate', onClick: () => handleDuplicate() },
    { label: 'Delete', onClick: () => handleDelete(), danger: true },
  ]}
  align="right"
/>
```

**Benefits:**
- ✅ Click outside to close
- ✅ Escape key support
- ✅ Danger item styling
- ✅ Icon support
- ✅ Disabled items
- ✅ Type-safe

---

### 25. Reusable Modal Component

**What:** Modal dialog with backdrop, keyboard support, and scroll lock.

**When to use:** Confirmations, forms, detail views.

**File:** `src/components/ui/Modal.tsx`

```typescript
'use client'

import { ReactNode, useEffect } from 'react'
import { Button } from './Button'

interface ModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  children: ReactNode
  footer?: ReactNode
  size?: 'sm' | 'md' | 'lg' | 'xl'
}

export function Modal({
  isOpen,
  onClose,
  title,
  children,
  footer,
  size = 'md'
}: ModalProps) {
  // Close on Escape key
  useEffect(() => {
    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        onClose()
      }
    }

    if (isOpen) {
      document.addEventListener('keydown', handleEscape)
      // Prevent body scroll when modal is open
      document.body.style.overflow = 'hidden'
    }

    return () => {
      document.removeEventListener('keydown', handleEscape)
      document.body.style.overflow = 'unset'
    }
  }, [isOpen, onClose])

  if (!isOpen) return null

  const sizes = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl',
  }

  return (
    <div
      className="fixed inset-0 z-50 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="flex min-h-full items-center justify-center p-4">
        <div
          className={`
            relative transform overflow-hidden rounded-lg bg-white
            shadow-xl transition-all w-full ${sizes[size]}
          `}
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="border-b border-gray-200 px-6 py-4">
            <div className="flex items-center justify-between">
              <h3
                className="text-lg font-semibold text-gray-900"
                id="modal-title"
              >
                {title}
              </h3>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500 focus:outline-none"
              >
                <span className="sr-only">Close</span>
                <svg
                  className="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
          </div>

          {/* Body */}
          <div className="px-6 py-4">
            {children}
          </div>

          {/* Footer */}
          {footer && (
            <div className="border-t border-gray-200 px-6 py-4 bg-gray-50">
              {footer}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// Common modal footer with Cancel and Confirm buttons
interface ModalFooterProps {
  onCancel: () => void
  onConfirm: () => void
  confirmText?: string
  cancelText?: string
  confirmVariant?: 'default' | 'danger'
  isLoading?: boolean
}

export function ModalFooter({
  onCancel,
  onConfirm,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  confirmVariant = 'default',
  isLoading = false,
}: ModalFooterProps) {
  return (
    <div className="flex justify-end gap-3">
      <Button
        onClick={onCancel}
        variant="outline"
        disabled={isLoading}
      >
        {cancelText}
      </Button>
      <Button
        onClick={onConfirm}
        variant={confirmVariant}
        isLoading={isLoading}
      >
        {confirmText}
      </Button>
    </div>
  )
}
```

**Usage:**

```typescript
import { Modal, ModalFooter } from '@/components/ui/Modal'

const [isOpen, setIsOpen] = useState(false)

<Modal
  isOpen={isOpen}
  onClose={() => setIsOpen(false)}
  title="Delete Project"
  size="md"
  footer={
    <ModalFooter
      onCancel={() => setIsOpen(false)}
      onConfirm={handleDelete}
      confirmText="Delete"
      confirmVariant="danger"
      isLoading={isDeleting}
    />
  }
>
  <p>Are you sure you want to delete this project?</p>
</Modal>
```

**Benefits:**
- ✅ Backdrop with click-to-close
- ✅ Escape key support
- ✅ Body scroll lock
- ✅ Multiple sizes
- ✅ Custom footer support
- ✅ ModalFooter helper
- ✅ Accessible with ARIA
- ✅ Type-safe

---

## Quick Copy-Paste Checklist

Use this checklist when starting a new project:

### Initial Setup
- [ ] Create Next.js 16 app: `npx create-next-app@latest`
- [ ] Enable Cache Components in `next.config.ts`
- [ ] Configure import alias in `tsconfig.json`
- [ ] Create folder structure (src/app, src/lib, src/components, etc.)
- [ ] Create `src/constants/index.ts`
- [ ] Create `src/types/index.ts`

### Supabase Setup
- [ ] Create Supabase project
- [ ] Install: `npm install @supabase/supabase-js @supabase/ssr`
- [ ] Create `.env.local` with credentials
- [ ] Create `.env.local.example` (commit to git)
- [ ] Create `src/lib/supabase/client.ts`
- [ ] Create `src/lib/supabase/server.ts`
- [ ] Create `src/lib/supabase/middleware.ts`
- [ ] Create `proxy.ts` at root
- [ ] Create `supabase/migrations/` folder

### Database
- [ ] Create schema migration
- [ ] Enable RLS on all tables
- [ ] Create RLS policies
- [ ] Create RPC functions
- [ ] Run migrations in Supabase Dashboard
- [ ] Generate TypeScript types

### Security
- [ ] Add `.env*.local` to `.gitignore`
- [ ] Never use `SUPABASE_SERVICE_ROLE_KEY` in client code
- [ ] Use `getUser()` not `getSession()` in proxy
- [ ] Test RLS policies

---

## Version History

**v1.1 - Module 1, Lessons 1-3 (2025-11-19)**
- **NEW in Lesson 3:** 5 Reusable UI Components
  - Button component (variants, sizes, loading states)
  - Input component (labels, errors, helper text)
  - Select component (options array, placeholder)
  - Dropdown component (menus, click-outside, keyboard)
  - Modal component (backdrop, escape key, scroll lock)

**v1.0 - Module 1, Lessons 1-2 (2025-11-19)**
- Next.js 16 setup with Cache Components
- Import alias configuration
- Constants and types pattern
- Supabase integration (browser & server clients)
- Next.js 16 proxy.ts for session refresh
- Database schema with RLS and RPC
- TypeScript type generation
- Protected route helpers

**Coming in future lessons:**
- Server Actions (authentication, CRUD operations)
- Form handling patterns with validation
- Error boundaries and error handling
- Loading states and skeletons
- Real-time subscriptions
- File uploads with Supabase Storage
- Email templates
- Payment integration (Stripe)
- And more...

---

## 📝 Notes for Future Lessons

This section will be updated as new features are introduced in upcoming lessons.

**Planned additions:**
- Lesson 4: Project CRUD operations, Server Actions
- Lesson 5: Task management, real-time updates
- Lesson 6: File uploads, image handling
- And more...

---

**🎯 End of Reference - Will be updated with each lesson!**
