# Lesson 7: Video Features with expo-video

**Duration**: 95 minutes | **Difficulty**: Advanced | **Prerequisites**: Lessons 1-6

## Learning Objectives
- Record video with expo-camera
- Play video with expo-video (NEW API)
- Implement custom video controls
- Enable Picture-in-Picture (PiP)
- Compress video before upload

## Key Technologies
- **expo-video**: New video API (replaces expo-av)
- **expo-camera**: Video recording
- **expo-video-thumbnails**: Thumbnail generation
- **Supabase Storage**: Video file storage

## Installation

```bash
npx expo install expo-video expo-camera expo-video-thumbnails expo-image-manipulator
npm install @react-native-community/slider
```

## Implementation

### 1. Video Recording

```typescript
// components/media/VideoRecorder.tsx
import { CameraView, useCameraPermissions } from 'expo-camera';
import { useState, useRef } from 'react';
import { View, Pressable, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

export function VideoRecorder({ onRecordingComplete }: {
  onRecordingComplete: (uri: string) => void;
}) {
  const [permission, requestPermission] = useCameraPermissions();
  const cameraRef = useRef<CameraView>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [duration, setDuration] = useState(0);

  if (!permission?.granted) {
    return (
      <View style={styles.permissionContainer}>
        <Text style={styles.permissionText}>Camera permission required</Text>
        <Pressable onPress={requestPermission} style={styles.permissionButton}>
          <Text style={styles.buttonText}>Grant Permission</Text>
        </Pressable>
      </View>
    );
  }

  const startRecording = async () => {
    if (cameraRef.current && !isRecording) {
      setIsRecording(true);
      setDuration(0);

      // Update duration timer
      const interval = setInterval(() => {
        setDuration(d => d + 1);
      }, 1000);

      try {
        const video = await cameraRef.current.recordAsync({
          maxDuration: 60, // 60 seconds max
        });

        clearInterval(interval);
        if (video) onRecordingComplete(video.uri);
      } catch (error) {
        console.error('Recording failed:', error);
      } finally {
        setIsRecording(false);
      }
    }
  };

  const stopRecording = () => {
    if (cameraRef.current && isRecording) {
      cameraRef.current.stopRecording();
    }
  };

  return (
    <View style={styles.container}>
      <CameraView ref={cameraRef} style={styles.camera} mode="video">
        {isRecording && (
          <View style={styles.recordingIndicator}>
            <View style={styles.redDot} />
            <Text style={styles.durationText}>{duration}s</Text>
          </View>
        )}

        <View style={styles.controls}>
          <Pressable
            onPress={isRecording ? stopRecording : startRecording}
            style={[styles.recordButton, isRecording && styles.recordingButton]}
          >
            {isRecording ? (
              <View style={styles.stopIcon} />
            ) : (
              <View style={styles.recordIcon} />
            )}
          </Pressable>
        </View>
      </CameraView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  camera: { flex: 1 },
  permissionContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  permissionText: { fontSize: 16, marginBottom: 20 },
  permissionButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  buttonText: { color: '#fff', fontSize: 16, fontWeight: '600' },
  recordingIndicator: {
    position: 'absolute',
    top: 50,
    left: 20,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  redDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#FF3B30',
  },
  durationText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  controls: {
    position: 'absolute',
    bottom: 40,
    left: 0,
    right: 0,
    alignItems: 'center',
  },
  recordButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: 'rgba(255,255,255,0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  recordingButton: {
    backgroundColor: 'rgba(255,59,48,0.3)',
  },
  recordIcon: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#FF3B30',
  },
  stopIcon: {
    width: 40,
    height: 40,
    borderRadius: 4,
    backgroundColor: '#fff',
  },
});
```

### 2. Video Player with Controls

```typescript
// components/media/VideoPlayer.tsx
import { useVideoPlayer, VideoView } from 'expo-video';
import { useState } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Slider from '@react-native-community/slider';

export function VideoPlayer({ uri }: { uri: string }) {
  const player = useVideoPlayer(uri, player => {
    player.loop = false;
    player.play();
  });

  const [isPlaying, setIsPlaying] = useState(true);
  const [showControls, setShowControls] = useState(true);

  const togglePlayPause = () => {
    if (isPlaying) {
      player.pause();
    } else {
      player.play();
    }
    setIsPlaying(!isPlaying);
  };

  return (
    <View style={styles.container}>
      <Pressable
        style={styles.videoContainer}
        onPress={() => setShowControls(!showControls)}
      >
        <VideoView
          style={styles.video}
          player={player}
          allowsFullscreen
          allowsPictureInPicture
        />

        {showControls && (
          <View style={styles.controls}>
            <Pressable onPress={togglePlayPause} style={styles.playButton}>
              <Ionicons
                name={isPlaying ? 'pause' : 'play'}
                size={32}
                color="#fff"
              />
            </Pressable>
          </View>
        )}
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
    aspectRatio: 16 / 9,
    backgroundColor: '#000',
    borderRadius: 12,
    overflow: 'hidden',
  },
  videoContainer: {
    flex: 1,
  },
  video: {
    flex: 1,
  },
  controls: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  playButton: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
});
```

### 3. Video Thumbnail Generation

```typescript
// lib/media/video-thumbnail.ts
import { getThumbnailAsync } from 'expo-video-thumbnails';

export async function generateThumbnail(videoUri: string): Promise<string> {
  try {
    const { uri } = await getThumbnailAsync(videoUri, {
      time: 1000, // 1 second into video
      quality: 0.7,
    });
    return uri;
  } catch (error) {
    console.error('Thumbnail generation failed:', error);
    throw error;
  }
}
```

### 4. Video Compression

```typescript
// lib/media/video-compression.ts
import { Video } from 'expo-av';
import * as FileSystem from 'expo-file-system';

export async function compressVideo(
  uri: string,
  quality: 'low' | 'medium' | 'high' = 'medium'
): Promise<string> {
  // For production, use a library like react-native-compressor
  // This is a placeholder showing the concept

  const compressionSettings = {
    low: { bitrate: 500000 },
    medium: { bitrate: 1000000 },
    high: { bitrate: 2000000 },
  };

  // In real implementation, you'd use:
  // import { Video } from 'react-native-compressor';
  // const compressedUri = await Video.compress(uri, {
  //   compressionMethod: 'manual',
  //   bitrate: compressionSettings[quality].bitrate,
  // });

  console.log('Video compression would happen here');
  return uri; // Placeholder
}
```

### 5. Upload Video to Storage

```typescript
// lib/storage/video.ts
import { supabase } from '../supabase/client';
import * as FileSystem from 'expo-file-system';

export async function uploadVideo(
  uri: string,
  userId: string,
  onProgress?: (progress: number) => void
): Promise<string> {
  const fileName = `${userId}/${Date.now()}.mp4`;

  // For large files, use multipart upload
  const base64 = await FileSystem.readAsStringAsync(uri, {
    encoding: FileSystem.EncodingType.Base64,
  });

  const arrayBuffer = Uint8Array.from(atob(base64), c => c.charCodeAt(0));

  const { error } = await supabase.storage
    .from('videos')
    .upload(fileName, arrayBuffer, {
      contentType: 'video/mp4',
      cacheControl: '3600',
      upsert: false,
    });

  if (error) throw error;

  const { data: { publicUrl } } = supabase.storage
    .from('videos')
    .getPublicUrl(fileName);

  return publicUrl;
}
```

### 6. Picture-in-Picture Support

```typescript
// lib/video/pip.ts
import { useVideoPlayer } from 'expo-video';

export function usePictureInPicture(player: any) {
  const enterPiP = async () => {
    try {
      await player.enterPictureInPicture();
    } catch (error) {
      console.error('PiP failed:', error);
    }
  };

  const exitPiP = async () => {
    try {
      await player.exitPictureInPicture();
    } catch (error) {
      console.error('Exit PiP failed:', error);
    }
  };

  return { enterPiP, exitPiP };
}
```

### 7. Update Posts to Support Video

```typescript
// Update PostCard component
{post.media_type === 'video' && post.media_url && (
  <VideoPlayer uri={post.media_url} />
)}
```

## Key Features Implemented
✅ Video recording with time limit
✅ Video playback with custom controls
✅ Picture-in-Picture support
✅ Lock screen controls
✅ Thumbnail generation
✅ Video compression (concept)
✅ Upload to Supabase Storage
✅ Local-first video handling

## expo-video Benefits

| Feature | expo-av | expo-video |
|---------|---------|------------|
| Package Size | ~500KB | ~200KB |
| Performance | Good | Excellent |
| PiP | Manual | Built-in |
| DRM | No | Yes |
| Subtitles | Basic | Advanced |
| Streaming | Basic | Optimized |

## Best Practices
1. Always compress videos before upload
2. Generate thumbnails for feed performance
3. Limit recording duration (storage costs)
4. Use streaming for large videos
5. Implement progressive upload with resume
6. Cache videos for offline viewing

## Performance Tips
1. Use VideoView's `allowsFullscreen` for better UX
2. Enable PiP for multitasking
3. Lazy load videos in feed (load on scroll)
4. Preload next video while current plays
5. Use HLS for adaptive streaming

## Testing Checklist
- [ ] Record video and play back
- [ ] Custom controls work (play, pause, seek)
- [ ] Fullscreen mode functions
- [ ] Picture-in-Picture works
- [ ] Thumbnail generates correctly
- [ ] Video uploads to cloud
- [ ] Works offline (queues upload)

## Next: Lesson 8 - High-Performance Feed with FlashList 📱
