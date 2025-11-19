# Module 1, Lesson 2: Supabase Setup & Database Configuration
**Practical Step-by-Step Guide with Bash Commands**

> **💡 Tip:** This lesson connects Next.js to Supabase (PostgreSQL database). Each step has expandable **📖 Details** sections for deeper learning!

---

## ✅ 1. DESC

This lesson will create:

✔ **Supabase project** on supabase.com (manual web setup)
✔ **Database tables** with `prj_` prefix following relational model
✔ **Row Level Security (RLS)** policies for data protection
✔ **RPC functions** for type-safe database queries
✔ **Supabase clients** (browser & server) with new publishable key method
✔ **Next.js 16 proxy.ts** for automatic session refresh
✔ **Middleware helper** for cookie management
✔ **Database migrations** as SQL files for version control
✔ **TypeScript types** synced with database schema
✔ **Environment variables** properly configured
✔ **Session infrastructure** ready for authentication (Lesson 3)  

**Database Schema:**
- ✔ `prj_projects` - Project management
- ✔ `prj_tasks` - Task tracking with foreign keys
- ✔ `prj_project_members` - Many-to-many user relationships
- ✔ `prj_project_payments` - Payment tracking
- ✔ `prj_project_terms` - Project terms and conditions

---

## ✅ 2. CODE / STEPS (ALL BASH ONLY)

### 🎯 STEP 1 — Create Supabase Project (Manual)

**⚠️ This step requires web browser - cannot be done via bash**

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in:
   - **Name:** `project-management-app`
   - **Database Password:** (save this securely!)
   - **Region:** Choose closest to you
4. Click "Create new project"
5. Wait 2-3 minutes for setup to complete

<details>
<summary>📖 <strong>What is Supabase?</strong></summary>

### Supabase Overview

**What is it?**
- Open-source Firebase alternative
- PostgreSQL database in the cloud
- Built-in authentication
- Real-time subscriptions
- Auto-generated REST APIs
- Row Level Security (RLS)

**Why use Supabase?**
1. **PostgreSQL** - Most powerful open-source database
2. **Type-Safe** - Generate TypeScript types from schema
3. **Secure** - RLS policies protect data at database level
4. **Fast** - CDN-cached, globally distributed
5. **Free Tier** - 500MB database, 50,000 monthly active users
6. **Real-time** - Built-in websocket support

**vs. Traditional Backend:**
- No server code needed
- No API routes to write (though you can)
- Database handles auth, permissions, validation
- Scales automatically

</details>

---

### 🎯 STEP 2 — Get Supabase Credentials

After project creation:

1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **Project API keys** → **publishable** (anon key - new name)
   - **Project API keys** → **service_role** (keep secret!)

**Now create `.env.local` file:**

```bash
cat > .env.local << 'ENV_EOF'
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=your-publishable-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# App Configuration
NEXT_PUBLIC_APP_NAME=Project Management App
NEXT_PUBLIC_APP_URL=http://localhost:3000
ENV_EOF

# Verify file created
cat .env.local
```

**⚠️ IMPORTANT:** Replace the placeholder values with your actual keys!

<details>
<summary>📖 <strong>Understanding Supabase Keys</strong></summary>

### Three Types of Keys

**1. Project URL**
- Your database endpoint
- Public, safe to expose
- Format: `https://xxxxx.supabase.co`

**2. Publishable Key (formerly "anon key")**
- Used in browser/client code
- Safe to expose publicly
- Respects Row Level Security (RLS)
- **NEW NAME:** `PUBLISHABLE_DEFAULT_KEY` (Supabase updated naming)

**3. Service Role Key**
- Full database access
- **NEVER** expose in client code
- Only use in server-side code
- Bypasses RLS (use carefully!)

**Why `NEXT_PUBLIC_` prefix?**
```javascript
// With NEXT_PUBLIC_ - Available in browser
const url = process.env.NEXT_PUBLIC_SUPABASE_URL; // ✅ Works

// Without NEXT_PUBLIC_ - Server-only
const key = process.env.SUPABASE_SERVICE_ROLE_KEY; // ✅ Secure
```

**Security Model:**
- Client uses publishable key
- RLS policies enforce permissions
- Service role only in Server Actions/API routes

</details>

---

### 🎯 STEP 3 — Install Supabase Package

```bash
npm install @supabase/supabase-js

# Verify installation
cat package.json | grep supabase
```

**Expected output:**
```
"@supabase/supabase-js": "^2.x.x"
```

<details>
<summary>📖 <strong>What does @supabase/supabase-js do?</strong></summary>

### Supabase JavaScript Client

**What it provides:**
- Database queries (`select`, `insert`, `update`, `delete`)
- Authentication (`signUp`, `signIn`, `signOut`)
- Real-time subscriptions
- Storage (file uploads)
- RPC function calls
- TypeScript support

**Why this package?**
- Official Supabase client
- Type-safe queries
- Auto-handles authentication
- Real-time out of the box
- Works in browser and Node.js

**Alternative approaches:**
- ❌ Direct PostgreSQL client - No auth, no RLS
- ❌ Raw SQL - No type safety
- ✅ Supabase client - Best of both worlds

</details>

---

### 🎯 STEP 4 — Create Supabase Client for Browser

```bash
mkdir -p src/lib/supabase

cat > src/lib/supabase/client.ts << 'CLIENT_EOF'
import { createBrowserClient } from '@supabase/ssr'
import { Database } from '@/types/database'

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!
  )
}
CLIENT_EOF

# Verify file
cat src/lib/supabase/client.ts
```

<details>
<summary>📖 <strong>Why createBrowserClient?</strong></summary>

### Browser vs Server Client

**Supabase has different clients for different environments:**

**1. Browser Client (`createBrowserClient`)**
- Used in Client Components
- Uses cookies for auth
- Respects RLS policies
- Safe to use with publishable key

**2. Server Client (`createServerClient`)**
- Used in Server Components
- Access to server-side cookies
- Can use service role key
- More powerful queries

**3. Route Handler Client**
- Used in API routes
- Full server access

**Why type it with `<Database>`?**
```typescript
// Without types
const { data } = await supabase.from('prj_projects').select()
// data is 'any' - no autocomplete, no safety

// With types
const { data } = await supabase.from('prj_projects').select()
// data is Project[] - full autocomplete, type safety!
```

**We'll generate the `Database` type from our schema later.**

</details>

---

### 🎯 STEP 5 — Create Database Schema SQL

```bash
mkdir -p supabase/migrations

cat > supabase/migrations/001_initial_schema.sql << 'SCHEMA_EOF'
-- ============================================
-- PROJECT MANAGEMENT DATABASE SCHEMA
-- All tables prefixed with prj_
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROJECTS TABLE
-- ============================================
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

-- ============================================
-- TASKS TABLE (1:M with projects)
-- ============================================
CREATE TABLE prj_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES prj_projects(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'todo',
  due_date DATE,
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  
  CONSTRAINT prj_tasks_title_length CHECK (char_length(title) >= 3),
  CONSTRAINT prj_tasks_status_check CHECK (status IN ('todo', 'in_progress', 'review', 'done', 'cancelled'))
);

-- ============================================
-- PROJECT MEMBERS TABLE (M:N with users)
-- ============================================
CREATE TABLE prj_project_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES prj_projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(20) DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  
  CONSTRAINT prj_project_members_role_check CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  CONSTRAINT prj_project_members_unique UNIQUE (project_id, user_id)
);

-- ============================================
-- PROJECT PAYMENTS TABLE
-- ============================================
CREATE TABLE prj_project_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES prj_projects(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  status VARCHAR(20) DEFAULT 'pending',
  due_date DATE NOT NULL,
  paid_date DATE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  
  CONSTRAINT prj_payments_amount_positive CHECK (amount > 0),
  CONSTRAINT prj_payments_status_check CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled'))
);

-- ============================================
-- PROJECT TERMS TABLE
-- ============================================
CREATE TABLE prj_project_terms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES prj_projects(id) ON DELETE CASCADE,
  title VARCHAR(100) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_tasks_project_id ON prj_tasks(project_id);
CREATE INDEX idx_tasks_assigned_to ON prj_tasks(assigned_to);
CREATE INDEX idx_tasks_status ON prj_tasks(status);
CREATE INDEX idx_members_project_id ON prj_project_members(project_id);
CREATE INDEX idx_members_user_id ON prj_project_members(user_id);
CREATE INDEX idx_payments_project_id ON prj_project_payments(project_id);
CREATE INDEX idx_terms_project_id ON prj_project_terms(project_id);

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_prj_projects_updated_at BEFORE UPDATE ON prj_projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prj_tasks_updated_at BEFORE UPDATE ON prj_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prj_payments_updated_at BEFORE UPDATE ON prj_project_payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prj_terms_updated_at BEFORE UPDATE ON prj_project_terms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
SCHEMA_EOF

# Verify SQL file
cat supabase/migrations/001_initial_schema.sql | head -30
```

<details>
<summary>📖 <strong>Understanding the Database Schema</strong></summary>

### Schema Design Explained

**Why these tables?**

**1. `prj_projects` - The Core Table**
- Every project has basic info (name, dates, status)
- `is_active` - soft delete (don't actually delete)
- `status` - track project lifecycle
- `CHECK` constraints ensure data quality

**2. `prj_tasks` - One-to-Many**
- Each task belongs to ONE project
- `project_id` foreign key with CASCADE delete
- When project deleted, all tasks deleted too
- `assigned_to` and `created_by` link to users

**3. `prj_project_members` - Many-to-Many**
- One project has many users
- One user belongs to many projects
- Link table connects them
- `UNIQUE` constraint prevents duplicates
- Different roles (owner, admin, member, viewer)

**4. `prj_project_payments` - Payment Tracking**
- Track money owed/paid per project
- `DECIMAL(10, 2)` - proper money type (not FLOAT!)
- Status workflow: pending → paid/overdue/cancelled

**5. `prj_project_terms` - Terms & Conditions**
- Legal terms per project
- Can have multiple terms per project

**Why UUID instead of SERIAL?**
```sql
-- ❌ Old way: SERIAL (1, 2, 3...)
id SERIAL PRIMARY KEY

-- ✅ New way: UUID (unique globally)
id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
```

**Benefits of UUID:**
- Can't guess other IDs
- Merge databases without conflicts
- Generate client-side
- More secure

**Why TIMESTAMP WITH TIME ZONE?**
```sql
-- ❌ Without timezone
created_at TIMESTAMP

-- ✅ With timezone
created_at TIMESTAMP WITH TIME ZONE
```
- Always stores in UTC
- Converts to user's timezone
- No daylight saving bugs

**The `updated_at` Trigger:**
- Automatically updates `updated_at` on every UPDATE
- No need to remember in code
- Database handles it

</details>

---

### 🎯 STEP 6 — Run Database Migration

**⚠️ This step requires web browser**

1. Go to Supabase Dashboard → **SQL Editor**
2. Click **New Query**
3. Copy the SQL from `supabase/migrations/001_initial_schema.sql`
4. Paste into the editor
5. Click **Run** button
6. Wait for success message

**Verify tables were created:**

```bash
# We'll verify this in later steps with a test query
echo "✅ Tables should now exist in your Supabase database"
```

<details>
<summary>📖 <strong>Why run migration in Dashboard?</strong></summary>

### Database Migrations

**What are migrations?**
- SQL scripts that modify database structure
- Version-controlled database changes
- Can be run and re-run safely

**Why not use Supabase CLI for migrations?**
- **Learning approach**: Manual helps understand what's happening
- **Visual feedback**: Dashboard shows results immediately
- **No local dependencies**: No need to install Supabase CLI yet

**Production approach:**
```bash
# In real projects, use Supabase CLI
supabase db push
supabase db reset
```

**Migration file naming:**
- `001_` - Sequential number
- `initial_schema` - Descriptive name
- `.sql` - SQL file

**Why keep migrations in version control?**
1. **Reproducible** - Anyone can recreate database
2. **Documented** - History of all changes
3. **Testable** - Can test migrations locally
4. **Rollback** - Can undo changes if needed

</details>

---

### 🎯 STEP 7 — Create Row Level Security (RLS) Policies

```bash
cat > supabase/migrations/002_rls_policies.sql << 'RLS_EOF'
-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE prj_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE prj_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE prj_project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE prj_project_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE prj_project_terms ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROJECTS POLICIES
-- ============================================

-- Users can view projects they are members of
CREATE POLICY "Users can view their projects"
  ON prj_projects FOR SELECT
  USING (
    id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can insert projects (they become owner automatically)
CREATE POLICY "Users can create projects"
  ON prj_projects FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Only owners and admins can update projects
CREATE POLICY "Owners and admins can update projects"
  ON prj_projects FOR UPDATE
  USING (
    id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- Only owners can delete projects
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

-- ============================================
-- TASKS POLICIES
-- ============================================

-- Users can view tasks in their projects
CREATE POLICY "Users can view tasks in their projects"
  ON prj_tasks FOR SELECT
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can create tasks in their projects
CREATE POLICY "Users can create tasks in their projects"
  ON prj_tasks FOR INSERT
  WITH CHECK (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can update tasks in their projects
CREATE POLICY "Users can update tasks in their projects"
  ON prj_tasks FOR UPDATE
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
    )
  );

-- Only admins and owners can delete tasks
CREATE POLICY "Admins and owners can delete tasks"
  ON prj_tasks FOR DELETE
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- ============================================
-- PROJECT MEMBERS POLICIES
-- ============================================

-- Users can view members of their projects
CREATE POLICY "Users can view project members"
  ON prj_project_members FOR SELECT
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
    )
  );

-- Only owners and admins can add members
CREATE POLICY "Owners and admins can add members"
  ON prj_project_members FOR INSERT
  WITH CHECK (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- Only owners and admins can update member roles
CREATE POLICY "Owners and admins can update members"
  ON prj_project_members FOR UPDATE
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- Only owners and admins can remove members
CREATE POLICY "Owners and admins can remove members"
  ON prj_project_members FOR DELETE
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- ============================================
-- PAYMENTS POLICIES
-- ============================================

-- Users can view payments for their projects
CREATE POLICY "Users can view project payments"
  ON prj_project_payments FOR SELECT
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
    )
  );

-- Only owners and admins can manage payments
CREATE POLICY "Owners and admins can create payments"
  ON prj_project_payments FOR INSERT
  WITH CHECK (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners and admins can update payments"
  ON prj_project_payments FOR UPDATE
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Owners and admins can delete payments"
  ON prj_project_payments FOR DELETE
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- ============================================
-- TERMS POLICIES
-- ============================================

-- Users can view terms for their projects
CREATE POLICY "Users can view project terms"
  ON prj_project_terms FOR SELECT
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
    )
  );

-- Only owners can manage terms
CREATE POLICY "Only owners can create terms"
  ON prj_project_terms FOR INSERT
  WITH CHECK (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role = 'owner'
    )
  );

CREATE POLICY "Only owners can update terms"
  ON prj_project_terms FOR UPDATE
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role = 'owner'
    )
  );

CREATE POLICY "Only owners can delete terms"
  ON prj_project_terms FOR DELETE
  USING (
    project_id IN (
      SELECT project_id
      FROM prj_project_members
      WHERE user_id = auth.uid()
      AND role = 'owner'
    )
  );
RLS_EOF

# Verify file created
cat supabase/migrations/002_rls_policies.sql | head -30
```

**Now run this migration in Supabase Dashboard (same as STEP 6)**

<details>
<summary>📖 <strong>What is Row Level Security (RLS)?</strong></summary>

### Row Level Security Explained

**What is RLS?**
- Database-level security
- Controls which rows users can access
- Policies applied automatically to all queries
- **Impossible to bypass** (unlike application-level security)

**Without RLS:**
```javascript
// ❌ INSECURE - Anyone can access any data
const { data } = await supabase
  .from('prj_projects')
  .select('*')
// Returns ALL projects in database!
```

**With RLS:**
```javascript
// ✅ SECURE - Only returns user's projects
const { data } = await supabase
  .from('prj_projects')
  .select('*')
// Automatically filters to projects where user is member
```

**RLS Policy Structure:**
```sql
CREATE POLICY "policy_name"
  ON table_name
  FOR operation  -- SELECT, INSERT, UPDATE, DELETE
  USING (condition)  -- When to allow read
  WITH CHECK (condition)  -- When to allow write
```

**The `auth.uid()` Function:**
- Returns current user's ID
- Automatically set by Supabase auth
- NULL if not authenticated
- Used in all RLS policies

**Benefits:**
1. **Secure by default** - No data leaks
2. **Centralized** - Security logic in one place
3. **Auditable** - Clear security rules
4. **Type-safe** - Works with TypeScript
5. **Real-time safe** - Even websockets respect RLS

**Our Security Model:**
- **Viewers** - Read-only access
- **Members** - Can view and create tasks
- **Admins** - Can manage members and payments
- **Owners** - Full control including deletion

</details>

---

### 🎯 STEP 8 — Create RPC Functions for Data Access

```bash
cat > supabase/migrations/003_rpc_functions.sql << 'RPC_EOF'
-- ============================================
-- RPC FUNCTIONS FOR TYPE-SAFE DATA ACCESS
-- All database access through RPC functions
-- ============================================

-- ============================================
-- PROJECT FUNCTIONS
-- ============================================

-- Get all projects for current user
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

-- Get single project with user role
CREATE OR REPLACE FUNCTION get_project_by_id(project_uuid UUID)
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
  WHERE p.id = project_uuid
  AND pm.user_id = auth.uid();
END;
$$;

-- Create project and make user owner
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

-- ============================================
-- TASK FUNCTIONS
-- ============================================

-- Get tasks for a project
CREATE OR REPLACE FUNCTION get_project_tasks(project_uuid UUID)
RETURNS TABLE (
  id UUID,
  project_id UUID,
  title VARCHAR(200),
  description TEXT,
  status VARCHAR(20),
  due_date DATE,
  assigned_to UUID,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verify user has access to project
  IF NOT EXISTS (
    SELECT 1 FROM prj_project_members
    WHERE project_id = project_uuid
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied to project';
  END IF;

  RETURN QUERY
  SELECT
    t.id,
    t.project_id,
    t.title,
    t.description,
    t.status,
    t.due_date,
    t.assigned_to,
    t.created_by,
    t.created_at,
    t.updated_at
  FROM prj_tasks t
  WHERE t.project_id = project_uuid
  ORDER BY t.created_at DESC;
END;
$$;

-- Create task
CREATE OR REPLACE FUNCTION create_task(
  task_project_id UUID,
  task_title VARCHAR(200),
  task_description TEXT,
  task_due_date DATE,
  task_assigned_to UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_task_id UUID;
BEGIN
  -- Verify user has access to project
  IF NOT EXISTS (
    SELECT 1 FROM prj_project_members
    WHERE project_id = task_project_id
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied to project';
  END IF;

  -- Insert task
  INSERT INTO prj_tasks (
    project_id,
    title,
    description,
    due_date,
    assigned_to,
    created_by
  )
  VALUES (
    task_project_id,
    task_title,
    task_description,
    task_due_date,
    task_assigned_to,
    auth.uid()
  )
  RETURNING id INTO new_task_id;

  RETURN new_task_id;
END;
$$;

-- ============================================
-- MEMBER FUNCTIONS
-- ============================================

-- Get project members
CREATE OR REPLACE FUNCTION get_project_members(project_uuid UUID)
RETURNS TABLE (
  id UUID,
  project_id UUID,
  user_id UUID,
  role VARCHAR(20),
  joined_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verify user has access to project
  IF NOT EXISTS (
    SELECT 1 FROM prj_project_members
    WHERE project_id = project_uuid
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied to project';
  END IF;

  RETURN QUERY
  SELECT
    pm.id,
    pm.project_id,
    pm.user_id,
    pm.role,
    pm.joined_at
  FROM prj_project_members pm
  WHERE pm.project_id = project_uuid
  ORDER BY pm.joined_at ASC;
END;
$$;

-- Add project member
CREATE OR REPLACE FUNCTION add_project_member(
  member_project_id UUID,
  member_user_id UUID,
  member_role VARCHAR(20)
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_member_id UUID;
  current_user_role VARCHAR(20);
BEGIN
  -- Check if current user is owner or admin
  SELECT role INTO current_user_role
  FROM prj_project_members
  WHERE project_id = member_project_id
  AND user_id = auth.uid();

  IF current_user_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Only owners and admins can add members';
  END IF;

  -- Insert member
  INSERT INTO prj_project_members (project_id, user_id, role)
  VALUES (member_project_id, member_user_id, member_role)
  RETURNING id INTO new_member_id;

  RETURN new_member_id;
END;
$$;

-- ============================================
-- PAYMENT FUNCTIONS
-- ============================================

-- Get project payments
CREATE OR REPLACE FUNCTION get_project_payments(project_uuid UUID)
RETURNS TABLE (
  id UUID,
  project_id UUID,
  amount DECIMAL(10, 2),
  currency VARCHAR(3),
  status VARCHAR(20),
  due_date DATE,
  paid_date DATE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verify user has access to project
  IF NOT EXISTS (
    SELECT 1 FROM prj_project_members
    WHERE project_id = project_uuid
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied to project';
  END IF;

  RETURN QUERY
  SELECT
    pp.id,
    pp.project_id,
    pp.amount,
    pp.currency,
    pp.status,
    pp.due_date,
    pp.paid_date,
    pp.description,
    pp.created_at,
    pp.updated_at
  FROM prj_project_payments pp
  WHERE pp.project_id = project_uuid
  ORDER BY pp.due_date ASC;
END;
$$;
RPC_EOF

# Verify file created
cat supabase/migrations/003_rpc_functions.sql | head -40
```

**Now run this migration in Supabase Dashboard (same as STEP 6)**

<details>
<summary>📖 <strong>Why use RPC Functions?</strong></summary>

### RPC (Remote Procedure Call) Functions

**What are RPC functions?**
- PostgreSQL functions callable from JavaScript
- Server-side logic executed in database
- Type-safe parameters and returns
- Better security than direct table access

**Without RPC:**
```typescript
// ❌ Multiple round trips, complex joins in client
const { data: projects } = await supabase
  .from('prj_projects')
  .select('*')

// Separate query for roles
const { data: members } = await supabase
  .from('prj_project_members')
  .select('*')
  .eq('user_id', userId)

// Join in JavaScript - slow and error-prone
```

**With RPC:**
```typescript
// ✅ One call, database handles join, type-safe
const { data: projects } = await supabase
  .rpc('get_user_projects')
// Returns projects with user_role in one query!
```

**Benefits:**

**1. Performance**
- Single database round-trip
- Database handles joins (optimized)
- No data over-fetching

**2. Security**
- `SECURITY DEFINER` - runs with function owner's permissions
- Can bypass RLS when needed (carefully!)
- Validates permissions in function body

**3. Type Safety**
- Defined return types
- TypeScript knows exact shape
- Autocomplete works perfectly

**4. Business Logic**
- Complex operations atomic
- Create project + add owner in one transaction
- No race conditions

**5. Maintainability**
- Logic in one place
- Easy to update
- Testable in SQL

**Function Structure:**
```sql
CREATE OR REPLACE FUNCTION function_name(param_name TYPE)
RETURNS TABLE (column_name TYPE, ...)
LANGUAGE plpgsql
SECURITY DEFINER  -- Important for RLS bypass
AS $$
BEGIN
  -- Verify permissions
  IF NOT authorized THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Return data
  RETURN QUERY SELECT ...;
END;
$$;
```

**Why `SECURITY DEFINER`?**
- Function runs with creator's permissions
- Can access tables even if RLS blocks user
- Function implements its own security checks
- More flexible than pure RLS

**Example: create_project**
- Inserts into prj_projects
- Automatically adds user as owner to prj_project_members
- Atomic transaction - both succeed or both fail
- Returns new project ID

</details>

---

### 🎯 STEP 9 — Create Server-Side Supabase Client

```bash
cat > src/lib/supabase/server.ts << 'SERVER_EOF'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { Database } from '@/types/database'

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
SERVER_EOF

# Verify file created
cat src/lib/supabase/server.ts
```

<details>
<summary>📖 <strong>Server vs Browser Client</strong></summary>

### Supabase Client Types

**Two different clients for different environments:**

**1. Browser Client (src/lib/supabase/client.ts)**
```typescript
import { createBrowserClient } from '@supabase/ssr'

// Used in Client Components
'use client'
export function ClientComponent() {
  const supabase = createClient() // Browser client
  // ...
}
```

**2. Server Client (src/lib/supabase/server.ts)**
```typescript
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

// Used in Server Components
export async function ServerComponent() {
  const supabase = await createClient() // Server client
  // ...
}
```

**Key Differences:**

| Feature | Browser Client | Server Client |
|---------|---------------|---------------|
| Where | Client Components | Server Components, API Routes |
| Cookies | Browser cookies | Next.js cookies API |
| Auth | Client-side auth | Server-side auth |
| Performance | Network calls from browser | Direct DB connection |
| Security | Publishable key only | Can use service role |

**Why cookies for auth?**
- Supabase stores JWT token in cookie
- Cookie sent automatically with requests
- More secure than localStorage
- Works with SSR

**The cookie handlers:**
```typescript
cookies: {
  getAll() {
    // Read all cookies from Next.js
    return cookieStore.getAll()
  },
  setAll(cookiesToSet) {
    // Write cookies back to Next.js
    cookiesToSet.forEach(({ name, value, options }) =>
      cookieStore.set(name, value, options)
    )
  },
}
```

**When to use which:**
- **Browser client**: Forms, interactive UI, client-side mutations
- **Server client**: Initial data fetching, Server Actions, API routes

</details>

---

### 🎯 STEP 10 — Create Middleware Helper for Session Refresh

```bash
cat > src/lib/supabase/middleware.ts << 'MIDDLEWARE_EOF'
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

/**
 * Updates and refreshes Supabase session in middleware/proxy
 *
 * This function:
 * 1. Creates a Supabase server client with cookie handlers
 * 2. Refreshes the auth token if expired (via getUser())
 * 3. Updates cookies in both request and response
 * 4. Returns the response with refreshed session
 *
 * Why this is needed:
 * - Server Components cannot write cookies
 * - Middleware/proxy can intercept requests and refresh tokens
 * - Prevents expired session errors in Server Components
 *
 * @param request - The incoming Next.js request
 * @returns NextResponse with updated cookies
 */
export async function updateSession(request: NextRequest) {
  // Create a response object that we'll modify
  let supabaseResponse = NextResponse.next({
    request,
  })

  // Create Supabase client with custom cookie handlers
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!,
    {
      cookies: {
        // Read all cookies from the request
        getAll() {
          return request.cookies.getAll()
        },
        // Write cookies to both request and response
        setAll(cookiesToSet) {
          // Set cookies on the request (for Server Components to read)
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )

          // Create new response with updated request cookies
          supabaseResponse = NextResponse.next({
            request,
          })

          // Set cookies on the response (for browser to receive)
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // IMPORTANT: Refresh session if expired
  // This triggers the cookie refresh via setAll above
  // getUser() is secure - it validates the JWT signature
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Optional: Add user info to request headers for Server Components
  // This avoids additional database calls in components
  if (user) {
    supabaseResponse.headers.set('x-user-id', user.id)
    supabaseResponse.headers.set('x-user-email', user.email || '')
  }

  return supabaseResponse
}

/**
 * Protected route checker
 * Use this in your proxy.ts to redirect unauthenticated users
 *
 * Example:
 * const response = await updateSession(request)
 * const isProtected = isProtectedRoute(request.nextUrl.pathname)
 * if (isProtected && !response.headers.get('x-user-id')) {
 *   return NextResponse.redirect(new URL('/login', request.url))
 * }
 */
export function isProtectedRoute(pathname: string): boolean {
  const protectedPaths = [
    '/dashboard',
    '/projects',
    '/profile',
    '/settings',
  ]

  return protectedPaths.some(path => pathname.startsWith(path))
}

/**
 * Public-only route checker
 * Use this to redirect authenticated users away from login/signup
 *
 * Example:
 * const isPublicOnly = isPublicOnlyRoute(request.nextUrl.pathname)
 * if (isPublicOnly && response.headers.get('x-user-id')) {
 *   return NextResponse.redirect(new URL('/dashboard', request.url))
 * }
 */
export function isPublicOnlyRoute(pathname: string): boolean {
  const publicOnlyPaths = [
    '/login',
    '/signup',
    '/forgot-password',
  ]

  return publicOnlyPaths.some(path => pathname.startsWith(path))
}
MIDDLEWARE_EOF

# Verify file created
cat src/lib/supabase/middleware.ts | head -20
```

<details>
<summary>📖 <strong>Why Server Components Can't Write Cookies</strong></summary>

### The Cookie Problem in Next.js

**Server Components are read-only:**
- They run on the server during rendering
- They cannot modify the HTTP response
- They cannot set cookies directly

**Why this matters for auth:**
```typescript
// ❌ This DOESN'T work in Server Component
export default async function Page() {
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  // If session is expired, Supabase needs to refresh it
  // But Server Component can't write the new cookie!
  // Result: User appears logged out
}
```

**The solution: Middleware/Proxy**
- Runs BEFORE Server Components render
- Has full access to request/response
- Can write cookies
- Refreshes session automatically

**How it works:**
1. **Request comes in** → Proxy intercepts it
2. **Check session** → Call `getUser()` to validate token
3. **Token expired?** → Supabase automatically refreshes it
4. **Write new cookie** → Proxy updates response cookies
5. **Continue to Server Component** → Component sees fresh session

**Cookie flow:**
```
Browser → Proxy (refresh token if needed) → Server Component (read fresh session)
         ↓
         Write new cookie to response
         ↓
Browser receives updated cookie
```

**Key benefits:**
- ✅ Sessions never expire unexpectedly
- ✅ Server Components always see valid sessions
- ✅ Users stay logged in seamlessly
- ✅ No manual refresh logic needed

</details>

---

### 🎯 STEP 11 — Create Proxy for Automatic Session Refresh (Next.js 16)

```bash
cat > proxy.ts << 'PROXY_EOF'
import { type NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

/**
 * Next.js 16 Proxy
 *
 * Replaces middleware.ts in Next.js 16
 * Runs on Node.js runtime (not Edge)
 *
 * Purpose:
 * - Refresh Supabase auth sessions automatically
 * - Update cookies for authenticated users
 * - Runs before every request that matches the config
 *
 * Why "proxy" not "middleware"?
 * - Clearer naming for network boundary
 * - Node.js runtime for predictable behavior
 * - Separates routing logic from app logic
 */
export async function proxy(request: NextRequest) {
  // Refresh Supabase session and update cookies
  return await updateSession(request)
}

/**
 * Config: Which routes should trigger this proxy
 *
 * Matches all routes EXCEPT:
 * - Static files (_next/static)
 * - Image optimization (_next/image)
 * - Favicon
 * - Public images (svg, png, jpg, etc.)
 *
 * This ensures session refresh on every page navigation
 * but skips unnecessary calls for static assets
 */
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - *.svg, *.png, *.jpg, *.jpeg, *.gif, *.webp (image files)
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
PROXY_EOF

# Verify file created
cat proxy.ts
```

<details>
<summary>📖 <strong>Next.js 16: proxy.ts vs middleware.ts</strong></summary>

### What Changed in Next.js 16?

**Old approach (Next.js 15 and earlier):**
```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  // ... logic
}
```

**New approach (Next.js 16):**
```typescript
// proxy.ts
export function proxy(request: NextRequest) {
  // ... same logic
}
```

**Why the change?**

**1. Naming Confusion**
- "Middleware" is confusing (like Express middleware)
- Developers expected it to work like app-level middleware
- Actually runs at network boundary, not in app

**2. Runtime Clarity**
- `proxy.ts` runs on **Node.js runtime**
- More predictable than Edge runtime
- Better for auth, database calls
- Full Node.js API access

**3. Separation of Concerns**
- **Proxy**: Network boundary (routing, redirects, session refresh)
- **Server Actions**: App logic (mutations, business logic)
- **Route Handlers**: API endpoints (REST, webhooks)

**Migration:**
```bash
# Simple rename
mv middleware.ts proxy.ts

# Update function name
# Old: export function middleware
# New: export function proxy
```

**When to use proxy.ts:**
- ✅ Authentication session refresh (our use case)
- ✅ Redirects and rewrites
- ✅ Header modifications
- ✅ Logging and analytics
- ✅ A/B testing routing

**When NOT to use proxy.ts:**
- ❌ Heavy database queries (use Server Actions)
- ❌ Complex business logic (use Route Handlers)
- ❌ Data fetching (use Server Components)

**Matcher config explained:**
```typescript
matcher: [
  // Match everything EXCEPT static files
  '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg)$).*)',
]
```

This regex:
- `(?!...)` - Negative lookahead (exclude these patterns)
- `_next/static` - Next.js static files (JS, CSS bundles)
- `_next/image` - Optimized images
- `favicon.ico` - Favicon
- `.*\\.(?:svg|png|jpg)$` - Image files

**Why exclude static files?**
- No session needed for images/CSS/JS
- Reduces unnecessary proxy calls
- Better performance
- Lower serverless function costs

**Security note:**
```typescript
// ✅ SECURE: getUser() validates JWT signature
const { data: { user } } = await supabase.auth.getUser()

// ❌ INSECURE in proxy: getSession() doesn't revalidate
const { data: { session } } = await supabase.auth.getSession()
```

Always use `getUser()` in proxy/middleware for security!

</details>

---

### 🎯 STEP 12 — Create Database TypeScript Types

```bash
# Create placeholder types file (will be auto-generated later)
mkdir -p src/types

cat > src/types/database.ts << 'DATABASE_TYPES_EOF'
/**
 * Database type definitions
 *
 * TODO: Auto-generate these types from Supabase schema
 *
 * For now, using manual types. In production:
 * 1. Install Supabase CLI: npm install -g supabase
 * 2. Login: supabase login
 * 3. Generate types: supabase gen types typescript --project-id YOUR_PROJECT_ID > src/types/database.ts
 */

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
      prj_tasks: {
        Row: {
          id: string
          project_id: string
          title: string
          description: string | null
          status: string
          due_date: string | null
          assigned_to: string | null
          created_by: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          project_id: string
          title: string
          description?: string | null
          status?: string
          due_date?: string | null
          assigned_to?: string | null
          created_by: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          project_id?: string
          title?: string
          description?: string | null
          status?: string
          due_date?: string | null
          assigned_to?: string | null
          created_by?: string
          created_at?: string
          updated_at?: string
        }
      }
      prj_project_members: {
        Row: {
          id: string
          project_id: string
          user_id: string
          role: string
          joined_at: string
        }
        Insert: {
          id?: string
          project_id: string
          user_id: string
          role?: string
          joined_at?: string
        }
        Update: {
          id?: string
          project_id?: string
          user_id?: string
          role?: string
          joined_at?: string
        }
      }
      prj_project_payments: {
        Row: {
          id: string
          project_id: string
          amount: number
          currency: string
          status: string
          due_date: string
          paid_date: string | null
          description: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          project_id: string
          amount: number
          currency?: string
          status?: string
          due_date: string
          paid_date?: string | null
          description?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          project_id?: string
          amount?: number
          currency?: string
          status?: string
          due_date?: string
          paid_date?: string | null
          description?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      prj_project_terms: {
        Row: {
          id: string
          project_id: string
          title: string
          content: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          project_id: string
          title: string
          content: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          project_id?: string
          title?: string
          content?: string
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
          start_date: string
          end_date: string | null
          is_active: boolean
          status: string
          created_at: string
          updated_at: string
          user_role: string
        }>
      }
      get_project_by_id: {
        Args: { project_uuid: string }
        Returns: Array<{
          id: string
          name: string
          description: string | null
          start_date: string
          end_date: string | null
          is_active: boolean
          status: string
          created_at: string
          updated_at: string
          user_role: string
        }>
      }
      create_project: {
        Args: {
          project_name: string
          project_description: string
          project_start_date: string
          project_end_date: string
        }
        Returns: string
      }
      get_project_tasks: {
        Args: { project_uuid: string }
        Returns: Array<{
          id: string
          project_id: string
          title: string
          description: string | null
          status: string
          due_date: string | null
          assigned_to: string | null
          created_by: string
          created_at: string
          updated_at: string
        }>
      }
      create_task: {
        Args: {
          task_project_id: string
          task_title: string
          task_description: string
          task_due_date: string
          task_assigned_to: string
        }
        Returns: string
      }
      get_project_members: {
        Args: { project_uuid: string }
        Returns: Array<{
          id: string
          project_id: string
          user_id: string
          role: string
          joined_at: string
        }>
      }
      add_project_member: {
        Args: {
          member_project_id: string
          member_user_id: string
          member_role: string
        }
        Returns: string
      }
      get_project_payments: {
        Args: { project_uuid: string }
        Returns: Array<{
          id: string
          project_id: string
          amount: number
          currency: string
          status: string
          due_date: string
          paid_date: string | null
          description: string | null
          created_at: string
          updated_at: string
        }>
      }
    }
  }
}
DATABASE_TYPES_EOF

# Verify file created
cat src/types/database.ts | head -20
```

<details>
<summary>📖 <strong>Understanding Database Types</strong></summary>

### TypeScript Database Types

**What are these types for?**
- Full type safety for Supabase queries
- Autocomplete for table names and columns
- Catch errors at compile time, not runtime
- Know exact shape of data returned

**Three type categories:**

**1. Row Types**
```typescript
Row: {
  id: string
  name: string
  // ... all columns as they exist in DB
}
```
- Exact database column types
- Used when reading data (SELECT)
- All fields present

**2. Insert Types**
```typescript
Insert: {
  id?: string  // Optional - has default
  name: string  // Required - no default
  created_at?: string  // Optional - has default
}
```
- Used when inserting data (INSERT)
- Required fields vs optional (with defaults)
- Generated IDs optional

**3. Update Types**
```typescript
Update: {
  id?: string
  name?: string  // All optional
  // ... update only what you want
}
```
- Used when updating data (UPDATE)
- All fields optional
- Update only what you need

**RPC Function Types:**
```typescript
Functions: {
  get_user_projects: {
    Args: Record<string, never>  // No arguments
    Returns: Array<{...}>  // Array of projects
  }
  create_project: {
    Args: { project_name: string, ... }  // Named arguments
    Returns: string  // Returns UUID
  }
}
```

**How types are used:**
```typescript
// Type-safe client
const supabase = createClient<Database>()

// TypeScript knows exact columns
const { data } = await supabase
  .from('prj_projects')  // Autocomplete table names
  .select('name, description')  // Autocomplete columns

// data is typed as:
// Array<{ name: string; description: string | null }>

// RPC with types
const { data } = await supabase
  .rpc('get_user_projects')
// data is Array<{ id: string, name: string, ..., user_role: string }>
```

**Auto-generation (Production):**
```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Generate types from live database
supabase gen types typescript --project-id YOUR_PROJECT_ID > src/types/database.ts
```

**Benefits:**
1. **No typos** - `prj_project` vs `prj_projects` caught at compile time
2. **Column changes** - Regenerate types, TypeScript shows all breaking changes
3. **Refactoring** - Rename column in DB, regenerate types, fix all usages
4. **Documentation** - Types document database structure

**For this lesson:**
- Manual types (easier to learn)
- In production: auto-generate from schema

</details>

---

### 🎯 STEP 13 — Create Example RPC Usage File

```bash
cat > src/lib/supabase/rpc-examples.ts << 'RPC_EXAMPLES_EOF'
/**
 * Example RPC function usage
 * These are type-safe database queries using RPC functions
 */

import { createClient as createServerClient } from '@/lib/supabase/server'
import { createClient as createBrowserClient } from '@/lib/supabase/client'

// ============================================
// SERVER-SIDE EXAMPLES (Server Components)
// ============================================

/**
 * Get all projects for current user
 * Returns projects with user's role in each project
 */
export async function getUserProjects() {
  const supabase = await createServerClient()

  const { data, error } = await supabase
    .rpc('get_user_projects')

  if (error) {
    console.error('Error fetching projects:', error)
    return []
  }

  return data
}

/**
 * Get single project by ID
 * Includes user's role in the project
 */
export async function getProjectById(projectId: string) {
  const supabase = await createServerClient()

  const { data, error } = await supabase
    .rpc('get_project_by_id', { project_uuid: projectId })

  if (error) {
    console.error('Error fetching project:', error)
    return null
  }

  return data?.[0] || null
}

/**
 * Create new project
 * Automatically adds current user as owner
 */
export async function createProject(input: {
  name: string
  description: string
  startDate: string
  endDate: string
}) {
  const supabase = await createServerClient()

  const { data, error } = await supabase
    .rpc('create_project', {
      project_name: input.name,
      project_description: input.description,
      project_start_date: input.startDate,
      project_end_date: input.endDate,
    })

  if (error) {
    console.error('Error creating project:', error)
    return null
  }

  return data // Returns new project UUID
}

/**
 * Get all tasks for a project
 */
export async function getProjectTasks(projectId: string) {
  const supabase = await createServerClient()

  const { data, error } = await supabase
    .rpc('get_project_tasks', { project_uuid: projectId })

  if (error) {
    console.error('Error fetching tasks:', error)
    return []
  }

  return data
}

/**
 * Create new task in project
 */
export async function createTask(input: {
  projectId: string
  title: string
  description: string
  dueDate: string
  assignedTo: string
}) {
  const supabase = await createServerClient()

  const { data, error } = await supabase
    .rpc('create_task', {
      task_project_id: input.projectId,
      task_title: input.title,
      task_description: input.description,
      task_due_date: input.dueDate,
      task_assigned_to: input.assignedTo,
    })

  if (error) {
    console.error('Error creating task:', error)
    return null
  }

  return data // Returns new task UUID
}

/**
 * Get all members of a project
 */
export async function getProjectMembers(projectId: string) {
  const supabase = await createServerClient()

  const { data, error } = await supabase
    .rpc('get_project_members', { project_uuid: projectId })

  if (error) {
    console.error('Error fetching members:', error)
    return []
  }

  return data
}

/**
 * Add member to project
 */
export async function addProjectMember(input: {
  projectId: string
  userId: string
  role: 'owner' | 'admin' | 'member' | 'viewer'
}) {
  const supabase = await createServerClient()

  const { data, error } = await supabase
    .rpc('add_project_member', {
      member_project_id: input.projectId,
      member_user_id: input.userId,
      member_role: input.role,
    })

  if (error) {
    console.error('Error adding member:', error)
    return null
  }

  return data // Returns new member UUID
}

/**
 * Get all payments for a project
 */
export async function getProjectPayments(projectId: string) {
  const supabase = await createServerClient()

  const { data, error } = await supabase
    .rpc('get_project_payments', { project_uuid: projectId })

  if (error) {
    console.error('Error fetching payments:', error)
    return []
  }

  return data
}

// ============================================
// CLIENT-SIDE EXAMPLES (Client Components)
// ============================================

/**
 * Client-side project fetch
 * Use in 'use client' components
 */
export async function getUserProjectsClient() {
  const supabase = createBrowserClient()

  const { data, error } = await supabase
    .rpc('get_user_projects')

  if (error) {
    console.error('Error fetching projects:', error)
    return []
  }

  return data
}

/**
 * Client-side project creation
 * Use in forms, user interactions
 */
export async function createProjectClient(input: {
  name: string
  description: string
  startDate: string
  endDate: string
}) {
  const supabase = createBrowserClient()

  const { data, error } = await supabase
    .rpc('create_project', {
      project_name: input.name,
      project_description: input.description,
      project_start_date: input.startDate,
      project_end_date: input.endDate,
    })

  if (error) {
    console.error('Error creating project:', error)
    return null
  }

  return data
}
RPC_EXAMPLES_EOF

# Verify file created
cat src/lib/supabase/rpc-examples.ts | head -30
```

<details>
<summary>📖 <strong>How to use RPC functions</strong></summary>

### Using RPC Functions

**Basic RPC call structure:**
```typescript
const { data, error } = await supabase
  .rpc('function_name', {
    argument_name: value
  })
```

**Server vs Client:**

**Server Component (default in Next.js 16):**
```typescript
// app/projects/page.tsx
import { getUserProjects } from '@/lib/supabase/rpc-examples'

export default async function ProjectsPage() {
  const projects = await getUserProjects()

  return (
    <div>
      {projects.map(project => (
        <div key={project.id}>
          <h2>{project.name}</h2>
          <span>Your role: {project.user_role}</span>
        </div>
      ))}
    </div>
  )
}
```

**Client Component (interactive):**
```typescript
// components/CreateProjectForm.tsx
'use client'

import { createProjectClient } from '@/lib/supabase/rpc-examples'
import { useState } from 'react'

export function CreateProjectForm() {
  const [name, setName] = useState('')

  async function handleSubmit() {
    const projectId = await createProjectClient({
      name,
      description: '...',
      startDate: '2025-01-01',
      endDate: '2025-12-31',
    })

    if (projectId) {
      console.log('Created project:', projectId)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <input value={name} onChange={(e) => setName(e.target.value)} />
      <button type="submit">Create Project</button>
    </form>
  )
}
```

**Error handling:**
```typescript
const { data, error } = await supabase.rpc('get_user_projects')

if (error) {
  // RPC function raised exception
  // Or database error
  // Or permission denied
  console.error('RPC error:', error.message)
  return []
}

// data is typed correctly!
return data
```

**Type safety:**
```typescript
// TypeScript knows argument names and types
await supabase.rpc('create_project', {
  project_name: 'My Project',  // ✅ Correct
  // name: 'My Project',  // ❌ TypeScript error - wrong argument name
  // project_name: 123,  // ❌ TypeScript error - wrong type
})
```

**Benefits of this pattern:**
1. **All data access in one place** - Easy to find and update
2. **Consistent error handling** - Same pattern everywhere
3. **Type-safe** - TypeScript catches errors
4. **Cacheable** - Can add React Cache easily
5. **Testable** - Mock the RPC functions in tests

</details>

---

### 🎯 STEP 14 — Verify Installation

```bash
# Check all files created
echo "📁 Checking Supabase files..."
ls -lh src/lib/supabase/
ls -lh src/types/
ls -lh supabase/migrations/

echo ""
echo "🔄 Checking proxy file..."
ls -lh proxy.ts

echo ""
echo "📦 Checking package installation..."
cat package.json | grep supabase

echo ""
echo "🔐 Checking environment template..."
cat .env.local.example | grep SUPABASE

echo ""
echo "✅ Verification complete!"
```

**Expected output:**
```
📁 Checking Supabase files...
client.ts
server.ts
middleware.ts
rpc-examples.ts

database.ts

001_initial_schema.sql
002_rls_policies.sql
003_rpc_functions.sql

🔄 Checking proxy file...
proxy.ts

📦 Checking package installation...
"@supabase/supabase-js": "^2.x.x"

🔐 Checking environment template...
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...

✅ Verification complete!
```

---

## ✅ 3. CHECKLIST

### 🎯 Supabase Project Setup

- [ ] Created Supabase project at supabase.com
- [ ] Saved database password securely
- [ ] Copied Project URL from Settings → API
- [ ] Copied Publishable key from Settings → API
- [ ] Copied Service Role key from Settings → API
- [ ] Created `.env.local` file with all credentials
- [ ] Replaced placeholder values with actual keys
- [ ] Verified `.env.local` is in `.gitignore`

### 🎯 Package Installation

- [ ] Ran `npm install @supabase/supabase-js`
- [ ] Verified package in package.json
- [ ] No installation errors

### 🎯 File Structure

- [ ] Created `src/lib/supabase/` directory
- [ ] Created `src/lib/supabase/client.ts` (browser client)
- [ ] Created `src/lib/supabase/server.ts` (server client)
- [ ] Created `src/lib/supabase/middleware.ts` (session refresh helper)
- [ ] Created `src/lib/supabase/rpc-examples.ts` (usage examples)
- [ ] Created `src/types/database.ts` (type definitions)
- [ ] Created `supabase/migrations/` directory
- [ ] Created `proxy.ts` at project root (Next.js 16)

### 🎯 Proxy & Session Management (Next.js 16)

- [ ] Created `src/lib/supabase/middleware.ts` with `updateSession()` function
- [ ] Created `isProtectedRoute()` helper function
- [ ] Created `isPublicOnlyRoute()` helper function
- [ ] Created `proxy.ts` at root with `proxy()` function
- [ ] Configured matcher to exclude static files
- [ ] Proxy uses `updateSession()` from middleware helper
- [ ] Cookie handlers for `getAll()` and `setAll()` implemented
- [ ] Session refresh uses `getUser()` (secure, not `getSession()`)
- [ ] Request headers set for user info (`x-user-id`, `x-user-email`)
- [ ] Understands difference between proxy.ts and middleware.ts

### 🎯 Database Schema

- [ ] Created `001_initial_schema.sql` migration
- [ ] Migration includes `prj_projects` table
- [ ] Migration includes `prj_tasks` table with foreign key
- [ ] Migration includes `prj_project_members` table (M:N)
- [ ] Migration includes `prj_project_payments` table
- [ ] Migration includes `prj_project_terms` table
- [ ] All tables have UUID primary keys
- [ ] All tables have timestamp fields
- [ ] Indexes created for foreign keys
- [ ] Triggers created for `updated_at` auto-update
- [ ] Ran migration in Supabase Dashboard SQL Editor
- [ ] Verified tables exist in Database → Tables view

### 🎯 Row Level Security

- [ ] Created `002_rls_policies.sql` migration
- [ ] RLS enabled on all tables
- [ ] SELECT policies created for all tables
- [ ] INSERT policies created for all tables
- [ ] UPDATE policies created for all tables
- [ ] DELETE policies created for all tables
- [ ] Policies check user membership via `prj_project_members`
- [ ] Role-based permissions implemented (owner, admin, member, viewer)
- [ ] Ran RLS migration in Supabase Dashboard
- [ ] Verified policies in Database → Policies view

### 🎯 RPC Functions

- [ ] Created `003_rpc_functions.sql` migration
- [ ] `get_user_projects()` function created
- [ ] `get_project_by_id()` function created
- [ ] `create_project()` function created
- [ ] `get_project_tasks()` function created
- [ ] `create_task()` function created
- [ ] `get_project_members()` function created
- [ ] `add_project_member()` function created
- [ ] `get_project_payments()` function created
- [ ] All functions use `SECURITY DEFINER`
- [ ] All functions verify user permissions
- [ ] Ran RPC migration in Supabase Dashboard
- [ ] Verified functions in Database → Functions view

### 🎯 TypeScript Configuration

- [ ] Database types file created
- [ ] Types include all tables (Row, Insert, Update)
- [ ] Types include all RPC functions (Args, Returns)
- [ ] Types properly exported
- [ ] No TypeScript errors in type file

### 🎯 Supabase Clients

- [ ] Browser client uses `createBrowserClient`
- [ ] Browser client typed with `<Database>`
- [ ] Server client uses `createServerClient`
- [ ] Server client handles cookies correctly
- [ ] Server client typed with `<Database>`
- [ ] Both clients use publishable key (not service role)

### 🎯 Code Quality

- [ ] All files use import alias `@/`
- [ ] No relative imports (`../`)
- [ ] All table names use `prj_` prefix
- [ ] Type-safe function signatures
- [ ] Error handling in RPC examples
- [ ] Comments explain complex logic
- [ ] Consistent naming conventions

### 🎯 Security Verification

- [ ] `.env.local` NOT committed to git
- [ ] Service role key NOT used in client code
- [ ] RLS policies tested manually in dashboard
- [ ] No way to bypass RLS from client
- [ ] All mutations require authentication
- [ ] Permission checks in RPC functions

### 🎯 Final Verification

- [ ] Can view Supabase project in dashboard
- [ ] Tables visible in Database view
- [ ] Policies visible in Policies view
- [ ] Functions visible in Functions view
- [ ] No build errors: `npm run build`
- [ ] Ready for Lesson 3 (Authentication)

---

## 🎓 What You Learned

**In this lesson you configured:**

✅ **Supabase Project** - Cloud PostgreSQL database
✅ **Database Schema** - 5 tables with relationships (1:M, M:N)
✅ **Row Level Security** - Database-level permission system
✅ **RPC Functions** - Type-safe server-side data access
✅ **TypeScript Types** - Full type safety for queries
✅ **Supabase Clients** - Browser and server integration
✅ **Migration Files** - Version-controlled database changes
✅ **Next.js 16 Proxy** - Automatic session refresh infrastructure
✅ **Middleware Helper** - Cookie management for authentication

**Key Concepts Mastered:**
- PostgreSQL relational database design
- Foreign keys and CASCADE deletion
- Row Level Security (RLS) policies
- Remote Procedure Call (RPC) functions
- SECURITY DEFINER for permission bypass
- Server vs Browser Supabase clients
- Type-safe database operations
- UUID primary keys vs SERIAL
- Triggers for automatic field updates
- Database migrations and version control
- **Next.js 16 proxy.ts** (replaces middleware.ts)
- **Session refresh** with cookie management
- **Server Components cookie limitation** and workarounds
- **Node.js runtime** vs Edge runtime
- **Protected routes infrastructure** (helpers ready for Lesson 3)

**Next Lesson:** Module 1, Lesson 3 - Authentication with Supabase Auth (Email/Password, OAuth, Protected Routes)

---

**🎉 Lesson 2 Complete!** Your Next.js app now has a fully configured database with security policies and type-safe data access!

