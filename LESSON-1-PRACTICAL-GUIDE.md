# Module 1, Lesson 1: Next.js 16 + React 19.2 Setup
**Practical Step-by-Step Guide with Bash Commands**

---

## ✅ 1. DESC

This lesson will create:

✔ **Next.js 16.0.3 + React 19.2.0** project with TypeScript  
✔ **Tailwind CSS 4** for styling  
✔ **Import alias** (@/*) configured  
✔ **Cache Components** enabled in Next.js 16  
✔ **Folder structure** following SOLID principles  
✔ **Constants file** with all app constants (DRY principle)  
✔ **TypeScript types** for type safety  
✔ **Environment variables** template for Supabase  
✔ **Home page** using import alias and constants  
✔ **Production build** verified and working  

**Everything will be done through bash commands, not manual file creation.**

---

## ✅ 2. CODE / STEPS (ALL BASH ONLY)

### 🎯 STEP 1 — Create Next.js 16 App with src directory

```bash
npx create-next-app@latest . \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-npm \
  --yes
```

**What this does:**
- Creates Next.js 16 app in current directory
- Enables TypeScript
- Configures Tailwind CSS 4
- Sets up ESLint
- Uses App Router
- Creates `src` folder structure
- Configures `@/*` import alias
- Uses npm (not yarn/pnpm)
- Skips prompts with --yes

---

### 🎯 STEP 2 — Verify Versions

```bash
# Check Node.js version
node -v

# Check npm version
npm -v

# Check installed packages
cat package.json | grep -E "(next|react)"
```

**Expected Output:**
```
"next": "16.0.3"
"react": "19.2.0"
"react-dom": "19.2.0"
```

---

### 🎯 STEP 3 — Create Folder Structure

```bash
# Create all folders at once
mkdir -p src/lib
mkdir -p src/components/ui
mkdir -p src/components/features/auth
mkdir -p src/components/features/projects
mkdir -p src/components/features/tasks
mkdir -p src/components/features/payments
mkdir -p src/types
mkdir -p src/constants
mkdir -p src/styles
mkdir -p src/hooks
mkdir -p src/utils

# Verify folder structure
find src -type d | sort
```

**Expected Output:**
```
src
src/app
src/components
src/components/features
src/components/features/auth
src/components/features/payments
src/components/features/projects
src/components/features/tasks
src/components/ui
src/constants
src/hooks
src/lib
src/styles
src/types
src/utils
```

---

### 🎯 STEP 4 — Create Constants File

```bash
cat > src/constants/index.ts << 'CONSTANTS_EOF'
/**
 * Application Constants
 * Following DRY principle - all magic strings and numbers centralized here
 */

// ============================================
// DATABASE TABLE NAMES
// ============================================
export const DB_TABLES = {
  PROJECTS: 'prj_projects',
  TASKS: 'prj_tasks',
  PROJECT_MEMBERS: 'prj_project_members',
  PROJECT_PAYMENTS: 'prj_project_payments',
  PROJECT_TERMS: 'prj_project_terms',
  USERS: 'users', // Supabase auth.users
} as const;

// ============================================
// CACHE TAGS (Next.js 16 Cache Components)
// ============================================
export const CACHE_TAGS = {
  PROJECTS: 'projects',
  TASKS: 'tasks',
  PROJECT_MEMBERS: 'project-members',
  PAYMENTS: 'payments',
  TERMS: 'terms',
  USER_PROFILE: 'user-profile',
} as const;

// ============================================
// CACHE LIFETIMES (Next.js 16)
// ============================================
export const CACHE_LIFETIMES = {
  DEFAULT: 'default' as const, // 15 minutes
  SECONDS: 'seconds' as const, // 1 second
  HOURS: 'hours' as const,     // 1 hour
  DAYS: 'days' as const,       // 1 day
  MAX: 'max' as const,         // 30 days
};

// ============================================
// ROUTES
// ============================================
export const ROUTES = {
  HOME: '/',
  DASHBOARD: '/dashboard',
  PROJECTS: '/projects',
  PROJECT_DETAIL: (id: string) => `/projects/${id}`,
  TASKS: '/tasks',
  PAYMENTS: '/payments',
  AUTH: {
    LOGIN: '/auth/login',
    SIGNUP: '/auth/signup',
    FORGOT_PASSWORD: '/auth/forgot-password',
    CALLBACK: '/auth/callback',
  },
} as const;

// ============================================
// TASK STATUS
// ============================================
export const TASK_STATUS = {
  TODO: 'todo',
  IN_PROGRESS: 'in_progress',
  REVIEW: 'review',
  DONE: 'done',
  CANCELLED: 'cancelled',
} as const;

// ============================================
// PROJECT STATUS
// ============================================
export const PROJECT_STATUS = {
  ACTIVE: 'active',
  ON_HOLD: 'on_hold',
  COMPLETED: 'completed',
  ARCHIVED: 'archived',
} as const;

// ============================================
// MEMBER ROLES
// ============================================
export const MEMBER_ROLES = {
  OWNER: 'owner',
  ADMIN: 'admin',
  MEMBER: 'member',
  VIEWER: 'viewer',
} as const;

// ============================================
// PAYMENT STATUS
// ============================================
export const PAYMENT_STATUS = {
  PENDING: 'pending',
  PAID: 'paid',
  OVERDUE: 'overdue',
  CANCELLED: 'cancelled',
} as const;

// ============================================
// API ENDPOINTS
// ============================================
export const API_ENDPOINTS = {
  PROJECTS: '/api/projects',
  TASKS: '/api/tasks',
  PAYMENTS: '/api/payments',
} as const;

// ============================================
// VALIDATION
// ============================================
export const VALIDATION = {
  PROJECT_NAME_MIN_LENGTH: 3,
  PROJECT_NAME_MAX_LENGTH: 100,
  TASK_TITLE_MIN_LENGTH: 3,
  TASK_TITLE_MAX_LENGTH: 200,
  PASSWORD_MIN_LENGTH: 8,
} as const;

// ============================================
// UI CONSTANTS
// ============================================
export const UI = {
  ITEMS_PER_PAGE: 10,
  DEBOUNCE_DELAY: 300,
  TOAST_DURATION: 3000,
} as const;

// ============================================
// ERROR MESSAGES
// ============================================
export const ERROR_MESSAGES = {
  GENERIC: 'Something went wrong. Please try again.',
  UNAUTHORIZED: 'You must be logged in to perform this action.',
  FORBIDDEN: 'You do not have permission to perform this action.',
  NOT_FOUND: 'Resource not found.',
  VALIDATION_FAILED: 'Please check your input and try again.',
  NETWORK_ERROR: 'Network error. Please check your connection.',
} as const;

// ============================================
// SUCCESS MESSAGES
// ============================================
export const SUCCESS_MESSAGES = {
  PROJECT_CREATED: 'Project created successfully',
  PROJECT_UPDATED: 'Project updated successfully',
  PROJECT_DELETED: 'Project deleted successfully',
  TASK_CREATED: 'Task created successfully',
  TASK_UPDATED: 'Task updated successfully',
  TASK_DELETED: 'Task deleted successfully',
} as const;

// ============================================
// TYPE EXPORTS
// ============================================
export type TaskStatus = typeof TASK_STATUS[keyof typeof TASK_STATUS];
export type ProjectStatus = typeof PROJECT_STATUS[keyof typeof PROJECT_STATUS];
export type MemberRole = typeof MEMBER_ROLES[keyof typeof MEMBER_ROLES];
export type PaymentStatus = typeof PAYMENT_STATUS[keyof typeof PAYMENT_STATUS];
CONSTANTS_EOF

# Verify file was created
cat src/constants/index.ts | head -20
```

---

### 🎯 STEP 5 — Create TypeScript Types

```bash
cat > src/types/index.ts << 'TYPES_EOF'
/**
 * TypeScript Type Definitions
 * Centralized types for type safety across the application
 */

import { 
  TaskStatus, 
  ProjectStatus, 
  MemberRole, 
  PaymentStatus 
} from '@/constants';

// ============================================
// DATABASE TYPES
// ============================================

export interface Project {
  id: string;
  name: string;
  description: string | null;
  start_date: string;
  end_date: string | null;
  is_active: boolean;
  status: ProjectStatus;
  created_at: string;
  updated_at: string;
}

export interface Task {
  id: string;
  project_id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  due_date: string | null;
  assigned_to: string | null;
  created_at: string;
  updated_at: string;
  created_by: string;
}

export interface ProjectMember {
  id: string;
  project_id: string;
  user_id: string;
  role: MemberRole;
  joined_at: string;
}

export interface ProjectPayment {
  id: string;
  project_id: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  due_date: string;
  paid_date: string | null;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface ProjectTerm {
  id: string;
  project_id: string;
  title: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface User {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
  created_at: string;
}

// ============================================
// FORM TYPES
// ============================================

export interface CreateProjectInput {
  name: string;
  description?: string;
  start_date: string;
  end_date?: string;
}

export interface UpdateProjectInput {
  name?: string;
  description?: string;
  start_date?: string;
  end_date?: string;
  status?: ProjectStatus;
  is_active?: boolean;
}

export interface CreateTaskInput {
  project_id: string;
  title: string;
  description?: string;
  status?: TaskStatus;
  due_date?: string;
  assigned_to?: string;
}

export interface UpdateTaskInput {
  title?: string;
  description?: string;
  status?: TaskStatus;
  due_date?: string;
  assigned_to?: string;
}

// ============================================
// API RESPONSE TYPES
// ============================================

export interface ApiResponse<T> {
  data: T | null;
  error: string | null;
  success: boolean;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

// ============================================
// COMPONENT PROPS TYPES
// ============================================

export interface BaseComponentProps {
  className?: string;
  children?: React.ReactNode;
}

export interface ProjectCardProps extends BaseComponentProps {
  project: Project;
  onEdit?: (project: Project) => void;
  onDelete?: (projectId: string) => void;
}

export interface TaskCardProps extends BaseComponentProps {
  task: Task;
  onStatusChange?: (taskId: string, status: TaskStatus) => void;
  onEdit?: (task: Task) => void;
  onDelete?: (taskId: string) => void;
}

// ============================================
// UTILITY TYPES
// ============================================

export type AsyncActionState<T> = {
  data: T | null;
  loading: boolean;
  error: string | null;
};

export type FormState = {
  errors: Record<string, string[]>;
  message: string | null;
};
TYPES_EOF

# Verify file was created
cat src/types/index.ts | head -20
```

---

### 🎯 STEP 6 — Configure Next.js 16 Cache Components

```bash
cat > next.config.ts << 'CONFIG_EOF'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Enable Next.js 16 Cache Components feature (includes PPR)
  cacheComponents: true,

  // Custom cache life profiles
  cacheLife: {
    // Weekly cache profile for less frequently changing data
    weekly: {
      stale: 60 * 60 * 24 * 7, // 7 days in seconds
      revalidate: 60 * 60 * 24 * 7,
      expire: 60 * 60 * 24 * 7,
    },
    // Daily cache profile for moderately changing data
    daily: {
      stale: 60 * 60 * 24, // 1 day in seconds
      revalidate: 60 * 60 * 24,
      expire: 60 * 60 * 24,
    },
  },
};

export default nextConfig;
CONFIG_EOF

# Verify configuration
cat next.config.ts
```

---

### 🎯 STEP 7 — Update Layout (Remove Google Fonts, Use Import Alias)

```bash
cat > src/app/layout.tsx << 'LAYOUT_EOF'
import type { Metadata } from "next";
import "@/app/globals.css";

export const metadata: Metadata = {
  title: "Project Management App",
  description: "Learn Next.js 16 + React 19.2 - Project Management Application",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
LAYOUT_EOF

# Verify layout
cat src/app/layout.tsx
```

---

### 🎯 STEP 8 — Create Home Page Using Constants

```bash
cat > src/app/page.tsx << 'PAGE_EOF'
import { ROUTES } from '@/constants';

export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      <main className="flex flex-col items-center justify-center gap-8 p-8 text-center">
        <div className="space-y-4">
          <h1 className="text-5xl font-bold text-gray-900 dark:text-white">
            Project Management App
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-300">
            Built with Next.js 16 + React 19.2 + Tailwind CSS + Supabase
          </p>
        </div>

        <div className="flex flex-col gap-4 sm:flex-row">
          <div className="rounded-lg bg-white dark:bg-gray-800 p-6 shadow-lg">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
              Features
            </h2>
            <ul className="text-left text-gray-600 dark:text-gray-300 space-y-2">
              <li>✅ Next.js 16 with Cache Components</li>
              <li>✅ React 19.2 with Server Components</li>
              <li>✅ Tailwind CSS 4</li>
              <li>✅ TypeScript</li>
              <li>✅ Supabase Integration (Coming Next)</li>
            </ul>
          </div>
        </div>

        <div className="text-sm text-gray-500 dark:text-gray-400 mt-8">
          Module 1, Lesson 1: Setup Complete! 🎉
        </div>
      </main>
    </div>
  );
}
PAGE_EOF

# Verify page
cat src/app/page.tsx
```

---

### 🎯 STEP 9 — Create Environment Variables Template

```bash
cat > .env.local.example << 'ENV_EOF'
# Supabase Configuration
# Get these from https://supabase.com/dashboard/project/_/settings/api
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=your-publishable-default-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# App Configuration
NEXT_PUBLIC_APP_NAME=Project Management App
NEXT_PUBLIC_APP_URL=http://localhost:3000
ENV_EOF

# Verify template
cat .env.local.example
```

---

### 🎯 STEP 10 — Update .gitignore

```bash
cat >> .gitignore << 'GITIGNORE_EOF'

# Environment variables
.env.local
.env*.local

# Database
*.db
*.db-journal
GITIGNORE_EOF

# Verify .gitignore includes our additions
tail -10 .gitignore
```

---

### 🎯 STEP 11 — Build the Project

```bash
npm run build
```

**Expected Output:**
```
✓ Compiled successfully
Route (app)
┌ ○ /
└ ○ /_not-found

○  (Static)  prerendered as static content
```

---

### 🎯 STEP 12 — Test Development Server

```bash
# Start dev server
npm run dev

# Visit http://localhost:3000 in your browser
# You should see the "Project Management App" page
```

---

## ✅ 3. VERIFY / CHECKLIST

### Project Structure
- [ ] Project installed with `src` folder
- [ ] Next.js 16.0.3 installed (`cat package.json | grep next`)
- [ ] React 19.2.0 installed (`cat package.json | grep react`)
- [ ] TypeScript configured (`tsconfig.json` exists)
- [ ] Tailwind CSS 4 configured

### Folder Structure
- [ ] `src/lib` created
- [ ] `src/components/ui` created
- [ ] `src/components/features/auth` created
- [ ] `src/components/features/projects` created
- [ ] `src/components/features/tasks` created
- [ ] `src/components/features/payments` created
- [ ] `src/types` created
- [ ] `src/constants` created
- [ ] `src/hooks` created
- [ ] `src/utils` created

**Verify with:** `find src -type d | sort`

### Configuration Files
- [ ] `next.config.ts` has `cacheComponents: true`
- [ ] `next.config.ts` has custom cache profiles (weekly, daily)
- [ ] `tsconfig.json` has `"@/*": ["./src/*"]` in paths
- [ ] `.env.local.example` created with Supabase variables
- [ ] `.env.local.example` uses `PUBLISHABLE_DEFAULT_KEY` (new method)
- [ ] `.gitignore` includes `.env.local`

### Source Files
- [ ] `src/constants/index.ts` created via bash
- [ ] Constants file has `DB_TABLES` with `prj_` prefix
- [ ] Constants file has `CACHE_TAGS` for Next.js 16
- [ ] Constants file has `CACHE_LIFETIMES`
- [ ] Constants file has all status enums
- [ ] Constants file has `VALIDATION` constants (no magic numbers)
- [ ] Constants file has error/success messages (no magic strings)

**Verify with:** `cat src/constants/index.ts | grep "DB_TABLES\|CACHE_TAGS"`

### TypeScript Types
- [ ] `src/types/index.ts` created via bash
- [ ] Types file imports from `@/constants` (using alias)
- [ ] Types file has `Project` interface
- [ ] Types file has `Task` interface
- [ ] Types file has `ProjectMember` interface
- [ ] Types file has `ProjectPayment` interface
- [ ] Types file has form input types
- [ ] Types file has API response types

**Verify with:** `cat src/types/index.ts | head -20`

### Import Alias
- [ ] `src/app/layout.tsx` uses `@/app/globals.css` (not `./globals.css`)
- [ ] `src/app/page.tsx` uses `@/constants` (not relative path)
- [ ] `src/types/index.ts` uses `@/constants`
- [ ] No relative imports found (`grep -r "from '\.\./\|from '\.\/" src/` returns empty)

**Verify with:** `grep -r "from '@/" src/`

### Application
- [ ] Layout created via bash (no Google Fonts)
- [ ] Home page created via bash
- [ ] Home page imports from `@/constants`
- [ ] Build succeeds (`npm run build`)
- [ ] Build shows route as "Static" (○)
- [ ] Dev server runs (`npm run dev`)
- [ ] App displays at http://localhost:3000
- [ ] App shows "Project Management App" title
- [ ] App shows feature list with checkmarks
- [ ] App shows "Module 1, Lesson 1: Setup Complete! 🎉"

### Best Practices
- [ ] DRY: All constants in one file (`src/constants/index.ts`)
- [ ] No magic strings (all in constants)
- [ ] No magic numbers (all in `VALIDATION` constants)
- [ ] SOLID: Organized folder structure
- [ ] Type Safety: TypeScript types defined
- [ ] Import Alias: Using `@/*` everywhere
- [ ] Database Naming: All tables have `prj_` prefix
- [ ] Environment Variables: Template created

---

## 🎯 Quick Verification Commands

```bash
# 1. Check versions
cat package.json | grep -E "(next|react)"

# 2. Check folder structure
find src -type d | sort

# 3. Check constants file exists and has DB_TABLES
cat src/constants/index.ts | grep -A5 "DB_TABLES"

# 4. Check types file exists and imports constants
cat src/types/index.ts | grep "from '@/constants'"

# 5. Check import alias in layout
cat src/app/layout.tsx | grep "@/app/globals.css"

# 6. Check import alias in page
cat src/app/page.tsx | grep "@/constants"

# 7. Check for relative imports (should be empty)
grep -r "from '\.\./\|from '\.\/" src/ --include="*.ts" --include="*.tsx"

# 8. Check Next.js config
cat next.config.ts | grep "cacheComponents"

# 9. Check environment template
cat .env.local.example | grep "PUBLISHABLE_DEFAULT_KEY"

# 10. Build project
npm run build

# 11. Start dev server
npm run dev
```

---

## 📊 Expected Results

### Build Output
```
   ▲ Next.js 16.0.3 (Turbopack, Cache Components)

   Creating an optimized production build ...
 ✓ Compiled successfully in 2.3s
   
Route (app)
┌ ○ /
└ ○ /_not-found

○  (Static)  prerendered as static content
```

### File Structure
```
nextjs-tutorial/
├── src/
│   ├── app/
│   │   ├── layout.tsx          (Using @/app/globals.css)
│   │   └── page.tsx            (Using @/constants)
│   ├── components/
│   │   ├── ui/
│   │   └── features/
│   │       ├── auth/
│   │       ├── projects/
│   │       ├── tasks/
│   │       └── payments/
│   ├── constants/index.ts      (All app constants)
│   ├── types/index.ts          (TypeScript types)
│   ├── lib/
│   ├── hooks/
│   └── utils/
├── next.config.ts              (Cache Components enabled)
├── tsconfig.json               (Import alias configured)
├── .env.local.example          (Supabase template)
└── package.json                (Next 16, React 19.2)
```

---

## 🎉 Success Criteria

✅ **ALL** checkboxes above are checked  
✅ Build completes without errors  
✅ Dev server runs at http://localhost:3000  
✅ Page displays correctly with all features listed  
✅ No relative imports found in src/  
✅ All imports use `@/*` alias  
✅ Constants file has `prj_` prefix for all tables  
✅ Environment template uses `PUBLISHABLE_DEFAULT_KEY`  

---

## 🚀 Next Steps

Once all checkboxes are complete:
1. ✅ Read `LEARNING-GUIDE.md` to understand concepts
2. ✅ Keep `IMPORT-ALIAS-GUIDE.md` as reference
3. 🔜 Continue to **Lesson 2: Supabase Setup & Database Configuration**

---

**Lesson 1 Complete! Ready for Lesson 2?** 🎯
