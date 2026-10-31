# GSP319: Build and Deploy ML Solutions on Vertex AI — Technical Notes

## 💡 Vertex AI MLOps Concepts

### 1. Pre-built vs Custom Prediction Containers
- **Pre-built Containers**: Google-managed and optimized for TensorFlow, Scikit-learn, XGBoost, and PyTorch. No Dockerfile or container building needed; simply upload the model artifact (`model.joblib`, `saved_model.pb`) to Cloud Storage.
- **Custom Prediction Containers**: Required when using custom C++ libraries, preprocessing pipelines, or unsupported frameworks. Exposes an HTTP server on port 8080 implementing `/predict` and `/health` endpoints.

### 2. Vertex AI Endpoints & Traffic Splitting
- A single Vertex AI Endpoint can host multiple deployed models simultaneously.
- **Canary Deployments / A/B Testing**: Traffic can be split across model versions (e.g., 90% to v1, 10% to v2) by configuring `--traffic-split=0=90,1=10`.
- **Zero-Downtime Migration**: You can promote new models to 100% traffic without updating client endpoint URLs.

### 3. Model Monitoring & Drift Detection
- Vertex AI Model Monitoring analyzes live prediction requests against the training dataset baseline to identify feature drift and concept drift, triggering Cloud Monitoring alerts when statistical distributions diverge.
