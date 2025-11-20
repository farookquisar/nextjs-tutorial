# Astro 5.0 Tutorial - Lesson 1: Setup & Project Structure

**Prerequisites:** Node.js 20+, basic JavaScript/HTML/CSS knowledge

---

## ✅ 1. DESC (Description)

### What You'll Learn

In this lesson, you'll set up a complete Astro 5.0 project from scratch and build the foundation of a content platform.

**Core Concepts:**
- ✅ Astro 5.0 project initialization
- ✅ File-based routing system
- ✅ `.astro` component syntax
- ✅ Layouts with slots
- ✅ Component props and TypeScript
- ✅ TailwindCSS integration
- ✅ Environment variables with `astro:env`
- ✅ CSS custom properties for theming

**What You'll Build:**
- Complete project structure
- Base layout with responsive header/footer
- Home, About, and Contact pages
- Dark mode toggle
- Navigation component
- Responsive design with TailwindCSS

---

### Why Astro?

**Astro is perfect for content-driven websites because:**

1. **Zero JavaScript by Default** - Ship only HTML and CSS
2. **Islands Architecture** - Add interactivity only where needed
3. **Content Layer API** - Type-safe content management
4. **Fast by Default** - Optimized for performance
5. **Framework Agnostic** - Use React, Vue, Svelte, or none
6. **Server Islands** - Dynamic personalized content

**Performance Benefits:**
- 📉 **90% less JavaScript** than traditional SPAs
- ⚡ **Sub-second page loads** out of the box
- 🎯 **95+ Lighthouse scores** with minimal effort

---

### File-Based Routing

Astro uses file-based routing similar to Next.js but simpler:

```
src/pages/
├── index.astro          → /
├── about.astro          → /about
├── contact.astro        → /contact
└── blog/
    ├── index.astro      → /blog
    └── [slug].astro     → /blog/post-name
```

**No configuration needed!** Every `.astro` file in `src/pages/` becomes a route.

---

### Component Syntax

Astro components (`.astro` files) have three parts:

```astro
---
// 1. Component Script (Frontmatter)
// Runs at build time on the server
const title = "Hello World";
const items = [1, 2, 3];
---

<!-- 2. Template (HTML) -->
<div>
  <h1>{title}</h1>
  {items.map(item => <li>{item}</li>)}
</div>

<style>
  /* 3. Scoped Styles (Optional) */
  div {
    padding: 1rem;
  }
</style>
```

**Key Points:**
- Frontmatter runs at **build time** (or request time for SSR)
- No JavaScript shipped to the client by default
- CSS is automatically scoped to the component
- Use JSX-like syntax in templates

---

## ✅ 2. CODE (Implementation)

### STEP 1: Create Astro Project

```bash
# Create project directory
mkdir astro-blog
cd astro-blog

# Initialize Astro project with npm
npm create astro@latest . -- --template minimal --install --git --typescript strict

# OR with yarn
yarn create astro . --template minimal --install --git --typescript strict

# OR with pnpm
pnpm create astro@latest . --template minimal --install --git --typescript strict
```

**Template options:**
- `minimal` - Bare bones starter (we'll use this)
- `blog` - Pre-configured blog template
- `portfolio` - Portfolio template

**What this creates:**
```
astro-blog/
├── src/
│   ├── pages/
│   │   └── index.astro
│   └── env.d.ts
├── public/
├── astro.config.mjs
├── package.json
├── tsconfig.json
└── .gitignore
```

<details>
<summary>📖 <strong>What is astro.config.mjs?</strong></summary>

The main configuration file for Astro. Here's what a basic config looks like:

```javascript
import { defineConfig } from 'astro/config';

export default defineConfig({
  // Project root (default: '.')
  root: '.',

  // Output directory for build (default: './dist')
  outDir: './dist',

  // Public directory for static assets (default: './public')
  publicDir: './public',

  // Output mode: 'static' or 'server'
  output: 'static',

  // Integrations (React, Vue, Tailwind, etc.)
  integrations: [],
});
```
</details>

---

### STEP 2: Install TailwindCSS

```bash
# Install Tailwind integration
npx astro add tailwind

# This command will:
# 1. Install @astrojs/tailwind
# 2. Install tailwindcss
# 3. Create tailwind.config.mjs
# 4. Update astro.config.mjs

# Press Enter to confirm all prompts
```

**Verify TailwindCSS installation:**

```bash
# Check astro.config.mjs
cat astro.config.mjs
```

Should show:
```javascript
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  integrations: [tailwind()],
});
```

<details>
<summary>📖 <strong>Why TailwindCSS?</strong></summary>

**Benefits:**
- **Utility-first** - Build designs without leaving HTML
- **Small bundle** - Only CSS you use is included
- **Responsive** - Mobile-first breakpoints
- **Dark mode** - Built-in dark mode support
- **Customizable** - Extensive configuration options

**File size comparison:**
- Bootstrap: ~150KB
- TailwindCSS (production): ~10-20KB
</details>

---

### STEP 3: Project Structure Setup

```bash
# Create directory structure
mkdir -p src/{components,layouts,styles,lib}
mkdir -p src/components/{ui,features}

# Create placeholder files
touch src/styles/global.css
touch src/lib/constants.ts
```

**Final structure:**
```
src/
├── components/
│   ├── ui/           # Reusable UI components
│   └── features/     # Feature-specific components
├── layouts/          # Page layouts
├── pages/            # Routes (file-based routing)
├── styles/           # Global styles
├── lib/              # Utilities and constants
└── env.d.ts          # TypeScript environment types
```

---

### STEP 4: Create Global Styles

```bash
cat > src/styles/global.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* CSS Custom Properties for Theming */
:root {
  /* Light mode colors */
  --color-bg-primary: 255 255 255;
  --color-bg-secondary: 249 250 251;
  --color-text-primary: 17 24 39;
  --color-text-secondary: 107 114 128;
  --color-border: 229 231 235;
  --color-accent: 59 130 246;
}

[data-theme='dark'] {
  /* Dark mode colors */
  --color-bg-primary: 17 24 39;
  --color-bg-secondary: 31 41 55;
  --color-text-primary: 243 244 246;
  --color-text-secondary: 156 163 175;
  --color-border: 55 65 81;
  --color-accent: 96 165 250;
}

@layer base {
  body {
    @apply bg-[rgb(var(--color-bg-primary))] text-[rgb(var(--color-text-primary))];
    @apply transition-colors duration-200;
  }
}

@layer components {
  /* Button styles */
  .btn {
    @apply px-4 py-2 rounded-lg font-medium transition-colors;
    @apply focus:outline-none focus:ring-2 focus:ring-offset-2;
  }

  .btn-primary {
    @apply btn bg-[rgb(var(--color-accent))] text-white;
    @apply hover:opacity-90;
  }

  .btn-secondary {
    @apply btn border border-[rgb(var(--color-border))];
    @apply hover:bg-[rgb(var(--color-bg-secondary))];
  }

  /* Link styles */
  .link {
    @apply text-[rgb(var(--color-accent))] hover:underline;
  }

  /* Card styles */
  .card {
    @apply bg-[rgb(var(--color-bg-secondary))] rounded-lg p-6;
    @apply border border-[rgb(var(--color-border))];
  }
}
EOF
```

<details>
<summary>📖 <strong>Why CSS Custom Properties?</strong></summary>

**CSS variables enable:**
- **Dynamic theming** - Change colors without rebuilding
- **Better performance** - No JavaScript needed for theme switching
- **Type safety** - Validate in TailwindCSS config
- **Maintainability** - Single source of truth

**Traditional approach:**
```css
.dark .bg-primary { background: #1f2937; }
```

**Custom properties approach:**
```css
[data-theme='dark'] { --color-bg-primary: 31 41 55; }
.bg-primary { background: rgb(var(--color-bg-primary)); }
```
</details>

---

### STEP 5: Configure Tailwind for Custom Properties

```bash
cat > tailwind.config.mjs << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: ['class', '[data-theme="dark"]'],
  theme: {
    extend: {
      colors: {
        'bg-primary': 'rgb(var(--color-bg-primary) / <alpha-value>)',
        'bg-secondary': 'rgb(var(--color-bg-secondary) / <alpha-value>)',
        'text-primary': 'rgb(var(--color-text-primary) / <alpha-value>)',
        'text-secondary': 'rgb(var(--color-text-secondary) / <alpha-value>)',
        'border': 'rgb(var(--color-border) / <alpha-value>)',
        'accent': 'rgb(var(--color-accent) / <alpha-value>)',
      },
    },
  },
  plugins: [],
};
EOF
```

---

### STEP 6: Create Constants File

```bash
cat > src/lib/constants.ts << 'EOF'
// Site Configuration
export const SITE_CONFIG = {
  name: 'Astro Blog',
  description: 'A modern blog built with Astro 5.0',
  url: 'https://yourdomain.com',
  author: 'Your Name',
  email: 'your.email@example.com',
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
EOF
```

---

### STEP 7: Create Base Layout

```bash
cat > src/layouts/BaseLayout.astro << 'EOF'
---
import '../styles/global.css';
import { SITE_CONFIG } from '../lib/constants';

interface Props {
  title?: string;
  description?: string;
}

const {
  title = SITE_CONFIG.name,
  description = SITE_CONFIG.description,
} = Astro.props;

const pageTitle = title === SITE_CONFIG.name ? title : `${title} | ${SITE_CONFIG.name}`;
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="generator" content={Astro.generator} />

    <!-- SEO -->
    <title>{pageTitle}</title>
    <meta name="description" content={description} />

    <!-- Theme Script (inline to prevent flash) -->
    <script is:inline>
      // Check for saved theme preference or default to light mode
      const theme = localStorage.getItem('theme') || 'light';
      document.documentElement.setAttribute('data-theme', theme);
    </script>
  </head>
  <body>
    <slot />
  </body>
</html>
EOF
```

<details>
<summary>📖 <strong>Understanding Layouts</strong></summary>

**Key Concepts:**
- Layouts are reusable page wrappers
- Use `<slot />` for content injection
- Can have multiple named slots
- Layouts can wrap other layouts

**Example with named slots:**
```astro
<header>
  <slot name="header" />
</header>
<main>
  <slot /> <!-- Default slot -->
</main>
<footer>
  <slot name="footer" />
</footer>
```

**Usage:**
```astro
<Layout>
  <div slot="header">Header content</div>
  <p>Main content</p>
</Layout>
```
</details>

---

### STEP 8: Create Header Component

```bash
cat > src/components/Header.astro << 'EOF'
---
import { NAV_LINKS } from '../lib/constants';

const currentPath = Astro.url.pathname;
---

<header class="border-b border-border bg-bg-primary sticky top-0 z-50">
  <nav class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="flex items-center justify-between h-16">
      <!-- Logo -->
      <a href="/" class="flex items-center space-x-2 font-bold text-xl">
        <span class="text-accent">Astro</span>
        <span>Blog</span>
      </a>

      <!-- Desktop Navigation -->
      <div class="hidden md:flex items-center space-x-8">
        {NAV_LINKS.map(link => (
          <a
            href={link.href}
            class:list={[
              'transition-colors',
              currentPath === link.href
                ? 'text-accent font-semibold'
                : 'text-text-secondary hover:text-text-primary'
            ]}
          >
            {link.label}
          </a>
        ))}

        <!-- Theme Toggle Button -->
        <button
          id="theme-toggle"
          type="button"
          class="btn-secondary p-2"
          aria-label="Toggle theme"
        >
          <svg
            id="theme-toggle-light-icon"
            class="w-5 h-5"
            fill="currentColor"
            viewBox="0 0 20 20"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"
              fill-rule="evenodd"
              clip-rule="evenodd"
            ></path>
          </svg>
          <svg
            id="theme-toggle-dark-icon"
            class="w-5 h-5 hidden"
            fill="currentColor"
            viewBox="0 0 20 20"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path>
          </svg>
        </button>
      </div>

      <!-- Mobile Menu Button -->
      <button
        id="mobile-menu-button"
        type="button"
        class="md:hidden btn-secondary p-2"
        aria-label="Toggle menu"
      >
        <svg
          class="w-6 h-6"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M4 6h16M4 12h16M4 18h16"
          ></path>
        </svg>
      </button>
    </div>

    <!-- Mobile Navigation -->
    <div id="mobile-menu" class="hidden md:hidden pb-4">
      {NAV_LINKS.map(link => (
        <a
          href={link.href}
          class:list={[
            'block py-2 transition-colors',
            currentPath === link.href
              ? 'text-accent font-semibold'
              : 'text-text-secondary hover:text-text-primary'
          ]}
        >
          {link.label}
        </a>
      ))}
    </div>
  </nav>
</header>

<script>
  // Theme toggle functionality
  const themeToggle = document.getElementById('theme-toggle');
  const lightIcon = document.getElementById('theme-toggle-light-icon');
  const darkIcon = document.getElementById('theme-toggle-dark-icon');

  // Set initial icon state
  const currentTheme = document.documentElement.getAttribute('data-theme');
  if (currentTheme === 'dark') {
    lightIcon?.classList.add('hidden');
    darkIcon?.classList.remove('hidden');
  }

  themeToggle?.addEventListener('click', () => {
    const theme = document.documentElement.getAttribute('data-theme');
    const newTheme = theme === 'light' ? 'dark' : 'light';

    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);

    // Toggle icons
    lightIcon?.classList.toggle('hidden');
    darkIcon?.classList.toggle('hidden');
  });

  // Mobile menu toggle
  const mobileMenuButton = document.getElementById('mobile-menu-button');
  const mobileMenu = document.getElementById('mobile-menu');

  mobileMenuButton?.addEventListener('click', () => {
    mobileMenu?.classList.toggle('hidden');
  });
</script>
EOF
```

<details>
<summary>📖 <strong>Astro Scripts vs Client JavaScript</strong></summary>

**Astro `<script>` tags:**
- Run once on page load
- Bundled and optimized
- Processed by Vite
- Can import modules

**Traditional inline scripts:**
```html
<script is:inline>
  // Runs immediately, not processed by Vite
  // Use for critical scripts that need to run before page renders
</script>
```

**When to use `is:inline`:**
- Theme detection (prevent flash)
- Analytics scripts
- Third-party widgets
</details>

---

### STEP 9: Create Footer Component

```bash
cat > src/components/Footer.astro << 'EOF'
---
import { SITE_CONFIG, SOCIAL_LINKS } from '../lib/constants';

const currentYear = new Date().getFullYear();
---

<footer class="border-t border-border bg-bg-secondary mt-auto">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
      <!-- About Section -->
      <div>
        <h3 class="font-bold text-lg mb-4">About</h3>
        <p class="text-text-secondary">
          {SITE_CONFIG.description}
        </p>
      </div>

      <!-- Links Section -->
      <div>
        <h3 class="font-bold text-lg mb-4">Quick Links</h3>
        <ul class="space-y-2">
          <li><a href="/" class="link">Home</a></li>
          <li><a href="/blog" class="link">Blog</a></li>
          <li><a href="/about" class="link">About</a></li>
          <li><a href="/contact" class="link">Contact</a></li>
        </ul>
      </div>

      <!-- Social Section -->
      <div>
        <h3 class="font-bold text-lg mb-4">Connect</h3>
        <div class="flex space-x-4">
          <a
            href={SOCIAL_LINKS.github}
            target="_blank"
            rel="noopener noreferrer"
            class="text-text-secondary hover:text-accent transition-colors"
            aria-label="GitHub"
          >
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.840 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
            </svg>
          </a>
          <a
            href={SOCIAL_LINKS.twitter}
            target="_blank"
            rel="noopener noreferrer"
            class="text-text-secondary hover:text-accent transition-colors"
            aria-label="Twitter"
          >
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
              <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
            </svg>
          </a>
          <a
            href={SOCIAL_LINKS.linkedin}
            target="_blank"
            rel="noopener noreferrer"
            class="text-text-secondary hover:text-accent transition-colors"
            aria-label="LinkedIn"
          >
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
              <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
            </svg>
          </a>
        </div>
      </div>
    </div>

    <div class="mt-8 pt-8 border-t border-border text-center text-text-secondary">
      <p>&copy; {currentYear} {SITE_CONFIG.name}. All rights reserved.</p>
      <p class="mt-2 text-sm">Built with <span class="text-accent">Astro 5.0</span></p>
    </div>
  </div>
</footer>
EOF
```

---

### STEP 10: Create Main Layout with Header/Footer

```bash
cat > src/layouts/MainLayout.astro << 'EOF'
---
import BaseLayout from './BaseLayout.astro';
import Header from '../components/Header.astro';
import Footer from '../components/Footer.astro';

interface Props {
  title?: string;
  description?: string;
}

const { title, description } = Astro.props;
---

<BaseLayout title={title} description={description}>
  <div class="flex flex-col min-h-screen">
    <Header />
    <main class="flex-1">
      <slot />
    </main>
    <Footer />
  </div>
</BaseLayout>
EOF
```

---

### STEP 11: Create Pages

**Home Page:**

```bash
cat > src/pages/index.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
---

<MainLayout title="Home">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <!-- Hero Section -->
    <section class="text-center mb-16">
      <h1 class="text-5xl font-bold mb-4">
        Welcome to <span class="text-accent">Astro Blog</span>
      </h1>
      <p class="text-xl text-text-secondary max-w-2xl mx-auto">
        A modern, performant blog built with Astro 5.0. Fast by default, powered by the islands architecture.
      </p>
      <div class="mt-8 flex justify-center space-x-4">
        <a href="/blog" class="btn-primary">Read Blog</a>
        <a href="/about" class="btn-secondary">Learn More</a>
      </div>
    </section>

    <!-- Features Section -->
    <section class="grid md:grid-cols-3 gap-8 mt-16">
      <div class="card">
        <div class="text-accent text-3xl mb-4">⚡</div>
        <h3 class="font-bold text-xl mb-2">Lightning Fast</h3>
        <p class="text-text-secondary">
          Zero JavaScript by default. Only hydrate components when needed.
        </p>
      </div>

      <div class="card">
        <div class="text-accent text-3xl mb-4">🏝️</div>
        <h3 class="font-bold text-xl mb-2">Islands Architecture</h3>
        <p class="text-text-secondary">
          Mix static and interactive content for optimal performance.
        </p>
      </div>

      <div class="card">
        <div class="text-accent text-3xl mb-4">📝</div>
        <h3 class="font-bold text-xl mb-2">Content First</h3>
        <p class="text-text-secondary">
          Built for content with the powerful Content Layer API.
        </p>
      </div>
    </section>

    <!-- Stats Section -->
    <section class="mt-16 bg-bg-secondary rounded-lg p-8">
      <div class="grid md:grid-cols-4 gap-8 text-center">
        <div>
          <div class="text-4xl font-bold text-accent">95+</div>
          <div class="text-text-secondary mt-2">Lighthouse Score</div>
        </div>
        <div>
          <div class="text-4xl font-bold text-accent">50KB</div>
          <div class="text-text-secondary mt-2">JavaScript Bundle</div>
        </div>
        <div>
          <div class="text-4xl font-bold text-accent">&lt;1s</div>
          <div class="text-text-secondary mt-2">Page Load Time</div>
        </div>
        <div>
          <div class="text-4xl font-bold text-accent">0KB</div>
          <div class="text-text-secondary mt-2">Default JS Shipped</div>
        </div>
      </div>
    </section>
  </div>
</MainLayout>
EOF
```

**About Page:**

```bash
cat > src/pages/about.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
---

<MainLayout title="About" description="Learn more about our blog">
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <h1 class="text-4xl font-bold mb-8">About Us</h1>

    <div class="prose prose-lg max-w-none">
      <p class="text-xl text-text-secondary mb-8">
        Welcome to our blog built with Astro 5.0, the modern web framework that delivers lightning-fast performance with a focus on content.
      </p>

      <div class="card mb-8">
        <h2 class="text-2xl font-bold mb-4">Our Mission</h2>
        <p class="text-text-secondary">
          We're on a mission to share knowledge and insights about web development, performance optimization, and modern JavaScript frameworks. Our blog focuses on practical tutorials and real-world examples.
        </p>
      </div>

      <div class="card mb-8">
        <h2 class="text-2xl font-bold mb-4">Why Astro?</h2>
        <ul class="space-y-2 text-text-secondary">
          <li>✅ <strong>Zero JavaScript by Default:</strong> Ship only HTML and CSS</li>
          <li>✅ <strong>Islands Architecture:</strong> Add interactivity where needed</li>
          <li>✅ <strong>Framework Agnostic:</strong> Use React, Vue, Svelte, or none</li>
          <li>✅ <strong>Content Layer API:</strong> Type-safe content management</li>
          <li>✅ <strong>Fast by Default:</strong> Optimized build process</li>
        </ul>
      </div>

      <div class="card">
        <h2 class="text-2xl font-bold mb-4">Tech Stack</h2>
        <div class="grid md:grid-cols-2 gap-4">
          <div>
            <h3 class="font-semibold mb-2">Frontend</h3>
            <ul class="text-text-secondary space-y-1">
              <li>• Astro 5.0</li>
              <li>• TypeScript</li>
              <li>• TailwindCSS</li>
              <li>• React (Islands)</li>
            </ul>
          </div>
          <div>
            <h3 class="font-semibold mb-2">Backend</h3>
            <ul class="text-text-secondary space-y-1">
              <li>• Supabase</li>
              <li>• PostgreSQL</li>
              <li>• Content Layer API</li>
              <li>• Server Islands</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</MainLayout>
EOF
```

**Contact Page:**

```bash
cat > src/pages/contact.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import { SITE_CONFIG } from '../lib/constants';
---

<MainLayout title="Contact" description="Get in touch with us">
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <h1 class="text-4xl font-bold mb-8">Contact Us</h1>

    <div class="grid md:grid-cols-2 gap-8">
      <!-- Contact Info -->
      <div>
        <div class="card mb-6">
          <h2 class="text-2xl font-bold mb-4">Get in Touch</h2>
          <p class="text-text-secondary mb-4">
            Have questions or suggestions? We'd love to hear from you!
          </p>
          <div class="space-y-3">
            <div class="flex items-center space-x-3">
              <svg class="w-5 h-5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
              </svg>
              <a href={`mailto:${SITE_CONFIG.email}`} class="link">{SITE_CONFIG.email}</a>
            </div>
            <div class="flex items-center space-x-3">
              <svg class="w-5 h-5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path>
              </svg>
              <span class="text-text-secondary">{SITE_CONFIG.url}</span>
            </div>
          </div>
        </div>

        <div class="card">
          <h3 class="font-bold text-xl mb-3">Follow Us</h3>
          <p class="text-text-secondary mb-4">
            Stay updated with our latest posts and updates.
          </p>
          <div class="flex space-x-4">
            <a href="#" class="text-accent hover:underline">Twitter</a>
            <a href="#" class="text-accent hover:underline">GitHub</a>
            <a href="#" class="text-accent hover:underline">LinkedIn</a>
          </div>
        </div>
      </div>

      <!-- Contact Form (Static for now) -->
      <div class="card">
        <h2 class="text-2xl font-bold mb-4">Send a Message</h2>
        <form class="space-y-4">
          <div>
            <label for="name" class="block text-sm font-medium mb-2">Name</label>
            <input
              type="text"
              id="name"
              name="name"
              class="w-full px-4 py-2 border border-border rounded-lg bg-bg-primary focus:ring-2 focus:ring-accent focus:border-transparent"
              required
            />
          </div>

          <div>
            <label for="email" class="block text-sm font-medium mb-2">Email</label>
            <input
              type="email"
              id="email"
              name="email"
              class="w-full px-4 py-2 border border-border rounded-lg bg-bg-primary focus:ring-2 focus:ring-accent focus:border-transparent"
              required
            />
          </div>

          <div>
            <label for="message" class="block text-sm font-medium mb-2">Message</label>
            <textarea
              id="message"
              name="message"
              rows="4"
              class="w-full px-4 py-2 border border-border rounded-lg bg-bg-primary focus:ring-2 focus:ring-accent focus:border-transparent"
              required
            ></textarea>
          </div>

          <button type="submit" class="btn-primary w-full">
            Send Message
          </button>

          <p class="text-sm text-text-secondary text-center">
            Note: Form functionality will be added in future lessons
          </p>
        </form>
      </div>
    </div>
  </div>
</MainLayout>
EOF
```

---

### STEP 12: Create Blog Placeholder Page

```bash
mkdir -p src/pages/blog

cat > src/pages/blog/index.astro << 'EOF'
---
import MainLayout from '../../layouts/MainLayout.astro';
---

<MainLayout title="Blog" description="Read our latest blog posts">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
    <h1 class="text-4xl font-bold mb-8">Blog</h1>

    <div class="card text-center py-16">
      <div class="text-6xl mb-4">📝</div>
      <h2 class="text-2xl font-bold mb-4">Coming Soon</h2>
      <p class="text-text-secondary mb-8">
        Blog posts will be added in Lesson 2 when we set up the Content Layer API.
      </p>
      <a href="/" class="btn-primary">Back to Home</a>
    </div>
  </div>
</MainLayout>
EOF
```

---

### STEP 13: Add Favicon

```bash
# Create a simple SVG favicon
cat > public/favicon.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:rgb(59,130,246);stop-opacity:1" />
      <stop offset="100%" style="stop-color:rgb(147,51,234);stop-opacity:1" />
    </linearGradient>
  </defs>
  <circle cx="50" cy="50" r="45" fill="url(#grad)" />
  <text x="50" y="70" font-family="Arial, sans-serif" font-size="60" font-weight="bold" fill="white" text-anchor="middle">A</text>
</svg>
EOF
```

---

### STEP 14: Update Package.json Scripts

```bash
cat > package.json << 'EOF'
{
  "name": "astro-blog",
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev",
    "build": "astro check && astro build",
    "preview": "astro preview",
    "astro": "astro",
    "check": "astro check"
  },
  "dependencies": {
    "@astrojs/check": "^0.9.0",
    "@astrojs/tailwind": "^5.1.0",
    "astro": "^5.0.0",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.6.0"
  }
}
EOF

# Reinstall dependencies to ensure everything is correct
npm install
```

---

### STEP 15: Run the Project

```bash
# Start development server
npm run dev

# The server will start at http://localhost:4321
```

**Expected Output:**
```
  🚀  astro  v5.0.0 started in 45ms

  ┃ Local    http://localhost:4321/
  ┃ Network  use --host to expose

  watching for file changes...
```

**Open your browser:**
- Home: http://localhost:4321/
- About: http://localhost:4321/about
- Contact: http://localhost:4321/contact
- Blog: http://localhost:4321/blog

**Test dark mode toggle:**
- Click the sun/moon icon in the header
- Theme should switch smoothly
- Refresh page - theme persists

---

## ✅ 3. VERIFY (Testing)

### Checklist

#### Project Setup ✓
- [ ] Project created with `npm create astro@latest`
- [ ] TailwindCSS installed and configured
- [ ] Development server runs at http://localhost:4321
- [ ] No console errors in browser

#### File Structure ✓
- [ ] All directories created (`components`, `layouts`, `styles`, `lib`)
- [ ] Global CSS file exists with custom properties
- [ ] Tailwind config has custom colors
- [ ] Constants file has site configuration

#### Components ✓
- [ ] BaseLayout.astro created and renders
- [ ] MainLayout.astro wraps BaseLayout
- [ ] Header.astro displays navigation
- [ ] Footer.astro shows at bottom
- [ ] Header is sticky on scroll

#### Pages ✓
- [ ] Home page loads at `/`
- [ ] About page loads at `/about`
- [ ] Contact page loads at `/contact`
- [ ] Blog placeholder loads at `/blog`
- [ ] All pages use MainLayout
- [ ] Page titles are correct

#### Styling ✓
- [ ] TailwindCSS classes work
- [ ] Custom color utilities work (`bg-bg-primary`, etc.)
- [ ] Responsive design works on mobile
- [ ] Cards have proper styling
- [ ] Buttons have hover states

#### Dark Mode ✓
- [ ] Toggle button in header works
- [ ] Theme switches between light/dark
- [ ] Theme persists on page refresh
- [ ] No flash of wrong theme on load
- [ ] All custom properties update correctly

#### Navigation ✓
- [ ] All nav links work
- [ ] Active link is highlighted
- [ ] Mobile menu toggles on small screens
- [ ] Logo links to home

#### Performance ✓
- [ ] Page loads in <1 second
- [ ] No unnecessary JavaScript shipped
- [ ] CSS is scoped properly
- [ ] No console warnings

---

### Common Issues & Solutions

**Issue 1: Port 4321 already in use**
```bash
# Use a different port
npm run dev -- --port 3000
```

**Issue 2: Tailwind styles not working**
```bash
# Verify tailwind.config.mjs content paths
# Should include: './src/**/*.{astro,html,js,jsx,md,mdx,ts,tsx}'

# Restart dev server
npm run dev
```

**Issue 3: Theme toggle not working**
```bash
# Check browser console for JavaScript errors
# Ensure IDs match: theme-toggle, theme-toggle-light-icon, theme-toggle-dark-icon

# Clear localStorage
localStorage.clear();
```

**Issue 4: Mobile menu not opening**
```bash
# Verify IDs match: mobile-menu-button, mobile-menu
# Check that Tailwind's `md:` breakpoint is configured
```

**Issue 5: Custom properties not applying**
```bash
# Check that global.css is imported in BaseLayout.astro
# Verify CSS custom properties syntax: rgb(var(--color-bg-primary))
# Ensure [data-theme='dark'] selector is present
```

---

### Testing Commands

```bash
# Check TypeScript errors
npm run check

# Build for production
npm run build

# Preview production build
npm run preview

# Check bundle size
npm run build && ls -lh dist/

# Verify HTML output
cat dist/index.html
```

---

### Expected File Count

```bash
# Count all project files (excluding node_modules)
find src -type f | wc -l
# Should be around 15-20 files

# List all pages
ls src/pages/
# Should show: index.astro, about.astro, contact.astro, blog/

# List all components
ls src/components/
# Should show: Header.astro, Footer.astro
```

---

## 🎯 What You Built

### Pages (4)
- ✅ **Home** - Hero section, features, stats
- ✅ **About** - Mission, tech stack, info
- ✅ **Contact** - Contact form, social links
- ✅ **Blog** - Placeholder for Lesson 2

### Components (2)
- ✅ **Header** - Navigation, theme toggle, mobile menu
- ✅ **Footer** - Links, social icons, copyright

### Layouts (2)
- ✅ **BaseLayout** - HTML structure, SEO, theme script
- ✅ **MainLayout** - Header + content + Footer

### Features
- ✅ **Dark Mode** - Persists across sessions
- ✅ **Responsive Design** - Mobile-first approach
- ✅ **File-Based Routing** - Clean URLs
- ✅ **Type Safety** - TypeScript throughout
- ✅ **Zero JavaScript** - Static HTML by default

---

## 🚀 Next Steps

In **Lesson 2**, you'll learn:
- Content Layer API
- Content collections with Zod schemas
- Type-safe queries
- Static page generation
- Blog post listing
- Pagination

**Continue to:** [LESSON-2-CONTENT-LAYER.md](./LESSON-2-CONTENT-LAYER.md)

---

## 📚 Key Concepts Review

### Astro Components
- Frontmatter (---) runs at build time
- Templates use JSX-like syntax
- Styles are scoped automatically
- No client JavaScript by default

### File-Based Routing
- `src/pages/` maps to URLs
- `index.astro` → `/`
- `about.astro` → `/about`
- `blog/[slug].astro` → `/blog/:slug`

### Layouts
- Reusable page wrappers
- Use `<slot />` for content
- Can nest layouts
- Pass props for customization

### Custom Properties
- CSS variables for dynamic theming
- No JavaScript needed
- Better performance than CSS classes
- Easy to maintain

### TypeScript
- Type-safe props with `interface Props`
- Auto-completion in VS Code
- Catch errors early
- Self-documenting code

---

## 💡 Pro Tips

1. **Use `class:list` for conditional classes:**
```astro
<div class:list={['base', isActive && 'active']} />
```

2. **Component scripts run once at build time:**
```astro
---
const data = await fetchData(); // Runs at build time
---
```

3. **Use `is:inline` for critical scripts:**
```astro
<script is:inline>
  // Not processed by Vite, runs immediately
</script>
```

4. **Astro.props is fully typed:**
```astro
interface Props {
  title: string;
}
const { title } = Astro.props; // TypeScript knows this!
```

---

**Congratulations!** 🎉 You've completed Lesson 1 and built a solid foundation for your Astro blog.

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 2-3 hours
