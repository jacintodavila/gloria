Example: baseball_manager (baseball pitching manager)

1. Load Gloria:
   ?- [gloria].

2. Load agent configuration:
   ?- consult('examples/baseball_manager/baseball_manager.main').

3. Build the agent module from its KB:
   ?- make_module(baseball_manager0, 'examples/baseball_manager/baseball_manager.kb').

4. Run sample steps:

   Escenario 1: Inercia y dominio (camino feliz)
   ?- make_module(bm1, 'examples/baseball_manager/baseball_manager.kb'),
      prolog_agent(bm1, 0, 400,
        [comienza_turno_al_bate, lanzador_actual(abridor_d), no_cansado(abridor_d),
         retiros_recientes_sin_dano(abridor_d), pitcheos_optimos(abridor_d)], A).
   A = [do(mantener_lanzador(abridor_d),0)].

   Escenario 2: Alerta temprana sin cambio inmediato
   ?- make_module(bm2, 'examples/baseball_manager/baseball_manager.kb'),
      prolog_agent(bm2, 0, 400,
        [lanzador_actual(abridor), corredores_embasados_sin_outs], A).
   A = [do(calentar_bullpen,0)].

   Escenario 3: Sustitución estándar por desgaste
   ?- make_module(bm3, 'examples/baseball_manager/baseball_manager.kb'),
      prolog_agent(bm3, 0, 400,
        [lanzador_actual(abridor), supera_limite_pitcheos(abridor),
         ordeno_calentar(relA), calentamiento_completo(relA), descanso_suficiente(relA),
         es_abridor(abridor)], A).
   A = [do(sustituir_lanzador(abridor,relA),0)].

   Escenario 4: Bloqueo por reglamento (trampa de 3 bateadores)
   ?- make_module(bm4, 'examples/baseball_manager/baseball_manager.kb'),
      prolog_agent(bm4, 0, 400,
        [entrada_tardia, carrera_empate_o_ventaja_en_riesgo, lanzador_actual(relA_d),
         no_cansado(relA_d), bateador_actual(bateador_zurdo), es_relevista(relA_d),
         ordeno_calentar(rel_zurdo), calentamiento_completo(rel_zurdo),
         descanso_suficiente(rel_zurdo), matchup_brazo_perfil(rel_zurdo,bateador_zurdo)], A).
   A = [].
   % No hay sustitución táctica: falta restricción reglamentaria
   % (el relevista actual no ha enfrentado a 3 bateadores ni cumple otra excepción).

   Escenario 5: Sustitución táctica por apremio (matchup)
   ?- make_module(bm5, 'examples/baseball_manager/baseball_manager.kb'),
      prolog_agent(bm5, 0, 400,
        [entrada_tardia, carrera_empate_o_ventaja_en_riesgo, lanzador_actual(relA_d),
         no_cansado(relA_d), bateador_actual(bateador_zurdo_poder), es_relevista(relA_d),
         enfrento_minimo_tres_bateadores(relA_d), ordeno_calentar(relB_z),
         calentamiento_completo(relB_z), descanso_suficiente(relB_z),
         matchup_brazo_perfil(relB_z,bateador_zurdo_poder)], A).
   A = [do(sustituir_lanzador_tactico(relA_d,relB_z),0)].

   Escenario 6: Modo ahorro (paliza en contra)
   ?- make_module(bm7, 'examples/baseball_manager/baseball_manager.kb'),
      prolog_agent(bm7, 0, 400,
        [equipo_pierde_por_mucho, lanzador_actual(abridor), supera_limite_pitcheos(abridor),
         dos_bb_consecutivas(abridor), es_abridor(abridor), ordeno_calentar(relevista_largo),
         calentamiento_completo(relevista_largo), descanso_suficiente(relevista_largo)], A).
   A = [do(sustituir_lanzador(abridor,relevista_largo),0),
        do(sustituir_lanzador(abridor,relevista_largo),0),
        do(ingresar_relevista_largo,0),
        do(bloquear_relevistas_alta_jerarquia,0)].
   % Nota: sustituir_lanzador aparece duplicado porque esta_cansado/1 se deriva
   % por dos causas (supera_limite_pitcheos y dos_bb_consecutivas).

Notes:
- This agent models only pitching-management decisions.
- no_cansado/1 is a positive observable leaf used to avoid not/1 over defined heads.
- Regulatory restriction is represented by observable/derived facts in the scenario.
- Closer/save rules were removed to simplify the model (Scenario 6 shows current behavior).