# Answer key: Rank a list of findings by real risk, not just score

Your findings are your own, so this key gives a ranking rubric and a worked
example with **made-up** findings (A to F) to show the method. Don't copy the
example into your docs as if it were real.

## A defensible rubric
1. **In CISA KEV:** first, whatever the score. Someone is already using it.
2. **High or Critical, reachable over a network it's actually exposed to**, on a
   running service. Internet-reachable beats lab-only.
3. **High or Critical, not exposed** (a library or tool nothing listening uses,
   or local-only `AV:L`).
4. **Medium and Low:** the normal patch cycle.

Within a tier, break ties by **asset value** (wazuh and win-srv are High in the
asset inventory, linux-srv Medium) and then by **ease of fix** (no reboot first).
EPSS helps order findings inside a tier.

## Worked example (made-up findings)
| Rank | Finding | VM | CVSS | KEV | Exposure | Why here |
|---|---|---|---|---|---|---|
| 1 | D: remote desktop flaw | win-srv | 8.8 | Yes | RDP from one home IP | Known exploited, on the only internet-facing service |
| 2 | B: SSH server flaw | linux-srv | 8.1 | No | Lab subnet | Network, no login needed, on a running service |
| 3 | E: web dashboard flaw | wazuh | 7.5 | No | Lab subnet | Network-reachable on the SIEM, a high-value asset |
| 4 | A: image library flaw | wazuh | 9.8 | No | Not used by anything running | Highest score, but nothing reachable uses it |
| 5 | F: kernel local flaw | linux-srv | 7.8 | No | `AV:L`, needs a login first | Needs a foothold; needs a reboot to fix |
| 6 | C: text tool flaw | win-srv | 5.5 | No | Local, user must open a file | Medium, user action needed |

**CVSS versus rank:** A has the top score (9.8) but ranks 4th, because no running
program uses the library and nothing can reach it. D ranks first with a lower
score because it's known exploited and internet-facing.

## How the twists change it
- **RDP open to the internet:** any win-srv finding reachable over RDP jumps to
  the top, and the real first fix is the firewall rule, not a patch.
- **One VM down this week:** pick the VM with the most top-tier findings, or the
  one whose fix closes the most exposed risk; move the rest to next week and say
  so.
- **linux-srv hosts payroll:** its asset value rises to High, so its exposed
  findings move up within their tier.
- **A finding is in KEV:** it goes to rank 1 whatever its score.

## Common mistakes
- Sorting by CVSS and calling it a ranking.
- Rules written after the ranking to justify it.
- "Exposed" without saying exposed to whom.
- Forgetting the cost of the fix (a reboot of wazuh takes the SIEM down).

## Interview talking point
"Given a list of vulnerabilities, I wrote down ranking rules before sorting:
known exploited first, then exposed high-severity on running services, then
everything else, with asset value and fix cost as tie-breakers. I could show a
case where a 9.8 ranked below an 8.8 and say exactly why, and I re-ranked when the
situation changed instead of sticking to the scanner's order."
