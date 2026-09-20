# Enclosure agent – window/door example

## Two-step scenario

**Initial state**: `time_day(am), it_is(sunny)`

**Step 0** – the agent observes `time_day(am)` and `it_is(sunny)`, and decides to shut the east window and open the doors:

```
do(shut(east_window),0), do(open(doors),0)
```

**Step 1** – time progresses to `pm`, and it starts raining. The agent now shuts the east window, the west window, and the doors:

```
do(shut(east_window),1), do(shut(west_window),1), do(shut(doors),1)
```

## How it works

The enclosure agent's knowledge base (`examples/enclosure/enclosure.kb`) contains:

- `def(adjust_home(am, sunny), (shut(east_window), open(doors))).`
- `def(adjust_home(pm, sunny), (shut(west_window), open(doors))).`
- `def(adjust_home(Anytime, rainy), (shut(east_window), shut(west_window), shut(doors))).`
- `if_((time_day(Time),it_is(Temp)),[adjust_home(Time,Temp)]).`

The reasoning cycle:

1. **Observing**: `time_day(am), it_is(sunny)`.
2. **Abducing**: match `if_((time_day(Time),it_is(Temp)),[adjust_home(Time,Temp)])` → `adjust_home(am, sunny)`.
3. **Applying goals**: `def(adjust_home(am, sunny), (shut(east_window), open(doors)))` → produce `do(shut(east_window),0), do(open(doors),0)`.

## Running step-by-step in the Playground

1. **Load** the enclosure agent.
2. **Step 0** – the Playground sends `[time_day(am), it_is(sunny)]` as observations.
3. The engine returns `do(shut(east_window),0), do(open(doors),0)` and updates the clock to `t=1`.
4. **Step 1** – send `[time_day(pm), it_is(rainy)]`.
5. The engine returns `do(shut(east_window),1), do(shut(west_window),1), do(shut(doors),1)`.

---

*This notebook is part of the Ciao Prolog Playground ALD material for the Gloria reactive-agent reasoner.*