:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_json)).

% Load our API handlers
:- [api].

% Define the server port
:- dynamic port/1.
port(8080).

% Start server
start_server :-
    port(Port),
    http_server(http_dispatch, [port(Port)]),
    format('Server running on port ~w~n', [Port]).

% Serve static files from the React build directory
% The path must be absolute for http_reply_from_files to work reliably.
% It is derived from the repository root that api.pl has resolved.
:- ( gloria_root_path('web/client/dist', ClientDist)
    ->  http_handler(root(.), http_reply_from_files(ClientDist, []), [prefix])
    ;   gloria_root_error
    ).
