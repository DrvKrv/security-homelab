# A4 Prevent: Auto-block a brute-forcing source with Wazuh active response

> Runs on the current lab. You configure the wazuh VM; the block lands on
> linux-srv. **Only ever test active response against linux-srv, never win-srv.**
> win-srv is your only way into the lab, and a block there could lock you out.

## The concept
So far Wazuh has only **told** you about attacks. **Active response** lets it
**act**: when a chosen rule fires, the manager tells an agent to run a command.
Wazuh ships with ready-made commands. One of them adds a firewall rule on the
agent's machine that drops all traffic from the alert's source address.

A good automatic block is **temporary**. You give it a **timeout**, and when the
time is up the agent removes the block by itself. Attackers change addresses
anyway, permanent blocks pile up and are forgotten, and if the alert was a false
alarm (a real user who kept mistyping) the damage heals on its own.

Automation needs a narrow trigger. A block that fires on the wrong alert, or on
the wrong machine, can cut off your own access. So you decide exactly which
alerts can trigger it and where it is allowed to run.

**Warning, read before staging.** The staging script runs on the wazuh VM, so the
"attacker" address is wazuh itself. When the block works, linux-srv will drop
everything from wazuh for the length of the timeout. That is the proof, and it
is safe, but wait for the block to expire (or lift it) before the next lesson.
You still reach linux-srv from win-srv, which is not blocked.

## Your mission
1. Configure an active response that blocks the source of an **SSH brute-force**
   alert on the machine that was attacked, with a **timeout**.
2. Make sure it can only be triggered by SSH alerts, never by Windows ones.
3. Stage, then prove the block: it appeared on linux-srv, connections from the
   source failed, and Wazuh recorded the response.
4. Prove the timeout: the block disappeared on its own and connections work again.
5. Decide whether to leave it on, and write down what it would affect.

## The analyst workflow
1. On wazuh, read the commands already defined in `/var/ossec/etc/ossec.conf`.
   Find the one that drops an address at the firewall and check it allows a timeout.
2. Choose the trigger: only the SSH burst alerts you met in earlier lessons.
3. Choose where it runs: the agent that raised the alert.
4. Add an active-response block, validate, restart the manager.
5. Stage. Then, from win-srv, connect to linux-srv and look at its firewall rules
   and the agent's active-response log.
6. Wait out the timeout and check the same things again.

## Predict before you run
The pretend attacker is the wazuh VM. Once linux-srv drops everything from
wazuh, what else that wazuh does with linux-srv will stop working for a while?

## What good looks like
A case file (`../../../../case-file-template.md`) with: your active-response
XML, the alert that triggered it, the firewall rule on linux-srv during the block,
the add and delete lines from the active-response log with times, and a short
paragraph on the risks of automatic blocking.

## Hints
1. On wazuh: `sudo grep -n -A4 '<command>' /var/ossec/etc/ossec.conf` lists the stock commands; the one you want is `firewall-drop`.
2. Trigger on 5712 (always fires in this staging) and 5763 (only when linux-srv accepts passwords), nothing else.
3. Use `<command>firewall-drop</command>`, `<location>local</location>`, `<rules_id>5712,5763</rules_id>` and `<timeout>300</timeout>`.
4. On linux-srv: `sudo iptables -S | grep 10.0.1.10` shows the block and `/var/ossec/logs/active-responses.log` shows add and delete.
