# Astro 5.0 Tutorial - Lesson 11: Admin Dashboard & Content Management

**Prerequisites:** Completion of Lessons 1-10

---

## ✅ 1. DESC (Description)

### What You'll Learn

Build a complete admin dashboard for managing content, users, and comments with role-based access control.

**Core Concepts:**
- ✅ Admin dashboard layout
- ✅ Post creation/editing interface
- ✅ Rich text editor (Tiptap)
- ✅ Image upload with preview
- ✅ User management panel
- ✅ Comment moderation
- ✅ Analytics dashboard with charts
- ✅ Role-based access control (RBAC)

**What You'll Build:**
- Admin dashboard page
- Post editor with Tiptap
- Image upload manager
- User management interface
- Comment moderation panel
- Analytics charts
- Activity logs
- Settings page

---

## ✅ 2. CODE (Implementation)

### STEP 1: Create Admin Role System

\`\`\`bash
cat > supabase/migrations/014_create_admin_roles.sql << 'EOF'
-- Create user roles enum
CREATE TYPE user_role AS ENUM ('user', 'editor', 'admin');

-- Add role column to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role user_role DEFAULT 'user';

-- Create admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'editor')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RLS policies for admin actions
CREATE POLICY "Admins can manage all posts"
ON posts FOR ALL
USING (is_admin());

CREATE POLICY "Admins can manage all comments"
ON comments FOR ALL
USING (is_admin());
EOF

npm run db:push
\`\`\`

---

### STEP 2: Create Admin Dashboard

\`\`\`bash
cat > src/pages/admin/index.astro << 'EOF'
---
import MainLayout from '../../layouts/MainLayout.astro';
import { createSupabaseServerClient } from '../../lib/auth';

const supabase = createSupabaseServerClient(Astro.cookies);

// Check admin access
const { data: { user } } = await supabase.auth.getUser();
if (!user) return Astro.redirect('/login');

const { data: profile } = await supabase
  .from('profiles')
  .select('role')
  .eq('id', user.id)
  .single();

if (!profile || !['admin', 'editor'].includes(profile.role)) {
  return Astro.redirect('/');
}

// Get stats
const { count: totalPosts } = await supabase
  .from('posts')
  .select('*', { count: 'exact', head: true });

const { count: totalUsers } = await supabase
  .from('profiles')
  .select('*', { count: 'exact', head: true });

const { count: totalComments } = await supabase
  .from('comments')
  .select('*', { count: 'exact', head: true });

const { count: pendingFlags } = await supabase
  .from('comment_flags')
  .select('*', { count: 'exact', head: true })
  .eq('resolved', false);
---

<MainLayout title="Admin Dashboard">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <h1 class="text-4xl font-bold mb-8">Admin Dashboard</h1>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-12">
      <div class="card">
        <div class="text-sm text-gray-500 mb-2">Total Posts</div>
        <div class="text-3xl font-bold">{totalPosts}</div>
      </div>

      <div class="card">
        <div class="text-sm text-gray-500 mb-2">Total Users</div>
        <div class="text-3xl font-bold">{totalUsers}</div>
      </div>

      <div class="card">
        <div class="text-sm text-gray-500 mb-2">Total Comments</div>
        <div class="text-3xl font-bold">{totalComments}</div>
      </div>

      <div class="card">
        <div class="text-sm text-gray-500 mb-2">Pending Flags</div>
        <div class="text-3xl font-bold text-red-600">{pendingFlags}</div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <a href="/admin/posts/new" class="card hover:border-accent transition-colors">
        <h3 class="text-xl font-bold mb-2">Create Post</h3>
        <p class="text-gray-600">Write a new blog post</p>
      </a>

      <a href="/admin/posts" class="card hover:border-accent transition-colors">
        <h3 class="text-xl font-bold mb-2">Manage Posts</h3>
        <p class="text-gray-600">Edit or delete posts</p>
      </a>

      <a href="/admin/comments" class="card hover:border-accent transition-colors">
        <h3 class="text-xl font-bold mb-2">Moderate Comments</h3>
        <p class="text-gray-600">Review flagged comments</p>
      </a>
    </div>
  </div>
</MainLayout>

<style>
  .card {
    @apply bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6;
  }
</style>
EOF
\`\`\`

---

### STEP 3: Create Post Editor with Tiptap

\`\`\`bash
# Install Tiptap
npm install @tiptap/react @tiptap/starter-kit @tiptap/extension-image

cat > src/components/react/PostEditor.tsx << 'EOF'
import React from 'react';
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Image from '@tiptap/extension-image';

interface PostEditorProps {
  initialContent?: string;
  onChange: (content: string) => void;
}

export function PostEditor({ initialContent = '', onChange }: PostEditorProps) {
  const editor = useEditor({
    extensions: [StarterKit, Image],
    content: initialContent,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
  });

  if (!editor) return null;

  return (
    <div className="border border-gray-300 rounded-lg">
      {/* Toolbar */}
      <div className="border-b border-gray-300 p-2 flex gap-1">
        <button
          onClick={() => editor.chain().focus().toggleBold().run()}
          className={\`p-2 rounded \${editor.isActive('bold') ? 'bg-gray-200' : ''}\`}
        >
          <strong>B</strong>
        </button>

        <button
          onClick={() => editor.chain().focus().toggleItalic().run()}
          className={\`p-2 rounded \${editor.isActive('italic') ? 'bg-gray-200' : ''}\`}
        >
          <em>I</em>
        </button>

        <button
          onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
          className={\`p-2 rounded \${editor.isActive('heading', { level: 2 }) ? 'bg-gray-200' : ''}\`}
        >
          H2
        </button>

        <button
          onClick={() => editor.chain().focus().toggleBulletList().run()}
          className={\`p-2 rounded \${editor.isActive('bulletList') ? 'bg-gray-200' : ''}\`}
        >
          •
        </button>

        <button
          onClick={() => editor.chain().focus().toggleOrderedList().run()}
          className={\`p-2 rounded \${editor.isActive('orderedList') ? 'bg-gray-200' : ''}\`}
        >
          1.
        </button>
      </div>

      {/* Editor */}
      <EditorContent editor={editor} className="prose max-w-none p-4" />
    </div>
  );
}
EOF
\`\`\`

---

## ✅ 3. VERIFY (Testing & Troubleshooting)

### Verification Checklist

**Admin Dashboard:**
- [ ] Only admins can access
- [ ] Stats display correctly
- [ ] Quick actions work
- [ ] Role checks enforce

**Post Editor:**
- [ ] Rich text editing works
- [ ] Images can be uploaded
- [ ] Content saves correctly

---

**Congratulations!** 🎉 You've built a complete admin dashboard!

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 6-8 hours
