% runner.pl - long-lived SWI-Prolog worker used by the Gloria MCP server.
%
% Protocol (JSON over stdin/stdout, one message per line):
%   request:  {"cmd":"list_agents"}
%             {"cmd":"agent_info","agent":"enclosure"}
%             {"cmd":"run_step","agent":"enclosure","input":"[time_day(am), it_is(sunny)]","session":"s1"}
%             {"cmd":"reset","agent":"enclosure"}
%             {"cmd":"quit"}
%   reply:    {"ok":true, ...fields...}
%             {"ok":false,"error":"message"}
%
% The knowledge base of one agent is consulted into the `user` module
% (classic Gloria flow, see examples/enclosure/readme.txt).  Before loading a
% different agent, the predicates that the previous agents asserted in `user`
% are retracted so sessions do not contaminate each other.

:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- use_module(library(lists)).

:- ['/home/jacinto/git/gloria/gloria.pl'].

:- dynamic session_time/3.       % session_time(Session, Agent, T)
:- dynamic loaded_agent/1.

examples_root('/home/jacinto/git/gloria/examples').

/*************************************************************** main loop */

main :-
    repeat,
        read_line_to_string(current_input, Line),
        (   Line == end_of_file
        ->  !
        ;   Line == "",
            fail
        ;   catch(process_line(Line), Error,
                  ( term_string(Error, Msg),
                    reply(json{ok:false, error: Msg}) ) ),
            fail ),
    !.

process_line(Line) :-
    atom_json_dict(Line, Request, [default('')]),
    once(handle(Request, Reply)),
    reply(Reply).

reply(Reply) :-
    json_write_dict(current_output, Reply, [width(0)]),
    nl(current_output),
    flush_output(current_output).

/************************************************************** dispatching */

handle(Request, Reply) :-
    to_atom(Request.cmd, Cmd),
    handle_cmd(Cmd, Request, Reply).

% atom_json_dict/3 parses JSON strings as Prolog strings; use the atom
% spelling everywhere for reliable matching against 'list_agents' & friends.
to_atom(Value, Atom) :-
    (   atom(Value)
    ->  Atom = Value
    ;   string(Value)
    ->  atom_string(Atom, Value)
    ;   atom_string(Atom, Value) ).
:- discontiguous handle_cmd/3.

handle_cmd('list_agents', _Request, Reply) :-
    examples_root(Root),
    directory_files(Root, Entries),
    exclude(is_dot, Entries, Agents),
    sort(Agents, Sorted),
    Reply = json{ok:true, agents: Sorted}.

handle_cmd('agent_info', Request, Reply) :-
    to_atom(Request.agent, Agent),
    agent_info(Agent, Info),
    Reply = json{ok:true, agent: Agent, info: Info}.

handle_cmd('run_step', Request, Reply) :-
    to_atom(Request.agent, Agent),
    to_atom(Request.session, Session),
    (   run_one_step(Request, Agent, Session, Reply)
    ->  true
    ;   Reply = json{ok:false, error: 'agent produced no result (goal failed)'}
    ).

run_one_step(Request, Agent, Session, Reply) :-
    ensure_loaded_agent(Agent),
    get_session_time(Session, Agent, T),
    parse_input(Request.input, Inputs),
    catch(prolog_agent(Agent, T, 200, Inputs, Actions),
          Error,
          throw(Error)),
    maplist(action_to_string, Actions, ActionsStr),
    NextT is T + 1,
    retractall(session_time(Session, Agent, _)),
    assert(session_time(Session, Agent, NextT)),
    Reply = json{ok:true, agent: Agent, session: Session,
                 actions: ActionsStr, time: T, next_time: NextT}.

handle_cmd('reset', Request, Reply) :-
    to_atom(Request.agent, Agent),
    to_atom(Request.session, Session),
    (   Agent == '_all_'
    ->  retractall(session_time(Session, _, _))
    ;   retractall(session_time(Session, Agent, _)) ),
    Reply = json{ok:true, reset: Agent, session: Session}.

handle_cmd('ping', _Request, Reply) :-
    Reply = json{ok:true, pong:true}.

handle_cmd('quit', _Request, Reply) :-
    Reply = json{ok:true, bye:true}.

is_dot(.) :- !.
is_dot(..) :- !.

parse_input('', []) :- !.
parse_input(Input, Inputs) :-
    atom_string(Input, Atom),
    (   catch(term_string(Inputs, Atom), _, fail)
    ->  true
    ;   Inputs = [] ).

/*********************************************** agent loading / unloading */

ensure_loaded_agent(Agent) :-
    (   loaded_agent(Agent)
    ->  true
    ;   (   loaded_agent(Previous), Previous \== Agent
        ->  unload_agent(Previous)
        ;   true ),
        load_agent(Agent) ).

load_agent(Agent) :-
    agent_files(Agent, MainFile, KBFile),
    agent_keys(Agent, Keys),
    forall(member(Name/Arity, Keys),
           catch(user:dynamic(Name/Arity), _, true)),
    consult(MainFile),
    consult(KBFile),
    retractall(loaded_agent(_)),
    assert(loaded_agent(Agent)).

unload_agent(Agent) :-
    agent_keys(Agent, Keys),
    retract_all_keys(Keys),
    retractall(loaded_agent(Agent)).

% Union of the functors defined in the agent's source files and the classic
% dynamic predicates a Gloria agent may assert while reasoning.
agent_keys(Agent, Keys) :-
    agent_files(Agent, MainFile, KBFile),
    (   exists_file(MainFile) -> read_file_to_terms(MainFile, MT, []) ; MT = [] ),
    (   exists_file(KBFile)   -> read_file_to_terms(KBFile, KBT, []) ; KBT = [] ),
    append(MT, KBT, Terms),
    maplist(term_head_functor, Terms, TermKeys),
    fixed_user_predicates(Fixed),
    append([TermKeys, Fixed], KeyLists),
    flatten(KeyLists, Keys0),
    list_to_set(Keys0, Keys).

retract_all_keys([]).
retract_all_keys([K|Ks]) :-
    (   K = Name/Arity
    ->  functor(Pattern, Name, Arity),
        catch(retractall(user:Pattern),
              error(permission_error(_, _, _), _), true)
    ;   true ),
    retract_all_keys(Ks).

% functor of the head of a term in an agent file.  Clauses are `(:-)/2` terms,
% directives are `(:-)/1` terms.
term_head_functor(T, K) :-
    (   var(T)
    ->  K = none
    ;   (   T = (Head :- _)
        ->  HeadK = Head
        ;   HeadK = T ),
        (   var(HeadK)
        ->  K = none
        ;   functor(HeadK, Name, Arity),
            (   Name == (:-)
            ->  K = none                       % directive, e.g. :- dynamic ghistory/1.
            ;   K = Name/Arity ) ) ).

fixed_user_predicates([ 'abd'/1, 'observable'/1, 'if_'/2, 'if'/2, 'def'/2,
                        'user_built'/1, 'for_testing_only'/1, 'tracefile'/1,
                        'goalsmem'/3, 'actionsmem'/4, 'ghistory'/1,
                        'current_time'/1 ]).

/*********************************************************** file discovery */

agent_files(Agent, MainFile, KBFile) :-
    examples_root(Root),
    atomic_list_concat([Root, '/', Agent], Dir),
    exists_directory(Dir),
    find_file_pair(Dir, Agent, MainFile, KBFile).

% Priority: <agent>.main/.kb, then ex-<agent>.main/.kb, then any single
% .main/.kb found in the directory.
find_file_pair(Dir, Agent, MainFile, KBFile) :-
    named_pair(Dir, Agent, MainFile, KBFile),
    !.
find_file_pair(Dir, Agent, MainFile, KBFile) :-
    atomic_list_concat(['ex-', Agent], ExPrefix),
    named_pair(Dir, ExPrefix, MainFile, KBFile),
    !.
find_file_pair(Dir, _Agent, MainFile, KBFile) :-
    first_with_ext(Dir, '.main', MainFile),
    first_with_ext(Dir, '.kb', KBFile).

named_pair(Dir, Name, MainFile, KBFile) :-
    atomic_list_concat([Dir, '/', Name, '.main'], MainFile),
    atomic_list_concat([Dir, '/', Name, '.kb'], KBFile),
    exists_file(MainFile),
    exists_file(KBFile).

first_with_ext(Dir, Ext, File) :-
    directory_files(Dir, Files),
    exclude(is_dot, Files, Names),
    include(has_suffix(Ext), Names, Matching),
    sort(Matching, [F|_]),
    atomic_list_concat([Dir, '/', F], File).

has_suffix(Suffix, File) :-
    sub_atom(File, Before, _, 0, Suffix),
    Before > 0.

/************************************************************** agent info */

agent_info(Agent, Info) :-
    (   agent_files(Agent, MainFile, KBFile),
        exists_file(MainFile)
    ->  read_file_to_string(MainFile, MainText, []),
        read_file_to_string(KBFile, KBText, []),
        (   agent_gfile(Agent, GFile), exists_file(GFile)
        ->  read_file_to_string(GFile, GText, [])
        ;   GText = "" ),
        atomic_list_concat([GText, MainText, KBText], FullText),
        extract_title(FullText, Desc),
        agent_terms(MainFile, KBFile, Terms),
        findall(S, goal_string(Terms, S), Goals),
        findall(S, belief_string(Terms, S), Beliefs),
        findall(S, observable_string(MainText, S), Observables),
        findall(S, abducible_string(MainText, S), Abducibles),
        Info = json{description: Desc, goals: Goals, beliefs: Beliefs,
                    observables: Observables, abducibles: Abducibles}
    ;   Info = json{description: 'Agent files not found in examples/',
                    goals: [], beliefs: [],
                    observables: [], abducibles: []} ).

% Clauses and directives from both source files, so goals (if_/2) and beliefs
% (def/2) are found whether they live in the .main or the .kb file.
agent_terms(MainFile, KBFile, Terms) :-
    read_terms_if_exists(MainFile, MT),
    read_terms_if_exists(KBFile, KBT),
    append(MT, KBT, Terms).

read_terms_if_exists(File, Terms) :-
    (   exists_file(File)
    ->  catch(read_file_to_terms(File, Terms, []), _, Terms = [])
    ;   Terms = [] ).

% Best-effort Galatea specification file: <agent>.g, ex-<agent>.g, or the only
% .g in the agent directory.
agent_gfile(Agent, GFile) :-
    examples_root(Root),
    atomic_list_concat([Root, '/', Agent], Dir),
    (   atomic_list_concat([Dir, '/', Agent, '.g'], GFile),
        exists_file(GFile)
    ->  true
    ;   atomic_list_concat(['ex-', Agent], Ex),
        atomic_list_concat([Dir, '/', Ex, '.g'], GFile),
        exists_file(GFile)
    ->  true
    ;   first_with_ext(Dir, '.g', GFile)
    ).

% First paragraph following a "TITLE" line in a .g-style file.
extract_title(Text, Title) :-
    split_string(Text, "\n", " \t", Lines),
    (   append(_, ["TITLE"|Rest], Lines),
        exclude(=(""), Rest, NonEmpty),
        take_until_separator(NonEmpty, Body),
        Body \== [],
        atomic_list_concat(Body, " ", Title)
    ;   Title = 'No TITLE section available.' ).

take_until_separator(Lines, Body) :-
    append(Body, [Sep|_], Lines),
    memberchk(Sep, ["NETWORK", "AGENTS", "INIT"]),
    !.
take_until_separator(Lines, Body) :- Body = Lines.

goal_string(Terms, S) :-
    member(T, Terms),
    (   T = if_(Conds, Goals)
    ->  true
    ;   T = if(Conds, Goals)
    ->  true
    ;   fail ),
    term_string(Conds, CStr),
    term_string(Goals, GStr),
    atomic_list_concat([CStr, ' -> ', GStr], S).

belief_string(Terms, S) :-
    member(def(Goal, Body), Terms),
    term_string(Goal, GStr),
    term_string(Body, BStr),
    atomic_list_concat(['def(', GStr, ', ', BStr, ')'], S).

observable_string(Text, S) :-
    split_string(Text, "\n", " \t", Lines),
    member(Line, Lines),
    sub_string(Line, _, _, _, "observable("),
    source_term_arg(Line, "observable", S).

abducible_string(Text, S) :-
    split_string(Text, "\n", " \t", Lines),
    member(Line, Lines),
    sub_string(Line, _, _, _, "abd("),
    source_term_arg(Line, "abd", S).

% Render the argument inside the first `Fun(...)` group on a source line,
% keeping source variable names (e.g. time_day(X)).  Spaces are collapsed so
% that files with `abd(shut ) .` spacing still parse; brackets are balanced so
% `observable(time_day(_))` yields `time_day(_)`.
source_term_arg(Line, Fun, S) :-
    atom_string(LineAtom0, Line),
    atom_chars(LineAtom0, Chars0),
    exclude(=(' '), Chars0, Tight),
    atom_chars(LineAtom, Tight),
    atomic_list_concat([Fun, "("], OpenTag),
    sub_atom(LineAtom, Pos0, OpenLen, _, OpenTag),
    ArgStart is Pos0 + OpenLen,
    sub_atom(LineAtom, ArgStart, _, 0, ArgRest),
    atom_chars(ArgRest, RestChars),
    extract_balanced(RestChars, 0, ArgChars),
    atom_chars(ArgAtom, ArgChars),
    atom_string(ArgAtom, S).

% Extract chars until bracket depth returns to zero (the Fun( group's close).
extract_balanced([')'|_], 0, []) :- !.
extract_balanced([C|Cs], Depth, [C|Out]) :-
    (   C = '(' -> D1 is Depth + 1
    ;   C = ')' -> D1 is Depth - 1
    ;   D1 = Depth ),
    extract_balanced(Cs, D1, Out).

/************************************************************** helpers */

get_session_time(Session, Agent, T) :-
    (   session_time(Session, Agent, T)
    ->  true
    ;   T = 0 ).

action_to_string(do(Name, Time), String) :-
    with_output_to(string(String), writeq(do(Name, Time))).

/************************************************************** entry point */

% Started as:  swipl -q -s runner.pl -g "main" -t halt
% (Do not use `:- main.` here: gloria.pl also defines main/0.)