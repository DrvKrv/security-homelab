# Stage 2: web-srv (the company's website and apps)

This stage gives Acme Corp a web presence and gives you web-layer logs to defend:
a company website, an internal employee portal, and a dedicated training target to
practise attacking and fixing. It's the biggest single jump in realism after Phase 1.

**Do Phase 1 first.** Finish the incidents and the case study before starting here,
and don't let this delay applying to internships.

## What you'll have running on web-srv

| Piece | URL (from win-srv) | What it's for |
|---|---|---|
| Company website | `http://<web-srv-ip>/` | An ordinary static site - "normal" traffic |
| Employee portal | `http://<web-srv-ip>/portal/` | A normal login app that produces realistic auth logs |
| Training target | `http://<web-srv-ip>:3000/` | OWASP Juice Shop - the thing you practise on |

The portal and website are deliberately **ordinary, reasonably-secure apps**. The
thing you attack is the **training target**, which is a well-known, purpose-built
teaching application pulled from its official image - not something hand-written
here. That's on purpose: you learn against a documented, widely-used target instead
of a homemade one, and you keep a clear line between "the app I defend" and "the app
I attack."

## The security ideas in this stage

- **Attack surface.** Adding a web server adds doors. Which ports are open? Who can
  reach them? (Answer: only the lab, because web-srv has no public IP.)
- **Web vs. host logs.** Phase 1 was host logs (who logged in). Now you also get
  *web* logs (every HTTP request). Different attacks show up in different places.
- **Defence in depth.** The portal hashes passwords and uses parameterised queries;
  the training target does not. Comparing them is half the lesson.

> **Predict first:** before you run anything, where would a failed *portal* login
> show up - the web access log, the portal auth log, or both? Why? (Check yourself
> after step 4 with `verify.sh`.)

## Before you start: check your Azure core quota

Student subscriptions cap how many VM cores can run in a region. Your three current
VMs already use 6. In the portal: **Subscriptions > Usage + quotas >** search
"Total Regional vCPUs" for West US 2. If your limit is 6, stop a VM (or request
more) before creating web-srv.

## Steps

### 1. Create the VM (the only clicking)

In the Azure portal, create a VM like `linux-srv` (see `lab/azure/` and
`azure-setup-plan.md`):

- Resource group `homelab-rg`, region West US 2, subnet `lab-subnet`.
- **No public IP.** (If the portal adds one by default, remove it.)
- Static private IP `10.0.1.40`, name `web-srv`, Ubuntu 24.04, size B2as_v2 or similar.
- Auto-shutdown on, so an idle VM stops burning Azure credit.

> **Predict:** why does web-srv not get a public IP, when win-srv does? What would
> change about your risk if it did?

### 2. Get in and get the code

```bash
# From your machine: RDP to win-srv, then from win-srv:
ssh azureuser@10.0.1.40
sudo git clone https://github.com/DrvKrv/security-homelab.git /opt/security-homelab
cd /opt/security-homelab/lab/stages/2-web-srv
```

(Public repo, so no login or token needed. `/opt/security-homelab` is the path the
Wazuh file-integrity rule expects; use it so FIM works without editing config.)

### 3. Run the installer

```bash
sudo bash install.sh
```

It refuses to run if the VM has a public IP, installs Docker, generates a random
fake company, seeds the portal (hashed passwords only), and starts the three
containers. First run pulls images, so give it a few minutes.

### 4. Check it

```bash
bash verify.sh
```

Every line should say PASS (the training target can take ~30s on first boot; re-run
if it's the only failure). Then browse the three URLs from win-srv.

### 5. Wire up Wazuh

Follow `wazuh/README.md`: install the agent on web-srv, add the `web` group config
and the portal rules on the manager. Then log into the portal with a wrong password
a few times and watch rule **100401** (failed login) appear in the dashboard.

## What to practise here (your actual job)

1. **Recon:** from linux-srv, scan web-srv (authorized, lab-only) and note the open
   ports. Does Wazuh see it?
2. **Web attacks:** work through the training target's built-in challenges. Find
   each one in the web access log afterwards.
3. **Vulnerability research:** check the versions of the software on web-srv
   (`wodle syscollector` feeds Wazuh's vuln scan). Pick a real CVE, note its CVSS,
   and write it up in `docs/cve-research-worksheet.md`.
4. **Fix and verify:** patch something, re-scan, show the finding is gone.
5. **Write it up:** one short incident or detection note in `docs/incidents/`,
   redacted per the publishing checklist.

## Housekeeping

- **Between exercises:** `bash reset.sh` stops the stack and rolls a fresh company.
- **Done for now:** stop/deallocate web-srv in the portal to save credit. The code
  stays in the repo, so `install.sh` rebuilds it in minutes next time.
- **Done for good:** delete the VM. Nothing is lost.

See `scenarios/` and `noise/` for what's coming next (both are placeholders today).
