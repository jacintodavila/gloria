# Introduction to Gloria reactive agents

## The Gloria cycle

Gloria is a goal-directed, reactive-agent reasoner that runs an *abductive reasoning cycle* over an agent knowledge base.

### Core concepts

- **Observables** – facts about the current world state (e.g., `time_day(am)`, `it_is(sunny)`).
- **Abducibles** – facts that can be assumed to explain observations (e.g., `adjust_home(am, sunny)`).
- **Goals** – desired states or actions, encoded via `if_/2` clauses.
- **Beliefs** – persistent knowledge about the agent, encoded via `def/2`.
- **Time** – discrete time steps; each step produces `do(Name,Time)` actions.
- **Actions** – `do(Name,Time)` denotes an action performed at a given time.

### The reasoning cycle (high-level)

1. **Observing** – read the current observables from the input.
2. **Abducing** – generate candidate explanations (abducibles) for the observations.
3. **Applying goals** – use `if_/2` to determine which actions achieve the goals.
4. **Updating beliefs** – persist the derived beliefs via `def/2`.
5. **Producing actions** – output the `do/2` list for the next time step.

### Example: enclosure two-step scenario

- **Step 0** (`time_day(am), it_is(sunny)`): `do(shut(east_window),0), do(open(doors),0)`
- **Step 1** (`time_day(pm), it_is(rainy)`): `do(shut(east_window),1), do(shut(west_window),1), do(shut(doors),1)`

### Running in the Playground

- Pick an agent from the menu, press **Load**, then **Step** to advance one cycle.
- Observations are passed programmatically; no interactive input is required in the browser runtime.

---

*This notebook is part of the Ciao Prolog Playground ALD (Active-Learning Document) material for the Gloria reactive-agent reasoner.*