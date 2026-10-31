# GSP344: Networking in Google Cloud

![Cloud NAT](https://img.shields.io/badge/Google_Cloud-Cloud_NAT-4285F4?logo=google-cloud&logoColor=white)
![Track](https://img.shields.io/badge/Track-Infrastructure-orange)
![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate-yellow)

## 📋 Overview
Enterprise cloud architectures require secure connectivity patterns where workload compute instances remain inaccessible from the public internet, yet can perform outbound downloads (package updates, API queries) and communicate securely across isolated virtual networks.

In this lab, you configure:
1. **Cloud NAT (Network Address Translation)** with Cloud Router to give private VMs outbound internet access without public IPs.
2. **Private Google Access** to reach Google APIs (Cloud Storage, BigQuery) without public IPs.
3. **VPC Network Peering** to interconnect two independent VPCs privately across RFC 1918 space.

---

## 🏛️ Architecture Topology

```mermaid
flowchart LR
    subgraph VPC1["Production VPC (priv-vpc)"]
        subgraph SubnetProd["Private Subnet (10.0.1.0/24)"]
            PrivVM["Private VM<br/>(No External IP)"]
        end
        CloudRouter["Cloud Router"]
        CloudNAT["Cloud NAT Gateway"]
    end

    subgraph VPC2["Shared Services VPC (shared-vpc)"]
        subgraph SubnetShared["Shared Subnet (10.0.2.0/24)"]
            SharedVM["Shared Services VM<br/>(10.0.2.2)"]
        end
    end

    subgraph InternetZone["External Network"]
        WWW["Public Internet / Repositories"]
    end

    PrivVM -->|Outbound Egress| CloudNAT
    CloudNAT -->|NAT Translation| WWW
    PrivVM <-->|VPC Peering (Direct RFC 1918)| SharedVM
```

---

## ⚙️ Environment Variables

| Variable | Default Value | Description |
|---|---|---|
| `REGION` | `us-central1` | Deployment region |
| `ZONE` | `us-central1-a` | Deployment compute zone |
| `VPC_PROD` | `priv-vpc` | Isolated production VPC |
| `VPC_SHARED` | `shared-vpc` | Shared services VPC |
| `ROUTER_NAME` | `nat-router` | Cloud Router instance |
| `NAT_NAME` | `nat-gateway` | Cloud NAT gateway |

---

## 🚀 Step-by-Step Implementation

### Step 1: Create Two Isolated VPCs and Subnets
```bash
# Production VPC
gcloud compute networks create priv-vpc --subnet-mode=custom
gcloud compute networks subnets create priv-subnet \
  --network=priv-vpc \
  --region=us-central1 \
  --range=10.0.1.0/24 \
  --enable-private-ip-google-access

# Shared Services VPC
gcloud compute networks create shared-vpc --subnet-mode=custom
gcloud compute networks subnets create shared-subnet \
  --network=shared-vpc \
  --region=us-central1 \
  --range=10.0.2.0/24
```

### Step 2: Establish VPC Network Peering (Bidirectional)
VPC Peering must be created from VPC 1 to VPC 2 and from VPC 2 to VPC 1:
```bash
# Peering from priv-vpc to shared-vpc
gcloud compute networks peerings create peer-priv-to-shared \
  --network=priv-vpc \
  --peer-network=shared-vpc \
  --auto-create-routes

# Peering from shared-vpc to priv-vpc
gcloud compute networks peerings create peer-shared-to-priv \
  --network=shared-vpc \
  --peer-network=priv-vpc \
  --auto-create-routes
```

### Step 3: Configure Cloud Router and Cloud NAT Gateway
```bash
# Create Cloud Router
gcloud compute routers create nat-router \
  --network=priv-vpc \
  --region=us-central1

# Create Cloud NAT Gateway on Router
gcloud compute routers nats create nat-gateway \
  --router=nat-router \
  --region=us-central1 \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges
```

### Step 4: Configure Firewall Rules
```bash
# Allow IAP / SSH into instances
gcloud compute firewall-rules create allow-priv-ssh \
  --network=priv-vpc \
  --allow=tcp:22 \
  --source-ranges=35.235.240.0/20

gcloud compute firewall-rules create allow-shared-ssh \
  --network=shared-vpc \
  --allow=tcp:22 \
  --source-ranges=35.235.240.0/20

# Allow ICMP across peered networks
gcloud compute firewall-rules create allow-priv-peer-icmp \
  --network=priv-vpc \
  --allow=icmp,tcp:80,tcp:443 \
  --source-ranges=10.0.2.0/24

gcloud compute firewall-rules create allow-shared-peer-icmp \
  --network=shared-vpc \
  --allow=icmp,tcp:80,tcp:443 \
  --source-ranges=10.0.1.0/24
```

### Step 5: Provision Workload VMs
```bash
# Private VM (No external IP)
gcloud compute instances create priv-vm \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --subnet=priv-subnet \
  --no-address

# Shared Services VM (No external IP)
gcloud compute instances create shared-vm \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --subnet=shared-subnet \
  --no-address
```

---

## 🔍 Verification & Testing

### 1. Test Outbound Internet Access via Cloud NAT
SSH into `priv-vm` using Cloud Identity-Aware Proxy (IAP):
```bash
gcloud compute ssh priv-vm --zone=us-central1-a --tunnel-through-iap
```
Inside `priv-vm`, query external internet:
```bash
curl -s http://checkip.dyndns.org
```
Notice the returned IP is one of Cloud NAT's auto-allocated public IPs!

### 2. Test Cross-VPC Peering Connectivity
Inside `priv-vm`, ping `shared-vm` (10.0.2.2):
```bash
ping -c 3 10.0.2.2
```
Expected output:
```text
3 packets transmitted, 3 received, 0% packet loss
```
