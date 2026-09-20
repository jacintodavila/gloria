%% driver_parity_c.pl -- Ciao side of the cross-engine parity harness.
%% Prints the same SHAPE lines as driver_parity_s.pl.  Plain (module-less)
%% file with main/1 as required by `ciao run`.  Run from the repo root:
%%   ciao run ciao/gloria/tests/driver_parity_c.pl
:- use_module('../src/gloria').
:- include('term_shape.pl').

main(_) :-
    gloria:load_agent(enclosure0, 'examples/enclosure/enclosure.kb'),
    catch(gloria:gloria_step(enclosure0, 0, 400,
                             [time_day(am), it_is(sunny)],
                             NextGs, OutGs, Actions),
          Exc, (writeq(error(Exc)), nl, fail)),
    term_shape(Actions, AS),
    term_shape(NextGs, NS),
    term_shape(OutGs, OS),
    write_lines([AS, NS, OS]).

write_lines([]).
write_lines([H|T]) :-
    writeq(H),
    nl,
    write_lines(T).