# A3 Respond: Reset a compromised portal account and end its sessions

> Needs web-srv (unit 6). Read it any time; stage it once web-srv is built. You
> work on web-srv for the fix and in win-srv's browser for the proof.

## The concept
When a password is stolen, **containment** has two halves. First, change the
secret so the attacker cannot sign in again. Second, throw out the attacker who
is **already signed in**. People often do the first and forget the second.

After you sign in to a website, the site does not ask for your password on every
page. It gives your browser a **session cookie**, a small token that says "this
browser already signed in". How the site checks that token decides how you can
revoke it. Some apps keep a list of sessions on the server, so an admin can delete
one. Others put the session inside the cookie itself and sign it with a **secret
key** on the server, so there is no list to delete from. You have to find out
which kind of app you are defending before you can end its sessions.

Defenders care because a reset that leaves the attacker's session alive looks
like success on paper while the attacker keeps working.

## Your mission
Treat the staging as real: the demo account's password has leaked and someone is
signed in with it. Then:
1. From Wazuh, record **when** the account signed in and **from where**.
2. **Reset** the account's password. The portal has no reset page, so you do it as
   the administrator on web-srv.
3. **End every existing session** for that account.
4. **Prove** it: the open tab is signed out, the old password fails, the new
   password works. Record the alert for each check.
5. Note any **side effect** your session fix had on other users.

## The analyst workflow
1. Find the successful sign-in for the account in Wazuh and note its time and source.
2. Read how the portal works: `lab/stages/2-web-srv/portal/app.py` (how passwords
   are checked and where the session is stored) and `docker-compose.yml` (where
   the app gets its settings). Decide what makes a session valid.
3. Reset the password inside the portal's container, where the app's database lives.
4. End the sessions in the way step 2 told you is possible for this app.
5. Prove it from win-srv's browser, then confirm each result in Wazuh.

## Predict before you run
If you only reset the password and do nothing else, will the open "intruder" tab
still work when you refresh it? Explain why, using what you read in step 2.

## What good looks like
A case file (`../../../../case-file-template.md`) with the sign-in that started
it, the exact commands you ran with their times, the three proof checks with
their Wazuh alerts, and a short note on the trade-off of your session fix.

## Hints
1. Search `agent.name: web-srv and rule.id: 100400` for successful portal sign-ins; read `data.srcuser` and `data.srcip`.
2. The portal stores the session in a cookie signed with `PORTAL_SECRET_KEY`; a password change does not touch that cookie.
3. Run a short Python snippet with `docker compose exec -u root acme-portal` to write a new hash with werkzeug's `generate_password_hash`.
4. Recreate the portal with a new random `PORTAL_SECRET_KEY` to invalidate every cookie, then refresh the old tab.
