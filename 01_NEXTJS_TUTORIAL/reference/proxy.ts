import { type NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

/**
 * Next.js 16 Proxy
 *
 * Replaces middleware.ts in Next.js 16
 * Runs on Node.js runtime (not Edge)
 *
 * Purpose:
 * - Refresh Supabase auth sessions automatically
 * - Update cookies for authenticated users
 * - Runs before every request that matches the config
 *
 * Why "proxy" not "middleware"?
 * - Clearer naming for network boundary
 * - Node.js runtime for predictable behavior
 * - Separates routing logic from app logic
 */
export async function proxy(request: NextRequest) {
  // Refresh Supabase session and update cookies
  return await updateSession(request)
}

/**
 * Config: Which routes should trigger this proxy
 *
 * Matches all routes EXCEPT:
 * - Static files (_next/static)
 * - Image optimization (_next/image)
 * - Favicon
 * - Public images (svg, png, jpg, etc.)
 *
 * This ensures session refresh on every page navigation
 * but skips unnecessary calls for static assets
 */
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - *.svg, *.png, *.jpg, *.jpeg, *.gif, *.webp (image files)
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
