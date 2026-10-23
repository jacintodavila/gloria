# Emergencia agent – emergency-help example

## One-step scenario

**Initial state**: `emergencia`

**Step 0** – the agent observes an emergency, works out that it must get help,
that help is obtained by alerting the driver, and that alerting the driver is
done by pressing the alarm button:

```
do(pulsa_boton,0)
```

With no observation the agent issues no actions.

## How it works

The emergencia agent's knowledge base (`examples/emergencia/emergencia.kb`)
contains:

- `if_(emergencia, [consigue_ayuda]).`
- `def(consigue_ayuda, alerta_conductor).`
- `def(alerta_conductor, pulsa_boton).`

The reasoning cycle:

1. **Observing**: `emergencia`.
2. **Unfolding the goal**: `if_(emergencia, [consigue_ayuda])` is triggered and
   `consigue_ayuda` becomes the target.
3. **Applying beliefs**: `consigue_ayuda` is achieved by `alerta_conductor`,
   and `alerta_conductor` is achieved by `pulsa_boton`.
4. **Abducing**: `pulsa_boton` is abducible, so it becomes the action
   `do(pulsa_boton,0)`.

## Running step-by-step in the Playground

1. **Load** the emergencia agent.
2. **Step 0** – the Playground sends `[emergencia]` as observations.
3. The engine returns `do(pulsa_boton,0)` and updates the clock to `t=1`.
4. Send `[]` for a quiet step: no goal is triggered and no action is issued.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*
