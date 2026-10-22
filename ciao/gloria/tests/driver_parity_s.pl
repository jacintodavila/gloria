%% driver_parity_s.pl -- SWI side of the cross-engine parity harness.
%% Prints SHAPE lines for Actions, NextGs and OutGs of the enclosure
%% example.  Usage:
%%   swipl -q -g run_parity ciao/gloria/tests/driver_parity_s.pl
%%
%% The engine and the example agent are located through gloria_root.pl,
%% so the driver works from any working directory.
:- consult('../../../gloria_root').
:- ( set_gloria_root -> true ; gloria_root_error ).
:- ( gloria_root_path('gloria.pl', EngineFile)
    ->  consult(EngineFile)
    ;   gloria_root_error ).
:- ( gloria_root_path('examples/enclosure/enclosure.main', EnclosureMain)
    ->  consult(EnclosureMain)
    ;   gloria_root_error ).
:- ensure_loaded(term_shape).

run_parity :-
    gloria_root_path('examples/enclosure/enclosure.kb', EnclosureKb),
    make_module(enclosure0, EnclosureKb),
    (   catch(gloria_step(enclosure0, 0, 400,
                          [time_day(am), it_is(sunny)],
                          NextGs, OutGs, Actions),
              Exc, (writeq(error(Exc)), nl, fail))
    ->  term_shape(Actions, AS),
        term_shape(NextGs, NS),
        term_shape(OutGs, OS),
        write_lines([AS, NS, OS])
    ;   true
    ),
    halt.
run_parity :- halt(1).

write_lines([]).
write_lines([H|T]) :-
    writeq(H),
    nl,
    write_lines(T).