# Patroni PostgreSQL Automation

## Overview
This project aims to create a robust, high-availability PostgreSQL cluster using Patroni. The deployment leverages Bicep templates for infrastructure provisioning, Ansible playbooks for configuration management, and Azure DevOps pipelines for continuous integration and continuous deployment (CI/CD).

## Components

### 1. Bicep Templates
- **Virtual Machines (VMs):** Defines parameters for VM names, admin credentials, location, size, and security types. This includes conditional creation and configuration of VMs.
- **Virtual Network (VNet):** Provisions the network infrastructure necessary for VM communication.
- **Network Security Group (NSG):** Configures security rules to control traffic to and from the VMs.
- **Public IP Addresses:** Ensures public IPs are created before deploying the load balancer.
- **Load Balancer:** Initially deploys the load balancer without backend pool configurations, and then updates it to include VMs.

### 2. Ansible Playbooks
- Used for provisioning and configuring the PostgreSQL cluster.
- Deploys and configures HAProxy, etcd, Patroni, and PostgreSQL on the infrastructure nodes.
- Ensures the cluster is highly available, using HAProxy as a central point for database connection.

### 3. Azure DevOps
- **Version Control:** Manages code using Visual Studio Code (VSC) integrated with Azure DevOps.
- **CI/CD Pipeline:** Automates the deployment process using Azure DevOps pipelines, ensuring that infrastructure and configurations are continuously integrated and deployed.

## Architecture
- **Infrastructure Nodes:** These are VMs that host the PostgreSQL cluster, configured using Ansible.
- **Load Balancer (NLB):** Acts as a central point for connecting to the database, ensuring high availability and failover capabilities.
- **Backend Pools:** NICs are configured to be part of the load balancer's backend pool, enabling distribution of traffic among the database nodes.

## Project Workflow
1. **Provisioning Infrastructure:**
   - Uses Bicep templates to provision VMs, VNets, NSGs, and public IP addresses.
   - An initial load balancer is deployed without backend configurations.
2. **Deploying Configuration:**
   - Ansible playbooks are executed to set up HAProxy, etcd, Patroni, and PostgreSQL on the infrastructure nodes.
3. **Final Load Balancer Configuration:**
   - The load balancer is updated to include VMs in the backend pool, ensuring traffic distribution and high availability.
4. **Automated Deployment:**
   - The entire process is automated using Azure DevOps pipelines, enabling continuous deployment and integration, ensuring that any updates or changes are seamlessly deployed.

## Inspiration and Purpose
This project draws inspiration from practical, real-world scenarios encountered in my current role. It showcases my ability to design and implement a complete, automated, high-availability PostgreSQL cluster from scratch, emphasizing the use of modern DevOps practices and tools.

## Things I've Learned
1. **Network Security Group (NSG) Configuration:**
   - **Challenge:** By default, NSGs deny all traffic. I had to add elevated permissions to allow necessary traffic for the VMs.
   - **Solution:** Configured NSG rules to permit the required inbound and outbound traffic, ensuring smooth communication between components.
2. **Load Balancer and NIC Provisioning:**
   - **Challenge:** Avoiding circular dependencies when configuring load balancer backend pools.
   - **Solution:** Implemented a step-by-step deployment process:
     - **Step 1:** Provision the load balancer without backend pool configurations.
     - **Step 2:** Create and configure NICs for the VMs, referencing the backend pool IDs.
     - **Step 3:** Update the load balancer to include the backend pools and associate the NICs' IP configurations.
3. **Automation with Azure DevOps:**
   - Leveraged Azure DevOps pipelines to automate the deployment process, ensuring consistent and repeatable deployments.
   - Integrated version control with Azure DevOps for efficient code management and tracking changes.
