# 🧠 Google Cloud Arcade: Master Trivia Bank & Answer Guide

This reference bank catalogs verified answers for Google Cloud Arcade weekly trivia questions across all technical domains.

---

## ☁️ Compute Engine & Serverless

| Question / Topic | Correct Answer | Technical Explanation |
|---|---|---|
| Which compute option provides serverless container execution that scales to zero? | **Cloud Run** | Cloud Run runs containers directly on Google's Borg infrastructure without managing Kubernetes clusters or nodes. |
| What is the primary difference between Cloud Functions Gen 1 and Gen 2? | **Gen 2 runs on Cloud Run and uses Eventarc** | Gen 2 supports longer timeouts (up to 60m), larger instances (32GB RAM / 8 vCPUs), and concurrency up to 1000. |
| Which feature recreates unhealthy VMs in a Managed Instance Group? | **Autohealing** | An autohealing policy uses an application health check to reboot or recreate instances that fail consecutive probes. |
| What is the maximum duration for a preemptible / Spot VM? | **No 24-hour limit on Spot VMs; can be terminated at any time** | Unlike legacy Preemptible VMs (max 24h), Spot VMs do not have a hard 24-hour expiration. |

---

## 🔒 Identity, Access & Security

| Question / Topic | Correct Answer | Technical Explanation |
|---|---|---|
| Which IAM role allows an identity to grant or revoke other IAM roles on a project? | **Security Admin (`roles/iam.securityAdmin`) or Project Owner** | `roles/resourcemanager.organizationAdmin` or `roles/iam.securityAdmin` controls IAM policy bindings. |
| Which service securely allows SSH into private VMs without a public IP or VPN? | **Identity-Aware Proxy (IAP) TCP Forwarding** | IAP proxies TCP port 22 traffic through Google's reverse proxy using IP range `35.235.240.0/20`. |
| What type of Google Cloud service account key is rotated automatically by Google? | **Google-managed keys** | Google-managed service account keys are stored securely in KMS and rotated automatically every week. |
| What IAM concept prevents permissions from being granted even if an Allow policy exists? | **IAM Deny Policy** | IAM Deny policies take precedence over any inherited or explicit IAM Allow bindings. |

---

## 🌐 Networking & VPC

| Question / Topic | Correct Answer | Technical Explanation |
|---|---|---|
| What is the scope of a Google Cloud Virtual Private Cloud (VPC) network? | **Global** | Unlike AWS (regional), Google Cloud VPCs span all Google regions globally. |
| Which service enables private VMs to download software updates from the internet? | **Cloud NAT** | Cloud NAT translates private egress traffic to public external IPs without accepting unsolicited ingress. |
| What is required to reach Google APIs (Storage, BigQuery) from a VM without external IP? | **Private Google Access** | Enabled at the subnet level to route `*.googleapis.com` internally via private virtual IPs (`199.36.153.8/30`). |
| Can VPC Peering routes be transitive across multiple networks? | **No (Non-transitive)** | VPC Peering connects only the two directly peered networks. |

---

## 📊 Data, Analytics & Machine Learning

| Question / Topic | Correct Answer | Technical Explanation |
|---|---|---|
| What SQL syntax does BigQuery use by default? | **GoogleSQL (Standard SQL)** | Legacy SQL is deprecated; Standard SQL (ANSI:2011 compliant) is the default. |
| Which storage class is best for data accessed less than once a year? | **Archive Storage** | Provides lowest storage cost ($0.0012/GB/month) with higher retrieval costs. |
| What format must Scikit-learn models be serialized to for Vertex AI pre-built containers? | **`model.joblib` or `model.pkl`** | Pre-built Scikit-learn containers specifically expect this exact file naming in the GCS artifact directory. |
| Which Google Cloud database offers 99.999% availability and global horizontal scalability? | **Cloud Spanner** | Combines relational ACID transactions with global distributed scalability using TrueTime atomic clocks. |
