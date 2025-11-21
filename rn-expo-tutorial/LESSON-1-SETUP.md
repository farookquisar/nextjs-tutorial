# Lesson 1: React Native 0.82 Setup & New Architecture

**Duration**: 90 minutes
**Difficulty**: Beginner
**Prerequisites**: Node.js 18+, basic JavaScript/React knowledge

## Learning Objectives

By the end of this lesson, you will:
- Understand React Native's New Architecture (Fabric, TurboModules, JSI)
- Set up a React Native 0.82 project with Expo 54
- Configure TypeScript, ESLint, and Prettier
- Run your app on iOS and Android
- Understand the project structure and development workflow

---

## DESCRIBE: Understanding React Native 0.82 & New Architecture

### What's New in React Native 0.82

React Native 0.82, released in October 2025, marks a major milestone:
- **New Architecture is mandatory** - No legacy bridge toggle
- **Fabric renderer** - Synchronous JavaScript-to-native communication
- **TurboModules** - On-demand, lazy-loaded native modules
- **JSI (JavaScript Interface)** - Direct JavaScript-to-native C++ bindings
- **Bridgeless mode** - Eliminates the old bridge entirely
- **Hermes V1** - 9% faster bundle loads, 7.6% faster TTI (Time to Interactive)
- **React 19.1.1 integration** - Latest React features

### The New Architecture Explained

#### 1. Fabric Renderer
The old architecture used an asynchronous bridge where JavaScript and native couldn't communicate synchronously. Fabric changes this:

**Old Architecture**:
```
JavaScript → Serialized JSON → Bridge → Native Thread
(async, unpredictable timing)
```

**New Architecture (Fabric)**:
```
JavaScript → JSI → Direct C++ → Native (synchronous)
```

**Benefits**:
- Synchronous layout calculations
- Better handling of user interactions
- Smoother animations at 60+ FPS
- Reduced latency for UI updates

#### 2. TurboModules
Native modules are now loaded on-demand instead of at startup.

**Old Architecture**:
- All native modules loaded at app start
- Slow startup time
- Memory overhead

**New Architecture (TurboModules)**:
- Modules loaded only when needed
- Faster app startup
- Lower memory footprint
- Type-safe interfaces with JSI

#### 3. JSI (JavaScript Interface)
Direct bindings between JavaScript and C++.

**Key Features**:
- No serialization overhead
- Synchronous method calls
- Ability to hold references to C++ objects
- Foundation for Fabric and TurboModules

#### 4. Hermes V1
Hermes is now the default JavaScript engine with significant improvements:
- 9% faster bundle load times
- 7.6% faster Time to Interactive (TTI)
- Better memory management
- Ahead-of-time compilation

### Expo 54 Overview

Expo SDK 54 provides a managed workflow around React Native:
- **Expo Router**: File-based navigation (like Next.js)
- **EAS Build**: Cloud build service for iOS/Android
- **EAS Update**: Over-the-air updates
- **expo-audio**: New audio API (replaces expo-av)
- **expo-video**: New video API (replaces expo-av)
- **expo-image**: Highly optimized image component
- **Prebuild**: Generate native projects when needed

### Development Workflow

```
Write Code (TypeScript/JSX)
    ↓
Expo Dev Client
    ↓
Metro Bundler (Fast Refresh)
    ↓
iOS Simulator / Android Emulator / Physical Device
```

---

## CODE: Setting Up Your Project

### Step 1: Install Prerequisites

First, ensure you have the required tools installed.

#### Install Node.js 18+ (if not already installed)
```bash
# Check Node version
node --version
# Should be 18.x or higher

# If you need to install/update Node.js, use nvm:
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
# nvm install 18
# nvm use 18
```

#### Install Expo CLI
```bash
npm install -g expo-cli@latest
```

#### Install Watchman (macOS only, recommended for better file watching)
```bash
# macOS
brew install watchman
```

#### Set Up iOS Development (macOS only)
```bash
# Install Xcode from Mac App Store (14.3+ required)
# Install Xcode Command Line Tools
xcode-select --install

# Install iOS Simulator
# Open Xcode → Preferences → Components → Install desired simulators
```

#### Set Up Android Development
```bash
# Download Android Studio from https://developer.android.com/studio
# Install Android Studio and open it
# Go to: Settings → Appearance & Behavior → System Settings → Android SDK
# Install SDK Platform 34 (Android 14.0) and SDK Platform-Tools
# Add to ~/.bashrc or ~/.zshrc:

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### Step 2: Create the Project

Create a new Expo project with TypeScript and New Architecture enabled:

```bash
# Navigate to your projects folder
cd ~/projects

# Create new Expo app with TypeScript template
npx create-expo-app@latest mediasocial --template expo-template-blank-typescript

# Navigate into the project
cd mediasocial
```

### Step 3: Configure New Architecture

The New Architecture is enabled by default in React Native 0.82, but let's verify and configure it properly.

#### Update app.json
```bash
# Open app.json and verify/update the configuration
cat > app.json << 'EOF'
{
  "expo": {
    "name": "MediaSocial",
    "slug": "mediasocial",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "assetBundlePatterns": [
      "**/*"
    ],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.yourcompany.mediasocial",
      "newArchEnabled": true
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "package": "com.yourcompany.mediasocial",
      "newArchEnabled": true
    },
    "web": {
      "favicon": "./assets/favicon.png"
    },
    "plugins": [
      "expo-router"
    ],
    "experiments": {
      "typedRoutes": true
    }
  }
}
EOF
```

### Step 4: Install Essential Dependencies

Install the core packages we'll need:

```bash
# Install Expo Router for navigation
npx expo install expo-router react-native-safe-area-context react-native-screens expo-linking expo-constants expo-status-bar

# Install TypeScript types
npm install --save-dev @types/react @types/react-native

# Install development tools
npm install --save-dev eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks
```

### Step 5: Configure TypeScript

Create a strict TypeScript configuration:

```bash
cat > tsconfig.json << 'EOF'
{
  "extends": "expo/tsconfig.base",
  "compilerOptions": {
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "allowJs": true,
    "jsx": "react-native",
    "lib": ["ESNext"],
    "target": "ESNext",
    "noEmit": true,
    "isolatedModules": true,
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./components/*"],
      "@/lib/*": ["./lib/*"],
      "@/types/*": ["./types/*"]
    }
  },
  "include": [
    "**/*.ts",
    "**/*.tsx",
    ".expo/types/**/*.ts",
    "expo-env.d.ts"
  ],
  "exclude": [
    "node_modules"
  ]
}
EOF
```

### Step 6: Configure ESLint

Set up ESLint for code quality:

```bash
cat > .eslintrc.js << 'EOF'
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier',
  ],
  plugins: ['react', 'react-hooks', '@typescript-eslint'],
  rules: {
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-explicit-any': 'warn',
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
  env: {
    'react-native/react-native': true,
    es6: true,
    node: true,
  },
};
EOF
```

### Step 7: Configure Prettier

Set up Prettier for code formatting:

```bash
cat > .prettierrc << 'EOF'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "arrowParens": "avoid",
  "bracketSpacing": true
}
EOF
```

### Step 8: Set Up Project Structure

Create the recommended folder structure:

```bash
# Create directories
mkdir -p app components lib/{supabase,storage,hooks} types assets

# Create initial files
touch app/_layout.tsx
touch app/index.tsx
touch components/.gitkeep
touch lib/.gitkeep
touch types/index.ts
```

### Step 9: Create Root Layout

Set up Expo Router with a root layout:

```bash
cat > app/_layout.tsx << 'EOF'
import { Stack } from 'expo-router';
import { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';

export default function RootLayout() {
  useEffect(() => {
    console.log('🚀 MediaSocial - New Architecture Enabled');
    console.log('📱 React Native 0.82');
    console.log('🎯 Expo SDK 54');
  }, []);

  return (
    <>
      <StatusBar style="auto" />
      <Stack
        screenOptions={{
          headerStyle: {
            backgroundColor: '#007AFF',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: 'bold',
          },
        }}
      >
        <Stack.Screen
          name="index"
          options={{
            title: 'MediaSocial',
            headerShown: true,
          }}
        />
      </Stack>
    </>
  );
}
EOF
```

### Step 10: Create Home Screen

Create the main home screen:

```bash
cat > app/index.tsx << 'EOF'
import { View, Text, StyleSheet, Platform, Pressable } from 'react-native';
import { useEffect, useState } from 'react';

export default function HomeScreen() {
  const [architectureInfo, setArchitectureInfo] = useState<{
    isFabricEnabled: boolean;
    isTurboModuleEnabled: boolean;
    isHermesEnabled: boolean;
  }>({
    isFabricEnabled: false,
    isTurboModuleEnabled: false,
    isHermesEnabled: false,
  });

  useEffect(() => {
    // Check if Fabric is enabled
    const isFabric = !!(global as any).nativeFabricUIManager;

    // Check if TurboModules are enabled
    const isTurboModule = !!(global as any).__turboModuleProxy;

    // Check if Hermes is enabled
    const isHermes = !!(global as any).HermesInternal;

    setArchitectureInfo({
      isFabricEnabled: isFabric,
      isTurboModuleEnabled: isTurboModule,
      isHermesEnabled: isHermes,
    });

    console.log('Architecture Check:', {
      fabric: isFabric,
      turboModules: isTurboModule,
      hermes: isHermes,
    });
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>MediaSocial</Text>
        <Text style={styles.subtitle}>React Native 0.82 + Expo 54</Text>
      </View>

      <View style={styles.infoContainer}>
        <Text style={styles.sectionTitle}>New Architecture Status</Text>

        <ArchitectureItem
          label="Fabric Renderer"
          enabled={architectureInfo.isFabricEnabled}
          description="Synchronous UI rendering"
        />

        <ArchitectureItem
          label="TurboModules"
          enabled={architectureInfo.isTurboModuleEnabled}
          description="On-demand native modules"
        />

        <ArchitectureItem
          label="Hermes Engine"
          enabled={architectureInfo.isHermesEnabled}
          description="Optimized JavaScript engine"
        />
      </View>

      <View style={styles.platformInfo}>
        <Text style={styles.platformText}>
          Platform: {Platform.OS} {Platform.Version}
        </Text>
        <Text style={styles.platformText}>
          Environment: {__DEV__ ? 'Development' : 'Production'}
        </Text>
      </View>

      <Pressable
        style={({ pressed }) => [
          styles.button,
          pressed && styles.buttonPressed
        ]}
        onPress={() => console.log('Button pressed!')}
      >
        <Text style={styles.buttonText}>Test Interaction</Text>
      </Pressable>
    </View>
  );
}

interface ArchitectureItemProps {
  label: string;
  enabled: boolean;
  description: string;
}

function ArchitectureItem({ label, enabled, description }: ArchitectureItemProps) {
  return (
    <View style={styles.architectureItem}>
      <View style={styles.architectureHeader}>
        <Text style={styles.architectureLabel}>{label}</Text>
        <View style={[styles.badge, enabled ? styles.badgeEnabled : styles.badgeDisabled]}>
          <Text style={styles.badgeText}>{enabled ? '✓ Enabled' : '✗ Disabled'}</Text>
        </View>
      </View>
      <Text style={styles.architectureDescription}>{description}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginTop: 20,
    marginBottom: 30,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#007AFF',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  infoContainer: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 16,
    color: '#333',
  },
  architectureItem: {
    marginBottom: 20,
  },
  architectureHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  architectureLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  architectureDescription: {
    fontSize: 14,
    color: '#666',
  },
  badge: {
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  badgeEnabled: {
    backgroundColor: '#34C759',
  },
  badgeDisabled: {
    backgroundColor: '#FF3B30',
  },
  badgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  platformInfo: {
    marginTop: 20,
    padding: 16,
    backgroundColor: '#fff',
    borderRadius: 12,
  },
  platformText: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
  button: {
    marginTop: 20,
    backgroundColor: '#007AFF',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  buttonPressed: {
    opacity: 0.7,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
EOF
```

### Step 11: Update Package.json Scripts

Add useful scripts to package.json:

```bash
# This will be done manually - add these scripts to your package.json
npm pkg set scripts.start="expo start"
npm pkg set scripts.android="expo start --android"
npm pkg set scripts.ios="expo start --ios"
npm pkg set scripts.web="expo start --web"
npm pkg set scripts.lint="eslint . --ext .ts,.tsx"
npm pkg set scripts.lint:fix="eslint . --ext .ts,.tsx --fix"
npm pkg set scripts.format="prettier --write \"**/*.{ts,tsx,json,md}\""
npm pkg set scripts.type-check="tsc --noEmit"
```

### Step 12: Generate Native Projects (Prebuild)

Generate native iOS and Android projects:

```bash
# This creates ios/ and android/ folders with New Architecture enabled
npx expo prebuild --clean

# You should see output indicating New Architecture is enabled:
# ✓ iOS: newArchEnabled: true
# ✓ Android: newArchEnabled: true
```

---

## VERIFY: Testing Your Setup

### Step 1: Start the Development Server

```bash
# Start Expo development server
npm start

# You should see:
# › Metro waiting on exp://192.168.x.x:8081
# › Scan the QR code above with Expo Go (Android) or the Camera app (iOS)
```

### Step 2: Run on iOS Simulator (macOS only)

```bash
# Press 'i' in the terminal, or run:
npm run ios

# The iOS simulator should open and show your app
# Check the console logs for architecture verification
```

### Step 3: Run on Android Emulator

```bash
# Start an Android emulator from Android Studio, then:
# Press 'a' in the terminal, or run:
npm run android

# The app should install and launch on the emulator
```

### Step 4: Verify New Architecture

Open the app on your simulator/emulator and check:

1. **Visual Verification**: You should see three green badges:
   - ✓ Fabric Renderer: Enabled
   - ✓ TurboModules: Enabled
   - ✓ Hermes Engine: Enabled

2. **Console Verification**: Check the Metro bundler console:
```bash
# You should see logs like:
🚀 MediaSocial - New Architecture Enabled
📱 React Native 0.82
🎯 Expo SDK 54
Architecture Check: { fabric: true, turboModules: true, hermes: true }
```

3. **Test Interaction**: Press the "Test Interaction" button and verify:
   - Button responds instantly (Fabric's synchronous rendering)
   - Console shows "Button pressed!" log

### Step 5: Run Linting and Type Checking

```bash
# Check TypeScript types
npm run type-check
# Should complete with no errors

# Run ESLint
npm run lint
# Should show no errors (or only warnings)

# Format code
npm run format
# Should format all files
```

### Step 6: Test Hot Reload

1. With the app running, open `app/index.tsx`
2. Change the title text from "MediaSocial" to "MediaSocial 2.0"
3. Save the file
4. The app should update instantly without full reload (Fast Refresh)

---

## TROUBLESHOOTING

### Issue: "New Architecture not enabled"

**Solution 1**: Clear cache and rebuild
```bash
# Clear Expo cache
npx expo start --clear

# Clear Metro cache
rm -rf node_modules/.cache

# Rebuild native projects
npx expo prebuild --clean
```

**Solution 2**: Verify app.json configuration
```json
{
  "expo": {
    "ios": {
      "newArchEnabled": true
    },
    "android": {
      "newArchEnabled": true
    }
  }
}
```

### Issue: "Command PhaseScriptExecution failed" (iOS)

**Solution**: Clean build folder
```bash
cd ios
xcodebuild clean
cd ..
npx expo prebuild --clean
npm run ios
```

### Issue: "Android build failed"

**Solution**: Ensure correct Android SDK
```bash
# Open Android Studio
# Go to: Settings → Android SDK
# Ensure Android 14.0 (API 34) is installed
# Ensure Android SDK Build-Tools 34.0.0 is installed
```

### Issue: "Metro bundler port already in use"

**Solution**: Kill the process and restart
```bash
# Kill process on port 8081
lsof -ti:8081 | xargs kill -9

# Start again
npm start
```

### Issue: "Hermes not enabled"

**Solution**: Hermes is enabled by default in Expo SDK 54. If disabled:
```json
// app.json
{
  "expo": {
    "jsEngine": "hermes"
  }
}
```

### Issue: "Module not found" errors

**Solution**: Reinstall dependencies
```bash
# Remove node_modules and lockfile
rm -rf node_modules package-lock.json

# Clear npm cache
npm cache clean --force

# Reinstall
npm install

# Rebuild
npx expo prebuild --clean
```

---

## PERFORMANCE CHECK

### Verify New Architecture Benefits

Create a simple performance test:

```bash
cat > app/performance-test.tsx << 'EOF'
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { useState } from 'react';

export default function PerformanceTest() {
  const [count, setCount] = useState(0);
  const [startTime, setStartTime] = useState<number | null>(null);

  const handlePress = () => {
    const now = performance.now();
    if (startTime) {
      const latency = now - startTime;
      console.log(`Interaction latency: ${latency.toFixed(2)}ms`);
    }
    setCount(c => c + 1);
    setStartTime(now);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Performance Test</Text>
      <Text style={styles.count}>Count: {count}</Text>
      <Text style={styles.info}>
        With Fabric, each press should show &lt;16ms latency (60 FPS)
      </Text>
      <Pressable style={styles.button} onPress={handlePress}>
        <Text style={styles.buttonText}>Test Interaction Speed</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  count: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#007AFF',
    marginBottom: 10,
  },
  info: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    marginBottom: 30,
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 20,
    borderRadius: 12,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
EOF
```

Add the route to your layout and test interaction latency. With Fabric, you should see &lt;16ms consistently.

---

## KEY CONCEPTS RECAP

### 1. New Architecture Components
- **Fabric**: Synchronous UI renderer
- **TurboModules**: Lazy-loaded native modules
- **JSI**: JavaScript-to-C++ interface
- **Hermes**: Optimized JS engine

### 2. Expo Benefits
- Managed workflow with native access when needed
- File-based routing with Expo Router
- Over-the-air updates with EAS Update
- Simplified build process with EAS Build

### 3. Development Workflow
- Fast Refresh for instant updates
- TypeScript for type safety
- ESLint for code quality
- Prettier for consistent formatting

### 4. Performance Gains
- 9% faster bundle loads (Hermes V1)
- 7.6% faster TTI
- Synchronous rendering (Fabric)
- Lower memory footprint (TurboModules)

---

## NEXT STEPS

You now have a fully configured React Native 0.82 project with New Architecture enabled!

In **Lesson 2**, we'll implement navigation using Expo Router with:
- File-based routing
- Stack, tab, and drawer navigation
- Type-safe navigation
- Deep linking
- Protected routes

---

## ADDITIONAL RESOURCES

- [React Native New Architecture Docs](https://reactnative.dev/docs/new-architecture-intro)
- [Expo SDK 54 Docs](https://docs.expo.dev/)
- [Fabric Renderer Deep Dive](https://reactnative.dev/architecture/fabric-renderer)
- [TurboModules Explained](https://reactnative.dev/architecture/turbo-module)
- [Hermes Engine](https://hermesengine.dev/)

---

## CHECKPOINT

Before moving to Lesson 2, ensure:
- ✅ App runs on iOS simulator (macOS) or Android emulator
- ✅ All three architecture components show "Enabled"
- ✅ Hot reload works when editing files
- ✅ TypeScript compilation succeeds
- ✅ ESLint shows no errors
- ✅ You understand Fabric, TurboModules, and JSI concepts

**Congratulations!** You've successfully set up a React Native 0.82 project with New Architecture. You're ready to build modern, high-performance mobile apps! 🚀
