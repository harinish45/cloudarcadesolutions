# GSP313: Set Up a Google Cloud Network

![VPC Network](https://img.shields.io/badge/Google_Cloud-VPC_Network-4285F4?logo=google-cloud&logoColor=white)
![Track](https://img.shields.io/badge/Track-Infrastructure-orange)
![Difficulty](https://img.shields.io/badge/Difficulty-Intermediate-yellow)

## 📋 Overview
In this lab, you build an enterprise VPC network architecture in Google Cloud. You provision custom mode subnets across different geographical regions, establish fine-grained firewall rules for secure administrative access (bastion host), deploy compute workloads, and verify multi-region private network routing.

### Key Objectives
1. Create a custom-mode Virtual Private Cloud (VPC) network.
2. Provision subnets in distinct regions (`us-east1` and `us-central1`).
3. Create firewall rules for ICMP, internal east-west traffic, and external SSH access.
4. Deploy Compute Engine VM instances to each subnet.
5. Establish a secure Bastion Host and verify secure internal cross-subnet communication.

---

## 🏛️ Architecture Topology

```mermaid
flowchart TD
    subgraph VPC["Custom VPC Network (taw-custom-network)"]
        subgraph SubnetA["Subnet Alpha: us-east1 (10.10.10.0/24)"]
            VM1["Compute Engine<br/>vm-internal-1<br/>10.10.10.2 (Private)"]
        end

        subgraph SubnetB["Subnet Beta: us-central1 (10.10.20.0/24)"]
            VM2["Compute Engine<br/>vm-internal-2<br/>10.10.20.2 (Private)"]
        end

        subgraph DMZ["Management Subnet (10.10.30.0/24)"]
            Bastion["Bastion Jumpbox<br/>vm-bastion<br/>Public IP + SSH"]
        end
    end

    Internet["Public Internet / Admin"] -->|Port 22 SSH| Bastion
    Bastion -->|Internal Private SSH| VM1
    Bastion -->|Internal Private SSH| VM2
    VM1 <-->|VPC Global Routing (ICMP/TCP)| VM2
```

---

## ⚙️ Environment Variables

| Variable | Recommended / Default Value | Purpose |
|---|---|---|
| `VPC_NAME` | `taw-custom-network` | Custom VPC Network name |
| `SUBNET_A` | `subnet-alpha` (`10.10.10.0/24` in `us-east1`) | Primary application tier |
| `SUBNET_B` | `subnet-beta` (`10.10.20.0/24` in `us-central1`) | Secondary application tier |
| `SUBNET_MGMT` | `subnet-mgmt` (`10.10.30.0/24` in `us-central1`) | Management / Bastion tier |
| `VM_TYPE` | `e2-micro` | Machine type |

---

## 🚀 Step-by-Step Implementation

### Step 1: Create Custom Mode VPC Network
```bash
gcloud compute networks create taw-custom-network \
  --subnet-mode=custom
```

### Step 2: Provision Subnets Across Regions
```bash
# Subnet Alpha in us-east1
gcloud compute networks subnets create subnet-alpha \
  --network=taw-custom-network \
  --region=us-east1 \
  --range=10.10.10.0/24

# Subnet Beta in us-central1
gcloud compute networks subnets create subnet-beta \
  --network=taw-custom-network \
  --region=us-central1 \
  --range=10.10.20.0/24

# Management Subnet in us-central1
gcloud compute networks subnets create subnet-mgmt \
  --network=taw-custom-network \
  --region=us-central1 \
  --range=10.10.30.0/24
```

### Step 3: Configure Firewall Rules
```bash
# Allow internal cross-subnet communication
gcloud compute firewall-rules create nw-allow-internal \
  --network=taw-custom-network \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=all \
  --source-ranges=10.10.0.0/16

# Allow ICMP ping from anywhere
gcloud compute firewall-rules create nw-allow-icmp \
  --network=taw-custom-network \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=icmp \
  --source-ranges=0.0.0.0/0

# Allow SSH to Bastion Host only (target tagged)
gcloud compute firewall-rules create nw-allow-ssh-bastion \
  --network=taw-custom-network \
  --action=ALLOW \
  --direction=INGRESS \
  --rules=tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=bastion
```

### Step 4: Deploy VM Instances
```bash
# Workload VM 1 in us-east1 (Private IP only)
gcloud compute instances create vm-internal-1 \
  --zone=us-east1-b \
  --machine-type=e2-micro \
  --subnet=subnet-alpha \
  --no-address

# Workload VM 2 in us-central1 (Private IP only)
gcloud compute instances create vm-internal-2 \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --subnet=subnet-beta \
  --no-address

# Bastion Host in us-central1 (Public IP with tag)
gcloud compute instances create vm-bastion \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --subnet=subnet-mgmt \
  --tags=bastion
```

---

## 🔍 Verification & Connectivity Testing

1. Connect to `vm-bastion` via Cloud Shell SSH:
```bash
gcloud compute ssh vm-bastion --zone=us-central1-a
```

2. From `vm-bastion`, ping `vm-internal-1` and `vm-internal-2` using their private IP addresses:
```bash
ping -c 3 10.10.10.2
ping -c 3 10.10.20.2
```

Expected output:
```text
3 packets transmitted, 3 received, 0% packet loss
```
