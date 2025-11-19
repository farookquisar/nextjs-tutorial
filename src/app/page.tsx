import { ROUTES } from '@/constants';

export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      <main className="flex flex-col items-center justify-center gap-8 p-8 text-center">
        <div className="space-y-4">
          <h1 className="text-5xl font-bold text-gray-900 dark:text-white">
            Project Management App
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-300">
            Built with Next.js 16 + React 19.2 + Tailwind CSS + Supabase
          </p>
        </div>

        <div className="flex flex-col gap-4 sm:flex-row">
          <div className="rounded-lg bg-white dark:bg-gray-800 p-6 shadow-lg">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
              Features
            </h2>
            <ul className="text-left text-gray-600 dark:text-gray-300 space-y-2">
              <li>✅ Next.js 16 with Cache Components</li>
              <li>✅ React 19.2 with Server Components</li>
              <li>✅ Tailwind CSS 4</li>
              <li>✅ TypeScript</li>
              <li>✅ Supabase Integration (Coming Next)</li>
            </ul>
          </div>
        </div>

        <div className="text-sm text-gray-500 dark:text-gray-400 mt-8">
          Module 1, Lesson 1: Setup Complete! 🎉
        </div>
      </main>
    </div>
  );
}
