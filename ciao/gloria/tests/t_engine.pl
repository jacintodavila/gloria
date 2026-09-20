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
           gerente_scenario/0, arch_scenario/0],
          [assertions]).

:- doc(title, "Gloria engine port tests (enclosure, burocratin, gerente, arch)").

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

run_checks(Ag, Kb, Steps, Expected) :-
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
    gloria:load_agent(Ag, Kb),
    gloria:gloria_step(Ag, T, 400, In, _NextGs, _OutGs, Acts),
    T1 is T + 1,
    run_steps(Ag, Kb, T1, Rest, More).