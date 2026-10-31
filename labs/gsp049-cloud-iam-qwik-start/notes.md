# GSP049: Cloud IAM: Qwik Start — Technical Notes

## 💡 Key Security Concepts

### 1. Primitive vs Predefined vs Custom Roles
- **Primitive Roles**:
  - `roles/owner`: Full administrative privileges, billing management, role assignment.
  - `roles/editor`: Deploy, mutate, delete resources; cannot modify permissions or billing.
  - `roles/viewer`: Read-only inspection of resources.
  - *Best Practice*: Avoid primitive roles in production environments due to excessive blast radius.
- **Predefined Roles**:
  - Fine-grained service-specific roles managed by Google (e.g. `roles/storage.objectViewer`, `roles/pubsub.publisher`).
- **Custom Roles**:
  - User-defined collections of specific permissions (`service.resource.verb`) when predefined roles grant unnecessary privileges.

### 2. IAM Policy Inheritance
- Google Cloud Resource Hierarchy: **Organization ➔ Folders ➔ Projects ➔ Resources**.
- Permissions are inherited downwards. A role granted at the Organization level applies to every folder, project, and resource beneath it and **cannot** be restricted at a child level (allow-only model).
- Deny policies (IAM Deny) can override inherited allow grants.
