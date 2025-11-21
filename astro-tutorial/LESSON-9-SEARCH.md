# Astro 5.0 Tutorial - Lesson 9: Search & Filtering

**Prerequisites:** Completion of Lessons 1-8

---

## ✅ 1. DESC (Description)

### What You'll Learn

Build a powerful search system with PostgreSQL full-text search, advanced filtering, and client-side search capabilities.

**Core Concepts:**
- ✅ PostgreSQL full-text search
- ✅ GIN indexes and tsvector
- ✅ Search autocomplete/suggestions
- ✅ Advanced filter sidebar
- ✅ Search result highlighting
- ✅ Client-side search with Fuse.js
- ✅ Debounced search
- ✅ Search analytics
- ✅ Faceted search
- ✅ Search history

**What You'll Build:**
- Full-text search page
- Search autocomplete
- Filter sidebar (tags, date, author)
- Search result highlighting
- Search suggestions
- Recent searches
- Popular searches
- Search analytics dashboard

---

## ✅ 2. CODE (Implementation)

### STEP 1: Create Full-Text Search with PostgreSQL

\`\`\`bash
cat > supabase/migrations/013_create_fulltext_search.sql << 'EOF'
-- Add tsvector column for full-text search
ALTER TABLE posts ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Create function to update search vector
CREATE OR REPLACE FUNCTION posts_search_vector_update()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.excerpt, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(NEW.content, '')), 'C') ||
    setweight(to_tsvector('english', coalesce(array_to_string(NEW.tags, ' '), '')), 'B');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS posts_search_vector_trigger ON posts;
CREATE TRIGGER posts_search_vector_trigger
  BEFORE INSERT OR UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION posts_search_vector_update();

-- Update existing posts
UPDATE posts SET search_vector = 
  setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
  setweight(to_tsvector('english', coalesce(excerpt, '')), 'B') ||
  setweight(to_tsvector('english', coalesce(content, '')), 'C') ||
  setweight(to_tsvector('english', coalesce(array_to_string(tags, ' '), '')), 'B');

-- Create GIN index
CREATE INDEX IF NOT EXISTS idx_posts_search_vector ON posts USING GIN(search_vector);

-- Create search function
CREATE OR REPLACE FUNCTION search_posts_fulltext(
  search_query TEXT,
  filter_tags TEXT[] DEFAULT NULL,
  filter_author_id UUID DEFAULT NULL,
  filter_date_from TIMESTAMPTZ DEFAULT NULL,
  filter_date_to TIMESTAMPTZ DEFAULT NULL,
  result_limit INT DEFAULT 20,
  result_offset INT DEFAULT 0
)
RETURNS TABLE (
  id TEXT,
  title TEXT,
  excerpt TEXT,
  slug TEXT,
  tags TEXT[],
  published_at TIMESTAMPTZ,
  author_id UUID,
  author_name TEXT,
  relevance REAL,
  headline TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.title,
    p.excerpt,
    p.slug,
    p.tags,
    p.published_at,
    p.author_id,
    prof.full_name AS author_name,
    ts_rank(p.search_vector, plainto_tsquery('english', search_query)) AS relevance,
    ts_headline('english', p.title || ' ' || p.excerpt, plainto_tsquery('english', search_query),
      'StartSel=<mark>, StopSel=</mark>, MaxWords=50, MinWords=25') AS headline
  FROM posts p
  LEFT JOIN profiles prof ON p.author_id = prof.id
  WHERE
    p.published = true
    AND p.search_vector @@ plainto_tsquery('english', search_query)
    AND (filter_tags IS NULL OR p.tags && filter_tags)
    AND (filter_author_id IS NULL OR p.author_id = filter_author_id)
    AND (filter_date_from IS NULL OR p.published_at >= filter_date_from)
    AND (filter_date_to IS NULL OR p.published_at <= filter_date_to)
  ORDER BY relevance DESC, p.published_at DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create search suggestions function
CREATE OR REPLACE FUNCTION get_search_suggestions(
  partial_query TEXT,
  suggestion_limit INT DEFAULT 5
)
RETURNS TABLE (
  suggestion TEXT,
  type TEXT
) AS $$
BEGIN
  RETURN QUERY
  -- Title suggestions
  SELECT DISTINCT
    p.title AS suggestion,
    'title'::TEXT AS type
  FROM posts p
  WHERE
    p.published = true
    AND p.title ILIKE '%' || partial_query || '%'
  LIMIT suggestion_limit

  UNION ALL

  -- Tag suggestions
  SELECT DISTINCT
    unnest(p.tags) AS suggestion,
    'tag'::TEXT AS type
  FROM posts p
  WHERE
    p.published = true
    AND EXISTS (
      SELECT 1 FROM unnest(p.tags) AS tag
      WHERE tag ILIKE '%' || partial_query || '%'
    )
  LIMIT suggestion_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create search analytics table
CREATE TABLE IF NOT EXISTS search_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  query TEXT NOT NULL,
  results_count INT NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_search_analytics_query ON search_analytics(query);
CREATE INDEX idx_search_analytics_created_at ON search_analytics(created_at DESC);

-- Function to get popular searches
CREATE OR REPLACE FUNCTION get_popular_searches(
  time_period INTERVAL DEFAULT '7 days',
  result_limit INT DEFAULT 10
)
RETURNS TABLE (
  query TEXT,
  search_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    sa.query,
    COUNT(*) AS search_count
  FROM search_analytics sa
  WHERE sa.created_at >= NOW() - time_period
  GROUP BY sa.query
  ORDER BY search_count DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
EOF

npm run db:push
\`\`\`

---

### STEP 2: Create Search Page with Filters

\`\`\`bash
cat > src/pages/search.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import { createSupabaseServerClient } from '../lib/auth';
import SearchInterface from '../components/react/SearchInterface';

const supabase = createSupabaseServerClient(Astro.cookies);

// Get URL search params
const query = Astro.url.searchParams.get('q') || '';
const tags = Astro.url.searchParams.getAll('tag');
const author = Astro.url.searchParams.get('author');
const dateFrom = Astro.url.searchParams.get('from');
const dateTo = Astro.url.searchParams.get('to');

// Fetch all tags for filter
const { data: allPosts } = await supabase
  .from('posts')
  .select('tags')
  .eq('published', true);

const allTags = [...new Set(
  allPosts?.flatMap(p => p.tags || []) || []
)].sort();

// Fetch all authors
const { data: authors } = await supabase
  .from('profiles')
  .select('id, full_name')
  .order('full_name');

// Get search results if query exists
let results: any[] = [];
let totalResults = 0;

if (query && query.length >= 2) {
  const { data } = await supabase.rpc('search_posts_fulltext', {
    search_query: query,
    filter_tags: tags.length > 0 ? tags : null,
    filter_author_id: author || null,
    filter_date_from: dateFrom || null,
    filter_date_to: dateTo || null,
    result_limit: 20,
    result_offset: 0,
  });

  results = data || [];
  totalResults = results.length;

  // Track search
  if (totalResults >= 0) {
    await supabase.from('search_analytics').insert({
      query,
      results_count: totalResults,
    });
  }
}

// Get popular searches
const { data: popularSearches } = await supabase.rpc('get_popular_searches', {
  time_period: '7 days',
  result_limit: 10,
});
---

<MainLayout
  title={query ? \`Search: \${query}\` : 'Search'}
  description="Search blog posts"
>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
      <!-- Filters Sidebar -->
      <aside class="lg:col-span-1">
        <div class="sticky top-4 space-y-6">
          <div class="card">
            <h3 class="font-bold mb-4">Filters</h3>

            <form method="GET" class="space-y-4">
              <!-- Keep existing query -->
              <input type="hidden" name="q" value={query} />

              <!-- Tags Filter -->
              <div>
                <label class="block text-sm font-medium mb-2">
                  Tags
                </label>
                <div class="space-y-2 max-h-48 overflow-y-auto">
                  {allTags.map(tag => (
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="tag"
                        value={tag}
                        checked={tags.includes(tag)}
                        class="rounded"
                      />
                      <span class="text-sm">#{tag}</span>
                    </label>
                  ))}
                </div>
              </div>

              <!-- Author Filter -->
              <div>
                <label for="author" class="block text-sm font-medium mb-2">
                  Author
                </label>
                <select
                  id="author"
                  name="author"
                  class="input w-full"
                >
                  <option value="">All Authors</option>
                  {authors?.map(a => (
                    <option value={a.id} selected={author === a.id}>
                      {a.full_name}
                    </option>
                  ))}
                </select>
              </div>

              <!-- Date Range -->
              <div>
                <label for="from" class="block text-sm font-medium mb-2">
                  From Date
                </label>
                <input
                  type="date"
                  id="from"
                  name="from"
                  value={dateFrom || ''}
                  class="input w-full"
                />
              </div>

              <div>
                <label for="to" class="block text-sm font-medium mb-2">
                  To Date
                </label>
                <input
                  type="date"
                  id="to"
                  name="to"
                  value={dateTo || ''}
                  class="input w-full"
                />
              </div>

              <!-- Buttons -->
              <div class="flex gap-2">
                <button type="submit" class="btn-primary flex-1">
                  Apply
                </button>
                <a href="/search?q={query}" class="btn">
                  Clear
                </a>
              </div>
            </form>
          </div>

          <!-- Popular Searches -->
          {popularSearches && popularSearches.length > 0 && (
            <div class="card">
              <h3 class="font-bold mb-4">Popular Searches</h3>
              <div class="space-y-2">
                {popularSearches.map((search: any) => (
                  <a
                    href={\`/search?q=\${encodeURIComponent(search.query)}\`}
                    class="block text-sm text-accent hover:underline"
                  >
                    {search.query}
                  </a>
                ))}
              </div>
            </div>
          )}
        </div>
      </aside>

      <!-- Search Results -->
      <main class="lg:col-span-3">
        <SearchInterface
          client:load
          initialQuery={query}
          initialResults={results}
          totalResults={totalResults}
        />
      </main>
    </div>
  </div>
</MainLayout>

<style>
  .card {
    @apply bg-bg-primary border border-border rounded-lg p-6;
  }

  .input {
    @apply block w-full px-3 py-2 border border-border rounded-lg;
    @apply bg-bg-primary text-text-primary;
    @apply focus:ring-2 focus:ring-accent focus:border-transparent;
  }

  .btn {
    @apply px-4 py-2 rounded-lg font-medium text-center;
    @apply border border-border;
    @apply hover:bg-bg-secondary;
    @apply transition-colors;
  }

  .btn-primary {
    @apply px-4 py-2 rounded-lg font-medium;
    @apply bg-accent text-white;
    @apply hover:bg-accent/80;
    @apply transition-colors;
  }
</style>
EOF
\`\`\`

---

### STEP 3: Create Search Interface Component

\`\`\`bash
cat > src/components/react/SearchInterface.tsx << 'EOF'
import React, { useState } from 'react';
import { useDebounce } from 'use-debounce';

interface SearchResult {
  id: string;
  title: string;
  excerpt: string;
  slug: string;
  tags: string[];
  published_at: string;
  author_name: string;
  headline: string;
}

interface SearchInterfaceProps {
  initialQuery: string;
  initialResults: SearchResult[];
  totalResults: number;
}

export default function SearchInterface({
  initialQuery,
  initialResults,
  totalResults: initialTotal,
}: SearchInterfaceProps) {
  const [query, setQuery] = useState(initialQuery);
  const [debouncedQuery] = useDebounce(query, 300);
  const [results, setResults] = useState<SearchResult[]>(initialResults);
  const [totalResults, setTotalResults] = useState(initialTotal);
  const [isLoading, setIsLoading] = useState(false);

  // Fetch results when query changes
  React.useEffect(() => {
    if (debouncedQuery.length < 2) {
      setResults([]);
      setTotalResults(0);
      return;
    }

    const fetchResults = async () => {
      setIsLoading(true);

      try {
        const response = await fetch(
          \`/api/search?q=\${encodeURIComponent(debouncedQuery)}\`
        );

        if (!response.ok) throw new Error('Search failed');

        const data = await response.json();
        setResults(data.results || []);
        setTotalResults(data.total || 0);
      } catch (error) {
        console.error('Search error:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchResults();
  }, [debouncedQuery]);

  return (
    <div className="space-y-6">
      {/* Search Input */}
      <div className="relative">
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search posts..."
          className="input w-full pl-12 pr-4 text-lg"
          autoFocus
        />

        <div className="absolute left-4 top-1/2 -translate-y-1/2">
          {isLoading ? (
            <svg className="animate-spin h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
          ) : (
            <svg className="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          )}
        </div>
      </div>

      {/* Results Count */}
      {query && (
        <div className="text-sm text-gray-600 dark:text-gray-400">
          {totalResults === 0
            ? 'No results found'
            : \`Found \${totalResults} result\${totalResults === 1 ? '' : 's'}\`}
        </div>
      )}

      {/* Results */}
      {results.length > 0 ? (
        <div className="space-y-6">
          {results.map((result) => (
            <article
              key={result.id}
              className="card hover:border-accent/50 transition-colors"
            >
              <a href={\`/blog/\${result.slug}\`} className="block">
                <h2 className="text-2xl font-bold mb-2 text-gray-900 dark:text-gray-100">
                  {result.title}
                </h2>

                {result.headline && (
                  <div
                    className="text-gray-700 dark:text-gray-300 mb-3"
                    dangerouslySetInnerHTML={{ __html: result.headline }}
                  />
                )}

                <div className="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400">
                  <span>{result.author_name}</span>
                  <span>•</span>
                  <time>
                    {new Date(result.published_at).toLocaleDateString()}
                  </time>

                  {result.tags && result.tags.length > 0 && (
                    <>
                      <span>•</span>
                      <div className="flex gap-2">
                        {result.tags.slice(0, 3).map((tag) => (
                          <span
                            key={tag}
                            className="px-2 py-1 bg-accent/10 text-accent rounded-full text-xs"
                          >
                            #{tag}
                          </span>
                        ))}
                      </div>
                    </>
                  )}
                </div>
              </a>
            </article>
          ))}
        </div>
      ) : query && !isLoading ? (
        <div className="text-center py-12 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <svg
            className="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
          <h3 className="mt-2 text-sm font-medium">No results found</h3>
          <p className="mt-1 text-sm text-gray-500">
            Try adjusting your search or filters
          </p>
        </div>
      ) : null}
    </div>
  );
}
EOF
\`\`\`

---

## ✅ 3. VERIFY (Testing & Troubleshooting)

### Verification Checklist

**Search:**
- [ ] Full-text search works
- [ ] Results are relevant
- [ ] Highlighting displays correctly
- [ ] Filters apply correctly
- [ ] Pagination works
- [ ] Search analytics tracked

---

**Congratulations!** 🎉 You've built a comprehensive search system.

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 5-7 hours
