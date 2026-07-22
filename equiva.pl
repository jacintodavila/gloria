/*  $Id: equiva.pl,v 1.0.1 2006/06/25 10:00:00 jacinto $

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


/* equiva.pl

   Equivalence relation for the iff proof procedure. 
   
*/

/************************************************************** modules */

% :- [auxilia]. % See gloria.pl

/******************************************************* if and only if */

% base conditions

[] equiv [] :- !.

[ [Delta,( _ :: true, UCR ), CN, HF, M] |AltGoals] equiv
  [ [Delta, UCR, CN, HF, M] |AltGoals] :- !.

[ [_,( _ :: ([], _), _), _, _, _] |AltGoals] equiv AltGoals :- !.

[ [_,( _ :: ( ([], _), _ ), _ ), _, _, _] |AltGoals] equiv AltGoals :- !.

% Splitting in UC
% 
% [ [Delta, ( ( Cont :: [D1|DRest], Rest), RestUC ), CN, HF, M] |AltG] equiv 
%   [NewHead|NewAltG] :-
%   [Delta, ( ( Cont :: D1, Rest), RestUC ), CN, HF, M] equiv NewHead,
%   [ [Delta, ( ( Cont :: DRest, Rest), RestUC ), CN, HF,M] |AltG] equiv NewAlt% G, !.

[ [Delta, ( Cont :: ([D1|DRest], Rest), RestUC ), CN, HF, M] |AltG] equiv 
  [NewHead|NewAltG] :-
  and_append( D1, Rest, NewD1Rest ),
  [Delta, ( Cont :: NewD1Rest, RestUC ), CN, HF, M] equiv NewHead,
  [ [Delta, ( Cont :: (DRest, Rest), RestUC ), CN, HF,M] |AltG] equiv NewAltG, !.

% Base case of [[_|_]|_] equiv L.

[ FirstG|AltG] equiv [ NewFirstG|AltG] :- FirstG equiv NewFirstG, !.  

% Splitting in UC

[Delta, ( Cont :: ( D1, Rest ), RestUC ), CN, HF, M] equiv
  [Delta, ( Cont :: FlatConjunct, RestUC ), NewCN, HF, M] :- 
  (D1, Rest) old_equiv FlatConjunct,
  CN cn_equiv NewCN, !. % <- this test could be ignore perhaps..

% Observe that I 'm including in the clause above a second test
% which could be avoided.. 

% Base case of [_|_] equiv L.

[Delta, UC, CN, HF, M] equiv [Delta, NewUC, NewCN, HF, M] :- 
  UC old_equiv NewUC,
  CN cn_equiv NewCN, !.

% Equivalence between terms which are not lists.

A equiv B :- A cn_equiv B, !.  % Note that this must go before that old_equiv

% or should be supported with a test to guarantee that A and B are
% implications, otherwise one gets the wrong results..
  
A equiv B :- A old_equiv B.


/************************************************************** cn_equiv */

true cn_equiv true :- !.

( _ :: _ if ([], _) @ _, Rest) cn_equiv Rest.

( Cont :: H if ([D], Rest) @ HP, CNRest ) cn_equiv (NewFirstCN, CNRest ) :-
  and_append( D, Rest, NewBody ),
  NewFirstCN = ( Cont :: H if NewBody @ HP ).

( Cont :: H if ([D1|D2], Rest) @ HP, CNRest ) cn_equiv (NewFirstCN, NewCNRest) :-
  and_append( D1, Rest, NewBody ),
  NewFirstCN = ( Cont :: H if NewBody @ HP ),
  ( Cont :: H if (D2, Rest) @ HP, CNRest ) cn_equiv NewCNRest.

A cn_equiv B :- A old_equiv B.
  

/************************************************************ old_equiv */

true old_equiv true :- !.

(_ :: true, Rest) old_equiv NewRest :- !,
  Rest old_equiv NewRest.
  
(true, Rest) old_equiv NewRest :- !,
  Rest old_equiv NewRest.

((C1, C2), Rest) old_equiv NewHead :-
  (C2, Rest) old_equiv NewRest, !,
  NewHead = (C1, NewRest).

(G, Rest) old_equiv (G, Rest) :- singleatom( G ).

  
/**************************************************************** tools */
    
%
singleatom( G ) :- not(G =@= (_,_)).


%
no_contain_Un_Vars( ExV, D1 ) :-
  collect_Ex_Vars( (D1, true), [], VarsinD1 ),
  subset_( VarsinD1, ExV ).
 
%
/**************************************************************** test */
te01 :- [[true, ((test :: [(a,true), (b,true)], z, true), true), true, [], []]] equiv _.
te02 :- [[true, true, ((test :: [a, b] if (c,true), z, true), true), [], [] ]] equiv _.
%te03 :- ((test :: a if ([(not b, c, true), (d, not e, true)], f, true) ) @ [], g, true) equiv _.

%te04 :- ( ( test :: h if ([(not b, c, true), (d, not e, true)], f, true) @ []), true) equiv _.

%%% ------------------------------------------ end of file equiva.pl  %%%





