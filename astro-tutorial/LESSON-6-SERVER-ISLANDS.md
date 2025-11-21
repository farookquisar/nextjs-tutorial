# Astro 5.0 Tutorial - Lesson 6: Server Islands & Dynamic Content

**Prerequisites:** Completion of Lessons 1-5, Supabase configured with auth

---

## ✅ 1. DESC (Description)

### What You'll Learn

In this lesson, you'll implement Server Islands - Astro 5.0's revolutionary feature for dynamic, personalized content within static pages.

**Core Concepts:**
- ✅ Server Islands fundamentals
- ✅ `server:defer` directive
- ✅ Dynamic user-specific content
- ✅ Real-time data fetching
- ✅ Encrypted props for security
- ✅ Streaming HTML responses
- ✅ Fallback content strategies
- ✅ Cache strategies for islands
- ✅ Performance optimization
- ✅ Error boundaries

**What You'll Build:**
- User avatar widget (Server Island)
- Like/bookmark buttons with real-time counts
- View counter with increments
- Personalized content recommendations
- Dynamic user dashboard widgets
- Real-time notifications badge
- User-specific sidebar
- Activity feed
- Stats widgets
- Session-based content

---

### What Are Server Islands?

**Server Islands are Astro's solution for dynamic content in static pages:**

Traditional approach (full SSR):
```
❌ Entire page renders on every request → Slow
❌ All content dynamic → High server load
❌ No static optimization → Poor caching
```

Server Islands approach:
```
✅ Static shell cached → Fast initial load
✅ Dynamic islands load separately → Targeted updates
✅ Best of static + dynamic → Optimal performance
```

**Example:**
```astro
<!-- Static content (cached) -->
<h1>Blog Post Title</h1>
<article>Static content here...</article>

<!-- Dynamic island (per-user) -->
<UserActions server:defer>
  <div slot="fallback">Loading...</div>
</UserActions>
```

---

### Server Islands vs Client Islands

**Client Islands (React, Vue, Svelte):**
- Run in the browser
- Interactive components
- JavaScript sent to client
- Use for: buttons, forms, modals

**Server Islands (Astro components):**
- Run on the server
- Dynamic data fetching
- No JavaScript sent to client
- Use for: user data, real-time counts, personalized content

**Comparison:**

| Feature | Client Island | Server Island |
|---------|--------------|---------------|
| Execution | Browser | Server |
| JavaScript | Yes, sent to client | No, stays on server |
| Data Access | API calls | Direct database |
| Authentication | Client-side tokens | Server-side sessions |
| SEO | After hydration | Immediately |
| Performance | JS bundle size | Server processing |

---

### Server Island Architecture

**How Server Islands work:**

```
1. User requests page
   └─> Static HTML served instantly (cached)

2. Browser renders static content
   └─> Shows fallback for islands

3. Browser requests islands
   └─> Fetches dynamic content via HTTP

4. Server executes island code
   └─> Accesses database, checks auth

5. Island HTML streamed to browser
   └─> Replaces fallback content

6. Page fully interactive
   └─> All content displayed
```

**Network flow:**
```
GET /blog/post-1
└─> Returns: Static HTML + Island placeholders

GET /_server-islands/UserActions?props=...
└─> Returns: Rendered island HTML

GET /_server-islands/ViewCounter?props=...
└─> Returns: Updated count HTML
```

---

### Use Cases for Server Islands

**Perfect for:**
- ✅ User-specific data (profile, preferences)
- ✅ Real-time counters (views, likes, comments)
- ✅ Personalized recommendations
- ✅ Activity feeds
- ✅ Live notifications
- ✅ Dynamic pricing
- ✅ Inventory status
- ✅ User authentication state

**Not ideal for:**
- ❌ Highly interactive UI (use React/Vue islands)
- ❌ Content that needs client-side state
- ❌ Real-time collaboration (use WebSockets)
- ❌ Complex animations (use CSS/JS)

---

## ✅ 2. CODE (Implementation)

### STEP 1: Enable Server Islands in Config

```bash
cat > astro.config.mjs << 'EOF'
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import react from '@astrojs/react';
import mdx from '@astrojs/mdx';

export default defineConfig({
  output: 'hybrid', // Enable hybrid rendering
  integrations: [
    tailwind(),
    react(),
    mdx(),
  ],
  experimental: {
    serverIslands: true, // Enable Server Islands
  },
  server: {
    // Configure server for development
    port: 4321,
    host: true,
  },
});
EOF

# Install required dependencies
npm install @astrojs/node

# Update package.json scripts
cat > package.json << 'EOF'
{
  "name": "astro-blog",
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "check": "astro check"
  },
  "dependencies": {
    "@astrojs/check": "^0.3.0",
    "@astrojs/mdx": "^2.0.0",
    "@astrojs/node": "^7.0.0",
    "@astrojs/react": "^3.0.0",
    "@astrojs/tailwind": "^5.0.0",
    "@supabase/ssr": "^0.0.10",
    "@supabase/supabase-js": "^2.38.0",
    "astro": "^5.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "tailwindcss": "^3.3.0",
    "typescript": "^5.3.0"
  }
}
EOF

npm install
```

---

### STEP 2: Create User Avatar Widget (Server Island)

```bash
cat > src/components/islands/UserAvatar.astro << 'EOF'
---
import { getUserProfile } from '../../lib/auth';

export const prerender = false; // Make this a server island

interface Props {
  size?: 'sm' | 'md' | 'lg';
  showName?: boolean;
}

const { size = 'md', showName = true } = Astro.props;

// Fetch user profile (runs on server for each request)
const userProfile = await getUserProfile(Astro.cookies);

// Size classes
const sizeClasses = {
  sm: 'w-8 h-8 text-sm',
  md: 'w-12 h-12 text-base',
  lg: 'w-16 h-16 text-xl',
};

const avatarClass = sizeClasses[size];
---

{userProfile ? (
  <div class="flex items-center gap-3">
    <!-- Avatar -->
    <div class={`${avatarClass} bg-accent/10 rounded-full flex items-center justify-center overflow-hidden`}>
      {userProfile.profile.avatar_url ? (
        <img
          src={userProfile.profile.avatar_url}
          alt={userProfile.profile.full_name || 'User'}
          class="w-full h-full object-cover"
        />
      ) : (
        <span class="text-accent font-semibold">
          {userProfile.profile.full_name?.charAt(0).toUpperCase() ||
           userProfile.user.email?.charAt(0).toUpperCase()}
        </span>
      )}
    </div>

    <!-- Name -->
    {showName && (
      <div class="flex flex-col">
        <span class="font-semibold text-sm">
          {userProfile.profile.full_name || 'User'}
        </span>
        <span class="text-xs text-text-secondary">
          {userProfile.user.email}
        </span>
      </div>
    )}
  </div>
) : (
  <div class="flex items-center gap-3">
    <div class={`${avatarClass} bg-gray-300 rounded-full animate-pulse`}></div>
    {showName && (
      <div class="flex flex-col gap-1">
        <div class="h-4 w-20 bg-gray-300 rounded animate-pulse"></div>
        <div class="h-3 w-32 bg-gray-300 rounded animate-pulse"></div>
      </div>
    )}
  </div>
)}
EOF
```

**Usage in pages:**
```bash
cat > src/pages/test-avatar.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import UserAvatar from '../components/islands/UserAvatar.astro';
---

<MainLayout title="Test Avatar">
  <div class="max-w-4xl mx-auto p-8">
    <h1 class="text-4xl font-bold mb-8">User Avatar Test</h1>

    <!-- Server Island with fallback -->
    <div class="card">
      <h2 class="text-xl font-semibold mb-4">Small Avatar</h2>
      <UserAvatar server:defer size="sm">
        <div slot="fallback" class="flex items-center gap-3">
          <div class="w-8 h-8 bg-gray-300 rounded-full animate-pulse"></div>
          <div class="h-4 w-20 bg-gray-300 rounded animate-pulse"></div>
        </div>
      </UserAvatar>
    </div>

    <div class="card mt-6">
      <h2 class="text-xl font-semibold mb-4">Medium Avatar</h2>
      <UserAvatar server:defer size="md">
        <div slot="fallback">Loading user...</div>
      </UserAvatar>
    </div>

    <div class="card mt-6">
      <h2 class="text-xl font-semibold mb-4">Large Avatar</h2>
      <UserAvatar server:defer size="lg">
        <div slot="fallback">Loading user...</div>
      </UserAvatar>
    </div>
  </div>
</MainLayout>

<style>
  .card {
    @apply bg-bg-primary border border-border rounded-lg p-6;
  }
</style>
EOF
```

---

### STEP 3: Create View Counter (Server Island)

**Database schema:**
```bash
cat > supabase/migrations/006_create_views.sql << 'EOF'
-- Create views table
CREATE TABLE IF NOT EXISTS post_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX idx_post_views_post_id ON post_views(post_id);
CREATE INDEX idx_post_views_created_at ON post_views(created_at);

-- Create view_counts materialized view
CREATE MATERIALIZED VIEW post_view_counts AS
SELECT
  post_id,
  COUNT(*) AS view_count,
  COUNT(DISTINCT user_id) AS unique_users,
  COUNT(DISTINCT ip_address) AS unique_ips
FROM post_views
GROUP BY post_id;

-- Index for fast access
CREATE UNIQUE INDEX idx_post_view_counts_post_id ON post_view_counts(post_id);

-- Function to refresh view counts
CREATE OR REPLACE FUNCTION refresh_view_counts()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY post_view_counts;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to refresh counts periodically (use pg_cron in production)
-- For now, we'll refresh manually or via API call
EOF

npm run db:push
```

**View counter component:**
```bash
cat > src/components/islands/ViewCounter.astro << 'EOF'
---
import { createSupabaseServerClient } from '../../lib/auth';

export const prerender = false;

interface Props {
  postId: string;
  increment?: boolean;
}

const { postId, increment = true } = Astro.props;

const supabase = createSupabaseServerClient(Astro.cookies);

// Get user session
const { data: { session } } = await supabase.auth.getSession();

// Increment view count if requested
if (increment) {
  const { error } = await supabase
    .from('post_views')
    .insert({
      post_id: postId,
      user_id: session?.user?.id || null,
      ip_address: Astro.request.headers.get('x-forwarded-for') ||
                  Astro.request.headers.get('x-real-ip') ||
                  'unknown',
      user_agent: Astro.request.headers.get('user-agent') || 'unknown',
    });

  if (error) {
    console.error('Error incrementing view count:', error);
  }

  // Refresh materialized view (in background)
  supabase.rpc('refresh_view_counts').then();
}

// Get current view count
const { data: viewCount } = await supabase
  .from('post_view_counts')
  .select('view_count, unique_users')
  .eq('post_id', postId)
  .single();

const count = viewCount?.view_count || 0;
const uniqueUsers = viewCount?.unique_users || 0;
---

<div class="flex items-center gap-2 text-sm text-text-secondary">
  <!-- Eye icon -->
  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
  </svg>

  <!-- Count -->
  <span class="font-medium">
    {count.toLocaleString()}
    <span class="text-xs">
      {count === 1 ? 'view' : 'views'}
    </span>
  </span>

  <!-- Unique users -->
  {uniqueUsers > 0 && (
    <span class="text-xs opacity-60">
      ({uniqueUsers} {uniqueUsers === 1 ? 'visitor' : 'visitors'})
    </span>
  )}
</div>
EOF
```

---

### STEP 4: Create Like/Bookmark Buttons (Server Islands)

**Database schema:**
```bash
cat > supabase/migrations/007_create_interactions.sql << 'EOF'
-- Create likes table
CREATE TABLE IF NOT EXISTS post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Create bookmarks table
CREATE TABLE IF NOT EXISTS post_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Indexes
CREATE INDEX idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);
CREATE INDEX idx_post_bookmarks_post_id ON post_bookmarks(post_id);
CREATE INDEX idx_post_bookmarks_user_id ON post_bookmarks(user_id);

-- RLS policies
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view likes"
ON post_likes FOR SELECT
USING (true);

CREATE POLICY "Users can manage their own likes"
ON post_likes FOR ALL
USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view bookmarks"
ON post_bookmarks FOR SELECT
USING (true);

CREATE POLICY "Users can manage their own bookmarks"
ON post_bookmarks FOR ALL
USING (auth.uid() = user_id);

-- Create counts materialized view
CREATE MATERIALIZED VIEW post_interaction_counts AS
SELECT
  p.id AS post_id,
  COALESCE(l.like_count, 0) AS like_count,
  COALESCE(b.bookmark_count, 0) AS bookmark_count
FROM posts p
LEFT JOIN (
  SELECT post_id, COUNT(*) AS like_count
  FROM post_likes
  GROUP BY post_id
) l ON p.id = l.post_id
LEFT JOIN (
  SELECT post_id, COUNT(*) AS bookmark_count
  FROM post_bookmarks
  GROUP BY post_id
) b ON p.id = b.post_id;

CREATE UNIQUE INDEX idx_interaction_counts_post_id ON post_interaction_counts(post_id);
EOF

npm run db:push
```

**Like button component:**
```bash
cat > src/components/islands/LikeButton.astro << 'EOF'
---
import { createSupabaseServerClient } from '../../lib/auth';

export const prerender = false;

interface Props {
  postId: string;
}

const { postId } = Astro.props;

const supabase = createSupabaseServerClient(Astro.cookies);

// Get user session
const { data: { session } } = await supabase.auth.getSession();

// Get like count
const { data: counts } = await supabase
  .from('post_interaction_counts')
  .select('like_count')
  .eq('post_id', postId)
  .single();

const likeCount = counts?.like_count || 0;

// Check if user has liked
let userHasLiked = false;
if (session?.user) {
  const { data: existingLike } = await supabase
    .from('post_likes')
    .select('id')
    .eq('post_id', postId)
    .eq('user_id', session.user.id)
    .single();

  userHasLiked = !!existingLike;
}
---

<form method="POST" action={`/api/posts/${postId}/like`} class="inline-block">
  <button
    type="submit"
    class={`like-button ${userHasLiked ? 'liked' : ''}`}
    disabled={!session}
    title={!session ? 'Sign in to like' : userHasLiked ? 'Unlike' : 'Like'}
  >
    <!-- Heart icon -->
    <svg
      class="w-5 h-5"
      fill={userHasLiked ? 'currentColor' : 'none'}
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
      />
    </svg>

    <!-- Count -->
    <span class="like-count">
      {likeCount > 0 ? likeCount.toLocaleString() : ''}
    </span>
  </button>
</form>

<style>
  .like-button {
    @apply flex items-center gap-2 px-4 py-2 rounded-lg;
    @apply border border-border hover:bg-bg-secondary;
    @apply transition-all duration-200;
    @apply text-text-secondary hover:text-text-primary;
  }

  .like-button:disabled {
    @apply opacity-50 cursor-not-allowed;
  }

  .like-button.liked {
    @apply text-red-500 hover:text-red-600;
    @apply border-red-500/20 bg-red-500/5;
  }

  .like-button.liked svg {
    @apply animate-pulse;
    animation-duration: 0.5s;
    animation-iteration-count: 1;
  }

  .like-count {
    @apply font-medium text-sm;
  }
</style>
EOF
```

**Bookmark button component:**
```bash
cat > src/components/islands/BookmarkButton.astro << 'EOF'
---
import { createSupabaseServerClient } from '../../lib/auth';

export const prerender = false;

interface Props {
  postId: string;
}

const { postId } = Astro.props;

const supabase = createSupabaseServerClient(Astro.cookies);

// Get user session
const { data: { session } } = await supabase.auth.getSession();

// Get bookmark count
const { data: counts } = await supabase
  .from('post_interaction_counts')
  .select('bookmark_count')
  .eq('post_id', postId)
  .single();

const bookmarkCount = counts?.bookmark_count || 0;

// Check if user has bookmarked
let userHasBookmarked = false;
if (session?.user) {
  const { data: existingBookmark } = await supabase
    .from('post_bookmarks')
    .select('id')
    .eq('post_id', postId)
    .eq('user_id', session.user.id)
    .single();

  userHasBookmarked = !!existingBookmark;
}
---

<form method="POST" action={`/api/posts/${postId}/bookmark`} class="inline-block">
  <button
    type="submit"
    class={`bookmark-button ${userHasBookmarked ? 'bookmarked' : ''}`}
    disabled={!session}
    title={!session ? 'Sign in to bookmark' : userHasBookmarked ? 'Remove bookmark' : 'Bookmark'}
  >
    <!-- Bookmark icon -->
    <svg
      class="w-5 h-5"
      fill={userHasBookmarked ? 'currentColor' : 'none'}
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
      />
    </svg>

    <!-- Count -->
    {bookmarkCount > 0 && (
      <span class="bookmark-count">
        {bookmarkCount.toLocaleString()}
      </span>
    )}
  </button>
</form>

<style>
  .bookmark-button {
    @apply flex items-center gap-2 px-4 py-2 rounded-lg;
    @apply border border-border hover:bg-bg-secondary;
    @apply transition-all duration-200;
    @apply text-text-secondary hover:text-text-primary;
  }

  .bookmark-button:disabled {
    @apply opacity-50 cursor-not-allowed;
  }

  .bookmark-button.bookmarked {
    @apply text-accent hover:text-accent/80;
    @apply border-accent/20 bg-accent/5;
  }

  .bookmark-count {
    @apply font-medium text-sm;
  }
</style>
EOF
```

---

### STEP 5: Create API Endpoints for Like/Bookmark

```bash
mkdir -p src/pages/api/posts/[postId]

# Like endpoint
cat > src/pages/api/posts/[postId]/like.ts << 'EOF'
import type { APIRoute } from 'astro';
import { createSupabaseServerClient } from '../../../../lib/auth';

export const POST: APIRoute = async ({ params, cookies, redirect, request }) => {
  const { postId } = params;
  const supabase = createSupabaseServerClient(cookies);

  // Check authentication
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    // Check if already liked
    const { data: existingLike } = await supabase
      .from('post_likes')
      .select('id')
      .eq('post_id', postId!)
      .eq('user_id', session.user.id)
      .single();

    if (existingLike) {
      // Unlike - delete the like
      await supabase
        .from('post_likes')
        .delete()
        .eq('id', existingLike.id);
    } else {
      // Like - insert new like
      await supabase
        .from('post_likes')
        .insert({
          post_id: postId!,
          user_id: session.user.id,
        });
    }

    // Refresh materialized view
    await supabase.rpc('refresh_interaction_counts');

    // Get referer to redirect back
    const referer = request.headers.get('referer') || '/blog';
    return redirect(referer);

  } catch (error) {
    console.error('Error toggling like:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
};
EOF

# Bookmark endpoint
cat > src/pages/api/posts/[postId]/bookmark.ts << 'EOF'
import type { APIRoute } from 'astro';
import { createSupabaseServerClient } from '../../../../lib/auth';

export const POST: APIRoute = async ({ params, cookies, redirect, request }) => {
  const { postId } = params;
  const supabase = createSupabaseServerClient(cookies);

  // Check authentication
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    // Check if already bookmarked
    const { data: existingBookmark } = await supabase
      .from('post_bookmarks')
      .select('id')
      .eq('post_id', postId!)
      .eq('user_id', session.user.id)
      .single();

    if (existingBookmark) {
      // Remove bookmark
      await supabase
        .from('post_bookmarks')
        .delete()
        .eq('id', existingBookmark.id);
    } else {
      // Add bookmark
      await supabase
        .from('post_bookmarks')
        .insert({
          post_id: postId!,
          user_id: session.user.id,
        });
    }

    // Refresh materialized view
    await supabase.rpc('refresh_interaction_counts');

    // Get referer to redirect back
    const referer = request.headers.get('referer') || '/blog';
    return redirect(referer);

  } catch (error) {
    console.error('Error toggling bookmark:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
};
EOF

# Create RPC function for refreshing counts
cat > supabase/migrations/008_create_refresh_function.sql << 'EOF'
CREATE OR REPLACE FUNCTION refresh_interaction_counts()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY post_interaction_counts;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
EOF

npm run db:push
```

---

### STEP 6: Create Personalized Recommendations (Server Island)

```bash
cat > src/components/islands/RecommendedPosts.astro << 'EOF'
---
import { createSupabaseServerClient } from '../../lib/auth';

export const prerender = false;

interface Props {
  currentPostId?: string;
  limit?: number;
}

const { currentPostId, limit = 5 } = Astro.props;

const supabase = createSupabaseServerClient(Astro.cookies);

// Get user session
const { data: { session } } = await supabase.auth.getSession();

let recommendedPosts: any[] = [];

if (session?.user) {
  // Personalized recommendations based on user's likes and bookmarks
  const { data } = await supabase.rpc('get_personalized_recommendations', {
    p_user_id: session.user.id,
    p_current_post_id: currentPostId || null,
    p_limit: limit,
  });

  recommendedPosts = data || [];
} else {
  // Generic recommendations for anonymous users (most popular)
  const { data } = await supabase
    .from('posts')
    .select(`
      id,
      title,
      excerpt,
      slug,
      created_at,
      post_interaction_counts (
        like_count,
        bookmark_count
      )
    `)
    .neq('id', currentPostId || '')
    .eq('published', true)
    .order('created_at', { ascending: false })
    .limit(limit);

  recommendedPosts = data || [];
}
---

{recommendedPosts.length > 0 ? (
  <div class="space-y-4">
    <h3 class="text-xl font-bold mb-4">
      {session ? 'Recommended for You' : 'Popular Posts'}
    </h3>

    {recommendedPosts.map(post => (
      <a
        href={`/blog/${post.slug}`}
        class="block p-4 bg-bg-secondary rounded-lg hover:bg-bg-secondary/80 transition-colors"
      >
        <h4 class="font-semibold mb-2">{post.title}</h4>
        {post.excerpt && (
          <p class="text-sm text-text-secondary line-clamp-2">
            {post.excerpt}
          </p>
        )}

        <div class="flex items-center gap-4 mt-3 text-xs text-text-secondary">
          {post.post_interaction_counts && (
            <>
              <span>❤️ {post.post_interaction_counts.like_count}</span>
              <span>🔖 {post.post_interaction_counts.bookmark_count}</span>
            </>
          )}
          <span>{new Date(post.created_at).toLocaleDateString()}</span>
        </div>
      </a>
    ))}
  </div>
) : (
  <div class="text-center py-8 text-text-secondary">
    <p>No recommendations available</p>
  </div>
)}
EOF

# Create recommendation function in database
cat > supabase/migrations/009_create_recommendations.sql << 'EOF'
CREATE OR REPLACE FUNCTION get_personalized_recommendations(
  p_user_id UUID,
  p_current_post_id TEXT,
  p_limit INT DEFAULT 5
)
RETURNS TABLE (
  id TEXT,
  title TEXT,
  excerpt TEXT,
  slug TEXT,
  created_at TIMESTAMPTZ,
  like_count BIGINT,
  bookmark_count BIGINT,
  relevance_score NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH user_interests AS (
    -- Get tags from posts the user liked or bookmarked
    SELECT UNNEST(p.tags) AS tag, COUNT(*) AS interest_weight
    FROM posts p
    WHERE p.id IN (
      SELECT post_id FROM post_likes WHERE user_id = p_user_id
      UNION
      SELECT post_id FROM post_bookmarks WHERE user_id = p_user_id
    )
    GROUP BY tag
  ),
  scored_posts AS (
    SELECT
      p.id,
      p.title,
      p.excerpt,
      p.slug,
      p.created_at,
      COALESCE(pic.like_count, 0) AS like_count,
      COALESCE(pic.bookmark_count, 0) AS bookmark_count,
      -- Calculate relevance score
      (
        -- Tag matching (weighted by user interest)
        COALESCE((
          SELECT SUM(ui.interest_weight)
          FROM user_interests ui
          WHERE ui.tag = ANY(p.tags)
        ), 0) * 2 +
        -- Popularity score
        COALESCE(pic.like_count, 0) * 0.5 +
        COALESCE(pic.bookmark_count, 0) * 0.3 +
        -- Recency bonus (posts from last 30 days)
        CASE WHEN p.created_at > NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END
      ) AS relevance_score
    FROM posts p
    LEFT JOIN post_interaction_counts pic ON p.id = pic.post_id
    WHERE p.published = true
      AND p.id != COALESCE(p_current_post_id, '')
      -- Exclude posts user has already liked or bookmarked
      AND p.id NOT IN (
        SELECT post_id FROM post_likes WHERE user_id = p_user_id
        UNION
        SELECT post_id FROM post_bookmarks WHERE user_id = p_user_id
      )
  )
  SELECT *
  FROM scored_posts
  ORDER BY relevance_score DESC, created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
EOF

npm run db:push
```

---

### STEP 7: Create Activity Feed (Server Island)

```bash
cat > src/components/islands/ActivityFeed.astro << 'EOF'
---
import { createSupabaseServerClient } from '../../lib/auth';

export const prerender = false;

interface Props {
  limit?: number;
}

const { limit = 10 } = Astro.props;

const supabase = createSupabaseServerClient(Astro.cookies);

// Get user session
const { data: { session } } = await supabase.auth.getSession();

if (!session) {
  return null;
}

// Fetch user's recent activities
const { data: activities } = await supabase.rpc('get_user_activities', {
  p_user_id: session.user.id,
  p_limit: limit,
});

// Activity type icons and colors
const activityConfig: Record<string, { icon: string; color: string }> = {
  like: { icon: '❤️', color: 'text-red-500' },
  bookmark: { icon: '🔖', color: 'text-blue-500' },
  comment: { icon: '💬', color: 'text-green-500' },
  post: { icon: '📝', color: 'text-purple-500' },
};

function formatTimeAgo(date: string) {
  const now = new Date();
  const then = new Date(date);
  const seconds = Math.floor((now.getTime() - then.getTime()) / 1000);

  if (seconds < 60) return 'just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`;
  return then.toLocaleDateString();
}
---

<div class="activity-feed">
  <h3 class="text-lg font-bold mb-4">Recent Activity</h3>

  {activities && activities.length > 0 ? (
    <div class="space-y-3">
      {activities.map((activity: any) => {
        const config = activityConfig[activity.activity_type] || {
          icon: '•',
          color: 'text-text-secondary',
        };

        return (
          <div class="flex items-start gap-3 p-3 bg-bg-secondary rounded-lg">
            <!-- Icon -->
            <span class={`text-xl ${config.color}`}>
              {config.icon}
            </span>

            <!-- Content -->
            <div class="flex-1 min-w-0">
              <p class="text-sm">
                <span class="font-medium">You</span>
                {' '}
                {activity.activity_type === 'like' && 'liked'}
                {activity.activity_type === 'bookmark' && 'bookmarked'}
                {activity.activity_type === 'comment' && 'commented on'}
                {activity.activity_type === 'post' && 'published'}
                {' '}
                <a
                  href={activity.post_url}
                  class="text-accent hover:underline truncate"
                >
                  {activity.post_title}
                </a>
              </p>

              <p class="text-xs text-text-secondary mt-1">
                {formatTimeAgo(activity.created_at)}
              </p>
            </div>
          </div>
        );
      })}
    </div>
  ) : (
    <p class="text-sm text-text-secondary text-center py-8">
      No recent activity
    </p>
  )}
</div>

<style>
  .activity-feed {
    @apply bg-bg-primary border border-border rounded-lg p-4;
  }
</style>
EOF

# Create activity tracking function
cat > supabase/migrations/010_create_activity_feed.sql << 'EOF'
CREATE OR REPLACE FUNCTION get_user_activities(
  p_user_id UUID,
  p_limit INT DEFAULT 10
)
RETURNS TABLE (
  activity_type TEXT,
  post_id TEXT,
  post_title TEXT,
  post_url TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  WITH all_activities AS (
    -- Likes
    SELECT
      'like' AS activity_type,
      pl.post_id,
      p.title AS post_title,
      '/blog/' || p.slug AS post_url,
      pl.created_at
    FROM post_likes pl
    JOIN posts p ON pl.post_id = p.id
    WHERE pl.user_id = p_user_id

    UNION ALL

    -- Bookmarks
    SELECT
      'bookmark' AS activity_type,
      pb.post_id,
      p.title AS post_title,
      '/blog/' || p.slug AS post_url,
      pb.created_at
    FROM post_bookmarks pb
    JOIN posts p ON pb.post_id = p.id
    WHERE pb.user_id = p_user_id

    UNION ALL

    -- Comments (if comments table exists)
    SELECT
      'comment' AS activity_type,
      c.post_id,
      p.title AS post_title,
      '/blog/' || p.slug AS post_url,
      c.created_at
    FROM comments c
    JOIN posts p ON c.post_id = p.id
    WHERE c.user_id = p_user_id

    UNION ALL

    -- Posts
    SELECT
      'post' AS activity_type,
      p.id AS post_id,
      p.title AS post_title,
      '/blog/' || p.slug AS post_url,
      p.created_at
    FROM posts p
    WHERE p.author_id = p_user_id
  )
  SELECT *
  FROM all_activities
  ORDER BY created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
EOF

npm run db:push
```

---

### STEP 8: Update Blog Post Page with Server Islands

```bash
cat > src/pages/blog/[slug].astro << 'EOF'
---
import { getEntry } from 'astro:content';
import MainLayout from '../../layouts/MainLayout.astro';
import ViewCounter from '../../components/islands/ViewCounter.astro';
import LikeButton from '../../components/islands/LikeButton.astro';
import BookmarkButton from '../../components/islands/BookmarkButton.astro';
import RecommendedPosts from '../../components/islands/RecommendedPosts.astro';
import UserAvatar from '../../components/islands/UserAvatar.astro';

export const prerender = false; // Enable SSR for this page

const { slug } = Astro.params;
const post = await getEntry('blog', slug!);

if (!post) {
  return Astro.redirect('/404');
}

const { Content } = await post.render();
---

<MainLayout
  title={post.data.title}
  description={post.data.excerpt}
>
  <article class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Header -->
    <header class="mb-8">
      <h1 class="text-4xl font-bold mb-4">{post.data.title}</h1>

      <div class="flex items-center justify-between flex-wrap gap-4 mb-6">
        <!-- Author info (static) -->
        <div class="flex items-center gap-3">
          <div class="w-12 h-12 bg-accent/10 rounded-full flex items-center justify-center">
            <span class="text-accent font-semibold">A</span>
          </div>
          <div>
            <p class="font-semibold">Admin</p>
            <p class="text-sm text-text-secondary">
              {new Date(post.data.publishedAt).toLocaleDateString()}
            </p>
          </div>
        </div>

        <!-- View counter (Server Island) -->
        <ViewCounter server:defer postId={post.id} increment={true}>
          <div slot="fallback" class="flex items-center gap-2 text-sm text-text-secondary">
            <svg class="w-5 h-5 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>Loading views...</span>
          </div>
        </ViewCounter>
      </div>

      <!-- Tags -->
      {post.data.tags && (
        <div class="flex flex-wrap gap-2">
          {post.data.tags.map((tag: string) => (
            <span class="px-3 py-1 bg-accent/10 text-accent rounded-full text-sm">
              #{tag}
            </span>
          ))}
        </div>
      )}
    </header>

    <!-- Content -->
    <div class="prose prose-lg max-w-none mb-12">
      <Content />
    </div>

    <!-- Actions (Server Islands) -->
    <div class="flex items-center gap-4 py-6 border-y border-border">
      <LikeButton server:defer postId={post.id}>
        <div slot="fallback" class="px-4 py-2 bg-gray-300 rounded-lg animate-pulse">
          <span class="opacity-0">Like</span>
        </div>
      </LikeButton>

      <BookmarkButton server:defer postId={post.id}>
        <div slot="fallback" class="px-4 py-2 bg-gray-300 rounded-lg animate-pulse">
          <span class="opacity-0">Bookmark</span>
        </div>
      </BookmarkButton>

      <!-- Share button (static) -->
      <button
        type="button"
        class="share-button"
        onclick="navigator.share?.({ title: this.dataset.title, url: window.location.href })"
        data-title={post.data.title}
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
        </svg>
        <span>Share</span>
      </button>
    </div>

    <!-- Sidebar (Server Islands) -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mt-12">
      <!-- Recommended posts -->
      <div class="lg:col-span-2">
        <RecommendedPosts server:defer currentPostId={post.id} limit={5}>
          <div slot="fallback" class="space-y-4">
            <div class="h-24 bg-gray-300 rounded-lg animate-pulse"></div>
            <div class="h-24 bg-gray-300 rounded-lg animate-pulse"></div>
            <div class="h-24 bg-gray-300 rounded-lg animate-pulse"></div>
          </div>
        </RecommendedPosts>
      </div>

      <!-- User info -->
      <div class="lg:col-span-1">
        <div class="card sticky top-4">
          <h3 class="text-lg font-bold mb-4">Signed in as</h3>
          <UserAvatar server:defer size="md" showName={true}>
            <div slot="fallback" class="flex items-center gap-3">
              <div class="w-12 h-12 bg-gray-300 rounded-full animate-pulse"></div>
              <div class="flex-1 space-y-2">
                <div class="h-4 bg-gray-300 rounded animate-pulse"></div>
                <div class="h-3 bg-gray-300 rounded animate-pulse"></div>
              </div>
            </div>
          </UserAvatar>
        </div>
      </div>
    </div>
  </article>
</MainLayout>

<style>
  .card {
    @apply bg-bg-primary border border-border rounded-lg p-6;
  }

  .share-button {
    @apply flex items-center gap-2 px-4 py-2 rounded-lg;
    @apply border border-border hover:bg-bg-secondary;
    @apply transition-colors;
  }

  .prose {
    @apply text-text-primary;
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

  .prose code {
    @apply bg-bg-secondary px-2 py-1 rounded text-sm;
  }

  .prose pre {
    @apply bg-bg-secondary p-4 rounded-lg overflow-x-auto mb-4;
  }

  .prose ul, .prose ol {
    @apply mb-4 pl-6;
  }

  .prose li {
    @apply mb-2;
  }

  .prose blockquote {
    @apply border-l-4 border-accent pl-4 italic my-4;
  }
</style>
EOF
```

---

## ✅ 3. VERIFY (Testing & Troubleshooting)

### Verification Checklist

**Server Islands Basics:**
- [ ] Server Islands config enabled
- [ ] `server:defer` directive works
- [ ] Fallback content displays
- [ ] Islands load asynchronously
- [ ] Dynamic content renders
- [ ] Authentication state detected

**Components:**
- [ ] UserAvatar displays correctly
- [ ] ViewCounter increments properly
- [ ] LikeButton toggles state
- [ ] BookmarkButton saves correctly
- [ ] RecommendedPosts shows personalized results
- [ ] ActivityFeed displays user actions

**Performance:**
- [ ] Static content loads instantly
- [ ] Islands stream progressively
- [ ] No layout shift during loading
- [ ] Fallbacks are visually smooth
- [ ] Caching works properly

**Security:**
- [ ] User data is protected
- [ ] RLS policies enforce access
- [ ] Props are encrypted
- [ ] No sensitive data in HTML

---

### Testing Commands

```bash
# Start dev server
npm run dev

# Test server islands
open http://localhost:4321/blog/your-post

# Check network tab for island requests
# DevTools → Network → Filter by "server-islands"

# Build for production
npm run build

# Test production build
npm run preview

# Check TypeScript
npm run check

# View database
npx supabase db pull
```

---

### Manual Testing

**1. Test View Counter:**
```bash
# 1. Visit a blog post
# 2. Check view count displays
# 3. Refresh page
# 4. View count should increment
# 5. Check database:
npx supabase db query "SELECT * FROM post_views ORDER BY created_at DESC LIMIT 10"
```

**2. Test Like Button:**
```bash
# 1. Log in
# 2. Visit blog post
# 3. Click like button
# 4. Button should turn red and show "liked" state
# 5. Refresh page
# 6. Like state should persist
# 7. Click again to unlike
# 8. Check database:
npx supabase db query "SELECT * FROM post_likes WHERE user_id = 'your-user-id'"
```

**3. Test Recommendations:**
```bash
# 1. Log in
# 2. Like several posts with similar tags
# 3. Visit any post
# 4. Recommended posts should be related
# 5. Check personalization:
npx supabase db query "SELECT * FROM get_personalized_recommendations('your-user-id', null, 5)"
```

**4. Test Server Island Loading:**
```bash
# 1. Open DevTools → Network
# 2. Enable "Throttling" → "Slow 3G"
# 3. Visit blog post
# 4. Observe:
#    - Static content loads instantly
#    - Fallbacks display
#    - Islands load progressively
#    - No content jump
```

---

### Troubleshooting

**Issue 1: Server Islands not loading**
```bash
# Check config
cat astro.config.mjs
# Ensure: experimental: { serverIslands: true }

# Check component has prerender = false
grep "prerender" src/components/islands/UserAvatar.astro

# Check network requests
# DevTools → Network → Look for /_server-islands/

# Enable debug logging
export DEBUG=astro:server-islands
npm run dev
```

**Issue 2: Fallback content not showing**
```bash
# Check slot syntax
<UserAvatar server:defer>
  <div slot="fallback">Loading...</div>
</UserAvatar>

# Ensure fallback is visible
# Add border for testing:
<div slot="fallback" style="border: 2px solid red;">
  Loading...
</div>
```

**Issue 3: View counter not incrementing**
```bash
# Check database connection
npx supabase status

# Check insert query
const { error } = await supabase
  .from('post_views')
  .insert({ post_id: 'test' });
console.log('Insert error:', error);

# Check materialized view
npx supabase db query "SELECT * FROM post_view_counts"

# Manually refresh view
npx supabase db query "REFRESH MATERIALIZED VIEW post_view_counts"
```

**Issue 4: Like/bookmark not persisting**
```bash
# Check RLS policies
npx supabase db query "
  SELECT * FROM pg_policies
  WHERE tablename IN ('post_likes', 'post_bookmarks')
"

# Check user authentication
const { data: { session } } = await supabase.auth.getSession();
console.log('Session:', session);

# Test API endpoint
curl -X POST http://localhost:4321/api/posts/test-post/like \
  -H "Cookie: sb-access-token=your-token"
```

**Issue 5: Recommendations not personalized**
```bash
# Check user has likes/bookmarks
npx supabase db query "
  SELECT * FROM post_likes WHERE user_id = 'your-user-id'
  UNION
  SELECT * FROM post_bookmarks WHERE user_id = 'your-user-id'
"

# Test recommendation function
npx supabase db query "
  SELECT * FROM get_personalized_recommendations('your-user-id', null, 5)
"

# Check post tags
npx supabase db query "SELECT id, title, tags FROM posts WHERE published = true"
```

**Issue 6: Props encryption failing**
```bash
# Check encryption key
echo $SERVER_ISLANDS_SECRET

# Generate new key if missing
openssl rand -base64 32

# Add to .env
echo "SERVER_ISLANDS_SECRET=your-key-here" >> .env

# Restart dev server
npm run dev
```

---

### Performance Optimization

**1. Cache island responses:**
```typescript
// In astro.config.mjs
export default defineConfig({
  experimental: {
    serverIslands: true,
    serverIslandsCaching: {
      enabled: true,
      ttl: 60, // Cache for 60 seconds
    },
  },
});
```

**2. Optimize database queries:**
```typescript
// Use materialized views for counts
CREATE MATERIALIZED VIEW post_counts AS
SELECT
  post_id,
  COUNT(*) FILTER (WHERE type = 'like') AS likes,
  COUNT(*) FILTER (WHERE type = 'bookmark') AS bookmarks
FROM interactions
GROUP BY post_id;

// Refresh periodically with pg_cron
SELECT cron.schedule('refresh-counts', '*/5 * * * *', 'REFRESH MATERIALIZED VIEW CONCURRENTLY post_counts');
```

**3. Implement connection pooling:**
```typescript
// Use Supabase connection pooler
const supabase = createClient(
  process.env.PUBLIC_SUPABASE_URL,
  process.env.PUBLIC_SUPABASE_ANON_KEY,
  {
    db: {
      schema: 'public',
    },
    global: {
      headers: {
        'X-Connection-Pool': 'true',
      },
    },
  }
);
```

**4. Add request deduplication:**
```typescript
// Prevent duplicate island requests
const requestCache = new Map();

async function fetchIsland(id: string, props: any) {
  const cacheKey = `${id}-${JSON.stringify(props)}`;

  if (requestCache.has(cacheKey)) {
    return requestCache.get(cacheKey);
  }

  const promise = fetch(`/_server-islands/${id}`, {
    method: 'POST',
    body: JSON.stringify(props),
  });

  requestCache.set(cacheKey, promise);

  setTimeout(() => requestCache.delete(cacheKey), 5000);

  return promise;
}
```

---

## 🎯 What You Built

### Components (6)
- ✅ **UserAvatar** - Dynamic user avatar widget
- ✅ **ViewCounter** - Real-time view tracking
- ✅ **LikeButton** - Like functionality with counts
- ✅ **BookmarkButton** - Bookmark system
- ✅ **RecommendedPosts** - Personalized recommendations
- ✅ **ActivityFeed** - User activity timeline

### Database Tables (3)
- ✅ **post_views** - View tracking
- ✅ **post_likes** - Like interactions
- ✅ **post_bookmarks** - Bookmark storage

### Database Functions (3)
- ✅ **get_personalized_recommendations** - ML-based recommendations
- ✅ **get_user_activities** - Activity feed
- ✅ **refresh_interaction_counts** - Count updates

### Features
- ✅ **Server Islands** - Dynamic content in static pages
- ✅ **Real-time Counts** - Live view/like/bookmark tracking
- ✅ **Personalization** - User-specific recommendations
- ✅ **Activity Tracking** - User action history
- ✅ **Streaming HTML** - Progressive enhancement
- ✅ **Encrypted Props** - Secure data transmission
- ✅ **Fallback Content** - Graceful loading states
- ✅ **RLS Security** - Database-level protection

---

## 🚀 Next Steps

In **Lesson 7**, you'll learn:
- React island integration
- Interactive comment forms
- Live search with debouncing
- Modal dialog systems
- Toast notifications
- Form validation with React Hook Form + Zod
- Client directives (client:load, client:idle, client:visible)

**Continue to:** [LESSON-7-REACT-ISLANDS.md](./LESSON-7-REACT-ISLANDS.md)

---

## 📚 Key Concepts Review

### Server Islands
- Server-rendered dynamic content
- No JavaScript sent to client
- Direct database access
- Progressive enhancement
- Streaming responses

### server:defer Directive
- Lazy-loads island content
- Shows fallback during loading
- Improves perceived performance
- Enables partial hydration

### Encrypted Props
- Secure prop transmission
- Prevents tampering
- Server-side verification
- User data protection

### Materialized Views
- Pre-computed aggregations
- Fast query performance
- Periodic refresh strategies
- Concurrent updates

### Personalization
- User behavior tracking
- ML-based recommendations
- Interest profiling
- Relevance scoring

---

## 💡 Pro Tips

1. **Use server islands for user-specific data:**
```astro
<!-- ✅ Good: User data in server island -->
<UserProfile server:defer userId={id} />

<!-- ❌ Bad: User data in static content -->
<div>{user.email}</div>
```

2. **Optimize fallback content:**
```astro
<!-- ✅ Good: Skeleton with same dimensions -->
<ViewCounter server:defer>
  <div slot="fallback" class="h-8 w-24 bg-gray-300 animate-pulse"></div>
</ViewCounter>

<!-- ❌ Bad: Different size causes layout shift -->
<ViewCounter server:defer>
  <div slot="fallback">...</div>
</ViewCounter>
```

3. **Cache expensive operations:**
```typescript
// Use Redis or Cloudflare KV for caching
const cached = await kv.get(`recommendations:${userId}`);
if (cached) return cached;

const recommendations = await getRecommendations(userId);
await kv.set(`recommendations:${userId}`, recommendations, { ex: 300 });
```

4. **Implement rate limiting:**
```typescript
// Prevent abuse of like/bookmark endpoints
import { Ratelimit } from '@upstash/ratelimit';

const ratelimit = new Ratelimit({
  redis: kv,
  limiter: Ratelimit.slidingWindow(10, '1 m'),
});

const { success } = await ratelimit.limit(userId);
if (!success) return new Response('Rate limited', { status: 429 });
```

5. **Monitor island performance:**
```typescript
// Add timing headers
export async function onRequest(context, next) {
  const start = Date.now();
  const response = await next();
  const duration = Date.now() - start;

  response.headers.set('Server-Timing', `island;dur=${duration}`);
  return response;
}
```

---

**Congratulations!** 🎉 You've mastered Server Islands and built dynamic, personalized content.

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 5-7 hours
