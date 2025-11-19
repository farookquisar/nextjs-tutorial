import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

/**
 * Updates and refreshes Supabase session in middleware/proxy
 *
 * This function:
 * 1. Creates a Supabase server client with cookie handlers
 * 2. Refreshes the auth token if expired (via getUser())
 * 3. Updates cookies in both request and response
 * 4. Returns the response with refreshed session
 *
 * Why this is needed:
 * - Server Components cannot write cookies
 * - Middleware/proxy can intercept requests and refresh tokens
 * - Prevents expired session errors in Server Components
 *
 * @param request - The incoming Next.js request
 * @returns NextResponse with updated cookies
 */
export async function updateSession(request: NextRequest) {
  // Create a response object that we'll modify
  let supabaseResponse = NextResponse.next({
    request,
  })

  // Create Supabase client with custom cookie handlers
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!,
    {
      cookies: {
        // Read all cookies from the request
        getAll() {
          return request.cookies.getAll()
        },
        // Write cookies to both request and response
        setAll(cookiesToSet) {
          // Set cookies on the request (for Server Components to read)
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )

          // Create new response with updated request cookies
          supabaseResponse = NextResponse.next({
            request,
          })

          // Set cookies on the response (for browser to receive)
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // IMPORTANT: Refresh session if expired
  // This triggers the cookie refresh via setAll above
  // getUser() is secure - it validates the JWT signature
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Optional: Add user info to request headers for Server Components
  // This avoids additional database calls in components
  if (user) {
    supabaseResponse.headers.set('x-user-id', user.id)
    supabaseResponse.headers.set('x-user-email', user.email || '')
  }

  return supabaseResponse
}

/**
 * Protected route checker
 * Use this in your proxy.ts to redirect unauthenticated users
 *
 * Example:
 * const response = await updateSession(request)
 * const isProtected = isProtectedRoute(request.nextUrl.pathname)
 * if (isProtected && !response.headers.get('x-user-id')) {
 *   return NextResponse.redirect(new URL('/login', request.url))
 * }
 */
export function isProtectedRoute(pathname: string): boolean {
  const protectedPaths = [
    '/dashboard',
    '/projects',
    '/profile',
    '/settings',
  ]

  return protectedPaths.some(path => pathname.startsWith(path))
}

/**
 * Public-only route checker
 * Use this to redirect authenticated users away from login/signup
 *
 * Example:
 * const isPublicOnly = isPublicOnlyRoute(request.nextUrl.pathname)
 * if (isPublicOnly && response.headers.get('x-user-id')) {
 *   return NextResponse.redirect(new URL('/dashboard', request.url))
 * }
 */
export function isPublicOnlyRoute(pathname: string): boolean {
  const publicOnlyPaths = [
    '/login',
    '/signup',
    '/forgot-password',
  ]

  return publicOnlyPaths.some(path => pathname.startsWith(path))
}
