# Astro 5.0 Tutorial - Lesson 2: Content Layer API & Collections

**Prerequisites:** Complete Lesson 1 (Setup & Project Structure)

---

## ✅ 1. DESC (Description)

### What You'll Learn

In this lesson, you'll master Astro's Content Layer API to build a fully functional blog with type-safe content management.

**Core Concepts:**
- ✅ Content Layer API fundamentals
- ✅ Content collections with Zod schemas
- ✅ Frontmatter structure and validation
- ✅ Type-safe queries with `getCollection()` and `getEntry()`
- ✅ Static path generation for dynamic routes
- ✅ Pagination implementation
- ✅ Category and tag filtering
- ✅ Reading time calculation
- ✅ Table of contents generation

**What You'll Build:**
- Blog content collection with validation
- Blog listing page with pagination
- Individual blog post pages
- Category filtering pages
- Tag cloud and filtering
- Reading time estimator
- Auto-generated TOC for posts
- Related posts widget

---

### Content Layer API Overview

**What is the Content Layer API?**

The Content Layer API is Astro's built-in solution for managing content with full type safety:

1. **Type-Safe Content** - Zod schemas validate frontmatter
2. **File-Based** - Markdown/MDX files in `src/content/`
3. **Query API** - `getCollection()` and `getEntry()` methods
4. **Static Generation** - Pre-render all content at build time
5. **IntelliSense** - Full TypeScript autocomplete

**Content Collections Flow:**
```
src/content/
├── config.ts              → Define schemas
└── blog/
    ├── post-1.md         → Content files
    └── post-2.md

Build Time:
1. Astro reads all .md files
2. Validates frontmatter against schema
3. Generates TypeScript types
4. Makes available via getCollection()
```

---

### Frontmatter vs Content

**Frontmatter (YAML):**
```yaml
---
title: "My Blog Post"
date: 2025-01-01
tags: ["astro", "web"]
---
```

**Content (Markdown):**
```markdown
# Heading

This is the **content** of the post.
```

**Accessing in Astro:**
```typescript
const { title, date, tags } = post.data;  // Frontmatter
const { Content } = await post.render();  // Rendered content
```

---

## ✅ 2. CODE (Implementation)

### STEP 1: Define Content Collection Schema

```bash
cat > src/content/config.ts << 'EOF'
import { defineCollection, z } from 'astro:content';

// Blog collection schema
const blogCollection = defineCollection({
  type: 'content',
  schema: z.object({
    // Required fields
    title: z.string().min(5).max(100),
    description: z.string().min(50).max(200),
    pubDate: z.date(),

    // Optional fields with defaults
    author: z.string().default('Anonymous'),
    heroImage: z.string().optional(),

    // Categories and tags
    category: z.enum([
      'technology',
      'tutorial',
      'news',
      'opinion',
      'showcase'
    ]),
    tags: z.array(z.string()).default([]),

    // Publication status
    draft: z.boolean().default(false),
    featured: z.boolean().default(false),

    // SEO
    ogImage: z.string().optional(),
    canonicalURL: z.string().url().optional(),
  }),
});

// Export collections
export const collections = {
  blog: blogCollection,
};
EOF
```

<details>
<summary>📖 <strong>Understanding Zod Schemas</strong></summary>

**Why Zod?**
- Runtime validation (catches errors at build time)
- Type inference (TypeScript types auto-generated)
- Error messages (clear validation failures)
- Transformations (parse dates, normalize strings)

**Common Zod Methods:**

```typescript
// String validation
z.string()                    // Any string
z.string().min(5)            // At least 5 chars
z.string().max(100)          // Max 100 chars
z.string().email()           // Valid email
z.string().url()             // Valid URL
z.string().optional()        // Can be undefined

// Number validation
z.number()                    // Any number
z.number().positive()         // > 0
z.number().int()             // Integer only

// Date validation
z.date()                      // Date object
z.coerce.date()              // Auto-convert string to date

// Arrays
z.array(z.string())          // String array
z.array(z.number()).min(1)   // At least 1 item

// Enums
z.enum(['a', 'b', 'c'])      // One of these values

// Objects
z.object({
  name: z.string(),
  age: z.number(),
})

// Defaults
z.string().default('value')   // Use this if undefined

// Optional vs Nullable
z.string().optional()         // string | undefined
z.string().nullable()         // string | null
```

**Schema Benefits:**
1. **Validation** - Invalid frontmatter = build error
2. **Type Safety** - Full autocomplete in TypeScript
3. **Documentation** - Schema documents expected fields
4. **Defaults** - Auto-fill missing values
</details>

---

### STEP 2: Create Sample Blog Posts

```bash
# Create blog content directory
mkdir -p src/content/blog

# Create first blog post
cat > src/content/blog/welcome-to-astro.md << 'EOF'
---
title: "Welcome to Astro 5.0"
description: "Learn why Astro is the best framework for content-driven websites with zero JavaScript by default."
pubDate: 2025-01-15
author: "Astro Team"
heroImage: "/images/welcome.jpg"
category: "tutorial"
tags: ["astro", "getting-started", "web-dev"]
featured: true
---

# Welcome to Astro!

Astro is a modern web framework designed for **speed and simplicity**. Unlike traditional frameworks, Astro ships **zero JavaScript by default**, making your websites lightning fast.

## Why Astro?

### 1. Zero JavaScript by Default
Astro components render to pure HTML and CSS. No client-side JavaScript unless you explicitly need it.

```javascript
// Only ships if you use client: directives
<Counter client:load />
```

### 2. Islands Architecture
Add interactivity exactly where needed with "islands" of React, Vue, or Svelte.

```astro
---
import Counter from './Counter.tsx';
---

<div>
  <h1>Static HTML</h1>
  <Counter client:idle /> {/* Only this hydrates! */}
</div>
```

### 3. Content Collections
Type-safe content management with Zod schemas:

```typescript
const posts = await getCollection('blog');
// posts is fully typed!
```

## Getting Started

Install Astro with a single command:

```bash
npm create astro@latest
```

Then choose a template and start building!

## Next Steps

- [Read the docs](https://docs.astro.build/)
- [Join Discord](https://astro.build/chat)
- [Explore examples](https://astro.build/themes/)

Happy coding! 🚀
EOF

# Create second blog post
cat > src/content/blog/content-layer-api.md << 'EOF'
---
title: "Mastering the Content Layer API"
description: "Deep dive into Astro's Content Layer API for managing blog posts, documentation, and any content with full type safety."
pubDate: 2025-01-20
author: "Content Team"
category: "tutorial"
tags: ["astro", "content-collections", "typescript"]
draft: false
---

# Content Layer API Guide

Astro's Content Layer API provides a **type-safe** way to manage content in your project.

## Defining Collections

Create `src/content/config.ts`:

```typescript
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  schema: z.object({
    title: z.string(),
    date: z.date(),
    tags: z.array(z.string()),
  }),
});

export const collections = { blog };
```

## Querying Content

Get all posts:

```typescript
import { getCollection } from 'astro:content';

const posts = await getCollection('blog');
```

Get a single post:

```typescript
import { getEntry } from 'astro:content';

const post = await getEntry('blog', 'my-post-slug');
```

## Filtering Content

Filter by frontmatter:

```typescript
const published = await getCollection('blog', ({ data }) => {
  return data.draft !== true;
});
```

## Rendering Content

```astro
---
const post = await getEntry('blog', Astro.params.slug);
const { Content } = await post.render();
---

<h1>{post.data.title}</h1>
<Content />
```

## Type Safety

TypeScript knows the shape of your content:

```typescript
posts.map(post => {
  post.data.title;  // ✅ string
  post.data.date;   // ✅ Date
  post.data.xyz;    // ❌ TypeScript error!
});
```

## Benefits

1. **Validation** - Invalid frontmatter fails at build time
2. **IntelliSense** - Full autocomplete in VS Code
3. **Refactoring** - Rename fields safely
4. **Documentation** - Schema documents content structure

Start using Content Collections today!
EOF

# Create third blog post
cat > src/content/blog/astro-vs-next.md << 'EOF'
---
title: "Astro vs Next.js: When to Use Each"
description: "Compare Astro and Next.js to understand which framework is best for your project based on content needs and interactivity."
pubDate: 2025-01-25
author: "Framework Comparison"
category: "opinion"
tags: ["astro", "nextjs", "comparison", "frameworks"]
featured: true
---

# Astro vs Next.js

Both frameworks are excellent, but serve different use cases.

## When to Use Astro

✅ **Content-heavy sites**
- Blogs
- Documentation
- Marketing sites
- Portfolios

✅ **Performance is critical**
- Zero JavaScript by default
- Faster page loads
- Better Core Web Vitals

✅ **Framework flexibility**
- Mix React, Vue, Svelte
- No lock-in

## When to Use Next.js

✅ **App-heavy projects**
- Dashboards
- SaaS applications
- Interactive tools

✅ **Server-side rendering**
- Dynamic data on every request
- Personalized content
- Real-time updates

✅ **React ecosystem**
- Need React-specific libraries
- Team expertise in React

## Performance Comparison

| Metric | Astro | Next.js |
|--------|-------|---------|
| Initial JS | 0KB | 80KB+ |
| Page Load | <1s | 1-3s |
| Build Time | Fast | Moderate |
| Learning Curve | Easy | Moderate |

## Hybrid Approach

You can use both!

- **Astro** for marketing site
- **Next.js** for app/dashboard
- Share design system

## Conclusion

- **Content-first?** → Astro
- **App-first?** → Next.js
- **Both?** → Use both!

Choose based on your needs, not hype.
EOF
```

---

### STEP 3: Create Blog Listing Page

```bash
cat > src/pages/blog/index.astro << 'EOF'
---
import { getCollection } from 'astro:content';
import MainLayout from '../../layouts/MainLayout.astro';
import { SITE_CONFIG } from '../../lib/constants';

// Get all blog posts
const allPosts = await getCollection('blog', ({ data }) => {
  // Filter out drafts in production
  if (import.meta.env.PROD) {
    return data.draft !== true;
  }
  return true;
});

// Sort by date (newest first)
const sortedPosts = allPosts.sort((a, b) =>
  b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
);

// Pagination setup
const POSTS_PER_PAGE = 6;
const currentPage = 1;
const totalPages = Math.ceil(sortedPosts.length / POSTS_PER_PAGE);
const paginatedPosts = sortedPosts.slice(0, POSTS_PER_PAGE);

// Calculate reading time
function calculateReadingTime(content: string): number {
  const wordsPerMinute = 200;
  const words = content.trim().split(/\s+/).length;
  return Math.ceil(words / wordsPerMinute);
}

// Format date
function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date);
}
---

<MainLayout
  title="Blog"
  description="Read our latest blog posts about web development, Astro, and modern frameworks"
>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <!-- Header -->
    <div class="text-center mb-12">
      <h1 class="text-5xl font-bold mb-4">Blog</h1>
      <p class="text-xl text-text-secondary max-w-2xl mx-auto">
        Thoughts, tutorials, and insights about web development
      </p>
    </div>

    <!-- Featured Posts -->
    {paginatedPosts.some(post => post.data.featured) && (
      <section class="mb-16">
        <h2 class="text-2xl font-bold mb-6">Featured Posts</h2>
        <div class="grid md:grid-cols-2 gap-8">
          {paginatedPosts
            .filter(post => post.data.featured)
            .slice(0, 2)
            .map(async (post) => {
              const { remarkPluginFrontmatter } = await post.render();
              return (
                <a
                  href={`/blog/${post.slug}`}
                  class="card hover:shadow-lg transition-shadow group"
                >
                  {post.data.heroImage && (
                    <img
                      src={post.data.heroImage}
                      alt={post.data.title}
                      class="w-full h-48 object-cover rounded-t-lg mb-4"
                    />
                  )}
                  <div class="p-6">
                    <div class="flex items-center gap-4 mb-3 text-sm text-text-secondary">
                      <span class="px-3 py-1 bg-accent/10 text-accent rounded-full">
                        {post.data.category}
                      </span>
                      <time datetime={post.data.pubDate.toISOString()}>
                        {formatDate(post.data.pubDate)}
                      </time>
                    </div>
                    <h3 class="text-2xl font-bold mb-2 group-hover:text-accent transition-colors">
                      {post.data.title}
                    </h3>
                    <p class="text-text-secondary mb-4">
                      {post.data.description}
                    </p>
                    <div class="flex items-center justify-between text-sm text-text-secondary">
                      <span>By {post.data.author}</span>
                      <span>{calculateReadingTime(post.body)} min read</span>
                    </div>
                  </div>
                </a>
              );
            })}
        </div>
      </section>
    )}

    <!-- All Posts Grid -->
    <section>
      <h2 class="text-2xl font-bold mb-6">All Posts</h2>
      <div class="grid md:grid-cols-3 gap-8">
        {paginatedPosts.map((post) => (
          <article class="card hover:shadow-lg transition-shadow">
            {post.data.heroImage && (
              <img
                src={post.data.heroImage}
                alt={post.data.title}
                class="w-full h-48 object-cover rounded-t-lg -mt-6 -mx-6 mb-4"
              />
            )}
            <div class="flex items-center gap-2 mb-3 text-sm">
              <span class="px-2 py-1 bg-accent/10 text-accent rounded text-xs font-medium">
                {post.data.category}
              </span>
              <time datetime={post.data.pubDate.toISOString()} class="text-text-secondary">
                {formatDate(post.data.pubDate)}
              </time>
            </div>
            <h3 class="text-xl font-bold mb-2">
              <a href={`/blog/${post.slug}`} class="hover:text-accent transition-colors">
                {post.data.title}
              </a>
            </h3>
            <p class="text-text-secondary mb-4 line-clamp-3">
              {post.data.description}
            </p>
            <div class="flex items-center justify-between text-sm text-text-secondary pt-4 border-t border-border">
              <span>{post.data.author}</span>
              <span>{calculateReadingTime(post.body)} min read</span>
            </div>
            {post.data.tags.length > 0 && (
              <div class="flex flex-wrap gap-2 mt-4">
                {post.data.tags.slice(0, 3).map(tag => (
                  <span class="text-xs px-2 py-1 bg-bg-secondary rounded">
                    #{tag}
                  </span>
                ))}
              </div>
            )}
          </article>
        ))}
      </div>
    </section>

    <!-- Pagination -->
    {totalPages > 1 && (
      <nav class="mt-12 flex justify-center gap-2">
        {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
          <a
            href={page === 1 ? '/blog' : `/blog/page/${page}`}
            class:list={[
              'px-4 py-2 rounded-lg transition-colors',
              page === currentPage
                ? 'bg-accent text-white'
                : 'bg-bg-secondary hover:bg-border'
            ]}
          >
            {page}
          </a>
        ))}
      </nav>
    )}

    <!-- No Posts Message -->
    {paginatedPosts.length === 0 && (
      <div class="text-center py-16">
        <p class="text-xl text-text-secondary">No blog posts yet. Check back soon!</p>
      </div>
    )}
  </div>
</MainLayout>

<style>
  .line-clamp-3 {
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style>
EOF
```

---

### STEP 4: Create Dynamic Blog Post Page

```bash
cat > src/pages/blog/[...slug].astro << 'EOF'
---
import { getCollection, getEntry } from 'astro:content';
import MainLayout from '../../layouts/MainLayout.astro';

// Generate static paths for all blog posts
export async function getStaticPaths() {
  const posts = await getCollection('blog', ({ data }) => {
    if (import.meta.env.PROD) {
      return data.draft !== true;
    }
    return true;
  });

  return posts.map(post => ({
    params: { slug: post.slug },
    props: { post },
  }));
}

const { post } = Astro.props;
const { Content, headings } = await post.render();

// Format date
function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date);
}

// Calculate reading time
function calculateReadingTime(content: string): number {
  const wordsPerMinute = 200;
  const words = content.trim().split(/\s+/).length;
  return Math.ceil(words / wordsPerMinute);
}

// Get related posts
const allPosts = await getCollection('blog', ({ data }) =>
  import.meta.env.PROD ? data.draft !== true : true
);
const relatedPosts = allPosts
  .filter(p =>
    p.slug !== post.slug &&
    p.data.category === post.data.category
  )
  .sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf())
  .slice(0, 3);
---

<MainLayout
  title={post.data.title}
  description={post.data.description}
>
  <article class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <!-- Header -->
    <header class="mb-8">
      <!-- Category Badge -->
      <div class="mb-4">
        <a
          href={`/blog/category/${post.data.category}`}
          class="inline-block px-3 py-1 bg-accent/10 text-accent rounded-full text-sm font-medium hover:bg-accent/20 transition-colors"
        >
          {post.data.category}
        </a>
      </div>

      <!-- Title -->
      <h1 class="text-5xl font-bold mb-4">{post.data.title}</h1>

      <!-- Description -->
      <p class="text-xl text-text-secondary mb-6">
        {post.data.description}
      </p>

      <!-- Meta Information -->
      <div class="flex flex-wrap items-center gap-6 text-text-secondary text-sm">
        <div class="flex items-center gap-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
          </svg>
          <span>{post.data.author}</span>
        </div>

        <div class="flex items-center gap-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
          </svg>
          <time datetime={post.data.pubDate.toISOString()}>
            {formatDate(post.data.pubDate)}
          </time>
        </div>

        <div class="flex items-center gap-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <span>{calculateReadingTime(post.body)} min read</span>
        </div>
      </div>

      <!-- Hero Image -->
      {post.data.heroImage && (
        <img
          src={post.data.heroImage}
          alt={post.data.title}
          class="w-full h-96 object-cover rounded-lg mt-8"
        />
      )}
    </header>

    <!-- Table of Contents -->
    {headings.length > 0 && (
      <aside class="mb-8 p-6 bg-bg-secondary rounded-lg border border-border">
        <h2 class="text-xl font-bold mb-4">Table of Contents</h2>
        <nav>
          <ul class="space-y-2">
            {headings.map(heading => (
              <li
                style={`margin-left: ${(heading.depth - 1) * 1}rem`}
                class="text-text-secondary hover:text-accent transition-colors"
              >
                <a href={`#${heading.slug}`}>
                  {heading.text}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      </aside>
    )}

    <!-- Content -->
    <div class="prose prose-lg max-w-none">
      <Content />
    </div>

    <!-- Tags -->
    {post.data.tags.length > 0 && (
      <footer class="mt-12 pt-8 border-t border-border">
        <div class="flex flex-wrap gap-2">
          <span class="font-medium text-text-secondary">Tags:</span>
          {post.data.tags.map(tag => (
            <a
              href={`/blog/tag/${tag}`}
              class="px-3 py-1 bg-bg-secondary hover:bg-border rounded-full text-sm transition-colors"
            >
              #{tag}
            </a>
          ))}
        </div>
      </footer>
    )}
  </article>

  <!-- Related Posts -->
  {relatedPosts.length > 0 && (
    <section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 border-t border-border">
      <h2 class="text-3xl font-bold mb-8">Related Posts</h2>
      <div class="grid md:grid-cols-3 gap-8">
        {relatedPosts.map(relatedPost => (
          <article class="card">
            <a href={`/blog/${relatedPost.slug}`} class="block">
              <h3 class="text-xl font-bold mb-2 hover:text-accent transition-colors">
                {relatedPost.data.title}
              </h3>
              <p class="text-text-secondary mb-4 line-clamp-3">
                {relatedPost.data.description}
              </p>
              <time class="text-sm text-text-secondary">
                {formatDate(relatedPost.data.pubDate)}
              </time>
            </a>
          </article>
        ))}
      </div>
    </section>
  )}
</MainLayout>

<style>
  /* Prose styling for markdown content */
  .prose {
    @apply text-text-primary;
  }

  .prose h1 {
    @apply text-4xl font-bold mt-8 mb-4;
  }

  .prose h2 {
    @apply text-3xl font-bold mt-8 mb-4;
  }

  .prose h3 {
    @apply text-2xl font-bold mt-6 mb-3;
  }

  .prose p {
    @apply mb-4 leading-relaxed;
  }

  .prose a {
    @apply text-accent hover:underline;
  }

  .prose ul {
    @apply list-disc list-inside mb-4 space-y-2;
  }

  .prose ol {
    @apply list-decimal list-inside mb-4 space-y-2;
  }

  .prose code {
    @apply bg-bg-secondary px-2 py-1 rounded text-sm font-mono;
  }

  .prose pre {
    @apply bg-bg-secondary p-4 rounded-lg overflow-x-auto mb-4;
  }

  .prose pre code {
    @apply bg-transparent p-0;
  }

  .prose blockquote {
    @apply border-l-4 border-accent pl-4 italic my-4;
  }

  .prose table {
    @apply w-full border-collapse mb-4;
  }

  .prose th {
    @apply bg-bg-secondary font-bold p-2 text-left border border-border;
  }

  .prose td {
    @apply p-2 border border-border;
  }

  .line-clamp-3 {
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style>
EOF
```

---

### STEP 5: Create Category Filter Page

```bash
mkdir -p src/pages/blog/category

cat > src/pages/blog/category/[category].astro << 'EOF'
---
import { getCollection } from 'astro:content';
import MainLayout from '../../../layouts/MainLayout.astro';

// Get all unique categories
export async function getStaticPaths() {
  const allPosts = await getCollection('blog', ({ data }) =>
    import.meta.env.PROD ? data.draft !== true : true
  );

  const categories = [...new Set(allPosts.map(post => post.data.category))];

  return categories.map(category => {
    const posts = allPosts.filter(post => post.data.category === category);
    return {
      params: { category },
      props: { posts, category },
    };
  });
}

const { posts, category } = Astro.props;

// Sort by date
const sortedPosts = posts.sort((a, b) =>
  b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
);

// Format date
function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date);
}

// Capitalize category
const categoryTitle = category.charAt(0).toUpperCase() + category.slice(1);
---

<MainLayout
  title={`${categoryTitle} Posts`}
  description={`Browse all posts in the ${categoryTitle} category`}
>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <!-- Header -->
    <div class="mb-12">
      <div class="flex items-center gap-4 mb-4">
        <a href="/blog" class="text-text-secondary hover:text-accent transition-colors">
          ← Back to Blog
        </a>
      </div>
      <h1 class="text-5xl font-bold mb-4">
        <span class="text-accent">{categoryTitle}</span> Posts
      </h1>
      <p class="text-xl text-text-secondary">
        {sortedPosts.length} {sortedPosts.length === 1 ? 'post' : 'posts'} in this category
      </p>
    </div>

    <!-- Posts Grid -->
    <div class="grid md:grid-cols-3 gap-8">
      {sortedPosts.map(post => (
        <article class="card hover:shadow-lg transition-shadow">
          {post.data.heroImage && (
            <img
              src={post.data.heroImage}
              alt={post.data.title}
              class="w-full h-48 object-cover rounded-t-lg -mt-6 -mx-6 mb-4"
            />
          )}
          <time datetime={post.data.pubDate.toISOString()} class="text-sm text-text-secondary">
            {formatDate(post.data.pubDate)}
          </time>
          <h2 class="text-xl font-bold mt-2 mb-3">
            <a href={`/blog/${post.slug}`} class="hover:text-accent transition-colors">
              {post.data.title}
            </a>
          </h2>
          <p class="text-text-secondary mb-4 line-clamp-3">
            {post.data.description}
          </p>
          <div class="flex items-center justify-between text-sm text-text-secondary pt-4 border-t border-border">
            <span>{post.data.author}</span>
            <span class="text-accent">Read more →</span>
          </div>
        </article>
      ))}
    </div>

    <!-- Empty State -->
    {sortedPosts.length === 0 && (
      <div class="text-center py-16">
        <p class="text-xl text-text-secondary">No posts in this category yet.</p>
        <a href="/blog" class="btn-primary mt-6">Browse All Posts</a>
      </div>
    )}
  </div>
</MainLayout>

<style>
  .line-clamp-3 {
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style>
EOF
```

---

### STEP 6: Update Navigation to Include Blog

```bash
# Update constants file to include blog link
cat > src/lib/constants.ts << 'EOF'
// Site Configuration
export const SITE_CONFIG = {
  name: 'Astro Blog',
  description: 'A modern blog built with Astro 5.0',
  url: 'https://yourdomain.com',
  author: 'Your Name',
  email: 'your.email@example.com',
  postsPerPage: 6,
} as const;

// Navigation Links
export const NAV_LINKS = [
  { href: '/', label: 'Home' },
  { href: '/blog', label: 'Blog' },
  { href: '/about', label: 'About' },
  { href: '/contact', label: 'Contact' },
] as const;

// Social Links
export const SOCIAL_LINKS = {
  github: 'https://github.com/yourusername',
  twitter: 'https://twitter.com/yourusername',
  linkedin: 'https://linkedin.com/in/yourusername',
} as const;

// SEO Defaults
export const SEO_DEFAULTS = {
  title: SITE_CONFIG.name,
  description: SITE_CONFIG.description,
  ogImage: '/og-image.jpg',
  twitterCard: 'summary_large_image',
} as const;

// Blog Categories
export const BLOG_CATEGORIES = [
  'technology',
  'tutorial',
  'news',
  'opinion',
  'showcase',
] as const;

export type BlogCategory = typeof BLOG_CATEGORIES[number];
EOF
```

---

### STEP 7: Run and Test

```bash
# Start development server
npm run dev

# Visit these URLs to test:
echo "
Test URLs:
- Blog listing: http://localhost:4321/blog
- Individual post: http://localhost:4321/blog/welcome-to-astro
- Category filter: http://localhost:4321/blog/category/tutorial
- Another post: http://localhost:4321/blog/content-layer-api
"
```

---

## ✅ 3. VERIFY (Testing)

### Checklist

#### Content Collection Setup ✓
- [ ] `src/content/config.ts` created with Zod schema
- [ ] Schema validates all required fields
- [ ] Optional fields have defaults
- [ ] Enum validation for category
- [ ] Array validation for tags

#### Sample Content ✓
- [ ] Created `src/content/blog/` directory
- [ ] Added at least 3 sample blog posts
- [ ] Each post has valid frontmatter
- [ ] Frontmatter passes schema validation
- [ ] Posts have varying categories and tags

#### Blog Listing Page ✓
- [ ] `/blog` page loads successfully
- [ ] All posts displayed in grid
- [ ] Featured posts section shows (if any featured posts)
- [ ] Post cards show title, description, date, author
- [ ] Reading time calculated correctly
- [ ] Category badges display
- [ ] Pagination setup (even if only 1 page)

#### Individual Blog Posts ✓
- [ ] Dynamic route `/blog/[...slug]` works
- [ ] Post title and description render
- [ ] Hero image displays (if present)
- [ ] Meta information shows (author, date, reading time)
- [ ] Table of contents generates from headings
- [ ] Markdown content renders correctly
- [ ] Code blocks have syntax highlighting
- [ ] Tags display at bottom
- [ ] Related posts section shows (if related posts exist)

#### Category Pages ✓
- [ ] Category routes work (`/blog/category/tutorial`)
- [ ] Filtered posts show correctly
- [ ] Category count accurate
- [ ] Back to blog link works
- [ ] Empty state shows when no posts

#### TypeScript & Types ✓
- [ ] No TypeScript errors
- [ ] Autocomplete works for post.data fields
- [ ] Invalid frontmatter fails build
- [ ] Type inference from schema works

---

### Expected Results

**Blog Listing (`/blog`):**
```
✅ Shows all posts in grid layout
✅ Featured posts prominently displayed
✅ Each card shows:
   - Category badge
   - Date
   - Title
   - Description
   - Author
   - Reading time
   - Tags (first 3)
✅ Pagination controls (if > 6 posts)
```

**Individual Post (`/blog/welcome-to-astro`):**
```
✅ Full post layout with:
   - Category badge (clickable)
   - Title
   - Description
   - Meta info (author, date, reading time)
   - Hero image (if present)
   - Table of contents (if headings present)
   - Rendered markdown content
   - Tags (all, clickable)
   - Related posts (3 max)
```

**Category Page (`/blog/category/tutorial`):**
```
✅ Filtered posts for that category
✅ Category title
✅ Post count
✅ Back to blog link
✅ Same post card layout as listing
```

---

### Common Issues & Solutions

**Issue 1: Schema validation errors**
```bash
# Error: Invalid frontmatter
# Solution: Check src/content/config.ts schema matches frontmatter

# Example error:
# Error: Expected date, received string

# Fix: Use date format in frontmatter
# Correct:
pubDate: 2025-01-15

# Incorrect:
pubDate: "January 15, 2025"
```

**Issue 2: Posts not appearing**
```bash
# Check if posts are marked as draft
# In production, drafts are filtered out

# View drafts in dev:
npm run dev

# Hide drafts in dev:
# Add filter: data.draft !== true
```

**Issue 3: Missing images**
```bash
# Ensure image paths are correct
# Place images in public/ directory

# Correct path in frontmatter:
heroImage: /images/welcome.jpg

# File location:
public/images/welcome.jpg
```

**Issue 4: Headings not showing in TOC**
```bash
# Ensure markdown uses proper heading syntax:
# Correct:
## Heading 2

# Incorrect:
**Heading 2** (this is bold, not a heading)
```

**Issue 5: Reading time incorrect**
```bash
# Reading time uses word count
# Adjust wordsPerMinute constant if needed

function calculateReadingTime(content: string): number {
  const wordsPerMinute = 200; // Adjust this
  const words = content.trim().split(/\s+/).length;
  return Math.ceil(words / wordsPerMinute);
}
```

---

### Testing Commands

```bash
# Type check
npx astro check

# Build for production
npm run build

# Preview production build
npm run preview

# Check content collection
# Should show "Content collections built successfully"
npm run build 2>&1 | grep -i "content"

# List all generated pages
ls dist/**/*.html

# Verify static paths generated
ls dist/blog/**/*.html
```

---

## 🎯 What You Built

### Content Infrastructure
- ✅ **Content Collection** - Type-safe blog posts with Zod
- ✅ **3 Sample Posts** - Real content to test with
- ✅ **Validation Schema** - Automatic frontmatter validation
- ✅ **Type Inference** - Full TypeScript autocomplete

### Pages
- ✅ **Blog Listing** - Grid layout with pagination
- ✅ **Individual Posts** - Full post rendering with TOC
- ✅ **Category Pages** - Filtered post lists
- ✅ **Related Posts** - Content recommendations

### Features
- ✅ **Reading Time** - Automatic calculation
- ✅ **Table of Contents** - Auto-generated from headings
- ✅ **Date Formatting** - Locale-aware dates
- ✅ **Tag System** - Clickable tags
- ✅ **Category System** - Filterable categories
- ✅ **Draft Support** - Hide unpublished posts in production

---

## 🚀 Next Steps

In **Lesson 3**, you'll add:
- MDX integration for enhanced content
- Custom components (callouts, code blocks)
- Syntax highlighting with Shiki
- Image optimization
- YouTube/Twitter embeds
- Copy-to-clipboard for code blocks

**Continue to:** [LESSON-3-MDX.md](./LESSON-3-MDX.md)

---

## 📚 Key Concepts Review

### Content Layer API
- **Collections** - Group related content together
- **Schemas** - Validate and type content
- **Queries** - `getCollection()` and `getEntry()`
- **Rendering** - `await post.render()` for content
- **Static Paths** - Pre-render all posts at build time

### Zod Validation
- **Runtime validation** - Catches errors early
- **Type inference** - TypeScript types from schemas
- **Defaults** - Auto-fill missing values
- **Enums** - Restrict to specific values
- **Arrays** - Validate list fields

### Performance
- **Static Generation** - All pages pre-rendered
- **No JavaScript** - Pure HTML for content
- **Fast Builds** - Content processed once
- **Type Safety** - No runtime type errors

---

**Congratulations!** 🎉 You've mastered the Content Layer API and built a fully functional blog with type-safe content management.

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 3-4 hours
