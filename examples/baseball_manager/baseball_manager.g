NAME: baseball_manager

TITLE: Baseball Pitching Manager

DESCRIPTION: Agente lógico que modela el comportamiento de un manager de béisbol
encargado exclusivamente de la gestión del pitcheo. Observa el estado del
juego y decide mantener al lanzador, calentar el bullpen, realizar
sustituciones estándar o tácticas, o entrar en modo ahorro.

DISPLAY:
El manager observa el estado del juego, evalúa fatiga, dominio, apremio,
reglamento y disponibilidad del bullpen, y emite acciones de pitcheo.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Base de conocimiento Gloria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SOURCE 'gloria'
BEGIN

Prolog {
tracefile('baseball_manager.dot').  % see flach/graphviz.pl
for_testing_only(false).

% abducible predicates
abd(mantener_lanzador).
abd(calentar_bullpen).
abd(sustituir_lanzador).
abd(sustituir_lanzador_tactico).
abd(ingresar_relevista_largo).
abd(bloquear_relevistas_alta_jerarquia).

% observable predicates
observable(comienza_turno_al_bate).
observable(lanzador_actual(_)).
observable(no_cansado(_)).
observable(fatiga_temprana(_)).
observable(corredores_embasados_sin_outs).
observable(supera_limite_pitcheos(_)).
observable(dos_bb_consecutivas(_)).
observable(tercera_vuelta_alineacion(_)).
observable(retiros_recientes_sin_dano(_)).
observable(pitcheos_optimos(_)).
observable(entrada_tardia).
observable(carrera_empate_o_ventaja_en_riesgo).
observable(ordeno_calentar(_)).
observable(calentamiento_completo(_)).
observable(descanso_suficiente(_)).
observable(matchup_brazo_perfil(_, _)).
observable(induce_rodado(_)).
observable(situacion_doble_matanza).
observable(bateador_actual(_)).
observable(es_abridor(_)).
observable(es_relevista(_)).
observable(enfrento_minimo_tres_bateadores(_)).
observable(finalizo_entrada_anterior(_)).
observable(lesion(_)).
observable(equipo_pierde_por_mucho).

% built-in, user-defined predicates
user_built(true).
}

GOALS {
if comienza_turno_al_bate and lanzador_actual(L) and en_dominio(L) and no_cansado(L) then mantener_lanzador(L).
if lanzador_actual(L) and fatiga_temprana(L) then calentar_bullpen.
if corredores_embasados_sin_outs then calentar_bullpen.
if lanzador_actual(L) and esta_cansado(L) and relevista_listo(R) and restriccion_reglamentaria(L) then sustituir_lanzador(L,R).
if situacion_de_apremio and lanzador_actual(L) and relevista_listo(R) and ventaja_de_enfrentamiento(R,B) and bateador_actual(B) and restriccion_reglamentaria(L) then sustituir_lanzador_tactico(L,R).
if equipo_pierde_por_mucho then modo_ahorro.
}

BELIEFS {
to esta_cansado(L) do supera_limite_pitcheos(L).
to esta_cansado(L) do dos_bb_consecutivas(L).
to esta_cansado(L) do tercera_vuelta_alineacion(L).
to en_dominio(L) do retiros_recientes_sin_dano(L) and pitcheos_optimos(L).
to situacion_de_apremio do entrada_tardia and carrera_empate_o_ventaja_en_riesgo.
to ventaja_de_enfrentamiento(R,B) do matchup_brazo_perfil(R,B).
to ventaja_de_enfrentamiento(R,B) do induce_rodado(R) and situacion_doble_matanza.
to relevista_listo(R) do ordeno_calentar(R) and calentamiento_completo(R) and descanso_suficiente(R).
to restriccion_reglamentaria(L) do es_abridor(L).
to restriccion_reglamentaria(L) do es_relevista(L) and enfrento_minimo_tres_bateadores(L).
to restriccion_reglamentaria(L) do finalizo_entrada_anterior(L).
to restriccion_reglamentaria(L) do lesion(L).
to modo_ahorro do ingresar_relevista_largo and bloquear_relevistas_alta_jerarquia.
}

END
