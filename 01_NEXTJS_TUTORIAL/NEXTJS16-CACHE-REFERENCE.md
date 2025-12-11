# Next.js 16 Cache Components & PPR Reference Guide

> **Reference Document for Next.js 16 + React 19.2 Tutorial Series**
>
> This guide covers the new caching features introduced in Next.js 16: Cache Components, `use cache` directive, Suspense boundaries, and Partial Pre-Rendering (PPR).

---

## Table of Contents

1. [Overview](#overview)
2. [Complete Setup & Implementation](#complete-setup--implementation)
3. [Cache Life Options](#cache-life-options)
4. [Revalidation Strategies](#revalidation-strategies)
5. [Best Practices](#best-practices)
6. [Common Patterns](#common-patterns)

---

## Overview

Cache Components is a new Next.js 16 feature built on top of Partial Pre-Rendering (PPR) that allows you to cache dynamic sections with fine-grained control.

**Key Features:**
- ✅ Fine-grained caching at component level
- ✅ Works with PPR for optimal performance
- ✅ Instant revalidation with `updateTag`
- ✅ Custom cache durations
- ✅ Tag-based cache invalidation

**Rendering Strategies:**
- **Dynamic**: Server rendered on demand (no caching)
- **PPR Enabled**: Pre-rendered as static HTML with dynamic server streamed content
- **Fully Cached**: Pre-rendered as static content with Cache Components

---

## Complete Setup & Implementation

### Step 1: Initial Project Setup

**Before optimization - Traditional `page.tsx`:**
```tsx
export default async function Page() {
  // Fetch data
  const totalCount = await getTotalCount();
  const blogPosts = await getBlogPosts();

  return (
    <div>
      {/* Static Section - Title, Description, Button */}
      <div>
        <h1>Blog Title</h1>
        <p>Description</p>
        <button>Click Me</button>
      </div>

      {/* Static Section - Features */}
      <div>
        <p>Fast Performance</p>
        <p>Beautiful Design</p>
      </div>

      {/* Dynamic Section - Total Count */}
      <div>
        <p>Total blog posts: {totalCount}</p>
      </div>

      {/* Dynamic Section - Blog Posts List */}
      <div>
        {blogPosts.map(post => (
          <div key={post.id}>
            <h2>{post.title}</h2>
            <p>{post.content}</p>
          </div>
        ))}
      </div>

      {/* Static Section - Footer */}
      <footer>
        <p>Built with Next.js 16</p>
      </footer>
    </div>
  );
}
```

**Check build status:**
```bash
pnpm run build
```
**Result:** The index page shows as "Dynamic" (server rendered on demand).

---

### Step 2: Enable Cache Components

**Update `next.config.js`:**
```javascript
module.exports = {
  experimental: {
    cacheComponents: true
  }
}
```

---

### Step 3: Implement Suspense Boundaries

**Refactored `page.tsx` with Suspense:**
```tsx
import { Suspense } from 'react';

// Async component for blog posts list
async function BlogPostList() {
  const blogPosts = await getBlogPosts();

  return (
    <div>
      {blogPosts.map(post => (
        <div key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.content}</p>
          <img src={post.imageUrl} alt={post.title} />
        </div>
      ))}
    </div>
  );
}

// Async component for total posts count
async function TotalPosts() {
  const totalCount = await getTotalCount();

  return (
    <div>
      <p>Total blog posts: {totalCount}</p>
    </div>
  );
}

export default function Page() {
  return (
    <div>
      {/* Static Section - Title, Description, Button */}
      <div>
        <h1>Blog Title</h1>
        <p>Description</p>
        <button>Click Me</button>
      </div>

      {/* Static Section - Features */}
      <div>
        <p>Fast Performance</p>
        <p>Beautiful Design</p>
      </div>

      {/* Dynamic Section - Total Count wrapped in Suspense */}
      <Suspense fallback={<div>Loading count...</div>}>
        <TotalPosts />
      </Suspense>

      {/* Dynamic Section - Blog Posts wrapped in Suspense */}
      <Suspense fallback={<div>Loading posts...</div>}>
        <BlogPostList />
      </Suspense>

      {/* Static Section - Footer */}
      <footer>
        <p>Built with Next.js 16</p>
      </footer>
    </div>
  );
}
```

**Build and check PPR:**
```bash
pnpm run build
```
**Result:** Index page now shows **"Pre-rendered as static HTML with dynamic server streamed content"** (PPR enabled).

---

### Step 4: Add Cache Components with `use cache`

**Final `page.tsx` with Cache Components:**
```tsx
import { Suspense } from 'react';
import { cacheLife, cacheTag } from 'next/cache';

// Cached async component for blog posts list
async function BlogPostList() {
  'use cache';
  cacheLife('hours'); // Cache for 1 hour
  cacheTag('blog-posts'); // Tag for revalidation

  const blogPosts = await getBlogPosts();

  return (
    <div>
      {blogPosts.map(post => (
        <div key={post.id}>
          <h2>{post.title}</h2>
          <p>{post.content}</p>
          <img src={post.imageUrl} alt={post.title} />
        </div>
      ))}
    </div>
  );
}

// Dynamic (non-cached) async component for total posts count
async function TotalPosts() {
  const totalCount = await getTotalCount();

  return (
    <div>
      <p>Total blog posts: {totalCount}</p>
    </div>
  );
}

// OR if you want to cache TotalPosts too:
async function TotalPostsCached() {
  'use cache';
  cacheLife('hours'); // Cache for 1 hour
  cacheTag('total-posts'); // Tag for revalidation

  const totalCount = await getTotalCount();

  return (
    <div>
      <p>Total blog posts: {totalCount}</p>
    </div>
  );
}

export default function Page() {
  return (
    <div>
      {/* Static Section */}
      <div>
        <h1>Blog Title</h1>
        <p>Description</p>
        <button>Click Me</button>
      </div>

      {/* Static Section */}
      <div>
        <p>Fast Performance</p>
        <p>Beautiful Design</p>
      </div>

      {/* Dynamic/Cached Section with Suspense */}
      <Suspense fallback={<SkeletonLoader />}>
        <TotalPosts />
      </Suspense>

      {/* Cached Section with Suspense */}
      <Suspense fallback={<SkeletonLoader />}>
        <BlogPostList />
      </Suspense>

      {/* Static Section */}
      <footer>
        <p>Built with Next.js 16</p>
      </footer>
    </div>
  );
}
```

**Build and verify Cache Components:**
```bash
pnpm run build
```

**Result:**
- If both components use `use cache`: **"Pre-rendered as static content"**
- If only BlogPostList uses `use cache`: **"Pre-rendered as static HTML with dynamic server streamed content"**

---

## Cache Life Options

### Built-in Cache Profiles

```tsx
import { cacheLife } from 'next/cache';

// Available cache durations:
cacheLife('default'); // 15 minutes (default)
cacheLife('seconds'); // 1 second
cacheLife('hours');   // 1 hour
cacheLife('days');    // 1 day
cacheLife('max');     // 30 days
```

### Custom Cache Profile

**Define in `next.config.js`:**
```javascript
module.exports = {
  experimental: {
    cacheComponents: true
  },
  cacheLife: {
    biweekly: {
      stale: 60 * 60 * 24 * 14,      // 14 days in seconds
      revalidate: 60 * 60 * 24 * 14, // 14 days in seconds
      expire: 60 * 60 * 24 * 14       // 14 days in seconds
    },
    weekly: {
      stale: 60 * 60 * 24 * 7,        // 7 days
      revalidate: 60 * 60 * 24 * 7,
      expire: 60 * 60 * 24 * 7
    },
    minutes: {
      stale: 60 * 5,                  // 5 minutes
      revalidate: 60 * 5,
      expire: 60 * 5
    }
  }
}
```

**Use custom cache profile:**
```tsx
async function MyComponent() {
  'use cache';
  cacheLife('biweekly'); // Use custom profile
  cacheTag('my-data');

  const data = await fetchData();
  return <div>{data}</div>;
}
```

---

## Revalidation Strategies

### Strategy 1: `updateTag` - Instant Revalidation (Recommended)

**Server Action with `updateTag`:**
```tsx
'use server';

import { updateTag } from 'next/cache';
import { redirect } from 'next/navigation';

export async function createPost(formData: FormData) {
  const title = formData.get('title');
  const content = formData.get('content');
  const imageUrl = formData.get('imageUrl');

  // Create the post in database
  await createNewPost({ title, content, imageUrl });

  // Revalidate cache tags instantly
  updateTag('blog-posts');
  updateTag('total-posts');

  redirect('/');
}
```

**Create Post Form Component:**
```tsx
import { createPost } from './actions';

export function CreatePostForm() {
  return (
    <form action={createPost}>
      <input name="title" placeholder="Title" required />
      <textarea name="content" placeholder="Content" required />
      <input name="imageUrl" placeholder="Image URL" required />
      <button type="submit">Create Post</button>
    </form>
  );
}
```

**Benefits:**
- ✅ **Instant revalidation** (Read Your Own Writes)
- ✅ User sees fresh data immediately
- ✅ Works in Server Actions only

---

### Strategy 2: `revalidateTag` - Background Revalidation

**Route Handler with `revalidateTag`:**
```tsx
// app/api/revalidate/route.ts
import { revalidateTag } from 'next/cache';
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  const { tag } = await request.json();

  // Revalidates in background (not instant)
  revalidateTag(tag);

  return NextResponse.json({ revalidated: true });
}
```

**Client-side usage:**
```tsx
async function handleRevalidate() {
  await fetch('/api/revalidate', {
    method: 'POST',
    body: JSON.stringify({ tag: 'blog-posts' })
  });
}
```

**Characteristics:**
- ✅ Works in Route Handlers
- ❌ Background revalidation (not instant)
- ❌ User may see stale content initially

---

### Key Differences: `updateTag` vs `revalidateTag`

| Feature | `updateTag` | `revalidateTag` |
|---------|-------------|-----------------|
| **Where it works** | Server Actions only | Route Handlers |
| **Revalidation speed** | Instant (RYOW) | Background |
| **User experience** | Sees fresh data immediately | May see stale data first |
| **Use case** | Form submissions, mutations | Webhooks, cron jobs |

**Recommendation:** Use `updateTag` in Server Actions for best user experience.

---

## Best Practices

### 1. Choose Appropriate Cache Durations

```tsx
// Frequently changing data
async function LiveData() {
  'use cache';
  cacheLife('seconds'); // 1 second
  cacheTag('live-data');
  // ...
}

// Daily updates
async function DailyStats() {
  'use cache';
  cacheLife('hours'); // 1 hour
  cacheTag('daily-stats');
  // ...
}

// Rarely changing data
async function StaticContent() {
  'use cache';
  cacheLife('days'); // 1 day
  cacheTag('static-content');
  // ...
}
```

---

### 2. Use Descriptive Cache Tags

```tsx
// ❌ Bad - vague tags
cacheTag('data');
cacheTag('posts');

// ✅ Good - specific tags
cacheTag('blog-posts');
cacheTag('user-profile');
cacheTag('project-list');
cacheTag('task-details');
```

---

### 3. Always Wrap in Suspense

```tsx
// ❌ Bad - no fallback
async function MyComponent() {
  'use cache';
  const data = await fetchData();
  return <div>{data}</div>;
}

// ✅ Good - with Suspense and fallback
export default function Page() {
  return (
    <Suspense fallback={<SkeletonLoader />}>
      <MyComponent />
    </Suspense>
  );
}
```

---

### 4. Group Related Revalidations

```tsx
'use server';

import { updateTag } from 'next/cache';

export async function updateProject(projectId: string, data: any) {
  await updateProjectInDb(projectId, data);

  // Revalidate all related caches
  updateTag('project-list');
  updateTag(`project-${projectId}`);
  updateTag('project-stats');
  updateTag('user-projects');
}
```

---

### 5. Use Multiple Cache Tags

```tsx
async function ProjectDetails({ projectId }: { projectId: string }) {
  'use cache';
  cacheLife('hours');

  // Multiple tags for flexible revalidation
  cacheTag('project-list');           // Revalidate all projects
  cacheTag(`project-${projectId}`);   // Revalidate specific project
  cacheTag('projects');               // Revalidate projects category

  const project = await getProject(projectId);
  return <div>{project.name}</div>;
}
```

---

## Common Patterns

### Pattern 1: List + Detail Pages

**Projects List Page:**
```tsx
// app/projects/page.tsx
import { Suspense } from 'react';
import { cacheLife, cacheTag } from 'next/cache';

async function ProjectsList() {
  'use cache';
  cacheLife('hours');
  cacheTag('project-list');

  const projects = await getProjects();

  return (
    <div>
      {projects.map(project => (
        <ProjectCard key={project.id} project={project} />
      ))}
    </div>
  );
}

export default function ProjectsPage() {
  return (
    <div>
      <h1>Projects</h1>
      <Suspense fallback={<ProjectsSkeleton />}>
        <ProjectsList />
      </Suspense>
    </div>
  );
}
```

**Project Detail Page:**
```tsx
// app/projects/[id]/page.tsx
import { Suspense } from 'react';
import { cacheLife, cacheTag } from 'next/cache';

async function ProjectDetails({ id }: { id: string }) {
  'use cache';
  cacheLife('hours');
  cacheTag('project-list');         // Revalidate when list changes
  cacheTag(`project-${id}`);        // Revalidate specific project

  const project = await getProject(id);

  return (
    <div>
      <h1>{project.name}</h1>
      <p>{project.description}</p>
    </div>
  );
}

export default function ProjectPage({ params }: { params: { id: string } }) {
  return (
    <Suspense fallback={<ProjectDetailSkeleton />}>
      <ProjectDetails id={params.id} />
    </Suspense>
  );
}
```

**Update Action:**
```tsx
'use server';

import { updateTag } from 'next/cache';
import { revalidatePath } from 'next/cache';

export async function updateProject(id: string, data: any) {
  await updateProjectInDb(id, data);

  // Revalidate specific project and list
  updateTag(`project-${id}`);
  updateTag('project-list');

  revalidatePath(`/projects/${id}`);
  revalidatePath('/projects');
}
```

---

### Pattern 2: Dashboard with Multiple Metrics

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react';
import { cacheLife, cacheTag } from 'next/cache';

async function UserStats() {
  'use cache';
  cacheLife('hours');
  cacheTag('user-stats');

  const stats = await getUserStats();
  return <StatsCards stats={stats} />;
}

async function RecentActivity() {
  'use cache';
  cacheLife('seconds'); // More frequent updates
  cacheTag('user-activity');

  const activity = await getRecentActivity();
  return <ActivityList items={activity} />;
}

async function ProjectSummary() {
  'use cache';
  cacheLife('hours');
  cacheTag('project-summary');
  cacheTag('project-list');

  const summary = await getProjectSummary();
  return <SummaryWidget data={summary} />;
}

export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>

      {/* Each metric cached independently */}
      <Suspense fallback={<StatsSkeleton />}>
        <UserStats />
      </Suspense>

      <Suspense fallback={<ActivitySkeleton />}>
        <RecentActivity />
      </Suspense>

      <Suspense fallback={<SummarySkeleton />}>
        <ProjectSummary />
      </Suspense>
    </div>
  );
}
```

---

### Pattern 3: User-Specific Cached Data

```tsx
import { Suspense } from 'react';
import { cacheLife, cacheTag } from 'next/cache';
import { getCurrentUser } from '@/lib/auth';

async function UserProjects() {
  'use cache';
  cacheLife('hours');

  const user = await getCurrentUser();

  // User-specific cache tags
  cacheTag(`user-${user.id}-projects`);
  cacheTag('project-list');

  const projects = await getUserProjects(user.id);

  return (
    <div>
      {projects.map(project => (
        <ProjectCard key={project.id} project={project} />
      ))}
    </div>
  );
}

export default function MyProjectsPage() {
  return (
    <div>
      <h1>My Projects</h1>
      <Suspense fallback={<ProjectsSkeleton />}>
        <UserProjects />
      </Suspense>
    </div>
  );
}
```

**Revalidate user-specific data:**
```tsx
'use server';

import { updateTag } from 'next/cache';
import { getCurrentUser } from '@/lib/auth';

export async function createProject(formData: FormData) {
  const user = await getCurrentUser();

  // Create project
  await createProjectInDb({ ...formData, userId: user.id });

  // Revalidate user-specific and global caches
  updateTag(`user-${user.id}-projects`);
  updateTag('project-list');
}
```

---

### Pattern 4: Nested Components with Different Cache Durations

```tsx
import { Suspense } from 'react';
import { cacheLife, cacheTag } from 'next/cache';

// Cached for 1 day - rarely changes
async function ProjectMetadata({ id }: { id: string }) {
  'use cache';
  cacheLife('days');
  cacheTag(`project-${id}-metadata`);

  const metadata = await getProjectMetadata(id);
  return <MetadataDisplay data={metadata} />;
}

// Cached for 1 hour - changes occasionally
async function ProjectTasks({ id }: { id: string }) {
  'use cache';
  cacheLife('hours');
  cacheTag(`project-${id}-tasks`);

  const tasks = await getProjectTasks(id);
  return <TaskList tasks={tasks} />;
}

// Cached for 1 second - frequently changing
async function LiveCollaborators({ id }: { id: string }) {
  'use cache';
  cacheLife('seconds');
  cacheTag(`project-${id}-collaborators`);

  const collaborators = await getLiveCollaborators(id);
  return <CollaboratorList users={collaborators} />;
}

export default function ProjectPage({ params }: { params: { id: string } }) {
  return (
    <div>
      {/* Each component cached independently with different durations */}
      <Suspense fallback={<MetadataSkeleton />}>
        <ProjectMetadata id={params.id} />
      </Suspense>

      <Suspense fallback={<TasksSkeleton />}>
        <ProjectTasks id={params.id} />
      </Suspense>

      <Suspense fallback={<CollaboratorsSkeleton />}>
        <LiveCollaborators id={params.id} />
      </Suspense>
    </div>
  );
}
```

---

## Build Output Indicators

When you run `pnpm run build`, check for these indicators:

| Output | Meaning | Optimization Level |
|--------|---------|-------------------|
| **"Dynamic"** | Server rendered on demand | ❌ No caching |
| **"Pre-rendered as static HTML with dynamic server streamed content"** | PPR enabled | ✅ Partial pre-rendering |
| **"Pre-rendered as static content"** | Fully cached | ✅✅ Full caching |

---

## Complete Command Summary

```bash
# Build the application
pnpm run build

# Run development server
pnpm run dev

# Check build output to verify rendering strategy
pnpm run build | grep "Route"

# Check specific page rendering
pnpm run build | grep "/projects"
```

---

## Summary of Implementation Steps

1. ✅ **Enable Cache Components** in `next.config.js`:
   ```javascript
   experimental: { cacheComponents: true }
   ```

2. ✅ **Wrap dynamic sections in Suspense** boundaries:
   ```tsx
   <Suspense fallback={<Loading />}>
     <AsyncComponent />
   </Suspense>
   ```

3. ✅ **Add `'use cache'` directive** to async components:
   ```tsx
   async function MyComponent() {
     'use cache';
     // ...
   }
   ```

4. ✅ **Set cache duration** with `cacheLife()`:
   ```tsx
   cacheLife('hours'); // Cache for 1 hour
   ```

5. ✅ **Add cache tags** for revalidation:
   ```tsx
   cacheTag('my-data');
   ```

6. ✅ **Use `updateTag()` in Server Actions** to revalidate:
   ```tsx
   'use server';
   import { updateTag } from 'next/cache';

   export async function myAction() {
     // ... update data
     updateTag('my-data');
   }
   ```

7. ✅ **Build and verify** with `pnpm run build`

---

## Quick Reference Checklist

### For Every Cached Component:
- [ ] Component is async
- [ ] Wrapped in `<Suspense>` with fallback
- [ ] Has `'use cache'` directive
- [ ] Has `cacheLife()` configured
- [ ] Has `cacheTag()` for revalidation
- [ ] Related Server Actions call `updateTag()`

### Configuration:
- [ ] `next.config.js` has `experimental.cacheComponents: true`
- [ ] Custom cache profiles defined (optional)
- [ ] Build output shows correct rendering strategy

---

## Additional Resources

- **Next.js 16 Documentation**: [nextjs.org/docs](https://nextjs.org/docs)
- **Cache Components RFC**: [GitHub RFC](https://github.com/vercel/next.js/discussions)
- **PPR Documentation**: [Partial Pre-Rendering](https://nextjs.org/docs/app/building-your-application/rendering/partial-prerendering)

---

**Last Updated**: November 2025
**Next.js Version**: 16
**React Version**: 19.2
