%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                      %
%   Prolog programs from Section 9.3 of the book       %
%   SIMPLY LOGICAL: Intelligent reasoning by example   %
%   (c) Peter A. Flach/John Wiley & Sons, 1994.        %
%                                                      %
%   Predicates: induce_spec/2                          %
%                                                      %
%   NB. This file needs predicates defined in          %
%   the file 'library'.                                %
%                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% modified and extended by Jacinto Davila, June-Sep 2006. 
%
% requires a fact tracefile(File) in the KB. August 2006.
% modified to allow Agent specification, August 2009

:-consult(library).
:-consult(graphvizapi).

:- dynamic bg/1.

%%% 9.3  Top-down induction %%%

induce_spec(Examples,Clauses):-
  gv_start_trace, 
  gv_root_trace('start',0),
  process_examples(0, [],[],Examples,Clauses, _),
  gv_stop_trace.

induce_spec(Ag, Inicial_Theory, Examples,Clauses):-
  gv_start_trace, 
  gv_root_trace('start',0),
  process_examples(Ag, 0, Inicial_Theory,[],Examples,Clauses, _),
  gv_stop_trace.

% process the examples
process_examples(_, N, Clauses,Done,[],Clauses, N).
process_examples(Ag, N, Cls1,Done,[Ex|Exs],Clauses, NNN):-  
  process_example(Ag, N, Cls1,Done,Ex,Cls2, NN),!,
  writef("\n# Learner: %w's example %w processed\n", [Ag, Ex]),
  process_examples(Ag, NN, Cls2,[Ex|Done],Exs,Clauses, NNN).

% process one example
process_example(Ag, N, Clauses,Done,+Example,Clauses, N):-
  % writef("\n# Learner %w: processing positive example %w",[Ag, +Example]),
  covers(Ag, Clauses,Example).
process_example(Ag, N, Cls,Done,+Example,Clauses, NN):-
  not covers(Ag, Cls,Example),
  % writef("\n# Learner %w: generalise positive example %w",[Ag, +Example]),
  generalise(Ag, N, Cls,Done,Example,Clauses, NN).
process_example(Ag, N, Cls,Done,-Example,Clauses, NN):-
  covers(Ag, Cls,Example),
  % writef("\n# Learner %w: specialising negative example %w",[Ag, -Example]),
  specialise(Ag, N, Cls,Done,Example,Clauses, NN).
process_example(Ag, N, Clauses,Done,-Example,Clauses, N):-
  % writef("\n# Learner %w: processing negative example %w",[Ag, -Example]),
  not covers(Ag, Clauses,Example).

% covers(Ag, Clauses,Ex) <- Ag's Ex can be proved from Clauses and
%                       background theory in max. 20 steps
covers(Ag, Clauses,Example):-
	prove_d(Ag, 20,Clauses,Example), !,
    writef("\n# Learner %w: example %w is covered by %w", [Ag, Example, Clauses]).

prove_d(_, _, _,true):-!.
prove_d(Ag, D,Cls,(A,B)):- !,
    % writef("\n# Learner %w: proving %w and %w\n",[Ag, A, B]),
	prove_d(Ag, D,Cls,A),
	prove_d(Ag, D,Cls,B).
prove_d(Ag, D,Cls,A):-
	D>0,D1 is D-1,
	copy_element((A:-B),Cls),	% make copy of clause
    % writef("\n# Learner %w: proving %w from %w and %w\n",[Ag, A,Cls,B]),
	prove_d(Ag, D1,Cls,B).
prove_d(Ag, D,Cls,A):-
    % writef("\n# Learner %w: proving %w from background\n",[Ag, A]),
	prove_bg(Ag, A). % proving from background knowledge defined in .main

prove_bg(_, true):-!.
prove_bg(Ag, (A,B)):-   % cut was here!.
    % writef("\n# Learner %w: proving %w and %w in background\n",[Ag, A, B]),
	prove_bg(Ag, A),
	prove_bg(Ag, B). % cut changed to this position! and then removed.
prove_bg(Ag, A):-
	bg(Ag, (A:-B)),  % problem specific predicate. See .main
    % writef("\n# Learner %w: proving %w from %w in background\n",[Ag, A, B]),
	prove_bg(Ag, B).


% Specialisation by removing a refuted clause
% modified by J. Davila June 2006, August 2009
% Specialisation by refining the false clause and adding the 
% refined version instead of the other
specialise(Ag, N, Cls,Done,Example,Clauses, NNN):-
	false_clause(Ag, Cls,Done,Example,C),
	% remove_one(C,Cls,Cls1),
    % varsin(C, Vs), 
    % doesn't work. Need to prepare C to reenter the spec. cycle
    % it's done inside false_clause
    specialise_clause(C,a(S, _)), 
    % 
    C = a(To_be_removed, _),
    remove_one(To_be_removed, Cls, Cls1), 
	% write('     ...refuted: '),
    % write(C),nl,
	% write('     ...specialised into: '),write(S),nl,
    NN is N + 1,
    % gv_node_trace(N,S,NN),
	% process_examples(Cls1,[],[-Example|Done],Clauses).	
    process_examples(Ag, NN, [S|Cls1],[],[-Example|Done],Clauses, NNN).

% false_clause(Ag, Cs,E,E,C) <- Ag's C is a false clause in the proof of E (or ok)
false_clause(_, Cls,Exs,true,ok):-!.
false_clause(Ag, Cls,Exs,(A,B),X):-!,
	false_clause(Ag, Cls,Exs,A,Xa),
	( Xa = ok   -> false_clause(Ag, Cls,Exs,B,X)
	; otherwise -> X = Xa
	).
false_clause(Ag, Cls,Exs,E,ok):-
	element(+E,Exs),!.
false_clause(Ag, Cls,Exs,A,ok):-
	bg(Ag, (H:-B)), would_unify(A,H), !. % gets clause from Ag's Bk. 
false_clause(Ag, Cls,Exs,A,X):-
	% copy_element((A:-B),Cls),
        clause_matches((A:-B),Cls,Clause), 
	false_clause(Ag, Cls,Exs,B,Xb),
	( Xb \= ok		-> X = Xb
	% ; otherwise		-> X = (A:-B)
        ; otherwise		-> X = Clause
	).

% clause_matches checks whether some clause in Cls
% can be used to prove the example. If it finds it, it points it out. 
% 
clause_matches((A :- B), [(H :- B)|_], a((H :- B), Vars)) :-
    would_unify(A, H),!, 
    % collect_all_vars((H,B), Vars).
    literal(H, Vars).     % Also, let's forget about other variables
                          % but I shouldn't. This limits the search
                          % only to the variables in the head
clause_matches(In, [_|R], Out) :- clause_matches(In, R, Out). 

would_unify(X,Y) :- var(X) ; var(Y). 
would_unify(X,Y) :- X=..[F|P], Y=..[F|Q], would_unify_list(P,Q).

would_unify_list([],[]).
would_unify_list([F|Rest], [S|SRest]) :- would_unify(F,S), would_unify_list(Rest, SRest).

collect_all_vars(true, []).
collect_all_vars((F,R), Vars) :-
    literal(F, VarsF),
    collect_all_vars(R, VarsR),
    append(VarsF, VarsR, Vars).
collect_all_vars(L, Vars) :- literal(L, Vars), !. 

% Generalisation by adding a covering clause
generalise(Ag, N, Cls,Done,Example,Clauses, NNN):-
	search_clause(Ag, N, Done,Example,Cl), nl,
	% write('% Found clause: '),write(Cl),nl,
    writef("\n# Learner: Found the clause \n%  - %w\n\n", [Cl]),
    NN is N + 1,
    % gv_node_trace(N,Cl,NN), 
	process_examples(Ag, NN, [Cl|Cls],[],[+Example|Done],Clauses, NNN).

% search_clause(Ag, N, Exs,E,C) <- C is a clause covering Ag's E and
%                           not covering negative examples
%                           (iterative deepening search)
%                           N is the node number for graphvizs
search_clause(Ag, N, Exs,Example,Clause):-
	literal(Head,Vars),
	try((Head=Example)),
    % aliteral(Do, AVars), % append(Vars, AVars, AllV), % abducibles not needed
    ss(AVars, Vars), 
    % search_clause(Ag, N, 3,a((Head:-Do),Vars),Exs,Example,Clause).
    search_clause(Ag, N, 5,a((Head:-true),Vars),Exs,Example,Clause).

% search_clause(Ag, N, D,Current,Exs,Example,Clause):-
%	write(D),write('..'),
%	search_clause_d(Ag, N, D,Current,Exs,Example,Clause),!.
% search_clause(Ag, N, D,Current,Exs,Example,Clause):-
%	D1 is D+1,
%	!,search_clause(Ag, N, D1,Current,Exs,Example,Clause).
% base case
search_clause_d(Ag, NN, D,a(Clause,Vars),Exs,Example,Clause):-
	covers_ex(Ag, Clause,Example,Exs),	% goal
	not((element(-N,Exs),covers_ex(Ag, Clause,N,Exs))),
	% gv_answer(NN, Clause), 
	!.
search_clause_d(Ag, N, D,Current,Exs,Example,Clause):-
	D>0,D1 is D-1, NN is N + 1, 
	specialise_clause(Current,Spec),
	gv_node_trace_given(N,N,NN),
	% write(N), write('--'), writeln(NN), 
	search_clause_d(Ag, NN, D1,Spec,Exs,Example,Clause).

% Extensional coverage
covers_ex(Ag, (Head:-Body),Example,Exs):-
        try((Head=Example,covers_ex(Ag, Body,Exs))).
covers_ex(_, true,Exs):-!.
covers_ex(Ag, (A,B),Exs):-!,
	covers_ex(Ag, A,Exs),
	covers_ex(Ag, B,Exs).
covers_ex(_, A,Exs):-
	element(+A,Exs).
covers_ex(A,Exs):-
	prove_bg(Ag, A).

% specialise_clause(C,S) <- S is a minimal specialisation
%                           of C under theta-subsumption
specialise_clause(Current,Spec):-
	add_literal(Current,Spec).
specialise_clause(Current,Spec):-
 	apply_subs(Current,Spec).

% less restrictive than the original predicate
add_literal(a((H:-true),Vars),a((H:-L),Vars)):-!,
	literal(L,LVars),
    % append(Vars, LVars, NVars).
	% proper_subset(LVars,Vars). % too restrictive
    % subset(LVars, Vars). % check this!!!!
    not(would_unify(L, H)), % preventing recursive clauses
    ss(LVars, Vars). % using a new predicate
add_literal(a((H:-B),Vars),a((H:-L,B),Vars)):-
    literal(L,LVars), not_too_big((L,B)), % Problem-specific condition
    not(repeated(L,B)), % another problem-specific condition
    % append(Vars, LVars, NVars).  % not restrictive at all
	% proper_subset(LVars,Vars). % too restrictive
    % subset(LVars, Vars). 
    not(would_unify(L, H)), % preventing recursive clauses
    % writef("% Learner: adding literal %w to clause %w :- %w\n", [L,H,B]),
    % and_length(B, N), writef("*%w", [N]),
    ss(LVars, Vars). %

% modified to support strict specialisation
apply_subs(a(Clause,Vars),a(Spec,SVars)):-
	copy_term(a(Clause,Vars),a(Spec,Vs)),
	apply_subs1(Vs,SVars),
    % writef("applying a subs %w to %w \n", [Vs,Clause]),
    not(just_the_same(Clause, Spec)). % strict specialisation

apply_subs1(Vars,SVars):-
	unify_two(Vars,SVars).
apply_subs1(Vars,SVars):-
	subs_term(Vars,SVars).

unify_two([X|Vars],Vars):-
	element(Y,Vars),
	X=Y.
unify_two([X|Vars],[X|SVars]):-
	unify_two(Vars,SVars).

subs_term(Vars,SVars):-
	remove_one(X,Vars,Vs),
	term(Term,TVars),
	X=Term,
	append(Vs,TVars,SVars).

just_the_same(X,Y) :- X =@= Y. % they are structurally the same

repeated(L,LL) :- just_the_same(L,LL), !.
repeated(L,(LL,RR)) :- just_the_same(L,LL), !. % exactly the same
repeated(L,(_, RR)) :- repeated(L, RR). 

%%% Queries %%%

% term(list([]),[]).
% term(list([X|Y]),[item(X),list(Y)]).

%%%%%%%%%%%%%%%%%%  element/2  %%%%%%%%%%%%%%%%%%%%%%%%

% literal(element(X,Y),[item(X),list(Y)]).

% bg.

query1(Clauses):-
	induce_spec([+element(a,[a,b]),
 	            -element(x,[a,b]),
	             +element(b,[b]),
	             +element(b,[a,b])
	            ],Clauses).


%%%%%%%%%%%%%%%%%%  append/3   %%%%%%%%%%%%%%%%%%%%%%%

% literal(append(X,Y,Z),[list(X),list(Y),list(Z)]).

% bg.

query2(Clauses):-
	induce_spec([+append([],[b,c],[b,c]),
	             -append([],[a,b],[c,d]),
	             -append([a,b],[c,d],[c,d]),
	             -append([a],[b,c],[d,b,c]),
	             -append([a],[b,c],[a,d,e]),
	             +append([a],[b,c],[a,b,c])
	            ],Clauses).

%%%%%%%%%%%%%%%%%%   listnum/2    %%%%%%%%%%%%%%%%%%%%%%%

% literal(listnum(X,Y),[list(X),list(Y)]).
% literal(num(X,Y),[item(X),item(Y)]).

% no longer active. Now use bg/2
bg((num(1,one):-true)).
bg((num(2,two):-true)).
bg((num(3,three):-true)).
bg((num(4,four):-true)).
bg((num(5,five):-true)).

query3(Clauses):-
	induce_spec([+listnum([],[]),
 	            -listnum([one],[one]),
	             -listnum([1,two],[one,two]),
	             +listnum([1],[one]),
	             -listnum([five,two],[5,two]),
	             +listnum([five],[5])
	            ],Clauses).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

not_too_big(And_List) :- and_length(And_List, N), N < 6.

and_length(A, 0) :- not(A=(_,_)).
and_length((A,B), NN) :- and_length(B, N), NN is N + 1.

% subset predicate
ss([],_).
ss([X|Xs], Ys) :-
   remove_one(X, Ys, Ys1),
   ss(Xs, Ys1). 

