import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Project Management App",
  description: "Learn Next.js 16 + React 19.2 - Project Management Application",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
