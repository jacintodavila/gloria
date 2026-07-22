% glorita.pl
% v 1.0.2
%
% glorita now is not a very naive secretary agent. It is being
% programmed to learnt. 
%
%Copyright (C) Jacinto Dávila <jacinto@ula.ve>
%
% This program is free software; you can redistribute it
% and/or modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2 of
% the License, or any later version.
%
% This program is distributed in the hope that it will be
% useful, but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public
% License along with this program; if not, write to the Free
% Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
% 02111-1307 USA or see http://www.opensource.org/licenses/gpl-license.php
% 
% Author:  Jacinto Davila <jacinto@ula.ve>

:- dynamic recuerda/1.

:-['gloria.pl'].

%
% Prolog or user-defined predicates
builtin(_ > _). % para usar las desigualdades de prolog. 
builtin(A is B) :- write(A), write(' igual a '), writeln(B). 
builtin(memoriza(_)).

memoriza(Algo) :- assertz(recuerda(Algo)). 

olvida :- retractall(recuerda(_)). 

glorita([X|Y]) :- 
	assert(recuerda(principio)), 
	% writeln('Dime:'), read(Observa), 
	observo_mi_memoria(Obs),
	demod([X|Obs], true, _, Influences),
	ejecuto(Influences), 
	glorita(Y).

glorita :- 
	writeln('Dime:'), read(Observa), 
	observo_mi_memoria(Obs),
	demod([Observa|Obs], true, _, Influences),
	ejecuto(Influences), 
	glorita.

observo_mi_memoria(Obs) :-
	findall(ya_lo_se(X), recuerda(X), Obs). 

ejecuto([]).
ejecuto([te_digo_que_ya_sabia(Algo)|R]) :- write('Ya me habias dicho sobre '), writeln(Algo),
	ejecuto(R), memoriza(Algo).
ejecuto([digo(Algo)|R]) :- write('Te recuerdo que '), writeln(Algo),
	ejecuto(R).  
	

% Introduzca aquí su código en OPENLOG o ACTILOG. Puede cargarlos también por separado. 
%

observable(recuerdame(_)).
observable(ya_lo_se(_)).
observable(obs(_)).
executable(te_digo_que_ya_sabia(_)).
executable(digo(_)). 
executable(hace(_,_)). 


% si ya_lo_se(Algo) entonces digo(Algo). 

% si recuerdame(Algo) entonces recordar(Algo). 

si obs(A), obs(B), relacion(A,B) entonces hace(A,B).

para recordar(Algo) haga ya_lo_se(Algo), te_digo_que_ya_sabia(Algo).

para recordar(Algo) haga memoriza(Algo), digo(Algo).   

asuma relacion(1,2). 

asuma nada. 


observe obs(1).
observe obs(2). 
observe nada. 
%observe recuerdame(examen). 
%observe ya_lo_se(proyecto).
%observe ya_lo_se(agenda). 
%observe ya_lo_se(reunion). 

recuerda(algo). 

%
% para limpiar la memoria en Prolog puede usar ?- olvida.
%


