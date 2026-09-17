---
name: gloria-gerente
description: Use when running or testing the Gloria "gerente" agent - "run gerente", "bank manager agent", "queue control agent", "revisa_cola", "crear_taquilla". Gives the observables, goals, beliefs and a known-good two-step sample.
---

# Gloria agent: gerente

A bank manager agent that watches the queues in front of the tellers and
creates or closes tellers depending on how long the queues are.

- Source: `examples/gerente/gerente.main`, `examples/gerente/gerente.kb`,
  `examples/gerente/gerente.g`
- Observables: `cola_larga`, `taq_vacias`
- Goals (`if_/2`):
  - `timing(T) -> [revisa_cola(T)]`
  - `cola_larga -> [crear_taquilla]`
  - `taq_vacias -> [eliminar_taquilla]`
- Abducibles: `cola_larga`, `crear_taquilla`, `taq_vacias`, `eliminar_taquilla`,
  `revisa_cola`
- Beliefs: none (`def/2` empty)

## Sample run

`gloria_run_step` with `agent="gerente"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[timing(1), cola_larga]` | `do(revisa_cola(1),0)`, `do(crear_taquilla,0)` |
| 1 | `[timing(2), taq_vacias]` | `do(revisa_cola(2),1)`, `do(eliminar_taquilla,1)` |

`timing(T)` drives `revisa_cola(T)`; the queue observations drive opening or
closing a teller. Reuse the `session` to advance time; call `gloria_reset` to
restart at time 0.
