/*  t_engine.pl -- Ciao unittest suite for the ported Gloria engine.

    Each test runs a golden scenario of an example agent through the
    ported engine (gloria:load_agent + gloria:gloria_step) and compares
    the produced do/2 actions with the SWI golden captured by the
    parity harness (ciao/gloria/tests/parity_scenarios_check.sh).

    Run from the repo root:
      ciao run ciao/gloria/tests/run_unittests.pl
    or call the two failing cases below / use `ciao test` once the
    bundle manifest exists (WP2).
*/

:- module(t_engine,
          [enclosure_scenario/0, burocratin_scenario/0,
           gerente_scenario/0, arch_scenario/0,
           emergencia_scenario/0, piojo_scenario/0,
           marciano_scenario/0, baseball_manager_scenario/0],
          [assertions]).

:- doc(title, "Gloria engine port tests (enclosure, burocratin, gerente, arch, emergencia, piojo, marciano, baseball_manager)").

:- use_module(library(format)).
:- use_module('../src/gloria').

:- test enclosure_scenario
   # "enclosure: [time_day(am),it_is(sunny)] -> shut(east_window)+open(doors); then pm/rainy -> 3 actions".

enclosure_scenario :-
    run_checks(enclosure0, 'examples/enclosure/enclosure.kb',
               [[time_day(am), it_is(sunny)], [time_day(pm), it_is(rainy)]],
               [[do(shut(east_window), 0), do(open(doors), 0)],
                [do(shut(east_window), 1), do(shut(west_window), 1), do(shut(doors), 1)]]).

:- test burocratin_scenario
   # "burocratin: me_pide(juan,sacar_constancia) -> do(lee(sacar_constancia),0)".

burocratin_scenario :-
    run_checks(burocratin0, 'examples/burocratin/burocratin.kb',
               [[me_pide(juan, sacar_constancia)]],
               [[do(lee(sacar_constancia), 0)]]).

:- test gerente_scenario
   # "gerente: timing+cola_larga -> revisa_cola+crear_taquilla; timing+taq_vacias -> revisa_cola+eliminar_taquilla".

gerente_scenario :-
    run_checks(gerente0, 'examples/gerente/gerente.kb',
               [[timing(1), cola_larga], [timing(2), taq_vacias]],
               [[do(revisa_cola(1), 0), do(crear_taquilla, 0)],
                [do(revisa_cola(2), 1), do(eliminar_taquilla, 1)]]).

:- test arch_scenario
   # "arch: build(5)+c(5)+c(8)+b(10) -> do(do(8),0) x2 + do(do_b(10),0)".

arch_scenario :-
    run_checks(arch0, 'examples/arch/ex-arch.kb',
               [[build(5), c(5), c(8), b(10)]],
               [[do(do(8), 0), do(do(8), 0), do(do_b(10), 0)]]).

:- test emergencia_scenario
   # "emergencia: [emergencia] -> do(pulsa_boton,0); no observation -> no actions".

emergencia_scenario :-
    run_checks(emergencia0, 'examples/emergencia/emergencia.kb',
               [[emergencia], []],
               [[do(pulsa_boton, 0)], []]).

:- test piojo_scenario
   # "piojo: free+rested -> avanzar; obstacle+rested -> voltear_derecha; free+tired -> detenerse only".

piojo_scenario :-
    run_checks(piojo0, 'examples/piojo/piojo.kb',
               [[frente_libre, descansado],
                [frente_libre, descansado],
                [obstaculo_al_frente, descansado],
                [frente_libre, cansado]],
               [[do(avanzar, 0)],
                [do(avanzar, 1)],
                [do(voltear_derecha, 2)],
                [do(detenerse, 3)]]).

:- test marciano_scenario
   # "marciano: coordinate map; free+unvisited -> avanzar; free+visited -> turn; obstacle -> turn; life -> report+turn".

marciano_scenario :-
    run_checks(marciano0, 'examples/marciano/marciano.kb',
               [[posicion(0,0), orientacion(este), frente_libre],
                [posicion(1,0), orientacion(este), frente_libre],
                [posicion(2,0), orientacion(este), obstaculo_al_frente],
                [posicion(2,0), orientacion(sur), obstaculo_al_frente],
                [posicion(2,0), orientacion(oeste), frente_libre],
                [posicion(2,0), orientacion(norte), vida]],
               [[do(avanzar, 0)],
                [do(avanzar, 1)],
                [do(voltear_derecha, 2)],
                [do(voltear_derecha, 3)],
                [do(voltear_derecha, 4)],
                [do(reportar((2,1)), 5), do(voltear_derecha, 5)]]).

:- test baseball_manager_scenario
   # "baseball_manager: keep, warm bullpen, standard/tactical substitution, closer, save mode".

baseball_manager_scenario :-
    run_checks(baseball_manager0, 'examples/baseball_manager/baseball_manager.kb',
               [[comienza_turno_al_bate, lanzador_actual(starter), en_dominio(starter),
                 no_cansado(starter), retiros_recientes_sin_dano(starter), pitcheos_optimos(starter)],
                [lanzador_actual(starter), fatiga_temprana(starter)],
                [lanzador_actual(starter), supera_limite_pitcheos(starter),
                 ordeno_calentar(rel1), calentamiento_completo(rel1), descanso_suficiente(rel1),
                 es_abridor(starter)],
                [situacion_de_apremio, entrada_tardia, carrera_empate_o_ventaja_en_riesgo,
                 lanzador_actual(starter), bateador_actual(b1), ordeno_calentar(rel_left),
                 calentamiento_completo(rel_left), descanso_suficiente(rel_left),
                 matchup_brazo_perfil(rel_left, b1), es_abridor(starter)],
                [equipo_pierde_por_mucho]],
               [[do(mantener_lanzador(starter), 0)],
                [do(calentar_bullpen, 1)],
                [do(sustituir_lanzador(starter, rel1), 2)],
                [do(sustituir_lanzador_tactico(starter, rel_left), 3)],
                [do(ingresar_relevista_largo, 4), do(bloquear_relevistas_alta_jerarquia, 4)]]).

run_checks(Ag, Kb, Steps, Expected) :-
    gloria:load_agent(Ag, Kb),
    run_steps(Ag, Kb, 0, Steps, Got),
    (   Got = Expected
    ->  true
    ;   format('FAIL ~w:~nt  got      ~w~nt  expected ~w~n',
               [Ag, Got, Expected]),
        fail
    ),
    !.

run_steps(_, _, _, [], []).
run_steps(Ag, Kb, T, [In|Rest], [Acts|More]) :-
    gloria:gloria_step(Ag, T, 400, In, _NextGs, _OutGs, Acts),
    T1 is T + 1,
    run_steps(Ag, Kb, T1, Rest, More).