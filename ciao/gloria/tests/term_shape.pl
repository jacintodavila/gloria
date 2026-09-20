/*  term_shape.pl -- canonical term serializer for cross-engine parity.

    Included by both the SWI and Ciao parity drivers.  term_shape/2 maps a
    term to a structurally identical copy in which every variable is
    replaced by ts_var(N), numbered by first occurrence in a left-to-right
    traversal.  Two answers that differ only in variable identity (e.g.
    _10605 vs _G) then serialize identically and can be diffed across
    engines.
*/

:- dynamic ts_n/1.

term_shape(T, S) :-
    retractall(ts_n(_)),
    assert(ts_n(0)),
    shape(T, S),
    retractall(ts_n(_)).

shape(V, ts_var(N)) :-
    var(V), !,
    ts_n(N),
    N2 is N + 1,
    retractall(ts_n(_)),
    assert(ts_n(N2)).
shape([], []) :- !.
shape([H|T], [SH|ST]) :- !,
    shape(H, SH),
    shape(T, ST).
shape(T, S) :-
    compound(T), !,
    functor(T, F, A),
    functor(S, F, A),
    shape_args(T, A, S).
shape(T, T).

shape_args(_, 0, _) :- !.
shape_args(T, A, S) :-
    arg(A, T, Arg),
    arg(A, S, SArg),
    shape(Arg, SArg),
    A1 is A - 1,
    shape_args(T, A1, S).