#!/bin/bash

# Welcome message
echo "============================================"
echo "Welcome to Dr. Abhishek Cloud Tutorials!"
echo "Subscribe to the channel:"
echo "https://www.youtube.com/@drabhishek.5460/videos"
echo "============================================"
echo ""

# Enable Compute Engine API
echo "Enabling Compute Engine API..."
gcloud services enable compute.googleapis.com --project=$DEVSHELL_PROJECT_ID

sleep 30

# Create directory and set up Terraform configuration
echo "Setting up Terraform configuration..."
mkdir tfnet
cd tfnet

# Create terraform state backup file
cat > terraform.tfstate.backup <<EOF
[Previous terraform.tfstate.backup content remains exactly the same...]
EOF

# Create current terraform state file
cat > terraform.tfstate <<EOF
[Previous terraform.tfstate content remains exactly the same...]
EOF

# Create provider configuration
cat > provider.tf <<EOF
provider "google" {}
EOF

# Create privatenet configuration
cat > privatenet.tf <<EOF
# Create privatenet network
resource "google_compute_network" "privatenet" {
  name                    = "privatenet"
  auto_create_subnetworks = false
}

# Create privatesubnet-us subnetwork
resource "google_compute_subnetwork" "privatesubnet-us" {
  name          = "privatesubnet-us"
  region        = "$REGION_1"
  network       = google_compute_network.privatenet.self_link
  ip_cidr_range = "172.16.0.0/24"
}

# Create privatesubnet-second-subnet subnetwork
resource "google_compute_subnetwork" "privatesubnet-second-subnet" {
  name          = "privatesubnet-second-subnet"
  region        = "$REGION_2"
  network       = google_compute_network.privatenet.self_link
  ip_cidr_range = "172.20.0.0/24"
}

# Create a firewall rule to allow HTTP, SSH, RDP and ICMP traffic on privatenet
resource "google_compute_firewall" "privatenet-allow-http-ssh-rdp-icmp" {
  name = "privatenet-allow-http-ssh-rdp-icmp"
  source_ranges = [
    "0.0.0.0/0"
  ]
  network = google_compute_network.privatenet.self_link
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3389"]
  }
  allow {
    protocol = "icmp"
  }
}

# Add the privatenet-us-vm instance
module "privatenet-us-vm" {
  source              = "./instance"
  instance_name       = "privatenet-us-vm"
  instance_zone       = "$ZONE_1"
  instance_subnetwork = google_compute_subnetwork.privatesubnet-us.self_link
}
EOF

# Create mynetwork configuration
cat > mynetwork.tf <<EOF
# Create the mynetwork network
resource "google_compute_network" "mynetwork" {
  name                    = "mynetwork"
  auto_create_subnetworks = true
}

# Create a firewall rule to allow HTTP, SSH, RDP and ICMP traffic on mynetwork
resource "google_compute_firewall" "mynetwork-allow-http-ssh-rdp-icmp" {
  name = "mynetwork-allow-http-ssh-rdp-icmp"
  source_ranges = [
    "0.0.0.0/0"
  ]
  network = google_compute_network.mynetwork.self_link
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3389"]
  }
  
  allow {
    protocol = "icmp"
  }
}

# Create the mynet-us-vm instance
module "mynet-us-vm" {
  source              = "./instance"
  instance_name       = "mynet-us-vm"
  instance_zone       = "$ZONE_1"
  instance_subnetwork = google_compute_network.mynetwork.self_link
}

# Create the mynet-second-vm instance
module "mynet-second-vm" {
  source              = "./instance"
  instance_name       = "mynet-second-vm"
  instance_zone       = "$ZONE_2"
  instance_subnetwork = google_compute_network.mynetwork.self_link
}
EOF

# Create managementnet configuration
cat > managementnet.tf <<EOF
# Create managementnet network
resource "google_compute_network" "managementnet" {
  name                    = "managementnet"
  auto_create_subnetworks = false
}

# Create managementsubnet-us subnetwork
resource "google_compute_subnetwork" "managementsubnet-us" {
  name          = "managementsubnet-us"
  region        = "$REGION_1"
  network       = google_compute_network.managementnet.self_link
  ip_cidr_range = "10.130.0.0/20"
}

# Create a firewall rule to allow HTTP, SSH, RDP and ICMP traffic on managementnet
resource "google_compute_firewall" "managementnet_allow_http_ssh_rdp_icmp" {
  name = "managementnet-allow-http-ssh-rdp-icmp"
  source_ranges = [
    "0.0.0.0/0"
  ]
  network = google_compute_network.managementnet.self_link
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3389"]
  }
  allow {
    protocol = "icmp"
  }
}

# Add the managementnet-us-vm instance
module "managementnet-us-vm" {
  source              = "./instance"
  instance_name       = "managementnet-us-vm"
  instance_zone       = "$ZONE_1"
  instance_subnetwork = google_compute_subnetwork.managementsubnet-us.self_link
}
EOF

# Create instance module directory and configuration
echo "Creating instance module..."
mkdir instance

cat > instance/main.tf <<EOF
variable "instance_name" {}
variable "instance_zone" {}
variable "instance_type" {
  default = "e2-medium"
}
variable "instance_subnetwork" {}

resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  zone         = var.instance_zone
  machine_type = var.instance_type
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    subnetwork = var.instance_subnetwork
    access_config {
      # Allocate a one-to-one NAT IP to the instance
    }
  }
}
EOF

# Format and initialize Terraform
echo "Initializing and applying Terraform configuration..."
terraform fmt

terraform init

terraform plan

echo "============================================"
echo "Applying Terraform configuration..."
echo "This will create networks, subnets, firewall rules, and VM instances"
echo "============================================"

terraform apply -auto-approve

echo ""
echo "============================================"
echo "Infrastructure deployment complete!"
echo "Thank you for following Dr. Abhishek Cloud Tutorials!"
echo "Don't forget to subscribe: https://www.youtube.com/@drabhishek.5460/videos"
echo "============================================"
