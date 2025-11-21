# Astro 5.0 Tutorial - Lesson 4: Supabase Setup & Database

**Prerequisites:** Complete Lessons 1-3 (Setup, Content Layer, MDX)

---

## ✅ 1. DESC (Description)

### What You'll Learn

In this lesson, you'll integrate Supabase as your backend database and set up a production-ready PostgreSQL schema.

**Core Concepts:**
- ✅ Supabase project creation and configuration
- ✅ PostgreSQL schema design with relationships
- ✅ Row Level Security (RLS) policies
- ✅ Database migrations for version control
- ✅ Server-side and client-side Supabase instances
- ✅ Environment variables with `astro:env`
- ✅ Type generation from database schema
- ✅ Foreign keys and relationships
- ✅ Database triggers and functions

**What You'll Build:**
- Supabase project with PostgreSQL database
- Complete database schema (users, profiles, comments, likes, bookmarks)
- RLS policies for secure data access
- Migration files for reproducible schema
- Server and client Supabase utilities
- Type-safe database queries
- Environment configuration

---

### Why Supabase?

**Supabase is the open-source Firebase alternative:**

1. **PostgreSQL Database** - Full power of Postgres
2. **Built-in Auth** - Email, OAuth, magic links
3. **Row Level Security** - Database-level access control
4. **Real-time** - WebSocket subscriptions
5. **Storage** - S3-compatible file storage
6. **Auto-generated APIs** - REST and GraphQL

**Architecture:**
```
Frontend (Astro)
    ↓
Supabase Client
    ↓
Supabase (Backend)
├── PostgreSQL Database
├── Authentication
├── Storage
└── Real-time
```

---

### Database Schema Overview

**Tables we'll create:**

1. **user_profiles** - Extended user information
   - Links to Supabase Auth users (1:1)
   - Display name, bio, avatar

2. **comments** - Blog post comments
   - Nested comments (parent_id for threading)
   - Links to users and blog posts

3. **likes** - Post likes
   - Track who liked what
   - Prevent duplicate likes

4. **bookmarks** - Saved posts
   - User's reading list
   - Quick access to favorites

5. **portfolio_projects** - Portfolio items (bonus)
   - Showcase projects
   - Images, links, tech stack

---

## ✅ 2. CODE (Implementation)

### STEP 1: Create Supabase Project

```bash
# Go to https://supabase.com
# Click "Start your project"
# Create a new organization (free tier)
# Create a new project:
#   - Name: astro-blog
#   - Database Password: (generate strong password - SAVE IT!)
#   - Region: Choose closest to you
#   - Wait ~2 minutes for setup

echo "
✅ Supabase project created!

Next, get your project credentials:
1. Go to Project Settings → API
2. Copy 'Project URL'
3. Copy 'anon/public' key (now called 'publishable key')
4. Copy 'service_role' key (keep secret!)
"
```

---

### STEP 2: Install Supabase Client

```bash
# Install Supabase JavaScript client
npm install @supabase/supabase-js

# Verify installation
npm list @supabase/supabase-js
```

---

### STEP 3: Configure Environment Variables

```bash
# Create .env file
cat > .env << 'EOF'
# Supabase Configuration
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
EOF

# Add .env to .gitignore (should already be there)
echo ".env" >> .gitignore

# Create example file for others
cat > .env.example << 'EOF'
# Supabase Configuration
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
EOF
```

<details>
<summary>📖 <strong>Environment Variables Best Practices</strong></summary>

**PUBLIC_ prefix:**
- Variables prefixed with `PUBLIC_` are exposed to the browser
- Use for client-side API keys (like Supabase anon key)
- Never include secrets!

**Non-prefixed variables:**
- Only available server-side
- Use for sensitive keys (service role key)
- Never exposed to the browser

**Example:**
```javascript
// ✅ Available in browser
const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;

// ❌ Only server-side (returns undefined in browser)
const serviceKey = import.meta.env.SUPABASE_SERVICE_ROLE_KEY;
```

**Security:**
- Never commit `.env` to git
- Always create `.env.example` without real values
- Rotate keys if exposed
- Use different projects for dev/staging/production
</details>

---

### STEP 4: Create Supabase Client Utilities

```bash
# Create lib directory structure
mkdir -p src/lib/supabase

# Create server-side client
cat > src/lib/supabase/server.ts << 'EOF'
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

/**
 * Server-side Supabase client
 * - Uses service role key (has admin privileges)
 * - Only use on server (API routes, SSR)
 * - Can bypass RLS policies
 */
export function createServerClient() {
  const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = import.meta.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error('Missing Supabase environment variables');
  }

  return createClient<Database>(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
EOF

# Create client-side client
cat > src/lib/supabase/client.ts << 'EOF'
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

/**
 * Client-side Supabase client
 * - Uses anon/public key
 * - Safe to use in browser
 * - Respects RLS policies
 */
const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
  },
});
EOF
```

---

### STEP 5: Create Database Types Placeholder

```bash
cat > src/lib/supabase/types.ts << 'EOF'
/**
 * Database types
 * Generated from Supabase schema
 *
 * To regenerate:
 * npx supabase gen types typescript --project-id YOUR_PROJECT_ID > src/lib/supabase/types.ts
 */

export interface Database {
  public: {
    Tables: {
      user_profiles: {
        Row: {
          id: string;
          user_id: string;
          display_name: string | null;
          bio: string | null;
          avatar_url: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          display_name?: string | null;
          bio?: string | null;
          avatar_url?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          display_name?: string | null;
          bio?: string | null;
          avatar_url?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      comments: {
        Row: {
          id: string;
          post_slug: string;
          user_id: string;
          parent_id: string | null;
          content: string;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          post_slug: string;
          user_id: string;
          parent_id?: string | null;
          content: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          post_slug?: string;
          user_id?: string;
          parent_id?: string | null;
          content?: string;
          created_at?: string;
          updated_at?: string;
        };
      };
      likes: {
        Row: {
          id: string;
          post_slug: string;
          user_id: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          post_slug: string;
          user_id: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          post_slug?: string;
          user_id?: string;
          created_at?: string;
        };
      };
      bookmarks: {
        Row: {
          id: string;
          post_slug: string;
          user_id: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          post_slug: string;
          user_id: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          post_slug?: string;
          user_id?: string;
          created_at?: string;
        };
      };
    };
    Views: {};
    Functions: {};
  };
}
EOF
```

---

### STEP 6: Create Database Migrations

```bash
# Create migrations directory
mkdir -p supabase/migrations

# Create initial schema migration
cat > supabase/migrations/001_initial_schema.sql << 'EOF'
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- USER PROFILES TABLE
-- =============================================
-- Extends Supabase Auth users with custom fields

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Ensure one profile per user
  UNIQUE(user_id)
);

-- Index for faster lookups
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- COMMENTS TABLE
-- =============================================
-- Supports nested comments (replies)

CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_slug TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Validation
  CHECK (LENGTH(content) >= 1 AND LENGTH(content) <= 5000)
);

-- Indexes
CREATE INDEX idx_comments_post_slug ON comments(post_slug);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_id);

-- Auto-update timestamp
CREATE TRIGGER update_comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- LIKES TABLE
-- =============================================
-- Track post likes (one per user per post)

CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_slug TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Ensure one like per user per post
  UNIQUE(post_slug, user_id)
);

-- Indexes
CREATE INDEX idx_likes_post_slug ON likes(post_slug);
CREATE INDEX idx_likes_user_id ON likes(user_id);

-- =============================================
-- BOOKMARKS TABLE
-- =============================================
-- Save posts for later (one per user per post)

CREATE TABLE bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_slug TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Ensure one bookmark per user per post
  UNIQUE(post_slug, user_id)
);

-- Indexes
CREATE INDEX idx_bookmarks_post_slug ON bookmarks(post_slug);
CREATE INDEX idx_bookmarks_user_id ON bookmarks(user_id);

-- =============================================
-- PORTFOLIO PROJECTS TABLE (BONUS)
-- =============================================
-- Showcase personal projects

CREATE TABLE portfolio_projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT,
  project_url TEXT,
  github_url TEXT,
  tech_stack TEXT[] DEFAULT '{}',
  featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Validation
  CHECK (LENGTH(title) >= 3 AND LENGTH(title) <= 100),
  CHECK (LENGTH(description) >= 10 AND LENGTH(description) <= 500)
);

-- Index
CREATE INDEX idx_portfolio_projects_user_id ON portfolio_projects(user_id);
CREATE INDEX idx_portfolio_projects_featured ON portfolio_projects(featured);

-- Auto-update timestamp
CREATE TRIGGER update_portfolio_projects_updated_at
  BEFORE UPDATE ON portfolio_projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
EOF
```

---

### STEP 7: Create RLS Policies Migration

```bash
cat > supabase/migrations/002_rls_policies.sql << 'EOF'
-- =============================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================
-- Database-level access control

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_projects ENABLE ROW LEVEL SECURITY;

-- =============================================
-- USER PROFILES POLICIES
-- =============================================

-- Anyone can view profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON user_profiles FOR SELECT
  USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own profile
CREATE POLICY "Users can delete their own profile"
  ON user_profiles FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================
-- COMMENTS POLICIES
-- =============================================

-- Anyone can view comments
CREATE POLICY "Comments are viewable by everyone"
  ON comments FOR SELECT
  USING (true);

-- Authenticated users can insert comments
CREATE POLICY "Authenticated users can insert comments"
  ON comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own comments
CREATE POLICY "Users can update their own comments"
  ON comments FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments"
  ON comments FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================
-- LIKES POLICIES
-- =============================================

-- Anyone can view likes
CREATE POLICY "Likes are viewable by everyone"
  ON likes FOR SELECT
  USING (true);

-- Authenticated users can insert likes
CREATE POLICY "Authenticated users can insert likes"
  ON likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own likes
CREATE POLICY "Users can delete their own likes"
  ON likes FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================
-- BOOKMARKS POLICIES
-- =============================================

-- Users can view their own bookmarks
CREATE POLICY "Users can view their own bookmarks"
  ON bookmarks FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own bookmarks
CREATE POLICY "Users can insert their own bookmarks"
  ON bookmarks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own bookmarks
CREATE POLICY "Users can delete their own bookmarks"
  ON bookmarks FOR DELETE
  USING (auth.uid() = user_id);

-- =============================================
-- PORTFOLIO PROJECTS POLICIES
-- =============================================

-- Anyone can view projects
CREATE POLICY "Projects are viewable by everyone"
  ON portfolio_projects FOR SELECT
  USING (true);

-- Authenticated users can insert projects
CREATE POLICY "Authenticated users can insert projects"
  ON portfolio_projects FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own projects
CREATE POLICY "Users can update their own projects"
  ON portfolio_projects FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own projects
CREATE POLICY "Users can delete their own projects"
  ON portfolio_projects FOR DELETE
  USING (auth.uid() = user_id);
EOF
```

---

### STEP 8: Create Helper Functions Migration

```bash
cat > supabase/migrations/003_helper_functions.sql << 'EOF'
-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Get comment count for a post
CREATE OR REPLACE FUNCTION get_comment_count(p_post_slug TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM comments
    WHERE post_slug = p_post_slug
  );
END;
$$ LANGUAGE plpgsql;

-- Get like count for a post
CREATE OR REPLACE FUNCTION get_like_count(p_post_slug TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM likes
    WHERE post_slug = p_post_slug
  );
END;
$$ LANGUAGE plpgsql;

-- Check if user liked a post
CREATE OR REPLACE FUNCTION has_user_liked(p_post_slug TEXT, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM likes
    WHERE post_slug = p_post_slug
      AND user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql;

-- Check if user bookmarked a post
CREATE OR REPLACE FUNCTION has_user_bookmarked(p_post_slug TEXT, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM bookmarks
    WHERE post_slug = p_post_slug
      AND user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql;

-- Get comments with user info (for display)
CREATE OR REPLACE FUNCTION get_comments_with_user(p_post_slug TEXT)
RETURNS TABLE (
  id UUID,
  post_slug TEXT,
  user_id UUID,
  parent_id UUID,
  content TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  display_name TEXT,
  avatar_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.post_slug,
    c.user_id,
    c.parent_id,
    c.content,
    c.created_at,
    c.updated_at,
    COALESCE(up.display_name, 'Anonymous') as display_name,
    up.avatar_url
  FROM comments c
  LEFT JOIN user_profiles up ON c.user_id = up.user_id
  WHERE c.post_slug = p_post_slug
  ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql;
EOF
```

---

### STEP 9: Run Migrations in Supabase

```bash
echo "
To apply migrations to your Supabase database:

Option 1: Using Supabase Dashboard (Recommended for beginners)
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to SQL Editor
4. Click 'New query'
5. Copy and paste the contents of each migration file IN ORDER:
   - 001_initial_schema.sql
   - 002_rls_policies.sql
   - 003_helper_functions.sql
6. Run each migration

Option 2: Using Supabase CLI (Advanced)
1. Install Supabase CLI: npm install -g supabase
2. Link project: supabase link --project-ref your-project-ref
3. Push migrations: supabase db push

✅ Migrations applied successfully!
"
```

---

### STEP 10: Create Database Constants

```bash
cat > src/lib/constants/database.ts << 'EOF'
/**
 * Database table names
 * Centralized to avoid typos
 */
export const DB_TABLES = {
  USER_PROFILES: 'user_profiles',
  COMMENTS: 'comments',
  LIKES: 'likes',
  BOOKMARKS: 'bookmarks',
  PORTFOLIO_PROJECTS: 'portfolio_projects',
} as const;

/**
 * Database function names
 */
export const DB_FUNCTIONS = {
  GET_COMMENT_COUNT: 'get_comment_count',
  GET_LIKE_COUNT: 'get_like_count',
  HAS_USER_LIKED: 'has_user_liked',
  HAS_USER_BOOKMARKED: 'has_user_bookmarked',
  GET_COMMENTS_WITH_USER: 'get_comments_with_user',
} as const;

/**
 * Max lengths for validation
 */
export const DB_LIMITS = {
  DISPLAY_NAME_MAX: 50,
  BIO_MAX: 500,
  COMMENT_MAX: 5000,
  PROJECT_TITLE_MAX: 100,
  PROJECT_DESC_MAX: 500,
} as const;
EOF
```

---

### STEP 11: Create Test Query

```bash
# Create test file to verify database connection
cat > src/pages/api/test-db.ts << 'EOF'
import type { APIRoute } from 'astro';
import { createServerClient } from '../../lib/supabase/server';

/**
 * Test endpoint to verify database connection
 * Visit: /api/test-db
 */
export const GET: APIRoute = async () => {
  try {
    const supabase = createServerClient();

    // Test query: Get all tables
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .limit(1);

    if (error) {
      return new Response(
        JSON.stringify({
          success: false,
          error: error.message,
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Database connected successfully!',
        data,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
};
EOF
```

---

### STEP 12: Test Database Connection

```bash
# Start dev server
npm run dev

# Test database connection
echo "
Test your database connection:
1. Open browser to http://localhost:4321/api/test-db
2. Should see: {\"success\": true, \"message\": \"Database connected successfully!\"}

If you see an error:
- Check .env file has correct values
- Verify migrations were run in Supabase dashboard
- Check Supabase project is active
"
```

---

## ✅ 3. VERIFY (Testing)

### Checklist

#### Supabase Project ✓
- [ ] Supabase project created
- [ ] Project URL copied to `.env`
- [ ] Anon key copied to `.env`
- [ ] Service role key copied to `.env`
- [ ] `.env` added to `.gitignore`

#### Client Setup ✓
- [ ] `@supabase/supabase-js` installed
- [ ] Server client created (`server.ts`)
- [ ] Browser client created (`client.ts`)
- [ ] Types file created (`types.ts`)
- [ ] No TypeScript errors

#### Database Schema ✓
- [ ] Migration files created (001, 002, 003)
- [ ] Migrations applied in Supabase dashboard
- [ ] All tables created (verify in dashboard)
- [ ] RLS enabled on all tables
- [ ] Helper functions created

#### Tables Created ✓
- [ ] `user_profiles` table exists
- [ ] `comments` table exists
- [ ] `likes` table exists
- [ ] `bookmarks` table exists
- [ ] `portfolio_projects` table exists

#### RLS Policies ✓
- [ ] Profiles viewable by everyone
- [ ] Users can only update own profile
- [ ] Comments viewable by everyone
- [ ] Authenticated users can create comments
- [ ] Bookmarks private to user

#### Test Connection ✓
- [ ] `/api/test-db` endpoint returns success
- [ ] No connection errors
- [ ] Can query database successfully

---

### Expected Results

**Database Structure in Supabase Dashboard:**
```
Tables (5):
✅ user_profiles (0 rows)
✅ comments (0 rows)
✅ likes (0 rows)
✅ bookmarks (0 rows)
✅ portfolio_projects (0 rows)

Functions (5):
✅ get_comment_count
✅ get_like_count
✅ has_user_liked
✅ has_user_bookmarked
✅ get_comments_with_user
```

**Test API Response:**
```json
{
  "success": true,
  "message": "Database connected successfully!",
  "data": []
}
```

---

### Common Issues & Solutions

**Issue 1: Missing environment variables**
```bash
# Error: Missing Supabase environment variables

# Solution: Check .env file exists and has values
cat .env

# Should show:
PUBLIC_SUPABASE_URL=https://xxx.supabase.co
PUBLIC_SUPABASE_ANON_KEY=eyJxxx...
SUPABASE_SERVICE_ROLE_KEY=eyJxxx...

# Restart dev server after adding/changing .env
npm run dev
```

**Issue 2: Migrations not applied**
```bash
# Error: relation "user_profiles" does not exist

# Solution: Run migrations in Supabase dashboard
# 1. Go to SQL Editor
# 2. Paste migration files
# 3. Run in order (001, 002, 003)
```

**Issue 3: RLS blocking queries**
```bash
# Error: Row level security policy violation

# Solution: Either:
# 1. Use service role key (server-side only)
# 2. Ensure user is authenticated
# 3. Check RLS policies are correct
```

**Issue 4: Type errors**
```bash
# Error: Type 'Database' does not satisfy the constraint

# Solution: Update types.ts with actual types:
# npx supabase gen types typescript --project-id YOUR_PROJECT_ID > src/lib/supabase/types.ts
```

**Issue 5: Connection timeout**
```bash
# Error: Connection timeout

# Solution:
# 1. Check project is not paused (Supabase dashboard)
# 2. Verify project URL is correct
# 3. Check internet connection
```

---

### Manual Testing in Supabase Dashboard

```sql
-- Test: Insert a profile
INSERT INTO user_profiles (user_id, display_name)
VALUES (auth.uid(), 'Test User');

-- Test: Query profiles
SELECT * FROM user_profiles;

-- Test: Get comment count
SELECT get_comment_count('welcome-to-astro');

-- Test: Check RLS (should fail if not authenticated)
SELECT * FROM bookmarks;
```

---

## 🎯 What You Built

### Infrastructure
- ✅ **Supabase Project** - Production PostgreSQL database
- ✅ **5 Database Tables** - Users, comments, likes, bookmarks, projects
- ✅ **Row Level Security** - Database-level access control
- ✅ **3 Migrations** - Version-controlled schema
- ✅ **5 Helper Functions** - Reusable database queries
- ✅ **Type Safety** - TypeScript types from database

### Files Created
- ✅ **Client utilities** - Server and browser Supabase clients
- ✅ **Type definitions** - Database schema types
- ✅ **Constants** - Table names and limits
- ✅ **Test endpoint** - Verify connection
- ✅ **Migrations** - Reproducible schema

### Features
- ✅ **User Profiles** - Extended user data
- ✅ **Nested Comments** - Threaded discussions
- ✅ **Likes System** - Track favorites
- ✅ **Bookmarks** - Save for later
- ✅ **Portfolio** - Showcase projects

---

## 🚀 Next Steps

In **Lesson 5**, you'll add:
- Complete authentication system
- Login and signup pages
- Protected routes
- User profiles
- Password reset
- OAuth providers (GitHub, Google)

**Continue to:** [LESSON-5-AUTH.md](./LESSON-5-AUTH.md)

---

## 📚 Key Concepts Review

### Supabase Architecture
- **PostgreSQL** - Powerful relational database
- **RLS** - Row Level Security for access control
- **Auth** - Built-in authentication
- **Real-time** - WebSocket subscriptions
- **Storage** - File uploads

### Database Design
- **Foreign Keys** - Link related data
- **Indexes** - Faster queries
- **Triggers** - Auto-update timestamps
- **Functions** - Reusable logic
- **Constraints** - Data validation

### Security
- **RLS Policies** - Who can access what
- **auth.uid()** - Current user's ID
- **Service Role** - Admin access (server-only)
- **Anon Key** - Public access (respects RLS)

### Best Practices
- **Migrations** - Version control for schema
- **Type Safety** - Generate types from schema
- **Validation** - Database-level constraints
- **Indexes** - Optimize common queries

---

**Congratulations!** 🎉 You've successfully integrated Supabase and created a production-ready database schema with security!

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 3-4 hours
