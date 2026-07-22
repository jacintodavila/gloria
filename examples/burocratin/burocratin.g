TITLE
This is the burocratic agent 

NETWORK

AGENTS

burocratin {


GOALS {

si me_pide(Alguien, Algo) entonces sigo_procedimiento(Algo, Alguien). 
si me_pide(Alguien, Algo), muy_importante(Algo) entonces resuelvo(inmediatamente, Algo, Alguien).
}

BELIEFS {

para sigo_procedimiento(X, Y) haga consulto_manual(X). 

para sigo_procedimiento(W, R) haga invento_manual(X, R). 

para consulto_manual(X) haga existe(X), lee(X).  

para invento_manual(X, Y) haga pide_carta_autoridad, resuelvo(lentamente, X, Y).

para muy_importante(Algo) haga aparece_en_la_ley(Algo). }

Prolog {

tracefile('burocratin.dot').  % see flach/graphviz.pl

for_testing_only(false).

/************************************************** control stuff */

abd(pide_carta_autoridad).
abd(aparece_en_la_ley). 
abd(resuelvo).

observable(pide_carta_autoridad).
observable(aparece_en_la_ley(Algo)). 

user_built(existe(_)).

/*************************************************** user_built */

existe(sacar_constancia). 
existe(reporte). 
}

INTERFACE

INIT

DECL


END.
