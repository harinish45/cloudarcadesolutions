# GSP282: A Tour of Firebase — Technical Notes & Reference

## 💡 Core Architecture & Best Practices

### Cloud Firestore: Native Mode vs Datastore Mode
- **Native Mode**: Strongly consistent document database optimized for real-time mobile and web apps with client SDK direct access and sub-second updates. Includes offline sync and security rules.
- **Datastore Mode**: Designed for server-side high-throughput key-value operations with backward compatibility for App Engine Datastore. Client SDKs cannot connect directly; no security rules.

### Firebase Hosting Features
- **Global CDN Edge Caching**: Assets deployed to Firebase Hosting are mirrored across Google's worldwide Edge POPs with free automated SSL certificate provisioning.
- **Microservice Rewrites**: Can route API paths (`/api/**`) directly to Cloud Run services or Cloud Functions gen2.

### Firestore Security Rules Syntax
- Security rules run atomically before any document operation is committed.
- Default locked state: `allow read, write: if false;` (best practice during development).
- Token-authenticated access: `allow write: if request.auth != null && request.auth.uid == userId;`.
