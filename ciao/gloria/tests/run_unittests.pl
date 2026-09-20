/*  run_unittests.pl -- driver for the Ciao unittest suite (t_engine.pl).
    Plain file with main/1 for `ciao run`.  Run from the repo root:
      ciao run ciao/gloria/tests/run_unittests.pl
    Loads the test module and runs the checks, reporting each one.
*/
:- use_module(library(unittest), [run_tests/3]).
:- use_module('t_engine').

main(_) :-
    run_tests('ciao/gloria/tests/t_engine', [], [check, show_results, status(Status)]),
    format('UNITEST status=~w~n', [Status]),
    (   Status == 0
    ->  halt(0)
    ;   halt(1)
    ).
main(_) :- halt(1).