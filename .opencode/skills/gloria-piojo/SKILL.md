---
name: gloria-piojo
description: Use when running or testing the Gloria "piojo" agent - "run piojo", "woodlouse agent", "pure reactive production system", "avanzar", "voltear_derecha", "detenerse", "frente_libre", "cansado". Gives the observables, goals and a known-good four-step sample.
---

# Gloria agent: piojo

A woodlouse (`piojo de la madera`): a purely reactive production system with no
representation of the world. It only sees what is directly in front of it and
feels whether its body is tired or rested. Its whole behaviour is three
condition–action rules.

- Source: `examples/piojo/piojo.main`, `examples/piojo/piojo.kb`
- Observables: `frente_libre`, `obstaculo_al_frente`, `descansado`, `cansado`
- Goals (`if_/2`):
  - `(frente_libre, descansado) -> [avanzar]`
  - `(obstaculo_al_frente, descansado) -> [voltear_derecha]`
  - `cansado -> [detenerse]`
- Beliefs (`def/2`): none; the actions are abducibles directly.
- Abducibles: `frente_libre`, `obstaculo_al_frente`, `descansado`, `cansado`,
  `avanzar`, `voltear_derecha`, `detenerse`

The body reports exactly one of `descansado` / `cansado` on every step. The
first two rules require `descansado`, so tiredness has priority: with
`[frente_libre, cansado]` the agent stops and does **not** move forward.

## Sample run

`gloria_run_step` with `agent="piojo"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[frente_libre, descansado]` | `do(avanzar,0)` |
| 1 | `[frente_libre, descansado]` | `do(avanzar,1)` |
| 2 | `[obstaculo_al_frente, descansado]` | `do(voltear_derecha,2)` |
| 3 | `[frente_libre, cansado]` | `do(detenerse,3)` |

At time 3 both "front free" and "tired" hold, but only the tiredness rule
fires. Passing `[]` makes the agent produce no actions.
