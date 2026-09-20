# Arch agent – abduction example

## Core predicates

The arch agent demonstrates abduction over constants `b`, `c`, and `build`.

- `build(N)` – a constant representing a build number.
- `c(N)` – a constant.
- `do_b(K)` – an abduced action.

## Scenario

### Step 0

- **Observations**: `build(5), c(5), c(8), b(10)`
- **Actions**: `do(do(8),0), do(do(8),0), do(do_b(10),0)`

### Why two `do(do(8),0)`?

The arch knowledge base contains duplicate `def(do(8),0)` clauses; both fire in the same time step, producing two identical actions.

## Reasoning cycle

1. **Observing**: read the constants `build(5), c(5), c(8), b(10)`.
2. **Abducing**: match the `if_/2` clauses that produce `do/2` actions.
3. **Applying goals**: the two `do(do(8),0)` entries arise from duplicated `def(do(8),0)` clauses in the KB.

## Running in the Playground

1. **Load** the arch agent.
2. **Step 0** – send `[build(5), c(5), c(8), b(10)]` as observations.
3. The engine returns the three actions and updates the clock.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*