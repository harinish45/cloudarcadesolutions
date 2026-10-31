# GSP330: Implement Load Balancing on Compute Engine — Technical Notes

## 💡 Load Balancing Architecture

### 1. Global Anycast IP vs Regional DNS
- Google Cloud External HTTP(S) Load Balancers use a single **Anycast IP address**. Client packets enter Google's network at the nearest edge Point of Presence (POP) around the globe, traversing Google's private backbone rather than the public internet.
- Cross-region failover occurs without DNS TTL delay.

### 2. Google Health Check Probers
- Health check requests originate from Google internal IP ranges:
  - `130.211.0.0/22`
  - `35.191.0.0/16`
- **Rule of Thumb**: For backend instances to report `HEALTHY`, a firewall rule permitting ingress on target ports from both CIDR blocks must exist in the network.

### 3. Managed Instance Groups (MIGs)
- **Auto-healing**: If health check failures exceed the unhealthy threshold, the MIG automatically recreates unhealthy instances using the base template.
- **Autoscaling metrics**: CPU utilization, Cloud Monitoring metrics, or Load balancing serving capacity.
