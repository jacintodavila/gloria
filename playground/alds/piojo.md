# Piojo agent – pure reactive production system

## The agent

A woodlouse (`piojo de la madera`) with **no representation of the world**. It
only perceives what is directly in front of it and the state of its own body,
and reacts with three condition–action rules:

- If the front is free (and it is rested), move forward.
- If there is an obstacle in front (and it is rested), turn right.
- If it is tired, stop.

The body reports `descansado` or `cansado` on every step. Requiring
`descansado` in the first two rules gives tiredness priority, so
`[frente_libre, cansado]` only triggers `detenerse`.

## Scenario

The observation sequence from the specification, with the body state made
explicit:

| time | observations | action |
| --- | --- | --- |
| 0 | `[frente_libre, descansado]` | `do(avanzar,0)` |
| 1 | `[frente_libre, descansado]` | `do(avanzar,1)` |
| 2 | `[obstaculo_al_frente, descansado]` | `do(voltear_derecha,2)` |
| 3 | `[frente_libre, cansado]` | `do(detenerse,3)` |

At time 3 both "front free" and "tired" hold, but only the tiredness rule
fires: the agent stops instead of moving forward.

## How it works

The knowledge base (`examples/piojo/piojo.kb`) is a direct transcription of
the three rules:

```prolog
if_((frente_libre, descansado), [avanzar]).
if_((obstaculo_al_frente, descansado), [voltear_derecha]).
if_(cansado, [detenerse]).
```

The reasoning cycle is purely reactive:

1. **Observing** the world in front and the state of the body.
2. **Matching** the observation against each `if_/2` rule.
3. **Abducing** the action in the head of every matching rule. There is no
   plan, no memory and no model of the world; the rule itself is the whole
   behaviour.

## Running step-by-step in the Playground

1. **Load** the piojo agent.
2. **Step 0** – send `[frente_libre, descansado]`; the engine returns
   `do(avanzar,0)`.
3. **Step 1** – send `[frente_libre, descansado]`; the engine returns
   `do(avanzar,1)`.
4. **Step 2** – send `[obstaculo_al_frente, descansado]`; the engine returns
   `do(voltear_derecha,2)`.
5. **Step 3** – send `[frente_libre, cansado]`; the engine returns
   `do(detenerse,3)` and no movement.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*
