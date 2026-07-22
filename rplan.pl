/*  $Id: rplan.pl,v 1.0.1 2006/06/25 10:00:00 jacinto $

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

    You should have received a copy of the GNU General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    You can also find a copy of the GPL at http://www.gnu.org/copyleft/gpl.html

    ---
*/


/* rplan.pl

   This is a propotype of a reactive planner based on an abductive
   theorem prover. The specification is similar to that of
   Kowaslki-Fung's IFF proof procedure. However, this program
   incorporates other important concepts like any-timeness and
   interleaving of action and execution and interleaving of
   planning and testing.

   The computation strategy is essentially depth-first search
   Every module (predicate) is intented to be reentrant.

*/

/*************************************************************** operators */
% See auxilia.pl

:- dynamic sus/1, unf/1, observable/1.

/******************************************************************** demo */
% demo( Agent, ResourceCounter, FlagUC, FlagCN, InGoals, OutGoals ).

% No goals..
demo(_, _, _, _, [], [] ) :- !.

% No resources
demo(_, 0, _, _, InGoals, InGoals ) :- !,
  % writef("\n DEMO: Stopping thinking. No more resources \n",[]), 
  write_last( InGoals ).

% No rule applied since last call 
demo(_, _, no_ru_uc, no_ru_cn, InGoals, InGoals ) :- !, write_last( InGoals ).

% Rewrite and reordering
% 
demo(Ag, R, FlagUC, FlagCN, InGoals, OutGoals ) :-
  rewrite_disj( InGoals, NewGoals0 ), !,
  NewGoals0 equiv NewGoals,
  ( NewGoals = [FirstPlan|AltGoals] -> 
    ( priority_order( somenumber, FirstPlan, OrderPlan ),
      NextGoals = [OrderPlan|AltGoals] ) 
  ; NextGoals = [] ),
  demo_drop(Ag, R, FlagUC, FlagCN, NextGoals, OutGoals ).


/**************************************************************** demo_drop */
% demo_drop( Ag, 0, _, _, InGoals, InGoals ).

demo_drop(_, _, _, _, [], [] ) :- !.

% if it is the special literal false ([]).
%
demo_drop(Ag, R, _, _, [FaultG|AltGoals], OutGoals ) :-
  [] in FaultG,
  write_ir(" % -> pruning  -> %q \n",[FaultG] ),
  write_fr( [FaultG|AltGoals] ),
  demo(Ag, R, ru_uc, ru_cn, AltGoals, OutGoals ). % It's like starting again

% else..
demo_drop(Ag, R, _, FlagCN, InGoals, OutGoals ) :-
  InGoals equiv NewGoals,
  NewGoals = [FirstPlan|_],
  not(([] in FirstPlan)),
  write_fr( InGoals ),
  demo_rules(Ag, R, ru_uc, FlagCN, NewGoals, OutGoals ).

/*************************************************************** demo_rules */
% demo_rules(_, 0, _, _, InGoals, InGoals ).

% if it is a built-in predicate..
%
demo_rules(Ag, R,  _, FlagCN, InGoals, OutGoals ) :-
  InGoals = [FirstPlan|AltGoals],
  FirstPlan = [Abds, ( Cont :: ( G, Rest ), UCRest), CN, HF, M], 
  % writef(" DELTA: %q \n UC %q\n",[Abds, (Cont::(G,Rest), UCRest)]),
  G \= not(_),
  builtin( G ), !,
  % writef(" % -> processing built-in %q -> \n",[G]),
  ( G -> NewFirstPlan = [Abds, ( Cont :: Rest, UCRest), CN, HF, M]
  ;      NewFirstPlan = [Abds, ( Cont :: ([], true), true), CN, HF, M] ),
  NewR is R - 1,
  [NewFirstPlan|AltGoals] equiv NextGoals,
%  write_fr( NextGoals ),
  demo(Ag, NewR, ru_uc, FlagCN, NextGoals, OutGoals ).

% if it is a negative atom..
%
demo_rules(Ag, R, _, _, InGoals, OutGoals ) :-
  InGoals = [FirstPlan|AltGoals],
  FirstPlan = [Abds, ( Cont :: ( G, Rest ), UCRest), CN, HF, M], 
  G = not(Sg), !,
  NewCN = ( Cont :: [] if (Sg, true) @ [], CN),  % false if Sg
%  write_fr( [[Abds, ( Cont :: Rest, UCRest), NewCN, HF, M]|AltGoals] ),
  NextGoals = [[Abds, ( Cont :: Rest, UCRest), NewCN, HF, M]|AltGoals],
  demo_impl(Ag, R, ru_uc, ru_cn, NextGoals, OutGoals ).

% if it is to be tested only...
%
demo_rules(Ag, R, _, FlagCN, InGoals, OutGoals ) :-
  InGoals = [FirstPlan|AltGoals],
  FirstPlan = [Abds, ( Cont :: ( G, Rest ), UCRest), CN, HF, M], 
  % keeping for_testing_only for backward compatibility
  (observable(G);for_testing_only( G )), Cont = c(T,L), T\=t, !,
  % for_testing_only( G ), Cont = c(T,L), T\=t, !,
  write_ir("\n % -> starting testing of -> %q \n",[G]),
%  write_fr( [[Abds, ( c(t,L) :: (G, true), Cont :: Rest, UCRest), CN, HF, M]|AltGoals] ),
  demo(Ag, R, ru_uc, FlagCN,
	     [[Abds, ( c(t,L) :: (G, true), Cont :: Rest, UCRest), CN, HF, M]|AltGoals], OutGoals ).


% if it is a defined atom..
%
demo_rules(Ag, R, _, FlagCN, InGoals, OutGoals ) :-
  InGoals = [FirstPlan|AltGoals],
  FirstPlan = [Abds, ( Cont :: ( G, Rest ), UCRest), CN, HF, M],          
  unfoldable( G ),  !,
  definition(Ag, Abds, G, D ),
  write_ir(" % -> unfolding -> %q \n",[G]),
  Cont = c(C,PG), ContP = c(C,G), % Set the new context with G but only for D
  NewFirstPlan = [Abds, ( ContP :: ( D, true ), Cont :: Rest,  UCRest), CN, HF, M],
  [NewFirstPlan|AltGoals] equiv NextGoals,
  useful_order( R, NextGoals, OrderGoals ),
  rewrite_disj( OrderGoals, OrderGoals2 ),
%  write_fr( OrderGoals2 ),
  NR is R - 1,
  demo(Ag, NR, ru_uc, FlagCN, OrderGoals2, OutGoals ).

% if it is an equality or disequality atom..
%
demo_rules(Ag, R, _, FlagCN, InGoals, OutGoals ) :-
  InGoals = [FirstPlan|AltGoals],
  FirstPlan = [Abds, ( Cont :: ( G, Rest ), UCRest), CN, HF, M],          
  equality( G ),
  suspend( G, Abds, NewAbds ), !,
  rewrite_disj([[NewAbds, ( Cont :: Rest, UCRest), CN,HF,M]|AltGoals], NextGoals), 
  NR is R - 1,
  demo(Ag, NR, ru_uc, FlagCN, NextGoals, OutGoals).

% if it is an inequality 
%
demo_rules(Ag, R, _, _, InGoals, OutGoals ) :-
  factoring_ineq( InGoals, NextGoals ), 
  NR is R - 1, !,
  demo(Ag, NR, ru_uc, ru_cn, NextGoals, OutGoals ).

% if it is an suspendable literal but factoring is possible
%
demo_rules(Ag, R,  _, FlagCN, InGoals, OutGoals ) :-
  rewrite_disj( InGoals, InGoals2 ),
  factoring( InGoals2, NextGoals ),
%  write_fr( NextGoals ),
  NewR is R - 1, !,
  rewrite_disj( NextGoals, NextGoals2 ),
  demo(Ag, NewR, ru_uc, FlagCN, NextGoals2, OutGoals ).

% if it is an suspendable atom but factoring was impossible and Cont = p
%
demo_rules(Ag, R, _, FlagCN, InGoals, OutGoals ) :-
  InGoals = [FirstPlan|AltGoals],
  FirstPlan = [Abds, ( c(p,L) :: ( G, Rest ), UCRest), CN, HF, M],          
  suspendable( G ),
  suspend( todo(L,G), Abds, NewAbds ), !, % to L do G, new abds structure!
  NR is R - 1,
  demo(Ag, NR, ru_uc, FlagCN, [[NewAbds, ( c(p,L) :: Rest, UCRest), CN, HF, M]|AltGoals], OutGoals).

% if it is an suspendable atom but factoring was impossible and Cont = t
%
demo_rules(Ag, R, _, FlagCN, InGoals, OutGoals ) :-
  InGoals = [FirstPlan|_],
  FirstPlan = [_, ( c(t,_) :: ( G, _ ), _ ), _, _, _],
  suspendable( G ),
  quick_order( InGoals, NextGoals ), !,
  NewR is R - 1,
  demo(Ag, NewR, ru_uc, FlagCN, NextGoals, OutGoals ). % control back to demo..

% No rule was applied on UC.. control goes to demo_impl 
%
demo_rules(Ag, R, _, FlagCN, InGoals, OutGoals ) :-
  NewR is R - 1,
  demo_impl(Ag, NewR, no_ru_uc, FlagCN, InGoals, OutGoals ).


/************************************************************* quick_order */
/* Trying to explore the more relevant branches..                          */

% quick_order( [F, S, T|Rest], [S, T, F| Rest] ).

% quick_order( [F|Rest], New ) :- append( Rest, [F], New ).

quick_order( [_|Rest], Rest ).

% The idea here is that with this rotation I will be
% able to process another nodes on which I may be able to
% keep building.. 
% The problem is that I lose my chance to execute an
% action already in this node.. 
 

/********************************************************** priority_order */
% Redefined in gloria.pl to include meta-level rules..
% priority_order( _, Node, Node ).


/************************************************************** unfoldable */

unfoldable( G ) :- not(abducible( G )),
	not(equality( G )), not(inequality( G )).

/************************************************************** definition */
% moved to gloria.pl. This one is deprecated
% 
% definition( _, G, D ) :- !,
%   createscheme(G, NG),
%   findall( (NG, B), clause(NG, B), L ),
%   attach_eq( G, L, D ).
 

/************************************************************ useful_order */

useful_order( _, Goals, Goals ).

/*************************************************************** abducible */

abducible( G ) :- G=..[Ab|_], abd(Ab).

/***************************************************************** suspend */

suspend( G, Abds, NewAbds ) :-
  % writef(" Suspended %q", [G]),
  write_ir(" % -> suspending %q -> \n",[G]),
  and_append( Abds, (G, true), NewAbds ).

/*************************************************************** factoring */

factoring( InGoals, OutGoals ) :- 
  InGoals = [[Abds, ( Cont :: ( Pt, Rest ), UCRest), CN, HF, M]|AltGoals],
  suspendable( Pt ),
  ground(Pt), !,
  clause(Pt,_),    % This is because we store some Abd in PROLOG's DB
  write_ir(" % -> factoring/subsuming %q in DB -> \n", [Pt]), 
  OutGoals = [[Abds, ( Cont :: Rest, UCRest), CN, HF, M]|AltGoals].

factoring( InGoals, OutGoals ) :- 
  InGoals = [[Abds, ( Cont :: ( Pt, Rest ), UCRest), CN, HF, M]|AltGoals],
  suspendable( Pt ),
  % ground(Pt),
  scontain( Abds, todo(_,Pt) ), !,
  write_ir(" % -> factoring/subsuming %q in Delta %q -> \n", [Pt, Abds]), 
  OutGoals = [[Abds, ( Cont :: Rest, UCRest), CN, HF, M]|AltGoals].

factoring( InGoals, OutGoals ) :- 
  InGoals = [[Abds, ( Cont :: ( Pt, Rest ), UCRest), CN, HF, M]|AltGoals],
  suspendable( Pt ),
  not(scontain( Abds, todo(_,Pt) )),
  findalldb( Pt, HF, LKb ),                % defined in implica.pl
  findallabs( Pt, Abds, HF, LAb, _ ),      % "
  % Pred \== Pt,                             % excluding propositions..
  append( LKb, LAb, All ),                 % Collect all the candidates P(s)
  member(Ps, All),                     % Choose one (if none then fail) 
  % Chosen = todo(_,Ps),     % Structured abds for execution now in findallabs
  Chosen = Ps, 
  unpack_eq( Pt, Chosen, T_eq_S ),
  T_eq_S \== ([], true),                   % if they don't match then fail
  check_eq( HF, T_eq_S, ToHF ),
  ToHF \== [], !,                          % if any var's used before then fail
  and_append( T_eq_S, Abds, NewAbds ),
  append( ToHF, HF, NewHF ),
  write_ir(" % -> factoring %q with %q - New Delta %q -> \n",
           [Pt, Chosen, NewAbds]), 
  OutGoals = [[NewAbds, ( Cont :: Rest, UCRest), CN, HF, M],
	      [Abds, ( Cont :: ( Pt, Rest ), UCRest), CN, NewHF, M]|AltGoals].


factoring_ineq( InGoals, OutGoals ) :- 
  InGoals = [[Abds, ( Cont :: ( Ine, Rest ), UCRest), CN, HF, M]|AltGoals],
  inequality( Ine ),
  ground( Ine ), !,
  write_ir(" % -> factoring INEQ  %w  -> \n",[Ine]),
  and_append( Abds, (Ine, true), NewAbds ),
  OutGoals = [[NewAbds, ( Cont :: Rest, UCRest), CN, HF, M]|AltGoals].

factoring_ineq( InGoals, OutGoals ) :- 
  InGoals = [[Abds, ( Cont :: ( Ine, Rest ), UCRest), CN, HF, M]|AltGoals],
  inequality( Ine ),                      % if it's not an ineq. fail
  not(ground( Ine )),
  ( Ine = ( X le Y ) ; Ine = ( X lt Y ) ),
  ( before( Y, X, Abds ) ->
    ( OutGoals = [[true, ( Cont :: ([],true), true), true, [], []]|AltGoals]
    )
  ; ( subsume_ineq( Ine, Abds, NextAbds ) ->
      ( OutGoals = [[NextAbds, ( Cont :: Rest, UCRest), CN, HF, M]|AltGoals] )
    ; ( and_append( Abds, (Ine, true), NewAbds ),
        OutGoals = [[NewAbds, ( Cont :: Rest, UCRest), CN, HF, M]|AltGoals] )
    )
  ), !, write_ir(" % -> factoring INEQ  %w  -> \n",[Ine]).


/************************************************************** suspendable */

suspendable( G ) :- abducible( G ).

/*********************************************************************** in */

X in [_, ( _ :: G, _ ), _, _, _] :- X belongs G.

/********************************************************************** xin */

xin( Elem, [First|_] ) :-  Elem =@= First, !.
xin( Elem, [_|List] ) :- xin( Elem, List ).

/**************************************************************** attach_eq */

attach_eq( _, [], [] ) :- !.
attach_eq( G, [(NG, C)|RestC], [NC|NRestC] ) :-
  unpack_eq_falsefilter( G, NG, Eq ), !, 
  and_append( Eq, C, NC ), % defined  in auxiliar.pl
  attach_eq( G, RestC, NRestC ).
attach_eq( G, [_|RestC], NRestC ) :-
  attach_eq( G, RestC, NRestC ).

unpack_eq_falsefilter( G, Gs, T_eq_S ) :-
  unpack_eq( G, Gs, T_eq_S ), % defined in rewrite.pl
  not([] belongs T_eq_S).

/***************************************************************** builtin */
% To define my own builtin predicates..

builtin( renvar( _, _ ) ) :- !.

builtin( L ) :- is_list( L ), fail, !. % just in case..

builtin( L ) :- user_built( L ). 

builtin( G ) :-   
  predicate_property( G, P ), (P = built_in ; P = interpreted ). % or foreign? 

/*********************************************************** subsume_ineq */

subsume_ineq( Ineq, Delta, Delta ) :- Ineq blgs Delta, !.
subsume_ineq( Ineq, Delta, NewDelta ) :- 
  ( Ineq = (A le B) ; Ineq = (A lt B) ),
  nonvar(A), 
  ( ( ( C le B ) blgs Delta, Aux = ( C le B ) ) 
  ; ( ( C lt B ) blgs Delta, Aux = ( C lt B ) ) ),
  nonvar(C),
  ( A < C -> 
    ( NewDelta = Delta, ! )
  ; ( extract_ineq( Aux, Delta, TempDelta ),
      NewDelta = ( Ineq, TempDelta ) ) ), !.
subsume_ineq( Ineq, Delta, NewDelta ) :- 
  ( Ineq = (A le B) ; Ineq = (A lt B) ),
  nonvar(B), 
  ( ( ( A le C ) blgs Delta, Aux = ( A le C ) ) 
  ; ( ( A lt C ) blgs Delta, Aux = ( A lt C ) ) ),
  nonvar(C),
  ( C < B -> 
    ( NewDelta = Delta, ! )
  ; ( extract_ineq( Aux, Delta, TempDelta ),
      NewDelta = ( Ineq, TempDelta ) ) ).

/********************************************************** extract_ineq */

extract_ineq( Ineq, (Y, S), S ) :- Ineq == Y, !.
extract_ineq( Ineq, (_, R), S ) :- extract_ineq( Ineq, R, S ).


%%% --------------------------------------------- end of file rplan.pl %%%

