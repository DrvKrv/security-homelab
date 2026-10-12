# Exercise 1: Read and predict

**Goal:** understand what's here before you change anything, and learn the one
habit that keeps infrastructure-as-code safe: always read the plan.

## Do this

1. Open these files in order and read every comment:
   `versions.tf` -> `variables.tf` -> `network.tf` -> `firewall.tf` -> `core.tf`.
2. In Azure Cloud Shell (it has Terraform built in and you're already signed in):
   ```bash
   git clone https://github.com/DrvKrv/security-homelab.git
   cd security-homelab/infra
   cp terraform.tfvars.example terraform.tfvars
   # edit terraform.tfvars with your real subscription ID, home IP, SSH public key
   terraform init
   ```
3. **Predict before you run:** with both stage flags `false`, how many *new*
   resources should `terraform plan` want to create? (Hint: the core VMs already
   exist but Terraform doesn't know that yet. So what will it think?)
4. Now run it:
   ```bash
   terraform plan
   ```

## What you should notice

Terraform will propose to **create** the core VMs, because it doesn't yet know
they already exist in Azure. That's expected, and it's exactly why you don't
`apply` yet - you'd get duplicate-name errors or a mess. Exercise 5 (import) is
how you fix that. For now you're just learning to *read* a plan: every `+` is a
create, `~` is a change, `-` is a destroy. The number at the bottom is the
summary.

## The habit

`plan` shows you what `apply` would do, before it does it. A security engineer
reads the plan every single time. A `-` (destroy) you didn't expect is how people
accidentally delete production. You will never `apply` without reading `plan`.
