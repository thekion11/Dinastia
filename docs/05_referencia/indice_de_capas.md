# Índice de capas del código (norma de 450 líneas)

Los scripts que pasaban de 450 líneas se partieron en **capas** encadenadas: cada una extiende a la anterior
y la última (sin `_pN` en el nombre) conserva la ruta y el `class_name` de siempre. Este archivo lo genera
`herramientas/indice_capas.py`; no se edita a mano.

## `nucleo/cantera.gd` · 4 capas

1. `cantera_p1.gd` — 442 líneas — _init, _mundo, bono_de_camada, multiplicador_de_reputacion, grupo_con_tope, demarcacion_de … (+8)
2. `cantera_p2.gd` — 411 líneas — _hijos_del_dt, _sortear_hermano, camada_anual, _sortear_nombre, _nombre_al_azar, sembrar_leyendas … (+16)
3. `cantera_p3.gd` — 378 líneas — _chequeo_fugas, _proceso_etiquetas, procesar_semana, etiqueta_de, origen_de, registrar_de_academia … (+19)
4. `cantera.gd` — 209 líneas — resolver_agente, _ficha_vacia, a_dic, desde_dic, ranking_canteras

## `nucleo/carrera_jugador.gd` · 2 capas

1. `carrera_jugador_p1.gd` — 444 líneas — jugador, club, _club_inicial, _dorsal_libre, crear, es_titular … (+13)
2. `carrera_jugador.gd` — 357 líneas — semana, _ceder, _club_extranjero, resolver, aceptar_oferta, tras_partido … (+10)

## `nucleo/cesiones.gd` · 3 capas

1. `cesiones_p1.gd` — 427 líneas — _init, _mundo, esta_cedido, _destino_para, _firmar_cesion, ceder_canterano … (+12)
2. `cesiones_p2.gd` — 430 líneas — comision_de_agente, coste_de_clausula, nombre_del_agente, derechos_de_formacion, pagar_derechos_formacion, pagar_clausula … (+12)
3. `cesiones.gd` — 157 líneas — revisar_bonos, fondos_a_dic, a_dic, fondos_desde_dic, desde_dic, oferta_de_fondo … (+4)

## `nucleo/ciudad.gd` · 2 capas

1. `ciudad_p1.gd` — 435 líneas — paletas_luces, _init, _mundo, _tabla, lista_terrenos, lista_negocios … (+25)
2. `ciudad.gd` — 67 líneas — _resolver_sancion, semana, mes, a_dic, desde_dic

## `nucleo/continental.gd` · 2 capas

1. `continental_p1.gd` — 430 líneas — _confed, claves, paises_de, nombre_conti, premio_de, confed_de … (+19)
2. `continental.gd` — 193 líneas — _anotar, _ordenar_grupo, premio_de_cuartos, _armar_llaves, _jugar_fecha_de_grupos, premio_de_ronda … (+5)

## `nucleo/entrenamiento.gd` · 3 capas

1. `entrenamiento_p1.gd` — 431 líneas — _init, bloques, bloque, nombres_de_dias, especiales, especial … (+25)
2. `entrenamiento_p2.gd` — 430 líneas — _sesion_general, _dado_de_la_intensidad, _plan_por_dias, freno_temporada, _hay_capitan, tiene_habilidad … (+16)
3. `entrenamiento.gd` — 270 líneas — sortear_habilidades, dt_coste, dt_requisito, dt_nombre, dt_icono, dt_descripcion … (+21)

## `nucleo/estadio_propio.gd` · 3 capas

1. `estadio_propio_p1.gd` — 433 líneas — en_obras, hecho, avanzar_semana, terminar_obra, _mismo, semanas_de … (+5)
2. `estadio_propio_p2.gd` — 422 líneas — factor_forma, aforo_efectivo, niveles_maximos, niveles_visibles, _bandejas_personalizadas, _tramos_personalizados … (+16)
3. `estadio_propio.gd` — 33 líneas — desde_dic, factor_lesion, factor_desgaste_cesped

## `nucleo/federacion.gd` · 3 capas

1. `federacion_p1.gd` — 406 líneas — catalogo, _titulo_mocion, revisar_presidencia, agenda_empuja, abrir_votacion, abrir_caso … (+3)
2. `federacion_p2.gd` — 410 líneas — votar, factor_tv, factor_tarjetas, revisar_cupo_juvenil, puede_fichar_extranjero, infracciones_de … (+11)
3. `federacion.gd` — 188 líneas — apelar, sancionar_dt, cumplir_sancion_dt, dt_sancionado, a_dic, desde_dic … (+4)

## `nucleo/idiomas.gd` · 2 capas

1. `idiomas_p1.gd` — 436 líneas — _cargar_narracion
2. `idiomas.gd` — 341 líneas — _cargar_extra, _ready, _ordinales, mayusculas, _directa, _tiene_letras … (+13)

## `nucleo/logros.gd` · 3 capas

1. `logros_p1.gd` — 439 líneas — perfil_leer, perfil_guardar, perfil_nivel, perfil_sumar_xp, sumar_xp, _anotar_plantilla_inicial … (+10)
2. `logros_p2.gd` — 367 líneas — _cumple, _cumple_oculto, revisar_ocultos, revisar, revisar_largos, catalogo_largo … (+12)
3. `logros.gd` — 405 líneas — premios_temporada, cerrar_temporada, cara_a_cara, rivalidad_con, nivel_rivalidad, rivalidades … (+7)

## `nucleo/medico.gd` · 2 capas

1. `medico_p1.gd` — 434 líneas — _init, catalogo, _bolsa, severidad_en_partido, ficha, historial … (+17)
2. `medico.gd` — 132 líneas — riesgo_declarado, informe, informe_de, retiro_forzado, _estimar_semanas, ranking_liga … (+4)

## `nucleo/mercado.gd` · 2 capas

1. `mercado_p1.gd` — 436 líneas — _init, _mundo, valor_pedido, deseo_de_venir, ficha_que_pide, club_acepta … (+10)
2. `mercado.gd` — 58 líneas — desde_dic, abrir_negociacion, cerrar_negociacion

## `nucleo/motor_libre.gd` · 2 capas

1. `motor_libre_p1.gd` — 397 líneas — _dir, _dar_balon, _saque, _init, _porteria_rival, _mover_vuelo … (+15)
2. `motor_libre.gd` — 170 líneas — _mover_todos, paso, resultado, simular, foto, tomar_control … (+3)

## `nucleo/mundo.gd` · 10 capas

1. `mundo_p1.gd` — 442 líneas — actual, _init, _anotar_movimiento, _rol_cambio_directiva
2. `mundo_p2.gd` — 446 líneas — tiene_desafio, _norm_nombre, es_clasico, mi_club, club_de_la_copa, _demarcacion_al_azar … (+13)
3. `mundo_p3.gd` — 424 líneas — fundar_club, multiplicador_desafios, alternar_tienda, ingreso_tienda, puntaje_carrera, proximo_partido … (+20)
4. `mundo_p4.gd` — 314 líneas — _avisar_a_la_directiva, horario_actual, factor_publico, factor_tv_horario, _copa_es_de, _continental_es_de … (+8)
5. `mundo_p5_p1.gd` — 270 líneas — _semana_contexto_de_partidos, _semana_once_antes_de_jugar, _semana_jugar_ligas, _semana_caja_y_plantillas, _finanzas_de_la_semana, _cobrar_la_jornada … (+3)
6. `mundo_p5_p2.gd` — 211 líneas — _semana_memoria_del_partido, _semana_mercado, _semana_lesion_insolita, _semana_imprevisto, _semana_obras, _semana_ojeo … (+4)
7. `mundo_p5.gd` — 232 líneas — avanzar_semana, _semana_modulos_del_club, _semana_banco, _semana_ingresos_comerciales, _semana_enfermeria, _semana_entrenamiento … (+3)
8. `mundo_p6.gd` — 422 líneas — temporada_en_curso, jugar_temporada, _rodar_era, _segunda_de, jugar_promocion, _mover_de_liga … (+9)
9. `mundo_p7.gd` — 450 líneas — cerrar_temporada, nueva_temporada, perfil_estadio_de, estacion, clima, campana_lanzada_este_anio … (+13)
10. `mundo.gd` — 129 líneas — tope_valor_ia, tomar_el_mando, nueva_temporada, valor_medio_ia, ranking_tactico, puede_analizar … (+2)

## `nucleo/ojeadores.gd` · 2 capas

1. `ojeadores_p1.gd` — 424 líneas — _init, _mundo, max_paises, costo_informe, cubre, sesgo_de … (+22)
2. `ojeadores.gd` — 133 líneas — mejorar_analitica, semana_analitica, hallazgos_vivos, tiene_academia, alternar_academia, mantencion_academias … (+1)

## `nucleo/partida.gd` · 2 capas

1. `partida_p1.gd` — 394 líneas — carpeta, ruta_de, _cabecera_de, _leer_todo, _leer_con_respaldo, listar … (+11)
2. `partida.gd` — 347 líneas — _dic_a_club, _dic_a_liga, _dic_a_copa, _restaurar_lo_tuyo, desde_instantanea, cargar … (+2)

## `nucleo/partido.gd` · 3 capas

1. `partido_p1.gd` — 448 líneas — fijar_clima, _momentum_push, momentum_local, limpiar_contexto, es_ex_de, _media_linea … (+7)
2. `partido_p2.gd` — 447 líneas — _contar_penal, _aporte_tarjeta, _init, valoraciones, mejor_del_partido, preparar … (+13)
3. `partido.gd` — 379 líneas — simular_minuto, _por_id, gol_externo, anular_gol_externo, remate_externo, tarjeta_externa … (+16)

## `nucleo/prensa.gd` · 8 capas

1. `prensa_p1.gd` — 436 líneas — variables, constantes y señales
2. `prensa_p2.gd` — 426 líneas — _init, _mundo, _dinero, agente_de, _rival_de_la_semana, _eventos_nuevos … (+10)
3. `prensa_p3.gd` — 73 líneas — _fatigar_por_viaje, _mover_funa, _pagar, _ceder, _para_mostrar
4. `prensa_p4_p1.gd` — 232 líneas — _ev_fondo_presiona, _ev_retiro_joven, _ev_virus_fifa, _ev_filtracion_agente, _ev_hostil, _ev_comercial … (+10)
5. `prensa_p4.gd` — 263 líneas — _ev_tunel, _ev_viral, _ev_capitan, _ev_silencio, _ev_cambio_posicion, _ev_sponsor_rueda … (+9)
6. `prensa_p5.gd` — 436 líneas — _pregunta_identidad, _hash_de, _fecha, _pregunta_clima, periodista_de, _poner_periodista … (+18)
7. `prensa_p6.gd` — 413 líneas — clasificar_respuesta, opcion_de_texto, responder_texto, pie_de_campo, revisar_al_paso, abrir_al_paso … (+18)
8. `prensa.gd` — 444 líneas — mesa_de_debate, ranking_entrenadores, nombrar_vocero, revisar_vocero, negociar_tv, factor_tv … (+13)

## `nucleo/redes.gd` · 2 capas

1. `redes_p1.gd` — 394 líneas — usuario_de, seguidores_base_club, iniciar, hashtag_club, puede_publicar, _nueva … (+13)
2. `redes.gd` — 119 líneas — comentar_ultimo_partido, semana, comentar_jugador, a_dic, desde_dic

## `nucleo/roles.gd` · 5 capas

1. `roles_p1.gd` — 436 líneas — look_efectivo, aspecto_3d, es_ayudante
2. `roles_p2.gd` — 433 líneas — jefe_confianza, dt_nombre, jefe_nombre, desgastar_relacion, fijar_directriz, dt_obedece … (+27)
3. `roles_p3.gd` — 415 líneas — emergencia_activa, puede_fichar, puede_alinear, puede_contratar_staff, puede_construir, puede_vender_jugadores … (+26)
4. `roles_p4.gd` — 433 líneas — tras_temporada, ayudante_ascendido, subir_al_primer_equipo, ascender, chequeo_filosofia, homenajear … (+12)
5. `roles.gd` — 357 líneas — bono_reputacion_fichajes, multiplicador_sponsor, tiene, comprar_dt, semana_patrimonio, buscar_rival_dt … (+18)

## `nucleo/selecciones.gd` · 3 capas

1. `selecciones_p1.gd` — 427 líneas — _init, _mundo, _tabla_selecciones, _tabla_paises, _txt, pais_seleccion … (+10)
2. `selecciones_p2.gd` — 429 líneas — _prenomina, _resolver, convocados, prenominados, caps_de, racha_de … (+16)
3. `selecciones.gd` — 161 líneas — _mejores_del_plantel, _vitrina_mundialista, copa_del_mundo, toca_copa_del_mundo, cierre_de_temporada, a_dic … (+3)

## `nucleo/sonido.gd` · 7 capas

1. `sonido_p1.gd` — 225 líneas — _tono, _lienzo, _mezclar, _ruido, _cantico, _bombo … (+1)
2. `sonido_p2_p1.gd` — 328 líneas — _receta_silbato, _receta_pitido_final, _receta_saque_inicial, _receta_medio_tiempo, _receta_reanudacion, _receta_roja … (+52)
3. `sonido_p2_p2.gd` — 300 líneas — _receta_gol, _receta_gol_rival, _receta_gol_cabeza, _receta_gol_chilena, _receta_gol_falta, _receta_gol_penal … (+25)
4. `sonido_p2_p3.gd` — 226 líneas — _receta_murmullo, _receta_ovacion, _receta_tambor, _receta_trompeta, _receta_abucheo, _receta_aplauso … (+39)
5. `sonido_p2_p4.gd` — 339 líneas — _receta_lesion, _receta_cambio, _receta_fichaje, _receta_contrato, _receta_despido, _receta_dinero_entra … (+48)
6. `sonido_p2.gd` — 180 líneas — _receta_clic, _receta_clic_suave, _receta_menu_mover, _receta_menu_aceptar, _receta_menu_atras, _receta_menu_cambio … (+21)
7. `sonido.gd` — 167 líneas — ruta_grabado, _crear_banco, _sintetizar_banco, _generar_en_fondo, _ready, banco … (+6)

## `nucleo/trabajadores.gd` · 2 capas

1. `trabajadores_p1.gd` — 436 líneas — de, texto_de, _persona, es_mujer, equipo, factor … (+6)
2. `trabajadores.gd` — 22 líneas — texto_equipo, a_dic, desde_dic

## `nucleo/vestuario.gd` · 4 capas

1. `vestuario_p1.gd` — 402 líneas — _init, _mundo, _club, _jugador, _montar_clan, agente_de … (+8)
2. `vestuario_p2.gd` — 407 líneas — chequeo_clanes, mediar, estado_mental, _proceso_mental, dar_terapia, descanso_mental … (+13)
3. `vestuario_p3.gd` — 432 líneas — resolver_solicitud, _aptitud, _satisfaccion, _slots_del_once, satisfaccion, motivo_satisfaccion … (+19)
4. `vestuario.gd` — 273 líneas — semana, nueva_temporada, resumen, charla, _tiene, tono_de_texto … (+10)

## `pruebas/banco/ciudad.gd` · 2 capas

1. `ciudad_p1.gd` — 380 líneas — _probar_ciudad, _probar_minijuegos, _probar_ciudad_grande, _probar_ciudad_animo, _probar_ciudad_b7, _probar_modulos … (+1)
2. `ciudad.gd` — 93 líneas — _probar_optimizacion, _probar_no_atravesar_paredes

## `pruebas/banco/estadio.gd` · 2 capas

1. `estadio_p1.gd` — 416 líneas — _probar_pantalla_y_vallas, _probar_estadio, _probar_ola_grada, _probar_vallas_led, _probar_guinos_estadio, _probar_estadio_b6 … (+4)
2. `estadio.gd` — 126 líneas — _probar_interiores_club, _probar_galeria_club, _probar_reforma_con_obra

## `pruebas/banco/gestion.gd` · 3 capas

1. `gestion_p1.gd` — 416 líneas — _probar_finanzas, _probar_mercado, _probar_directiva, _probar_staff, _probar_obras, _probar_cantera … (+1)
2. `gestion_p2.gd` — 312 líneas — _probar_cesiones, _probar_vender, _probar_ojeadores
3. `gestion.gd` — 371 líneas — _probar_negociacion, _probar_economia, _probar_capitan_votado, _probar_piel_por_pais, _probar_contratos_c9, _jug_ley … (+2)

## `pruebas/banco/guardado.gd` · 3 capas

1. `guardado_p1.gd` — 169 líneas — _probar_repetibilidad, _probar_guardado_seguro, _comprobar_estado_cargado
2. `guardado_p2.gd` — 382 líneas — _probar_guardado_1
3. `guardado.gd` — 202 líneas — _probar_guardado_2, _probar_guardado

## `pruebas/banco/ideas.gd` · 2 capas

1. `ideas_p1.gd` — 421 líneas — _probar_ideas_del_documento, _probar_ideas_instalaciones_y_marca, _probar_ideas_personas_y_negocios, _probar_ideas_eventos_de_despacho, _probar_ideas_premios_y_memoria_del_club, _probar_ideas_roles_y_carrera … (+1)
2. `ideas.gd` — 312 líneas — _probar_ideas_simulacion_del_partido, _probar_ideas_club_y_calendario_de_pretemporada, _probar_ideas_dinero_ciudad_y_lesiones, _probar_ideas_tribunal_antidopaje_y_asamblea, _probar_ideas_medicina_y_vestuario, _probar_ideas_entrenamiento_prensa_y_dueno … (+8)

## `pruebas/banco/partido.gd` · 6 capas

1. `partido_p1.gd` — 430 líneas — _probar_partidos, _probar_previa, _probar_arbitros, _probar_puente3d, _probar_notas
2. `partido_p2.gd` — 383 líneas — _probar_tactica_en_movimiento, _motor_de_prueba, _probar_dificultad_cpu, _probar_faltas_puntos
3. `partido_p3.gd` — 53 líneas — _probar_fisica_motor
4. `partido_p4.gd` — 392 líneas — _probar_tanda_c_1
5. `partido_p5.gd` — 411 líneas — _probar_tanda_c_2, _probar_tanda_c, _probar_arreglos_partido_motor, _probar_transmision_y_estadisticas
6. `partido.gd` — 88 líneas — _probar_prorroga_y_penales, _probar_partido_abandonado

## `pruebas/banco/varios.gd` · 10 capas

1. `varios_p1.gd` — 410 líneas — _probar_datos, _probar_mundo, _probar_cubierta_nombres, _probar_base_ficticia, _probar_reales
2. `varios_p2.gd` — 347 líneas — _probar_pie_habil, _probar_banquillo, _probar_banco
3. `varios_p3.gd` — 419 líneas — _probar_roles_y_federacion, _probar_pulso_de_roles, _probar_logros, _probar_desafios
4. `varios_p4.gd` — 416 líneas — _probar_fundar_club, _probar_consejeros, _probar_bilbao_solo_local, _probar_sala_de_prensa, _probar_auspicio, _media_techo_camada … (+1)
5. `varios_p5.gd` — 418 líneas — _probar_analitica_y_academias, _probar_habilidades, _probar_carrera_por_dentro, _probar_editor, _probar_marca, _probar_tribuna_real … (+1)
6. `varios_p6.gd` — 392 líneas — _probar_dinastias, _probar_rotulo_y_sala, _probar_mesa_agente, _probar_plantillas_fijas, _probar_aspecto_y_audio, _probar_tutorial … (+1)
7. `varios_p7.gd` — 415 líneas — _probar_academia, _probar_modos_simulacion, _probar_presets_exportacion, _probar_eventos_nuevos, _probar_entrevistas, _probar_coherencia_c1
8. `varios_p8.gd` — 406 líneas — _probar_portadas_c20, _probar_cantera_c3, _probar_instituciones_c5_c8, _probar_charlas_c6_c7, _probar_licencia_c7, _probar_calendario_c13 … (+2)
9. `varios_p9.gd` — 406 líneas — _probar_politica_c15, _probar_historia_c4, _probar_vida_dt, _probar_maestrias, _probar_habilidades_en_resultados, _probar_motor_libre … (+1)
10. `varios.gd` — 310 líneas — _probar_jugadores_fijos, _probar_disenos_kit, _probar_region_reales, _probar_sancion_dt, _probar_tanda_top25b, _probar_informe_rival … (+1)

## `pruebas/video_promo.gd` · 2 capas

1. `video_promo_p1.gd` — 433 líneas — _montar_rotulo, _ready, _t, _sin_aa, _animar_rotulo, _process … (+32)
2. `video_promo.gd` — 31 líneas — _montar_cierre, _paso_cierre

## `ui/cara.gd` · 2 capas

1. `cara_p1.gd` — 394 líneas — _hash, _look_base, _piel_y_pelo_del_pais, _rasgos_reales_de, look_de, look_aleatorio … (+4)
2. `cara.gd` — 381 líneas — svg_de, _indice_fotos_de, foto_de_ruta, foto_real, textura_2d, textura … (+10)

## `ui/carrera_jugador_ui.gd` · 2 capas

1. `carrera_jugador_ui_p1.gd` — 439 líneas — _limpiar, _st, _panel, _lbl, _boton, _crear … (+18)
2. `carrera_jugador_ui.gd` — 253 líneas — _centro, _derecha, _pintar_semana, _ready

## `ui/casa_escena3d.gd` · 3 capas

1. `casa_escena3d_p1.gd` — 428 líneas — aplicar_funda, _entorno, _suelo, _mat, _fondo_lejano, _caja … (+3)
2. `casa_escena3d_p2.gd` — 424 líneas — _caja_de, _modelo, _casa, _piscina, _auto, _pieza … (+15)
3. `casa_escena3d.gd` — 120 líneas — abrir

## `ui/ciudad_vista.gd` · 2 capas

1. `ciudad_vista_p1.gd` — 425 líneas — _ajustar_a_pantalla, _saturacion_animo, _aplicar_hora, _datos_de, _mover_camara, _boton … (+9)
2. `ciudad_vista.gd` — 203 líneas — _construir, abrir, _desplazar, _process, punto_en, _probar_clic_estadio … (+1)

## `ui/componentes/creador_personaje.gd` · 2 capas

1. `creador_personaje_p1.gd` — 155 líneas — abrir, aspecto, _hay_cambios, _hoja_conjuntos, _aleatorio, _deshacer … (+4)
2. `creador_personaje.gd` — 66 líneas — _montar, _unhandled_input

## `ui/componentes/disenador_kit.gd` · 2 capas

1. `disenador_kit_p1.gd` — 386 líneas — abrir, _selector_color, _actualizar, _color_cambiado, _pasa_filtro, _filtrar … (+7)
2. `disenador_kit.gd` — 288 líneas — _tab_sponsors, _rehacer, _aleatorio, _restablecer, _cerrar, _guardar … (+5)

## `ui/componentes/interior_instalacion.gd` · 7 capas

1. `interior_instalacion_p1.gd` — 415 líneas — _sala_de, tiene, abrir, en_mundo, _sala_nombre, tam_sala … (+11)
2. `interior_instalacion_p2.gd` — 435 líneas — _cerrar_para_pasear, _textura_suelo, _mat_suelo, _sala, _medida, _altura_cadera … (+13)
3. `interior_instalacion_p3.gd` — 430 líneas — _cuadro, _comisaria, _bomberos, _aula, _prim, _texto … (+4)
4. `interior_instalacion_p4.gd` — 402 líneas — _caja_cobro, _supermercado, _puesto_mercado, _mercado, _cine, _camiseta … (+15)
5. `interior_instalacion_p5.gd` — 308 líneas — _gimnasio, _analisis, _cocina, _comedor, _prensa, _museo
6. `interior_instalacion_p6.gd` — 423 líneas — _piscina, _vivienda, _bar, _panaderia
7. `interior_instalacion.gd` — 361 líneas — _peluqueria, _libreria, _taller, _recreativos, _construir_sala, _cerrar … (+6)

## `ui/componentes/mando_giratorio.gd` · 2 capas

1. `mando_giratorio_p1.gd` — 447 líneas — _ajustar_camara, mirar, _material, _semialtura, _caida, _malla_cuerpo … (+14)
2. `mando_giratorio.gd` — 316 líneas — _ready, _process, _reiniciar, _gui_input, _lineas, _cortar … (+2)

## `ui/componentes/minijuegos_ciudad.gd` · 3 capas

1. `minijuegos_ciudad_p1.gd` — 436 líneas — juego_de, abrir, _lbl, _fondo_ciudad, _autografos_empezar, _salpicar … (+5)
2. `minijuegos_ciudad_p2.gd` — 376 líneas — _suelo_verde, _largo_pista, _centro_pista, _multimalla, _piloto, _nuevo_kart … (+9)
3. `minijuegos_ciudad.gd` — 164 líneas — _kart, _process, _firmar, _firmar_en, _gui_input, _firmar_mas_cercano … (+1)

## `ui/componentes/panel_controles.gd` · 3 capas

1. `panel_controles_p1.gd` — 419 líneas — abrir, _sonar, _estilo, _mover_pastilla_menu, _mover_pastilla_disp, _pistas … (+15)
2. `panel_controles_p2.gd` — 446 líneas — _etiquetas_mando, _entrada_escalonada, _pintar, _montar_cabecera, _secciones, _enfocar_primera_fila … (+14)
3. `panel_controles.gd` — 121 líneas — _montar, filas_de_acciones, _cambiar_seccion, _input

## `ui/componentes/panel_mercado.gd` · 2 capas

1. `panel_mercado_p1.gd` — 339 líneas — _lbl, _pintar_estado_ventana, _dato, _dinero, _pintar_ofertas_recibidas, _objetivos … (+4)
2. `panel_mercado.gd` — 374 líneas — _pintar_filtros, _con_foco, _fila_ajuste, _rejilla_ajustes, _pintar_mesa_negociacion, _pintar_termometro … (+5)

## `ui/componentes/telefono.gd` · 4 capas

1. `telefono_p1.gd` — 445 líneas — crear, _hora, _decir, _t_icono, _frase, _widget_informe … (+16)
2. `telefono_p2.gd` — 441 líneas — _tarjeta, _perfil, _publicar, _tribuna, _burbuja_icono, _un_chat … (+4)
3. `telefono_p3.gd` — 117 líneas — restaurar_marcas, _unhandled_input, atras, _tras_abrir, enfocar, _estilo_aviso … (+1)
4. `telefono.gd` — 422 líneas — _banco, _calendario, _fotos, _muestra, _pintar_papel, _elegir_de_galeria … (+6)

## `ui/componentes/tutorial.gd` · 3 capas

1. `tutorial_p1.gd` — 422 líneas — _negrita, contexto, _nombre_mentor, mentor_de, _paso, _dt_o … (+17)
2. `tutorial_p2.gd` — 360 líneas — _pintar_panel_aspecto, _etiqueta_activa, _completar_escritura, _terminar, paso_actual, _accion … (+14)
3. `tutorial.gd` — 209 líneas — _construir_prologo, iniciar, fase, guion_actual, aspecto_actual, indice … (+3)

## `ui/disenos_kit.gd` · 5 capas

1. `disenos_kit_p1.gd` — 347 líneas — claves, diseno, indice_diseno, indice_de, _diseno_de, marca_de … (+8)
2. `disenos_kit_p2.gd` — 267 líneas — _fam_franjas, _fam_aros, _fam_banda, _fam_panos_v, _fam_bloques_h, _fam_franja_pecho … (+25)
3. `disenos_kit_p3.gd` — 313 líneas — _acento, _fam_marmol, _fam_fragmentos, _fam_mangas, _fam_diagonal_partida, _fam_relampago … (+26)
4. `disenos_kit_p4.gd` — 89 líneas — color_en, _mascara_camiseta, _estampar_sponsors
5. `disenos_kit.gd` — 303 líneas — _imagen_camiseta, textura_camiseta, _color_botin, textura_completa, textura_botin, uniforms

## `ui/entrada/entrada_campeonato.gd` · 2 capas

1. `entrada_campeonato_p1.gd` — 131 líneas — _caja, _etq, _color_tono, _boton, _insignia, _fila_cifra … (+3)
2. `entrada_campeonato.gd` — 399 líneas — configurar, _ready, entrada_actual, elegir_modo, elegir_club, _construir … (+12)

## `ui/entrada/idioma.gd` · 2 capas

1. `idioma_p1.gd` — 295 líneas — _calcular_textos, _fuente_serif, _construir, _cabecera, _columna_tarjetas, _tarjeta … (+5)
2. `idioma.gd` — 271 líneas — configurar, _ready, codigos, codigo_enfocado, tarjeta, confirmacion … (+16)

## `ui/entrada/personaje.gd` · 2 capas

1. `personaje_p1.gd` — 272 líneas — configurar, personaje, errores, _poner_datos, _refrescar, _tarjeta … (+5)
2. `personaje.gd` — 292 líneas — _ready, _columna_estudio, _ficha, _columna_editor, _botonera, _boton … (+7)

## `ui/escudo.gd` · 2 capas

1. `escudo_p1.gd` — 427 líneas — _nivel_perfil_actual, especiales_desbloqueados, especial_desbloqueado, textura_especial, silueta, _rasgo_real … (+8)
2. `escudo.gd` — 71 líneas — textura, _guardar, textura_mono, limpiar_cache

## `ui/estadio.gd` · 6 capas

1. `estadio_p1.gd` — 428 líneas — _ajustar_a_pantalla, _pref, _montar_pantalla, _poner_banca_de, _a_la_butaca, poner_directiva … (+6)
2. `estadio_p2.gd` — 405 líneas — recorrer, _mostrar_banner_gol, _guardar_pref, _crear_cursor, texto_controles, _mostrar_ayuda_control … (+21)
3. `estadio_p3.gd` — 425 líneas — _construir, _a_la_revision_var, _al_jugada_ambiente, _nodo_de, _banca_gesto, _banca_celebra … (+6)
4. `estadio_p4.gd` — 375 líneas — _al_gol, _frenar_destacado, _a_la_tarjeta, _al_cambio, _al_remate, _a_la_lesion … (+16)
5. `estadio_p5.gd` — 444 líneas — _montar_motor, _crear_banner_gol, _crear_rotulo_jugada, _arrancar_partido, abrir, _escalar_rotulos … (+2)
6. `estadio.gd` — 391 líneas — _actualizar_barras, disponibles_fuera_del_once, poner_dt, poner_banca_de, poner_personal, _tocar_ambiente … (+11)

## `ui/fondo.gd` · 2 capas

1. `fondo_p1.gd` — 430 líneas — _r, _foco, _gente, _vineta, _marco, _nocturna … (+12)
2. `fondo.gd` — 348 líneas — _ciudad, _montana, _playa, _nieve, _juntas, _mapa … (+7)

## `ui/inicio.gd` · 3 capas

1. `inicio_p1.gd` — 354 líneas — rotacion, _textura_de, _brillo_de, _leer_ajuste, _texto, _construir_banner … (+9)
2. `inicio_p2.gd` — 304 líneas — _guardar_ajuste, _degradado, _pintar_banner, _actualizar_picker, _clave_tinte, _tenir_particulas … (+11)
3. `inicio.gd` — 103 líneas — _rotar_pagina, _ready, _construir_nuevo_juego, _nuevo_juego

## `ui/ocasion_jugable.gd` · 2 capas

1. `ocasion_jugable_p1.gd` — 391 líneas — encendida, guardar, configurar, congela, activa, _lado_de … (+17)
2. `ocasion_jugable.gd` — 130 líneas — _construir, _franjas_visibles, _pintar, _avisar

## `ui/pantalla_estadio.gd` · 2 capas

1. `pantalla_estadio_p1.gd` — 430 líneas — _color_casa, _etiqueta, _base, _escudo_de, abreviatura, _barra_posesion … (+9)
2. `pantalla_estadio.gd` — 273 líneas — _panel_gol, _panel_cruces, _rehacer_orden, mostrar, _casa_es_local, _par_stat … (+7)

## `ui/pantallas/pantalla_ajustes.gd` · 2 capas

1. `pantalla_ajustes_p1.gd` — 391 líneas — _init, _pintar_fotogramas, _color_pal, _pal_borde, _pintar_clima, _pintar_aspecto … (+5)
2. `pantalla_ajustes.gd` — 347 líneas — fuente_de, _pintar_tipografia, _pintar_ranuras, _pintar_fondos_ajustes, _pintar_ajustes

## `ui/pantallas/pantalla_cantera.gd` · 3 capas

1. `pantalla_cantera_p1.gd` — 387 líneas — _init, _pintar_palmares_mundial, _nacionalizar, _pintar_seleccion, _pintar_fondos, _pintar_mapa_del_talento … (+2)
2. `pantalla_cantera_p2.gd` — 426 líneas — _pintar_cantera, _cambiar_rol_prometido, _pintar_roles_prometidos, _pintar_agencias, _pintar_contratos, _apellido … (+3)
3. `pantalla_cantera.gd` — 175 líneas — _pintar_comparar, _pintar_informe

## `ui/pantallas/pantalla_club_vida.gd` · 4 capas

1. `pantalla_club_vida_p1.gd` — 410 líneas — _init, _pintar_balance_medico, _terapia, _segunda_opinion, _pintar_medico, _pintar_logros_ocultos … (+5)
2. `pantalla_club_vida_p2.gd` — 418 líneas — _pintar_obras, _elegir_pretemporada, _pintar_pretemporada, _pintar_mentorias, _pintar_entrenamiento_individual, _pintar_ambiente_y_horario … (+3)
3. `pantalla_club_vida_p3.gd` — 338 líneas — _pintar_entrenamiento, _pintar_historial_federacion, _apelar_caso, _pintar_licencia_y_tribunal, _bono_staff, _renovar … (+2)
4. `pantalla_club_vida.gd` — 130 líneas — _pintar_hinchada

## `ui/pantallas/pantalla_editor.gd` · 2 capas

1. `pantalla_editor_p1.gd` — 445 líneas — _init, _texto_con, _par, _letra_12, _pintar_editor_competiciones, _fila_mas_menos … (+6)
2. `pantalla_editor.gd` — 118 líneas — _pintar_editor_csv, _pintar_editor, _importar_csv, _exportar_csv

## `ui/pantallas/pantalla_ficha.gd` · 2 capas

1. `pantalla_ficha_p1.gd` — 429 líneas — _init, _paleta_ficha, _pedir_informe_ojeo, _pagar_clausula, _paleta_club_dentro, _alternar_consejero … (+12)
2. `pantalla_ficha.gd` — 75 líneas — _club_staff, _pintar_club

## `ui/pantallas/pantalla_gente.gd` · 2 capas

1. `pantalla_gente_p1.gd` — 437 líneas — _init, _charlar_con, _pintar_gente_personas, _pintar_gente, _filtrar_redes, _comunicado … (+10)
2. `pantalla_gente.gd` — 220 líneas — _pintar_redes, _pintar_correo, _firmar_auspicio, _lanzar_campana, _pujar_marca, _pedir_credito … (+3)

## `ui/pantallas/pantalla_identidad.gd` · 2 capas

1. `pantalla_identidad_p1.gd` — 438 líneas — _init, _fila_color_identidad, _rejilla_identidad, _rejilla_especiales, _boton_heredar, _pintar_proveedor … (+5)
2. `pantalla_identidad.gd` — 135 líneas — _pintar_comercial, _pintar_kits

## `ui/pantallas/pantalla_legado.gd` · 3 capas

1. `pantalla_legado_p1.gd` — 424 líneas — _init, _pintar_inicio, _texto_proximo_compromiso, _pintar_desgaste, _pintar_rival_dt, _pintar_leyenda_viva … (+6)
2. `pantalla_legado_p2.gd` — 420 líneas — _pintar_sucesion, _retirarse, _pintar_fin_de_carrera, _pintar_epilogo, _pintar_legado, _pintar_vida … (+4)
3. `pantalla_legado.gd` — 179 líneas — _pintar_records

## `ui/pantallas/pantalla_opciones.gd` · 2 capas

1. `pantalla_opciones_p1.gd` — 417 líneas — _init, _pintar_glosario, _pintar_idioma, _pintar_moneda, _situacion_musical, _pintar_musica … (+7)
2. `pantalla_opciones.gd` — 367 líneas — _pintar_dispositivo, _pintar_velocidad_partido, _pintar_qol

## `ui/pantallas/pantalla_plantel.gd` · 4 capas

1. `pantalla_plantel_p1.gd` — 374 líneas — _init, _pintar_plantel, _fichar_libre, _pintar_libres, _pintar_pizarron, _pintar_balon_parado … (+2)
2. `pantalla_plantel_p2.gd` — 416 líneas — _pintar_tactica, _pintar_desafios, _pintar_rivalidades, _frase_clasico, _historia_de, _pintar_ficha_club … (+1)
3. `pantalla_plantel_p3.gd` — 432 líneas — _pintar_premios, _pintar_juegos_mentales, _pintar_partido, _pintar_proximas_fechas, _pintar_calendario
4. `pantalla_plantel.gd` — 67 líneas — _abrir_negociacion, _cancelar_negociacion, _pintar_copa

## `ui/partido_jugable.gd` · 2 capas

1. `partido_jugable_p1.gd` — 411 líneas — abrir, _montar_pantalla, _once_con, _preparar_cambio, _mostrar_banner, _escena_cambio … (+14)
2. `partido_jugable.gd` — 450 líneas — _montar_hud, _ver_hud, ceremonia_activa, saltar_ceremonia, _silbato, _fin_ceremonia … (+10)

## `ui/partido_vivo.gd` · 3 capas

1. `partido_vivo_p1.gd` — 448 líneas — _escribir, _traducir_tramos, _limpiar, _en_palco, _texto, _mi_once … (+9)
2. `partido_vivo_p2.gd` — 433 líneas — _presionar_desde_el_palco, _pintar_palco, _perilla, _gritar_desde_la_banda, _mis_cambios, _hacer_cambio … (+13)
3. `partido_vivo.gd` — 436 líneas — _informe, _escribir_notas, _al_final, _hasta_el_proximo_gol, _columna, _hasta_el_final … (+5)

## `ui/portada.gd` · 2 capas

1. `portada_p1.gd` — 436 líneas — _r, _marco, _nocturna, _retro, _prensa, _neon … (+14)
2. `portada.gd` — 37 líneas — svg_de, textura

## `ui/principal.gd` · 17 capas

1. `principal_p1.gd` — 403 líneas — variables, constantes y señales
2. `principal_p2.gd` — 413 líneas — _ayudante
3. `principal_p3.gd` — 360 líneas — _acento_de, _aplicar_fondo, fecha_del_dia, fecha_de_hoy, fecha_larga, _limpiar … (+13)
4. `principal_p4.gd` — 435 líneas — _fuente_de, _caja, _pal_fondo, _aplicar_tema, _tinta, _escudo … (+9)
5. `principal_p5.gd` — 301 líneas — _ver_estadio_propio, _ver_estadio_con_carga, _dato, _aire_cifra, _miles, _pintar_estadio
6. `principal_p6.gd` — 424 líneas — _pintar_finanzas, _pintar_porque_moral, _pintar_camarin
7. `principal_p7.gd` — 393 líneas — _idolo_del_club, _ir_a_pestana, _ver_ciudad_propia, _ver_ciudad_con_carga, _pintar_ciudad, _celda … (+9)
8. `principal_p8.gd` — 378 líneas — _ver_ficha, _jugador_de_la_semana
9. `principal_p9.gd` — 421 líneas — _origen_de, _traducir_pantalla, _refrescar, _avanzar_semana, _avanzar_dia, _pintar_dias … (+2)
10. `principal_p10.gd` — 60 líneas — _anotar, _noticia_contratos, _guardar, _autoguardar_si_toca, _deshacer, _cargar_preferencias … (+5)
11. `principal_p12.gd` — 410 líneas — _al_elegir_club, _llenar_selector, _tomar_club, _pintar_elegir_club, _abrir_elegir_club, _modo_simulacion … (+10)
12. `principal_p13.gd` — 311 líneas — _nueva_temporada, _al_elegir_calendario, _abrir_hub, _buscar_global, _textura_brillo_panel, _panel … (+5)
13. `principal_p14.gd` — 315 líneas — _enviar_oferta_negociacion, _al_ajustar_rol_neg, _al_ajustar_campo_neg, _indice_grupo, _paso_pagina, _animar_pagina … (+14)
14. `principal_p15.gd` — 418 líneas — _construir, abrir_tutorial, tutorial_objetivo, tutorial_hecho, tutorial_accion
15. `principal_p16.gd` — 319 líneas — _ready, _bloque_vecino, _rejilla, _fila_jugador, _fijar_modo_simulacion, _selector_modo_partido … (+8)
16. `principal_p17.gd` — 134 líneas — _abrir_rueda_pantalla_completa, _repintar_posturas, _responder, _pintar_museo, _marca, _ver_ciudad_explorando … (+3)
17. `principal.gd` — 254 líneas — _ready, _capa_modal_encima, _input, _pintar_identidad, _al_paso_nuevo, _portada_nueva

## `ui/principal/noticias.gd` · 2 capas

1. `noticias_p1.gd` — 410 líneas — _init, _conectar_1
2. `noticias.gd` — 165 líneas — _conectar_2, conectar

## `ui/rueda_prensa_escena3d.gd` · 4 capas

1. `rueda_prensa_escena3d_p1.gd` — 364 líneas — _montar_suelo, _montar_sala, _montar_periodistas, _montar_fondo_sponsors, _montar_banderas, _montar_luces
2. `rueda_prensa_escena3d_p2.gd` — 449 líneas — _mallas_de, _montar_podio_generado, _montar_podio_procedural, _montar_ocultador_podio, _montar_podio, _montar_dt_generico … (+8)
3. `rueda_prensa_escena3d_p3.gd` — 258 líneas — _montar_periodistas, _mat, _rumbo, _montar_persona, _montar_un_periodista, _montar_camara_tv … (+4)
4. `rueda_prensa_escena3d.gd` — 62 líneas — _process

## `ui/sorteo.gd` · 2 capas

1. `sorteo_p1.gd` — 401 líneas — _paleta, _paises_del_sorteo, _svg, _textura_luz, _escudo, _fila_club … (+9)
2. `sorteo.gd` — 178 líneas — _sacar_bola, _correr, abrir_grupos, abrir_eliminatoria, _unhandled_input, _textura_bombo … (+2)

## `ui/sorteo_escena3d.gd` · 3 capas

1. `sorteo_escena3d_p1.gd` — 396 líneas — cortar_plano, _vertices_icosaedro, textura_balon, _montar_suelo, _montar_sala, _montar_pared … (+2)
2. `sorteo_escena3d_p2.gd` — 404 líneas — _montar_bombo, _montar_bolas, _montar_capas, _montar_publico, _montar_pantalla_gigante, _montar_presentador_realista … (+3)
3. `sorteo_escena3d.gd` — 403 líneas — _montar_presentador_siluetas, _montar_presentador, _montar_reveladores, _montar_camara, montar, poner_banderas … (+9)

## `visor/anim_extra.gd` · 2 capas

1. `anim_extra_p1.gd` — 439 líneas — _brazo, _codo, _p, _completar, _par, espejar … (+12)
2. `anim_extra.gd` — 93 líneas — pedir_balon, saludar_publico, pedir_calma, manos_cabeza, cabeza_gacha, mirar_cielo … (+5)

## `visor/anim_futbol.gd` · 3 capas

1. `anim_futbol_p1.gd` — 421 líneas — L, _canal, armar, golpeo, chilena, tijera … (+15)
2. `anim_futbol_p2.gd` — 432 líneas — estirada, portero_lateral, defensor_pica, duelo_hombro, duelo_empujado, duelo_agarron … (+16)
3. `anim_futbol.gd` — 12 líneas — espejables

## `visor/anim_quaternius.gd` · 3 capas

1. `anim_quaternius_p1.gd` — 346 líneas — _buscar_ap, _lib_real, cargar_real, _buscar_esqueleto, _cargar_clip_futbol
2. `anim_quaternius_p2.gd` — 423 líneas — cargar_futbol, _nueva, _huesos_rigidos, _limitar_rodillas, _bakear_futbol_global, cargar_futbol_global … (+9)
3. `anim_quaternius.gd` — 376 líneas — rabia, senalar_falta, falta_barrida, dolor, _firma, parado … (+11)

## `visor/camera_rig.gd` · 2 capas

1. `camera_rig_p1.gd` — 438 líneas — _add, build_for, current_name, _efectos, altura_segura, amortiguar … (+6)
2. `camera_rig.gd` — 217 líneas — impacto, golpe_de_zoom, cycle, ajustar_zoom, ajustar_altura, ayuda … (+10)

## `visor/ceremonia_partido.gd` · 2 capas

1. `ceremonia_partido_p1.gd` — 386 líneas — iniciar, _anim_de, _nino, _preparar_salida, _poner_mascota, _poner_lona … (+8)
2. `ceremonia_partido.gd` — 224 líneas — _preparar_sorteo, _entrar_en, _caminar, _camara, _rotulo_sorteo, _anim_gesto … (+3)

## `visor/city_builder.gd` · 12 capas

1. `city_builder_p1.gd` — 432 líneas — variables, constantes y señales
2. `city_builder_p2.gd` — 412 líneas — _marca, _color_luces, _altura_terreno, _textura_cesped, _normal_rejilla, _terreno … (+6)
3. `city_builder_p3.gd` — 413 líneas — _construir_vias, _color_club, _una_farola, _farolas_anillo, _calles, _grua
4. `city_builder_p4.gd` — 434 líneas — _estadio_maqueta, _estadio, _lineas_campo, _un_campo, _campos, _rotulo … (+8)
5. `city_builder_p5.gd` — 404 líneas — _detalle_edificio, _arquito, _extra, _poner_extra, _rasgo_instalacion, _personal_en … (+3)
6. `city_builder_p6.gd` — 428 líneas — _complejo, _cartel, _huerto, _piscina_olimpica, _polideportivo, _canchas_secundarias … (+6)
7. `city_builder_p7.gd` — 431 líneas — _terminal_buses, _paradas_bus, _perimetro, _solar, _tabla_terrenos, _nombre_terreno … (+8)
8. `city_builder_p8.gd` — 435 líneas — _parking_negocio, _centro_comercial, _clinica, _parcelas, _finca_enredadera, _parque_barrio … (+5)
9. `city_builder_p9.gd` — 430 líneas — tenir, _fila_urbana, _frentes_urbanos, _en_ovalo, _karting, _en_frente_urbano … (+2)
10. `city_builder_p10.gd` — 413 líneas — _karts_en_pista, _redondear, autobus, _un_peaton, _hacer_bote, _trafico … (+3)
11. `city_builder_p11.gd` — 392 líneas — _hinchada_estadio, _dia_de_partido, _animo_del_club, _rotulo_barrio, _despejar_vestuario, vestir_todas_las_torres … (+7)
12. `city_builder.gd` — 148 líneas — _distritos, _casa_gigante, asfalto_mate, mostrar_rotulos

## `visor/ciudad_expansion.gd` · 9 capas

1. `ciudad_expansion_p1.gd` — 411 líneas — _init, dentro_nucleo, en_borde_nucleo, nombre_fila, nombre_columna, nombre_calle_en … (+7)
2. `ciudad_expansion_p2.gd` — 330 líneas — armar_red, ancho_brazo, medio_cruce, es_puente, tiene_semaforo, fin_de_cebra … (+15)
3. `ciudad_expansion_p3.gd` — 370 líneas — _adornar_puente, _puente, _fin_acera, _libre_de_marcas, _dibujar_calles, _arboles_en … (+6)
4. `ciudad_expansion_p4.gd` — 424 líneas — _detalles_parque, _parque, _acera_bloque, _caja_det, _detalle_edificio, _kit … (+10)
5. `ciudad_expansion_p5.gd` — 431 líneas — _pisos, _escala_largo, _es_largo_x, _industrial, _cd, _detalle_casa … (+6)
6. `ciudad_expansion_p6.gd` — 434 líneas — _recreativos, _puestos_feria, _estacion_rusa, _en_recorrido, _tren_rusa, _montana_rusa … (+6)
7. `ciudad_expansion_p7.gd` — 438 líneas — _bandera_mastil, _cartel_m, _instalacion, _dibujar_bloque, _edificios_lejanos, _casas_kenney … (+5)
8. `ciudad_expansion_p8.gd` — 420 líneas — _libre_farola, _textura_charco, _mat_poste_farola, _farolas, _mobiliario_urbano, _placas_de_calle … (+3)
9. `ciudad_expansion.gd` — 360 líneas — _kenney_calles, _parque_eolico, _deposito_agua, _volcar_lotes, construir, _kit_apilado … (+6)

## `visor/edificio_club.gd` · 2 capas

1. `edificio_club_p1.gd` — 367 líneas — nombre_planta, plantas, nivel, zonas, _ascensor, _pared_galeria … (+7)
2. `edificio_club.gd` — 279 líneas — _objeto, _marco_foto, _decorar, montar, reconstruir

## `visor/estadio_partes_tribuna.gd` · 10 capas

1. `stadium_builder_p1.gd` — 442 líneas — _c, marcar_techo, ocultar_techo_ante, _box, _rect_outline, _verdes_reales … (+4)
2. `stadium_builder_p2.gd` — 424 líneas — _add_goal, _zona_tecnica, _corners, _anuncio, _con_paleta, _anuncios_de … (+4)
3. `stadium_builder_p3.gd` — 429 líneas — _banquillos_detalle, _tunel, geom_de_forma, _un_camarografo, _camarografos, _escudo_cancha … (+4)
4. `stadium_builder_p4.gd` — 449 líneas — build_pitch, _pintar_publico, _make_stand_texture, _make_stand_texture_tramos, _techo_mat, _mat_fachada
5. `stadium_builder_p5.gd` — 416 líneas — _tramos_sin_hueco, niveles_de, subida_bandeja, altura_de, fondo_tribuna, centro_tribuna … (+15)
6. `stadium_builder_p6.gd` — 362 líneas — _butacas, _vomitorios, _cabeza_foco
7. `stadium_builder_p7.gd` — 434 líneas — _telones, _cinta_led, _esquina_grada, _caras_esquina, _pista_atletismo, _bandera_ondeante … (+2)
8. `stadium_builder_p8.gd` — 436 líneas — _focos, color_luz, _exterior, _pantalla_textura, _quad_pantalla, _pantallas … (+2)
9. `stadium_builder_p9.gd` — 73 líneas — _sombra_unica
10. `estadio_partes_tribuna.gd` — 255 líneas — _muro_y_zocalo, _material_grada, _bandejas, _rampa, _peto, _vuelo_techo … (+2)

## `visor/explorador_ciudad.gd` · 6 capas

1. `explorador_ciudad_p1.gd` — 442 líneas — _raton_en_primera_persona, _sentado_fp, construir_obstaculos, _huellas_de_torres, _indexar_obstaculos, _indexar_circulos … (+12)
2. `explorador_ciudad_p2.gd` — 439 líneas — _choca_moviles, _rect_coche, _dentro_rect, _huella, buscar_libre, es_tactil … (+9)
3. `explorador_ciudad_p3.gd` — 363 líneas — _colocar_camara, _salir_del_edificio, _portero, _salir_del_estadio, _ir_a_planta, _subir_al_tren … (+11)
4. `explorador_ciudad_p4.gd` — 437 líneas — _mover_en_estadio, _bajar_a_la_galeria, _usar, _tactil, _aplicar_ajustes, _montar_hud … (+7)
5. `explorador_ciudad_p5.gd` — 448 líneas — edificio_en, pausar, _actualizar_mano, _mover_en_anden, _viajar, _choca_mueble … (+7)
6. `explorador_ciudad.gd` — 11 líneas — _exit_tree

## `visor/explorador_estadio.gd` · 2 capas

1. `explorador_estadio_p1.gd` — 419 líneas — _aplicar_ajustes, _mostrar_lugar, _buscar_anim, _crear_cuerpo, levantarse, _personal … (+14)
2. `explorador_estadio.gd` — 77 líneas — _rotulos, _physics_process, _raton_en_primera_persona, _unhandled_input, _exit_tree

## `visor/fachada_estadio.gd` · 3 capas

1. `fachada_estadio_p1.gd` — 415 líneas — estilo_de, cara, _paleta, _tramos, _ejes, _libre … (+2)
2. `fachada_estadio_p2.gd` — 438 líneas — _lamas, _celosia, _porticos, _barrio, _torre_esquina, _tapar_junta … (+6)
3. `fachada_estadio.gd` — 145 líneas — _material, _tex_muro_cortina, _volcar, montar

## `visor/mascota_q.gd` · 2 capas

1. `mascota_q_p1.gd` — 422 líneas — material_pelaje, _pegar, _mat, _esf, _cono, _pelaje_oscuro … (+6)
2. `mascota_q.gd` — 133 líneas — crear, _gesto, _ready, _process

## `visor/match_playback.gd` · 4 capas

1. `match_playback_p1.gd` — 430 líneas — velocidad, etiqueta_velocidad, pausar_o_seguir, mas_rapido, mas_lento, setup … (+10)
2. `match_playback_p2.gd` — 418 líneas — _ejecutar_accion, _decidir_regate, _animar, _resolver_choques, _mover, _mas_cercano_a … (+2)
3. `match_playback_p3.gd` — 379 líneas — _jugada_corner, _programar_gesto, _trabajo_del_arbitro, _jugada_tiro_libre, _jugada_gol, _celebrar … (+2)
4. `match_playback.gd` — 149 líneas — tick, ejecutar_jugada_prehecha, suceso

## `visor/metro_ciudad.gd` · 4 capas

1. `metro_ciudad_p1.gd` — 436 líneas — _mat, _caja, _viaducto, _tunel_xray, _tunel, _estacion_elevada … (+2)
2. `metro_ciudad_p2.gd` — 337 líneas — _kenney, _tam_lon, _amueblar_anden, _decorar_estacion, linea, _panel … (+3)
3. `metro_ciudad_p3.gd` — 426 líneas — _tren_real, _tren_fantasma, _centro_anden, _totem, montar, tren_parado_en … (+11)
4. `metro_ciudad.gd` — 388 líneas — _mover_caminantes, _llegadas, _pasajeros_cerca, _gente_cerca, puerta_cercana, _en_tren … (+8)

## `visor/motor_jugable.gd` · 12 capas

1. `motor_jugable_p1.gd` — 449 líneas — _atributos, equipo_cpu, _dificultad_de, _rasgos_duelo
2. `motor_jugable_p2.gd` — 444 líneas — _preparar_uno, dir_ataque, _orientar_formaciones, _poner_usuario, pos, _elegir_lanzador … (+30)
3. `motor_jugable_p3.gd` — 450 líneas — _mio_mas_cercano, _control_de_equipo, _aplicar_cansancio, _anadido_de, segundos_anadidos, minutos_anadidos … (+15)
4. `motor_jugable_p4.gd` — 423 líneas — _mover_balon, _plano, _libre_para_duelo, _fuerza, _derecha, _ganador … (+11)
5. `motor_jugable_p5.gd` — 428 líneas — _duelo_agarron, _duelos, _mover_jugadores, _actualizar_balon_visual, _rol, _pitar_offside … (+3)
6. `motor_jugable_p6.gd` — 420 líneas — _patear, _companero_cerca, _cabezazo, _entrada, _disputas, _punto_de_recepcion … (+11)
7. `motor_jugable_p7.gd` — 450 líneas — _parada, _penal_en_juego, _reaccion_portero, _ia_portero, _finta_ia, _intentar_regate … (+4)
8. `motor_jugable_p8.gd` — 428 líneas — _forma, _zona_de_llegada, _ia_ataque_sin_balon, _gatillo_presion, _linea_defensiva, _ia_defensa … (+10)
9. `motor_jugable_p9.gd` — 447 líneas — _filigrana, _pase_manual, _centro_usuario, _segundo_presionador, _control_usuario, _fuera_del_area … (+3)
10. `motor_jugable_p10.gd` — 394 líneas — _anillo_serenidad, tanda_equipo_usuario, tanda_me_toca_parar, tanda_me_toca_tirar, tanda_turno, _lado_portero_tanda … (+14)
11. `motor_jugable_p11.gd` — 381 líneas — _colocar_saque, _sitio_tanda, _siguiente_penal, _resultado_tanda, _vuelo_tanda, tanda_decidida … (+7)
12. `motor_jugable.gd` — 96 líneas — paso, _physics_process, anular_gol, posesion_local

## `visor/optimizar.gd` · 2 capas

1. `optimizar_p1.gd` — 438 líneas — _lados, primitivas, butacas_livianas, _diagonal, distancias, _no … (+10)
2. `optimizar.gd` — 190 líneas — informe, _rejilla, _sin_dinamica, _en_rejilla, obstaculos, _circulos … (+1)

## `visor/pelo_capas.gd` · 2 capas

1. `pelo_capas_p1.gd` — 375 líneas — _normales, _densidades, _anillo, _max, _capas_sobre, _solo_con … (+9)
2. `pelo_capas.gd` — 157 líneas — poner, _suavizar

## `visor/personaje_dt.gd` · 2 capas

1. `personaje_dt_p1.gd` — 448 líneas — aleatorio, de_rival, aspecto, _objetivos, _cuerpo, _pegar … (+7)
2. `personaje_dt.gd` — 318 líneas — _accesorios, crear, _cejas, parado_persona, poner_en_banda, gestos_banda … (+4)

## `visor/player_spawner.gd` · 2 capas

1. `player_spawner_p1.gd` — 432 líneas — altura_de, _find_anim_player, _build_shared_lib, slot_to_position, poner_energia, energia … (+12)
2. `player_spawner.gd` — 230 líneas — spawn_cuarto_arbitro, spawn_banca, _banco_de_suplentes, spawn_sentados

## `visor/recorrido_club.gd` · 2 capas

1. `recorrido_club_p1.gd` — 438 líneas — aviso_de, y_de, menu_ascensor, respuesta_oficio, dialogo, dialogo_portero … (+6)
2. `recorrido_club.gd` — 115 líneas — sala_decorable, interiores, panel_decorar

## `visor/repeticion.gd` · 2 capas

1. `repeticion_p1.gd` — 435 líneas — setup, _process, segundos_guardados, reproducir, saltar, cortar … (+14)
2. `repeticion.gd` — 46 líneas — _punto_anim, _terminar

## `visor/stadium_builder.gd` · 3 capas

1. `stadium_builder_p10_p1.gd` — 172 líneas — _preparar_obra, _tribunas, _tribuna_de, _levantar_tribuna
2. `stadium_builder_p10.gd` — 176 líneas — build, _esquinas, _vallas, _fachada_y_escudo
3. `stadium_builder.gd` — 8 líneas — encender_conos

## `visor/texturas.gd` · 2 capas

1. `texturas_p1.gd` — 421 líneas — _ruido, _tex_ruido, _ruido_claro, hormigon, ladrillo, _imagen_asfalto … (+9)
2. `texturas.gd` — 36 líneas — churrete

## `visor/trafico_ciudad.gd` · 2 capas

1. `trafico_ciudad_p1.gd` — 400 líneas — s_mas_cercano, largo_de, agregar_control, marcar_cola_al_ultimo, agregar_paradas_al_ultimo, agregar_ruta … (+12)
2. `trafico_ciudad.gd` — 335 líneas — _process, _lateral, _esquivar, tapa_al_jugador, _rejilla_paso, _hueco … (+3)

## `visor/vestidor_q.gd` · 3 capas

1. `vestidor_q_p1.gd` — 419 líneas — _botin_de, _cargar_male, _textura_recoloreada, _mallas, vestir, _material_liso … (+5)
2. `vestidor_q_p2.gd` — 288 líneas — vestir_equipacion, exposicion_piel, compensar_piel, _afin_foto, _ocultar_cejas_y_barba, _teñir_pelo … (+4)
3. `vestidor_q.gd` — 183 líneas — poner_cara

