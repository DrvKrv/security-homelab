# Exercise 4: Find and fix a misconfiguration (the cloud-security skill)

**Goal:** catch a dangerous setting in the code *before* it's ever built, using a
scanner - exactly what a cloud-security reviewer does.

This is the highest-value habit in the whole lab-as-code track. Most real cloud
breaches aren't clever hacks; they're a setting left open by accident. When the
setting lives in code, a scanner can catch it in seconds, and you fix a file
instead of cleaning up a breach.

## The scanners

Both are free and read your `.tf` files without touching Azure. Pick one:

```bash
# tfsec (simple, fast)
docker run --rm -v "$PWD:/src" aquasec/tfsec /src --exclude-path answers

# or Checkov (more checks, nicer output)
docker run --rm -v "$PWD:/src" bridgecrew/checkov -d /src --skip-path answers
```

Both scanners also read sub-folders. The exclude/skip flag keeps the answer key
in `answers/` out of your results.

## First, the baseline

Run the scanner on `infra/` as it stands. **Don't assume it comes back clean.**
tfsec runs fewer checks and may pass everything. Checkov runs more and will
report a handful of findings, even though the firewall only allows RDP from your
single IP. That's normal: scanners compare you with a generic "ideal" setup and
don't know what your lab is for. Use Checkov for this step, so you have
something to decide about.

For each finding, write one line in your notes:

1. **What it says** in your own words, and which resource it's about.
2. **Fix or accept?** Fix it if the fix is cheap and doesn't break the lab. Accept
   it if the setting is there on purpose or the fix costs more than the risk.
3. **Why.** One sentence. "Accepted because..." with a reason someone else could
   check is a real security decision. "Ignored" is not.

To record an accepted finding in the code itself, put a skip comment on the
first line inside the resource block. For Checkov: `#checkov:skip=<CHECK_ID>:<your reason>`. For
tfsec: `#tfsec:ignore:<rule-id>` on the line above the setting. Re-run the
scanner: the finding moves from failed to skipped, with your reason attached. This is
**risk acceptance**, and the reason travels with the code for the next reviewer.

## Now plant a mistake and catch it

Here is a BAD rule. It opens RDP to the entire internet - the classic blunder.
**Do not keep this.** Add it temporarily to a scratch file to see the scanner
catch it:

```hcl
# scratch-bad.tf  -- DELETE after this exercise. Opens RDP to the whole internet.
resource "azurerm_network_security_group" "bad_example" {
  name                = "bad-example-nsg"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  security_rule {
    name                       = "DANGER-rdp-from-anywhere"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"   # <-- "*" = the whole internet. This is the bug.
    destination_address_prefix = "*"
  }
}
```

1. Save that as `scratch-bad.tf`, run the scanner again. On top of your
   baseline, it should flag a new open RDP / "public ingress" / "0.0.0.0/0" style finding. Read exactly what it says.
2. **Fix it** the right way: change `source_address_prefix` to `var.admin_source_ip`.
   Re-run the scanner - the finding is gone.
3. Delete `scratch-bad.tf` (`rm scratch-bad.tf`). Run `terraform plan` to confirm
   nothing from it is left.

## Write it up

This is a perfect short case-study entry: "I added a pre-deployment IaC scan that
catches an internet-exposed RDP rule before it's applied." That's a real
cloud-security control, and it pairs with the optional DevSecOps pipeline later
(lesson G4 in the lesson grid). Add your baseline notes too: "I reviewed every
finding and fixed or accepted each one with a written reason."
