---
name: gloria-emergencia
description: Use when running or testing the Gloria "emergencia" agent - "run emergencia", "emergency help agent", "consigue_ayuda", "alerta_conductor", "pulsa_boton". Gives the observables, goals, beliefs and a known-good sample.
---

# Gloria agent: emergencia

An emergency-help agent: when it perceives an emergency it gets help by
alerting the driver, which it does by pressing the alarm-signal button.

- Source: `examples/emergencia/emergencia.main`, `examples/emergencia/emergencia.kb`
- Observables: `emergencia`
- Goals (`if_/2`):
  - `emergencia -> [consigue_ayuda]`
- Beliefs (`def/2`):
  - `def(consigue_ayuda, alerta_conductor)`
  - `def(alerta_conductor, pulsa_boton)`
- Abducibles: `emergencia`, `pulsa_boton`

The goal `consigue_ayuda` unfolds through the beliefs to the abducible
`pulsa_boton`, so pressing the alarm button is the only action the agent issues.

## Sample run

`gloria_run_step` with `agent="emergencia"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[emergencia]` | `do(pulsa_boton,0)` |
| 1 | `[]` | (no actions) |

Passing `[]` (no emergency) does not trigger the goal.
