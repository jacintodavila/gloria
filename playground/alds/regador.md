# Regador: riego automático de un huerto

## Observables y acciones

- **Observables**: `humedad_baja`, `llueve`, `tanque_vacio`, `humedad_subio`.
- **Acciones**: `abre_valvula`, `cierra_valvula`, `registra_riego`, `avisa_dueno`.

## Reglas

1. Humedad baja y sin lluvia → abrir la válvula y registrar el riego.
2. Lluvia → cerrar la válvula.
3. Tanque vacío → avisar al dueño y no regar (tiene prioridad explícita sobre la regla 1).
4. En el paso siguiente al riego, verificar: si no llegó `humedad_subio`, avisar al dueño.

`prolog_agent/5` no pasa el tiempo `T` a la base de conocimientos, así que el
"paso siguiente" se implementa con memoria de trabajo: cada ciclo avanza un
reloj `tick(N)`; al regar se crea el token `riego(N)` con `N` = paso actual, y
la verificación exige `paso_post(N, _)` (un tick posterior). Al verificar se
memoriza `verificado(N)`: el token queda consumido y el aviso no se repite en
pasos posteriores.

## Escenarios (salidas reales del motor SWI)

| Caso | Entrada | Acciones |
| --- | --- | --- |
| (a) | T=0 `[humedad_baja]` | `do(abre_valvula,0), do(registra_riego,0)` |
| (b) | T=0 `[humedad_baja, llueve]` | `do(cierra_valvula,0)` |
| (c) | T=0 `[humedad_baja, tanque_vacio]` | `do(avisa_dueno,0)` |
| (d) | T=0 `[humedad_baja]`, T=1 `[]` | T=0 `do(abre_valvula,0), do(registra_riego,0)`; T=1 `do(avisa_dueno,1)` |
| (e) | T=0 `[humedad_baja]`, T=1 `[humedad_subio]` | T=0 `do(abre_valvula,0), do(registra_riego,0)`; T=1 sin acciones |
| (f) | T=0 `[]` | sin acciones |
| (g) | T=0 `[humedad_baja]`, T=1 `[]`, T=2 `[]` | T=1 `do(avisa_dueno,1)`; T=2 sin acciones (el aviso **no** se repite) |
| (h) | T=0 `[humedad_baja]`, T=1 `[humedad_baja]` | T=1 `do(avisa_dueno,1)` únicamente |

### Sobre el caso (h)

Con humedad todavía baja en T=1, el agente **avisa al dueño** (regla 4) pero
**no vuelve a regar en ese mismo paso**: la regla 1 exige `sin_pendiente`, y el
riego de T=0 todavía está pendiente de verificación. Es coherente con la
descripción: el aviso reporta que el riego no surtió efecto, y reiniciar otro
riego antes de cerrar la verificación sería redundante. En un paso posterior
(con el token consumido), una nueva observación de `humedad_baja` inicia un
ciclo de riego nuevo.

Si llueve *y* el tanque está vacío a la vez (caso extra, no pedido), se emiten
`do(cierra_valvula,0)` y `do(avisa_dueno,0)`: ambas reglas de seguridad son
compatibles.

## Cómo reproducirlo en el playground

1. *Examples → Regador (automatic garden watering)*, luego **Load ▶**.
2. Insertar y ejecutar, por ejemplo:

```prolog
?- prolog_agent(regador, 0, 400, [humedad_baja], Actions).
```

3. Para el escenario (d), ejecutar a continuación la consulta del menú *Run
   agent* `step 1 (sin humedad_subio -> aviso)`, que inserta:

```prolog
?- prolog_agent(regador, 1, 400, [], Actions).
```

El reloj y el token pendiente viven en la memoria del agente cargado; para
empezar de cero, vuelve a pulsar **Load ▶**.
