# Cómo agregar otro ejemplo (agente) a Gloria

Esta guía documenta, paso a paso, **todo lo que se hizo para agregar el agente
`emergencia`** al repositorio. Sirve como receta para agregar un agente nuevo
(llamémoslo `<nombre>`) y dejarlo integrado en el motor SWI, el motor Ciao, el
playground, las pruebas de paridad y el servidor MCP.

El agente `emergencia` es un ejemplo mínimo:

- **Observable:** `emergencia`
- **Meta:** si hay una emergencia, conseguir ayuda → `consigue_ayuda`
- **Creencias:**
  - `consigue_ayuda` se logra alertando al conductor → `alerta_conductor`
  - `alerta_conductor` se logra pulsando el botón de alarma → `pulsa_boton`
- **Abducibles:** `emergencia`, `pulsa_boton`
- **Comportamiento:** con `[emergencia]` en el tiempo 0 emite
  `do(pulsa_boton,0)`; sin observación no emite acciones.

---

## Resumen de archivos que se crearon o modificaron

### Nuevos

| Archivo | Para qué |
|---|---|
| `examples/emergencia/emergencia.g` | Especificación Galatea (documentación; no se carga en tiempo de ejecución) |
| `examples/emergencia/emergencia.kb` | Metas (`if_/2`) y creencias (`def/2`) |
| `examples/emergencia/emergencia.main` | Configuración: `abd/1`, `observable/1`, `user_built/1`, `for_testing_only/1`, `tracefile/1` |
| `src/agents/emergencia/emergencia.kb` | Copia para generar el playground Ciao |
| `src/agents/emergencia/emergencia.main` | Copia para generar el playground Ciao |
| `playground/agents/emergencia.pl` | **Generado** por `mkpage.py` (no editar a mano) |
| `playground/alds/emergencia.md` | Cuaderno ALD del ejemplo |
| `.opencode/skills/gloria-emergencia/SKILL.md` | Habilidad para usar el agente vía MCP |

### Modificados

| Archivo | Cambio |
|---|---|
| `playground/mkpage.py` | Entrada en `AGENTS` y en `AGENT_RUNS` |
| `playground/gloria.html` | **Regenerado** por `mkpage.py` (no editar a mano) |
| `ciao/gloria/tests/parity_scenarios_check.sh` | Línea `run_one emergencia ...` |
| `ciao/gloria/tests/t_engine.pl` | Export + `:- test emergencia_scenario` + cláusula |
| `ciao/gloria/tests/t_playground.pl` | Export + `:- test emergencia_pg` + cláusula |
| `ciao/gloria/tests/t_engine.testin`, `t_playground.testin` | Cachés de Ciao, regeneradas solas |
| `.opencode/skills/gloria/SKILL.md` | Se agregó `emergencia` a la lista de agentes |

> Regla general: **nunca** edites a mano
> `playground/gloria.html`, `playground/agents/*.pl` ni los `.testin`. Son
> artefactos generados.

---

## Paso 1 — Crear las fuentes del agente en `examples/<nombre>/`

El motor SWI carga un agente a partir de **dos** archivos:

- `<nombre>.main`: configuración (qué predicados son abducibles/observables,
  si es un agente de usuario, etc.).
- `<nombre>.kb`: base de conocimiento (metas con `if_/2` y creencias con
  `def/2`).

### 1.1 `examples/emergencia/emergencia.main`

```prolog
tracefile('emergencia.dot').  % see flach/graphviz.pl
for_testing_only(false).

% abducible predicates
%
abd(emergencia).
abd(pulsa_boton).

% observable predicates
%
observable(emergencia).

% built-in, user-defined predicates
%
user_built(true).
```

Puntos importantes:

- `user_built/1` es **obligatorio**. El motor SWI llama `Ag:user_built/1` y
  falla con `existence_error(user_built/1)` si falta.
- Los predicados que el agente puede **ejecutar** (las acciones) van en
  `abd/1`. Aquí la acción es `pulsa_boton`.
- `observable/1` declara lo que el agente puede percibir.
- `tracefile/1` es opcional; genera un `.dot` con el rastro de inferencia.

### 1.2 `examples/emergencia/emergencia.kb`

```prolog
% emergencia.kb -- metas (if_/2) y creencias (def/2)
%
% Spec (espanol):
%   Metas:
%     Si ocurre una emergencia, consiga ayuda.
%   Creencias:
%     Ud consigue ayuda si alerta al conductor.
%     Ud alerta al conductor si pulsa el boton de la senal de alarma.

% ---------------------------------------------------------------- metas
% Si ocurre una emergencia, consiga ayuda.
if_(emergencia, [consigue_ayuda]).

% ------------------------------------------------------------ creencias
% Ud consigue ayuda si alerta al conductor.
def(consigue_ayuda, alerta_conductor).
% Ud alerta al conductor si pulsa el boton de la senal de alarma.
def(alerta_conductor, pulsa_boton).
```

- `if_(Observacion, [Metas])` dispara metas cuando se observa algo.
- `def(Meta, Submeta)` encadena una meta con la creencia que la satisface.
  Al final de la cadena debe quedar un abducible (una acción).

### 1.3 `examples/emergencia/emergencia.g` (opcional)

Es la especificación en el lenguaje Galatea original. Se conserva como
documentación y como fuente legible de la intención del agente; **no** la lee
el motor en tiempo de ejecución. Incluye `TITLE`, el bloque `Prolog` con
`tracefile`, `abd`, `observable`, `user_built`, y las secciones `GOALS` y
`BELIEFS`:

```prolog
GOALS {
if emergencia then consigue_ayuda.
}

BELIEFS {
to consigue_ayuda do alerta_conductor.
to alerta_conductor do pulsa_boton.
}
```

### 1.4 Probar el agente directamente con SWI

Antes de tocar el playground o las pruebas, verifica que el agente funciona:

```bash
cd /home/jacinto/git/gloria
swipl -q -g "consult('examples/emergencia/emergencia.main'), \
             make_module(emergencia0, 'examples/emergencia/emergencia.kb'), \
             prolog_agent(emergencia0, 0, 400, [emergencia], A), \
             writeq(A), nl" \
      -t halt gloria.pl
```

Salida esperada:

```prolog
[do(pulsa_boton,0)]
```

> Las opciones de SWI (`-g`, `-t`, …) van **antes** de `gloria.pl`. Si las
> pones después, SWI las trata como argumentos del script y las ignora.

Prueba también el segundo paso sin observación:

```bash
swipl -q -g "consult('examples/emergencia/emergencia.main'), \
             make_module(emergencia0, 'examples/emergencia/emergencia.kb'), \
             prolog_agent(emergencia0, 0, 400, [emergencia], _), \
             prolog_agent(emergencia0, 1, 400, [], A), \
             writeq(A), nl" \
      -t halt gloria.pl
```

→ `[]` (ninguna acción).

---

## Paso 2 — Espejar las fuentes en `src/agents/<nombre>/`

`playground/mkpage.py` lee desde `src/agents/<nombre>/`, no desde
`examples/`. Copia el `.kb` y el `.main` **idénticos**:

```bash
mkdir -p src/agents/emergencia
cp examples/emergencia/emergencia.kb   src/agents/emergencia/emergencia.kb
cp examples/emergencia/emergencia.main src/agents/emergencia/emergencia.main
```

Verifica que no haya diferencias:

```bash
diff examples/emergencia/emergencia.kb   src/agents/emergencia/emergencia.kb
diff examples/emergencia/emergencia.main src/agents/emergencia/emergencia.main
```

Si en el futuro cambias el agente, actualiza **ambas** copias.

---

## Paso 3 — Registrar el agente en `playground/mkpage.py` y regenerar

`mkpage.py` tiene dos tablas que deben incluir el agente. Si falta una, el
agente no aparece (o el generador falla).

### 3.1 `AGENTS`

Lista de tuplas `(id, nombre legible, archivo .kb, archivo .main)`:

```python
AGENTS = [
    ('enclosure',   'Enclosure (windows and doors)', 'enclosure.kb',   'enclosure.main'),
    ('mylamp',      'MyLamp (motion light)',         'mylamp.kb',      'mylamp.main'),
    ('burocratin',  'Burocratin (bureaucrat)',       'burocratin.kb',  'burocratin.main'),
    ('gerente',     'Gerente (queue manager)',       'gerente.kb',     'gerente.main'),
    ('arch',        'Arch (abduction example)',      'ex-arch.kb',     'ex-arch.main'),
    ('rentin',      'Rentin (opportunist)',          'rentin.kb',      'rentin.main'),
    ('emergencia',  'Emergencia (emergency help)',   'emergencia.kb',  'emergencia.main'),
]
```

El `id` es el nombre del módulo/agente y también el nombre del archivo
generado (`playground/agents/<id>.pl`). Los nombres de `.kb`/`.main` pueden
diferir del `id` (como en `arch`, que usa `ex-arch.*`).

### 3.2 `AGENT_RUNS`

Lista de escenarios listos para el menú **Run agent** del playground. Cada
entrada es `(etiqueta, tiempo, observaciones como texto Prolog)`:

```python
AGENT_RUNS = {
    # ...
    'emergencia': [
        ('emergency', 0, '[emergencia]'),
        ('quiet step (no observation)', 0, '[]'),
    ],
}
```

Cada entrada se expande a:

```prolog
prolog_agent(emergencia, 0, 400, [emergencia], Actions).
```

Usa las **mismas observaciones** que los escenarios de paridad y las pruebas
unitarias, para que todo quede coherente.

### 3.3 Regenerar

Desde la raíz del repositorio:

```bash
python3 playground/mkpage.py
```

Esto reescribe:

- `playground/agents/emergencia.pl` (módulo + `.kb` + `.main` en un solo archivo)
- `playground/gloria.html` (menú *Examples* y menú *Run agent*)

Comprueba que el archivo generado tenga el encabezado correcto:

```bash
head -5 playground/agents/emergencia.pl
grep -c "emergencia" playground/gloria.html
```

---

## Paso 4 — Escribir el cuaderno ALD

Crea `playground/alds/emergencia.md` con:

- la observación inicial,
- la acción esperada en el paso 0,
- el razonamiento (observar → desplegar la meta → aplicar creencias →
  abducir la acción),
- cómo reproducirlo en el playground.

Contenido real usado para `emergencia`:

```markdown
# Emergencia agent – emergency-help example

## One-step scenario

**Initial state**: `emergencia`

**Step 0** – the agent observes an emergency, works out that it must get help,
that help is obtained by alerting the driver, and that alerting the driver is
done by pressing the alarm button:

    do(pulsa_boton,0)

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
```

Después de crear el ALD, vuelve a correr `python3 playground/mkpage.py` si el
generador incorpora los ALD en la página (en esta versión la lista de ALD se
documenta en `README.md`; el archivo `.md` se sirve con el sitio).

---

## Paso 5 — Agregar el escenario de paridad (SWI vs Ciao)

Edita `ciao/gloria/tests/parity_scenarios_check.sh` y agrega una línea
`run_one` junto a las demás:

```sh
run_one emergencia examples/emergencia/emergencia.kb \
    '[[emergencia],[]]'
```

- El primer argumento es el nombre del agente.
- El segundo es la ruta **relativa a la raíz del repositorio** del `.kb`.
- El tercero es una lista de pasos; cada paso es la lista de observaciones de
  ese instante. `[[emergencia],[]]` significa: paso 0 con `emergencia`, paso 1
  sin observación.

El script corre el mismo escenario con SWI y con Ciao y compara las acciones
canonicalizadas. Debe imprimir `PARITY: OK` para el agente nuevo.

---

## Paso 6 — Agregar las pruebas unitarias de Ciao

Hay dos suites: una para el motor (`t_engine.pl`) y otra para el pegamento del
playground (`t_playground.pl`). Hay que tocar **tres** cosas en cada una:
exportar el predicado, declarar el `:- test` y escribir la cláusula.

### 6.1 `ciao/gloria/tests/t_engine.pl`

En la lista de exportaciones del `:- module(...)`:

```prolog
:- module(t_engine,
          [enclosure_scenario/0, burocratin_scenario/0,
           gerente_scenario/0, arch_scenario/0,
           emergencia_scenario/0],
          [assertions]).
```

Agrega la declaración y la cláusula:

```prolog
:- test emergencia_scenario
   # "emergencia: [emergencia] -> do(pulsa_boton,0); no observation -> no actions".

emergencia_scenario :-
    run_checks(emergencia0, 'examples/emergencia/emergencia.kb',
               [[emergencia], []],
               [[do(pulsa_boton, 0)], []]).
```

`run_checks(Agente, Kb, Pasos, Esperado)` usa el módulo `<nombre>0`
(`emergencia0`), la ruta del `.kb` en `examples/` y, para cada paso, la lista
de acciones esperadas.

### 6.2 `ciao/gloria/tests/t_playground.pl`

En las exportaciones del módulo:

```prolog
:- module(t_playground,
          [enclosure_pg/0, burocratin_pg/0, gerente_pg/0, arch_pg/0,
           mylamp_pg/0, rentin_pg/0, emergencia_pg/0, query_rewriting/0],
          [assertions]).
```

Declaración y cláusula:

```prolog
:- test emergencia_pg
   # "emergencia: [emergencia] -> do(pulsa_boton,0); no observation -> no actions".

emergencia_pg :-
    pg_checks('playground/agents/emergencia.pl',
              [[emergencia], []],
              [[do(pulsa_boton, 0)], []]).
```

`pg_checks/3` carga el archivo **generado** con `load_agent_code/1`, que es
exactamente el punto de entrada que usa la página del navegador.

### 6.3 Cachés de Ciao (`.testin`, `.itf`, `.po`)

Ciao guarda metadatos de las pruebas en `t_engine.testin` y
`t_playground.testin`, y las interfaces/objetos compilados en `.itf`/`.po`. Al
agregar pruebas o exportaciones, esos archivos pueden quedar desactualizados y
el runner aborta con un error del tipo
`emergencia_pg/0 undefined in source` o `emergencia_scenario/0 undefined in
source`. Solución (desde la raíz del repositorio):

```bash
rm -f ciao/gloria/tests/t_engine.itf ciao/gloria/tests/t_engine.po \
      ciao/gloria/tests/t_playground.itf ciao/gloria/tests/t_playground.po \
      ciao/gloria/tests/run_unittests.itf ciao/gloria/tests/run_unittests.po
rm -f ciao/gloria/tests/t_engine.testin ciao/gloria/tests/t_playground.testin
touch ciao/gloria/tests/t_engine.pl ciao/gloria/tests/t_playground.pl
```

La siguiente ejecución los regenera. Son artefactos: no los edites a mano.
(En este repositorio los `.itf`/`.po`/`.testin`/`.testout` están versionados,
así que la regeneración aparecerá como cambio en `git status`.)

---

## Paso 7 — Documentar el agente para el servidor MCP (opcional pero recomendado)

Crea `.opencode/skills/gloria-emergencia/SKILL.md` con el formato de las demás
habilidades:

```markdown
---
name: gloria-emergencia
description: Use when running or testing the Gloria "emergencia" agent - "run emergencia", "emergency help agent", "consigue_ayuda", "alerta_conductor", "pulsa_boton". Gives the observables, goals, beliefs and a known-good sample.
---

# Gloria agent: emergencia

An emergency-help agent: when it perceives an emergency it gets help by
alerting the driver, which it does by pressing the alarm-signal button.

- Source: `examples/emergencia/emergencia.main`, `examples/emergencia/emergencia.kb`
- Observables: `emergencia`
- Goals (`if_/2`):
  - `emergencia -> [consigue_ayuda]`
- Beliefs (`def/2`):
  - `def(consigue_ayuda, alerta_conductor)`
  - `def(alerta_conductor, pulsa_boton)`
- Abducibles: `emergencia`, `pulsa_boton`

## Sample run

`gloria_run_step` with `agent="emergencia"`, `session="s"`:

| time | input | actions |
| --- | --- | --- |
| 0 | `[emergencia]` | `do(pulsa_boton,0)` |
| 1 | `[]` | (no actions) |
```

Además, agrega el nombre del agente a la lista de `.opencode/skills/gloria/SKILL.md`
(en la descripción y en la sección que enumera las habilidades por agente),
para que el agente sea descubrible vía MCP.

---

## Paso 8 — Verificar todo

### 8.1 SWI directo

```bash
swipl -q -g "consult('examples/emergencia/emergencia.main'), \
             make_module(emergencia0, 'examples/emergencia/emergencia.kb'), \
             prolog_agent(emergencia0, 0, 400, [emergencia], A), \
             writeq(A), nl" \
      -t halt gloria.pl
```

→ `[do(pulsa_boton,0)]`

### 8.2 Worker del MCP (sin cliente MCP)

```bash
printf '%s\n' \
  '{"cmd":"agent_info","agent":"emergencia"}' \
  '{"cmd":"run_step","agent":"emergencia","input":"[emergencia]","session":"s"}' \
  '{"cmd":"run_step","agent":"emergencia","input":"[]","session":"s"}' \
| swipl -q -s web/mcp/runner.pl -g main -t halt
```

→ información del agente, luego
`{"actions":["do(pulsa_boton,0)"],...}` y luego `{"actions":[],...}`.

### 8.3 Servidor web SWI

```bash
swipl -q -s web/server/server.pl -g "start_server, thread_get_message(_)"
```

En otra terminal:

```bash
curl -s http://localhost:8080/api/examples
curl -s -X POST http://localhost:8080/api/session/start \
     -H 'Content-Type: application/json' -d '{"agent":"emergencia"}'
curl -s -X POST http://localhost:8080/api/session/step \
     -H 'Content-Type: application/json' -d '{"input":"[emergencia]"}'
```

→ `{"actions":["do(pulsa_boton,0)"],"next_time":1}`.

### 8.4 Paridad SWI vs Ciao

```bash
export PATH="$HOME/.ciaoroot/v1.25.0-m1/build/bin:$PATH"
./ciao/gloria/tests/parity_scenarios_check.sh
```

→ los **7** agentes, incluido `emergencia`, deben reportar `PARITY: OK`.

### 8.5 Suite unitaria de Ciao

```bash
ciao run ciao/gloria/tests/run_unittests.pl
```

→ `Passed: 13 (100.00%) Failed: 0` y `UNITEST status=0`.

### 8.6 Playground Ciao (wasm)

```bash
python3 playground/mkpage.py
./serve_gloria.sh
```

Abre <http://localhost:8000/playground/gloria.html>, elige
`Examples → Emergencia`, pulsa `Load ▶`, y ejecuta:

```prolog
prolog_agent(emergencia, 0, 400, [emergencia], Actions).
```

→ `Actions = [do(pulsa_boton,0)]`.

---

## Lista de verificación rápida

- [ ] `examples/<nombre>/<nombre>.main` con `abd/1`, `observable/1`,
      `user_built/1`.
- [ ] `examples/<nombre>/<nombre>.kb` con `if_/2` y `def/2`.
- [ ] Copias idénticas en `src/agents/<nombre>/`.
- [ ] Entrada en `AGENTS` **y** en `AGENT_RUNS` de `playground/mkpage.py`.
- [ ] `python3 playground/mkpage.py` ejecutado sin errores.
- [ ] `playground/alds/<nombre>.md` escrito.
- [ ] `run_one <nombre> ...` en `parity_scenarios_check.sh`.
- [ ] Export + `:- test` + cláusula en `t_engine.pl` y `t_playground.pl`.
- [ ] `.itf`/`.po`/`.testin` regenerados (o borrados antes de correr).
- [ ] Habilidad MCP creada y agente listado en `gloria/SKILL.md`.
- [ ] SWI directo, runner MCP, API web, paridad y unittest en verde.
