:- dynamic current_time/1.
:- ['gloria.pl'].
:- dynamic ghistory/1.
:- dynamic trace_stream/1.

start_test(AgentName, AgentModule) :-
    atom_concat(AgentName, '.main', MainFile),
    atom_concat(AgentName, '.kb', KBFile),
    format('Loading ~w...~n', [AgentName]),
    (current_predicate(tracefile/1) -> true ; assert(tracefile(_) :- true)),
    consult(MainFile), consult(KBFile),
    retractall(current_time(_)), assert(current_time(0)),
    atom_concat(AgentName, '_trace.log', TraceFile),
    setup_call_cleanup(open(TraceFile, write, S),
        (assert(trace_stream(S)), run_loop(AgentModule)),
        (retractall(trace_stream(_)), close(S))).

run_loop(Module) :-
    current_time(T),
    format('~n--- Time: ~w ---~n', [T]),
    write('Inputs: '),
    read_line_to_string(user_input, InputString),
    (InputString == "end" -> write('Finished.'), nl ;
        (term_string(Inputs, InputString) ->
            (prolog_agent(Module, T, 200, Inputs, Actions),
             (trace_stream(S) -> format(S, 'Time: ~w | Input: ~w | Actions: ~w~n', [T, Inputs, Actions]), flush_output(S) ; true),
             print_actions(Actions),
             NextT is T + 1, retract(current_time(T)), assert(current_time(NextT)), run_loop(Module)) ;
            (write('Invalid input.'), nl, run_loop(Module)))).

print_actions([]) :- write('  No actions.'), nl.
print_actions([do(A, T)|Rest]) :- format('  Action: ~w(~w)~n', [A, T]), print_actions(Rest).
