/*  gloria_loader.pl  --  Ciao loader for agent .kb / .main files.

    Replaces the SWI-only make_module/2 (which built a runtime module
    and asserted raw terms with call-by-module semantics).  Ciao cannot
    create runtime modules this way, so the loader reads the knowledge
    base and asserts *reified* facts for agent `Ag`:

        def/2          -> def(Ag, Head, Body)
        if_/2          -> if_(Ag, Body, Head)
        abd/1          -> abd(Ag, Ab)
        observable/1   -> observable(Ag, Pattern)
        user_built/1   -> user_built(Ag, L)
        for_testing_only/1 -> for_testing_only(Ag, Value)
        ghistory/1     -> ghistory(Ag, G)
        tracefile/1    -> skipped (config only)
        (:- _)         -> skipped (directives, comments)
        plain facts    -> agent_fact(Ag, Fact)     e.g. existe(sacar_constancia)
        plain clauses  -> agent_rule(Ag, Head, Body) e.g. timing(T) :- body

    The last two are what the agent module got in SWI by consulting the
    .main into `user`; here they go into the shared reified store and are
    evaluated by agent_goal/2.

    load_agent/2 is idempotent: it clears all clauses previously loaded
    for `Ag` before reading the file.  The agent's .kb file holds its
    rules (if_/2, def/2); its sibling .main file (same basename, .main
    extension) holds the configuration facts (abd/1, observable/1,
    user_built/1, for_testing_only/1, tracefile/1).  In the SWI setup
    the .main was consulted into `user` and reached the agent module by
    import; here both files are loaded explicitly into the reified DB.
*/

load_agent(Ag, KbFile) :-
    retract_all_agent(Ag),
    read_terms_file(Ag, KbFile),
    kb_main(KbFile, MainFile),
    (   catch(open(MainFile, read, S), _, fail)
    ->  read_agent_stream(Ag, S),
        close(S)
    ;   true
    ).

kb_main(KbFile, MainFile) :-
    atom_concat(Base, '.kb', KbFile),
    atom_concat(Base, '.main', MainFile).

read_terms_file(Ag, File) :-
    open(File, read, S),
    read_agent_stream(Ag, S),
    close(S).

read_agent_stream(_Ag, S) :-
    at_end_of_stream(S), !.
read_agent_stream(Ag, S) :-
    read(S, Term),
    (   Term = end_of_file
    ->  true
    ;   assert_agent_term(Ag, Term),
        read_agent_stream(Ag, S)
    ).

assert_agent_term(Ag, def(H, B)) :- !, assertz(def(Ag, H, B)).
assert_agent_term(Ag, if_(B, H)) :- !, assertz(if_(Ag, B, H)).
assert_agent_term(Ag, abd(L)) :- !, assert_exact(abd(Ag, L)).
assert_agent_term(Ag, observable(P)) :- !, assert_exact(observable(Ag, P)).
assert_agent_term(Ag, user_built(L)) :- !, assertz(user_built(Ag, L)).
assert_agent_term(Ag, for_testing_only(V)) :- !, assert_exact(for_testing_only(Ag, V)).
assert_agent_term(Ag, ghistory(G)) :- !, assertz(ghistory(Ag, G)).
assert_agent_term(_Ag, comment(_)) :- !.
assert_agent_term(_Ag, (:-(_))) :- !.          % directives: :- dynamic ..., :- [..]
assert_agent_term(_Ag, tracefile(_)) :- !.
% clauses of the SWI-only catch-all / MIS background: not agent knowledge
assert_agent_term(_Ag, (user_built(_) :- _)) :- !.
assert_agent_term(_Ag, (bg(_) :- _)) :- !.
assert_agent_term(Ag, (H :- B)) :- !, assertz(agent_rule(Ag, H, B)).
assert_agent_term(Ag, Fact) :- assertz(agent_fact(Ag, Fact)).

assert_exact(P) :-
    retractall(P),
    assertz(P).

retract_all_agent(Ag) :-
    retractall(def(Ag, _, _)),
    retractall(if_(Ag, _, _)),
    retractall(abd(Ag, _)),
    retractall(observable(Ag, _)),
    retractall(user_built(Ag, _)),
    retractall(for_testing_only(Ag, _)),
    retractall(goalsmem(Ag, _, _)),
    retractall(ghistory(Ag, _)),
    retractall(agent_fact(Ag, _)),
    retractall(agent_rule(Ag, _, _)).