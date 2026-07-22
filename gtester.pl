/*  gtester.pl
    Part of Gloria http://gloria.sourceforge.net
    
    Simple text-based tester for Gloria/Galatea agents.
*/

:- dynamic current_time/1.
:- ['gloria.pl']. 
:- dynamic ghistory/1.  % the background changes.

% Start the test
% Usage: ?- start_test('AgentName', agent_mod).
% AgentName is the prefix for .main and .kb files.
start_test(AgentName, AgentModule) :-
    atom_concat(AgentName, '.main', MainFile),
    atom_concat(AgentName, '.kb', KBFile),
    
    format('Loading ~w...~n', [AgentName]),
    make_module(AgentModule, MainFile),
    make_module(AgentModule, KBFile),
    
    retractall(current_time(_)),
    assert(current_time(0)),
    
    format('Simulation started for ~w.~n', [AgentModule]),
    format('Enter inputs as a Prolog list, e.g., [time_day(am), it_is(sunny)].~n'),
    format('Enter "end." to stop the simulation.~n'),
    run_loop(AgentModule).

% Main interaction loop
run_loop(Module) :-
    current_time(T),
    format('~n--- Time: ~w ---~n', [T]),
    write('Inputs (e.g., [time_day(am), it_is(sunny)] or "end"): '),
    read_line_to_string(user_input, InputString),
    (InputString == "end" -> 
        write('Simulation finished.'), nl ;
        (
            % Robustly parse the input
            (term_string(Inputs, InputString) ->
                (
                    % Run reasoning
                    prolog_agent(Module, T, 200, Inputs),
                    
                    % Retrieve and print actions
                    findall(act(A, P), Module:actionsmem(Module, T, A, P), Actions),
                    print_actions(Actions),
                    
                    % Advance time
                    NextT is T + 1,
                    retract(current_time(T)),
                    assert(current_time(NextT)),
                    run_loop(Module)
                ) ;
                (write('Invalid input format. Please enter a valid Prolog list.'), nl, run_loop(Module))
            )
        )
    ).

% Helper to display actions
print_actions([]) :- write('  No actions taken.'), nl.
print_actions([act(A, P)|Rest]) :-
    format('  Action: ~w(~w)~n', [A, P]),
    print_actions(Rest).
