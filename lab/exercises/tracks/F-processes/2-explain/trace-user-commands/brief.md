# F2 Explain: Trace what a user ran after logging in

> Needs the detection add-ons from unit 4 (Sysmon on win-srv / process auditing on linux-srv). Read it any time; do it once they're installed.

## The concept
Spotting that an account was active is level 1. Explaining *what it did* is the
next step, and on Linux that means reading the commands it ran. When someone
first gets onto a machine, legitimately or not, they usually start by looking
around: who am I, what box is this, what accounts exist, what can I reach. This
quiet "look around" phase is called **discovery**, and it leaves a trail of small
read-only commands.

To follow that trail you need **command visibility**, which you added in unit 4
(auditd recording `execve`, or Wazuh command monitoring). Each command becomes an
event showing the program, its arguments, and which user ran it. Your job is to
line those events up into the order they happened and say, in plain words, what
the user was trying to learn.

A key idea: a single command is rarely suspicious on its own. `id` is normal.
`uname -a` is normal. It is the **sequence**, several discovery commands in a row
right after a login, that tells a story.

## Your mission
A user ran a short series of commands on **linux-srv**. Build the picture:
1. **Which account** ran the commands.
2. **The commands, in order**, with their arguments.
3. **What they were trying to learn** (group the commands by what each reveals).
4. **Whether this looks like routine use or like someone getting their bearings**,
   and why.

## The analyst workflow
1. Stage the lesson, then start broad in Wazuh with the linux-srv filter and move
   to process / command events.
2. Find the events tied to one username close together in time. Note the account.
3. Read each command and its arguments. Put them in time order (a small table
   works well).
4. For each command, write what it tells the person running it (your identity,
   the OS version, who else has an account, and so on). Then judge the pattern.

## Predict before you run
Before you look: if you wanted to understand a Linux box you just landed on,
which one or two commands would you run first, and what would each tell you? Keep
your list and compare it to what the user actually ran.

## What good looks like
A short timeline in your case file: the account, each command in order with its
arguments, a one-line "what this reveals" per command, and your call on whether
it reads as normal work or as discovery. This run's account is shown under *This
run's details* in `reveal`.

## Hints
1. Filter to linux-srv and look at process / command execution events, not login or auth events.
2. Find the username that appears across several commands in a short window, then pin your search to that user.
3. Read the arguments, not just the program: `uname -a` and `cat /etc/os-release` both answer "what OS is this?".
4. Think about what each command reveals: identity (`id`), the system (`uname`, os-release), and other accounts (`ls /home`). Together that is a classic look-around.
