# GSP313: Set Up a Google Cloud Network — Technical Notes

## 💡 Key Architectural Concepts

### 1. Google Cloud VPC Global Scope
- Unlike AWS VPCs which are regional, Google Cloud VPCs are **global**. A single VPC can host subnets in every Google Cloud region worldwide without inter-region VPNs or complex routing peering.
- Cross-region subnet communication travels over Google's private software-defined Andromeda network, offering lower latency, higher throughput, and encryption in transit.

### 2. Auto Mode vs Custom Mode VPC
- **Auto Mode**: Automatically provisions one subnet per region using pre-allocated `10.128.0.0/9` IP blocks. Convenient for quick prototyping, but creates CIDR overlap risks if peering with on-prem networks.
- **Custom Mode**: Production standard. You explicitly define subnets, IP ranges, and regions, preventing overlapping ranges.

### 3. Firewall Rules Evaluation
- Rules are stateful: if incoming traffic is permitted, response traffic is automatically allowed.
- Priority ranges from 0 to 65535 (lower numbers have higher priority). Default implied deny ingress is priority 65535.
- Target filtering can be based on target tags, service accounts, or all instances in the VPC.
