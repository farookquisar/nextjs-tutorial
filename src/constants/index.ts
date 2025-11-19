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
