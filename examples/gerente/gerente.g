TITLE
This is an agent destined to live inside a simulation of a bank, controlling
the sides of the queues in front of each teller, with the abilities to
create more tellers or close them, depending on the side of the queues. 

NETWORK

AGENTS

gerente {

Prolog { 


tracefile('gerente.dot').  % see flach/graphviz.pl

targets_to('./taquilla3'). 

abd(cola_larga).
abd(crear_taquilla).
abd(taq_vacias).
abd(eliminar_taquilla).
abd(revisa_cola).

for_testing_only(nothing).

observable(cola_larga).
observable(taq_vacias).

user_built(true). 
user_built(G) :- xref_built_in(G), !. % allowing any prolog builtin predicate
user_built(timing(_)). 

timing(T) :- gensym('', C), atom_number(C, T).
}

GOALS {

if timing(T) then revisa_cola(T). 
if cola_larga then crear_taquilla.
if taq_vacias then eliminar_taquilla. 

}

BELIEFS {

}

}

INTERFACE

INIT

DECL


END.
