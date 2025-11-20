# Lesson 9: Search & Filtering with Full-Text Search

**Tutorial:** Next.js 16 + React 19.2 + Supabase - Complete Learning Path
**Focus:** Advanced search, filtering, and pagination
**Prerequisites:** Lessons 1-8 completed

---

## What You'll Build

In this lesson, you'll implement **powerful search and filtering** features to help users find tasks and projects quickly:

- ✅ **Full-Text Search** - PostgreSQL full-text search across multiple fields
- ✅ **Search Highlighting** - Highlight matching text in results
- ✅ **Advanced Filtering** - Multi-select filters (status, priority, members)
- ✅ **Date Range Filters** - Filter by creation date, due date, etc.
- ✅ **Debounced Search** - Optimize API calls with input debouncing
- ✅ **Pagination** - Cursor-based and offset-based pagination
- ✅ **Sorting** - Multiple sort options (relevance, date, name, priority)
- ✅ **Search Suggestions** - Auto-complete suggestions as user types
- ✅ **URL State Management** - Preserve filters in URL query params
- ✅ **Performance Optimization** - Database indexes for fast queries

### Technologies Used

- **PostgreSQL Full-Text Search** - tsvector, tsquery, ts_rank
- **GIN Indexes** - Fast full-text search indexing
- **URL Search Params** - Persistent filter state
- **React Hooks** - Custom hooks for search and filters
- **Next.js 16** - Server Actions with search parameters
- **Debouncing** - Optimize search input performance

---

## Architecture Overview

### Full-Text Search Flow

```
User Input: "urgent bug authentication"
                ↓
     [Debounce 300ms]
                ↓
     Convert to tsquery: 'urgent' & 'bug' & 'authentication'
                ↓
     PostgreSQL Query:
     WHERE search_vector @@ to_tsquery('urgent:* & bug:* & authentication:*')
     ORDER BY ts_rank(search_vector, query) DESC
                ↓
     Results ranked by relevance
```

### Search Vector Structure

```sql
-- Each row has a tsvector column with indexed text
search_vector = to_tsvector('english',
  coalesce(title, '') || ' ' ||
  coalesce(description, '') || ' ' ||
  coalesce(tags, '')
)

-- Indexed with GIN for fast lookups
CREATE INDEX idx_tasks_search ON prj_tasks USING GIN (search_vector);
```

---

## Step 1: Add Full-Text Search to Database

Create a migration to add search capabilities:

```bash
cat > supabase/migrations/006_full_text_search.sql << 'EOF'
-- ============================================================
-- LESSON 9: FULL-TEXT SEARCH & FILTERING
-- ============================================================

-- Add search vector column to prj_tasks
ALTER TABLE prj_tasks
ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Add search vector column to prj_projects
ALTER TABLE prj_projects
ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- ============================================================
-- UPDATE SEARCH VECTORS
-- ============================================================

-- Update existing tasks with search vectors
UPDATE prj_tasks
SET search_vector = to_tsvector('english',
  coalesce(title, '') || ' ' ||
  coalesce(description, '')
);

-- Update existing projects with search vectors
UPDATE prj_projects
SET search_vector = to_tsvector('english',
  coalesce(name, '') || ' ' ||
  coalesce(description, '')
);

-- ============================================================
-- TRIGGERS TO MAINTAIN SEARCH VECTORS
-- ============================================================

-- Function to update task search vector
CREATE OR REPLACE FUNCTION update_task_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.title, '') || ' ' ||
    coalesce(NEW.description, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for tasks
DROP TRIGGER IF EXISTS task_search_vector_update ON prj_tasks;
CREATE TRIGGER task_search_vector_update
  BEFORE INSERT OR UPDATE ON prj_tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_task_search_vector();

-- Function to update project search vector
CREATE OR REPLACE FUNCTION update_project_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    coalesce(NEW.name, '') || ' ' ||
    coalesce(NEW.description, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for projects
DROP TRIGGER IF EXISTS project_search_vector_update ON prj_projects;
CREATE TRIGGER project_search_vector_update
  BEFORE INSERT OR UPDATE ON prj_projects
  FOR EACH ROW
  EXECUTE FUNCTION update_project_search_vector();

-- ============================================================
-- GIN INDEXES FOR FAST FULL-TEXT SEARCH
-- ============================================================

-- Index for tasks
CREATE INDEX IF NOT EXISTS idx_tasks_search_vector
  ON prj_tasks USING GIN (search_vector);

-- Index for projects
CREATE INDEX IF NOT EXISTS idx_projects_search_vector
  ON prj_projects USING GIN (search_vector);

-- Additional indexes for filtering
CREATE INDEX IF NOT EXISTS idx_tasks_status_priority
  ON prj_tasks(status, priority);

CREATE INDEX IF NOT EXISTS idx_tasks_due_date
  ON prj_tasks(due_date) WHERE due_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_projects_status_dates
  ON prj_projects(status, start_date, end_date);

-- ============================================================
-- RPC FUNCTION: ADVANCED TASK SEARCH
-- ============================================================

CREATE OR REPLACE FUNCTION search_tasks(
  p_project_id UUID DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_status TEXT[] DEFAULT NULL,
  p_priority TEXT[] DEFAULT NULL,
  p_due_date_from TIMESTAMPTZ DEFAULT NULL,
  p_due_date_to TIMESTAMPTZ DEFAULT NULL,
  p_assigned_to UUID DEFAULT NULL,
  p_sort_by TEXT DEFAULT 'relevance',
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  project_id UUID,
  title TEXT,
  description TEXT,
  status VARCHAR(20),
  priority VARCHAR(20),
  due_date TIMESTAMPTZ,
  owner_id UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  relevance REAL
) AS $$
DECLARE
  search_tsquery tsquery;
BEGIN
  -- Convert search query to tsquery if provided
  IF p_search_query IS NOT NULL AND p_search_query <> '' THEN
    -- Add prefix matching with :* for partial word matches
    search_tsquery := to_tsquery('english',
      regexp_replace(trim(p_search_query), '\s+', ':* & ', 'g') || ':*'
    );
  END IF;

  RETURN QUERY
  SELECT
    t.id,
    t.project_id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.owner_id,
    t.created_at,
    t.updated_at,
    CASE
      WHEN search_tsquery IS NOT NULL THEN
        ts_rank(t.search_vector, search_tsquery)
      ELSE 0
    END AS relevance
  FROM prj_tasks t
  WHERE
    -- Project filter
    (p_project_id IS NULL OR t.project_id = p_project_id)
    -- Full-text search
    AND (search_tsquery IS NULL OR t.search_vector @@ search_tsquery)
    -- Status filter (array)
    AND (p_status IS NULL OR t.status = ANY(p_status))
    -- Priority filter (array)
    AND (p_priority IS NULL OR t.priority = ANY(p_priority))
    -- Due date range
    AND (p_due_date_from IS NULL OR t.due_date >= p_due_date_from)
    AND (p_due_date_to IS NULL OR t.due_date <= p_due_date_to)
    -- Assigned to filter
    AND (p_assigned_to IS NULL OR t.owner_id = p_assigned_to)
    -- RLS: User must be member of project
    AND EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = t.project_id
      AND pm.user_id = auth.uid()
    )
  ORDER BY
    CASE p_sort_by
      WHEN 'relevance' THEN ts_rank(t.search_vector, search_tsquery)
      ELSE 0
    END DESC,
    CASE p_sort_by
      WHEN 'date_desc' THEN t.created_at
    END DESC,
    CASE p_sort_by
      WHEN 'date_asc' THEN t.created_at
    END ASC,
    CASE p_sort_by
      WHEN 'priority' THEN
        CASE t.priority
          WHEN 'urgent' THEN 1
          WHEN 'high' THEN 2
          WHEN 'medium' THEN 3
          WHEN 'low' THEN 4
        END
    END ASC,
    CASE p_sort_by
      WHEN 'title' THEN t.title
    END ASC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- RPC FUNCTION: SEARCH SUGGESTIONS (AUTOCOMPLETE)
-- ============================================================

CREATE OR REPLACE FUNCTION search_task_suggestions(
  p_project_id UUID,
  p_partial_query TEXT,
  p_limit INT DEFAULT 5
)
RETURNS TABLE (
  suggestion TEXT,
  match_count INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.title AS suggestion,
    COUNT(*)::INT AS match_count
  FROM prj_tasks t
  WHERE
    t.project_id = p_project_id
    AND t.title ILIKE '%' || p_partial_query || '%'
    AND EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = t.project_id
      AND pm.user_id = auth.uid()
    )
  GROUP BY t.title
  ORDER BY match_count DESC, t.title
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- RPC FUNCTION: GET TASK COUNT (FOR PAGINATION)
-- ============================================================

CREATE OR REPLACE FUNCTION count_tasks(
  p_project_id UUID DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_status TEXT[] DEFAULT NULL,
  p_priority TEXT[] DEFAULT NULL,
  p_due_date_from TIMESTAMPTZ DEFAULT NULL,
  p_due_date_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
  search_tsquery tsquery;
  task_count INT;
BEGIN
  IF p_search_query IS NOT NULL AND p_search_query <> '' THEN
    search_tsquery := to_tsquery('english',
      regexp_replace(trim(p_search_query), '\s+', ':* & ', 'g') || ':*'
    );
  END IF;

  SELECT COUNT(*)
  INTO task_count
  FROM prj_tasks t
  WHERE
    (p_project_id IS NULL OR t.project_id = p_project_id)
    AND (search_tsquery IS NULL OR t.search_vector @@ search_tsquery)
    AND (p_status IS NULL OR t.status = ANY(p_status))
    AND (p_priority IS NULL OR t.priority = ANY(p_priority))
    AND (p_due_date_from IS NULL OR t.due_date >= p_due_date_from)
    AND (p_due_date_to IS NULL OR t.due_date <= p_due_date_to)
    AND EXISTS (
      SELECT 1 FROM prj_project_members pm
      WHERE pm.project_id = t.project_id
      AND pm.user_id = auth.uid()
    );

  RETURN task_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

EOF
```

**Run migration:**

```bash
# Using Supabase CLI
supabase db push

# Or run SQL in Supabase Dashboard → SQL Editor
```

---

## Step 2: Configure Next.js 16 Cache Components

Enable Cache Components in Next.js configuration:

```bash
cat > next.config.ts << 'EOF'
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    // Enable Next.js 16 Cache Components
    cacheComponents: true,
  },
};

export default nextConfig;
EOF
```

**Why Cache Components for Search?**

Search and filtering are perfect use cases for intelligent caching:
- **Search results change infrequently** - Most queries return stable results
- **Filters are reusable** - Same filter combinations are often reused
- **Database queries are expensive** - Full-text search with PostgreSQL is CPU-intensive
- **User experience** - Cached results load instantly

**Cache Strategy:**
```typescript
// ✅ GOOD: Cache search results with query-specific tags
async function SearchResults({ query }: { query: string }) {
  'use cache'
  cacheLife('hours')
  cacheTag('task-search')
  cacheTag(`task-search-${query}`) // Query-specific
  cacheTag('tasks') // Invalidate when tasks change

  const results = await searchTasks(query)
  return <ResultsList results={results} />
}

// ❌ BAD: Don't cache interactive filters (Client Components)
'use client'
function SearchFilters() {
  // Client-side state management - no caching
}
```

---

## Step 3: Extend Constants for Search

Add search and filter constants:

```bash
cat >> src/constants/index.ts << 'EOF'

// ============================================================
// SEARCH & FILTER CONSTANTS (Lesson 9)
// ============================================================

export const SEARCH_CONFIG = {
  DEBOUNCE_DELAY: 300, // milliseconds
  MIN_SEARCH_LENGTH: 2,
  MAX_SUGGESTIONS: 5,
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,
} as const;

export const SORT_OPTIONS = {
  RELEVANCE: 'relevance',
  DATE_DESC: 'date_desc',
  DATE_ASC: 'date_asc',
  PRIORITY: 'priority',
  TITLE: 'title',
} as const;

export const SORT_LABELS: Record<string, string> = {
  [SORT_OPTIONS.RELEVANCE]: 'Most Relevant',
  [SORT_OPTIONS.DATE_DESC]: 'Newest First',
  [SORT_OPTIONS.DATE_ASC]: 'Oldest First',
  [SORT_OPTIONS.PRIORITY]: 'By Priority',
  [SORT_OPTIONS.TITLE]: 'Alphabetical',
};

export const FILTER_OPERATORS = {
  EQUALS: 'eq',
  NOT_EQUALS: 'neq',
  IN: 'in',
  NOT_IN: 'nin',
  GREATER_THAN: 'gt',
  LESS_THAN: 'lt',
  CONTAINS: 'contains',
} as const;

// Type exports
export type SortOption = typeof SORT_OPTIONS[keyof typeof SORT_OPTIONS];
export type FilterOperator = typeof FILTER_OPERATORS[keyof typeof FILTER_OPERATORS];

EOF
```

---

## Step 4: Create Search Utilities

Create utilities for search and debouncing:

```bash
mkdir -p src/utils/search
cat > src/utils/search/debounce.ts << 'EOF'
/**
 * Debounce function to limit how often a function is called
 * Useful for search inputs to avoid excessive API calls
 */
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timeoutId: NodeJS.Timeout;

  return function (this: any, ...args: Parameters<T>) {
    clearTimeout(timeoutId);

    timeoutId = setTimeout(() => {
      func.apply(this, args);
    }, delay);
  };
}

/**
 * Debounced async function with cancel support
 */
export function debounceAsync<T extends (...args: any[]) => Promise<any>>(
  func: T,
  delay: number
): {
  execute: (...args: Parameters<T>) => Promise<ReturnType<T>>;
  cancel: () => void;
} {
  let timeoutId: NodeJS.Timeout;
  let resolveList: Array<(value: any) => void> = [];

  const cancel = () => {
    clearTimeout(timeoutId);
    resolveList.forEach((resolve) => resolve(undefined));
    resolveList = [];
  };

  const execute = (...args: Parameters<T>): Promise<ReturnType<T>> => {
    return new Promise((resolve) => {
      clearTimeout(timeoutId);
      resolveList.push(resolve);

      timeoutId = setTimeout(async () => {
        const result = await func(...args);
        resolveList.forEach((res) => res(result));
        resolveList = [];
      }, delay);
    });
  };

  return { execute, cancel };
}

EOF
```

Create search highlighting utility:

```bash
cat > src/utils/search/highlight.ts << 'EOF'
/**
 * Highlight search terms in text
 * Returns text with <mark> tags around matching terms
 */
export function highlightSearchTerms(text: string, searchQuery: string): string {
  if (!searchQuery || searchQuery.trim() === '') {
    return text;
  }

  const terms = searchQuery
    .trim()
    .split(/\s+/)
    .filter((term) => term.length > 0);

  let highlighted = text;

  terms.forEach((term) => {
    const regex = new RegExp(`(${escapeRegex(term)})`, 'gi');
    highlighted = highlighted.replace(regex, '<mark class="bg-yellow-200">$1</mark>');
  });

  return highlighted;
}

/**
 * Escape special regex characters
 */
function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Component-safe highlight (returns array of elements)
 */
export function getHighlightedParts(text: string, searchQuery: string): Array<{
  text: string;
  highlighted: boolean;
}> {
  if (!searchQuery || searchQuery.trim() === '') {
    return [{ text, highlighted: false }];
  }

  const terms = searchQuery
    .trim()
    .split(/\s+/)
    .filter((term) => term.length > 0);

  const regex = new RegExp(`(${terms.map(escapeRegex).join('|')})`, 'gi');
  const parts = text.split(regex);

  return parts
    .filter((part) => part.length > 0)
    .map((part) => ({
      text: part,
      highlighted: terms.some((term) => part.toLowerCase() === term.toLowerCase()),
    }));
}

EOF
```

---

## Step 5: Create Cached Search Server Components

First, create Server Actions that invalidate search caches:

```bash
cat >> src/lib/actions/tasks.ts << 'EOF'

// ============================================================
// SEARCH & FILTERING (Lesson 9)
// ============================================================

import { updateTag } from 'next/cache';

/**
 * Search tasks with advanced filtering
 * NOTE: This is called from Server Components with 'use cache'
 */
export async function searchTasks(params: {
  projectId?: string;
  searchQuery?: string;
  status?: string[];
  priority?: string[];
  dueDateFrom?: string;
  dueDateTo?: string;
  assignedTo?: string;
  sortBy?: string;
  page?: number;
  pageSize?: number;
}) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    const {
      projectId,
      searchQuery,
      status,
      priority,
      dueDateFrom,
      dueDateTo,
      assignedTo,
      sortBy = 'relevance',
      page = 1,
      pageSize = 20,
    } = params;

    const offset = (page - 1) * pageSize;

    // Call RPC function for advanced search
    const { data, error } = await supabase.rpc('search_tasks', {
      p_project_id: projectId || null,
      p_search_query: searchQuery || null,
      p_status: status || null,
      p_priority: priority || null,
      p_due_date_from: dueDateFrom || null,
      p_due_date_to: dueDateTo || null,
      p_assigned_to: assignedTo || null,
      p_sort_by: sortBy,
      p_limit: pageSize,
      p_offset: offset,
    });

    if (error) {
      console.error('Search tasks error:', error);
      return { success: false, error: error.message };
    }

    // Get total count for pagination
    const { data: countData } = await supabase.rpc('count_tasks', {
      p_project_id: projectId || null,
      p_search_query: searchQuery || null,
      p_status: status || null,
      p_priority: priority || null,
      p_due_date_from: dueDateFrom || null,
      p_due_date_to: dueDateTo || null,
    });

    const totalCount = countData || 0;
    const totalPages = Math.ceil(totalCount / pageSize);

    return {
      success: true,
      data,
      pagination: {
        page,
        pageSize,
        totalCount,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  } catch (error: any) {
    console.error('Search tasks error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Get search suggestions (autocomplete)
 * NOTE: Called from cached Server Component
 */
export async function getTaskSuggestions(projectId: string, partialQuery: string) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    if (!partialQuery || partialQuery.length < 2) {
      return { success: true, data: [] };
    }

    const { data, error } = await supabase.rpc('search_task_suggestions', {
      p_project_id: projectId,
      p_partial_query: partialQuery,
      p_limit: 5,
    });

    if (error) {
      console.error('Get suggestions error:', error);
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (error: any) {
    console.error('Get suggestions error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * EXAMPLE: Create task with cache invalidation
 * This shows how to invalidate search caches when data changes
 */
export async function createTaskWithCacheInvalidation(input: {
  project_id: string;
  title: string;
  description?: string;
  status?: string;
  priority?: string;
}) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    // Create task
    const { data, error } = await supabase
      .from('prj_tasks')
      .insert({
        ...input,
        owner_id: user.id,
      })
      .select()
      .single();

    if (error) {
      return { success: false, error: error.message };
    }

    // ✅ Invalidate search caches
    updateTag('tasks'); // All task lists
    updateTag('task-search'); // All search results
    updateTag(`project-${input.project_id}-tasks`); // Project-specific tasks

    return { success: true, data };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

/**
 * EXAMPLE: Update task with cache invalidation
 */
export async function updateTaskWithCacheInvalidation(
  taskId: string,
  updates: Partial<{
    title: string;
    description: string;
    status: string;
    priority: string;
  }>
) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    // Get project_id before update
    const { data: task } = await supabase
      .from('prj_tasks')
      .select('project_id')
      .eq('id', taskId)
      .single();

    // Update task
    const { data, error } = await supabase
      .from('prj_tasks')
      .update(updates)
      .eq('id', taskId)
      .select()
      .single();

    if (error) {
      return { success: false, error: error.message };
    }

    // ✅ Invalidate search caches
    updateTag('tasks');
    updateTag('task-search'); // All search results need refresh
    if (task?.project_id) {
      updateTag(`project-${task.project_id}-tasks`);
    }
    updateTag(`task-${taskId}`); // Specific task cache

    return { success: true, data };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

/**
 * EXAMPLE: Delete task with cache invalidation
 */
export async function deleteTaskWithCacheInvalidation(taskId: string) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    // Get project_id before delete
    const { data: task } = await supabase
      .from('prj_tasks')
      .select('project_id')
      .eq('id', taskId)
      .single();

    // Delete task
    const { error } = await supabase
      .from('prj_tasks')
      .delete()
      .eq('id', taskId);

    if (error) {
      return { success: false, error: error.message };
    }

    // ✅ Invalidate search caches
    updateTag('tasks');
    updateTag('task-search'); // All search results
    if (task?.project_id) {
      updateTag(`project-${task.project_id}-tasks`);
    }

    return { success: true };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

EOF
```

Now create **cached Server Components** for search results:

```bash
mkdir -p src/components/features/search
cat > src/components/features/search/TaskSearchResults.tsx << 'EOF'
import { Suspense } from 'react';
import { searchTasks } from '@/lib/actions/tasks';
import { TaskCard } from '@/components/features/tasks/TaskCard';
import type { Database } from '@/lib/types/database';

type Task = Database['public']['Tables']['prj_tasks']['Row'] & {
  relevance?: number;
};

type TaskSearchResultsProps = {
  projectId?: string;
  searchQuery?: string;
  status?: string[];
  priority?: string[];
  sortBy?: string;
  page?: number;
};

/**
 * Cached Server Component for search results
 * This component is cached and re-used for identical search queries
 */
async function TaskSearchResults({
  projectId,
  searchQuery,
  status,
  priority,
  sortBy = 'relevance',
  page = 1,
}: TaskSearchResultsProps) {
  'use cache';

  // Cache for 1 hour - search results change infrequently
  cacheLife('hours');

  // Multiple cache tags for fine-grained invalidation
  cacheTag('task-search'); // All search results
  cacheTag('tasks'); // Invalidate when any task changes

  // Query-specific cache tags
  if (searchQuery) {
    cacheTag(`task-search-${searchQuery}`);
  }

  // Filter-specific cache tags
  if (status && status.length > 0) {
    cacheTag(`task-filter-status-${status.sort().join('-')}`);
  }
  if (priority && priority.length > 0) {
    cacheTag(`task-filter-priority-${priority.sort().join('-')}`);
  }

  // Project-specific cache tag
  if (projectId) {
    cacheTag(`project-${projectId}-tasks`);
  }

  const result = await searchTasks({
    projectId,
    searchQuery,
    status,
    priority,
    sortBy,
    page,
    pageSize: 20,
  });

  if (!result.success || !result.data) {
    return (
      <div className="text-center py-8 text-red-500">
        Error: {result.error || 'Failed to load search results'}
      </div>
    );
  }

  const { data: tasks, pagination } = result;

  if (tasks.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        No tasks found. Try adjusting your search or filters.
      </div>
    );
  }

  return (
    <>
      <div className="text-sm text-gray-600 mb-4">
        Showing {tasks.length} of {pagination?.totalCount || 0} results
        {searchQuery && ` for "${searchQuery}"`}
      </div>

      <div className="grid gap-4">
        {tasks.map((task) => (
          <TaskCard key={task.id} task={task} showRelevance={!!searchQuery} />
        ))}
      </div>

      {pagination && pagination.totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-6">
          <div className="text-sm text-gray-600">
            Page {pagination.page} of {pagination.totalPages}
          </div>
        </div>
      )}
    </>
  );
}

/**
 * Skeleton loader for search results
 */
function SearchResultsSkeleton() {
  return (
    <div className="space-y-4">
      {[1, 2, 3].map((i) => (
        <div key={i} className="border rounded-lg p-4 animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-3/4 mb-2"></div>
          <div className="h-4 bg-gray-200 rounded w-full mb-2"></div>
          <div className="h-4 bg-gray-200 rounded w-2/3"></div>
        </div>
      ))}
    </div>
  );
}

/**
 * Export with Suspense boundary
 */
export function CachedTaskSearchResults(props: TaskSearchResultsProps) {
  return (
    <Suspense fallback={<SearchResultsSkeleton />}>
      <TaskSearchResults {...props} />
    </Suspense>
  );
}

EOF
```

Create cached autocomplete suggestions component:

```bash
cat > src/components/features/search/TaskAutocomplete.tsx << 'EOF'
import { Suspense } from 'react';
import { getTaskSuggestions } from '@/lib/actions/tasks';

type TaskAutocompleteProps = {
  projectId: string;
  query: string;
  onSelect: (suggestion: string) => void;
};

/**
 * Cached Server Component for autocomplete suggestions
 * Cached with shorter duration since autocomplete is more dynamic
 */
async function TaskAutocomplete({
  projectId,
  query,
  onSelect,
}: TaskAutocompleteProps) {
  'use cache';

  // Shorter cache for autocomplete - 5 minutes
  cacheLife('minutes');

  // Cache tags
  cacheTag('task-autocomplete');
  cacheTag(`autocomplete-${query}`);
  cacheTag(`project-${projectId}-autocomplete`);

  const result = await getTaskSuggestions(projectId, query);

  if (!result.success || !result.data || result.data.length === 0) {
    return null;
  }

  return (
    <div className="absolute z-10 mt-1 w-full bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto">
      {result.data.map((item, index) => (
        <button
          key={index}
          onClick={() => onSelect(item.suggestion)}
          className="w-full text-left px-4 py-2 hover:bg-gray-100"
        >
          {item.suggestion}
        </button>
      ))}
    </div>
  );
}

/**
 * Skeleton loader for autocomplete
 */
function AutocompleteSkeleton() {
  return (
    <div className="absolute z-10 mt-1 w-full bg-white border border-gray-300 rounded-md shadow-lg">
      <div className="px-4 py-2 animate-pulse">
        <div className="h-4 bg-gray-200 rounded"></div>
      </div>
    </div>
  );
}

/**
 * Export with Suspense boundary
 */
export function CachedTaskAutocomplete(props: TaskAutocompleteProps) {
  return (
    <Suspense fallback={<AutocompleteSkeleton />}>
      <TaskAutocomplete {...props} />
    </Suspense>
  );
}

EOF
```

**Key Points:**

1. **`'use cache'` directive** - Marks component as cacheable
2. **`cacheLife('hours')`** - Search results cached for 1 hour
3. **`cacheLife('minutes')`** - Autocomplete cached for 5 minutes (more dynamic)
4. **Multiple cache tags** - Fine-grained invalidation:
   - `task-search` - Invalidates all search results
   - `task-search-${query}` - Invalidates specific query
   - `task-filter-${type}-${values}` - Invalidates specific filter combinations
   - `project-${id}-tasks` - Invalidates project-specific caches
5. **Suspense boundaries** - Provides loading states during cache misses

---

## Step 6: Create useSearch Hook

Create a custom hook for search functionality:

```bash
mkdir -p src/hooks/search
cat > src/hooks/search/useSearch.ts << 'EOF'
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';
import { debounce } from '@/utils/search/debounce';
import { SEARCH_CONFIG } from '@/constants';

type UseSearchOptions = {
  onSearch?: (query: string) => void;
  minLength?: number;
  debounceDelay?: number;
  syncWithUrl?: boolean;
};

/**
 * Hook for managing search input with debouncing and URL sync
 *
 * @example
 * ```tsx
 * const { searchQuery, setSearchQuery, debouncedQuery } = useSearch({
 *   onSearch: (query) => console.log('Search:', query),
 *   syncWithUrl: true,
 * });
 * ```
 */
export function useSearch(options: UseSearchOptions = {}) {
  const {
    onSearch,
    minLength = SEARCH_CONFIG.MIN_SEARCH_LENGTH,
    debounceDelay = SEARCH_CONFIG.DEBOUNCE_DELAY,
    syncWithUrl = true,
  } = options;

  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const [searchQuery, setSearchQuery] = useState(
    syncWithUrl ? searchParams.get('q') || '' : ''
  );
  const [debouncedQuery, setDebouncedQuery] = useState(searchQuery);

  // Debounced search handler
  const debouncedSearch = useCallback(
    debounce((query: string) => {
      setDebouncedQuery(query);
      onSearch?.(query);

      // Update URL if enabled
      if (syncWithUrl) {
        const params = new URLSearchParams(searchParams);
        if (query && query.length >= minLength) {
          params.set('q', query);
        } else {
          params.delete('q');
        }
        router.push(`${pathname}?${params.toString()}`, { scroll: false });
      }
    }, debounceDelay),
    [onSearch, syncWithUrl, pathname, searchParams, minLength, debounceDelay]
  );

  // Trigger debounced search when query changes
  useEffect(() => {
    debouncedSearch(searchQuery);
  }, [searchQuery, debouncedSearch]);

  const clearSearch = useCallback(() => {
    setSearchQuery('');
    setDebouncedQuery('');
  }, []);

  return {
    searchQuery,
    setSearchQuery,
    debouncedQuery,
    clearSearch,
    isSearching: searchQuery !== debouncedQuery,
  };
}

EOF
```

---

## Step 7: Create useFilters Hook

Create a hook for managing filters:

```bash
cat > src/hooks/search/useFilters.ts << 'EOF'
'use client';

import { useState, useCallback } from 'react';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';

type FilterValue = string | string[] | null;

type Filters = Record<string, FilterValue>;

type UseFiltersOptions = {
  initialFilters?: Filters;
  syncWithUrl?: boolean;
  onFilterChange?: (filters: Filters) => void;
};

/**
 * Hook for managing filters with URL sync
 *
 * @example
 * ```tsx
 * const { filters, setFilter, clearFilter, clearAllFilters } = useFilters({
 *   initialFilters: { status: null, priority: null },
 *   syncWithUrl: true,
 * });
 *
 * setFilter('status', ['todo', 'in_progress']);
 * ```
 */
export function useFilters(options: UseFiltersOptions = {}) {
  const {
    initialFilters = {},
    syncWithUrl = true,
    onFilterChange,
  } = options;

  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // Initialize filters from URL or defaults
  const getInitialFilters = useCallback(() => {
    if (!syncWithUrl) return initialFilters;

    const urlFilters: Filters = { ...initialFilters };

    searchParams.forEach((value, key) => {
      if (key !== 'q' && key !== 'page') {
        // Handle array values (comma-separated)
        if (value.includes(',')) {
          urlFilters[key] = value.split(',');
        } else {
          urlFilters[key] = value;
        }
      }
    });

    return urlFilters;
  }, [initialFilters, searchParams, syncWithUrl]);

  const [filters, setFilters] = useState<Filters>(getInitialFilters);

  // Update URL with current filters
  const updateUrl = useCallback(
    (newFilters: Filters) => {
      if (!syncWithUrl) return;

      const params = new URLSearchParams(searchParams);

      // Clear existing filter params
      Array.from(params.keys()).forEach((key) => {
        if (key !== 'q' && key !== 'page') {
          params.delete(key);
        }
      });

      // Set new filter params
      Object.entries(newFilters).forEach(([key, value]) => {
        if (value !== null && value !== undefined && value !== '') {
          const stringValue = Array.isArray(value) ? value.join(',') : String(value);
          params.set(key, stringValue);
        }
      });

      router.push(`${pathname}?${params.toString()}`, { scroll: false });
    },
    [syncWithUrl, pathname, searchParams, router]
  );

  // Set a single filter
  const setFilter = useCallback(
    (key: string, value: FilterValue) => {
      const newFilters = { ...filters, [key]: value };
      setFilters(newFilters);
      updateUrl(newFilters);
      onFilterChange?.(newFilters);
    },
    [filters, updateUrl, onFilterChange]
  );

  // Clear a single filter
  const clearFilter = useCallback(
    (key: string) => {
      const newFilters = { ...filters, [key]: null };
      setFilters(newFilters);
      updateUrl(newFilters);
      onFilterChange?.(newFilters);
    },
    [filters, updateUrl, onFilterChange]
  );

  // Clear all filters
  const clearAllFilters = useCallback(() => {
    const clearedFilters = Object.keys(filters).reduce((acc, key) => {
      acc[key] = null;
      return acc;
    }, {} as Filters);

    setFilters(clearedFilters);
    updateUrl(clearedFilters);
    onFilterChange?.(clearedFilters);
  }, [filters, updateUrl, onFilterChange]);

  // Check if any filters are active
  const hasActiveFilters = Object.values(filters).some(
    (value) => value !== null && value !== undefined && value !== ''
  );

  return {
    filters,
    setFilter,
    clearFilter,
    clearAllFilters,
    hasActiveFilters,
  };
}

EOF
```

---

## Step 8: Create Search Input Component

Create a search input with suggestions:

**Note:** This is a **Client Component** for interactivity. It updates the URL via `useSearch` hook, which causes the parent Server Component to re-render with cached results. The `onSearch` callback is optional and used for custom handling.

```bash
mkdir -p src/components/features/search
cat > src/components/features/search/SearchInput.tsx << 'EOF'
'use client';

import { useState, useEffect, useRef } from 'react';
import { useSearch } from '@/hooks/search/useSearch';
import { getTaskSuggestions } from '@/lib/actions/tasks';
import { SEARCH_CONFIG } from '@/constants';

type SearchInputProps = {
  projectId: string;
  onSearch: (query: string) => void;
  placeholder?: string;
  showSuggestions?: boolean;
};

/**
 * Search input with autocomplete suggestions
 */
export function SearchInput({
  projectId,
  onSearch,
  placeholder = 'Search tasks...',
  showSuggestions = true,
}: SearchInputProps) {
  const { searchQuery, setSearchQuery, debouncedQuery, clearSearch, isSearching } = useSearch({
    onSearch,
    syncWithUrl: true,
  });

  const [suggestions, setSuggestions] = useState<Array<{ suggestion: string }>>([]);
  const [showSuggestionsList, setShowSuggestionsList] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);

  // Fetch suggestions when query changes
  useEffect(() => {
    const fetchSuggestions = async () => {
      if (
        !showSuggestions ||
        !debouncedQuery ||
        debouncedQuery.length < SEARCH_CONFIG.MIN_SEARCH_LENGTH
      ) {
        setSuggestions([]);
        return;
      }

      const result = await getTaskSuggestions(projectId, debouncedQuery);
      if (result.success && result.data) {
        setSuggestions(result.data);
        setShowSuggestionsList(true);
      }
    };

    fetchSuggestions();
  }, [debouncedQuery, projectId, showSuggestions]);

  // Handle keyboard navigation
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!showSuggestionsList || suggestions.length === 0) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((prev) => Math.min(prev + 1, suggestions.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((prev) => Math.max(prev - 1, -1));
    } else if (e.key === 'Enter' && selectedIndex >= 0) {
      e.preventDefault();
      setSearchQuery(suggestions[selectedIndex].suggestion);
      setShowSuggestionsList(false);
    } else if (e.key === 'Escape') {
      setShowSuggestionsList(false);
    }
  };

  return (
    <div className="relative">
      <div className="relative">
        {/* Search Icon */}
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <svg
            className="h-5 w-5 text-gray-400"
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
        </div>

        {/* Input */}
        <input
          ref={inputRef}
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          onFocus={() => setShowSuggestionsList(suggestions.length > 0)}
          placeholder={placeholder}
          className="block w-full pl-10 pr-12 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
        />

        {/* Loading/Clear Button */}
        {searchQuery && (
          <div className="absolute inset-y-0 right-0 pr-3 flex items-center">
            {isSearching ? (
              <svg className="animate-spin h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24">
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
            ) : (
              <button
                onClick={clearSearch}
                className="text-gray-400 hover:text-gray-600"
              >
                <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            )}
          </div>
        )}
      </div>

      {/* Suggestions Dropdown */}
      {showSuggestionsList && suggestions.length > 0 && (
        <div className="absolute z-10 mt-1 w-full bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto">
          {suggestions.map((item, index) => (
            <button
              key={index}
              onClick={() => {
                setSearchQuery(item.suggestion);
                setShowSuggestionsList(false);
              }}
              className={`w-full text-left px-4 py-2 hover:bg-gray-100 ${
                index === selectedIndex ? 'bg-gray-100' : ''
              }`}
            >
              {item.suggestion}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

EOF
```

---

## Step 9: Create Filter Components

Create multi-select filter component:

```bash
cat > src/components/features/search/MultiSelectFilter.tsx << 'EOF'
'use client';

import { useState, useRef, useEffect } from 'react';

type Option = {
  value: string;
  label: string;
};

type MultiSelectFilterProps = {
  label: string;
  options: Option[];
  value: string[];
  onChange: (values: string[]) => void;
};

/**
 * Multi-select dropdown filter
 */
export function MultiSelectFilter({ label, options, value, onChange }: MultiSelectFilterProps) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const toggleOption = (optionValue: string) => {
    if (value.includes(optionValue)) {
      onChange(value.filter((v) => v !== optionValue));
    } else {
      onChange([...value, optionValue]);
    }
  };

  const selectedLabels = options
    .filter((opt) => value.includes(opt.value))
    .map((opt) => opt.label)
    .join(', ');

  return (
    <div ref={dropdownRef} className="relative">
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
      </label>

      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="w-full px-3 py-2 border border-gray-300 rounded-md text-left bg-white hover:bg-gray-50 flex items-center justify-between"
      >
        <span className="truncate">
          {selectedLabels || `Select ${label.toLowerCase()}...`}
        </span>
        <svg
          className={`h-5 w-5 text-gray-400 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-10 mt-1 w-full bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto">
          {options.map((option) => (
            <label
              key={option.value}
              className="flex items-center px-4 py-2 hover:bg-gray-100 cursor-pointer"
            >
              <input
                type="checkbox"
                checked={value.includes(option.value)}
                onChange={() => toggleOption(option.value)}
                className="h-4 w-4 text-blue-600 rounded border-gray-300 focus:ring-blue-500"
              />
              <span className="ml-2 text-sm text-gray-700">{option.label}</span>
            </label>
          ))}
        </div>
      )}
    </div>
  );
}

EOF
```

---

## Step 10: Create Task Search Page with Caching

Create a search page that uses cached Server Components:

```bash
cat > src/app/dashboard/tasks/search/page.tsx << 'EOF'
import { Suspense } from 'react';
import { SearchInput } from '@/components/features/search/SearchInput';
import { SearchFiltersClient } from '@/components/features/search/SearchFiltersClient';
import { CachedTaskSearchResults } from '@/components/features/search/TaskSearchResults';
import {
  TASK_STATUS_LABELS,
  TASK_PRIORITY_LABELS,
  SORT_OPTIONS,
  SORT_LABELS,
} from '@/constants';

type SearchPageProps = {
  searchParams: {
    q?: string;
    projectId?: string;
    status?: string;
    priority?: string;
    sortBy?: string;
    page?: string;
  };
};

/**
 * Search page - Server Component with cached results
 * This is a Server Component that passes URL params to cached child components
 */
export default function TaskSearchPage({ searchParams }: SearchPageProps) {
  // Parse URL parameters
  const query = searchParams.q || undefined;
  const projectId = searchParams.projectId || undefined;
  const status = searchParams.status?.split(',') || undefined;
  const priority = searchParams.priority?.split(',') || undefined;
  const sortBy = searchParams.sortBy || SORT_OPTIONS.RELEVANCE;
  const page = parseInt(searchParams.page || '1', 10);

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold">Search Tasks</h1>
        <p className="text-gray-600">Find tasks with advanced search and filters</p>
      </div>

      {/* Search Input - Client Component for interactivity */}
      <SearchInput
        projectId={projectId || ''}
        placeholder="Search tasks..."
        showSuggestions={!!projectId}
      />

      {/* Filters - Client Component for interactivity */}
      <SearchFiltersClient
        statusOptions={Object.entries(TASK_STATUS_LABELS).map(([value, label]) => ({
          value,
          label,
        }))}
        priorityOptions={Object.entries(TASK_PRIORITY_LABELS).map(([value, label]) => ({
          value,
          label,
        }))}
        sortOptions={Object.entries(SORT_LABELS).map(([value, label]) => ({
          value,
          label,
        }))}
        currentStatus={status}
        currentPriority={priority}
        currentSortBy={sortBy}
      />

      {/*
        Cached Search Results - Server Component with 'use cache'
        This component is automatically cached and reused for identical queries
        When tasks change, updateTag('task-search') invalidates all search caches
      */}
      <CachedTaskSearchResults
        projectId={projectId}
        searchQuery={query}
        status={status}
        priority={priority}
        sortBy={sortBy}
        page={page}
      />
    </div>
  );
}

EOF
```

Create the Client Component for filters:

```bash
cat > src/components/features/search/SearchFiltersClient.tsx << 'EOF'
'use client';

import { MultiSelectFilter } from './MultiSelectFilter';
import { useFilters } from '@/hooks/search/useFilters';
import { SORT_OPTIONS } from '@/constants';

type Option = {
  value: string;
  label: string;
};

type SearchFiltersClientProps = {
  statusOptions: Option[];
  priorityOptions: Option[];
  sortOptions: Option[];
  currentStatus?: string[];
  currentPriority?: string[];
  currentSortBy?: string;
};

/**
 * Client Component for interactive filters
 * This handles user interactions and updates URL params
 */
export function SearchFiltersClient({
  statusOptions,
  priorityOptions,
  sortOptions,
  currentStatus = [],
  currentPriority = [],
  currentSortBy = SORT_OPTIONS.RELEVANCE,
}: SearchFiltersClientProps) {
  const { filters, setFilter, clearAllFilters, hasActiveFilters } = useFilters({
    initialFilters: {
      status: currentStatus,
      priority: currentPriority,
      sortBy: currentSortBy,
    },
    syncWithUrl: true,
  });

  return (
    <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
      <MultiSelectFilter
        label="Status"
        options={statusOptions}
        value={(filters.status as string[]) || []}
        onChange={(values) => setFilter('status', values)}
      />

      <MultiSelectFilter
        label="Priority"
        options={priorityOptions}
        value={(filters.priority as string[]) || []}
        onChange={(values) => setFilter('priority', values)}
      />

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Sort By
        </label>
        <select
          value={(filters.sortBy as string) || SORT_OPTIONS.RELEVANCE}
          onChange={(e) => setFilter('sortBy', e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md"
        >
          {sortOptions.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>

      {hasActiveFilters && (
        <div className="flex items-end">
          <button
            onClick={clearAllFilters}
            className="w-full px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
          >
            Clear Filters
          </button>
        </div>
      )}
    </div>
  );
}

EOF
```

**Architecture Explanation:**

```
┌─────────────────────────────────────────────────────────────┐
│ TaskSearchPage (Server Component)                           │
│ - Reads URL search params                                   │
│ - No caching at this level                                  │
└──────────────┬──────────────────────────────────────────────┘
               │
               ├── SearchInput (Client Component)
               │   └── Interactive search with debouncing
               │
               ├── SearchFiltersClient (Client Component)
               │   └── Interactive filters, updates URL
               │
               └── CachedTaskSearchResults (Server Component)
                   └── 'use cache' + cacheLife('hours')
                   └── Cached by query + filters
                   └── Invalidated by updateTag('task-search')
```

**Why This Architecture?**

1. **Parent is Server Component** - Fast initial render, SEO-friendly
2. **Interactive UI is Client** - SearchInput and filters need user interaction
3. **Results are Cached Server Component** - Heavy database queries are cached
4. **URL as source of truth** - Shareable links, browser back/forward works
5. **Fine-grained invalidation** - Only invalidate affected caches

---

## Understanding Search Caching Strategy

### Why Cache Search Results?

Search and filtering are **perfect candidates for caching** because:

1. **Search results are stable** - A query for "urgent bug" will return similar results over time
2. **Queries are repeated** - Users often search for the same terms
3. **Database queries are expensive** - PostgreSQL full-text search with `ts_rank` is CPU-intensive
4. **User experience** - Instant results feel magical

### Cache Duration Strategy

Different types of search content have different cache durations:

```typescript
// ✅ Search Results - Cache for 1 hour
'use cache'
cacheLife('hours')  // Results change infrequently

// ✅ Autocomplete - Cache for 5 minutes
'use cache'
cacheLife('minutes')  // More dynamic, shorter cache

// ❌ Interactive Filters - No caching
'use client'  // Client-side state, not cacheable
```

### Cache Tag Strategy

Use **multiple cache tags** for fine-grained invalidation:

```typescript
async function TaskSearchResults({ query, status, priority, projectId }) {
  'use cache'
  cacheLife('hours')

  // Global tags - invalidate ALL search results
  cacheTag('tasks')          // When any task changes
  cacheTag('task-search')    // When search needs refresh

  // Query-specific tags - invalidate specific queries
  cacheTag(`task-search-${query}`)  // Only this query

  // Filter-specific tags - invalidate specific filter combinations
  cacheTag(`task-filter-status-${status.sort().join('-')}`)
  cacheTag(`task-filter-priority-${priority.sort().join('-')}`)

  // Project-specific tags - invalidate project caches
  cacheTag(`project-${projectId}-tasks`)

  // ... fetch and return results
}
```

### Cache Invalidation Strategy

When tasks are created, updated, or deleted:

```typescript
export async function createTask(input) {
  // ... create task in database

  // ✅ Invalidate multiple cache tags
  updateTag('tasks')              // Invalidate ALL task lists
  updateTag('task-search')        // Invalidate ALL search results
  updateTag(`project-${projectId}-tasks`)  // Project-specific

  // This ensures:
  // 1. All search results reflect the new task
  // 2. Project-specific views update
  // 3. Global task lists update
  // 4. Filter combinations update automatically
}
```

### Trade-offs: Cache Freshness vs Performance

| Approach | Freshness | Performance | Best For |
|----------|-----------|-------------|----------|
| **No caching** | Always fresh | Slow | Real-time data |
| **Short cache (5 min)** | Very fresh | Fast | Autocomplete |
| **Medium cache (1 hour)** | Fresh enough | Very fast | Search results |
| **Long cache (1 day)** | Stale possible | Instant | Static content |

**Our Choice:** 1 hour cache with tag-based invalidation
- Fresh enough for most use cases
- Instant for cache hits
- Invalidated immediately when data changes

### Query-Specific vs Global Invalidation

**Query-Specific Tags:**
```typescript
cacheTag(`task-search-${query}`)
// Only invalidates searches for "urgent bug"
// Other searches remain cached
```

**Global Tags:**
```typescript
updateTag('task-search')
// Invalidates ALL search results
// Use when underlying data changes
```

**Filter-Specific Tags:**
```typescript
cacheTag(`task-filter-status-${status.sort().join('-')}`)
// Only invalidates this specific filter combination
// status=['todo','in_progress'] vs status=['done']
```

### When to Invalidate

| Action | Tags to Invalidate | Why |
|--------|-------------------|-----|
| **Create task** | `tasks`, `task-search`, `project-X-tasks` | New task appears in all views |
| **Update task** | `tasks`, `task-search`, `task-X`, `project-X-tasks` | Task details changed |
| **Delete task** | `tasks`, `task-search`, `project-X-tasks` | Task removed from all views |
| **Update status** | `tasks`, `task-search`, `task-filter-status-*` | Affects status filters |
| **Update priority** | `tasks`, `task-search`, `task-filter-priority-*` | Affects priority filters |

### Caching Best Practices

1. **✅ Cache expensive queries** - Full-text search, joins, aggregations
2. **✅ Use multiple tags** - Enable fine-grained invalidation
3. **✅ Normalize tag values** - Sort arrays before creating tags
4. **✅ Wrap in Suspense** - Provide loading states during cache misses
5. **❌ Don't cache user-specific data** - Unless tagged by user ID
6. **❌ Don't cache real-time data** - Chat messages, live updates
7. **❌ Don't cache forms** - Interactive UI should be Client Components

---

## Verification Steps

### 1. Test Full-Text Search

**Browser:**
1. Go to search page: `http://localhost:3000/dashboard/tasks/search`
2. Type "bug authentication"
3. **Expected:** Tasks containing "bug" OR "authentication" appear ✅
4. **Expected:** Results ranked by relevance (both words > one word) ✅

### 2. Test Debouncing

**Browser DevTools:**
1. Open Network tab
2. Type search query character by character: "t-e-s-t"
3. **Expected:** Only ONE API call after 300ms delay ✅
4. **Expected:** No call for every character ✅

### 3. Test Filters

**Browser:**
1. Select Status: "To Do", "In Progress"
2. Select Priority: "High", "Urgent"
3. **Expected:** Only tasks matching ALL filters appear ✅
4. Click "Clear Filters"
5. **Expected:** All tasks appear again ✅

### 4. Test Pagination

**Browser:**
1. Perform search with 25+ results
2. **Expected:** Shows "Page 1 of 2" ✅
3. Click "Next"
4. **Expected:** Shows page 2 results, URL updated with `?page=2` ✅

### 5. Test URL State

**Browser:**
1. Set search query: "urgent"
2. Set filters: status=todo, priority=high
3. Copy URL
4. Open URL in new tab
5. **Expected:** Same search query and filters applied ✅

### 6. Test Cache Components

**Browser DevTools:**
1. Open React DevTools
2. Perform search: "urgent bug"
3. **Expected:** See `TaskSearchResults` Server Component ✅
4. **Expected:** Component shows as cached on second load ✅

**Next.js Terminal:**
1. Watch server logs during search
2. First search: See database query logs
3. Second identical search: No database query (cache hit!) ✅

### 7. Test Cache Invalidation

**Browser:**
1. Search for "bug" - note results count
2. Create a new task with "bug" in title
3. Search for "bug" again
4. **Expected:** New task appears immediately (cache invalidated) ✅

**How it works:**
```typescript
// When task is created:
createTaskWithCacheInvalidation()
  ↓
updateTag('task-search')  // Invalidates all search caches
  ↓
Next search fetches fresh data
```

### 8. Test Suspense Boundaries

**Browser with Throttled Network:**
1. DevTools → Network → Slow 3G
2. Perform search query
3. **Expected:** See skeleton loader during fetch ✅
4. **Expected:** Smooth transition to results ✅

### 9. Test Query-Specific Cache Tags

**Next.js Cache Debug (add to next.config.ts):**
```typescript
const nextConfig: NextConfig = {
  experimental: {
    cacheComponents: true,
  },
  logging: {
    fetches: {
      fullUrl: true,
    },
  },
};
```

1. Search for "bug" (creates cache entry with tag `task-search-bug`)
2. Search for "urgent" (creates separate cache entry with tag `task-search-urgent`)
3. **Expected:** Two separate cache entries ✅

### 10. Verify Database Performance

**Supabase Dashboard → SQL Editor:**

```sql
EXPLAIN ANALYZE
SELECT *
FROM prj_tasks
WHERE search_vector @@ to_tsquery('english', 'bug:* & auth:*')
ORDER BY ts_rank(search_vector, to_tsquery('english', 'bug:* & auth:*')) DESC;
```

**Expected:** Query uses GIN index (fast) ✅

---

## What You Learned

### Database & Search
✅ **PostgreSQL Full-Text Search** - tsvector, tsquery, ts_rank
✅ **GIN Indexes** - Fast full-text search performance
✅ **Search Highlighting** - Show matching terms in results
✅ **Autocomplete** - Search suggestions as user types

### Next.js 16 Cache Components
✅ **'use cache' directive** - Mark Server Components as cacheable
✅ **cacheLife() API** - Set cache duration (minutes, hours, days)
✅ **cacheTag() API** - Tag caches for fine-grained invalidation
✅ **updateTag() API** - Invalidate specific cache tags
✅ **Suspense boundaries** - Loading states during cache misses
✅ **Cache strategy** - When to cache, how long, what to invalidate

### Advanced Patterns
✅ **Debouncing** - Optimize API calls for search inputs
✅ **Advanced Filtering** - Multi-select, date ranges, combinations
✅ **Pagination** - Offset-based with total count
✅ **URL State Management** - Persist filters in URL for sharing
✅ **Query-specific caching** - Cache each query independently
✅ **Filter-specific caching** - Cache each filter combination
✅ **Type Safety** - TypeScript for search parameters

### Architecture
✅ **Server Component caching** - Cache expensive database queries
✅ **Client Component interactivity** - Keep UI interactive
✅ **Mixed component architecture** - Server + Client composition
✅ **Tag-based invalidation** - Global vs query-specific invalidation

---

## Next Steps

**Lesson 10 Preview:** Deployment to Vercel
- Environment variables setup
- Database migrations in production
- Vercel deployment configuration
- Custom domain setup
- Performance monitoring
- Error tracking
- Production best practices

**Continue to:** `LESSON-10-PRACTICAL-GUIDE.md`

---

## Reference

**Files Created/Modified:**
- `next.config.ts` - **NEW** Cache Components configuration
- `supabase/migrations/006_full_text_search.sql` - Full-text search setup
- `src/constants/index.ts` - Search constants (EXTENDED)
- `src/utils/search/debounce.ts` - Debounce utilities
- `src/utils/search/highlight.ts` - Search highlighting
- `src/lib/actions/tasks.ts` - **UPDATED** Search Server Actions with cache invalidation
- `src/hooks/search/useSearch.ts` - Search hook with debouncing
- `src/hooks/search/useFilters.ts` - Filters hook with URL sync
- `src/components/features/search/SearchInput.tsx` - Interactive search input
- `src/components/features/search/MultiSelectFilter.tsx` - Multi-select filter
- `src/components/features/search/TaskSearchResults.tsx` - **NEW** Cached search results Server Component
- `src/components/features/search/TaskAutocomplete.tsx` - **NEW** Cached autocomplete Server Component
- `src/components/features/search/SearchFiltersClient.tsx` - **NEW** Interactive filters Client Component
- `src/app/dashboard/tasks/search/page.tsx` - **UPDATED** Search page with cached components

**Key Concepts:**

### Database & Search
- Full-text search vectors (tsvector)
- Search queries (tsquery)
- Relevance ranking (ts_rank)
- GIN indexes for performance
- RPC functions for advanced queries

### Next.js 16 Caching
- `'use cache'` directive for Server Components
- `cacheLife()` - Set cache duration
- `cacheTag()` - Tag caches for invalidation
- `updateTag()` - Invalidate specific tags
- Suspense boundaries for loading states

### Patterns & Architecture
- Query-specific cache tags (`task-search-${query}`)
- Filter-specific cache tags (`task-filter-status-${values}`)
- Global cache invalidation (`updateTag('task-search')`)
- Mixed Server/Client component architecture
- Debouncing for user input
- URL as state management

**Important APIs:**

```typescript
// Cache Components APIs
'use cache'                    // Mark component as cacheable
cacheLife('minutes' | 'hours') // Set cache duration
cacheTag('tag-name')           // Tag for invalidation
updateTag('tag-name')          // Invalidate tagged caches

// Suspense for loading states
<Suspense fallback={<Skeleton />}>
  <CachedComponent />
</Suspense>
```

**External Resources:**
- **PostgreSQL Full-Text Search:** https://www.postgresql.org/docs/current/textsearch.html
- **Next.js 16 Caching:** https://nextjs.org/docs/app/api-reference/directives/use-cache
- **React Suspense:** https://react.dev/reference/react/Suspense
