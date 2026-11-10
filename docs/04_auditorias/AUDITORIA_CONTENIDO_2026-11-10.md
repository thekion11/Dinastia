# Auditoría de contenido: Dinastía frente al fútbol profesional del mundo (10-11-2026)

Pedido del dueño (10-11): qué clubes faltan considerando todas las ligas profesionales del mundo; cuántos estadios reales faltan y cómo simplificar; cuántos jugadores, caras, escudos y uniformes faltan; qué torneos y copas faltan; celebraciones; objetivos por club; selecciones (aceptar una selección y jugar sus torneos).
Fuentes: lectura de los datos y el código del juego (solo lectura) e investigación web (FIFA Professional Football Report 2023, Wikipedia, confederaciones). [V] = verificado, [C] = conocido sin verificar ahora, [E] = estimación.

## 1. Resumen: lo que hay y lo que falta

| Magnitud | Dinastía hoy | Mundo real | Falta |
|---|---|---|---|
| Países con liga | 28 | 135 con fútbol profesional (FIFA) [V]; ~160 con semiprofesional [E] | **107** (o ~130 con semiprofesional) |
| Ligas | 29 (solo Chile con 2.ª división) | ~150 primeras divisiones; ~300 contando 2.ª y 3.ª profesionales [E] | **~120 primeras + ~150 inferiores** |
| Clubes | 466 (402 con datos propios + 64 genéricos de POR, BEL, CRO y DEN) | 3.986 profesionales (FIFA) [V]; 5.500-6.500 con 2.ª división [E] | **~3.500** (estricto) a **~6.000** (con 2.ªs) |
| Clubes que faltan DENTRO de las ligas que ya hay (todas recortadas a 16) | — | ENG 20, ESP 20, ITA 20, GER 18, FRA 18, ARG 30, BRA 20, MEX 18, USA 30, JPN 20, COL 20, PER 18, KSA 18, EGY ~21 [C] | **~67 clubes** (y 4 ligas sobran: KOR 12, AUS 13, PAR 12 reales) |
| Jugadores | 11.650 (466 × 25); 4.311 con nombre fijo (37 %) | ~128.700 profesionales [V] | **~117.000** (o ~7.300 sin nombre fijo en lo que ya hay) |
| Caras | 72 de biblioteca (mezclas, no son nadie) + cara procedural; 1.219 fotos reales solo en `caras_reales.pck` (33 % de los fijos) | una por jugador | 3.092 jugadores fijos sin foto; **el build público no lleva ni la biblioteca de 72** (excluida en `export_presets.cfg`) y cae al dibujo procedural |
| Estadios | 402 con perfil propio ESQUEMÁTICO (forma, niveles, techo, focos…), 142 con nombre real, 64 genéricos; **0 modelos individuales** | ~3.500-5.500 distintos [E]; ~150 icónicos para una 1.ª tanda [E] | **150 icónicos** como objetivo y el resto por perfil |
| Escudos | 402 con forma y patrón propios (378 con figura o letras), 64 por sorteo | uno por club | 64 + todos los clubes nuevos; los 402 son genéricos «parecidos» |
| Uniformes | 147 con diseño propio, 305 con pantalón y medias propios; 142 con fotos reales (solo base real) | uno o tres por club | ~319 diseños en lo que ya hay + todos los nuevos |

## 2. Torneos

| Torneo | Hoy | Falta |
|---|---|---|
| Copas nacionales | 28 copas en 25 países; PAR, ECU y BOL con nombre genérico; **solo se juega la copa de tu país** | las de los 107 países nuevos; que se jueguen las de todos los países (simuladas) |
| Supercopas nacionales | solo la de tu país (un partido) | las del resto (España, Italia, Alemania, Francia, Portugal, Brasil, Argentina…) |
| Segunda copa (copa de liga) | ENG, ARG y JPN alternan una por año | jugar las dos el mismo año; Taça da Liga, Scottish League Cup, J.League Cup… |
| Mundial de selecciones | se «simula» por fuerza, sin partidos; 32 de 37 selecciones | 48 selecciones (2026), partidos de verdad |
| Continentales de clubes (HECHO 10-11, sesión 6: formatos reales, supercopas, Mundial de Clubes de 32 y Copa Intercontinental) | — | solo Leagues Cup y las previas de la Libertadores |
| Eurocopa, Copa América, Copa Oro, Copa Africana, Copa de Asia, Oceanía | solo se sortea el puesto de tu país; en el calendario, solo fechas | torneos jugados |
| Nations League (UEFA y CONCACAF), eliminatorias, Finalissima, Juegos Olímpicos | no existen | todos |
| Incoherencia | el calendario muestra el Mundial en 2026 y 2030, pero el cierre de temporada lo juega en 2028 y 2032 | unificar |

## 3. Selecciones

- **No existe el cargo de seleccionador**: las ofertas de trabajo son solo de clubes (`Roles.sortear_oferta_de_club`).
- Solo hay 37 selecciones. Los convocados de tu plantilla se van 4 veces por temporada (desgaste, lesiones, moral). Los amistosos son un marcador al azar.
- **Falta todo**: ofertas de selecciones (por prestigio), doble cargo club + selección o solo selección, convocatoria (elegir 26 de los jugadores de su país en todo el mundo), partidos jugables (amistosos, eliminatorias, Nations League, torneos) y las 211 selecciones FIFA (o al menos las de los países con liga).

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
