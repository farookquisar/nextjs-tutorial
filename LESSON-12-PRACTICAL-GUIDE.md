# Lesson 12: Monitoring, Observability & Health Checks

**Tutorial:** Next.js 16 + React 19.2 + Supabase - Complete Learning Path
**Focus:** Comprehensive system monitoring and health checks
**Prerequisites:** Lessons 1-11 completed

---

## What You'll Build

In this lesson, you'll implement a **complete monitoring and observability system** to ensure your application runs smoothly:

- ✅ **Health Check Endpoints** - Monitor each system component
- ✅ **Error Tracking** - Capture and track all errors with Sentry
- ✅ **Structured Logging** - Comprehensive logging system
- ✅ **Custom Metrics** - Track business and technical metrics
- ✅ **Uptime Monitoring** - External monitoring with alerts
- ✅ **Database Health** - Monitor connections and query performance
- ✅ **Payment Monitoring** - Track Stripe webhook reliability
- ✅ **Authentication Monitoring** - Track login failures and patterns
- ✅ **Performance Monitoring** - Page load times, API latency
- ✅ **Alerting System** - Real-time notifications for issues
- ✅ **Dashboards** - Visualize system health

### Monitoring Coverage

**By Function:**
- 🔐 **Authentication** - Login success/failure rates, session issues
- 📊 **Projects** - CRUD operations, errors, performance
- ✅ **Tasks** - Creation rates, completion rates, errors
- 👥 **Members** - Invitation success/failure, permission errors
- 💰 **Payments** - Subscription events, webhook failures, revenue tracking
- 📁 **Storage** - Upload success/failure, storage usage
- 🔍 **Search** - Query performance, popular searches
- ⚡ **Real-time** - WebSocket connection health, event delivery

### Technologies Used

- **Sentry** - Error tracking and performance monitoring
- **Vercel Analytics** - Real-time analytics and Web Vitals
- **Custom Health Endpoints** - Application-specific health checks
- **Structured Logging** - Winston/Pino for production logging
- **OpenTelemetry** - Distributed tracing (optional)
- **Uptime Monitoring** - External health checks (Better Uptime, Pingdom)
- **Custom Dashboards** - Visualize metrics and health status

---

## Architecture Overview

### Monitoring Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Application                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Auth │ Projects │ Tasks │ Payments │ Storage         │  │
│  │    ↓       ↓        ↓         ↓          ↓            │  │
│  │  [Instrumentation Layer]                              │  │
│  │    • Error tracking                                   │  │
│  │    • Logging                                          │  │
│  │    • Metrics collection                               │  │
│  │    • Health checks                                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├──────────────────┐
                  │                  │
         ┌────────▼────────┐  ┌─────▼──────┐
         │     Sentry      │  │  Vercel    │
         │  Error Tracking │  │ Analytics  │
         └────────┬────────┘  └─────┬──────┘
                  │                  │
         ┌────────▼──────────────────▼──────┐
         │      Monitoring Dashboard        │
         │  • Real-time metrics              │
         │  • Error rates                    │
         │  • Performance data               │
         │  • Custom business metrics        │
         └───────────────────────────────────┘
                  │
         ┌────────▼────────┐
         │  Alert System   │
         │  • Email alerts │
         │  • Slack alerts │
         │  • PagerDuty    │
         └─────────────────┘
```

---

## Step 1: Configure Next.js 16 Cache Components

### 1.1 Update next.config.js

Add experimental Cache Components configuration to enable caching for monitoring dashboards:

```bash
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Enable Cache Components for monitoring dashboards
    cacheComponents: true,

    // Cache lifecycle defaults
    cacheLife: {
      // Very short cache for monitoring data (30-60 seconds)
      seconds: {
        stale: 30,   // Consider stale after 30 seconds
        revalidate: 60, // Revalidate every 60 seconds
        expire: 120, // Expire after 2 minutes
      },

      // Default for other data
      default: {
        stale: 900,    // 15 minutes
        revalidate: 3600, // 1 hour
        expire: 86400, // 1 day
      },
    },
  },

  // Existing Next.js configuration...
};

module.exports = nextConfig;
EOF
```

**Why Cache Components for Monitoring?**

Monitoring dashboards often display expensive aggregation queries that are:
- ✅ **Read-heavy** - Metrics are queried frequently by dashboards
- ✅ **Near-real-time** - Need fresh data but don't require instant updates
- ✅ **Cacheable** - Same data for all admins viewing the dashboard
- ✅ **Performance-critical** - Aggregations can be slow without caching

**Cache Strategy:**
- Use `cacheLife('seconds')` for **30-60 second** cache duration
- Balance between real-time visibility and performance
- Invalidate cache when new metrics are recorded
- Cache expensive aggregation queries, not individual metric writes

---

## Step 2: Install Monitoring Dependencies

```bash
# Core monitoring packages
npm install @sentry/nextjs
npm install winston winston-daily-rotate-file
npm install prom-client  # For metrics

# Development dependencies
npm install -D @types/winston
```

---

## Step 3: Configure Sentry Error Tracking

### 3.1 Setup Sentry Account

1. Go to https://sentry.io and create account
2. Create a new project → Select "Next.js"
3. Copy your DSN (Data Source Name)

### 3.2 Initialize Sentry

```bash
npx @sentry/wizard@latest -i nextjs
```

This creates:
- `sentry.client.config.ts`
- `sentry.server.config.ts`
- `sentry.edge.config.ts`

### 3.3 Configure Sentry with Context

```bash
cat > sentry.server.config.ts << 'EOF'
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.SENTRY_DSN,

  // Set environment
  environment: process.env.NODE_ENV,

  // Performance monitoring
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

  // Error sampling
  sampleRate: 1.0,

  // Release tracking
  release: process.env.VERCEL_GIT_COMMIT_SHA,

  // Enable profiling
  profilesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

  // Ignore common errors
  ignoreErrors: [
    'ResizeObserver loop limit exceeded',
    'Non-Error promise rejection captured',
  ],

  // Configure integrations
  integrations: [
    new Sentry.BrowserTracing({
      tracePropagationTargets: [
        'localhost',
        /^https:\/\/yourapp\.com/,
      ],
    }),
  ],

  // Before send hook - add context
  beforeSend(event, hint) {
    // Add custom context
    if (event.user) {
      Sentry.setContext('subscription', {
        plan: event.user.subscription_plan,
        status: event.user.subscription_status,
      });
    }

    return event;
  },
});

EOF
```

Update environment variables:

```bash
cat >> .env.local << 'EOF'

# ============================================================
# MONITORING (Lesson 12)
# ============================================================

# Sentry
SENTRY_DSN=your_sentry_dsn_here
SENTRY_AUTH_TOKEN=your_sentry_auth_token_here
SENTRY_ORG=your_org_name
SENTRY_PROJECT=your_project_name

# Monitoring
NEXT_PUBLIC_ENABLE_MONITORING=true
LOG_LEVEL=info

EOF
```

---

## Step 4: Create Structured Logging System

```bash
mkdir -p src/lib/monitoring
cat > src/lib/monitoring/logger.ts << 'EOF'
import winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';

const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const IS_PRODUCTION = process.env.NODE_ENV === 'production';

// Custom log format
const customFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.metadata(),
  winston.format.json()
);

// Console format for development
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...metadata }) => {
    let msg = `${timestamp} [${level}]: ${message}`;

    if (Object.keys(metadata).length > 0) {
      msg += ` ${JSON.stringify(metadata)}`;
    }

    return msg;
  })
);

// Create logger instance
export const logger = winston.createLogger({
  level: LOG_LEVEL,
  format: customFormat,
  defaultMeta: {
    service: 'nextjs-app',
    environment: process.env.NODE_ENV,
  },
  transports: [
    // Console transport
    new winston.transports.Console({
      format: IS_PRODUCTION ? customFormat : consoleFormat,
    }),

    // File transports (production only)
    ...(IS_PRODUCTION
      ? [
          // Error logs
          new DailyRotateFile({
            filename: 'logs/error-%DATE%.log',
            datePattern: 'YYYY-MM-DD',
            level: 'error',
            maxSize: '20m',
            maxFiles: '14d',
          }),

          // Combined logs
          new DailyRotateFile({
            filename: 'logs/combined-%DATE%.log',
            datePattern: 'YYYY-MM-DD',
            maxSize: '20m',
            maxFiles: '7d',
          }),
        ]
      : []),
  ],
});

// Helper methods for specific log types
export const loggers = {
  auth: (action: string, details: any) => {
    logger.info('AUTH', { action, ...details });
  },

  payment: (action: string, details: any) => {
    logger.info('PAYMENT', { action, ...details });
  },

  project: (action: string, details: any) => {
    logger.info('PROJECT', { action, ...details });
  },

  task: (action: string, details: any) => {
    logger.info('TASK', { action, ...details });
  },

  search: (action: string, details: any) => {
    logger.info('SEARCH', { action, ...details });
  },

  storage: (action: string, details: any) => {
    logger.info('STORAGE', { action, ...details });
  },

  error: (error: Error, context?: any) => {
    logger.error('ERROR', {
      message: error.message,
      stack: error.stack,
      ...context,
    });
  },
};

EOF
```

---

## Step 5: Create Health Check System

### 5.1 Base Health Check Interface

```bash
cat > src/lib/monitoring/healthCheck.ts << 'EOF'
export type HealthStatus = 'healthy' | 'degraded' | 'unhealthy';

export type HealthCheckResult = {
  status: HealthStatus;
  timestamp: string;
  checks: {
    [key: string]: {
      status: HealthStatus;
      message?: string;
      responseTime?: number;
      details?: any;
    };
  };
};

export type HealthChecker = {
  name: string;
  check: () => Promise<{
    status: HealthStatus;
    message?: string;
    responseTime?: number;
    details?: any;
  }>;
};

/**
 * Run all health checks and aggregate results
 */
export async function runHealthChecks(
  checkers: HealthChecker[]
): Promise<HealthCheckResult> {
  const checks: HealthCheckResult['checks'] = {};
  let overallStatus: HealthStatus = 'healthy';

  const results = await Promise.allSettled(
    checkers.map(async (checker) => {
      const startTime = Date.now();

      try {
        const result = await checker.check();
        const responseTime = Date.now() - startTime;

        checks[checker.name] = {
          ...result,
          responseTime,
        };

        // Update overall status
        if (result.status === 'unhealthy') {
          overallStatus = 'unhealthy';
        } else if (result.status === 'degraded' && overallStatus !== 'unhealthy') {
          overallStatus = 'degraded';
        }
      } catch (error: any) {
        checks[checker.name] = {
          status: 'unhealthy',
          message: error.message,
          responseTime: Date.now() - startTime,
        };

        overallStatus = 'unhealthy';
      }
    })
  );

  return {
    status: overallStatus,
    timestamp: new Date().toISOString(),
    checks,
  };
}

EOF
```

### 5.2 Database Health Check

```bash
cat > src/lib/monitoring/checks/database.ts << 'EOF'
import { createClient } from '@/lib/supabase/server';
import type { HealthChecker } from '../healthCheck';

export const databaseHealthCheck: HealthChecker = {
  name: 'database',
  check: async () => {
    try {
      const supabase = await createClient();

      // Test simple query
      const startTime = Date.now();
      const { error, count } = await supabase
        .from('prj_projects')
        .select('id', { count: 'exact', head: true });

      const queryTime = Date.now() - startTime;

      if (error) {
        return {
          status: 'unhealthy',
          message: `Database query failed: ${error.message}`,
          responseTime: queryTime,
        };
      }

      // Check query performance
      if (queryTime > 1000) {
        return {
          status: 'degraded',
          message: 'Database response time is slow',
          responseTime: queryTime,
          details: { queryTime, threshold: 1000 },
        };
      }

      return {
        status: 'healthy',
        message: 'Database is responsive',
        responseTime: queryTime,
        details: { projectCount: count },
      };
    } catch (error: any) {
      return {
        status: 'unhealthy',
        message: `Database connection failed: ${error.message}`,
      };
    }
  },
};

EOF
```

### 5.3 Authentication Health Check

```bash
cat > src/lib/monitoring/checks/auth.ts << 'EOF'
import { createClient } from '@/lib/supabase/server';
import type { HealthChecker } from '../healthCheck';

export const authHealthCheck: HealthChecker = {
  name: 'authentication',
  check: async () => {
    try {
      const supabase = await createClient();

      // Test auth service by checking session
      const startTime = Date.now();
      const { error } = await supabase.auth.getSession();
      const responseTime = Date.now() - startTime;

      if (error) {
        return {
          status: 'unhealthy',
          message: `Auth service error: ${error.message}`,
          responseTime,
        };
      }

      // Check response time
      if (responseTime > 500) {
        return {
          status: 'degraded',
          message: 'Auth service is slow',
          responseTime,
        };
      }

      return {
        status: 'healthy',
        message: 'Authentication service is operational',
        responseTime,
      };
    } catch (error: any) {
      return {
        status: 'unhealthy',
        message: `Auth check failed: ${error.message}`,
      };
    }
  },
};

EOF
```

### 5.4 Stripe Payment Health Check

```bash
cat > src/lib/monitoring/checks/payments.ts << 'EOF'
import { stripe } from '@/lib/stripe/server';
import type { HealthChecker } from '../healthCheck';

export const paymentsHealthCheck: HealthChecker = {
  name: 'payments',
  check: async () => {
    try {
      // Test Stripe API connection
      const startTime = Date.now();
      const balance = await stripe.balance.retrieve();
      const responseTime = Date.now() - startTime;

      if (responseTime > 2000) {
        return {
          status: 'degraded',
          message: 'Stripe API is slow',
          responseTime,
        };
      }

      return {
        status: 'healthy',
        message: 'Payment service is operational',
        responseTime,
        details: {
          available: balance.available[0]?.amount || 0,
          pending: balance.pending[0]?.amount || 0,
          currency: balance.available[0]?.currency || 'usd',
        },
      };
    } catch (error: any) {
      return {
        status: 'unhealthy',
        message: `Stripe API error: ${error.message}`,
      };
    }
  },
};

EOF
```

### 5.5 Storage Health Check

```bash
cat > src/lib/monitoring/checks/storage.ts << 'EOF'
import { createClient } from '@/lib/supabase/server';
import { STORAGE_BUCKETS } from '@/constants';
import type { HealthChecker } from '../healthCheck';

export const storageHealthCheck: HealthChecker = {
  name: 'storage',
  check: async () => {
    try {
      const supabase = await createClient();

      // Test storage by listing buckets
      const startTime = Date.now();
      const { data, error } = await supabase.storage.listBuckets();
      const responseTime = Date.now() - startTime;

      if (error) {
        return {
          status: 'unhealthy',
          message: `Storage service error: ${error.message}`,
          responseTime,
        };
      }

      // Check if required buckets exist
      const requiredBuckets = [
        STORAGE_BUCKETS.PROJECT_ATTACHMENTS,
        STORAGE_BUCKETS.TASK_ATTACHMENTS,
      ];

      const existingBuckets = data?.map((b) => b.name) || [];
      const missingBuckets = requiredBuckets.filter(
        (b) => !existingBuckets.includes(b)
      );

      if (missingBuckets.length > 0) {
        return {
          status: 'degraded',
          message: 'Some storage buckets are missing',
          responseTime,
          details: { missingBuckets },
        };
      }

      return {
        status: 'healthy',
        message: 'Storage service is operational',
        responseTime,
        details: { bucketCount: existingBuckets.length },
      };
    } catch (error: any) {
      return {
        status: 'unhealthy',
        message: `Storage check failed: ${error.message}`,
      };
    }
  },
};

EOF
```

### 5.6 Real-time Health Check

```bash
cat > src/lib/monitoring/checks/realtime.ts << 'EOF'
import { createClient } from '@/lib/supabase/server';
import type { HealthChecker } from '../healthCheck';

export const realtimeHealthCheck: HealthChecker = {
  name: 'realtime',
  check: async () => {
    try {
      const supabase = await createClient();

      // Check realtime configuration
      const startTime = Date.now();

      // Test by attempting to create a channel
      const channel = supabase.channel('health-check-channel');

      return new Promise((resolve) => {
        const timeout = setTimeout(() => {
          supabase.removeChannel(channel);
          resolve({
            status: 'degraded',
            message: 'Realtime connection timeout',
            responseTime: Date.now() - startTime,
          });
        }, 5000);

        channel.subscribe((status) => {
          clearTimeout(timeout);
          supabase.removeChannel(channel);

          const responseTime = Date.now() - startTime;

          if (status === 'SUBSCRIBED') {
            resolve({
              status: 'healthy',
              message: 'Realtime service is operational',
              responseTime,
            });
          } else {
            resolve({
              status: 'unhealthy',
              message: `Realtime subscription failed: ${status}`,
              responseTime,
            });
          }
        });
      });
    } catch (error: any) {
      return {
        status: 'unhealthy',
        message: `Realtime check failed: ${error.message}`,
      };
    }
  },
};

EOF
```

---

## Step 6: Create Health Check API Endpoint with Caching

### 6.1 Create Cached Health Status Component

First, create a Server Component that caches health check results:

```bash
mkdir -p src/components/features/monitoring
cat > src/components/features/monitoring/HealthStatus.tsx << 'EOF'
import { runHealthChecks } from '@/lib/monitoring/healthCheck';
import { databaseHealthCheck } from '@/lib/monitoring/checks/database';
import { authHealthCheck } from '@/lib/monitoring/checks/auth';
import { paymentsHealthCheck } from '@/lib/monitoring/checks/payments';
import { storageHealthCheck } from '@/lib/monitoring/checks/storage';
import { realtimeHealthCheck } from '@/lib/monitoring/checks/realtime';
import type { HealthCheckResult } from '@/lib/monitoring/healthCheck';

/**
 * Cached Health Status Component
 *
 * This Server Component caches health check results for 30-60 seconds
 * to avoid overloading services with constant health checks while still
 * providing near-real-time status.
 */
async function HealthStatus() {
  'use cache'
  cacheLife('seconds') // Cache for 30-60 seconds (configured in next.config.js)
  cacheTag('health-checks')
  cacheTag('monitoring')

  const healthResult = await runHealthChecks([
    databaseHealthCheck,
    authHealthCheck,
    paymentsHealthCheck,
    storageHealthCheck,
    realtimeHealthCheck,
  ]);

  return healthResult;
}

export default HealthStatus;

EOF
```

**Why Cache Health Checks?**

- ✅ **Prevents overload** - Avoids hammering services with constant health checks
- ✅ **Near-real-time** - 30-60 second cache provides fresh data without excessive load
- ✅ **Consistent view** - All users see the same health status in the same time window
- ✅ **Performance** - Health checks can be slow (database queries, API calls)

**Important:** Health checks should NOT cache for too long (>60 seconds) because you want to detect issues quickly.

### 6.2 Create Health Check API Route

```bash
cat > src/app/api/health/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import { unstable_cacheTag as cacheTag, unstable_cacheLife as cacheLife } from 'next/cache';
import { runHealthChecks } from '@/lib/monitoring/healthCheck';
import { databaseHealthCheck } from '@/lib/monitoring/checks/database';
import { authHealthCheck } from '@/lib/monitoring/checks/auth';
import { paymentsHealthCheck } from '@/lib/monitoring/checks/payments';
import { storageHealthCheck } from '@/lib/monitoring/checks/storage';
import { realtimeHealthCheck } from '@/lib/monitoring/checks/realtime';

/**
 * Health check endpoint with caching
 * GET /api/health
 * GET /api/health?detailed=true
 *
 * Caches results for 30-60 seconds to prevent excessive health checks
 */
async function getHealthStatus() {
  'use cache'
  cacheLife('seconds') // Very short cache (30-60s) for near-real-time status
  cacheTag('health-checks')

  return await runHealthChecks([
    databaseHealthCheck,
    authHealthCheck,
    paymentsHealthCheck,
    storageHealthCheck,
    realtimeHealthCheck,
  ]);
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const detailed = url.searchParams.get('detailed') === 'true';

  try {
    // Get cached health status
    const healthResult = await getHealthStatus();

    // Determine HTTP status code
    const statusCode =
      healthResult.status === 'healthy'
        ? 200
        : healthResult.status === 'degraded'
        ? 200 // Still return 200 for degraded
        : 503; // Service unavailable for unhealthy

    // Return detailed or simple response
    if (detailed) {
      return NextResponse.json(healthResult, { status: statusCode });
    }

    // Simple response
    return NextResponse.json(
      {
        status: healthResult.status,
        timestamp: healthResult.timestamp,
      },
      { status: statusCode }
    );
  } catch (error: any) {
    return NextResponse.json(
      {
        status: 'unhealthy',
        message: error.message,
        timestamp: new Date().toISOString(),
      },
      { status: 503 }
    );
  }
}

EOF
```

---

## Step 7: Create Metrics Collection System with Cache Invalidation

```bash
cat > src/lib/monitoring/metrics.ts << 'EOF'
import { createClient } from '@/lib/supabase/server';
import { updateTag } from 'next/cache';
import { logger } from './logger';

export type MetricType =
  | 'auth.login'
  | 'auth.signup'
  | 'auth.logout'
  | 'auth.failure'
  | 'project.create'
  | 'project.update'
  | 'project.delete'
  | 'task.create'
  | 'task.update'
  | 'task.complete'
  | 'payment.success'
  | 'payment.failure'
  | 'storage.upload'
  | 'storage.delete'
  | 'search.query';

export type MetricData = {
  type: MetricType;
  value: number;
  userId?: string;
  metadata?: Record<string, any>;
};

/**
 * Record a metric event and invalidate related caches
 *
 * This function:
 * 1. Stores the metric in the database
 * 2. Logs the metric for immediate visibility
 * 3. Invalidates cached dashboard data so new metrics show up
 */
export async function recordMetric(data: MetricData) {
  try {
    const supabase = await createClient();

    // Store in database
    await supabase.from('metrics').insert({
      metric_type: data.type,
      metric_value: data.value,
      user_id: data.userId,
      metadata: data.metadata,
      created_at: new Date().toISOString(),
    });

    // Also log for immediate visibility
    logger.info('METRIC', {
      type: data.type,
      value: data.value,
      userId: data.userId,
    });

    // ✅ Invalidate metrics cache to show fresh data
    // This ensures dashboards show the latest metrics
    updateTag('metrics')
    updateTag('metrics-dashboard')
    updateTag('monitoring')

    // Invalidate feature-specific caches
    const [feature] = data.type.split('.')
    if (feature) {
      updateTag(`metrics-${feature}`)
    }
  } catch (error) {
    // Don't let metrics fail the main operation
    logger.error('Failed to record metric', { error, data });
  }
}

/**
 * Get metrics for a time period (cached)
 *
 * This function caches results for 30-60 seconds to avoid
 * expensive repeated queries for the same metrics.
 */
export async function getMetrics(
  type: MetricType,
  startDate: Date,
  endDate: Date
) {
  'use cache'
  cacheLife('seconds') // Cache for 30-60 seconds
  cacheTag('metrics')
  cacheTag(`metrics-${type.split('.')[0]}`) // Feature-specific tag

  try {
    const supabase = await createClient();

    const { data, error } = await supabase
      .from('metrics')
      .select('*')
      .eq('metric_type', type)
      .gte('created_at', startDate.toISOString())
      .lte('created_at', endDate.toISOString())
      .order('created_at', { ascending: false });

    if (error) throw error;

    return data;
  } catch (error) {
    logger.error('Failed to get metrics', { error, type });
    return [];
  }
}

/**
 * Get aggregated metrics (cached)
 *
 * Aggregation queries are expensive, so we cache them for 30-60 seconds.
 * Cache is automatically invalidated when new metrics are recorded.
 */
export async function getMetricsAggregate(
  type: MetricType,
  startDate: Date,
  endDate: Date
) {
  'use cache'
  cacheLife('seconds') // Cache for 30-60 seconds
  cacheTag('metrics')
  cacheTag('metrics-dashboard')
  cacheTag(`metrics-${type.split('.')[0]}`) // Feature-specific tag

  try {
    const supabase = await createClient();

    const { data, error } = await supabase.rpc('get_metrics_aggregate', {
      p_metric_type: type,
      p_start_date: startDate.toISOString(),
      p_end_date: endDate.toISOString(),
    });

    if (error) throw error;

    return data;
  } catch (error) {
    logger.error('Failed to get metrics aggregate', { error, type });
    return null;
  }
}

EOF
```

### 7.1 Create Metrics Table Migration

```bash
cat > supabase/migrations/008_metrics.sql << 'EOF'
-- ============================================================
-- LESSON 12: METRICS & MONITORING
-- ============================================================

-- Metrics Table
CREATE TABLE IF NOT EXISTS metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_type TEXT NOT NULL,
  metric_value NUMERIC NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_metrics_type ON metrics(metric_type);
CREATE INDEX idx_metrics_created_at ON metrics(created_at);
CREATE INDEX idx_metrics_user_id ON metrics(user_id);
CREATE INDEX idx_metrics_type_date ON metrics(metric_type, created_at);

-- RLS (allow service role only)
ALTER TABLE metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can insert metrics"
  ON metrics
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Service role can read metrics"
  ON metrics
  FOR SELECT
  USING (true);

-- ============================================================
-- RPC FUNCTION: Aggregate metrics
-- ============================================================

CREATE OR REPLACE FUNCTION get_metrics_aggregate(
  p_metric_type TEXT,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
  total_count BIGINT,
  total_value NUMERIC,
  avg_value NUMERIC,
  min_value NUMERIC,
  max_value NUMERIC,
  unique_users BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_count,
    SUM(metric_value) AS total_value,
    AVG(metric_value) AS avg_value,
    MIN(metric_value) AS min_value,
    MAX(metric_value) AS max_value,
    COUNT(DISTINCT user_id)::BIGINT AS unique_users
  FROM metrics
  WHERE
    metric_type = p_metric_type
    AND created_at >= p_start_date
    AND created_at <= p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

EOF
```

---

## Step 8: Instrument Authentication Monitoring

Update auth actions to include monitoring:

```bash
cat >> src/lib/actions/auth.ts << 'INNEREOF'

// Add monitoring imports at top
import { recordMetric } from '@/lib/monitoring/metrics';
import { loggers } from '@/lib/monitoring/logger';
import * as Sentry from '@sentry/nextjs';

// Update signIn function
export async function signIn(input: SignInInput) {
  const startTime = Date.now();

  try {
    // Existing validation...
    const validated = signInSchema.parse(input);

    const supabase = await createClient();
    const { data, error } = await supabase.auth.signInWithPassword({
      email: validated.email,
      password: validated.password,
    });

    if (error) {
      // ✅ Log failure
      loggers.auth('login_failed', {
        email: validated.email,
        error: error.message,
        duration: Date.now() - startTime,
      });

      // ✅ Record metric
      await recordMetric({
        type: 'auth.failure',
        value: 1,
        metadata: { reason: error.message },
      });

      return { success: false, error: error.message };
    }

    // ✅ Log success
    loggers.auth('login_success', {
      userId: data.user?.id,
      email: validated.email,
      duration: Date.now() - startTime,
    });

    // ✅ Record metric
    await recordMetric({
      type: 'auth.login',
      value: 1,
      userId: data.user?.id,
      metadata: { duration: Date.now() - startTime },
    });

    // ✅ Set Sentry user context
    Sentry.setUser({
      id: data.user?.id,
      email: data.user?.email,
    });

    revalidatePath(ROUTES.DASHBOARD);
    return { success: true, data };
  } catch (error: any) {
    // ✅ Capture error in Sentry
    Sentry.captureException(error, {
      tags: { feature: 'authentication', action: 'login' },
    });

    loggers.error(error, { feature: 'auth', action: 'login' });

    return { success: false, error: error.message };
  }
}

// Similar updates for signUp, signOut...

INNEREOF
```

---

## Step 9: Instrument Payment Monitoring

Update Stripe webhook to include monitoring:

```bash
cat >> src/app/api/webhooks/stripe/route.ts << 'INNEREOF'

import { recordMetric } from '@/lib/monitoring/metrics';
import { loggers } from '@/lib/monitoring/logger';
import * as Sentry from '@sentry/nextjs';

export async function POST(request: NextRequest) {
  const startTime = Date.now();

  try {
    // ... existing webhook verification ...

    const event = stripe.webhooks.constructEvent(/*...*/);

    // ✅ Log webhook received
    loggers.payment('webhook_received', {
      eventType: event.type,
      eventId: event.id,
    });

    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;

        // ✅ Record successful payment
        await recordMetric({
          type: 'payment.success',
          value: session.amount_total || 0,
          userId: session.metadata?.user_id,
          metadata: {
            sessionId: session.id,
            mode: session.mode,
          },
        });

        loggers.payment('checkout_completed', {
          userId: session.metadata?.user_id,
          amount: session.amount_total,
          duration: Date.now() - startTime,
        });

        // ... process subscription ...
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object;

        // ✅ Record payment failure
        await recordMetric({
          type: 'payment.failure',
          value: 1,
          metadata: {
            invoiceId: invoice.id,
            amount: invoice.amount_due,
            reason: invoice.last_finalization_error?.message,
          },
        });

        // ✅ Alert on payment failure
        Sentry.captureMessage('Payment failed', {
          level: 'warning',
          tags: {
            feature: 'payments',
            invoiceId: invoice.id,
          },
          contexts: {
            invoice: {
              amount: invoice.amount_due,
              currency: invoice.currency,
              customer: invoice.customer,
            },
          },
        });

        loggers.payment('payment_failed', {
          invoiceId: invoice.id,
          amount: invoice.amount_due,
        });

        // ... handle failed payment ...
        break;
      }

      // ... other webhook events ...
    }

    // ✅ Record webhook processing time
    await recordMetric({
      type: 'webhook.processing_time' as any,
      value: Date.now() - startTime,
      metadata: { eventType: event.type },
    });

    return NextResponse.json({ received: true });
  } catch (error: any) {
    // ✅ Capture webhook errors
    Sentry.captureException(error, {
      tags: { feature: 'payments', type: 'webhook' },
    });

    loggers.error(error, { feature: 'payments', action: 'webhook' });

    return NextResponse.json({ error: 'Webhook failed' }, { status: 500 });
  }
}

INNEREOF
```

---

## Step 10: Create Cached Monitoring Dashboard Components

### 10.1 Create Cached Metrics Dashboard Server Component

```bash
cat > src/components/features/monitoring/MetricsDashboard.tsx << 'EOF'
import { getMetricsAggregate } from '@/lib/monitoring/metrics';

/**
 * Cached Metrics Dashboard Component
 *
 * This Server Component caches expensive aggregation queries for 30-60 seconds.
 * Cache is automatically invalidated when new metrics are recorded via updateTag().
 */
async function MetricsDashboard() {
  'use cache'
  cacheLife('seconds') // Cache for 30-60 seconds
  cacheTag('metrics')
  cacheTag('metrics-dashboard')
  cacheTag('monitoring')

  const now = new Date();
  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  // All these queries are cached together
  const [
    authLogins,
    authFailures,
    projectsCreated,
    tasksCreated,
    paymentsSucceeded,
    paymentsFailed,
  ] = await Promise.all([
    getMetricsAggregate('auth.login', yesterday, now),
    getMetricsAggregate('auth.failure', yesterday, now),
    getMetricsAggregate('project.create', yesterday, now),
    getMetricsAggregate('task.create', yesterday, now),
    getMetricsAggregate('payment.success', yesterday, now),
    getMetricsAggregate('payment.failure', yesterday, now),
  ]);

  // Calculate rates
  const authSuccessRate =
    authLogins && authFailures
      ? (authLogins.total_count /
          (authLogins.total_count + authFailures.total_count)) *
        100
      : 100;

  const paymentSuccessRate =
    paymentsSucceeded && paymentsFailed
      ? (paymentsSucceeded.total_count /
          (paymentsSucceeded.total_count + paymentsFailed.total_count)) *
        100
      : 100;

  return {
    timestamp: now.toISOString(),
    period: '24h',
    metrics: {
      authentication: {
        totalLogins: authLogins?.total_count || 0,
        totalFailures: authFailures?.total_count || 0,
        successRate: authSuccessRate.toFixed(2) + '%',
        uniqueUsers: authLogins?.unique_users || 0,
      },
      projects: {
        totalCreated: projectsCreated?.total_count || 0,
        uniqueUsers: projectsCreated?.unique_users || 0,
      },
      tasks: {
        totalCreated: tasksCreated?.total_count || 0,
        uniqueUsers: tasksCreated?.unique_users || 0,
      },
      payments: {
        totalSuccess: paymentsSucceeded?.total_count || 0,
        totalFailed: paymentsFailed?.total_count || 0,
        successRate: paymentSuccessRate.toFixed(2) + '%',
        totalRevenue: paymentsSucceeded?.total_value || 0,
      },
    },
  };
}

export default MetricsDashboard;

EOF
```

### 10.2 Create Monitoring Dashboard API

Use the cached component in your API route:

```bash
mkdir -p src/app/api/monitoring
cat > src/app/api/monitoring/dashboard/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { Suspense } from 'react';
import MetricsDashboard from '@/components/features/monitoring/MetricsDashboard';

/**
 * Monitoring dashboard data endpoint with caching
 * GET /api/monitoring/dashboard
 *
 * Returns aggregated metrics for the last 24 hours.
 * Data is cached for 30-60 seconds via the MetricsDashboard component.
 * Cache is automatically invalidated when new metrics are recorded.
 */
export async function GET(request: Request) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    // Only allow admin users
    if (!user || user.email !== 'admin@yourapp.com') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Use cached component - this will be fast after first request
    const dashboardData = await MetricsDashboard();

    return NextResponse.json(dashboardData);
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}

EOF
```

### 10.3 Create Dashboard Page with Suspense

Create a dashboard page that uses Suspense for loading states:

```bash
mkdir -p src/app/admin/monitoring
cat > src/app/admin/monitoring/page.tsx << 'EOF'
import { Suspense } from 'react';
import MetricsDashboard from '@/components/features/monitoring/MetricsDashboard';
import HealthStatus from '@/components/features/monitoring/HealthStatus';

/**
 * Monitoring Dashboard Page
 *
 * Uses Suspense boundaries to show loading states while fetching
 * cached data. Each component can load independently.
 */
export default function MonitoringPage() {
  return (
    <div className="container mx-auto p-6">
      <h1 className="text-3xl font-bold mb-6">System Monitoring</h1>

      {/* Health Status Section */}
      <section className="mb-8">
        <h2 className="text-2xl font-semibold mb-4">Health Status</h2>
        <Suspense fallback={<HealthStatusSkeleton />}>
          <HealthStatusDisplay />
        </Suspense>
      </section>

      {/* Metrics Dashboard Section */}
      <section>
        <h2 className="text-2xl font-semibold mb-4">Metrics (Last 24h)</h2>
        <Suspense fallback={<MetricsDashboardSkeleton />}>
          <MetricsDashboardDisplay />
        </Suspense>
      </section>
    </div>
  );
}

async function HealthStatusDisplay() {
  const health = await HealthStatus();

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {Object.entries(health.checks).map(([name, check]) => (
        <div
          key={name}
          className={`p-4 rounded-lg border ${
            check.status === 'healthy'
              ? 'border-green-500 bg-green-50'
              : check.status === 'degraded'
              ? 'border-yellow-500 bg-yellow-50'
              : 'border-red-500 bg-red-50'
          }`}
        >
          <h3 className="font-semibold capitalize">{name}</h3>
          <p className="text-sm">{check.message}</p>
          {check.responseTime && (
            <p className="text-xs text-gray-600">{check.responseTime}ms</p>
          )}
        </div>
      ))}
    </div>
  );
}

async function MetricsDashboardDisplay() {
  const dashboard = await MetricsDashboard();

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {/* Authentication */}
      <MetricCard
        title="Authentication"
        metrics={[
          { label: 'Total Logins', value: dashboard.metrics.authentication.totalLogins },
          { label: 'Success Rate', value: dashboard.metrics.authentication.successRate },
        ]}
      />

      {/* Payments */}
      <MetricCard
        title="Payments"
        metrics={[
          { label: 'Successful', value: dashboard.metrics.payments.totalSuccess },
          { label: 'Revenue', value: `$${(dashboard.metrics.payments.totalRevenue / 100).toFixed(2)}` },
        ]}
      />

      {/* Projects */}
      <MetricCard
        title="Projects"
        metrics={[
          { label: 'Created', value: dashboard.metrics.projects.totalCreated },
          { label: 'Active Users', value: dashboard.metrics.projects.uniqueUsers },
        ]}
      />

      {/* Tasks */}
      <MetricCard
        title="Tasks"
        metrics={[
          { label: 'Created', value: dashboard.metrics.tasks.totalCreated },
          { label: 'Active Users', value: dashboard.metrics.tasks.uniqueUsers },
        ]}
      />
    </div>
  );
}

function MetricCard({ title, metrics }: { title: string; metrics: { label: string; value: any }[] }) {
  return (
    <div className="p-4 bg-white rounded-lg border">
      <h3 className="font-semibold mb-2">{title}</h3>
      {metrics.map((metric) => (
        <div key={metric.label} className="flex justify-between mb-1">
          <span className="text-sm text-gray-600">{metric.label}:</span>
          <span className="font-medium">{metric.value}</span>
        </div>
      ))}
    </div>
  );
}

function HealthStatusSkeleton() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {[1, 2, 3, 4, 5].map((i) => (
        <div key={i} className="p-4 rounded-lg border bg-gray-100 animate-pulse h-24" />
      ))}
    </div>
  );
}

function MetricsDashboardSkeleton() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {[1, 2, 3, 4].map((i) => (
        <div key={i} className="p-4 rounded-lg border bg-gray-100 animate-pulse h-32" />
      ))}
    </div>
  );
}

EOF
```

---

## Step 11: Understanding Monitoring-Specific Caching Strategy

### Why Monitoring Data Needs Special Caching

Monitoring data has unique characteristics:

**1. High Query Frequency**
- Dashboards are refreshed frequently by admins
- Health checks are polled every 1-5 minutes
- Metrics aggregations are expensive database queries

**2. Near-Real-Time Requirements**
- Need fresh data to detect issues quickly
- BUT don't need instant (<1 second) updates
- 30-60 second staleness is acceptable

**3. Expensive Aggregations**
- Counting metrics across time ranges
- Calculating success rates and percentages
- Joining multiple tables for dashboard views

### Cache Duration Guidelines

**Very Short (30-60 seconds) - `cacheLife('seconds')`:**
- ✅ **Health check results** - Detect issues quickly
- ✅ **Metrics dashboards** - Show recent activity
- ✅ **Aggregation queries** - Expensive to compute
- ✅ **System status** - Current state of services

**DO NOT Cache:**
- ❌ **Individual metric writes** - Must be real-time
- ❌ **Critical alerts** - Need immediate notification
- ❌ **Real-time event streams** - WebSocket/SSE data
- ❌ **User activity tracking** - Should be immediate

### Cache Invalidation Strategy

When new metrics are recorded, we selectively invalidate caches:

```typescript
// Recording a metric invalidates related caches
await recordMetric({
  type: 'auth.login',
  value: 1,
  userId: 'user-123',
});

// This automatically calls:
updateTag('metrics')           // Invalidate all metrics
updateTag('metrics-dashboard') // Invalidate dashboard
updateTag('metrics-auth')      // Invalidate auth-specific metrics
updateTag('monitoring')        // Invalidate monitoring views
```

**Tag Organization:**
- `'metrics'` - All metrics queries
- `'metrics-dashboard'` - Dashboard aggregations
- `'metrics-{feature}'` - Feature-specific (auth, payment, project, etc.)
- `'health-checks'` - Health status
- `'monitoring'` - All monitoring views

### Performance Benefits

**Without caching:**
- 10 admins checking dashboard every 30 seconds
- Each request runs 6 aggregation queries
- = 60 database queries per minute
- = 3,600 queries per hour

**With 60-second caching:**
- First admin request caches results
- Next 9 admins get cached data
- = 6 database queries per minute
- = 360 queries per hour
- **90% reduction in database load!**

### Balance: Real-Time vs Performance

The 30-60 second cache window provides:
- ✅ **Fast dashboard loads** - No waiting for queries
- ✅ **Reduced database load** - 90% fewer queries
- ✅ **Near-real-time data** - Issues detected within 1 minute
- ✅ **Consistent views** - All users see same data in window
- ✅ **Automatic invalidation** - Fresh data after metric writes

**This is the sweet spot for monitoring dashboards!**

---

## Step 12: Set Up Uptime Monitoring

### External Monitoring Services

Use external services to monitor your application from outside:

**Recommended Services:**
1. **Better Uptime** (https://betteruptime.com) - Free tier available
2. **Pingdom** (https://www.pingdom.com)
3. **UptimeRobot** (https://uptimerobot.com) - Free tier available

**Setup Steps:**
1. Sign up for uptime monitoring service
2. Add your health check endpoint: `https://your-domain.com/api/health`
3. Set check interval (1-5 minutes)
4. Configure alerts (email, Slack, SMS)

**What to Monitor:**
- Main health endpoint: `/api/health`
- Authentication endpoint: `/api/auth/session`
- Database connectivity
- Payment webhooks (check Stripe dashboard)

---

## Step 13: Configure Cron Jobs for Automated Checks

Add automated health checks using Vercel Cron:

```bash
# Update vercel.json
cat > vercel.json << 'INNEREOF'
{
  "crons": [
    {
      "path": "/api/cron/health-check",
      "schedule": "*/5 * * * *"
    },
    {
      "path": "/api/cron/metrics-aggregate",
      "schedule": "0 * * * *"
    }
  ]
}
INNEREOF
```

Create cron endpoints:

```bash
mkdir -p src/app/api/cron
cat > src/app/api/cron/health-check/route.ts << 'INNEREOF'
import { NextResponse } from 'next/server';
import { checkSystemHealth } from '@/lib/monitoring/alerts';

/**
 * Automated health check cron job
 * Runs every 5 minutes
 */
export async function GET(request: Request) {
  // Verify cron secret
  const authHeader = request.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    await checkSystemHealth();

    return NextResponse.json({
      success: true,
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}

INNEREOF
```

---

## Verification Steps

### 1. Verify Next.js 16 Cache Components Configuration

```bash
# Check next.config.js includes cacheComponents
grep -A 5 "cacheComponents" next.config.js

# Should see:
# cacheComponents: true,
# cacheLife: { seconds: { stale: 30, ... } }
```

### 2. Test Cached Health Checks

```bash
# Test main health endpoint
curl http://localhost:3000/api/health

# Test detailed health check
curl http://localhost:3000/api/health?detailed=true
```

**Expected Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-20T12:00:00.000Z",
  "checks": {
    "database": {
      "status": "healthy",
      "message": "Database is responsive",
      "responseTime": 45
    },
    "authentication": {
      "status": "healthy",
      "responseTime": 32
    },
    // ... other checks
  }
}
```

**Verify Cache is Working:**
```bash
# Make first request (should hit database)
time curl http://localhost:3000/api/health?detailed=true

# Make second request within 60 seconds (should be cached - faster)
time curl http://localhost:3000/api/health?detailed=true

# Second request should be significantly faster (< 10ms vs 100ms+)
```

### 3. Test Metrics Collection and Cache Invalidation

```bash
# Check initial dashboard state
curl http://localhost:3000/api/monitoring/dashboard

# Trigger some actions to generate metrics
# 1. Login (generates auth.login metric)
# 2. Create project (generates project.create metric)
# 3. Make payment (generates payment.success metric)

# Check dashboard again - should show new metrics immediately
# (cache was invalidated by recordMetric calls)
curl http://localhost:3000/api/monitoring/dashboard
```

**Verify Cache Tags:**
```bash
# Check that components use cache directives
grep -r "use cache" src/components/features/monitoring/
grep -r "cacheTag" src/components/features/monitoring/
grep -r "cacheLife" src/components/features/monitoring/

# Check that metrics functions have cache directives
grep -r "use cache" src/lib/monitoring/metrics.ts
```

### 4. Test Suspense Boundaries

Visit the monitoring dashboard page and observe loading behavior:

```bash
# Open monitoring dashboard
open http://localhost:3000/admin/monitoring

# Observe:
# 1. Loading skeletons appear first
# 2. Health status loads (cached after first request)
# 3. Metrics dashboard loads (cached after first request)
# 4. Subsequent refreshes are instant (served from cache)
```

### 5. Test Cache Refresh Intervals

```bash
# Run this script to test cache timing
cat > scripts/test-cache-timing.sh << 'TESTEOF'
#!/bin/bash

echo "Testing cache refresh intervals..."
echo ""

for i in {1..5}; do
  echo "Request $i ($(date +%H:%M:%S)):"
  time curl -s http://localhost:3000/api/health > /dev/null
  echo ""
  sleep 15
done

echo "After 75 seconds (past 60s cache window):"
time curl -s http://localhost:3000/api/health > /dev/null
TESTEOF

chmod +x scripts/test-cache-timing.sh
./scripts/test-cache-timing.sh
```

**Expected Results:**
- First request: Slow (100ms+) - cache miss
- Requests 2-4 (within 60s): Fast (<10ms) - cache hit
- Request after 60s: Slow again - cache expired, fresh data

### 6. Test Error Tracking

```bash
# Trigger an error in your application
# Check Sentry dashboard at https://sentry.io

# Should see:
# - Error details
# - Stack trace
# - User context
# - Breadcrumbs
```

### 7. Test Cache Invalidation on Metric Write

```bash
# Get current dashboard (this caches the results)
BEFORE=$(curl -s http://localhost:3000/api/monitoring/dashboard | jq '.metrics.authentication.totalLogins')
echo "Logins before: $BEFORE"

# Trigger a login (this records a metric and invalidates cache)
# Login via your app or API

# Get dashboard again (should show updated count immediately, not cached)
AFTER=$(curl -s http://localhost:3000/api/monitoring/dashboard | jq '.metrics.authentication.totalLogins')
echo "Logins after: $AFTER"

# Verify the count increased
if [ "$AFTER" -gt "$BEFORE" ]; then
  echo "✅ Cache invalidation working! Dashboard shows fresh data."
else
  echo "❌ Cache not invalidated. Still showing stale data."
fi
```

### 8. Test Alerts

```bash
# Stop your database temporarily
# Wait for health check to run
# Should receive alert via Slack/email
```

---

## Monitoring Best Practices

### 1. What to Monitor

**System Health:**
- ✅ Database connectivity and query performance
- ✅ API endpoint response times
- ✅ External service dependencies (Stripe, Supabase)
- ✅ Storage availability

**Business Metrics:**
- ✅ User signups and logins
- ✅ Projects and tasks created
- ✅ Payment success/failure rates
- ✅ User engagement (active users, feature usage)

**Performance Metrics:**
- ✅ Page load times (Web Vitals)
- ✅ API latency
- ✅ Database query times
- ✅ Error rates

### 2. Alert Thresholds

**Critical (Page immediately):**
- System completely down
- Database unreachable
- Payment processing failure rate > 10%
- Error rate > 5%

**Warning (Email/Slack):**
- Response time > 2 seconds
- Database query time > 1 second
- Payment failure rate > 5%
- Error rate > 1%

**Info (Log only):**
- Degraded performance
- Unusual traffic patterns
- Non-critical warnings

### 3. Log Retention

**Production:**
- Error logs: 30 days
- Combined logs: 7 days
- Metrics: 90 days
- Health checks: 7 days

**Development:**
- All logs: 24 hours (or don't persist)

### 4. Dashboard Organization

**Group by Feature:**
```
Authentication
├── Login success rate
├── Failed login attempts
├── Session duration
└── Active users

Payments
├── Revenue (24h, 7d, 30d)
├── Payment success rate
├── Failed payments
└── Average transaction value

Performance
├── Page load times
├── API latency
├── Database query times
└── Error rates
```

---

## Production Checklist

### Before Going Live

- [ ] **Next.js 16 Configuration** - Cache Components enabled in next.config.js
- [ ] **Cache Directives** - All monitoring components use `'use cache'`
- [ ] **Cache Tags** - Proper tags set for invalidation (metrics, health-checks, etc.)
- [ ] **Cache Duration** - `cacheLife('seconds')` set for 30-60 second cache
- [ ] **Cache Invalidation** - `updateTag()` called when recording metrics
- [ ] **Suspense Boundaries** - Dashboard wrapped in `<Suspense>` with loading states
- [ ] **Sentry configured** - DSN and environment set
- [ ] **Logging system** - Winston configured, log rotation enabled
- [ ] **Health checks** - All endpoints tested, caching verified
- [ ] **Metrics collection** - Database table created, RPC functions working, cache invalidation tested
- [ ] **Uptime monitoring** - External service configured
- [ ] **Alert channels** - Slack/email webhooks configured
- [ ] **Cron jobs** - Automated health checks scheduled
- [ ] **Monitoring dashboard** - Admin access configured, cache working
- [ ] **Error tracking** - Test errors captured in Sentry
- [ ] **Performance monitoring** - Vercel Analytics enabled
- [ ] **Cache Performance** - Verified 90% query reduction with caching

### Regular Monitoring Tasks

**Daily:**
- Check error rates in Sentry
- Review failed payments
- Check system health status

**Weekly:**
- Review performance trends
- Analyze user behavior metrics
- Check database performance
- Review alert accuracy (too many false positives?)

**Monthly:**
- Audit log retention
- Review monitoring costs
- Update alert thresholds based on patterns
- Performance optimization based on metrics

---

## Common Issues & Solutions

### Issue 1: Too many alerts

**Cause:** Alert thresholds too sensitive

**Solution:**
- Adjust thresholds based on normal patterns
- Add debouncing (only alert after N failures)
- Group related alerts (don't send 100 alerts for same issue)

### Issue 2: Missing metrics

**Cause:** Metric recording failures

**Solution:**
- Check database connectivity
- Verify RPC function permissions
- Add fallback logging if metric insert fails

### Issue 3: Slow health checks

**Cause:** Health checks timing out

**Solution:**
- Add timeouts to all health check operations
- Run checks in parallel
- Cache health status for high-traffic endpoints

### Issue 4: Log file disk space

**Cause:** Logs filling up disk

**Solution:**
- Enable log rotation (Winston daily rotate)
- Set max file size and retention
- Consider external log aggregation (Papertrail, LogDNA)

---

## Cost Estimation

**Free Tier Tools:**
- Sentry: 5,000 events/month free
- UptimeRobot: 50 monitors free
- Vercel Analytics: Included with Vercel

**Paid Options (if needed):**
- Sentry Team: $26/month (50K events)
- Better Uptime: $18/month (unlimited checks)
- Papertrail (logs): $7/month (50GB)
- **Estimated Total:** $50-100/month for full monitoring

---

## What You Learned

✅ **Next.js 16 Cache Components** - Configure caching for monitoring data
✅ **Near-Real-Time Caching** - Balance freshness and performance with 30-60s cache
✅ **Cache Invalidation** - Automatic cache updates when metrics are recorded
✅ **Suspense Boundaries** - Loading states for cached Server Components
✅ **Cache Tags** - Granular cache invalidation by feature
✅ **Health Check System** - Monitor all system components with caching
✅ **Error Tracking** - Capture and analyze errors with Sentry
✅ **Structured Logging** - Comprehensive logging with Winston
✅ **Custom Metrics** - Track business and technical metrics
✅ **Cached Aggregations** - Expensive queries cached for performance
✅ **Alert System** - Real-time notifications for issues
✅ **Monitoring Dashboard** - Cached dashboard with 90% query reduction
✅ **Uptime Monitoring** - External health checks
✅ **Performance Monitoring** - Track response times and latency
✅ **Feature-Specific Monitoring** - Auth, payments, storage, etc.
✅ **Production Best Practices** - Alert thresholds, log retention, dashboards, caching strategy

---

## Next Steps

**Extend Your Monitoring:**
1. Add custom business metrics (user retention, feature adoption)
2. Implement distributed tracing with OpenTelemetry
3. Create executive dashboards with key metrics
4. Add anomaly detection (detect unusual patterns)
5. Implement predictive alerts (predict issues before they happen)
6. Add user session recording (LogRocket, FullStory)
7. Create runbooks for common issues
8. Implement automated remediation for known issues

**Advanced Topics:**
- APM (Application Performance Monitoring) with New Relic/Datadog
- Log aggregation with ELK stack (Elasticsearch, Logstash, Kibana)
- Metrics visualization with Grafana
- Distributed tracing across microservices
- Real user monitoring (RUM)

---

## Reference

**Files Created:**
- `next.config.js` - Next.js 16 Cache Components configuration
- `sentry.server.config.ts` - Sentry configuration
- `supabase/migrations/008_metrics.sql` - Metrics table and RPC functions
- `src/lib/monitoring/logger.ts` - Structured logging system
- `src/lib/monitoring/healthCheck.ts` - Health check framework
- `src/lib/monitoring/checks/database.ts` - Database health check
- `src/lib/monitoring/checks/auth.ts` - Auth health check
- `src/lib/monitoring/checks/payments.ts` - Payments health check
- `src/lib/monitoring/checks/storage.ts` - Storage health check
- `src/lib/monitoring/checks/realtime.ts` - Realtime health check
- `src/lib/monitoring/metrics.ts` - Metrics collection with cache invalidation
- `src/lib/monitoring/alerts.ts` - Alert system
- `src/app/api/health/route.ts` - Cached health check endpoint
- `src/app/api/monitoring/dashboard/route.ts` - Cached monitoring dashboard API
- `src/app/api/cron/health-check/route.ts` - Automated health check cron
- `src/app/admin/monitoring/page.tsx` - Monitoring dashboard page with Suspense
- `src/components/features/monitoring/MetricsDashboard.tsx` - Cached dashboard component
- `src/components/features/monitoring/HealthStatus.tsx` - Cached health status component
- `scripts/test-cache-timing.sh` - Script to test cache refresh intervals

**Key Concepts:**
- Next.js 16 Cache Components (`'use cache'`)
- Cache duration strategies (`cacheLife('seconds')`)
- Cache invalidation with tags (`updateTag()`)
- Suspense boundaries for loading states
- Near-real-time monitoring (30-60s cache)
- Observability (logs, metrics, traces)
- Health checks and liveness probes with caching
- Structured logging
- Error tracking and alerting
- Custom business metrics with cache invalidation
- Cached aggregation queries
- Uptime monitoring
- Performance monitoring
- Alert fatigue prevention

**Resources:**
- Next.js 16 Caching: https://nextjs.org/docs/app/api-reference/directives/use-cache
- Cache Components Guide: /NEXTJS-16-CACHE-COMPONENTS-REFERENCE.md
- Sentry Docs: https://docs.sentry.io/
- Winston Logging: https://github.com/winstonjs/winston
- OpenTelemetry: https://opentelemetry.io/
- The Twelve-Factor App (Logs): https://12factor.net/logs
- Google SRE Book (Monitoring): https://sre.google/sre-book/monitoring-distributed-systems/

---

## Congratulations! 🎉

You've implemented a **comprehensive monitoring and observability system with Next.js 16 Cache Components**!

Your application now has:
- ✅ **Cached monitoring dashboards** - 90% reduction in database queries
- ✅ **Near-real-time data** - 30-60 second cache for fresh insights
- ✅ **Automatic cache invalidation** - Fresh data when metrics are recorded
- ✅ **Suspense boundaries** - Smooth loading states for cached components
- ✅ **Real-time health monitoring** - Cached health checks
- ✅ **Error tracking and alerting** - Sentry integration
- ✅ **Custom business metrics** - With cache invalidation
- ✅ **Structured logging** - Winston logging system
- ✅ **Performance monitoring** - Track response times
- ✅ **Uptime monitoring** - External health checks
- ✅ **Feature-specific instrumentation** - Per-feature cache tags
- ✅ **Admin monitoring dashboard** - Fast, cached aggregations

**Your system is production-ready, observable, and performant!** 📊⚡

---

**Tutorial Complete:** You've built a full-stack production application with Next.js 16, React 19.2, Supabase, Stripe payments, and comprehensive monitoring!

---

## Quick Verification Guide: Database Queries & Scripts

### SQL Queries for Quick Health Checks

#### 1. Check Metrics Collection

```sql
-- Check if metrics table exists and has data
SELECT 
  metric_type,
  COUNT(*) as total_events,
  MIN(created_at) as first_event,
  MAX(created_at) as last_event,
  COUNT(DISTINCT user_id) as unique_users
FROM metrics
GROUP BY metric_type
ORDER BY total_events DESC;

-- Expected output:
-- auth.login    | 45 | 2024-01-20 10:00:00 | 2024-01-20 15:30:00 | 12
-- project.create| 23 | 2024-01-20 10:15:00 | 2024-01-20 15:20:00 | 8
-- payment.success| 5 | 2024-01-20 11:00:00 | 2024-01-20 14:00:00 | 5
```

#### 2. Check Recent Authentication Activity

```sql
-- Get last 24 hours of auth metrics
SELECT 
  metric_type,
  COUNT(*) as count,
  jsonb_pretty(jsonb_agg(DISTINCT metadata)) as sample_metadata
FROM metrics
WHERE 
  metric_type IN ('auth.login', 'auth.failure', 'auth.signup')
  AND created_at >= NOW() - INTERVAL '24 hours'
GROUP BY metric_type;

-- Check login success rate
WITH auth_stats AS (
  SELECT 
    metric_type,
    COUNT(*) as count
  FROM metrics
  WHERE 
    metric_type IN ('auth.login', 'auth.failure')
    AND created_at >= NOW() - INTERVAL '24 hours'
  GROUP BY metric_type
)
SELECT 
  COALESCE((SELECT count FROM auth_stats WHERE metric_type = 'auth.login'), 0) as successful_logins,
  COALESCE((SELECT count FROM auth_stats WHERE metric_type = 'auth.failure'), 0) as failed_logins,
  ROUND(
    COALESCE((SELECT count FROM auth_stats WHERE metric_type = 'auth.login'), 0)::numeric / 
    NULLIF(
      COALESCE((SELECT count FROM auth_stats WHERE metric_type = 'auth.login'), 0) + 
      COALESCE((SELECT count FROM auth_stats WHERE metric_type = 'auth.failure'), 0),
      0
    ) * 100,
    2
  ) as success_rate_percent;
```

#### 3. Check Payment Metrics

```sql
-- Payment success/failure tracking
SELECT 
  metric_type,
  COUNT(*) as transaction_count,
  SUM(metric_value) as total_value,
  AVG(metric_value) as avg_value,
  MIN(metric_value) as min_value,
  MAX(metric_value) as max_value
FROM metrics
WHERE 
  metric_type IN ('payment.success', 'payment.failure')
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY metric_type;

-- Daily revenue breakdown
SELECT 
  DATE(created_at) as date,
  COUNT(*) as payments,
  SUM(metric_value) as revenue_cents,
  ROUND(SUM(metric_value) / 100.0, 2) as revenue_dollars
FROM metrics
WHERE 
  metric_type = 'payment.success'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

#### 4. Check System Health Status

```sql
-- Check subscription health
SELECT 
  plan_id,
  COUNT(*) as user_count,
  status,
  COUNT(*) FILTER (WHERE cancel_at_period_end = true) as canceling_soon
FROM prj_user_subscriptions
GROUP BY plan_id, status
ORDER BY plan_id;

-- Check project creation by plan
SELECT 
  s.plan_id,
  COUNT(DISTINCT p.id) as total_projects,
  COUNT(DISTINCT p.owner_id) as active_users,
  ROUND(AVG(project_count.cnt), 2) as avg_projects_per_user
FROM prj_user_subscriptions s
LEFT JOIN prj_projects p ON p.owner_id = s.user_id
LEFT JOIN (
  SELECT owner_id, COUNT(*) as cnt
  FROM prj_projects
  GROUP BY owner_id
) project_count ON project_count.owner_id = s.user_id
GROUP BY s.plan_id;
```

#### 5. Check Database Performance

```sql
-- Check for slow queries (if pg_stat_statements is enabled)
-- Note: pg_stat_statements must be enabled in PostgreSQL config
SELECT 
  query,
  calls,
  total_exec_time,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 1000 -- queries taking more than 1 second
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

### API Health Check Scripts

#### 1. Basic Health Check

```bash
#!/bin/bash
# Save as: scripts/check-health.sh

echo "🏥 Health Check - $(date)"
echo "================================"

# Check main health endpoint
response=$(curl -s http://localhost:3000/api/health)
status=$(echo $response | jq -r '.status')

if [ "$status" == "healthy" ]; then
  echo "✅ System Status: HEALTHY"
else
  echo "❌ System Status: $status"
fi

# Check detailed health
curl -s http://localhost:3000/api/health?detailed=true | jq '.checks | to_entries[] | {service: .key, status: .value.status, responseTime: .value.responseTime}'

echo ""
echo "================================"
```

#### 2. Detailed Component Health Check

```bash
#!/bin/bash
# Save as: scripts/check-all-services.sh

check_service() {
  local name=$1
  local url=$2
  
  start_time=$(date +%s%N)
  response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
  end_time=$(date +%s%N)
  
  duration=$(( (end_time - start_time) / 1000000 ))
  
  if [ "$response" == "200" ]; then
    echo "✅ $name: OK (${duration}ms)"
  else
    echo "❌ $name: FAILED (HTTP $response)"
  fi
}

echo "🔍 Checking All Services..."
echo ""

check_service "Main Health" "http://localhost:3000/api/health"
check_service "Database" "http://localhost:3000/api/health?detailed=true"
check_service "Monitoring Dashboard" "http://localhost:3000/api/monitoring/dashboard"
check_service "Authentication" "http://localhost:3000/api/auth/session"

echo ""
echo "✨ Check complete!"
```

#### 3. Metrics Dashboard Quick Check

```bash
#!/bin/bash
# Save as: scripts/check-metrics.sh

echo "📊 Metrics Summary (Last 24h)"
echo "================================"

curl -s http://localhost:3000/api/monitoring/dashboard | jq '{
  authentication: .metrics.authentication,
  payments: .metrics.payments,
  projects: .metrics.projects.totalCreated,
  tasks: .metrics.tasks.totalCreated
}'
```

#### 4. Load Test Metrics Collection

```bash
#!/bin/bash
# Save as: scripts/test-metrics-collection.sh

echo "🧪 Testing Metrics Collection..."

# This script demonstrates how to test metrics collection
# Note: Replace $DATABASE_URL with your actual Supabase connection string

echo "Inserting test metrics..."
echo "INSERT INTO metrics (metric_type, metric_value, metadata) VALUES ('auth.login', 1, '{\"test\": true}');"
echo ""
echo "After running test metrics, check with:"
echo "SELECT metric_type, COUNT(*) FROM metrics WHERE metadata->>'test' = 'true' GROUP BY metric_type;"
echo ""
echo "Delete test metrics with:"
echo "DELETE FROM metrics WHERE metadata->>'test' = 'true';"
```

### Node.js Monitoring Scripts

#### 1. Health Check Script

```javascript
// Save as: scripts/health-check.js
// Usage: node scripts/health-check.js

const BASE_URL = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';

async function checkHealth() {
  console.log('🏥 Running Health Checks...\n');
  
  try {
    // Main health check
    const healthRes = await fetch(`${BASE_URL}/api/health`);
    const health = await healthRes.json();
    
    console.log(`Overall Status: ${health.status === 'healthy' ? '✅' : '❌'} ${health.status.toUpperCase()}`);
    console.log(`Timestamp: ${health.timestamp}\n`);
    
    // Detailed checks
    const detailedRes = await fetch(`${BASE_URL}/api/health?detailed=true`);
    const detailed = await detailedRes.json();
    
    console.log('Component Status:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    for (const [name, check] of Object.entries(detailed.checks)) {
      const icon = check.status === 'healthy' ? '✅' : '❌';
      const time = check.responseTime ? `(${check.responseTime}ms)` : '';
      console.log(`${icon} ${name.padEnd(15)} ${check.message} ${time}`);
    }
    
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    return health.status === 'healthy';
  } catch (error) {
    console.error('❌ Health check failed:', error.message);
    return false;
  }
}

async function main() {
  const isHealthy = await checkHealth();
  process.exit(isHealthy ? 0 : 1);
}

main();
```

#### 2. Real-Time Metrics Monitor

```javascript
// Save as: scripts/monitor-metrics.js
// Usage: node scripts/monitor-metrics.js

const BASE_URL = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';

async function fetchMetrics() {
  const res = await fetch(`${BASE_URL}/api/monitoring/dashboard`);
  return res.json();
}

function formatMetrics(data) {
  console.clear();
  console.log('📊 Real-Time Metrics Dashboard');
  console.log('════════════════════════════════════════════════\n');
  
  // Authentication
  console.log('🔐 AUTHENTICATION (24h)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  Logins:        ${data.metrics.authentication.totalLogins}`);
  console.log(`  Failed:        ${data.metrics.authentication.failedLogins}`);
  console.log(`  Success Rate:  ${data.metrics.authentication.successRate}%`);
  console.log(`  Active Users:  ${data.metrics.authentication.activeUsers}\n`);
  
  // Payments
  console.log('💳 PAYMENTS (24h)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  Successful:    ${data.metrics.payments.successful}`);
  console.log(`  Failed:        ${data.metrics.payments.failed}`);
  console.log(`  Success Rate:  ${data.metrics.payments.successRate}%`);
  console.log(`  Revenue:       $${(data.metrics.payments.revenue / 100).toFixed(2)}\n`);
  
  // Projects & Tasks
  console.log('📁 PROJECTS & TASKS (24h)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  Projects:      ${data.metrics.projects.totalCreated}`);
  console.log(`  Tasks:         ${data.metrics.tasks.totalCreated}`);
  console.log(`  Completed:     ${data.metrics.tasks.totalCompleted}\n`);
  
  // Storage
  console.log('💾 STORAGE');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  Files:         ${data.metrics.storage.totalFiles}`);
  console.log(`  Size:          ${(data.metrics.storage.totalSize / 1024 / 1024).toFixed(2)} MB\n`);
  
  // Performance
  console.log('⚡ PERFORMANCE');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  Avg Response:  ${data.performance.avgResponseTime}ms`);
  console.log(`  Errors (24h):  ${data.performance.errorCount}\n`);
  
  console.log(`Last updated: ${new Date().toLocaleString()}`);
  console.log('Press Ctrl+C to stop monitoring...');
}

async function monitor() {
  try {
    const data = await fetchMetrics();
    formatMetrics(data);
  } catch (error) {
    console.error('❌ Failed to fetch metrics:', error.message);
  }
}

// Monitor every 30 seconds
console.log('🚀 Starting metrics monitor...\n');
monitor();
setInterval(monitor, 30000);
```

#### 3. Alert System Test

```javascript
// Save as: scripts/test-alerts.js
// Usage: node scripts/test-alerts.js

async function testAlert() {
  console.log('🔔 Testing Alert System...\n');
  
  const testPayload = {
    level: 'warning',
    title: 'Test Alert',
    message: 'This is a test alert from the monitoring system',
    details: {
      timestamp: new Date().toISOString(),
      test: true
    }
  };
  
  try {
    const response = await fetch('http://localhost:3000/api/monitoring/alert', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testPayload)
    });
    
    if (response.ok) {
      console.log('✅ Alert sent successfully!');
      console.log('   Check your Slack channel or email for the alert.');
    } else {
      console.error('❌ Alert failed:', await response.text());
    }
  } catch (error) {
    console.error('❌ Failed to send alert:', error.message);
  }
}

testAlert();
```

---

## Quick Verification Checklist

### After Setup - Verify Everything Works

**1. Database Setup ✓**
```bash
# Check metrics table exists
psql $DATABASE_URL -c "\d metrics"

# Check health_checks table exists  
psql $DATABASE_URL -c "\d health_checks"

# Verify RPC functions
psql $DATABASE_URL -c "\df get_metrics_aggregate"
```

**2. Health Endpoints ✓**
```bash
# Test basic health
curl http://localhost:3000/api/health

# Test detailed health
curl http://localhost:3000/api/health?detailed=true

# Test monitoring dashboard
curl http://localhost:3000/api/monitoring/dashboard
```

**3. Metrics Collection ✓**
```bash
# Insert a test metric
curl -X POST http://localhost:3000/api/monitoring/metrics \
  -H "Content-Type: application/json" \
  -d '{"type": "test.metric", "value": 1, "metadata": {"test": true}}'

# Verify it was recorded
psql $DATABASE_URL -c "SELECT * FROM metrics WHERE metric_type = 'test.metric' LIMIT 5;"
```

**4. Error Tracking ✓**
```bash
# Trigger a test error
curl http://localhost:3000/api/test-error

# Check Sentry dashboard at: https://sentry.io
# Should see the error logged
```

**5. Logging System ✓**
```bash
# Check logs directory
ls -lh logs/

# View recent errors
tail -f logs/error.log

# View combined logs
tail -f logs/combined.log
```

**6. Alert System ✓**
```bash
# Test alert webhook
node scripts/test-alerts.js

# Check Slack channel or email for test alert
```

**7. Monitoring Dashboard ✓**
```bash
# Access the dashboard
open http://localhost:3000/admin/monitoring

# Verify all metrics display
# Check real-time updates
```

**8. Automated Health Checks ✓**
```bash
# Run health check script
chmod +x scripts/check-health.sh
./scripts/check-health.sh

# Run comprehensive check
chmod +x scripts/check-all-services.sh
./scripts/check-all-services.sh
```

**9. Real-Time Monitoring ✓**
```bash
# Start real-time monitor
node scripts/monitor-metrics.js

# Should update every 30 seconds
```

**10. Uptime Monitoring ✓**
- Set up UptimeRobot or Pingdom
- Monitor endpoint: `https://yourdomain.com/api/health`
- Configure alerts for downtime
- Test by temporarily stopping the server

---

## Troubleshooting

### Health Check Returns Unhealthy

**Database Issues:**
```sql
-- Check database connectivity
SELECT NOW();

-- Check for connection issues
SELECT 
  datname,
  numbackends,
  xact_commit,
  xact_rollback
FROM pg_stat_database
WHERE datname = current_database();
```

**Storage Issues:**
```bash
# Check Supabase storage status
curl https://your-project.supabase.co/storage/v1/healthcheck
```

### Metrics Not Being Recorded

**Check Metrics Table:**
```sql
-- Verify table structure
\d metrics

-- Check recent inserts
SELECT metric_type, COUNT(*), MAX(created_at)
FROM metrics
GROUP BY metric_type
ORDER BY MAX(created_at) DESC;

-- Check for errors in insertion
SELECT * FROM metrics 
WHERE created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 50;
```

**Check RPC Functions:**
```sql
-- Test metrics aggregate function
SELECT * FROM get_metrics_aggregate(
  'auth.login',
  NOW() - INTERVAL '24 hours',
  NOW()
);
```

### Sentry Not Receiving Errors

**Verify Configuration:**
```bash
# Check environment variables
echo $SENTRY_DSN
echo $NEXT_PUBLIC_SENTRY_DSN

# Test Sentry connection
node -e "
const Sentry = require('@sentry/nextjs');
Sentry.init({ dsn: process.env.SENTRY_DSN });
Sentry.captureMessage('Test from CLI');
console.log('Test error sent to Sentry');
"
```

### Logs Not Rotating

**Check Winston Configuration:**
```javascript
// In src/lib/monitoring/logger.ts
// Verify maxSize and maxFiles settings

// Manually compress old logs
gzip logs/*.log

// Check disk space
df -h logs/
```

### Alerts Not Sending

**Test Slack Webhook:**
```bash
# Test Slack directly
curl -X POST $SLACK_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{"text": "Test alert from monitoring system"}'

# Check webhook response
# Should return "ok"
```

**Test Email Alerts:**
```bash
# Verify email service configuration
# Check SMTP settings in .env.local

# Send test email
node scripts/test-alerts.js
```

---

## Summary

In this lesson, you learned how to implement comprehensive monitoring and observability for your Next.js application:

### ✅ What We Covered

1. **Next.js 16 Cache Components Configuration**
   - Experimental cache components enabled
   - Cache lifecycle configuration (30-60s for monitoring)
   - Cache duration strategies
   - next.config.js setup

2. **Cached Server Components**
   - `'use cache'` directive for monitoring components
   - `cacheLife('seconds')` for near-real-time data
   - `cacheTag()` for granular invalidation
   - Suspense boundaries for loading states

3. **Cache Invalidation Strategy**
   - `updateTag()` when recording metrics
   - Feature-specific cache tags
   - Automatic cache refresh
   - Selective invalidation

4. **Feature-Segregated Health Checks (Cached)**
   - Authentication health monitoring
   - Payment system checks
   - Database connectivity tests
   - Storage availability verification
   - Realtime subscription monitoring
   - 30-60 second cache for health status

5. **Error Tracking**
   - Sentry integration for error capture
   - Source maps for debugging
   - Error grouping and alerting
   - Performance monitoring

6. **Structured Logging**
   - Winston logger setup
   - Log rotation and retention
   - Feature-specific loggers (auth, payment, project)
   - Log levels and formatting

7. **Custom Metrics (with Cache Invalidation)**
   - Database metrics table
   - Metrics collection API with cache invalidation
   - Cached aggregation RPC functions
   - Business and technical metrics
   - 90% reduction in database load

8. **Alert System**
   - Multi-channel alerts (Slack, email)
   - Alert levels (critical, warning, info)
   - Configurable thresholds
   - Alert deduplication

9. **Monitoring Dashboard (Cached)**
   - Cached metrics display (30-60s)
   - Health status overview
   - Performance tracking
   - User activity monitoring
   - Fast dashboard loads

10. **Automated Monitoring**
    - Health check cron jobs
    - Uptime monitoring
    - External service checks
    - Alert escalation

11. **Verification Tools**
    - Cache timing tests
    - Cache invalidation tests
    - SQL queries for quick checks
    - Bash scripts for automation
    - Node.js monitoring scripts
    - Quick verification checklist

### 🎯 Key Takeaways

- **Cache Monitoring Data**: Use Next.js 16 Cache Components for 90% query reduction
- **Near-Real-Time is Enough**: 30-60 second cache balances freshness and performance
- **Invalidate Selectively**: Use cache tags to invalidate only relevant data
- **Suspense for UX**: Show loading states while fetching cached data
- **Monitor Everything**: Database, authentication, payments, storage, and realtime features
- **Segregate by Feature**: Separate health checks make it easier to identify issues
- **Cache Health Checks**: Prevent overload with 30-60 second cache
- **Log Strategically**: Capture meaningful logs without overwhelming storage
- **Alert Proactively**: Set up alerts before issues become critical
- **Verify Regularly**: Use automated scripts to verify system health and cache performance
- **Track Metrics**: Monitor both technical and business metrics
- **Test Monitoring**: Regularly test your monitoring, alert systems, and cache invalidation
- **Retain Appropriately**: Balance log retention with storage costs

### 📊 Monitoring Best Practices

1. **Cache Duration**: 30-60 seconds for monitoring dashboards (balance real-time and performance)
2. **Cache Invalidation**: Always invalidate cache when recording new metrics
3. **Cache Tags**: Use feature-specific tags for granular invalidation
4. **Health Checks**: Cache for 30-60 seconds, external checks every 1-5 minutes
5. **Metrics Collection**: Real-time writes, cached reads (30-60s)
6. **Log Retention**: 7-30 days depending on criticality
7. **Alert Thresholds**: Start conservative, tune based on patterns
8. **Dashboard Updates**: 30-60s cache for aggregated views
9. **Uptime Monitoring**: External service checking every 1-5 minutes
10. **Cache Performance**: Monitor cache hit rates and query reduction

### 🚀 Next Steps

1. **Verify Cache Components** working in next.config.js
2. **Test cache performance** - confirm 90% query reduction
3. **Monitor cache hit rates** in production
4. **Set up Sentry** and verify error tracking
5. **Configure alerts** for your team's communication channels
6. **Deploy health checks** and monitor for 24 hours
7. **Tune alert thresholds** based on baseline metrics
8. **Tune cache durations** based on usage patterns
9. **Create runbooks** for common issues (include cache invalidation)
10. **Set up on-call rotation** for critical alerts
11. **Review metrics weekly** to identify trends

### 📚 Additional Resources

- [Sentry Documentation](https://docs.sentry.io/)
- [Winston Logger](https://github.com/winstonjs/winston)
- [UptimeRobot](https://uptimerobot.com/)
- [Pingdom](https://www.pingdom.com/)
- [Observability Best Practices](https://www.datadoghq.com/knowledge-center/observability/)

---

**Congratulations!** 🎉 You've now implemented a production-ready monitoring and observability system with Next.js 16 Cache Components that will help you maintain a healthy, performant application and quickly identify and resolve issues before they impact users.

The monitoring foundation you've built will scale with your application and provide invaluable insights into system behavior, user activity, and business metrics. By leveraging Cache Components, your monitoring dashboards achieve **90% reduction in database load** while maintaining near-real-time visibility into your system's health. Your application is now equipped to handle production traffic with confidence and performance!
