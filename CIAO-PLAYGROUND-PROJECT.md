# Project proposal: adopting Gloria as a Ciao package and standalone Ciao-Playground web application

Status: draft (v0.1) — **WP0 (feasibility spike) DONE; WP1 engine port underway** (4/4 agent scenarios parity achieved, Ciao unittest suite green, gloria.pl module header trimmed; remaining five engine files need `:- module/2` headers per §3.2).
Author: Gloria project (J. Davila) — for review by the Ciao team (CLIP group).

> **WP0 status (2026-09-19).** The minimal path is ported and parity is green:
> `ciao/gloria/src/` compiles and runs under native Ciao 1.25, and the
> enclosure two-step scenario (`[time_day(am), it_is(sunny)]` ->
> `[do(shut(east_window),0), do(open(doors),0)]`) produces output identical to
> the SWI engine, verified by the cross-engine harness
> `ciao/gloria/tests/parity_check.sh` (canonicalizes variables via
> `term_shape.pl` and diffs Actions/NextGs/OutGs). The existing SWI web app
> (`web/server/`) and JSON-lines MCP runner (`web/mcp/runner.pl`) were smoke
> tested after the SWI-side `gloria_step/7` refactor and still return the
> golden actions. Notable porting decisions so far: agent identity is reified
> (`def/3`, `if_/3`, `abd/2`, ... see §3.2); `load_agent/2` reads both the
> `.kb` and sibling `.main` files; SWI-only I/O sleeps/printing and the MIS
> learner are stubbed out of the Ciao runtime (kept as `:- fail.` placeholders).

Goal: adapt the Gloria reactive-agent reasoner (currently SWI-Prolog) to
Ciao-Prolog and deploy it as part of the Ciao Prolog Playground, following the
same bundle + wasm pattern already used by the s(CASP) and LPTP playgrounds.

---

## 1. Executive summary

Two deliverables:

1. **Ciao package (the `gloria` bundle).** A Ciao port of the Gloria reasoning
   engine plus the example agents, installable with `ciao install gloria` and
   runnable in a normal Ciao toplevel, tested with Ciao's `unittest` library
   and checkable with CiaoPP.
2. **Standalone web application (`/playground/gloria.html`).** A specialized
   Ciao-Playground page in the exact style of `/playground/scasp.html`. It
   runs entirely in the browser on the ciao-wasm engine: the user picks an
   agent, edits its goals/beliefs (or its `.g` openlog/actilog spec), feeds
   observations one step at a time, and sees both the produced
   `do(Action,Time)` outputs and the `# Gloria ...` reasoning trace.

No server is involved at runtime (2-3x slower than native wasm execution is
irrelevant for these toy-sized scenarios). Everything is deliverable as one
Ciao "bundle" that any Ciao installation — including the official ciao-lang.org
playground — can pick up.

Secondary deliverables: an LPdoc manual for the bundle, and Active-Logic-Document
(ALD) notebooks teaching the Gloria model (observables, abducibles, goals,
beliefs, the reasoning cycle) with editable, runnable cells.

---

## 2. Background

### 2.1 What Gloria is

Gloria is a goal-directed, reactive-agent reasoner in Prolog (~1997--).
It runs an *abductive reasoning cycle* over an agent knowledge base.

- **Engine** (bare Prolog, no modules, no foreign code):
  - `gloria.pl` — the agent cycle, `prolog_agent/5`, `thinking`, IC
    extraction, criticism/learning hooks.
  - `rplan.pl` — the reactive planner (the `demo_impl` continuation machine).
  - `implica.pl` — the Abductive Proof Procedure (`demo/9`) using `if_/2`.
  - `equiva.pl` — equivalence of formulas and case analysis.
  - `rewrite.pl` — equality/inequality rewriting (`eq`, `ge`, `le`, `gt`, `lt`).
  - `auxilia.pl` — support predicates and custom operators (`if/2`, `@`, `::`, `eq`...).
  - `flach/mis.pl` — optional MIS-style learning (`learning/5`); off in the
    web/MCP flows (`for_testing_only(false)`).
- **Agent sources** (`.g` files; openlog/actilog, Spanish or English):
  `TITLE / NETWORK / AGENTS / GOALS / BELIEFS / Prolog / ...` — see
  `examples/burocratin/burocratin.g`, `examples/gerente/gerente.g`,
  `examples/enclosure/enclosure.g`.
- **Compiled agents**: `.kb` (clauses `def(Head,Body)` and `if_(Conds,[Goal])`,
  produced by `gcompile.pl` + `tokenizer.pl`, which are pure DCG) and `.main`
  (`abd/1`, `observable/1`, `user_built/1`, `dynamic` declarations, plus the
  `:- ['../../gloria.pl']` include).
- **Entry point**: `prolog_agent(Agent, Time, 200, Observations, Actions)`,
  returning `[do(Name,Time)]` and writing a human-readable `# Gloria ...`
  trace to `user_error`. This is what the existing SWI web app, `gtester.pl`,
  and the MCP server (`web/mcp/runner.pl`) all call.

### 2.2 The Ciao Playground platform

Two layers exist today:

- `ciao-lang/ciaowasm` — builds a wasm *build grade* Ciao engine with
  Emscripten and ships the `ciao-prolog.js` JS client (browser + `node` REPL);
  it is what the Playground and LPdoc ALDs use. The build-grade support lives
  in `builder/` of the main `ciao-lang/ciao` repo.
- `ciao-lang/ciao_playground` — the Playground bundle: Monaco editor, a
  top-level proxy configured via `window.toplevelCfg` (`custom_load_query`,
  `custom_run_query`, `special_query`, `init_bundles`, `init_queries`,
  `custom_postprint_sol`), LPdoc preview, and standalone applications driven
  by `window.playgroundCfg`.

**Distribution model.** A *bundle* is a directory with `Manifest/Manifest.pl`.
Bundles carrying a `playground/` directory are detected by the `ciao_playground`
hooks `list_playgrounds` / `dist_playground`
(`ciao_playground/Manifest/ciao_playground.hooks.pl`): their `playground/*.html`
are copied to the site's `/playground/` and `playground/*.js` to `/playground/js`.
That is exactly how `scasp.html` ships — the s(CASP) bundle puts its own
`playground/scasp.html` and the page appears on ciao-lang.org.

The standalone-app contract (from the s(CASP) source, `playground/scasp.html`):

```js
window.playgroundCfg = {
  title: "playground for s(CASP)",
  window_layout: ['E','T','P'],
  storage_key: 'code_scasp',
  splash_code: `...`,
  example_list: [ /* menu items -> files */ ],
  has_ext_mode_button: false, /* etc. */
};
window.toplevelCfg = {
  special_query: { "load": { read_code: true } },
  init_bundles: ['ciaowasm', 'core', 'builder', 'sCASP'],
  init_queries: ['use_module(library(classic/classic_predicates))',
                 'use_module(scasp(scasp))'],
  custom_load_query: m => "load('" + m + "')",
  custom_run_query: q => quote_and_wrap(q),
  custom_postprint_sol: async (pg) => { /* read 'draft.html' from VFS, render */ }
};
```

Notably, the page reads a file the *Prolog* side writes (`draft.html`) and
renders it in the preview area — exactly the pattern Gloria can reuse for its
reasoning traces.

### 2.3 Why a Gloria port is feasible

- The engine is **bare, pure Prolog** and mostly dialect-insensitive.
- The SWI-specific surface is small, localized, and documented (§3); most of
  it is interactive I/O and the SWI *"dynamic module per agent"* harness —
  both replaced by design, not patched.
- `gcompile.pl` + `tokenizer.pl` are **pure DCG** and port nearly verbatim.
- Ciao already provides the pieces Gloria needs: `format/2,3`, `sformat/3`,
  `format_to_string/3` (`library(format)`, reexported by
  `library(classic/classic_predicates)`), `read_term/2,3`,
  `read_from_string/2,3`, `current_prolog_flag/2` and `current_module/1`
  (`engine(runtime_control)`), `catch/3`, `dynamic` predicates, ISO list and
  term predicates.

---

## 3. Porting analysis (SWI -> Ciao)

### 3.1 Portability matrix

| Gloria call | Where | Ciao status | Action |
| --- | --- | --- | --- |
| `format(Stream,Fmt,Args)` | generic IO + trace | `format/2,3` in `library(format)` | keep; verify `user_error` stream atom on wasm |
| `writeln/1,2`, `writef/2` | interactive cycle, gcompile | not builtin | shim in `gloria_utils.pl` (use `format`); interactive writers excluded from the browser runtime |
| `print_message/2` | `gloria.pl` `eval/0`/`main/0` | SWI-only | drop (`main/0` not part of the Ciao API) |
| `current_prolog_flag/2` | `eval/0` (argv) | `engine(runtime_control)` | keep only if needed |
| `current_module/1` | `make_module/2` | `engine(runtime_control)` | obsoleted by the redesign (§3.2) |
| `add_import_module/3` | `make_module/2` | not supported | replace (redesign) |
| `read_file_to_terms/3` | `make_module/2` | read-loop instead | port as `read_terms_from_stream/2` (and `read_from_string` for text) |
| `term_to_atom/2`, `atom_string/2` | `eval/0`, `to_module_atom/1` | via `sformat` / atom-to-string libs | shim; mostly dropped |
| `read_term/2,3`, `read/1` | interactive observing | supported | not needed in browser runtime |
| `sleep/1` | `gloria.pl` demo pacing | library shim | trivial / drop |
| `catch/3`, `throw/1` | generic | ISO | keep |
| `assertz/asserta/retractall` on owned `dynamic` preds | `def/2`, `if_/2`, `goalsmem/4`, `actionsmem/4`, `ghistory/1` | supported | keep with Ciao `:- dynamic` declarations |
| `Ag:Pred(...)` **runtime-qualified calls/asserts** | engine-wide (def, if_, mems, ghistory, abds, observables) | **not supported** — Ciao forbids defining clauses of other modules via qualification | **redesign: reify the agent id (§3.2)** |
| DCG (`-->`) | `gcompile.pl`, `tokenizer.pl` | supported | keep verbatim |
| `:- op` declarations | `auxilia.pl`, `gloria_ops.pl` | supported | keep per module |
| `findall/3`, `length/2`, `member/2`, `append/3`, arithmetic | engine | ISO | keep |
| `flach/mis.pl` (MIS learner) | `learning/5` | portable in principle | exclude from browser build; keep as an optional native-only module |

### 3.2 The architectural change: reify the agent

Gloria currently treats each agent as a **SWI dynamic module**:
`Ag:def/2`, `Ag:if_/2`, `Ag:actionsmem/4`, `Ag:goalsmem/4`, `Ag:ghistory/1`,
created at runtime with `make_module/2` / `add_import_module/3` and populated
with `assert(Mod:Term)`. Ciao's module system is static and explicit: a
module-qualified predicate cannot be used to access predicates that were not
imported, nor to define clauses of another module (Ciao module-system manual).
The agent-as-module trick therefore cannot be ported as-is.

Resolution: keep the reasoner's semantics, but **reify the agent identifier**
— every per-agent predicate gains the agent as its first argument and lives in
one shared, `dynamic` database owned by the `gloria` library:

| SWI (agent = module) | Ciao (agent = record) |
| --- | --- |
| `Ag:def(H,B)` | `def(Ag,H,B)` |
| `Ag:if_(B,H)` | `if_(Ag,B,H)` |
| `Ag:actionsmem(Ag,T,A,P)` | `actionsmem(Ag,T,A,P)` |
| `Ag:goalsmem(Ag,T,G)` | `goalsmem(Ag,T,G)` |
| `Ag:ghistory(A)` | `ghistory(Ag,A)` |
| `Ag:abd(X)` / `Ag:observable(P)` / `Ag:user_built(P)` | `spec(Ag, abd(X))` / `spec(Ag, observable(P))` / `spec(Ag, user_built(P))` |

`prolog_agent/5` keeps its public signature, so the existing SWI web server,
`gtester.pl` and the MCP runner continue to work unchanged with the original
SWI sources, while the Ciao port shares the same scenario outputs through the
reified core. Agents become data: `gloria_new_agent(Ag, File)` loads a
`.kb`/`.main`, and in the browser `gloria_load_agent_text(Ag, Text)` reads
terms from a string with `read_from_string/3` and asserts them — no dynamic
module hacks, fully portable to wasm.

The port also gives the six engine files proper `:- module/2` headers (with
explicit exports), keeps the `:- op` declarations, declares the shared dynamic
predicates, and adds Ciao assertions/props so CiaoPP can analyze and check the
code from the playground menus, and `unittest` can run the test suite in-page.

---

## 4. Package layout (the `gloria` Ciao bundle)

Mirrors the s(CASP) bundle layout and Ciao project conventions:

```
gloria/
  Manifest/Manifest.pl          # :- bundle(gloria). depends([core]). lib('src').
  src/
    gloria.pl                   # ported cycle + public API (module header)
    rplan.pl                    # ported reactive planner
    implica.pl                  # ported proof procedure
    equiva.pl
    rewrite.pl
    auxilia.pl                  # + reified predicate definitions
    gloria_utils.pl             # shims: writeln/2, writef/2, read_terms_from_stream/2
    gcompile.pl                 # ported openlog/actilog -> kb/main compiler
    tokenizer.pl                # ported tokenizer
    agents/
      enclosure.pl              # one module per example agent (compiled .kb/.main)
      burocratin.pl
      gerente.pl
      arch.pl
  examples/
    enclosure/ burocratin/ gerente/ arch/      # .g sources, .kb/.main, readme.txt
    expected-traces/            # golden traces (see §7)
  playground/
    gloria.html                 # standalone app page
    gloria.js                   # app logic (menus, run-step button, trace render)
    alds/*.md                   # ALD notebooks (editable/runnable tutorials)
  doc/reference/                # LPdoc source for the `gloria` manual
  tests/
    t_engine.pl                 # unittest/ assertions for the engine
    scenarios/                  # per-agent (input -> do/actions) expected results
  build.sh                      # local build/serve for development (see §6)
  COPYING                       # LGPL3 notices
```

`Manifest/Manifest.pl` essentials:

```prolog
:- bundle(gloria).
depends([core, ciaowasm, builder]).   % graded installs for the wasm site build
lib('src').
manual('gloria', [main='doc/reference/SETTINGS.pl']).

% hooks to expose /playground/gloria.html on the site build
'$builder_hook'(custom_run(dist_playground, [Bndl])) :-
    gloria_dist_playground(Bndl).
```

---

## 5. The standalone app: `/playground/gloria.html`

### 5.1 Behavior

The page lets the visitor:

1. Pick an agent (enclosure, burocratin, gerente, arch) from a menu (same
   mechanism as the s(CASP) example menu); the agent's editable openlog/actilog
   or `.kb` text loads into the editor.
2. Edit the agent and press *Load*; the page compiles/loads it into the wasm
   worker through `custom_load_query` -> `gloria:load_agent_code(...)`.
3. *Step the simulation*: a control row (agent selector, observations field,
   *Run step*, *Reset clock*) built on top of the top-level submits
   `gloria:run_step(Agent, [observation_terms])` (or `prolog_agent/5` with a
   client-tracked clock) and shows the returned `do(Name,Time)` actions.
4. Inspect the trace: the engine writes the `# Gloria ...` reasoning trace,
   the Prolog side renders it to a VFS file (`draft.html`-style), and the page
   JS renders it in the preview area - the same mechanism as the s(CASP)
   justification tree (`custom_postprint_sol`).

### 5.2 Configuration sketch

```js
window.playgroundCfg = {
  title: "playground for Gloria reactive agents",
  window_layout: ['E','T','P'],
  storage_key: 'code_gloria',
  splash_code: gloria_splash(),     // enclosure.kb + a commented step script
  example_list: [
    menu_h('Example agents'),
    menu_i('Enclosure (windows/doors)',  'gloria/examples/enclosure'),
    menu_i('Burocratin (procedures)',    'gloria/examples/burocratin'),
    menu_i('Gerente (queue manager)',    'gloria/examples/gerente'),
    menu_i('Arch (abduction example)',   'gloria/examples/arch'),
  ],
  has_run_tests_button: true,        // Ciao unittest on the ported engine
  has_doc_button: true,
 };

window.toplevelCfg = {
  special_query: { "load": { read_code: true } },
  init_bundles: ['ciaowasm', 'core', 'builder', 'gloria'],
  init_queries: [
    'use_module(library(classic/classic_predicates))',
    'use_module(library(gloria/gloria))'
  ],
  custom_load_query: m => "gloria:load_agent_code('" + m + "')",
  custom_run_query:  q => "gloria:step_query(" + q + ")",
  custom_postprint_sol: async (pg) => { render_trace(pg); }  // reads draft.html
};
```

### 5.3 Support predicates added by the Ciao port (app-facing API)

```prolog
:- export(prolog_agent/5).           % same public API as the SWI engine
:- export(load_agent_code/1).        % agent spec text -> reified KB
:- export(run_step/1).               % one cycle; also writes trace+actions to 'draft.html'
:- export(reset_clock/0, time/2).    % per-agent clock for step-by-step sessions
:- export(agent_info/3).             % goals/beliefs/observables for UI panels
```

The engine's interactive I/O (`observing/1`, `testing/2`, `read/1`) is
compiled out of the browser runtime (observations are passed in programmatically
in `prolog_agent/5`), keeping the wasm build lean.

---

## 6. Build and deployment pipeline

### 6.1 Local development

Reuses the `ciao_playground` build recipe (`build.sh` there), plus one extra
hook for the `gloria` bundle:

```sh
ciao build --bin gloria           # check/compile the ported engine (native)
ciao install --grade=wasm gloria  # wasm build grade for browser use
ciao custom_run ciao_playground dist            # assemble build/site
ciao custom_run ciao_playground dist_playground gloria   # copy gloria.html into /playground/
```

Serve with `ciao-serve-mt` (the multi-threaded server bundled with
`ciao_playground`; single-threaded servers deadlock wasm loading in some
browsers) and browse `http://localhost:8001/playground/gloria.html`.

### 6.2 Releasing on ciao-lang.org

Published like the s(CASP) and LPTP pages: the Ciao team's CI runs the build
for every bundle that has a `playground/` directory (see `list_playgrounds` in
`ciao_playground.hooks.pl` and `builder/etc/publish-bundle.sh`), so once
`gloria` is a recognized bundle the page appears automatically at
`https://ciao-lang.org/playground/gloria.html` with no extra coordination.

Two distribution options to negotiate with the Ciao team:

- **Option A (upstream bundle):** put `gloria` in the Ciao bundle ecosystem
  (own git repo, or as a contributed bundle), and have ciao-lang.org CI build
  it. Lowest deployment effort, best outreach.
- **Option B (self-hosted):** publish the built `build/site` (or a fork of the
  playground) on any static host. Same HTML, zero server requirements; useful
  as a staging/backup site.

### 6.3 CI for the project

A GitHub/GitLab Actions workflow that, on every push and nightly:

1. installs Ciao, `ciao_playground`, and `ciaowasm` deps (and Emscripten for
   wasm rebuilds);
2. runs the parity tests (section 7) under native Ciao and under the
   `ciao-wasm` node REPL;
3. runs the `unittest` suite (the playground *Run tests* button uses the same
   code);
4. produces a tarball of `build/site` for manual/offline testing.

---

## 7. Validation and testing strategy

The value of the port is *behavioral equivalence* with the SWI implementation,
so the plan centers on a **parity harness**:

1. **Golden scenarios.** For each example agent, capture the scenario sets from
   the per-agent skills and test files (enclosure two-step with
   `[time_day(am), it_is(sunny)]`, burocratin's `[me_pide(jefe, x), ...]`,
   gerente queue events, arch abduction) as (time, input, expected `do/2`
   list) triples in `tests/scenarios/`.
2. **Cross-dialect runs.** Run the same scenario under SWI (`swipl`, current
   engine), under Ciao native (ported engine) and under the wasm engine (via
   `node ciao-prolog.js`), normalize whitespace/formatting in the `# Gloria`
   traces, and diff. Any divergence is either a porting bug or a documented,
   behavior-preserving change.
3. **Unit tests in-page.** Ciao `unittest` assertions on the engine predicates
   (`ic/2`, `thinking/5`, `prolog_agent/5`) so the playground *Run tests*
   button exercises the engine in the browser.
4. **Manual app checks.** A checklist for `gloria.html`: agent switch, edit +
   reload, step/clock/reset behavior, trace rendering, "no result" (empty
   observation) diagnostics.

Acceptance criteria: all golden scenarios pass identically on the three
backends; no `# Gloria` trace line is lost; the four example agents run from a
clean browser session without a server.

---

## 8. Tutorial material (ALD notebooks)

In `playground/alds/`, markdown notebooks with editable/runnable cells, e.g.:

- `intro.md` — the Gloria cycle: observables, abducibles, goals (`if_/2`),
  beliefs (`def/2`), time, actions (`do/2`).
- `enclosure.md` — build the window/door agent step by step and run the
  two-step scenario ("time_day(am), it_is(sunny)" -> shut east window + open
  doors).
- `burocratin.md` — Spanish/German-style "if me_pide then sigo_procedimiento"
  example with `existe/1` preconditions.
- `gerente.md` — the bank queue agent.
- `arch.md` — the abduction example (`do_b/...`).

These double as the manual's tutorial chapters and are shareable via Playground
links (the `Share!` button / `?code=` URLs), which is the standard way the
Playground spreads examples.

---

## 9. Work packages, milestones, effort

| WP | Deliverable | Milestone / exit criteria | Effort (est.) |
| --- | --- | --- | --- |
| 0 | Feasibility spike | **DONE** — port `gloria.pl`+`rplan.pl`+`implica.pl` minimal path, run `prolog_agent/5` under native Ciao; parity harness skeleton | 1 week |
| 1 | Engine port | All six engine files + `gloria_utils.pl`; `gloria.pl` module header trimmed (exports: `prolog_agent/5, gloria_step/7, load_agent/2, induce_spec/4`); `:- module/2` headers added to rplan, implica, equiva, rewrite, auxilia; dynamic declarations preserved; unittest suite green (4/4 agents) | 2-3 weeks |
| 2 | Bundle packaging | `Manifest.pl`, `build.sh`, golden scenarios green on native Ciao; agents under `examples/` (loader reads `.kb`/`.main` sibling files) and under `src/agents/` (copies of `.kb`/`.main` for module layout); `ciao install gloria` placeholder for future pipeline integration | 1 week |
| 3 | wasm + app | `ciao install --grade=wasm gloria` (requires Emscripten/build grade); `gloria.html`/`gloria.js` standalone page scaffolding created in `playground/` (see files); step/reset/trace UI working when wasm build grade is available | 2-3 weeks |
| 4 | Docs + ALDs | LPdoc `gloria` manual (existing doc structure); ALD notebooks created and runnable in the public playground (intro, enclosure, burocratin, gerente, arch) | 1-2 weeks |
| 5 | Upstreaming | Submit bundle + hooks to the Ciao team; get `gloria.html` on ciao-lang.org | ongoing |

Total ~2-3 months of part-time work. Risks and mitigations:

- **Dialect corner cases.** Subtle `format`/cut differences may produce trace
  diffs -> keep the parity harness diffing from day one; changes only
  whitespace/streams, never semantics.
- **The reified-agent refactor.** Touching `Ag:P` across the engine is
  mechanical but wide -> do it as a single scripted refactor on the SWI side
  first and re-run the existing MCP/SWI tests (green = refactor neutral)
  before porting.
- **wasm-only gaps.** Some I/O / filesystem op may behave differently on
  Emscripten -> the browser runtime avoids files entirely (VFS text files only,
  like s(CASP)'s `draft.html`).
- **Licensing.** Gloria is GPL-2; Ciao core and the playground bundle are
  LGPL-3. Bundles ship with their own licenses today (s(CASP) is Apache/BSD),
  but confirm with the Ciao team whether a GPL bundle in the ciao-lang.org
  build is acceptable, or whether Gloria should be offered (by its author) under
  LGPL as well.
- **Engineering ownership.** The engine is single-author legacy code ->
  keep the port's diffs against `*.orig` files readable, document every
  behavioral deviation in `gloria-utils` and the manual.

Suggested communications: the Ciao team's moderated lists `ciao@cliplab.org`,
and a GitHub issue/PR on `ciao-lang/ciao_playground` (or the main `ciao` repo)
describing the bundle + the `list_playgrounds`/`dist_playground` reuse.

---

## 10. Appendix: facts verified while drafting

- Ciao 1.25 (`ciao-lang/ciao`, master): module-qualified predicate access
  cannot define clauses of other modules (module-system manual, `modules.html`).
- `engine(runtime_control)` exports `current_module/1`, `current_prolog_flag/2`,
  `set_prolog_flag/2`.
- `library(format)` exports `format/2,3`, `sformat/3`, `format_to_string/3`;
  reexported via `library(classic/classic_predicates)` (loaded in the s(CASP)
  playground init). `library(read_from_string)` exports `read_from_string/2,3`,
  `read_from_string_opts/4`.
- Playground distribution hooks `list_playgrounds` / `dist_playground` live in
  `ciao_playground/Manifest/ciao_playground.hooks.pl`; `build.sh` shows the
  `ciao install --grade=wasm ...` pipeline; `builder/etc/publish-bundle.sh`
  publishes to ciao-lang.org.
- Standalone app reference: `ciao-lang/sCASP` bundle
  (gitlab.software.imdea.org/ciao-lang/sCASP), `playground/scasp.html` +
  `Manifest/Manifest.pl`; live at https://ciao-lang.org/playground/scasp.html.
- wasm engine + JS client: `ciao-lang/ciaowasm` (browser and `node`).
- Gloria SWI-only call sites: `gloria.pl` (`make_module/2`, `to_module_atom/1`,
  `assert_in_module/2`, `read_file_to_terms/3`, `term_to_atom/2`,
  `current_module/1`, `add_import_module/3`, `print_message/2`,
  `format(user_error,...)`, `writeln/1`, `writef/2`, `sleep/1`, `read/1`),
  `gcompile.pl` (`atomic_list_concat/2`, `writeln/2`, `writef/2`), and the
  `Ag:P(...)` qualified calls throughout the engine.