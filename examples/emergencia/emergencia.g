TITLE
An emergency-help agent. When it perceives an emergency it gets help by
alerting the driver, which it does by pressing the alarm-signal button.

NETWORK

AGENTS

Emergencia {

Prolog {

tracefile('emergencia.dot').  % see flach/graphviz.pl
for_testing_only(false).

abd(emergencia).
abd(pulsa_boton).

observable(emergencia).

user_built(true).

}

GOALS {

if emergencia then consigue_ayuda.

}

BELIEFS {

to consigue_ayuda do alerta_conductor.

to alerta_conductor do pulsa_boton.

}

} % end of Agents section

INTERFACE

INIT

DECL


END.
