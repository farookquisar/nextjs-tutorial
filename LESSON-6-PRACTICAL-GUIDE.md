# Module 1, Lesson 6 — Project Members with Many-to-Many Relationships

**Prerequisites:** Complete Lesson 1 (Next.js Setup), Lesson 2 (Supabase Setup), Lesson 3 (Authentication), Lesson 4 (Project CRUD), and Lesson 5 (Task Management)

---

## 📖 1. DESC

### What You'll Build

In this lesson, you'll implement **Project Members Management** using the **prj_project_members** table created in Lesson 2, introducing **many-to-many relationships** and **role-based access control**:

✅ **Many-to-Many Relationships** - Users can belong to multiple projects, projects can have multiple users
✅ **Member Roles** - Owner, Admin, Member, Viewer with different permissions
✅ **Member Constants** - Add member-specific constants to `src/constants/index.ts` (created in Lesson 1)
✅ **Invite Members** - Add users to projects via email
✅ **Remove Members** - Remove users from projects
✅ **Update Roles** - Change member permissions
✅ **RPC Functions** - Complex member queries with role checking
✅ **Row-Level Security** - Enforce permissions at database level

**What are Many-to-Many Relationships?**
- One user can be a member of many projects
- One project can have many members
- Junction table (prj_project_members) connects users ↔ projects
- Each membership has additional data (role, joined date)

### Building On Previous Lessons

**Lesson 1:** Next.js 16 setup with constants.ts
**Lesson 2:** Database schema with `prj_project_members` table
**Lesson 3:** Authentication with user management
**Lesson 4:** Project CRUD operations
**Lesson 5:** Task management with best practices
**Lesson 6 (THIS LESSON):** Team collaboration with M:N relationships

### What You'll Implement

✅ **Constants Extension** - Add member roles and permissions to `src/constants/index.ts`
✅ **Member CRUD** - Add, remove, update members
✅ **RPC Functions** - `get_project_members()`, `check_member_role()`, `get_user_projects()`
✅ **Role-Based Access** - Enforce permissions based on member roles
✅ **Member UI Components** - MemberCard, MemberList, InviteMemberForm
✅ **Permission Checks** - Server-side role validation

```
📁 Your App Structure (After This Lesson)
├── src/
│   ├── constants/
│   │   └── index.ts                          ← UPDATE: Add member constants
│   ├── lib/
│   │   ├── actions/
│   │   │   └── members.ts                    ← NEW: Member CRUD Server Actions
│   │   ├── validations/
│   │   │   └── member.ts                     ← NEW: Zod member schemas
│   │   └── types/
│   │       └── database.ts                   ← UPDATE: Add member types
│   ├── app/
│   │   └── dashboard/
│   │       └── projects/[id]/
│   │           └── members/
│   │               └── page.tsx              ← NEW: Members list (Server Component)
│   ├── components/
│   │   └── features/members/
│   │       ├── MemberList.tsx                ← NEW: Members list component
│   │       ├── MemberCard.tsx                ← NEW: Member card component
│   │       ├── InviteMemberForm.tsx          ← NEW: Invite member form
│   │       └── MemberRoleSelect.tsx          ← NEW: Role selector
│   └── utils/
│       └── permissions.ts                    ← NEW: Permission helpers
└── supabase/migrations/
    └── 004_member_rls_and_rpc.sql            ← NEW: RLS + RPC functions
```

### Why This Approach?

✅ **Scalable** - Many-to-many design supports complex team structures
✅ **Secure** - Role-based access control at database level
✅ **Flexible** - Easy to add new roles or permissions
✅ **Type-safe** - TypeScript + constants = autocomplete for roles
✅ **Maintainable** - Clear separation of concerns (SOLID)
✅ **Performant** - RPC functions for efficient queries

---

## 🎯 2. STEPS

### 🎯 STEP 1 — Add Member-Specific Constants

**In Lesson 1, we already created `src/constants/index.ts` with foundational constants.**

**In this lesson, we'll ADD these NEW member-specific constants:**

1. **MEMBER_ROLES** - Owner, Admin, Member, Viewer (already in Lesson 1, may need to verify)
2. **MEMBER_ROLE_LABELS** - Display labels for UI (NEW!)
3. **MEMBER_PERMISSIONS** - What each role can do (NEW!)
4. **Member routes** - ADD to existing ROUTES object

**Add these NEW constants to `src/constants/index.ts`:**

```bash
# Open your constants file and ADD/UPDATE these sections:

# 1. VERIFY MEMBER_ROLES exists (should be from Lesson 1)
# If not, add it:
export const MEMBER_ROLES = {
  OWNER: 'owner',
  ADMIN: 'admin',
  MEMBER: 'member',
  VIEWER: 'viewer',
} as const;

# 2. ADD Display Labels for Roles (NEW)
export const MEMBER_ROLE_LABELS: Record<MemberRole, string> = {
  [MEMBER_ROLES.OWNER]: 'Owner',
  [MEMBER_ROLES.ADMIN]: 'Admin',
  [MEMBER_ROLES.MEMBER]: 'Member',
  [MEMBER_ROLES.VIEWER]: 'Viewer',
};

# 3. ADD Role Descriptions (NEW)
export const MEMBER_ROLE_DESCRIPTIONS: Record<MemberRole, string> = {
  [MEMBER_ROLES.OWNER]: 'Full access - can delete project and manage all settings',
  [MEMBER_ROLES.ADMIN]: 'Can manage members, tasks, and project settings',
  [MEMBER_ROLES.MEMBER]: 'Can create and manage tasks',
  [MEMBER_ROLES.VIEWER]: 'Read-only access to project and tasks',
};

# 4. ADD Permission Matrix (NEW)
export const MEMBER_PERMISSIONS = {
  // Project permissions
  CAN_DELETE_PROJECT: [MEMBER_ROLES.OWNER],
  CAN_UPDATE_PROJECT: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN],
  CAN_VIEW_PROJECT: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN, MEMBER_ROLES.MEMBER, MEMBER_ROLES.VIEWER],

  // Member permissions
  CAN_INVITE_MEMBERS: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN],
  CAN_REMOVE_MEMBERS: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN],
  CAN_UPDATE_MEMBER_ROLES: [MEMBER_ROLES.OWNER],

  // Task permissions
  CAN_CREATE_TASKS: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN, MEMBER_ROLES.MEMBER],
  CAN_UPDATE_TASKS: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN, MEMBER_ROLES.MEMBER],
  CAN_DELETE_TASKS: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN, MEMBER_ROLES.MEMBER],
  CAN_VIEW_TASKS: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN, MEMBER_ROLES.MEMBER, MEMBER_ROLES.VIEWER],
} as const;

# 5. ADD Member Routes to existing ROUTES (UPDATE ROUTES object)
# Add these member routes to your existing ROUTES constant:
  PROJECT_MEMBERS: (projectId: string) => `/dashboard/projects/${projectId}/members`,

# 6. ADD Member Error Messages (UPDATE ERROR_MESSAGES)
# Add to existing ERROR_MESSAGES object:
  MEMBER: {
    NOT_FOUND: 'Member not found',
    ALREADY_MEMBER: 'User is already a member of this project',
    CANNOT_REMOVE_OWNER: 'Cannot remove the project owner',
    INSUFFICIENT_PERMISSIONS: 'You do not have permission to perform this action',
    INVALID_ROLE: 'Invalid member role',
    USER_NOT_FOUND: 'User not found',
  },

# 7. ADD Member Success Messages (UPDATE SUCCESS_MESSAGES)
# Add to existing SUCCESS_MESSAGES object:
  MEMBER: {
    INVITED: 'Member invited successfully',
    REMOVED: 'Member removed successfully',
    ROLE_UPDATED: 'Member role updated successfully',
  },

# 8. UPDATE Type Exports (if not already present)
export type MemberRole = typeof MEMBER_ROLES[keyof typeof MEMBER_ROLES];
```

**Verify the constants compile:**

```bash
# Check TypeScript compiles without errors
npx tsc --noEmit src/constants/index.ts
```

<details>
<summary>📖 <strong>Understanding Permission Matrix</strong></summary>

### What is a Permission Matrix?

A permission matrix defines what each role can do:

```typescript
// Check if a role has permission
function hasPermission(userRole: MemberRole, permission: keyof typeof MEMBER_PERMISSIONS): boolean {
  return MEMBER_PERMISSIONS[permission].includes(userRole);
}

// Example usage
if (hasPermission(currentUserRole, 'CAN_DELETE_PROJECT')) {
  // Show delete button
}
```

### Benefits

1. **Centralized** - All permissions in one place
2. **Type-safe** - TypeScript ensures valid permissions
3. **Easy to change** - Update permissions without touching components
4. **Auditable** - Clear view of who can do what
5. **Testable** - Easy to write permission tests

### Adding New Permissions

```typescript
// Just add to the matrix:
export const MEMBER_PERMISSIONS = {
  ...existing permissions...,
  CAN_EXPORT_DATA: [MEMBER_ROLES.OWNER, MEMBER_ROLES.ADMIN],
}
```

</details>

---

### 🎯 STEP 2 — Add RLS Policies and RPC Functions for Members

The `prj_project_members` table was created in Lesson 2, but we need Row Level Security and RPC functions.

**Create migration file:**

```bash
mkdir -p supabase/migrations

cat > supabase/migrations/004_member_rls_and_rpc.sql << 'EOF'
-- ============================================
-- LESSON 6: MEMBER RLS POLICIES AND RPC FUNCTIONS
-- ============================================

-- ============================================
-- ROW LEVEL SECURITY FOR PROJECT MEMBERS
-- ============================================

-- Enable RLS on prj_project_members
ALTER TABLE prj_project_members ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view members of projects they belong to
CREATE POLICY "Users can view members of own projects"
  ON prj_project_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = prj_project_members.project_id
      AND pm.user_id = auth.uid()
    )
  );

-- Policy: Owners and Admins can invite members
CREATE POLICY "Owners and Admins can invite members"
  ON prj_project_members
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = prj_project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'admin')
    )
  );

-- Policy: Owners and Admins can remove members (except owner)
CREATE POLICY "Owners and Admins can remove members"
  ON prj_project_members
  FOR DELETE
  USING (
    -- Can't remove owner
    role != 'owner'
    AND
    -- Must be owner or admin of the project
    EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = prj_project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role IN ('owner', 'admin')
    )
  );

-- Policy: Only owners can update member roles
CREATE POLICY "Only owners can update member roles"
  ON prj_project_members
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = prj_project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role = 'owner'
    )
  )
  WITH CHECK (
    -- Can't change owner role
    role != 'owner'
    AND
    EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = prj_project_members.project_id
      AND pm.user_id = auth.uid()
      AND pm.role = 'owner'
    )
  );

-- Create indexes for faster member queries
CREATE INDEX IF NOT EXISTS idx_members_project_id ON prj_project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_members_user_id ON prj_project_members(user_id);
CREATE INDEX IF NOT EXISTS idx_members_role ON prj_project_members(role);

-- ============================================
-- RPC FUNCTION: GET PROJECT MEMBERS
-- ============================================

CREATE OR REPLACE FUNCTION get_project_members(p_project_id UUID)
RETURNS TABLE (
  user_id UUID,
  role VARCHAR(50),
  joined_at TIMESTAMPTZ,
  user_email TEXT,
  member_count BIGINT
) AS $$
BEGIN
  -- Check if requesting user is a member
  IF NOT EXISTS (
    SELECT 1 FROM prj_project_members
    WHERE project_id = p_project_id
    AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Access denied: You are not a member of this project';
  END IF;

  RETURN QUERY
  SELECT
    pm.user_id,
    pm.role,
    pm.joined_at,
    au.email AS user_email,
    COUNT(*) OVER() AS member_count
  FROM prj_project_members pm
  INNER JOIN auth.users au ON pm.user_id = au.id
  WHERE pm.project_id = p_project_id
  ORDER BY
    -- Owner first, then admins, then members, then viewers
    CASE pm.role
      WHEN 'owner' THEN 1
      WHEN 'admin' THEN 2
      WHEN 'member' THEN 3
      WHEN 'viewer' THEN 4
    END,
    pm.joined_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RPC FUNCTION: CHECK MEMBER ROLE
-- ============================================

CREATE OR REPLACE FUNCTION check_member_role(
  p_project_id UUID,
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
  has_access BOOLEAN,
  user_role VARCHAR(50),
  can_delete_project BOOLEAN,
  can_update_project BOOLEAN,
  can_invite_members BOOLEAN,
  can_remove_members BOOLEAN,
  can_update_roles BOOLEAN,
  can_create_tasks BOOLEAN,
  can_update_tasks BOOLEAN,
  can_delete_tasks BOOLEAN
) AS $$
DECLARE
  v_user_id UUID;
  v_role VARCHAR(50);
BEGIN
  -- Use provided user_id or current authenticated user
  v_user_id := COALESCE(p_user_id, auth.uid());

  -- Get user's role in project
  SELECT pm.role INTO v_role
  FROM prj_project_members pm
  WHERE pm.project_id = p_project_id
  AND pm.user_id = v_user_id;

  -- If no role found, user is not a member
  IF v_role IS NULL THEN
    RETURN QUERY SELECT
      FALSE AS has_access,
      NULL::VARCHAR(50) AS user_role,
      FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE;
    RETURN;
  END IF;

  -- Return permissions based on role
  RETURN QUERY SELECT
    TRUE AS has_access,
    v_role AS user_role,
    (v_role = 'owner') AS can_delete_project,
    (v_role IN ('owner', 'admin')) AS can_update_project,
    (v_role IN ('owner', 'admin')) AS can_invite_members,
    (v_role IN ('owner', 'admin')) AS can_remove_members,
    (v_role = 'owner') AS can_update_roles,
    (v_role IN ('owner', 'admin', 'member')) AS can_create_tasks,
    (v_role IN ('owner', 'admin', 'member')) AS can_update_tasks,
    (v_role IN ('owner', 'admin', 'member')) AS can_delete_tasks;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RPC FUNCTION: GET USER PROJECTS
-- ============================================

CREATE OR REPLACE FUNCTION get_user_projects(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
  project_id UUID,
  project_name VARCHAR(100),
  project_description TEXT,
  user_role VARCHAR(50),
  member_count BIGINT,
  task_count BIGINT,
  joined_at TIMESTAMPTZ
) AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Use provided user_id or current authenticated user
  v_user_id := COALESCE(p_user_id, auth.uid());

  RETURN QUERY
  SELECT
    p.id AS project_id,
    p.name AS project_name,
    p.description AS project_description,
    pm.role AS user_role,
    (
      SELECT COUNT(*)::BIGINT
      FROM prj_project_members pm2
      WHERE pm2.project_id = p.id
    ) AS member_count,
    (
      SELECT COUNT(*)::BIGINT
      FROM prj_tasks t
      WHERE t.project_id = p.id
    ) AS task_count,
    pm.joined_at
  FROM prj_project_members pm
  INNER JOIN prj_projects p ON pm.project_id = p.id
  WHERE pm.user_id = v_user_id
  ORDER BY pm.joined_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- RPC FUNCTION: INVITE MEMBER BY EMAIL
-- ============================================

CREATE OR REPLACE FUNCTION invite_member_by_email(
  p_project_id UUID,
  p_email TEXT,
  p_role VARCHAR(50)
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  user_id UUID
) AS $$
DECLARE
  v_user_id UUID;
  v_requester_role VARCHAR(50);
BEGIN
  -- Check if requester has permission (must be owner or admin)
  SELECT pm.role INTO v_requester_role
  FROM prj_project_members pm
  WHERE pm.project_id = p_project_id
  AND pm.user_id = auth.uid();

  IF v_requester_role NOT IN ('owner', 'admin') THEN
    RETURN QUERY SELECT FALSE, 'Insufficient permissions'::TEXT, NULL::UUID;
    RETURN;
  END IF;

  -- Check if role is valid (can't invite as owner)
  IF p_role NOT IN ('admin', 'member', 'viewer') THEN
    RETURN QUERY SELECT FALSE, 'Invalid role'::TEXT, NULL::UUID;
    RETURN;
  END IF;

  -- Find user by email
  SELECT au.id INTO v_user_id
  FROM auth.users au
  WHERE au.email = p_email;

  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'User not found'::TEXT, NULL::UUID;
    RETURN;
  END IF;

  -- Check if already a member
  IF EXISTS (
    SELECT 1 FROM prj_project_members
    WHERE project_id = p_project_id
    AND user_id = v_user_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'User is already a member'::TEXT, v_user_id;
    RETURN;
  END IF;

  -- Add member
  INSERT INTO prj_project_members (project_id, user_id, role)
  VALUES (p_project_id, v_user_id, p_role);

  RETURN QUERY SELECT TRUE, 'Member invited successfully'::TEXT, v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
EOF

# Verify file created
cat supabase/migrations/004_member_rls_and_rpc.sql
```

**Run the migration in Supabase:**

1. Go to Supabase Dashboard → SQL Editor
2. Copy the contents of `supabase/migrations/004_member_rls_and_rpc.sql`
3. Paste and click "Run"

**Verify RLS policies:**

```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'prj_project_members';

-- Check policies exist
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'prj_project_members';

-- Check RPC functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_name IN ('get_project_members', 'check_member_role', 'get_user_projects', 'invite_member_by_email');
```

<details>
<summary>📖 <strong>Understanding Many-to-Many RLS</strong></summary>

### Why M:N RLS is Complex

In one-to-many (projects → tasks), RLS is simple:
```sql
-- User owns project → can see tasks
WHERE project_id IN (SELECT id FROM projects WHERE owner_id = auth.uid())
```

In many-to-many (users ↔ projects), it's different:
```sql
-- User is MEMBER of project → can see other members
WHERE project_id IN (SELECT project_id FROM members WHERE user_id = auth.uid())
```

### Key RLS Patterns for M:N

**1. View members if you're a member:**
```sql
EXISTS (
  SELECT 1 FROM prj_project_members pm
  WHERE pm.project_id = prj_project_members.project_id
  AND pm.user_id = auth.uid()
)
```

**2. Add members if you're owner/admin:**
```sql
EXISTS (
  SELECT 1 FROM prj_project_members pm
  WHERE pm.project_id = NEW.project_id
  AND pm.user_id = auth.uid()
  AND pm.role IN ('owner', 'admin')
)
```

**3. Remove members (but not owner):**
```sql
role != 'owner'  -- Can't remove owner
AND EXISTS (...owner/admin check...)
```

</details>

---

### 🎯 STEP 3 — Create Member Types and Validation Schemas

**Update database types:**

```bash
cat >> src/lib/types/database.ts << 'EOF'

// ============================================
// MEMBER TYPES
// ============================================

export interface ProjectMember {
  user_id: string;
  project_id: string;
  role: MemberRole;
  joined_at: string;
  user_email?: string;  // From RPC join
}

export interface MemberPermissions {
  has_access: boolean;
  user_role: MemberRole | null;
  can_delete_project: boolean;
  can_update_project: boolean;
  can_invite_members: boolean;
  can_remove_members: boolean;
  can_update_roles: boolean;
  can_create_tasks: boolean;
  can_update_tasks: boolean;
  can_delete_tasks: boolean;
}

export interface UserProject {
  project_id: string;
  project_name: string;
  project_description: string | null;
  user_role: MemberRole;
  member_count: number;
  task_count: number;
  joined_at: string;
}

// ============================================
// FORM TYPES
// ============================================

export interface InviteMemberInput {
  email: string;
  role: MemberRole;
  project_id: string;
}

export interface UpdateMemberRoleInput {
  user_id: string;
  project_id: string;
  role: MemberRole;
}
EOF

# Verify
cat src/lib/types/database.ts | tail -50
```

**Create Zod validation schemas for members:**

```bash
mkdir -p src/lib/validations

cat > src/lib/validations/member.ts << 'EOF'
// ============================================
// MEMBER VALIDATION SCHEMAS
// ============================================

import { z } from 'zod';
import {
  MEMBER_ROLES,
  ERROR_MESSAGES,
} from '@/constants';

// ============================================
// SCHEMA: INVITE MEMBER
// ============================================

export const inviteMemberSchema = z.object({
  email: z
    .string()
    .email({ message: 'Invalid email address' })
    .toLowerCase()
    .trim(),

  role: z.enum(
    [MEMBER_ROLES.ADMIN, MEMBER_ROLES.MEMBER, MEMBER_ROLES.VIEWER],
    { errorMap: () => ({ message: ERROR_MESSAGES.MEMBER.INVALID_ROLE }) }
  ),

  project_id: z.string().uuid({ message: 'Invalid project ID' }),
});

// ============================================
// SCHEMA: UPDATE MEMBER ROLE
// ============================================

export const updateMemberRoleSchema = z.object({
  user_id: z.string().uuid({ message: 'Invalid user ID' }),

  project_id: z.string().uuid({ message: 'Invalid project ID' }),

  role: z.enum(
    [MEMBER_ROLES.ADMIN, MEMBER_ROLES.MEMBER, MEMBER_ROLES.VIEWER],
    { errorMap: () => ({ message: ERROR_MESSAGES.MEMBER.INVALID_ROLE }) }
  ),
});

// ============================================
// SCHEMA: REMOVE MEMBER
// ============================================

export const removeMemberSchema = z.object({
  user_id: z.string().uuid({ message: 'Invalid user ID' }),
  project_id: z.string().uuid({ message: 'Invalid project ID' }),
});

// ============================================
// TYPE INFERENCE
// ============================================

export type InviteMemberInput = z.infer<typeof inviteMemberSchema>;
export type UpdateMemberRoleInput = z.infer<typeof updateMemberRoleSchema>;
export type RemoveMemberInput = z.infer<typeof removeMemberSchema>;
EOF

# Verify
cat src/lib/validations/member.ts
```

**Verify TypeScript compiles:**

```bash
npx tsc --noEmit src/lib/types/database.ts src/lib/validations/member.ts
```

---

### 🎯 STEP 4 — Create Permission Helper Utilities

Create utility functions for checking permissions:

```bash
mkdir -p src/utils

cat > src/utils/permissions.ts << 'EOF'
// ============================================
// PERMISSION UTILITIES
// ============================================

import { MEMBER_PERMISSIONS, MEMBER_ROLES } from '@/constants';
import type { MemberRole, MemberPermissions } from '@/lib/types/database';

/**
 * Check if a role has a specific permission
 */
export function hasPermission(
  role: MemberRole | null | undefined,
  permission: keyof typeof MEMBER_PERMISSIONS
): boolean {
  if (!role) return false;
  return MEMBER_PERMISSIONS[permission].includes(role as any);
}

/**
 * Get all permissions for a role
 */
export function getRolePermissions(role: MemberRole): {
  [K in keyof typeof MEMBER_PERMISSIONS]: boolean;
} {
  return {
    CAN_DELETE_PROJECT: hasPermission(role, 'CAN_DELETE_PROJECT'),
    CAN_UPDATE_PROJECT: hasPermission(role, 'CAN_UPDATE_PROJECT'),
    CAN_VIEW_PROJECT: hasPermission(role, 'CAN_VIEW_PROJECT'),
    CAN_INVITE_MEMBERS: hasPermission(role, 'CAN_INVITE_MEMBERS'),
    CAN_REMOVE_MEMBERS: hasPermission(role, 'CAN_REMOVE_MEMBERS'),
    CAN_UPDATE_MEMBER_ROLES: hasPermission(role, 'CAN_UPDATE_MEMBER_ROLES'),
    CAN_CREATE_TASKS: hasPermission(role, 'CAN_CREATE_TASKS'),
    CAN_UPDATE_TASKS: hasPermission(role, 'CAN_UPDATE_TASKS'),
    CAN_DELETE_TASKS: hasPermission(role, 'CAN_DELETE_TASKS'),
    CAN_VIEW_TASKS: hasPermission(role, 'CAN_VIEW_TASKS'),
  };
}

/**
 * Check if user is project owner
 */
export function isOwner(role: MemberRole | null | undefined): boolean {
  return role === MEMBER_ROLES.OWNER;
}

/**
 * Check if user is admin or owner
 */
export function isAdminOrOwner(role: MemberRole | null | undefined): boolean {
  return role === MEMBER_ROLES.OWNER || role === MEMBER_ROLES.ADMIN;
}

/**
 * Check if user can manage members
 */
export function canManageMembers(role: MemberRole | null | undefined): boolean {
  return hasPermission(role, 'CAN_INVITE_MEMBERS');
}

/**
 * Get role hierarchy level (lower = more powerful)
 */
export function getRoleLevel(role: MemberRole): number {
  const levels: Record<MemberRole, number> = {
    [MEMBER_ROLES.OWNER]: 1,
    [MEMBER_ROLES.ADMIN]: 2,
    [MEMBER_ROLES.MEMBER]: 3,
    [MEMBER_ROLES.VIEWER]: 4,
  };
  return levels[role];
}

/**
 * Check if role A can modify role B
 * (e.g., admins can't change owner's role)
 */
export function canModifyRole(
  modifierRole: MemberRole,
  targetRole: MemberRole
): boolean {
  // Owners can modify anyone except other owners
  if (modifierRole === MEMBER_ROLES.OWNER && targetRole !== MEMBER_ROLES.OWNER) {
    return true;
  }

  // No one else can modify roles
  return false;
}
EOF

# Verify
cat src/utils/permissions.ts
```

**Verify TypeScript compiles:**

```bash
npx tsc --noEmit src/utils/permissions.ts
```

---

### 🎯 STEP 5 — Create Member Server Actions

Server Actions for member management:

```bash
mkdir -p src/lib/actions

cat > src/lib/actions/members.ts << 'EOF'
'use server';

// ============================================
// MEMBER SERVER ACTIONS
// ============================================

import { revalidatePath } from 'next/cache';
import { createServerClient } from '@/lib/supabase/server';
import {
  inviteMemberSchema,
  updateMemberRoleSchema,
  removeMemberSchema,
} from '@/lib/validations/member';
import type {
  InviteMemberInput,
  UpdateMemberRoleInput,
  ProjectMember,
  MemberPermissions,
  UserProject,
} from '@/lib/types/database';
import {
  ERROR_MESSAGES,
  SUCCESS_MESSAGES,
  ROUTES,
} from '@/constants';

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
// GET PROJECT MEMBERS
// ============================================

export async function getProjectMembers(
  projectId: string
): Promise<{ success: boolean; data?: ProjectMember[]; error?: string }> {
  'use cache';

  try {
    await getAuthenticatedUser();

    const supabase = await createServerClient();
    const { data, error } = await supabase.rpc('get_project_members', {
      p_project_id: projectId,
    });

    if (error) {
      console.error('Get members error:', error);
      return { success: false, error: ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG };
    }

    return { success: true, data: data || [] };
  } catch (error) {
    console.error('Get members error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG,
    };
  }
}

// ============================================
// CHECK MEMBER PERMISSIONS
// ============================================

export async function checkMemberPermissions(
  projectId: string,
  userId?: string
): Promise<{ success: boolean; data?: MemberPermissions; error?: string }> {
  'use cache';

  try {
    await getAuthenticatedUser();

    const supabase = await createServerClient();
    const { data, error } = await supabase.rpc('check_member_role', {
      p_project_id: projectId,
      p_user_id: userId || null,
    });

    if (error) {
      console.error('Check permissions error:', error);
      return { success: false, error: ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG };
    }

    return { success: true, data: data?.[0] || null };
  } catch (error) {
    console.error('Check permissions error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG,
    };
  }
}

// ============================================
// GET USER PROJECTS
// ============================================

export async function getUserProjects(
  userId?: string
): Promise<{ success: boolean; data?: UserProject[]; error?: string }> {
  'use cache';

  try {
    await getAuthenticatedUser();

    const supabase = await createServerClient();
    const { data, error } = await supabase.rpc('get_user_projects', {
      p_user_id: userId || null,
    });

    if (error) {
      console.error('Get user projects error:', error);
      return { success: false, error: ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG };
    }

    return { success: true, data: data || [] };
  } catch (error) {
    console.error('Get user projects error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG,
    };
  }
}

// ============================================
// INVITE MEMBER
// ============================================

export async function inviteMember(
  input: InviteMemberInput
): Promise<{ success: boolean; error?: string }> {
  try {
    await getAuthenticatedUser();

    // Validate input
    const validated = inviteMemberSchema.parse(input);

    const supabase = await createServerClient();
    const { data, error } = await supabase.rpc('invite_member_by_email', {
      p_project_id: validated.project_id,
      p_email: validated.email,
      p_role: validated.role,
    });

    if (error || !data?.[0]?.success) {
      console.error('Invite member error:', error || data?.[0]?.message);
      return {
        success: false,
        error: data?.[0]?.message || ERROR_MESSAGES.MEMBER.ALREADY_MEMBER,
      };
    }

    // Revalidate members list
    revalidatePath(ROUTES.PROJECT_MEMBERS(validated.project_id));
    revalidatePath(ROUTES.PROJECT_VIEW(validated.project_id));

    return { success: true };
  } catch (error) {
    console.error('Invite member error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG,
    };
  }
}

// ============================================
// UPDATE MEMBER ROLE
// ============================================

export async function updateMemberRole(
  input: UpdateMemberRoleInput
): Promise<{ success: boolean; error?: string }> {
  try {
    await getAuthenticatedUser();

    // Validate input
    const validated = updateMemberRoleSchema.parse(input);

    const supabase = await createServerClient();
    const { error } = await supabase
      .from('prj_project_members')
      .update({ role: validated.role })
      .eq('project_id', validated.project_id)
      .eq('user_id', validated.user_id);

    if (error) {
      console.error('Update role error:', error);
      return { success: false, error: ERROR_MESSAGES.MEMBER.INSUFFICIENT_PERMISSIONS };
    }

    // Revalidate members list
    revalidatePath(ROUTES.PROJECT_MEMBERS(validated.project_id));
    revalidatePath(ROUTES.PROJECT_VIEW(validated.project_id));

    return { success: true };
  } catch (error) {
    console.error('Update role error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG,
    };
  }
}

// ============================================
// REMOVE MEMBER
// ============================================

export async function removeMember(
  input: { user_id: string; project_id: string }
): Promise<{ success: boolean; error?: string }> {
  try {
    await getAuthenticatedUser();

    // Validate input
    const validated = removeMemberSchema.parse(input);

    const supabase = await createServerClient();
    const { error } = await supabase
      .from('prj_project_members')
      .delete()
      .eq('project_id', validated.project_id)
      .eq('user_id', validated.user_id);

    if (error) {
      console.error('Remove member error:', error);
      return { success: false, error: ERROR_MESSAGES.MEMBER.CANNOT_REMOVE_OWNER };
    }

    // Revalidate members list
    revalidatePath(ROUTES.PROJECT_MEMBERS(validated.project_id));
    revalidatePath(ROUTES.PROJECT_VIEW(validated.project_id));

    return { success: true };
  } catch (error) {
    console.error('Remove member error:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : ERROR_MESSAGES.GENERIC.SOMETHING_WENT_WRONG,
    };
  }
}
EOF

# Verify
cat src/lib/actions/members.ts
```

**Verify TypeScript compiles:**

```bash
npx tsc --noEmit src/lib/actions/members.ts
```

---

### 🎯 STEP 6 — Create Member Components

Create reusable member components:

**Create MemberCard component:**

```bash
mkdir -p src/components/features/members

cat > src/components/features/members/MemberCard.tsx << 'EOF'
// ============================================
// MEMBER CARD COMPONENT
// Single Responsibility: Display one member
// ============================================

import { MEMBER_ROLE_LABELS, MEMBER_ROLES } from '@/constants';
import type { ProjectMember, MemberRole } from '@/lib/types/database';

interface MemberCardProps {
  member: ProjectMember;
  currentUserRole: MemberRole;
  onRemove?: (userId: string) => void;
  onUpdateRole?: (userId: string, role: MemberRole) => void;
}

export function MemberCard({
  member,
  currentUserRole,
  onRemove,
  onUpdateRole,
}: MemberCardProps) {
  const isOwner = member.role === MEMBER_ROLES.OWNER;
  const canRemove = currentUserRole === MEMBER_ROLES.OWNER || currentUserRole === MEMBER_ROLES.ADMIN;
  const canUpdateRole = currentUserRole === MEMBER_ROLES.OWNER;

  return (
    <div className="p-4 bg-white border rounded-lg">
      {/* Member Email */}
      <div className="flex items-center justify-between">
        <div>
          <p className="font-medium text-gray-900">{member.user_email}</p>
          <p className="text-sm text-gray-500">
            Joined {new Date(member.joined_at).toLocaleDateString()}
          </p>
        </div>

        {/* Role Badge */}
        <span
          className={`px-3 py-1 text-sm font-medium rounded-full ${
            isOwner
              ? 'bg-purple-100 text-purple-800'
              : member.role === MEMBER_ROLES.ADMIN
              ? 'bg-blue-100 text-blue-800'
              : member.role === MEMBER_ROLES.MEMBER
              ? 'bg-green-100 text-green-800'
              : 'bg-gray-100 text-gray-800'
          }`}
        >
          {MEMBER_ROLE_LABELS[member.role]}
        </span>
      </div>

      {/* Actions */}
      {!isOwner && (canRemove || canUpdateRole) && (
        <div className="mt-4 flex gap-2">
          {canUpdateRole && onUpdateRole && (
            <select
              onChange={(e) => onUpdateRole(member.user_id, e.target.value as MemberRole)}
              value={member.role}
              className="text-sm px-2 py-1 border rounded"
            >
              <option value={MEMBER_ROLES.ADMIN}>
                {MEMBER_ROLE_LABELS[MEMBER_ROLES.ADMIN]}
              </option>
              <option value={MEMBER_ROLES.MEMBER}>
                {MEMBER_ROLE_LABELS[MEMBER_ROLES.MEMBER]}
              </option>
              <option value={MEMBER_ROLES.VIEWER}>
                {MEMBER_ROLE_LABELS[MEMBER_ROLES.VIEWER]}
              </option>
            </select>
          )}

          {canRemove && onRemove && (
            <button
              onClick={() => onRemove(member.user_id)}
              className="text-sm text-red-600 hover:text-red-800"
            >
              Remove
            </button>
          )}
        </div>
      )}
    </div>
  );
}
EOF

# Verify
cat src/components/features/members/MemberCard.tsx
```

**Create MemberList component:**

```bash
cat > src/components/features/members/MemberList.tsx << 'EOF'
'use client';

// ============================================
// MEMBER LIST COMPONENT
// Single Responsibility: Display list of members
// ============================================

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { MemberCard } from './MemberCard';
import { removeMember, updateMemberRole } from '@/lib/actions/members';
import type { ProjectMember, MemberRole } from '@/lib/types/database';
import { SUCCESS_MESSAGES } from '@/constants';

interface MemberListProps {
  members: ProjectMember[];
  projectId: string;
  currentUserRole: MemberRole;
}

export function MemberList({ members, projectId, currentUserRole }: MemberListProps) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const handleRemove = async (userId: string) => {
    if (!confirm('Are you sure you want to remove this member?')) return;

    startTransition(async () => {
      const result = await removeMember({ user_id: userId, project_id: projectId });

      if (result.success) {
        router.refresh();
      } else {
        setError(result.error || 'Failed to remove member');
      }
    });
  };

  const handleUpdateRole = async (userId: string, role: MemberRole) => {
    startTransition(async () => {
      const result = await updateMemberRole({
        user_id: userId,
        project_id: projectId,
        role,
      });

      if (result.success) {
        router.refresh();
      } else {
        setError(result.error || 'Failed to update role');
      }
    });
  };

  if (members.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">No members found.</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      <div className="grid gap-4 md:grid-cols-2">
        {members.map((member) => (
          <MemberCard
            key={member.user_id}
            member={member}
            currentUserRole={currentUserRole}
            onRemove={handleRemove}
            onUpdateRole={handleUpdateRole}
          />
        ))}
      </div>

      {isPending && (
        <p className="text-sm text-gray-500 text-center">Updating...</p>
      )}
    </div>
  );
}
EOF

# Verify
cat src/components/features/members/MemberList.tsx
```

**Create InviteMemberForm component:**

```bash
cat > src/components/features/members/InviteMemberForm.tsx << 'EOF'
'use client';

// ============================================
// INVITE MEMBER FORM COMPONENT
// Single Responsibility: Invite new members
// ============================================

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { inviteMember } from '@/lib/actions/members';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import {
  MEMBER_ROLES,
  MEMBER_ROLE_LABELS,
  MEMBER_ROLE_DESCRIPTIONS,
  UI_LABELS,
  SUCCESS_MESSAGES,
} from '@/constants';

interface InviteMemberFormProps {
  projectId: string;
  onSuccess?: () => void;
}

export function InviteMemberForm({ projectId, onSuccess }: InviteMemberFormProps) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [email, setEmail] = useState('');
  const [role, setRole] = useState(MEMBER_ROLES.MEMBER);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    startTransition(async () => {
      const result = await inviteMember({
        email,
        role,
        project_id: projectId,
      });

      if (result.success) {
        setEmail('');
        setRole(MEMBER_ROLES.MEMBER);
        router.refresh();
        onSuccess?.();
      } else {
        setError(result.error || 'Failed to invite member');
      }
    });
  };

  const roleOptions = [
    {
      value: MEMBER_ROLES.ADMIN,
      label: MEMBER_ROLE_LABELS[MEMBER_ROLES.ADMIN],
    },
    {
      value: MEMBER_ROLES.MEMBER,
      label: MEMBER_ROLE_LABELS[MEMBER_ROLES.MEMBER],
    },
    {
      value: MEMBER_ROLES.VIEWER,
      label: MEMBER_ROLE_LABELS[MEMBER_ROLES.VIEWER],
    },
  ];

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      <Input
        label="Email Address"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="colleague@example.com"
        required
        disabled={isPending}
      />

      <Select
        label="Role"
        value={role}
        onChange={(e) => setRole(e.target.value as any)}
        options={roleOptions}
        disabled={isPending}
      />

      <div className="text-sm text-gray-600 bg-gray-50 p-3 rounded">
        <strong>{MEMBER_ROLE_LABELS[role]}:</strong> {MEMBER_ROLE_DESCRIPTIONS[role]}
      </div>

      <Button type="submit" disabled={isPending} isLoading={isPending}>
        {isPending ? 'Inviting...' : 'Invite Member'}
      </Button>
    </form>
  );
}
EOF

# Verify
cat src/components/features/members/InviteMemberForm.tsx
```

**Verify all components compile:**

```bash
npx tsc --noEmit src/components/features/members/*.tsx
```

---

### 🎯 STEP 7 — Create Members Page

Create the members page:

```bash
mkdir -p 'src/app/dashboard/projects/[id]/members'

cat > 'src/app/dashboard/projects/[id]/members/page.tsx' << 'EOF'
// ============================================
// MEMBERS PAGE (Server Component)
// ============================================

import Link from 'next/link';
import { getProjectMembers, checkMemberPermissions } from '@/lib/actions/members';
import { MemberList } from '@/components/features/members/MemberList';
import { InviteMemberForm } from '@/components/features/members/InviteMemberForm';
import { Button } from '@/components/ui/Button';
import { ROUTES, UI_LABELS, ERROR_MESSAGES } from '@/constants';

interface MembersPageProps {
  params: Promise<{ id: string }>;
}

export default async function MembersPage({ params }: MembersPageProps) {
  const { id: projectId } = await params;

  // Fetch members and check permissions
  const [membersResult, permissionsResult] = await Promise.all([
    getProjectMembers(projectId),
    checkMemberPermissions(projectId),
  ]);

  // Check access
  if (!permissionsResult.success || !permissionsResult.data?.has_access) {
    return (
      <div className="p-6">
        <p className="text-red-600">
          {permissionsResult.error || ERROR_MESSAGES.MEMBER.INSUFFICIENT_PERMISSIONS}
        </p>
      </div>
    );
  }

  const members = membersResult.data || [];
  const permissions = permissionsResult.data;
  const currentUserRole = permissions.user_role!;

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Project Members</h1>
          <p className="text-gray-600 mt-1">{members.length} members</p>
        </div>

        <Link href={ROUTES.PROJECT_VIEW(projectId)}>
          <Button variant="secondary">{UI_LABELS.BUTTONS.BACK} to Project</Button>
        </Link>
      </div>

      {/* Invite Form (only if can invite) */}
      {permissions.can_invite_members && (
        <div className="bg-white p-6 rounded-lg border">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Invite New Member</h2>
          <InviteMemberForm projectId={projectId} />
        </div>
      )}

      {/* Members List */}
      <div className="bg-white p-6 rounded-lg border">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Team Members</h2>
        {membersResult.success ? (
          <MemberList
            members={members}
            projectId={projectId}
            currentUserRole={currentUserRole}
          />
        ) : (
          <p className="text-red-600">{membersResult.error}</p>
        )}
      </div>
    </div>
  );
}
EOF

# Verify
cat 'src/app/dashboard/projects/[id]/members/page.tsx'
```

**Verify page compiles:**

```bash
npx tsc --noEmit 'src/app/dashboard/projects/[id]/members/page.tsx'
```

---

## ✅ 3. VERIFY

### Verification Checklist

**🎯 Step 1: Add Member Constants**
- [ ] MEMBER_ROLES verified/added to `src/constants/index.ts`
- [ ] MEMBER_ROLE_LABELS, MEMBER_ROLE_DESCRIPTIONS added
- [ ] MEMBER_PERMISSIONS matrix added
- [ ] Member routes added to ROUTES object
- [ ] Member error/success messages added
- [ ] TypeScript compiles without errors

**🎯 Step 2: Database**
- [ ] Migration file `004_member_rls_and_rpc.sql` created
- [ ] RLS enabled on `prj_project_members` table
- [ ] 4 RLS policies created (SELECT, INSERT, UPDATE, DELETE)
- [ ] RPC function `get_project_members()` created
- [ ] RPC function `check_member_role()` created
- [ ] RPC function `get_user_projects()` created
- [ ] RPC function `invite_member_by_email()` created
- [ ] Indexes created for performance

**🎯 Step 3: Types & Validation**
- [ ] Member types added to `src/lib/types/database.ts`
- [ ] `src/lib/validations/member.ts` created with Zod schemas
- [ ] TypeScript compiles without errors

**🎯 Step 4: Permission Utilities**
- [ ] `src/utils/permissions.ts` created
- [ ] Permission helper functions implemented
- [ ] TypeScript compiles without errors

**🎯 Step 5: Server Actions**
- [ ] `src/lib/actions/members.ts` created
- [ ] `use cache` directive on read functions
- [ ] All error messages use constants
- [ ] TypeScript compiles without errors

**🎯 Step 6: Components**
- [ ] `MemberCard.tsx` created (displays one member)
- [ ] `MemberList.tsx` created (displays members with actions)
- [ ] `InviteMemberForm.tsx` created (invite form)
- [ ] All components use constants
- [ ] TypeScript compiles without errors

**🎯 Step 7: Pages**
- [ ] Members page created at `[id]/members/page.tsx`
- [ ] Permission checks implemented
- [ ] TypeScript compiles without errors

### Manual Testing

**Test Member Management:**

1. **Start dev server:**
   ```bash
   npm run dev
   ```

2. **Create/Access a project:**
   - Navigate to dashboard
   - Open a project you own

3. **Access Members page:**
   - Click "Members" or navigate to `/dashboard/projects/{id}/members`
   - Should see yourself as Owner

4. **Invite a member:**
   - Fill invite form with email
   - Select role (Admin/Member/Viewer)
   - Submit - should see new member in list

5. **Update member role:**
   - Change role in dropdown (if Owner)
   - Should update immediately

6. **Remove member:**
   - Click "Remove" on non-owner member
   - Confirm - member should disappear

7. **Test permissions:**
   - Login as different role (Admin/Member/Viewer)
   - Verify appropriate buttons show/hide

### Code Quality Checks

```bash
# No magic strings for roles
grep -r "role === 'owner'" src/ --exclude="*.sql"

# All role checks use constants
grep -r "MEMBER_ROLES\." src/

# Permission checks use utility functions
grep -r "hasPermission\|canManageMembers" src/
```

---

## 🎓 4. KEY CONCEPTS SUMMARY

### Best Practices Learned

✅ **Many-to-Many Relationships**
- Junction table connects two entities
- Additional data on relationships (role, joined_at)
- Complex RLS policies for M:N access control

✅ **Role-Based Access Control**
- Permission matrix defines capabilities
- Database enforces permissions (RLS)
- Client shows/hides UI based on role
- Server validates all actions

✅ **RPC Functions for M:N**
- Join queries across multiple tables
- Return aggregated data
- Enforce security in database
- Better performance than multiple queries

✅ **Permission Utilities**
- Centralized permission logic
- Type-safe permission checks
- Reusable across components
- Easy to test

✅ **Constants for Roles**
- Type-safe role values
- Autocomplete everywhere
- Single source of truth
- Easy to add new roles

### File Organization

```
src/
├── constants/
│   └── index.ts              ← Roles, permissions, messages
├── utils/
│   └── permissions.ts        ← Permission helpers
├── lib/
│   ├── actions/
│   │   └── members.ts        ← Member CRUD (with cache)
│   ├── validations/
│   │   └── member.ts         ← Zod schemas
│   └── types/
│       └── database.ts       ← Member types
├── components/
│   └── features/members/
│       ├── MemberCard.tsx    ← Display one member
│       ├── MemberList.tsx    ← Display list with actions
│       └── InviteMemberForm.tsx  ← Invite form
└── app/
    └── dashboard/projects/[id]/members/
        └── page.tsx          ← Members page (Server Component)
```

### Next Steps

With Lesson 6 complete, you now have:
- ✅ Many-to-many relationships (users ↔ projects)
- ✅ Role-based access control
- ✅ Member management (invite, remove, update roles)
- ✅ Permission system
- ✅ Team collaboration features

**Technologies:** Many-to-Many, RLS, RPC Functions, RBAC, Zod, TypeScript

---

**🎉 Congratulations!** You've completed Lesson 6 and learned how to build team collaboration features with many-to-many relationships!
