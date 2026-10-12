# infra/ — the lab as code (Terraform)

This folder describes your whole lab as text files, so it can be rebuilt,
reviewed and audited instead of clicked together in the portal. It's **unit 5**
of the curriculum ([docs/plan/curriculum-roadmap.md](../docs/plan/curriculum-roadmap.md)).

**Nothing here changes Azure until you run it, and it's built for you to learn,
not just run.** The network, firewall and web-srv files are written as worked
examples; you write the dc01 file yourself and fix a planted misconfiguration.

## What "infrastructure as code" means here

Instead of clicking through the Create-VM wizard (and hitting its traps — a
surprise resource group, Premium SSD, a default public IP), you declare what you
want in `.tf` files. Terraform compares your files to what's really in Azure and
makes reality match. The big wins:

- **Reproducible:** delete the lab and rebuild it identically in minutes.
- **Reviewable:** every change is a diff in Git, with a reason.
- **Safe to check:** a scanner can catch a dangerous setting in the file before
  anything is built (exercise 4).

## The files

| File | What it defines |
|---|---|
| `versions.tf` | Terraform + provider versions (pinned) |
| `providers.tf` | how Terraform talks to Azure |
| `variables.tf` | the knobs (IPs, sizes, which stages are on) |
| `network.tf` | resource group, VNet, subnet, the fixed IPs |
| `firewall.tf` | NSGs — the firewall rules (RDP from your IP only) |
| `core.tf` | your three existing VMs (you *import* these, exercise 5) |
| `web-srv.tf` | stage 2's VM — the **worked example** to model dc01 on |
| `dc01.tf.todo` | stage 3's VM — **you write this** (exercise 3) |
| `outputs.tf` | IPs/passwords printed after apply |
| `terraform.tfvars.example` | copy to `terraform.tfvars` (git-ignored) and fill in |
| `answers/dc01.tf` | the dc01 answer key — don't peek until you've tried |
| `exercises/` | the five lessons below |

## Where you run it

**Azure Cloud Shell** (the `>_` icon at the top of the portal). It has Terraform
pre-installed and is already signed in to your account, so there's nothing to
install and no credentials to manage.

```bash
git clone https://github.com/DrvKrv/security-homelab.git
cd security-homelab/infra
cp terraform.tfvars.example terraform.tfvars   # then edit it with your values
terraform init
terraform plan                                  # ALWAYS read this before apply
```

## The lessons (do them in order)

1. **`exercises/01-read-and-predict.md`** — read the files, run your first `plan`, learn to read it.
2. **`exercises/02-make-a-change.md`** — the edit → plan → apply loop on something safe.
3. **`exercises/03-write-dc01.md`** — write the dc01 file yourself from the web-srv model.
4. **`exercises/04-find-the-misconfig.md`** — catch an internet-exposed RDP rule with a scanner, and fix it.
5. **`exercises/05-import-existing-vms.md`** — bring your three hand-built VMs under code.

## Safety and secrets (this is a public repo)

- **State and secrets are git-ignored.** `terraform.tfvars` (your subscription ID,
  home IP, SSH key) and `*.tfstate` (which can hold generated passwords) never get
  committed. Only `terraform.tfvars.example`, with placeholders, is tracked.
- **No VM gets a public IP except win-srv**, and win-srv's RDP is limited to your
  home IP. Keep it that way; exercise 4 is about proving you can catch the opposite.
- **Cost:** Terraform is free; VMs cost the same whether clicked or coded. The good
  habit it makes easy: set a stage's flag back to `false` and `apply` to remove its
  VM when you're done, instead of leaving it running.

## How this fits the stages

`web-srv.tf` and `dc01.tf` create the VMs; the stage scripts already in
`lab/stages/2-web-srv/` and `lab/stages/3-dc01/` still do the setup inside them
(web-srv runs its installer automatically on first boot via cloud-init). So this
folder is the "build the box" layer; `lab/stages/` is the "set it up" layer. They
work together.

> A note on why this is worth your time: city and small-org IT runs on exactly
> this kind of reproducible, auditable infrastructure, and "I can define and
> review cloud infrastructure as code" is a strong line for a govtech founder and
> for cloud-engineer or cloud-security internships alike.
