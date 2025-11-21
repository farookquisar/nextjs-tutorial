# Astro 5.0 Tutorial - Lesson 7: React Islands & Interactivity

**Prerequisites:** Completion of Lessons 1-6, React knowledge helpful

---

## ✅ 1. DESC (Description)

### What You'll Learn

In this lesson, you'll integrate React into your Astro project using the Islands architecture, creating interactive components that enhance user experience without sacrificing performance.

**Core Concepts:**
- ✅ React integration in Astro
- ✅ Client directives (client:load, client:idle, client:visible, client:only)
- ✅ Partial hydration strategies
- ✅ Component props sharing
- ✅ React state management
- ✅ Form handling with React Hook Form
- ✅ Validation with Zod
- ✅ Modal dialogs and portals
- ✅ Toast notifications
- ✅ Debouncing and throttling
- ✅ Custom hooks
- ✅ Context providers

**What You'll Build:**
- Interactive comment form with validation
- Live search with autocomplete
- Modal dialog system
- Toast notification system
- Image carousel/gallery
- Accordion/tabs components
- Form wizard with steps
- Rich text editor integration
- File upload with preview
- Infinite scroll component
- Keyboard shortcuts handler
- Drag and drop interface

---

### Islands Architecture Explained

**Traditional SPA approach:**
```
❌ Entire app is JavaScript
❌ Bundle size: 500KB+
❌ Time to Interactive: 3-5s
❌ Hydration overhead: All components
```

**Astro Islands approach:**
```
✅ HTML-first, JS-second
✅ Bundle size: 50KB (only interactive parts)
✅ Time to Interactive: <1s
✅ Hydration: Only necessary components
```

**Visual representation:**
```
┌─────────────────────────────────────┐
│  Static HTML (Astro)                │
│  ┌──────────┐                       │
│  │ React    │  ← Island 1 (Modal)   │
│  │ Island   │                       │
│  └──────────┘                       │
│                                     │
│  Static content here...             │
│                                     │
│  ┌──────────┐    ┌──────────┐     │
│  │ React    │    │ React    │     │
│  │ Island   │    │ Island   │     │
│  └──────────┘    └──────────┘     │
│   ↑ Island 2      ↑ Island 3      │
│   (Search)        (Comments)       │
└─────────────────────────────────────┘
```

---

### Client Directives

**Astro provides 5 client directives for controlling hydration:**

| Directive | When it loads | Use case |
|-----------|--------------|----------|
| `client:load` | On page load | Critical interactive UI |
| `client:idle` | After page load | Non-critical interactions |
| `client:visible` | When in viewport | Below-fold content |
| `client:media` | Media query match | Responsive components |
| `client:only` | Client-side only | No SSR needed |

**Examples:**

```astro
<!-- Load immediately (critical) -->
<SearchBar client:load />

<!-- Load when browser idle (recommended for most) -->
<CommentForm client:idle />

<!-- Load when scrolled into view (below fold) -->
<ImageCarousel client:visible />

<!-- Load on mobile only -->
<MobileMenu client:media="(max-width: 768px)" />

<!-- Never server-render (browser APIs) -->
<WebGLAnimation client:only="react" />
```

---

### When to Use React Islands

**Use React islands for:**
- ✅ Forms with complex validation
- ✅ Interactive data tables
- ✅ Real-time search
- ✅ Modals and dialogs
- ✅ Drag and drop interfaces
- ✅ Charts and visualizations
- ✅ Rich text editors
- ✅ File uploads
- ✅ WebSocket connections
- ✅ Browser-specific features

**Use Astro components for:**
- ❌ Static content
- ❌ Navigation
- ❌ Footers/headers
- ❌ Blog post content
- ❌ SEO-critical content
- ❌ Simple buttons/links

---

## ✅ 2. CODE (Implementation)

### STEP 1: Install React Dependencies

```bash
# React is already installed from earlier lessons, but let's add additional packages

npm install react-hook-form zod @hookform/resolvers
npm install react-hot-toast framer-motion
npm install @headlessui/react
npm install @tiptap/react @tiptap/starter-kit
npm install react-dropzone
npm install use-debounce

# Install types
npm install -D @types/react @types/react-dom

# Verify React integration
cat > src/test-react.astro << 'EOF'
---
import { useState } from 'react';

// Simple test component
function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
---

<Counter client:load />
EOF
```

---

### STEP 2: Create Comment Form with Validation

**Zod schema for validation:**

```bash
cat > src/lib/schemas.ts << 'EOF'
import { z } from 'zod';

export const commentSchema = z.object({
  name: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(50, 'Name must be less than 50 characters'),
  email: z
    .string()
    .email('Invalid email address')
    .min(1, 'Email is required'),
  comment: z
    .string()
    .min(10, 'Comment must be at least 10 characters')
    .max(1000, 'Comment must be less than 1000 characters'),
  parentId: z.string().uuid().optional(),
  postId: z.string().min(1, 'Post ID is required'),
});

export type CommentFormData = z.infer<typeof commentSchema>;

export const replySchema = commentSchema.omit({ name: true, email: true });

export const profileSchema = z.object({
  fullName: z.string().min(2).max(100),
  bio: z.string().max(500).optional(),
  website: z.string().url().optional().or(z.literal('')),
  avatar: z
    .instanceof(File)
    .refine((file) => file.size <= 2 * 1024 * 1024, 'File must be less than 2MB')
    .refine(
      (file) => ['image/jpeg', 'image/png', 'image/webp'].includes(file.type),
      'File must be JPEG, PNG, or WebP'
    )
    .optional(),
});

export const searchSchema = z.object({
  query: z.string().min(2).max(100),
  filters: z.object({
    tags: z.array(z.string()).optional(),
    dateFrom: z.string().optional(),
    dateTo: z.string().optional(),
    author: z.string().optional(),
  }).optional(),
});
EOF
```

**Comment form component:**

```bash
cat > src/components/react/CommentForm.tsx << 'EOF'
import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { commentSchema, type CommentFormData } from '../../lib/schemas';
import toast from 'react-hot-toast';

interface CommentFormProps {
  postId: string;
  parentId?: string;
  onSuccess?: () => void;
  onCancel?: () => void;
}

export function CommentForm({
  postId,
  parentId,
  onSuccess,
  onCancel,
}: CommentFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<CommentFormData>({
    resolver: zodResolver(commentSchema),
    defaultValues: {
      postId,
      parentId,
    },
  });

  const onSubmit = async (data: CommentFormData) => {
    setIsSubmitting(true);

    try {
      const response = await fetch('/api/comments', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Failed to submit comment');
      }

      toast.success('Comment submitted successfully!');
      reset();
      onSuccess?.();
    } catch (error) {
      console.error('Error submitting comment:', error);
      toast.error(
        error instanceof Error ? error.message : 'Failed to submit comment'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      {/* Name field */}
      <div>
        <label
          htmlFor="name"
          className="block text-sm font-medium mb-2"
        >
          Name *
        </label>
        <input
          {...register('name')}
          type="text"
          id="name"
          className="input w-full"
          placeholder="Your name"
          disabled={isSubmitting}
        />
        {errors.name && (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">
            {errors.name.message}
          </p>
        )}
      </div>

      {/* Email field */}
      <div>
        <label
          htmlFor="email"
          className="block text-sm font-medium mb-2"
        >
          Email *
        </label>
        <input
          {...register('email')}
          type="email"
          id="email"
          className="input w-full"
          placeholder="your@email.com"
          disabled={isSubmitting}
        />
        {errors.email && (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">
            {errors.email.message}
          </p>
        )}
        <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
          Your email will not be published
        </p>
      </div>

      {/* Comment field */}
      <div>
        <label
          htmlFor="comment"
          className="block text-sm font-medium mb-2"
        >
          Comment *
        </label>
        <textarea
          {...register('comment')}
          id="comment"
          rows={5}
          className="input w-full"
          placeholder="Share your thoughts..."
          disabled={isSubmitting}
        />
        {errors.comment && (
          <p className="mt-1 text-sm text-red-600 dark:text-red-400">
            {errors.comment.message}
          </p>
        )}
      </div>

      {/* Hidden fields */}
      <input {...register('postId')} type="hidden" />
      {parentId && <input {...register('parentId')} type="hidden" />}

      {/* Buttons */}
      <div className="flex items-center gap-3">
        <button
          type="submit"
          disabled={isSubmitting}
          className="btn-primary"
        >
          {isSubmitting ? 'Submitting...' : 'Submit Comment'}
        </button>

        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            disabled={isSubmitting}
            className="btn"
          >
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}
EOF
```

**Add global styles for React components:**

```bash
cat >> src/styles/global.css << 'EOF'

/* React component styles */
.input {
  @apply block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg;
  @apply bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100;
  @apply focus:ring-2 focus:ring-blue-500 focus:border-transparent;
  @apply transition-colors;
  @apply disabled:opacity-50 disabled:cursor-not-allowed;
}

.btn {
  @apply px-4 py-2 rounded-lg font-medium;
  @apply border border-gray-300 dark:border-gray-600;
  @apply bg-white dark:bg-gray-800;
  @apply hover:bg-gray-50 dark:hover:bg-gray-700;
  @apply transition-colors;
  @apply disabled:opacity-50 disabled:cursor-not-allowed;
}

.btn-primary {
  @apply px-4 py-2 rounded-lg font-medium;
  @apply bg-blue-600 text-white;
  @apply hover:bg-blue-700;
  @apply transition-colors;
  @apply disabled:opacity-50 disabled:cursor-not-allowed;
}

.btn-danger {
  @apply px-4 py-2 rounded-lg font-medium;
  @apply bg-red-600 text-white;
  @apply hover:bg-red-700;
  @apply transition-colors;
  @apply disabled:opacity-50 disabled:cursor-not-allowed;
}
EOF
```

---

### STEP 3: Create Live Search Component

```bash
cat > src/components/react/LiveSearch.tsx << 'EOF'
import React, { useState, useEffect, useRef } from 'react';
import { useDebounce } from 'use-debounce';

interface SearchResult {
  id: string;
  title: string;
  excerpt: string;
  slug: string;
  type: 'post' | 'page';
}

interface LiveSearchProps {
  placeholder?: string;
  minChars?: number;
  debounceMs?: number;
}

export function LiveSearch({
  placeholder = 'Search...',
  minChars = 2,
  debounceMs = 300,
}: LiveSearchProps) {
  const [query, setQuery] = useState('');
  const [debouncedQuery] = useDebounce(query, debounceMs);
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const searchRef = useRef<HTMLDivElement>(null);

  // Fetch results when debounced query changes
  useEffect(() => {
    if (debouncedQuery.length < minChars) {
      setResults([]);
      setIsOpen(false);
      return;
    }

    const fetchResults = async () => {
      setIsLoading(true);

      try {
        const response = await fetch(
          `/api/search?q=${encodeURIComponent(debouncedQuery)}`
        );

        if (!response.ok) {
          throw new Error('Search failed');
        }

        const data = await response.json();
        setResults(data.results || []);
        setIsOpen(true);
      } catch (error) {
        console.error('Search error:', error);
        setResults([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchResults();
  }, [debouncedQuery, minChars]);

  // Handle keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!isOpen || results.length === 0) return;

      switch (e.key) {
        case 'ArrowDown':
          e.preventDefault();
          setSelectedIndex((prev) =>
            prev < results.length - 1 ? prev + 1 : prev
          );
          break;
        case 'ArrowUp':
          e.preventDefault();
          setSelectedIndex((prev) => (prev > 0 ? prev - 1 : -1));
          break;
        case 'Enter':
          e.preventDefault();
          if (selectedIndex >= 0) {
            window.location.href = `/blog/${results[selectedIndex].slug}`;
          }
          break;
        case 'Escape':
          setIsOpen(false);
          setSelectedIndex(-1);
          break;
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, results, selectedIndex]);

  // Handle click outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (
        searchRef.current &&
        !searchRef.current.contains(e.target as Node)
      ) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const highlightMatch = (text: string, query: string) => {
    const parts = text.split(new RegExp(`(${query})`, 'gi'));
    return (
      <>
        {parts.map((part, i) =>
          part.toLowerCase() === query.toLowerCase() ? (
            <mark key={i} className="bg-yellow-200 dark:bg-yellow-800">
              {part}
            </mark>
          ) : (
            part
          )
        )}
      </>
    );
  };

  return (
    <div ref={searchRef} className="relative w-full max-w-2xl">
      {/* Search input */}
      <div className="relative">
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => query.length >= minChars && setIsOpen(true)}
          placeholder={placeholder}
          className="input w-full pl-10 pr-4"
          aria-label="Search"
          aria-autocomplete="list"
          aria-controls="search-results"
          aria-expanded={isOpen}
        />

        {/* Search icon */}
        <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
          {isLoading ? (
            <svg
              className="animate-spin h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
            >
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
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
          )}
        </div>

        {/* Clear button */}
        {query && (
          <button
            type="button"
            onClick={() => {
              setQuery('');
              setResults([]);
              setIsOpen(false);
            }}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
            aria-label="Clear search"
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

      {/* Results dropdown */}
      {isOpen && (
        <div
          id="search-results"
          className="absolute top-full mt-2 w-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg max-h-96 overflow-y-auto z-50"
          role="listbox"
        >
          {results.length > 0 ? (
            <ul className="py-2">
              {results.map((result, index) => (
                <li key={result.id} role="option" aria-selected={index === selectedIndex}>
                  <a
                    href={`/blog/${result.slug}`}
                    className={`block px-4 py-3 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors ${
                      index === selectedIndex
                        ? 'bg-gray-100 dark:bg-gray-700'
                        : ''
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      {/* Type icon */}
                      <div className="mt-1">
                        {result.type === 'post' ? (
                          <svg className="h-5 w-5 text-blue-500" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M9 4.804A7.968 7.968 0 005.5 4c-1.255 0-2.443.29-3.5.804v10A7.969 7.969 0 015.5 14c1.669 0 3.218.51 4.5 1.385A7.962 7.962 0 0114.5 14c1.255 0 2.443.29 3.5.804v-10A7.968 7.968 0 0014.5 4c-1.255 0-2.443.29-3.5.804V12a1 1 0 11-2 0V4.804z" />
                          </svg>
                        ) : (
                          <svg className="h-5 w-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clipRule="evenodd" />
                          </svg>
                        )}
                      </div>

                      {/* Content */}
                      <div className="flex-1 min-w-0">
                        <h4 className="font-semibold text-gray-900 dark:text-gray-100 mb-1">
                          {highlightMatch(result.title, query)}
                        </h4>
                        {result.excerpt && (
                          <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                            {highlightMatch(result.excerpt, query)}
                          </p>
                        )}
                      </div>
                    </div>
                  </a>
                </li>
              ))}
            </ul>
          ) : (
            <div className="px-4 py-8 text-center text-gray-500 dark:text-gray-400">
              {isLoading ? (
                'Searching...'
              ) : query.length < minChars ? (
                `Type at least ${minChars} characters to search`
              ) : (
                'No results found'
              )}
            </div>
          )}

          {/* Footer */}
          {results.length > 0 && (
            <div className="border-t border-gray-200 dark:border-gray-700 px-4 py-2">
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Use ↑↓ to navigate, Enter to select, Esc to close
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
EOF

# Create search API endpoint
cat > src/pages/api/search.ts << 'EOF'
import type { APIRoute } from 'astro';
import { createSupabaseServerClient } from '../../lib/auth';

export const GET: APIRoute = async ({ url, cookies }) => {
  const query = url.searchParams.get('q');

  if (!query || query.length < 2) {
    return new Response(JSON.stringify({ results: [] }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const supabase = createSupabaseServerClient(cookies);

  try {
    // Full-text search in PostgreSQL
    const { data, error } = await supabase.rpc('search_posts', {
      search_query: query,
      result_limit: 10,
    });

    if (error) throw error;

    return new Response(
      JSON.stringify({
        results: data || [],
        query,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Search error:', error);
    return new Response(
      JSON.stringify({ error: 'Search failed' }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
};
EOF

# Create search function in database
cat > supabase/migrations/011_create_search.sql << 'EOF'
-- Create full-text search function
CREATE OR REPLACE FUNCTION search_posts(
  search_query TEXT,
  result_limit INT DEFAULT 10
)
RETURNS TABLE (
  id TEXT,
  title TEXT,
  excerpt TEXT,
  slug TEXT,
  type TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.title,
    p.excerpt,
    p.slug,
    'post'::TEXT AS type
  FROM posts p
  WHERE
    p.published = true
    AND (
      to_tsvector('english', p.title) @@ plainto_tsquery('english', search_query)
      OR to_tsvector('english', p.excerpt) @@ plainto_tsquery('english', search_query)
      OR to_tsvector('english', p.content) @@ plainto_tsquery('english', search_query)
      OR p.title ILIKE '%' || search_query || '%'
      OR p.excerpt ILIKE '%' || search_query || '%'
    )
  ORDER BY
    ts_rank(
      to_tsvector('english', p.title || ' ' || p.excerpt || ' ' || p.content),
      plainto_tsquery('english', search_query)
    ) DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create GIN index for faster full-text search
CREATE INDEX IF NOT EXISTS idx_posts_search
ON posts USING GIN (
  to_tsvector('english', title || ' ' || excerpt || ' ' || content)
);
EOF

npm run db:push
```

---

### STEP 4: Create Modal Dialog System

```bash
cat > src/components/react/Modal.tsx << 'EOF'
import React, { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  closeOnOverlayClick?: boolean;
  closeOnEscape?: boolean;
  showCloseButton?: boolean;
}

export function Modal({
  isOpen,
  onClose,
  title,
  children,
  size = 'md',
  closeOnOverlayClick = true,
  closeOnEscape = true,
  showCloseButton = true,
}: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);

  // Handle escape key
  useEffect(() => {
    if (!isOpen || !closeOnEscape) return;

    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, closeOnEscape, onClose]);

  // Prevent body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }

    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  // Focus trap
  useEffect(() => {
    if (!isOpen) return;

    const modal = modalRef.current;
    if (!modal) return;

    const focusableElements = modal.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );

    const firstElement = focusableElements[0] as HTMLElement;
    const lastElement = focusableElements[
      focusableElements.length - 1
    ] as HTMLElement;

    const handleTab = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return;

      if (e.shiftKey) {
        if (document.activeElement === firstElement) {
          e.preventDefault();
          lastElement?.focus();
        }
      } else {
        if (document.activeElement === lastElement) {
          e.preventDefault();
          firstElement?.focus();
        }
      }
    };

    modal.addEventListener('keydown', handleTab as any);
    firstElement?.focus();

    return () => {
      modal.removeEventListener('keydown', handleTab as any);
    };
  }, [isOpen]);

  const sizeClasses = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl',
    full: 'max-w-full m-4',
  };

  if (typeof document === 'undefined') return null;

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          {/* Overlay */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm"
            onClick={closeOnOverlayClick ? onClose : undefined}
            aria-hidden="true"
          />

          {/* Modal */}
          <div className="flex min-h-full items-center justify-center p-4">
            <motion.div
              ref={modalRef}
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              transition={{ duration: 0.2 }}
              className={`relative w-full ${sizeClasses[size]} bg-white dark:bg-gray-800 rounded-lg shadow-xl`}
              role="dialog"
              aria-modal="true"
              aria-labelledby={title ? 'modal-title' : undefined}
            >
              {/* Header */}
              {(title || showCloseButton) && (
                <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                  {title && (
                    <h2
                      id="modal-title"
                      className="text-xl font-semibold text-gray-900 dark:text-gray-100"
                    >
                      {title}
                    </h2>
                  )}

                  {showCloseButton && (
                    <button
                      type="button"
                      onClick={onClose}
                      className="ml-auto p-1 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                      aria-label="Close modal"
                    >
                      <svg
                        className="h-6 w-6"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
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

              {/* Content */}
              <div className="px-6 py-4">{children}</div>
            </motion.div>
          </div>
        </div>
      )}
    </AnimatePresence>,
    document.body
  );
}

// Example usage component
export function ModalExample() {
  const [isOpen, setIsOpen] = React.useState(false);

  return (
    <div>
      <button onClick={() => setIsOpen(true)} className="btn-primary">
        Open Modal
      </button>

      <Modal
        isOpen={isOpen}
        onClose={() => setIsOpen(false)}
        title="Example Modal"
        size="md"
      >
        <p>This is modal content!</p>

        <div className="mt-6 flex justify-end gap-3">
          <button onClick={() => setIsOpen(false)} className="btn">
            Cancel
          </button>
          <button onClick={() => setIsOpen(false)} className="btn-primary">
            Confirm
          </button>
        </div>
      </Modal>
    </div>
  );
}
EOF
```

---

### STEP 5: Create Toast Notification System

```bash
cat > src/components/react/ToastProvider.tsx << 'EOF'
import React from 'react';
import { Toaster, toast as hotToast } from 'react-hot-toast';

export function ToastProvider() {
  return (
    <Toaster
      position="top-right"
      toastOptions={{
        // Default options
        duration: 4000,
        style: {
          background: 'var(--color-bg-primary)',
          color: 'var(--color-text-primary)',
          border: '1px solid var(--color-border)',
        },
        // Success
        success: {
          duration: 3000,
          iconTheme: {
            primary: '#10b981',
            secondary: '#fff',
          },
        },
        // Error
        error: {
          duration: 5000,
          iconTheme: {
            primary: '#ef4444',
            secondary: '#fff',
          },
        },
      }}
    />
  );
}

// Custom toast helpers
export const toast = {
  success: (message: string) => {
    hotToast.success(message);
  },

  error: (message: string) => {
    hotToast.error(message);
  },

  loading: (message: string) => {
    return hotToast.loading(message);
  },

  promise: <T,>(
    promise: Promise<T>,
    messages: {
      loading: string;
      success: string;
      error: string;
    }
  ) => {
    return hotToast.promise(promise, messages);
  },

  custom: (component: React.ReactNode) => {
    hotToast.custom(component);
  },
};

// Example toast notifications
export function ToastExamples() {
  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold">Toast Examples</h3>

      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => toast.success('Successfully saved!')}
          className="btn-primary"
        >
          Success Toast
        </button>

        <button
          onClick={() => toast.error('Something went wrong!')}
          className="btn-danger"
        >
          Error Toast
        </button>

        <button
          onClick={() => {
            const id = toast.loading('Saving...');
            setTimeout(() => {
              hotToast.success('Saved successfully!', { id });
            }, 2000);
          }}
          className="btn"
        >
          Loading Toast
        </button>

        <button
          onClick={() => {
            toast.promise(
              new Promise((resolve) => setTimeout(resolve, 2000)),
              {
                loading: 'Saving...',
                success: 'Saved!',
                error: 'Failed to save',
              }
            );
          }}
          className="btn"
        >
          Promise Toast
        </button>

        <button
          onClick={() => {
            toast.custom(
              <div className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg shadow-lg">
                🎉 Custom styled toast!
              </div>
            );
          }}
          className="btn"
        >
          Custom Toast
        </button>
      </div>
    </div>
  );
}
EOF

# Update layout to include ToastProvider
cat > src/layouts/ReactLayout.astro << 'EOF'
---
import BaseLayout from './BaseLayout.astro';
import { ToastProvider } from '../components/react/ToastProvider';

interface Props {
  title: string;
  description?: string;
}

const { title, description } = Astro.props;
---

<BaseLayout title={title} description={description}>
  <slot />

  <!-- Toast notifications -->
  <ToastProvider client:load />
</BaseLayout>
EOF
```

---

### STEP 6: Create Image Gallery with Lightbox

```bash
cat > src/components/react/ImageGallery.tsx << 'EOF'
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface Image {
  id: string;
  url: string;
  alt: string;
  caption?: string;
}

interface ImageGalleryProps {
  images: Image[];
  columns?: 2 | 3 | 4;
}

export function ImageGallery({ images, columns = 3 }: ImageGalleryProps) {
  const [selectedImage, setSelectedImage] = useState<Image | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);

  const openLightbox = (image: Image, index: number) => {
    setSelectedImage(image);
    setCurrentIndex(index);
  };

  const closeLightbox = () => {
    setSelectedImage(null);
  };

  const goToPrevious = () => {
    const newIndex = currentIndex > 0 ? currentIndex - 1 : images.length - 1;
    setCurrentIndex(newIndex);
    setSelectedImage(images[newIndex]);
  };

  const goToNext = () => {
    const newIndex = currentIndex < images.length - 1 ? currentIndex + 1 : 0;
    setCurrentIndex(newIndex);
    setSelectedImage(images[newIndex]);
  };

  // Keyboard navigation
  React.useEffect(() => {
    if (!selectedImage) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      switch (e.key) {
        case 'ArrowLeft':
          goToPrevious();
          break;
        case 'ArrowRight':
          goToNext();
          break;
        case 'Escape':
          closeLightbox();
          break;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedImage, currentIndex]);

  const gridCols = {
    2: 'grid-cols-1 sm:grid-cols-2',
    3: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3',
    4: 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-4',
  };

  return (
    <>
      {/* Gallery Grid */}
      <div className={`grid ${gridCols[columns]} gap-4`}>
        {images.map((image, index) => (
          <motion.button
            key={image.id}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => openLightbox(image, index)}
            className="group relative aspect-square overflow-hidden rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <img
              src={image.url}
              alt={image.alt}
              className="h-full w-full object-cover transition-transform group-hover:scale-110"
              loading="lazy"
            />

            {/* Overlay */}
            <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors" />

            {/* Expand icon */}
            <div className="absolute top-2 right-2 p-2 bg-black/50 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
              <svg
                className="h-5 w-5 text-white"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7"
                />
              </svg>
            </div>
          </motion.button>
        ))}
      </div>

      {/* Lightbox */}
      <AnimatePresence>
        {selectedImage && (
          <div className="fixed inset-0 z-50 flex items-center justify-center">
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={closeLightbox}
              className="absolute inset-0 bg-black/90"
            />

            {/* Content */}
            <div className="relative z-10 w-full h-full flex flex-col">
              {/* Header */}
              <div className="flex items-center justify-between p-4 text-white">
                <div className="text-sm">
                  {currentIndex + 1} / {images.length}
                </div>

                <button
                  onClick={closeLightbox}
                  className="p-2 rounded-lg hover:bg-white/10 transition-colors"
                  aria-label="Close"
                >
                  <svg
                    className="h-6 w-6"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
              </div>

              {/* Image */}
              <div className="flex-1 flex items-center justify-center p-4">
                <motion.img
                  key={selectedImage.id}
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.9 }}
                  transition={{ duration: 0.2 }}
                  src={selectedImage.url}
                  alt={selectedImage.alt}
                  className="max-h-full max-w-full object-contain"
                />
              </div>

              {/* Caption */}
              {selectedImage.caption && (
                <div className="p-4 text-center text-white">
                  <p>{selectedImage.caption}</p>
                </div>
              )}

              {/* Navigation */}
              <button
                onClick={goToPrevious}
                className="absolute left-4 top-1/2 -translate-y-1/2 p-3 rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
                aria-label="Previous image"
              >
                <svg
                  className="h-6 w-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 19l-7-7 7-7"
                  />
                </svg>
              </button>

              <button
                onClick={goToNext}
                className="absolute right-4 top-1/2 -translate-y-1/2 p-3 rounded-full bg-white/10 hover:bg-white/20 text-white transition-colors"
                aria-label="Next image"
              >
                <svg
                  className="h-6 w-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </button>
            </div>
          </div>
        )}
      </AnimatePresence>
    </>
  );
}
EOF
```

---

### STEP 7: Create File Upload Component

```bash
cat > src/components/react/FileUpload.tsx << 'EOF'
import React, { useCallback, useState } from 'react';
import { useDropzone } from 'react-dropzone';
import { toast } from './ToastProvider';

interface FileUploadProps {
  onUpload: (files: File[]) => Promise<void>;
  accept?: Record<string, string[]>;
  maxFiles?: number;
  maxSize?: number;
  multiple?: boolean;
}

export function FileUpload({
  onUpload,
  accept = {
    'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp'],
  },
  maxFiles = 5,
  maxSize = 5 * 1024 * 1024, // 5MB
  multiple = true,
}: FileUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [previews, setPreviews] = useState<Array<{ file: File; preview: string }>>([]);

  const onDrop = useCallback(
    async (acceptedFiles: File[]) => {
      // Validate file sizes
      const invalidFiles = acceptedFiles.filter((file) => file.size > maxSize);
      if (invalidFiles.length > 0) {
        toast.error(
          `${invalidFiles.length} file(s) exceed ${maxSize / 1024 / 1024}MB limit`
        );
        return;
      }

      // Create previews
      const newPreviews = acceptedFiles.map((file) => ({
        file,
        preview: URL.createObjectURL(file),
      }));

      setPreviews((prev) => [...prev, ...newPreviews]);

      // Upload files
      setUploading(true);
      try {
        await onUpload(acceptedFiles);
        toast.success(`${acceptedFiles.length} file(s) uploaded successfully`);
      } catch (error) {
        console.error('Upload error:', error);
        toast.error('Failed to upload files');
      } finally {
        setUploading(false);
      }
    },
    [onUpload, maxSize]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept,
    maxFiles,
    multiple,
    disabled: uploading,
  });

  const removePreview = (index: number) => {
    setPreviews((prev) => {
      const newPreviews = [...prev];
      URL.revokeObjectURL(newPreviews[index].preview);
      newPreviews.splice(index, 1);
      return newPreviews;
    });
  };

  // Cleanup previews on unmount
  React.useEffect(() => {
    return () => {
      previews.forEach((preview) => URL.revokeObjectURL(preview.preview));
    };
  }, []);

  return (
    <div className="space-y-4">
      {/* Dropzone */}
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
          isDragActive
            ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
            : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
        } ${uploading ? 'opacity-50 cursor-not-allowed' : ''}`}
      >
        <input {...getInputProps()} />

        <div className="space-y-2">
          {/* Icon */}
          <svg
            className="mx-auto h-12 w-12 text-gray-400"
            stroke="currentColor"
            fill="none"
            viewBox="0 0 48 48"
          >
            <path
              d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
              strokeWidth={2}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>

          {/* Text */}
          <div>
            {isDragActive ? (
              <p className="text-blue-600 dark:text-blue-400 font-medium">
                Drop files here...
              </p>
            ) : (
              <>
                <p className="text-gray-600 dark:text-gray-400">
                  <span className="font-medium text-blue-600 dark:text-blue-400 hover:underline">
                    Click to upload
                  </span>{' '}
                  or drag and drop
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-500 mt-1">
                  {Object.keys(accept)
                    .flatMap((key) => accept[key])
                    .join(', ')}{' '}
                  up to {maxSize / 1024 / 1024}MB
                </p>
              </>
            )}
          </div>

          {/* Progress */}
          {uploading && (
            <div className="mt-4">
              <div className="animate-pulse flex items-center justify-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                <svg
                  className="animate-spin h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                >
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
                <span>Uploading...</span>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Previews */}
      {previews.length > 0 && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {previews.map((preview, index) => (
            <div key={index} className="relative group">
              <img
                src={preview.preview}
                alt={`Preview ${index + 1}`}
                className="w-full h-32 object-cover rounded-lg"
              />

              {/* Remove button */}
              <button
                type="button"
                onClick={() => removePreview(index)}
                className="absolute top-2 right-2 p-1 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                aria-label="Remove file"
              >
                <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fillRule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clipRule="evenodd"
                  />
                </svg>
              </button>

              {/* File info */}
              <div className="mt-1 text-xs text-gray-500 dark:text-gray-400 truncate">
                {preview.file.name}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// Example usage
export function FileUploadExample() {
  const handleUpload = async (files: File[]) => {
    // Simulate upload
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // In real app, upload to Supabase storage
    // const { data, error } = await supabase.storage
    //   .from('uploads')
    //   .upload(`${userId}/${file.name}`, file);
  };

  return (
    <div className="max-w-2xl">
      <h3 className="text-lg font-semibold mb-4">Upload Images</h3>
      <FileUpload onUpload={handleUpload} />
    </div>
  );
}
EOF
```

---

## ✅ 3. VERIFY (Testing & Troubleshooting)

### Verification Checklist

**React Integration:**
- [ ] React components render
- [ ] Client directives work
- [ ] Props pass correctly
- [ ] State updates properly
- [ ] Event handlers fire
- [ ] Hydration is efficient

**Forms:**
- [ ] Comment form validates
- [ ] Error messages display
- [ ] Submission works
- [ ] Reset after submit
- [ ] Loading states show

**Search:**
- [ ] Debouncing works
- [ ] Results display
- [ ] Keyboard navigation
- [ ] Highlighting works
- [ ] Click outside closes

**Modals:**
- [ ] Opens/closes smoothly
- [ ] Focus trapping works
- [ ] Escape key closes
- [ ] Body scroll locked
- [ ] Animations smooth

**Toast:**
- [ ] Success toasts show
- [ ] Error toasts show
- [ ] Loading toasts work
- [ ] Auto-dismiss works
- [ ] Multiple toasts stack

**File Upload:**
- [ ] Drag and drop works
- [ ] Click to select works
- [ ] Validation works
- [ ] Previews display
- [ ] Upload completes

---

### Testing Commands

```bash
# Start dev server
npm run dev

# Test React components
open http://localhost:4321/test-react

# Check bundle size
npm run build
ls -lh dist/_astro/

# Analyze bundle
npx astro build --analyze

# Check TypeScript
npm run check
```

---

### Troubleshooting

**Issue 1: React components not rendering**
```bash
# Check React integration
cat astro.config.mjs | grep react

# Ensure @astrojs/react is installed
npm list @astrojs/react

# Check client directive
# Must have client:load, client:idle, etc.

# Check browser console for errors
```

**Issue 2: Hydration mismatch**
```bash
# Check for server/client differences
# Avoid: new Date(), Math.random(), etc. in component body

# Solution: Use useEffect for client-only code
useEffect(() => {
  // Client-only code here
}, []);
```

**Issue 3: Props not passing**
```bash
# Check prop types match
interface Props {
  postId: string; // Must match
}

# Pass as regular HTML attributes
<CommentForm client:idle postId="123" />

# Not as spread
<CommentForm client:idle {...props} /> // ❌ Won't work
```

**Issue 4: Forms not submitting**
```bash
# Check API endpoint exists
curl -X POST http://localhost:4321/api/comments

# Check request headers
# Must include Content-Type: application/json

# Check CORS if deployed
# Add appropriate headers in API route
```

---

## 🎯 What You Built

### Components (7)
- ✅ **CommentForm** - Validated comment submission
- ✅ **LiveSearch** - Debounced search with keyboard navigation
- ✅ **Modal** - Accessible dialog system
- ✅ **ToastProvider** - Notification system
- ✅ **ImageGallery** - Lightbox with navigation
- ✅ **FileUpload** - Drag-and-drop file uploads

### Features
- ✅ **Form Validation** - React Hook Form + Zod
- ✅ **Debouncing** - Optimized search performance
- ✅ **Keyboard Navigation** - Full accessibility
- ✅ **Focus Management** - Proper focus trapping
- ✅ **Animations** - Framer Motion integration
- ✅ **File Handling** - Preview and validation
- ✅ **Toast Notifications** - User feedback system

---

## 🚀 Next Steps

In **Lesson 8**, you'll learn:
- Complete comments system with threading
- Real-time updates with Supabase Realtime
- Optimistic UI updates
- Comment moderation
- Markdown support
- Like/flag functionality

**Continue to:** [LESSON-8-COMMENTS-REALTIME.md](./LESSON-8-COMMENTS-REALTIME.md)

---

**Congratulations!** 🎉 You've mastered React Islands in Astro.

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 6-8 hours
