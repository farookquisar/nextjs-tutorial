# Lesson 1 Setup Script Usage Guide

This bash script automates the complete setup for Module 1, Lesson 1.

## 📝 What the Script Does

The `lesson-1-setup.sh` script automates all 11 steps from Lesson 1:

1. ✅ Creates Next.js 16 project with React 19.2
2. ✅ Verifies versions
3. ✅ Creates organized folder structure
4. ✅ Creates constants file (DRY principle)
5. ✅ Creates TypeScript types
6. ✅ Configures Next.js 16 Cache Components
7. ✅ Updates layout.tsx
8. ✅ Creates home page
9. ✅ Creates environment template
10. ✅ Updates .gitignore
11. ✅ Builds the project

## 🚀 How to Use

### Option 1: Fresh Project (Recommended for Learning)

If you want to start from scratch in a new directory:

```bash
# 1. Create a new directory
mkdir my-nextjs-app
cd my-nextjs-app

# 2. Initialize git
git init

# 3. Copy the script from this repo
cp /path/to/lesson-1-setup.sh .

# 4. Make it executable
chmod +x lesson-1-setup.sh

# 5. Run the script
./lesson-1-setup.sh
```

### Option 2: Review Only

The current project was already set up manually. To see what the script does:

```bash
# Just review the script
cat lesson-1-setup.sh

# Or run it in a test directory
mkdir ../test-lesson-1
cd ../test-lesson-1
cp ../nextjs-tutorial/lesson-1-setup.sh .
./lesson-1-setup.sh
```

## ⏱️ Expected Duration

- First run: ~2-3 minutes (includes npm install)
- Subsequent runs: ~1-2 minutes

## 📋 What Gets Created

```
project/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── globals.css
│   ├── constants/index.ts      ⭐ All app constants
│   ├── types/index.ts          ⭐ TypeScript types
│   ├── components/
│   │   ├── ui/
│   │   └── features/
│   │       ├── auth/
│   │       ├── projects/
│   │       ├── tasks/
│   │       └── payments/
│   ├── lib/
│   ├── hooks/
│   └── utils/
├── next.config.ts              ⭐ Cache Components config
├── .env.local.example
├── package.json                (Next.js 16, React 19.2)
└── LESSON-1-CHECKLIST.md
```

## ✅ Verification After Running

After the script completes, verify the setup:

```bash
# 1. Check versions
cat package.json | grep -E "(next|react)"
# Should show: Next.js 16.0.3, React 19.2.0

# 2. Check folder structure
find src -type d | sort

# 3. Verify constants file
cat src/constants/index.ts | head -20

# 4. Test development server
npm run dev
# Visit http://localhost:3000

# 5. Test build
npm run build
# Should show: ○ (Static) prerendered as static content
```

## 🎯 Learning Approach

### For Copy-Paste Learning:

Instead of running the entire script, you can copy-paste individual sections.

Example - Create constants file only:
```bash
# Open the script and copy lines for Step 4
cat > src/constants/index.ts << 'EOF'
export const DB_TABLES = {
  PROJECTS: 'prj_projects',
  // ... rest of the code
}
EOF
```

Example - Create folder structure only:
```bash
# Copy the folder creation commands from Step 3
mkdir -p src/lib
mkdir -p src/components/ui
# ... etc
```

### Step-by-Step Manual Approach:

Open the script and execute each section manually:

```bash
# Step 1: Create Next.js project
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm --yes

# Step 2: Verify
node -v && npm -v

# Step 3: Create folders
mkdir -p src/lib src/components/ui src/types src/constants

# ... continue with each step
```

## 🔍 Understanding Each Section

The script is heavily commented. Each section includes:
- Clear step numbers
- Description of what it does
- The actual code
- Success confirmation message

Script Structure:
```bash
# Step X: Description
echo "Step X: Creating something..."
# ... actual code ...
echo "✓ Something created"
```

## 🐛 Troubleshooting

### Script fails at npm install
```bash
# Check Node.js version (need 18+)
node -v

# Clear npm cache
npm cache clean --force

# Try again
./lesson-1-setup.sh
```

### Build fails
```bash
# Check for syntax errors
npm run build

# View detailed error
npm run build 2>&1 | more
```

### Permission denied
```bash
# Make script executable
chmod +x lesson-1-setup.sh
```

## 📚 Best Practices Demonstrated

1. **DRY Principle**: All constants in one file
2. **Type Safety**: Full TypeScript coverage
3. **SOLID**: Single Responsibility - organized folders
4. **No Magic Strings**: Everything in constants
5. **Import Alias**: Clean @/* imports
6. **Cache Components**: Next.js 16 latest features
7. **Database Naming**: All tables prefixed with prj_

## 🔄 Resetting for Practice

Want to practice again? Reset with:

```bash
# WARNING: This deletes everything!
cd ..
rm -rf my-nextjs-app
mkdir my-nextjs-app
cd my-nextjs-app
./lesson-1-setup.sh
```

## 📖 Related Files

- `LESSON-1-CHECKLIST.md` - Verification checklist
- `lesson-1-setup.sh` - This automated script
- `src/constants/index.ts` - All app constants (with prj_ prefix)
- `src/types/index.ts` - TypeScript definitions
- `next.config.ts` - Cache Components config

## 🎓 Learning Outcomes

After running this script, you'll have:
- ✅ Working Next.js 16 + React 19.2 app
- ✅ Cache Components enabled
- ✅ Professional folder structure
- ✅ Type-safe codebase
- ✅ Best practices implemented
- ✅ All database objects prefixed with prj_
- ✅ Ready for Lesson 2 (Supabase)

---

**Next**: Proceed to Lesson 2 - Supabase Setup & Database Configuration
