---
name: gloria-mylamp
description: Use when running or testing the Gloria "mylamp" agent - "run mylamp", "motion lamp agent", "light_on", "switch_on". Gives the observables, goals, beliefs and a known-good sample.
---

# Gloria agent: mylamp

A motion-triggered lamp agent: when it perceives motion in a room it turns on
the lamp and logs the event.

- Source: `examples/mylamp/mylamp.main`, `examples/mylamp/mylamp.kb`
- Observables: `motion(_)`
- Goals (`if_/2`):
  - `motion(M) -> [light_on(M)]`
- Beliefs (`def/2`):
  - `def(light_on(M), (switch_on(lamp1), log(M)))`
- Abducibles: `motion`, `switch_on`, `log`

`motion/1` is the only observable; `switch_on/1` and `log/1` are the actions the
agent may issue.

## Sample run

`gloria_run_step` with `agent="mylamp"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[motion(room)]` | `do(switch_on(lamp1),0)`, `do(log(room),0)` |

The room reported by `motion/1` is threaded into the `log/1` action, so
`motion(kitchen)` yields `do(log(kitchen),0)`. Passing `[]` (no motion) makes
the agent produce no actions.
