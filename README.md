# Gloria – SWI-Prolog Reasoner and Ciao Port

## Overview
Gloria is a goal-directed reactive-agent reasoner written in Prolog. This
repository ships **two implementations of the same engine** and verifies that
they behave identically:

- the **original SWI-Prolog engine** (`gloria.pl` and friends at the repository
  root), with an **MCP server** and a **web application** under `web/`; and
- a **Ciao-Prolog port** under `ciao/gloria/`, used both natively and through a
  wasm browser playground.

The port achieves **behavioral parity** with the SWI implementation across all
seven example agents (enclosure, burocratin, gerente, arch, mylamp, rentin,
emergencia) and includes a full **Ciao `unittest` suite**.

| Path | What it is |
|---|---|
| `gloria.pl`, `equiva.pl`, `implica.pl`, `rplan.pl`, `rewrite.pl`, `auxilia.pl`, … | SWI-Prolog engine and helpers |
| `examples/<agent>/` | Agent sources (`<agent>.kb`, `<agent>.main`, sometimes `<agent>.g`) |
| `src/agents/<agent>/` | Copies used to generate the Ciao playground sources |
| `web/mcp/` | MCP server (`gloria_mcp.py`) + SWI JSON-lines worker (`runner.pl`) |
| `web/server/` | SWI HTTP API server (port 8080) |
| `web/client/` | React/Vite front end for the web application |
| `ciao/gloria/` | Ciao port: engine, tests, parity harness |
| `playground/` | Ciao wasm playground: `mkpage.py`, generated `gloria.html`, ALDs |

---

# Part 1 — SWI-Prolog (the original engine)

The SWI engine can be used at three levels. They are independent: you do not
need the MCP server or the web app to run the engine, and you do not need the
web app to use MCP.

## Prerequisites

```bash
swipl --version          # SWI-Prolog (tested with 9.3.26)
python3 --version        # only for the MCP server
node --version           # only for the web front end (tested with v24)
```

The MCP server uses the Python environment in `.venv/`, which must have the
`mcp` package installed:

```bash
.venv/bin/python -c "import mcp; print('MCP OK')"
```

If `.venv/` does not exist, create it and install the dependency:

```bash
python3 -m venv .venv
.venv/bin/pip install mcp
```

## 1.1 Direct SWI engine (no MCP, no web)

The engine entry point is `prolog_agent/5`:

```prolog
prolog_agent(Agent, Time, ResourceLimit, Observations, Actions)
```

An agent is built from two files: the `.main` file (configuration: `abd/1`,
`observable/1`, `user_built/1`, `for_testing_only/1`, `tracefile/1`) and the
`.kb` file (goals `if_/2` and beliefs `def/2`). Load the `.main` into `user`,
build a module from the `.kb`, then run a step.

**One-shot query from the repository root:**

```bash
swipl -q -g "consult('examples/enclosure/enclosure.main'), \
             make_module(enclosure0, 'examples/enclosure/enclosure.kb'), \
             prolog_agent(enclosure0, 0, 400, [time_day(am), it_is(sunny)], A), \
             writeq(A), nl" \
      -t halt gloria.pl
```

Expected output:

```prolog
[do(shut(east_window),0),do(open(doors),0)]
```

A one-step emergency example:

```bash
swipl -q -g "consult('examples/emergencia/emergencia.main'), \
             make_module(emergencia0, 'examples/emergencia/emergencia.kb'), \
             prolog_agent(emergencia0, 0, 400, [emergencia], A), \
             writeq(A), nl" \
      -t halt gloria.pl
```

→ `[do(pulsa_boton,0)]`

> **Important:** put the SWI options (`-g`, `-t`, …) **before** the
> `gloria.pl` argument. Anything after the file is treated as a script
> argument and silently ignored.

**Interactive session:**

```bash
swipl -q gloria.pl
```

```prolog
?- consult('examples/enclosure/enclosure.main').
?- make_module(enclosure0, 'examples/enclosure/enclosure.kb').
?- prolog_agent(enclosure0, 0, 400, [time_day(am), it_is(sunny)], A).
A = [do(shut(east_window),0),do(open(doors),0)].
```

The agent module name (`enclosure0` above) is arbitrary; use a different name
per agent/session so their asserted clauses do not mix. The engine prints its
reasoning trace to `stderr`; redirect it to `/dev/null` if you only want the
actions.

**Multi-step scenarios:** keep the module and call `prolog_agent/5` again with
`Time` = 0, 1, 2, … Each step retracts the previous step's action/goal memory
and continues from the agent's current state.

**Interactive test harness (optional):** `gtester.pl` loads `gloria.pl` and
runs an agent step by step, reading observations from stdin:

```bash
cd examples/enclosure
swipl -q -g "start_test(enclosure, enclosure0)" ../../gtester.pl
```

## 1.2 SWI + MCP server

`web/mcp/gloria_mcp.py` exposes the SWI agents to any MCP client (opencode,
Claude Desktop, the MCP inspector, …). It keeps one long-lived SWI worker
(`web/mcp/runner.pl`) and loads one agent at a time into it.

### Tools

| Tool | Arguments | Purpose |
|---|---|---|
| `gloria_list_agents` | — | List agent names found under `examples/` |
| `gloria_agent_info` | `agent` | Goals, beliefs, observables and abducibles of an agent |
| `gloria_run_step` | `agent`, `input`, `session` | Run one step; returns actions, time and trace |
| `gloria_reset` | `agent` (default `_all_`), `session` | Forget the clock so the next step restarts at time 0 |

`input` is a **Prolog term list** written as a string, e.g.
`"[time_day(am), it_is(sunny)]"`. Use the same `session` value across calls
to keep the time counter (`0`, `1`, `2`, …) and goals between steps.

### Run it from opencode

The server is already registered in `opencode.json`:

```json
{
  "mcp": {
    "gloria": {
      "type": "local",
      "command": [
        "bash", "-c",
        "cd \"$(git rev-parse --show-toplevel)\" && exec .venv/bin/python web/mcp/gloria_mcp.py"
      ],
      "enabled": true
    }
  }
}
```

Restart opencode after changing that file. The four `gloria_*` tools then
appear automatically.

### Run the MCP server standalone

```bash
.venv/bin/python web/mcp/gloria_mcp.py
```

It speaks the MCP protocol over stdio, so it normally runs under a client
rather than in a terminal. To check that it starts without errors:

```bash
timeout 5 .venv/bin/python web/mcp/gloria_mcp.py
```

### Debug the worker without MCP (JSON lines)

`web/mcp/runner.pl` is the SWI process underneath the MCP server; it accepts
one JSON object per line. This is the quickest way to test an agent or a
scenario without any client:

```bash
printf '%s\n' \
  '{"cmd":"list_agents"}' \
  '{"cmd":"agent_info","agent":"emergencia"}' \
  '{"cmd":"run_step","agent":"emergencia","input":"[emergencia]","session":"s"}' \
  '{"cmd":"run_step","agent":"emergencia","input":"[]","session":"s"}' \
  '{"cmd":"reset","agent":"emergencia","session":"s"}' \
| swipl -q -s web/mcp/runner.pl -g main -t halt
```

The replies are JSON objects with `"ok":true` (or `"ok":false` and an
`"error"`). Note that `list_agents` returns every directory under `examples/`,
which currently includes the auxiliary `taquilla` directory in addition to the
seven documented agents.

Worker commands: `list_agents`, `agent_info`, `run_step`, `reset`, `quit`.

## 1.3 SWI + web application

The web app is a thin React front end plus an SWI HTTP backend. It is
**separate** from the Ciao wasm playground served by `serve_gloria.sh` (see
Part 2); do not mix the two.

```
browser ──► Vite dev server :5173 ──/api proxy──► SWI backend :8080 ──► gloria.pl
                    (development)
browser ──► SWI backend :8080 (serves web/client/dist + /api)   (production)
```

### Start the backend

```bash
swipl -q -s web/server/server.pl -g "start_server, thread_get_message(_)"
```

This serves on **http://localhost:8080** and stays in the foreground. The
`thread_get_message(_)` is needed to keep the process alive: without it, SWI
reaches the end of the goal and exits when stdin closes. Press `Ctrl-C` to
stop it.

### API endpoints

| Method | Path | Body | Response |
|---|---|---|---|
| `GET` | `/api/examples` | — | `{"examples":["arch", …]}` |
| `POST` | `/api/session/start` | `{"agent":"emergencia"}` | `{"agent":"emergencia","status":"started"}` |
| `POST` | `/api/session/step` | `{"input":"[emergencia]"}` | `{"actions":["do(pulsa_boton,0)"],"next_time":1}` |

`/api/session/start` loads `examples/<agent>/<agent>.main` and
`examples/<agent>/<agent>.kb`, resets the clock to 0 and remembers the current
agent. Each `/api/session/step` runs `prolog_agent/5` at the current time,
increments it, and returns the actions as strings. This is a single-user
prototype: there is one global session, so it expects the
`examples/<agent>/<agent>.kb` naming convention (the `arch` example uses
`ex-arch.kb` and therefore needs the direct engine or MCP path).

Quick smoke test:

```bash
curl -s http://localhost:8080/api/examples
curl -s -X POST http://localhost:8080/api/session/start \
     -H 'Content-Type: application/json' -d '{"agent":"emergencia"}'
curl -s -X POST http://localhost:8080/api/session/step \
     -H 'Content-Type: application/json' -d '{"input":"[emergencia]"}'
curl -s http://localhost:8080/ | head
```

### Front end: development mode

Keep the backend running, then in another terminal:

```bash
cd web/client
npm install          # first time only
npm run dev
```

Open **http://localhost:5173**. Vite proxies `/api` to
`http://localhost:8080` (see `web/client/vite.config.js`), so agent listing and
reasoning steps go to the SWI backend while you get hot reload.

### Front end: production mode

```bash
cd web/client
npm run build        # writes web/client/dist/
```

Then restart (or start) the backend as above and open
**http://localhost:8080**. `web/server/server.pl` serves `web/client/dist`
statically from `/`, alongside the `/api` endpoints. Re-run `npm run build`
after changing the front end.

---

# Part 2 — Ciao-Prolog port and wasm playground

This part is the Ciao implementation. It is independent of Part 1: the MCP
server and the `web/` application always run the SWI engine.

## 📋 Current Status

| Work Package | Deliverable | Status |
|---|---|---|
| **WP0** | Feasibility spike (port minimal path, parity harness) | **DONE** |
| **WP1** | Engine port (`:- module/2` headers; `gloria.pl` trimmed; unittest green) | **DONE** |
| **WP2** | Bundle packaging (`Manifest.pl`, `build.sh`, `COPYING` AGPL-3.0-or-later; agents under `examples/` + `src/agents/`; golden scenarios verified) | **DONE** |
| **WP3** | Wasm + app (`playground/gloria.html`, generated by `playground/mkpage.py`; wasm grade installed; page served from the assembled site; verified headless in Chrome — Load ▶ then `prolog_agent(...)` returns the golden actions) | **DONE** |
| **WP4** | Docs + ALDs (8 ALD notebooks; LPdoc manual = existing doc structure) | **DONE** |

## 🔍 Verification Suites (Run These First)

### 1. Cross-Engine Parity Harness
```bash
export PATH="$HOME/.ciaoroot/v1.25.0-m1/build/bin:$PATH"
./ciao/gloria/tests/parity_scenarios_check.sh
```
Adjust the path to whichever Ciao install works in your environment: some
timestamped installs under `~/.ciaoroot/` are non-relocatable and fail with
`exec: .../ciaoengine: not found`, while `v1.25.0-m1` works in this checkout.
**Expected output:** All **7** agents show `PARITY: OK` with byte-identical
Ciao/SWI action lists (enclosure, burocratin, gerente, arch, mylamp, rentin,
emergencia).

### 2. Ciao unittest Suite
```bash
ciao run ciao/gloria/tests/run_unittests.pl
```
**Expected output:** `Note: {Total: Passed: 13 (100.00%) Failed: 0 (0.00%) ...}` + `UNITEST status=0`

(The suite has two halves: `t_engine` replays the golden scenarios through
`load_agent/2` on the `examples/` `.kb` files, and `t_playground` replays the
same scenarios through `load_agent_code/1` on the generated
`playground/agents/*.pl` files, plus the page's `disguise_trans_query/3`
rewriting.  The latter covers the exact entry point the browser page uses.)

## 🛠️ Local Self-Hosted Testing

### 3. Regenerate the page and the agent sources
```bash
python3 playground/mkpage.py
```
**What this does:** rebuilds `playground/gloria.html` and
`playground/agents/*.pl` from `src/agents/`, so the page and the shipped agent
sources never drift from the engine data.  Run it after editing an agent;
`serve_gloria.sh` then copies the regenerated page into the served site.

### 4. Start the Local Server
```bash
./serve_gloria.sh
```
**What this does:**
- Copies the generated `playground/gloria.html` into the served site (this is
  what makes a newly added agent appear in the *Examples* menu)
- Serves the assembled site (`$CIAOROOT/build/site`) on `http://localhost:8000`
- Uses the threaded `mt-httpd.py` from `ciao_playground` (CORS + `application/wasm`)

> This is the **Ciao/wasm** playground on port **8000**. It is not the SWI web
> app on port 8080 described in Part 1.

### 5. Open the Playground Page
```bash
open http://localhost:8000/playground/gloria.html
```
**You will see:**
- The editor holding a self-contained Gloria agent (`enclosure` by default)
- An *Examples* menu with the seven agents (enclosure, burocratin, gerente,
  arch, mylamp, rentin, emergencia)
- A *Run agent* menu with the Prolog query for each agent and scenario
  (e.g. `prolog_agent(emergencia, 0, 400, [emergencia], Actions).`).  Selecting
  an entry inserts the query into the top level; load the agent first
  (`Examples` → agent → `Load ▶`), then press Enter to run the inserted query.
- A top level where you type the reasoning queries, after pressing `Load ▶`:
  `?- prolog_agent(enclosure, 0, 400, [time_day(am), it_is(sunny)], Actions).`

### 6. ALD Notebooks
The playground includes 8 Active-Learning Documents:
- `alds/intro.md` – Gloria cycle: observables, abducibles, goals (`if_/2`), beliefs (`def/2`), time, actions (`do/2`)
- `alds/enclosure.md` – Two-step scenario: `[time_day(am), it_is(sunny)]` → shut east + open doors; then pm/rainy → 3 actions
- `alds/burocratin.md` – "sigo_procedimiento" example: `me_pide(juan, sacar_constancia)` → `do(lee(sacar_constancia),0)`
- `alds/gerente.md` – Bank queue manager: `timing(1)/cola_larga` → step-0 actions; `timing(2)/taq_vacias` → step-1 actions
- `alds/arch.md` – Abduction example: `build(5), c(5), c(8), b(10)` → `do(do(8),0) x2 + do(do_b(10),0)`
- `alds/mylamp.md` – Motion-triggered lamp: `motion(room)` → `do(switch_on(lamp1),0), do(log(room),0)`
- `alds/rentin.md` – Opportunist who rationalises abuse: `[flojera, gano, no_hay_jueces_confiables, sin_observador]` → `do(no_trabajo,0), do(abuso,0)`; with `observador_independiente` → `do(no_trabajo,0)` only
- `alds/emergencia.md` – Emergency help: `[emergencia]` → `do(pulsa_boton,0)`; no observation → no actions

## 📦 What's Included

| File/Directory | Purpose |
|---|---|
| `Manifest/Manifest.pl` | Bundle declaration, deps (`core, ciaowasm, builder`), `library` alias paths, builder hook for `playground/gloria.html` |
| `build.sh` | Local development build/serve script |
| `COPYING` | License notice (AGPL-3.0-or-later; see `LICENSING.md`) |
| `src/` | Engine files with `:- module/2` headers (rplan, implica, equiva, rewrite, auxilia + gloria.pl trimmed) |
| `examples/` | Original agent `.g`/`.kb`/`.main` files |
| `tests/` | Parity harness, unittest suite, scenarios |
| `playground/` | `gloria.html` (generated), `mkpage.py`, `agents/` (generated), `alds/` |
| `serve_gloria.sh` | One-command local server (Ciao/wasm, port 8000) |
| `testing_emscripten.md` | Emscripten/wasm testing guide (full wasm build) |
| `CIAO-PLAYGROUND-PROJECT.md` | WP0–WP4 status & milestones |

## 🛠️ Developer Notes

### Native Ciao Engine (Already Verified)
- `./ciao/gloria/tests/parity_scenarios_check.sh` – 7/7 agents **PARITY: OK**
- `ciao run ciao/gloria/tests/run_unittests.pl` – `status=0`, **13/13 passed**
- No errors/warnings in `gloria.pl` compilation

### Wasm/Emscripten (Future)
- `emcc 6.0.10` is available at `~/git/emsdk/`
- Full `ciao install --grade=wasm gloria` integration is documented in `testing_emscripten.md`
- Requires catalog activation; not currently enabled in this environment

### Adding New Agents
See [`Como_agregar_otro_ejemplo.md`](Como_agregar_otro_ejemplo.md) for the
complete, step-by-step recipe (it documents how `emergencia` was added). In
short:

- Create `examples/<name>/<name>.kb` (goals `if_/2`, beliefs `def/2`) and
  `examples/<name>/<name>.main` (config: `abd/1`, `observable/1`,
  `user_built/1`, `for_testing_only/1`). The MCP server and the SWI web API
  discover agents by directory and load the `<name>.main`/`<name>.kb` pair.
- Every `.main` **must** define `user_built/1` (e.g. `user_built(true).`); the
  SWI engine calls `Ag:user_built/1` and raises
  `existence_error(user_built/1)` when it is missing.
- Mirror the `.kb`/`.main` pair under `src/agents/<name>/` and register the
  agent in `AGENTS` and `AGENT_RUNS` in `playground/mkpage.py`; then run
  `python3 playground/mkpage.py` (never hand-edit `playground/agents/*.pl` or
  `playground/gloria.html`).
- Add an ALD under `playground/alds/<name>.md`, a `run_one` line in
  `ciao/gloria/tests/parity_scenarios_check.sh`, and the corresponding
  `:- test` cases in `ciao/gloria/tests/t_engine.pl` and
  `ciao/gloria/tests/t_playground.pl`.

## 📜 License
This project is licensed under the **GNU Affero General Public License, version 3 or later (AGPL-3.0-or-later)** — see [`LICENSE`](LICENSE) for the full text and [`LICENSING.md`](LICENSING.md) for the details.

The Ciao port under `ciao/gloria/src/` is dual-licensed and may also be used under the **GNU Lesser General Public License, version 3 or later (LGPL-3.0-or-later)**, so that it can be combined with the Ciao system. Note that `flach/` contains third-party material with its own terms (see [`LICENSING.md`](LICENSING.md)).

## 📬 Contact
- **Repository:** this checkout (the Gloria source tree)
- **Author:** Gloria project (J. Davila)
- **Ciao environment:** `CIAOROOT=$HOME/.ciaoroot/v1.25.0-m1` (use the install that works on your machine; see the parity note above)

---

*This README documents both the original SWI-Prolog engine (with its MCP and
web front ends) and the Ciao-Prolog port with its self-hosted wasm playground.*
