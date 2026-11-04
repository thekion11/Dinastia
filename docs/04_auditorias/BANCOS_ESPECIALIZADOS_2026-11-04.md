# Bancos especializados (megarreforma pedida por el dueño, 3-11-2026)

Pedido: «más de 30 bancos especiales, modulares y ultra detallados, aunque tarden más», más uno EXTRA de rendimiento.

## Fase 1 (hecha, 4-11): 33 bancos + rendimiento = 34
- `python3 dinastia-godot/herramientas/bancos_especiales.py --lista` — los 33 bancos por área y cuántas pruebas tiene cada uno.
- `python3 dinastia-godot/herramientas/bancos_especiales.py <banco> [...]` — corre uno o varios; `--todos` todos; `--sin_banco` lo que no cae en ninguno (debe dar 0).
- Cada banco junta las secciones del banco que son de su área (`BANCO_SOLO=a,b,c`, un solo proceso) y las pruebas especiales de su área.
- `python3 dinastia-godot/herramientas/banco_rendimiento.py` — el banco extra de rendimiento (7 secciones contra topes en `banco_rendimiento.json`).
- `banco.sh` y `especiales.sh` siguen igual (el CI no cambia): los bancos especializados son una forma más fina de correr y ampliar lo mismo.

Áreas: arranque · determinismo · datos_mundo · calendario_competiciones · partido_reglas · partido_ia · partido_fisica ·
partido_porteros · partido_jugable · partido_presentacion · plantel_cantera · mercado_contratos · economia · club_directiva ·
vestuario_moral · entrenamiento_lesiones · prensa_redes · carrera_dt · guardado · idiomas · menu_navegacion ·
accesibilidad_tutorial · estadio_3d · ciudad_construccion · ciudad_vida · ciudad_transporte · personajes_3d · audio ·
minijuegos · mundo_largo_plazo · calidad_grafica · codigo_y_auditorias · ideas_documento (+ rendimiento).

## Fase 2 (en curso): ULTRA DETALLE por banco
Cada banco suma su escena propia `dinastia-godot/pruebas/bancos/<banco>.tscn/.gd` (extiende BaseIdea, «FIN. N fallos»), que el lanzador
corre sola si existe. Criterio: comprobaciones finas y numéricas (rangos reales, invariantes, ida y vuelta, casos límite), aunque tarden.
Bancos más flojos hoy (pocas pruebas para su peso): partido_porteros (0 secciones), club_directiva (0 especiales), minijuegos, audio,
guardado, personajes_3d, partido_fisica, determinismo. Orden propuesto: guardado → idiomas → menu_navegacion → partido_reglas →
economia → … (los del partido, coordinados con la sesión PES 6, que es dueña de la IA y la física).

### partido_reglas (4-11, líder): hallazgos
Escena `pruebas/bancos/partido_reglas.gd`: acta de 40 partidos (marcador = goles avisados = crónica, goleador y asistente en el campo,
estadísticas coherentes, once de 11 sin lesionados ni sancionados), cambios, prórroga y penales, menos de siete, disciplina y tabla.
Arreglados (fallos reales del juego):
- **Reingreso**: `Partido.cambiar()` dejaba volver a entrar a quien ya había salido, y el DT de la IA del estadio podía elegirlo.
  Ahora lo rechaza (`ya_salio()`), y la IA del estadio no lo elige.
- **Rojas del partido simulado sin castigo**: `_incidencias()` ponía la sanción sin `Disciplina.sanciona`, así que se descontaba esa
  misma semana y la roja no costaba ningún partido. Ahora sí.
- **La 5.ª amarilla no sancionaba en el simulado**: faltaba `Disciplina.acumula` en `_incidencias()` (solo estaba en el árbitro y el 3D).
Avisos (simplificaciones del simulado, para el dueño o la sesión PES 6; no se tocan sin su OK):
- La «segunda amarilla» se cuenta sobre las amarillas de la TEMPORADA (par), no del partido: ~8 de cada 40 partidos sale una roja
  a alguien con una sola amarilla en ese partido. `P_ROJA_SEGUNDA` (0,09) está calibrada con esa regla.
- En el simulado la roja no saca al jugador del once (documentado en `_revisar_siete`): puede marcar después de expulsado (raro: 0-1 en 40).

### mercado_contratos y calendario_competiciones (4-11, líder)
- `mercado_contratos`: integridad de planteles durante una temporada y el cambio de año (un club por jugador, `club_id` coherente,
  libres fuera de planteles, 16-34 jugadores y portero), traspasos, contratos FIFA (5 años; 3 menores), vencimientos, reglas del trato
  (92 % de lo pedido, 45 % de la caja de la IA, dinero exacto). Sin fallos del juego.
- `calendario_competiciones`: ida y vuelta de cada liga, copa (potencia de 2, ganadores y tandas, premio), Pascua/Ramadán y fechas,
  temporada completa y ascensos/descensos. Sin fallos del juego. AVISO: con número IMPAR de clubes (solo posible desde el editor) el
  método del círculo deja rachas de 4 partidos en el mismo campo; las ligas reales (pares) no pasan de 2.
