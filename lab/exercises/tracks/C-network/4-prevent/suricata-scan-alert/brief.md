# C4 Prevent: Make a scan show up as a network alert with Suricata

> Needs the detection add-ons (unit 4): Suricata on linux-srv, set up with
> `lab/runbooks/06-detection-engineering.md`. Staging runs the lab's authorized
> scan from the wazuh VM; you work on linux-srv and the wazuh VM.

## The concept
In C1 you found a port scan through **host** evidence: linux-srv's firewall
logged what it dropped. A **network intrusion detection system** (IDS) like
Suricata looks at the traffic itself and compares it with **signatures**: rules
that describe what known attacks look like on the wire. The two views catch
different things, and a good defender uses both.

Signatures are written with assumptions, for example about which networks are
"yours" and where attacks come from. A rule can be perfectly correct and still
stay quiet in your network, because your situation doesn't match its
assumptions. Knowing your tools' assumptions is part of the job.

When the published rules don't cover your case, you write a **local rule**.
Suricata can count events: "if one source sends this many new connections in
this many seconds, alert". Count too low and normal traffic sets it off; too high
and a slow scan slips under it.

Finally, Wazuh gives every Suricata alert the same low level. If this one
matters to you, raise it in Wazuh, the same way you chained rules in B4.

## Your mission
1. Stage the scan. Does Suricata raise any alert for it? Look in its own log
   on linux-srv and in Wazuh.
2. Explain why the published rules did or didn't fire, using the network
   variables in Suricata's config.
3. Write a local Suricata rule that alerts **once** when one lab machine opens
   many new connections to another in a short time. Choose the numbers and
   say why.
4. Prove it: it stays quiet for a handful of connections and fires for the scan.
5. Write a Wazuh rule that raises your Suricata alert to level 10, with an ATT&CK
   tag, and a test for it in `lab/wazuh/tests/`.
6. Run `./run.sh verify C4/suricata-scan-alert` on linux-srv.

## The analyst workflow
1. On linux-srv, read `/var/log/suricata/eve.json` for alerts around the scan.
2. In `/etc/suricata/suricata.yaml`, read `HOME_NET` and `EXTERNAL_NET`. Where do
   the scanner and the target sit in those terms?
3. Write your rule in `/etc/suricata/rules/local.rules` (the lab setup created it
   and loads it). Test the config, restart Suricata.
4. Make a few connections by hand from wazuh, then stage the scan again. Compare.
5. On wazuh, chain a rule from Wazuh's Suricata alert rule, matching your rule's
   signature id. Validate, restart, check.

## Predict before you run
The scan sends a thousand connection attempts in seconds. With a rule that counts
"20 in 10 seconds", how many alerts do you want for one scan: one, or hundreds?
Which Suricata option controls that?

## What good looks like
A case file (`../../../../case-file-template.md`) with: what Suricata did before
your rule and why, your Suricata rule with the numbers explained, the quiet test
and the loud test, your Wazuh rule and its test, the alert in Wazuh at level 10,
and a passing verify.

## Hints
1. `sudo grep '"event_type":"alert"' /var/log/suricata/eve.json | tail` shows Suricata's own alerts.
2. `EXTERNAL_NET` is `!$HOME_NET`: anything not home. The wazuh VM is home, so rules written for outside scanners don't match it.
3. Rule skeleton: `alert tcp $HOME_NET any -> $HOME_NET any (msg:"..."; flow:to_server; flags:S,12; threshold:type both, track by_src, count 20, seconds 10; sid:9000100; rev:1;)`
4. Wazuh's rule for any Suricata alert is 86601; chain with `<if_sid>86601</if_sid>` and `<field name="alert.signature_id">^9000100$</field>`.
