# GSP344: Networking in Google Cloud — Technical Notes

## 💡 Networking Deep Dive

### 1. Cloud NAT Architecture
- **Distributed Software-Defined NAT**: Google Cloud NAT is fully distributed; there are no intermediary NAT appliance VMs, bottlenecks, or single points of failure.
- **Port Allocation**: By default, Cloud NAT allocates 64 minimum ports per VM instance. If instances run high-concurrency microservices, adjust minimum ports per VM to prevent port exhaustion errors (`NAT_ALLOCATION_FAILED`).
- **Endpoint-Independent Mapping**: Ensures that multiple outbound connections to different external IP addresses can reuse internal IP/port translations efficiently.

### 2. VPC Network Peering Constraints
- **Non-Transitive Peering**: If VPC A peers with VPC B, and VPC B peers with VPC C, VPC A **cannot** communicate with VPC C through VPC B. To enable transit routing, Network Connectivity Center (NCC) or Cloud VPN / Interconnect hubs must be used.
- **No Overlapping CIDRs**: Peering fails if any subnet IP ranges in either network overlap.
- **Dynamic Routing Exchange**: Custom routes can be exported and imported dynamically across peered VPCs using `--export-custom-routes` and `--import-custom-routes`.
