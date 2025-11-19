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

<details>
<summary>📖 <b>Click to learn what each flag does</b></summary>

### Detailed Explanation

**`npx create-next-app@latest`**
- `npx` - Runs packages without installing them globally
- `create-next-app` - Official Next.js scaffolding tool
- `@latest` - Uses the newest version (Next.js 16)

**`.` (dot)**
- Creates project in current directory instead of new folder

**`--typescript`**
- Adds TypeScript configuration (`tsconfig.json`)
- Installs TypeScript types for Next.js and React
- All `.js` files become `.ts` or `.tsx`
- **Why?** Type safety catches errors before runtime

**`--tailwind`**
- Installs Tailwind CSS 4
- Creates `tailwind.config.ts`
- Adds Tailwind directives to `globals.css`
- **Why?** Utility-first CSS without writing custom styles

**`--eslint`**
- Installs ESLint with Next.js rules
- Creates `eslint.config.mjs`
- **Why?** Catches code quality issues automatically

**`--app`**
- Uses App Router (not Pages Router)
- Creates `app` directory
- **Why?** Modern Next.js architecture with React Server Components

**`--src-dir`**
- Creates `src` folder for all source code
- Better organization for larger projects
- **Why?** Separates source code from config files

**`--import-alias "@/*"`**
- Configures `@/*` to point to `src/*`
- Updates `tsconfig.json` with path mapping
- **Why?** Clean imports without `../../../`

**`--use-npm`**
- Uses npm instead of yarn or pnpm
- **Why?** Most common package manager

**`--yes`**
- Skips all prompts
- Uses all defaults
- **Why?** Faster setup, no manual input needed

</details>

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

<details>
<summary>📖 <b>Click to learn why we verify versions</b></summary>

### Why Version Verification Matters

**Node.js Version Check (`node -v`)**
- Next.js 16 requires Node.js 18+
- Older versions won't work
- Ensures compatibility

**npm Version Check (`npm -v`)**
- Confirms package manager is working
- npm 9+ recommended

**Package Version Check**
- **Next.js 16.0.3** - Latest stable version with:
  - Cache Components (new!)
  - Partial Pre-Rendering (PPR)
  - Improved performance
  
- **React 19.2.0** - Latest with:
  - Server Components (stable)
  - Improved concurrent rendering
  - Better error handling

**Why This Matters:**
- Ensures you're using features we'll teach
- Tutorial examples match your installed versions
- Avoids "it doesn't work" issues due to old versions

</details>

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

<details>
<summary>📖 <b>Click to learn about the folder structure (SOLID principles)</b></summary>

### Why This Folder Structure?

This follows **SOLID principles**, specifically **Single Responsibility Principle (SRP)**.

**`src/lib/`** - Third-party integrations
- Supabase client
- External API wrappers
- **Why separate?** Easy to swap libraries

**`src/components/ui/`** - Reusable UI components
- Button, Card, Input, etc.
- Used across the entire app
- **Why separate?** Can be shared between features

**`src/components/features/`** - Feature-specific components
- **`auth/`** - Login, Signup, PasswordReset
- **`projects/`** - ProjectList, ProjectCard, CreateProject
- **`tasks/`** - TaskList, TaskCard, CreateTask
- **`payments/`** - PaymentForm, PaymentHistory
- **Why separate?** Easy to find and modify specific features

**`src/types/`** - TypeScript type definitions
- Interfaces for database models
- Form input types
- **Why separate?** Types are imported everywhere

**`src/constants/`** - Application constants
- Database table names
- Status enums
- Error messages
- **Why separate?** DRY principle - single source of truth

**`src/hooks/`** - Custom React hooks
- `useProjects()`, `useAuth()`, etc.
- Reusable logic
- **Why separate?** Share logic between components

**`src/utils/`** - Utility functions
- `formatDate()`, `cn()` (classnames), etc.
- Pure functions
- **Why separate?** Easy to test and reuse

### Benefits:
1. **Easy to Find** - Know exactly where code lives
2. **Easy to Scale** - Add features without mess
3. **Easy to Test** - Each part isolated
4. **Team Friendly** - Multiple developers can work in parallel

</details>

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

// Rest of constants...
CONSTANTS_EOF

# Verify file was created
cat src/constants/index.ts | head -20
```

<details>
<summary>📖 <b>Click to learn why we use constants (DRY principle)</b></summary>

### Why Centralize Constants?

**The Problem:**
```typescript
// ❌ BAD - Scattered magic strings
function getProjects() {
  return db.from('prj_projects').select(); // In file A
}

function createProject() {
  return db.from('prj_projects').insert(); // In file B
}

function deleteProject() {
  return db.from('prj_projects').delete(); // In file C
}
```

**What if you need to rename `prj_projects` to `app_projects`?**
- You'd have to find and replace in 50+ files
- Easy to miss one
- Easy to make typos
- Hard to test

**The Solution:**
```typescript
// ✅ GOOD - Single source of truth
// constants/index.ts
export const DB_TABLES = {
  PROJECTS: 'prj_projects'
};

// Usage everywhere
import { DB_TABLES } from '@/constants';

function getProjects() {
  return db.from(DB_TABLES.PROJECTS).select();
}
```

**Benefits:**

1. **Single Update Point**
   - Change table name in ONE place
   - Automatically updates everywhere

2. **Autocomplete**
   - TypeScript knows all available tables
   - Can't type wrong table name

3. **Type Safety**
   - `DB_TABLES.PROJETS` ← catches typo
   - Errors before runtime

4. **Self-Documenting**
   - See all tables in one file
   - Easy to understand app structure

5. **Easy Refactoring**
   - Rename with confidence
   - IDE can track all usages

**Why `prj_` Prefix?**
- Prevents conflicts with system tables
- Easy to identify your app's tables
- Professional database naming

**Why `as const`?**
```typescript
const STATUS = {
  ACTIVE: 'active'
} as const;

// Without 'as const': type is string
// With 'as const': type is literal "active"
// Better type safety!
```

</details>

---

### 🎯 STEP 5 — Create TypeScript Types

```bash
cat > src/types/index.ts << 'TYPES_EOF'
import { TaskStatus, ProjectStatus } from '@/constants';

export interface Project {
  id: string;
  name: string;
  description: string | null;
  status: ProjectStatus;
  created_at: string;
  updated_at: string;
}

// More types...
TYPES_EOF

# Verify file was created
cat src/types/index.ts | head -20
```

<details>
<summary>📖 <b>Click to learn about TypeScript type safety</b></summary>

### Why TypeScript Types?

**Without Types (JavaScript):**
```javascript
// ❌ No type checking
function createProject(name, description, date) {
  // What if someone passes:
  // - A number for name?
  // - undefined for description?
  // - Invalid date format?
  // You won't know until runtime error!
}

createProject(12345, null, 'not-a-date'); // No error until it runs
```

**With Types (TypeScript):**
```typescript
// ✅ Type checking
interface CreateProjectInput {
  name: string;           // Must be string
  description?: string;   // Optional string
  start_date: string;     // Required string
}

function createProject(input: CreateProjectInput) {
  // TypeScript ensures correct types!
}

// Error immediately in editor:
createProject({
  name: 12345,  // ❌ Error: number is not string
  start_date: null  // ❌ Error: null is not string
});
```

**Benefits:**

1. **Catch Errors Early**
   - In editor, not production
   - Before users see them

2. **Better Autocomplete**
   - IDE knows what properties exist
   - Suggests correct field names

3. **Self-Documenting**
   ```typescript
   // Interface explains data structure
   interface Project {
     id: string;              // UUID
     name: string;            // Project name
     description: string | null;  // Can be null
     status: ProjectStatus;   // Only valid statuses
   }
   ```

4. **Refactoring Safety**
   - Rename a field
   - TypeScript shows all places to update

5. **Team Communication**
   - Types are contract between team members
   - No ambiguity about data shapes

**Why Import from `@/constants`?**
```typescript
import { TaskStatus, ProjectStatus } from '@/constants';

// Now status can only be valid values:
status: ProjectStatus; // 'active' | 'on_hold' | 'completed' | 'archived'

// Not any random string:
status: string; // ❌ Less safe
```

</details>

---

### 🎯 STEP 6 — Configure Next.js 16 Cache Components

```bash
cat > next.config.ts << 'CONFIG_EOF'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  cacheComponents: true,
  cacheLife: {
    weekly: {
      stale: 60 * 60 * 24 * 7,
      revalidate: 60 * 60 * 24 * 7,
      expire: 60 * 60 * 24 * 7,
    },
    daily: {
      stale: 60 * 60 * 24,
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

<details>
<summary>📖 <b>Click to learn about Cache Components (Next.js 16)</b></summary>

### What are Cache Components?

**Cache Components** is a new Next.js 16 feature that lets you cache parts of your page with fine-grained control.

**The Problem:**
```typescript
// Traditional approach: Cache whole page or nothing
export const revalidate = 3600; // Whole page cached for 1 hour

// But what if:
// - Header should update every 5 minutes (user info)
// - Blog posts can cache for 1 day
// - Comments should always be fresh
```

**The Solution:**
```typescript
// ✅ Cache individual components with different strategies

// Fast-changing component
async function UserProfile() {
  'use cache';
  cacheLife('seconds'); // Cache 1 second
  cacheTag('user');
  
  const user = await getUser();
  return <div>{user.name}</div>;
}

// Slow-changing component
async function BlogPosts() {
  'use cache';
  cacheLife('days'); // Cache 1 day
  cacheTag('blog-posts');
  
  const posts = await getPosts();
  return <div>{posts.map(...)}</div>;
}
```

**What `cacheComponents: true` Does:**
1. Enables the `'use cache'` directive
2. Enables Partial Pre-Rendering (PPR) automatically
3. Allows `cacheLife()` and `cacheTag()`

**Cache Life Options:**
```typescript
cacheLife('default');  // 15 minutes
cacheLife('seconds');  // 1 second
cacheLife('hours');    // 1 hour
cacheLife('days');     // 1 day
cacheLife('max');      // 30 days
cacheLife('weekly');   // Your custom profile
```

**Cache Tags for Revalidation:**
```typescript
// Tag component
async function Projects() {
  'use cache';
  cacheTag('projects'); // Tag this cache
  
  return <ProjectList />;
}

// Invalidate when data changes
import { updateTag } from 'next/cache';

async function createProject(data) {
  await db.insert(data);
  updateTag('projects'); // Instantly refresh projects cache
}
```

**Benefits:**
- ⚡ **Faster**: Cached content loads instantly
- 🎯 **Precise**: Cache exactly what you want
- 🔄 **Fresh**: Update cache on demand
- 💰 **Cost-Effective**: Less database queries

**When to Use:**
- Static content that rarely changes
- Expensive database queries
- API calls to third parties
- Computed/processed data

</details>

---

Continue with more steps...

