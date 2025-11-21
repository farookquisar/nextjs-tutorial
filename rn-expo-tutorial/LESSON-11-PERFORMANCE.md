# Lesson 11: Performance & Testing

**Duration**: 90 minutes | **Difficulty**: Advanced | **Prerequisites**: Lessons 1-10

## Learning Objectives
- Profile React Native performance
- Measure New Architecture benefits
- Implement comprehensive testing
- Set up performance monitoring
- Optimize bundle size

## Installation

```bash
# Testing dependencies
npm install --save-dev jest @testing-library/react-native @testing-library/jest-native
npm install --save-dev detox

# Performance monitoring
npm install @shopify/react-native-performance
```

## Performance Profiling

### 1. Measure New Architecture Benefits

```typescript
// lib/performance/metrics.ts
export function measureRenderTime(componentName: string, callback: () => void) {
  const start = performance.now();
  callback();
  const end = performance.now();
  console.log(`${componentName} render time: ${(end - start).toFixed(2)}ms`);
}

// Usage in component
import { useEffect } from 'react';

function PostCard({ post }: { post: Post }) {
  useEffect(() => {
    const start = performance.now();
    return () => {
      const end = performance.now();
      if (end - start > 16) {
        console.warn(`PostCard took ${(end - start).toFixed(2)}ms to render`);
      }
    };
  }, []);

  return <View>...</View>;
}
```

### 2. Bundle Size Optimization

```bash
# Analyze bundle size
npx expo export --platform ios
npx expo export --platform android

# Check bundle sizes
du -sh dist/bundles/*

# Expected sizes:
# iOS: < 5MB
# Android: < 8MB
```

**Optimization Strategies**:

```javascript
// babel.config.js
module.exports = function(api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      // Remove console logs in production
      ['transform-remove-console', { exclude: ['error', 'warn'] }],
      // Tree shaking
      'react-native-reanimated/plugin',
    ],
    env: {
      production: {
        plugins: ['transform-remove-console'],
      },
    },
  };
};
```

### 3. Memory Leak Detection

```typescript
// lib/performance/memory.ts
export class MemoryMonitor {
  private intervalId?: NodeJS.Timeout;

  start() {
    if (this.intervalId) return;

    this.intervalId = setInterval(() => {
      if (__DEV__ && (performance as any).memory) {
        const memory = (performance as any).memory;
        const used = (memory.usedJSHeapSize / 1048576).toFixed(2);
        const total = (memory.totalJSHeapSize / 1048576).toFixed(2);

        console.log(`Memory: ${used}MB / ${total}MB`);

        if (parseInt(used) > 150) {
          console.warn('⚠️ High memory usage detected!');
        }
      }
    }, 5000);
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = undefined;
    }
  }
}

// Usage in App.tsx
const memoryMonitor = new MemoryMonitor();
memoryMonitor.start();
```

### 4. FPS Monitoring

```typescript
// lib/performance/fps.ts
import { useEffect, useRef } from 'react';

export function useFPSMonitor() {
  const frameCount = useRef(0);
  const lastTime = useRef(performance.now());

  useEffect(() => {
    if (!__DEV__) return;

    const checkFPS = () => {
      frameCount.current++;

      const now = performance.now();
      const delta = now - lastTime.current;

      if (delta >= 1000) {
        const fps = Math.round((frameCount.current * 1000) / delta);

        if (fps < 50) {
          console.warn(`⚠️ Low FPS detected: ${fps}`);
        }

        frameCount.current = 0;
        lastTime.current = now;
      }

      requestAnimationFrame(checkFPS);
    };

    const id = requestAnimationFrame(checkFPS);
    return () => cancelAnimationFrame(id);
  }, []);
}
```

## Testing

### 1. Unit Tests with Jest

```typescript
// __tests__/lib/database/posts.test.ts
import { PostsRepository } from '@/lib/database/repositories/posts';
import { database } from '@/lib/database';

beforeAll(async () => {
  await database.init();
});

afterAll(async () => {
  await database.close();
});

describe('PostsRepository', () => {
  it('should create a post', async () => {
    const post = await PostsRepository.create({
      user_id: 'test-user',
      content: 'Test post',
      media_url: null,
      media_type: null,
    });

    expect(post.content).toBe('Test post');
    expect(post.user_id).toBe('test-user');
    expect(post.id).toBeDefined();
  });

  it('should get all posts', async () => {
    const posts = await PostsRepository.getAll();
    expect(Array.isArray(posts)).toBe(true);
  });

  it('should update a post', async () => {
    const post = await PostsRepository.create({
      user_id: 'test-user',
      content: 'Original content',
      media_url: null,
      media_type: null,
    });

    const updated = await PostsRepository.update(post.id, {
      content: 'Updated content',
    });

    expect(updated?.content).toBe('Updated content');
  });

  it('should delete a post', async () => {
    const post = await PostsRepository.create({
      user_id: 'test-user',
      content: 'To be deleted',
      media_url: null,
      media_type: null,
    });

    const success = await PostsRepository.delete(post.id);
    expect(success).toBe(true);

    const deleted = await PostsRepository.getById(post.id);
    expect(deleted).toBeNull();
  });
});
```

### 2. Component Tests

```typescript
// __tests__/components/PostCard.test.tsx
import { render, fireEvent } from '@testing-library/react-native';
import { PostCard } from '@/components/feed/PostCard';

describe('PostCard', () => {
  const mockPost = {
    id: '1',
    user_id: 'user1',
    user_name: 'Test User',
    user_avatar: 'https://example.com/avatar.jpg',
    content: 'Test post content',
    media_url: null,
    media_type: null,
    likes_count: 5,
    comments_count: 2,
    created_at: Date.now(),
    updated_at: Date.now(),
    synced_at: Date.now(),
    is_deleted: 0,
    version: 1,
  };

  it('renders post content', () => {
    const { getByText } = render(<PostCard post={mockPost} />);
    expect(getByText('Test post content')).toBeTruthy();
  });

  it('displays like count', () => {
    const { getByText } = render(<PostCard post={mockPost} />);
    expect(getByText('5')).toBeTruthy();
  });

  it('handles like button press', () => {
    const { getByTestId } = render(<PostCard post={mockPost} />);
    const likeButton = getByTestId('like-button');

    fireEvent.press(likeButton);
    // Add assertions for like behavior
  });
});
```

### 3. E2E Tests with Detox

```typescript
// e2e/feed.test.ts
describe('Feed Flow', () => {
  beforeAll(async () => {
    await device.launchApp();
  });

  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('should display feed', async () => {
    await expect(element(by.id('home-screen'))).toBeVisible();
    await expect(element(by.id('post-list'))).toBeVisible();
  });

  it('should create a new post', async () => {
    // Tap compose button
    await element(by.id('compose-fab')).tap();

    // Type content
    await element(by.id('post-input')).typeText('Test post content');

    // Submit post
    await element(by.id('post-button')).tap();

    // Verify post appears
    await expect(element(by.text('Test post content'))).toBeVisible();
  });

  it('should like a post', async () => {
    // Find first post
    const firstPost = element(by.id('post-card')).atIndex(0);

    // Get initial like count
    const likeButton = element(by.id('like-button')).atIndex(0);

    // Tap like
    await likeButton.tap();

    // Verify like count increased
    // Add assertion here
  });

  it('should scroll feed smoothly', async () => {
    await element(by.id('post-list')).scroll(500, 'down');
    await element(by.id('post-list')).scroll(500, 'down');
    await element(by.id('post-list')).scroll(500, 'down');

    // Should load more posts
    await waitFor(element(by.id('loading-footer')))
      .toBeVisible()
      .withTimeout(2000);
  });
});
```

### 4. Performance Testing

```typescript
// __tests__/performance/feed.test.ts
import { measurePerformance } from '@shopify/react-native-performance';

describe('Feed Performance', () => {
  it('should render feed in under 1 second', async () => {
    const start = performance.now();

    // Render feed with 100 posts
    await renderFeed(100);

    const end = performance.now();
    const duration = end - start;

    expect(duration).toBeLessThan(1000);
  });

  it('should scroll at 60 FPS', async () => {
    const fpsData = await measureScrollFPS();
    const averageFPS = fpsData.reduce((a, b) => a + b) / fpsData.length;

    expect(averageFPS).toBeGreaterThanOrEqual(55);
  });
});
```

## Performance Benchmarks

### Target Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| App Launch | < 2s | Measure: __ |
| Feed Load | < 1s | Measure: __ |
| Scroll FPS | > 55 | Measure: __ |
| Memory | < 150MB | Measure: __ |
| Bundle Size | < 5MB (iOS) | Measure: __ |

### Measuring on Device

**iOS (Xcode)**:
1. Open Xcode → Product → Profile
2. Select "Time Profiler"
3. Run app and interact
4. Analyze CPU usage

**Android (Android Studio)**:
1. Open Profiler window
2. Select CPU, Memory, Network
3. Record session
4. Analyze performance

## Optimization Checklist

### React Native
- [ ] Use React.memo for components
- [ ] Implement useMemo for expensive calculations
- [ ] Use useCallback for event handlers
- [ ] Avoid inline functions in render
- [ ] Use FlatList/FlashList properly

### New Architecture
- [ ] Verify Fabric enabled
- [ ] Verify TurboModules enabled
- [ ] Measure render latency
- [ ] Check synchronous layout

### Images
- [ ] Use expo-image for caching
- [ ] Compress images before upload
- [ ] Use appropriate image sizes
- [ ] Implement lazy loading

### Database
- [ ] Add indexes for queries
- [ ] Use transactions for batch operations
- [ ] Clean up old data regularly
- [ ] Optimize query patterns

### Bundle
- [ ] Remove unused dependencies
- [ ] Enable Hermes
- [ ] Strip console logs in production
- [ ] Use dynamic imports where possible

## Testing Checklist
- [ ] Unit tests pass (>80% coverage)
- [ ] Component tests pass
- [ ] E2E tests pass
- [ ] Performance benchmarks met
- [ ] No memory leaks detected
- [ ] 60 FPS scrolling achieved

## Key Features Implemented
✅ Performance profiling
✅ Bundle size optimization
✅ Memory leak detection
✅ FPS monitoring
✅ Unit testing
✅ Component testing
✅ E2E testing
✅ Performance benchmarks

## Next: Lesson 12 - App Store Publishing 🚀
