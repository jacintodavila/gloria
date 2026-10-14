# Rentin agent – the opportunist who rationalises abuse

## Two-step scenario

**Step 0** – the agent is lazy, wins undeservedly, the judges are unreliable and
there is **no independent observer** watching the data:

```
input:  [flojera, gano, no_hay_jueces_confiables, sin_observador]
actions: do(no_trabajo,0), do(abuso,0)
```

**Step 1** – same world, but now there **is an independent observer** (`observador_independiente`).
The accountability chain is blocked, so `puedo` fails and the agent does **not**
abuse; it still refuses to work:

```
input:  [flojera, gano, no_hay_jueces_confiables, observador_independiente]
actions: do(no_trabajo,0)
```

## How it works

The spec (Spanish) is compiled into `examples/rentin/rentin.kb`:

```prolog
if_((puedo, gano_sin_merecerlo), [abuso]).   % Si puedo, abuso
if_(flojera, [no_trabajo]).                  % Si me da flojera, no trabajo

def(gano_sin_merecerlo, (gano, no_merezco)). % Abuso si gano sin merecerlo
def(no_merezco, no_trabajo).                 % No lo merezco si no trabajo
def(puedo, nadie_sospecha).                  % Puedo si nadie sospecha de mi
def(nadie_sospecha, oculto_en_complejidad).
def(oculto_en_complejidad,
    (evaluacion_compleja, sistema_judicial_no_funciona)).
def(evaluacion_compleja, no_hay_memoria).
def(no_hay_memoria, datos_no_colectados).    % ... o se pierden
def(no_hay_memoria, datos_se_pierden).
def(datos_no_colectados, sin_observador).    % no hay observador independiente
def(sistema_judicial_no_funciona,
    (no_hay_jueces_confiables, exenciones_arbitrarias)).
def(exenciones_arbitrarias, evaluacion_compleja).
def(datos_colectados, observador_independiente).
```

The reasoning cycle for step 0:

1. **Observing**: `flojera`, `gano`, `no_hay_jueces_confiables`, `sin_observador`.
2. **Firing the metas**: `flojera` → goal `no_trabajo`; and `puedo` +
   `gano_sin_merecerlo` → goal `abuso`.
3. **Unfolding the beliefs**: `sin_observador` → `datos_no_colectados` →
   `no_hay_memoria` → `evaluacion_compleja` → `exenciones_arbitrarias`, which
   with `no_hay_jueces_confiables` makes `sistema_judicial_no_funciona`; the two
   then make `oculto_en_complejidad` → `nadie_sospecha` → `puedo`. And
   `no_trabajo` → `no_merezco`, so with `gano` we get `gano_sin_merecerlo`.
4. **Acting**: produce `do(no_trabajo,0), do(abuso,0)`.

In step 1 the leaf `sin_observador` is replaced by `observador_independiente`, so
`datos_no_colectados` (and `no_hay_memoria`) fail; the whole `puedo` chain
collapses and no abuse is produced.

## Running step-by-step in the Playground

1. **Load** the `rentin` agent.
2. **Step 0** – observations `[flojera, gano, no_hay_jueces_confiables, sin_observador]`
   → `do(no_trabajo,0), do(abuso,0)`.
3. **Step 1** – observations `[flojera, gano, no_hay_jueces_confiables, observador_independiente]`
   → `do(no_trabajo,0)`.

## Notes

- The two metas are the abducible actions. Goal/observable leaves are declared
  both `abd` and `observable`; an abducible fact absent from the input is not
  assumed.
- `not/1` is not usable here, so "no independent observer" is the positive leaf
  `sin_observador`. The alternatives "no se colectan **o** se pierden" are two
  `def` clauses for `no_hay_memoria`.
