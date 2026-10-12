# Answer key: Make a scan show up as a network alert with Suricata

## What happened
The staging script on wazuh (10.0.1.10) scanned linux-srv (10.0.1.30): a SYN scan
of the top 1000 ports, then version detection on the open ones. linux-srv's UFW
dropped most of it (C1's evidence), but Suricata reads packets as they arrive,
before the firewall, so it saw every attempt.

## Why the published rules may stay quiet
The lab setup sets `HOME_NET` to the lab VNet (10.0.0.0/16), and `EXTERNAL_NET`
is `!$HOME_NET`. The scanner is inside `HOME_NET`. Emerging Threats' scan rules
are mostly written `$EXTERNAL_NET -> $HOME_NET`, so an inside scanner doesn't
match them. You may still see a few alerts from rules written for `any` source:
note which, if any. Either way the finding is the same: the ruleset assumes the
danger comes from outside, and lateral scanning needs its own rule.

## The fix
On linux-srv, add to `/etc/suricata/rules/local.rules`:

```
alert tcp $HOME_NET any -> $HOME_NET any (msg:"LAB possible port scan inside the lab"; flow:to_server; flags:S,12; threshold:type both, track by_src, count 20, seconds 10; classtype:attempted-recon; sid:9000100; rev:1;)
```

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml && sudo systemctl restart suricata
```

- `flags:S,12` matches connection openings (SYN), ignoring two rarely used flag bits.
- `threshold: type both, track by_src, count 20, seconds 10` means: once a source
  has opened 20 connections within 10 seconds, alert **once** for that window. With
  `detection_filter` instead, it alerts on every connection after the 20th:
  hundreds of alerts for one scan.
- 20 in 10 seconds is well above anything normal in this lab (one SSH session,
  agent traffic that's already established) and far below a scan.

This rule was tested on Suricata 7.0.3 (Ubuntu 24.04's version): 10 connections
raised nothing, 40 raised exactly one alert.

On wazuh, add to `/var/ossec/etc/rules/local_rules.xml`:

```xml
<group name="lab,ids,">
  <rule id="100320" level="10">
    <if_sid>86601</if_sid>
    <field name="alert.signature_id">^9000100$</field>
    <description>Lab: Suricata saw a port scan inside the lab from $(src_ip)</description>
    <mitre>
      <id>T1046</id>
    </mitre>
  </rule>
</group>
```

And a test, for example `lab/wazuh/tests/my-rules.tests`: copy the alert line
from linux-srv's eve.json as `log:`, with `rule: 100320` and `level: 10`. This
Wazuh rule was checked with wazuh-logtest on Wazuh 4.12: the scan alert gave
100320 at level 10, and other Suricata alerts stayed at 86601, level 3.

## Answers to the mission
1. Before your rule: Suricata saw the traffic but raised few or no alerts for it.
2. Scanner and target are both `HOME_NET`; the scan rules expect `EXTERNAL_NET`.
3. and 4. The rule above; quiet for a handful of connections, one alert for the scan.
5. The Wazuh rule and test above.
6. Verify passes.

**Predict:** one per scan (per window). That's `threshold: type both`;
`detection_filter` would alert on every packet over the count.

## MITRE ATT&CK
T1046 Network Service Discovery.

## Common mistakes
- Setting `EXTERNAL_NET` to `any` to make the published rules fire. It works,
  but every internal connection now counts as "from outside", which floods you.
- A rule without a threshold: one alert per packet.
- Forgetting `suricata -T` and restarting into a broken config.
- Not raising it in Wazuh, so a level-3 alert drowns among the rest.

## Interview talking point
"I added Suricata to my lab and found that the public scan signatures assume the
attacker is outside the network, so a scan from an internal machine went
unnoticed. I wrote a local threshold rule that alerts once per scan, proved it
stayed quiet on normal traffic, and chained a Wazuh rule to raise it to high
severity, with a regression test."
