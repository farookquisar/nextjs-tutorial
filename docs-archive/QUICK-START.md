# 🚀 Quick Start Guide - Lesson 1

## ⚡ Quick Commands

### Run Everything (Automated)
```bash
./lesson-1-setup.sh
```

### Manual Step-by-Step
```bash
# 1. Create Next.js 16 project
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm --yes

# 2. Create folders
mkdir -p src/{lib,components/{ui,features/{auth,projects,tasks,payments}},types,constants,hooks,utils}

# 3. Copy constants (see lesson-1-setup.sh lines 70-246)
cat > src/constants/index.ts << 'CONSTANTS_EOF'
# ... copy from script ...
CONSTANTS_EOF

# 4. Copy types (see lesson-1-setup.sh lines 250-380)
cat > src/types/index.ts << 'TYPES_EOF'
# ... copy from script ...
TYPES_EOF

# 5. Update next.config.ts (see lesson-1-setup.sh lines 384-405)
# 6. Update layout.tsx (see lesson-1-setup.sh lines 409-429)
# 7. Update page.tsx (see lesson-1-setup.sh lines 433-468)
# 8. Create .env.local.example (see lesson-1-setup.sh lines 472-483)

# 9. Build
npm run build
```

### Verify Setup
```bash
# Check versions
cat package.json | grep -E "(next|react)"

# Check structure
find src -type d | sort

# Test build
npm run build

# Start dev server
npm run dev
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `lesson-1-setup.sh` | Automated setup script |
| `LESSON-1-SCRIPT-USAGE.md` | Script usage guide |
| `LESSON-1-CHECKLIST.md` | Verification checklist |
| `src/constants/index.ts` | All app constants (prj_ prefix) |
| `src/types/index.ts` | TypeScript types |
| `next.config.ts` | Cache Components config |

## 🎯 What You Get

✅ Next.js 16.0.3 + React 19.2.0  
✅ Cache Components enabled  
✅ TypeScript + Tailwind CSS 4  
✅ Organized folder structure  
✅ DRY principle (constants file)  
✅ All DB objects with prj_ prefix  

## 📚 Documentation

- **Full Tutorial**: See conversation above
- **Script Usage**: `LESSON-1-SCRIPT-USAGE.md`
- **Verification**: `LESSON-1-CHECKLIST.md`
- **Next Lesson**: Module 1, Lesson 2 (Supabase)

## 🔥 One-Liner Setup

```bash
chmod +x lesson-1-setup.sh && ./lesson-1-setup.sh
```

---

**Ready for Lesson 2?** Type "ready" to continue!
