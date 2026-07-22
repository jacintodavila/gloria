/*  $Id: gloria.pl,v 1.0.2 2006/10/14 10:00:00 jacinto $

    Part of Gloria http://gloria.sourceforge.net

    Author:        H. Yelitza Contreras y Jacinto Davila
    E-mail:        hyelitza@ula.ve, jacinto@ula.ve
    WWW:           http://webdelprofesor.ula.ve/ingenieria/jacinto
    Copyright (C): 2006, H. Yelitza Contreras, Jacinto Davila and 
			Universidad de Los Andes, Venezuela

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

% tokenizer.pl
% adapted from the yelinizador.pl
% Author: H. Yelitza Contreras CopyRight 2002. 
% Adapted by: Jacinto Davila, 2006

read_source(Filename, Tokens) :-
	see(Filename), 
        leer_caracter(C,T), 
	leer_oracion(C,T,Tokens, _), 
	seen.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Paso 1 : Leer, Tokennizer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% archivo entrada/salida, tokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Esto corresponde al primer paso para escribir resumenes.
% Consiste en dividir el texto en fases del pensamiento: párrafos, 
% oraciones y palabras.
% leer_parrafo(-Atomos,-ProximoC)
% lee una línea del texto, separándola en una lista de átomos.
% átomo = párrafo, delimitado por el caracter especial de fin de 
% archivo.

leer_parrafo(Atomos,ProximoC) :-
        leer_caracter(PrimerC, PrimerT),
        leer_resto_p(PrimerC, PrimerT, Atomos, ProximoC).
        
% leer_resto_p(46,especial,Parrafo,ProximoC) :- 
%        !,
%        leer_caracter(Caracter,TipoC),
%        leer_resto_p(Caracter,TipoC,Parrafo,ProximoC).

leer_resto_p(32,blanco,Parrafo,ProximoC) :- 
        !,
        leer_caracter(Caracter,TipoC),
        leer_resto_p(Caracter,TipoC,Parrafo,ProximoC).

leer_resto_p(-1,fin,[],ProximoC) :- 
        !,
        leer_caracter(ProximoC,_).

%leer_resto_p(10,fin,[],ProximoC) :- 
%        !,
%        leer_caracter(ProximoC,_).
        
leer_resto_p(Caracter,fin,[],Caracter) :- !.    
                
leer_resto_p(PrimerC,PrimerT,[Oracion|Atomos],ProximoCaracter) :- 
        % tipo alfa
        leer_oracion(PrimerC,PrimerT,Oracion,ProximoC),
        tipo_caracter(ProximoC,ProximoT,PC),
        leer_resto_p(PC,ProximoT,Atomos,ProximoCaracter).

% leer_atomos(-Atomos,-ProximoC)
% lee una línea del texto, separándola en una lista de átomos

leer_atomos(Atomos,ProximoC) :-
        leer_caracter(PrimerC, PrimerT),
        leer_oracion(PrimerC, PrimerT, Atomos,ProximoC).
        
% leer_oracion(+PrimerC,+PrimerT,-Lista,-ProximoC)
% Dado el primer caracter y tipo de caracter retorna la lista de 
% palabras de la oración. La oración esta delimitada por cualquier
% caracter de fin, en especial el punto [46].

leer_oracion(Caracter,fin,[],Caracter) :- !.

% leer_oracion(46,especial,[],46) :- !.

leer_oracion(_,blanco,Atomos,ProximoC) :- 
        !,
        leer_atomos(Atomos,ProximoC).

leer_oracion(PrimerC,especial,[A|Atomos],ProximoC) :-
        !,
        name(A,[PrimerC]),
        leer_atomos(Atomos,ProximoC).
                
leer_oracion(PrimerC,PrimerT,[A|Atomos],ProximoCaracter) :- % tipo alfa
        palabra_completa(PrimerC,PrimerT,Palabra,ProximoC,ProximoT),
        name(A,Palabra),
        leer_oracion(ProximoC,ProximoT,Atomos,ProximoCaracter).

% leer_caracter(-Caracter,-Tipo)
% lee un caracter de la entrada estándar y obtiene el tipo de caracter
% de la funcion tipo_caracter

leer_caracter(Caracter,Tipo) :- 
        get0(C), %% lee un caracter de la entrada estándar
        tipo_caracter(C,Tipo,Caracter).

% palabra_completa(+PrimerC,+PrimerT,-Lista,-ProximoC,-ProximoT)
% dado el primer caracter y el primer tipo de caracter lee el resto de
% la palabra, colocándola en la lista.
        
palabra_completa(PrimerC,alfa,[PrimerC|Lista],ProximoC,ProximoT) :-
        !,
        leer_caracter(Caracter,TipoC),
        palabra_completa(Caracter,TipoC,Lista,ProximoC,ProximoT).

palabra_completa(PrimerC,num,[PrimerC|Lista],ProximoC,ProximoT) :-
        !,
        leer_caracter(Caracter,TipoC),
        palabra_numerica_completa(Caracter,TipoC,Lista,ProximoC,ProximoT).

%% cuando el primer caracter no es alfanumérico 

palabra_completa(PrimerC,PrimerT,[],PrimerC,PrimerT).

palabra_numerica_completa(PrimerC,PrimerT,[PrimerC|Lista],ProximoC,ProximoT) :-
        member(PrimerT,[num,alfa]),
        !,
        leer_caracter(Caracter,TipoC),
        palabra_numerica_completa(Caracter,TipoC,Lista,ProximoC,ProximoT).

palabra_numerica_completa(PrimerC,especial,[PrimerC|Lista],ProximoC,ProximoT) :-
        member(PrimerC,[46]),
        !,
        leer_caracter(Caracter,TipoC),
        palabra_numerica_completa(Caracter,TipoC,Lista,ProximoC,ProximoT).
        
palabra_numerica_completa(PrimerC,PrimerT,[],PrimerC,PrimerT).

% tipo_caracter(+Codigo,?Type,-NuevoCodigo)
% Dado un código ASCII, clasifica el caracter en "fin" (de linea/archivo
% /palabra), "alfa" (alfabético y numéricos), "especiales" al resto de 
% los caracteres y "blanco"

% tipo_caracter(10,fin,10) :- !. % fin de línea en DOS
% tipo_caracter(13,fin,13) :- !. % fin de línea en UNIX
tipo_caracter(-1,fin,-1) :- !. % fin de archivo

%% blanco y otros caracteres de control

tipo_caracter(Codigo,blanco,Codigo) :- 
        Codigo =< 32,
        !.

%% dígitos numéricos    

tipo_caracter(Codigo,num,Codigo) :- 
        48 =< Codigo, Codigo =< 57,
        !.

%% letras lower-case, alfabéticos

tipo_caracter(Codigo,alfa,Codigo) :- 
        97 =< Codigo, Codigo =< 122,
        !.

%% letras upper-case, alfabéticos

tipo_caracter(Codigo,alfa,NuevoCodigo) :- 
        65 =< Codigo, Codigo =< 90,
        !,
        NuevoCodigo is Codigo. % NO trasladar a lower-case
        %% NuevoCodigo is Codigo + 32. % trasladar a lower-case

%% vocales acentuadas y tilde en minúsculas
%% la lista representa respectivamente L = [á,é,í,ó,ú,ñ]

tipo_caracter(Codigo,alfa,Codigo) :- 
        member(Codigo,[225,233,237,243,250,241]), 
        !.

%% vocales acentuadas y tilde en mayúsculas
%% la lista representa respectivamente L = [Á,É,Í,Ó,Ú,Ñ]
% L = [[193,225],[201,233],[205,237],[211,243],[218,250],[209,241]]
% L = [[Á,á],[É,é],[Í,í],[Ó,ó],[Ú,ú],[Ñ,ñ]]

tipo_caracter(Codigo,alfa,NuevoCodigo) :- 
        member(Codigo,[193,201,205,211,218,209]), 
        !,
        % NuevoCodigo is Codigo. % NO trasladar a lower-case
        NuevoCodigo is Codigo + 32. % trasladar a lower-case

%% caracteres especiales tratados como alfabéticos
%% la lista representa respectivamente L = [%,$,/,°]

tipo_caracter(Codigo,alfa,Codigo) :- 
        member(Codigo,[37,36,47,176]),
        !.

%% caracteres de fin de linea y el subray representados como alfabeticos
%%

tipo_caracter(Codigo,alfa,Codigo) :- 
        member(Codigo,[10, 13, 95]),
        !.

%% todos los especiales (incluyendo al punto). 

tipo_caracter(Codigo,especial,Codigo).

% --------------------------------------------- end of tokenizer.pl 
