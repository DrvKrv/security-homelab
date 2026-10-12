# Exercise 5: Import your existing VMs (the hardest, most real-world step)

**Goal:** bring the three VMs you built by clicking under Terraform's control,
without deleting and recreating them. This is a genuine job skill - most
companies and city IT departments have hand-built systems to adopt.

**Do this one last,** once you're comfortable with plan/apply, and when you have
time to go slowly. Rushing an import is how you accidentally destroy a VM.

## The idea

`core.tf` already describes your three VMs. But Terraform's *state* (its record
of what it manages) is empty for them, so it thinks they need creating. Importing
tells Terraform "this code block IS that real resource," so state and reality line up.

## The loop, one resource at a time

1. Find the resource's Azure ID (its full path). For example, the resource group:
   ```bash
   az group show --name homelab-rg --query id -o tsv
   ```
2. Import it into the matching code block:
   ```bash
   terraform import azurerm_resource_group.lab \
     /subscriptions/<sub-id>/resourceGroups/homelab-rg
   ```
3. Run `terraform plan`. You want it to say **no changes**. If it shows `~`
   (change) lines, your code doesn't match reality yet - adjust the code (a size,
   an image SKU, a disk type) until `plan` is clean. **Never** let it show a `-`
   (destroy) for a VM you care about.
4. Repeat for the VNet, subnet, each NIC, each NSG, each public IP, each VM.

Work from the outside in: resource group, then network, then NICs/NSGs, then VMs.
Go one at a time and re-run `plan` after each. A good order and the exact `az ...`
query for each type is worth writing into your own notes as you go.

## If plan wants to destroy something

Stop. A destroy means the code and the real VM differ in a way Terraform can only
fix by replacing it. Figure out which attribute differs (the plan names it) and
change the **code** to match the real VM. Importing should never cost you a VM.

## The payoff

When `terraform plan` finally says "No changes. Your infrastructure matches the
configuration," your entire lab is now described in code and reproducible. Say
that in an interview and you've just described how real cloud teams operate.
