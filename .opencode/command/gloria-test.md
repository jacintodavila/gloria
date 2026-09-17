---
description: Run a Gloria agent through the MCP server for one or more reasoning steps.
agent: gloria-test
---

Use the gloria MCP tools to run a Gloria agent and explain the result.

$ARGUMENTS

If the arguments do not name an agent, pick `enclosure`, run it for two steps
with input `[time_day(am), it_is(sunny)]` then `[time_day(pm), it_is(rainy)]`,
and summarize the actions. If the arguments name an agent and an input, call
`gloria_reset` and then `gloria_run_step` with exactly that input. Always show
the actions and the current/next time.
