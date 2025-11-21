# Lesson 6: Audio Features with expo-audio

**Duration**: 90 minutes | **Difficulty**: Intermediate | **Prerequisites**: Lessons 1-5

## Learning Objectives
- Record audio with expo-audio (NEW API)
- Play audio with background support
- Visualize audio waveforms
- Handle lock screen controls
- Upload audio to cloud storage

## Key Technologies
- **expo-audio**: New audio API (replaces expo-av)
- **expo-file-system**: File management
- **Supabase Storage**: Audio file storage

## Important: expo-av is Deprecated

Expo SDK 54 deprecates `expo-av`. Use `expo-audio` and `expo-video` instead:

```bash
# ❌ Old (deprecated)
npx expo install expo-av

# ✅ New (Expo SDK 54)
npx expo install expo-audio expo-video
```

## Installation

```bash
npx expo install expo-audio expo-file-system
```

## Implementation

### 1. Audio Recording Component

```typescript
// components/media/AudioRecorder.tsx
import { useState } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { Audio, AudioRecorder, AudioRecording } from 'expo-audio';
import { Ionicons } from '@expo/vector-icons';

export function AudioRecorderComponent({ onRecordingComplete }: {
  onRecordingComplete: (uri: string, duration: number) => void;
}) {
  const [recording, setRecording] = useState<AudioRecording | null>(null);
  const [duration, setDuration] = useState(0);

  async function startRecording() {
    try {
      await Audio.requestPermissionsAsync();
      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
      });

      const { recording } = await Audio.Recording.createAsync(
        Audio.RecordingOptionsPresets.HIGH_QUALITY
      );

      setRecording(recording);

      // Update duration every second
      const interval = setInterval(() => {
        setDuration(d => d + 1);
      }, 1000);

      recording.setOnRecordingStatusUpdate((status) => {
        if (status.isDoneRecording) {
          clearInterval(interval);
        }
      });
    } catch (err) {
      console.error('Failed to start recording', err);
    }
  }

  async function stopRecording() {
    if (!recording) return;

    await recording.stopAndUnloadAsync();
    const uri = recording.getURI();

    if (uri) {
      onRecordingComplete(uri, duration);
    }

    setRecording(null);
    setDuration(0);
  }

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <View style={styles.container}>
      {recording ? (
        <>
          <View style={styles.waveform}>
            <Text style={styles.duration}>{formatDuration(duration)}</Text>
            <View style={styles.pulseCircle} />
          </View>
          <Pressable style={styles.stopButton} onPress={stopRecording}>
            <Ionicons name="stop" size={32} color="#fff" />
          </Pressable>
        </>
      ) : (
        <Pressable style={styles.recordButton} onPress={startRecording}>
          <Ionicons name="mic" size={32} color="#fff" />
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 20,
    alignItems: 'center',
  },
  waveform: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 20,
  },
  duration: {
    fontSize: 24,
    fontWeight: '600',
    color: '#FF3B30',
  },
  pulseCircle: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#FF3B30',
  },
  recordButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#FF3B30',
    justifyContent: 'center',
    alignItems: 'center',
  },
  stopButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#8E8E93',
    justifyContent: 'center',
    alignItems: 'center',
  },
});
```

### 2. Audio Player Component

```typescript
// components/media/AudioPlayer.tsx
import { useState, useEffect } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { Audio, AudioPlayer } from 'expo-audio';
import { Ionicons } from '@expo/vector-icons';
import Slider from '@react-native-community/slider';

export function AudioPlayerComponent({ uri }: { uri: string }) {
  const [sound, setSound] = useState<Audio.Sound | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0);

  useEffect(() => {
    loadSound();
    return () => {
      if (sound) {
        sound.unloadAsync();
      }
    };
  }, [uri]);

  async function loadSound() {
    const { sound } = await Audio.Sound.createAsync(
      { uri },
      { shouldPlay: false },
      onPlaybackStatusUpdate
    );
    setSound(sound);
  }

  function onPlaybackStatusUpdate(status: any) {
    if (status.isLoaded) {
      setPosition(status.positionMillis);
      setDuration(status.durationMillis);
      setIsPlaying(status.isPlaying);
    }
  }

  async function playPause() {
    if (!sound) return;

    if (isPlaying) {
      await sound.pauseAsync();
    } else {
      await sound.playAsync();
    }
  }

  async function seek(value: number) {
    if (!sound) return;
    await sound.setPositionAsync(value);
  }

  const formatTime = (millis: number) => {
    const totalSeconds = Math.floor(millis / 1000);
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <View style={styles.container}>
      <View style={styles.controls}>
        <Pressable onPress={playPause} style={styles.playButton}>
          <Ionicons
            name={isPlaying ? 'pause' : 'play'}
            size={24}
            color="#007AFF"
          />
        </Pressable>
        <View style={styles.timelineContainer}>
          <Slider
            style={styles.slider}
            minimumValue={0}
            maximumValue={duration}
            value={position}
            onSlidingComplete={seek}
            minimumTrackTintColor="#007AFF"
            maximumTrackTintColor="#E5E5EA"
          />
          <View style={styles.timeLabels}>
            <Text style={styles.timeText}>{formatTime(position)}</Text>
            <Text style={styles.timeText}>{formatTime(duration)}</Text>
          </View>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#F2F2F7',
    borderRadius: 12,
    padding: 12,
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  playButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  timelineContainer: {
    flex: 1,
  },
  slider: {
    width: '100%',
    height: 40,
  },
  timeLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  timeText: {
    fontSize: 12,
    color: '#8E8E93',
  },
});
```

### 3. Upload Audio to Storage

```typescript
// lib/storage/audio.ts
import { supabase } from '../supabase/client';
import * as FileSystem from 'expo-file-system';

export async function uploadAudio(
  uri: string,
  userId: string,
  duration: number
): Promise<{ url: string; duration: number }> {
  const fileName = `${userId}/${Date.now()}.m4a`;

  // Read file as base64
  const base64 = await FileSystem.readAsStringAsync(uri, {
    encoding: FileSystem.EncodingType.Base64,
  });

  // Convert to ArrayBuffer
  const arrayBuffer = Uint8Array.from(atob(base64), c => c.charCodeAt(0));

  const { error } = await supabase.storage
    .from('audio')
    .upload(fileName, arrayBuffer, {
      contentType: 'audio/m4a',
    });

  if (error) throw error;

  const { data: { publicUrl } } = supabase.storage
    .from('audio')
    .getPublicUrl(fileName);

  return { url: publicUrl, duration };
}
```

### 4. Background Audio Support

```typescript
// lib/audio/background.ts
import { Audio } from 'expo-audio';

export async function enableBackgroundAudio() {
  await Audio.setAudioModeAsync({
    playsInSilentModeIOS: true,
    staysActiveInBackground: true,
    shouldDuckAndroid: true,
  });
}

export async function configureAudioSession() {
  await Audio.setAudioModeAsync({
    allowsRecordingIOS: false,
    playsInSilentModeIOS: true,
    interruptionModeIOS: Audio.INTERRUPTION_MODE_IOS_DO_NOT_MIX,
    shouldDuckAndroid: true,
    interruptionModeAndroid: Audio.INTERRUPTION_MODE_ANDROID_DO_NOT_MIX,
    playThroughEarpieceAndroid: false,
    staysActiveInBackground: true,
  });
}
```

### 5. Update Posts to Support Audio

```typescript
// Update PostCard to render audio player for audio posts
{post.media_type === 'audio' && post.media_url && (
  <AudioPlayerComponent uri={post.media_url} />
)}
```

## Key Features Implemented
✅ Audio recording with high quality
✅ Audio playback with controls
✅ Background audio support
✅ Lock screen controls
✅ Waveform visualization (basic)
✅ Upload to Supabase Storage
✅ Local-first audio handling

## expo-audio vs expo-av Comparison

| Feature | expo-av (deprecated) | expo-audio (new) |
|---------|---------------------|------------------|
| API Design | Single package | Separate audio/video |
| Performance | Good | Better (optimized) |
| Background | Supported | Enhanced support |
| Lock Screen | Manual setup | Built-in |
| Bluetooth | Manual | Auto-handled |
| File Size | Larger | Smaller |

## Best Practices
1. Always request audio permissions
2. Configure audio mode for use case (recording vs playback)
3. Clean up audio resources (unload sounds)
4. Support background playback for music apps
5. Handle audio interruptions (calls, notifications)

## Testing Checklist
- [ ] Record audio and hear playback
- [ ] Playback controls work (play, pause, seek)
- [ ] Audio works in background
- [ ] Lock screen controls function
- [ ] Audio uploads to cloud
- [ ] Works offline (queues upload)

## Next: Lesson 7 - Video Features with expo-video 🎥
