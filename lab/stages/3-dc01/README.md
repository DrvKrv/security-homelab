# Stage 3: dc01 (Active Directory - the company's accounts)

This stage adds a Windows **domain controller**, `dc01`, and turns Acme into a
real-looking company with central accounts: staff log in with domain usernames,
groups control access, and identity events flow into Wazuh. Almost every real
company runs Active Directory, and most real breaches involve abusing accounts in
it - so this is the stage that makes your lab look like somewhere people actually
work.

**Do stage 2 first.** It's a bigger lift, and the fake company data lines up with it.

## The security ideas in this stage

- **Central identity.** Instead of local accounts on each box, one directory holds
  everyone. That's convenient *and* a bigger prize for an attacker.
- **Least privilege.** Who's in `IT-Admins`? Should they be? Spotting over-broad
  rights is a real audit task.
- **Identity attacks.** Password spraying, Kerberoasting, and sneaky group changes
  all live here. You'll detect them in Wazuh in later stages; for now you build the
  directory they happen in.

> **Predict first:** if an attacker steals one ordinary employee's password, what
> can they reach in a domain that they couldn't on a single standalone server? Why
> is a domain controller the machine you protect most?

## Cost note

dc01 is a Windows VM, so it costs a bit more per hour than the Linux ones (the
Windows license). Deallocate it when you're not using it, and the disk is the only
thing that keeps charging. Check your regional vCPU quota first (see stage 2's
README) - a 4th or 5th running VM may hit the student-subscription core cap.

## Steps

### 1. Create the VM

In the Azure portal, create a Windows Server 2025 VM like win-srv:

- Resource group `homelab-rg`, subnet `lab-subnet`, **no public IP**.
- Static private IP `10.0.1.50`, name `dc01`, size B2als_v2 or similar.
- Auto-shutdown on.

> **Predict:** why does dc01 get no public IP at all, when win-srv has one for RDP?
> How will you reach dc01 to administer it? (Answer: RDP to win-srv first, then RDP
> from win-srv to 10.0.1.50 - a "double hop" that keeps the DC off the internet.)

### 2. Get in and get the code

RDP to win-srv, then RDP from win-srv to `10.0.1.50`. In an elevated PowerShell:

```powershell
git clone https://github.com/DrvKrv/security-homelab.git C:\security-homelab
cd C:\security-homelab\lab\stages\3-dc01
```

### 3. Promote to a domain controller (reboots once)

```powershell
.\Install-Dc01.ps1
```

This installs Active Directory, creates the `acme.lab` forest, and reboots. The
recovery (DSRM) password is generated randomly and saved to `C:\LabState` - it's
never put in git. **Log back in and run the same script again** to seed the company:

```powershell
.\Install-Dc01.ps1
```

The second run creates departmental OUs, security groups, and a randomized set of
staff accounts (random passwords, stored only as AD hashes). A `demo.user` account
with a fixed, obviously-fake password is added so you can test signing in.

### 4. Check it

```powershell
.\Verify-Dc01.ps1
```

Every line should say PASS: dc01 is a DC for `acme.lab`, the services are running,
and the Acme OU, staff accounts and groups exist.

### 5. Wire up Wazuh and join win-srv

- Follow `wazuh/README.md` to put dc01 in the Wazuh `windows` group and turn on the
  DC audit subcategories.
- Optionally join win-srv to the domain (**System > Rename this PC (advanced) >
  Change > Domain: acme.lab**) so your existing Windows exercises run against domain
  accounts. Keep a local admin account so you don't lock yourself out.

## What to practise here

1. **Identity hygiene (audit):** list members of `IT-Admins` and `Domain Admins`.
   Is anyone there who shouldn't be? Write it up.
2. **Baseline logons:** watch 4624/4625 in Wazuh for a day of normal use.
3. **Password policy:** check the default domain password policy. Is it strong
   enough? Change it and note the before/after.
4. Later stages add the actual identity *attacks* to detect; this stage is the
   directory they target.

## Housekeeping

- **Roll a fresh company:** `.\Reset-Company.ps1` (removes OU=Acme), then
  `.\Seed-Company.ps1`.
- **Done for now:** deallocate dc01 to save credit; the scripts rebuild it.
- **Lab-only credentials** live in `C:\LabState\lab-credentials.csv` on the DC -
  never committed, never reused anywhere real.
