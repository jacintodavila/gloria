/*  $Id: gcompile.pl,v 1.0.3 2006/08/14 10:00:00 jacinto $

    Part of Gloria http://gloria.sourceforge.net

    Author:        Jacinto Davila
    E-mail:        jacinto@ula.ve
    WWW:           http://webdelprofesor.ula.ve/ingenieria/jacinto
    Copyright (C): 2007, 2006, Jacinto Davila and Universidad de Los Andes, Venezuela

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

    Changed: Oct 2007 - added syntax in Spanish and ability to write quoted atoms
    Last changed: added infix operator expressions, e.g. X < Y
*/

:- [tokenizer]. % to read the source files


/************************************************************* grammars */ 

comilla --> ['\''].
comilla --> ['\"'].

quoted(Term) --> comilla, in_quotes(Term). 

in_quotes([]) --> comilla. 
in_quotes([T|R]) --> id(T), in_quotes(R). 

/* ----------------------------------------------------------- Openlog */

openlog_grammar([def(Name, Body)|Rest]) --> procedure(Name, Body), openlog_grammar(Rest).
openlog_grammar([]) --> [].

procedure(Name, Body) --> to, name(Name), do, body(Body), period. 

procedure(Name, true) --> asume, name(Name). 

to --> [to].
to -->  [para].

do --> [do]. 
do --> [haga].

period --> ['.'].

name(Predicate) --> pred(Pred_name), open_parentesis, arguments(Args), close_parentesis, 
                   {append([Pred_name], Args, List), Predicate =.. List}.
name(Predicate) --> id(X), pred(Pred_name), id(Y), 
                   {append([Pred_name], [X,Y], List), Predicate =.. List}.

name(N) --> id(N).

pred(P) --> id(P). 

body(Body) --> commands(Body). 

commands((C,R)) --> command(C), comma, commands(R).
commands(C) --> command(C). 

command(C) --> name(C). 

arguments([A|RA]) --> id(A), comma, arguments(RA). 
arguments([A]) --> id(A). %, close_parentesis. 

asume --> [asume].

comma --> [','].

open_parentesis --> ['('].
close_parentesis --> [')'].

/* ---------------------------------------------------------- Actilog */

actilog_grammar([If|RestIf]) --> cg_rule(If), actilog_grammar(RestIf). 
actilog_grammar([]) --> [].

cg_rule(if_(Conds, [Goal])) --> if, conditions(Conds), then, goal(Goal), period. 

if --> [if].
if --> [si].

then --> [then]. 
then --> [entonces]. 

conditions((C,RC)) --> condition(C), comma, conditions(RC). 
conditions(C) --> condition(C). 

condition(C) --> name(C). 

goal(Goal) --> name(Goal). 

/* --------------------------------------------------------- C */

c_grammar --> [].


/* --------------------------------------------------------- Java */

java_grammar --> [].

/* --------------------------------------------------------- Php */

php_grammar --> [].

/* --------------------------------------------------------- Python */

phyton_grammar --> [].

/* --------------------------------------------------------- Prolog */

prolog_grammar --> []. 


/************************************************************* id */
% anything is an id, for the time being. 
% even numbers !!! (April 2007). 
% and now quoted terms too (Oct 2007).

id(Term, [ID|R], RR) :- quoted(List, [ID|R], RR), 
	append(['\''|List], ['\''], FList), 
	concat_atom(FList, ' ', Term), !. 
id(ID, [ID|R], R) :- atom(ID), not(member(ID, [')', '('])). 
id(ID, [ID|R], R) :- number(ID), not(member(ID, [')', '('])). 

/************************************************************ compile */

compile(openlog, Sourcefile, Objectfile) :-
    read_source(Sourcefile, Tokens),
    openlog_grammar(Defs, Tokens, _), 
    write_object(Objectfile, Defs). 

compile(actilog, Sourcefile, Objectfile) :-
    read_source(Sourcefile, Tokens),
    actilog_grammar(Defs, Tokens, _), 
    write_object(Objectfile, Defs).

write_object(File, List) :-
    % tell(File), write_list(List), told.
    append(File), write_list(List), told.

write_list([]).
write_list([D|R]) :- write(D), writeln('.'), write_list(R). 

/********************************************************* decompile */

decompile(prolog, []).
decompile(prolog, [(H:-B)|Rest] ) :-
    writef("% to %w do \n%     %w\n",[H,B]),
    decompile(prolog, Rest). 
