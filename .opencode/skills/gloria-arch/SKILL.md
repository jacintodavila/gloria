---
name: gloria-arch
description: Use when running or testing the Gloria "arch" agent - "run arch", "architecture agent", "build/arch abduction example", "do_b". Gives the observables, goals, beliefs and a known-good sample.
---

# Gloria agent: arch

An architecture/abduction demonstration agent: given an observed `build/1`
goal and observations of columns and beams, it constructs an `arch` and issues
the corresponding `do`/`do_b` actions.

- Source: `examples/arch/ex-arch.main`, `examples/arch/ex-arch.kb`
- Observables: `build(_)`
- Goals (`if_/2`):
  - `build(A) -> [arch(A)]`
- Beliefs (`def/2`):
  - `def(arch(A), (col(C1, C2), beam(B)))`
  - `def(col(C1, C2), (c(C1), c(C2), do(C1), do(C2)))`
  - `def(beam(B), (b(B), do_b(B)))`
  - `def(neq(X, Y), not(X eq Y))`
- Abducibles: `do`, `do_b`, `c`, `b`, `build`
- `c/1`, `b/1` and `build/1` are declared `for_testing_only`, so include them in
  the observation list to let the abduction fire.

## Sample run

`gloria_run_step` with `agent="arch"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[build(5), c(5), c(8), b(10)]` | `do(do(8),0)`, `do(do(8),0)`, `do(do_b(10),0)` |

The exact `do/2` arguments follow the abduced columns and beam, so they may
vary with the observation set. This agent is best treated as an abduction
demo; unlike enclosure/gerente there is no natural sequence of observations.
