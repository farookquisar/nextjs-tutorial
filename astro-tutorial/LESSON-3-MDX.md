# Astro 5.0 Tutorial - Lesson 3: MDX & Rich Content

**Prerequisites:** Complete Lesson 2 (Content Layer API & Collections)

---

## ✅ 1. DESC (Description)

### What You'll Learn

In this lesson, you'll enhance your blog with MDX to create rich, interactive content with custom components.

**Core Concepts:**
- ✅ MDX integration in Astro
- ✅ Custom MDX components
- ✅ Syntax highlighting with Shiki
- ✅ Copy-to-clipboard for code blocks
- ✅ Image optimization with Astro Image
- ✅ Custom callout/alert components
- ✅ YouTube and Twitter embeds
- ✅ Related posts widget
- ✅ Remark and Rehype plugins

**What You'll Build:**
- MDX support for blog posts
- Custom callout/alert components (info, warning, error, success)
- Enhanced code blocks with copy button
- Syntax highlighting for 50+ languages
- Responsive optimized images
- Video and social media embeds
- Reading progress bar
- Share buttons component

---

### MDX vs Markdown

**Markdown (.md):**
```markdown
# Heading
This is **bold** text.
```

**MDX (.mdx):**
```mdx
import { Callout } from '../components/Callout.astro';

# Heading
This is **bold** text.

<Callout type="info">
  You can use components in MDX!
</Callout>
```

**Key Differences:**

| Feature | Markdown | MDX |
|---------|----------|-----|
| Import components | ❌ | ✅ |
| Use JSX | ❌ | ✅ |
| JavaScript expressions | ❌ | ✅ |
| Props | ❌ | ✅ |
| File size | Smaller | Slightly larger |
| Processing | Faster | Slightly slower |

**When to use MDX:**
- ✅ Need custom interactive components
- ✅ Want to embed media (YouTube, Twitter)
- ✅ Need advanced layouts
- ✅ Want to pass props to content

**When to use Markdown:**
- ✅ Simple blog posts
- ✅ Maximum performance
- ✅ No custom components needed

---

## ✅ 2. CODE (Implementation)

### STEP 1: Install MDX Integration

```bash
# Install MDX integration
npx astro add mdx

# This command will:
# 1. Install @astrojs/mdx
# 2. Update astro.config.mjs
# 3. Add MDX support to content collections

# Press Enter to confirm all prompts
```

**Verify installation:**

```bash
cat astro.config.mjs
```

Should show:
```javascript
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';

export default defineConfig({
  integrations: [tailwind(), mdx()],
});
```

---

### STEP 2: Configure Syntax Highlighting

```bash
cat > astro.config.mjs << 'EOF'
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';

export default defineConfig({
  integrations: [tailwind(), mdx()],

  markdown: {
    // Syntax highlighting with Shiki
    syntaxHighlight: 'shiki',
    shikiConfig: {
      // Choose from Shiki's built-in themes:
      // https://shiki.style/themes
      theme: 'github-dark',
      themes: {
        light: 'github-light',
        dark: 'github-dark',
      },
      // Add custom languages
      langs: [],
      // Enable word wrap to prevent horizontal scrolling
      wrap: true,
    },
  },
});
EOF
```

<details>
<summary>📖 <strong>Shiki Themes</strong></summary>

**Popular Themes:**
- `github-dark` / `github-light` - GitHub style
- `dracula` - Popular dark theme
- `nord` - Cool blue theme
- `one-dark-pro` - VS Code default dark
- `material-theme-palenight` - Material design

**Dual Theme Support:**
```javascript
shikiConfig: {
  themes: {
    light: 'github-light',
    dark: 'github-dark',
  },
}
```

**Custom Theme:**
```javascript
import myTheme from './my-theme.json';

shikiConfig: {
  theme: myTheme,
}
```

**Supported Languages:**
Shiki supports 100+ languages including:
- JavaScript, TypeScript
- Python, Ruby, PHP
- Go, Rust, C++
- HTML, CSS, SCSS
- JSON, YAML, TOML
- SQL, GraphQL
- Shell, Bash
</details>

---

### STEP 3: Create Custom Callout Component

```bash
mkdir -p src/components/mdx

cat > src/components/mdx/Callout.astro << 'EOF'
---
export interface Props {
  type?: 'info' | 'warning' | 'error' | 'success';
  title?: string;
}

const { type = 'info', title } = Astro.props;

const types = {
  info: {
    icon: 'ℹ️',
    bgColor: 'bg-blue-50',
    borderColor: 'border-blue-500',
    textColor: 'text-blue-900',
    titleColor: 'text-blue-700',
  },
  warning: {
    icon: '⚠️',
    bgColor: 'bg-yellow-50',
    borderColor: 'border-yellow-500',
    textColor: 'text-yellow-900',
    titleColor: 'text-yellow-700',
  },
  error: {
    icon: '❌',
    bgColor: 'bg-red-50',
    borderColor: 'border-red-500',
    textColor: 'text-red-900',
    titleColor: 'text-red-700',
  },
  success: {
    icon: '✅',
    bgColor: 'bg-green-50',
    borderColor: 'border-green-500',
    textColor: 'text-green-900',
    titleColor: 'text-green-700',
  },
};

const config = types[type];
---

<div
  class:list={[
    'callout',
    'my-6 p-4 rounded-lg border-l-4',
    config.bgColor,
    config.borderColor,
    config.textColor,
  ]}
>
  {title && (
    <div class:list={['font-bold mb-2 flex items-center gap-2', config.titleColor]}>
      <span class="text-xl">{config.icon}</span>
      <span>{title}</span>
    </div>
  )}
  <div class="callout-content">
    <slot />
  </div>
</div>

<style>
  .callout-content :global(p:last-child) {
    margin-bottom: 0;
  }

  .callout-content :global(p) {
    margin-top: 0.5rem;
  }

  /* Dark mode support */
  [data-theme='dark'] .callout {
    filter: brightness(0.8);
  }
</style>
EOF
```

---

### STEP 4: Create Enhanced Code Block Component

```bash
cat > src/components/mdx/CodeBlock.astro << 'EOF'
---
export interface Props {
  title?: string;
  lang?: string;
  showLineNumbers?: boolean;
}

const { title, lang, showLineNumbers = true } = Astro.props;
---

<div class="code-block my-6">
  {title && (
    <div class="code-header bg-bg-secondary px-4 py-2 rounded-t-lg border border-border flex items-center justify-between">
      <span class="text-sm font-mono text-text-secondary">{title}</span>
      <button
        class="copy-button text-xs px-3 py-1 bg-accent/10 hover:bg-accent/20 text-accent rounded transition-colors"
        data-copy
      >
        Copy
      </button>
    </div>
  )}
  <div class:list={[
    'relative',
    showLineNumbers && 'line-numbers',
  ]}>
    <slot />
    {!title && (
      <button
        class="copy-button absolute top-2 right-2 text-xs px-3 py-1 bg-bg-secondary/80 hover:bg-bg-secondary border border-border rounded transition-colors"
        data-copy
      >
        Copy
      </button>
    )}
  </div>
</div>

<script>
  // Copy to clipboard functionality
  document.addEventListener('astro:page-load', () => {
    const copyButtons = document.querySelectorAll('[data-copy]');

    copyButtons.forEach(button => {
      button.addEventListener('click', async () => {
        // Find the code element
        const codeBlock = button.closest('.code-block');
        const codeElement = codeBlock?.querySelector('code');

        if (codeElement) {
          const code = codeElement.textContent || '';

          try {
            await navigator.clipboard.writeText(code);

            // Show feedback
            const originalText = button.textContent;
            button.textContent = 'Copied!';
            button.classList.add('copied');

            setTimeout(() => {
              button.textContent = originalText;
              button.classList.remove('copied');
            }, 2000);
          } catch (err) {
            console.error('Failed to copy:', err);
          }
        }
      });
    });
  });
</script>

<style>
  .code-block pre {
    @apply rounded-lg p-4 overflow-x-auto;
    margin: 0 !important;
  }

  .code-header + div pre {
    @apply rounded-t-none;
  }

  .copy-button.copied {
    @apply bg-green-500/20 text-green-600;
  }

  /* Line numbers (optional, requires rehype-prism-plus or similar) */
  .line-numbers pre {
    counter-reset: line;
  }

  .line-numbers code {
    counter-increment: line;
  }

  .line-numbers code::before {
    content: counter(line);
    display: inline-block;
    width: 2rem;
    margin-right: 1rem;
    text-align: right;
    color: rgba(255, 255, 255, 0.3);
  }
</style>
EOF
```

---

### STEP 5: Create YouTube Embed Component

```bash
cat > src/components/mdx/YouTubeEmbed.astro << 'EOF'
---
export interface Props {
  id: string;
  title?: string;
}

const { id, title = 'YouTube video' } = Astro.props;
---

<div class="youtube-embed my-8">
  <div class="relative w-full" style="padding-bottom: 56.25%;">
    <iframe
      class="absolute top-0 left-0 w-full h-full rounded-lg"
      src={`https://www.youtube-nocookie.com/embed/${id}`}
      title={title}
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen
    ></iframe>
  </div>
  {title && (
    <p class="text-center text-sm text-text-secondary mt-2 italic">
      {title}
    </p>
  )}
</div>

<style>
  .youtube-embed {
    max-width: 100%;
  }

  /* Responsive aspect ratio */
  @media (max-width: 640px) {
    .youtube-embed iframe {
      border-radius: 0.5rem;
    }
  }
</style>
EOF
```

---

### STEP 6: Create Twitter/X Embed Component

```bash
cat > src/components/mdx/TweetEmbed.astro << 'EOF'
---
export interface Props {
  id: string;
}

const { id } = Astro.props;
const tweetUrl = `https://twitter.com/i/status/${id}`;
---

<div class="tweet-embed my-8 flex justify-center">
  <blockquote class="twitter-tweet" data-theme="dark">
    <a href={tweetUrl}>Loading tweet...</a>
  </blockquote>
</div>

<script is:inline async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<style>
  .tweet-embed {
    max-width: 550px;
    margin-left: auto;
    margin-right: auto;
  }
</style>
EOF
```

---

### STEP 7: Create Reading Progress Bar Component

```bash
cat > src/components/mdx/ReadingProgress.astro << 'EOF'
---
// No props needed - reads scroll position
---

<div id="reading-progress" class="fixed top-0 left-0 w-full h-1 z-50 bg-bg-secondary">
  <div id="progress-bar" class="h-full bg-accent transition-all duration-100"></div>
</div>

<script>
  document.addEventListener('astro:page-load', () => {
    const progressBar = document.getElementById('progress-bar');

    function updateProgress() {
      const windowHeight = window.innerHeight;
      const documentHeight = document.documentElement.scrollHeight;
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

      const progress = (scrollTop / (documentHeight - windowHeight)) * 100;

      if (progressBar) {
        progressBar.style.width = `${Math.min(progress, 100)}%`;
      }
    }

    // Update on scroll
    window.addEventListener('scroll', updateProgress);

    // Initial update
    updateProgress();
  });
</script>
EOF
```

---

### STEP 8: Create Share Buttons Component

```bash
cat > src/components/mdx/ShareButtons.astro << 'EOF'
---
export interface Props {
  title: string;
  url: string;
}

const { title, url } = Astro.props;

// Encode for URLs
const encodedTitle = encodeURIComponent(title);
const encodedUrl = encodeURIComponent(url);

// Share URLs
const twitterShare = `https://twitter.com/intent/tweet?text=${encodedTitle}&url=${encodedUrl}`;
const facebookShare = `https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`;
const linkedinShare = `https://www.linkedin.com/sharing/share-offsite/?url=${encodedUrl}`;
const emailShare = `mailto:?subject=${encodedTitle}&body=Check out this article: ${encodedUrl}`;
---

<div class="share-buttons my-8 p-6 bg-bg-secondary rounded-lg border border-border">
  <h3 class="text-lg font-bold mb-4">Share this post</h3>
  <div class="flex flex-wrap gap-3">
    <!-- Twitter -->
    <a
      href={twitterShare}
      target="_blank"
      rel="noopener noreferrer"
      class="share-button"
      aria-label="Share on Twitter"
    >
      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
      </svg>
      Twitter
    </a>

    <!-- Facebook -->
    <a
      href={facebookShare}
      target="_blank"
      rel="noopener noreferrer"
      class="share-button"
      aria-label="Share on Facebook"
    >
      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
      </svg>
      Facebook
    </a>

    <!-- LinkedIn -->
    <a
      href={linkedinShare}
      target="_blank"
      rel="noopener noreferrer"
      class="share-button"
      aria-label="Share on LinkedIn"
    >
      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
      </svg>
      LinkedIn
    </a>

    <!-- Email -->
    <a
      href={emailShare}
      class="share-button"
      aria-label="Share via Email"
    >
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
      </svg>
      Email
    </a>

    <!-- Copy Link -->
    <button
      id="copy-link"
      class="share-button"
      aria-label="Copy link"
      data-url={url}
    >
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
      </svg>
      Copy Link
    </button>
  </div>
</div>

<script>
  document.addEventListener('astro:page-load', () => {
    const copyButton = document.getElementById('copy-link');

    copyButton?.addEventListener('click', async () => {
      const url = copyButton.getAttribute('data-url');

      if (url) {
        try {
          await navigator.clipboard.writeText(url);

          // Show feedback
          const originalHTML = copyButton.innerHTML;
          copyButton.innerHTML = `
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            Copied!
          `;

          setTimeout(() => {
            copyButton.innerHTML = originalHTML;
          }, 2000);
        } catch (err) {
          console.error('Failed to copy:', err);
        }
      }
    });
  });
</script>

<style>
  .share-button {
    @apply flex items-center gap-2 px-4 py-2 bg-bg-primary border border-border rounded-lg;
    @apply hover:bg-accent hover:text-white hover:border-accent transition-colors;
    @apply text-sm font-medium;
  }
</style>
EOF
```

---

### STEP 9: Update Content Config for MDX

```bash
cat > src/content/config.ts << 'EOF'
import { defineCollection, z } from 'astro:content';

// Blog collection schema (supports both .md and .mdx)
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

    // MDX specific (optional)
    showTOC: z.boolean().default(true),
    showReadingProgress: z.boolean().default(true),
  }),
});

// Export collections
export const collections = {
  blog: blogCollection,
};
EOF
```

---

### STEP 10: Create Sample MDX Blog Post

```bash
cat > src/content/blog/mdx-features-demo.mdx << 'EOF'
---
title: "MDX Features Demo - Interactive Components"
description: "Explore the power of MDX with interactive components, custom callouts, code blocks, and embedded media in your Astro blog posts."
pubDate: 2025-01-30
author: "MDX Team"
category: "tutorial"
tags: ["mdx", "components", "astro"]
featured: true
showTOC: true
showReadingProgress: true
---

import { Callout } from '../../components/mdx/Callout.astro';
import { CodeBlock } from '../../components/mdx/CodeBlock.astro';
import { YouTubeEmbed } from '../../components/mdx/YouTubeEmbed.astro';
import { ShareButtons } from '../../components/mdx/ShareButtons.astro';

# MDX Features Demo

This post demonstrates the power of **MDX** in Astro. MDX allows you to use JSX components directly in your Markdown content!

## Custom Callouts

MDX enables custom alert/callout components:

<Callout type="info" title="Information">
  This is an informational callout. Great for tips and notes!
</Callout>

<Callout type="success" title="Success">
  This indicates something positive or a successful action.
</Callout>

<Callout type="warning" title="Warning">
  Use this to warn users about potential issues or important information.
</Callout>

<Callout type="error" title="Error">
  This highlights errors or critical information that needs attention.
</Callout>

## Enhanced Code Blocks

### JavaScript Example

<CodeBlock title="example.js" lang="javascript">
```javascript
// Calculate Fibonacci numbers
function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

// Memoized version (much faster!)
function fibonacciMemo(n, memo = {}) {
  if (n in memo) return memo[n];
  if (n <= 1) return n;

  memo[n] = fibonacciMemo(n - 1, memo) + fibonacciMemo(n - 2, memo);
  return memo[n];
}

console.log(fibonacciMemo(10)); // 55
```
</CodeBlock>

### TypeScript Example

<CodeBlock title="types.ts" lang="typescript">
```typescript
interface User {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'user';
}

type UserWithoutEmail = Omit<User, 'email'>;

const users: User[] = [
  { id: 1, name: 'Alice', email: 'alice@example.com', role: 'admin' },
  { id: 2, name: 'Bob', email: 'bob@example.com', role: 'user' },
];

function filterByRole(users: User[], role: User['role']): User[] {
  return users.filter(user => user.role === role);
}
```
</CodeBlock>

## Embedded Media

### YouTube Videos

<YouTubeEmbed
  id="dsTXcSeAZq8"
  title="Astro in 100 Seconds"
/>

## Benefits of MDX

### 1. **Component Reusability**
Create once, use everywhere. Your custom components work across all posts.

### 2. **Type Safety**
Since you're using TypeScript, your components are fully typed.

### 3. **Flexibility**
Mix Markdown's simplicity with React's power.

<Callout type="success" title="Best Practice">
  Use MDX for posts that need interactivity. Use regular Markdown for simple content to keep builds fast!
</Callout>

## Interactive Elements

You can pass dynamic data to components:

```astro
<ShareButtons
  title={post.data.title}
  url={Astro.url.href}
/>
```

## Code Syntax Highlighting

MDX automatically highlights code with Shiki:

```python
# Python example
def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)

print(quicksort([3, 6, 8, 10, 1, 2, 1]))
```

```rust
// Rust example
fn main() {
    let numbers = vec![1, 2, 3, 4, 5];

    let sum: i32 = numbers.iter().sum();
    let product: i32 = numbers.iter().product();

    println!("Sum: {}", sum);
    println!("Product: {}", product);
}
```

## Performance Considerations

<Callout type="warning" title="Build Time">
  MDX files take slightly longer to process than Markdown. Use them strategically for posts that benefit from components.
</Callout>

**Tips for optimal performance:**

1. Use regular Markdown for simple posts
2. Reserve MDX for interactive content
3. Lazy-load heavy components
4. Optimize images with Astro Image

## Share This Post

<ShareButtons
  title="MDX Features Demo - Interactive Components"
  url="https://yourdomain.com/blog/mdx-features-demo"
/>

## Conclusion

MDX combines the best of both worlds:
- ✅ Markdown's simplicity
- ✅ Components' power
- ✅ Type safety with TypeScript
- ✅ Reusable across projects

Try MDX in your next Astro project!
EOF
```

---

### STEP 11: Update Blog Post Layout with New Components

```bash
# Update the blog post page to include reading progress
cat > src/pages/blog/[...slug].astro << 'EOF'
---
import { getCollection, getEntry } from 'astro:content';
import MainLayout from '../../layouts/MainLayout.astro';
import ReadingProgress from '../../components/mdx/ReadingProgress.astro';
import ShareButtons from '../../components/mdx/ShareButtons.astro';

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

function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date);
}

function calculateReadingTime(content: string): number {
  const wordsPerMinute = 200;
  const words = content.trim().split(/\s+/).length;
  return Math.ceil(words / wordsPerMinute);
}

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

const fullUrl = new URL(Astro.url.pathname, Astro.site).href;
---

<MainLayout
  title={post.data.title}
  description={post.data.description}
>
  <!-- Reading Progress Bar -->
  {post.data.showReadingProgress && <ReadingProgress />}

  <article class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <header class="mb-8">
      <div class="mb-4">
        <a
          href={`/blog/category/${post.data.category}`}
          class="inline-block px-3 py-1 bg-accent/10 text-accent rounded-full text-sm font-medium hover:bg-accent/20 transition-colors"
        >
          {post.data.category}
        </a>
      </div>

      <h1 class="text-5xl font-bold mb-4">{post.data.title}</h1>

      <p class="text-xl text-text-secondary mb-6">
        {post.data.description}
      </p>

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

      {post.data.heroImage && (
        <img
          src={post.data.heroImage}
          alt={post.data.title}
          class="w-full h-96 object-cover rounded-lg mt-8"
        />
      )}
    </header>

    {post.data.showTOC && headings.length > 0 && (
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

    <div class="prose prose-lg max-w-none">
      <Content />
    </div>

    <!-- Share Buttons -->
    <ShareButtons title={post.data.title} url={fullUrl} />

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

### STEP 12: Run and Test MDX Features

```bash
# Start development server
npm run dev

# Test URLs:
echo "
MDX Test URLs:
- MDX Demo Post: http://localhost:4321/blog/mdx-features-demo
- Copy code buttons (click to test)
- Share buttons (click to test)
- Reading progress bar (scroll to test)
- Callout components (view different types)
"
```

---

## ✅ 3. VERIFY (Testing)

### Checklist

#### MDX Integration ✓
- [ ] MDX integration installed successfully
- [ ] `astro.config.mjs` includes MDX
- [ ] Syntax highlighting configured with Shiki
- [ ] Both `.md` and `.mdx` files work

#### Custom Components ✓
- [ ] Callout component renders all types (info, warning, error, success)
- [ ] CodeBlock component displays correctly
- [ ] Copy button works on code blocks
- [ ] YouTube embeds load
- [ ] Share buttons display
- [ ] Reading progress bar moves on scroll

#### MDX Features ✓
- [ ] Can import components in MDX files
- [ ] Props pass to components correctly
- [ ] JSX expressions work in MDX
- [ ] Markdown syntax still works
- [ ] Frontmatter validated correctly

#### Syntax Highlighting ✓
- [ ] Code blocks have color syntax
- [ ] Multiple languages supported
- [ ] Dark theme applied
- [ ] Line highlighting works (if enabled)

#### Interactive Features ✓
- [ ] Copy button copies code to clipboard
- [ ] Shows "Copied!" feedback
- [ ] Share buttons open correct URLs
- [ ] Copy link button works
- [ ] Progress bar updates on scroll

---

### Expected Results

**MDX Post Rendering:**
```
✅ All imports resolve correctly
✅ Custom components render
✅ Markdown syntax works
✅ Callouts display with correct colors
✅ Code blocks have syntax highlighting
✅ Copy buttons functional
✅ Embedded media loads
✅ Share buttons work
✅ Progress bar animates
```

**Component Interaction:**
```
✅ Click copy button → code copied
✅ Click share button → opens share dialog
✅ Scroll page → progress bar updates
✅ Hover buttons → visual feedback
```

---

### Common Issues & Solutions

**Issue 1: MDX components not rendering**
```bash
# Ensure imports use correct path
# Correct:
import { Callout } from '../../components/mdx/Callout.astro';

# Incorrect:
import Callout from '../../components/mdx/Callout.astro';
```

**Issue 2: Syntax highlighting not working**
```bash
# Check astro.config.mjs has:
markdown: {
  syntaxHighlight: 'shiki',
}

# Restart dev server after config changes
npm run dev
```

**Issue 3: Copy button not working**
```bash
# Ensure script uses astro:page-load event
document.addEventListener('astro:page-load', () => {
  // Setup code here
});
```

**Issue 4: Props not passing to components**
```bash
# In MDX, use JSX syntax for props:
# Correct:
<Callout type="info" title="Hello" />

# Incorrect:
<Callout type=info title=Hello />
```

**Issue 5: YouTube embeds not showing**
```bash
# Check YouTube video ID is correct
# URL: https://youtube.com/watch?v=VIDEO_ID_HERE
# Use: VIDEO_ID_HERE

<YouTubeEmbed id="dsTXcSeAZq8" />
```

---

### Testing Commands

```bash
# Type check
npx astro check

# Build (tests MDX processing)
npm run build

# Check for MDX errors
npm run build 2>&1 | grep -i "mdx"

# Preview production build
npm run preview
```

---

## 🎯 What You Built

### Custom Components (7)
- ✅ **Callout** - 4 types of alerts
- ✅ **CodeBlock** - Enhanced code with copy button
- ✅ **YouTubeEmbed** - Responsive video embeds
- ✅ **TweetEmbed** - Twitter/X embeds
- ✅ **ReadingProgress** - Scroll progress indicator
- ✅ **ShareButtons** - Social sharing
- ✅ **CopyButton** - Clipboard functionality

### Features
- ✅ **MDX Support** - Import components in content
- ✅ **Syntax Highlighting** - 100+ languages with Shiki
- ✅ **Interactive Code** - Copy to clipboard
- ✅ **Media Embeds** - YouTube, Twitter
- ✅ **Social Sharing** - Twitter, Facebook, LinkedIn, Email
- ✅ **Reading Progress** - Visual scroll indicator
- ✅ **Type Safety** - Fully typed components

---

## 🚀 Next Steps

In **Lesson 4**, you'll add:
- Supabase database integration
- PostgreSQL schema design
- Row Level Security (RLS)
- Server and client Supabase instances
- Environment variables
- Type generation from database

**Continue to:** [LESSON-4-SUPABASE.md](./LESSON-4-SUPABASE.md)

---

## 📚 Key Concepts Review

### MDX Benefits
- **Component Reusability** - Write once, use everywhere
- **Type Safety** - Full TypeScript support
- **Flexibility** - Mix Markdown and JSX
- **Interactive Content** - Rich user experiences

### Best Practices
- **Use MDX selectively** - Only when you need components
- **Optimize imports** - Don't import unused components
- **Keep components simple** - Easier to maintain
- **Test interactivity** - Ensure scripts work across page navigations

### Performance Tips
- Regular Markdown for simple posts
- MDX for interactive content
- Lazy-load heavy components
- Minimize client-side JavaScript

---

**Congratulations!** 🎉 You've added powerful MDX support to your Astro blog with custom interactive components!

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 2-3 hours
