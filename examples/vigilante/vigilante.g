TITLE
Vigilante de un conjunto residencial que controla el acceso de vehiculos
segun la categoria de quien llega.

NETWORK

AGENTS

vigilante {

Prolog {

tracefile('vigilante.dot').  % see flach/graphviz.pl

for_testing_only(false).

% abducible predicates (acciones)
%
abd(abre_porton).
abd(anota_cuaderno).
abd(niega_acceso).

% observable predicates
%
observable(llega_vehiculo(_)).

% la observacion tambien es una hoja abducible
abd(llega_vehiculo).

% built-in, user-defined predicates
%
user_built(true).

}

GOALS {

si llega_vehiculo(Categoria) entonces gestionar_acceso(Categoria).

}

BELIEFS {

para gestionar_acceso(residente) haga abre_porton.

para gestionar_acceso(visitante) haga anota_cuaderno, abre_porton.

para gestionar_acceso(desconocido) haga niega_acceso.

}

} % end of Agents section

INTERFACE

INIT

DECL


END.
