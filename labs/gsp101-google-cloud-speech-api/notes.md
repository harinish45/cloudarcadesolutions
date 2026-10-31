# GSP101: Google Cloud Speech-to-Text API — Technical Notes

## 💡 Key Machine Learning Concepts

### 1. Synchronous vs Asynchronous Recognition
- **Synchronous Recognition (`speech:recognize`)**:
  - Max audio duration: **60 seconds** (1 minute).
  - Synchronous blocking call returning transcript directly in the HTTP response.
- **Asynchronous Recognition (`speech:longrunningrecognize`)**:
  - Max audio duration: **480 minutes** (8 hours).
  - Returns an `Operation` object that must be polled until completion. Audio file must reside in Cloud Storage (`gs://`).
- **Streaming Recognition**:
  - Real-time bidirectional gRPC streaming for interactive voice bots and live closed captioning.

### 2. Audio Encodings & Optimization
- **Lossless Encodings**: `FLAC` or `LINEAR16` (uncompressed 16-bit signed PCM) yield the highest recognition accuracy.
- **Sampling Rates**: Optimal recognition occurs at 16,000 Hz or higher. Supplying audio with mismatched sample rates will severely reduce accuracy.
- **Model Adaptation & Speech Adaptation**: Custom phrases, boost weights, and class tokens (e.g. `$OPERAND`, `$POSTALCODE`) can be configured to recognize specialized domain jargon.
