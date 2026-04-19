# Talkify User App 

Talkify is a high-performance, real-time communication platform built with Flutter. This repository contains the **User App**, designed for users to browse contacts, check availability, and initiate high-quality audio and video calls.

---

##  Key Features
- **Real-time Video/Audio Calling**: Seamless communication powered by Agora SDK with dedicated modes for voice and video.
- **Presence System**: Real-time tracking of recipient availability (Online/Offline) via Firestore heartbeat.
- **Premium Glassmorphism UI**: A stunning, modern interface featuring glassmorphism effects, smooth animations, and a curated color palette.
- **Advanced Call Management**: Full control over call initiation, real-time state synchronization, and in-call media toggles.

---

##  Technical Architecture

### 1. Firebase Integration 
Firebase provides the foundation for data persistence and identity management:
- **Firebase Authentication**: Secure user registration and login with persistent session handling.
- **Cloud Firestore**: Acts as the signaling server and presence database, tracking user status and active call sessions in real-time.
- **Cloud Functions**: Power the backend logic for secure call initiation and lifecycle events.

### 2. Agora SDK Implementation 🎥
The app leverages the **Agora RTC SDK** for industry-leading media delivery:
- **Dynamic Media Handling**: Supports seamless switching between audio and video calling.
- **Optimized RTC Engine**: Configured for low latency and high reliability across varying network conditions.
- **In-Call Controls**: Real-time microphone muting, speakerphone toggles, and camera switching.

### 3. Webhook & Signaling System ⚓
The call lifecycle is managed through a sophisticated webhook-based architecture:
- **`startCall` Webhook**: Triggered when a user initiates a call. It validates the session, creates Firestore metadata, and signals the receiver.
- **`handleCallEvent` Webhook**: Manages state transitions like `accepted`, `rejected`, or `ended`, ensuring the UI reflects the current call state instantly.
- **Mock Fallback**: Includes a robust mock mode for development and testing without live backend dependencies.

### 4. Push Notifications & Presence 🛰️
- **Presence Heartbeat**: Implements a real-time status system to ensure callers only attempt to reach available users.
- **FCM Integration**: Uses Firebase Cloud Messaging to receive status updates and call event notifications.

---

## 📁 Project Structure
- `lib/screens/`: Premium UI implementation including Glassmorphism login/signup and dynamic call screens.
- `lib/providers/`: State management for authentication, user presence, and call signaling logic.
- `lib/services/`: Core logic for Firebase, Agora integration, and webhook communication.
- `lib/models/`: Structured data models for `Call` and `User` entities.

---
