# Auditoría de contenido: Dinastía frente al fútbol profesional del mundo (actualizada el 10-11-2026, cifras MEDIDAS)

Pedido del dueño (10-11): qué clubes faltan considerando todas las ligas profesionales del mundo; cuántos estadios reales faltan y cómo simplificar; cuántos jugadores, caras, escudos y uniformes faltan; qué torneos y copas faltan; celebraciones; objetivos por club; selecciones.
**Cómo se midió**: `herramientas/medir_contenido.tscn` genera el mundo completo (`Mundo.generar`, semilla 7) y lee las tablas; cifras en bruto en `docs/04_auditorias/cifras_contenido_2026-11-10.json`. Se repite con
`godot --headless --path dinastia-godot res://herramientas/medir_contenido.tscn -- --salida=ruta.json`. Con el pack real (`pack_real.json`) presente mide el mundo real; los nombres que salen aquí son los del pack.
Cifras del «mundo real»: FIFA Professional Football Report 2023 [V]; el resto [C] = conocido sin verificar ahora, [E] = estimación. Lo que no se pudo remedir hoy lo dice.

## 1. Resumen: lo que hay (medido) y lo que falta

| Magnitud | Dinastía hoy (medido) | Mundo real | Falta |
|---|---|---|---|
| Países con liga | **86** (los 28 de antes + 22 nuevos + 10 de la tanda 1 + 12 de la tanda 2 + 14 de la tanda 3: BIH, MNE, ISL, EST, KAZ, AZE, BLR, LVA, ALB, MKD, GEO, LTU, NIR, LUX) | 135 con fútbol profesional [V]; ~160 con semiprofesional [E] | **49** (o ~75) |
| Ligas | **98**: 86 primeras + 12 segundas (ARG, BRA, CHI, ENG, ESP, FRA, GER, ITA, MEX, NED, POR, TUR) | ~150 primeras; ~300 con 2.ª y 3.ª profesionales [E] | **~100 primeras + ~190 inferiores** |
| Clubes | **1.541**: 1.293 en primera y 248 en segunda | 3.986 profesionales [V]; 5.500-6.500 con 2.ª [E] | **~2.400** (estricto) a **~5.000** (con 2.ªs) |
| Clubes DENTRO de las ligas hechas | cantidades reales: ENG 20, ESP 20, ITA 20, GER 18, FRA 18, ARG 30, BRA 20, MEX 18, USA 30, JPN 20, COL 20, PER 18, KSA 18, EGY 21, TUR 18, POR 18, NED 18, POL 18… | las mismas [C] | ~0 (antes ~67). Residuo: Australia 12 de 13 reales, ligas con formato especial (play-offs) simplificado |
| Jugadores | **38.525** en clubes (DEF 8.552, MED 8.328, DEL 6.638, POR 3.207); 114 nacionalidades; OVR medio 55,3; **3.911 con nombre y datos fijos (14,6 %)** en 339 clubes del pack real | ~128.700 profesionales [V] | **~102.000** (o ~22.800 sin datos fijos dentro de lo que ya hay) |
| Caras | biblioteca de **300** mezclas (antes 72) + cara procedural; las fotos reales solo en `caras_reales.pck`: **no medible en las sesiones** (el `.pck` no está en ningún contenedor ni va al repo); último dato conocido 1.219, sin verificar; pregunta para el dueño | una por jugador | la biblioteca debe incluirse en el build público (revisar `export_presets.cfg`); fotos solo en el `.pck` por política |
| Estadios | **1.069 perfiles**; tras la variedad generada (10-11, `herramientas/estadios_variedad.py`) hay **536 arquitecturas distintas** (forma, niveles, techo, focos, fachada, pista; antes 99), 10 formas (la más repetida, «rect», baja de 688 a 330 = 31 %) y **1.067 firmas visuales distintas** con butacas y colores (0 repetidas dentro de una liga); piezas de estadio real hechas a mano: arco 1, torres de rampa 4, costillas 5, fachada curva 21, colchón 2 (~30 perfiles; 33 icónicos + 21 en las tandas de la sesión 3); aforo medio 22.794, máximo 95.000 (Comtal FC) | ~3.500-5.500 distintos [E]; ~150 icónicos [E] | los ~150 icónicos con pieza propia (hay ~30); los 725 estadios generados son variados pero no son el real |
| Escudos | **1.069** filas; **917 diseños distintos** (forma + patrón + colores + letras); 842 con patrón o letras propias | uno por club | variedad suficiente; falta que se parezcan a su club real (colores de varios clubes salen de memoria, sin verificar) |
| Uniformes | **1.029** con kit propio y **1.007** con visitante; hecha la regla **ningún uniforme repetido dentro de una liga** (herramienta `aspecto_unicos_kit.py`, prueba M-062b; 175 retoques de diseño y pantalón/medias sin tocar colores; antes 303 clubes repetían uniforme con otro de su liga); **606 combinaciones distintas** en el mundo (antes 434); 952 con butacas de color propio | uno o tres por club | el resto de repeticiones es entre ligas distintas (válido); falta fidelidad al real en los 175 retocados |
| Historia de club | 1.069 filas de `HISTORIA_CLUBES` (fundación, apodo, estadio, palmarés) | — | — |
| Idiomas | 9 | — | no se suman más (orden 5) |

## 2. Torneos

| Torneo | Hoy | Falta |
|---|---|---|
| Copas nacionales | 50 nombres de copa (`COPA_NOM`); se simulan las de **todos** los países, con supercopas y palmarés del mundo (pantalla Competiciones); la de tu país se juega | las de los 85 países sin liga |
| Fases finales de liga | **15 países** (EGY, ARG, USA, BEL, SCO, DEN, SUI, AUT, GRE, CZE, ROU, SRB, ISR, SVK, BUL) con grupos/zonas/conferencias/play-offs reales | NED/POR/TUR…: play-offs menores; MLS (1 fecha interconferencias) |
| Supercopas nacionales | en todos los países con copa (resultado simulado) | jugarlas |
| Continentales de clubes | **6 principales** (Libertadores, Champions, Asia, África, Oceanía, Concacaf) más Sudamericana y Europa League, con formato real, supercopas continentales | previas de la Libertadores y Leagues Cup |
| Torneos FIFA de clubes | **Mundial de Clubes de 32** (8 grupos + eliminatorias) y **Copa Intercontinental** (5 campeones; Challenger Cup, Derbi de las Américas y final) | — |
| Selecciones | **69 selecciones** (11 África, 11 Asia, 7 Concacaf, 14 Sudamérica, 2 Oceanía, 28 Europa; Rusia suspendida: solo amistosos). **Mundial de 48** jugado de verdad (grupos y eliminatorias), 6 continentales de selecciones con partidos, **Finalissima** y **Olímpicos** | Nations League (UEFA y Concacaf) y eliminatorias: no existen |
| Cargo de seleccionador | **existe** (`CargoSeleccion`): llaman selecciones por prestigio; cargo doble con el club; con él se juegan los torneos de esa selección | convocatoria de 26 con el mundo entero y amistosos jugables |
| Calendario del Mundial | unificado (Selecciones `ANIO_BASE` 2026, ciclo de 4 años, y `Calendario.torneos` usan 2026, 2030, 2034…; Eurocopa y Copa América en 2028, 2032…) [confirmado por la sesión principal] | — |

## 3. Qué FALTA, en números (lista corta)

1. **49 países** con liga profesional (de 135) y **~100 primeras divisiones**.
2. **~2.900 clubes** profesionales (~5.000 con segundas y terceras) y **~102.000 jugadores**.
3. Las **211 selecciones** FIFA: hay 86, **todas con jugadores propios del mundo** (0 sin convocables); faltan 125.
4. **Nations League y eliminatorias** (no existen); las copas y supercopas de los otros países se simulan por resultado, no se juegan.
5. **Estadios**: 536 arquitecturas para 1.069 clubes (≈ 2 por arquitectura; antes 99) y solo ~30 con pieza propia de estadio real; **uniformes**: 606 combinaciones para 1.029 kits, sin repeticiones dentro de una liga.
6. Caras: 300 mezclas frente a 26.725 jugadores; el build público debe llevarlas.

## 4. Celebraciones

- Gol: 16 festejos con nombre (avión, de rodillas, corazón, besa el escudo…), unas 25 animaciones, una por jugador; el asistidor también celebra; realización con 4 planos.
- Títulos: una sola vuelta olímpica (copa, confeti, vuelta y ola), igual para liga, copa y continental.
- Faltan: festejos por tipo de título (levantar la copa en el palco o el escenario, entrega de medallas, foto de plantilla, mantear al DT, champán en el vestuario, desfile en autobús, pasillo de campeón del rival), celebraciones de ascenso y de salvación, festejos de grupo coreografiados y la grada con tifos en una final.

## 5. Objetivos por club

- Hoy: 5 metas fijas según tu puesto en la reputación de tu liga (campeón, top 4, top 8, evitar el descenso, ascenso). Iguales en las 29 ligas: «top 4» aunque la liga dé otras plazas, y «14» aunque la liga tenga 18 equipos.
- Faltan: objetivos que dependan del club (historia, palmarés, finanzas, masa social, cantera), varios a la vez (liga, copa, continental, economía, cantera, estilo), ajustados al tamaño de la liga y a sus plazas continentales reales, y objetivos a varias temporadas (proyecto).

## 6. Caras de la alineación (arreglado)

Causa: el campo de la plantilla pedía la cara a 68 px y la pizarra a 42, y el encuadre de solo cabeza llegaba hasta 40: salían como busto, con la cara pequeña y cortada en el aro. Arreglado el 10-11 (`Retrato3D.ALTO_CABEZA` 70 y encuadre algo más abierto), revisado con 3 clubes distintos.

## 7. Cómo simplificar el trabajo (propuesta)

1. **Un formato de datos por país** (`datos/paises/<PAIS>.json`: ligas, divisiones, clubes con `[nombre, ciudad, colores, reputación, aforo, fundación]`, copas, plazas continentales). Con él, todo lo demás se GENERA:
   - el escudo (forma, patrón y figura desde los colores y el nombre, como hoy);
   - el uniforme (diseño desde los colores);
   - el estadio (perfil paramétrico desde el aforo y la reputación, como hoy);
   - los jugadores (nombres desde una bolsa de nombres y apellidos por país, que ya existe en parte).
2. **Por niveles**, no todo a la vez:
   - Nivel 1, unas 20 ligas grandes: completas con sus 18-20 clubes, 2.ª división y jugadores fijos.
   - Nivel 2, unas 60 ligas: solo la 1.ª división, con jugadores generados.
   - Nivel 3, el resto: ligas «de fondo» que solo alimentan el mercado y las selecciones.
3. **Estadios**: el constructor paramétrico ya existe. Para los ~150 icónicos basta una fila más rica (pieza característica: arco, cubierta, color de butacas, fachada); para el resto, el perfil por aforo. Hay estadios compartidos (Milán, Roma, Génova).
4. **Caras**: ampliar la biblioteca de mezclas (72 → 300-500) y decidir si se publica (hoy queda fuera del build público), además del procedural mejorado; las fotos reales siguen solo en el `.pck`.
5. **Herramienta** `herramientas/importar_pais.py`: crea el JSON de un país desde una tabla simple (CSV) con los nombres modificados, para que cargar un país nuevo lleve minutos.

## 8. Fuentes externas

- FIFA Professional Football Report 2023: https://inside.fifa.com/news/fifa-publishes-professional-football-report-2023
- Formato de la Champions 2025-26: https://www.beinsports.com/en-us/soccer/uefa-champions-league/articles/how-does-the-2025-26-champions-league-format-work-everything-you-need-to-know-about-uefa-s-new-system-2025-08-01
- Copa Libertadores 2025: https://en.wikipedia.org/wiki/2025_Copa_Libertadores
- Leagues Cup 2025: https://worldsoccertalk.com/amp/news/leagues-cup-2025-new-format-full-schedule-and-all-36-teams-confirmed
- AFC Champions League Elite: https://www.flashscore.com/news/soccer-afc-champions-league-asian-champions-league-elite-to-expand-from-24-teams-to-32-in-2026-27/OM9LN5fT/
- CAF Champions League 2025-26: https://www.cafonline.com/caf-champions-league/news/everything-you-need-to-know-about-the-202526-totalenergies-caf-champions-league/
- Mundial de Clubes 2025: https://www.wikipedia.com/wiki/2025_FIFA_Club_World_Cup
- Copa Intercontinental 2025: https://inside.fifa.com/en/news/intercontinental-cup-2025-dates-venues-first-match-ups-confirmed
- Listas de clubes por división en la UEFA (Wikipedia): https://en.wikipedia.org/wiki/List_of_top-division_football_clubs_in_UEFA_countries

Notas: `dinastia-godot/AUDITORIA_CLUBES.csv` está desfasado (384 clubes, sin NED, POR, BEL, CRO ni DEN): no usarlo; su generador es `pruebas/auditoria_clubes.gd`. Datos reales solo en `pack_real.json` (regla del proyecto): lo nuevo, con nombres modificados.

## 9. Avance del 10-11 (noche), tras la auditoría

| Magnitud | Antes | Ahora |
|---|---|---|
| Clubes con datos propios | 402 (todas las ligas a 16) | **457** con su cantidad REAL por liga (+64 genéricos de POR, BEL, CRO y DEN en `paises_extra.json`): ENG, ESP, ITA, BRA, COL y JPN 20; GER, FRA, MEX, KSA y NED 18; EGY 21; PER 18; ARG y USA 30 (a una vuelta); PAR, KOR y AUS 12; URU, ECU, BOL, MAR, RSA y CHI 16 (+16 en la B) |
| Clubes reales de primera | descendidos dentro y ascendidos fuera | 93 añadidos y 38 descendidos fuera (`herramientas/ligas_completas.py`), con historia, estadio, aspecto y estilo; 22 clásicos nuevos |
| Formación y estilo | los 466 iguales (4-3-3, todo «medio») | cada club el suyo de la vida real (`EstiloClub`, 11 formaciones y 10 estilos) |
| Escudos | 402 genéricos «parecidos» por colores | 134 reescritos a mano parecidos al real + 8 figuras nuevas (sesión 2); el resto, genéricos |
| Uniformes | 147 con diseño propio | uniforme base retocado en las ligas grandes y 2.º uniforme en 330 clubes (sesión 2) |
| Caras | piel/pelo/barba al azar en 2.971 jugadores fijos sin medir | rasgos por país medidos en las caras reales (`CaraPrior`): cara coherente 5 % → 11 % (sin fotos en lo público) |
| Copas | solo la de tu país | las de todos los países, con supercopas y palmarés del mundo (pantalla en Competiciones) |
| Selecciones | 37, fuerza sin partidos | 63 (hoy 69), equipos de verdad, Mundial de 48, continentales jugados, cargo de seleccionador con convocatoria, fechas FIFA y torneos jugables |
| Jugadores reales con nombre | 4.311 | 3.911 (los de los 38 descendidos salen con su club) |

Hecho después (10-11, sesiones 6 y 7): 50 países y 62 ligas (22 países nuevos con `importar_pais.py`), 1.069 clubes con aspecto propio, 24 segundas con escudo/uniforme/butacas, formatos reales de los continentales, supercopas continentales, Mundial de Clubes de 32, Copa Intercontinental, fases finales de liga en 15 países y 69 selecciones. Las cifras de la sección 1 sustituyen a las de esta tabla.
Pendiente: 85 países sin liga, estadios icónicos con pieza propia, más piezas de estadio real (hay ~30 de ~150), Nations League y eliminatorias, y los colores de memoria sin verificar (Persepolis visitante, Al Gharafa, Al Sadd, Al Rayyan, Craiova, Viking, Krasnodar y CSKA visitante, Sharjah, Al Jazira, Zorya, Metalist, venezolanos; segundas: Alvarado, Colegiales, Dep. Maipú, Est. Buenos Aires, Güemes, Tepatitlán).

Variedad visual (10-11, tarde): hoja de 12 estadios generados de 6 países (TUR, POL, SWE, KOR, CHN, SRB) con la cámara real y Forward+: `docs/04_auditorias/capturas/estadios_generados_2026-11-10.jpg` (se repite con `TANDA=5 herramientas/captura.sh res://pruebas/captura_estadios_iconicos.tscn`).
Pregunta para el dueño: cuántas fotos reales de caras hay hoy en `caras_reales.pck` (solo él puede medirlo; último dato conocido 1.219, sin verificar).

Tanda 1 de «países sin liga» (10-11, noche): elegidos con datos (las 19 selecciones sin liga tenían 0 jugadores convocables; se tomaron 10 por ranking FIFA [C] y por cobertura: África tenía 3 ligas y la CONCACAF 2). Hoy el mundo tiene 60 países, 72 ligas, 1.215 clubes y 30.375 jugadores; 582 arquitecturas de estadio distintas, 0 uniformes repetidos por liga, 1.066 escudos distintos. Datos de clubes de memoria (sin verificar en la web): colores, aforos y composición exacta de la temporada.

Tanda 2 de «países sin liga» (10-11, noche): Gales, Honduras, Irak, Jamaica, Jordania, Malí, N. Zelanda, Panamá, Uzbekistán (las 9 que seguían con 0 convocables) más Finlandia, Eslovenia y Chipre. Hoy: 72 países, 84 ligas, 1.375 clubes, 34.375 jugadores, 72 selecciones sin ninguna a 0 convocables, 641 arquitecturas de estadio, 1.226 escudos distintos, 0 uniformes repetidos por liga. VERIFICADO en Wikipedia (clubes, estadio y aforo 2025-26): WAL, SVN, JOR, CYP, IRQ, UZB, FIN, JAM, HON. NO verificado: MLI (lista de 2021-22), PAN (estadios y aforos de memoria), NZL (sin aforos), Aris Limassol, Génesis y Platense (estadio); y de todos los países los colores, fundaciones y apodos.

Tanda 3 (10-11, noche): 14 países de la UEFA (BIH, MNE, ISL, EST, KAZ, AZE, BLR, LVA, ALB, MKD, GEO, LTU, NIR, LUX). Hoy: 86 países, 98 ligas, 1.541 clubes, 38.525 jugadores, 86 selecciones (0 a 0 convocables), 673 arquitecturas de estadio, 1.391 escudos distintos, 0 uniformes repetidos por liga. Verificado en Wikipedia: los 14 (clubes, estadio y aforo; Flora y los estadios de MKD inferidos; ISL sin aforos). Bielorrusia no está suspendida: solo vetada como local (según Wikipedia).

## Tanda 4 de países (10-11)
+16 países (THA, IDN, VIE, IND, MAS, BHR, OMA, COD, BFA, ZAM, GUI, KEN, ARM, MDA, ESA, GUA): ahora **102 países, 114 ligas, 1.762 clubes, 44.050 jugadores, 102 selecciones**; estadios repetidos en una misma liga: 0. Elegidos por peso (selecciones y ranking), empezando por Asia y África.
Verificado en Wikipedia (2025-26): THA, IDN, VIE, IND, MAS, BHR (sin estadios por club), ZAM, KEN, ARM, ESA, GUA. NO verificado: OMA (lista 2024-25), BFA y GUI (2021-22), MDA (parejas club-estadio inferidas), COD (16 de 31 clubes, aforos estimados). Colores, fundaciones y apodos: de memoria.
