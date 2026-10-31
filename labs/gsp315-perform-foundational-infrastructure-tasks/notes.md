# GSP315: Perform Foundational Infrastructure Tasks — Technical Notes

## 💡 Architecture & Implementation Details

### Cloud Functions Gen 2 Architecture
- Built on top of **Google Cloud Run** and **Eventarc**.
- Long-running request timeout up to 60 minutes for HTTP functions (up to 10 minutes for event functions).
- Native support for concurrency (up to 1000 concurrent requests per instance), significantly lowering cold starts and overall cost.
- Event delivery standard: Follows the **CloudEvents v1.0** specification.

### Cloud Storage: Uniform vs Fine-Grained Access
- **Uniform Bucket-Level Access**: Disables per-object ACLs; permissions are evaluated strictly at the bucket level through Cloud IAM policies. Highly recommended for compliance and security auditing.
- **Fine-Grained Access**: Supports legacy individual Object ACLs alongside bucket policies.
