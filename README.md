![Talkify Logo](/Users/nandinin/.gemini/antigravity/brain/120daa48-8805-402c-80a1-95d8be5f1e5e/talkify_logo_banner_1776524697007.png)

# Talkify - Premium RTC Solution

Talkify is a state-of-the-art real-time communication application built with Flutter, designed to provide seamless audio and video calling experiences. It leverages a robust cloud architecture to ensure high availability, low latency, and secure peer-to-peer signaling.

## 🚀 Key Features

- **Crystal Clear Calls**: High-definition audio and video calling powered by Agora RTC.
- **Real-time Signaling**: Instant call initiation and lifecycle management using Firebase Firestore.
- **Intelligent Notifications**: Foreground and background call alerts via Firebase Cloud Messaging (FCM).
- **Presence Management**: Real-time tracking of user online/offline status.
- **Glassmorphism UI**: A premium, modern design language featuring translucent elements and vibrant gradients.
- **Secure Authentication**: Robust user identity management via Firebase Auth.

---

## 🛠 Tech Stack & Integrations

### 1. Firebase Ecosystem

Talkify uses Firebase as its primary backend-as-a-service (BaaS) for several critical functions:

- **Authentication**: Handles user registration and secure login.
- **Firestore**:
  - **User Data**: Stores profiles and FCM tokens.
  - **Signaling**: Acts as a real-time message bus for call events (ringing, accepted, rejected, ended).
  - **Presence**: Tracks user heartbeat to show availability.
- **Cloud Messaging (FCM)**: Essential for waking up the `Receiver App` when a call is initiated while the app is in the background or terminated.

### 2. Agora RTC Engine

For the media layer, we integrated **Agora SDK**, which provides:

- **Scalable Video/Audio**: Dynamic bitrate adjustment for varying network conditions.
- **Global Network**: Low-latency routing via Agora's SD-RTN™.
- **Channel Management**: Automatic channel creation and token-based security for every call session.

### 3. Webhook Architecture (Cloud Functions)

To decouple client-side logic from signaling management, we implemented a **Webhook Service**:

- **`startCall` Endpoint**: Instead of clients writing directly to Firestore signaling collections, they trigger a secure webhook. This webhook:
  1. Validates the caller and receiver.
  2. Generates necessary Agora tokens.
  3. Triggers the FCM notification to the receiver.
  4. Initializes the Firestore call document.
- **Mock Mode**: For rapid development, the service includes a `Mock Mode` that simulates backend behavior without requiring a full Cloud Function deployment.

---

## 🔧 Setup & Configuration

### Firebase Setup

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Email/Password Auth**.
3. Create a **Firestore Database** in test mode.
4. Add an Android/iOS app and download `google-services.json` / `GoogleService-Info.plist`.
5. Run `flutterfire configure` to generate `firebase_options.dart`.

### Agora Setup

1. Register on [Agora.io](https://www.agora.io/) and create a project.
2. Obtain your **App ID**.
3. Update the `agoraAppId` in `lib/providers/call_provider.dart`.
4. Ensure your project has `CAMERA` and `RECORD_AUDIO` permissions configured in `AndroidManifest.xml` and `Info.plist`.

### Webhook Configuration

1. Deploy the Cloud Functions located in the backend repository (if available).
2. Update the `_functionsBaseUrl` in `lib/services/webhook_service.dart`.
3. If no backend is deployed, the app will automatically enter **Mock Mode** when it detects a placeholder URL.

---

## 📱 User App vs. Receiver App

Talkify is split into two specialized applications:

- **User App**: The primary interface for users to browse contacts and initiate calls.
- **Receiver App**: Optimized for high-priority background listening, ensuring no incoming calls are missed even when the device is locked.

---

## 🎨 Design Philosophy

Talkify follows a **Premium Dark Aesthetic**. We use:

- **Custom Gradients**: Soft violet and cyan tones for a tech-forward feel.
- **Micro-animations**: Smooth transitions between call states.
- **Interactive UI**: Animated buttons and glassmorphic cards for an immersive experience.

---
