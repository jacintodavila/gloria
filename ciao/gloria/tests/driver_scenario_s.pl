%% driver_scenario_s.pl -- SWI scenario runner for the parity harness.
%% Usage (run from the repo root):
%%   swipl -q -g run_scenario ciao/gloria/tests/driver_scenario_s.pl -- <Agent> <KbPath> <StepsFile>
%% Prints one canonicalized action-shape per time step (see term_shape.pl).
:- consult('gloria.pl').
:- ensure_loaded(term_shape).

run_scenario :-
    current_prolog_flag(argv, [AgentStr, KbPath, StepsFile|_]),
    atom_string(Agent, AgentStr),
    atom_string(KbPathA, KbPath),
    atom_string(StepsFileA, StepsFile),
    main_file(KbPathA, MainFile),
    (   catch((
            consult(user:MainFile),
            make_module(Agent, KbPathA),
            read_steps(StepsFileA, Steps),
            run_steps(Agent, 0, Steps)
        ), Exc, (writeq(error(Exc)), nl)),
    halt).
run_scenario :- halt(1).

main_file(KbPath, MainFile) :-
    atom_concat(Base, '.kb', KbPath),
    atom_concat(Base, '.main', MainFile).

read_steps(File, Steps) :-
    open(File, read, S),
    read(S, Steps),
    close(S).

run_steps(_, _, []).
run_steps(Ag, T, [In|Rest]) :-
    gloria_step(Ag, T, 400, In, _NextGs, _OutGs, Actions),
    write('R '), writeq(Actions), nl,
    term_shape(Actions, Shape),
    write('S '), writeq(Shape), nl,
    T1 is T + 1,
    run_steps(Ag, T1, Rest).