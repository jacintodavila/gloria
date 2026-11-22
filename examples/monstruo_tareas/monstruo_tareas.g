TITLE
El mayordomo remendado: un agente ensamblado con partes prestadas. El Doctor
le da ordenes de la casa (servir_sopa, limpiar_polvo, arreglar_gotera,
cuidar_gansos, reparar_puertas) y el mayordomo las cumple coordinando un brazo
de labriego, una pierna de acrobata, un ojo de pintor, una oreja de portera y
un cuerpo enorme.

NETWORK

AGENTS

monstruo_tareas {

Prolog {

tracefile('monstruo_tareas.dot').  % see flach/graphviz.pl
for_testing_only(false).

% Ordenes del Doctor.
abd(orden).

% Partes prestadas del mayordomo remendado.
abd(brazo_de_labriego).
abd(pierna_de_acrobata).
abd(ojo_de_pintor).
abd(oreja_de_portera).
abd(cuerpo_enorme).

observable(orden(_)).

user_built(true).

}

GOALS {

si orden(Tarea) entonces cumple(Tarea).

}

BELIEFS {

para cumple(servir_sopa) haga brazo_de_labriego(sostiene_la_sopa), pierna_de_acrobata(cruza_el_comedor), ojo_de_pintor(mide_la_distancia), oreja_de_portera(oye_la_orden), cuerpo_enorme(ocupa_la_puerta).

para cumple(limpiar_polvo) haga brazo_de_labriego(alcanza_el_estante), pierna_de_acrobata(sube_al_taburete), ojo_de_pintor(encuentra_el_polvo), oreja_de_portera(oye_la_orden), cuerpo_enorme(llena_el_cuarto).

para cumple(arreglar_gotera) haga brazo_de_labriego(aprieta_la_tuberia), pierna_de_acrobata(sube_al_techo), ojo_de_pintor(mira_la_gotera), oreja_de_portera(escucha_el_goteo), cuerpo_enorme(bloquea_el_paso).

para cumple(cuidar_gansos) haga brazo_de_labriego(cierra_la_reja), pierna_de_acrobata(corre_al_corral), ojo_de_pintor(cuenta_los_gansos), oreja_de_portera(oye_a_los_gansos), cuerpo_enorme(tapa_la_salida).

para cumple(reparar_puertas) haga brazo_de_labriego(golpea_la_bisagra), pierna_de_acrobata(sostiene_la_puerta), ojo_de_pintor(revisa_la_madera), oreja_de_portera(detecta_el_chirrido), cuerpo_enorme(empuja_la_puerta).

}

} % end of Agents section

INTERFACE

INIT

DECL


END.
