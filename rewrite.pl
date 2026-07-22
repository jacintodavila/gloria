/*  $Id: rewrite.pl,v 1.0.1 2006/06/25 10:00:00 jacinto $

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



/* rewrite.pl

   Rewrite rules for equalities and disequalities.
   Created: 24 June 1996 (from the previous eq.pl)
                         (this is the file used by rplan.pl)
   Last modified: 14 August 1996
   Last modified: 17 Nov 1996
   Last modified: 02 Dec 1996
   Last modified: 28 Jan 1997
   Last modified: 17 Feb 1997
   Last modified: 18 Ago 2006
   
   Conventions: 
   1.- A variable is considered universally quantified iff it
   does not appear in UC or M.

   2.- The algorithm process every node exhaustively. In the
   event of finding a condition that implies falsity, the
   operation cease and the node is tagged to be dropped 
   immediately. In that case, the next node is taken in
   for processing.

*/

/******************************************************** submodules */

:- [auxilia].

/********************************************** rewrite_rules_UC */

rewrite_disj( [], [] ) :- !.

rewrite_disj( InGoals, NewGoals ) :-
  InGoals =  [[Delta, UC, _, _, _]|AltGoals],
  ( [] belongs Delta ; ( UC = ( _ :: Plan, _ ), [] belongs Plan ) ), !,
  rewrite_disj( AltGoals, NewGoals ).
  % NewGoals = AltGoals. If I use this I may get unprocessed eq on the way..

rewrite_disj( InGoals, NewGoals ) :-
  InGoals =  [[Delta, UC, CN, HF, M]|AltGoals],
  rewrite( Delta, NewDelta, Theta, M ),
  ( member(dropit, Theta) ->  % the c(t,true) may be wrong
    ( NewGoals = [[true, (c(t,true) :: ([], true), true), CN, HF, M]|AltGoals])
  ; ( apply( Theta, UC, NewUC ),
      apply( Theta, CN, NewCN ),
      NewGoals = [[NewDelta, NewUC, NewCN, HF, M]|AltGoals] ) ).


/****************************************************** rewrite */
/* rewrite( InConj, OutConj, Theta, MarkedVars )                */
   
rewrite( true, true, [], _ ).

% Added rule.. (Equality between existen. quan. variables).
%  rewrite( (X eq Y, Rest), NewAbsRest, [tie|Theta], M ) :-
rewrite( (X eq Y, Rest), NewAbsRest, [X/Y|Theta], M ) :-
  var( X ), var( Y ),  
% X == Y,
%    ( not_occurs_in( Y, X ) -> 
%      ( NexTheta = [Y/X|Theta],
  apply_conj([X/Y], Rest, Rest2 ), % Important step..
  write_eq(" % -> equalities:  %q/%q -> \n",[X,Y]),
  rewrite( Rest2, NewAbsRest, Theta, M ).

% rule 1 and 2.
rewrite( (X eq Y, Rest), NewAbs, Theta, M ) :-
  nonvar( Y ), nonvar( X ),( compound(X); compound(Y)),
  term_unify( X, Y, TermConj, TermTheta), 
  ( TermConj == ([], true) -> 
    ( NewAbs = ([], true),
      write_eq(" % -> equalities: dropping %q eq %q -> \n",[X,Y]),
      Theta = [dropit] )
  ; ( rewrite( Rest, NextAbs, NexTheta, M ),
      write_eq(" % -> equalities: rules 1|2 on %q eq %q -> \n",[X,Y]),
      and_append( TermConj, NextAbs, NewAbs ),
      append( TermTheta, NexTheta, Theta ) ) ).

% rule 3 
rewrite( (X eq Y, Rest), NewAbsRest, Theta, M ) :-
  nonvar( Y ), nonvar( X ), atomic(X), atomic(Y), 
  ( X = Y -> 
    ( rewrite( Rest, NewAbsRest, Theta, M ),
      write_eq(" % -> equalities: rule 3 on %q eq %q -> \n",[X,Y]) )
  ; ( NewAbsRest = ([], true),
      write_eq(" % -> equalities: dropping %q eq %q -> \n",[X,Y]),
      Theta = [dropit] ) ).


% rules 4, 5 and 6, Y is the variable
rewrite( (X eq Y, Rest), NewAbsRest, NexTheta, M ) :-
  var( Y ), nonvar( X ), 
  ( not_occurs_in( Y, X ) -> 
    ( NexTheta = [Y/X|Theta],
      apply_conj([Y/X], Rest, Rest2 ), % Important step..
      ( Y sbelongs M -> 
        NewAbsRest = ( Y eq X, NARest )
      ; NewAbsRest = NARest ), % WARNING!!!
      % NewAbsRest = NARest,
      % equalities of this sort are kept.
      write_eq(" % -> equalities: rules 4|5|6 on %q eq %q -> \n",[X,Y]),
      rewrite( Rest2, NARest, Theta, M ) )
  ; ( NewAbsRest = ([],true),
      write_eq(" % -> equalities: dropping %q eq %q -> \n",[X,Y]), 
      NexTheta = [dropit] ) ).

% rules 4, 5 and 6, X is the variable
rewrite( (X eq Y, Rest), NewAbsRest, NexTheta, M ) :-
  var( X ), nonvar( Y ), 
  ( not_occurs_in( X, Y ) -> 
    ( NexTheta = [X/Y|Theta],
      apply_conj([X/Y], Rest, Rest2 ),
      ( X sbelongs M -> 
         NewAbsRest = ( Y eq X, NARest )
       ; NewAbsRest = NARest ), % WARNING!!!
      % NewAbsRest = NARest,
      % equalities of this sort are kept.
      write_eq(" % -> equalities: rules 4|5|6 on %q eq %q -> \n",[X,Y]),
      rewrite( Rest2, NARest, Theta, M ) )
  ; ( NewAbsRest = ([],true),
      write_eq(" % -> equalities: dropping %q eq %q -> \n",[X,Y]), 
      NexTheta = [dropit] ) ).


% Section for disequalities.. Only for atomics terms so far.. 
rewrite( (X lt Y, Rest), NewBodyRest, Theta, M ) :-
  atomic( X ), atomic( Y ),
  ( ( X < Y ) -> 
    rewrite( Rest, NewBodyRest, Theta, M )
  ; ( NewBodyRest = ([], true), Theta = [] ) ).


rewrite( (X le Y, Rest), NewBodyRest, Theta, M ) :-
  atomic( X ), atomic( Y ),
  ( ( X =< Y ) -> 
    rewrite( Rest, NewBodyRest, Theta, M )
  ; ( NewBodyRest = ([], true), Theta = [] ) ).


% Auxiliary clause.
rewrite( (A, Rest), NewDelta, Theta, M ) :-
  non_eq( A ), 
  rewrite( Rest, NewAbsRest, Theta, M ),
  apply_conj( Theta, (A, true), NewA ),
  and_append( NewA, NewAbsRest, NewDelta ).


/********************************************** process_conds */

process_conds( ExQVars, InImp, NextImp, OutFlag ) :-
  InImp = ( Cont :: H if Body @ HP),
  rewrite_body( ExQVars, Body, NewBody, Theta ), !,
  ( member( dropcn, Theta ) -> 
    NextImp = true
  ; apply( Theta, ( Cont :: H if NewBody @ HP, true), ( NextImp, _ ) ) ),
  ( Theta \= [] ->
    ( OutFlag = rule_applied,
      write_eq(" % -> equalities in CN rewritten -> %q \n",[NextImp]) )
  ; ( OutFlag = no_rule_applied ) ).


%  rewrite_body( ExQVars, Body, NextBody, Theta ), !,
%  rename_vars( ExQVars, H, NextBody, NH, NewBody ), 
%  ( member( dropcn, Theta ) -> 
%    NextImp = true
%  ; apply( Theta, ( Cont :: NH if NewBody @ HP, true), ( NextImp, _ ) ) ),
%  ( Theta \= [] ->
%    ( OutFlag = rule_applied,
%      write_eq(" % -> equalities in CN rewritten -> %q \n",[NextImp]) )
%  ; ( OutFlag = no_rule_applied ) ).


% notice that we still need range restriction ..
% but now we are renaming the head as well.. 

rename_vars( M, H, Body, NewH, NewBody ) :- % inefficient sol.
  collect_Ex_Vars( Body, [], VarsBody ),
  rename( M, VarsBody, RenTheta ),
  apply_conj( RenTheta, Body, NewBody ),
  apply_head( RenTheta, H, NewH ).


rename( [], _, [] ) :- !.
 
rename( [F|RestToRen], VarsBody, [V/_|RestTheta] ) :-
  F =.. [_, V, sk(L)],
  none_in( L, VarsBody ), !,
  rename( RestToRen, VarsBody, RestTheta ). 
 
rename( [_|RestToRen], VarsBody, RestTheta ) :-
  rename( RestToRen, VarsBody, RestTheta ).


none_in( [], _ ).
none_in( [F|Rest], Set ) :- not(F sbelongs Set), none_in( Rest, Set ).


/************************************************* rewrite_body */
/* rewrite_body(ExVars, InConj, OutConj, Theta)                 */

rewrite_body( _, true, true, [] ).

%  X = X is always a possibility.. 
%
rewrite_body( ExVs, (X eq Y, Rest), NewBodyRest, [done|Theta] ) :-
% rewrite_body( ExVs, (X eq Y, Rest), NewBodyRest, [tie|Theta] ) :-
  var( X ), var( Y ), X == Y, !, % I could use X = Y here
  rewrite_body( ExVs, Rest, NewBodyRest, Theta ).

% 
%
rewrite_body( ExVs, (X eq Y, Rest), NewBodyRest, [X/Y|Theta] ) :-
% rewrite_body( ExVs, (X eq Y, Rest), NewBodyRest, [tie|Theta] ) :-
  var( X ), var( Y ), 
  not( X sbelongs ExVs), not( Y sbelongs ExVs), !, % I could use X = Y here
  rewrite_body( ExVs, Rest, NewBodyRest, Theta ).

% rules 1 and 2 for CN
rewrite_body( ExVs, (X eq Y, Rest), NewBody, Theta ) :-
  nonvar( Y ), nonvar( X ), (compound(X); compound(Y)),
  term_unify( ExVs, X, Y, TermConj, TermTheta), !,
  rewrite_body( ExVs, Rest, NextBody, NexTheta ),
  and_append( TermConj, NextBody, NewBody ),
  append( TermTheta, NexTheta, Theta ).

% rule 3 
rewrite_body( ExVs, (X eq Y, Rest), NewBodyRest, Theta ) :-
  nonvar( Y ), nonvar( X ), atomic(X), atomic(Y),
  ( X = Y -> 
    ( rewrite_body( ExVs, Rest, NewBodyRest, RTheta ),
      Theta = [done|RTheta] )
  ; ( NewBodyRest = ([], true), Theta = [dropcn] ) ).

% rule 4 and rule 6 first combination.
rewrite_body( ExVs, (X eq Y, Rest), NewBodyRest, [X/Y|Theta] ) :-
  var( X ), var( Y ), not( X sbelongs ExVs), !, 
  apply_conj( [X/Y], Rest, NewRest ),                       
  rewrite_body( ExVs, NewRest, NewBodyRest, Theta ).

% rule 4 and rule 6 second combination.
rewrite_body( ExVs, (Y eq X, Rest), NewBodyRest, [X/Y|Theta] ) :-
  var( X ), var( Y ), not( X sbelongs ExVs), !, 
  apply_conj( [X/Y], Rest, NewRest ),                       
  rewrite_body( ExVs, NewRest, NewBodyRest, Theta ).

% rule 5 and rule 6.. X is the variable.
rewrite_body( ExVs, (X eq Y, Rest), NewBodyRest, NexTheta ) :-
  var( X ),
  not( X sbelongs ExVs), nonvar( Y ), 
  ( not_occurs_in( X, Y ) -> 
    ( NexTheta = [X/Y|Theta], 
      apply_conj( [X/Y], Rest, NewRest ),
      rewrite_body( ExVs, NewRest, NewBodyRest, Theta ) )
  ; ( NewBodyRest = ([],true), NexTheta = [dropcn] ) ).

% rule 5 and rule 6.. Y is the variable.
rewrite_body( ExVs, (X eq Y, Rest), NewBodyRest, NexTheta ) :-
  var( Y ),
  not( Y sbelongs ExVs), nonvar( X ), 
  ( not_occurs_in( Y, X ) -> 
    ( NexTheta = [Y/X|Theta], 
      apply_conj( [Y/X], Rest, NewRest ), 
      rewrite_body( ExVs, NewRest, NewBodyRest, Theta ) )
  ; ( NewBodyRest = ([],true), NexTheta = [dropcn] ) ).


% Section for disequalities.. Only for atomics terms so far.. 
rewrite_body( ExVs, (X lt Y, Rest), NewBodyRest, Theta ) :-
  atomic( X ), atomic( Y ),
  ( ( X < Y ) -> 
    ( rewrite_body( ExVs, Rest, NewBodyRest, RTheta ),
      Theta = [done|RTheta] )
  ; ( NewBodyRest = ([], true), Theta = [dropcn] ) ).


rewrite_body( ExVs, (X le Y, Rest), NewBodyRest, Theta ) :-
  atomic( X ), atomic( Y ),
  ( ( X =< Y ) -> 
    ( rewrite_body( ExVs, Rest, NewBodyRest, RTheta ),
      Theta = [done|RTheta] )
  ; ( NewBodyRest = ([], true), Theta = [dropcn] ) ).


% Auxiliar clause.
rewrite_body( ExVs, (A, Rest), NewDelta, Theta ) :-
  % non_eq( A ), !,  OR it exist quantif .. 
  rewrite_body( ExVs, Rest, NewAbsRest, Theta ),
  apply_conj( Theta, (A, true), NewA ),
  and_append( NewA, NewAbsRest, NewDelta ).


/****************************************************** match */
/* This routines matches non-variable terms only. So it 's a
   limited form of rewriting.. */
/* match( InConj, OutConj )                                   */
   
match( true, true ).

% Added rule.. Identity between variables.. 
match( (X eq Y, Rest),  NewRest ) :-
  var( X ), var( Y ), X == Y, !,
  write_eq(" % -> matching:  to drop  %q eq %q -> \n",[X,Y]),
  match( Rest, NewRest ).

% Added rule.. (Equality between existen. quan. variables).
match( (X eq Y, Rest), (X eq Y, NewRest) ) :-
  (var( X ); var( Y )), !,
  write_eq(" % -> matching:  %q eq %q -> \n",[X,Y]),
  match( Rest, NewRest ).

% rule 1 and 2.
match( (X eq Y, Rest), NewEqs ) :-
  nonvar( Y ), nonvar( X ),( compound(X); compound(Y) ),
  term_unify( X, Y, TermConj, TermTheta), !,
%   ( TermConj == ([], true) ->
   ( [] belongs TermConj -> 
    ( NewEqs = ([], true), !,
      write_eq(" % -> matching: to drop %q eq %q -> \n",[X,Y]) )
  ; ( match( Rest, NextAbs ),
      fromThetaToEq( TermTheta, Eq ),
      write_eq(" % -> matching: rules 1|2 on %q eq %q -> \n",[X,Y]),
      and_append( Eq, NextAbs, NewEqs ) ) ).

% rule 3 
match( (X eq Y, Rest), NewAbsRest ) :-
  nonvar( Y ), nonvar( X ), atomic(X), atomic(Y), !,
  ( X = Y -> 
    ( match( Rest, NewAbsRest ), !,
      write_eq(" % -> matching: rule 3 on %q eq %q -> \n",[X,Y]) )
  ; ( NewAbsRest = ([], true),
      write_eq(" % -> matching: to drop %q eq %q -> \n",[X,Y]) ) ).

% Examples
% match( (X eq Y, true), R ).
% match( (do(up(2), T) eq do(X, Y), true), R ).
% match( (do(down(2), T) eq do(up(2), T), true), R ).
% match( (do(down(2), T) eq do(down(Y), T), true), R ).

%
/************************************************** support routines */
/* See Sterling and Shapiro, The Art of Prolog, Page 152 */
%
not_occurs_in( X, Y ) :- var( Y ), X \== Y.
%
not_occurs_in( _, Y ) :- nonvar( Y ), atomic( Y ).
%
not_occurs_in( X, Y ) :- nonvar( Y ), compound( Y ), functor( Y, _, N ),
  not_occurs_in( N, X, Y ).
%
not_occurs_in(N, X, Y ) :-
  N > 0, arg(N, Y, Arg), not_occurs_in(X, Arg), N1 is N-1,
  not_occurs_in(N1, X, Y ).
%
not_occurs_in(0, _, _ ).
%
%
term_unify(X, Y, NewConj, Theta) :-
  functor(X, F, N), functor(Y, F, N), unify_args(N, X, Y, NewConj, Theta ).
term_unify(_, _, ([], true), [] ).  % Do not unify.
%
%
unify_args(N, X, Y, Conj, Theta ) :-
  N > 0,
  unify_arg(N, X, Y, ArgConj, ArgTheta ),
  N1 is N-1,
  unify_args(N1, X, Y, NextConj, Restheta),
  and_append( ArgConj, NextConj, Conj ),
  append( ArgTheta, Restheta, Theta ).
%
unify_args(0, _, _, true, []).
%
unify_arg(N, X, Y, Conj , Theta ) :- % Very inefficient..
  arg(N, X, ArgX), arg(N, Y, ArgY),
  rewrite( ( ArgX eq ArgY, true ), Conj, Theta, []).
%
%compound( X ) :- functor(X, _, N), N > 0.
%
% term_unify for CN..
term_unify( ExVs, X, Y, NewConj, Theta) :-
  functor(X, F, N), functor(Y, F, N),
  unify_args( ExVs, N, X, Y, NewConj, Theta ).
%
term_unify( _, _, _, ([], true), [] ).  % Do not unify.
%
unify_args( ExVs, N, X, Y, Conj, Theta ) :-
  N > 0,
  unify_arg(ExVs, N, X, Y, ArgConj, ArgTheta ),
  N1 is N-1,
  unify_args( ExVs, N1, X, Y, NextConj, Restheta),
  and_append( ArgConj, NextConj, Conj ),
  append( ArgTheta, Restheta, Theta ).
%
unify_args( _, 0, _, _, true, []).
%
unify_arg( ExVs, N, X, Y, Conj, Theta ) :-
  arg(N, X, ArgX), arg(N, Y, ArgY),
  rewrite( ExVs, ( ArgX eq ArgY, true ), Conj, Theta).
%
/*************************************************** apply */
%
apply( [], C, C ) :- !.
% apply( _, ([], R), ([], R) ) :- !.
apply( _, true, true ).
% apply( [V/_|_], _, ([], true) ) :- nonvar(V), !.
% apply( [dropit|_], C, C ) :- !.
% apply( [tie|Rest], C, R ) :- !, apply( Rest, C, R ).
% apply( [done|Rest], C, R ) :- !, apply( Rest, C, R ).
apply( Theta, (( Cont :: Conj  ), Rest ),
              (( NCont :: NConj ), NRest ) ) :- !,
  % I could introduce apply(Theta, Cont, Cont')..
  % now I have a reason to use apply_conj/3 here. 
  % It will work because the context is one atom.
  % we may need a more complex predicate later
  apply_conj( Theta, (Cont, true), (NCont, true) ), 
  ( apply_conj( Theta, Conj, NConj )
  ; apply_cond( Theta, Conj, NConj ) ), 
  apply( Theta, Rest, NRest).
% apply( Theta, ICs, NewICs ) :- apply_cond( Theta, ICs, NewICs ), !.
% apply( Theta, Conj, NewConj ) :- apply_conj( Theta, Conj, NewConj ).

%
% Repeating for efficiency's sake.
apply_cond( [], C, C ) :- !.
apply_cond( _, ([], R), ([], R) ) :- !.
apply_cond( _, true, true ).
% apply( [V/_|_], _, ([], true) ) :- nonvar(V), !.
apply_cond( [dropit|_], C, C ) :- !.
apply_cond( [tie|Rest], C, R ) :- !, apply_cond( Rest, C, R ).
apply_cond( [done|Rest], C, R ) :- !, apply_cond( Rest, C, R ).
% apply_cond( [], Cond, Cond ) :- !.
apply_cond( Theta, Head if Cond @ HP, NewHead if NewCond @ HP ) :- 
  apply_head( Theta, Head, NewHead ),
  apply_conj( Theta, Cond, NewCond ).

%
%
apply_conj( [], C, C ) :- !.
apply_conj( _, ([], R), ([], R) ) :- !.
apply_conj( _, true, true ).
% apply( [V/_|_], _, ([], true) ) :- nonvar(V), !.
apply_conj( [dropit|_], C, C ) :- !.
apply_conj( [tie|Rest], C, R ) :- !, apply_conj( Rest, C, R ).
apply_conj( [done|Rest], C, R ) :- !, apply_conj( Rest, C, R ).
apply_conj( [], Conj, Conj ) :- !.
apply_conj( [V/T|Rest], Conjunct,  NewConj ) :-
  substitute_conj( V, T, Conjunct, NextConj ),
  apply_conj( Rest, NextConj, NewConj ).

%
apply_head( [], H, H ) :- !.
apply_head( _, ([], R), ([], R) ) :- !.
apply_head( _, true, true ) :- !.
apply_head( [dropit|_], C, C ) :- !.
apply_head( [tie|Rest], C, R ) :- !, apply_head( Rest, C, R ).
apply_head( [done|Rest], C, R ) :- !, apply_head( Rest, C, R ).
apply_head( [V/T|Rest], H, FH ) :- !,
  subst_head( V, T, H, NH ), apply_head( Rest, NH, FH ).

%
apply_hp( Theta, HP, NHP ) :- apply_head( Theta, HP, NHP ).

%
%
/*************************************************** substitute */
% The set of routines to apply a substitution to a set of terms..
%
subst_head( _, _, [], [] ) :- !.
subst_head( V, T, [C|R], [NC|NR] ) :-
  substitute( V, T, C, NC ),
  subst_head( V, T, R, NR ).

%
%
% substitute_cond( _, _, true, true ) :- !.
% substitute_cond( V, T, (Head if Cond, RestCn), (NewH if NewC, NRestCn) ) :-
%   subst_head( V, T, Head, NewH ),
%   apply_conj( [V/T], Cond, NewC ), 
%   substitute_cond( V, T, RestCn, NRestCn ).
%

%
substitute_conj( _, _, true, true ) :- !.
substitute_conj( V, T, (G, Rest), (NewG, NewRest ) ) :-
  substitute( V, T, G, NewG ),
  substitute_conj( V, T, Rest, NewRest ).
%
%
substitute( V, T, Pred, NewPred ) :-
  Pred =.. [Name|Args],
  substitute_args( V, T, Args, NewArgs ),
  NewPred =.. [Name|NewArgs].
%
%
substitute_args( _, _, [], [] ).
substitute_args( V, T, [A|Rest], [T|NRest] ) :-
  V == A, !, 
  substitute_args( V, T, Rest, NRest ).
substitute_args( V, T, [A|Rest], [NewA|NRest] ) :- % complex atoms.
  compound( A ), !,
  substitute( V, T, A, NewA ),
  substitute_args( V, T, Rest, NRest ).
substitute_args( V, T, [A|Rest], [A|NRest] ) :-
  V \== A, 
  substitute_args( V, T, Rest, NRest ).

/*********************************************** collect_Ex_Vars */
% Collect existentially quantified variables..

collect_Ex_Vars( true, Vs, Vs ) :- !.
collect_Ex_Vars( ( _ :: Conj, Rest), Ivs, Ovs ) :-
  collect_Ex_Vars( Conj, Ivs, Nvs ), !,
  collect_Ex_Vars( Rest, Nvs, Ovs ). 
collect_Ex_Vars( (Pred, Rest), Ivs, Ovs ) :-
  Pred =.. [_|Args],
  collect_Vars_in_Args( Args, Ivs, Nvs ),
  collect_Ex_Vars( Rest, Nvs, Ovs ).


collect_Vars_in_Args( [], Vs, Vs ).
collect_Vars_in_Args( [A1|RestA], IVs, NVs ) :-
  var( A1 ), not( A1 sbelongs IVs), !,
  collect_Vars_in_Args( RestA, [A1|IVs], NVs ).
collect_Vars_in_Args( [C1|RestA], IVs, NVs ) :-
  compound( C1 ), !, 
  collect_Ex_Vars( (C1, true), IVs, Vs ), 
  collect_Vars_in_Args( RestA, Vs, NVs ).
collect_Vars_in_Args( [_|RestA], RestV, NVs ) :-
  collect_Vars_in_Args( RestA, RestV, NVs ).


/*************** ***************************** collect_Ini_Ex_Vars */

collect_Init_Ex_Vars( [], [] ) :- !.
collect_Init_Ex_Vars( [F|R], [V|NR] ) :-
  F = (V = sk(_)), !,
  collect_Init_Ex_Vars( R, NR ).
collect_Init_Ex_Vars( [_|R], NR ) :-
  collect_Init_Ex_Vars( R, NR ).

% 
/**************************************************** more tools */

non_eq( A ) :- A \= _ eq _.

equality( A ) :- A=.. [eq|_].

inequality( A ) :-  A=..[lt|_].

disequality( A ) :- A=..[lt|_]; A=..[le|_].


createscheme( Predicate, PredicateScheme) :-
  Predicate =.. [Predicatename|Arguments],
  duplicate_struct(Arguments, NewArg),
  PredicateScheme =.. [Predicatename|NewArg].
  
%
duplicate_struct( [], [] ).

duplicate_struct([_|R], [_|CR]) :-
  duplicate_struct(R, CR).


% unpack_eq( Pt, todo(_,Ps), FinalT_eq_S ) :-
unpack_eq( Pt, Ps, FinalT_eq_S ) :-
  Pt =.. [P|T],
  Ps =.. [P|S],
  build_eq( T, S, T_eq_S ),
  match( T_eq_S, FinalT_eq_S ), !.

%
unpack_all_eq( _, [], [], [] ).

unpack_all_eq( G, [Gs|Rest], [T_eq_S|D], FinalAll ) :-
  unpack_eq( G, Gs, T_eq_S ),
  ( T_eq_S = ([], true) -> 
    FinalAll = RestA
  ; FinalAll = [Gs|RestA]  ),  
  unpack_all_eq( G, Rest, D, RestA ).
  
%
build_eq( [], [], true ).
build_eq( [T1|RT], [S1|RS], (T1 eq S1, Rest) ) :-
  build_eq( RT, RS, Rest ).

%
fromThetaToEq( [], true ).

fromThetaToEq( [X/Y|Rest], (X eq Y, RestE) ) :- !,
  fromThetaToEq( Rest, RestE ).

fromThetaToEq( [_|Rest], RestE ) :- !,
  fromThetaToEq( Rest, RestE ).


/******************************************************** collectM */
% collectM( Marked, VarsInImp, Renaming, NewMarked, NewVars )

collectM( [], _,  [], [], [] ) :- !.
collectM( [F|R], VarsInImp, [V/NV|TR], [F, NV=sk(L)|MR], [NV|RV] ) :-
  F = (V=sk(L)), 
  V sbelongs VarsInImp, !,
  collectM( R, VarsInImp, TR, MR, RV ).
collectM( [F|R], Vars, TR, [F|MR], RV ) :- 
  collectM( R, Vars, TR, MR, RV ).


/********************************************************* tests */
teq01 :- process_conds( [A], ( test :: [] if (A eq a, f(A), true) @ [] ), _, _ ).
teq02 :- process_conds( [], ( test :: [] if (a eq B, _ eq B, f(B), true) @ [] ), _, _).
teq03 :- process_conds( [], ( test :: [] if (_ eq B, a eq B, f(B), true) @ [] ), _, _).
teq04 :- process_conds( [], ( test :: [q(B)] if (_ eq B, a eq B, f(B), true) @ [] ), _, _).















