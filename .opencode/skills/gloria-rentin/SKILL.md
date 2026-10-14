---
name: gloria-rentin
description: Use when the user wants to run or test the Gloria "rentin" agent - "run rentin", "opportunist agent", "abuso / no_trabajo agent", "abuse rationalization agent", "sin_observador scenario". Gives the observables, goals, beliefs and known-good sample runs.
---

# Gloria via the `rentin` agent

`rentin` is a small, self-interested agent that **abuses when it can** and
"rationalises" the abuse by manufacturing complexity in the evaluation system.
Its Spanish specification is compiled from `examples/rentin/rentin.g`.

- Source: `examples/rentin/rentin.main`, `examples/rentin/rentin.kb`
  (mirrored in `src/agents/rentin/`)
- Abducibles: `abuso`, `no_trabajo` (the actions) plus the observable leaves
  `flojera`, `gano`, `no_hay_jueces_confiables`, `sin_observador`,
  `datos_se_pierden`, `observador_independiente`
- Observables (inputs): `flojera`, `gano`, `no_hay_jueces_confiables`,
  `sin_observador`, `datos_se_pierden`, `observador_independiente`
- Goals (`if_/2`):
  - `(puedo, gano_sin_merecerlo) -> [abuso]`
  - `flojera -> [no_trabajo]`
- Beliefs (`def/2`): `puedo` ← `nadie_sospecha` ← `oculto_en_complejidad` ←
  (`evaluacion_compleja`, `sistema_judicial_no_funciona`); `evaluacion_compleja`
  ← `no_hay_memoria` ← (`datos_no_colectados` | `datos_se_pierden`);
  `datos_no_colectados` ← `sin_observador`; `sistema_judicial_no_funciona` ←
  (`no_hay_jueces_confiables`, `exenciones_arbitrarias`); `exenciones_arbitrarias`
  ← `evaluacion_compleja`; `no_merezco` ← `no_trabajo`; `gano_sin_merecerlo` ←
  (`gano`, `no_merezco`); `datos_colectados` ← `observador_independiente`.

## Modelling notes (why it is written this way)

- The two metas become abducible actions, so the agent emits `do(abuso, T)` and
  `do(no_trabajo, T)`.
- The belief "Abuso si gano sin merecerlo" is compiled into the *condition* of
  the `abuso` goal (`puedo, gano_sin_merecerlo`). This is deliberate: an
  abducible atom's `def` is never unfolded by the engine, so a bare
  `def(abuso, gano_sin_merecerlo)` would be dead code.
- `not/1` is unreliable in this engine (it succeeds even when its argument is
  provable), so "los datos no se colectan" is modelled with the positive leaf
  `sin_observador` (absence of an independent observer) instead of
  `not(observador_independiente)`.
- The disjunction "no se colectan **o** se pierden" is two `def` clauses for
  `no_hay_memoria` (Gloria idiom), not a Prolog `;`.
- Goal/observable leaves must be declared **both** `abd` and `observable`; an
  abducible fact that is not in the input is not assumed, so an absent leaf
  simply fails.

## Sample run

`gloria_run_step` with `agent="rentin"`. Time advances per `(agent, session)`;
use a fresh session per scenario.

| time | input | actions |
| --- | --- | --- |
| 0 | `[flojera, gano, no_hay_jueces_confiables, sin_observador]` | `do(no_trabajo,0)`, `do(abuso,0)` |
| 0 | `[flojera, gano, no_hay_jueces_confiables, observador_independiente]` | `do(no_trabajo,0)` |
| 0 | `[flojera, gano, no_hay_jueces_confiables, datos_se_pierden]` | `do(no_trabajo,0)`, `do(abuso,0)` |
| 0 | `[flojera]` | `do(no_trabajo,0)` |
| 0 | `[]` | *(no actions)* |

The key contrast: with an **independent observer** (`observador_independiente`)
the accountability chain is blocked, so `puedo` fails and the agent does not
abuse — it only refuses to work. With `sin_observador` (or `datos_se_pierden`)
the data/complexity chain unfolds and the agent abuses.
