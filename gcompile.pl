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

/************************************************************ G-compiler */

% Process a .g file and extract the files .kb and .main for each agent,
% leaving them in the folder where the .g file is located.
process_g_file(File) :-
    read_source(File, Tokens),
    file_directory_name(File, Dir),
    extract_agents_tokens(Tokens, AgentsTokens),
    parse_and_compile_agents(AgentsTokens, Dir).

extract_agents_tokens(Tokens, AgentsTokens) :-
    % Find 'AGENTS' token, and get the rest
    append(_, [AGENTS | Rest], Tokens),
    (AGENTS = 'AGENTS' ; AGENTS = 'agents'), !,
    % Now find 'INTERFACE' in Rest and get everything before it
    append(BeforeInterface, [INTERFACE | _], Rest),
    (INTERFACE = 'INTERFACE' ; INTERFACE = 'interface'), !,
    strip_braces(BeforeInterface, AgentsTokens).

strip_braces(Tokens, Stripped) :-
    Tokens = ['{' | Rest],
    append(Inner, ['}'], Rest), !,
    Stripped = Inner.
strip_braces(Tokens, Tokens).

extract_next_agent(Tokens, AgentName, AgentTokens, RestTokens) :-
    Tokens = [AgentName, '{' | Rest],
    atom(AgentName),
    \+ member(AgentName, ['{', '}', ',', '.']), !,
    extract_matching_block(Rest, 1, AgentTokens, RestTokens).

extract_matching_block([], _, [], []).
extract_matching_block(['}' | Rest], 1, [], Rest) :- !.
extract_matching_block(['}' | Rest], N, ['}' | Acc], Out) :-
    N > 1, !,
    N1 is N - 1,
    extract_matching_block(Rest, N1, Acc, Out).
extract_matching_block(['{' | Rest], N, ['{' | Acc], Out) :-
    !,
    N1 is N + 1,
    extract_matching_block(Rest, N1, Acc, Out).
extract_matching_block([T | Rest], N, [T | Acc], Out) :-
    extract_matching_block(Rest, N, Acc, Out).

has_explicit_sections(AgentTokens) :-
    ( member('Prolog', AgentTokens) ; member('PROLOG', AgentTokens) ; member('prolog', AgentTokens) ),
    ( member('GOALS', AgentTokens) ; member('goals', AgentTokens) ; member('Goals', AgentTokens) ).

% Filter out comments from token list
filter_comments([], []).
filter_comments(['//' | Rest], Out) :- !,
    filter_until_newline(Rest, NewRest),
    filter_comments(NewRest, Out).
filter_comments(['%' | Rest], Out) :- !,
    filter_until_newline(Rest, NewRest),
    filter_comments(NewRest, Out).
filter_comments([T | Rest], [T | Out]) :-
    filter_comments(Rest, Out).

filter_until_newline([], []).
filter_until_newline([T | Rest], Out) :-
    (T == '.' -> Rest = Out ; filter_until_newline(Rest, Out)).

extract_explicit_sections(AgentTokens, Prolog, Goals, Beliefs) :-
    ( find_section(AgentTokens, ['Prolog', 'PROLOG', 'prolog'], PrologRaw) -> 
        filter_comments(PrologRaw, Prolog) ; Prolog = [] ),
    ( find_section(AgentTokens, ['GOALS', 'goals', 'Goals'], GoalsRaw) -> 
        filter_comments(GoalsRaw, Goals) ; Goals = [] ),
    ( find_section(AgentTokens, ['BELIEFS', 'beliefs', 'Beliefs'], BeliefsRaw) -> 
        filter_comments(BeliefsRaw, Beliefs) ; Beliefs = [] ).

find_section(Tokens, KeywordAlternatives, SectionTokens) :-
    append(_, [Keyword, '{' | Rest], Tokens),
    member(Keyword, KeywordAlternatives), !,
    extract_matching_block(Rest, 1, SectionTokens, _).

% Add check for rule indicators to separate_implicit_sections
is_rule_indicator(then).
is_rule_indicator(entonces).
is_rule_indicator(do).
is_rule_indicator(haga).

contains_rule_indicator(Tokens) :- member(X, Tokens), is_rule_indicator(X).

separate_implicit_sections(Tokens, Prolog, Goals, Beliefs) :-
    filter_comments(Tokens, FilteredTokens),
    separate_implicit_sections_filtered(FilteredTokens, Prolog, Goals, Beliefs).

separate_implicit_sections_filtered([], [], [], []).
separate_implicit_sections_filtered([If | Rest], Prolog, Goals, Beliefs) :-
    member(If, [if, si]),
    contains_rule_indicator(Rest), !,
    get_until_period(Rest, RuleTokens, RestOfTokens),
    separate_implicit_sections_filtered(RestOfTokens, Prolog, RestGoals, Beliefs),
    append([If | RuleTokens], RestGoals, Goals).
separate_implicit_sections_filtered([To | Rest], Prolog, Goals, Beliefs) :-
    member(To, [to, para]),
    contains_rule_indicator(Rest), !,
    get_until_period(Rest, RuleTokens, RestOfTokens),
    separate_implicit_sections_filtered(RestOfTokens, Prolog, Goals, RestBeliefs),
    append([To | RuleTokens], RestBeliefs, Beliefs).
separate_implicit_sections_filtered([Token | Rest], [Token | RestProlog], Goals, Beliefs) :-
    separate_implicit_sections_filtered(Rest, RestProlog, Goals, Beliefs).

get_until_period([], [], []).
get_until_period(['.' | Rest], ['.'], Rest) :- !.
get_until_period([T | Rest], [T | Acc], Out) :-
    get_until_period(Rest, Acc, Out).

parse_and_compile_agents([], _).
parse_and_compile_agents(Tokens, Dir) :-
    extract_next_agent(Tokens, AgentName, AgentTokens, RestTokens), !,
    ( has_explicit_sections(AgentTokens) ->
        extract_explicit_sections(AgentTokens, Prolog, Goals, Beliefs)
    ;
        separate_implicit_sections(AgentTokens, Prolog, Goals, Beliefs)
    ), !,
    downcase_atom(AgentName, NameLower),
    atomic_list_concat([Dir, '/', NameLower, '.kb'], KBFile),
    atomic_list_concat([Dir, '/', NameLower, '.main'], MainFile),
    
    % Clear KBFile
    open(KBFile, write, Stream1), close(Stream1),
    
    % Compile Goals if any
    ( Goals \= [] ->
        write_to_temp_file('goals.tmp', Goals),
        compile(actilog, 'goals.tmp', KBFile),
        delete_file('goals.tmp')
    ; true ),
    
    % Compile Beliefs if any
    ( Beliefs \= [] ->
        write_to_temp_file('beliefs.tmp', Beliefs),
        compile_openlog_append(openlog, 'beliefs.tmp', KBFile),
        delete_file('beliefs.tmp')
    ; true ),
    
    % Write Boundaries (Prolog)
    write_to_file(MainFile, Prolog),
    
    parse_and_compile_agents(RestTokens, Dir).
parse_and_compile_agents([_ | RestTokens], Dir) :-
    parse_and_compile_agents(RestTokens, Dir).

compile_openlog_append(openlog, Sourcefile, Objectfile) :-
    read_source(Sourcefile, Tokens),
    openlog_grammar(Defs, Tokens, _), 
    append_object(Objectfile, Defs).

append_object(File, List) :-
    open(File, append, Stream),
    write_list_to_stream(Stream, List),
    close(Stream).
    
write_list_to_stream(_, []).
write_list_to_stream(Stream, [D|R]) :- 
    write(Stream, D), write(Stream, '.'), nl(Stream), 
    write_list_to_stream(Stream, R).
    
write_to_temp_file(File, Content) :-
    open(File, write, Stream),
    write_tokens_smart(Stream, Content),
    close(Stream).

write_tokens_smart(Stream, [Atom, '(' | Rest]) :-
    atom(Atom), \+ member(Atom, [',', '.', ';', '(', ')', '[', ']', '{', '}']), !,
    write(Stream, Atom),
    write(Stream, '('),
    write_tokens_smart(Stream, Rest).
write_tokens_smart(Stream, [':', '-' | Rest]) :- !,
    write(Stream, ':- '),
    write_tokens_smart(Stream, Rest).
write_tokens_smart(Stream, ['\'' | Rest]) :- !,
    write(Stream, '\''),
    write_quoted_tokens(Stream, Rest).
write_tokens_smart(Stream, ['.' | Rest]) :- !,
    writeln(Stream, '.'),
    write_tokens_smart(Stream, Rest).
write_tokens_smart(Stream, ['{' | Rest]) :- !,
    writeln(Stream, '{'),
    write_tokens_smart(Stream, Rest).
write_tokens_smart(Stream, ['}' | Rest]) :- !,
    writeln(Stream, '}'),
    write_tokens_smart(Stream, Rest).
write_tokens_smart(Stream, [T | Rest]) :- !,
    write(Stream, T),
    write(Stream, ' '),
    write_tokens_smart(Stream, Rest).
write_tokens_smart(_, []).

write_quoted_tokens(Stream, ['\'' | Rest]) :- !,
    write(Stream, '\' '),
    write_tokens_smart(Stream, Rest).
write_quoted_tokens(Stream, [T | Rest]) :- !,
    write(Stream, T),
    write_quoted_tokens(Stream, Rest).

write_to_file(File, Content) :-
    open(File, write, Stream),
    write_tokens_smart(Stream, Content),
    close(Stream).

/********************************************************* decompile */

decompile(prolog, []).
decompile(prolog, [(H:-B)|Rest] ) :-
    writef("% to %w do \n%     %w\n",[H,B]),
    decompile(prolog, Rest). 
