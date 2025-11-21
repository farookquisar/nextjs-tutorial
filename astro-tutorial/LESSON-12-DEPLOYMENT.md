# Astro 5.0 Tutorial - Lesson 12: SEO, Performance & Deployment

**Prerequisites:** Completion of Lessons 1-11

---

## ✅ 1. DESC (Description)

### What You'll Learn

Optimize your Astro blog for SEO, performance, and deploy to production with automated builds.

**Core Concepts:**
- ✅ SEO optimization with meta tags
- ✅ Automatic sitemap.xml generation
- ✅ RSS feed for blog
- ✅ robots.txt configuration
- ✅ Performance monitoring setup
- ✅ Image optimization
- ✅ Build optimization
- ✅ Deployment to Vercel/Netlify
- ✅ Environment configuration
- ✅ Analytics integration

**What You'll Build:**
- SEO component with Open Graph
- Sitemap generator
- RSS feed
- robots.txt
- Performance monitoring
- CI/CD pipeline
- Production deployment

---

## ✅ 2. CODE (Implementation)

### STEP 1: Create SEO Component

\`\`\`bash
cat > src/components/SEO.astro << 'EOF'
---
interface Props {
  title: string;
  description?: string;
  image?: string;
  article?: {
    publishedAt: string;
    modifiedAt?: string;
    author: string;
    tags?: string[];
  };
  noindex?: boolean;
}

const {
  title,
  description = 'A modern blog built with Astro 5.0',
  image = '/og-image.jpg',
  article,
  noindex = false,
} = Astro.props;

const canonicalURL = new URL(Astro.url.pathname, Astro.site);
const imageURL = new URL(image, Astro.site);
const siteName = 'Astro Blog';
---

<!-- Primary Meta Tags -->
<title>{title}</title>
<meta name="title" content={title} />
<meta name="description" content={description} />
{noindex && <meta name="robots" content="noindex, nofollow" />}

<!-- Canonical URL -->
<link rel="canonical" href={canonicalURL} />

<!-- Open Graph / Facebook -->
<meta property="og:type" content={article ? 'article' : 'website'} />
<meta property="og:url" content={canonicalURL} />
<meta property="og:title" content={title} />
<meta property="og:description" content={description} />
<meta property="og:image" content={imageURL} />
<meta property="og:site_name" content={siteName} />

{article && (
  <>
    <meta property="article:published_time" content={article.publishedAt} />
    {article.modifiedAt && (
      <meta property="article:modified_time" content={article.modifiedAt} />
    )}
    <meta property="article:author" content={article.author} />
    {article.tags?.map((tag) => (
      <meta property="article:tag" content={tag} />
    ))}
  </>
)}

<!-- Twitter -->
<meta property="twitter:card" content="summary_large_image" />
<meta property="twitter:url" content={canonicalURL} />
<meta property="twitter:title" content={title} />
<meta property="twitter:description" content={description} />
<meta property="twitter:image" content={imageURL} />

<!-- Additional SEO -->
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta charset="UTF-8" />
<link rel="sitemap" href="/sitemap-index.xml" />
EOF
\`\`\`

---

### STEP 2: Generate Sitemap and RSS Feed

\`\`\`bash
# Install integrations
npm install @astrojs/sitemap @astrojs/rss

# Update config
cat > astro.config.mjs << 'EOF'
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import react from '@astrojs/react';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://yourdomain.com', // Update with your domain
  output: 'hybrid',
  integrations: [
    tailwind(),
    react(),
    mdx(),
    sitemap(),
  ],
  experimental: {
    serverIslands: true,
  },
});
EOF

# Create RSS feed
cat > src/pages/rss.xml.ts << 'EOF'
import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import type { APIContext } from 'astro';

export async function GET(context: APIContext) {
  const posts = await getCollection('blog');
  
  return rss({
    title: 'Astro Blog',
    description: 'A modern blog built with Astro 5.0',
    site: context.site!,
    items: posts.map((post) => ({
      title: post.data.title,
      pubDate: post.data.publishedAt,
      description: post.data.excerpt,
      link: \`/blog/\${post.slug}/\`,
      categories: post.data.tags,
    })),
    customData: \`<language>en-us</language>\`,
  });
}
EOF
\`\`\`

---

### STEP 3: Create robots.txt

\`\`\`bash
cat > public/robots.txt << 'EOF'
User-agent: *
Allow: /

# Disallow admin pages
Disallow: /admin/
Disallow: /api/

# Sitemap
Sitemap: https://yourdomain.com/sitemap-index.xml
EOF
\`\`\`

---

### STEP 4: Optimize Images

\`\`\`bash
npm install @astrojs/image sharp

# Update config
cat >> astro.config.mjs << 'EOF'
import image from '@astrojs/image';

export default defineConfig({
  // ... existing config
  integrations: [
    // ... existing integrations
    image({
      serviceEntryPoint: '@astrojs/image/sharp',
    }),
  ],
});
EOF

# Use optimized images
cat > src/components/OptimizedImage.astro << 'EOF'
---
import { Image } from '@astrojs/image/components';

interface Props {
  src: string;
  alt: string;
  width: number;
  height: number;
}

const { src, alt, width, height } = Astro.props;
---

<Image
  src={src}
  alt={alt}
  width={width}
  height={height}
  format="webp"
  quality={80}
  loading="lazy"
/>
EOF
\`\`\`

---

### STEP 5: Deploy to Vercel

\`\`\`bash
# Install Vercel adapter
npm install @astrojs/vercel

# Update config
cat > astro.config.mjs << 'EOF'
import { defineConfig } from 'astro/config';
import vercel from '@astrojs/vercel/serverless';

export default defineConfig({
  output: 'hybrid',
  adapter: vercel({
    webAnalytics: {
      enabled: true,
    },
    speedInsights: {
      enabled: true,
    },
  }),
  // ... rest of config
});
EOF

# Create vercel.json
cat > vercel.json << 'EOF'
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "astro",
  "regions": ["iad1"],
  "env": {
    "PUBLIC_SUPABASE_URL": "@public-supabase-url",
    "PUBLIC_SUPABASE_ANON_KEY": "@public-supabase-anon-key"
  }
}
EOF

# Deploy
npx vercel --prod
\`\`\`

---

### STEP 6: Setup Analytics

\`\`\`bash
cat > src/components/Analytics.astro << 'EOF'
---
const isProd = import.meta.env.PROD;
const analyticsId = import.meta.env.PUBLIC_ANALYTICS_ID;
---

{isProd && analyticsId && (
  <script async src={\`https://www.googletagmanager.com/gtag/js?id=\${analyticsId}\`}></script>
  <script is:inline define:vars={{ analyticsId }}>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', analyticsId);
  </script>
)}
EOF
\`\`\`

---

### STEP 7: Performance Optimization

\`\`\`bash
# Build configuration
cat > astro.config.mjs << 'EOF'
export default defineConfig({
  build: {
    inlineStylesheets: 'auto',
  },
  vite: {
    build: {
      cssCodeSplit: true,
      rollupOptions: {
        output: {
          manualChunks: {
            'react-vendor': ['react', 'react-dom'],
          },
        },
      },
    },
  },
});
EOF

# Add lighthouse CI
cat > .github/workflows/lighthouse.yml << 'EOF'
name: Lighthouse CI

on:
  pull_request:
    branches: [main]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run build
      - uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            http://localhost:4321
            http://localhost:4321/blog
          uploadArtifacts: true
EOF
\`\`\`

---

## ✅ 3. VERIFY (Testing & Troubleshooting)

### Verification Checklist

**SEO:**
- [ ] Meta tags present
- [ ] Open Graph works
- [ ] Sitemap generates
- [ ] RSS feed valid
- [ ] robots.txt accessible

**Performance:**
- [ ] Lighthouse score 90+
- [ ] Images optimized
- [ ] CSS minified
- [ ] JS code-split

**Deployment:**
- [ ] Build succeeds
- [ ] Environment variables set
- [ ] Domain configured
- [ ] SSL enabled
- [ ] Analytics tracking

---

### Testing Commands

\`\`\`bash
# Build for production
npm run build

# Check bundle size
npx astro build --analyze

# Test production build
npm run preview

# Run Lighthouse
npx lighthouse http://localhost:4321 --view

# Check SEO
curl -I https://yourdomain.com
curl https://yourdomain.com/sitemap-index.xml
curl https://yourdomain.com/rss.xml
curl https://yourdomain.com/robots.txt

# Deploy to Vercel
npx vercel --prod

# Deploy to Netlify
npx netlify deploy --prod
\`\`\`

---

### Performance Checklist

- [ ] Core Web Vitals passing
- [ ] First Contentful Paint < 1.8s
- [ ] Largest Contentful Paint < 2.5s
- [ ] Cumulative Layout Shift < 0.1
- [ ] Time to Interactive < 3.8s
- [ ] Total Blocking Time < 200ms

---

## 🎯 Project Complete!

### What You've Built

**Pages:** 15+
- Home, About, Contact
- Blog listing and posts
- Search page
- Dashboard
- Profile
- Admin panel
- Login/Signup

**Features:** 25+
- Authentication (Email + OAuth)
- Server Islands
- React Islands
- Comments with real-time updates
- Like/Bookmark system
- View tracking
- Search with filters
- View Transitions
- Admin dashboard
- Rich text editor
- Image optimization
- SEO optimization

**Database Tables:** 10+
- Users & Profiles
- Posts & Categories
- Comments
- Likes & Bookmarks
- Views
- Search Analytics

---

## 🚀 Next Steps

**Enhancements to Consider:**
1. Newsletter subscription
2. Multi-language support (i18n)
3. Related posts algorithm
4. User notifications
5. Content scheduling
6. A/B testing
7. Progressive Web App (PWA)
8. WebSocket live updates
9. Payment integration
10. Advanced analytics

---

**Congratulations!** 🎉 You've completed the entire Astro 5.0 tutorial series and built a production-ready blog platform!

---

## 📚 Resources

- [Astro Documentation](https://docs.astro.build)
- [Supabase Documentation](https://supabase.com/docs)
- [React Documentation](https://react.dev)
- [Tailwind CSS](https://tailwindcss.com)
- [Vercel Documentation](https://vercel.com/docs)

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 5-7 hours
**Total Series Duration:** 40-60 hours
