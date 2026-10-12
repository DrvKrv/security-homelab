# variables.tf - the knobs for the lab.
#
# A "variable" is an input you set once (in terraform.tfvars) and reuse
# everywhere. Change it in one place and `terraform apply` updates the lab to
# match. The sensitive ones (your IP, subscription) live in terraform.tfvars,
# which is git-ignored, so they never reach the public repo.

variable "subscription_id" {
  description = "Your Azure subscription ID (from the portal, or `az account show`)."
  type        = string
}

variable "location" {
  description = "Azure region. Keep it the same as your existing lab."
  type        = string
  default     = "westus2"
}

variable "resource_group_name" {
  description = "The resource group that holds everything (so you can delete it all at once)."
  type        = string
  default     = "homelab-rg"
}

# --- network ----------------------------------------------------------------
variable "vnet_name" {
  type    = string
  default = "homelab-vnet"
}

variable "vnet_cidr" {
  description = "The whole private network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "lab_subnet_cidr" {
  description = "The subnet the VMs sit on."
  type        = string
  default     = "10.0.1.0/24"
}

# --- access -----------------------------------------------------------------
variable "admin_source_ip" {
  description = <<-EOT
    YOUR home public IP, used to allow RDP to win-srv and nothing else.
    Find it at https://ifconfig.me . If your home IP changes, update this and
    re-apply. NEVER widen this to 0.0.0.0/0 (the whole internet).
  EOT
  type        = string
}

variable "admin_username" {
  description = "The admin login created on each VM."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "Your SSH *public* key (the .pub file) for the Linux VMs. Never the private key."
  type        = string
}

# --- VM sizes (B-series v2; D-series is blocked on the student subscription) -
variable "vm_size_wazuh" {
  type    = string
  default = "Standard_B2as_v2"
}

variable "vm_size_linux" {
  type    = string
  default = "Standard_B2ats_v2"
}

variable "vm_size_windows" {
  type    = string
  default = "Standard_B2als_v2"
}

# --- which stages are switched on -------------------------------------------
# Flip these to true (in terraform.tfvars) to add a stage's VM, then `apply`.
# Flip back to false and `apply` to remove it and stop its charges.
variable "enable_web_srv" {
  description = "Stage 2: the company web server (10.0.1.40)."
  type        = bool
  default     = false
}

variable "enable_dc01" {
  description = "Stage 3: the Active Directory domain controller (10.0.1.50). You write this file."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags put on every resource, so costs are easy to find and filter."
  type        = map(string)
  default = {
    project = "security-homelab"
    managed = "terraform"
  }
}
