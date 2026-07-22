/*  $Id: gloria.pl,v 1.0.3 2007/04/12 10:00:00 jacinto $

    Part of Gloria http://gloria.sourceforge.net

    Author:        Jacinto Davila
    E-mail:        jacinto@ula.ve
    WWW:           http://webdelprofesor.ula.ve/ingenieria/jacinto
    Copyright (C): 2006, Jacinto Davila and Universidad de Los Andes, Venezuela

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    You can also find a copy of the GPL at http://www.gnu.org/copyleft/gpl.html

    ---
    Changed Oct 2007: using if_ instead of just if in actilog files

*/

/********************************************************* submodules */
% the rest of the Gloria system must be in the same directory

:- [auxilia].      % Support predicates
:- [equiva].       % Term equivalence relations and case analysis
:- [rewrite].      % Re-write rules for equality and inequalities
:- [implica].      % Implications processing engine
:- [rplan].        % main processing engine (r stands for reactive)
:- ['flach/mis.pl']. % invoking Shapiro's MIS (based on an implem. by Flach). 

% :- op(1100,fy,'if').            %if tal cosa.
% :- op(1200,xfy,'then').         %if tal cosa then tal cosa.
% :- op(1100,fy,'observe').
% :- op(1100,fy,'asummes').
%
% :- op(1100,fy,'to').  %to tal cosa
% :- op(1200,xfy,'do'). % do tal cosa

% :- dynamic on/1, at/1, on/2, at/2, endfile/0, nonstop/0, def/2, if/2,
% 	   now/1, toldtostop/0, lastaction/1, do/3, bg/1.

:- dynamic def/2, if/2, goalsmem/3, actionsmem/4.

%
% Warning:
% Most of this file is intended for demostration purposes only.  
% Gloria-like agents may use this code as an illustration, but
% they do not have to abide by exactly the same rules. The rest of Gloria,
% however, must be kept like it is. 
%

/************************************************************* main */
% to invoke the agent as a standalone program or in batch job
% NOT READY

print_attr_list([]).

print_attr_list([A|R]) :-
    write(A), nl,
    print_attr_list(R).

eval :-
      current_prolog_flag(argv, Argv),
      append(_, [--|Args], Argv),
      % concat_atom(Args, ' ', SingleArg),
      % term_to_atom(Term, SingleArg),
      % Args = [Obs, Gin],
      term_to_atom(ObsT, Obs),
      term_to_atom(GinT, Gin),
      cycling(GinT), % demo has been invoked
      % Gout = goals( _, AltG ), % write(hola), write(Gout), nl, nl, write(AltG), nl, 
      % format('~w~n', [Gout]),
      % format('~w~n', [AltG]), 
      % escribe_influencias(Influences).
      % print_attr_list(Influences).

escribe_influencias([]).
escribe_influencias([I|R]) :- I =.. [Nombre|Args], format('~w', [Nombre]), escribe_lista(Args), nl, escribe_influencias(R). 

escribe_lista([]).
escribe_lista([X|R]) :- escribe_lista(X), escribe_lista(R), !.
escribe_lista([X|R]) :- format(' ~w', [X]), escribe_lista(R). 

main :-
        catch(eval, E, (print_message(error, E), fail)),
        halt.
main :-
        halt(1).

/************************************************************* gcompile */
% to parse the original source code of the agent beliefs to
% produce a list of definitions for the agent's internal language
%
% gcompile(language, sourcefile, destinationfile). 
%
% language can be either openlog, actilog, java or prolog
%
% see gcompile.pl


/************************************************************ demo_gloria */

% demo_gloria( R1, InGoals, OutGoals ) :-
%   demo( R1, ru_uc, ru_cn, InGoals, OutGoals ).
% module adjusted

demo_gloria(Ag, R1, InGoals, OutGoals ) :-
  demo_impl(Ag, R1, ru_uc, ru_cn, InGoals, OutGoals ).


% examples:
% demo_all_cond( 10, 10, [], [] ).
% [ex007].
% demo_all_cond( 10, 10,[[ true, true, shoes_are_wet, ([(cloudy_last_night,true)] if (rain_last_night, true) @ [], [] if (cloudy_last_night, true) @ [], true), [], []] ], OutG ).
% demo_all_cond( 10, 100,[[ (rain_last_night, true), true, true, ([(cloudy_last_night,true)] if (rain_last_night, true) @ [], [] if (cloudy_last_night, true) @ [], true), [], []] ], OutG ). 


/************************************************************ cycling */
% the cycle top most predicate
%
% cycle(input_goals, output_goals). 
%
% NOT READY

cycling(R, InG) :- 
	thinking(R, InG, OutG), 
	% executing(OutG, NextG),
        executing(OutG, NextG, Examples, Bad_Rules),
        learning(Examples, Bad_Rules), 
	cycling(R, NextG).

 
step(R, InG, NextG) :- 
	thinking(R, InG, OutG), 
        executing(OutG, NextG, _Examples, _Bad_Rules). 

/***************************************************************** ic */
% module adjusted
ic(Ag, Restricciones) :- % revisar el formato de las reglas
        findall( ( c(p,true) ::  [HHead] if BBody @ []),  
                 ( Ag:if_(Body, Head), arregla(Body, BBody), aplana(Head, HHead)), L ),
        aplana(L, Restricciones). 

% obs(L) :-
%        findall( Obs, observe Obs, L ).
%        % aplana(L, Observaciones ).

aplana([], true).
aplana([C|R], (C, RR)) :- aplana(R, RR). 

arregla(true, true) :- !. 
arregla((A,B), (A,BB)) :- !, arregla(B,BB).
arregla(A, (A, true)).


/************************************************************** definition */
% definition retrieves the definition Def of a goal G from the knowledge
% base. The missing argument stands for when we tried to use the abducibles
% to retrieve definitions as well. Bad idea. 
%
% module adjusted
definition(Ag,  _, G, Def ) :-
  createscheme(G, NG),
  % findall( (NG, B), (para NG haga B), L ),
  % findall( (NG, true), (asuma NG), LF), 
  findall( (NG, B), Ag:def(NG, B), L),
  %% this invokes the database of definitions created by gcompile
  % append(L, LF, LL),
  attach_eq( G, L, Def ).
  % make_or(D, Def). % ancient tranformation

% Transforma  [] list into a (.. , false) or-list
make_or([], false).
make_or([A|B], or(AA,BB)) :- arregla(A,AA), make_or(B, BB).

observing( G, List, Def ) :- 
  createscheme(G, NG),
  findall( (NG, true), member(NG,List), LL),
  attach_eq( G, LL, D ),
  make_or(D, Def).

% to use what I already have
assimilate_action( G, D ) :-  
  createscheme(G, NG),
  attach_eq( G, [(NG,true)], D ).


/**************************************************************** thinking */
%
% thinking procedure
% module adjusted
thinking(Ag, R, Gin, Gout) :-
  demo_gloria(Ag, R, Gin, Gout ).

% and_append(true, X, X).
% and_append((X,W), Y, (Z,R)) :- and_append(W, Y, R). 

/*************************************************************** executing */
%
executing([[Influences, Rest, CN, HF, HH]|RestG], 
          [[NewInfluences, Rest, NewCN, HF, HH]|RestG], Examples, Rules_to_reLearn ) :-
    writeln('%'),
    writeln('% In a NEW CYCLE, while executing this:'), 
    write_frontier([[Influences, Rest, CN, HF, HH]]), 
    testing(Influences, Feedback), 
    % writeln(Influences), 
    writeln('% the agent observes (please, input observations and finish with "end.".'),
    % writeln('% to report failing actions write failed(Action, Goal).'),
    % writeln('% to report successful actions write succeded(Action, Goal).'),
    writeln('% for any other observation, type each atom and the period)'), 
    observing(Raw_Observations), append(Raw_Observations, Feedback, Observations), 
    % control commands
    (member(record(F), Observations) -> 
       protocola(F) ; true ),
    (member(norecord, Observations) -> 
       noprotocol ; true ),
    (member(regoal, Observations) -> 
       ( ic( IC ),
	 and_append( IC, CN, NewCN )  % IC are put first into the plan.  
        ) ; NewCN = CN ),
    criticising(Observations, Obs, Examples, Rules_to_reLearn),
    (member(learn, Observations) -> 
	  true ; ( Examples = [], Rules_to_reLearn = [] ) ),
    (member(clearobs, Observations) -> 
       NewInfluences = Obs 
       ; and_append(Obs, Influences, NewInfluences) ). 
    % Don't loose previous obs, yet...

/*************************************************************** observing */

observing(List) :-
    read(Obs), 
    ( Obs = help -> 
        ( writef("\n regoal. reload c-a rules", []),
          writef("\n clearobs. clears observations", []),
          writef("\n end. quits observing", []), !, 
          observing(List) ) ;   
        ( Obs = end -> List = [] ; (List = [Obs|Rest], observing(Rest)))).

/*************************************************************** testing */

% testing is eliminated while not learning for usability
testing(_, []) :- !. 
testing(true, []).
testing((todo(see, _), Rest), F ) :- testing(Rest, F ). % Don't process obs
testing((todo(Goal, Do), Rest), Feedback) :-
     writef("%    - Does %w succed achieving %w? (yes, no or unk):\n", [Do, Goal]),
     read(Ans), ( Ans = yes -> Feedback = [succeded(Do, Goal)|R] ;
                               Ans = no -> Feedback = [failed(Do, Goal)|R] ;
                               Feedback = R ),
     testing(Rest, R). 

/************************************************************** critising */
% criticising builds the list of examples requires by the learning task.
% in the indicated agent
% criticising( Agent, Feedback, Observations, Examples, Rules to review).
% 

criticising(_, [], true, [], []).
criticising(Ag, [failed(Action, Goal)|RestActs], (fail(Action),R), [-Goal|RestExamples], New_Rules) :-
    saving(Ag, Action :- true), % The action attempted, the goal failed approach
    % I will not use the db for other than these abducibles in the
    % background theory for learning
    % get the Rules for the definition of this Goal
    get_rules_for(Ag, Goal, This_Rules),
    criticising(Ag, RestActs, R, RestExamples, Rules),
    append( Rules, This_Rules, New_Rules).
%
% the following two are used to account for simple feedback, not for learning
%
criticising(Ag, [fail(Action)|RA], (fail(Action), R), RestExamples, Rules) :-
    criticising(Ag, RA, R, RestExamples, Rules).
%
criticising(Ag, [success(Action)|RA], (success(Action), R), RestExamples, Rules) :-
    criticising(Ag, RA, R, RestExamples, Rules).
%
% The following needs some thought. If I produce positive examples
% then, the associated rules must also be put into question.
% but, why would the agent want to do that and when?
%
% criticising([succeded(Action, Goal)|RA], R, [+Goal|RestExamples], Rules) :-
criticising(Ag, [succeded(Action, Goal)|RA], (success(Action), R), RestExamples, Rules) :-
    saving(Ag, Action :- true),
    criticising(Ag, RA, R, RestExamples, Rules).
% restoring untried actions. This semantics must be verified
criticising(Ag, [suspended(Action, Goal)|RA], (todo(Goal, Action), R), RestExamples, Rules) :-
    saving(Ag, Action :- true),
    criticising(Ag, RA, R, RestExamples, Rules).
criticising(Ag, [Obs|RA], RObs, Examples, Rules) :-
    ( Obs = regoal ; Obs = clearobs ), !, 
    criticising(Ag, RA, RObs, Examples, Rules).
criticising(Ag, [Obs|RA], (todo(see, Obs), RObs), Examples, Rules) :-
    criticising(Ag, RA, RObs, Examples, Rules).

% must think about bounded storage and garbage collection here!. 
saving(Ag, A) :- !, side_of_storage(Ag, N), ((N < 100, assertz(Ag:ghistory(A)),
  writef("\n# Gloria: guardando %w in agent %w\n",[A,Ag])) ; true ).

side_of_storage(Ag, N) :- findall(A, Ag:ghistory(A), L), !, length(L,N).

get_rules_for(Ag, Goal, Rules) :-
    createscheme(Goal, NG),
    findall( NG :- B, Ag:def(NG, B), Rules),
    writef("\n# Gloria: rules of agent %w\n",[Ag]),
    revising(Rules), 
    retractall(Ag:def(NG, _)). % clear this goal's clauses from the KB.

revising([]).
revising([(H:- B)|Rest]) :-  
    writef("\n# Gloria: revising -> to %w do %w.\n",[H,B]),
    revising(Rest). 

/************************************************************* learning */
% learning invokes the mis learner and clears and updates the defs. 
%

learning(Ag, Examples, Rules) :-
    % writef("# Gloria: starting a learning exercise with %w", [Examples]),
    induce_spec(Ag, Rules, Examples, Clauses), !,
    assertall(Ag, Clauses).

assertall(_, []).
% assertall(Ag, [Clause|R]) :- assertz(Ag, Clause), assertall(Ag, R).
assertall(Ag, [(H:-B)|R]) :- 
    assertz(Ag:def(H,B)),
    writef("# Gloria: newly learnt rule -> %w : to %w do %w.\n",[Ag,H,B]),
    assertall(Ag, R).


/* lastest additions to allow for agents */
bg(Ag, X) :-
  % writef("# Gloria: Agent %w is checking background", [Ag]),
  Ag:ghistory(X).
  % writef("\n# Gloria: Agent %w is checking on %w", [Ag, X]).
bg(Ag, X) :- bg(X). % for backward compatibility. Beware!
bg(Ag, H:-B) :- 
  Ag:def(H, B).
  % writef("#\n Gloria: Agent %w is checking on its def(%w,%w)", [Ag, H, B]).
  % to use Ag's rules as background knowledge


/******************************************************** old methods */
/************************************************************* gloria */

gloria( R, M, IC ) :-
  % create_sem,
  assert(ic(IC, M)),
  Goals0 = [[true, true, IC, [], M]],
  cycle( R, Goals0, 0).
  % destroy_sem.

set_time( T ) :- 
  (retractall(now(_)) ; true ),
  assert(now(T)).

/*************************************************************** cycle */
%
cycle( R, Goals, T) :- !,
  verify_frontier( Goals, Goals1 ),
  % ( Goals2 == [] -> ( protocol(out), write_frontier(Goals1) ) ; true ),
  set_time( T ),
  writef(" ****************************************** CYCLE TIME: %q \n",[T]),
  % profile( demo_gloria( R, Goals1, Goals2 ), plain, _ ),
  time( demo_gloria( R, Goals1, Goals2 ) ),
  % ( Goals2 == [] -> ( protocol(out), write_frontier(Goals1) ) ; true ),
  verify_frontier( Goals2, Goals3 ), !,
  Tact is T + 1, % Normalizing the resource consumption to 1.
  stop( Goals3 ),
  pace( Goals3 ), % statistics, % show_profile(P),
  act( Goals3, Goals4, Tact, NewT ), !, 
  writef("\n Next Cycle is %q\n",[NewT]),
  cycle( R, Goals4, NewT ). 


/***************************************************************** pace */

pace( G ) :- 
  length( G, L ), L < 2, !, sleep(3).

pace( _ ).


/****************************************************** verify_frontier */

verify_frontier( Goals, Goals0 ) :-
  ( Goals == [] -> 
    ( restore_frontier( Goals0 ) )
  ; Goals0 = Goals ), !. 

/**************************************************************** stop */

stop( _ ) :- nonstop, !.

stop( G ) :- read( A ),
  ( ( A = y, ! )
  ; ( A = d, !, writef(" CYCLE: Current Plan \n",[]),
      ( G = [F|_] -> write_frontier([F]) ; write_frontier(G) ) )
  ; ( A = g, !, tell(out), writef(" CYCLE: Current Plan \n",[]),
      ( G = [F|_] -> write_frontier([F]) ; write_frontier(G) ), told )
  ; ( A = s, !, statistics )
  ; ( A = nst, !, assert(nonstop) ) 
  ; ( A = t, !, trace )
  ).  

/***************************************************** restore_frontier */

restore_frontier( [[true, true, IC, [], M]] ) :-
   ic( IC, M ).
   % findall(do(A,B,C), do(A,B,C), L ),
   % writef(" CYCLE: Forgetting all this %q and restoring frontier \n", [L]),
   % clean_do, clean_all.

/****************************************************************** act */

act( [], [], T, T ) :- 
  writef(" ACT: Before execution, at time %q the frontier is empty \n",[T]), !.

act( InGoals0, OutGoals, T, Tf ) :-
  % trace,
  length( InGoals0, LL ),
  writef(" ACT: Before execution, at time %q the length of the frontier is %q \n",[T, LL]),
  % writef(" ACT: Current First Plan: \n",[T]),
  InGoals0 equiv InGoals,
  InGoals = [FirstPlan|_],
  % write_frontier( [FirstPlan] ),
  ( empty_plan( FirstPlan ) ->
    ( treat_garbage( FirstPlan, NewFirstPlan ),  
      NextGoals = [NewFirstPlan], ! % cleaning frontier..
    )
  ; % ( ( LL > 100 ) ->
    %   ( cut_frontier( InGoals, NextGoals, 50, 50 ), !
    %  )
    % ; ( NextGoals = InGoals 
    %   )
    %  )
    NextGoals = InGoals    
  ),
  NextGoals = [FirstP|_],
  FirstP = [Delta, UC, _, _, _],
  writef(" Delta: %q\n UC: %q\n",[Delta, UC]), 
  executables( FirstP, T, ToExecute ),
  try( ToExecute, T, Feedback, Tf ),
  ( ( succeeded( Feedback ), !,
      writef("\n# ACT: Succeeded Action %q \n with Inputs %q \n",[ToExecute, Feedback]),
      assimilate( Feedback, NextGoals, NewGoals ) 
    )
  ; ( NextGoals = [_|PruneGoals],   % cutting off the faulty plan..
      writef("\n# ACT: Failed Action %q \n with Inputs %q \n",[ToExecute, Feedback]),
      assimilate( Feedback, PruneGoals, NewGoals )
    )
  ),
  % OutGoals = NewGoals.
  clean_FirstCN( NewGoals, OutGoals ). 

/********************************************************* empty_plan */

empty_plan([Delta, true, _, _, _]) :- 
  not(contain( Delta, do(_,_,_) )).

/********************************************************** succeeded */

succeeded( true ) :- !.

succeeded( (A, Rest) ) :- 
  not(A = fail(_,_,_)),  % old representation
  not(A = fail(_)), % updated for the current general representation
  succeeded( Rest ).

/************************************************* contain_clean_only */

contains_clean_only( ( do(clean, Tc, Tc), RestExec ), RestExec ) :- !.

contains_clean_only( (A, Rest), Final ) :- 
  A \== do( _, _, _ ), contains_clean_only( Rest, Final ).  

/********************************************************* executables */

executables([Delta, _, _, _, _], _, ToExecute ) :-
  ( extract_do_s( Delta, ToExecute ), ! ) 
  ; ToExecute = true .

/******************************************************** extract_do_s */

extract_do_s( Delta, Doos ) :-
  first_do( Delta, Do ),
  starting-time( Do, T ),
  pick_all_doos( T, Delta, true, Doos ).


first_do( ( do(A, T, Td) , _ ), do(A,T,Td) ) :- !.
first_do( ( _, Rest ), Doos ) :- first_do( Rest, Doos ).


starting-time( do(_, T, _), T ).


pick_all_doos( _, true, In, In ) :- !.

pick_all_doos( T, (A,R), In, Out ) :-
  A = do(_, To, _ ), To == T, !,
  pick_all_doos( T, R, (A, In), Out ).

pick_all_doos( T, (_ ,R), In, Out ) :-
  pick_all_doos( T, R, In, Out ).


% examples:
% extract_do_s( (do(a,T,T2), T lt T3, do(b, T3, T4), true ), TE ).
% extract_do_s( (do(a,T,T2), do(b, T3, T4), true ),  TE ).
% extract_do_s( (do(a,T,T2), 1 lt T3, do(b, T3, T4), true ), TE ).
% extract_do_s( (do(up(3), X, Y), do(open, Y, Z), true), TE ).
% extract_do_s( (do(a,T,T1), do(b,T2,T4), do(c, T, T3), true ), Te ).
% extract_do_s( ( 1 lt T3, true ),  TE ).
%


/********************************************************* treat_garbage */

treat_garbage( [_, _, _, _, _], 
               [true, true, IC, [], M] ) :-
  % collect_Init_Ex_Vars( Mo, Vars0 ),
  % collect_Ex_Vars( Delta, Vars0, Vars1 ),
  % collect_Ex_Vars( UC, Vars1, Vars ), % spy(ic),
  ic( IC, M ),
  clean_all, 
  % clean_cn( CN, Vars, IC, NewCN ).
  clean_do,
  % remove_marker( clean, Delta, NewDelta ),
  garbage_collect.


% To remove the first 
remove_marker( _, true, true ) :- !.
remove_marker( M, (do(M,_,_), RD), RD ) :- !.
remove_marker( M, ( _, RD), De ) :- remove_marker( M, RD, De ).


clean_cn( true, _, _, true ) :- !.

% clean_cn( (Imp, Rest), Vars, IC, (NewImp, NewCN) ) :-
%   is_ic( Imp, IC, NewImp ), !,
%   clean_cn( Rest, Vars, IC, NewCN ).

clean_cn( (Imp, Rest), Vars, IC, (Imp, NewCN) ) :- 
  no_all_vars_unused( Imp, Vars ), !,
  clean_cn( Rest, Vars, IC,  NewCN ).

clean_cn( (_, Rest), Vars, IC, NewCN ) :- 
  % writef(" %q ", [Rest]),
  clean_cn( Rest, Vars, IC, NewCN ).


is_ic( Cont :: IH if IBody @ _, 
  ( Cont :: H if Body @ HP, _), Cont :: H if Body @ HP ) :- 
  IH =@= H,
  IBody =@= Body,!.

is_ic( Imp, (_, Rest), NewImp ) :-
  is_ic( Imp, Rest, NewImp ).


/********************************************************* clean_FirstCN */

clean_FirstCN( [], [] ) :- !.

clean_FirstCN( [First|AltG], NewGoals ) :-
  First = [Delta, UC, CN, HF, Mo], % trace,
  collect_Init_Ex_Vars( Mo, Vars0 ), 
  collect_Ex_Vars( Delta, Vars0, Vars1 ),
  collect_Ex_Vars( UC, Vars1, Vars ), % spy(ic),
  % ic( IC, _ ),
  soft_clean_cn( CN, Vars, ic, NewCN, [], UsedVars ),
  % tell(myout),
  % writef(" Soft cleaning \n",[]),
  % write_frontier([First]),
  % write_frontier([[Delta, UC, NewCN, HF, M]]),
  % told,
  filter_vars( Mo, UsedVars, NewM ),
  garbage_collect,
  NewGoals = [[Delta, UC, NewCN, HF, NewM]|AltG].


soft_clean_cn( true, _, _, true, U, U ) :- !.

soft_clean_cn( (Imp, Rest), Vars, IC, (Imp, NewCN), InV, OutV ) :- 
  no_all_vars_unused( Imp, Vars, InV, NeV ), !,
  soft_clean_cn( Rest, Vars, IC, NewCN, NeV, OutV ).

soft_clean_cn( (_, Rest), Vars, IC, NewCN, InV, OutV ) :- 
  soft_clean_cn( Rest, Vars, IC, NewCN, InV, OutV ).


% In the second case..
% Notice that, if at least one variable in the implication
% is also in UC then the restriction is
% still valid and the implication cannot be removed.
%
no_all_vars_unused( ( _ :: H if Body @ _), Vars, InV, OutV ) :-
  collect_Vars_in_Args( H, [], HVars ),
  collect_Ex_Vars( Body, HVars, AllVars ),
  contains( Vars, AllVars ),
  append( AllVars, InV, OutV ).

% contains( Set1, Set2 ) -> Set1 contains Set2 

contains( _, [] ) :- !.
% contains( [], [] ) :- !..
contains( Vars, [V|_] ) :- V sbelongs Vars, !.
contains( Vars, [_|Rest] ) :- contains( Vars, Rest ).


filter_vars( [], _, [] ) :- !.
filter_vars( [F|R], Vars, [F|RNewM] ) :-
  F = ( V=sk(_) ),
  V sbelongs Vars, !,
  filter_vars( R, Vars, RNewM ).
filter_vars( [_|R], Vars, RNewM ) :-
  filter_vars( R, Vars, RNewM ).
  
 
/************************************************************* assimilate */
/* This procedure deals with the update of the frontier of goals, considering
 * the results of the actions.
 * assimilate(+Obs, +InGoals, -OutGoals)
*/

% nothing to assimilate
assimilate( true, InGoals,  InGoals ) :- !.

% nothing to assimilate into. it shouldn't happen
assimilate( _, [], [] ) :- !.

% assimilating a suspended goal. Basically, puting it back
assimilate( (todo(Goal, Action), Rest ), InGoals, OutGoals ) :- 
  InGoals = [[Delta, UC, CN, HF, M]|RestG],
  and_append(todo(Goal,Action), Delta, NewDelta),  
  NextGoals = [[NewDelta, UC, CN, HF, M]|RestG],
  assimilate( Rest, NextGoals, OutGoals ).

% assimilating a sucessful action
assimilate( (success(A), Rest ), InGoals, OutGoals ) :- 
  InGoals = [FirstPlan|RestG],
  FirstPlan = [Abds, UCRest, CN, HF, M],
  Cont = c(p,A),
  assimilate_action( A, D ),
  PreNext = [[Abds, ( Cont :: (D, true), UCRest), CN, HF, M]|RestG],
  PreNext equiv NextGoals,
  assimilate( Rest, NextGoals, OutGoals ).

% old implementation. Too attached to a representation
assimilate( (Input, Rest ), InGoals, OutGoals ) :-
  Input = succeed( A, T1, T2 ), !,
  % asserta( do(A,T1, T2) ), 
  force_factoring( A, T1, T2, InGoals, NextGoals ),
  assimilate( Rest, NextGoals, OutGoals ).

% assimilating a failing action. In principle, it must be added as a 
% new constraint. However, a record of the failing action will hardly
% be used in further reasoning. It has already been dealt with by
% assimilating (see above or the .main file of the agent). 
assimilate( (fail(A), Rest ), InGoals, OutGoals ) :-
  % Input = fail( A, T1, T2 ), 
  % add_ic( A, T1, T2, InGoals, NextGoals ), !, 
  assimilate( Rest, InGoals, OutGoals ).

% old implementation
assimilate( (Input, Rest ), InGoals, OutGoals ) :-
  Input = fail( A, T1, T2 ), !,
  add_ic( A, T1, T2, InGoals, NextGoals ),
  % assimilate( Rest, NextGoals, OutGoals ).
  % clean_FirstCN( InGoals, NextGoals ), 
  assimilate( Rest, NextGoals, OutGoals ).

% deprecated
% assimilate( (Input, Rest ), InGoals, OutGoals ) :-
%  not(Input = succeed( _, _, _)),
%  not(Input = fail( _, _, _ )),
%  % asserta( Input ), 
%  assimilate( Rest, InGoals, OutGoals ). 

/**************************************************** force factoring */
/* this predicate factorizes a fact representing a sucessful action, with
 * those similar predicates already in Delta. */

force_factoring( _, _, _, [], [] ).

force_factoring( A, T1, T2, [First|AltG], NewGoals ) :-
  First = [Delta, UC, CN, HF, M],
  seek_do( A, T1, T2, Delta, Found, NewDelta, _ ),
  ( Found = do(_, _, _ ) ->
      (
% 
%        append( ToHF, HF, NewHF ),
% The following line have been disengaged to prevent
% the proliferation of branches...
%        UFirst = [Delta, UC, CN, NewHF, M], 
%        NewGoals = [[NewDelta, UC, CN, HF, M], UFirst|NAltG]
%
        NewGoals = [[NewDelta, UC, CN, HF, M]|NAltG]
      )
%
%     Experiment with incomplete factoring after success..
%     it does not work.. recall act1 + act2
%     NewGoals = [[NewDelta, TUC, UC, CN, HF, M]|NAltG]
%
%   ; NewGoals = [First|NAltG]
% 
%     Another experiment.. this time to prune the frontier..
%     if the action succeeds, then the alternatives should be
%     removed
%
  ; NewGoals = NAltG 
%
  ),
  force_factoring( A, T1, T2, AltG, NAltG ).


seek_do( _, _, _, true, false, true, [] ) :- !.

seek_do( A1, T1, T2, ( do(A2, Ti, Tf), Rest ), do(A2, Ti, Tf), 
        ( Ti eq T1, Tf eq T2, Rest ), [Ti eq T1, Tf eq T2] ) :-
  A1 == A2, !.

seek_do( A, T1, T2, ( X lt Y, Rest ), F, NRest, ToHF ) :- 
  nonvar(X), nonvar(Y), !,
  seek_do( A, T1, T2, Rest, F, NRest, ToHF ).

% seek_do( A, T1, T2, ( X lt Y, Rest ), F, NRest, ToHF ) :-
%  nonvar(X), var(Y), !,
%  seek_do( A, T1, T2, Rest, F, NRest, ToHF ).

seek_do( A, T1, T2, ( X eq Y, Rest ), F, NRest, ToHF ) :- 
  nonvar(X),nonvar(Y), !, 
  seek_do( A, T1, T2, Rest, F, NRest, ToHF ).

seek_do( A, T1, T2, ( going_up, Rest ), F, NRest, ToHF ) :-
  at(N), not(one_above(N)), !, 
  seek_do( A, T1, T2, Rest, F, NRest, ToHF ).

seek_do( A, T1, T2, ( Abd, Rest ), F, NRest, ToHF ) :-
  scontain( Rest, Abd ), !,
  seek_do( A, T1, T2, Rest, F, NRest, ToHF ). 

seek_do( A, T1, T2, ( going_down, Rest ), F, NRest, ToHF ) :-
  at(N), not(one_below(N)), !, 
  seek_do( A, T1, T2, Rest, F, NRest, ToHF ).

seek_do( A, T1, T2, ( Abd, Rest ), F, ( Abd, NRest ), ToHF ) :- !,
  seek_do( A, T1, T2, Rest, F, NRest, ToHF ).


one_above(N) :- on(M), M >= N, !.

one_below(N) :- on(M), M =< N, !.

/**************************************************************** add_ic */
% add the failing action as a new constraint to the system..
% There is no point in adding it to the plans that do not have the action desc.
 
add_ic( _, _, _, [], [] ).

add_ic( A, T1, T2, [First|AltG], NewGoals ) :-
   First = [Delta, _, _, _, _],
   seek_do( A, T1, T2, Delta, Found, _, _ ),
   ( Found = do(_, _, _ ) ->
     NewGoals = NAltG   % cutting off plans that contain the faulty action.
   ; NewGoals = [First|NAltG] 
   ),
   add_ic( A, T1, T2, AltG, NAltG ).


% add_ic( A, T1, T2, [First|AltG], NewGoals ) :-
%   First = [Delta, UC, CN, HF, M],
%   seek_do( A, T1, T2, Delta, Found, _, _ ),
%   ( Found = do(_, _, _ ) ->
%     ( NewCN = ( p :: [] if (do(A, T1, T2), true) @ [], CN),    
%       NewGoals = [[Delta, UC, NewCN, HF, M]|NAltG]
%     )
%   ; NewGoals = [First|NAltG] 
%   ),
%   add_ic( A, T1, T2, AltG, NAltG ).


% add_ic( A, T1, T2, [First|AltG], NewGoals ) :-
%  clean_FirstCN( [First], [NewFirst] ),
%  NewFirst = [Delta, UC, CN, HF, M],
%  ( propagation( Delta, p :: [] if (do(A, T1, T2), true) @ [], NewIC ) ->
%    and_append( NewIC, CN, NewCN )
%  ; NewCN = ( p :: [] if (do(A, T1, T2), true) @ [], CN) 
%  ),
%  TempGoals = [[Delta, UC, NewCN, HF, M]|NAltG],
%  % rewrite_disj( TempGoals, NextFirstGoals ),
%  add_ic( A, T1, T2, AltG, NAltG ),
%  % append( NextFirstGoals, NAltG, NewGoals ).
%  append( TempGoals, NAltG, NewGoals ).


/******************************************************************** try */

try( ToExecute, T, Feedback, Tf ) :-
  Tf is T + 1,        % Time after execution..
  clean_all,          % cleaning memory to avoid overwhelming branching..
%  wait_sem,           % Waiting for the semaphore of mutual exclusion.. 
%  [which], [where],!, % Which buttons are on, and where am I?..
  execute( ToExecute, T, Tf, Feedback ).
%  flush(which),
%  release_sem,      % Release the semaphore of mutual exclusion..
%  flush(where).

% try(  _, T, true, T ).   not free to execute..


/*************************************************************** execute */
% This version cannot deal with concurrent actions.. 

execute( true, _, Tf, Inputs ) :-  !,
  findall( on(N, Tf), on(N), L1 ), 
  findall( at(N, Tf), at(N), L2 ),
  append( L1, L2, L ),
  copyOr2And( L, Inputs ).  

execute( (A, Rest), T, Tf,  ( NewA, NewRest ) ) :- !,
  A = do( Act, T1, T2 ),
  ( ( possible_start( T, T1 ),
      possible_finish( Tf, T2 ),
      ( (  Act = up( N ),
           at( F ), F < N,
           retract(at( _ )),
           asserta(at( N ))
         )
      ;  ( Act = down( N ),
           at( F ), F > N,
           retract(at( _ )),
           asserta(at( N ))
         )
      ;  ( Act = open
         )
      ;  ( Act = close
         )
      ;  ( Act = turnoff(N),
	   at( N ),
           on( N ),
           retract(on( N ))
         )
      ),  
      NewA = succeed( Act, T, Tf ),
      ( retract(lastaction(_)) ; true ),
      assert(lastaction(Act)) 
    )
  ; ( ( ( in_the_past( T, T1 ); in_the_past(T, T2) ) ->  
	%  A had known exec. times, but is too late now..
        NewA = fail( Act, T1, T2 )
      ; NewA = fail( Act, T, Tf )    
      )   
    ) 
  ),
  % writef(" During execution %q\n",[NewA]),
  execute( Rest, T, Tf, NewRest ).

% execute( ( do(turnoff(N), 1,2), true), 1,2, R ). with pre2. first..
% execute( ( do(turnoff(3), T,2), true), 1,2, R ). with pre2. first..
% execute( ( do(turnoff(3), T,3), true), 1,2, R ). with pre2. first..	
					

possible_start( T, T1 ) :- ( var(T1), ! ) ; ( T1 == T ).

possible_finish( T, T2 ) :- ( var(T2), ! ) ; ( T2 == T ).

in_the_past( T, T1 ) :- nonvar( T1 ), T1 < T.


/***************************************************** output predicates */
% to be implemented 
%

/********************************************  other auxiliary predicates */

same( [F1|_], [F2|_] ) :-
  F1 == F2. % This is only to increase efficiency. 
            % I could compare the whole thing..

rotate_cn( [F1|R], [F2|R] ) :-
  F1 = [Delta, UC, CN, HF, M],
  shift( CN, NewCN ),
  F2 = [Delta, UC, NewCN, HF, M]. 

% rotate_cn( [[true,true,(a if b @ c, d if e @ f, true ), [], [] ]],R).

shift( (A, Rest), NewCN ) :- !,
  and_append( Rest, A, NewCN ).

shift( A, A ).
   
/************************************************** ACTIVA | PREFERENCE */
% These are examples of possible policies for reordering of plans
%
%

/******************************************************** priority_order */
priority_order( _, A, A ).  % do nothing for the time being.. 

% priority_order( _, [Delta, UC1, CN, HF, M], [Delta, UC2, CN, HF, M] ) :-
  % writef("  Reordering UC \n",[]),
  % policy3( 1, Delta, UC1, UC2 ).
  % writef("  Newly Ordered Frontier \n",[]),
  % write_frontier( [[Delta, UC2, CN, HF, M]] ).


/********************************************** priority_order_FirstP */
%
% priority_order_FirstP( _, G, G ) :- !.

priority_order_FirstP( _, [], [] ) :- !, 
   writef(" PRIORITY: Empty frontier",[]).

priority_order_FirstP( ActivatedGoals, 
                      [[Delta, UC1, CN, HF, M]|AltG], 
                      [[Delta, UC2, CN, HF, M]|AltG] ) :- % trace,
  ( ActivatedGoals = ( p :: ([Goal|_], true) ),
    ( ( contain( Goal, serve(_,_,_)) 
      ; contain( Goal, going_up )
      ; contain( Goal, going_down ) ),  
    % writef(" PRIORITY: Reordering UC after activation of goal %q in Plan:\n",[Goal]), 
    % write_frontier( [[Delta, UC1, CN, HF, M]] ), !,
    policy3( 50, Delta, UC1, UC2 ) )
  ; ( write_ir(" PRIORITY: No Reordering applies on %q\n",[ActivatedGoals]), UC1 = UC2 ) ).


policy3( R, Delta, UC1, UC2 ) :-
  ( ( contain( Delta, going_down ), !, 
      descendent_ord( R, UC1, UC2 ) )
  ; ( contain( Delta, going_up ), !,
      ascendent_ord( R, UC1, UC2 ) )
  ; ( contain( Delta, do(turnoff(_),_,_) ), !,
      UC1 = UC2 )
  ; ( neutral_ord( R, UC1, UC2 ) )
  ).


/******************************************************* descendent_ord */

descendent_ord( _, true, true ) :- !.
descendent_ord( _, (A, true), (A, true) ) :- !.
descendent_ord( 0, L, L ) :- !. 
descendent_ord( R, ( A, B, Rest ), NewOrdList ) :-
  dbetter( A, B ), !,
  NR is R//2,
  descendent_ord( NR, (B, Rest), IntOrdList ),
  descendent_ord( NR, (A, IntOrdList), NewOrdList ).
descendent_ord( R, ( A, B, Rest ), NewOrdList ) :-
  dbetter( B, A ), !,
  NR is R//2,
  descendent_ord( NR, (A, Rest), IntOrdList ),
  descendent_ord( NR, (B, IntOrdList), NewOrdList ).
descendent_ord( R, ( A, B, Rest ), NewOrdList ) :-
  % not dbetter( A, B ), not dbetter( B, A ),
  NR is R//2,
  descendent_ord( NR, (B, Rest), IntOrdList ),
  descendent_ord( NR, (A, IntOrdList), NewOrdList ).


dbetter( ( t :: _ ), ( p :: _ ) ) :- !.

dbetter( (p :: A ), ( p :: B ) ) :-  
  contain( A, do(turnoff(N), _, _ ) ),
  ( ( nonvar(N), at(N) )
  ; ( not(contain( B, do(turnoff(_), _, _ ) )) ) ), !.

dbetter( (p :: A ), ( p :: _ ) ) :- 
  contain( A, serve(N, _, _ ) ),
  nonvar(N), at(N), !.

dbetter( (p :: _ ), ( p :: B ) ) :- 
   contain( B, going_up ), !. 
  % not contain( B, do(turnoff(_), _, _ ) ), !.

%dbetter( (p :: A ), ( p :: _ ) ) :- 
%  contain( A, going_down ), !. 
  % not contain( B, do(turnoff(_), _, _ ) ), !.

dbetter( ( p :: A), ( p :: B ) ) :-
  contain( A, serve( N, _, _ ) ),
  contain( B, serve( M, _, _ ) ),
  nonvar( N ), nonvar( M ), N < M,
  at(H), N < H, H < M, !.

dbetter( ( p :: A), ( p :: B ) ) :-
  contain( A, serve( N, _, _ ) ),
  contain( B, serve( M, _, _ ) ),
  nonvar( N ), nonvar( M ), M < N,
  at(H), N < H, M < H, !.

/******************************************************** ascendent_ord */
   
ascendent_ord( _, true, true ) :- !.
ascendent_ord( 0, L, L ) :- !.
ascendent_ord( _, (A, true), (A, true) ) :- !.
ascendent_ord( R, ( A, B, Rest ), NewOrdList ) :-
  abetter( A, B ), !,
  NR is R//2,
  ascendent_ord( NR, (B, Rest), IntOrdList ),
  ascendent_ord( NR, (A, IntOrdList), NewOrdList ).
ascendent_ord( R, ( A, B, Rest ), NewOrdList ) :-
  abetter( B, A ), !,
  NR is R//2,
  ascendent_ord( NR, (A, Rest), IntOrdList ),
  ascendent_ord( NR, (B, IntOrdList), NewOrdList ).
ascendent_ord( R, ( A, B, Rest ), NewOrdList ) :-
  % not abetter( A, B ), not abetter( B, A ),
  NR is R//2,
  ascendent_ord( NR, (B, Rest), IntOrdList ),
  ascendent_ord( NR, (A, IntOrdList), NewOrdList ).


abetter( (t :: _ ), ( p :: _ ) ) :- !.

abetter( (p :: A ), ( p :: B ) ) :- 
  contain( A, do(turnoff(N), _, _ ) ),
  ( ( nonvar(N), at(N) )
  ; ( not(contain( B, do(turnoff(_), _, _ ) )) ) ), !.

abetter( (p :: A ), ( p :: _ ) ) :- 
  contain( A, serve(N, _, _ ) ),
  nonvar(N), at(N), !.

abetter( (p :: _ ), ( p :: B ) ) :- 
  contain( B, going_down ), !. 

% abetter( (p :: _ ), ( p :: _ ) ) :- 
%  contain( A, going_up ), !. 
  % not contain( B, do(turnoff(_), _, _ ) ), !.

%abetter( (p :: A ), ( p :: _ ) ) :- 
%  contain( A, going_down ), !. 
  % not contain( B, do(turnoff(_), _, _ ) ), !.

abetter( ( p :: A), ( p :: B ) ) :-
  contain( A, serve( N, _, _ ) ),
  contain( B, serve( M, _, _ ) ),
  nonvar( N ), nonvar( M ), N < M,
  at(H), H < M, H < N, !.

abetter( ( p :: A), ( p :: B ) ) :-
  contain( A, serve( N, _, _ ) ),
  contain( B, serve( M, _, _ ) ),
  nonvar( N ), nonvar( M ),  M < N,
  at(H), M < H, H < N, !.

/*********************************************************** neutral_ord */

neutral_ord( _, true, true ) :- !.
neutral_ord( 0, L, L ) :- !.
neutral_ord( _, (A, true), (A, true) ) :- !.
neutral_ord( R, ( A, B, Rest ), NewOrdList ) :-
  nbetter( A, B ), !,
  NR is R//2,
  neutral_ord( NR, (B, Rest), IntOrdList ),
  neutral_ord( NR, (A, IntOrdList), NewOrdList ).
neutral_ord( R, ( A, B, Rest ), NewOrdList ) :-
  nbetter( B, A ), !,
  NR is R//2,
  neutral_ord( NR, (A, Rest), IntOrdList ),
  neutral_ord( NR, (B, IntOrdList), NewOrdList ).
neutral_ord( R, ( A, B, Rest ), NewOrdList ) :-
  % not nbetter( A, B ), not nbetter( B, A ),
  NR is R//2,
  neutral_ord( NR, (B, Rest), IntOrdList ),
  neutral_ord( NR, (A, IntOrdList), NewOrdList ).


nbetter( (t :: _ ), ( p :: _ ) ) :- !.

nbetter( (p :: A ), ( p :: B ) ) :- 
  contain( A, do(turnoff(N), _, _ ) ),
  ( ( nonvar(N), at(N) )
  ; ( not(contain( B, do(turnoff(_), _, _ ) )) ) ), !.

nbetter( (p :: A ), ( p :: _ ) ) :- 
  contain( A, serve(N, _, _ ) ),
  nonvar(N), at(N), !.

%nbetter( (p :: A ), ( p :: _ ) ) :- 
%  contain( A, going_up ), !. 
  % not contain( B, do(turnoff(_), _, _ ) ), !.

%nbetter( (p :: A ), ( p :: _ ) ) :- 
%  contain( A, going_down ), !. 
  % not contain( B, do(turnoff(_), _, _ ) ), !.

nbetter( ( p :: A), ( p :: B ) ) :-
  contain( A, serve( N, _, _ ) ),
  contain( B, serve( M, _, _ ) ),
  nonvar( N ), nonvar( M ), at(H),
  % N < M, !.
  D1 is abs(N - H),
  D2 is abs(M - H),
  D1 < D2, !.

/******************************************************************* ord */

ord( _, true, true ) :- !.
ord( 0, L, L ) :- !.
ord( _, (A, true), (A, true) ) :- !.
ord( R, ( A, B, Rest ), NewOrdList ) :-
  A < B, !,
  NR is R//2,
  ord( NR, (B, Rest), IntOrdList ),
  ord( NR, (A, IntOrdList), NewOrdList ).
ord( R, ( A, B, Rest ), NewOrdList ) :-
  B < A, !,
  NR is R//2,
  ord( NR, (A, Rest), IntOrdList ),
  ord( NR, (B, IntOrdList), NewOrdList ).
ord( R, ( A, B, Rest ), NewOrdList ) :-
  not(A < B), not(B < A),
  NR is R//2,
  ord( NR, (B, Rest), IntOrdList ),
  ord( NR, (A, IntOrdList), NewOrdList ).


ord_res( 0 ).
ord_res( N ) :- 
  write(N), nl,
  NN is N // 2,
  ord_res( NN ).


/*********************************************** interface to Galatea */

goalsmem(_,_, _, [[true, true, true, [], []]]).

/************************************************************* prolog_agent */
% this is the predicate to invoke que agent-s reasoning engine
% prolog_agent(agent-s id, time, resources, observations)
% It s being adjusted to process raw observations and separate
% failures from achievements to prepare a learning task.
% Also, observations are preprocessed into the right format.
% the logic of the invocation must be verified.
% 
% This corresponds to the body of the cycle predicate. As such:
%
%  cycle if   observe feedback
%        and  learn from the mistakes
%        and  assimilate mistakes and success
%        and  think and act and cycle
%
%
% module adjusted (first stage)

prolog_agent(Ag, T, R, Obs) :-
    retractall(Ag:actionsmem(Ag, _, _, _)),
    retractall(Ag:goalsmem(Ag, _, _)),
    % Ag:goalsmem(Ag, T, [[Abds, Plan, Constraints, HF, HP]|RGs]),
    % ( Constraints = true -> (ic(IC), NewConst = IC, !) ; NewConst = Constraints ),
    % if a reentrant, use previous goals. Otherwise, start it over
    ( goalsmem(Ag, T, [[Abds, Plan, Constraints, HF, HP]|RGs]) ->
    % We decided to clean previous obs, if it necesary
    % context will be provided by the java wrapper
    % if contraints are null, reload IC otherwise carry on
      ( Constraints = true -> 
          (ic(Ag, IC),  and_append( IC, Contraints, NewConst ), cleaning_previous_obs(Abds,NAbds),!)
        ; (NewConst = Constraints, cleaning_previous_obs(Abds,NAbds) ) )
    ; ( ic(Ag, IC), and_append( IC, true, NewConst ),
	NAbds = true, Plan = true, HF = [], HP=[], RGs = [], !) ),
    criticising(Ag, Obs, Observations, Examples, Bad_Rules),
    learning(Ag, Examples, Bad_Rules), !,
    % at this point, the agent kb must has been corrected
    % if any bad rule was considered
    % for simplicity, clean up the abducibles
    % We may allow for success, failure and postponing actions as feedback
    %
    NextGs = [[NAbds, Plan, NewConst, HF, HP]|RGs],
    %
    % writeq(NextGs), nl,
    % something is missing here
    % the new set of goals must be updated depending on the outcome of actions
    %
    assimilating(Observations, NextGs, NewNextGs),
    thinking(Ag, R, NewNextGs, OutGs),
    record_actions(Ag, T, OutGs),
    record_goals(Ag, T, OutGs).

%prolog_agent(Ag, T, R, Obs) :-
%    goalsmem([[Abds, Plan, Constraints, HF, HP]|RGs]),
%    ( Constraints = true -> (ic(IC), NewConst = IC, !) ; NewConst = Constraints ),
%    and_append(Obs, Abds, NewAbds),
%    NewNextGs = [[NewAbds, Plan, NewConst, HF, HP]|RGs],
%    thinking(R, NewNextGs, OutGs),
%    record_actions(Ag, T, OutGs),
%    record_goals(Ag, T, OutGs).

record_actions(Ag, T, [[Abds, Plan, Constraints, HF, HP]|RGs] ) :-
    % retractall(actionsmem(Ag, _, _, _)),
    record_every_action(Ag, T, Abds).

record_every_action(_,_, true).
record_every_action(Ag, T, (todo(see,_), Rest)) :- !, % skip observations
    record_every_action(Ag, T, Rest).
record_every_action(Ag, T, (todo(_,Action), Rest)) :-
    prepare_action(Ag, T, Action, PreparedAction),
    assert(Ag:PreparedAction),
    record_every_action(Ag, T, Rest).


% prepare action for execution
% This is, still, a grey area. We must set the execution time variable here
% so that the wrapper can set the actual time at the right moment.
% But this means that the systems is linked to a particular representation
% of actions. Bad idea
% Also, I am separating the action name from the parameter in Prolog, where
% it is easier.

prepare_action(Ag, T, Action, actionsmem(Ag, T, Name, Parameters)) :-
   Action =.. [Name|Parameters].


record_goals(Ag, T, G) :- % retractall(goalsmem(Ag, _, _)),
    assert(Ag:goalsmem(Ag, T, G)), !.

assimilating(Feedback, NextGoals, NewGoals) :-
    succeeded( Feedback ), !,
    % writef("\n ACT: Succeeded Action %q \n with Inputs  \n",[Feedback]),
    assimilate( Feedback, NextGoals, NewGoals ).

assimilating(Feedback, NexGoals, NewGoals) :-
    NextGoals = [_|PruneGoals],   % cutting off the faulty plan..
    % writef("\n ACT: Failed Action %q \n with Inputs \n",[Feedback]),
    assimilate( Feedback, PruneGoals, NewGoals ).

cleaning_previous_obs(true,true) :- !.
cleaning_previous_obs((todo(see,_), Rest), New ) :-
    cleaning_previous_obs(Rest, New).
cleaning_previous_obs((H,R), (H,RR)) :-
    cleaning_previous_obs(R,RR).

% crear modulo dado el nombre del agente
% leer archivo .kb de ese agente
% lo carga en modulo
% using AgUD as the agent's module name and
% using AgType as the agent's kb filename

make_module(AgID, AgType) :-
	read_file_to_terms(AgType, Terms, []),
	assert_in_module(Terms, AgID).

assert_in_module([],_).
assert_in_module([T|R], ID) :-
	assert(ID:T),
    writef("# Gloria: asserted %w:%w\n",[ID,T]),
	assert_in_module(R,ID). 

%%% --------------------------------------------- end of file gloria.pl %%%


