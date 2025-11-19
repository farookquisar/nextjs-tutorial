# Import Alias Guide (@/*)

## 📋 Configuration

The import alias `@/*` is configured to point to the `src/` directory.

**tsconfig.json:**
```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## ✅ Correct Usage

### Always use `@/*` instead of relative paths:

```typescript
// ✅ CORRECT - Use import alias
import { ROUTES, DB_TABLES, CACHE_TAGS } from '@/constants';
import { Project, Task } from '@/types';
import { createClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { ProjectCard } from '@/components/features/projects/project-card';

// ❌ WRONG - Don't use relative paths
import { ROUTES } from '../../../constants';
import { Project } from '../../types';
import { createClient } from '../lib/supabase/client';
```

## 📁 Import Patterns by Location

### From `src/app/page.tsx` (Root page)
```typescript
import { ROUTES } from '@/constants';
import { Project } from '@/types';
import { getProjects } from '@/lib/supabase/queries';
```

### From `src/app/projects/page.tsx` (Nested route)
```typescript
import { DB_TABLES } from '@/constants';
import { ProjectList } from '@/components/features/projects/project-list';
import { createClient } from '@/lib/supabase/client';
```

### From `src/components/features/projects/project-card.tsx`
```typescript
import { Project } from '@/types';
import { ROUTES } from '@/constants';
import { Button } from '@/components/ui/button';
```

### From `src/lib/supabase/client.ts`
```typescript
import { DB_TABLES } from '@/constants';
// No need for alias when importing external packages
import { createClient } from '@supabase/supabase-js';
```

### From `src/types/index.ts`
```typescript
import { 
  TaskStatus, 
  ProjectStatus, 
  MemberRole, 
  PaymentStatus 
} from '@/constants';
```

## 🗂️ Common Import Examples

### Constants (Most frequently imported)
```typescript
// Import everything
import * as Constants from '@/constants';

// Import specific items (recommended)
import { DB_TABLES, ROUTES, CACHE_TAGS } from '@/constants';

// Import types
import { TaskStatus, ProjectStatus } from '@/constants';
```

### Types
```typescript
// Import multiple types
import { Project, Task, ProjectMember } from '@/types';

// Import specific type
import type { CreateProjectInput } from '@/types';
```

### Components
```typescript
// UI components
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';

// Feature components
import { ProjectList } from '@/components/features/projects/project-list';
import { TaskCard } from '@/components/features/tasks/task-card';
```

### Utilities
```typescript
import { formatDate } from '@/utils/date';
import { cn } from '@/utils/classnames';
```

### Lib (Supabase, etc.)
```typescript
import { createClient } from '@/lib/supabase/client';
import { getProjects } from '@/lib/supabase/queries';
```

## 🎯 Benefits of Using Import Alias

1. **Cleaner Code**: No messy `../../../` paths
2. **Refactoring Safe**: Move files without updating imports
3. **Consistent**: Same import path regardless of file location
4. **Easier to Read**: Clear what you're importing from
5. **Better DX**: IDE autocomplete works better

## 🔍 Verification

### Check for relative imports (should return empty):
```bash
grep -r "from '\.\./\|from '\.\/" src/ --include="*.ts" --include="*.tsx"
```

### Verify all imports use alias:
```bash
grep -r "from '@/" src/ --include="*.ts" --include="*.tsx"
```

## 📝 Examples from Current Project

### ✅ src/app/page.tsx
```typescript
import { ROUTES } from '@/constants';
```

### ✅ src/types/index.ts
```typescript
import { 
  TaskStatus, 
  ProjectStatus, 
  MemberRole, 
  PaymentStatus 
} from '@/constants';
```

## 🚫 Anti-Patterns to Avoid

```typescript
// ❌ Don't mix relative and alias imports
import { ROUTES } from '@/constants';
import { Project } from '../types';  // Wrong!

// ✅ Use alias for both
import { ROUTES } from '@/constants';
import { Project } from '@/types';   // Correct!

// ❌ Don't use alias for external packages
import { createClient } from '@/node_modules/@supabase/supabase-js';

// ✅ Import external packages directly
import { createClient } from '@supabase/supabase-js';

// ❌ Don't use relative paths
import Button from '../../components/ui/button';

// ✅ Use alias
import { Button } from '@/components/ui/button';
```

## 🔄 Migration from Relative Imports

If you have relative imports, convert them:

```bash
# Before
import { ROUTES } from '../../../constants';

# After
import { ROUTES } from '@/constants';
```

## 📖 Directory Structure Reference

```
src/
├── app/              → @/app/*
├── components/       → @/components/*
│   ├── ui/          → @/components/ui/*
│   └── features/    → @/components/features/*
├── constants/        → @/constants
├── types/           → @/types
├── lib/             → @/lib/*
├── hooks/           → @/hooks/*
└── utils/           → @/utils/*
```

## ✨ Best Practices

1. **Always use `@/*`** for internal imports
2. **Group imports** by type (external, @/*, relative if absolutely needed)
3. **Sort alphabetically** within groups
4. **Use named exports** when possible

### Example: Well-organized imports
```typescript
// External packages (third-party)
import { createClient } from '@supabase/supabase-js';
import { Suspense } from 'react';

// Internal imports using alias
import { ProjectCard } from '@/components/features/projects/project-card';
import { Button } from '@/components/ui/button';
import { DB_TABLES, ROUTES } from '@/constants';
import { createClient as createSupabaseClient } from '@/lib/supabase/client';
import { Project, Task } from '@/types';
import { formatDate } from '@/utils/date';
```

## 🎓 Summary

- ✅ **Use** `@/*` for all internal imports
- ✅ Configured in `tsconfig.json`
- ✅ Works with TypeScript autocomplete
- ✅ Makes refactoring easier
- ✅ Cleaner, more maintainable code
- ❌ Never use relative paths (`../`)
- ❌ Don't use alias for external packages

---

**All project files already follow this pattern!** ✅
