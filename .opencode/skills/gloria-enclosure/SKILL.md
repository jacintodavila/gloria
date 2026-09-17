---
name: gloria-enclosure
description: Use when running or testing the Gloria "enclosure" agent - "run enclosure", "window/door control agent", "adjust_home", "outdoor temperature agent". Gives the observables, goals, beliefs and a known-good two-step sample.
---

# Gloria agent: enclosure

Building-enclosure control that keeps a room comfortable by balancing fresh air
against internal temperature, depending on the type of day (sunny/rainy) and
the position of windows and doors.

- Source: `examples/enclosure/enclosure.main`, `examples/enclosure/enclosure.kb`,
  `examples/enclosure/enclosure.g`
- Observables: `time_day(_)`, `it_is(_)`
- Goals (`if_/2`):
  - `(time_day(Time), it_is(Temp)) -> [adjust_home(Time, Temp)]`
- Beliefs (`def/2`):
  - `def(adjust_home(am, sunny), (shut(east_window), open(doors)))`
  - `def(adjust_home(pm, sunny), (shut(west_window), open(doors)))`
  - `def(adjust_home(Any, rainy), (shut(east_window), shut(west_window), shut(doors)))`
- Abducibles: `shut`, `open`, `time_day`, `it_is`

## Sample run

`gloria_run_step` with `agent="enclosure"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[time_day(am), it_is(sunny)]` | `do(shut(east_window),0)`, `do(open(doors),0)` |
| 1 | `[time_day(pm), it_is(rainy)]` | `do(shut(east_window),1)`, `do(shut(west_window),1)`, `do(shut(doors),1)` |

Reuse the same `session` to continue the clock; call `gloria_reset` to restart
at time 0.
