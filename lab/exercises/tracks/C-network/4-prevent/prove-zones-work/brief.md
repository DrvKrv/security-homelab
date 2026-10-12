# C4 Prevent: Prove the split network works: web-srv can't reach dc01

> Needs network zones (unit 8). Read it any time. You build the zones with
> `infra/exercises/06-network-zones.md`, then come back to prove them;
> `./run.sh verify` runs on web-srv.

## The concept
A **flat network** lets every machine talk to every other one. That's
convenient until one machine is taken over: then the attacker can reach
everything else from it. Moving from one machine to the next is called
**lateral movement**, and it's how a small foothold becomes a company-wide
breach.

**Segmentation** splits the network into **zones** by risk, with a firewall
between them. The machine most exposed to attack (here, web-srv with its weak
training app) goes in a **DMZ** (demilitarised zone). The machines that hold the
keys (dc01, the SIEM, your jump host) stay in an **internal** zone. Between them,
the firewall allows only what the business needs and refuses the rest. That's
**default deny**.

A segmentation design is a claim. Your job is to **prove** it from the side an
attacker would stand on, and to prove your proof means something: a connection
that fails because the target was switched off proves nothing about the
firewall.

## Your mission
1. Build the two zones with exercise 06, including the internal firewall you
   write yourself.
2. From web-srv, show which internal addresses and ports it can still reach,
   and that each one is something the design meant to allow.
3. Show that dc01's services can't be reached from web-srv.
4. Show that the same dc01 services **do** answer from the internal zone, so
   the block is the firewall, not a switched-off machine.
5. Show that the business still works: the website loads for staff, and
   web-srv still reports to Wazuh.
6. Remove one of the two layers on purpose. Does the other still hold? Then put
   it back.
7. Run `./run.sh verify C4/prove-zones-work` on web-srv.

## The analyst workflow
1. Write your intended rules as a table first: from, to, port, allow or deny,
   and why.
2. Compare the table with what Terraform will build (`terraform plan`).
3. Test from the DMZ side, then from the internal side, with the same targets.
4. In the Azure portal, open web-srv's network card and read its **effective
   security rules**: what Azure actually applies, all layers combined.
5. Break one layer, retest, restore, retest.

## Predict before you run
With both firewall layers in place, you delete the DMZ's own deny rule. Which
connections from web-srv start working again, if any? Why?

## What good looks like
A case file (`../../../../case-file-template.md`) with your rule table, the
checker output from web-srv, the matching test from the internal side, the
effective security rules screenshot, the break-one-layer result, and a passing
verify.

## Hints
1. `bash lab/stages/4-zones/check-segmentation.sh` on web-srv runs the whole DMZ-side test for you.
2. On win-srv, `Test-NetConnection 10.0.1.50 -Port 389` should say `True`; from web-srv the same port must fail.
3. Portal: web-srv > Networking > the network interface > Effective security rules.
4. With only the internal firewall left, traffic from the DMZ is still refused at the internal subnet; that's defence in depth.
