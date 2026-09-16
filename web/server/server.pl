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
% The path must be absolute for http_reply_from_files to work reliably
:- http_handler(root(.), http_reply_from_files('/home/jacinto/git/gloria/web/client/dist', []), [prefix]).
