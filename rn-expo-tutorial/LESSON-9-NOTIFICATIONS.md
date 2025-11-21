# Lesson 9: Push Notifications

**Duration**: 75 minutes | **Difficulty**: Intermediate | **Prerequisites**: Lessons 1-8

## Learning Objectives
- Set up Expo push notifications
- Request notification permissions
- Handle notification interactions
- Implement deep linking from notifications
- Manage badge counts

## Installation

```bash
npx expo install expo-notifications expo-device expo-constants
```

## Implementation

### 1. Notification Setup

```typescript
// lib/notifications/setup.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { Platform } from 'react-native';

// Configure notification behavior
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export async function registerForPushNotificationsAsync(): Promise<string | undefined> {
  if (!Device.isDevice) {
    alert('Must use physical device for Push Notifications');
    return;
  }

  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') {
    alert('Failed to get push token for push notification!');
    return;
  }

  const projectId = Constants.expoConfig?.extra?.eas?.projectId;
  const token = await Notifications.getExpoPushTokenAsync({ projectId });

  if (Platform.OS === 'android') {
    Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: '#FF231F7C',
    });
  }

  return token.data;
}
```

### 2. Notification Listener

```typescript
// lib/notifications/listener.ts
import { useEffect, useRef } from 'react';
import * as Notifications from 'expo-notifications';
import { useRouter } from 'expo-router';

export function useNotifications() {
  const router = useRouter();
  const notificationListener = useRef<any>();
  const responseListener = useRef<any>();

  useEffect(() => {
    // Listen for notifications received while app is foregrounded
    notificationListener.current = Notifications.addNotificationReceivedListener(
      notification => {
        console.log('Notification received:', notification);
      }
    );

    // Listen for user tapping notification
    responseListener.current = Notifications.addNotificationResponseReceivedListener(
      response => {
        const data = response.notification.request.content.data;

        // Handle deep linking
        if (data.postId) {
          router.push(`/post/${data.postId}`);
        } else if (data.userId) {
          router.push(`/profile/${data.userId}`);
        }
      }
    );

    return () => {
      if (notificationListener.current) {
        Notifications.removeNotificationSubscription(notificationListener.current);
      }
      if (responseListener.current) {
        Notifications.removeNotificationSubscription(responseListener.current);
      }
    };
  }, []);
}
```

### 3. Send Notification (Backend Function)

```typescript
// Supabase Edge Function: send-notification
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

interface PushNotification {
  to: string;
  title: string;
  body: string;
  data?: any;
}

serve(async (req) => {
  const { to, title, body, data } = await req.json() as PushNotification;

  const message = {
    to,
    sound: 'default',
    title,
    body,
    data,
  };

  const response = await fetch('https://exp.host/--/api/v2/push/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'Accept-encoding': 'gzip, deflate',
    },
    body: JSON.stringify(message),
  });

  const result = await response.json();
  return new Response(JSON.stringify(result), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

### 4. Badge Management

```typescript
// lib/notifications/badge.ts
import * as Notifications from 'expo-notifications';

export async function setBadgeCount(count: number) {
  await Notifications.setBadgeCountAsync(count);
}

export async function clearBadge() {
  await Notifications.setBadgeCountAsync(0);
}

export async function incrementBadge() {
  const current = await Notifications.getBadgeCountAsync();
  await Notifications.setBadgeCountAsync(current + 1);
}
```

### 5. Notification Preferences UI

```typescript
// app/settings/notifications.tsx
import { useState, useEffect } from 'react';
import { View, Text, Switch, StyleSheet } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

export default function NotificationSettings() {
  const [likesEnabled, setLikesEnabled] = useState(true);
  const [commentsEnabled, setCommentsEnabled] = useState(true);
  const [followsEnabled, setFollowsEnabled] = useState(true);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    const likes = await AsyncStorage.getItem('notif_likes');
    const comments = await AsyncStorage.getItem('notif_comments');
    const follows = await AsyncStorage.getItem('notif_follows');

    if (likes !== null) setLikesEnabled(likes === 'true');
    if (comments !== null) setCommentsEnabled(comments === 'true');
    if (follows !== null) setFollowsEnabled(follows === 'true');
  };

  const updateSetting = async (key: string, value: boolean) => {
    await AsyncStorage.setItem(key, value.toString());
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Notification Preferences</Text>

      <View style={styles.setting}>
        <Text style={styles.label}>Likes</Text>
        <Switch
          value={likesEnabled}
          onValueChange={(val) => {
            setLikesEnabled(val);
            updateSetting('notif_likes', val);
          }}
        />
      </View>

      <View style={styles.setting}>
        <Text style={styles.label}>Comments</Text>
        <Switch
          value={commentsEnabled}
          onValueChange={(val) => {
            setCommentsEnabled(val);
            updateSetting('notif_comments', val);
          }}
        />
      </View>

      <View style={styles.setting}>
        <Text style={styles.label}>New Followers</Text>
        <Switch
          value={followsEnabled}
          onValueChange={(val) => {
            setFollowsEnabled(val);
            updateSetting('notif_follows', val);
          }}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  setting: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5EA',
  },
  label: {
    fontSize: 16,
    color: '#000',
  },
});
```

### 6. Notification Types

```typescript
// lib/notifications/types.ts
export enum NotificationType {
  LIKE = 'like',
  COMMENT = 'comment',
  FOLLOW = 'follow',
  MENTION = 'mention',
}

export async function sendLikeNotification(
  toUserId: string,
  fromUsername: string,
  postId: string
) {
  // Call your backend to send notification
  await fetch(`${API_URL}/notifications/send`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId: toUserId,
      type: NotificationType.LIKE,
      title: 'New Like',
      body: `${fromUsername} liked your post`,
      data: { postId },
    }),
  });
}
```

## Key Features Implemented
✅ Push notification registration
✅ Foreground & background notifications
✅ Deep linking from notifications
✅ Badge count management
✅ Notification preferences
✅ Multiple notification types

## Best Practices
1. Always request permission at appropriate time
2. Use notification channels on Android
3. Implement deep linking for all notification types
4. Allow users to customize preferences
5. Clear badge count when appropriate
6. Test on physical devices only

## Testing Checklist
- [ ] Notifications received in foreground
- [ ] Notifications received in background
- [ ] Tapping notification opens correct screen
- [ ] Badge count updates correctly
- [ ] Preferences save correctly
- [ ] Works on iOS and Android

## Next: Lesson 10 - Offline Support & Storage 💾
