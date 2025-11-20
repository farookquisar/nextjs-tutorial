# Lessons Summary - Next.js 16 + React 19.2 + Supabase Tutorial

**Purpose:** Quick reference for lesson progression and key concepts covered in each lesson.

---

## Lesson 1: Next.js 16 Setup with TypeScript & Constants

**Reference:** `LESSON-1-PRACTICAL-GUIDE.md`

**What was built:**
- Next.js 16.0.3 + React 19.2.0 project setup
- TypeScript configuration with strict mode
- Tailwind CSS 4 styling
- Import alias (@/) configuration
- SOLID-based folder structure
- Constants file following DRY principle
- TypeScript types file for type safety
- Next.js 16 Cache Components enabled
- Supabase packages installed
- Environment variables template

**Folder structure created:**
- `src/lib/` - External integrations and utilities
- `src/components/ui/` - Generic UI components
- `src/components/features/` - Feature-specific components (auth, projects, tasks, payments)
- `src/constants/` - All app constants (DRY principle)
- `src/types/` - TypeScript type definitions
- `src/hooks/` - Custom React hooks
- `src/utils/` - Utility functions
- `src/styles/` - Additional styles

**Key files created:**
- `tsconfig.json` - TypeScript config with path aliases
- `next.config.ts` - Next.js 16 config with cacheComponents enabled
- `tailwind.config.ts` - Tailwind CSS 4 setup
- `src/constants/index.ts` - ALL app constants (table names, routes, statuses, messages)
- `src/types/index.ts` - TypeScript types (Project, Task, Payment, etc.)
- `src/app/page.tsx` - Home page using constants
- `src/app/layout.tsx` - Root layout with @/ import alias
- `.env.local.example` - Environment variables template
- `.gitignore` - Updated to ignore .env files

**Key concepts:**
- **DRY Principle** - Don't Repeat Yourself, all constants centralized
- **SOLID Principles** - Folder structure follows Single Responsibility
- **Import Aliases** - Use @/ instead of ../../../
- **Next.js 16 Cache Components** - Enabled for performance
- **Type Safety** - TypeScript types exported from constants
- **`as const`** - Readonly constants with literal types
- **No Magic Strings** - All strings/numbers in constants file

**Constants included:**
- Database table names (DB_TABLES)
- Cache tags and lifetimes (CACHE_TAGS, CACHE_LIFETIMES)
- Routes (ROUTES)
- Task statuses (TASK_STATUS)
- Project statuses (PROJECT_STATUS)
- Member roles (MEMBER_ROLES)
- Payment statuses (PAYMENT_STATUS)
- Validation rules (VALIDATION)
- UI constants (UI)
- Error messages (ERROR_MESSAGES)
- Success messages (SUCCESS_MESSAGES)

**Technologies:** Next.js 16, React 19.2, TypeScript, Tailwind CSS 4, Supabase (@supabase/supabase-js, @supabase/ssr)

---

## Lesson 2: Supabase Setup & Database Configuration

**Reference:** `LESSON-2-PRACTICAL-GUIDE.md`

**What was built:**
- Supabase project connection
- Complete database schema with 5 tables
- Row Level Security (RLS) setup
- Supabase clients (browser + server)
- Next.js 16 proxy.ts for session management
- Database migrations in SQL files

**Database tables created:**
1. **prj_projects** - Main projects table (name, description, dates, status)
2. **prj_tasks** - Tasks linked to projects (1:M relationship)
3. **prj_project_members** - User-project relationships (M:N relationship)
4. **prj_project_payments** - Payment tracking per project
5. **prj_project_terms** - Project terms and conditions

**Key files created:**
- `.env.local` - Environment variables (Supabase URL, keys)
- `supabase/migrations/001_initial_schema.sql` - Database schema
- `supabase/migrations/002_rls_policies.sql` - RLS policies
- `src/lib/supabase/client.ts` - Browser Supabase client
- `src/lib/supabase/server.ts` - Server Supabase client
- `proxy.ts` - Session refresh middleware (Next.js 16)

**Key concepts:**
- **Row Level Security (RLS)** - Database-level permission control
- **RPC Functions** - Server-side database procedures
- **Session Management** - Automatic token refresh via proxy.ts
- **Database Migrations** - Version-controlled schema changes
- **Publishable Key** - New naming (formerly "anon key")

**Technologies:** Supabase, PostgreSQL, Next.js middleware

---

## Lesson 3: Authentication with Supabase Auth

**Reference:** `LESSON-3-PRACTICAL-GUIDE.md`

**What was built:**
- Email/password authentication
- Login and Signup pages with forms
- Protected routes (dashboard)
- Public-only routes (login/signup redirect if authenticated)
- Server Actions for auth operations
- Reusable UI components (Button, Input, Select, Dropdown, Modal)
- Auth state hooks
- Logout functionality
- Email confirmation flow (optional)
- Playwright E2E testing setup
- AI-assisted code review workflow

**Key files created:**
- `src/lib/actions/auth.ts` - Server Actions (signUp, signIn, signOut)
- `src/app/(auth)/login/page.tsx` - Login page
- `src/app/(auth)/signup/page.tsx` - Signup page
- `src/app/dashboard/page.tsx` - Protected dashboard
- `src/components/ui/Button.tsx` - Reusable button component
- `src/components/ui/Input.tsx` - Reusable input component
- `src/components/ui/Select.tsx` - Reusable select/dropdown list
- `src/components/ui/Dropdown.tsx` - Reusable dropdown menu
- `src/components/ui/Modal.tsx` - Reusable modal dialog
- `src/components/features/auth/LoginForm.tsx` - Login form
- `src/components/features/auth/SignupForm.tsx` - Signup form
- `src/components/features/auth/LogoutButton.tsx` - Logout button
- `src/hooks/useAuth.ts` - Auth state hook
- `e2e/auth.spec.ts` - Playwright E2E tests
- `playwright.config.ts` - Playwright configuration

**Key concepts:**
- **Server Actions** - `'use server'` for secure mutations
- **Route Groups** - `(auth)` folder for shared layouts
- **Protected Routes** - Server-side auth checks with redirects
- **Public-only Routes** - Redirect authenticated users to dashboard
- **Session Cookies** - HttpOnly cookies managed by Supabase
- **Progressive Enhancement** - Forms work without JavaScript
- **E2E Testing** - Playwright for automated testing
- **Accessible Selectors** - getByRole, getByLabel for tests
- **AI Code Review** - Security, performance, bugs, code quality audits

**Technologies:** Supabase Auth, Server Actions, React hooks, Playwright

---

## Lesson 4: Project CRUD Operations with Server Actions

**Reference:** `LESSON-4-PRACTICAL-GUIDE.md`

**What was built:**
- Full CRUD operations for projects
- Row Level Security (RLS) policies for prj_projects
- Server Actions for all database operations
- Zod validation schemas
- RPC function for project statistics
- Project management UI (list, create, edit, view, delete)
- Project analytics dashboard

**Database changes:**
- Added `owner_id` column to `prj_projects` table
- Created RLS policies (SELECT, INSERT, UPDATE, DELETE)
- Created `get_project_stats()` RPC function

**Key files created:**
- `src/lib/types/database.ts` - TypeScript database types
- `src/lib/validations/project.ts` - Zod validation schemas
- `src/lib/actions/projects.ts` - CRUD Server Actions
- `src/components/features/projects/ProjectCard.tsx` - Project card component
- `src/components/features/projects/ProjectList.tsx` - Projects list component
- `src/components/features/projects/ProjectForm.tsx` - Create/Edit form
- `src/components/features/projects/ProjectStats.tsx` - Analytics dashboard
- `src/app/dashboard/projects/page.tsx` - Projects list page
- `src/app/dashboard/projects/new/page.tsx` - Create project page
- `src/app/dashboard/projects/[id]/page.tsx` - View project page
- `src/app/dashboard/projects/[id]/edit/page.tsx` - Edit project page

**Server Actions created:**
- `createProject()` - Create new project
- `getProjects()` - List all user's projects (with filters)
- `getProject()` - Get single project by ID
- `updateProject()` - Update existing project
- `deleteProject()` - Delete project
- `toggleProjectStatus()` - Toggle is_active status
- `getProjectStats()` - Get project statistics via RPC

**Key concepts:**
- **CRUD Operations** - Create, Read, Update, Delete
- **Row Level Security** - Users can only access their own projects
- **Zod Validation** - Runtime input validation with type inference
- **RPC Functions** - Complex SQL queries on database server
- **Server Actions** - Type-safe data mutations without API routes
- **Revalidation** - `revalidatePath()` to refresh cached data
- **Optimistic Updates** - Instant UI feedback before server response
- **Date Validation** - End date must be after start date
- **Overdue Detection** - Projects past end date flagged as overdue

**Project features:**
- Create projects with name, description, dates, status
- View all projects with statistics
- Edit existing projects
- Delete projects (cascades to tasks and related data)
- Toggle project active/inactive status
- Filter projects by status and search
- Track completion rate and overdue projects

**Technologies:** Zod, Server Actions, RPC Functions, TypeScript

---

## Lesson 5: Task Management with Best Practices

**Reference:** `LESSON-5-PRACTICAL-GUIDE.md`

**What was built:**
- Task CRUD operations with `prj_tasks` table
- Extended `src/constants/index.ts` (from Lesson 1) with NEW task-specific values
- Applied Next.js 16 `use cache` directive to Server Actions (cacheComponents already enabled in Lesson 1)
- React 19.2 `useEffectEvent` hook implementation
- RPC functions for task queries and statistics
- Task management UI with SOLID principles

**Database changes:**
- Added RLS policies for `prj_tasks` table (SELECT, INSERT, UPDATE, DELETE)
- Created `get_tasks_by_project()` RPC function with filters
- Created `get_task_stats()` RPC function for analytics
- Added indexes for performance (status, priority, due_date)

**Key files created:**
- `src/lib/actions/tasks.ts` - Task CRUD Server Actions (with 'use cache')
- `src/lib/validations/task.ts` - Zod schemas using constants
- `src/lib/types/database.ts` - Task types and interfaces
- `src/components/features/tasks/TaskCard.tsx` - Display one task
- `src/components/features/tasks/TaskList.tsx` - Display task list
- `src/components/features/tasks/TaskForm.tsx` - Create/edit task form
- `src/components/features/tasks/TaskStats.tsx` - Task statistics dashboard
- `src/app/dashboard/projects/[id]/tasks/page.tsx` - Tasks list (Server Component with cache)
- `src/app/dashboard/projects/[id]/tasks/new/page.tsx` - Create task
- `src/app/dashboard/projects/[id]/tasks/[taskId]/page.tsx` - View task (Server Component with cache)
- `src/app/dashboard/projects/[id]/tasks/[taskId]/edit/page.tsx` - Edit task
- `src/hooks/useTaskTimer.ts` - Demo of useEffectEvent (optional)
- `supabase/migrations/003_task_rls_and_rpc.sql` - RLS + RPC functions

**Constants added to existing file (from Lesson 1):**
- `TASK_PRIORITY` - Low, Medium, High, Urgent (NEW!)
- `TASK_STATUS_LABELS` - Display labels for UI (NEW!)
- `TASK_PRIORITY_LABELS` - Display labels for UI (NEW!)
- `TASK_STATUS_COLORS` - Tailwind CSS classes for badges (NEW!)
- `TASK_PRIORITY_COLORS` - Tailwind CSS classes for badges (NEW!)
- `UI_LABELS` - Button labels, placeholders, form field labels (NEW!)
- Task routes - Added to existing ROUTES object (NEW!)
- `TaskPriority` type export (NEW!)

**Key concepts:**
- **Extending Constants** - Add new values to existing constants file (from Lesson 1)
- **Next.js 16 'use cache'** - Applied to Server Actions for read operations
- **Partial Prerendering (PPR)** - Enabled by cacheComponents (from Lesson 1)
- **React 19.2 useEffectEvent** - Avoid stale closures in effects
- **SOLID Principles** - Single Responsibility per component
- **DRY Principle** - Don't Repeat Yourself, extend constants
- **No Magic Strings** - All values from constants file
- **Type Safety** - TypeScript + constants = autocomplete everywhere
- **Cache Invalidation** - `revalidateTag()` after mutations
- **RPC Functions** - Complex task queries on database server

**Task features:**
- Create tasks with title, description, status, priority, due date
- Link tasks to projects (foreign key relationship)
- Filter tasks by status, priority, overdue
- Task statistics dashboard (counts, completion rate)
- Overdue detection (tasks past due date)
- Sort by priority and due date
- Full CRUD with RLS protection

**Technologies:** Next.js 16 Cache, React 19.2 useEffectEvent, Zod, RPC Functions, SOLID, DRY

---

## Lesson 6: Team Collaboration with Many-to-Many Relationships

**Reference:** `LESSON-6-PRACTICAL-GUIDE.md`

**What was built:**
- Many-to-many relationships between users and projects
- Role-based access control (Owner, Admin, Member, Viewer)
- Permission matrix system for granular access control
- Member invitation and management
- Role-based UI rendering
- Team member listing with role badges

**Database changes:**
- RLS policies for `prj_project_members` table
- RPC function: `get_project_members()` - List members with user details
- RPC function: `check_member_role()` - Get user's role and permissions
- RPC function: `get_user_projects()` - List projects user belongs to
- RPC function: `invite_member_by_email()` - Invite members with role validation

**Key files created:**
- `supabase/migrations/004_member_rls_and_rpc.sql` - Member RLS and RPC functions
- `src/constants/index.ts` - Member roles and permissions (EXTENDED)
- `src/lib/actions/members.ts` - Member CRUD Server Actions
- `src/lib/validations/member.ts` - Zod validation for member operations
- `src/utils/permissions.ts` - Permission checking utilities
- `src/components/features/members/MemberCard.tsx` - Member display card
- `src/components/features/members/MemberList.tsx` - Members list component
- `src/components/features/members/InviteMemberForm.tsx` - Invite member form
- `src/app/dashboard/projects/[id]/members/page.tsx` - Members management page

**Key concepts:**
- **Many-to-Many (M:N) Relationships** - Junction tables for user-project association
- **Role-Based Access Control (RBAC)** - Four role levels with different permissions
- **Permission Matrix** - Centralized permission definitions in constants
- **RPC for Complex Queries** - Join operations across multiple tables
- **Cascading Operations** - Removing members affects their tasks/data
- **Conditional UI Rendering** - Show/hide features based on user role

**Member features:**
- Invite members to projects by email with specific roles
- View all project members with their roles
- Update member roles (if authorized)
- Remove members from projects (if authorized)
- Check permissions before showing UI elements
- Track who invited each member

**Technologies:** RPC Functions, Junction Tables, Permission Systems, RBAC

---

## Lesson 7: Real-time Updates with Supabase Subscriptions

**Reference:** `LESSON-7-PRACTICAL-GUIDE.md`

**What was built:**
- Real-time task updates using Supabase Realtime
- Real-time member presence tracking
- Custom event broadcasting between clients
- Connection state management
- Optimistic UI updates
- Typing indicators (broadcast example)

**Key files created:**
- `src/constants/index.ts` - Realtime events and connection status (EXTENDED)
- `src/types/realtime.ts` - TypeScript types for realtime features
- `src/hooks/realtime/useRealtimeSubscription.ts` - Base subscription hook
- `src/hooks/realtime/useTaskSubscription.ts` - Task-specific subscription
- `src/hooks/realtime/usePresence.ts` - Presence tracking hook
- `src/hooks/realtime/useBroadcast.ts` - Custom event broadcasting
- `src/components/features/realtime/ConnectionStatus.tsx` - Connection indicator
- `src/components/features/realtime/OnlineUsers.tsx` - Online users display
- `src/components/features/realtime/TypingIndicator.tsx` - Typing indicator component
- `src/components/features/tasks/TaskListRealtime.tsx` - Real-time task list
- `src/app/globals.css` - Animation styles (EXTENDED)

**Key concepts:**
- **PostgreSQL Changes** - Listen to database INSERT/UPDATE/DELETE events
- **Broadcast Channels** - Send ephemeral messages between clients
- **Presence Tracking** - Track who's currently viewing a project
- **WebSocket Connections** - Persistent connections for real-time updates
- **Automatic Cleanup** - Unsubscribe when components unmount
- **RLS for Realtime** - Row Level Security applies to realtime events
- **Connection State** - Handle connecting/connected/disconnected states

**Realtime features:**
- See task updates instantly when team members make changes
- Track which team members are currently online
- Show typing indicators in collaborative features
- Handle connection drops gracefully with reconnection
- Optimistic UI updates before server confirmation

**Technologies:** Supabase Realtime, WebSockets, PostgreSQL WAL, React hooks

---

## Lesson 8: File Uploads with Supabase Storage

**Reference:** `LESSON-8-PRACTICAL-GUIDE.md`

**What was built:**
- File upload system with Supabase Storage
- Storage buckets for project and task attachments
- File validation (size, type, count)
- Upload progress tracking
- Image previews and thumbnails
- Signed URLs for secure downloads
- File management (view, download, delete)

**Database changes:**
- Created `prj_project_attachments` table
- Created `prj_task_attachments` table
- RLS policies for attachment tables
- RPC function: `get_project_attachments()` - List attachments with uploader info
- RPC function: `get_task_attachments()` - List task attachments

**Storage setup:**
- Storage bucket: `project-attachments` (private, RLS enforced)
- Storage bucket: `task-attachments` (private, RLS enforced)
- Storage policies for upload/download/delete operations

**Key files created:**
- `supabase/migrations/005_attachments.sql` - Attachment tables and RLS
- `src/constants/index.ts` - Storage and file upload constants (EXTENDED)
- `src/types/storage.ts` - TypeScript types for storage operations
- `src/utils/storage/fileValidation.ts` - File validation utilities
- `src/lib/actions/storage.ts` - Storage Server Actions
- `src/components/ui/FileUpload.tsx` - Reusable file upload component
- `src/components/features/attachments/AttachmentList.tsx` - Attachments display
- `src/components/features/attachments/ProjectAttachmentsClient.tsx` - Client component
- `src/app/dashboard/projects/[id]/attachments/page.tsx` - Attachments page

**Key concepts:**
- **Object Storage** - S3-compatible file storage
- **Storage Policies** - RLS for storage buckets (not just database)
- **Signed URLs** - Time-limited, secure download links
- **FormData Uploads** - Upload files from browser to server
- **File Validation** - Client and server-side validation
- **Progress Tracking** - Show upload progress percentage
- **Cascading Deletes** - Delete files when attachments are removed

**File upload features:**
- Upload images, documents, and spreadsheets
- Real-time progress tracking with percentage
- Preview images before and after upload
- Download files with original filenames
- Delete attachments (files and database records)
- Validate file size (max 5MB) and type
- Limit number of files per upload (max 10)

**Technologies:** Supabase Storage, FormData, Signed URLs, File API

---

## Lesson 9: Search & Filtering with Full-Text Search

**Reference:** `LESSON-9-PRACTICAL-GUIDE.md`

**What was built:**
- PostgreSQL full-text search across multiple fields
- Advanced filtering (status, priority, date ranges, multi-select)
- Search highlighting with marked text
- Debounced search input for performance
- Autocomplete search suggestions
- Pagination (offset-based)
- Multiple sort options (relevance, date, priority, title)
- URL state management for filters

**Database changes:**
- Added `search_vector` tsvector column to `prj_tasks` and `prj_projects`
- Triggers to automatically update search vectors on INSERT/UPDATE
- GIN indexes for fast full-text search
- RPC function: `search_tasks()` - Advanced search with filters and sorting
- RPC function: `search_task_suggestions()` - Autocomplete suggestions
- RPC function: `count_tasks()` - Total count for pagination

**Key files created:**
- `supabase/migrations/006_full_text_search.sql` - Full-text search setup
- `src/constants/index.ts` - Search and filter constants (EXTENDED)
- `src/utils/search/debounce.ts` - Debouncing utilities
- `src/utils/search/highlight.ts` - Search highlighting utilities
- `src/lib/actions/tasks.ts` - Search Server Actions (EXTENDED)
- `src/hooks/search/useSearch.ts` - Search hook with debouncing
- `src/hooks/search/useFilters.ts` - Filter management hook
- `src/components/features/search/SearchInput.tsx` - Search input with autocomplete
- `src/components/features/search/MultiSelectFilter.tsx` - Multi-select filter component
- `src/app/dashboard/tasks/search/page.tsx` - Search page

**Key concepts:**
- **Full-Text Search** - PostgreSQL tsvector and tsquery
- **Search Vectors** - Indexed text for fast lookups
- **Relevance Ranking** - ts_rank to sort by best matches
- **GIN Indexes** - Generalized Inverted Index for performance
- **Debouncing** - Delay API calls until user stops typing
- **URL as State** - Persist search and filters in query params
- **Pagination** - Offset/limit with total count
- **Multi-Select Filters** - Combine multiple filter values

**Search features:**
- Search across task title and description
- Auto-complete suggestions as user types
- Filter by status, priority, due date
- Sort by relevance, date, priority, or title
- Highlight matching search terms in results
- Paginate through large result sets
- Preserve search state in URL (shareable links)
- Combine search with multiple filters

**Technologies:** PostgreSQL Full-Text Search, tsvector, tsquery, GIN indexes, Debouncing

---

## Lesson 10: Production Deployment to Vercel

**Reference:** `LESSON-10-PRACTICAL-GUIDE.md`

**What was built:**
- Production deployment to Vercel platform
- Environment variables management
- Supabase production project setup
- Database connection pooling for serverless
- Custom domain configuration
- Security headers (CSP, HSTS, X-Frame-Options)
- Performance monitoring with Vercel Analytics
- Error tracking and health checks
- CI/CD with GitHub integration

**Production setup:**
- Vercel project configuration
- Production environment variables
- Supabase Pro tier with connection pooling
- Custom domain with SSL certificate
- Security headers in next.config.ts
- Global error boundary
- Health check API endpoint

**Key files created:**
- `.env.production.example` - Production environment template
- `vercel.json` - Vercel deployment configuration
- `next.config.ts` - Production optimizations (UPDATED)
- `src/utils/env.ts` - Environment utilities
- `src/utils/logger.ts` - Production logging utility
- `src/app/error.tsx` - Global error boundary
- `src/app/api/health/route.ts` - Health check endpoint
- `.github/ISSUE_TEMPLATE/deployment-checklist.md` - Deployment checklist

**Key concepts:**
- **Serverless Deployment** - Vercel's edge network
- **Connection Pooling** - PgBouncer for database connections
- **Environment Management** - Separate dev/preview/production variables
- **Security Headers** - Protect against XSS, clickjacking, MIME sniffing
- **Performance Monitoring** - Track real user metrics
- **CI/CD** - Automatic deployments from GitHub
- **Health Checks** - Monitor application and database status
- **Error Boundaries** - Graceful error handling in production

**Production features:**
- Automatic deployments on git push
- Preview deployments for pull requests
- Custom domain with automatic SSL
- Connection pooling for database (no "too many connections" errors)
- Security headers (HSTS, CSP, X-Frame-Options)
- Performance monitoring and analytics
- Error tracking and logging
- Health check endpoint for monitoring
- Production-optimized builds (compression, minification)

**Technologies:** Vercel, GitHub Actions, Vercel Analytics, Production PostgreSQL, PgBouncer

---

## Lesson 11: Payments & Subscriptions with Stripe

**Reference:** `LESSON-11-PRACTICAL-GUIDE.md`

**What was built:**
- Complete Stripe payment integration
- Freemium model (2 free projects, paid plans for more)
- Stripe Checkout for subscription payments
- Customer billing portal for self-service
- Webhook handling for payment events
- Pricing page with multiple tiers
- Billing dashboard with usage stats
- Payment history tracking

**Business Model:**
- Free Tier: 2 projects, 3 members per project, 100 MB storage
- Pro Tier ($10/month): 10 projects, 10 members per project, 5 GB storage
- Team Tier ($25/month): Unlimited projects and members, 50 GB storage

**Database changes:**
- Created `prj_user_subscriptions` table
- Created `prj_payment_history` table
- Trigger to auto-create free subscription on user signup
- RPC function: `get_user_subscription()` - Get subscription with usage stats
- RPC function: `can_create_project()` - Check if user can create project
- RPC function: `get_payment_history()` - List all payments for user

**Key files created:**
- `supabase/migrations/007_subscriptions.sql` - Subscription tables and RLS
- `src/constants/index.ts` - Subscription plans and limits (EXTENDED)
- `src/types/subscription.ts` - TypeScript types for subscriptions
- `src/lib/stripe/client.ts` - Client-side Stripe.js
- `src/lib/stripe/server.ts` - Server-side Stripe API
- `src/lib/actions/subscriptions.ts` - Subscription Server Actions
- `src/app/api/webhooks/stripe/route.ts` - Stripe webhook handler
- `src/app/pricing/page.tsx` - Public pricing page
- `src/app/dashboard/billing/page.tsx` - Billing dashboard
- `src/app/dashboard/billing/success/page.tsx` - Checkout success page
- `src/app/dashboard/billing/cancel/page.tsx` - Checkout cancel page
- `src/components/features/billing/PricingCard.tsx` - Pricing card component
- `src/components/features/billing/BillingOverview.tsx` - Subscription overview
- `src/components/features/billing/PaymentHistoryTable.tsx` - Payment history display
- `src/components/features/projects/UpgradePrompt.tsx` - Upgrade prompt component
- `src/lib/actions/projects.ts` - Added subscription limit check (UPDATED)

**Key concepts:**
- **Freemium Model** - Free tier with usage limits
- **Stripe Checkout** - Hosted payment pages
- **Subscription Lifecycle** - Create, upgrade, downgrade, cancel
- **Webhook Security** - Verify signatures, process events
- **Customer Portal** - Self-service billing management
- **Usage Enforcement** - Database-level limit checking
- **RLS for Subscriptions** - Secure subscription data
- **Payment Events** - Handle success, failure, cancellation

**Subscription features:**
- Create Stripe Checkout sessions
- Process subscription webhooks (checkout, updates, cancellations)
- Track payment history in database
- Display current plan and usage
- Enforce project creation limits based on plan
- Customer billing portal for plan management
- Automatic free subscription on signup
- Upgrade prompts when limits reached
- Support for multiple pricing tiers

**Technologies:** Stripe, Stripe Checkout, Stripe Customer Portal, Stripe Webhooks, Stripe CLI

---
## Learning Progression Summary

**Lesson 1:** Setup → Next.js project foundation + constants.ts
**Lesson 2:** Database → Supabase tables, RLS, migrations
**Lesson 3:** Authentication → Login, signup, protected routes, UI components, E2E testing
**Lesson 4:** CRUD → Full project management with Server Actions, validation, analytics
**Lesson 5:** Tasks → Task CRUD, Next.js 16 cache, React 19.2 useEffectEvent, SOLID/DRY best practices
**Lesson 6:** Team Collaboration → Many-to-many relationships, RBAC, permission matrix
**Lesson 7:** Real-time → Supabase Realtime subscriptions, presence, broadcast events
**Lesson 8:** File Storage → Supabase Storage, file uploads, signed URLs, image previews
**Lesson 9:** Search → Full-text search, advanced filtering, pagination, autocomplete
**Lesson 10:** Deployment → Production deployment to Vercel, monitoring, security
**Lesson 11:** Payments → Stripe subscriptions, freemium model, billing management

---

## Key Technologies Used Across All Lessons

**Frontend:**
- Next.js 16 (App Router)
- React 19.2 (Server Components + Client Components)
- TypeScript (strict type checking)
- Tailwind CSS (utility-first styling)

**Backend:**
- Supabase (PostgreSQL database)
- Supabase Auth (authentication)
- Row Level Security (RLS policies)
- Server Actions (data mutations)
- RPC Functions (complex queries)

**Validation & Types:**
- Zod (runtime validation)
- TypeScript (compile-time type checking)
- Database-generated types

**Testing:**
- Playwright (E2E testing)
- Accessible test selectors
- AI-assisted code review

**Development Practices:**
- Database migrations (version control)
- Server-side authentication checks
- Reusable component patterns
- Type-safe API interactions
- Progressive enhancement
- Security-first approach (RLS, CSRF protection)

---

## Reference Files Location

**Configuration Files:** `reference/`
- `.env.local.example` - Environment variables template
- `.gitignore` - Git ignore patterns
- `next.config.ts` - Next.js configuration
- `proxy.ts` - Session refresh middleware
- `tsconfig.json` - TypeScript configuration
- `LESSON-1-SCRIPT-USAGE.md` - Automated setup script
- `REUSABLE-FEATURES-REFERENCE.md` - Comprehensive code patterns

**Archived Documentation:** `docs-archive/`
- Previous lesson versions and guides

**Main Lessons:** Root directory
- `LESSON-1-PRACTICAL-GUIDE.md` - Next.js 16 setup with TypeScript and constants
- `LESSON-2-PRACTICAL-GUIDE.md` - Supabase database with RLS and migrations
- `LESSON-3-PRACTICAL-GUIDE.md` - Authentication with protected routes
- `LESSON-4-PRACTICAL-GUIDE.md` - Project CRUD operations
- `LESSON-5-PRACTICAL-GUIDE.md` - Task management with best practices
- `LESSON-6-PRACTICAL-GUIDE.md` - Team collaboration with M:N relationships
- `LESSON-7-PRACTICAL-GUIDE.md` - Real-time updates with Supabase subscriptions
- `LESSON-8-PRACTICAL-GUIDE.md` - File uploads with Supabase Storage
- `LESSON-9-PRACTICAL-GUIDE.md` - Search & filtering with full-text search
- `LESSON-10-PRACTICAL-GUIDE.md` - Production deployment to Vercel
- `LESSON-11-PRACTICAL-GUIDE.md` - Payments & subscriptions with Stripe
