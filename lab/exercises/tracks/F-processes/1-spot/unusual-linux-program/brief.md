# F1 Spot: Spot an unusual program running on linux-srv

> Needs the detection add-ons from unit 4 (Sysmon on win-srv / process auditing on linux-srv). Read it any time; do it once they're installed.

## The concept
On Linux, the question "what is running right now, and should it be?" is one a
defender asks constantly. Most running programs are normal system services and
live in standard places like `/usr/bin` or `/usr/sbin`. Attackers often leave a
program running too, but they try to hide it: they give it a name that looks like
a real system service, and they run it from an odd location such as `/tmp` or a
hidden directory (a directory whose name starts with a dot, so `ls` does not show
it by default).

Two things make a running program worth a second look:
- **Where it runs from.** A real daemon running out of `/tmp` is suspicious no
  matter what it is called.
- **What its name pretends to be.** A name that mimics a familiar service is a
  trick to make you scroll past it.

In unit 4 you added process visibility on linux-srv (auditd, or Wazuh command
monitoring). That is what lets you see a program like this without logging into
the box and running `ps` by hand.

## Your mission
A program is running on **linux-srv** that should not be. Without stopping it yet:
1. Identify the **program name** and the **full path** it is running from.
2. Say **why it looks unusual** (think about the two things above).
3. Note **how you found it**: which log or search surfaced it.

## The analyst workflow
1. Stage the lesson on linux-srv, then start broad in Wazuh with the linux-srv
   filter and look at process / command activity.
2. Scan the paths of running programs. A program running from `/tmp` or a hidden
   `.`-directory should jump out against the normal `/usr/...` paths.
3. Read the program's name and location together, and ask what a real service of
   that name would normally look like.
4. Confirm on-box read-only if you like (`ps`, and look at the path), but do not
   kill it: spotting it is the whole job at this level.

## Predict before you run
Before you look: if an attacker wanted a program to blend in, would they more
likely change its **name**, its **location**, or both? What would still give it
away even with a convincing name?

## What good looks like
Your case file names the program and its full path, explains in one or two
sentences why the name and location are suspicious, and says which search found
it. This run's exact name is shown under *This run's details* at the end of
`reveal`, so write what you actually saw.

## Hints
1. Filter to linux-srv, then look at process or command activity rather than login events.
2. Ignore programs under `/usr/bin` and `/usr/sbin`: scan for a path under `/tmp` or a directory whose name starts with a dot.
3. The name is meant to look like a normal daemon. The giveaway is the location, not the name.
4. The exact name is randomized per run: check *This run's details* in `reveal` and compare it to what you found.
