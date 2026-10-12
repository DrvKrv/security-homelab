# Wazuh setup for web-srv

Two halves: install the **agent** on web-srv, and add the **web group config +
rules** on the manager (the `wazuh` VM). Do them in this order.

## 1. Install the agent on web-srv

Same as the other agents. On the Wazuh dashboard: **Agents > Deploy new agent**,
pick Linux/DEB, server address `10.0.1.10`, group `web` (create it in step 2 first,
or assign later). Copy the command it gives you and run it on web-srv, then:

```bash
sudo systemctl enable --now wazuh-agent
```

The agent should show **Active** within a minute.

## 2. Add the "web" group and config on the manager (wazuh VM)

```bash
# Create the group and drop in the centralized config.
sudo /var/ossec/bin/agent_groups -a -g web -q
sudo install -m 660 -o wazuh -g wazuh agent.conf /var/ossec/etc/shared/web/agent.conf

# Assign web-srv's agent to the web group (find its ID with: agent_control -l).
sudo /var/ossec/bin/agent_groups -a -i <AGENT_ID> -g web -q
```

Then add the decoder and rules (append, don't overwrite):

```bash
cat local_decoder.xml | sudo tee -a /var/ossec/etc/decoders/local_decoder.xml
cat local_rules.xml   | sudo tee -a /var/ossec/etc/rules/local_rules.xml
sudo /var/ossec/bin/wazuh-analysisd -t && sudo systemctl restart wazuh-manager
```

`wazuh-analysisd -t` checks every rule and decoder first. If it prints an error,
don't restart: a manager restarted with a broken rule file stops processing
events. Fix the file (or remove what you appended) and test again.

```bash
# Optional: run the lab's rule tests (lab/wazuh/test-rules.sh) to check that
# the portal rules decode and fire as expected.
sudo bash ../../../wazuh/test-rules.sh
```

## 3. Confirm it works

On the manager, test the decoder and rules without touching web-srv:

```bash
echo '2026-10-12T00:00:00Z acme-portal AUTH result=failure user=demo.user src=10.0.1.20' \
  | sudo /var/ossec/bin/wazuh-logtest
```

You should see it decode `status=failure`, `srcuser=demo.user`, `srcip=10.0.1.20`
and match rule **100401**. Then, on web-srv, open the portal and type a wrong
password a few times; within a minute you should see rule **100401** (and, after
six tries, the brute-force rule **100402**) in the dashboard.

## What you're collecting, and why

| Source | File | Tells you |
|---|---|---|
| Portal auth | `/var/log/acme-portal/auth.log` | who logged in or failed, and from where |
| Web access | `/var/log/acme-web/access.log` | every HTTP request to the site and portal |
| Web errors | `/var/log/acme-web/error.log` | app/proxy errors, some attack side-effects |
| journald | (automatic) | SSH, sudo, kernel/firewall on the VM itself |

The **training target** (Juice Shop on :3000) is intentionally not wired into
custom rules yet - detecting attacks against it is the exercise. Start from its
HTTP requests in the web access log.
