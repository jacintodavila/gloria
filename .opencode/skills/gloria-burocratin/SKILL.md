---
name: gloria-burocratin
description: Use when running or testing the Gloria "burocratin" agent - "run burocratin", "bureaucrat agent", "sigo_procedimiento", "me_pide". Gives the observables, goals, beliefs and a known-good sample.
---

# Gloria agent: burocratin

A bureaucratic agent that follows procedure when someone asks it for
something, and invents a manual or asks for authority when it cannot.

- Source: `examples/burocratin/burocratin.main`, `examples/burocratin/burocratin.kb`,
  `examples/burocratin/burocratin.g`
- Observables: `me_pide(_, _)`
- Goals (`if_/2`):
  - `me_pide(Alguien, Algo) -> [sigo_procedimiento(Algo, Alguien)]`
  - `(me_pide(Alguien, Algo), muy_importante(Algo)) -> [resuelvo(inmediatamente, Algo, Alguien)]`
- Beliefs (`def/2`):
  - `def(sigo_procedimiento(X, Y), consulto_manual(X))`
  - `def(sigo_procedimiento(W, R), invento_manual(X, R))`
  - `def(consulto_manual(X), (existe(X), lee(X)))`
  - `def(invento_manual(X, Y), (pida_carta_autoridad, resuelvo(lentamente, X, Y)))`
  - `def(muy_importante(Algo), aparece_en_la_ley(Algo))`
- Abducibles: `me_pide`, `lee`

## Sample run

`gloria_run_step` with `agent="burocratin"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[me_pide(juan, sacar_constancia)]` | `do(lee(sacar_constancia),0)` |

Note `existe/1` is not observable, so the `consulto_manual` branch is used and
the agent `lee` the requested thing. Use `gloria_reset` to restart at time 0.
