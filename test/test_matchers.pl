:- module(test_matchers, [verify_actions/3]).

% verify_actions(Mode, Expected, Actual)
% Mode: exact, subset, set

% 1. exact: Strict list equality (order and set must match exactly)
verify_actions(exact, Expected, Actual) :-
    Expected == Actual.

% 2. subset: Actual must contain all actions in Expected (allows extra actions)
verify_actions(subset, Expected, Actual) :-
    forall(member(Action, Expected), member(Action, Actual)).

% 3. set: The set of actions (ignoring time) must match (order ignored)
verify_actions(set, Expected, Actual) :-
    maplist(strip_time, Expected, Exp),
    maplist(strip_time, Actual, Act),
    msort(Exp, SExp),
    msort(Act, SAct),
    SExp == SAct.

% Helper: removes timestamp from do/2 action terms
strip_time(do(A, _), A).
