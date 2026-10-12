# Answer key: Block the attacking source and prove it's blocked

## What happened
The staging script on the wazuh VM (10.0.1.10) made a burst of SSH login
attempts against linux-srv (10.0.1.30): made-up usernames first, then wrong
passwords for the lab test account if linux-srv accepts passwords. Every attempt
came from one address, so a single firewall rule on linux-srv can contain it.

## The fix
On linux-srv:

```bash
sudo ufw status numbered                                  # see the order first
sudo ufw insert 1 deny log from 10.0.1.10 to any port 22 proto tcp
sudo ufw status numbered                                  # your rule is now [ 1]
```

Why each part matters:
- **`insert 1`** puts the rule above `allow from 10.0.1.0/24 to any port 22`.
  UFW stops at the first match. A plain `ufw deny ...` is appended below that
  allow, which already matches 10.0.1.10, so it would never be used. That is the
  most common mistake in this lesson, and verify catches it.
- **`from 10.0.1.10`**, not the whole subnet: you still need SSH from win-srv
  (10.0.1.20).
- **`port 22 proto tcp`**, not every port: it's the SSH guessing you're
  containing. Blocking everything from wazuh would also work and wouldn't break
  the agent (the agent connects *out* to wazuh, and replies to that are allowed),
  but a narrow rule is easier to reason about and to remove.
- **`log`**: UFW only logs packets that an explicit rule drops if the rule asks
  for it. Without `log` the block works but leaves no evidence.

## The evidence
- **Before:** from wazuh, `nc -z -w 3 10.0.1.30 22 && echo open || echo blocked`
  prints `open`. After: `blocked`.
- **Staging again** fails with a message that it can't reach SSH on
  10.0.1.30:22. The attacker's tool can't even start, so there are **no** new
  sshd login alerts.
- **Wazuh instead shows firewall blocks:** rule 100100 (or 100101) on linux-srv,
  "UFW firewall blocked a connection from 10.0.1.10 to port 22". The logs moved
  from "someone is guessing passwords" to "someone was refused at the door".
- `./run.sh verify A3/block-ssh-source` passes.

## Answers to the mission
1. Source 10.0.1.10, the wazuh VM, found in `data.srcip` on the 5710/5712 alerts
   (and 5760/5763 if passwords are on), mapped with the asset inventory.
2. and 3. The rule above, at position 1.
4. The `nc` test, the failed re-stage, and the 100100 alerts.
5. Verify passes.
6. Remove it once the cause is dealt with (here: the source is your own SIEM VM
   playing attacker; in real life, the compromised machine has been cleaned or
   rebuilt). Permanent per-address blocks pile up, get forgotten, and break
   things later when an address is reused.

**Before the next lesson,** remove the block or every SSH lesson staged from
wazuh will fail: `./run.sh reset A3/block-ssh-source` on linux-srv, or
`sudo ufw delete <number>`.

## MITRE ATT&CK
T1110.001 Brute Force: Password Guessing. The block contains it at the network level.

## Common mistakes
- `ufw deny` without `insert`: the rule lands below the subnet allow and does nothing.
- Blocking the whole subnet or all SSH: that includes win-srv, your way in.
- No `log`: the block works, but there's nothing to show in Wazuh.
- Testing only from win-srv. win-srv isn't the source; test from the source.

## Interview talking point
"I traced an SSH brute force to a single internal source and contained it with a
host firewall rule on the target. UFW is first-match, so I inserted the rule above
the existing subnet allow, kept it to one address and one port so I didn't lock
myself out, and turned on logging for it. I proved it with a connection test and
by re-running the attack: the login failures stopped and firewall-block alerts
appeared instead. I also noted it was temporary containment, not the fix."
