/*  gloria_compat.pl
    Ciao compat layer for the Gloria engine port.

    Provides shims for SWI-Prolog builtins / modules that the original
    engine relies on and that Ciao 1.25 does not provide natively.

    SWI-only items covered here:
      - not/1            -> \+/1
      - is_list/1
      - writeln/1,2
      - writef/2         -> Ciao format/2 with %w/%q -> ~w/~q mapping
      - =@= (variant)    -> library(terms_check) variant/2
      - atom_chars/2 (if missing)   [used by the writef shim]
      - predicate_property fallback -> ciao_builtin/1 whitelist
      - safe_clause/2    -> clause/2 that fails (like SWI) on undefined preds
      - sleep/1, time/1, statistics/0, garbage_collect/0,
        clean_all/0, clean_do/0, protocola/1, noprotocol/0  -> legacy stubs
      - data wr_eq/0, wr_ir/0, wr_fr/0, wr_last/0, at/1, on/1,
        now/1, lastaction/1, nonstop/0   -> asserted/queried at runtime

    MIS induction (flach/mis.pl) is stubbed for now: the no-example /
    no-rule case returns [] immediately; anything else throws a
    not-yet-ported error. Porting full MIS is out of WP0 scope.
*/

/********************************************************* basic shims */

not(G) :- \+ G.

is_list([]).
is_list([_|T]) :- is_list(T).

writeln(X) :- write(X), nl.
writeln(S, X) :- write(S, X), nl(S).

/************************************************************ writef/2 */

writef(Format, Args) :-
    (   atom(Format)
    ->  name(Format, Codes),
        convf(Codes, Out),
        name(CiaoFmt, Out)
    ;   convf(Format, Out),          % Ciao "..." strings are code lists
        CiaoFmt = Out
    ),
    format(CiaoFmt, Args).

convf([], []).
convf([0'%, w | R], [~, w | O]) :- !, convf(R, O).
convf([0'%, q | R], [~, q | O]) :- !, convf(R, O).
convf([0'%, s | R], [~, s | O]) :- !, convf(R, O).
convf([0'%, d | R], [~, d | O]) :- !, convf(R, O).
convf([0'%, 0'% | R], [0'% | O]) :- !, convf(R, O).
convf([C|R], [C|O]) :- convf(R, O).

/******************************************************* variant =@= */

:- op(700, xfx, =@=).

X =@= Y :- variant(X, Y).

/*************************************************** safe clause/2 */
% SWI's clause/2 fails silently for predicates that are neither
% defined nor declared (e.g. abducibles like shut/1). Ciao raises an
% existence error. Keep SWI semantics for the reasoning engine.

safe_clause(A, _) :-
    functor(A, F, N),
    current_predicate(F/N),
    !, clause(A, _).
safe_clause(_, _) :- fail.

/*************************************************** builtin/2 hook */
% The original engine ends builtin/2 by probing predicate_property/2.
% For Ciao we use a whitelist of the classic builtins the planner may
% legitimately execute (arithmetic, type checks, term inspection).

ciao_builtin(G) :-
    functor(G, F, A),
    builtin_functor(F, A).

builtin_functor(is, 2).
builtin_functor(=:=, 2).
builtin_functor(=\=, 2).
builtin_functor(<, 2).
builtin_functor(=<, 2).
builtin_functor(>, 2).
builtin_functor(>=, 2).
builtin_functor(atom, 1).
builtin_functor(atomic, 1).
builtin_functor(number, 1).
builtin_functor(integer, 1).
builtin_functor(float, 1).
builtin_functor(var, 1).
builtin_functor(nonvar, 1).
builtin_functor(compound, 1).
builtin_functor(ground, 1).
builtin_functor(is_list, 1).
builtin_functor(length, 2).
builtin_functor(functor, 3).
builtin_functor(arg, 3).
builtin_functor('=..', 2).
builtin_functor(copy_term, 2).

/****************************************************** runtime DB */
% Predicates asserted/queried at runtime by legacy demo code.
:- data wr_eq/0, wr_ir/0, wr_fr/0, wr_last/0.
:- data at/1, on/1, now/1, lastaction/1, nonstop/0.

% Reified agent knowledge store (loaded by gloria_loader.pl and queried
% through agent_goal/2 in the builtin branches of demo_rules/demo_one_cond):
%   agent_fact(Ag, Fact)    e.g. existe(sacar_constancia)
%   agent_rule(Ag, H, Body) e.g. timing(T) :- gensym('', C), atom_number(C, T)
:- data agent_fact/2, agent_rule/3.

/*********************************************************** gensym */
% SWI gensym/2 is used by the gerente agent's timing/1 belief.  Ciao
% classic does not provide it, so keep a process-wide counter here.

:- data gensym_counter/1.

gensym(Base, Sym) :-
    (   retract(gensym_counter(N))
    ->  N2 is N + 1
    ;   N2 = 1
    ),
    assert(gensym_counter(N2)),
    sformat(NCodes, '~w', [N2]),
    atom_codes(Suffix, NCodes),
    atom_concat(Base, Suffix, Sym).

/*************************************************** agent_goal/2 */
% Evaluates a goal `G` in the agent's context, the way SWI did by
% executing it inside the agent module.  Order of resolution:
%   1. agent_fact(Ag, G)      -- a plain fact asserted from the .main
%   2. agent_rule(Ag, H, B)   -- a plain clause asserted from the .main
%   3. call(G)                -- engine-level / ISO / classic builtin
% The builtin branches of demo_rules and demo_one_cond use this instead
% of executing `G` directly (which would fail in Ciao for facts/rules
% that live in the SWI agent module).

agent_goal(Ag, G) :-
    agent_fact(Ag, G).
agent_goal(Ag, G) :-
    agent_rule(Ag, H, B),
    G = H,
    agent_goal_body(Ag, B).
agent_goal(_Ag, G) :-
    call(G).

agent_goal_body(_Ag, true) :- !.
agent_goal_body(Ag, (A, B)) :- !,
    agent_goal(Ag, A),
    agent_goal_body(Ag, B).
agent_goal_body(Ag, (A; B)) :- !,
    (   call(A)
    ;   call(B)
    ).
agent_goal_body(Ag, not(P)) :- !,
    \+ agent_goal(Ag, P).
agent_goal_body(Ag, P) :-
    agent_goal(Ag, P).

/*************************************************** legacy stubs */
% Ciao's classic runtime already provides time/1, statistics/0 and
% garbage_collect/0 (via runtime_control), so those are NOT stubbed
% here.  The remaining legacy entry points were only ever used by the
% interactive demo, which the Ciao port does not run.

sleep(_).

clean_all.

clean_do.

protocola(_).

noprotocol.

/*************************************************** MIS stub */

induce_spec(_, Rules, [], Rules) :- !.
induce_spec(_, _, Examples, _) :-
    throw('MIS induction not ported to Ciao yet (WP0)')
     , Examples = _Ex.   % keep Examples referenced to avoid warnings