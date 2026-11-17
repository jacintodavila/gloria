# Marciano agent – production system with a coordinate map

## The agent

A robot explorer sent to Mars to look for traces of Martian life. The terrain
is a grid of unit squares. Each square is identified by coordinates `(E,N)`:

- `E` is the distance East of the origin,
- `N` is the distance North of the origin.

The robot starts at `(0,0)` facing East and moves exactly one square per step.
It knows its current square and heading, and computes the coordinates of the
square ahead and of the square to the right with simple arithmetic. Every time
it moves into a new square it records that square in its map; to decide
whether it has been somewhere before it consults the map.

## The world

The example world has:

- free squares `(1,0)` and `(2,0)`;
- obstacles at `(3,0)`, `(2,-1)` and `(2,1)`;
- life at `(2,1)` (which is therefore also an obstacle).

The robot cannot see the life at `(2,1)` until that square is directly ahead.
When it starts, the only world fact it receives is that `(1,0)` is free.

## Observations

Each step the body reports:

- `posicion(E,N)` – the robot's current square,
- `orientacion(D)` – `este`, `norte`, `oeste` or `sur`,
- exactly one of `frente_libre`, `obstaculo_al_frente`, `vida` – the content of the square
  directly ahead.

The robot computes the ahead coordinates itself, so the observation only says
*what* is ahead, not *where* it is.

## The rules

In priority order:

1. If the square ahead is free **and already visited**, turn right.
2. If the square ahead is free **and not visited**, go there and record the
   visit.
3. If the square ahead is an obstacle **without life**, record it and turn
   right.
4. If the square ahead **has life**, report its coordinates to the control
   centre and turn right.

## Scenario

| time | observations | actions |
| --- | --- | --- |
| 0 | `[posicion(0,0), orientacion(este), frente_libre]` | `do(avanzar,0)` |
| 1 | `[posicion(1,0), orientacion(este), frente_libre]` | `do(avanzar,1)` |
| 2 | `[posicion(2,0), orientacion(este), obstaculo_al_frente]` | `do(voltear_derecha,2)` |
| 3 | `[posicion(2,0), orientacion(sur), obstaculo_al_frente]` | `do(voltear_derecha,3)` |
| 4 | `[posicion(2,0), orientacion(oeste), frente_libre]` | `do(voltear_derecha,4)` |
| 5 | `[posicion(2,0), orientacion(norte), vida]` | `do(reportar((2,1)),5), do(voltear_derecha,5)` |

At time 4 the robot refuses to re-enter `(1,0)` because it is in its map. At
time 5 the square ahead is `(2,1)`, so it reports `reportar((2,1))`.

## How it works

The knowledge base (`examples/marciano/marciano.kb`) contains the four rules.
The arithmetic and the map are defined in `marciano.main` as ordinary
`user_built/1` predicates:

```prolog
adelante(E,N,este, E2,N) :- E2 is E + 1.
adelante(E,N,norte,E,N2) :- N2 is N + 1.
...

visitado(P) :- recuerda(visitado(P)).
no_visitado(P) :- not(visitado(P)).

registra_visita(P) :-
    memoriza(visitado(P)),
    registra_mapa(P, frente_libre).

registra_observacion(P, Estado) :-
    registra_mapa(P, Estado).
```

The map is the set of `recuerda(mapa((E,N),Estado))` facts; the visited set is
the set of `recuerda(visitado((E,N)))` facts. They live in the engine's working
memory (`memoriza/1`, `recuerda/1`) and survive from one reasoning step to the
next.

Two implementation details matter:

- The visited rule is written **before** the new-square rule: rules are
  evaluated in source order, so a new square triggers `avanzar` (which records
  it) and not `voltear_derecha`.
- `frente_libre`, `obstaculo_al_frente` and `vida` are mutually exclusive observations.

## Running step-by-step in the Playground

1. **Load** the marciano agent.
2. **Step 0** – send `[posicion(0,0), orientacion(este), frente_libre]`; the engine
   returns `do(avanzar,0)` and records `(1,0)`.
3. **Step 1** – send `[posicion(1,0), orientacion(este), frente_libre]`; the engine
   returns `do(avanzar,1)` and records `(2,0)`.
4. **Step 2** – send `[posicion(2,0), orientacion(este), obstaculo_al_frente]`; the
   engine returns `do(voltear_derecha,2)`.
5. **Step 3** – send `[posicion(2,0), orientacion(sur), obstaculo_al_frente]`; the
   engine returns `do(voltear_derecha,3)`.
6. **Step 4** – send `[posicion(2,0), orientacion(oeste), frente_libre]`; `(1,0)` is
   already visited, so the engine returns `do(voltear_derecha,4)`.
7. **Step 5** – send `[posicion(2,0), orientacion(norte), vida]`; the engine
   returns `do(reportar((2,1)),5), do(voltear_derecha,5)`.

Reloading the agent (or resetting the session) clears the working memory.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*
