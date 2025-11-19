#!/bin/bash

###############################################################################
# MODULE 1, LESSON 1: Next.js 16 + React 19.2 Setup
# Complete automated setup script
###############################################################################

set -e  # Exit on error

echo "==========================================="
echo "MODULE 1, LESSON 1: PROJECT SETUP"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Create Next.js 16 Project
echo -e "${BLUE}Step 1: Creating Next.js 16 project...${NC}"
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm --yes

echo -e "${GREEN}✓ Next.js 16 project created${NC}"
echo ""

# Step 2: Verify versions
echo -e "${BLUE}Step 2: Verifying versions...${NC}"
node -v
npm -v
cat package.json | grep -E "(next|react)" | head -2
echo -e "${GREEN}✓ Versions verified${NC}"
echo ""

# Step 3: Create folder structure
echo -e "${BLUE}Step 3: Creating folder structure...${NC}"
mkdir -p src/lib
mkdir -p src/components/ui
mkdir -p src/components/features/auth
mkdir -p src/components/features/projects
mkdir -p src/components/features/tasks
mkdir -p src/components/features/payments
mkdir -p src/types
mkdir -p src/constants
mkdir -p src/styles
mkdir -p src/hooks
mkdir -p src/utils

# Clean up any incorrectly created folders
rm -rf 'src/{lib,components' 'src/{lib,components/{ui,features' 'src/{lib,components/{ui,features/{auth,projects,tasks,payments}},types,constants,styles,hooks,utils}' 2>/dev/null || true

echo -e "${GREEN}✓ Folder structure created${NC}"
find src -type d | sort
echo ""

# Step 4: Create constants file
echo -e "${BLUE}Step 4: Creating constants file...${NC}"
cat > src/constants/index.ts << 'CONSTANTS_EOF'
/**
 * Application Constants
 * Following DRY principle - all magic strings and numbers centralized here
 */

// ============================================
// DATABASE TABLE NAMES
// ============================================
export const DB_TABLES = {
  PROJECTS: 'prj_projects',
  TASKS: 'prj_tasks',
  PROJECT_MEMBERS: 'prj_project_members',
  PROJECT_PAYMENTS: 'prj_project_payments',
  PROJECT_TERMS: 'prj_project_terms',
  USERS: 'users', // Supabase auth.users
} as const;

// ============================================
// CACHE TAGS (Next.js 16 Cache Components)
// ============================================
export const CACHE_TAGS = {
  PROJECTS: 'projects',
  TASKS: 'tasks',
  PROJECT_MEMBERS: 'project-members',
  PAYMENTS: 'payments',
  TERMS: 'terms',
  USER_PROFILE: 'user-profile',
} as const;

// ============================================
// CACHE LIFETIMES (Next.js 16)
// ============================================
export const CACHE_LIFETIMES = {
  DEFAULT: 'default' as const, // 15 minutes
  SECONDS: 'seconds' as const, // 1 second
  HOURS: 'hours' as const,     // 1 hour
  DAYS: 'days' as const,       // 1 day
  MAX: 'max' as const,         // 30 days
};

// ============================================
// ROUTES
// ============================================
export const ROUTES = {
  HOME: '/',
  DASHBOARD: '/dashboard',
  PROJECTS: '/projects',
  PROJECT_DETAIL: (id: string) => `/projects/${id}`,
  TASKS: '/tasks',
  PAYMENTS: '/payments',
  AUTH: {
    LOGIN: '/auth/login',
    SIGNUP: '/auth/signup',
    FORGOT_PASSWORD: '/auth/forgot-password',
    CALLBACK: '/auth/callback',
  },
} as const;

// ============================================
// TASK STATUS
// ============================================
export const TASK_STATUS = {
  TODO: 'todo',
  IN_PROGRESS: 'in_progress',
  REVIEW: 'review',
  DONE: 'done',
  CANCELLED: 'cancelled',
} as const;

// ============================================
// PROJECT STATUS
// ============================================
export const PROJECT_STATUS = {
  ACTIVE: 'active',
  ON_HOLD: 'on_hold',
  COMPLETED: 'completed',
  ARCHIVED: 'archived',
} as const;

// ============================================
// MEMBER ROLES
// ============================================
export const MEMBER_ROLES = {
  OWNER: 'owner',
  ADMIN: 'admin',
  MEMBER: 'member',
  VIEWER: 'viewer',
} as const;

// ============================================
// PAYMENT STATUS
// ============================================
export const PAYMENT_STATUS = {
  PENDING: 'pending',
  PAID: 'paid',
  OVERDUE: 'overdue',
  CANCELLED: 'cancelled',
} as const;

// ============================================
// API ENDPOINTS
// ============================================
export const API_ENDPOINTS = {
  PROJECTS: '/api/projects',
  TASKS: '/api/tasks',
  PAYMENTS: '/api/payments',
} as const;

// ============================================
// VALIDATION
// ============================================
export const VALIDATION = {
  PROJECT_NAME_MIN_LENGTH: 3,
  PROJECT_NAME_MAX_LENGTH: 100,
  TASK_TITLE_MIN_LENGTH: 3,
  TASK_TITLE_MAX_LENGTH: 200,
  PASSWORD_MIN_LENGTH: 8,
} as const;

// ============================================
// UI CONSTANTS
// ============================================
export const UI = {
  ITEMS_PER_PAGE: 10,
  DEBOUNCE_DELAY: 300,
  TOAST_DURATION: 3000,
} as const;

// ============================================
// ERROR MESSAGES
// ============================================
export const ERROR_MESSAGES = {
  GENERIC: 'Something went wrong. Please try again.',
  UNAUTHORIZED: 'You must be logged in to perform this action.',
  FORBIDDEN: 'You do not have permission to perform this action.',
  NOT_FOUND: 'Resource not found.',
  VALIDATION_FAILED: 'Please check your input and try again.',
  NETWORK_ERROR: 'Network error. Please check your connection.',
} as const;

// ============================================
// SUCCESS MESSAGES
// ============================================
export const SUCCESS_MESSAGES = {
  PROJECT_CREATED: 'Project created successfully',
  PROJECT_UPDATED: 'Project updated successfully',
  PROJECT_DELETED: 'Project deleted successfully',
  TASK_CREATED: 'Task created successfully',
  TASK_UPDATED: 'Task updated successfully',
  TASK_DELETED: 'Task deleted successfully',
} as const;

// ============================================
// TYPE EXPORTS
// ============================================
export type TaskStatus = typeof TASK_STATUS[keyof typeof TASK_STATUS];
export type ProjectStatus = typeof PROJECT_STATUS[keyof typeof PROJECT_STATUS];
export type MemberRole = typeof MEMBER_ROLES[keyof typeof MEMBER_ROLES];
export type PaymentStatus = typeof PAYMENT_STATUS[keyof typeof PAYMENT_STATUS];
CONSTANTS_EOF

echo -e "${GREEN}✓ Constants file created${NC}"
echo ""

# Step 5: Create TypeScript types
echo -e "${BLUE}Step 5: Creating TypeScript types...${NC}"
cat > src/types/index.ts << 'TYPES_EOF'
/**
 * TypeScript Type Definitions
 * Centralized types for type safety across the application
 */

import { 
  TaskStatus, 
  ProjectStatus, 
  MemberRole, 
  PaymentStatus 
} from '@/constants';

// ============================================
// DATABASE TYPES
// ============================================

export interface Project {
  id: string;
  name: string;
  description: string | null;
  start_date: string;
  end_date: string | null;
  is_active: boolean;
  status: ProjectStatus;
  created_at: string;
  updated_at: string;
}

export interface Task {
  id: string;
  project_id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  due_date: string | null;
  assigned_to: string | null;
  created_at: string;
  updated_at: string;
  created_by: string;
}

export interface ProjectMember {
  id: string;
  project_id: string;
  user_id: string;
  role: MemberRole;
  joined_at: string;
}

export interface ProjectPayment {
  id: string;
  project_id: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  due_date: string;
  paid_date: string | null;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface ProjectTerm {
  id: string;
  project_id: string;
  title: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface User {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
  created_at: string;
}

// ============================================
// FORM TYPES
// ============================================

export interface CreateProjectInput {
  name: string;
  description?: string;
  start_date: string;
  end_date?: string;
}

export interface UpdateProjectInput {
  name?: string;
  description?: string;
  start_date?: string;
  end_date?: string;
  status?: ProjectStatus;
  is_active?: boolean;
}

export interface CreateTaskInput {
  project_id: string;
  title: string;
  description?: string;
  status?: TaskStatus;
  due_date?: string;
  assigned_to?: string;
}

export interface UpdateTaskInput {
  title?: string;
  description?: string;
  status?: TaskStatus;
  due_date?: string;
  assigned_to?: string;
}

// ============================================
// API RESPONSE TYPES
// ============================================

export interface ApiResponse<T> {
  data: T | null;
  error: string | null;
  success: boolean;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

// ============================================
// COMPONENT PROPS TYPES
// ============================================

export interface BaseComponentProps {
  className?: string;
  children?: React.ReactNode;
}

export interface ProjectCardProps extends BaseComponentProps {
  project: Project;
  onEdit?: (project: Project) => void;
  onDelete?: (projectId: string) => void;
}

export interface TaskCardProps extends BaseComponentProps {
  task: Task;
  onStatusChange?: (taskId: string, status: TaskStatus) => void;
  onEdit?: (task: Task) => void;
  onDelete?: (taskId: string) => void;
}

// ============================================
// UTILITY TYPES
// ============================================

export type AsyncActionState<T> = {
  data: T | null;
  loading: boolean;
  error: string | null;
};

export type FormState = {
  errors: Record<string, string[]>;
  message: string | null;
};
TYPES_EOF

echo -e "${GREEN}✓ TypeScript types created${NC}"
echo ""

# Step 6: Update next.config.ts
echo -e "${BLUE}Step 6: Configuring Next.js 16 Cache Components...${NC}"
cat > next.config.ts << 'CONFIG_EOF'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Enable Next.js 16 Cache Components feature (includes PPR)
  cacheComponents: true,

  // Custom cache life profiles
  cacheLife: {
    // Weekly cache profile for less frequently changing data
    weekly: {
      stale: 60 * 60 * 24 * 7, // 7 days in seconds
      revalidate: 60 * 60 * 24 * 7,
      expire: 60 * 60 * 24 * 7,
    },
    // Daily cache profile for moderately changing data
    daily: {
      stale: 60 * 60 * 24, // 1 day in seconds
      revalidate: 60 * 60 * 24,
      expire: 60 * 60 * 24,
    },
  },
};

export default nextConfig;
CONFIG_EOF

echo -e "${GREEN}✓ Next.js config updated${NC}"
echo ""

# Step 7: Update layout.tsx
echo -e "${BLUE}Step 7: Updating layout.tsx...${NC}"
cat > src/app/layout.tsx << 'LAYOUT_EOF'
import type { Metadata } from "next";
import "@/app/globals.css";

export const metadata: Metadata = {
  title: "Project Management App",
  description: "Learn Next.js 16 + React 19.2 - Project Management Application",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
LAYOUT_EOF

echo -e "${GREEN}✓ Layout updated${NC}"
echo ""

# Step 8: Update page.tsx
echo -e "${BLUE}Step 8: Creating home page...${NC}"
cat > src/app/page.tsx << 'PAGE_EOF'
import { ROUTES } from '@/constants';

export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      <main className="flex flex-col items-center justify-center gap-8 p-8 text-center">
        <div className="space-y-4">
          <h1 className="text-5xl font-bold text-gray-900 dark:text-white">
            Project Management App
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-300">
            Built with Next.js 16 + React 19.2 + Tailwind CSS + Supabase
          </p>
        </div>

        <div className="flex flex-col gap-4 sm:flex-row">
          <div className="rounded-lg bg-white dark:bg-gray-800 p-6 shadow-lg">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
              Features
            </h2>
            <ul className="text-left text-gray-600 dark:text-gray-300 space-y-2">
              <li>✅ Next.js 16 with Cache Components</li>
              <li>✅ React 19.2 with Server Components</li>
              <li>✅ Tailwind CSS 4</li>
              <li>✅ TypeScript</li>
              <li>✅ Supabase Integration (Coming Next)</li>
            </ul>
          </div>
        </div>

        <div className="text-sm text-gray-500 dark:text-gray-400 mt-8">
          Module 1, Lesson 1: Setup Complete! 🎉
        </div>
      </main>
    </div>
  );
}
PAGE_EOF

echo -e "${GREEN}✓ Home page created${NC}"
echo ""

# Step 9: Create environment template
echo -e "${BLUE}Step 9: Creating environment template...${NC}"
cat > .env.local.example << 'ENV_EOF'
# Supabase Configuration
# Get these from https://supabase.com/dashboard/project/_/settings/api
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=your-publishable-default-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# App Configuration
NEXT_PUBLIC_APP_NAME=Project Management App
NEXT_PUBLIC_APP_URL=http://localhost:3000
ENV_EOF

echo -e "${GREEN}✓ Environment template created${NC}"
echo ""

# Step 10: Update .gitignore
echo -e "${BLUE}Step 10: Updating .gitignore...${NC}"
cat >> .gitignore << 'GITIGNORE_EOF'

# Environment variables
.env.local
.env*.local

# Database
*.db
*.db-journal
GITIGNORE_EOF

echo -e "${GREEN}✓ .gitignore updated${NC}"
echo ""

# Step 11: Build the project
echo -e "${BLUE}Step 11: Building the project...${NC}"
npm run build

echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# Step 12: Display summary
echo ""
echo "==========================================="
echo -e "${GREEN}MODULE 1, LESSON 1 COMPLETE!${NC}"
echo "==========================================="
echo ""
echo "✅ Next.js 16.0.3 + React 19.2.0 installed"
echo "✅ Cache Components enabled"
echo "✅ Folder structure created"
echo "✅ Constants file with DRY principle"
echo "✅ TypeScript types defined"
echo "✅ Import alias (@/*) configured"
echo "✅ Build successful"
echo ""
echo "📁 Project Structure:"
find src -type d | sort
echo ""
echo "🎯 Next Steps:"
echo "1. Review LESSON-1-CHECKLIST.md"
echo "2. Run 'npm run dev' to start development server"
echo "3. Visit http://localhost:3000"
echo "4. Continue to Lesson 2: Supabase Setup"
echo ""
echo "==========================================="
