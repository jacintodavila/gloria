:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).

% Load Gloria: locate the repository root and load the engine from it, so
% that this server runs in any checkout (see gloria_root.pl).
:- consult('../../gloria_root').
:- ( set_gloria_root -> true ; gloria_root_error ).
:- ( gloria_root_path('gloria.pl', EngineFile)
    ->  consult(EngineFile)
    ;   gloria_root_error ).

% Mock state for single-user prototype
:- dynamic current_session_agent/1.
:- dynamic current_session_time/1.

% API Handlers
:- http_handler(root(api/examples), get_examples, []).
:- http_handler(root(api/session/start), post_start_session, []).
:- http_handler(root(api/session/step), post_step_session, []).

% Helper to filter dot files
is_dot(.) :- !.
is_dot(..) :- !.

get_examples(_Request) :-
    gloria_root_path(examples, ExamplesDir),
    directory_files(ExamplesDir, Files),
    exclude(is_dot, Files, Examples),
    reply_json_dict(json{examples: Examples}).

post_start_session(Request) :-
    http_read_json_dict(Request, DictIn),
    AgentName = DictIn.agent,
    to_module_atom(AgentName, Agent), % see gloria.pl
    
    retractall(current_session_agent(_)),
    assert(current_session_agent(Agent)),
    
    gloria_root_path(examples, ExamplesDir),
    atomic_list_concat([ExamplesDir, '/', AgentName, '/', AgentName, '.kb'], KBFile),
    atomic_list_concat([ExamplesDir, '/', AgentName, '/', AgentName, '.main'], MainFile),
    
    % Consult into the user module, as Gloria uses global predicates
    make_module(Agent, MainFile),
    make_module(Agent, KBFile),
    
    retractall(current_session_time(_)),
    assert(current_session_time(0)),
    
    reply_json_dict(json{status: "started", agent: AgentName}).

post_step_session(Request) :-
    http_read_json_dict(Request, DictIn),
    InputString = DictIn.input,
    term_string(Inputs, InputString),
    
    current_session_agent(AgentModule),
    current_session_time(T),
    
    % Pass AgentModule name to prolog_agent
    prolog_agent(AgentModule, T, 200, Inputs, Actions),
    
    NextT is T + 1,
    retract(current_session_time(T)),
    assert(current_session_time(NextT)),
    
    maplist(action_to_string, Actions, ActionsStr),
    reply_json_dict(json{actions: ActionsStr, next_time: NextT}).

action_to_string(do(Name, Time), String) :-
    with_output_to(string(String), writeq(do(Name, Time))).
