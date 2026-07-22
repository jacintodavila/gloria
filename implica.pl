/*  $Id: gloria.pl,v 1.0.1 2006/06/25 10:00:00 jacinto $

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


/* implica.pl
 
  It includes the procedures to process implications. 
 
*/

/******************************************************** submodules */
%
% see gloria.pl header

/*************************************************************** operators */
%
% See auxilia.pl.

:- dynamic sus/1, unf/1.

/********************************************************** demo_impl_ruc */
  
demo_impl(_, _, _, _, [] , [] ) :- !.

demo_impl(_, 0, _, _, In , In ) :- !,
  % writef("\n DEMO_IMPL: Stopping thinking. No more resources \n",[]),
  write_last( In ).

% No rule applied since last call 
%
demo_impl(_, _, no_ru_uc, no_ru_cn, InGoals, InGoals ) :- !,
  write_last( InGoals ).

demo_impl(Ag, R0, FlagUC, _, InGoals, OutGoals ) :-
  InGoals = [[Delta, UC, CN, HF, M]|AltGoals],
  collect_Init_Ex_Vars( M, Var0 ),
  collect_Ex_Vars( Delta, Var0, Var1 ), % <- Notice the use of M
  collect_Ex_Vars( UC, Var1, ExQVars ),
  demo_each_impl(Ag, R0, ExQVars, Delta, CN, true, NewCN, Rf, M, M1, NExQVars ),
  ( case_analysis( NExQVars, Delta, NewCN, Cont_Eq, NewCN1, NewCN2 ) -> 
    ( NextGoals = [[Delta, (Cont_Eq, UC), NewCN1, HF, M1],
                   [Delta, UC, NewCN2, HF, M1]|AltGoals], !,
      demo(Ag, Rf, ru_uc, ru_cn, NextGoals, OutGoals ) ) % back to demo..
  ; ( promotion( NExQVars, NewCN, Head, NextCN ) ->
      (  [[Delta,(Head, UC), NextCN, HF, M1]|AltGoals] equiv NextGoals0,!,
         % writef(" DEMO_IMPL: Goal %q activated!!! in plan \n",[Head]),
         % ( NextGoals0 = [F|_] -> write_frontier([F]); true ),
         priority_order_FirstP( Head, NextGoals0, NextGoals ),
	 % ( NextGoals = [F|_] -> write_frontier([F]); true ),
	 demo(Ag, Rf, ru_uc, ru_cn, NextGoals, OutGoals ) ) % back to demo..
    ; (  NextGoals = [[Delta, UC, NewCN, HF, M1]|AltGoals],
         demo(Ag, Rf, FlagUC, no_ru_cn, NextGoals, OutGoals ) ) ) ).


/******************************************************* demo_each_impl */
/* process each implication until one is found to be suitable for
   case analysis or promotion, in which case processing is 
   interrupted to apply those rules. Otherwise, processing continues
   until the last implication has been reduced by the other rules of
   the proof procedure.

   With resource counting, processing may stop when InR hits 0.

   demo_each_impl(Agent, InR, ExVars, Delta, InputCN, Auxiliar_Param,
	           Last_Imp_Proccessed, RestofImp, OutR)
*/

demo_each_impl(_, R, E, _, true, OutImp, OutImp, R, M, M, E ) :- !.

demo_each_impl(_, 0, E, _, InImp, PreImp, OutImp, 0, M, M, E ) :- !,
   and_append( PreImp, InImp, OutImp ).

demo_each_impl(Ag, R, ExVars, Delta, Input, Previous, OutImps, Rf, M, MF, NE ) :-
  Input = (Imp, Rest),
  demo_one_cond(Ag, ExVars, Delta, Imp, NewImp, Flag, M, M1, NExVars ),
  NR is R - 1,
  ( suitable_for_case_analysis_or_promotion( NExVars, Delta, NewImp ) -> % if
    ( and_append( Previous, Rest, RestImp ),                      % then
      and_append( NewImp, RestImp, OutImps ), !, 
      Rf = NR, MF = M1, NE = NExVars )
  ; ( suitable_for_deletion( NewImp ) ->                          % else if
      ( demo_each_impl(Ag, NR, NExVars, Delta, Rest, Previous,
                        OutImps, Rf, M1, MF, NE ), !)
    ; ( suitable_for_splitting( NewImp ) ->                       % else if
        ( NewImp equiv NextImplications,   
          and_append( NextImplications, Rest, NewRest),
          demo_each_impl(Ag, NR, NExVars, Delta, NewRest,
                          Previous, OutImps, Rf, M1, MF, NE ), ! )
      ; ( Flag = rule_applied ->                                  % else if
          ( and_append( NewImp, Rest, NewRest ), 
            demo_each_impl(Ag, NR, NExVars, Delta, NewRest,
                            Previous, OutImps, Rf, M1, MF, NE ) )
        ; ( and_append( Previous, NewImp, NewPrevious),           % else 
            demo_each_impl(Ag, NR, NExVars, Delta, Rest,
                          NewPrevious, OutImps, Rf, M1, MF, NE ) ) 
        ) 
      ) 
    ) 
  ).

/********************************************************* suitable_for.. */

suitable_for_case_analysis_or_promotion( ExVars, Delta, NewImp ) :-
  suitable_for_case_analysis( ExVars, Delta, NewImp ) 
  ; suitable_for_promotion( ExVars, NewImp ).

suitable_for_case_analysis( ExVars, _, ( _ :: H if ( X eq T , _) @ _, _ ) ) :-
  var(X), X sbelongs ExVars, 
  ( atomic( T ) ; ( compound( T ), not_occurs_in( X, T ) ) ),   
  no_contain_Un_Vars( ExVars, H ), !, 
  write_ir(" % -> suitable for case analysis on %w eq %w -> \n",[X,T]).  
  % The last condition can be relaxed using sk(L)...
 
suitable_for_case_analysis( ExVars, _, 
                            ( _ :: _ if ( X lt T , _) @ _, _ ) ) :-
  ground(X), var(T), not( T sbelongs ExVars).
%  not contains_Var( T, Delta ). 
%  not ( X lt T ) sbelongs HP. 
%  T sbelongs ExVars, not contains_Var( T, Delta ). 

suitable_for_equality_treatment( ( _ ::  _ if ( _ eq _ , _) @ _, _ ) ).

suitable_for_promotion( ExVars, ( _ :: H if true @ _, _ ) ) :-
  no_contain_Un_Vars( ExVars, H ).

suitable_for_deletion( ( _ :: _ if ( [] , _) @ _, _ ) ). 

suitable_for_splitting( ( _ :: _ if ( [_|_] , _) @ _, _ ) ). 

suitable_for_further_processing( _, ( _ :: _ if ( G , _) @ _, _ ) ) :-
  ( unfoldable( G ) 
  ; builtin( G )
  ; G = not(_) 
  ; ( inequality( G ), ground( G ) )
  ; valid_ineq( G ) 
  ), !. 

/**************************************************************** before */
% Is X before Y in Delta

% before( X, Y, _ ) :- 
%  ground( X ), var( Y ), now( N ), X =< N, !. % Very useful heuristic

% before( X, Y, Delta ) :-
%   ( contains_Var( X, Delta )
%  ; contains_Var( Y, Delta ) ),
%   rbefore( X, Y, Delta ).

% Both are variables in Delta

before( X, Y, Delta ) :-
  contains_Var(X, Delta), contains_Var(Y, Delta), !, rbefore(X,Y,Delta).

% X is a constant and Y is a variable in Delta

before( X, Y, Delta ) :-
  nonvar(X), contains_Var(Y, Delta),  
  lower_in_Delta( C, Delta), 
  X < C, !.

% X is a variable in Delta and Y is a constant 

before( X, Y, Delta ) :-  
  contains_Var(X, Delta), nonvar(Y),
  upper_in_Delta( C, Delta ),
  C < Y, !.


rbefore( X, Y, Delta ) :-
  ( strict_in( X lt Y, Delta ) 
  ; strict_in( do(_,X,Y), Delta ) ), !. 

rbefore( X, Y, Delta ) :-
  precedes( X, Z, Delta ), rbefore( Z, Y, Delta ).


precedes( X, Z, ( A, _ ) ) :-
  ( A = ( X1 lt Z ) 
  ; A = do( _, X1, Z ) ),
  X == X1, X \== Z, !.     % Note the extra-cond. X\==Z.

precedes(  X, Z, ( _, Rest ) ) :-
  precedes( X, Z, Rest ).

strict_in( A1, ( E1, _ ) ) :-
  A1 =.. [Pred, X, Y],
  E1 =.. [Pred, X1, Y1],
  X == X1, Y == Y1, !.

strict_in( do(_, X, Y), ( do(_, X1, Y1), _ ) ) :-
  X == X1, Y == Y1, !.

strict_in( Ine, ( _, Rest ) ) :-
  strict_in( Ine, Rest ).


lower_in_Delta( _, true ) :-  !, fail.

lower_in_Delta( C, ( C lt _, _ ) ) :- nonvar(C), !.

lower_in_Delta( C, ( _, Rest ) ) :- !, lower_in_Delta( C, Rest ).

upper_in_Delta( _, true ) :-  !, fail.

upper_in_Delta( C, ( _ lt C, _ ) ) :- nonvar(C), !.

upper_in_Delta( C, ( _, Rest ) ):- !, upper_in_Delta( C, Rest ).
                 

contains_Var( X, Delta ) :-
  collect_Ex_Vars( Delta, [], VarsinDelta ),
  X sbelongs VarsinDelta.

/********************************************************* demo_one_cond */
/* demo_one_cond( Exist Vars in UC, Delta, OneImplic, ListOfImpls
                  InitialVars, NewInitialVars, New Exist Vars ) */

demo_one_cond(_, E, _, true, true, no_rule_applied, M, M, E ) :- !.

demo_one_cond(_, E, _, InImp, (InImp, true), rule_applied, M, M, E ) :-
  InImp = ( _ ::  _ if ([], _) @ _), !.

demo_one_cond(_, ExVars, _, InImp, OutImp, DFlag, M, M, ExVars ) :-
  InImp = ( _ ::  _ if (G, _) @ _ ),
  equality( G ), !,
  process_conds( ExVars, InImp, NextImp, DFlag ), 
  OutImp = ( NextImp, true).
  %writef(" demo one cond %q \n     to %q\n", [InImp, OutImp]).

demo_one_cond(_, ExVars, _, InImp, OutImp, DFlag, M, M, ExVars ) :-
  InImp = ( _ ::  _ if (G, _) @ _ ),
  inequality( G ), ground( G ), !, 
  process_conds( ExVars, InImp, NextImp, DFlag ), 
  OutImp = ( NextImp, true).

demo_one_cond(Ag, ExVars, Delta, InImp, OutImp, rule_applied, M, MF, ExVars ) :-
  InImp = ( Cont :: H if (G, Rest) @ HP ), 
  valid_ineq( Delta, G ), !,
  NewImp = ( Cont :: H if Rest @ HP ),
  demo_one_cond(Ag, ExVars, Delta, NewImp, OutImp, _, M, MF, ExVars ).

demo_one_cond(Ag, ExVars, Delta, InImp, OutImp, rule_applied, M, MF, ExVars ) :-
  InImp = ( Cont :: H if (G, Rest) @ HP ), 
  G \= not(_),
  builtin( G ), !,
  ( G -> 
    NewImp = ( Cont :: H if Rest @ HP )
  ; NewImp = ( Cont :: H if ([], Rest) @ [] ) ),
  demo_one_cond(Ag, ExVars, Delta, NewImp, OutImp, _, M, MF, ExVars ).

% if it is a negative atom..
demo_one_cond(Ag, ExVars, Delta, InImp, OutImp, rule_applied, M, MF, ExVars ) :-
  InImp = ( Cont :: H if (G, Rest) @ HP ),
  G = not(L), !, 
  append( H, [L], NewH),
  NewImp = ( Cont :: NewH if Rest @ HP ),
  demo_one_cond(Ag, ExVars, Delta, NewImp, OutImp, _, M, MF, ExVars ).

% Unfolding and splitting..
demo_one_cond(Ag, E, Delta, InImp, OutImp, rule_applied, M, M, E ) :-
  InImp = ( Cont :: H if (G, Rest) @ HP ), 
  unfoldable( G ), !,
  write_ir(" % -> unfold in CN -> %q \n",[G]),
  definition(Ag, Delta, G, D ),
  ( Cont :: H if (D, Rest) @ HP, true) equiv OutImp.

% inverse multiple propagation..
demo_one_cond(_, E, Delta, InImp, OutImp, rule_applied, M, MF, NE ) :-
  InImp = ( _ ::  _ if (G, _) @ _ ),
  suspendable( G ),
  propagation( Delta, InImp, OutImp, M, MF, NEqV ), !,
  %writef("  % -> Inverse multiple propagation on -> %q \n",[G]),
  %writef("  % -> que produce -> %q \n",[OutImp]),
  append( NEqV, E, NE ). 

% no rule was applied..
demo_one_cond(_, E, _, InImp, (InImp, true), no_rule_applied, M, M, E ).


/************************************************************** valid_ineq */

valid_ineq( Delta, G ) :-
  inequality( G ), not(ground( G )),
  G = ( X lt Y ),
  before( X, Y, Delta ).
   
/*********************************************************** case_analysis */
/* case_analysis( ExQVars,  Delta, Input, Eq, CN1, CN2 )                   */

case_analysis( ExQVars, _, ( Cont :: H if (X eq T, Rest) @ HP, CNRest), 
               ( Cont :: ( X eq T, true ) ),  % <- could be better.. 
	       ( Cont :: H if Rest @ HP, CNRest), 
               ( Cont :: [] if (X eq T, true) @ [], CNRest) ) :-
  not(Rest = true),
  var( X ), X sbelongs ExQVars, !, 
  ( atomic( T ) ; ( compound( T ), not_occurs_in( X, T ) ) ),
  no_contain_Un_Vars( ExQVars, H ).
  %writef(" % -> case analysis on %w eq %w -> \n",[X,T]).

% This is a special rule to be used on inequalities
case_analysis( ExQVars, _, ( Cont :: H if (X lt T, Rest) @ HP, CNRest), 
               ( Cont :: ( X lt NT, true ) ),  
	       ( Cont :: H if (T eq NT, Rest) @ NextHP, CNRest),
               CNRest ) :-
  ground(X), var(T), not(T sbelongs ExQVars), % Only for univ. quant. var.
%  unpack_all_eq( X lt T, [X lt NT], D, _ ),
  check_his( HP, [(T eq NT, true)], NextHP, FinalD, y ),
  FinalD \== [], !.   %  like in propagation.. 


%   not contains_Var( T, Delta ),  
%  not  ( X lt T ) sbelongs HP,
%   T sbelongs ExQVars. % Important constraint


% As it was before..
% case_analysis( _, _, ( Cont :: H if (X lt T, Rest) @ HP, CNRest), 
%                ( Cont :: ( X lt Z, true ) ),  % <- could be better.. 
% 	       NewCNRest,
%                CNRest, M, MF ) :-
%   ground(X), var(T), now(N), X =< N, 
%   not  ( X lt T ) sbelongs HP,
%   propagation( (X lt Z, true), ( Cont :: H if (X lt T, Rest) @ HP ),
% 	       NewImp, M, MF ),
%   and_append( NewImp, CNRest, NewCNRest ).


/*************************************************************** promotion */
/* promotion( ExQVars, LastImplProc, Head )                                */

promotion( ExQVars, ( Cont :: H if true @ _, Rest) , 
	            ( Cont :: (H, true) ), Rest ) :- 
  no_contain_Un_Vars( ExQVars, H ).

/************************************************************* propagation */

propagation( Delta, InImp, OutImps, M, M, [] ):-
  InImp = ( Cont :: H if (G, Rest) @ HP ),
%  suspendable( G ),                       % tested outside..
  ground( G ), !,  % This is because we keep some abd. in PROLOG' DB
  % ( ( clause( G, _ ) ; todo(_,G) belongs Delta ) ->
  %  ( OutImps = ( Cont :: H if Rest @ HP , true),
  %    write_ir(" % -> propagating ground %q  -> \n",[G]) )
  %; OutImps = InImp ). % It's wrong!
  ( clause( G, _ ) ; todo(_,G) belongs Delta ), % either is clause or an abd.
  OutImps = ( Cont :: H if Rest @ HP , true).
  %writef(" % -> propagating ground %q  -> \n",[G]).


% propagation( Delta, InImp, OutImps, M, M, [] ):-
%   InImp = ( Cont :: H if (G, Rest) @ HP ),
%  suspendable( G ),                       % tested outside..
%   not ground( G ),
%   scontain( Delta, G ), !,
%   OutImps = ( Cont :: H if Rest @ HP , true),
%   write_ir(" % -> propagating %q  -> \n",[G]).

propagation( Delta, InImp, OutImps, M, NewM, NVars ) :-
  InImp = ( Cont :: H if (G, Rest) @ HP ),
%  writef(" Intentando propagar por %q\n", [G]), 
  not(ground( G )),
  not(scontain( Delta, todo(_,G) )), !,   % eliminated for efficiency's sake
%  writef(" Attempt for prop. %q and %q\n",[Delta,G]),
%  suspendable( G ),           % tested outside..
  findalldb( G, HP, LKb ),     % get those in KB. Not really using HP
  findallabs( G, Delta, HP, LAb, Pred ),   % get those in Abds. "
  append( LKb, LAb, AllCand ),
  AllCand \== [], !,               % First test.. There are new candidates.
  collect_Vars_in_Args( H, [], Vars0 ),          % Preparing for renaming
  collect_Ex_Vars( (G, Rest), Vars0, VarsImp ),  % Preparing for renaming
  collectM(M, VarsImp, ThetaM, NewM, NVars ),    % Preparing for renaming 
  apply_conj( ThetaM, (G, Rest), (MG, MRest) ),  % Rename body and G
  apply_head( ThetaM, H, MH ),        % Rename Head
  apply_hp( ThetaM, HP, MHP ),        % Rename previous history of propagation
  unpack_all_eq( MG, AllCand, D, _ ),
  check_his( MHP, D, NextHP, FinalD ),
  FinalD \== [], !,                   %  Secnd. test.. At least one is good.
  add_pre( Pred, NextHP, NewHP ),  % the predica. also goes to HP if not there
  % append(ForHP, MHP, NewHP),  % Beware!.. 
%  write_ir(" % -> propagating %q through %q -> \n",[FinalD, G]),
%  writef(" Previous HP %q - New HP %q \n", [HP, MHP]),
%  writef(" % => New Variables and dependencies %q - %q -> \n",[NewM, NVars]),  
  ( Cont ::  MH if (FinalD, MRest) @ MHP, Cont :: H if (G, Rest) @ NewHP, true ) equiv OutImps.
%   ( Cont ::  MH if (FinalD, MRest) @ MHP, true) equiv OutImps. % It's wrong, just for testing
%  writef(" Propagacion exitosa resulta en %q in", [OutImps]).


add_pre( Pred, H0, HF ) :-
  ( not(sbelongs(Pred, H0)) ->
    append( [Pred], H0, HF )
  ; HF = H0 ).

findalldb( G, HP, L ) :-
  createscheme( G, Ghole ),
  findall( Ghole, ( clause( Ghole, true ), not(sbelongs( Ghole, HP )) ), L ). 

% findallabs( G, Delta, HP, L, Pred ) :-
findallabs( G, Delta, HP, L, G ) :-
  G =.. [Pred|Args],
  ( ( Args == [], member( G, HP ) ) ->
%  ( G sbelongs HP ->  % this is not supposed to prevent propagation
    ( L = [], ! )   % In the prop. case. if the pred. is there it should fail
  ; pickall( Pred, Args, Delta, L ) ).

pickall( _,  _, true, [] ) :- !.
pickall( Pred, Args1, (Gdata, Rest), [Grdata|NRest] ) :-
  Gdata = todo(_,Grdata), 
  Grdata =.. [Pred|_], !,
%  unifiable( Args1, Args2 ), !,
  pickall( Pred, Args1, Rest, NRest ).
pickall( Pred, Args1, (_, Rest), NRest ) :-
  pickall( Pred, Args1, Rest, NRest ).


unifiable( [], [] ) :- !.
unifiable( [F1|Rest1], [F2|Rest2] ) :-
  (var(F1); var(F2)), !,
  unifiable( Rest1, Rest2 ).
unifiable( [F1|Rest1], [F2|Rest2] ) :- 
  atomic( F1 ), atomic( F2 ), F1 = F2, !,
  unifiable( Rest1, Rest2 ).
unifiable( [F1|Rest1], [F2|Rest2] ) :- 
  compound( F1 ), compound( F2 ), 
  F1 =.. [Pred|ArgF1],
  F2 =.. [Pred|ArgF2],
  unifiable( ArgF1, ArgF2 ),
  unifiable( Rest1, Rest2 ).
  

check_his( H, [], H, [] ) :- !.

check_his( H, [D1|DRest], NewH, [D1|NextD] ) :-
  check_eq( H, D1, ToH, y ),
  check_his( H, DRest,  NextH, NextD ),
  append( ToH, NextH, NewH ).

check_his( H, [_|Rest], NewH, NewD ) :-
  check_his( H, Rest, NewH, NewD ).

% rewritten, January 2007, to correct bug
% if the actual conjunction of equalities does not appear
% in the History of Propagation, it must be used. 
% previous version only checked one equality. 
check_eq( _, true, [], n ) :- !.

check_eq( _, ([], true), _, n ) :-  fail, !.

check_eq( H, (Eq, RestEqs), [Eq|NextEqs], y ) :-
  Eq = _ eq _, 
  not(is_in_list( Eq, H )),
  check_eq( H, RestEqs, NextEqs, _ ).

check_eq( H, (Eq, RestEqs), [Eq|NextEqs], T ) :-
  Eq = _ eq _,
  check_eq(H, RestEqs, NextEqs, T ). 

% keeping the old version for other uses (factoring)
check_eq( _, true, []) :- !.

check_eq( _, ([], true), _ ) :-  fail, !.

check_eq( H, (Eq, RestEqs), [Eq|NextEqs] ) :-
  Eq = _ eq _, 
  not(is_in_list( Eq, H )),
  check_eq( H, RestEqs, NextEqs ).

% check_eq( H, (Eq, RestEqs), [Eq|NextEqs], T ) :-
%   Eq = _ eq _,
%   check_eq(H, RestEqs, NextEqs, T ). 

% check_eq(H, Eqs, []) :- all_in_list(H, Eqs). % , fail, !. 

% check_eq(H, Eqs, FEqs) :- filter_eq(H, Eqs, FEqs).

filter_eq(_, true, []) :- !. 
filter_eq(H, (Eq, R), RR) :-
   is_in_list(Eq, H), !, 
   filter_eq(R, RR). 
filter_eq(H, (Eq, R), [Eq|RR]) :-
   filter_eq(H, R, RR). 

all_in_list(_, true).
all_in_list(H, (Eq, R) ) :-
   is_in_list(Eq, H),
   all_in_list(H, R). 

is_in_list( (X eq T), [ThisEq|_] ) :- (X eq T) == ThisEq, !.
is_in_list( (X eq T), [ThisEq|_] ) :- (T eq X) == ThisEq, !.
is_in_list( Eq, [_|Rest] ) :- is_in_list( Eq, Rest ).


% tests
% propagation( (on(3,1), true), t :: [(serve(G4, G1, G6), G8 lt G1, true)] if (on(G4, G8), true) @ [], NCN ).
% propagation( (on(3,1), true), p :: [(serve(G4, G1, G6), G8 lt G1, true)] if (on(G4, G8), true) @ [G4 eq 3,G8 eq 1], NCN ).
% propagation( (on(4,2), true), t :: [(serve(G4, G1, G6), G8 lt G1, true)] if (on(G4, G8), true) @ [G4 eq 3,G8 eq 1], NCN ). 

% propagation( (on(3,1), true), t :: [(serve(G4, G1, G6), G8 lt G1, true)] if (on(G4, G8), true) @ [], NCN, [G1=sk([G4, G8]), G6=sk([G4, G8])], NM ).
% propagation( (on(3,1), true), p :: [(serve(G4, G1, G6), G8 lt G1, true)] if (on(G4, G8), true) @ [G4 eq 3,G8 eq 1], NCN, [G1=sk([G4, G8]), G6=sk([G4, G8])], NM ).
% propagation( (on(4,2), true), t :: [(serve(G4, G1, G6), G8 lt G1, true)] if (on(G4, G8), true) @ [G4 eq 3,G8 eq 1], NCN, [G1=sk([G4, G8]), G6=sk([G4, G8])], NM ). 





%%% ---------------------------------------------- end of file implica.pl %%%


