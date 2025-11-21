# Astro 5.0 Tutorial - Lesson 5: Authentication with Supabase

**Prerequisites:** Completion of Lessons 1-4, Supabase account, Node.js 20+

---

## ✅ 1. DESC (Description)

### What You'll Learn

In this lesson, you'll implement a complete authentication system using Supabase Auth, including user registration, login, password reset, OAuth providers, and protected routes.

**Core Concepts:**
- ✅ Supabase Auth configuration
- ✅ Email/password authentication
- ✅ OAuth providers (GitHub, Google)
- ✅ Session management and cookies
- ✅ Protected routes with Astro middleware
- ✅ User profile management
- ✅ Password reset flow
- ✅ Auth state hooks and utilities
- ✅ Server-side auth checks
- ✅ Role-based access control

**What You'll Build:**
- Login and signup pages with forms
- OAuth provider integration
- Protected dashboard page
- User profile page with edit functionality
- Password reset flow (request + confirm)
- Auth middleware for route protection
- User avatar upload
- Email verification flow
- Session persistence
- Auth utilities and helpers

---

### Why Supabase Auth?

**Supabase Auth provides enterprise-grade authentication:**

1. **Built-in Security** - PKCE flow, JWT tokens, secure cookies
2. **Multiple Providers** - Email, OAuth (Google, GitHub, etc.), magic links
3. **Row Level Security** - Database-level access control
4. **Real-time Sessions** - Automatic token refresh
5. **Email Templates** - Customizable confirmation and reset emails
6. **Multi-factor Auth** - Optional TOTP support

**Authentication Flow:**
```
1. User signs up → Supabase creates user → Confirmation email sent
2. User confirms email → Account activated
3. User logs in → JWT token issued → Session stored
4. Middleware checks token → Allows/denies access
5. Token expires → Auto-refresh → Seamless experience
```

---

### Authentication Architecture

**Components of our auth system:**

```
src/
├── middleware/
│   └── auth.ts              # Route protection
├── pages/
│   ├── login.astro          # Login page
│   ├── signup.astro         # Signup page
│   ├── logout.astro         # Logout endpoint
│   ├── reset-password.astro # Password reset request
│   ├── confirm-reset.astro  # Password reset confirm
│   ├── profile.astro        # User profile (protected)
│   └── dashboard.astro      # User dashboard (protected)
├── components/
│   ├── AuthForm.astro       # Reusable auth form
│   ├── UserMenu.astro       # Logged-in user menu
│   └── ProtectedRoute.astro # Auth guard component
└── lib/
    ├── supabase.ts          # Supabase client
    ├── auth.ts              # Auth utilities
    └── types.ts             # TypeScript types
```

---

### Session Management

**Supabase uses secure cookie-based sessions:**

```typescript
// Server-side session check
const session = await supabase.auth.getSession();
if (!session.data.session) {
  return redirect('/login');
}

// Client-side session monitoring
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT') {
    window.location.href = '/login';
  }
});
```

**Session lifecycle:**
1. **Login** → JWT access token + refresh token stored in httpOnly cookies
2. **Request** → Token sent automatically with each request
3. **Validation** → Server validates token on protected routes
4. **Expiry** → Auto-refresh before expiration (1 hour default)
5. **Logout** → Tokens cleared from cookies

---

### Row Level Security (RLS)

**Database-level access control:**

```sql
-- Only users can read their own profile
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Only users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);
```

**Why RLS matters:**
- 🔒 **Security** - Even with stolen tokens, users can't access others' data
- 🎯 **Precision** - Define rules per table, per operation
- ⚡ **Performance** - Enforced at database level
- 🛡️ **Defense in Depth** - Additional layer beyond application logic

---

## ✅ 2. CODE (Implementation)

### STEP 1: Configure Supabase Auth

**Enable authentication in Supabase dashboard:**

1. Go to **Authentication** → **Providers**
2. Enable **Email** provider
3. Disable **Confirm email** for development (enable in production)
4. Configure **Site URL**: `http://localhost:4321`
5. Add **Redirect URLs**: `http://localhost:4321/auth/callback`

```bash
# Create auth utilities file
cat > src/lib/auth.ts << 'EOF'
import type { AstroCookies } from 'astro';
import { createServerClient } from '@supabase/ssr';

/**
 * Create Supabase client with cookie handling for SSR
 */
export function createSupabaseServerClient(cookies: AstroCookies) {
  return createServerClient(
    import.meta.env.PUBLIC_SUPABASE_URL,
    import.meta.env.PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        get(key: string) {
          return cookies.get(key)?.value;
        },
        set(key: string, value: string, options: any) {
          cookies.set(key, value, options);
        },
        remove(key: string, options: any) {
          cookies.delete(key, options);
        },
      },
    }
  );
}

/**
 * Get current user session
 */
export async function getSession(cookies: AstroCookies) {
  const supabase = createSupabaseServerClient(cookies);
  const { data: { session }, error } = await supabase.auth.getSession();

  if (error) {
    console.error('Error getting session:', error);
    return null;
  }

  return session;
}

/**
 * Get current user profile
 */
export async function getUserProfile(cookies: AstroCookies) {
  const supabase = createSupabaseServerClient(cookies);
  const { data: { user }, error: authError } = await supabase.auth.getUser();

  if (authError || !user) {
    return null;
  }

  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();

  if (profileError) {
    console.error('Error fetching profile:', profileError);
    return null;
  }

  return { user, profile };
}

/**
 * Check if user is authenticated
 */
export async function isAuthenticated(cookies: AstroCookies): Promise<boolean> {
  const session = await getSession(cookies);
  return session !== null;
}

/**
 * Require authentication (redirect if not authenticated)
 */
export async function requireAuth(cookies: AstroCookies, redirectTo: string = '/login') {
  const authenticated = await isAuthenticated(cookies);

  if (!authenticated) {
    return {
      redirect: redirectTo,
      authenticated: false,
    };
  }

  return {
    redirect: null,
    authenticated: true,
  };
}
EOF
```

**Create auth types:**

```bash
cat > src/lib/auth-types.ts << 'EOF'
import type { User, Session } from '@supabase/supabase-js';

export interface Profile {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  website: string | null;
  created_at: string;
  updated_at: string;
}

export interface AuthUser {
  user: User;
  profile: Profile;
}

export interface AuthSession {
  session: Session;
  user: AuthUser;
}

export type AuthProvider = 'github' | 'google' | 'discord' | 'twitter';

export interface AuthError {
  message: string;
  status?: number;
}
EOF
```

---

### STEP 2: Create Database Tables and Policies

**Create profiles table with RLS:**

```bash
# Create SQL migration file
cat > supabase/migrations/005_create_profiles.sql << 'EOF'
-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  website TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public profiles are viewable by everyone"
ON profiles FOR SELECT
USING (true);

CREATE POLICY "Users can insert their own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
EOF

# Apply migration
npm run db:push
```

**Create storage bucket for avatars:**

```sql
-- In Supabase dashboard: Storage → Create bucket
-- Name: avatars
-- Public: true

-- Or via SQL
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- Storage policies
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

---

### STEP 3: Create Signup Page

```bash
cat > src/pages/signup.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import { createSupabaseServerClient } from '../lib/auth';

const errors: Record<string, string> = {};
let successMessage = '';

// Check if already logged in
const supabase = createSupabaseServerClient(Astro.cookies);
const { data: { session } } = await supabase.auth.getSession();

if (session) {
  return Astro.redirect('/dashboard');
}

// Handle form submission
if (Astro.request.method === 'POST') {
  try {
    const formData = await Astro.request.formData();
    const email = formData.get('email')?.toString();
    const password = formData.get('password')?.toString();
    const fullName = formData.get('fullName')?.toString();
    const confirmPassword = formData.get('confirmPassword')?.toString();

    // Validation
    if (!email || !email.includes('@')) {
      errors.email = 'Valid email is required';
    }

    if (!password || password.length < 8) {
      errors.password = 'Password must be at least 8 characters';
    }

    if (password !== confirmPassword) {
      errors.confirmPassword = 'Passwords do not match';
    }

    if (!fullName || fullName.length < 2) {
      errors.fullName = 'Full name is required';
    }

    // If no errors, attempt signup
    if (Object.keys(errors).length === 0) {
      const { data, error } = await supabase.auth.signUp({
        email: email!,
        password: password!,
        options: {
          data: {
            full_name: fullName,
          },
          emailRedirectTo: `${Astro.url.origin}/auth/callback`,
        },
      });

      if (error) {
        errors.form = error.message;
      } else if (data.user) {
        // Check if email confirmation is required
        if (data.user.identities?.length === 0) {
          errors.form = 'This email is already registered';
        } else {
          successMessage = 'Account created! Please check your email to verify your account.';
        }
      }
    }
  } catch (error) {
    console.error('Signup error:', error);
    errors.form = 'An unexpected error occurred';
  }
}
---

<MainLayout
  title="Sign Up"
  description="Create your account"
>
  <div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <!-- Header -->
      <div class="text-center">
        <h1 class="text-4xl font-bold">Create Account</h1>
        <p class="mt-2 text-text-secondary">
          Or{' '}
          <a href="/login" class="text-accent hover:text-accent/80">
            sign in to your account
          </a>
        </p>
      </div>

      <!-- Success Message -->
      {successMessage && (
        <div class="bg-green-500/10 border border-green-500/20 rounded-lg p-4">
          <p class="text-green-600 dark:text-green-400">{successMessage}</p>
        </div>
      )}

      <!-- Form Error -->
      {errors.form && (
        <div class="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
          <p class="text-red-600 dark:text-red-400">{errors.form}</p>
        </div>
      )}

      <!-- Signup Form -->
      <form method="POST" class="mt-8 space-y-6">
        <!-- Full Name -->
        <div>
          <label for="fullName" class="block text-sm font-medium mb-2">
            Full Name
          </label>
          <input
            id="fullName"
            name="fullName"
            type="text"
            required
            class="input w-full"
            placeholder="John Doe"
          />
          {errors.fullName && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.fullName}
            </p>
          )}
        </div>

        <!-- Email -->
        <div>
          <label for="email" class="block text-sm font-medium mb-2">
            Email address
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            class="input w-full"
            placeholder="you@example.com"
          />
          {errors.email && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.email}
            </p>
          )}
        </div>

        <!-- Password -->
        <div>
          <label for="password" class="block text-sm font-medium mb-2">
            Password
          </label>
          <input
            id="password"
            name="password"
            type="password"
            required
            class="input w-full"
            placeholder="••••••••"
            minlength="8"
          />
          {errors.password && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.password}
            </p>
          )}
          <p class="mt-1 text-xs text-text-secondary">
            Must be at least 8 characters
          </p>
        </div>

        <!-- Confirm Password -->
        <div>
          <label for="confirmPassword" class="block text-sm font-medium mb-2">
            Confirm Password
          </label>
          <input
            id="confirmPassword"
            name="confirmPassword"
            type="password"
            required
            class="input w-full"
            placeholder="••••••••"
          />
          {errors.confirmPassword && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.confirmPassword}
            </p>
          )}
        </div>

        <!-- Submit Button -->
        <button type="submit" class="btn-primary w-full">
          Create Account
        </button>
      </form>

      <!-- OAuth Providers -->
      <div class="mt-6">
        <div class="relative">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-border"></div>
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-2 bg-bg-primary text-text-secondary">
              Or continue with
            </span>
          </div>
        </div>

        <div class="mt-6 grid grid-cols-2 gap-3">
          <!-- GitHub -->
          <form method="POST" action="/api/auth/github">
            <button
              type="submit"
              class="btn w-full flex items-center justify-center gap-2"
            >
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z" clip-rule="evenodd" />
              </svg>
              GitHub
            </button>
          </form>

          <!-- Google -->
          <form method="POST" action="/api/auth/google">
            <button
              type="submit"
              class="btn w-full flex items-center justify-center gap-2"
            >
              <svg class="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Google
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</MainLayout>

<style>
  .input {
    @apply block w-full px-3 py-2 border border-border rounded-lg;
    @apply bg-bg-primary text-text-primary;
    @apply focus:ring-2 focus:ring-accent focus:border-transparent;
    @apply transition-colors;
  }

  .btn {
    @apply px-4 py-2 rounded-lg font-medium;
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
```

---

### STEP 4: Create Login Page

```bash
cat > src/pages/login.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import { createSupabaseServerClient } from '../lib/auth';

const errors: Record<string, string> = {};

// Check if already logged in
const supabase = createSupabaseServerClient(Astro.cookies);
const { data: { session } } = await supabase.auth.getSession();

if (session) {
  return Astro.redirect('/dashboard');
}

// Handle form submission
if (Astro.request.method === 'POST') {
  try {
    const formData = await Astro.request.formData();
    const email = formData.get('email')?.toString();
    const password = formData.get('password')?.toString();

    // Validation
    if (!email || !email.includes('@')) {
      errors.email = 'Valid email is required';
    }

    if (!password) {
      errors.password = 'Password is required';
    }

    // If no errors, attempt login
    if (Object.keys(errors).length === 0) {
      const { error } = await supabase.auth.signInWithPassword({
        email: email!,
        password: password!,
      });

      if (error) {
        errors.form = 'Invalid email or password';
      } else {
        // Successful login - redirect to dashboard
        return Astro.redirect('/dashboard');
      }
    }
  } catch (error) {
    console.error('Login error:', error);
    errors.form = 'An unexpected error occurred';
  }
}
---

<MainLayout
  title="Sign In"
  description="Sign in to your account"
>
  <div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <!-- Header -->
      <div class="text-center">
        <h1 class="text-4xl font-bold">Welcome Back</h1>
        <p class="mt-2 text-text-secondary">
          Or{' '}
          <a href="/signup" class="text-accent hover:text-accent/80">
            create a new account
          </a>
        </p>
      </div>

      <!-- Form Error -->
      {errors.form && (
        <div class="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
          <p class="text-red-600 dark:text-red-400">{errors.form}</p>
        </div>
      )}

      <!-- Login Form -->
      <form method="POST" class="mt-8 space-y-6">
        <!-- Email -->
        <div>
          <label for="email" class="block text-sm font-medium mb-2">
            Email address
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            class="input w-full"
            placeholder="you@example.com"
            autocomplete="email"
          />
          {errors.email && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.email}
            </p>
          )}
        </div>

        <!-- Password -->
        <div>
          <div class="flex items-center justify-between mb-2">
            <label for="password" class="block text-sm font-medium">
              Password
            </label>
            <a
              href="/reset-password"
              class="text-sm text-accent hover:text-accent/80"
            >
              Forgot password?
            </a>
          </div>
          <input
            id="password"
            name="password"
            type="password"
            required
            class="input w-full"
            placeholder="••••••••"
            autocomplete="current-password"
          />
          {errors.password && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.password}
            </p>
          )}
        </div>

        <!-- Remember Me -->
        <div class="flex items-center">
          <input
            id="remember"
            name="remember"
            type="checkbox"
            class="h-4 w-4 text-accent focus:ring-accent border-border rounded"
          />
          <label for="remember" class="ml-2 block text-sm text-text-secondary">
            Remember me
          </label>
        </div>

        <!-- Submit Button -->
        <button type="submit" class="btn-primary w-full">
          Sign In
        </button>
      </form>

      <!-- OAuth Providers -->
      <div class="mt-6">
        <div class="relative">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-border"></div>
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-2 bg-bg-primary text-text-secondary">
              Or continue with
            </span>
          </div>
        </div>

        <div class="mt-6 grid grid-cols-2 gap-3">
          <!-- GitHub -->
          <form method="POST" action="/api/auth/github">
            <button
              type="submit"
              class="btn w-full flex items-center justify-center gap-2"
            >
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z" clip-rule="evenodd" />
              </svg>
              GitHub
            </button>
          </form>

          <!-- Google -->
          <form method="POST" action="/api/auth/google">
            <button
              type="submit"
              class="btn w-full flex items-center justify-center gap-2"
            >
              <svg class="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              Google
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</MainLayout>

<style>
  .input {
    @apply block w-full px-3 py-2 border border-border rounded-lg;
    @apply bg-bg-primary text-text-primary;
    @apply focus:ring-2 focus:ring-accent focus:border-transparent;
    @apply transition-colors;
  }

  .btn {
    @apply px-4 py-2 rounded-lg font-medium;
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
```

---

### STEP 5: Create OAuth API Endpoints

```bash
# Create API directory
mkdir -p src/pages/api/auth

# GitHub OAuth
cat > src/pages/api/auth/github.ts << 'EOF'
import type { APIRoute } from 'astro';
import { createSupabaseServerClient } from '../../../lib/auth';

export const POST: APIRoute = async ({ cookies, redirect, url }) => {
  const supabase = createSupabaseServerClient(cookies);

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'github',
    options: {
      redirectTo: `${url.origin}/auth/callback`,
    },
  });

  if (error) {
    return redirect('/login?error=oauth_failed');
  }

  if (data.url) {
    return redirect(data.url);
  }

  return redirect('/login');
};
EOF

# Google OAuth
cat > src/pages/api/auth/google.ts << 'EOF'
import type { APIRoute } from 'astro';
import { createSupabaseServerClient } from '../../../lib/auth';

export const POST: APIRoute = async ({ cookies, redirect, url }) => {
  const supabase = createSupabaseServerClient(cookies);

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${url.origin}/auth/callback`,
    },
  });

  if (error) {
    return redirect('/login?error=oauth_failed');
  }

  if (data.url) {
    return redirect(data.url);
  }

  return redirect('/login');
};
EOF

# Auth callback handler
cat > src/pages/auth/callback.astro << 'EOF'
---
import { createSupabaseServerClient } from '../../lib/auth';

const supabase = createSupabaseServerClient(Astro.cookies);

// Exchange code for session
const code = Astro.url.searchParams.get('code');

if (code) {
  await supabase.auth.exchangeCodeForSession(code);
}

// Redirect to dashboard
return Astro.redirect('/dashboard');
---
EOF
```

---

### STEP 6: Create Middleware for Protected Routes

```bash
cat > src/middleware/index.ts << 'EOF'
import { defineMiddleware } from 'astro:middleware';
import { createSupabaseServerClient } from '../lib/auth';

// Routes that require authentication
const protectedRoutes = [
  '/dashboard',
  '/profile',
  '/settings',
  '/admin',
];

// Routes only for unauthenticated users
const authRoutes = [
  '/login',
  '/signup',
];

export const onRequest = defineMiddleware(async ({ request, cookies, redirect, url }, next) => {
  const supabase = createSupabaseServerClient(cookies);
  const { data: { session } } = await supabase.auth.getSession();

  const isProtectedRoute = protectedRoutes.some(route =>
    url.pathname.startsWith(route)
  );

  const isAuthRoute = authRoutes.some(route =>
    url.pathname.startsWith(route)
  );

  // Redirect to login if accessing protected route without session
  if (isProtectedRoute && !session) {
    return redirect(`/login?redirect=${encodeURIComponent(url.pathname)}`);
  }

  // Redirect to dashboard if accessing auth pages with session
  if (isAuthRoute && session) {
    return redirect('/dashboard');
  }

  // Continue to the route
  return next();
});
EOF
```

---

### STEP 7: Create Protected Dashboard Page

```bash
cat > src/pages/dashboard.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import { getUserProfile } from '../lib/auth';

// Get user profile (middleware ensures user is authenticated)
const userProfile = await getUserProfile(Astro.cookies);

if (!userProfile) {
  return Astro.redirect('/login');
}

const { user, profile } = userProfile;

// Get recent posts
const supabase = createSupabaseServerClient(Astro.cookies);
const { data: posts } = await supabase
  .from('posts')
  .select('id, title, created_at, published')
  .eq('author_id', user.id)
  .order('created_at', { ascending: false })
  .limit(5);
---

<MainLayout
  title="Dashboard"
  description="Your personal dashboard"
>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-4xl font-bold">Dashboard</h1>
      <p class="mt-2 text-text-secondary">
        Welcome back, {profile.full_name || user.email}!
      </p>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
      <!-- Total Posts -->
      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-text-secondary text-sm">Total Posts</p>
            <p class="text-3xl font-bold mt-1">{posts?.length || 0}</p>
          </div>
          <div class="bg-accent/10 p-3 rounded-full">
            <svg class="w-6 h-6 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
        </div>
      </div>

      <!-- Published -->
      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-text-secondary text-sm">Published</p>
            <p class="text-3xl font-bold mt-1">
              {posts?.filter(p => p.published).length || 0}
            </p>
          </div>
          <div class="bg-green-500/10 p-3 rounded-full">
            <svg class="w-6 h-6 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
      </div>

      <!-- Drafts -->
      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-text-secondary text-sm">Drafts</p>
            <p class="text-3xl font-bold mt-1">
              {posts?.filter(p => !p.published).length || 0}
            </p>
          </div>
          <div class="bg-yellow-500/10 p-3 rounded-full">
            <svg class="w-6 h-6 text-yellow-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
            </svg>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Posts -->
    <div class="card">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-2xl font-bold">Recent Posts</h2>
        <a href="/admin/posts/new" class="btn-primary">
          New Post
        </a>
      </div>

      {posts && posts.length > 0 ? (
        <div class="space-y-4">
          {posts.map(post => (
            <div class="flex items-center justify-between p-4 bg-bg-secondary rounded-lg">
              <div class="flex-1">
                <h3 class="font-semibold">{post.title}</h3>
                <p class="text-sm text-text-secondary mt-1">
                  {new Date(post.created_at).toLocaleDateString()}
                </p>
              </div>
              <div class="flex items-center gap-4">
                <span class={`px-3 py-1 rounded-full text-sm ${
                  post.published
                    ? 'bg-green-500/10 text-green-600 dark:text-green-400'
                    : 'bg-yellow-500/10 text-yellow-600 dark:text-yellow-400'
                }`}>
                  {post.published ? 'Published' : 'Draft'}
                </span>
                <a
                  href={`/admin/posts/${post.id}/edit`}
                  class="text-accent hover:text-accent/80"
                >
                  Edit
                </a>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium">No posts yet</h3>
          <p class="mt-1 text-sm text-text-secondary">
            Get started by creating your first post
          </p>
          <div class="mt-6">
            <a href="/admin/posts/new" class="btn-primary">
              Create Post
            </a>
          </div>
        </div>
      )}
    </div>

    <!-- Quick Actions -->
    <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
      <a href="/profile" class="card hover:bg-bg-secondary transition-colors">
        <div class="flex items-center gap-4">
          <div class="bg-accent/10 p-3 rounded-full">
            <svg class="w-6 h-6 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <div>
            <h3 class="font-semibold">Edit Profile</h3>
            <p class="text-sm text-text-secondary">Update your information</p>
          </div>
        </div>
      </a>

      <a href="/settings" class="card hover:bg-bg-secondary transition-colors">
        <div class="flex items-center gap-4">
          <div class="bg-accent/10 p-3 rounded-full">
            <svg class="w-6 h-6 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </div>
          <div>
            <h3 class="font-semibold">Settings</h3>
            <p class="text-sm text-text-secondary">Manage your account</p>
          </div>
        </div>
      </a>
    </div>
  </div>
</MainLayout>

<style>
  .card {
    @apply bg-bg-primary border border-border rounded-lg p-6;
  }

  .btn-primary {
    @apply px-4 py-2 rounded-lg font-medium;
    @apply bg-accent text-white;
    @apply hover:bg-accent/80;
    @apply transition-colors;
  }
</style>
EOF
```

---

### STEP 8: Create User Profile Page

```bash
cat > src/pages/profile.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import { getUserProfile, createSupabaseServerClient } from '../lib/auth';

// Get user profile
const userProfile = await getUserProfile(Astro.cookies);

if (!userProfile) {
  return Astro.redirect('/login');
}

const { user, profile } = userProfile;
const supabase = createSupabaseServerClient(Astro.cookies);

let successMessage = '';
const errors: Record<string, string> = {};

// Handle profile update
if (Astro.request.method === 'POST') {
  try {
    const formData = await Astro.request.formData();
    const fullName = formData.get('fullName')?.toString();
    const bio = formData.get('bio')?.toString();
    const website = formData.get('website')?.toString();

    // Validation
    if (!fullName || fullName.length < 2) {
      errors.fullName = 'Full name must be at least 2 characters';
    }

    if (website && !website.match(/^https?:\/\/.+/)) {
      errors.website = 'Website must be a valid URL';
    }

    if (Object.keys(errors).length === 0) {
      const { error } = await supabase
        .from('profiles')
        .update({
          full_name: fullName,
          bio: bio || null,
          website: website || null,
        })
        .eq('id', user.id);

      if (error) {
        errors.form = error.message;
      } else {
        successMessage = 'Profile updated successfully!';
        // Refresh profile data
        const { data: updatedProfile } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

        if (updatedProfile) {
          Object.assign(profile, updatedProfile);
        }
      }
    }
  } catch (error) {
    console.error('Profile update error:', error);
    errors.form = 'An unexpected error occurred';
  }
}
---

<MainLayout
  title="Profile"
  description="Manage your profile"
>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-4xl font-bold">Profile</h1>
      <p class="mt-2 text-text-secondary">
        Manage your personal information
      </p>
    </div>

    <!-- Success Message -->
    {successMessage && (
      <div class="mb-6 bg-green-500/10 border border-green-500/20 rounded-lg p-4">
        <p class="text-green-600 dark:text-green-400">{successMessage}</p>
      </div>
    )}

    <!-- Form Error -->
    {errors.form && (
      <div class="mb-6 bg-red-500/10 border border-red-500/20 rounded-lg p-4">
        <p class="text-red-600 dark:text-red-400">{errors.form}</p>
      </div>
    )}

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Profile Card -->
      <div class="lg:col-span-1">
        <div class="card">
          <div class="text-center">
            <!-- Avatar -->
            <div class="mx-auto w-24 h-24 bg-accent/10 rounded-full flex items-center justify-center">
              {profile.avatar_url ? (
                <img
                  src={profile.avatar_url}
                  alt={profile.full_name || 'Avatar'}
                  class="w-24 h-24 rounded-full object-cover"
                />
              ) : (
                <span class="text-3xl text-accent">
                  {profile.full_name?.charAt(0).toUpperCase() || user.email?.charAt(0).toUpperCase()}
                </span>
              )}
            </div>

            <!-- Name & Email -->
            <h2 class="mt-4 text-xl font-bold">
              {profile.full_name || 'No name'}
            </h2>
            <p class="text-sm text-text-secondary">{user.email}</p>

            <!-- Member Since -->
            <p class="mt-4 text-xs text-text-secondary">
              Member since {new Date(profile.created_at).toLocaleDateString()}
            </p>

            <!-- Change Avatar Button -->
            <button
              type="button"
              class="mt-6 btn w-full"
              onclick="document.getElementById('avatar-upload')?.click()"
            >
              Change Avatar
            </button>
            <input
              id="avatar-upload"
              type="file"
              accept="image/*"
              class="hidden"
            />
          </div>
        </div>
      </div>

      <!-- Profile Form -->
      <div class="lg:col-span-2">
        <form method="POST" class="card">
          <h2 class="text-2xl font-bold mb-6">Personal Information</h2>

          <div class="space-y-6">
            <!-- Email (read-only) -->
            <div>
              <label class="block text-sm font-medium mb-2">
                Email
              </label>
              <input
                type="email"
                value={user.email}
                disabled
                class="input w-full opacity-60 cursor-not-allowed"
              />
              <p class="mt-1 text-xs text-text-secondary">
                Email cannot be changed
              </p>
            </div>

            <!-- Full Name -->
            <div>
              <label for="fullName" class="block text-sm font-medium mb-2">
                Full Name
              </label>
              <input
                id="fullName"
                name="fullName"
                type="text"
                value={profile.full_name || ''}
                class="input w-full"
                required
              />
              {errors.fullName && (
                <p class="mt-1 text-sm text-red-600 dark:text-red-400">
                  {errors.fullName}
                </p>
              )}
            </div>

            <!-- Bio -->
            <div>
              <label for="bio" class="block text-sm font-medium mb-2">
                Bio
              </label>
              <textarea
                id="bio"
                name="bio"
                rows="4"
                class="input w-full"
                placeholder="Tell us about yourself..."
              >{profile.bio || ''}</textarea>
              <p class="mt-1 text-xs text-text-secondary">
                Brief description for your profile
              </p>
            </div>

            <!-- Website -->
            <div>
              <label for="website" class="block text-sm font-medium mb-2">
                Website
              </label>
              <input
                id="website"
                name="website"
                type="url"
                value={profile.website || ''}
                class="input w-full"
                placeholder="https://example.com"
              />
              {errors.website && (
                <p class="mt-1 text-sm text-red-600 dark:text-red-400">
                  {errors.website}
                </p>
              )}
            </div>

            <!-- Submit Button -->
            <div class="flex items-center gap-4">
              <button type="submit" class="btn-primary">
                Save Changes
              </button>
              <a href="/dashboard" class="btn">
                Cancel
              </a>
            </div>
          </div>
        </form>

        <!-- Danger Zone -->
        <div class="card mt-6 border-red-500/20">
          <h3 class="text-xl font-bold text-red-600 dark:text-red-400 mb-4">
            Danger Zone
          </h3>
          <p class="text-sm text-text-secondary mb-4">
            Once you delete your account, there is no going back. Please be certain.
          </p>
          <button
            type="button"
            class="btn-danger"
            onclick="confirm('Are you sure you want to delete your account?') && (window.location.href = '/api/auth/delete-account')"
          >
            Delete Account
          </button>
        </div>
      </div>
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
    @apply transition-colors;
  }

  .btn {
    @apply px-4 py-2 rounded-lg font-medium;
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

  .btn-danger {
    @apply px-4 py-2 rounded-lg font-medium;
    @apply bg-red-600 text-white;
    @apply hover:bg-red-700;
    @apply transition-colors;
  }
</style>

<script>
  // Handle avatar upload
  const avatarInput = document.getElementById('avatar-upload') as HTMLInputElement;

  if (avatarInput) {
    avatarInput.addEventListener('change', async (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file) return;

      // Validate file size (max 2MB)
      if (file.size > 2 * 1024 * 1024) {
        alert('File size must be less than 2MB');
        return;
      }

      // Validate file type
      if (!file.type.startsWith('image/')) {
        alert('File must be an image');
        return;
      }

      // Upload to server
      const formData = new FormData();
      formData.append('avatar', file);

      try {
        const response = await fetch('/api/profile/avatar', {
          method: 'POST',
          body: formData,
        });

        if (response.ok) {
          window.location.reload();
        } else {
          alert('Failed to upload avatar');
        }
      } catch (error) {
        console.error('Upload error:', error);
        alert('Failed to upload avatar');
      }
    });
  }
</script>
EOF
```

---

### STEP 9: Create Password Reset Flow

```bash
# Reset request page
cat > src/pages/reset-password.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import { createSupabaseServerClient } from '../lib/auth';

let successMessage = '';
const errors: Record<string, string> = {};

if (Astro.request.method === 'POST') {
  try {
    const formData = await Astro.request.formData();
    const email = formData.get('email')?.toString();

    if (!email || !email.includes('@')) {
      errors.email = 'Valid email is required';
    }

    if (Object.keys(errors).length === 0) {
      const supabase = createSupabaseServerClient(Astro.cookies);

      const { error } = await supabase.auth.resetPasswordForEmail(email!, {
        redirectTo: `${Astro.url.origin}/confirm-reset`,
      });

      if (error) {
        errors.form = error.message;
      } else {
        successMessage = 'Password reset link sent! Check your email.';
      }
    }
  } catch (error) {
    console.error('Reset password error:', error);
    errors.form = 'An unexpected error occurred';
  }
}
---

<MainLayout
  title="Reset Password"
  description="Reset your password"
>
  <div class="min-h-screen flex items-center justify-center py-12 px-4">
    <div class="max-w-md w-full space-y-8">
      <div class="text-center">
        <h1 class="text-4xl font-bold">Reset Password</h1>
        <p class="mt-2 text-text-secondary">
          Enter your email to receive a reset link
        </p>
      </div>

      {successMessage && (
        <div class="bg-green-500/10 border border-green-500/20 rounded-lg p-4">
          <p class="text-green-600 dark:text-green-400">{successMessage}</p>
        </div>
      )}

      {errors.form && (
        <div class="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
          <p class="text-red-600 dark:text-red-400">{errors.form}</p>
        </div>
      )}

      <form method="POST" class="mt-8 space-y-6">
        <div>
          <label for="email" class="block text-sm font-medium mb-2">
            Email address
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            class="input w-full"
            placeholder="you@example.com"
          />
          {errors.email && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.email}
            </p>
          )}
        </div>

        <button type="submit" class="btn-primary w-full">
          Send Reset Link
        </button>

        <div class="text-center">
          <a href="/login" class="text-sm text-accent hover:text-accent/80">
            Back to login
          </a>
        </div>
      </form>
    </div>
  </div>
</MainLayout>

<style>
  .input {
    @apply block w-full px-3 py-2 border border-border rounded-lg;
    @apply bg-bg-primary text-text-primary;
    @apply focus:ring-2 focus:ring-accent focus:border-transparent;
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

# Reset confirm page
cat > src/pages/confirm-reset.astro << 'EOF'
---
import MainLayout from '../layouts/MainLayout.astro';
import { createSupabaseServerClient } from '../lib/auth';

let successMessage = '';
const errors: Record<string, string> = {};

if (Astro.request.method === 'POST') {
  try {
    const formData = await Astro.request.formData();
    const password = formData.get('password')?.toString();
    const confirmPassword = formData.get('confirmPassword')?.toString();

    if (!password || password.length < 8) {
      errors.password = 'Password must be at least 8 characters';
    }

    if (password !== confirmPassword) {
      errors.confirmPassword = 'Passwords do not match';
    }

    if (Object.keys(errors).length === 0) {
      const supabase = createSupabaseServerClient(Astro.cookies);

      const { error } = await supabase.auth.updateUser({
        password: password!,
      });

      if (error) {
        errors.form = error.message;
      } else {
        successMessage = 'Password updated successfully!';
        // Redirect to dashboard after 2 seconds
        setTimeout(() => {
          window.location.href = '/dashboard';
        }, 2000);
      }
    }
  } catch (error) {
    console.error('Password update error:', error);
    errors.form = 'An unexpected error occurred';
  }
}
---

<MainLayout
  title="Set New Password"
  description="Set your new password"
>
  <div class="min-h-screen flex items-center justify-center py-12 px-4">
    <div class="max-w-md w-full space-y-8">
      <div class="text-center">
        <h1 class="text-4xl font-bold">Set New Password</h1>
        <p class="mt-2 text-text-secondary">
          Choose a strong password for your account
        </p>
      </div>

      {successMessage && (
        <div class="bg-green-500/10 border border-green-500/20 rounded-lg p-4">
          <p class="text-green-600 dark:text-green-400">{successMessage}</p>
        </div>
      )}

      {errors.form && (
        <div class="bg-red-500/10 border border-red-500/20 rounded-lg p-4">
          <p class="text-red-600 dark:text-red-400">{errors.form}</p>
        </div>
      )}

      <form method="POST" class="mt-8 space-y-6">
        <div>
          <label for="password" class="block text-sm font-medium mb-2">
            New Password
          </label>
          <input
            id="password"
            name="password"
            type="password"
            required
            class="input w-full"
            placeholder="••••••••"
            minlength="8"
          />
          {errors.password && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.password}
            </p>
          )}
        </div>

        <div>
          <label for="confirmPassword" class="block text-sm font-medium mb-2">
            Confirm Password
          </label>
          <input
            id="confirmPassword"
            name="confirmPassword"
            type="password"
            required
            class="input w-full"
            placeholder="••••••••"
          />
          {errors.confirmPassword && (
            <p class="mt-1 text-sm text-red-600 dark:text-red-400">
              {errors.confirmPassword}
            </p>
          )}
        </div>

        <button type="submit" class="btn-primary w-full">
          Update Password
        </button>
      </form>
    </div>
  </div>
</MainLayout>

<style>
  .input {
    @apply block w-full px-3 py-2 border border-border rounded-lg;
    @apply bg-bg-primary text-text-primary;
    @apply focus:ring-2 focus:ring-accent focus:border-transparent;
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
```

---

### STEP 10: Create Logout Endpoint

```bash
cat > src/pages/logout.astro << 'EOF'
---
import { createSupabaseServerClient } from '../lib/auth';

const supabase = createSupabaseServerClient(Astro.cookies);
await supabase.auth.signOut();

return Astro.redirect('/login');
---
EOF
```

---

### STEP 11: Update Header with User Menu

```bash
cat > src/components/UserMenu.astro << 'EOF'
---
import { getUserProfile } from '../lib/auth';

const userProfile = await getUserProfile(Astro.cookies);
---

{userProfile ? (
  <div class="relative group">
    <button
      type="button"
      class="flex items-center gap-2 hover:opacity-80 transition-opacity"
      id="user-menu-button"
    >
      <div class="w-8 h-8 bg-accent/10 rounded-full flex items-center justify-center">
        {userProfile.profile.avatar_url ? (
          <img
            src={userProfile.profile.avatar_url}
            alt={userProfile.profile.full_name || 'Avatar'}
            class="w-8 h-8 rounded-full object-cover"
          />
        ) : (
          <span class="text-sm text-accent">
            {userProfile.profile.full_name?.charAt(0).toUpperCase() ||
             userProfile.user.email?.charAt(0).toUpperCase()}
          </span>
        )}
      </div>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- Dropdown Menu -->
    <div
      id="user-menu"
      class="absolute right-0 mt-2 w-48 bg-bg-primary border border-border rounded-lg shadow-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all"
    >
      <div class="py-2 px-4 border-b border-border">
        <p class="font-semibold text-sm">
          {userProfile.profile.full_name || 'User'}
        </p>
        <p class="text-xs text-text-secondary truncate">
          {userProfile.user.email}
        </p>
      </div>

      <div class="py-1">
        <a
          href="/dashboard"
          class="block px-4 py-2 text-sm hover:bg-bg-secondary transition-colors"
        >
          Dashboard
        </a>
        <a
          href="/profile"
          class="block px-4 py-2 text-sm hover:bg-bg-secondary transition-colors"
        >
          Profile
        </a>
        <a
          href="/settings"
          class="block px-4 py-2 text-sm hover:bg-bg-secondary transition-colors"
        >
          Settings
        </a>
      </div>

      <div class="py-1 border-t border-border">
        <a
          href="/logout"
          class="block px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-bg-secondary transition-colors"
        >
          Sign Out
        </a>
      </div>
    </div>
  </div>
) : (
  <div class="flex items-center gap-4">
    <a href="/login" class="hover:text-accent transition-colors">
      Sign In
    </a>
    <a href="/signup" class="btn-primary">
      Sign Up
    </a>
  </div>
)}

<style>
  .btn-primary {
    @apply px-4 py-2 rounded-lg font-medium;
    @apply bg-accent text-white;
    @apply hover:bg-accent/80;
    @apply transition-colors;
  }
</style>
EOF

# Update Header.astro to include UserMenu
cat >> src/components/Header.astro << 'EOF'
<!-- Add this after navigation links -->
import UserMenu from './UserMenu.astro';

<UserMenu />
EOF
```

---

## ✅ 3. VERIFY (Testing & Troubleshooting)

### Verification Checklist

**Authentication Flow:**
- [ ] Signup page creates new user
- [ ] Email confirmation sent (check Supabase logs)
- [ ] Login page authenticates user
- [ ] Session persists across page reloads
- [ ] Middleware protects routes
- [ ] Dashboard displays user data
- [ ] Profile page loads and updates
- [ ] Password reset flow works
- [ ] Logout clears session
- [ ] OAuth providers redirect correctly

**Security:**
- [ ] Passwords are hashed (never stored plain text)
- [ ] JWT tokens are httpOnly cookies
- [ ] RLS policies enforce data access
- [ ] CSRF protection enabled
- [ ] Input validation works
- [ ] SQL injection prevented
- [ ] XSS attacks mitigated

**User Experience:**
- [ ] Error messages are helpful
- [ ] Success messages display
- [ ] Forms preserve data on error
- [ ] Loading states show
- [ ] Redirects work correctly
- [ ] Mobile responsive
- [ ] Dark mode compatible

---

### Testing Commands

```bash
# Start dev server
npm run dev

# Test auth flow
open http://localhost:4321/signup

# Check TypeScript
npm run check

# Build for production
npm run build

# Test production build
npm run preview

# Check database
npx supabase db pull

# View migrations
ls supabase/migrations/

# Check RLS policies
npx supabase db dump --schema public
```

---

### Manual Testing

**1. Test Signup Flow:**
```bash
# 1. Visit /signup
# 2. Fill out form with valid data
# 3. Submit form
# 4. Check email for confirmation (Supabase dashboard if email disabled)
# 5. Confirm email
# 6. Should redirect to dashboard
```

**2. Test Login Flow:**
```bash
# 1. Visit /login
# 2. Enter credentials
# 3. Submit form
# 4. Should redirect to dashboard
# 5. Check session cookie in DevTools
```

**3. Test Protected Routes:**
```bash
# 1. Log out
# 2. Try to visit /dashboard
# 3. Should redirect to /login
# 4. Log in
# 5. Should redirect to /dashboard
```

**4. Test Profile Update:**
```bash
# 1. Log in
# 2. Visit /profile
# 3. Update full name
# 4. Submit form
# 5. Should show success message
# 6. Reload page
# 7. Changes should persist
```

**5. Test Password Reset:**
```bash
# 1. Visit /reset-password
# 2. Enter email
# 3. Check email for reset link
# 4. Click link
# 5. Enter new password
# 6. Should redirect to dashboard
# 7. Log out and log in with new password
```

**6. Test OAuth:**
```bash
# 1. Visit /signup or /login
# 2. Click "GitHub" or "Google"
# 3. Authorize app
# 4. Should redirect to dashboard
# 5. Profile should have OAuth data
```

---

### Troubleshooting

**Issue 1: Signup not working**
```bash
# Check Supabase connection
echo $PUBLIC_SUPABASE_URL
echo $PUBLIC_SUPABASE_ANON_KEY

# Check email provider settings
# Go to Supabase Dashboard → Authentication → Email Templates

# Check user in database
npx supabase db query "SELECT * FROM auth.users"

# Check browser console for errors
# Open DevTools → Console
```

**Issue 2: Session not persisting**
```bash
# Check cookie settings
# DevTools → Application → Cookies

# Verify middleware is running
console.log('Middleware running:', Astro.url.pathname);

# Check Supabase client initialization
# Ensure createServerClient is used, not createClient

# Verify cookie domain and path
# Should be set for entire domain
```

**Issue 3: Middleware redirecting incorrectly**
```bash
# Check protected routes array
const protectedRoutes = ['/dashboard', '/profile'];

# Add logging
console.log('Checking route:', url.pathname);
console.log('Session:', session);

# Verify URL path matching
# Ensure routes start with / and no trailing slash
```

**Issue 4: OAuth not working**
```bash
# Check OAuth provider configuration
# Supabase Dashboard → Authentication → Providers

# Verify redirect URLs
# Must match exactly: http://localhost:4321/auth/callback

# Check GitHub/Google OAuth app settings
# Callback URL must be: https://[project-ref].supabase.co/auth/v1/callback

# Test OAuth flow
curl -X POST http://localhost:4321/api/auth/github
```

**Issue 5: Profile not updating**
```bash
# Check RLS policies
npx supabase db query "SELECT * FROM pg_policies WHERE tablename = 'profiles'"

# Verify user ID matches
console.log('User ID:', user.id);
console.log('Profile ID:', profile.id);

# Check update query
const { data, error } = await supabase
  .from('profiles')
  .update({ full_name: 'Test' })
  .eq('id', user.id)
  .select();

console.log('Update result:', { data, error });
```

**Issue 6: Password reset not sending email**
```bash
# Check email templates
# Supabase Dashboard → Authentication → Email Templates

# Verify SMTP settings (if using custom provider)
# Dashboard → Settings → Email

# Check rate limiting
# Too many requests = temporary block

# View email logs
# Dashboard → Authentication → Users → Click user → Email logs
```

**Issue 7: Avatar upload failing**
```bash
# Check storage bucket exists
npx supabase storage list

# Verify storage policies
npx supabase storage buckets list --with-policies

# Check file size limit (default: 50MB)
# Can configure in Dashboard → Storage → Settings

# Test upload manually
const { data, error } = await supabase.storage
  .from('avatars')
  .upload('test.jpg', file);
console.log({ data, error });
```

---

### Common Errors

**Error: "Invalid API key"**
```
Solution: Check environment variables are loaded
- Verify .env file exists
- Restart dev server after adding env vars
- Check PUBLIC_ prefix for client-side vars
```

**Error: "Email not confirmed"**
```
Solution: Disable email confirmation for development
- Dashboard → Authentication → Settings
- Disable "Email Confirmations"
- Or confirm email manually in Dashboard → Authentication → Users
```

**Error: "Row Level Security policy violation"**
```
Solution: Check RLS policies allow operation
- Verify policy USING and WITH CHECK clauses
- Ensure auth.uid() matches user ID
- Test policies in SQL editor
```

**Error: "Cookie not set"**
```
Solution: Verify cookie configuration
- Check createServerClient cookie handlers
- Ensure httpOnly, secure, sameSite set correctly
- Verify domain and path settings
```

**Error: "Redirect loop"**
```
Solution: Fix middleware logic
- Check protected routes don't redirect to themselves
- Verify auth routes don't redirect to auth routes
- Add logging to debug redirect chain
```

---

### Performance Optimization

**1. Cache user sessions:**
```typescript
// Use request-scoped cache
let sessionCache: Session | null | undefined;

export async function getSession(cookies: AstroCookies) {
  if (sessionCache !== undefined) return sessionCache;

  const supabase = createSupabaseServerClient(cookies);
  const { data: { session } } = await supabase.auth.getSession();

  sessionCache = session;
  return session;
}
```

**2. Reduce database queries:**
```typescript
// Fetch user and profile together
const { data } = await supabase
  .from('profiles')
  .select('*, auth.users(*)')
  .eq('id', user.id)
  .single();
```

**3. Optimize middleware:**
```typescript
// Only run auth check on protected routes
export const onRequest = defineMiddleware(async (context, next) => {
  const isProtected = protectedRoutes.some(route =>
    context.url.pathname.startsWith(route)
  );

  if (!isProtected) return next();

  // Check auth only for protected routes
  const session = await getSession(context.cookies);
  if (!session) return context.redirect('/login');

  return next();
});
```

---

## 🎯 What You Built

### Pages (9)
- ✅ **Signup** - User registration with validation
- ✅ **Login** - Authentication with OAuth
- ✅ **Dashboard** - Protected user dashboard
- ✅ **Profile** - User profile management
- ✅ **Reset Password** - Password reset request
- ✅ **Confirm Reset** - Password reset confirmation
- ✅ **Logout** - Session termination
- ✅ **Auth Callback** - OAuth callback handler
- ✅ **Settings** - Account settings (placeholder)

### Components (1)
- ✅ **UserMenu** - Dropdown menu for logged-in users

### Utilities (2)
- ✅ **auth.ts** - Auth helper functions
- ✅ **auth-types.ts** - TypeScript types

### Middleware (1)
- ✅ **auth.ts** - Route protection and session validation

### Database (2)
- ✅ **profiles** table - User profile data
- ✅ **avatars** bucket - User avatar storage

### Features
- ✅ **Email/Password Auth** - Secure authentication
- ✅ **OAuth Providers** - GitHub, Google integration
- ✅ **Protected Routes** - Middleware-based protection
- ✅ **Session Management** - Persistent sessions
- ✅ **Profile Management** - Update user info
- ✅ **Password Reset** - Self-service password reset
- ✅ **Avatar Upload** - Profile picture management
- ✅ **Row Level Security** - Database-level protection
- ✅ **Type Safety** - Full TypeScript support

---

## 🚀 Next Steps

In **Lesson 6**, you'll learn:
- Server Islands architecture
- Dynamic user-specific content
- Real-time like/bookmark buttons
- View counters
- Personalized recommendations
- Encrypted props for security
- Server-side state management

**Continue to:** [LESSON-6-SERVER-ISLANDS.md](./LESSON-6-SERVER-ISLANDS.md)

---

## 📚 Key Concepts Review

### Supabase Auth
- JWT-based authentication
- Secure httpOnly cookies
- Automatic token refresh
- Multiple auth providers
- Email verification flow

### Row Level Security (RLS)
- Database-level access control
- Policy-based permissions
- auth.uid() function for user context
- Secure by default

### Astro Middleware
- Request interception
- Server-side auth checks
- Cookie manipulation
- Redirect handling

### Session Management
- Cookie-based sessions
- Server-side validation
- Token expiry and refresh
- Logout and cleanup

### OAuth Integration
- Provider configuration
- Callback handling
- Token exchange
- Profile data sync

---

## 💡 Pro Tips

1. **Always use server-side auth checks:**
```astro
---
const session = await getSession(Astro.cookies);
if (!session) return Astro.redirect('/login');
---
```

2. **Enable RLS on all tables:**
```sql
ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;
```

3. **Use transactions for complex operations:**
```typescript
const { data, error } = await supabase.rpc('create_user_with_profile', {
  email: 'user@example.com',
  full_name: 'John Doe',
});
```

4. **Implement rate limiting:**
```typescript
// Use Supabase Edge Functions or Cloudflare Workers
// To prevent brute force attacks
```

5. **Log security events:**
```typescript
await supabase
  .from('security_logs')
  .insert({
    user_id: user.id,
    event: 'login',
    ip_address: request.headers.get('x-forwarded-for'),
  });
```

---

**Congratulations!** 🎉 You've implemented a complete authentication system with Supabase.

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 4-6 hours
