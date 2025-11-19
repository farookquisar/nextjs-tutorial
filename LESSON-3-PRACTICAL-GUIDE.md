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
│   │       └── Input.tsx        ← NEW: Reusable input
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

**Benefits:**
1. **Consistent design** - Same look across all forms
2. **Less code** - Reuse instead of duplicate
3. **Accessible** - Built-in ARIA attributes
4. **Type-safe** - TypeScript catches errors
5. **Customizable** - Easy to extend with className

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

### 🎯 STEP 15 — Test Authentication Flow

```bash
# Start development server
npm run dev

# In your browser, test this flow:
echo "
📋 Testing Checklist:
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
- [ ] Both components are type-safe and accessible

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

### 🎯 Final Verification

- [ ] Ran STEP 14: Build verification (`npm run build`)
- [ ] Build succeeded with no TypeScript errors
- [ ] Tested STEP 15: All authentication flows work
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

✅ **Server Actions** - Secure authentication with `'use server'`
✅ **Email/Password Auth** - Supabase Auth integration
✅ **Protected Routes** - Server-side auth checks with redirects
✅ **Auth Forms** - Login and Signup with validation
✅ **Session Management** - Automatic refresh via proxy.ts
✅ **UI Components** - Reusable Button and Input components
✅ **Auth Hooks** - Client-side auth state with `useAuth()`
✅ **Email Confirmation** - Optional email verification flow
✅ **Route Groups** - `(auth)` folder for shared layouts
✅ **Type Safety** - Full TypeScript coverage for auth

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
