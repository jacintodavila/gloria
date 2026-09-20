%% driver_scenario_c.pl -- Ciao scenario runner for the parity harness.
%% Plain file with main/1 as required by `ciao run`.  Usage (repo root):
%%   ciao run ciao/gloria/tests/driver_scenario_c.pl <Agent> <KbPath> <StepsFile>
%% Prints one canonicalized action-shape per time step (see term_shape.pl).
:- use_module('../src/gloria').
:- include('term_shape.pl').

main([Agent, KbPath, StepsFile|_]) :-
    catch((
            gloria:load_agent(Agent, KbPath),
            read_steps(StepsFile, Steps),
            run_steps(Agent, 0, Steps)
        ), Exc, (writeq(error(Exc)), nl)),
    halt.
main(_) :- halt(1).

read_steps(File, Steps) :-
    open(File, read, S),
    read(S, Steps),
    close(S).

run_steps(_, _, []).
run_steps(Ag, T, [In|Rest]) :-
    gloria:gloria_step(Ag, T, 400, In, _NextGs, _OutGs, Actions),
    write('R '), writeq(Actions), nl,
    term_shape(Actions, Shape),
    write('S '), writeq(Shape), nl,
    T1 is T + 1,
    run_steps(Ag, T1, Rest).