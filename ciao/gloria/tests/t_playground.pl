/*  t_playground.pl -- tests for the browser-playground glue.

    The Gloria playground page (playground/gloria.html) uploads the editor
    contents as a single file in the engine's virtual filesystem and runs

        gloria:load_agent_code('/<agent>.pl')

    to build the agent from it.  load_agent_code/1 takes the agent id from
    the file's basename and reads both the knowledge base (if_/2, def/2)
    and the configuration (abd/1, observable/1, ...) out of that one file.

    These tests exercise the very same entry point natively, on the
    self-contained agent sources generated in playground/agents/ by
    playground/mkpage.py.  The golden actions are the SWI ones captured by
    the parity harness (see t_engine.pl).

    Run from the repo root:
      ciao run ciao/gloria/tests/run_unittests.pl
*/

:- module(t_playground,
          [enclosure_pg/0, burocratin_pg/0, gerente_pg/0, arch_pg/0,
           mylamp_pg/0, rentin_pg/0, emergencia_pg/0, query_rewriting/0],
          [assertions]).

:- doc(title, "Gloria playground glue tests (load_agent_code/1)").

:- use_module(library(format)).
:- use_module(library(pathnames), [path_basename/2, path_splitext/3]).
:- use_module(library(terms_check), [variant/2]).
:- use_module('../src/gloria').
:- use_module('../src/gloria_playground').

:- test enclosure_pg
   # "enclosure: same golden actions as t_engine, loaded from the .pl form".

enclosure_pg :-
    pg_checks('playground/agents/enclosure.pl',
              [[time_day(am), it_is(sunny)], [time_day(pm), it_is(rainy)]],
              [[do(shut(east_window), 0), do(open(doors), 0)],
               [do(shut(east_window), 1), do(shut(west_window), 1), do(shut(doors), 1)]]).

:- test burocratin_pg
   # "burocratin: me_pide(juan,sacar_constancia) -> do(lee(sacar_constancia),0)".

burocratin_pg :-
    pg_checks('playground/agents/burocratin.pl',
              [[me_pide(juan, sacar_constancia)]],
              [[do(lee(sacar_constancia), 0)]]).

:- test gerente_pg
   # "gerente: timing+cola_larga -> revisa_cola+crear_taquilla; then taq_vacias".

gerente_pg :-
    pg_checks('playground/agents/gerente.pl',
              [[timing(1), cola_larga], [timing(2), taq_vacias]],
              [[do(revisa_cola(1), 0), do(crear_taquilla, 0)],
               [do(revisa_cola(2), 1), do(eliminar_taquilla, 1)]]).

:- test arch_pg
   # "arch: build(5)+c(5)+c(8)+b(10) -> do(do(8),0) x2 + do(do_b(10),0)".

arch_pg :-
    pg_checks('playground/agents/arch.pl',
              [[build(5), c(5), c(8), b(10)]],
              [[do(do(8), 0), do(do(8), 0), do(do_b(10), 0)]]).

:- test mylamp_pg
   # "mylamp: motion(1) -> switch_on(lamp1)+log(1)".

mylamp_pg :-
    pg_checks('playground/agents/mylamp.pl',
              [[motion(1)]],
              [[do(switch_on(lamp1), 0), do(log(1), 0)]]).

:- test rentin_pg
   # "rentin: [flojera,gano,no_hay_jueces_confiables,sin_observador] -> no_trabajo+abuso; with an observer only no_trabajo".

rentin_pg :-
    pg_checks('playground/agents/rentin.pl',
              [[flojera, gano, no_hay_jueces_confiables, sin_observador],
               [flojera, gano, no_hay_jueces_confiables, observador_independiente]],
              [[do(no_trabajo, 0), do(abuso, 0)],
               [do(no_trabajo, 1)]]).

:- test emergencia_pg
   # "emergencia: [emergencia] -> do(pulsa_boton,0); no observation -> no actions".

emergencia_pg :-
    pg_checks('playground/agents/emergencia.pl',
              [[emergencia], []],
              [[do(pulsa_boton, 0)], []]).

:- test query_rewriting
   # "the page's disguise_trans_query/3 rewrites Gloria goals into the gloria module".

query_rewriting :-
    rw(prolog_agent(enclosure, 0, 400, [], _),
       gloria:prolog_agent(enclosure, 0, 400, [], _)),
    rw(gloria_step(enclosure, 0, 400, [], _, _, _),
       gloria:gloria_step(enclosure, 0, 400, [], _, _, _)),
    rw(load_agent_code('/enclosure.pl'),
       gloria:load_agent_code('/enclosure.pl')),
    % non-Gloria queries are left untouched (and reported as 'none')
    disguise_trans_query(foo(bar), R, foo(bar)),
    R == none.

rw(Q0, Expected) :-
    disguise_trans_query(Q0, R, Q),
    (   R == ok, variant(Q, Expected)
    ->  true
    ;   format('FAIL rewriting:~nt  got      ~w / ~w~nt  expected ok / ~w~n',
               [R, Q, Expected]),
        fail
    ).
%% The agent id is the basename of the uploaded file (load_agent_code/1)
pg_agent(Path, Ag) :-
    path_basename(Path, Base),
    path_splitext(Base, Ag, _Ext).

pg_checks(Path, Steps, Expected) :-
    pg_agent(Path, Ag),
    pg_run_steps(Ag, Path, 0, Steps, Got),
    (   Got = Expected
    ->  true
    ;   format('FAIL ~w:~nt  got      ~w~nt  expected ~w~n',
               [Ag, Got, Expected]),
        fail
    ),
    !.

pg_run_steps(_, _, _, [], []).
pg_run_steps(Ag, Path, T, [In|Rest], [Acts|More]) :-
    gloria:load_agent_code(Path),
    gloria:gloria_step(Ag, T, 400, In, _NextGs, _OutGs, Acts),
    T1 is T + 1,
    pg_run_steps(Ag, Path, T1, Rest, More).
