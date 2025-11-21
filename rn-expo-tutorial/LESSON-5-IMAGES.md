# Lesson 5: Image Handling & Camera

**Duration**: 80 minutes | **Difficulty**: Intermediate | **Prerequisites**: Lessons 1-4

## Learning Objectives
- Implement camera capture with expo-camera
- Use expo-image-picker for gallery selection
- Optimize images before upload
- Upload to Supabase Storage
- Display with expo-image caching

## Key Technologies
- **expo-camera**: Camera access
- **expo-image-picker**: Gallery picker
- **expo-image**: Optimized image component
- **expo-image-manipulator**: Image resizing/compression
- **Supabase Storage**: Cloud image storage

## Installation

```bash
npx expo install expo-camera expo-image-picker expo-image expo-image-manipulator expo-file-system
```

## Implementation Overview

### 1. Camera Permission Setup

```typescript
// lib/permissions/camera.ts
import { Camera } from 'expo-camera';
import * as ImagePicker from 'expo-image-picker';
import { Alert, Platform } from 'react-native';

export async function requestCameraPermission() {
  const { status } = await Camera.requestCameraPermissionsAsync();
  if (status !== 'granted') {
    Alert.alert('Permission denied', 'Camera access is required');
    return false;
  }
  return true;
}

export async function requestMediaLibraryPermission() {
  if (Platform.OS !== 'web') {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission denied', 'Gallery access is required');
      return false;
    }
  }
  return true;
}
```

### 2. Image Capture Component

```typescript
// components/media/ImageCapture.tsx
import { CameraView, useCameraPermissions } from 'expo-camera';
import { useState, useRef } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

export function ImageCapture({ onCapture }: { onCapture: (uri: string) => void }) {
  const [permission, requestPermission] = useCameraPermissions();
  const cameraRef = useRef<CameraView>(null);
  const [facing, setFacing] = useState<'front' | 'back'>('back');

  if (!permission?.granted) {
    return <Pressable onPress={requestPermission}><Text>Enable Camera</Text></Pressable>;
  }

  const takePicture = async () => {
    if (cameraRef.current) {
      const photo = await cameraRef.current.takePictureAsync();
      if (photo) onCapture(photo.uri);
    }
  };

  return (
    <View style={styles.container}>
      <CameraView ref={cameraRef} style={styles.camera} facing={facing}>
        <View style={styles.controls}>
          <Pressable onPress={() => setFacing(f => f === 'back' ? 'front' : 'back')}>
            <Ionicons name="camera-reverse" size={32} color="#fff" />
          </Pressable>
          <Pressable onPress={takePicture} style={styles.captureButton}>
            <View style={styles.captureInner} />
          </Pressable>
        </View>
      </CameraView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  camera: { flex: 1 },
  controls: {
    position: 'absolute',
    bottom: 40,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
  },
  captureButton: {
    width: 70,
    height: 70,
    borderRadius: 35,
    backgroundColor: 'rgba(255,255,255,0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  captureInner: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#fff',
  },
});
```

### 3. Image Picker

```typescript
// lib/media/image-picker.ts
import * as ImagePicker from 'expo-image-picker';
import * as ImageManipulator from 'expo-image-manipulator';

export async function pickImage() {
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    allowsEditing: true,
    aspect: [4, 3],
    quality: 0.8,
  });

  if (!result.canceled && result.assets[0]) {
    return result.assets[0].uri;
  }
  return null;
}

export async function optimizeImage(uri: string) {
  const manipResult = await ImageManipulator.manipulateAsync(
    uri,
    [{ resize: { width: 1080 } }],
    { compress: 0.7, format: ImageManipulator.SaveFormat.JPEG }
  );
  return manipResult.uri;
}
```

### 4. Upload to Supabase Storage

```typescript
// lib/storage/images.ts
import { supabase } from '../supabase/client';
import * as FileSystem from 'expo-file-system';
import { decode } from 'base64-arraybuffer';

export async function uploadImage(uri: string, userId: string): Promise<string> {
  const base64 = await FileSystem.readAsStringAsync(uri, {
    encoding: FileSystem.EncodingType.Base64,
  });

  const fileName = `${userId}/${Date.now()}.jpg`;
  const { data, error } = await supabase.storage
    .from('images')
    .upload(fileName, decode(base64), {
      contentType: 'image/jpeg',
    });

  if (error) throw error;

  const { data: { publicUrl } } = supabase.storage
    .from('images')
    .getPublicUrl(fileName);

  return publicUrl;
}
```

### 5. Update Post Creation with Images

```typescript
// Update app/modal/compose.tsx to include image handling
import { pickImage, optimizeImage } from '@/lib/media/image-picker';
import { uploadImage } from '@/lib/storage/images';
import { Image } from 'expo-image';

// Add state
const [imageUri, setImageUri] = useState<string | null>(null);
const [uploading, setUploading] = useState(false);

const handlePickImage = async () => {
  const uri = await pickImage();
  if (uri) {
    const optimized = await optimizeImage(uri);
    setImageUri(optimized);
  }
};

const handlePost = async () => {
  setPosting(true);
  try {
    let mediaUrl = null;

    if (imageUri) {
      setUploading(true);
      mediaUrl = await uploadImage(imageUri, user!.id);
      setUploading(false);
    }

    await createPost({
      user_id: user!.id,
      content: content.trim(),
      media_url: mediaUrl,
      media_type: mediaUrl ? 'image' : null,
    });

    router.back();
  } catch (error: any) {
    Alert.alert('Error', error.message);
  } finally {
    setPosting(false);
  }
};
```

### 6. Optimized Image Display

```typescript
// components/media/OptimizedImage.tsx
import { Image } from 'expo-image';
import { StyleSheet } from 'react-native';

export function OptimizedImage({ uri }: { uri: string }) {
  return (
    <Image
      source={{ uri }}
      style={styles.image}
      contentFit="cover"
      transition={200}
      cachePolicy="memory-disk"
    />
  );
}

const styles = StyleSheet.create({
  image: {
    width: '100%',
    aspectRatio: 4 / 3,
    borderRadius: 12,
  },
});
```

## Key Features Implemented
✅ Camera capture with front/back toggle
✅ Gallery image picker
✅ Image optimization (resize + compress)
✅ Upload to Supabase Storage
✅ Cached image display with expo-image
✅ Local-first with sync queue

## Best Practices
1. Always request permissions before accessing camera/gallery
2. Optimize images before upload to save bandwidth
3. Use expo-image for automatic caching
4. Store image URLs in local database
5. Queue uploads for offline scenarios

## Testing Checklist
- [ ] Camera opens and captures photos
- [ ] Gallery picker selects images
- [ ] Images are optimized before upload
- [ ] Images display with caching
- [ ] Works offline (queues upload)

## Next: Lesson 6 - Audio Features with expo-audio 🎵
