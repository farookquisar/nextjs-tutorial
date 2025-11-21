# Lesson 2: Navigation with Expo Router

**Duration**: 75 minutes
**Difficulty**: Beginner to Intermediate
**Prerequisites**: Completed Lesson 1

## Learning Objectives

By the end of this lesson, you will:
- Understand file-based routing with Expo Router
- Implement stack, tab, and modal navigation
- Create type-safe navigation with TypeScript
- Set up deep linking for your app
- Implement navigation guards for protected routes
- Use layout groups and shared layouts

---

## DESCRIBE: Understanding Expo Router

### What is Expo Router?

Expo Router brings Next.js-style file-based routing to React Native. Instead of manually configuring navigation stacks, your file structure defines your routes.

**Traditional React Navigation**:
```typescript
// Lots of boilerplate code
const Stack = createNativeStackNavigator();

function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Profile" component={ProfileScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

**Expo Router**:
```
app/
├── index.tsx           → / (home route)
├── profile.tsx         → /profile
└── settings.tsx        → /settings
```

### Key Features

1. **File-Based Routing**: File structure = route structure
2. **Type Safety**: Auto-generated typed routes
3. **Deep Linking**: Automatic URL handling
4. **Layouts**: Shared UI across routes
5. **Groups**: Organize routes without affecting URLs
6. **Dynamic Routes**: `[id].tsx` for dynamic segments
7. **API Routes**: Build backend endpoints (expo-server)

### Navigation Patterns

#### 1. Stack Navigation
Linear navigation flow (push/pop):
```
Home → Details → Settings
  ←       ←
```

#### 2. Tab Navigation
Persistent bottom tabs:
```
┌─────────────────────┐
│   Content Area      │
│                     │
├─────┬─────┬─────────┤
│ 🏠  │ 🔍  │  👤    │
│Home │Explore│Profile│
└─────┴─────┴─────────┘
```

#### 3. Drawer Navigation
Side menu:
```
┌──────────┐┌────────┐
│ Menu     ││ Main   │
│ - Home   ││ Content│
│ - Profile││        │
└──────────┘└────────┘
```

#### 4. Modal Navigation
Overlay screens:
```
┌─────────────────┐
│   Main Screen   │
│  ┌───────────┐  │
│  │   Modal   │  │
│  │           │  │
│  └───────────┘  │
└─────────────────┘
```

### Best Practices for Mobile Navigation

1. **Keep navigation shallow** - Max 3-4 levels deep
2. **Use tabs for primary sections** - Easy thumb access
3. **Stack for hierarchical content** - Drill-down patterns
4. **Modals for temporary tasks** - Forms, confirmations
5. **Gestures matter** - Swipe back, pull to dismiss

---

## CODE: Implementing Navigation

### Step 1: Install Navigation Dependencies

```bash
# Install Expo Router and dependencies
npx expo install expo-router react-native-safe-area-context react-native-screens expo-linking expo-constants expo-status-bar

# Install gesture handler for swipe gestures
npx expo install react-native-gesture-handler

# Install reanimated for smooth animations
npx expo install react-native-reanimated
```

### Step 2: Configure Expo Router

Update your app.json:

```bash
cat > app.json << 'EOF'
{
  "expo": {
    "name": "MediaSocial",
    "slug": "mediasocial",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "scheme": "mediasocial",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "assetBundlePatterns": ["**/*"],
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
    "plugins": [
      "expo-router",
      [
        "expo-build-properties",
        {
          "ios": {
            "newArchEnabled": true
          },
          "android": {
            "newArchEnabled": true
          }
        }
      ]
    ],
    "experiments": {
      "typedRoutes": true
    }
  }
}
EOF
```

### Step 3: Set Up Project Structure

Create the recommended Expo Router structure:

```bash
# Remove old app files
rm -f app/_layout.tsx app/index.tsx

# Create new structure
mkdir -p app/{(auth),(tabs),modal}
mkdir -p components/{ui,navigation}
mkdir -p lib/navigation

# Create route files
touch app/_layout.tsx
touch app/(tabs)/_layout.tsx
touch app/(tabs)/index.tsx
touch app/(tabs)/explore.tsx
touch app/(tabs)/profile.tsx
touch app/(auth)/_layout.tsx
touch app/(auth)/login.tsx
touch app/(auth)/signup.tsx
touch app/modal/compose.tsx
touch app/+not-found.tsx
```

### Step 4: Create Root Layout

The root layout wraps all routes:

```bash
cat > app/_layout.tsx << 'EOF'
import { Stack } from 'expo-router';
import { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

export default function RootLayout() {
  useEffect(() => {
    console.log('🚀 App initialized with Expo Router');
  }, []);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <Stack
        screenOptions={{
          headerStyle: {
            backgroundColor: '#007AFF',
          },
          headerTintColor: '#fff',
          headerTitleStyle: {
            fontWeight: '600',
          },
          animation: 'slide_from_right',
        }}
      >
        {/* Main app tabs */}
        <Stack.Screen
          name="(tabs)"
          options={{
            headerShown: false,
          }}
        />

        {/* Auth screens */}
        <Stack.Screen
          name="(auth)"
          options={{
            headerShown: false,
            presentation: 'modal',
          }}
        />

        {/* Modal screens */}
        <Stack.Screen
          name="modal/compose"
          options={{
            presentation: 'modal',
            title: 'New Post',
            headerLeft: () => null,
          }}
        />

        {/* 404 screen */}
        <Stack.Screen
          name="+not-found"
          options={{
            title: 'Not Found',
          }}
        />
      </Stack>
    </GestureHandlerRootView>
  );
}
EOF
```

### Step 5: Create Tab Layout

Set up bottom tabs for main navigation:

```bash
cat > app/'(tabs)'/_layout.tsx << 'EOF'
import { Tabs } from 'expo-router';
import { Platform } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerStyle: {
          backgroundColor: '#007AFF',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: '600',
        },
        tabBarActiveTintColor: '#007AFF',
        tabBarInactiveTintColor: '#8E8E93',
        tabBarStyle: {
          backgroundColor: '#fff',
          borderTopWidth: 1,
          borderTopColor: '#E5E5EA',
          paddingBottom: Platform.OS === 'ios' ? 20 : 10,
          height: Platform.OS === 'ios' ? 85 : 65,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '500',
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="explore"
        options={{
          title: 'Explore',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="search" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="person" size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
EOF
```

### Step 6: Create Home Screen

```bash
cat > app/'(tabs)'/index.tsx << 'EOF'
import { View, Text, StyleSheet, Pressable, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function HomeScreen() {
  const router = useRouter();

  const handleComposePress = () => {
    router.push('/modal/compose');
  };

  const handleNavigateToPost = (id: number) => {
    // We'll implement dynamic routes in the next section
    console.log('Navigate to post:', id);
  };

  return (
    <View style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.title}>Feed</Text>
          <Text style={styles.subtitle}>
            Stay connected with your friends
          </Text>
        </View>

        {/* Mock posts */}
        {[1, 2, 3, 4, 5].map(id => (
          <Pressable
            key={id}
            style={({ pressed }) => [
              styles.postCard,
              pressed && styles.postCardPressed,
            ]}
            onPress={() => handleNavigateToPost(id)}
          >
            <View style={styles.postHeader}>
              <View style={styles.avatar}>
                <Text style={styles.avatarText}>U{id}</Text>
              </View>
              <View style={styles.postInfo}>
                <Text style={styles.username}>User {id}</Text>
                <Text style={styles.timestamp}>2 hours ago</Text>
              </View>
            </View>
            <Text style={styles.postContent}>
              This is a sample post content. In the next lessons, we'll
              implement local-first CRUD with SQLite for offline support.
            </Text>
            <View style={styles.postActions}>
              <PostAction icon="heart-outline" count={42} />
              <PostAction icon="chatbubble-outline" count={8} />
              <PostAction icon="share-outline" count={3} />
            </View>
          </Pressable>
        ))}
      </ScrollView>

      {/* Floating action button */}
      <Pressable
        style={({ pressed }) => [
          styles.fab,
          pressed && styles.fabPressed,
        ]}
        onPress={handleComposePress}
      >
        <Ionicons name="add" size={28} color="#fff" />
      </Pressable>
    </View>
  );
}

function PostAction({ icon, count }: { icon: any; count: number }) {
  return (
    <Pressable style={styles.actionButton}>
      <Ionicons name={icon} size={20} color="#8E8E93" />
      <Text style={styles.actionCount}>{count}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 80,
  },
  header: {
    padding: 20,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#8E8E93',
  },
  postCard: {
    backgroundColor: '#fff',
    marginTop: 12,
    padding: 16,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#E5E5EA',
  },
  postCardPressed: {
    opacity: 0.7,
  },
  postHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 14,
  },
  postInfo: {
    marginLeft: 12,
    flex: 1,
  },
  username: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
  },
  timestamp: {
    fontSize: 13,
    color: '#8E8E93',
    marginTop: 2,
  },
  postContent: {
    fontSize: 15,
    lineHeight: 21,
    color: '#000',
    marginBottom: 12,
  },
  postActions: {
    flexDirection: 'row',
    gap: 20,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  actionCount: {
    fontSize: 14,
    color: '#8E8E93',
  },
  fab: {
    position: 'absolute',
    right: 20,
    bottom: 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  fabPressed: {
    transform: [{ scale: 0.95 }],
  },
});
EOF
```

### Step 7: Create Explore Screen

```bash
cat > app/'(tabs)'/explore.tsx << 'EOF'
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  ScrollView,
  Pressable,
} from 'react-native';
import { useState } from 'react';
import { Ionicons } from '@expo/vector-icons';

export default function ExploreScreen() {
  const [searchQuery, setSearchQuery] = useState('');

  const categories = [
    { id: 1, name: 'Technology', icon: 'laptop' as const, color: '#007AFF' },
    { id: 2, name: 'Travel', icon: 'airplane' as const, color: '#34C759' },
    { id: 3, name: 'Food', icon: 'restaurant' as const, color: '#FF9500' },
    { id: 4, name: 'Music', icon: 'musical-notes' as const, color: '#AF52DE' },
    { id: 5, name: 'Sports', icon: 'football' as const, color: '#FF3B30' },
    { id: 6, name: 'Art', icon: 'color-palette' as const, color: '#FF2D55' },
  ];

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      <View style={styles.searchContainer}>
        <View style={styles.searchBar}>
          <Ionicons name="search" size={20} color="#8E8E93" />
          <TextInput
            style={styles.searchInput}
            placeholder="Search posts, users, topics..."
            value={searchQuery}
            onChangeText={setSearchQuery}
            placeholderTextColor="#8E8E93"
          />
          {searchQuery.length > 0 && (
            <Pressable onPress={() => setSearchQuery('')}>
              <Ionicons name="close-circle" size={20} color="#8E8E93" />
            </Pressable>
          )}
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Categories</Text>
        <View style={styles.categoriesGrid}>
          {categories.map(category => (
            <Pressable
              key={category.id}
              style={({ pressed }) => [
                styles.categoryCard,
                { backgroundColor: category.color },
                pressed && styles.categoryCardPressed,
              ]}
            >
              <Ionicons name={category.icon} size={32} color="#fff" />
              <Text style={styles.categoryName}>{category.name}</Text>
            </Pressable>
          ))}
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Trending Topics</Text>
        {['React Native', 'Expo 54', 'Mobile Dev', 'TypeScript', 'UI Design'].map(
          (topic, index) => (
            <Pressable
              key={index}
              style={({ pressed }) => [
                styles.topicCard,
                pressed && styles.topicCardPressed,
              ]}
            >
              <View style={styles.topicInfo}>
                <Text style={styles.topicName}>#{topic}</Text>
                <Text style={styles.topicCount}>
                  {Math.floor(Math.random() * 1000)} posts
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={20} color="#8E8E93" />
            </Pressable>
          )
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  searchContainer: {
    padding: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F2F2F7',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: '#000',
  },
  section: {
    marginTop: 20,
    paddingHorizontal: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#000',
    marginBottom: 12,
  },
  categoriesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  categoryCard: {
    width: '47%',
    aspectRatio: 1.5,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
  },
  categoryCardPressed: {
    opacity: 0.8,
  },
  categoryName: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  topicCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 12,
    marginBottom: 8,
  },
  topicCardPressed: {
    opacity: 0.7,
  },
  topicInfo: {
    flex: 1,
  },
  topicName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000',
    marginBottom: 4,
  },
  topicCount: {
    fontSize: 13,
    color: '#8E8E93',
  },
});
EOF
```

### Step 8: Create Profile Screen

```bash
cat > app/'(tabs)'/profile.tsx << 'EOF'
import { View, Text, StyleSheet, Pressable, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function ProfileScreen() {
  const router = useRouter();

  const stats = [
    { label: 'Posts', value: '42' },
    { label: 'Followers', value: '1.2K' },
    { label: 'Following', value: '384' },
  ];

  const menuItems = [
    { icon: 'settings-outline' as const, label: 'Settings', route: '/settings' },
    { icon: 'bookmark-outline' as const, label: 'Saved Posts', route: '/saved' },
    { icon: 'notifications-outline' as const, label: 'Notifications', route: '/notifications' },
    { icon: 'help-circle-outline' as const, label: 'Help & Support', route: '/help' },
  ];

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      <View style={styles.profileHeader}>
        <View style={styles.avatarContainer}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>JD</Text>
          </View>
          <Pressable style={styles.editButton}>
            <Ionicons name="camera" size={20} color="#007AFF" />
          </Pressable>
        </View>

        <Text style={styles.name}>John Doe</Text>
        <Text style={styles.username}>@johndoe</Text>
        <Text style={styles.bio}>
          Mobile developer • React Native enthusiast • Building cool stuff
        </Text>

        <View style={styles.statsContainer}>
          {stats.map((stat, index) => (
            <View key={index} style={styles.statItem}>
              <Text style={styles.statValue}>{stat.value}</Text>
              <Text style={styles.statLabel}>{stat.label}</Text>
            </View>
          ))}
        </View>

        <Pressable style={styles.editProfileButton}>
          <Text style={styles.editProfileText}>Edit Profile</Text>
        </Pressable>
      </View>

      <View style={styles.menuSection}>
        {menuItems.map((item, index) => (
          <Pressable
            key={index}
            style={({ pressed }) => [
              styles.menuItem,
              pressed && styles.menuItemPressed,
            ]}
            onPress={() => {
              // We'll implement these routes later
              console.log('Navigate to:', item.route);
            }}
          >
            <View style={styles.menuItemLeft}>
              <Ionicons name={item.icon} size={24} color="#007AFF" />
              <Text style={styles.menuItemText}>{item.label}</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color="#8E8E93" />
          </Pressable>
        ))}
      </View>

      <Pressable style={styles.logoutButton}>
        <Ionicons name="log-out-outline" size={20} color="#FF3B30" />
        <Text style={styles.logoutText}>Log Out</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  profileHeader: {
    backgroundColor: '#fff',
    padding: 20,
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
  },
  avatarContainer: {
    position: 'relative',
    marginBottom: 16,
  },
  avatar: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    color: '#fff',
    fontSize: 36,
    fontWeight: '600',
  },
  editButton: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#007AFF',
  },
  name: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 4,
  },
  username: {
    fontSize: 16,
    color: '#8E8E93',
    marginBottom: 12,
  },
  bio: {
    fontSize: 14,
    color: '#000',
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 20,
  },
  statsContainer: {
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-around',
    marginBottom: 20,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#E5E5EA',
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 13,
    color: '#8E8E93',
  },
  editProfileButton: {
    width: '100%',
    paddingVertical: 12,
    backgroundColor: '#007AFF',
    borderRadius: 10,
    alignItems: 'center',
  },
  editProfileText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  menuSection: {
    backgroundColor: '#fff',
    marginTop: 20,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#E5E5EA',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
  },
  menuItemPressed: {
    backgroundColor: '#F2F2F7',
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  menuItemText: {
    fontSize: 16,
    color: '#000',
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginTop: 20,
    marginHorizontal: 20,
    marginBottom: 40,
    padding: 16,
    backgroundColor: '#fff',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#FF3B30',
  },
  logoutText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FF3B30',
  },
});
EOF
```

### Step 9: Create Modal Screen for Composing Posts

```bash
cat > app/modal/compose.tsx << 'EOF'
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  Pressable,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useState } from 'react';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function ComposeModal() {
  const router = useRouter();
  const [content, setContent] = useState('');

  const handlePost = () => {
    if (content.trim()) {
      // In Lesson 4, we'll save this to local SQLite database
      console.log('Post content:', content);
      router.back();
    }
  };

  const handleCancel = () => {
    router.back();
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <View style={styles.header}>
        <Pressable onPress={handleCancel} style={styles.cancelButton}>
          <Text style={styles.cancelText}>Cancel</Text>
        </Pressable>
        <Pressable
          onPress={handlePost}
          style={[
            styles.postButton,
            !content.trim() && styles.postButtonDisabled,
          ]}
          disabled={!content.trim()}
        >
          <Text
            style={[
              styles.postButtonText,
              !content.trim() && styles.postButtonTextDisabled,
            ]}
          >
            Post
          </Text>
        </Pressable>
      </View>

      <View style={styles.content}>
        <View style={styles.userInfo}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>JD</Text>
          </View>
          <View style={styles.composing}>
            <TextInput
              style={styles.input}
              placeholder="What's on your mind?"
              value={content}
              onChangeText={setContent}
              multiline
              autoFocus
              maxLength={500}
              placeholderTextColor="#8E8E93"
            />
          </View>
        </View>

        <View style={styles.footer}>
          <View style={styles.actions}>
            <Pressable style={styles.actionButton}>
              <Ionicons name="image-outline" size={24} color="#007AFF" />
            </Pressable>
            <Pressable style={styles.actionButton}>
              <Ionicons name="videocam-outline" size={24} color="#007AFF" />
            </Pressable>
            <Pressable style={styles.actionButton}>
              <Ionicons name="mic-outline" size={24} color="#007AFF" />
            </Pressable>
            <Pressable style={styles.actionButton}>
              <Ionicons name="location-outline" size={24} color="#007AFF" />
            </Pressable>
          </View>
          <Text style={styles.characterCount}>
            {content.length}/500
          </Text>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
  },
  cancelButton: {
    padding: 8,
  },
  cancelText: {
    fontSize: 16,
    color: '#007AFF',
  },
  postButton: {
    paddingHorizontal: 20,
    paddingVertical: 8,
    backgroundColor: '#007AFF',
    borderRadius: 20,
  },
  postButtonDisabled: {
    backgroundColor: '#E5E5EA',
  },
  postButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  postButtonTextDisabled: {
    color: '#8E8E93',
  },
  content: {
    flex: 1,
  },
  userInfo: {
    flexDirection: 'row',
    padding: 16,
    gap: 12,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  composing: {
    flex: 1,
  },
  input: {
    fontSize: 16,
    lineHeight: 22,
    color: '#000',
    minHeight: 100,
  },
  footer: {
    borderTopWidth: 1,
    borderTopColor: '#E5E5EA',
    padding: 16,
    gap: 12,
  },
  actions: {
    flexDirection: 'row',
    gap: 16,
  },
  actionButton: {
    padding: 8,
  },
  characterCount: {
    fontSize: 13,
    color: '#8E8E93',
    textAlign: 'right',
  },
});
EOF
```

### Step 10: Create 404 Screen

```bash
cat > app/+not-found.tsx << 'EOF'
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function NotFoundScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <Ionicons name="warning-outline" size={80} color="#FF9500" />
      <Text style={styles.title}>Page Not Found</Text>
      <Text style={styles.message}>
        The page you're looking for doesn't exist or has been moved.
      </Text>
      <Pressable
        style={styles.button}
        onPress={() => router.replace('/')}
      >
        <Text style={styles.buttonText}>Go to Home</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#000',
    marginTop: 20,
    marginBottom: 12,
  },
  message: {
    fontSize: 16,
    color: '#8E8E93',
    textAlign: 'center',
    marginBottom: 30,
    lineHeight: 22,
  },
  button: {
    paddingHorizontal: 30,
    paddingVertical: 14,
    backgroundColor: '#007AFF',
    borderRadius: 10,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
EOF
```

### Step 11: Update Metro Config for Expo Router

```bash
cat > metro.config.js << 'EOF'
const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// Enable CSS support
config.resolver.sourceExts.push('css');

module.exports = config;
EOF
```

### Step 12: Update Babel Config

```bash
cat > babel.config.js << 'EOF'
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      'react-native-reanimated/plugin',
      'expo-router/babel',
    ],
  };
};
EOF
```

---

## VERIFY: Testing Navigation

### Step 1: Start the Development Server

```bash
# Clear cache and start fresh
npx expo start --clear

# Or press 'i' for iOS, 'a' for Android
npm run ios
# or
npm run android
```

### Step 2: Test Tab Navigation

1. App should open on the Home tab
2. Tap the Explore tab - should navigate smoothly
3. Tap the Profile tab - should navigate smoothly
4. Notice the smooth tab transitions (Fabric renderer)

### Step 3: Test Modal Navigation

1. On the Home screen, tap the blue floating action button (+)
2. Compose modal should slide up from bottom
3. Try typing in the text field
4. Tap "Cancel" to dismiss the modal
5. Modal should slide down smoothly

### Step 4: Test Swipe Gestures

iOS:
- Swipe from left edge to go back (should work in modals)

Android:
- Press hardware back button or use gesture navigation

### Step 5: Verify Type Safety

Create a test file to verify typed routes:

```bash
cat > test-typed-routes.ts << 'EOF'
import { useRouter } from 'expo-router';

// This file tests type safety at compile time
function testTypedRoutes() {
  const router = useRouter();

  // These should work (valid routes)
  router.push('/');
  router.push('/(tabs)/explore');
  router.push('/modal/compose');

  // These should show TypeScript errors (invalid routes)
  // Uncomment to test:
  // router.push('/invalid-route');
  // router.push('/does-not-exist');
}
EOF
```

Run type check:
```bash
npm run type-check
```

### Step 6: Test Deep Linking

```bash
# Test deep linking (with app running)

# iOS Simulator
xcrun simctl openurl booted mediasocial://

# Android Emulator
adb shell am start -W -a android.intent.action.VIEW -d "mediasocial://"

# Specific route
xcrun simctl openurl booted mediasocial://explore
```

---

## TROUBLESHOOTING

### Issue: "Cannot find module 'expo-router'"

**Solution**:
```bash
npx expo install expo-router
npx expo prebuild --clean
```

### Issue: Tabs not showing icons

**Solution**: Install vector icons
```bash
npx expo install @expo/vector-icons
```

### Issue: Modal doesn't dismiss on iOS

**Solution**: Ensure GestureHandlerRootView wraps your root layout:
```tsx
import { GestureHandlerRootView } from 'react-native-gesture-handler';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      {/* Your navigation */}
    </GestureHandlerRootView>
  );
}
```

### Issue: TypeScript errors with routes

**Solution**: Regenerate typed routes
```bash
npx expo customize tsconfig.json
npm run type-check
```

### Issue: Navigtion animations are choppy

**Solution**: Ensure reanimated plugin is last in babel.config.js:
```javascript
plugins: [
  'expo-router/babel',
  'react-native-reanimated/plugin', // Must be last!
],
```

---

## BEST PRACTICES

### 1. Navigation Structure
```
app/
├── _layout.tsx           # Root layout
├── (tabs)/              # Tab navigation group
│   ├── _layout.tsx
│   └── index.tsx
├── (auth)/              # Auth flow group
│   ├── _layout.tsx
│   └── login.tsx
└── modal/              # Modal screens
    └── compose.tsx
```

### 2. Use Typed Navigation
```typescript
import { useRouter, useLocalSearchParams } from 'expo-router';

function MyScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();

  // Type-safe navigation
  router.push('/(tabs)/explore');
}
```

### 3. Loading States
```typescript
import { useSegments, useRouter } from 'expo-router';
import { useEffect } from 'react';

function useProtectedRoute(user: User | null) {
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    const inAuthGroup = segments[0] === '(auth)';

    if (!user && !inAuthGroup) {
      router.replace('/(auth)/login');
    } else if (user && inAuthGroup) {
      router.replace('/(tabs)');
    }
  }, [user, segments]);
}
```

### 4. Deep Linking Best Practices
- Use clear, semantic URLs: `mediasocial://post/123`
- Handle invalid links gracefully
- Test on both platforms
- Document your URL scheme

---

## KEY CONCEPTS RECAP

### 1. Expo Router Benefits
- File-based routing (like Next.js)
- Automatic deep linking
- Type-safe navigation
- Shared layouts
- Easy navigation patterns

### 2. Navigation Patterns Implemented
- ✅ Stack navigation
- ✅ Tab navigation
- ✅ Modal presentation
- ✅ 404 handling
- ✅ Deep linking ready

### 3. Performance with New Architecture
- Fabric enables smooth gesture handling
- Synchronous layout calculations
- 60 FPS tab switches
- Instant modal animations

---

## NEXT STEPS

In **Lesson 3**, we'll implement:
- Authentication with Supabase
- Secure token storage
- Protected routes with navigation guards
- OAuth with Google and Apple Sign-In
- User profile management

---

## ADDITIONAL RESOURCES

- [Expo Router Docs](https://docs.expo.dev/routing/introduction/)
- [React Navigation Docs](https://reactnavigation.org/)
- [Deep Linking Guide](https://docs.expo.dev/guides/linking/)
- [Navigation Patterns](https://reactnavigation.org/docs/navigating/)

---

## CHECKPOINT

Before moving to Lesson 3, ensure:
- ✅ All three tabs navigate correctly
- ✅ Compose modal opens and closes smoothly
- ✅ Swipe back gestures work (iOS)
- ✅ Type checking passes with no errors
- ✅ Deep links work for your app scheme
- ✅ You understand Expo Router file structure

**Great work!** You now have a fully functional navigation system. Next, we'll add authentication! 🚀
