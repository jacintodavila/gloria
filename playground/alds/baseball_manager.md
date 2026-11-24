# Baseball manager agent – pitching management example

## Purpose

The `baseball_manager` agent models a baseball manager focused exclusively on pitching decisions. It observes game state and emits pitching actions such as keeping the current pitcher, warming the bullpen, making substitutions, bringing in the closer, or entering blowout save mode.

## Knowledge base

- Source: `examples/baseball_manager/baseball_manager.main`, `examples/baseball_manager/baseball_manager.kb`
- Observables: game state facts such as `comienza_turno_al_bate`, `lanzador_actual/1`, `fatiga_temprana/1`, `entrada_tardia`, `equipo_pierde_por_mucho`, etc.
- Abducibles/actions: `mantener_lanzador/1`, `calentar_bullpen`, `sustituir_lanzador/2`, `sustituir_lanzador_tactico/2`, `ingresar_relevista_largo`, `bloquear_relevistas_alta_jerarquia`.

## Goals (`if_/2`)

- **Inertia / keep pitcher:** if an at-bat begins, the current pitcher is dominant, and not tired, keep the pitcher.
- **Prevention / warm bullpen:** if the current pitcher shows early fatigue or runners are on base with no outs, warm a reliever.
- **Standard substitution:** if the current pitcher is tired, a reliever is ready, and the regulatory restriction is satisfied, substitute the pitcher.
- **Tactical substitution:** if the game is in a high-leverage situation, a ready reliever has a matchup advantage, and the regulatory restriction is satisfied, substitute immediately.
- **Blowout save mode:** if the team is losing by 6 or more runs, use a long/low-profile reliever and block high-leverage relievers.

## Beliefs (`def/2`)

- `esta_cansado(L)`: pitch limit exceeded, 2 consecutive walks, or third time through the lineup.
- `en_dominio(L)`: recent outs without damage/congestion and optimal pitch count.
- `situacion_de_apremio`: late inning (>=7) and tying/go-ahead run is on base or at the plate.
- `ventaja_de_enfrentamiento(R,B)`: handedness/profile matchup or ground-ball inducer in double-play situation.
- `relevista_listo(R)`: previously ordered to warm up, completed preparation, and has not pitched the last 2 consecutive days.
- `restriccion_reglamentaria(L)`: starter, reliever who faced at least 3 batters, finished previous inning, or injury. Substituted pitchers cannot return (modeled by not reasserting them as current pitcher in subsequent steps).

## Sample scenarios

### Keep starter

Input:

```prolog
[comienza_turno_al_bate, lanzador_actual(starter), en_dominio(starter), no_cansado(starter),
 retiros_recientes_sin_dano(starter), pitcheos_optimos(starter)]
```

Expected action:

```prolog
[do(mantener_lanzador(starter),0)]
```

### Warm bullpen

```prolog
[lanzador_actual(starter), fatiga_temprana(starter)]
```

→ `[do(calentar_bullpen,0)]`

### Standard substitution

```prolog
[lanzador_actual(starter), supera_limite_pitcheos(starter), ordeno_calentar(rel1),
 calentamiento_completo(rel1), descanso_suficiente(rel1), es_abridor(starter)]
```

→ `[do(sustituir_lanzador(starter,rel1),0)]`

### Tactical substitution

```prolog
[situacion_de_apremio, entrada_tardia, carrera_empate_o_ventaja_en_riesgo,
 lanzador_actual(starter), bateador_actual(b1), ordeno_calentar(rel_left),
 calentamiento_completo(rel_left), descanso_suficiente(rel_left),
 matchup_brazo_perfil(rel_left,b1), es_abridor(starter)]
```

→ `[do(sustituir_lanzador_tactico(starter,rel_left),0)]`

### Blowout save mode

```prolog
[equipo_pierde_por_mucho]
```

→ `[do(ingresar_relevista_largo,0), do(bloquear_relevistas_alta_jerarquia,0)]`