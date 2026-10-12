# Publishing Checklist: Keep Secrets Out of This Repo

This repository is public. Run through this list **before every commit** that
adds logs, configs or screenshots.

## Never commit

- [ ] Passwords of any kind (Wazuh admin password printed by the installer, Windows and Linux account passwords)
- [ ] `wazuh-install-files.tar`, `wazuh-passwords.txt`, `client.keys`, or any agent enrollment password / key
- [ ] Private keys (`*.key`, `*.pem`, SSH `id_*` files without `.pub`), certificates with private keys (`.p12`, `.pfx`)
- [ ] API tokens, cloud credentials, `.env` files
- [ ] VM disk images, snapshots, memory files, ISOs
- [ ] Raw `.evtx` exports or full packet captures: publish short, redacted excerpts instead
- [ ] Azure identifiers: subscription ID, tenant ID, full resource IDs, the VMs' public IP address
- [ ] Your real home network details: home public IP (it appears in the NSG rule), router model, Wi-Fi name, MAC addresses of real devices
- [ ] Personal information: email, real name of other people, serial numbers, license keys

The [`.gitignore`](../.gitignore) blocks the most common file types, but it
cannot catch a password pasted into a Markdown file. You still need to check.

## Before committing a screenshot

- [ ] Crop to the part that proves the point
- [ ] Blur or black out: passwords, tokens, hostnames of real devices, your Mac's username if you prefer, browser bookmarks/tabs
- [ ] Lab private IPs (10.0.1.x) are fine to show: they only exist inside the VNet
- [ ] Black out the Azure portal header (account email, directory name) and any subscription ID or public IP
- [ ] Save into `docs/evidence/` with a descriptive name (`IR-2026-001-alert.png`)

## Before committing a config file or log excerpt

- [ ] Replace secrets with a placeholder like `<REDACTED>` or `<AGENT_KEY>`
- [ ] Remove lines you don't need

## Quick scan before you push

From the repo folder in Terminal:

```bash
# What am I about to commit?
git status
git diff --staged

# Search staged changes for likely secrets
git diff --staged | grep -inE 'password|passwd|secret|token|api[_-]?key|BEGIN .*PRIVATE KEY'
```

If anything sensitive appears, unstage it (`git restore --staged <file>`) and fix it first.

## If a secret was already pushed

Deleting it in a new commit is **not** enough: it stays in Git history.

1. **Change the secret immediately** (reset the password, regenerate the key). This is the step that actually protects you.
2. Then remove it from history (GitHub docs: "Removing sensitive data from a repository"), or ask Claude for help.
