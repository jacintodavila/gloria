# Gerente agent – bank queue manager

## Core predicates

The gerente agent manages a bank queue with two main predicates:

- `timing(T)` – discrete time steps.
- `cola_larga` / `taq_vacias` – boolean-like flags for queue length.

## Scenario

### Step 0

- **Observations**: `timing(1), cola_larga`
- **Actions**: `do(revisa_cola(1),0), do(crear_taquilla,0)`

### Step 1

- **Observations**: `timing(2), taq_vacias`
- **Actions**: `do(revisa_cola(2),1), do(eliminar_taquilla,1)`

## Reasoning cycle

1. **Observing**: read `timing(T)` and the queue flag.
2. **Abducing**: determine which action sequence matches the current state.
3. **Applying goals**: `def/revisa_cola/crear_taquilla/eliminar_taquilla` clauses produce the `do/2` list.

## Running in the Playground

1. **Load** the gerente agent.
2. **Step 0** – send `[timing(1), cola_larga]` as observations.
3. The engine returns the step-0 actions and updates the clock to `t=1`.
4. **Step 1** – send `[timing(2), taq_vacias]`.
5. The engine returns the step-1 actions.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*