# 📱 AZ Learner — Play Store Publishing Guide

This guide walks you through building, signing, and publishing the AZ Learner Android app to the Google Play Store.

---

## 📋 Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter | ≥ 3.2.0 | https://flutter.dev/docs/get-started/install |
| Android Studio | Latest | https://developer.android.com/studio |
| Java JDK | 17 | https://adoptium.net/ |
| Google Play Console account | — | https://play.google.com/console |

---

## 🔥 Step 1 — Set Up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Open your existing project (or create a new one)
3. Click **Add app → Android**
4. Enter package name: `com.azlearner.app`
5. Enter nickname: `AZ Learner Android`
6. Download `google-services.json`
7. Replace `android/app/google-services.json` with the downloaded file
8. Update `lib/firebase_options.dart` with your actual config values

### Enable Firebase Services:
- **Authentication** → Enable Email/Password sign-in
- **Cloud Firestore** → Create database in production mode
- **Firebase Storage** → Create default bucket
- **Cloud Messaging (FCM)** → Already enabled by default

---

## 🔑 Step 2 — Configure Gemini AI Key

The AI features use Google's Gemini API.

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create an API key
3. Set as environment variable (never hardcode in source!):

```bash
# Option A: Pass at build time (recommended)
flutter build appbundle --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE

# Option B: Add to your CI/CD secrets
```

---

## 🖊️ Step 3 — Generate Signing Keystore

> **IMPORTANT:** Keep your keystore file and passwords safe. Losing them means you can't update your app!

```bash
# Generate keystore (run once, keep forever)
keytool -genkey -v \
  -keystore ~/az-learner-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias az-learner-key

# You'll be prompted for:
# - keystore password (strong, remember it!)
# - key password
# - name, organization, city, country
```

### Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=az-learner-key
storeFile=/absolute/path/to/az-learner-keystore.jks
```

> ⚠️ Add `android/key.properties` and `*.jks` to `.gitignore` — NEVER commit these!

### Update `android/app/build.gradle` signing config:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... rest of config
        }
    }
}
```

---

## 📦 Step 4 — Install Dependencies

```bash
cd flutter_app
flutter pub get
```

---

## 🏗️ Step 5 — Build the App Bundle (AAB)

Google Play requires the **Android App Bundle (.aab)** format.

```bash
# Development build
flutter build appbundle --debug

# Production release build (with AI key)
flutter build appbundle --release \
  --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY

# The AAB will be at:
# build/app/outputs/bundle/release/app-release.aab
```

### Optional: Build APK for direct testing

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_KEY
# APK at: build/app/outputs/flutter-apk/app-release.apk

# Install directly to connected device
flutter install
```

---

## 🖼️ Step 6 — Prepare Store Assets

You'll need these assets for your Play Store listing:

| Asset | Size | Notes |
|-------|------|-------|
| App icon | 512×512 PNG | No rounded corners (Play adds them) |
| Feature graphic | 1024×500 PNG | Shown at top of store listing |
| Screenshots (phone) | Min 2, max 8 | 16:9 or 9:16 ratio |
| Screenshots (tablet) | Optional | Recommended for better ranking |
| Short description | ≤ 80 chars | Hook your users |
| Full description | ≤ 4000 chars | Use keywords naturally |
| Privacy policy URL | Required | Host on your website |

### Recommended screenshot content:
1. Home screen with streak card
2. Timetable view
3. Tasks list with AI help button
4. Study Room (Pomodoro timer running)
5. Note editor
6. AI Task Helper in action

---

## 🚀 Step 7 — Create Play Console App

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in:
   - **App name:** AZ Learner
   - **Default language:** English (United Kingdom)
   - **App or game:** App
   - **Free or paid:** Free
4. Accept the Developer Program Policies

---

## 📝 Step 8 — Complete Store Listing

In Play Console → **Store presence → Main store listing**:

```
App name: AZ Learner — Smart Student Companion

Short description (80 chars max):
Your all-in-one academic toolkit with AI-powered study assistance

Full description:
AZ Learner is the ultimate student companion app designed for university 
students. Stay organized, study smarter, and never miss a deadline.

🎓 ACADEMIC MANAGEMENT
• Timetable — manage your full weekly schedule with reminder notifications
• Assignments — track homework and deadlines with smart AI assistance
• Notes — rich-text note-taking with a beautiful grid view

🍅 STUDY ROOM
• Pomodoro Timer with focus/break cycle tracking
• Lofi radio player for calm, focused study sessions
• Daily focus goal setting

🤖 AI STUDY BUDDY
• Powered by Google Gemini AI
• Get help breaking down any assignment into manageable steps
• Ask for key points, resources, time estimates, and more
• Context-aware chat that knows your specific assignment

🔔 SMART NOTIFICATIONS
• Push notifications even when the app is closed
• Class reminders before your lectures
• Assignment deadline alerts
• Pomodoro session complete alerts

📊 GAMIFICATION
• Daily login streaks to build consistent study habits
• Weekly XP system with rank progression
• Rankings: Rookie → Scholar → Main Character → Academic Weapon → God Tier

💬 COMMUNITY (coming soon)
• Direct messaging with classmates
• Course circles for group study
```

---

## 🔒 Step 9 — Content Rating

Play Console → **Policy → App content → Content rating**:

1. Click **Start questionnaire**
2. Category: **Educational**
3. Answer questions (no violence, no adult content, etc.)
4. Confirm and **Apply rating**

---

## 🏷️ Step 10 — Set Up App Pricing & Distribution

Play Console → **Monetization setup → Pricing & distribution**:
- Price: **Free**
- Countries: Select all / specific target markets
- Content guidelines: Check all appropriate boxes

---

## 📤 Step 11 — Upload & Release

### Internal Testing (recommended first):

1. Play Console → **Testing → Internal testing**
2. Click **Create new release**
3. Upload your `app-release.aab`
4. Add release notes
5. Click **Save** then **Review release**
6. **Start rollout to Internal testing**
7. Add tester emails in the **Testers** tab

### Production Release:

1. Play Console → **Production**
2. Click **Create new release**
3. Upload your signed `.aab`
4. Fill in **What's new in this release**
5. **Save** → **Review release** → **Start rollout to production**

> 💡 First-time submissions typically take **3-7 business days** for review.
> Updates are usually reviewed within **24-48 hours**.

---

## ⚙️ Step 12 — Configure FCM for Push Notifications

For push notifications to work when the app is closed:

1. Firebase Console → **Project settings → Cloud Messaging**
2. Copy your **Server key**
3. To send notifications from your backend/Firestore Cloud Functions:

```javascript
// Firebase Cloud Function example (Node.js)
const admin = require('firebase-admin');

exports.sendTaskReminder = functions.firestore
  .document('assignments/{assignmentId}')
  .onCreate(async (snap, context) => {
    const task = snap.data();
    const userDoc = await admin.firestore().collection('users').doc(task.userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    
    if (!fcmToken) return;
    
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: `📋 New Assignment: ${task.title}`,
        body: `Due: ${task.dueDate} — ${task.course}`,
      },
      android: {
        notification: {
          channelId: 'az_learner_channel',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      data: {
        route: '/tasks',
        assignmentId: context.params.assignmentId,
      },
    });
  });
```

---

## 🔄 App Updates

To publish an update:

1. Increment `version` in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # name+code (both must be incremented)
   ```
2. Rebuild: `flutter build appbundle --release`
3. Upload new AAB to Play Console → **Production → Create new release**

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| `google-services.json` not found | Place in `android/app/`, not project root |
| Build fails with Kotlin error | Run `flutter clean && flutter pub get` |
| FCM not receiving on device | Check `minSdkVersion` ≥ 21 and battery optimization |
| Notification not showing | Verify channel ID matches in manifest and code |
| Signing error | Double-check `key.properties` paths and passwords |
| `GEMINI_API_KEY` not working | Pass via `--dart-define`, check API key is valid |

---

## 📞 Support

For issues with this codebase:
- Open an issue in the repository
- Contact the development team

For Play Store policy questions:
- https://support.google.com/googleplay/android-developer

---

*AZ Learner Flutter App — Built for university students* 🎓
