# Astro 5.0 Tutorial - Lesson 10: View Transitions & Animations

**Prerequisites:** Completion of Lessons 1-9

---

## ✅ 1. DESC (Description)

### What You'll Learn

Implement smooth page transitions and animations using Astro's View Transitions API and CSS animations.

**Core Concepts:**
- ✅ View Transitions API
- ✅ Smooth page transitions
- ✅ Fade, slide, and scale animations
- ✅ Persistent elements
- ✅ Loading states and skeletons
- ✅ Animation choreography
- ✅ Reduced motion preferences
- ✅ Fallback for unsupported browsers

**What You'll Build:**
- Page transition animations
- Persistent audio player
- Loading skeletons
- Scroll animations
- Hero animations
- Card hover effects
- Menu transitions
- Modal animations

---

## ✅ 2. CODE (Implementation)

### STEP 1: Enable View Transitions

\`\`\`bash
cat > src/layouts/MainLayout.astro << 'EOF'
---
import { ViewTransitions } from 'astro:transitions';
import BaseLayout from './BaseLayout.astro';
import Header from '../components/Header.astro';
import Footer from '../components/Footer.astro';

interface Props {
  title: string;
  description?: string;
}

const { title, description } = Astro.props;
---

<BaseLayout title={title} description={description}>
  <ViewTransitions />

  <div class="min-h-screen flex flex-col">
    <Header />

    <main class="flex-1" transition:animate="slide">
      <slot />
    </main>

    <Footer />
  </div>
</BaseLayout>

<style is:global>
  /* View transition animations */
  @view-transition {
    navigation: auto;
  }

  /* Fade animation */
  [transition\\:animate="fade"] {
    view-transition-name: fade;
  }

  ::view-transition-old(fade),
  ::view-transition-new(fade) {
    animation-duration: 0.3s;
  }

  /* Slide animation */
  [transition\\:animate="slide"] {
    view-transition-name: slide;
  }

  ::view-transition-old(slide) {
    animation: slide-out 0.3s ease-in-out;
  }

  ::view-transition-new(slide) {
    animation: slide-in 0.3s ease-in-out;
  }

  @keyframes slide-out {
    from {
      transform: translateX(0);
    }
    to {
      transform: translateX(-100%);
      opacity: 0;
    }
  }

  @keyframes slide-in {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  /* Reduce motion for accessibility */
  @media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
    }
  }
</style>
EOF
\`\`\`

---

### STEP 2: Create Loading Skeletons

\`\`\`bash
cat > src/components/Skeleton.astro << 'EOF'
---
interface Props {
  type?: 'text' | 'title' | 'avatar' | 'image' | 'card';
  count?: number;
}

const { type = 'text', count = 1 } = Astro.props;
---

<div class="animate-pulse space-y-4">
  {Array.from({ length: count }).map(() => (
    <div>
      {type === 'text' && (
        <div class="h-4 bg-gray-300 dark:bg-gray-700 rounded w-full"></div>
      )}

      {type === 'title' && (
        <div class="h-8 bg-gray-300 dark:bg-gray-700 rounded w-3/4"></div>
      )}

      {type === 'avatar' && (
        <div class="h-12 w-12 bg-gray-300 dark:bg-gray-700 rounded-full"></div>
      )}

      {type === 'image' && (
        <div class="aspect-video bg-gray-300 dark:bg-gray-700 rounded-lg"></div>
      )}

      {type === 'card' && (
        <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-6 space-y-4">
          <div class="h-6 bg-gray-300 dark:bg-gray-700 rounded w-3/4"></div>
          <div class="space-y-2">
            <div class="h-4 bg-gray-300 dark:bg-gray-700 rounded"></div>
            <div class="h-4 bg-gray-300 dark:bg-gray-700 rounded w-5/6"></div>
          </div>
        </div>
      )}
    </div>
  ))}
</div>
EOF
\`\`\`

---

### STEP 3: Add Scroll Animations

\`\`\`bash
cat > src/components/ScrollAnimation.astro << 'EOF'
---
interface Props {
  animation?: 'fade-up' | 'fade-down' | 'fade-left' | 'fade-right' | 'scale';
  delay?: number;
}

const { animation = 'fade-up', delay = 0 } = Astro.props;
---

<div
  class="scroll-animate"
  data-animation={animation}
  style={\`animation-delay: \${delay}ms\`}
>
  <slot />
</div>

<script>
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-in');
          observer.unobserve(entry.target);
        }
      });
    },
    {
      threshold: 0.1,
      rootMargin: '0px 0px -50px 0px',
    }
  );

  document.querySelectorAll('.scroll-animate').forEach((el) => {
    observer.observe(el);
  });
</script>

<style>
  .scroll-animate {
    opacity: 0;
    transform: translateY(20px);
    transition: opacity 0.6s ease, transform 0.6s ease;
  }

  .scroll-animate.animate-in {
    opacity: 1;
    transform: translateY(0);
  }

  [data-animation="fade-down"].scroll-animate {
    transform: translateY(-20px);
  }

  [data-animation="fade-left"].scroll-animate {
    transform: translateX(20px);
  }

  [data-animation="fade-right"].scroll-animate {
    transform: translateX(-20px);
  }

  [data-animation="scale"].scroll-animate {
    transform: scale(0.95);
  }

  [data-animation="fade-down"].scroll-animate.animate-in,
  [data-animation="fade-left"].scroll-animate.animate-in,
  [data-animation="fade-right"].scroll-animate.animate-in,
  [data-animation="scale"].scroll-animate.animate-in {
    transform: none;
  }
</style>
EOF
\`\`\`

---

## ✅ 3. VERIFY (Testing & Troubleshooting)

### Verification Checklist

**View Transitions:**
- [ ] Page transitions smooth
- [ ] Animations work correctly
- [ ] Persistent elements stay
- [ ] No flash of unstyled content
- [ ] Reduced motion respected

---

**Congratulations!** 🎉 You've added beautiful animations!

---

**Last Updated:** November 2025
**Astro Version:** 5.0+
**Lesson Duration:** 4-5 hours
