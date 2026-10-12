# Exercise 2: Make a small change

**Goal:** feel the edit -> plan -> apply loop on something low-risk, and see how a
variable change ripples through.

## Do this

1. In `terraform.tfvars`, set `enable_web_srv = true`.
2. **Predict:** how many new resources will that add? Which ones? (Look at
   `web-srv.tf` and count the `resource` blocks gated by the flag.)
3. Run `terraform plan`. Check your prediction against the `+` lines.
4. If (and only if) you actually want web-srv running right now, `terraform apply`.
   Otherwise set it back to `false` - the point was to read the plan.

## Then try

- Change `vm_size_linux` to a different B-series size and `plan` again. Notice
  Terraform wants to *change* the VM, not recreate it (a `~`). Why is resizing
  a change and not a destroy-and-create?
- Change `admin_source_ip` to a different value and `plan`. Which single resource
  updates? (This is the RDP firewall rule - the most security-relevant line in
  the whole project.)

## Why this matters

Every change is visible, reviewable and reversible. Compare that to clicking in
the portal, where a change leaves no record and the next person has no idea what
you did or why. "It's all in version control" is the whole point.
