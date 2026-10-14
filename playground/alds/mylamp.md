# MyLamp agent – motion-triggered lamp example

## One-step scenario

**Initial state**: `motion(room)`

**Step 0** – the agent observes motion in the `room` and decides to switch on
the lamp and log the room:

```
do(switch_on(lamp1),0), do(log(room),0)
```

## How it works

The mylamp agent's knowledge base (`examples/mylamp/mylamp.kb`) contains:

- `if_(motion(M), [light_on(M)]).`
- `def(light_on(M), (switch_on(lamp1), log(M))).`

The reasoning cycle:

1. **Observing**: `motion(room)`.
2. **Abducing**: match `if_(motion(M), [light_on(M)])` → `light_on(room)`.
3. **Applying goals**: `def(light_on(room), (switch_on(lamp1), log(room)))` →
   produce `do(switch_on(lamp1),0), do(log(room),0)`.

## Running step-by-step in the Playground

1. **Load** the mylamp agent.
2. **Step 0** – the Playground sends `[motion(room)]` as observations.
3. The engine returns `do(switch_on(lamp1),0), do(log(room),0)` and updates the
   clock to `t=1`.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*
