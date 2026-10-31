# Vigilante agent – control de acceso

## One-step scenario

**Initial state**: `llega_vehiculo(visitante)`

**Step 0** – el agente observa que llega un visitante. Su meta es gestionar el
acceso, para lo cual debe anotar en el cuaderno y luego abrir el portón:

```
do(anota_cuaderno,0)
do(abre_porton,0)
```

Con `llega_vehiculo(residente)` solo abre el portón; con
`llega_vehiculo(desconocido)` niega el acceso.

## How it works

The vigilante agent's knowledge base (`examples/vigilante/vigilante.kb`)
contains:

- `if_(llega_vehiculo(Categoria), [gestionar_acceso(Categoria)]).`
- `def(gestionar_acceso(residente), abre_porton).`
- `def(gestionar_acceso(visitante), (anota_cuaderno, abre_porton)).`
- `def(gestionar_acceso(desconocido), niega_acceso).`

The reasoning cycle:

1. **Observing**: `llega_vehiculo(visitante)`.
2. **Unfolding the goal**: `if_/2` triggers `gestionar_acceso(visitante)`.
3. **Applying beliefs**: the category selects the matching `def/2` clause.
4. **Abducing**: `anota_cuaderno` and `abre_porton` are abducible, so they
   become the actions `do(anota_cuaderno,0)` and `do(abre_porton,0)`.

## Running step-by-step in the Playground

1. **Load** the vigilante agent.
2. **Step 0** – the Playground sends `[llega_vehiculo(visitante)]`.
3. The engine returns `do(anota_cuaderno,0)` and `do(abre_porton,0)`.
4. Try `[llega_vehiculo(residente)]` or `[llega_vehiculo(desconocido)]` in a
   fresh session to see the other two branches.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*
