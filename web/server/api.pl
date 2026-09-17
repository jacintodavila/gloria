:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).

% Load Gloria
:- consult('/home/jacinto/git/gloria/gloria.pl').

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
    directory_files('/home/jacinto/git/gloria/examples', Files),
    exclude(is_dot, Files, Examples),
    reply_json_dict(json{examples: Examples}).

post_start_session(Request) :-
    http_read_json_dict(Request, DictIn),
    AgentName = DictIn.agent,
    to_module_atom(AgentName, Agent), % see gloria.pl
    
    retractall(current_session_agent(_)),
    assert(current_session_agent(Agent)),
    
    atomic_list_concat(['/home/jacinto/git/gloria/examples/', AgentName, '/', AgentName, '.kb'], KBFile),
    atomic_list_concat(['/home/jacinto/git/gloria/examples/', AgentName, '/', AgentName, '.main'], MainFile),
    
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
