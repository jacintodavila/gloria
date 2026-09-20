%% driver_parity_s.pl -- SWI side of the cross-engine parity harness.
%% Prints SHAPE lines for Actions, NextGs and OutGs of the enclosure
%% example.  Run from the repo root:
%%   swipl -q -g run_parity ciao/gloria/tests/driver_parity_s.pl
:- consult('gloria.pl').
:- consult('examples/enclosure/enclosure.main').
:- ensure_loaded(term_shape).

run_parity :-
    make_module(enclosure0, 'examples/enclosure/enclosure.kb'),
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