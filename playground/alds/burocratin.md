# Burocratin agent – “sigo_procedimiento” example

## Background

The burocin agent is a Spanish/German-style procedure example where a request `me_pide(Person, Request)` triggers a procedural workflow.

## Core predicate

```
existe(sacar_constancia).
existe(reporte).
```

When `me_pide(juan, sacar_constancia)` is observed, the agent performs:

```
do(lee(sacar_constancia),0)
```

## Reasoning cycle

1. **Observing**: `me_pide(juan, sacar_constancia)`.
2. **Abducing**: the presence of `existe(sacar_constancia)` is checked.
3. **Applying goals**: `existe(sacar_constancia)` holds → produce `do(lee(sacar_constancia),0)`.

## Running in the Playground

1. **Load** the burocratin agent.
2. **Step** – send `[me_pide(juan, sacar_constancia)]` as observations.
3. The engine returns `do(lee(sacar_constancia),0)` and updates the clock.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*