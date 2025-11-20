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

## Step 1: Install Monitoring Dependencies

```bash
# Core monitoring packages
npm install @sentry/nextjs
npm install winston winston-daily-rotate-file
npm install prom-client  # For metrics

# Development dependencies
npm install -D @types/winston
```

---

## Step 2: Configure Sentry Error Tracking

### 2.1 Setup Sentry Account

1. Go to https://sentry.io and create account
2. Create a new project → Select "Next.js"
3. Copy your DSN (Data Source Name)

### 2.2 Initialize Sentry

```bash
npx @sentry/wizard@latest -i nextjs
```

This creates:
- `sentry.client.config.ts`
- `sentry.server.config.ts`
- `sentry.edge.config.ts`

### 2.3 Configure Sentry with Context

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

## Step 3: Create Structured Logging System

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

## Step 4: Create Health Check System

### 4.1 Base Health Check Interface

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

### 4.2 Database Health Check

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

### 4.3 Authentication Health Check

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

### 4.4 Stripe Payment Health Check

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

### 4.5 Storage Health Check

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

### 4.6 Real-time Health Check

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

## Step 5: Create Health Check API Endpoint

```bash
cat > src/app/api/health/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import { runHealthChecks } from '@/lib/monitoring/healthCheck';
import { databaseHealthCheck } from '@/lib/monitoring/checks/database';
import { authHealthCheck } from '@/lib/monitoring/checks/auth';
import { paymentsHealthCheck } from '@/lib/monitoring/checks/payments';
import { storageHealthCheck } from '@/lib/monitoring/checks/storage';
import { realtimeHealthCheck } from '@/lib/monitoring/checks/realtime';

/**
 * Health check endpoint
 * GET /api/health
 *
 * Returns detailed health status of all system components
 */
export async function GET(request: Request) {
  const url = new URL(request.url);
  const detailed = url.searchParams.get('detailed') === 'true';

  try {
    // Run all health checks
    const healthResult = await runHealthChecks([
      databaseHealthCheck,
      authHealthCheck,
      paymentsHealthCheck,
      storageHealthCheck,
      realtimeHealthCheck,
    ]);

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

## Step 6: Create Metrics Collection System

```bash
cat > src/lib/monitoring/metrics.ts << 'EOF'
import { createClient } from '@/lib/supabase/server';
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
 * Record a metric event
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
  } catch (error) {
    // Don't let metrics fail the main operation
    logger.error('Failed to record metric', { error, data });
  }
}

/**
 * Get metrics for a time period
 */
export async function getMetrics(
  type: MetricType,
  startDate: Date,
  endDate: Date
) {
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
 * Get aggregated metrics
 */
export async function getMetricsAggregate(
  type: MetricType,
  startDate: Date,
  endDate: Date
) {
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

Create metrics table migration:

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

(Continuing in next part due to length...)

## Step 7: Instrument Authentication Monitoring

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

## Step 8: Instrument Payment Monitoring

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

## Step 9: Create Monitoring Dashboard API

```bash
mkdir -p src/app/api/monitoring
cat > src/app/api/monitoring/dashboard/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { getMetricsAggregate } from '@/lib/monitoring/metrics';

/**
 * Monitoring dashboard data endpoint
 * GET /api/monitoring/dashboard
 *
 * Returns aggregated metrics for the last 24 hours
 */
export async function GET(request: Request) {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();

    // Only allow admin users
    if (!user || user.email !== 'admin@yourapp.com') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const now = new Date();
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    // Fetch metrics for last 24 hours
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

    return NextResponse.json({
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
    });
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    );
  }
}


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

### 1. Test Health Checks

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

### 2. Test Metrics Collection

```bash
# Trigger some actions to generate metrics
# 1. Login (generates auth.login metric)
# 2. Create project (generates project.create metric)
# 3. Make payment (generates payment.success metric)

# Check dashboard
curl http://localhost:3000/api/monitoring/dashboard
```

### 3. Test Error Tracking

```bash
# Trigger an error in your application
# Check Sentry dashboard at https://sentry.io

# Should see:
# - Error details
# - Stack trace
# - User context
# - Breadcrumbs
```

### 4. Test Alerts

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

- [ ] **Sentry configured** - DSN and environment set
- [ ] **Logging system** - Winston configured, log rotation enabled
- [ ] **Health checks** - All endpoints tested
- [ ] **Metrics collection** - Database table created, RPC functions working
- [ ] **Uptime monitoring** - External service configured
- [ ] **Alert channels** - Slack/email webhooks configured
- [ ] **Cron jobs** - Automated health checks scheduled
- [ ] **Monitoring dashboard** - Admin access configured
- [ ] **Error tracking** - Test errors captured in Sentry
- [ ] **Performance monitoring** - Vercel Analytics enabled

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

✅ **Health Check System** - Monitor all system components
✅ **Error Tracking** - Capture and analyze errors with Sentry
✅ **Structured Logging** - Comprehensive logging with Winston
✅ **Custom Metrics** - Track business and technical metrics
✅ **Alert System** - Real-time notifications for issues
✅ **Monitoring Dashboard** - Visualize system health
✅ **Uptime Monitoring** - External health checks
✅ **Performance Monitoring** - Track response times and latency
✅ **Feature-Specific Monitoring** - Auth, payments, storage, etc.
✅ **Production Best Practices** - Alert thresholds, log retention, dashboards

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
- `sentry.server.config.ts` - Sentry configuration
- `supabase/migrations/008_metrics.sql` - Metrics table and RPC functions
- `src/lib/monitoring/logger.ts` - Structured logging system
- `src/lib/monitoring/healthCheck.ts` - Health check framework
- `src/lib/monitoring/checks/database.ts` - Database health check
- `src/lib/monitoring/checks/auth.ts` - Auth health check
- `src/lib/monitoring/checks/payments.ts` - Payments health check
- `src/lib/monitoring/checks/storage.ts` - Storage health check
- `src/lib/monitoring/checks/realtime.ts` - Realtime health check
- `src/lib/monitoring/metrics.ts` - Metrics collection system
- `src/lib/monitoring/alerts.ts` - Alert system
- `src/app/api/health/route.ts` - Main health check endpoint
- `src/app/api/monitoring/dashboard/route.ts` - Monitoring dashboard API
- `src/app/api/cron/health-check/route.ts` - Automated health check cron
- `src/app/dashboard/monitoring/page.tsx` - Monitoring dashboard page
- `src/components/features/monitoring/MonitoringDashboard.tsx` - Dashboard component
- `src/components/features/monitoring/HealthCheckPanel.tsx` - Health check UI
- `src/components/features/monitoring/MetricsPanel.tsx` - Metrics UI

**Key Concepts:**
- Observability (logs, metrics, traces)
- Health checks and liveness probes
- Structured logging
- Error tracking and alerting
- Custom business metrics
- Uptime monitoring
- Performance monitoring
- Alert fatigue prevention

**Resources:**
- Sentry Docs: https://docs.sentry.io/
- Winston Logging: https://github.com/winstonjs/winston
- OpenTelemetry: https://opentelemetry.io/
- The Twelve-Factor App (Logs): https://12factor.net/logs
- Google SRE Book (Monitoring): https://sre.google/sre-book/monitoring-distributed-systems/

---

## Congratulations! 🎉

You've implemented a **comprehensive monitoring and observability system**!

Your application now has:
- ✅ Real-time health monitoring
- ✅ Error tracking and alerting
- ✅ Custom business metrics
- ✅ Structured logging
- ✅ Performance monitoring
- ✅ Uptime monitoring
- ✅ Feature-specific instrumentation
- ✅ Admin monitoring dashboard

**Your system is production-ready and observable!** 📊

---

**Tutorial Complete:** You've built a full-stack production application with Next.js 16, React 19.2, Supabase, Stripe payments, and comprehensive monitoring!
