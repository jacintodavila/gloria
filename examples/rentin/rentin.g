TITLE
Rentin: un agente ventajoso. Racionaliza el abuso cuando puede y no
trabaja cuando le da flojera, ocultandose tras la complejidad del sistema.

NETWORK

AGENTS

Rentin {

Prolog {

tracefile('rentin.dot').  % see flach/graphviz.pl
for_testing_only(false).

% abducible predicates (acciones y observaciones asumibles)
%
abd(abuso).
abd(no_trabajo).
abd(flojera).
abd(gano).
abd(no_hay_jueces_confiables).
abd(sin_observador).
abd(datos_se_pierden).
abd(observador_independiente).

% observable predicates (lo que el agente percibe)
%
observable(flojera).
observable(gano).
observable(no_hay_jueces_confiables).
observable(sin_observador).
observable(datos_se_pierden).
observable(observador_independiente).

% built-in, user-defined predicates
%
user_built(true).

}

GOALS {

si puedo, gano_sin_merecerlo entonces abuso.
si flojera entonces no_trabajo.

}

BELIEFS {

para puedo haga nadie_sospecha.
para nadie_sospecha haga oculto_en_complejidad.
para oculto_en_complejidad haga evaluacion_compleja, sistema_judicial_no_funciona.
para evaluacion_compleja haga no_hay_memoria.
para no_hay_memoria haga datos_no_colectados.
para no_hay_memoria haga datos_se_pierden.
para datos_no_colectados haga sin_observador.
para sistema_judicial_no_funciona haga no_hay_jueces_confiables, exenciones_arbitrarias.
para exenciones_arbitrarias haga evaluacion_compleja.
para no_merezco haga no_trabajo.
para gano_sin_merecerlo haga gano, no_merezco.
para datos_colectados haga observador_independiente.

}

} % end of Agents section

INTERFACE

INIT

DECL


END.
