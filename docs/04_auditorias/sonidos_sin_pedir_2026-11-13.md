# Sonidos que no suenan (13-11-2026)

Queja del dueño: «siento que la mayoría de los sonidos no se están ejecutando». Medido: el catálogo de `Sonido` (`Sonido.NOMBRES`) tiene
**215 sonidos**; **113** los pide algún código por su nombre, **13** más se piden armando el nombre (`"gol_" + tipo`) y **89 (el 41 %) no los pide
nada**: se generan al arrancar (en un hilo de fondo) y no suenan nunca. De los 89, tres (`calentamiento`, `cronometro`, `soltar`) solo aparecen
como palabra en traducciones o nombres de animación.

Método: para cada nombre, búsqueda de `"nombre"` en todos los `.gd` (menos `terceros/`, `pruebas/`, `addons/` y la propia síntesis `sonido*.gd`),
más los prefijos dinámicos de `toca("prefijo" + x)`; los JSON y escenas no los piden. Vigilado desde ahora por la prueba del banco
`_probar_sonidos_pedidos` con `pruebas/sonidos_sin_pedir.txt` (la lista solo puede encogerse; meta: vacía).

Antes de crear sonidos nuevos, enchufar estos: ya existen, ya están sintetizados y casi todos corresponden a algo que el juego ya hace.

## Partido (estadio, `visor/` y `ui/estadio*`)
atajada_pies, atajada_punos, autogol, control_balon, fuera_de_banda, fuera_terreno_juego, libre_indirecto, mano_fuera_area, mano_penal,
palo_doble, penal_fallado, posesion_larga, presion_alta, recuperacion_balon, saque_puerta, segunda_amarilla, amonestacion_verbal,
silbido_agudo, tarjeta_banco, tiempo_anadido, tiro_flojo, var_anulado, protesta_jugador, protesta_masiva, festejo_banco,
celebracion_grupal, celebracion_individual, calentamiento, presentacion_alineaciones, pitos_arbitro

## Grada y ambiente
animador_grada, bocina_vuvuzela, bufanda_alzada, campanas_iglesia, cornetin, coro_rival, grada_de_pie, humo_bengala, multitud_entrando,
multitud_saliendo, ola_mexicana, pancarta_desplegada, silbidos_impaciencia, tambor_visitante, viento_fuerte, calor_extremo, huelga_hinchas,
entrada_taquilla

## Club y gestión (eventos de la semana, fichajes, directiva, prensa)
agente_llamada, alta_medica, baja_medica, ascenso_juvenil, debut_juvenil, aumento_socios, capitania, cesion_jugador, prestamo, dinero_entra,
dinero_sale, elecciones_club, entrenamiento_lesion, mejora_instalaciones, nivel_subido, objetivo_cumplido, objetivo_fallado,
oferta_rechazada, premio_individual, premio_liga, renovacion, renovacion_rechazada, retiro_jugador, reunion_directiva, rueda_prensa_aplauso,
rueda_prensa_pregunta, rumor_fichaje, sancion_directiva, scouting_informe, sesion_tactica, veto_fichaje, votacion_ganada, votacion_perdida

## Interfaz
arrastrar, cancelar, deseleccionar, desbloqueo, seleccionar, soltar, paso_atras, cronometro

## Reglas para enchufarlos
- Un sonido suena en el momento en que el jugador VE el hecho (no al calcularlo en la simulación): en la pantalla o el estadio que lo muestra.
- Nada de `Azar`: `Sonido.toca` no lo toca y no hay que cambiar eso (las huellas deben seguir iguales).
- Sin ametrallar: un hecho que ocurre muchas veces por minuto (posesión, recuperación) lleva su enfriamiento; la grada y el ambiente, con
  probabilidad baja o por eventos de grada ya existentes.
- Al enchufar uno, borrarlo de `pruebas/sonidos_sin_pedir.txt`; si de verdad no corresponde a nada del juego, anotarlo allí con el motivo o quitarlo del catálogo.
