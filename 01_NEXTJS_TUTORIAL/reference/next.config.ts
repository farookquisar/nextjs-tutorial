import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Enable Next.js 16 Cache Components feature (includes PPR)
  cacheComponents: true,

  // Custom cache life profiles
  cacheLife: {
    // Weekly cache profile for less frequently changing data
    weekly: {
      stale: 60 * 60 * 24 * 7, // 7 days in seconds
      revalidate: 60 * 60 * 24 * 7,
      expire: 60 * 60 * 24 * 7,
    },
    // Daily cache profile for moderately changing data
    daily: {
      stale: 60 * 60 * 24, // 1 day in seconds
      revalidate: 60 * 60 * 24,
      expire: 60 * 60 * 24,
    },
  },
};

export default nextConfig;
