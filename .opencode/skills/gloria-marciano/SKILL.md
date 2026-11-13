---
name: gloria-marciano
description: Use when running or testing the Gloria "marciano" agent - "run marciano", "Mars explorer agent", "coordinate map", "production system with memory", "posicion", "orientacion", "frente_libre", "obstaculo_al_frente", "vida", "reportar". Gives the coordinate protocol, goals, map model and a known-good six-step sample.
---

# Gloria agent: marciano

A robot explorer sent to Mars to look for traces of Martian life. The terrain
is a grid of unit squares identified by `(E,N)` coordinates (`E` East, `N`
North). The robot starts at `(0,0)` facing East, moves one square per step,
computes the square ahead with arithmetic, and keeps a map of the observations
of the squares it visits.

- Source: `examples/marciano/marciano.main`, `examples/marciano/marciano.kb`
- Observables:
  - `posicion(E,N)` – current square
  - `orientacion(D)` – `este`, `norte`, `oeste` or `sur`
  - `frente_libre` / `obstaculo_al_frente` / `vida` – content of the square **directly ahead**
- Goals (`if_/2`), in priority order:
  - `(posicion(E,N), orientacion(D), frente_libre, adelante(E,N,D,E2,N2), visitado((E2,N2))) -> [voltear_derecha]`
  - `(posicion(E,N), orientacion(D), frente_libre, adelante(E,N,D,E2,N2), no_visitado((E2,N2)), registra_visita((E2,N2))) -> [avanzar]`
  - `(posicion(E,N), orientacion(D), obstaculo_al_frente, adelante(E,N,D,E2,N2), registra_observacion((E2,N2),obstaculo_al_frente)) -> [voltear_derecha]`
  - `(posicion(E,N), orientacion(D), vida, adelante(E,N,D,E2,N2), registra_observacion((E2,N2),vida)) -> [reportar((E2,N2)), voltear_derecha]`
- Beliefs (`def/2`): none; the coordinate arithmetic and the map are
  `user_built/1` predicates in `marciano.main`.
- Abducibles: `posicion`, `orientacion`, `frente_libre`, `obstaculo_al_frente`, `vida`,
  `avanzar`, `voltear_derecha`, `reportar`

## Coordinate arithmetic

`adelante(E,N,D,E2,N2)` computes the square directly ahead:

| heading | ahead |
| --- | --- |
| `este` | `(E+1, N)` |
| `norte` | `(E, N+1)` |
| `oeste` | `(E-1, N)` |
| `sur` | `(E, N-1)` |

`derecha(E,N,D,E2,N2)` computes the square to the right (the one that becomes
"ahead" after turning).

## Memory

The map is the set of `recuerda(mapa((E,N),Estado))` facts; the visited set is
`recuerda(visitado((E,N)))`. They are updated with `registra_visita/1` and
`registra_observacion/2` and queried with `visitado/1` / `no_visitado/1`.
The engine provides the working-memory primitives `memoriza/1`, `recuerda/1`
and `no_recuerda/1` (see `gloria.pl` and the Ciao port).

The memory survives across `gloria_run_step` calls. It belongs to the loaded
agent, so all sessions of that agent share it; `gloria_reset` clears it along
with the clock.

## Sample run

`gloria_run_step` with `agent="marciano"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[posicion(0,0), orientacion(este), frente_libre]` | `do(avanzar,0)` |
| 1 | `[posicion(1,0), orientacion(este), frente_libre]` | `do(avanzar,1)` |
| 2 | `[posicion(2,0), orientacion(este), obstaculo_al_frente]` | `do(voltear_derecha,2)` |
| 3 | `[posicion(2,0), orientacion(sur), obstaculo_al_frente]` | `do(voltear_derecha,3)` |
| 4 | `[posicion(2,0), orientacion(oeste), frente_libre]` | `do(voltear_derecha,4)` |
| 5 | `[posicion(2,0), orientacion(norte), vida]` | `do(reportar((2,1)),5), do(voltear_derecha,5)` |

At time 4 the robot refuses to re-enter `(1,0)` because its map says it has
already visited it. At time 5 it reports the life at `(2,1)`.

The body must update `posicion`/`orientacion` after each action: `avanzar`
moves one square along the heading; `voltear_derecha` rotates
`este -> sur -> oeste -> norte -> este`.
