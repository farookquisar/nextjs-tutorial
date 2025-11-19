# Module 1, Lesson 3 — Authentication with Supabase Auth

**Prerequisites:** Complete Lesson 1 (Next.js Setup) and Lesson 2 (Supabase Setup)

---

## 📖 1. DESC

### What is Authentication?

**Authentication** is verifying who a user is (login/signup). **Authorization** is verifying what they can access (permissions).

In this lesson, we'll implement:
- **Email/Password** authentication with Supabase Auth
- **Login and Signup** pages with form validation
- **Protected Routes** using proxy.ts helpers from Lesson 2
- **Server Actions** for secure auth operations
- **Auth State Management** with React hooks
- **Logout** functionality
- **Email Confirmation** flow (optional)

### What You'll Build

```
📁 Your App Structure (After This Lesson)
├── src/
│   ├── app/
│   │   ├── (auth)/              ← NEW: Auth routes group
│   │   │   ├── login/
│   │   │   │   └── page.tsx     ← Login page
│   │   │   └── signup/
│   │   │       └── page.tsx     ← Signup page
│   │   ├── dashboard/           ← NEW: Protected route
│   │   │   └── page.tsx         ← Dashboard (requires auth)
│   │   └── auth/
│   │       └── callback/
│   │           └── route.ts     ← OAuth callback handler
│   ├── components/
│   │   ├── features/auth/
│   │   │   ├── LoginForm.tsx    ← NEW: Login form component
│   │   │   ├── SignupForm.tsx   ← NEW: Signup form component
│   │   │   └── LogoutButton.tsx ← NEW: Logout button
│   │   └── ui/
│   │       ├── Button.tsx       ← NEW: Reusable button
│   │       ├── Input.tsx        ← NEW: Reusable input
│   │       ├── Select.tsx       ← NEW: Reusable select/dropdown list
│   │       ├── Dropdown.tsx     ← NEW: Reusable dropdown menu
│   │       └── Modal.tsx        ← NEW: Reusable modal dialog
│   ├── lib/
│   │   └── actions/
│   │       └── auth.ts          ← NEW: Server actions for auth
│   └── hooks/
│       └── useAuth.ts           ← NEW: Auth state hook
```

### Why This Approach?

✅ **Secure** - Server actions prevent CSRF attacks
✅ **Type-safe** - Full TypeScript coverage
✅ **DRY** - Reusable components and actions
✅ **Simple** - No complex state management needed
✅ **Production-ready** - Email confirmation, error handling
✅ **SEO-friendly** - Server-side auth checks

---

## 🎯 2. STEPS

### 🎯 STEP 1 — Create Reusable UI Components

First, let's create reusable Button and Input components following shadcn/ui patterns.

**Create Button component:**

```bash
cat > src/components/ui/Button.tsx << 'BUTTON_EOF'
import { ButtonHTMLAttributes, forwardRef } from 'react'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'outline' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  isLoading?: boolean
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({
    children,
    variant = 'default',
    size = 'md',
    isLoading = false,
    disabled,
    className = '',
    ...props
  }, ref) => {
    const baseStyles = 'inline-flex items-center justify-center font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none'

    const variants = {
      default: 'bg-blue-600 text-white hover:bg-blue-700 focus-visible:ring-blue-500',
      outline: 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus-visible:ring-gray-500',
      ghost: 'text-gray-700 hover:bg-gray-100 focus-visible:ring-gray-500',
      danger: 'bg-red-600 text-white hover:bg-red-700 focus-visible:ring-red-500',
    }

    const sizes = {
      sm: 'px-3 py-1.5 text-sm rounded-md',
      md: 'px-4 py-2 text-base rounded-md',
      lg: 'px-6 py-3 text-lg rounded-lg',
    }

    return (
      <button
        ref={ref}
        disabled={disabled || isLoading}
        className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${className}`}
        {...props}
      >
        {isLoading ? (
          <>
            <svg className="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Loading...
          </>
        ) : (
          children
        )}
      </button>
    )
  }
)

Button.displayName = 'Button'
BUTTON_EOF

# Verify file created
cat src/components/ui/Button.tsx | head -20
```

**Create Input component:**

```bash
cat > src/components/ui/Input.tsx << 'INPUT_EOF'
import { InputHTMLAttributes, forwardRef } from 'react'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  helperText?: string
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, className = '', ...props }, ref) => {
    const inputId = props.id || props.name

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={inputId}
          className={`
            w-full px-3 py-2 border rounded-md shadow-sm
            focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
            disabled:bg-gray-100 disabled:cursor-not-allowed
            ${error ? 'border-red-500' : 'border-gray-300'}
            ${className}
          `}
          {...props}
        />
        {error && (
          <p className="mt-1 text-sm text-red-600">{error}</p>
        )}
        {helperText && !error && (
          <p className="mt-1 text-sm text-gray-500">{helperText}</p>
        )}
      </div>
    )
  }
)

Input.displayName = 'Input'
INPUT_EOF

# Verify file created
cat src/components/ui/Input.tsx | head -20
```

**Create Select component:**

```bash
cat > src/components/ui/Select.tsx << 'SELECT_EOF'
import { SelectHTMLAttributes, forwardRef } from 'react'

interface SelectOption {
  value: string
  label: string
  disabled?: boolean
}

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string
  error?: string
  helperText?: string
  options: SelectOption[]
  placeholder?: string
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, helperText, options, placeholder, className = '', ...props }, ref) => {
    const selectId = props.id || props.name

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={selectId}
            className="block text-sm font-medium text-gray-700 mb-1"
          >
            {label}
          </label>
        )}
        <select
          ref={ref}
          id={selectId}
          className={`
            w-full px-3 py-2 border rounded-md shadow-sm
            focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
            disabled:bg-gray-100 disabled:cursor-not-allowed
            ${error ? 'border-red-500' : 'border-gray-300'}
            ${className}
          `}
          {...props}
        >
          {placeholder && (
            <option value="" disabled>
              {placeholder}
            </option>
          )}
          {options.map((option) => (
            <option
              key={option.value}
              value={option.value}
              disabled={option.disabled}
            >
              {option.label}
            </option>
          ))}
        </select>
        {error && (
          <p className="mt-1 text-sm text-red-600">{error}</p>
        )}
        {helperText && !error && (
          <p className="mt-1 text-sm text-gray-500">{helperText}</p>
        )}
      </div>
    )
  }
)

Select.displayName = 'Select'
SELECT_EOF

# Verify file created
cat src/components/ui/Select.tsx | head -20
```

**Create Dropdown component:**

```bash
cat > src/components/ui/Dropdown.tsx << 'DROPDOWN_EOF'
'use client'

import { useState, useRef, useEffect, ReactNode } from 'react'

interface DropdownItem {
  label: string
  onClick: () => void
  icon?: ReactNode
  danger?: boolean
  disabled?: boolean
}

interface DropdownProps {
  trigger: ReactNode
  items: DropdownItem[]
  align?: 'left' | 'right'
}

export function Dropdown({ trigger, items, align = 'right' }: DropdownProps) {
  const [isOpen, setIsOpen] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside)
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isOpen])

  // Close on Escape key
  useEffect(() => {
    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setIsOpen(false)
      }
    }

    if (isOpen) {
      document.addEventListener('keydown', handleEscape)
    }

    return () => {
      document.removeEventListener('keydown', handleEscape)
    }
  }, [isOpen])

  return (
    <div className="relative inline-block" ref={dropdownRef}>
      <div onClick={() => setIsOpen(!isOpen)}>
        {trigger}
      </div>

      {isOpen && (
        <div
          className={`
            absolute z-50 mt-2 w-56 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5
            ${align === 'right' ? 'right-0' : 'left-0'}
          `}
        >
          <div className="py-1" role="menu">
            {items.map((item, index) => (
              <button
                key={index}
                onClick={() => {
                  if (!item.disabled) {
                    item.onClick()
                    setIsOpen(false)
                  }
                }}
                disabled={item.disabled}
                className={`
                  w-full text-left px-4 py-2 text-sm flex items-center gap-2
                  transition-colors
                  ${item.danger
                    ? 'text-red-700 hover:bg-red-50'
                    : 'text-gray-700 hover:bg-gray-100'
                  }
                  ${item.disabled
                    ? 'opacity-50 cursor-not-allowed'
                    : 'cursor-pointer'
                  }
                `}
                role="menuitem"
              >
                {item.icon && <span>{item.icon}</span>}
                <span>{item.label}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
DROPDOWN_EOF

# Verify file created
cat src/components/ui/Dropdown.tsx | head -30
```

**Create Modal component:**

```bash
cat > src/components/ui/Modal.tsx << 'MODAL_EOF'
'use client'

import { ReactNode, useEffect } from 'react'
import { Button } from './Button'

interface ModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  children: ReactNode
  footer?: ReactNode
  size?: 'sm' | 'md' | 'lg' | 'xl'
}

export function Modal({
  isOpen,
  onClose,
  title,
  children,
  footer,
  size = 'md'
}: ModalProps) {
  // Close on Escape key
  useEffect(() => {
    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        onClose()
      }
    }

    if (isOpen) {
      document.addEventListener('keydown', handleEscape)
      // Prevent body scroll when modal is open
      document.body.style.overflow = 'hidden'
    }

    return () => {
      document.removeEventListener('keydown', handleEscape)
      document.body.style.overflow = 'unset'
    }
  }, [isOpen, onClose])

  if (!isOpen) return null

  const sizes = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl',
  }

  return (
    <div
      className="fixed inset-0 z-50 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="flex min-h-full items-center justify-center p-4">
        <div
          className={`
            relative transform overflow-hidden rounded-lg bg-white
            shadow-xl transition-all w-full ${sizes[size]}
          `}
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="border-b border-gray-200 px-6 py-4">
            <div className="flex items-center justify-between">
              <h3
                className="text-lg font-semibold text-gray-900"
                id="modal-title"
              >
                {title}
              </h3>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500 focus:outline-none"
              >
                <span className="sr-only">Close</span>
                <svg
                  className="h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
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
          </div>

          {/* Body */}
          <div className="px-6 py-4">
            {children}
          </div>

          {/* Footer */}
          {footer && (
            <div className="border-t border-gray-200 px-6 py-4 bg-gray-50">
              {footer}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// Common modal footer with Cancel and Confirm buttons
interface ModalFooterProps {
  onCancel: () => void
  onConfirm: () => void
  confirmText?: string
  cancelText?: string
  confirmVariant?: 'default' | 'danger'
  isLoading?: boolean
}

export function ModalFooter({
  onCancel,
  onConfirm,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  confirmVariant = 'default',
  isLoading = false,
}: ModalFooterProps) {
  return (
    <div className="flex justify-end gap-3">
      <Button
        onClick={onCancel}
        variant="outline"
        disabled={isLoading}
      >
        {cancelText}
      </Button>
      <Button
        onClick={onConfirm}
        variant={confirmVariant}
        isLoading={isLoading}
      >
        {confirmText}
      </Button>
    </div>
  )
}
MODAL_EOF

# Verify file created
cat src/components/ui/Modal.tsx | head -40
```

<details>
<summary>📖 <strong>Why these UI components?</strong></summary>

### Reusable UI Components

**Button Component:**
- **Variants**: default (blue), outline (white), ghost (transparent), danger (red)
- **Sizes**: sm, md, lg for different contexts
- **Loading state**: Built-in spinner with `isLoading` prop
- **Accessibility**: `forwardRef` for focus management, disabled states
- **Type-safe**: Extends native `ButtonHTMLAttributes`

**Input Component:**
- **Label**: Automatically linked with `htmlFor`
- **Error handling**: Red border and error message
- **Helper text**: Gray text for instructions
- **Accessibility**: Proper label associations
- **Type-safe**: Extends native `InputHTMLAttributes`

**Select Component:**
- **Options array**: Pass array of `{value, label, disabled?}` objects
- **Placeholder**: Optional placeholder text
- **Error handling**: Same as Input component
- **Accessibility**: Proper label associations, disabled options
- **Type-safe**: Extends native `SelectHTMLAttributes`

**Dropdown Component:**
- **Click outside to close**: Auto-closes when clicking outside
- **Escape key support**: Press Escape to close
- **Alignment**: Left or right alignment
- **Icons**: Optional icons for menu items
- **Danger items**: Red styling for destructive actions
- **Disabled items**: Visual and functional disabled state
- **Type-safe**: Custom DropdownItem interface

**Modal Component:**
- **Backdrop**: Dark overlay with click-to-close
- **Escape key**: Press Escape to close
- **Body scroll lock**: Prevents scrolling when modal is open
- **Sizes**: sm, md, lg, xl for different content amounts
- **Custom footer**: Pass any ReactNode as footer
- **ModalFooter helper**: Pre-built Cancel/Confirm footer
- **Accessible**: ARIA attributes for screen readers
- **Type-safe**: All props typed

**Benefits:**
1. **Consistent design** - Same look across all forms
2. **Less code** - Reuse instead of duplicate
3. **Accessible** - Built-in ARIA attributes, keyboard navigation
4. **Type-safe** - TypeScript catches errors
5. **Customizable** - Easy to extend with className
6. **Production-ready** - Handles edge cases (click outside, escape key, scroll lock)

</details>

---

### 🎯 STEP 2 — Create Auth Server Actions

Create server actions for authentication operations.

```bash
cat > src/lib/actions/auth.ts << 'AUTH_ACTIONS_EOF'
'use server'

import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'

/**
 * Sign up a new user with email and password
 */
export async function signUp(formData: FormData) {
  const email = formData.get('email') as string
  const password = formData.get('password') as string
  const confirmPassword = formData.get('confirmPassword') as string

  // Validation
  if (!email || !password) {
    return { error: 'Email and password are required' }
  }

  if (password !== confirmPassword) {
    return { error: 'Passwords do not match' }
  }

  if (password.length < 8) {
    return { error: 'Password must be at least 8 characters' }
  }

  const supabase = await createClient()

  // Sign up user
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      // Optional: Redirect URL after email confirmation
      emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'}/auth/callback`,
    },
  })

  if (error) {
    return { error: error.message }
  }

  // Check if email confirmation is required
  if (data.user && !data.user.confirmed_at) {
    return {
      success: true,
      message: 'Check your email to confirm your account!'
    }
  }

  // User is created and confirmed
  redirect('/dashboard')
}

/**
 * Sign in existing user with email and password
 */
export async function signIn(formData: FormData) {
  const email = formData.get('email') as string
  const password = formData.get('password') as string

  // Validation
  if (!email || !password) {
    return { error: 'Email and password are required' }
  }

  const supabase = await createClient()

  // Sign in user
  const { error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    return { error: error.message }
  }

  // Successful login
  redirect('/dashboard')
}

/**
 * Sign out current user
 */
export async function signOut() {
  const supabase = await createClient()

  const { error } = await supabase.auth.signOut()

  if (error) {
    return { error: error.message }
  }

  redirect('/login')
}

/**
 * Get current user (for server components)
 */
export async function getCurrentUser() {
  const supabase = await createClient()

  const { data: { user }, error } = await supabase.auth.getUser()

  if (error) {
    return null
  }

  return user
}
AUTH_ACTIONS_EOF

# Verify file created
cat src/lib/actions/auth.ts | head -30
```

<details>
<summary>📖 <strong>Understanding Server Actions</strong></summary>

### Server Actions for Authentication

**What are Server Actions?**
- Functions that run on the server (not the browser)
- Marked with `'use server'` directive
- Called directly from client components
- Automatic CSRF protection
- Progressive enhancement (work without JavaScript)

**Why use Server Actions for auth?**
1. **Secure** - Credentials never exposed to client
2. **Simple** - No API routes needed
3. **Type-safe** - Full TypeScript support
4. **Modern** - React 19.2 feature
5. **Fast** - Direct function calls

**Server Action Flow:**
```
Client Component (form submit)
    ↓
Server Action (auth.ts)
    ↓
Supabase Auth API
    ↓
Database (create user/session)
    ↓
Redirect to dashboard
```

**Key Functions:**

**signUp():**
- Validates email and password
- Checks password confirmation
- Creates new user in Supabase
- Sends confirmation email (optional)
- Redirects to dashboard or shows message

**signIn():**
- Validates credentials
- Checks user exists and password matches
- Creates session cookie
- Redirects to dashboard

**signOut():**
- Clears session cookie
- Invalidates JWT tokens
- Redirects to login

**getCurrentUser():**
- Gets authenticated user from session
- Returns null if not authenticated
- Used in protected routes

</details>

---

### 🎯 STEP 3 — Create Auth Hook for Client Components

```bash
cat > src/hooks/useAuth.ts << 'USE_AUTH_EOF'
'use client'

import { useEffect, useState } from 'react'
import { User } from '@supabase/supabase-js'
import { createClient } from '@/lib/supabase/client'

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    // Get initial session
    const getUser = async () => {
      const { data: { user } } = await supabase.auth.getUser()
      setUser(user)
      setLoading(false)
    }

    getUser()

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setUser(session?.user ?? null)
        setLoading(false)
      }
    )

    return () => {
      subscription.unsubscribe()
    }
  }, [supabase])

  return { user, loading }
}
USE_AUTH_EOF

# Verify file created
cat src/hooks/useAuth.ts
```

---

### 🎯 STEP 4 — Create Login Form Component

```bash
cat > src/components/features/auth/LoginForm.tsx << 'LOGIN_FORM_EOF'
'use client'

import { useState } from 'react'
import { signIn } from '@/lib/actions/auth'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import Link from 'next/link'

export function LoginForm() {
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  async function handleSubmit(formData: FormData) {
    setIsLoading(true)
    setError(null)

    const result = await signIn(formData)

    if (result?.error) {
      setError(result.error)
      setIsLoading(false)
    }
    // Success: redirect happens in server action
  }

  return (
    <div className="w-full max-w-md mx-auto p-6">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Welcome Back</h1>
        <p className="text-gray-600">Sign in to your account</p>
      </div>

      <form action={handleSubmit} className="space-y-4">
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        <Input
          type="email"
          name="email"
          label="Email"
          placeholder="you@example.com"
          required
          autoComplete="email"
        />

        <Input
          type="password"
          name="password"
          label="Password"
          placeholder="••••••••"
          required
          autoComplete="current-password"
        />

        <Button
          type="submit"
          className="w-full"
          isLoading={isLoading}
        >
          Sign In
        </Button>

        <div className="text-center text-sm text-gray-600">
          Don't have an account?{' '}
          <Link href="/signup" className="text-blue-600 hover:underline font-medium">
            Sign up
          </Link>
        </div>
      </form>
    </div>
  )
}
LOGIN_FORM_EOF

# Verify file created
cat src/components/features/auth/LoginForm.tsx | head -30
```

---

### 🎯 STEP 5 — Create Signup Form Component

```bash
cat > src/components/features/auth/SignupForm.tsx << 'SIGNUP_FORM_EOF'
'use client'

import { useState } from 'react'
import { signUp } from '@/lib/actions/auth'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import Link from 'next/link'

export function SignupForm() {
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  async function handleSubmit(formData: FormData) {
    setIsLoading(true)
    setError(null)
    setMessage(null)

    const result = await signUp(formData)

    if (result?.error) {
      setError(result.error)
      setIsLoading(false)
    } else if (result?.message) {
      setMessage(result.message)
      setIsLoading(false)
    }
    // Success with redirect: redirect happens in server action
  }

  return (
    <div className="w-full max-w-md mx-auto p-6">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Create Account</h1>
        <p className="text-gray-600">Sign up to get started</p>
      </div>

      <form action={handleSubmit} className="space-y-4">
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {message && (
          <div className="p-3 bg-green-50 border border-green-200 rounded-md">
            <p className="text-sm text-green-600">{message}</p>
          </div>
        )}

        <Input
          type="email"
          name="email"
          label="Email"
          placeholder="you@example.com"
          required
          autoComplete="email"
        />

        <Input
          type="password"
          name="password"
          label="Password"
          placeholder="••••••••"
          required
          autoComplete="new-password"
          helperText="Must be at least 8 characters"
        />

        <Input
          type="password"
          name="confirmPassword"
          label="Confirm Password"
          placeholder="••••••••"
          required
          autoComplete="new-password"
        />

        <Button
          type="submit"
          className="w-full"
          isLoading={isLoading}
        >
          Sign Up
        </Button>

        <div className="text-center text-sm text-gray-600">
          Already have an account?{' '}
          <Link href="/login" className="text-blue-600 hover:underline font-medium">
            Sign in
          </Link>
        </div>
      </form>
    </div>
  )
}
SIGNUP_FORM_EOF

# Verify file created
cat src/components/features/auth/SignupForm.tsx | head -30
```

---

### 🎯 STEP 6 — Create Logout Button Component

```bash
cat > src/components/features/auth/LogoutButton.tsx << 'LOGOUT_BUTTON_EOF'
'use client'

import { useState } from 'react'
import { signOut } from '@/lib/actions/auth'
import { Button } from '@/components/ui/Button'

interface LogoutButtonProps {
  variant?: 'default' | 'outline' | 'ghost' | 'danger'
  children?: React.ReactNode
}

export function LogoutButton({ variant = 'outline', children }: LogoutButtonProps) {
  const [isLoading, setIsLoading] = useState(false)

  async function handleLogout() {
    setIsLoading(true)
    await signOut()
    // Redirect happens in server action
  }

  return (
    <Button
      onClick={handleLogout}
      variant={variant}
      isLoading={isLoading}
    >
      {children || 'Sign Out'}
    </Button>
  )
}
LOGOUT_BUTTON_EOF

# Verify file created
cat src/components/features/auth/LogoutButton.tsx
```

---

### 🎯 STEP 7 — Create Login Page

```bash
# Create (auth) route group directory
mkdir -p src/app/\(auth\)/login

cat > src/app/\(auth\)/login/page.tsx << 'LOGIN_PAGE_EOF'
import { redirect } from 'next/navigation'
import { getCurrentUser } from '@/lib/actions/auth'
import { LoginForm } from '@/components/features/auth/LoginForm'

export const metadata = {
  title: 'Login',
  description: 'Sign in to your account',
}

export default async function LoginPage() {
  // Redirect if already logged in
  const user = await getCurrentUser()
  if (user) {
    redirect('/dashboard')
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-gray-50">
      <LoginForm />
    </main>
  )
}
LOGIN_PAGE_EOF

# Verify file created
cat src/app/\(auth\)/login/page.tsx
```

---

### 🎯 STEP 8 — Create Signup Page

```bash
# Create signup directory
mkdir -p src/app/\(auth\)/signup

cat > src/app/\(auth\)/signup/page.tsx << 'SIGNUP_PAGE_EOF'
import { redirect } from 'next/navigation'
import { getCurrentUser } from '@/lib/actions/auth'
import { SignupForm } from '@/components/features/auth/SignupForm'

export const metadata = {
  title: 'Sign Up',
  description: 'Create a new account',
}

export default async function SignupPage() {
  // Redirect if already logged in
  const user = await getCurrentUser()
  if (user) {
    redirect('/dashboard')
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-gray-50">
      <SignupForm />
    </main>
  )
}
SIGNUP_PAGE_EOF

# Verify file created
cat src/app/\(auth\)/signup/page.tsx
```

---

### 🎯 STEP 9 — Create Protected Dashboard Page

```bash
# Create dashboard directory
mkdir -p src/app/dashboard

cat > src/app/dashboard/page.tsx << 'DASHBOARD_PAGE_EOF'
import { redirect } from 'next/navigation'
import { getCurrentUser } from '@/lib/actions/auth'
import { LogoutButton } from '@/components/features/auth/LogoutButton'

export const metadata = {
  title: 'Dashboard',
  description: 'Your project dashboard',
}

export default async function DashboardPage() {
  // Protect this route - redirect if not logged in
  const user = await getCurrentUser()
  if (!user) {
    redirect('/login')
  }

  return (
    <main className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
            <p className="text-gray-600 mt-1">Welcome back, {user.email}</p>
          </div>
          <LogoutButton />
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Your Projects</h2>
          <p className="text-gray-600">
            You're successfully authenticated! In the next lesson, we'll add project management features here.
          </p>

          <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-md">
            <h3 className="font-medium text-blue-900 mb-2">User Information</h3>
            <dl className="space-y-1 text-sm">
              <div>
                <dt className="inline font-medium text-blue-900">Email: </dt>
                <dd className="inline text-blue-700">{user.email}</dd>
              </div>
              <div>
                <dt className="inline font-medium text-blue-900">User ID: </dt>
                <dd className="inline text-blue-700 font-mono text-xs">{user.id}</dd>
              </div>
              <div>
                <dt className="inline font-medium text-blue-900">Email Confirmed: </dt>
                <dd className="inline text-blue-700">{user.confirmed_at ? 'Yes' : 'No'}</dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </main>
  )
}
DASHBOARD_PAGE_EOF

# Verify file created
cat src/app/dashboard/page.tsx
```

---

### 🎯 STEP 10 — Create Auth Callback Route (for Email Confirmation)

```bash
# Create auth callback directory
mkdir -p src/app/auth/callback

cat > src/app/auth/callback/route.ts << 'CALLBACK_ROUTE_EOF'
import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

/**
 * Auth callback handler for email confirmation
 * Supabase redirects here after user clicks email confirmation link
 */
export async function GET(request: NextRequest) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')

  if (code) {
    const supabase = await createClient()

    // Exchange code for session
    await supabase.auth.exchangeCodeForSession(code)
  }

  // Redirect to dashboard after confirmation
  return NextResponse.redirect(new URL('/dashboard', request.url))
}
CALLBACK_ROUTE_EOF

# Verify file created
cat src/app/auth/callback/route.ts
```

---

### 🎯 STEP 11 — Update Home Page with Auth Links

```bash
cat > src/app/page.tsx << 'HOME_PAGE_EOF'
import Link from 'next/link'
import { getCurrentUser } from '@/lib/actions/auth'
import { Button } from '@/components/ui/Button'
import { APP_NAME } from '@/constants'

export default async function Home() {
  const user = await getCurrentUser()

  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="max-w-2xl mx-auto px-4 text-center">
        <h1 className="text-5xl font-bold text-gray-900 mb-4">
          {APP_NAME}
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          Manage your projects, tasks, and team in one place
        </p>

        <div className="flex gap-4 justify-center">
          {user ? (
            <Link href="/dashboard">
              <Button size="lg">
                Go to Dashboard
              </Button>
            </Link>
          ) : (
            <>
              <Link href="/login">
                <Button size="lg">
                  Sign In
                </Button>
              </Link>
              <Link href="/signup">
                <Button size="lg" variant="outline">
                  Sign Up
                </Button>
              </Link>
            </>
          )}
        </div>

        {user && (
          <p className="mt-4 text-sm text-gray-600">
            Signed in as {user.email}
          </p>
        )}
      </div>
    </main>
  )
}
HOME_PAGE_EOF

# Verify file updated
cat src/app/page.tsx
```

---

### 🎯 STEP 12 — Configure Supabase Auth Settings

**⚠️ Important:** Configure Supabase settings for email confirmation.

**In Supabase Dashboard:**

1. Go to **Authentication → URL Configuration**
2. Set **Site URL**: `http://localhost:3000` (development) or your production URL
3. Add **Redirect URLs**:
   - `http://localhost:3000/auth/callback`
   - Your production URL + `/auth/callback`

4. Go to **Authentication → Email Templates** (optional)
   - Customize confirmation email
   - Customize reset password email

5. Go to **Authentication → Providers** → **Email**
   - **Enable email provider** (should be enabled by default)
   - **Confirm email**: Toggle ON/OFF based on your needs
     - ON = Users must confirm email before login
     - OFF = Users can login immediately after signup

```bash
# Add site URL to environment variables
cat >> .env.local << 'ENV_EOF'

# Site URL for auth redirects
NEXT_PUBLIC_SITE_URL=http://localhost:3000
ENV_EOF

# Update example file too
cat >> .env.local.example << 'ENV_EXAMPLE_EOF'

# Site URL for auth redirects (change for production)
NEXT_PUBLIC_SITE_URL=http://localhost:3000
ENV_EXAMPLE_EOF

echo "✅ Environment variables updated!"
```

<details>
<summary>📖 <strong>Understanding Email Confirmation Flow</strong></summary>

### Email Confirmation Flow

**With Email Confirmation Enabled:**

```
1. User fills signup form
   ↓
2. Server action calls supabase.auth.signUp()
   ↓
3. Supabase creates user (confirmed_at = null)
   ↓
4. Supabase sends confirmation email
   ↓
5. User clicks link in email
   ↓
6. Redirects to /auth/callback?code=XXX
   ↓
7. Route handler exchanges code for session
   ↓
8. User redirected to /dashboard (logged in)
```

**Without Email Confirmation:**

```
1. User fills signup form
   ↓
2. Server action calls supabase.auth.signUp()
   ↓
3. Supabase creates user (confirmed_at = timestamp)
   ↓
4. User immediately logged in
   ↓
5. Redirect to /dashboard
```

**Production Checklist:**
- [ ] Set production Site URL
- [ ] Add production redirect URLs
- [ ] Customize email templates with brand colors
- [ ] Test email delivery
- [ ] Consider email verification ON for production

</details>

---

### 🎯 STEP 13 — Update proxy.ts with Protected Routes

Now let's activate the protected route helpers we created in Lesson 2.

```bash
# Update proxy.ts to use the helper functions
cat > proxy.ts << 'PROXY_EOF'
/**
 * Next.js 16 Proxy (Replaces middleware.ts in Next.js 15)
 * Handles session refresh and route protection
 */
import { type NextRequest, NextResponse } from 'next/server'
import { updateSession, isProtectedRoute, isPublicOnlyRoute } from '@/lib/supabase/middleware'
import { createClient } from '@/lib/supabase/server'

export async function proxy(req: NextRequest) {
  const { response, user } = await updateSession(req)

  // Protected routes - redirect to login if not authenticated
  if (isProtectedRoute(req.nextUrl.pathname) && !user) {
    const redirectUrl = new URL('/login', req.url)
    redirectUrl.searchParams.set('redirect', req.nextUrl.pathname)
    return NextResponse.redirect(redirectUrl)
  }

  // Public-only routes - redirect to dashboard if authenticated
  if (isPublicOnlyRoute(req.nextUrl.pathname) && user) {
    return NextResponse.redirect(new URL('/dashboard', req.url))
  }

  return response
}

// Match all routes except static files and API routes
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
PROXY_EOF

echo "✅ proxy.ts updated with route protection!"
cat proxy.ts
```

---

### 🎯 STEP 14 — Run Build to Verify Everything Works

```bash
# Run production build to verify no TypeScript errors
echo "🏗️  Building project..."
npm run build

echo ""
echo "✅ If build succeeds, authentication is properly configured!"
echo "✅ All TypeScript types are correct!"
echo "✅ Ready to test authentication flow!"
```

**Expected output:**
```
🏗️  Building project...
   ▲ Next.js 16.x.x
   - Environments: .env.local

   Creating an optimized production build ...
 ✓ Compiled successfully
 ✓ Linting and checking validity of types
 ✓ Collecting page data
 ✓ Generating static pages (4/4)
 ✓ Collecting build traces
 ✓ Finalizing page optimization

Route (app)                              Size     First Load JS
┌ ○ /                                    XX kB          XX kB
├ ○ /_not-found                          XX kB          XX kB
├ ○ /dashboard                           XX kB          XX kB
├ ○ /login                               XX kB          XX kB
└ ○ /signup                              XX kB          XX kB

○  (Static)  prerendered as static content

✅ Build succeeded!
```

**If build fails:**
- Check all import paths use `@/` alias
- Verify all UI components are in `src/components/ui/`
- Ensure auth actions are in `src/lib/actions/auth.ts`
- Check that all pages have proper exports
- Review error messages for missing dependencies

---

### 🎯 STEP 15 — Set Up Automated Testing with Playwright

**Why Playwright?**
- ✅ Tests real user interactions (E2E testing)
- ✅ Cross-browser testing (Chrome, Firefox, Safari)
- ✅ Auto-wait for elements (no flaky tests)
- ✅ Built-in test generator (AI-assisted)
- ✅ Best practices recommended by Next.js team

**Install Playwright:**

```bash
# Install Playwright with TypeScript support
npm install -D @playwright/test @playwright/experimental-ct-react

# Initialize Playwright (creates config files)
npx playwright install

echo "✅ Playwright installed!"
```

**Create Playwright config:**

```bash
cat > playwright.config.ts << 'PLAYWRIGHT_EOF'
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',

  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
PLAYWRIGHT_EOF

echo "✅ Playwright config created!"
```

**Create E2E test directory:**

```bash
mkdir -p e2e
```

**Create authentication E2E tests:**

```bash
cat > e2e/auth.spec.ts << 'AUTH_TEST_EOF'
import { test, expect } from '@playwright/test'

/**
 * Authentication E2E Tests
 * Tests the complete authentication flow
 */

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Start from home page
    await page.goto('/')
  })

  test('should show sign in and sign up buttons on home page', async ({ page }) => {
    // Check for auth buttons
    await expect(page.getByRole('link', { name: /sign in/i })).toBeVisible()
    await expect(page.getByRole('link', { name: /sign up/i })).toBeVisible()
  })

  test('should navigate to signup page and show form', async ({ page }) => {
    // Click Sign Up button
    await page.getByRole('link', { name: /sign up/i }).click()

    // Wait for navigation
    await page.waitForURL('/signup')

    // Check form elements
    await expect(page.getByRole('heading', { name: /create account/i })).toBeVisible()
    await expect(page.getByLabel(/email/i)).toBeVisible()
    await expect(page.getByLabel(/^password/i)).toBeVisible()
    await expect(page.getByLabel(/confirm password/i)).toBeVisible()
    await expect(page.getByRole('button', { name: /sign up/i })).toBeVisible()
  })

  test('should navigate to login page and show form', async ({ page }) => {
    // Click Sign In button
    await page.getByRole('link', { name: /sign in/i }).click()

    // Wait for navigation
    await page.waitForURL('/login')

    // Check form elements
    await expect(page.getByRole('heading', { name: /welcome back/i })).toBeVisible()
    await expect(page.getByLabel(/email/i)).toBeVisible()
    await expect(page.getByLabel(/password/i)).toBeVisible()
    await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible()
  })

  test('should show validation errors for invalid signup', async ({ page }) => {
    await page.goto('/signup')

    // Try to submit empty form
    await page.getByRole('button', { name: /sign up/i }).click()

    // HTML5 validation should prevent submission
    // Check if email input is invalid
    const emailInput = page.getByLabel(/email/i)
    await expect(emailInput).toHaveAttribute('required')
  })

  test('should show error for password mismatch', async ({ page }) => {
    await page.goto('/signup')

    // Fill form with mismatched passwords
    await page.getByLabel(/email/i).fill('test@example.com')
    await page.getByLabel(/^password/i).fill('password123')
    await page.getByLabel(/confirm password/i).fill('differentpassword')

    // Submit form
    await page.getByRole('button', { name: /sign up/i }).click()

    // Should show error message
    await expect(page.getByText(/passwords do not match/i)).toBeVisible()
  })

  test('should show error for short password', async ({ page }) => {
    await page.goto('/signup')

    // Fill form with short password
    await page.getByLabel(/email/i).fill('test@example.com')
    await page.getByLabel(/^password/i).fill('short')
    await page.getByLabel(/confirm password/i).fill('short')

    // Submit form
    await page.getByRole('button', { name: /sign up/i }).click()

    // Should show error message
    await expect(page.getByText(/at least 8 characters/i)).toBeVisible()
  })

  test('should redirect to dashboard when accessing login while authenticated', async ({ page }) => {
    // This test assumes you have a way to authenticate
    // For now, we'll test the redirect logic exists

    // Note: In real tests, you'd set up auth state in beforeEach
    // For example: await page.context().addCookies([...authCookies])

    await page.goto('/login')
    // Page should load (will redirect if authenticated)
    await expect(page).toHaveURL(/\/(login|dashboard)/)
  })
})

test.describe('Protected Routes', () => {
  test('should redirect to login when accessing dashboard without auth', async ({ page }) => {
    // Try to access protected route
    await page.goto('/dashboard')

    // Should redirect to login
    await page.waitForURL(/\/login/)
    await expect(page).toHaveURL(/\/login/)
  })

  test('should show redirect parameter after unauthenticated access', async ({ page }) => {
    // Try to access dashboard without auth
    await page.goto('/dashboard')

    // Should redirect to login with redirect param
    await expect(page).toHaveURL(/\/login\?redirect/)
  })
})

test.describe('UI Components', () => {
  test('button should show loading state', async ({ page }) => {
    await page.goto('/login')

    const submitButton = page.getByRole('button', { name: /sign in/i })

    // Fill required fields
    await page.getByLabel(/email/i).fill('test@example.com')
    await page.getByLabel(/password/i).fill('password123')

    // Click submit
    await submitButton.click()

    // Button should show loading state (check for loading text or spinner)
    // This assumes your button shows "Loading..." text
    await expect(submitButton).toContainText(/loading/i)
  })

  test('input should show error state', async ({ page }) => {
    await page.goto('/signup')

    // Submit form with invalid data
    await page.getByLabel(/email/i).fill('invalid-email')
    await page.getByRole('button', { name: /sign up/i }).click()

    // Input should have error styling
    const emailInput = page.getByLabel(/email/i)
    await expect(emailInput).toHaveClass(/border-red/)
  })
})
AUTH_TEST_EOF

echo "✅ Authentication E2E tests created!"
```

**Add test scripts to package.json:**

```bash
# Add test scripts using npm pkg set
npm pkg set scripts.test:e2e="playwright test"
npm pkg set scripts.test:e2e:ui="playwright test --ui"
npm pkg set scripts.test:e2e:debug="playwright test --debug"
npm pkg set scripts.test:e2e:report="playwright show-report"

echo "✅ Test scripts added to package.json!"
```

**Run tests:**

```bash
# Run all E2E tests
npm run test:e2e

echo ""
echo "📊 To view the test report:"
echo "npm run test:e2e:report"

echo ""
echo "🎨 To run tests with UI mode (interactive):"
echo "npm run test:e2e:ui"

echo ""
echo "🐛 To debug tests step-by-step:"
echo "npm run test:e2e:debug"
```

<details>
<summary>📖 <strong>Using AI to Generate Tests (Best Practices)</strong></summary>

### How to Prompt AI for Test Generation

**1. For Authentication Tests:**

```
Prompt: "Write Playwright tests for Next.js authentication flow with:
- Email/password signup with validation
- Login with credentials
- Protected route redirects
- Logout functionality
- Error handling for invalid inputs
Follow testing best practices and use Page Object Model."
```

**2. For Component Tests:**

```
Prompt: "Write Playwright component tests for:
- Button component with loading states
- Input component with error handling
- Modal component with backdrop clicks
- Form validation and submission
Use accessible selectors and test user interactions."
```

**3. For E2E User Journeys:**

```
Prompt: "Write Playwright E2E test for complete user journey:
1. User visits home page
2. Clicks signup
3. Fills registration form
4. Gets redirected to dashboard
5. Views their profile
6. Logs out
Include assertions for each step and handle async operations."
```

### Best Practices for AI-Generated Tests

**DO:**
- ✅ Be specific about user flows
- ✅ Request accessible selectors (role, label, text)
- ✅ Ask for error handling tests
- ✅ Request visual regression tests
- ✅ Ask for both happy and sad paths
- ✅ Request realistic test data

**DON'T:**
- ❌ Rely on CSS selectors (brittle)
- ❌ Skip edge cases
- ❌ Ignore accessibility
- ❌ Test implementation details
- ❌ Create tests that depend on order

### Playwright Best Practices

**1. Use Accessibility Selectors:**
```typescript
// ✅ Good - Uses accessible selectors
await page.getByRole('button', { name: /submit/i })
await page.getByLabel('Email')
await page.getByText('Welcome back')

// ❌ Bad - Uses CSS selectors (brittle)
await page.locator('.btn-submit')
await page.locator('#email-input')
```

**2. Auto-waiting is Built-in:**
```typescript
// ✅ Good - Playwright auto-waits
await page.getByRole('button').click()

// ❌ Bad - Manual waiting (not needed)
await page.waitForTimeout(1000)
await page.getByRole('button').click()
```

**3. Use Page Object Model:**
```typescript
// ✅ Good - Reusable page objects
class LoginPage {
  constructor(private page: Page) {}

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email)
    await this.page.getByLabel('Password').fill(password)
    await this.page.getByRole('button', { name: /sign in/i }).click()
  }
}

test('should login successfully', async ({ page }) => {
  const loginPage = new LoginPage(page)
  await loginPage.login('user@example.com', 'password123')
})
```

**4. Test Data Management:**
```typescript
// ✅ Good - Use fixtures for test data
const testUser = {
  email: 'test@example.com',
  password: 'SecurePassword123!'
}

// Create reusable fixtures
test.use({
  testUser: async ({}, use) => {
    await use(testUser)
  }
})
```

**5. Parallel Testing:**
```typescript
// ✅ Good - Tests run in parallel
test.describe.configure({ mode: 'parallel' })

test.describe('Auth Flow', () => {
  test('signup', async ({ page }) => { /* ... */ })
  test('login', async ({ page }) => { /* ... */ })
  test('logout', async ({ page }) => { /* ... */ })
})
```

### CI/CD Integration

**GitHub Actions Example:**
```yaml
name: E2E Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run test:e2e
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
```

</details>

<details>
<summary>📖 <strong>Playwright Codegen - AI-Assisted Test Generation</strong></summary>

### Record Tests with Playwright Codegen

Playwright includes a **code generator** that records your actions and generates test code:

**1. Start Codegen:**
```bash
npx playwright codegen http://localhost:3000
```

**2. Interact with your app:**
- Click buttons
- Fill forms
- Navigate pages
- Playwright generates code in real-time!

**3. Copy generated code:**
```typescript
// Playwright automatically generates this:
import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.getByRole('link', { name: 'Sign In' }).click();
  await page.getByLabel('Email').click();
  await page.getByLabel('Email').fill('test@example.com');
  await page.getByLabel('Password').click();
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
});
```

**4. Refine with AI:**
```
Prompt to AI: "Improve this Playwright test by:
- Adding assertions for each step
- Extracting reusable functions
- Adding error handling
- Making it work for multiple users
- Following Page Object Model pattern"
```

</details>

---

### 🎯 STEP 16 — Manual Testing & Verification

```bash
# Start development server
npm run dev

# In your browser, test this flow:
echo "
📋 Manual Testing Checklist:
1. Visit http://localhost:3000
   → Should show Sign In / Sign Up buttons

2. Click 'Sign Up'
   → Fill form with valid email/password
   → Should redirect to dashboard OR show email confirmation message

3. Visit http://localhost:3000/dashboard (while logged in)
   → Should show dashboard with your email
   → Should show logout button

4. Click 'Sign Out'
   → Should redirect to /login

5. Visit http://localhost:3000/login
   → Fill form with same credentials
   → Should redirect to dashboard

6. Visit http://localhost:3000/signup (while logged in)
   → Should auto-redirect to dashboard (public-only route protection)

7. Open new incognito tab → http://localhost:3000/dashboard
   → Should redirect to /login (protected route)

✅ If all tests pass, authentication is working!
"
```

---

## ✅ 3. CHECKLIST

### 🎯 UI Components

- [ ] Created `src/components/ui/Button.tsx`
- [ ] Button has variants: default, outline, ghost, danger
- [ ] Button has loading state with spinner
- [ ] Created `src/components/ui/Input.tsx`
- [ ] Input has label, error, and helper text support
- [ ] Created `src/components/ui/Select.tsx`
- [ ] Select has options array with placeholder support
- [ ] Created `src/components/ui/Dropdown.tsx`
- [ ] Dropdown has click-outside and escape key support
- [ ] Dropdown supports icons and danger items
- [ ] Created `src/components/ui/Modal.tsx`
- [ ] Modal has backdrop, escape key, and scroll lock
- [ ] Modal has ModalFooter helper component
- [ ] All components are type-safe and accessible

### 🎯 Auth Server Actions

- [ ] Created `src/lib/actions/auth.ts` with `'use server'` directive
- [ ] `signUp()` function validates and creates users
- [ ] `signIn()` function authenticates users
- [ ] `signOut()` function clears session
- [ ] `getCurrentUser()` function gets authenticated user
- [ ] All actions include error handling
- [ ] Password validation (min 8 characters, confirmation match)

### 🎯 Auth Components

- [ ] Created `LoginForm.tsx` component
- [ ] Created `SignupForm.tsx` component
- [ ] Created `LogoutButton.tsx` component
- [ ] All forms use server actions
- [ ] Loading states implemented
- [ ] Error handling implemented
- [ ] Forms have proper autocomplete attributes

### 🎯 Auth Pages

- [ ] Created `/login` page at `src/app/(auth)/login/page.tsx`
- [ ] Created `/signup` page at `src/app/(auth)/signup/page.tsx`
- [ ] Both pages redirect if user already logged in
- [ ] Pages use Server Components for auth checks
- [ ] Metadata configured for SEO

### 🎯 Protected Routes

- [ ] Created `/dashboard` page at `src/app/dashboard/page.tsx`
- [ ] Dashboard redirects to login if not authenticated
- [ ] Dashboard displays user information
- [ ] Logout button functional
- [ ] Updated `proxy.ts` with route protection
- [ ] `isProtectedRoute()` helper working
- [ ] `isPublicOnlyRoute()` helper working

### 🎯 Auth Callback

- [ ] Created `/auth/callback/route.ts`
- [ ] Route handler exchanges code for session
- [ ] Redirects to dashboard after confirmation
- [ ] Works with email confirmation flow

### 🎯 Supabase Configuration

- [ ] Configured Site URL in Supabase Dashboard
- [ ] Added redirect URLs for auth callbacks
- [ ] Email provider enabled
- [ ] Email confirmation setting configured (ON/OFF decision made)
- [ ] Added `NEXT_PUBLIC_SITE_URL` to `.env.local`
- [ ] Updated `.env.local.example` with site URL

### 🎯 Home Page

- [ ] Updated home page with auth-aware content
- [ ] Shows Sign In/Sign Up for guests
- [ ] Shows Dashboard link for authenticated users
- [ ] Displays current user email when logged in

### 🎯 Auth Hook

- [ ] Created `useAuth()` hook at `src/hooks/useAuth.ts`
- [ ] Hook listens to auth state changes
- [ ] Returns user and loading state
- [ ] Properly unsubscribes on unmount

### 🎯 Automated Testing

- [ ] Installed Playwright (`npm install -D @playwright/test`)
- [ ] Created `playwright.config.ts` with proper configuration
- [ ] Created `e2e/` directory for test files
- [ ] Created `e2e/auth.spec.ts` with authentication tests
- [ ] Added test scripts to package.json (test:e2e, test:e2e:ui, test:e2e:debug)
- [ ] Tests cover authentication flow
- [ ] Tests cover protected routes
- [ ] Tests cover UI component states
- [ ] Tests use accessible selectors (getByRole, getByLabel)
- [ ] Ran STEP 15: Automated tests (`npm run test:e2e`)
- [ ] All E2E tests pass

### 🎯 Final Verification

- [ ] Ran STEP 14: Build verification (`npm run build`)
- [ ] Build succeeded with no TypeScript errors
- [ ] Ran STEP 15: Automated tests pass
- [ ] Ran STEP 16: Manual testing complete
- [ ] Can sign up new users
- [ ] Can sign in existing users
- [ ] Can sign out
- [ ] Protected routes redirect to login
- [ ] Public-only routes redirect to dashboard when authenticated
- [ ] Email confirmation flow works (if enabled)
- [ ] Ready for Lesson 4 (Project CRUD Operations)

---

## 🎓 What You Learned

**In this lesson you implemented:**

✅ **5 Reusable UI Components** - Button, Input, Select, Dropdown, Modal
✅ **Server Actions** - Secure authentication with `'use server'`
✅ **Email/Password Auth** - Supabase Auth integration
✅ **Protected Routes** - Server-side auth checks with redirects
✅ **Auth Forms** - Login and Signup with validation
✅ **Session Management** - Automatic refresh via proxy.ts
✅ **Auth Hooks** - Client-side auth state with `useAuth()`
✅ **Email Confirmation** - Optional email verification flow
✅ **Route Groups** - `(auth)` folder for shared layouts
✅ **Type Safety** - Full TypeScript coverage for auth
✅ **E2E Testing** - Playwright automated testing with best practices
✅ **AI-Assisted Testing** - Codegen and test generation prompts

**Key Concepts Mastered:**

- Server Actions vs API routes
- Progressive enhancement with forms
- Server Component auth checks
- Client Component auth hooks
- Protected route patterns
- Public-only route patterns
- Email confirmation flow
- Session cookie management
- Auth state synchronization
- Error handling in forms
- Loading states for UX
- Redirect after authentication
- E2E testing with Playwright
- Accessible test selectors (getByRole, getByLabel)
- Test-driven development (TDD)
- Page Object Model pattern
- AI-assisted test generation
- CI/CD integration for tests

**Security Features Implemented:**

1. **CSRF Protection** - Automatic with Server Actions
2. **Secure Cookies** - HttpOnly cookies via Supabase
3. **Server-side Validation** - All auth logic on server
4. **Password Requirements** - Min 8 characters, confirmation
5. **Email Verification** - Optional confirmation flow
6. **Route Protection** - Unauthorized access prevention

**Next Lesson:** Module 1, Lesson 4 - Project CRUD Operations (Create, Read, Update, Delete projects using RPC functions)

---

**🎉 Lesson 3 Complete!** Your Next.js app now has full authentication with protected routes and a beautiful login/signup flow!
