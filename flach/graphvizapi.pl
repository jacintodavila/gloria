%%% Graphviz utilities %%%

gv_max_id(1000).	% max number of nodes in the graph

% open file and start new graph
gv_start(FileName):-
	tell(FileName),
	writes(['digraph {']),
	%writes(['graph [size="4,6"];']),
	writes(['node [shape=plaintext, fontname=Courier, fontsize=12]']).

gv_start_trace :-
        tracefile(F),
        append(F),
        writes(['digraph {']),
	%writes(['graph [size="4,6"];']),
	writes(['node [shape=plaintext, fontname=Courier, fontsize=12]']),
        told.

% next graph
gv_next:-
	writes(['}']),
	writes(['digraph {']),
	writes(['node [shape=plaintext, fontname=Courier, fontsize=12]']).

% finish graph and close file
gv_stop:-
	writes(['}']),
	told.

gv_stop_trace :- tracefile(F), append(F),
	writes(['}']),
	told.


% start new subgraph
gv_cluster_start:-
	( retract('$gv_cluster'(N)) -> N1 is N+1
	; otherwise -> N1=0
	),assert('$gv_cluster'(N1)),
	writes(['subgraph cluster_',N1,' {']),
	writes(['[style=filled, color=lightgrey];']),
	writes(['node [style=filled,color=white];']).

% finish subgraph 
gv_cluster_stop:-
	writes(['}']).

% write the root of a tree and initialise node IDs
gv_root(L,N):-
	writes([N,' [label="',L,'"];']),
	gv_init_ids(N).

gv_root_trace(L,N):-
        tracefile(F), append(F), 
        writes([N,' [label="',L,'"];']),
	gv_init_ids(N), told.

% add a node with label L and parent N0
gv_node(N0,L,N):-
	gv_id(N),
	writes([N,' [label="',L,'"];']),
	writes([N0,' -> ',N,';']).

gv_node_trace(N0,L,N):-
        tracefile(F), append(F), 
	gv_id(N),
	writes([N,' [label="',L,'"];']),
	writes([N0,' -> ',N,';']), told.

gv_node_trace_given(N0,L,N):- nonvar(N), 
        tracefile(F), append(F),
	writes([N,' [label="',L,'"];']),
	writes([N0,' -> ',N,';']), told.

% add a specially formatted leaf
gv_answer(N0,L):-
	gv_id(N),
	writes([N,' [label="Answer:\\n',L,'", shape=ellipse, style=dotted, fontsize=10];']),
	writes([N0,' -> ',N,' [style=dotted, arrowhead=none];']).
	%writes(['{rank=same;',N0,';',N,';}']).

% generate a new node ID
gv_id(N):-
	retract('$gv_id'(N0)),
	gv_max_id(M),
	N0 < M,	% don't generate infinite graphs
	N is N0+1,
	assert('$gv_id'(N)).

% initialise node IDs, next free ID is N+1
gv_init_ids(N) :-
	retractall('$gv_id'(_)),
	assert('$gv_id'(N)).

% 
writes([]):-!,nl.
writes([H|T]):-!,writes(H),writes(T).
writes((A,B)):-!,writes(A),write(',\\n'),writes(B).	% break up conjunctions
writes(:-A):-!,write(':-'),writes(A).
writes(?-A):-!,write('?-'),writes(A).
writes('$empty_list'):-!,write([]).
writes(A):-write(A).	% catch-all
