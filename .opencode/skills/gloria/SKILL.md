---
name: gloria
description: Use when the user wants to run, test, query or demonstrate a Gloria agent (enclosure, burocratin, gerente, arch) - "run the enclosure agent", "Gloria reasoning step", "gloria_run_step", "what actions does the burocratin agent take", "list Gloria agents". Covers the gloria MCP tools, the observation/action/session model, and how to read a reasoning trace.
---

# Gloria via the gloria MCP server

Gloria is a goal-directed reactive-agent reasoner written in SWI-Prolog. It is
exposed to opencode through the `gloria` MCP server (`web/mcp/gloria_mcp.py`),
which keeps one long-lived `swipl` worker (`web/mcp/runner.pl`) and speaks a
small JSON protocol with it.

## Tools

| Tool | Arguments | Returns |
| --- | --- | --- |
| `gloria_list_agents` | none | names of runnable agents in `examples/` |
| `gloria_agent_info` | `agent` | description, goals, beliefs, observables, abducibles |
| `gloria_run_step` | `agent`, `input`, `session` (default `default`) | `actions`, `time`, `next_time`, `trace` |
| `gloria_reset` | `agent` (default `_all_`), `session` (default `default`) | acknowledgement |

## The reasoning model

- **Agents** live in `examples/<agent>/`. Each has a `.main` file (library
  include, `abd/1`, `observable/1`, `for_testing_only/1`) and a `.kb` file
  (goals `if_/2` and beliefs `def/2`).
- **Observables** are what the agent can perceive; they are passed to
  `gloria_run_step` as a Prolog term list, e.g. `[time_day(am), it_is(sunny)]`.
  Pass `[]` when nothing is observed.
- **Abducibles** are the predicates the agent may assume or act upon. Actions
  come back as `do(Name, Time)` terms, e.g. `do(shut(east_window),0)`.
- **Time** advances by one on every `gloria_run_step` call for a given
  `(agent, session)`. `time` is the step just run, `next_time` is the step the
  next call will use. Call `gloria_reset` to make the next step time `0`
  again.
- **Sessions** isolate clocks. Use a different `session` per scenario. Only one
  agent's knowledge base is loaded at a time; the server unloads the previous
  agent automatically.
- **Trace** is the list of `# Gloria ...` lines that the reasoner wrote while
  reasoning: the cycle entry, recovered goals, the "about to think"/"has
  thought" goal stacks, and the produced outputs. Use it to explain *why* an
  action was chosen, not just *what*.

## Typical workflow

1. `gloria_agent_info` for the agent (or read the per-agent skill below).
2. `gloria_reset` with the chosen agent and session.
3. One `gloria_run_step` per time step, reusing the session to continue.
4. Report: per step the input, the actions, and the interpretation.

## Per-agent skills

See `gloria-enclosure`, `gloria-burocratin`, `gloria-gerente` and
`gloria-arch` for each agent's observables, goals and a known-good sample run.

## Caveats

- `taquilla` appears in `gloria_list_agents` but is a Galatea simulation
  specification, not a single runnable `prolog_agent`; `gloria_run_step` is not
  meaningful for it.
- Warnings from loading an agent (e.g. singleton variables) are normal and
  appear at the start of the trace.
- If `gloria_run_step` reports `agent produced no result`, the observed input
  did not satisfy any goal; check the agent's observables and try a matching
  observation.
