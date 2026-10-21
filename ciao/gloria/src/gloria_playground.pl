/*  gloria_playground.pl  --  Query rewriting for the browser playground.

    The Gloria engine is a single Ciao module (`gloria`), and that is where
    its predicates live:

        gloria:load_agent_code('/enclosure.pl')
        gloria:prolog_agent(Ag, T, R, Obs, Actions)

    The playground's top level runs its queries in `user`, so those goals
    are *not* visible there: module-qualifying them fails with

        Bad module qualification ... module user does not import the
        predicate from module gloria

    The obvious fix -- `init_queries: ['use_module(library(gloria/gloria))']`
    -- would import the whole engine into `user`, which also makes every
    private helper callable unqualified (name collisions, wrong module
    resolution, ...).  Instead the page keeps the top level clean and this
    module rewrites the queries on the Prolog side, inside the `gloria`
    scope, so that it can see both the engine and the loader:

        ?- prolog_agent(enclosure, 0, 400, [time_day(am), it_is(sunny)], As).
           % parsed in 'user' -> fails -> rewritten below
        ?- gloria:prolog_agent(enclosure, 0, 400, [time_day(am), it_is(sunny)], As).
           % works

    The three rewrites (applied inside out, so a query can combine them):

        load_agent_code(P)          -> gloria:load_agent_code(P)
        prolog_agent(...)           -> gloria:prolog_agent(...)
        gloria_step(...)            -> gloria:gloria_step(...)

    Module qualification with a *module* whose predicates are all exported
    is fine in Ciao; it is only user modules, whose predicate names are not
    visible as module-qualified goals, that fail.

    Entry point (see the page's `pg_rewrite_goal`):

        ?- use_module(library(gloria/gloria_playground),
                      [disguise_trans_query/3]),
           disguise_trans_query((Query), _, Q), Q.

    Query is the goal the user typed and Q is the (possibly rewritten) goal
    to run: for a Gloria goal the engine is made visible by the `gloria:'
    qualification, and for anything else Q is Query unchanged, so ordinary
    top-level use is unaffected.  The second argument reports `ok' when a
    rewrite happened and `none' otherwise (useful for tests; the page does
    not need it).

    The first argument is read as a term (not met/1) on purpose: it is
    called from JavaScript, so no variables can have been bound by an
    earlier goal, and a typo does not need to distinguish "parser error"
    from "not a Gloria query".
*/

:- module(gloria_playground, [disguise_trans_query/3], [assertions, isomodes]).

:- doc(title, "Gloria playground query rewriting").

:- use_module(engine(term_basic), [functor/3]).

% ---------------------------------------------------------------------------

:- pred disguise_trans_query(+term, ?term, ?term)
   # "Rewrite the playground query @var{Query} into @var{Q}, so that the
      Gloria engine predicates (which live in the @tt{gloria} module, not in
      @tt{user}) become visible.  @var{R} is @tt{ok} when @var{Query} was
      rewritten.".

disguise_trans_query(Query, ok, Q) :-
    guise(Query, Q0),
    Q0 \= Query,
    !,
    Q = Q0.
disguise_trans_query(Query, none, Query).

% The guises that make a Gloria goal visible from `user`.  The clauses are
% tried inside out (the last one first), so wrapping is applied host-first.
guise(P, gloria:P) :- pred_name(P, load_agent_code), !.
guise(P, gloria:P) :- pred_name(P, prolog_agent), !.
guise(P, gloria:P) :- pred_name(P, gloria_step), !.

pred_name(Goal, Name) :-
    functor(Goal, Name, _).

% ---------------------------------------------------------------------------
