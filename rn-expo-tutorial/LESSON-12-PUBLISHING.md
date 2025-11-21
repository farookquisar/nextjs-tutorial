# Lesson 12: App Store Publishing

**Duration**: 100 minutes | **Difficulty**: Advanced | **Prerequisites**: Lessons 1-11

## Learning Objectives
- Configure EAS Build for iOS and Android
- Submit to Apple App Store (simplified process)
- Submit to Google Play Store
- Set up OTA updates with EAS Update
- Manage production environment

## Prerequisites

**Apple Developer Account** ($99/year):
- Sign up at https://developer.apple.com

**Google Play Console** ($25 one-time):
- Sign up at https://play.google.com/console

**EAS Account**:
- Sign up at https://expo.dev

## Installation

```bash
npm install -g eas-cli
eas login
```

## Part 1: iOS App Store (Simplified)

### Step 1: Configure app.json

```json
{
  "expo": {
    "name": "MediaSocial",
    "slug": "mediasocial",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.yourcompany.mediasocial",
      "buildNumber": "1",
      "newArchEnabled": true,
      "infoPlist": {
        "NSCameraUsageDescription": "This app uses the camera to take photos and videos",
        "NSMicrophoneUsageDescription": "This app uses the microphone to record audio",
        "NSPhotoLibraryUsageDescription": "This app needs access to your photo library"
      }
    },
    "android": {
      "package": "com.yourcompany.mediasocial",
      "versionCode": 1,
      "newArchEnabled": true,
      "permissions": [
        "CAMERA",
        "RECORD_AUDIO",
        "READ_EXTERNAL_STORAGE",
        "WRITE_EXTERNAL_STORAGE"
      ]
    },
    "extra": {
      "eas": {
        "projectId": "your-project-id"
      }
    }
  }
}
```

### Step 2: Initialize EAS

```bash
# Initialize EAS in your project
eas init

# This creates eas.json
```

### Step 3: Configure eas.json

```json
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "resourceClass": "m-medium"
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "simulator": true
      }
    },
    "production": {
      "ios": {
        "resourceClass": "m-medium"
      },
      "android": {
        "buildType": "app-bundle"
      },
      "env": {
        "EXPO_PUBLIC_SUPABASE_URL": "production_url",
        "EXPO_PUBLIC_SUPABASE_ANON_KEY": "production_key"
      }
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "your-apple-id@email.com",
        "ascAppId": "app-store-connect-app-id",
        "appleTeamId": "your-team-id"
      },
      "android": {
        "serviceAccountKeyPath": "./google-play-service-account.json",
        "track": "internal"
      }
    }
  }
}
```

### Step 4: Build iOS App

```bash
# EAS handles certificates automatically!
eas build --platform ios --profile production

# This will:
# 1. Create/manage certificates
# 2. Create provisioning profiles
# 3. Build your app
# 4. Provide download link

# Build completes in ~10-15 minutes
```

### Step 5: App Store Connect Setup

1. **Create App in App Store Connect**:
   - Go to https://appstoreconnect.apple.com
   - Click "My Apps" → "+" → "New App"
   - Fill in:
     - Platform: iOS
     - Name: MediaSocial
     - Primary Language: English
     - Bundle ID: com.yourcompany.mediasocial
     - SKU: mediasocial-001

2. **App Information**:
   - Privacy Policy URL (required)
   - Category: Social Networking
   - Content Rights: Own or licensed

3. **Pricing and Availability**:
   - Price: Free
   - Availability: All countries

### Step 6: Prepare App Metadata

Create metadata for submission:

**App Store Screenshots** (required):
- 6.5" Display (iPhone 14 Pro Max): 1290 x 2796
- 5.5" Display (iPhone 8 Plus): 1242 x 2208
- 12.9" iPad Pro: 2048 x 2732

**App Description**:
```
MediaSocial - Connect, Share, Inspire

Share your life through photos, videos, and audio with friends and family.

Features:
• Photo and video sharing
• Audio recordings
• Real-time updates
• Offline support
• Beautiful, fast interface

Built with React Native 0.82 and the latest New Architecture for best-in-class performance.
```

**Keywords**: social media, photos, videos, audio, sharing

**Support URL**: https://yourcompany.com/support

**Marketing URL**: https://yourcompany.com

### Step 7: Submit to TestFlight

```bash
# Submit build to TestFlight (beta testing)
eas submit --platform ios --profile production

# This uploads your .ipa to TestFlight
```

**TestFlight Setup**:
1. Go to App Store Connect → TestFlight
2. Select your build
3. Add beta testers
4. Enable automatic distribution
5. Testers receive email with install link

**Beta Test for 1-2 weeks** before production submission.

### Step 8: Submit to App Store

1. **In App Store Connect**:
   - Go to "App Store" tab
   - Click "+ Version or Platform"
   - Enter version: 1.0.0

2. **Upload Screenshots**:
   - Upload 3-5 screenshots per device size
   - Optional: App preview videos

3. **Fill Required Info**:
   - Description
   - Keywords
   - Support URL
   - Privacy Policy URL

4. **Age Rating**:
   - Complete questionnaire
   - MediaSocial: 12+ (social media)

5. **Review Information**:
   - First name, Last name
   - Phone number
   - Email address
   - Demo account (if login required)

6. **Submit for Review**:
   - Click "Add for Review"
   - Click "Submit to App Review"

**Review Time**: 1-3 days typically

### Step 9: Common Rejection Reasons

**Avoid these to pass review**:

1. **Missing Privacy Policy**: Always include URL
2. **Crashes**: Test thoroughly on real devices
3. **Incomplete Features**: All buttons must work
4. **Login Issues**: Provide demo account
5. **Content Violations**: Follow App Store guidelines
6. **Missing Permissions**: Explain all permission requests
7. **Links to External Payments**: Follow IAP rules

## Part 2: Google Play Store

### Step 1: Build Android App

```bash
# Build Android App Bundle (AAB)
eas build --platform android --profile production

# Downloads .aab file
```

### Step 2: Create App in Play Console

1. **Go to Google Play Console**:
   - https://play.google.com/console
   - Click "Create app"

2. **App Details**:
   - App name: MediaSocial
   - Default language: English
   - App or game: App
   - Free or paid: Free

3. **Declarations**:
   - ✓ App follows Play policies
   - ✓ App is not a duplicate
   - ✓ Agree to terms

### Step 3: Set Up App Content

1. **Privacy Policy**: Enter URL

2. **App Access**: All features available (or provide test account)

3. **Ads**: Contains ads (if applicable)

4. **Content Rating**:
   - Complete questionnaire
   - Social media app
   - Rating: Teen (typically)

5. **Target Audience**:
   - Age group: 13+

6. **Data Safety**:
   - Collect data: Yes (user profiles, posts)
   - Share data: No
   - Encryption: In transit and at rest
   - Delete data: Users can request deletion

### Step 4: Prepare Store Listing

**Graphics Requirements**:
- App icon: 512 x 512 PNG
- Feature graphic: 1024 x 500 JPG/PNG
- Phone screenshots: 2-8 screenshots (min 320px)
- 7" Tablet screenshots: Optional
- 10" Tablet screenshots: Optional

**Store Listing**:
```
Short description (80 chars):
Connect, share photos, videos & audio with friends

Full description (4000 chars):
MediaSocial - Your Personal Social Network

Share your life's moments through photos, videos, and audio recordings.
Stay connected with friends and family with real-time updates.

Features:
• Photo Sharing - Capture and share moments
• Video Recording - Create and share videos
• Audio Messages - Record voice messages
• Real-time Updates - See updates instantly
• Offline Support - Use app without internet
• Fast & Beautiful - Built with latest technology

Privacy & Security:
• End-to-end encryption
• Local-first data storage
• You own your data
• Delete anytime

Built with React Native 0.82, featuring the New Architecture for
exceptional performance and smooth 60 FPS scrolling.

Download MediaSocial today and start sharing!
```

### Step 5: Internal Testing

```bash
# Submit to internal testing track
eas submit --platform android --profile production
```

**Set Up Internal Testing**:
1. Create email list of testers
2. Upload AAB
3. Add testers' Google accounts
4. Testers receive invite
5. Test for 1 week

### Step 6: Production Release

1. **Create Production Release**:
   - Go to "Production" tab
   - Click "Create new release"
   - Upload AAB
   - Add release notes

2. **Release Notes**:
```
What's new in version 1.0.0:

• Initial release
• Share photos, videos, and audio
• Real-time updates
• Offline support
• Beautiful, fast interface
```

3. **Review and Rollout**:
   - Review all sections
   - Click "Review release"
   - Click "Start rollout to Production"

**Review Time**: 1-3 days

### Step 7: Staged Rollout (Recommended)

Start with small percentage:
1. Roll out to 10% of users
2. Monitor for crashes
3. Increase to 50% after 24 hours
4. Full rollout after 48 hours

## Part 3: Over-The-Air (OTA) Updates

### Why OTA Updates?

- Fix bugs instantly (no app store review)
- Update JavaScript/assets only
- Native code changes still require store update

### Step 1: Configure EAS Update

```bash
# Install EAS Update
npx expo install expo-updates

# Configure
eas update:configure
```

### Step 2: Update app.json

```json
{
  "expo": {
    "updates": {
      "url": "https://u.expo.dev/[your-project-id]"
    },
    "runtimeVersion": {
      "policy": "sdkVersion"
    }
  }
}
```

### Step 3: Publish Update

```bash
# Publish update to production
eas update --branch production --message "Fix: Resolved post upload issue"

# Users get update on next app launch
```

### Step 4: Update Channels

```bash
# Create different channels
eas update --branch staging --message "Staging update"
eas update --branch production --message "Production update"

# Configure in eas.json
```

### Step 5: Rollback

```bash
# View all updates
eas update:list --branch production

# Rollback to previous update
eas update:rollback --branch production
```

## Part 4: Production Environment

### Step 1: Environment Variables

```bash
# .env.production
EXPO_PUBLIC_SUPABASE_URL=https://prod.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=prod_key_here
EXPO_PUBLIC_API_URL=https://api.mediasocial.com
```

### Step 2: Error Tracking

```bash
# Install Sentry
npx expo install sentry-expo

# Configure
# app.json
{
  "expo": {
    "plugins": [
      [
        "sentry-expo",
        {
          "organization": "your-org",
          "project": "mediasocial"
        }
      ]
    ]
  }
}
```

### Step 3: Analytics

```bash
# Install analytics
npx expo install expo-firebase-analytics

# Track events
import { logEvent } from 'expo-firebase-analytics';

logEvent('post_created', {
  post_type: 'image',
  user_id: userId,
});
```

### Step 4: CI/CD Pipeline

```yaml
# .github/workflows/eas-build.yml
name: EAS Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npm test
      - uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}
      - run: eas build --platform all --non-interactive --no-wait
```

## Launch Checklist

### Pre-Launch
- [ ] All features tested on real devices
- [ ] No crashes or critical bugs
- [ ] Privacy policy published
- [ ] Support email set up
- [ ] Screenshots prepared
- [ ] App descriptions written
- [ ] Age ratings completed

### iOS Specific
- [ ] TestFlight testing complete
- [ ] All device sizes tested
- [ ] Review guidelines followed
- [ ] Demo account provided (if needed)

### Android Specific
- [ ] Internal testing complete
- [ ] Data safety form complete
- [ ] Content rating assigned
- [ ] Store listing complete

### Post-Launch
- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Track analytics
- [ ] Plan updates
- [ ] Marketing campaign

## Maintenance

**Regular Updates**:
- Bug fixes via OTA updates
- Feature updates via app stores
- Monitor user feedback
- Track analytics
- Respond to reviews

**Best Practices**:
1. Release updates every 2-4 weeks
2. Test thoroughly before release
3. Use staged rollouts
4. Monitor crash rates
5. Keep dependencies updated

## Congratulations! 🎉

You've completed the entire React Native 0.82 + Expo 54 tutorial series!

**You've built**:
✅ Production-ready social media app
✅ Local-first architecture
✅ Media sharing (photos, videos, audio)
✅ Real-time updates
✅ Offline support
✅ Push notifications
✅ Published to both app stores!

**Next Steps**:
- Monitor app performance
- Gather user feedback
- Iterate and improve
- Build new features
- Scale your infrastructure

**Resources**:
- Expo Docs: https://docs.expo.dev
- React Native Docs: https://reactnative.dev
- Supabase Docs: https://supabase.com/docs
- EAS Docs: https://docs.expo.dev/eas

**Thank you for completing this tutorial!** 🚀

Share your app and let us know what you built!
