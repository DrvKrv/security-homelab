# Exercise 6: Split the network into zones (unit 8)

**Goal:** design a two-zone network, write half of it yourself, and *prove* that
a taken-over web server can't reach the domain controller.

**Before you start:** web-srv exists (`enable_web_srv = true`), and ideally dc01
too, so there's something worth protecting. Exercises 1 to 3 done.

## Why zones

Right now every VM sits in `lab-subnet` and Azure lets them all talk to each
other. web-srv runs a deliberately weak app, so it's the most likely machine to
be taken over. On a flat network, whoever takes it can go straight for dc01.

**Segmentation** puts machines with different risk in different zones, with a
firewall between them that only allows what the business needs:

| Zone | Subnet | Machines | Who talks to it |
|---|---|---|---|
| DMZ | 10.0.2.0/24 | web-srv (moves to 10.0.2.40) | the internal zone, for web pages; you, for SSH |
| Internal | 10.0.1.0/24 | wazuh, win-srv, linux-srv, dc01 | each other; the DMZ only for Wazuh agent traffic |

## Step 1: read and predict

Read `zones.tf` top to bottom. Before running anything, write down:
1. Which connections **from** web-srv will still work? List address and port.
2. Which connections **to** web-srv will still work, and from where?
3. Why are the Deny rules at priority 4000 needed at all, when Azure denies
   internet traffic by default anyway?

## Step 2: write the internal zone's firewall

Open `zones-internal.tf.todo`. It describes the four blocks you need, with
hints. Write them, rename the file to `zones-internal.tf`, then:

```bash
terraform fmt
terraform validate
```

Only compare with `answers/zones-internal.tf` once `validate` passes.

## Step 3: plan, read, apply

Set `enable_zones = true` in `terraform.tfvars`, then:

```bash
terraform plan
```

Read every line. Expect a new subnet, two NSGs and their associations, and a
change to web-srv's network card. Moving a VM to another subnet may make
Terraform **replace** web-srv. That's acceptable here: its installer runs again
on first boot. It would not be acceptable for dc01, so check the plan doesn't
touch dc01 or the core VMs. Then `terraform apply`.

## Step 4: prove it

1. **From web-srv** (SSH from win-srv to 10.0.2.40), run
   `bash /opt/security-homelab/lab/stages/4-zones/check-segmentation.sh`. It should PASS.
2. **Prove the PASS means something.** A port that's "blocked" because the
   machine is switched off proves nothing. From win-srv (internal), check the
   same targets answer:
   ```powershell
   foreach ($t in '10.0.1.50:389','10.0.1.50:445','10.0.1.30:22','10.0.1.10:443') {
     $h, $p = $t -split ':'; Test-NetConnection $h -Port $p -InformationLevel Quiet |
       ForEach-Object { "{0,-16} {1}" -f $t, $_ } }
   ```
   Every line should say `True`.
3. **Prove the business still works:** from win-srv's browser, the Acme site
   (`http://10.0.2.40/`) and the training app (port 3000) still load, and
   web-srv's agent is still Active in Wazuh.
4. **Break it on purpose, then fix it:** delete the `Deny-dmz-to-internal` rule
   from zones.tf, apply, and run the checker again. What still blocks the
   traffic, and why? (That's the point of Step 2.) Put the rule back and apply.

## Write it up

A short note for the case study: the two zones and why, the rules in a table,
the checker output, the `Test-NetConnection` proof, and what happened in the
break-it test. "I segmented the network so the web server can't reach the
domain controller, wrote the firewall rules as code, and proved it from both
sides" is a strong interview line.

## Things to know

- Azure can't show you traffic between VMs the way a switch's mirror port can,
  so you prove segmentation by testing connections, not by watching packets.
- The NIC-level NSGs from earlier files still apply. Traffic has to pass the
  subnet NSG *and* the NIC NSG.
- To undo: `enable_zones = false` and apply. web-srv moves back to 10.0.1.40.
