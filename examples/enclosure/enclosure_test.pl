:- use_module('../../test/test_matchers', [verify_actions/3]).
:- consult('../../gloria.pl').
:- consult('../../gtester.pl').
% Load the agent definition
:- consult('enclosure0.kb').
:- consult('enclosure0.main').

% Set up required assertions
:- assert(for_testing_only(false)).
:- assert((tracefile(_) :- true)).

:- begin_tests(enclosure_test).

test(sunny_morning_actions) :-
    % Prepare agent input
    Inputs = [time_day(am), it_is(sunny)],
    
    % Execute reasoning
    prolog_agent(enclosure0, 0, 200, Inputs, Actions),
    
    % Verify actions (subset mode: agent must perform at least these)
    verify_actions(subset, [do(shut(east_window), 0), do(open(doors), 0)], Actions).

:- end_tests(enclosure_test).
