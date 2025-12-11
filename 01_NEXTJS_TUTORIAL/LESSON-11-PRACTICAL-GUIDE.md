# Lesson 11: Payments & Subscriptions with Stripe

**Tutorial:** Next.js 16 + React 19.2 + Supabase - Complete Learning Path
**Focus:** Stripe payment integration and subscription management
**Prerequisites:** Lessons 1-10 completed

---

## What You'll Build

In this lesson, you'll implement a **complete payment and subscription system** with Stripe:

- ✅ **Freemium Model** - 2 free projects, paid plans for more
- ✅ **Stripe Checkout** - Secure payment processing
- ✅ **Subscription Management** - Create, upgrade, downgrade, cancel
- ✅ **Pricing Page** - Display pricing tiers with features
- ✅ **Billing Portal** - Customer self-service portal
- ✅ **Webhook Handling** - Process Stripe events (payment success, cancellation)
- ✅ **Usage Enforcement** - Block project creation when limit reached
- ✅ **Subscription Status** - Display current plan and usage
- ✅ **Invoice History** - Track all payments and invoices
- ✅ **RLS Integration** - Database-level subscription enforcement

### Business Model

**Free Tier:**
- ✅ 2 projects maximum
- ✅ All basic features
- ❌ Limited team members (3 per project)
- ❌ Limited storage (100 MB)

**Pro Tier ($10/month):**
- ✅ 10 projects
- ✅ All features
- ✅ 10 team members per project
- ✅ 5 GB storage

**Team Tier ($25/month):**
- ✅ Unlimited projects
- ✅ All features
- ✅ Unlimited team members
- ✅ 50 GB storage
- ✅ Priority support

### Technologies Used

- **Stripe** - Payment processing and subscriptions
- **Stripe Checkout** - Hosted checkout pages
- **Stripe Customer Portal** - Self-service billing management
- **Stripe Webhooks** - Event-driven payment updates
- **Next.js API Routes** - Webhook endpoints
- **Supabase** - Subscription data storage with RLS

---

## Architecture Overview

### Payment Flow

```
User Journey:
1. User signs up → Free tier (2 projects)
2. User creates 2 projects → Limit reached
3. User clicks "Upgrade" → Pricing page
4. User selects plan → Stripe Checkout
5. User completes payment → Webhook fires
6. Database updated → Subscription active
7. User can create more projects ✅
```

### Database Schema

```
prj_user_subscriptions
├── id (uuid, primary key)
├── user_id (uuid, foreign key → auth.users)
├── stripe_customer_id (text, unique)
├── stripe_subscription_id (text, unique)
├── plan_id (text) -- 'free', 'pro', 'team'
├── status (text) -- 'active', 'canceled', 'past_due', 'trialing'
├── current_period_start (timestamptz)
├── current_period_end (timestamptz)
├── cancel_at_period_end (boolean)
├── created_at (timestamptz)
└── updated_at (timestamptz)

prj_payment_history
├── id (uuid, primary key)
├── user_id (uuid, foreign key → auth.users)
├── stripe_payment_intent_id (text)
├── stripe_invoice_id (text)
├── amount (integer) -- Amount in cents
├── currency (text) -- 'usd', 'eur', etc.
├── status (text) -- 'succeeded', 'pending', 'failed'
├── description (text)
├── created_at (timestamptz)
```

### Subscription Limits

```typescript
const PLAN_LIMITS = {
  free: {
    max_projects: 2,
    max_members_per_project: 3,
    max_storage_mb: 100,
  },
  pro: {
    max_projects: 10,
    max_members_per_project: 10,
    max_storage_mb: 5120, // 5 GB
  },
  team: {
    max_projects: -1, // unlimited
    max_members_per_project: -1, // unlimited
    max_storage_mb: 51200, // 50 GB
  },
};
```

---

## Caching Strategy for Payments & Subscriptions

### Why Cache Billing Data?

Billing and subscription systems benefit from strategic caching to:
- ✅ **Reduce Database Load** - Subscription queries can be expensive
- ✅ **Improve Performance** - Faster page loads for billing dashboards
- ✅ **Lower Costs** - Fewer Supabase queries = lower costs
- ✅ **Better UX** - Instant loading with cached data

### Cache Lifetimes Based on Data Volatility

Different types of billing data have different update frequencies:

| Data Type | Cache Duration | Reason | Cache Tag |
|-----------|----------------|---------|-----------|
| **Subscription Status** | 5 minutes | Changes when user upgrades/downgrades | `subscriptions`, `user-{id}-subscription` |
| **Payment History** | 1 hour | Historical data, rarely changes | `payment-history`, `user-{id}-payments` |
| **Pricing Plans** | 24 hours | Static data, changes infrequently | `pricing` |

### Webhook-Driven Cache Invalidation

The key to accurate cached billing data is **webhook-driven invalidation**:

```typescript
// Stripe webhook updates database AND invalidates cache
case 'customer.subscription.updated':
  await updateSubscription(...)  // Update database
  updateTag('subscriptions')      // Invalidate all subscriptions cache
  updateTag(`user-${userId}-subscription`) // Invalidate user-specific cache
```

**How it works:**
1. User upgrades plan in Stripe Checkout
2. Stripe webhook fires → updates database
3. Cache invalidated automatically via `updateTag()`
4. Next page load fetches fresh data
5. Data re-cached for 5 minutes

### User-Specific Cache Tags

Each user's billing data is cached independently:

```typescript
async function SubscriptionOverview({ userId }: { userId: string }) {
  'use cache';
  cacheLife('minutes');
  cacheTag('subscriptions');           // Global tag
  cacheTag(`user-${userId}-subscription`); // User-specific tag

  // User A's cache is separate from User B's cache
  const subscription = await getUserSubscription();
  return <BillingOverview subscription={subscription} />;
}
```

**Benefits:**
- ✅ Invalidating User A's cache doesn't affect User B
- ✅ Each user gets their own cached data
- ✅ More efficient than global cache invalidation

### Security Considerations with Cached Billing Data

**1. User Isolation**
```typescript
// ✅ CORRECT - User ID passed as prop, cached per user
<SubscriptionOverview userId={user.id} />

// ❌ WRONG - Would cache globally, exposing data
<SubscriptionOverview /> // No user context
```

**2. RLS Still Applies**
Even with caching, Row Level Security (RLS) in Supabase ensures users can only see their own data:
```sql
CREATE POLICY "Users can view own subscription"
  ON prj_user_subscriptions
  FOR SELECT
  USING (user_id = auth.uid());
```

**3. Sensitive Data**
Never cache:
- ❌ Credit card numbers (we don't store these anyway)
- ❌ Full card details
- ✅ Safe to cache: Plan name, status, subscription ID, payment amounts

### Cache vs. Real-Time Updates

**When cache is acceptable:**
- Viewing subscription status (5 min delay OK)
- Viewing payment history (1 hour delay OK)
- Viewing pricing plans (24 hour delay OK)

**When you need real-time:**
- Immediately after payment → Redirect to success page (no cache)
- Webhook events → Always update database + invalidate cache
- Admin operations → Bypass cache, query database directly

### Example: Complete Billing Cache Flow

```typescript
// 1. User visits billing dashboard
export default async function BillingPage() {
  // Auth check (not cached)
  const { user } = await supabase.auth.getUser();

  return (
    <>
      {/* 2. Subscription cached for 5 minutes */}
      <Suspense fallback={<LoadingSkeleton />}>
        <SubscriptionOverview userId={user.id} />
      </Suspense>

      {/* 3. Payment history cached for 1 hour */}
      <Suspense fallback={<LoadingSkeleton />}>
        <PaymentHistory userId={user.id} />
      </Suspense>
    </>
  );
}

// 4. Cached component with user-specific tag
async function SubscriptionOverview({ userId }: { userId: string }) {
  'use cache';
  cacheLife('minutes'); // 5 minutes
  cacheTag(`user-${userId}-subscription`);

  const subscription = await getUserSubscription();
  return <BillingOverview subscription={subscription} />;
}

// 5. Webhook invalidates cache on updates
export async function POST(request: Request) {
  const event = await stripe.webhooks.constructEvent(...);

  switch (event.type) {
    case 'customer.subscription.updated':
      await updateSubscription(...);
      updateTag(`user-${userId}-subscription`); // ✅ Invalidate user's cache
      break;
  }
}
```

### Cache Performance Metrics

**Before Caching:**
- Subscription query: ~200ms per request
- Payment history query: ~150ms per request
- Total: ~350ms per page load
- Database cost: High (every page load queries DB)

**After Caching:**
- First load: ~350ms (cache MISS)
- Subsequent loads: ~10ms (cache HIT)
- Database cost: Low (queries only on cache MISS)
- **95% reduction in database queries**

---

## Prerequisites

### 1. Create Stripe Account

1. Go to https://stripe.com
2. Sign up for a Stripe account
3. Verify your email
4. Complete business information (can use test mode for development)

### 2. Get Stripe API Keys

**In Stripe Dashboard:**
1. Go to **Developers → API keys**
2. Copy:
   - **Publishable key** (starts with `pk_test_`)
   - **Secret key** (starts with `sk_test_`)
3. Keep these safe - you'll add them to `.env.local`

---

## Step 1: Install Stripe Dependencies

```bash
npm install stripe @stripe/stripe-js
npm install -D @types/stripe
```

---

## Step 2: Configure Next.js for Cache Components

Enable the experimental `cacheComponents` feature in your Next.js configuration:

```bash
cat > next.config.ts << 'EOF'
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    cacheComponents: true, // ✅ Enable Cache Components
  },
  // ... your existing config
};

export default nextConfig;
EOF
```

**Why Cache Components for Billing?**

Billing and subscription data has unique caching requirements:

- **Subscription Status**: Needs quick updates (5 minutes) when users upgrade/downgrade
- **Payment History**: Historical data that rarely changes (1 hour)
- **Pricing Plans**: Static data that changes infrequently (24 hours)
- **User-Specific**: Each user's billing data cached independently

**Cache Strategy:**
- ✅ `cacheLife('minutes')` for active subscription data
- ✅ `cacheLife('hours')` for payment history
- ✅ `cacheLife('days')` for pricing information
- ✅ Webhook-driven cache invalidation for real-time updates

---

## Step 3: Create Stripe Products in Dashboard

**In Stripe Dashboard:**

### 3.1 Create Pro Plan Product

1. Go to **Products → Add product**
2. **Name:** "Pro Plan"
3. **Description:** "10 projects, 10 team members per project, 5 GB storage"
4. **Pricing:**
   - **Price:** $10.00 USD
   - **Billing period:** Monthly
   - **Recurring:** Yes
5. Click **Save product**
6. **Copy the Price ID** (starts with `price_`) - you'll need this

### 3.2 Create Team Plan Product

1. Go to **Products → Add product**
2. **Name:** "Team Plan"
3. **Description:** "Unlimited projects and team members, 50 GB storage"
4. **Pricing:**
   - **Price:** $25.00 USD
   - **Billing period:** Monthly
   - **Recurring:** Yes
5. Click **Save product**
6. **Copy the Price ID** (starts with `price_`) - you'll need this

---

## Step 4: Add Environment Variables

Update `.env.local` with Stripe credentials:

```bash
cat >> .env.local << 'EOF'

# ============================================================
# STRIPE (Lesson 11)
# ============================================================

# Stripe API Keys (from Stripe Dashboard → Developers → API keys)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_secret_key_here

# Stripe Webhook Secret (will get this after setting up webhook)
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Stripe Price IDs (from Products in Stripe Dashboard)
STRIPE_PRO_PRICE_ID=price_your_pro_price_id_here
STRIPE_TEAM_PRICE_ID=price_your_team_price_id_here

EOF
```

---

## Step 5: Extend Constants

Add subscription and pricing constants:

```bash
cat >> src/constants/index.ts << 'EOF'

// ============================================================
// SUBSCRIPTION & PRICING CONSTANTS (Lesson 11)
// ============================================================

export const SUBSCRIPTION_PLANS = {
  FREE: 'free',
  PRO: 'pro',
  TEAM: 'team',
} as const;

export const SUBSCRIPTION_STATUS = {
  ACTIVE: 'active',
  CANCELED: 'canceled',
  PAST_DUE: 'past_due',
  TRIALING: 'trialing',
  INCOMPLETE: 'incomplete',
  INCOMPLETE_EXPIRED: 'incomplete_expired',
  UNPAID: 'unpaid',
} as const;

export const PLAN_DETAILS = {
  [SUBSCRIPTION_PLANS.FREE]: {
    name: 'Free',
    price: 0,
    priceId: null,
    interval: null,
    features: [
      '2 projects',
      '3 team members per project',
      '100 MB storage',
      'Basic features',
    ],
    limits: {
      max_projects: 2,
      max_members_per_project: 3,
      max_storage_mb: 100,
    },
  },
  [SUBSCRIPTION_PLANS.PRO]: {
    name: 'Pro',
    price: 10,
    priceId: process.env.STRIPE_PRO_PRICE_ID!,
    interval: 'month',
    features: [
      '10 projects',
      '10 team members per project',
      '5 GB storage',
      'All features',
      'Email support',
    ],
    limits: {
      max_projects: 10,
      max_members_per_project: 10,
      max_storage_mb: 5120,
    },
  },
  [SUBSCRIPTION_PLANS.TEAM]: {
    name: 'Team',
    price: 25,
    priceId: process.env.STRIPE_TEAM_PRICE_ID!,
    interval: 'month',
    features: [
      'Unlimited projects',
      'Unlimited team members',
      '50 GB storage',
      'All features',
      'Priority support',
      'Advanced analytics',
    ],
    limits: {
      max_projects: -1, // -1 means unlimited
      max_members_per_project: -1,
      max_storage_mb: 51200,
    },
  },
} as const;

export const PAYMENT_STATUS = {
  SUCCEEDED: 'succeeded',
  PENDING: 'pending',
  FAILED: 'failed',
  REFUNDED: 'refunded',
} as const;

export const BILLING_ROUTES = {
  PRICING: '/pricing',
  BILLING: '/dashboard/billing',
  CHECKOUT_SUCCESS: '/dashboard/billing/success',
  CHECKOUT_CANCEL: '/dashboard/billing/cancel',
} as const;

export const BILLING_MESSAGES = {
  UPGRADE_REQUIRED: 'Upgrade your plan to create more projects',
  PROJECT_LIMIT_REACHED: 'You have reached your project limit',
  MEMBER_LIMIT_REACHED: 'You have reached the team member limit for this project',
  STORAGE_LIMIT_REACHED: 'You have reached your storage limit',
  SUBSCRIPTION_CANCELED: 'Your subscription has been canceled',
  PAYMENT_FAILED: 'Payment failed. Please update your payment method.',
} as const;

// Type exports
export type SubscriptionPlan = typeof SUBSCRIPTION_PLANS[keyof typeof SUBSCRIPTION_PLANS];
export type SubscriptionStatus = typeof SUBSCRIPTION_STATUS[keyof typeof SUBSCRIPTION_STATUS];
export type PaymentStatus = typeof PAYMENT_STATUS[keyof typeof PAYMENT_STATUS];

EOF
```

---

## Step 6: Create Database Migration for Subscriptions

```bash
cat > supabase/migrations/007_subscriptions.sql << 'EOF'
-- ============================================================
-- LESSON 11: SUBSCRIPTIONS & PAYMENTS
-- ============================================================

-- User Subscriptions Table
CREATE TABLE IF NOT EXISTS prj_user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  plan_id TEXT NOT NULL DEFAULT 'free', -- 'free', 'pro', 'team'
  status TEXT NOT NULL DEFAULT 'active', -- 'active', 'canceled', 'past_due', etc.
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment History Table
CREATE TABLE IF NOT EXISTS prj_payment_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_payment_intent_id TEXT,
  stripe_invoice_id TEXT,
  amount INTEGER NOT NULL, -- Amount in cents
  currency TEXT NOT NULL DEFAULT 'usd',
  status TEXT NOT NULL, -- 'succeeded', 'pending', 'failed', 'refunded'
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_user_subscriptions_user_id ON prj_user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_stripe_customer ON prj_user_subscriptions(stripe_customer_id);
CREATE INDEX idx_payment_history_user_id ON prj_payment_history(user_id);

-- Enable RLS
ALTER TABLE prj_user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prj_payment_history ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS POLICIES: Subscriptions
-- ============================================================

-- Users can view their own subscription
CREATE POLICY "Users can view own subscription"
  ON prj_user_subscriptions
  FOR SELECT
  USING (user_id = auth.uid());

-- Users can insert their own subscription (when first created)
CREATE POLICY "Users can create own subscription"
  ON prj_user_subscriptions
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Only service role can update subscriptions (via webhooks)
CREATE POLICY "Service role can update subscriptions"
  ON prj_user_subscriptions
  FOR UPDATE
  USING (true);

-- ============================================================
-- RLS POLICIES: Payment History
-- ============================================================

-- Users can view their own payment history
CREATE POLICY "Users can view own payment history"
  ON prj_payment_history
  FOR SELECT
  USING (user_id = auth.uid());

-- Service role can insert payment records (via webhooks)
CREATE POLICY "Service role can insert payment history"
  ON prj_payment_history
  FOR INSERT
  WITH CHECK (true);

-- ============================================================
-- TRIGGER: Auto-create free subscription on user signup
-- ============================================================

CREATE OR REPLACE FUNCTION create_free_subscription()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO prj_user_subscriptions (user_id, plan_id, status)
  VALUES (NEW.id, 'free', 'active');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS auto_create_subscription ON auth.users;
CREATE TRIGGER auto_create_subscription
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_free_subscription();

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Get user's current subscription with limits
CREATE OR REPLACE FUNCTION get_user_subscription(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  plan_id TEXT,
  status TEXT,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN,
  project_count BIGINT,
  max_projects INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.user_id,
    s.plan_id,
    s.status,
    s.current_period_end,
    s.cancel_at_period_end,
    COUNT(p.id) AS project_count,
    CASE s.plan_id
      WHEN 'free' THEN 2
      WHEN 'pro' THEN 10
      WHEN 'team' THEN -1 -- unlimited
    END AS max_projects
  FROM prj_user_subscriptions s
  LEFT JOIN prj_projects p ON p.owner_id = s.user_id
  WHERE s.user_id = p_user_id
  GROUP BY s.id, s.user_id, s.plan_id, s.status, s.current_period_end, s.cancel_at_period_end;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user can create a project based on subscription
CREATE OR REPLACE FUNCTION can_create_project(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_plan_id TEXT;
  v_project_count BIGINT;
  v_max_projects INTEGER;
  v_status TEXT;
BEGIN
  -- Get user's subscription info
  SELECT
    s.plan_id,
    s.status,
    COUNT(p.id),
    CASE s.plan_id
      WHEN 'free' THEN 2
      WHEN 'pro' THEN 10
      WHEN 'team' THEN -1
    END
  INTO v_plan_id, v_status, v_project_count, v_max_projects
  FROM prj_user_subscriptions s
  LEFT JOIN prj_projects p ON p.owner_id = s.user_id
  WHERE s.user_id = p_user_id
  GROUP BY s.plan_id, s.status;

  -- Check if subscription is active
  IF v_status != 'active' THEN
    RETURN FALSE;
  END IF;

  -- Check project limit
  IF v_max_projects = -1 THEN
    RETURN TRUE; -- unlimited
  END IF;

  RETURN v_project_count < v_max_projects;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get payment history for user
CREATE OR REPLACE FUNCTION get_payment_history(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  amount INTEGER,
  currency TEXT,
  status TEXT,
  description TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ph.id,
    ph.amount,
    ph.currency,
    ph.status,
    ph.description,
    ph.created_at
  FROM prj_payment_history ph
  WHERE ph.user_id = p_user_id
  ORDER BY ph.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

EOF
```

**Run migration:**

```bash
supabase db push
# Or run in Supabase Dashboard → SQL Editor
```

---

## Step 7: Create Stripe Utilities

Create utility functions for Stripe operations:

```bash
mkdir -p src/lib/stripe
cat > src/lib/stripe/client.ts << 'EOF'
import { loadStripe, Stripe } from '@stripe/stripe-js';

let stripePromise: Promise<Stripe | null>;

/**
 * Get Stripe.js instance (client-side only)
 */
export const getStripe = () => {
  if (!stripePromise) {
    stripePromise = loadStripe(
      process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!
    );
  }
  return stripePromise;
};

EOF
```

Create server-side Stripe client:

```bash
cat > src/lib/stripe/server.ts << 'EOF'
import Stripe from 'stripe';

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error('STRIPE_SECRET_KEY is not set');
}

/**
 * Stripe API client (server-side only)
 */
export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2024-11-20.acacia',
  typescript: true,
});

/**
 * Create or retrieve Stripe customer
 */
export async function getOrCreateStripeCustomer(userId: string, email: string) {
  const { createClient } = await import('@/lib/supabase/server');
  const supabase = await createClient();

  // Check if customer already exists in database
  const { data: subscription } = await supabase
    .from('prj_user_subscriptions')
    .select('stripe_customer_id')
    .eq('user_id', userId)
    .single();

  if (subscription?.stripe_customer_id) {
    return subscription.stripe_customer_id;
  }

  // Create new Stripe customer
  const customer = await stripe.customers.create({
    email,
    metadata: {
      supabase_user_id: userId,
    },
  });

  // Update database with customer ID
  await supabase
    .from('prj_user_subscriptions')
    .update({ stripe_customer_id: customer.id })
    .eq('user_id', userId);

  return customer.id;
}

/**
 * Format amount for display (cents to dollars)
 */
export function formatAmount(amount: number, currency: string = 'usd'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency.toUpperCase(),
  }).format(amount / 100);
}

EOF
```

---

## Step 8: Create Subscription Types

```bash
cat > src/types/subscription.ts << 'EOF'
import type { Database } from '@/lib/types/database';
import type { SubscriptionPlan, SubscriptionStatus, PaymentStatus } from '@/constants';

export type UserSubscription = Database['public']['Tables']['prj_user_subscriptions']['Row'];
export type PaymentHistory = Database['public']['Tables']['prj_payment_history']['Row'];

export type SubscriptionWithUsage = {
  id: string;
  user_id: string;
  plan_id: SubscriptionPlan;
  status: SubscriptionStatus;
  current_period_end: string | null;
  cancel_at_period_end: boolean;
  project_count: number;
  max_projects: number;
};

export type CreateCheckoutSessionInput = {
  priceId: string;
  userId: string;
  email: string;
  successUrl: string;
  cancelUrl: string;
};

export type SubscriptionLimits = {
  max_projects: number;
  max_members_per_project: number;
  max_storage_mb: number;
};

EOF
```

---

## Step 9: Create Subscription Server Actions

```bash
cat > src/lib/actions/subscriptions.ts << 'EOF'
'use server';

import { createClient } from '@/lib/supabase/server';
import { stripe, getOrCreateStripeCustomer, formatAmount } from '@/lib/stripe/server';
import { revalidatePath, updateTag } from 'next/cache';
import { BILLING_ROUTES, DB_TABLES, SUBSCRIPTION_PLANS } from '@/constants';
import type { CreateCheckoutSessionInput } from '@/types/subscription';

/**
 * Create Stripe Checkout session for subscription
 */
export async function createCheckoutSession(input: CreateCheckoutSessionInput) {
  try {
    const { priceId, userId, email, successUrl, cancelUrl } = input;

    // Get or create Stripe customer
    const customerId = await getOrCreateStripeCustomer(userId, email);

    // Create checkout session
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        user_id: userId,
      },
    });

    return { success: true, data: { url: session.url } };
  } catch (error: any) {
    console.error('Create checkout session error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Get user's subscription details
 */
export async function getUserSubscription() {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    const { data, error } = await supabase.rpc('get_user_subscription', {
      p_user_id: user.id,
    });

    if (error) {
      console.error('Get subscription error:', error);
      return { success: false, error: error.message };
    }

    return { success: true, data: data?.[0] || null };
  } catch (error: any) {
    console.error('Get subscription error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Check if user can create a project
 */
export async function canCreateProject() {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    const { data, error } = await supabase.rpc('can_create_project', {
      p_user_id: user.id,
    });

    if (error) {
      console.error('Check project limit error:', error);
      return { success: false, error: error.message };
    }

    return { success: true, data: !!data };
  } catch (error: any) {
    console.error('Check project limit error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Create Stripe Customer Portal session
 * Note: Cache invalidation happens via webhooks when user makes changes
 */
export async function createCustomerPortalSession(returnUrl: string) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    // Get stripe customer ID
    const { data: subscription } = await supabase
      .from(DB_TABLES.USER_SUBSCRIPTIONS)
      .select('stripe_customer_id')
      .eq('user_id', user.id)
      .single();

    if (!subscription?.stripe_customer_id) {
      return { success: false, error: 'No Stripe customer found' };
    }

    // Create portal session
    const session = await stripe.billingPortal.sessions.create({
      customer: subscription.stripe_customer_id,
      return_url: returnUrl,
    });

    return { success: true, data: { url: session.url } };
  } catch (error: any) {
    console.error('Create portal session error:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Get payment history
 */
export async function getPaymentHistory() {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    const { data, error } = await supabase.rpc('get_payment_history', {
      p_user_id: user.id,
    });

    if (error) {
      console.error('Get payment history error:', error);
      return { success: false, error: error.message };
    }

    return { success: true, data: data || [] };
  } catch (error: any) {
    console.error('Get payment history error:', error);
    return { success: false, error: error.message };
  }
}

EOF
```

Update constants to include new table name:

```bash
# Add to src/constants/index.ts in DB_TABLES section:
# USER_SUBSCRIPTIONS: 'prj_user_subscriptions',
# PAYMENT_HISTORY: 'prj_payment_history',
```

---

## Step 10: Create Stripe Webhook Handler with Cache Invalidation

Create API route to handle Stripe webhooks with automatic cache invalidation:

```bash
mkdir -p src/app/api/webhooks/stripe
cat > src/app/api/webhooks/stripe/route.ts << 'EOF'
import { NextRequest, NextResponse } from 'next/server';
import { stripe } from '@/lib/stripe/server';
import { createClient } from '@/lib/supabase/server';
import { updateTag } from 'next/cache';
import Stripe from 'stripe';

/**
 * Stripe webhook handler
 * Processes events: checkout.session.completed, customer.subscription.updated, etc.
 */
export async function POST(request: NextRequest) {
  const body = await request.text();
  const signature = request.headers.get('stripe-signature');

  if (!signature) {
    return NextResponse.json({ error: 'No signature' }, { status: 400 });
  }

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (error: any) {
    console.error('Webhook signature verification failed:', error.message);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const supabase = await createClient();

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session;

        if (session.mode === 'subscription' && session.subscription) {
          const subscription = await stripe.subscriptions.retrieve(
            session.subscription as string
          );

          const userId = session.metadata?.user_id;
          if (!userId) break;

          // Determine plan from price ID
          const priceId = subscription.items.data[0]?.price.id;
          let planId = 'free';

          if (priceId === process.env.STRIPE_PRO_PRICE_ID) {
            planId = 'pro';
          } else if (priceId === process.env.STRIPE_TEAM_PRICE_ID) {
            planId = 'team';
          }

          // Update subscription in database
          await supabase
            .from('prj_user_subscriptions')
            .update({
              stripe_subscription_id: subscription.id,
              stripe_customer_id: subscription.customer as string,
              plan_id: planId,
              status: subscription.status,
              current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
              current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
              cancel_at_period_end: subscription.cancel_at_period_end,
              updated_at: new Date().toISOString(),
            })
            .eq('user_id', userId);

          // ✅ Invalidate subscription cache for this user
          updateTag('subscriptions');
          updateTag(`user-${userId}-subscription`);

          console.log(`✅ Subscription created for user ${userId}`);
        }
        break;
      }

      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription;

        // Get user ID from customer
        const customer = await stripe.customers.retrieve(subscription.customer as string);
        const userId = (customer as Stripe.Customer).metadata?.supabase_user_id;

        if (!userId) break;

        // Determine plan from price ID
        const priceId = subscription.items.data[0]?.price.id;
        let planId = 'free';

        if (priceId === process.env.STRIPE_PRO_PRICE_ID) {
          planId = 'pro';
        } else if (priceId === process.env.STRIPE_TEAM_PRICE_ID) {
          planId = 'team';
        }

        // Update subscription
        await supabase
          .from('prj_user_subscriptions')
          .update({
            plan_id: planId,
            status: subscription.status,
            current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
            cancel_at_period_end: subscription.cancel_at_period_end,
            updated_at: new Date().toISOString(),
          })
          .eq('stripe_subscription_id', subscription.id);

        // ✅ Invalidate subscription cache for this user
        updateTag('subscriptions');
        updateTag(`user-${userId}-subscription`);

        console.log(`✅ Subscription updated for user ${userId}`);
        break;
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription;

        // Get user ID from customer
        const customer = await stripe.customers.retrieve(subscription.customer as string);
        const userId = (customer as Stripe.Customer).metadata?.supabase_user_id;

        // Downgrade to free plan
        await supabase
          .from('prj_user_subscriptions')
          .update({
            plan_id: 'free',
            status: 'canceled',
            stripe_subscription_id: null,
            current_period_start: null,
            current_period_end: null,
            cancel_at_period_end: false,
            updated_at: new Date().toISOString(),
          })
          .eq('stripe_subscription_id', subscription.id);

        // ✅ Invalidate subscription cache for this user
        if (userId) {
          updateTag('subscriptions');
          updateTag(`user-${userId}-subscription`);
        }

        console.log(`✅ Subscription canceled, downgraded to free`);
        break;
      }

      case 'invoice.payment_succeeded': {
        const invoice = event.data.object as Stripe.Invoice;

        const customer = await stripe.customers.retrieve(invoice.customer as string);
        const userId = (customer as Stripe.Customer).metadata?.supabase_user_id;

        if (!userId) break;

        // Record payment
        await supabase
          .from('prj_payment_history')
          .insert({
            user_id: userId,
            stripe_invoice_id: invoice.id,
            stripe_payment_intent_id: invoice.payment_intent as string,
            amount: invoice.amount_paid,
            currency: invoice.currency,
            status: 'succeeded',
            description: invoice.description || `Payment for ${invoice.lines.data[0]?.description}`,
          });

        // ✅ Invalidate payment history cache for this user
        updateTag('payment-history');
        updateTag(`user-${userId}-payments`);

        console.log(`✅ Payment recorded for user ${userId}`);
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice;

        const customer = await stripe.customers.retrieve(invoice.customer as string);
        const userId = (customer as Stripe.Customer).metadata?.supabase_user_id;

        if (!userId) break;

        // Record failed payment
        await supabase
          .from('prj_payment_history')
          .insert({
            user_id: userId,
            stripe_invoice_id: invoice.id,
            stripe_payment_intent_id: invoice.payment_intent as string,
            amount: invoice.amount_due,
            currency: invoice.currency,
            status: 'failed',
            description: `Failed payment for ${invoice.lines.data[0]?.description}`,
          });

        // Update subscription status
        if (invoice.subscription) {
          await supabase
            .from('prj_user_subscriptions')
            .update({ status: 'past_due' })
            .eq('stripe_subscription_id', invoice.subscription);
        }

        console.log(`❌ Payment failed for user ${userId}`);
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return NextResponse.json({ received: true });
  } catch (error: any) {
    console.error('Webhook handler error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

EOF
```

---

## Step 11: Configure Stripe Webhook

### 11.1 Test Webhooks Locally (Development)

**Install Stripe CLI:**
```bash
# macOS
brew install stripe/stripe-cli/stripe

# Linux
wget https://github.com/stripe/stripe-cli/releases/download/v1.19.4/stripe_1.19.4_linux_x86_64.tar.gz
tar -xvf stripe_1.19.4_linux_x86_64.tar.gz
sudo mv stripe /usr/local/bin
```

**Login and forward webhooks:**
```bash
# Login to Stripe
stripe login

# Forward webhooks to local server
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```

This will output a webhook signing secret like `whsec_...`. Copy it to your `.env.local`:
```
STRIPE_WEBHOOK_SECRET=whsec_your_local_webhook_secret
```

### 11.2 Production Webhooks

**In Stripe Dashboard:**
1. Go to **Developers → Webhooks**
2. Click **Add endpoint**
3. **Endpoint URL:** `https://your-domain.com/api/webhooks/stripe`
4. **Events to send:**
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Click **Add endpoint**
6. **Copy the Signing secret** (starts with `whsec_`)
7. Add to production environment variables in Vercel

---

## Step 12: Create Pricing Page with Caching

```bash
cat > src/app/pricing/page.tsx << 'EOF'
import { PLAN_DETAILS, SUBSCRIPTION_PLANS, BILLING_ROUTES } from '@/constants';
import { PricingCard } from '@/components/features/billing/PricingCard';
import Link from 'next/link';
import { Suspense } from 'react';

/**
 * Public pricing page - Cached Server Component
 * Shows all available subscription plans
 *
 * Pricing data is cached for 24 hours since it rarely changes
 */
async function PricingContent() {
  'use cache';
  cacheLife('days'); // Pricing rarely changes
  cacheTag('pricing');

  const plans = [
    PLAN_DETAILS[SUBSCRIPTION_PLANS.FREE],
    PLAN_DETAILS[SUBSCRIPTION_PLANS.PRO],
    PLAN_DETAILS[SUBSCRIPTION_PLANS.TEAM],
  ];

  return (
    <>
      {/* Pricing Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
        {plans.map((plan, index) => (
          <PricingCard
            key={plan.name}
            name={plan.name}
            price={plan.price}
            interval={plan.interval}
            features={plan.features}
            priceId={plan.priceId}
            highlighted={index === 1} // Highlight Pro plan
          />
        ))}
      </div>

      {/* FAQ Section */}
      <div className="max-w-3xl mx-auto mt-16">
        <h2 className="text-2xl font-bold text-center mb-8">
          Frequently Asked Questions
        </h2>

        <div className="space-y-6">
          <div>
            <h3 className="font-semibold text-lg mb-2">
              Can I cancel anytime?
            </h3>
            <p className="text-gray-600">
              Yes! You can cancel your subscription at any time. You'll continue to have access until the end of your billing period.
            </p>
          </div>

          <div>
            <h3 className="font-semibold text-lg mb-2">
              What happens to my projects if I downgrade?
            </h3>
            <p className="text-gray-600">
              Your existing projects won't be deleted. However, you won't be able to create new projects until you're within your plan's limit.
            </p>
          </div>

          <div>
            <h3 className="font-semibold text-lg mb-2">
              Do you offer refunds?
            </h3>
            <p className="text-gray-600">
              We offer a 14-day money-back guarantee. If you're not satisfied, contact support for a full refund.
            </p>
          </div>

          <div>
            <h3 className="font-semibold text-lg mb-2">
              Can I change plans later?
            </h3>
            <p className="text-gray-600">
              Absolutely! You can upgrade or downgrade your plan at any time from your billing dashboard.
            </p>
          </div>
        </div>
      </div>
    </>
  );
}

export default function PricingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white py-12 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Simple, Transparent Pricing
          </h1>
          <p className="text-xl text-gray-600">
            Choose the plan that fits your needs. Upgrade or downgrade anytime.
          </p>
        </div>

        {/* Cached Pricing Content with Suspense */}
        <Suspense fallback={
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
            {[1, 2, 3].map((i) => (
              <div key={i} className="border rounded-2xl p-8 animate-pulse">
                <div className="h-8 bg-gray-200 rounded mb-4"></div>
                <div className="h-12 bg-gray-200 rounded mb-6"></div>
                <div className="space-y-4">
                  {[1, 2, 3, 4].map((j) => (
                    <div key={j} className="h-6 bg-gray-200 rounded"></div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        }>
          <PricingContent />
        </Suspense>

        {/* CTA */}
        <div className="text-center mt-16">
          <Link
            href={BILLING_ROUTES.PRICING}
            className="text-blue-600 hover:text-blue-700 font-medium"
          >
            Have questions? Contact our support team →
          </Link>
        </div>
      </div>
    </div>
  );
}

EOF
```

Create PricingCard component:

```bash
mkdir -p src/components/features/billing
cat > src/components/features/billing/PricingCard.tsx << 'EOF'
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createCheckoutSession } from '@/lib/actions/subscriptions';
import { createClient } from '@/lib/supabase/client';
import { ROUTES, BILLING_ROUTES } from '@/constants';

type PricingCardProps = {
  name: string;
  price: number;
  interval: string | null;
  features: string[];
  priceId: string | null;
  highlighted?: boolean;
};

/**
 * Pricing card component for subscription plans
 */
export function PricingCard({
  name,
  price,
  interval,
  features,
  priceId,
  highlighted = false,
}: PricingCardProps) {
  const router = useRouter();
  const supabase = createClient();
  const [loading, setLoading] = useState(false);

  const isFree = price === 0;

  const handleSubscribe = async () => {
    setLoading(true);

    try {
      // Check if user is logged in
      const { data: { user } } = await supabase.auth.getUser();

      if (!user) {
        // Redirect to signup
        router.push(`${ROUTES.SIGNUP}?redirect=${BILLING_ROUTES.PRICING}`);
        return;
      }

      if (isFree) {
        // Free plan - just redirect to dashboard
        router.push(ROUTES.DASHBOARD);
        return;
      }

      if (!priceId) {
        throw new Error('Price ID not found');
      }

      // Create checkout session
      const result = await createCheckoutSession({
        priceId,
        userId: user.id,
        email: user.email!,
        successUrl: `${window.location.origin}${BILLING_ROUTES.CHECKOUT_SUCCESS}`,
        cancelUrl: `${window.location.origin}${BILLING_ROUTES.CHECKOUT_CANCEL}`,
      });

      if (result.success && result.data?.url) {
        // Redirect to Stripe Checkout
        window.location.href = result.data.url;
      } else {
        throw new Error(result.error || 'Failed to create checkout session');
      }
    } catch (error: any) {
      console.error('Subscribe error:', error);
      alert('Failed to start checkout. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className={`relative rounded-2xl border-2 p-8 ${
        highlighted
          ? 'border-blue-500 shadow-xl scale-105'
          : 'border-gray-200 shadow-lg'
      } bg-white`}
    >
      {/* Popular Badge */}
      {highlighted && (
        <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
          <span className="bg-blue-500 text-white px-4 py-1 rounded-full text-sm font-semibold">
            Most Popular
          </span>
        </div>
      )}

      {/* Plan Name */}
      <h3 className="text-2xl font-bold text-gray-900 mb-2">{name}</h3>

      {/* Price */}
      <div className="mb-6">
        <span className="text-5xl font-bold text-gray-900">${price}</span>
        {interval && <span className="text-gray-600 ml-2">/{interval}</span>}
      </div>

      {/* Features */}
      <ul className="space-y-4 mb-8">
        {features.map((feature, index) => (
          <li key={index} className="flex items-start">
            <svg
              className="h-6 w-6 text-green-500 mr-2 flex-shrink-0"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M5 13l4 4L19 7"
              />
            </svg>
            <span className="text-gray-700">{feature}</span>
          </li>
        ))}
      </ul>

      {/* CTA Button */}
      <button
        onClick={handleSubscribe}
        disabled={loading}
        className={`w-full py-3 px-6 rounded-lg font-semibold transition-colors ${
          highlighted
            ? 'bg-blue-600 text-white hover:bg-blue-700'
            : 'bg-gray-900 text-white hover:bg-gray-800'
        } disabled:opacity-50 disabled:cursor-not-allowed`}
      >
        {loading ? 'Loading...' : isFree ? 'Get Started' : `Subscribe to ${name}`}
      </button>
    </div>
  );
}

EOF
```

---

## Step 13: Create Billing Dashboard with Cached Components

Create a complete billing management page with cached subscription and payment data:

```bash
cat > src/app/dashboard/billing/page.tsx << 'INNEREOF'
import { redirect } from 'next/navigation';
import { Suspense } from 'react';
import { createClient } from '@/lib/supabase/server';
import { ROUTES } from '@/constants';

/**
 * Cached subscription overview component
 * Uses short cache (5 minutes) for near-real-time updates
 */
async function SubscriptionOverview({ userId }: { userId: string }) {
  'use cache';
  cacheLife('minutes'); // 5 minutes - subscription changes need quick updates
  cacheTag('subscriptions');
  cacheTag(`user-${userId}-subscription`);

  const { getUserSubscription } = await import('@/lib/actions/subscriptions');
  const { BillingOverview } = await import('@/components/features/billing/BillingOverview');

  const subscriptionResult = await getUserSubscription();
  const subscription = subscriptionResult.success ? subscriptionResult.data : null;

  return <BillingOverview subscription={subscription} />;
}

/**
 * Cached payment history component
 * Uses longer cache (1 hour) since historical data rarely changes
 */
async function PaymentHistorySection({ userId }: { userId: string }) {
  'use cache';
  cacheLife('hours'); // 1 hour - payment history is historical
  cacheTag('payment-history');
  cacheTag(`user-${userId}-payments`);

  const { getPaymentHistory } = await import('@/lib/actions/subscriptions');
  const { PaymentHistoryTable } = await import('@/components/features/billing/PaymentHistoryTable');

  const paymentsResult = await getPaymentHistory();
  const payments = paymentsResult.success ? paymentsResult.data : [];

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-4">Payment History</h2>
      <PaymentHistoryTable payments={payments} />
    </div>
  );
}

/**
 * Billing dashboard - shows subscription status and payment history
 * Uses separate cached components for subscription and payment data
 */
export default async function BillingPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect(ROUTES.LOGIN);

  return (
    <div className="container mx-auto p-6 space-y-8">
      <div>
        <h1 className="text-3xl font-bold">Billing & Subscription</h1>
        <p className="text-gray-600">Manage your subscription and view payment history</p>
      </div>

      {/* Subscription Overview - Cached with 5 min TTL */}
      <Suspense fallback={
        <div className="bg-white border rounded-lg p-6 animate-pulse">
          <div className="h-8 bg-gray-200 rounded mb-4 w-1/3"></div>
          <div className="h-6 bg-gray-200 rounded mb-2 w-1/4"></div>
          <div className="h-4 bg-gray-200 rounded w-1/2"></div>
        </div>
      }>
        <SubscriptionOverview userId={user.id} />
      </Suspense>

      {/* Payment History - Cached with 1 hour TTL */}
      <Suspense fallback={
        <div className="bg-white border rounded-lg p-6 animate-pulse">
          <div className="h-8 bg-gray-200 rounded mb-4 w-1/4"></div>
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-16 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      }>
        <PaymentHistorySection userId={user.id} />
      </Suspense>
    </div>
  );
}

INNEREOF
```

Create BillingOverview component:

```bash
cat > src/components/features/billing/BillingOverview.tsx << 'INNEREOF'
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createCustomerPortalSession } from '@/lib/actions/subscriptions';
import { PLAN_DETAILS, BILLING_ROUTES } from '@/constants';
import type { SubscriptionWithUsage } from '@/types/subscription';
import Link from 'next/link';

type BillingOverviewProps = {
  subscription: SubscriptionWithUsage | null;
};

/**
 * Display subscription overview with upgrade/manage options
 */
export function BillingOverview({ subscription }: BillingOverviewProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  if (!subscription) {
    return (
      <div className="bg-white border rounded-lg p-6">
        <p className="text-gray-600">Loading subscription...</p>
      </div>
    );
  }

  const plan = PLAN_DETAILS[subscription.plan_id as keyof typeof PLAN_DETAILS];
  const isFree = subscription.plan_id === 'free';
  const isUnlimited = subscription.max_projects === -1;

  const handleManageBilling = async () => {
    setLoading(true);

    try {
      const result = await createCustomerPortalSession(
        `${window.location.origin}${BILLING_ROUTES.BILLING}`
      );

      if (result.success && result.data?.url) {
        window.location.href = result.data.url;
      } else {
        throw new Error(result.error || 'Failed to open billing portal');
      }
    } catch (error: any) {
      console.error('Open portal error:', error);
      alert('Failed to open billing portal. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white border rounded-lg p-6 space-y-6">
      {/* Current Plan */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-xl font-semibold">{plan.name} Plan</h3>
            <p className="text-gray-600">
              {isFree ? 'Free forever' : `$${plan.price}/${plan.interval}`}
            </p>
          </div>

          <div>
            {isFree ? (
              <Link
                href={BILLING_ROUTES.PRICING}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                Upgrade Plan
              </Link>
            ) : (
              <button
                onClick={handleManageBilling}
                disabled={loading}
                className="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
              >
                {loading ? 'Loading...' : 'Manage Billing'}
              </button>
            )}
          </div>
        </div>

        {/* Status Badge */}
        <div className="flex items-center gap-2">
          <span
            className={`px-3 py-1 rounded-full text-sm font-medium ${
              subscription.status === 'active'
                ? 'bg-green-100 text-green-800'
                : subscription.status === 'canceled'
                ? 'bg-red-100 text-red-800'
                : 'bg-yellow-100 text-yellow-800'
            }`}
          >
            {subscription.status.charAt(0).toUpperCase() + subscription.status.slice(1)}
          </span>

          {subscription.cancel_at_period_end && (
            <span className="px-3 py-1 bg-orange-100 text-orange-800 rounded-full text-sm">
              Cancels on {new Date(subscription.current_period_end!).toLocaleDateString()}
            </span>
          )}
        </div>
      </div>

      {/* Usage Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-4 border-t">
        {/* Projects */}
        <div>
          <p className="text-sm text-gray-600 mb-1">Projects</p>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-bold">{subscription.project_count}</span>
            <span className="text-gray-600">
              / {isUnlimited ? '∞' : subscription.max_projects}
            </span>
          </div>
          <div className="mt-2 w-full bg-gray-200 rounded-full h-2">
            <div
              className={`h-2 rounded-full ${
                isUnlimited
                  ? 'bg-blue-500'
                  : subscription.project_count >= subscription.max_projects
                  ? 'bg-red-500'
                  : 'bg-blue-500'
              }`}
              style={{
                width: isUnlimited
                  ? '100%'
                  : `${Math.min((subscription.project_count / subscription.max_projects) * 100, 100)}%`,
              }}
            />
          </div>
        </div>

        {/* Team Members */}
        <div>
          <p className="text-sm text-gray-600 mb-1">Team Members per Project</p>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-bold">
              {plan.limits.max_members_per_project === -1
                ? '∞'
                : plan.limits.max_members_per_project}
            </span>
          </div>
        </div>

        {/* Storage */}
        <div>
          <p className="text-sm text-gray-600 mb-1">Storage</p>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-bold">
              {plan.limits.max_storage_mb >= 1024
                ? `${plan.limits.max_storage_mb / 1024} GB`
                : `${plan.limits.max_storage_mb} MB`}
            </span>
          </div>
        </div>
      </div>

      {/* Features List */}
      <div className="pt-4 border-t">
        <p className="text-sm font-medium text-gray-700 mb-3">Plan Features:</p>
        <ul className="grid grid-cols-1 md:grid-cols-2 gap-2">
          {plan.features.map((feature, index) => (
            <li key={index} className="flex items-start text-sm text-gray-600">
              <svg
                className="h-5 w-5 text-green-500 mr-2 flex-shrink-0"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M5 13l4 4L19 7"
                />
              </svg>
              {feature}
            </li>
          ))}
        </ul>
      </div>

      {/* Renewal Info */}
      {!isFree && subscription.current_period_end && (
        <div className="pt-4 border-t text-sm text-gray-600">
          {subscription.cancel_at_period_end ? (
            <p>
              Your subscription will be canceled on{' '}
              <span className="font-medium">
                {new Date(subscription.current_period_end).toLocaleDateString()}
              </span>
              . You'll be downgraded to the Free plan.
            </p>
          ) : (
            <p>
              Your subscription renews on{' '}
              <span className="font-medium">
                {new Date(subscription.current_period_end).toLocaleDateString()}
              </span>{' '}
              for ${plan.price}.
            </p>
          )}
        </div>
      )}
    </div>
  );
}

INNEREOF
```

Create PaymentHistoryTable component:

```bash
cat > src/components/features/billing/PaymentHistoryTable.tsx << 'INNEREOF'
import { formatAmount } from '@/lib/stripe/server';
import type { PaymentHistory } from '@/types/subscription';

type PaymentHistoryTableProps = {
  payments: PaymentHistory[];
};

/**
 * Display payment history in a table
 */
export function PaymentHistoryTable({ payments }: PaymentHistoryTableProps) {
  if (payments.length === 0) {
    return (
      <div className="bg-white border rounded-lg p-8 text-center text-gray-600">
        No payment history yet.
      </div>
    );
  }

  return (
    <div className="bg-white border rounded-lg overflow-hidden">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Date
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Description
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Amount
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Status
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {payments.map((payment) => (
            <tr key={payment.id}>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {new Date(payment.created_at).toLocaleDateString()}
              </td>
              <td className="px-6 py-4 text-sm text-gray-900">
                {payment.description || 'Payment'}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatAmount(payment.amount, payment.currency)}
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span
                  className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                    payment.status === 'succeeded'
                      ? 'bg-green-100 text-green-800'
                      : payment.status === 'failed'
                      ? 'bg-red-100 text-red-800'
                      : 'bg-yellow-100 text-yellow-800'
                  }`}
                >
                  {payment.status.charAt(0).toUpperCase() + payment.status.slice(1)}
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

INNEREOF
```

---

## Step 14: Add Project Limit Check

Update project creation to enforce subscription limits:

```bash
cat >> src/lib/actions/projects.ts << 'INNEREOF'

/**
 * Create project with subscription limit check
 * (UPDATE existing createProject function)
 */
export async function createProject(input: CreateProjectInput) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      return { success: false, error: 'Unauthorized' };
    }

    // ✅ NEW: Check if user can create project based on subscription
    const canCreate = await canCreateProject();

    if (!canCreate.success || !canCreate.data) {
      return {
        success: false,
        error: 'You have reached your project limit. Please upgrade your plan.',
        requiresUpgrade: true, // Flag for UI to show upgrade prompt
      };
    }

    // Existing validation and creation logic...
    const validated = createProjectSchema.parse(input);

    const { data, error } = await supabase
      .from(DB_TABLES.PROJECTS)
      .insert({
        name: validated.name,
        description: validated.description,
        start_date: validated.start_date,
        end_date: validated.end_date,
        status: validated.status,
        owner_id: user.id,
      })
      .select()
      .single();

    if (error) {
      console.error('Create project error:', error);
      return { success: false, error: error.message };
    }

    revalidatePath(ROUTES.DASHBOARD_PROJECTS);

    return { success: true, data };
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      return { success: false, error: error.errors[0].message };
    }
    console.error('Create project error:', error);
    return { success: false, error: error.message };
  }
}

INNEREOF
```

Update project creation page to show upgrade prompt:

```bash
cat > src/components/features/projects/UpgradePrompt.tsx << 'INNEREOF'
'use client';

import Link from 'next/link';
import { BILLING_ROUTES, BILLING_MESSAGES } from '@/constants';

type UpgradePromptProps = {
  message?: string;
};

/**
 * Prompt user to upgrade when limit is reached
 */
export function UpgradePrompt({ message = BILLING_MESSAGES.UPGRADE_REQUIRED }: UpgradePromptProps) {
  return (
    <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-6">
      <div className="flex">
        <div className="flex-shrink-0">
          <svg
            className="h-5 w-5 text-yellow-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
        </div>
        <div className="ml-3 flex-1">
          <p className="text-sm text-yellow-700">{message}</p>
          <div className="mt-2">
            <Link
              href={BILLING_ROUTES.PRICING}
              className="text-sm font-medium text-yellow-700 hover:text-yellow-600"
            >
              View pricing plans →
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

INNEREOF
```

---

## Step 15: Create Checkout Success/Cancel Pages

```bash
mkdir -p src/app/dashboard/billing/success
cat > src/app/dashboard/billing/success/page.tsx << 'INNEREOF'
import Link from 'next/link';
import { ROUTES, BILLING_ROUTES } from '@/constants';

/**
 * Checkout success page
 * Shown after successful Stripe checkout
 */
export default function CheckoutSuccessPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-8 text-center">
        {/* Success Icon */}
        <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-green-100 mb-4">
          <svg
            className="h-10 w-10 text-green-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 13l4 4L19 7"
            />
          </svg>
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Payment Successful!
        </h1>
        <p className="text-gray-600 mb-6">
          Your subscription has been activated. You can now enjoy all the features of your plan.
        </p>

        <div className="space-y-3">
          <Link
            href={ROUTES.DASHBOARD_PROJECTS}
            className="block w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Create Your First Project
          </Link>

          <Link
            href={BILLING_ROUTES.BILLING}
            className="block w-full px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
          >
            View Billing Dashboard
          </Link>
        </div>
      </div>
    </div>
  );
}

INNEREOF
```

Create cancel page:

```bash
mkdir -p src/app/dashboard/billing/cancel
cat > src/app/dashboard/billing/cancel/page.tsx << 'INNEREOF'
import Link from 'next/link';
import { BILLING_ROUTES } from '@/constants';

/**
 * Checkout cancel page
 * Shown when user cancels Stripe checkout
 */
export default function CheckoutCancelPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-8 text-center">
        {/* Cancel Icon */}
        <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-gray-100 mb-4">
          <svg
            className="h-10 w-10 text-gray-600"
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
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Checkout Canceled
        </h1>
        <p className="text-gray-600 mb-6">
          No worries! Your subscription hasn't been changed. Feel free to try again when you're ready.
        </p>

        <div className="space-y-3">
          <Link
            href={BILLING_ROUTES.PRICING}
            className="block w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            View Plans Again
          </Link>

          <Link
            href={BILLING_ROUTES.BILLING}
            className="block w-full px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
          >
            Back to Billing
          </Link>
        </div>
      </div>
    </div>
  );
}

INNEREOF
```

---

## Verification Steps

### 1. Test Free Tier Limits

**Browser:**
1. Sign up for a new account
2. Create Project 1 → Success ✅
3. Create Project 2 → Success ✅
4. Try to create Project 3 → **Expected:** Error message "Upgrade required" ✅
5. **Expected:** Upgrade prompt shown ✅

### 2. Test Stripe Checkout (Test Mode)

**Using Test Cards:**
```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
```

**Steps:**
1. Go to `/pricing`
2. Click "Subscribe to Pro"
3. Fill in:
   - Card: `4242 4242 4242 4242`
   - Expiry: Any future date (e.g., `12/25`)
   - CVC: Any 3 digits (e.g., `123`)
   - Name: Any name
4. Click "Subscribe"
5. **Expected:** Redirected to success page ✅
6. **Expected:** Webhook fires and updates database ✅

### 3. Test Subscription in Database

**Supabase Dashboard → Table Editor:**
```sql
SELECT * FROM prj_user_subscriptions WHERE user_id = 'your-user-id';
```

**Expected fields:**
- `plan_id`: 'pro'
- `status`: 'active'
- `stripe_subscription_id`: 'sub_...'
- `current_period_end`: Future date

### 4. Test Project Creation After Upgrade

**Browser:**
1. After successful payment
2. Go to Dashboard → Projects
3. Create Project 3 → **Expected:** Success ✅
4. Create Projects 4-10 → **Expected:** All succeed ✅
5. Try to create Project 11 → **Expected:** Error (Pro limit is 10) ✅

### 5. Test Customer Portal

**Browser:**
1. Go to `/dashboard/billing`
2. Click "Manage Billing"
3. **Expected:** Redirected to Stripe Customer Portal ✅
4. **Expected:** Can update payment method ✅
5. **Expected:** Can cancel subscription ✅

### 6. Test Webhook Events

**Terminal (with Stripe CLI):**
```bash
stripe trigger checkout.session.completed
```

**Expected:**
- Webhook endpoint receives event ✅
- Database updated with subscription ✅
- Payment recorded in `prj_payment_history` ✅

### 7. Test Subscription Cancellation

**Stripe Customer Portal:**
1. Click "Cancel plan"
2. Confirm cancellation
3. **Expected:** Webhook fires `customer.subscription.deleted` ✅
4. **Expected:** Database updated: `plan_id` = 'free' ✅
5. **Expected:** Can only create 2 projects again ✅

### 8. Verify Cache Behavior

**Test Cache Components:**

**1. Subscription Cache (5 minutes):**
```bash
# Visit billing dashboard
# Note the subscription status
# Upgrade via Stripe
# Wait for webhook to fire (check terminal logs)
# Refresh billing dashboard
# Expected: Status updates immediately (cache invalidated by webhook)
```

**2. Payment History Cache (1 hour):**
```bash
# Visit billing dashboard → Payment History
# Complete a payment
# Wait for webhook
# Refresh billing dashboard
# Expected: New payment appears (cache invalidated by webhook)
```

**3. Cache Tags:**
```bash
# Check browser DevTools → Network tab
# Look for X-Cache headers
# Expected: HIT after first load, MISS after cache invalidation
```

**4. Verify User-Specific Caching:**
```bash
# User A: View billing dashboard
# User B: View billing dashboard (different account)
# Expected: Each user sees their own cached data independently
```

---

## Production Checklist

### Before Going Live

- [ ] **Replace test API keys with live keys**
  - `STRIPE_SECRET_KEY` → Live key (starts with `sk_live_`)
  - `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` → Live key (starts with `pk_live_`)

- [ ] **Activate Stripe account**
  - Complete business verification
  - Add bank account for payouts
  - Set up tax settings

- [ ] **Create live products in Stripe**
  - Create Pro Plan product (live mode)
  - Create Team Plan product (live mode)
  - Copy live Price IDs to environment variables

- [ ] **Configure live webhook**
  - Create webhook endpoint: `https://your-domain.com/api/webhooks/stripe`
  - Select events (checkout.session.completed, etc.)
  - Copy live webhook secret
  - Add to production environment variables

- [ ] **Test with real card** (small amount)
  - Subscribe to lowest tier
  - Verify webhook fires
  - Verify database updates
  - Cancel subscription

- [ ] **Set up monitoring**
  - Monitor webhook failures in Stripe Dashboard
  - Set up alerts for failed payments
  - Track subscription churn rate

- [ ] **Legal compliance**
  - Add Terms of Service
  - Add Privacy Policy
  - Add Refund Policy
  - Comply with local tax laws

---

## Common Issues & Solutions

### Issue 1: Webhook not firing locally

**Cause:** Stripe CLI not running or wrong endpoint

**Solution:**
```bash
# Restart Stripe CLI
stripe listen --forward-to localhost:3000/api/webhooks/stripe

# Copy new webhook secret to .env.local
```

### Issue 2: "No signatures found matching the expected signature"

**Cause:** Wrong webhook secret or raw body not used

**Solution:**
- Verify `STRIPE_WEBHOOK_SECRET` matches Stripe CLI output
- Ensure using `request.text()` (raw body) not `request.json()`

### Issue 3: User upgraded but still sees free limits

**Cause:** Database not updated or webhook failed

**Solution:**
1. Check Stripe Dashboard → Webhooks → Event details
2. Manually trigger webhook: `stripe trigger checkout.session.completed`
3. Check database: `SELECT * FROM prj_user_subscriptions WHERE user_id = '...'`

### Issue 4: Customer portal not working

**Cause:** Customer portal not configured

**Solution:**
1. Stripe Dashboard → Settings → Customer Portal
2. Configure portal settings (enable cancellation, payment method updates)
3. Save settings

### Issue 5: Payment succeeded but project limit not increased

**Cause:** Webhook processed but RPC function not called

**Solution:**
```sql
-- Manually check subscription
SELECT * FROM prj_user_subscriptions WHERE user_id = 'user-id';

-- If plan_id wrong, update:
UPDATE prj_user_subscriptions
SET plan_id = 'pro', status = 'active'
WHERE user_id = 'user-id';
```

---

## What You Learned

✅ **Stripe Integration** - Checkout, subscriptions, customer portal
✅ **Freemium Model** - 2 free projects, upgrade for more
✅ **Webhook Handling** - Process payment events securely with cache invalidation
✅ **Subscription Management** - Create, upgrade, downgrade, cancel
✅ **Usage Enforcement** - Database-level limit checking
✅ **Pricing Page** - Display plans with features (cached for 24 hours)
✅ **Billing Dashboard** - Show subscription status and usage with smart caching
✅ **Payment History** - Track all payments and invoices (cached for 1 hour)
✅ **RLS Integration** - Subscription data security
✅ **Production Deployment** - Live vs test mode setup
✅ **Cache Components** - Optimized billing data caching with Next.js 16
✅ **Cache Invalidation** - Webhook-driven cache updates for real-time data
✅ **User-Specific Caching** - Each user's billing data cached independently
✅ **Cache Lifetimes** - Strategic TTLs based on data volatility

---

## Cost Estimation

**Stripe Fees:**
- **Transactions:** 2.9% + $0.30 per successful charge
- **Subscriptions:** Same as above (recurring)
- **No monthly fee** for Stripe account

**Example Monthly Revenue:**
- 100 Pro users × $10 = $1,000
- 20 Team users × $25 = $500
- **Total:** $1,500/month

**Stripe Fees:**
- $1,500 × 2.9% = $43.50
- 120 transactions × $0.30 = $36
- **Total fees:** ~$80/month (~5.3%)

**Net Revenue:** $1,500 - $80 = $1,420/month

---

## Next Steps

**Extend Your Subscription System:**
1. Add annual billing (discounted)
2. Implement promo codes and discounts
3. Add usage-based billing (per project overage)
4. Send subscription renewal reminders via email
5. Implement trial periods (14-day free trial)
6. Add team billing (one payment for multiple users)
7. Create admin dashboard for subscription analytics
8. Add refund handling
9. Implement dunning (retry failed payments)
10. Add subscription pause feature

**Explore Advanced Topics:**
- Stripe Tax for automatic tax calculation
- Stripe Invoicing for custom invoices
- Metered billing for usage-based pricing
- Multi-currency support
- Partner/referral programs with Stripe

---

## Reference

**Files Created/Updated:**
- `next.config.ts` - Enable Cache Components (UPDATED)
- `supabase/migrations/007_subscriptions.sql` - Subscription tables and RLS
- `src/constants/index.ts` - Subscription constants (EXTENDED)
- `src/types/subscription.ts` - TypeScript types for subscriptions
- `src/lib/stripe/client.ts` - Client-side Stripe.js
- `src/lib/stripe/server.ts` - Server-side Stripe API
- `src/lib/actions/subscriptions.ts` - Subscription Server Actions with cache invalidation (UPDATED)
- `src/app/api/webhooks/stripe/route.ts` - Stripe webhook handler with cache invalidation (UPDATED)
- `src/app/pricing/page.tsx` - Pricing page with Cache Components (UPDATED)
- `src/app/dashboard/billing/page.tsx` - Billing dashboard with Cache Components (UPDATED)
- `src/app/dashboard/billing/success/page.tsx` - Checkout success page
- `src/app/dashboard/billing/cancel/page.tsx` - Checkout cancel page
- `src/components/features/billing/PricingCard.tsx` - Pricing card component
- `src/components/features/billing/BillingOverview.tsx` - Subscription overview
- `src/components/features/billing/PaymentHistoryTable.tsx` - Payment history table
- `src/components/features/projects/UpgradePrompt.tsx` - Upgrade prompt
- `src/lib/actions/projects.ts` - Project creation with limit check (UPDATED)

**Key Concepts:**
- Freemium model
- Subscription lifecycle
- Webhook security with cache invalidation
- Payment processing
- Customer portal
- Usage limits
- Upgrade flows
- **Cache Components** - Next.js 16 caching for billing data
- **Cache Lifetimes** - Strategic TTLs (5min, 1hr, 24hr)
- **User-Specific Caching** - Independent cache per user
- **Webhook-Driven Invalidation** - Real-time cache updates

**Resources:**
- Stripe Docs: https://stripe.com/docs
- Stripe Checkout: https://stripe.com/docs/payments/checkout
- Stripe Subscriptions: https://stripe.com/docs/billing/subscriptions
- Stripe Webhooks: https://stripe.com/docs/webhooks
- Stripe Customer Portal: https://stripe.com/docs/customer-management/portal

---

## Congratulations! 🎉

You've successfully integrated **Stripe payments and subscriptions** into your Next.js application!

Your users can now:
- Start for free with 2 projects
- Upgrade to Pro or Team plans for more features
- Manage their subscriptions
- View payment history
- Cancel or change plans anytime

**Next lesson preview:** You could extend this with email notifications, team billing, or advanced analytics!

**Happy monetizing!** 💰

---

## Security Considerations for Payment Integration

### 🔒 Critical Security Measures

Payment processing requires the highest security standards. Here's how we protect your application and users:

---

## 1. API Key Security

### ✅ Server-Side Only Secret Keys

**CRITICAL:** Never expose your Stripe secret key in client-side code!

```typescript
// ❌ NEVER DO THIS - Secret key exposed to browser
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!); // In client component

// ✅ CORRECT - Secret key only on server
// src/lib/stripe/server.ts (server-side only)
export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2024-11-20.acacia',
});
```

**Environment Variable Rules:**
```bash
# ✅ Safe - Client-side (pk_ prefix is publishable)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# ❌ NEVER prefix with NEXT_PUBLIC - Server-side only
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

**Why:** If secret keys leak, attackers can:
- Create fake subscriptions
- Issue refunds
- Access customer data
- Modify payment amounts

---

## 2. Webhook Signature Verification

### ✅ Always Verify Webhook Signatures

Our webhook handler includes signature verification to prevent spoofed requests:

```typescript
// src/app/api/webhooks/stripe/route.ts

export async function POST(request: NextRequest) {
  const body = await request.text(); // ✅ Get raw body
  const signature = request.headers.get('stripe-signature');

  if (!signature) {
    return NextResponse.json({ error: 'No signature' }, { status: 400 });
  }

  // ✅ Verify signature
  try {
    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (error) {
    // ❌ Invalid signature - reject request
    console.error('Webhook signature verification failed');
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  // ✅ Signature valid - process event
}
```

**Why This Matters:**
- Prevents attackers from sending fake payment success events
- Ensures only Stripe can trigger subscription updates
- Protects against replay attacks

**Common Mistakes to Avoid:**
```typescript
// ❌ DON'T use parsed JSON for signature verification
const body = await request.json(); // Breaks signature!

// ✅ DO use raw body
const body = await request.text();
```

---

## 3. HTTPS Enforcement

### ✅ All Payment Flows Must Use HTTPS

**In Production:**
```typescript
// next.config.ts
export default {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          // ✅ Force HTTPS
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload',
          },
        ],
      },
    ];
  },
};
```

**Stripe Checkout automatically uses HTTPS**, but ensure your redirect URLs do too:

```typescript
// ✅ Always use HTTPS in production
const successUrl = `https://your-domain.com/billing/success`; // Not http://

// ✅ Use environment-aware URLs
const successUrl = `${process.env.NEXT_PUBLIC_APP_URL}/billing/success`;
```

---

## 4. Input Validation & Sanitization

### ✅ Validate All Payment-Related Inputs

Never trust user input, even for non-sensitive fields:

```typescript
// src/lib/validations/subscription.ts
import { z } from 'zod';

export const createCheckoutSchema = z.object({
  priceId: z.string().startsWith('price_'), // ✅ Validate format
  userId: z.string().uuid(), // ✅ Must be valid UUID
  email: z.string().email(), // ✅ Must be valid email
});

// In Server Action
export async function createCheckoutSession(input: any) {
  // ✅ Validate before processing
  const validated = createCheckoutSchema.parse(input);
  
  // ✅ Additional check: user must match authenticated user
  const { data: { user } } = await supabase.auth.getUser();
  if (validated.userId !== user?.id) {
    throw new Error('Unauthorized');
  }
  
  // Now safe to proceed...
}
```

**Prevent Price Manipulation:**
```typescript
// ❌ DON'T let users specify prices
const session = await stripe.checkout.sessions.create({
  line_items: [{ price: userInput.priceId }], // Dangerous!
});

// ✅ DO validate against known price IDs
const ALLOWED_PRICES = [
  process.env.STRIPE_PRO_PRICE_ID,
  process.env.STRIPE_TEAM_PRICE_ID,
];

if (!ALLOWED_PRICES.includes(input.priceId)) {
  throw new Error('Invalid price ID');
}
```

---

## 5. Rate Limiting

### ✅ Protect Webhook Endpoints from Abuse

Add rate limiting to prevent abuse:

```typescript
// src/app/api/webhooks/stripe/route.ts

import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

// Create rate limiter (100 requests per 10 seconds per IP)
const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(100, '10 s'),
  analytics: true,
});

export async function POST(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') ?? 'anonymous';
  
  // ✅ Check rate limit
  const { success } = await ratelimit.limit(ip);
  
  if (!success) {
    return NextResponse.json(
      { error: 'Rate limit exceeded' },
      { status: 429 }
    );
  }
  
  // Continue with webhook processing...
}
```

**Install dependencies:**
```bash
npm install @upstash/ratelimit @upstash/redis
```

---

## 6. Idempotency

### ✅ Prevent Duplicate Payments

Stripe automatically handles idempotency for API calls:

```typescript
// ✅ Use idempotency keys for critical operations
const session = await stripe.checkout.sessions.create(
  {
    // ... session config
  },
  {
    idempotencyKey: `checkout_${userId}_${Date.now()}`,
  }
);
```

**For webhooks, prevent duplicate processing:**

```typescript
export async function POST(request: NextRequest) {
  const event = stripe.webhooks.constructEvent(/* ... */);
  
  // ✅ Check if event already processed
  const { data: existing } = await supabase
    .from('processed_webhook_events')
    .select('id')
    .eq('stripe_event_id', event.id)
    .single();
  
  if (existing) {
    console.log('Event already processed:', event.id);
    return NextResponse.json({ received: true });
  }
  
  // Process event...
  
  // ✅ Mark as processed
  await supabase
    .from('processed_webhook_events')
    .insert({ stripe_event_id: event.id });
}
```

**Create the table:**
```sql
CREATE TABLE processed_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_event_id TEXT UNIQUE NOT NULL,
  processed_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 7. Row Level Security (RLS) for Subscriptions

### ✅ Database-Level Security

Our RLS policies prevent unauthorized access:

```sql
-- ✅ Users can only view their own subscription
CREATE POLICY "Users can view own subscription"
  ON prj_user_subscriptions
  FOR SELECT
  USING (user_id = auth.uid());

-- ✅ Only service role can update (webhooks)
CREATE POLICY "Service role can update subscriptions"
  ON prj_user_subscriptions
  FOR UPDATE
  USING (true); -- Requires service role key
```

**Why This Matters:**
- Users cannot see other users' subscription data
- Users cannot modify their own subscription directly
- Only Stripe webhooks (with service role key) can update subscriptions

---

## 8. Error Handling Without Information Leakage

### ✅ Don't Expose Sensitive Details in Errors

```typescript
// ❌ BAD - Exposes internal details
catch (error: any) {
  return { 
    success: false, 
    error: error.message // Might contain sensitive info
  };
}

// ✅ GOOD - Generic user-facing message, detailed logging
catch (error: any) {
  console.error('Payment error:', {
    userId: user.id,
    error: error.message,
    stack: error.stack,
  });
  
  return {
    success: false,
    error: 'Payment processing failed. Please try again or contact support.',
  };
}
```

**Production Error Handling:**
```typescript
// src/lib/utils/errorHandler.ts

export function handlePaymentError(error: any, userId: string) {
  // ✅ Log detailed error for debugging
  logger.error('Payment error', {
    userId,
    errorMessage: error.message,
    errorCode: error.code,
    timestamp: new Date().toISOString(),
  });
  
  // ✅ Send to monitoring service (e.g., Sentry)
  captureException(error, {
    tags: { feature: 'payments' },
    user: { id: userId },
  });
  
  // ✅ Return generic message to user
  return {
    success: false,
    error: 'We encountered an issue processing your payment. Please try again.',
  };
}
```

---

## 9. CORS Configuration

### ✅ Restrict API Access

```typescript
// src/app/api/webhooks/stripe/route.ts

export async function POST(request: NextRequest) {
  // ✅ Verify request is from Stripe
  const origin = request.headers.get('origin');
  
  // Only allow Stripe webhook servers
  if (origin && !origin.includes('stripe.com')) {
    return NextResponse.json(
      { error: 'Forbidden' },
      { status: 403 }
    );
  }
  
  // Continue processing...
}
```

---

## 10. Audit Logging

### ✅ Track All Subscription Changes

Log all payment-related actions for compliance and debugging:

```typescript
// src/lib/actions/auditLog.ts

export async function logSubscriptionEvent(
  userId: string,
  event: string,
  metadata: Record<string, any>
) {
  await supabase.from('audit_logs').insert({
    user_id: userId,
    event_type: event,
    metadata,
    ip_address: request.headers.get('x-forwarded-for'),
    user_agent: request.headers.get('user-agent'),
  });
}

// Usage in webhook
case 'checkout.session.completed':
  await logSubscriptionEvent(userId, 'subscription_created', {
    plan: 'pro',
    amount: 1000,
    stripe_subscription_id: subscription.id,
  });
```

**Create audit log table:**
```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  event_type TEXT NOT NULL,
  metadata JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
```

---

## 11. PCI Compliance

### ✅ We Never Handle Card Data

**Important:** By using Stripe Checkout, we never touch card data:

- ✅ **Card data goes directly to Stripe** (not our servers)
- ✅ **Stripe is PCI DSS Level 1 compliant**
- ✅ **We only store Stripe customer IDs** (safe to store)
- ✅ **No SSL certificates required for card handling**

**What We Store (Safe):**
```typescript
{
  stripe_customer_id: 'cus_...',     // ✅ Safe - just an ID
  stripe_subscription_id: 'sub_...', // ✅ Safe - just an ID
  plan_id: 'pro',                    // ✅ Safe - plan name
}
```

**What We NEVER Store:**
```typescript
{
  card_number: '4242...',      // ❌ NEVER store this
  cvv: '123',                  // ❌ NEVER store this
  expiry: '12/25',             // ❌ NEVER store this
}
```

---

## 12. GDPR & Data Privacy

### ✅ User Data Protection

**Data Minimization:**
```typescript
// ✅ Only store what's needed
type UserSubscription = {
  user_id: string;
  plan_id: string;
  status: string;
  // NO: credit_card_last4, billing_address, etc.
};
```

**Data Deletion (Right to be Forgotten):**
```typescript
export async function deleteUserData(userId: string) {
  // ✅ Cancel Stripe subscription
  const { data: subscription } = await supabase
    .from('prj_user_subscriptions')
    .select('stripe_subscription_id')
    .eq('user_id', userId)
    .single();
  
  if (subscription?.stripe_subscription_id) {
    await stripe.subscriptions.cancel(subscription.stripe_subscription_id);
  }
  
  // ✅ Delete from Stripe
  if (subscription?.stripe_customer_id) {
    await stripe.customers.del(subscription.stripe_customer_id);
  }
  
  // ✅ Delete from database (cascades to payment history)
  await supabase
    .from('prj_user_subscriptions')
    .delete()
    .eq('user_id', userId);
}
```

---

## 13. Test vs Production Isolation

### ✅ Keep Environments Separate

**Never mix test and production keys:**

```bash
# Development (.env.local)
STRIPE_SECRET_KEY=sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_test_...

# Production (Vercel environment variables)
STRIPE_SECRET_KEY=sk_live_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_live_...
```

**Runtime Check:**
```typescript
// ✅ Validate environment
if (process.env.NODE_ENV === 'production') {
  if (process.env.STRIPE_SECRET_KEY?.startsWith('sk_test_')) {
    throw new Error('Using test keys in production!');
  }
}
```

---

## 14. Fraud Prevention

### ✅ Monitor for Suspicious Activity

**Stripe Radar** (built-in fraud detection):
- Enabled automatically on all Stripe accounts
- Blocks suspicious payments
- No additional configuration needed

**Additional Checks:**
```typescript
// Server Action
export async function createCheckoutSession(input: any) {
  const { data: { user } } = await supabase.auth.getUser();
  
  // ✅ Check account age (prevent new account fraud)
  const accountAge = Date.now() - new Date(user.created_at).getTime();
  const ONE_HOUR = 60 * 60 * 1000;
  
  if (accountAge < ONE_HOUR) {
    // New account - add extra verification
    await logSuspiciousActivity(user.id, 'new_account_payment');
  }
  
  // ✅ Check for multiple failed payments
  const { data: failedPayments } = await supabase
    .from('prj_payment_history')
    .select('id')
    .eq('user_id', user.id)
    .eq('status', 'failed')
    .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());
  
  if (failedPayments && failedPayments.length > 3) {
    // Too many failed attempts in 24h
    throw new Error('Please contact support');
  }
}
```

---

## 15. Secure Webhook Endpoint

### ✅ Production Webhook Security Checklist

- [x] **HTTPS only** - Stripe won't send to HTTP
- [x] **Signature verification** - Validates sender
- [x] **Rate limiting** - Prevents DoS attacks
- [x] **Idempotency** - Prevents duplicate processing
- [x] **Error handling** - Doesn't leak info
- [x] **Audit logging** - Tracks all events

**Complete Secure Webhook:**
```typescript
// src/app/api/webhooks/stripe/route.ts

export async function POST(request: NextRequest) {
  // 1. Rate limit
  const { success } = await ratelimit.limit(
    request.headers.get('x-forwarded-for') ?? 'anonymous'
  );
  if (!success) {
    return NextResponse.json({ error: 'Rate limit' }, { status: 429 });
  }

  // 2. Get raw body
  const body = await request.text();
  const signature = request.headers.get('stripe-signature');

  // 3. Verify signature
  let event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature!,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (error) {
    await logSecurityEvent('webhook_signature_failed', { error });
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  // 4. Check idempotency
  const { data: processed } = await supabase
    .from('processed_webhook_events')
    .select('id')
    .eq('stripe_event_id', event.id)
    .single();

  if (processed) {
    return NextResponse.json({ received: true });
  }

  // 5. Process event
  try {
    await processWebhookEvent(event);
    
    // 6. Mark as processed
    await supabase
      .from('processed_webhook_events')
      .insert({ stripe_event_id: event.id });
    
    // 7. Audit log
    await logAuditEvent('webhook_processed', { event_type: event.type });
    
    return NextResponse.json({ received: true });
  } catch (error) {
    // 8. Error handling (don't expose details)
    console.error('Webhook processing error:', error);
    await captureException(error);
    return NextResponse.json(
      { error: 'Processing failed' },
      { status: 500 }
    );
  }
}
```

---

## Security Checklist

Before going to production, verify:

### API Security
- [ ] Secret keys are server-side only (never in client code)
- [ ] Environment variables properly configured
- [ ] HTTPS enforced on all payment endpoints
- [ ] Webhook signature verification implemented
- [ ] Rate limiting enabled on API routes

### Data Security
- [ ] RLS policies enabled on all subscription tables
- [ ] Input validation on all payment-related endpoints
- [ ] No sensitive data logged to console in production
- [ ] Audit logging for all subscription changes
- [ ] GDPR-compliant data deletion implemented

### Payment Security
- [ ] Never storing card numbers or CVV
- [ ] Using Stripe Checkout (PCI compliant)
- [ ] Idempotency keys for critical operations
- [ ] Fraud monitoring enabled (Stripe Radar)
- [ ] Test vs production keys isolated

### Compliance
- [ ] Privacy policy updated with payment processing
- [ ] Terms of service include subscription terms
- [ ] Refund policy clearly stated
- [ ] Cookie consent for Stripe (if in EU)
- [ ] VAT/sales tax handling configured

### Monitoring
- [ ] Error tracking configured (Sentry, etc.)
- [ ] Webhook failure alerts set up
- [ ] Failed payment notifications
- [ ] Suspicious activity monitoring
- [ ] Regular security audits scheduled

---

## Additional Security Resources

**Stripe Security Best Practices:**
- https://stripe.com/docs/security/guide

**Webhook Security:**
- https://stripe.com/docs/webhooks/best-practices

**PCI Compliance:**
- https://stripe.com/docs/security/pci

**OWASP Payment Security:**
- https://cheatsheetseries.owasp.org/cheatsheets/Payment_Security_Cheat_Sheet.html

---

## Next Section

With security measures in place, proceed to **Production Checklist** (already covered above) and **Verification Steps** to test your secure payment integration.

Remember: **Security is not a one-time setup**. Regularly review Stripe's security updates and audit your implementation.

