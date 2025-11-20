# Astro 5.0 Quick Reference Guide

> **Essential reference for Astro 5.0 features used in this tutorial**

---

## Table of Contents

1. [Content Layer API](#content-layer-api)
2. [Server Islands](#server-islands)
3. [Component Syntax](#component-syntax)
4. [Client Directives](#client-directives)
5. [View Transitions](#view-transitions)
6. [Environment Variables](#environment-variables)
7. [Routing](#routing)
8. [Supabase Integration](#supabase-integration)

---

## Content Layer API

### Defining Collections

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const blogCollection = defineCollection({
  type: 'content', // 'content' for local files
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.date(),
    author: z.string(),
    tags: z.array(z.string()),
    featured: z.boolean().default(false),
  }),
});

export const collections = {
  blog: blogCollection,
};
```

### Querying Collections

```typescript
// Get all entries
import { getCollection } from 'astro:content';
const allPosts = await getCollection('blog');

// Filter entries
const publishedPosts = await getCollection('blog', ({ data }) => {
  return data.draft !== true;
});

// Sort entries
const sortedPosts = allPosts.sort(
  (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
);

// Get single entry
import { getEntry } from 'astro:content';
const post = await getEntry('blog', 'post-slug');
```

### Rendering Content

```astro
---
import { getEntry } from 'astro:content';

const post = await getEntry('blog', Astro.params.slug);
const { Content } = await post.render();
---

<article>
  <h1>{post.data.title}</h1>
  <Content />
</article>
```

---

## Server Islands

### Basic Server Island

```astro
---
// src/components/UserProfile.astro
// This component will be deferred and rendered on the server
import { getUser } from '../lib/supabase';

const user = await getUser();
---

<div server:defer>
  <img src={user.avatar} alt={user.name} />
  <p>{user.name}</p>
</div>
```

### Using Server Islands in Pages

```astro
---
// src/pages/index.astro
import UserProfile from '../components/UserProfile.astro';
---

<html>
  <body>
    <!-- Static content loads first -->
    <h1>Welcome!</h1>

    <!-- Server Island loads after initial page render -->
    <UserProfile />
  </body>
</html>
```

### Server Island with Encrypted Props

```astro
---
// Sensitive data is automatically encrypted
const apiKey = import.meta.env.API_KEY;
---

<div server:defer>
  <SecureComponent apiKey={apiKey} />
</div>
```

### Configuration

```javascript
// astro.config.mjs
export default defineConfig({
  output: 'static', // or 'server'
  experimental: {
    serverIslands: true,
  },
});
```

---

## Component Syntax

### Basic Component

```astro
---
// Frontmatter (JavaScript/TypeScript)
const { title, subtitle } = Astro.props;
const date = new Date();
---

<!-- Template (HTML) -->
<div>
  <h1>{title}</h1>
  <h2>{subtitle}</h2>
  <p>Generated on: {date.toLocaleDateString()}</p>
</div>

<style>
  /* Scoped CSS */
  div {
    padding: 1rem;
  }
</style>
```

### Props with TypeScript

```astro
---
interface Props {
  title: string;
  description?: string;
  tags: string[];
}

const { title, description, tags } = Astro.props;
---

<article>
  <h1>{title}</h1>
  {description && <p>{description}</p>}
  <ul>
    {tags.map(tag => <li>{tag}</li>)}
  </ul>
</article>
```

### Slots

```astro
---
// Layout.astro
const { title } = Astro.props;
---

<html>
  <head>
    <title>{title}</title>
  </head>
  <body>
    <header>
      <slot name="header" />
    </header>

    <main>
      <slot /> <!-- Default slot -->
    </main>

    <footer>
      <slot name="footer" />
    </footer>
  </body>
</html>
```

Using slots:

```astro
---
import Layout from './Layout.astro';
---

<Layout title="My Page">
  <div slot="header">
    <h1>Header Content</h1>
  </div>

  <p>Main content goes here</p>

  <div slot="footer">
    <p>Footer content</p>
  </div>
</Layout>
```

---

## Client Directives

### `client:load`

Load component JavaScript immediately on page load.

```astro
<Counter client:load />
```

**Use when:** Component needs to be interactive immediately.

### `client:idle`

Load component JavaScript after page is idle.

```astro
<SearchBox client:idle />
```

**Use when:** Component is important but not immediately needed.

### `client:visible`

Load component JavaScript when it enters the viewport.

```astro
<CommentSection client:visible />
```

**Use when:** Component is below the fold.

### `client:media`

Load component based on media query.

```astro
<MobileMenu client:media="(max-width: 768px)" />
```

**Use when:** Component only needed on certain screen sizes.

### `client:only`

Skip server-side rendering, only render on client.

```astro
<ClientOnlyWidget client:only="react" />
```

**Use when:** Component has client-only dependencies (window, localStorage).

---

## View Transitions

### Enable View Transitions

```astro
---
// src/layouts/BaseLayout.astro
import { ViewTransitions } from 'astro:transitions';
---

<html>
  <head>
    <ViewTransitions />
  </head>
  <body>
    <slot />
  </body>
</html>
```

### Transition Naming

```astro
<div transition:name="hero-image">
  <img src="/hero.jpg" alt="Hero" />
</div>
```

### Persist Elements Across Pages

```astro
<audio transition:persist>
  <source src="/music.mp3" type="audio/mpeg" />
</audio>
```

### Custom Transitions

```astro
<div
  transition:animate="slide"
  transition:duration="0.5s"
>
  Content
</div>
```

### Transition Events

```astro
<script>
  document.addEventListener('astro:page-load', () => {
    console.log('Page loaded!');
  });

  document.addEventListener('astro:before-preparation', () => {
    console.log('Preparing to navigate...');
  });
</script>
```

---

## Environment Variables

### Define Environment Variables

```typescript
// env.d.ts
/// <reference types="astro/client" />

interface ImportMetaEnv {
  readonly SUPABASE_URL: string;
  readonly SUPABASE_ANON_KEY: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

### Using `astro:env`

```typescript
// astro.config.mjs
import { defineConfig, envField } from 'astro/config';

export default defineConfig({
  env: {
    schema: {
      SUPABASE_URL: envField.string({
        context: 'server',
        access: 'public',
      }),
      SUPABASE_ANON_KEY: envField.string({
        context: 'server',
        access: 'public',
      }),
      SUPABASE_SERVICE_KEY: envField.string({
        context: 'server',
        access: 'secret',
      }),
    },
  },
});
```

### Accessing Environment Variables

```typescript
// Server-side
import { SUPABASE_URL } from 'astro:env/server';

// Client-side (public only)
import { SUPABASE_URL } from 'astro:env/client';
```

### `.env` File

```bash
# .env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
SUPABASE_SERVICE_KEY=eyJhbGciOi... # Secret, server-only
```

---

## Routing

### File-Based Routing

```
src/pages/
├── index.astro          → /
├── about.astro          → /about
├── blog/
│   ├── index.astro      → /blog
│   └── [slug].astro     → /blog/:slug
└── api/
    └── posts.json.ts    → /api/posts.json
```

### Dynamic Routes

```astro
---
// src/pages/blog/[slug].astro
export async function getStaticPaths() {
  const posts = await getCollection('blog');

  return posts.map(post => ({
    params: { slug: post.slug },
    props: { post },
  }));
}

const { post } = Astro.props;
---

<h1>{post.data.title}</h1>
```

### Rest Parameters

```astro
---
// src/pages/[...path].astro
const { path } = Astro.params;
---

<p>Path: {path}</p>
```

### API Routes

```typescript
// src/pages/api/posts.json.ts
import type { APIRoute } from 'astro';

export const GET: APIRoute = async ({ request }) => {
  return new Response(
    JSON.stringify({ posts: [] }),
    {
      status: 200,
      headers: {
        'Content-Type': 'application/json'
      }
    }
  );
};

export const POST: APIRoute = async ({ request }) => {
  const data = await request.json();

  return new Response(
    JSON.stringify({ success: true }),
    { status: 201 }
  );
};
```

### Middleware

```typescript
// src/middleware.ts
import { defineMiddleware } from 'astro:middleware';

export const onRequest = defineMiddleware(async (context, next) => {
  // Check auth
  const session = await getSession(context.cookies);

  if (!session && context.url.pathname.startsWith('/admin')) {
    return Response.redirect(new URL('/login', context.url));
  }

  return next();
});
```

---

## Supabase Integration

### Setup Supabase Client

```typescript
// src/lib/supabase/server.ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

export function getSupabaseServer() {
  return createClient<Database>(
    import.meta.env.SUPABASE_URL,
    import.meta.env.SUPABASE_SERVICE_KEY,
    {
      auth: {
        persistSession: false,
      },
    }
  );
}
```

```typescript
// src/lib/supabase/client.ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

export const supabaseClient = createClient<Database>(
  import.meta.env.PUBLIC_SUPABASE_URL,
  import.meta.env.PUBLIC_SUPABASE_ANON_KEY
);
```

### Authentication

```typescript
// Sign up
const { data, error } = await supabaseClient.auth.signUp({
  email: 'user@example.com',
  password: 'password123',
});

// Sign in
const { data, error } = await supabaseClient.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123',
});

// Sign out
await supabaseClient.auth.signOut();

// Get session
const { data: { session } } = await supabaseClient.auth.getSession();
```

### Database Queries

```typescript
// Select
const { data, error } = await supabaseClient
  .from('posts')
  .select('*')
  .eq('published', true)
  .order('created_at', { ascending: false });

// Insert
const { data, error } = await supabaseClient
  .from('posts')
  .insert({ title: 'New Post', content: '...' })
  .select()
  .single();

// Update
const { data, error } = await supabaseClient
  .from('posts')
  .update({ title: 'Updated Title' })
  .eq('id', postId)
  .select()
  .single();

// Delete
const { error } = await supabaseClient
  .from('posts')
  .delete()
  .eq('id', postId);
```

### Real-time Subscriptions

```typescript
const channel = supabaseClient
  .channel('posts-changes')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'posts',
    },
    (payload) => {
      console.log('Change received!', payload);
    }
  )
  .subscribe();

// Cleanup
channel.unsubscribe();
```

---

## Common Patterns

### Protected Route

```astro
---
// src/pages/admin/index.astro
import { getSupabaseServer } from '../../lib/supabase/server';

const supabase = getSupabaseServer();
const { data: { session } } = await supabase.auth.getSession();

if (!session) {
  return Astro.redirect('/login');
}
---

<h1>Admin Dashboard</h1>
```

### Form Handling

```astro
---
// src/pages/contact.astro
let message = '';

if (Astro.request.method === 'POST') {
  const data = await Astro.request.formData();
  const name = data.get('name');

  // Process form...
  message = 'Thank you!';
}
---

<form method="POST">
  <input type="text" name="name" required />
  <button type="submit">Submit</button>
</form>

{message && <p>{message}</p>}
```

### Pagination

```astro
---
export async function getStaticPaths({ paginate }) {
  const posts = await getCollection('blog');

  return paginate(posts, { pageSize: 10 });
}

const { page } = Astro.props;
---

{page.data.map(post => <PostCard post={post} />)}

{page.url.prev && <a href={page.url.prev}>Previous</a>}
{page.url.next && <a href={page.url.next}>Next</a>}
```

---

## Performance Tips

### 1. Static Generation by Default
Use `output: 'static'` for maximum performance.

### 2. Minimize Client JavaScript
Only hydrate components that need interactivity.

### 3. Use Server Islands for Dynamic Content
Combine static pages with dynamic widgets.

### 4. Optimize Images

```astro
---
import { Image } from 'astro:assets';
import heroImage from '../assets/hero.jpg';
---

<Image
  src={heroImage}
  alt="Hero"
  width={800}
  height={600}
/>
```

### 5. Code Splitting
Client JavaScript is automatically split by island.

---

## Build Commands

```bash
# Development
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Type check
npm run astro check
```

---

## Configuration

```javascript
// astro.config.mjs
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';

export default defineConfig({
  output: 'static', // 'static' or 'server'
  integrations: [
    react(),
    tailwind(),
    mdx(),
  ],
  experimental: {
    serverIslands: true,
  },
  vite: {
    // Vite config
  },
});
```

---

## Useful Links

- **Astro Docs**: https://docs.astro.build/
- **Astro 5.0 Release**: https://astro.build/blog/astro-5/
- **Content Collections**: https://docs.astro.build/en/guides/content-collections/
- **Server Islands**: https://docs.astro.build/en/guides/server-islands/
- **Supabase + Astro**: https://docs.astro.build/en/guides/backend/supabase/

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
