# Answer key: Reset a compromised portal account and end its sessions

## What happened
The demo account (`demo.user`) signed in to the portal from win-srv, and that
browser tab plays the intruder. The portal checks passwords against a hash in
its SQLite database (`/data/portal.db` inside the container). After sign-in it
keeps the session in a **cookie signed with `PORTAL_SECRET_KEY`**. There is no
server-side session list, so the only way to end a session is to change the key.

## The evidence
- **Rule 100400** "Acme portal: successful login" with `srcuser` = `demo.user` and
  `srcip` = 10.0.1.20: the intruder's sign-in.
- After your fix: **100401** for the old password (fails), **100400** for the new
  password (works). Refreshing the old tab makes no auth event at all: the portal
  just sends it back to the login page.

## Answers to the mission
1. **Sign-in:** the time of the 100400 for `demo.user`, from 10.0.1.20 (win-srv).
2. **Reset the password** (on web-srv; you are asked for the account and a new password):
   ```bash
   cd /opt/security-homelab/lab/stages/2-web-srv
   sudo docker compose exec -u root acme-portal python -c "
   import sqlite3, getpass
   from werkzeug.security import generate_password_hash
   user = input('Account to reset: ').strip().lower()
   pw = getpass.getpass('New password: ')
   con = sqlite3.connect('/data/portal.db')
   n = con.execute('UPDATE users SET password_hash=? WHERE username=?', (generate_password_hash(pw), user)).rowcount
   con.commit(); print('accounts updated:', n)"
   ```
   `accounts updated: 1` means it worked; 0 means the username was mistyped.
3. **End the sessions:** give the portal a new random key and recreate it.
   ```bash
   sudo env PORTAL_SECRET_KEY="$(openssl rand -hex 32)" docker compose up -d --force-recreate acme-portal
   ```
   Every cookie signed with the old key is now rejected.
4. **Proof:** refresh the old tab: it lands on the login page. Old password:
   "Invalid username or password" and a **100401**. New password: dashboard and a
   **100400**. Put all three times in your case file.
5. **Side effect:** rotating the key signs out **everyone**, not just the
   compromised account. For a small portal that is acceptable; a bigger app should
   keep sessions on the server so one user's sessions can be revoked alone.

## MITRE ATT&CK
T1078 Valid Accounts. The intruder uses a real account with a real password, so
nothing looks like an exploit. Containment has to remove both the password and
the session.

## Common mistakes
- Resetting the password and stopping. The predict answer: the old tab keeps
  working, because the cookie is still validly signed.
- Restarting the container without passing a new key. Restarting alone does not
  change the key, so sessions survive. Always set a fresh random value.
- Forgetting to tell the real user their new password through a safe channel.
- Not recording times. The case file needs "contained at" as well as "found at".

## Interview talking point
"For a stolen web password I treat containment as two steps: change the
credential and kill live sessions. I read the app first and found it signs
sessions into the cookie, so a password reset alone would have left the attacker
signed in. I reset the hash, rotated the signing key, and proved it three ways:
the old session was rejected, the old password failed and the new one worked,
each with its Wazuh event."

To put the lab back (demo password and a fresh key), run `./run.sh reset` on
web-srv, which re-runs `stages/2-web-srv/install.sh`.
