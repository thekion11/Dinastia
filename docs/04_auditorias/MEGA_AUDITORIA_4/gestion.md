# Mega auditoría 4 — gestion


## Repaso 5 (cruzado, hecho por la sesión Ciudad, 4-11)
Método: sonda `pruebas/ideas/a4_gestion_cruzado.tscn` (en `especiales.sh`): invariantes cada 4 semanas (jugador en un solo lugar, `club_id` coherente, rangos de edad/ovr/pot/forma/moral/físico/sueldo/contrato/goles/lesión/sanción, finanzas finitas y rangos de confianza/reputación/socios/aforo/entradas, plantel ≥ 11, tablas: Σgf = Σgc, pts = victorias×puntos + empates − sanción, pj = g+e+p). Corridas: 2 semillas × 70 semanas × Chile+Argentina; 10 temporadas (520 semanas, `LARGO=1`, 131 muestras); 6 casos absurdos (plantel vacío, saldo ±2 000 M, todos ovr 1, sin libres, 3 jugadores) × 6 semanas. Más los bancos especializados economía, mercado_contratos y calendario_competiciones: 0 fallos.

- [A4-GESTION-001] (repaso 5, gravedad: bajo) Falso positivo propio, no fallo del juego: con 10 temporadas el invariante «pts = 3g + e» saltó 84 veces porque la insolvencia resta puntos (`Liga.sancionar`, que ya los anota en `sancion` de la fila). Cómo reproducirlo: `LARGO=1` con la versión anterior de la sonda. `pruebas/ideas/a4_gestion_cruzado.gd:80`. Estado: arreglado (la sonda descuenta `sancion`; commit de esta rama).

Resultado: 0 fallos reales en 10 temporadas y casos extremos; no se encontró nada crítico, alto ni medio. Fuera de alcance de esta sonda (no repasado a fondo): federación y carrera del jugador con guardado a mitad (cubiertos por el banco `guardado`), ofertas/traspasos con mercado saturado.
Prueba al límite del área: `dinastia-godot/pruebas/ideas/a4_gestion_limite.tscn` (8 temporadas con guardado cada dos años, integridad,
caja −250 M, todos lesionados y sancionados, club con 48 jugadores y otro vacío, año 2099).

- [A4-GES-001] (repaso 3, gravedad: alto) Tras CERRAR UNA TEMPORADA (`jugar_temporada` + `nueva_temporada`), guardar y cargar NO devuelve el
  mismo mundo (temporadas 2, 4, 6 y 8). El banco `guardado` solo lo probaba dentro de la primera temporada. Reproducir: `a4_gestion_limite`.
  Causa: `Citas.desde_dic` guardaba las citas por REFERENCIA y `semana()` las caducaba en el sitio, estropeando los datos cargados.
  Arreglo: copia profunda al cargar (`nucleo/citas.gd`). Estado: ARREGLADO (8 temporadas con guardado exacto; en `especiales.sh`).
- [A4-GES-002] (repaso 3, gravedad: alto, cambia el juego) Quedaban OFERTAS RECIBIDAS por jugadores que ya NO eran del club (vendidos
  o libres al cerrar la temporada): se podía aceptar y VENDER a un jugador ajeno. Arreglo: `Mercado.a_dic` no guarda esas ofertas y
  `responder_oferta` no hace nada si el jugador ya no es tuyo (`nucleo/mercado_p1.gd`). Estado: ARREGLADO.
- [A4-GES-003] (repaso 3, gravedad: medio, cambia cifras) La FICHA MENTAL (ansiedad/confianza) se creaba con `Azar` al LEERLA
  (`factor_animo` en el partido): al cargar una partida salía distinta y además consumía azar según el orden de lectura. Arreglo:
  la ficha inicial sale de un hash del id del jugador y leer no la crea (`nucleo/vestuario_p1.gd`). `igualdad_mundo` → 31094042.
  Estado: ARREGLADO.
- [A4-GES-004] (repaso 3, gravedad: bajo) El EDITOR no llegaba a la media pedida cerca del suelo de 20 (6 vueltas de `_cuadrar_media`
  no bastaban: los atributos topan en 20); fallo intermitente del banco según el azar. Arreglo: 40 vueltas (`nucleo/editor.gd`). ARREGLADO.
- [A4-GES-005] (repaso 1, gravedad: alto) NEGOCIACIÓN: cuando un club RIVAL se lleva al jugador en plena mesa («rival_traspaso» /
  «rival_firma»), solo se cambiaba `jugador.club_id`: el jugador SEGUÍA en el plantel del club viejo y no aparecía en el del rival
  (dos fuentes de verdad distintas; el club viejo lo seguía alineando). Además, si el jugador cambiaba de club mientras la mesa
  seguía abierta, cerrar el fichaje lo dejaba en DOS planteles. Arreglo: `_se_lo_lleva` (soltar + fichar de verdad) y la mesa se
  rompe si el jugador ya no está en el club con el que hablabas (`nucleo/negociacion.gd`). Prueba en `a4_gestion_limite`. ARREGLADO.
- [A4-GES-006] (repaso 2, gravedad: bajo) `clau_descenso_entreno` (banco `plantel_cantera`) fallaba según el ORDEN del azar: con 12
  juveniles la media del plan por defecto saltaba de +3,6 a +2,8 (suelo 3,0) solo porque A4-GES-003 dejó de gastar azar al leer
  la ficha mental. Arreglo: 6 semillas (24 juveniles). Cifras con la muestra grande: plan por defecto +3,4 (el dueño pidió +4-6) y
  buen plan +5,7 con un máximo de +11 (pidió ≤ +8; el freno de `Entrenamiento.freno_temporada` es probabilístico y la curva anual
  `ProgresoJugador.anual` suma aparte). Prueba: ARREGLADA. Calibración: SALDADA (4-11, repaso 5): `Entrenamiento` 0,10→0,13 y 0,014→0,018, umbral del freno 4/6 y curva 0,5-0,2·sobra: con 6 semillas el plan por defecto da +4,2 (pedido +4-6) y el buen plan +7,1 de media, p90 +10, máx +10 (pedido ≤ +8 de media); la prueba vuelve a exigir +4-6 y ≤ +8. TOPE DURO añadido a petición de la líder: `Entrenamiento.TOPE_TEMPORADA` = +6 de entrenamiento por temporada (semanal, mentorías y probabilidad semanal cuentan en `_subidas`) + hasta +2 de la curva anual = nunca más de +8; medido: por defecto +4,3 (máx +8), buen plan +6,1 (máx +8); la prueba exige máx ≤ +8; `igualdad_mundo` actualizada (689438746, era 194965960).
- [A4-GES-007] (caza, gravedad: alto, cambia el juego) CEDIDOS: mientras está cedido el jugador figura en el plantel del club que lo
  recibe, y nadie lo miraba: (a) la IA podía COMPRÁRSELO a ese club (que cobraba por un jugador prestado) y al acabar la cesión volvía a
  su dueño, con el comprador sin jugador ni dinero; (b) te llegaban OFERTAS por un jugador que solo tienes cedido (vendías algo ajeno);
  (c) podías negociar por un cedido y pagarle al club que lo tiene prestado. Arreglo: `Mercado._cedido` en `_buscar_objetivo`,
  `buscar_oferta_por_mi_jugador` y `responder_oferta`; `abrir_negociacion` lo rechaza con frase traducida. Prueba en `a4_gestion_limite`. ARREGLADO.
- [A4-GES-009] (caza, gravedad: medio, cambia el juego) CONTRATOS DE LOS CEDIDOS: vencían ANTES de que volvieran (`nueva_temporada`:
  contratos y luego `Cesiones.resolver`) y decidía el club donde estaba, no su dueño: un jugador de la IA cedido a tu club se iba LIBRE
  si tú no lo renovabas (la IA renueva ~88 %), y uno tuyo cedido a la IA lo «renovaba» un club que no era el suyo. Arreglo:
  `_vence_contrato` (mundo_p6 y mundo_p7) decide con el club DUEÑO de la cesión. Prueba en `a4_gestion_limite` (de 17 se iban 17; ahora 0). ARREGLADO.
- Sin hallazgos: integridad del mundo en 8 temporadas (un club por jugador, club_id, libres, contratos, sueldos, edades, medias, cajas,
  planteles, ligas y divisiones); caja a −250 M seis semanas; club con todos lesionados y sancionados (saca 11); club con 48 jugadores y
  otro vacío; año 2099.

### Repaso 5, segunda tanda (cesiones y ventas al límite)
Sonda `pruebas/ideas/a4_gestion_cesiones.tscn` (en `especiales.sh`): 2 semillas, cesiones simples/con opción/con obligación de todo el plantel + 110 semanas + `resolver`; y ventas con monto 0, negativo, 10¹², 0/50/100 % y −20 % de futura venta, a sí mismo. 0 fallos: nadie en dos plantillas ni perdido, ninguna cesión queda viva, el plantel no baja de 18.

- [A4-GESTION-002] (repaso 5, gravedad: bajo) `Cesiones.vender` no comprueba que el comprador tenga dinero ni que `monto` sea positivo: con comprador a 0 y monto 10¹² el comprador queda en −10¹² (y con monto negativo el vendedor paga). Cómo reproducirlo: `a4_gestion_cesiones` (caso `[999999999999, 0]`). `nucleo/cesiones_p2.gd:228`. Los llamadores reales (`mercado_p1.gd:402`, `insolvencia.gd:102`) sí filtran por saldo, salvo que la oferta recibida (`ofertas_recibidas`) se acepta DESPUÉS de crearse y el comprador pudo gastar entretanto. Estado: ARREGLADO por el líder (A4-GES-008): `vender` rechaza montos negativos y `responder_oferta` deja caer la operación si el comprador ya no tiene el dinero al aceptar.

### Repaso 5, tercera tanda (mercado saturado y federación)
Sonda `pruebas/ideas/a4_gestion_mercado_fed.tscn` (banco `mercado_contratos`): 200 compradores por semana × 40 semanas (688 traspasos; nadie duplicado, planteles de la IA entre 19 y 26, ningún cedido traspasado, saldos enteros); federación: todas las mociones en las opciones a/b/inválida con asambleas de 0, 1 y 20 clubes, casos con fechas 0/negativas/100 000 y sin jugador, antidopaje con plantel vacío, playoffs con tablas de 0/3/4/8 filas y con clubes inexistentes. 0 fallos.

- [A4-GESTION-003] (repaso 5, gravedad: bajo) `Federacion.abrir_caso` no acota `fechas` (100 000 deja al jugador suspendido para siempre) y `votar` con una opción distinta de «a» (p. ej. «zzz») cuenta como «b» sin avisar. Los llamadores reales pasan 1-10 fechas y las opciones «a»/«b»; sin camino real al fallo. `nucleo/federacion_p1.gd:275`, `federacion_p2.gd:11`. Estado: arreglado (`abrir_caso` acota las fechas a 0-`MAX_FECHAS` = 40; `votar` rechaza y deja abierta la votación si la opción no es «a» o «b»; `a4_gestion_mercado_fed` lo comprueba).

### Repaso 5, cuarta tanda (noticias y traducción)
Sonda `pruebas/ideas/a4_noticias_idiomas.tscn` (en `especiales.sh`): recoge todas las noticias que emiten las señales `noticia` del mundo en 110 semanas (469 frases distintas con las plantillas de imprevistos y lesiones insólitas) y las pasa por `Idiomas.t` en los 8 idiomas.

- [A4-GESTION-004] (repaso 5, gravedad: medio, cambia lo que se ve) Las ~240 `noticia.emit("…")` del núcleo salen en castellano con nombres y cifras ya puestos; la interfaz sí las traduce al mostrarlas (`Idiomas.t` en el registro, el correo y el móvil), pero solo las frases con clave exacta o patrón: 21 de 423 noticias (5 %) se veían en castellano en cualquier idioma (los 42 imprevistos y las 14 lesiones insólitas con nombre, «Efecto durante N semanas», los objetivos «(11000 €)», citas del alcalde, aniversario, etc.). Cómo reproducirlo: la sonda antes del arreglo. `nucleo/idiomas.gd` (`_por_plantilla`). Estado: arreglado (commit de esta rama): central, las claves de la tabla con `%s`/`%d` traducen ahora también la frase ya formada (856 claves en inglés); +14 plantillas de lesiones, 7 frases de calendario/eras y 2 patrones («X (N €)», «X (Y): Z») en los 8 idiomas. Resultado: 0 de 469 con aspecto de castellano en los 8 idiomas; el banco `idiomas` sigue en 0.

### Repaso 5, quinta tanda (directiva, junta y prensa)
Sondas `a4_gestion_directiva` (en el banco `club_directiva`: objetivos de las 29 ligas de los países generados en 6 mundos, 1000 derrotas/500 victorias, cierres con puestos 0/−3/500, dueño que no puede ser despedido, 60 trimestres de junta con respuestas a/b/inválida en 4 situaciones) y `a4_gestion_prensa` (15 ruedas encadenadas con índices −1/99 y tiempos −5/0/10⁹ s, abrir con otra abierta, delegar a media rueda, previa forzada, club sin plantel, 120 semanas con ánimo y relación en 0-100). 0 fallos salvo lo siguiente.

- [A4-GESTION-005] (repaso 5, gravedad: medio, cambia cómo se juega) La junta repartía DIVIDENDOS aunque el club estuviera en números rojos o sin caja: aceptar «Repartir dividendos» bajaba el saldo de −5 000 000 a −7 360 009 (nada en `pantalla_despacho.gd` ni `citas.gd` lo impedía). `nucleo/junta.gd` (`resolver`, rama «dividendos»). Estado: arreglado (commit de esta rama): se paga como mucho lo que haya en caja (`min(monto, max(saldo, 0))`), con texto propio para pago parcial y para caja vacía (traducido en los 8 idiomas); el saldo ya no baja de 0 por dividendos. Prueba: `a4_gestion_directiva`.

### Repaso 5, sexta tanda (entrenamiento, lesiones, médico y maestría)
Sonda `pruebas/ideas/a4_gestion_entrenamiento.tscn`: 12 temporadas con el plan más duro (técnico, «al límite», 3 prioritarios), 60 lesiones encadenadas con severidades 0/1/2/99/−3, chequeo de fatiga con carga 0/−5/10⁹, recuperación con 0 semanas, terapia con caja 0, en rojo y repetida, maestría hasta el nivel máximo en las 15 categorías, árbol del DT sin puntos/con 1000/inexistente/repetido. 0 fallos salvo lo siguiente.

- [A4-GESTION-006] (repaso 5, gravedad: bajo) `Medico.riesgo_por_fatiga` devolvía una «probabilidad» sin tope (con carga 10⁹ salían 9·10⁷): inocuo para `Azar.suerte`, pero la ficha o el informe podrían mostrar porcentajes absurdos. `nucleo/medico_p1.gd:298`. Estado: arreglado (commit de esta rama): tope 1.

### Repaso 5, séptima tanda (estadio y club)
Sonda `pruebas/ideas/a4_gestion_estadio.tscn`: todas las obras con 5 reputaciones (0/40/100/−5/1000) × 3 cajas (2 000 M/0/en rojo) × 60 semanas (nivel ≤ máximo, cobro exacto, rechazo sin tocar la caja, mantenimiento e ingresos ≥ 0, dos obras a la vez, obra inexistente); estadio propio con aforos 0/−5/10⁹, reformas con campos/valores inválidos, `niveles` 0/−3/99, sin caja y todos los presets; taquilla con precios 0/−3/10⁶, socios 0/−5/10⁶ y aforos 0/−5/10⁹ (28 combinaciones × 8 semanas).

- [A4-GESTION-007] (repaso 5, gravedad: bajo) `Instalaciones.coste` y `mantenimiento_del_mes` fuera de reputación 0-100 daban NaN/infinito (con rep 1000: coste −9 223 372 036 854 775 808 → «cobrar» una obra INCREMENTABA la caja; con rep −5, igual). La reputación real vive en 0-100, así que solo se llega con datos corruptos o un editor. `nucleo/instalaciones.gd:119,197`. Estado: arreglado (commit de esta rama): reputación acotada a 0-100.
- [A4-GESTION-008] (repaso 5, gravedad: bajo) `Mundo.estimar_taquilla` con un aforo negativo devolvía asistencia negativa (−5 espectadores). Mismo caso: solo con datos corruptos. `nucleo/mundo.gd:153`. Estado: arreglado (commit de esta rama): asistencia ≥ 0.
- Lo demás, sin fallo: obras sin caja nunca arrancan, el estadio propio recorta las bandejas a 1-5, la caja no se desborda con precio 10⁶ ni socios 10⁶, ni baja de socios en 8 semanas con precio 0.

- Nota (4-11, tope de entrenamiento): la especial «el entrenamiento se nota» (`j9_entrenamiento`) dio +9 (técnico) contra +10 (normal) con UNA semilla y ~10 jóvenes: ruido del azar tras mover la calibración. Ahora suma 8 semillas (técnico +59 contra +54 normal, al límite +24 contra suave −7).

### Repaso 5, octava tanda (museo, trofeos, academia y ojeadores)
Sonda `pruebas/ideas/a4_gestion_museo_cantera.tscn`: museo con 0 y 500 trofeos (orden por año, fichas −1/0/10⁶, planta 3 con 5 contextos absurdos, ida y vuelta por el guardado: 500 → 500 y mismos 502 hitos), 1000 vitrinas montadas; academia: captar con índices −1/99 999 y sin caja, cambiar con ids/campos/valores inválidos, entregar fuera de edad, camada de 0 y de 200 (12 semanas en 47 ms, guardar/cargar conserva a los 200, 5 fines de temporada), 20 temporadas del mundo; ojeadores: análisis y academias internacionales sin caja y en rojo, máximos, venta, presupuesto negativo, hallazgos ≤ 8.

- [A4-GESTION-009] (repaso 5, gravedad: bajo) `MuseoVitrinas.cercana` devolvía la PRIMERA vitrina dentro de 1,5 m, no la más cercana: con vitrinas juntas (muchos trofeos) E abría la ficha de la vecina. `visor/museo_vitrinas.gd:9`. Estado: arreglado (commit de esta rama): se devuelve la más cercana; `s8_museo_vitrinas` sigue en 0.
- Sin fallo: el resto del museo, la academia y los ojeadores (nada se desborda, todo rechazo deja la caja intacta).
- Nota de proceso: tras fusionar la rama de la líder, `escala_movil.gd` daba «Identifier PantallaMovil not declared» hasta correr `godot --headless --import` (clase nueva sin importar; regla de CLAUDE.md).

### Repaso 5, novena tanda (el mundo a muy largo plazo)
Sonda `pruebas/ideas/a4_deriva_larga.tscn` (`DERIVA_TEMP`, `DERIVA_PAISES`, `DERIVA_SEMILLA`, `DERIVA_CLUB`; en `especiales.sh todo`): una foto por temporada sin tocar nada. Medido: **30 temporadas × Chile+Argentina** (≈ 2,5 s por temporada) y **50 temporadas × Chile** (≈ 1,6 s): valoración media 61,1 → 61,1 (±0,5 todo el tiempo), edad media 26,9 → 27,0, valor medio de la IA ×1,50 desde t10 y plano, sueldo medio ×1,12-1,23, caja mediana de la IA 0,9 → 2,4 M (0 clubes en rojo de 48), plantillas siempre 24-29, libres estables en 80, 85+ entre 1 y 13 (sin tendencia), goles por partido 2,7-3,1, guardado 814 → 1 700 KB en 30 años (se aplana: 1 575 KB en t20) y 574 → 1 375 KB en 50. Nada se dispara ni se hunde.

- [A4-GESTION-010] (repaso 5, gravedad: medio, BALANCE, propuesta con números) **El campeón de la Primera se eterniza.** `mundo_p6.gd:165` suma +1 de reputación al campeón (tope 96) y nada la baja (solo la insolvencia): el club en cabeza llega a 96 y gana casi todo. Medido en 30 temporadas, Chile, 3 semillas: Lautaro FC 25-28 títulos de 30 (rachas de 21-30 años); con CHI+ARG la semilla 2026 dio UN solo campeón en las últimas 15 (Argentina 3, la B de Chile 10-15, sana). Con otro club al mando pasa lo mismo con quien esté arriba (Precordillera 10 seguidos). No es un fallo de código: es un bucle de realimentación (reputación → reposición/mercado/caja → más títulos → más reputación). **Probado y descartado:** que la élite que no gana pierda reputación (rep > 85/90: empeora, 24-30 títulos de 30, porque debilita a los rivales). **Probado y propuesto:** tope de la reputación por título en 90 (`clampi(campeon.rep + 1, 40, 90)`): títulos del mayor ganador 18/26/22 de 30 y rachas máx 6/11/7 (antes 25-28 y 21-30); con 92: 24/21/20 y rachas 10/6/8. Queda un trío dominante (Lautaro/Andina/Precordillera), parecido al Colo-Colo/U/UC real. Para quitar el resto habría que tocar cómo pesa la reputación en la reposición de plantillas (`mundo_p6.gd:400-406`: `ovr = rep − 20 …`) o en el mercado. Estado: **pregunta al dueño / decisión del líder** (cambia las igualdades del mundo: `igualdad_mundo` se actualizaría). El experimento NO está en el código.
- Sin fallo (a vigilar en cada cambio de balance): todo lo demás de la lista de derivas.

- **A4-GESTION-010, aplicado (orden de la líder, 4-11):** (1) tope de reputación por título 96 → 90 (`mundo_p6.gd`); (2) **segunda causa hallada**: el repuesto de plantilla seguía a la reputación 1 a 1 (`ovr = rep − 12`: rep 90 → 78 contra rep 78 → 66), ahora `62 + 0,3·(rep − 74)` (`PENDIENTE_REPOSICION`). Descartado: el mercado (sin él, igual o peor: 17-22 títulos), que la élite pierda reputación (peor). Medido, 30 temporadas, Chile, 5 semillas (títulos del mayor ganador de 30 / racha máxima): ANTES (tope 96) 25-28 / 21-30; solo tope 90: 18, 26, 22 / 6, 11, 7; + pendiente 0,6: 15, 19, 15, 23, 23 / 8, 7, 4, 16, 8; + **pendiente 0,3 (aplicada): 16, 17, 16, 15, 17 / 7, 5, 9, 5, 6**; pendiente 0: 19, 18, 22, 18, 23 / 6, 7, 9, 9, 7 (no mejora). Queda un trío dominante, algo por encima del objetivo (≤ 12-15 y rachas ≤ 6-8): el resto del dominio viene de la plantilla inicial y de la caja, fuera de este alcance. `igualdad_mundo` (689438746) e `igualdad_motor` no cambian (no llegan al tope ni a la reposición con la pendiente nueva); `eq_diez_temporadas` (balance 10 temporadas × 3 semillas) en 0 fallos; el mundo mantiene su nivel (ovr 58,6 → 58,5, edad 26,9 → 26,7).
- Nota (`a4_limite_mundo`): agotaba los 600 s de `especiales.sh` en este contenedor (392 s la primera mitad: ciudad completa en software, la primera apertura compila sombras y shaders). Partida en 3 con `A4_PARTE=1|2|3` y tiempos impresos: fugas 189 s, calidad y horas 41-187 s, estadios y tráfico 147 s: todas < 300 s.
