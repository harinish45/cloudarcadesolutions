# 📄 Product Requirements Document (PRD)
# ☁️ Cloud Arcade Solutions

---

## 1. Executive Summary & Mission
**Cloud Arcade Solutions** is an open-source, reproducible, production-grade knowledge repository providing automated solutions, architecture topologies, and key learning syntheses for the **Google Cloud Arcade** program and **Google Cloud Skills Boost** skill badges.

The primary objective is to empower cloud engineers, architects, and DevOps professionals to master Google Cloud competencies across 5 structured tracks:
1. **Foundations Track**: Identity & Access Management (IAM), Cloud Storage, Firebase, and basic serverless functions.
2. **Infrastructure Track**: VPC networking, Cloud NAT, VPC Peering, Cloud SQL PostgreSQL, and Cloud Load Balancing.
3. **Data & AI Track**: Cloud Speech-to-Text, BigQuery analytics, Vertex AI MLOps model training and endpoint deployments.
4. **Security Track**: Principle of Least Privilege, Service Account security, VPC firewall rules, and IAM database authentication.
5. **DevOps Track**: Google Kubernetes Engine (GKE), Docker containerization, Artifact Registry, and rolling updates.

---

## 2. Core Personas
- **Arcade Badgers**: Learners collecting monthly Arcade Points, Skill Badges, and Swag milestones.
- **Associate / Professional Cloud Engineers**: Practitioners preparing for Google Cloud certifications (Associate Cloud Engineer, Professional Cloud Architect, Professional Data Engineer, Professional Cloud Security Engineer).
- **Solutions Architects**: Engineers seeking verified architectural patterns and CLI automation snippets for enterprise cloud topologies.

---

## 3. Technical Requirements & Standards

### 3.1 Lab Standard Layout
Every lab within `labs/<lab-id>-<lab-name>/` MUST strictly conform to the three-file architectural contract:
1. `README.md`:
   - Official Lab Metadata (Lab ID, Track, Difficulty).
   - Clear Overview & Key Objectives.
   - Dark-mode Mermaid Architecture Diagram (`flowchart LR` or `flowchart TD` or `graph TD`).
   - Prerequisites & Environment Variables table.
   - Step-by-step reproducible CLI commands (`gcloud`, `bq`, `gsutil`, `kubectl`).
   - Verification commands with expected JSON / table outputs.
2. `solution.sh`:
   - POSIX / Bash compliant script with strict error handling (`set -Eeuo pipefail` and `trap`).
   - Non-interactive execution capability suitable for Cloud Shell.
   - Idempotent resource creation logic (checks if resources exist before creating).
3. `notes.md`:
   - Deep-dive technical explanations of underlying Google Cloud systems.
   - Architectural tradeoffs, limitations, and performance characteristics.
   - Certification exam tips and common troubleshooting pitfalls.

### 3.2 Diagramming Standards
- All architecture diagrams must use Mermaid syntax.
- Must use supported Mermaid diagram types: `flowchart LR`, `flowchart TD`, `graph TD`, `graph LR`.
- Subgraphs must group logical tiers (VPC, Storage, Compute, AI Platform, IAM).

---

## 4. Track Taxonomy & Lab Matrix

| Track | Lab ID | Lab Name | Core Technologies | Status |
|---|---|---|---|---|
| **Foundations** | GSP049 | Cloud IAM: Qwik Start | IAM, Roles, Service Accounts | ✅ Verified |
| **Foundations** | GSP282 | A Tour of Firebase | Firebase Hosting, Cloud Firestore | ✅ Verified |
| **Foundations** | GSP315 | Perform Foundational Infrastructure Tasks | GCS, Pub/Sub, Cloud Functions Gen 2 | ✅ Verified |
| **Infrastructure**| GSP313 | Set Up a Google Cloud Network | Custom VPC, Subnets, Bastion Host | ✅ Verified |
| **Infrastructure**| GSP344 | Networking in Google Cloud | Cloud NAT, VPC Peering, Private Access | ✅ Verified |
| **Infrastructure**| GSP330 | Implement Load Balancing on Compute Engine | MIGs, Health Checks, Global HTTP LB | ✅ Verified |
| **Infrastructure**| GSP355 | CloudSQL PostgreSQL Challenge Lab | DMS, PostgreSQL, IAM Authn, PITR | ✅ Verified |
| **Data & AI** | GSP101 | Google Cloud Speech-to-Text API | Speech REST API, Neural Recognition | ✅ Verified |
| **Data & AI** | GSP319 | Build & Deploy ML on Vertex AI | Scikit-learn, Model Registry, Endpoint | ✅ Verified |
| **DevOps** | GSP318 | Deploy to Kubernetes in Google Cloud | GKE, Docker, Artifact Registry, Rollout | ✅ Verified |

---

## 5. Verification & Quality Gates
- **Zero Broken Links**: All internal relative links must resolve to existing files.
- **Clean Code Fences**: All markdown code fences must be properly closed with matching backticks.
- **Valid Mermaid Syntax**: All diagram code blocks must parse with supported diagram declarations.
- **Script Safety**: All shell scripts must declare safety flags and pass `bash -n` validation.
- **Automated CI Validation**: Script `scripts/validate_labs.py` runs validation across the repository.
