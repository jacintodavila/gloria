/*  $Id: auxilia.pl,v 1.0.1 2006/06/25 10:00:00 jacinto $

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
*/


/* auxilia.pl

   File with multi-purpose predicates. 

*/

/************************************************ global operators */

:- op(500,xfx,sbelongs).
:- op(600,xfx,equiv).
:- op(600,xfx,old_equiv).
:- op(600,xfx,cn_equiv).
:- op(800,xfx,if).   % for implications..
:- op(810,xfx,@).    % for history of propagation
:- op(820,xfx,::).   % for the context (planning|testing)   
:- op(600,xfx,in).   
:- op(600,xfx,belongs).
:- op(600,xfx,blgs).
:- op(420,xfx,eq).
:- op(420,xfx,ge).
:- op(420,xfx,le).
:- op(420,xfx,gt).
:- op(420,xfx,lt).


/************************************* language specific operators */
% See about actilog and openlog syntax. 
%



/****************************************************** and_append */

and_append( F, S, R ) :- F == true, and_compress( S, R ).

and_append( F, S, ( F, R ) ) :-
	 (var(F); (functor(F, Funct, _), Funct \== ',')), !, 
	 and_compress( S, R ).

and_append( ( F, Rf ), S, ( F, Ro ) ) :- F \== true, !,
	and_append( Rf, S, Ro ).

and_append( ( F, Rf ), S,  Ro ) :- F == true, 
	and_append( Rf, S, Ro ).


and_compress( L, L ) :- L == true, !.

and_compress( L, ( L, true) ) :- 
	 (var(L); (functor(L, Funct, _), Funct \== ',')), !.

and_compress( ( F, Rf ), ( F, Ro ) ) :- F \== true, !,
	and_compress( Rf, Ro ).

and_compress( ( F, Rf ),  Ro ) :- F == true, !, 
	and_compress( Rf, Ro ). 


/**************************************************** strict_belongs */

_ sbelongs [] :- fail, !.
X sbelongs [Y|_] :-  X == Y, !.
X sbelongs [Y|S] :-  X \== Y, X sbelongs S.

/**************************************************** belongs */

X belongs (X, _) :- !.
X belongs (Y, S) :- 
  X \== Y, X belongs S. 

/**************************************************** write_frontier */

write_frontier( [] ) :-
  writef(" -> empty frontier -> \n",[] ).

write_frontier( Frontier ) :-
  Frontier \= [], 
  write_f( 1, Frontier ).


write_f( _, [] ) :- !,  nl.

write_f( N, [N1|Rest] ) :-
  write_node( N, N1 ),
  NN is N + 1,
  write_f( NN, Rest ).

write_node( N, [Abs, UC, CN, HF, _] ) :- 
%       Histories are not being written down
  writef("\n % Abducibles set[%w] = { ",[N]),
  write_conj( Abs ),
%  writef(" };\n % To Test[%w] = { ",[N]),
%   write_conj( TUC ),
%	writef(" | ",[]),
  writef(" };\n % Achievement Goals[%w] = { ",[N]),
  write_conj( UC ),
  writef(" };\n % Maintenance Goals[%w] = { ",[N]),
  write_cond( N, 1, CN ),
  writef(" };\n % HF[%w] = { ",[N]),
  writef("%q",[HF]),
  writef(" }\n",[]), 
  nl.


write_cond( _, _, true ) :- !.

write_cond( N, M, ( First, Rest ) ) :-
%  writef("\n    % - CN[%w, %w] =  %w ",[N, M, First]),
  writef("\n %    - Implication[%w, %w] :\n", [N, M]),
  % write_conj(First), 
  writef("%         -  %w, ",[First]),
  NM is M + 1,
  write_cond( N, NM, Rest ).


write_conj( true ) :- !.

write_conj( (true, Rest) ) :- !, write_conj( Rest ).

write_conj( (todo(G,A), Rest) ) :- 
    writef("\n %     -  to achieve %w do %w ",[G,A]), !,
    write_conj( Rest ).

write_conj( (A, Rest) ) :- writef("\n %     -  %w, ",[A]), write_conj( Rest ).


/**************************************************** general subset */

subset_( [], _ ).
subset_( [El|Rest], S ) :- El sbelongs S, subset_( Rest, S ).


/**************************************************** debuggers */

set_trace([]).

set_trace([equality|Rest]) :-
	assert(wr_eq),!,  set_trace(Rest).

set_trace([inference|Rest]) :-
	assert(wr_ir),!,  set_trace(Rest).

set_trace([frontier|Rest]) :-
	assert(wr_fr), !,set_trace(Rest).

set_trace([last|Rest]) :-
	assert(wr_last), !, set_trace(Rest).

set_trace(_|Rest) :- !, set_trace(Rest).

set_trace([all]) :-
	set_trace([equality,frontier, inference, last]).

clear_trace :- retract(wr_eq), retract(wr_fr), retract(wr_last).  


write_fr( F ) :-
	clause(wr_fr, true), !, write_frontier( F ).

write_fr( _ ).

 
write_eq( S, A ) :-
	clause(wr_eq, true), !, writef( S, A ).

write_eq( _, _ ).


write_ir( S, A ) :-
	clause(wr_ir, true), !, writef( S, A ).

write_ir( _, _ ).


write_last( F ) :-
	clause(wr_last, true), !, write_frontier( F ).

write_last( _ ).



copyOr2And( [], true ).

copyOr2And( [A|Rest], (A, AndRest) ) :-
  copyOr2And( Rest, AndRest ).


writelist( [] ).

writelist( [I|R] ) :-
  writeitem( I ),
  writelist( R ).


writeitem( I ) :- 
  write( I ), write('.'), nl.  


/******************************************************************* blgs */

X blgs (Y, _) :- X == Y, !.
X blgs (Y, S) :- X \== Y, X blgs S. 

/**************************************************************** contain */

contain( (A, _), A ).
contain( (_, Rest), A ) :- contain( Rest, A ). 

/*************************************************************** scontain */

scontain( ( A, _), B ) :- A == B, !. 
scontain( (_, Rest), A ) :- scontain( Rest, A ). 

/************************************************************** cut_list */

cut_list( _, [], 0 ) :- !.
cut_list([A|Rest], [A|NRest], R ) :- !,
  NR is R - 1, cut_list(Rest, NRest, NR).
cut_list([], [], _ ).

% included here to avoid incluying gcompile.pl
decompile(prolog, []).
decompile(prolog, [(H:-B)|Rest] ) :-
    writef("% to %w do \n%     %w\n",[H,B]),
    decompile(prolog, Rest).

%%% -------------------------------------------- end of file auxilia.pl %%%

