# PLAN GENERAL — el único documento de lo pendiente (antes «plan del lunes», 24-10-2026; renombrado el 3-11)

Aquí está TODO lo que falta: lo del dueño, las fases del guion, la ruta de lanzamiento, las mejoras de código, las 356 mejoras abiertas y tus ideas que no están hechas del todo. **Lo ya hecho se borra** (queda en el historial de git). Reglas de trabajo: `CLAUDE.md`; método: `docs/01_metodo/METODO.md`; auditoría con cifras: `docs/04_auditorias/MEGA_AUDITORIA_3.md`.

Cuando algo se termine: se borra de aquí (no se tacha) tras pasar su prueba (banco / especiales / captura con la cámara real).

## ESTADO AL 12-11 MEDIODÍA (sesiones Opus 13 y 14 cerradas y ARCHIVADAS; todo en `main`)
- CI de `main` en VERDE ENTERO por primera vez (f9147058): banco, 6 especiales, Windows, Windows ligero, Linux, Android, Android armv7, Web, Web móvil, C++ Android y C++ ARM. Solo se salta el AAB de Play (falta la keystore, la lleva el dueño). Arreglos del día: CI que se cancelaba en `main`, directiva con ligas de 13 clubes, tarjetas de C4, entrada arm64 del .gdextension en el trabajo ARM y acción de exportar idempotente (Web + Web móvil).
- Sesión 13 (jugabilidad de C4, 10 bloques): resumen para el dueño en `MOTOR_LEAGUE_SOCCER_PLAN.md` («RESUMEN PARA EL DUEÑO — sesión 13»). Encendido: paciencia ante el tiro lejano, encarar por la banda, falta lateral ensayada, no entrar por detrás a toda velocidad, seguir el tiro v2 y apoyo de cara. SIGUIENTE idea medida: el ADELANTO del pase (el rival llega antes al punto; el pasador debería compararlo y darla al pie o a otro).
- Sesión 14 (lo visual del partido, 6 bloques): botas, costura cara-cuello, nuca, disputa aérea a tiempo, reacciones, aro del portador en el móvil, HUD 95 → 40 llamadas, proporciones del cuerpo y relleno de luz en pieles claras. Informe: `docs/04_auditorias/partido_visual_2026-11-12.md`. Las +44 llamadas en la cámara de TV con C4 NO son regresión (motor clásico: 200 = 200).
- Líder: menú central (pie de ayudas del mando, socios en la cabecera), ligas programadas para la próxima temporada, solo primera persona (orden 45) con mirada por dedo/ratón/stick, plantas sin bolas verdes, piel de los 88 países añadidos después.
- PENDIENTE DEL DUEÑO: prueba en el teléfono (`GUIA_PRUEBA_TELEFONO_2026-11-11.md`; ahora con primera persona y el HUD aligerado), keystore para el AAB, y decidir si se abren sesiones nuevas (aviso de uso semanal cerca del límite).

## PREGUNTAS PARA EL DUEÑO (sesiones Opus) — se acumulan aquí y se envían juntas por Calendar al llegar a 5 (orden 44); se borran al responderse
- (12-11, sesión de pulido) ECONOMÍA DE LAS LIGAS CHICAS: en Uruguay, Paraguay, Bolivia, Ecuador, Perú, Colombia y Chile casi todos los clubes empiezan la partida perdiendo plata cada año y con sueldos del 45-100 % de sus ingresos (cifras en «BALANCE MEDIDO», más abajo). ¿Es a propósito (clubes que viven de vender jugadores) o hay que bajar sueldos / subir ingresos (tele, patrocinio) en esas ligas para que se puedan sostener?

## SESIÓN 14 (12-11): LO QUE SE VE Y SE SIENTE EN EL PARTIDO — rama `sesion14-partido-visual` (informe `docs/04_auditorias/partido_visual_2026-11-12.md`)
- HECHO: botas con horma (sin dedos), costura cara-cuello (borde pegado a la piel en 3D, también peatones y personal), nuca a la altura del
  lóbulo y corte 3D de la familia del retrato; disputa aérea a tiempo (los dos que disputan saltan 0,3 s antes del contacto), reacción
  al fallo, entradas de pie variadas, acrobacias y lamentos de CMU, todo NEUTRO para la simulación de C4 (6 cruces idénticos a `main`);
  móvil: aro del portador con color de equipo y flecha de ataque, el triángulo de tu jugador ya no tapa media pantalla; fuera el fondo
  negro redundante detrás del 3D.
- FALTA: (proporciones y relleno de la cara HECHOS el 12-11, bloque 6) apariencia por país: los ficticios de Senegal salen con piel clara y pelo
  pelirrojo; reacción del infractor
  a una falta sin tarjeta; vídeo con la cámara real de los saltos y reacciones (la foto fija no muestra el tiempo); medir en el teléfono
  el coste de la interfaz del partido (107 llamadas 2D) y reducirla.

## ESTADO AL CIERRE DEL 11-11 MAÑANA (orden 42 del dueño: «guarda y registra todo») — para retomar
- Trabajo del líder SOLO (sin sesiones abiertas), todo en `main` con banco «FIN. 0 fallos», huellas `igualdad_motor` 2244399493 e `igualdad_mundo` 2180788566 sin cambios, `mem_menu_estadio` 0 y `cifras_partido` 0.
- HECHO: (1) mando táctil: el fallo de la captura NO se reproduce en `main` (Compatibility y Forward+, horizontal y vertical); (2) C4 MEJORADO con las ideas del dueño (`visor/mejoras_c4.gd`, solo en C4): dos desmarques a la vez, sprints sin balón, balones largos y balón parado (córners por desvío 20 %, centros desde la banda) → cadenas de 5+ ~0,9 → ~1,5 antes del balón parado, goles 5,2 → ~6,2, córners 4,5 → 7,8, CPU igual; detalle en `MOTOR_LEAGUE_SOCCER_PLAN.md` «Mejoras de C4»; (3) referencias del dueño (menú de PES 2020, mandos de FC Mobile) en su Drive, carpeta `Dinastia_respaldo_2026-10-24/referencias_del_dueño` (orden 41); (4) contadores del motor (`diag`) en `comparar_tres_motores`.
- SIGUIENTE (propuesto por el líder): extremos que encaren por la banda hasta el fondo (los centros en juego siguen en 0,3-0,7 por partido y casi no hay goles de cabeza); recompilar la `.dll` de Windows; comparar el menú central con el de PES; resto del vertical.
- PENDIENTE DEL DUEÑO: prueba en su teléfono con `GUIA_PRUEBA_TELEFONO_2026-11-11.md` (FPS en Mínima, motores a ciegas, mando nuevo); orientación «sensor» para el vertical; licencia del pack de Rohr; borrar las ramas viejas (listas A y B).

## ESTADO AL CIERRE DEL 11-11 MADRUGADA (orden 40 del dueño) — para retomar
- TODO en `main`: las sesiones 9 a 12 terminaron, se unieron (banco «FIN. 0 fallos», 0 scripts > 450, `igualdad_motor` 2244399493, `igualdad_mundo` 2180788566, `mem_menu_estadio` en 0, `cifras_partido` 2,75) y se ARCHIVARON. Revisiones automáticas apagadas.
- HECHO: motor **C4** por defecto en el partido jugable (el de siempre con `MOTOR_CLASICO=1`; selector A-D a ciegas en Ajustes con voto de diversión); comparador de motores (`comparar_tres_motores`); fase 4 de League (catálogo de animaciones extensible, guía de locomoción, precarga sin tirones, faltas leves, celebraciones CMU); animaciones libres (100STYLE, UAL de Quaternius con sprint y entrada deslizante, CMU con carrera, patadas y celebraciones; solo viaja lo que se usa); **mando táctil estilo FC Mobile** (4 botones fijos que cambian con la posesión, gestos por botón; capturas en `docs/04_auditorias/capturas_mando_fc_2026-11-11/`); avatares (regalo del dueño elegible y público, fuera los no realistas, Kenney borrado, personal del club con apariencia y cara propias); guía de prueba en el teléfono (`GUIA_PRUEBA_TELEFONO_2026-11-11.md`).
- SIGUIENTE: mejorar C4 con las ideas del dueño (desmarques, balones largos, balón parado, sprints sin balón) y recuperar ocasiones del híbrido de ataque (`C_ATAQUE_LEAGUE`, `C_TERCIO`, `C_CADENCIA_ESTADO` escritos y apagados); disputa aérea; recorte de clips de CMU; realismo de futbolistas con cámara real; costura cabeza-cuello de las caras.
- PENDIENTE DEL DUEÑO: la prueba en su teléfono con la guía (FPS en Mínima, motores a ciegas y el mando nuevo); licencia del pack de Rohr; borrar las ramas viejas (listas A y B); orientación «sensor» para el vertical.
- FALLO DESCARTADO (líder, 11-11): «el jugador no se mueve con el dedo» y «el botón II no abre la pausa» NO se reproducen en `main` (a8029304): `captura_tactil_partido` y `captura_tactil_movil` dan 0 fallos en Compatibility (2400×1080 y 1080×2400) y en Forward+ (32,4 m con el dedo, la pausa abre). Venía del contenedor de la sesión 11. Queda la prueba real en el teléfono.

## ESTADO AL CIERRE DEL 10-11 NOCHE (orden 37 del dueño) — para retomar
- TODO en `main`: las sesiones 2 a 8 terminaron su bloque, se unieron (banco «FIN. 0 fallos», 0 scripts > 450, `cifras_partido` 2,75 goles, `igualdad_mundo` 2180788566, `igualdad_motor` 2244399493, `probar_nativo` y `mem_menu_estadio` en 0) y se ARCHIVARON. Revisiones automáticas apagadas.
- MUNDO: 135 países, 147 ligas, 2.206 clubes, 55.150 jugadores y 135 selecciones (nombres en 9 idiomas). Datos revisados con Wikipedia y RSSSF (`docs/04_auditorias/datos_dudosos_2026-11-10.md`); colores de las 7 ligas grandes con Wikipedia.
- HECHO HOY (resumen): ligas activas; Finalissima y Juegos Olímpicos; rueda de prensa con mesa; vestuario y oficinas realistas CC0 por país; fuga de memoria del mundo arreglada; móvil: resolución 3D automática y, POR DEFECTO, Modo rendimiento, Ahorro de menús y tope de 90 FPS; iconos dibujados por defecto; versión 0.9.2 con novedades traducidas; biblioteca de caras pública; preset aparte «WebMovil» con texturas ETC2/ASTC (mismo peso que la Web de PC; falta probarlo en un teléfono); `.so` de Android (arm64) de la extensión C++; semana del mundo 1,5 → 1,3 s.
- SIGUIENTE (orden 36, por hacer): guardado de jugadores con campos fijos; grada simplificada en celebraciones (diagnóstico hecho, sesión 3); museo por títulos con mini evento; diseño propio en vertical (HECHO en parte por la sesión 8: menús y partido; faltan Ajustes, nombres del plantel, entrada, minijuegos y pasar `orientation` a sensor en `project.godot`, que decide el dueño); recompilar la `.dll` de Windows (`PASO_CPP_PLAN.md` §2g) y probar el `.so` en un teléfono; datos: Marruecos y Sudáfrica con su lista actual; muebles CC0 de prensa, enfermería y pasillos.
- MOTOR DEL PARTIDO (decisión del dueño, 11-11, en conversación casual): «solo visual» significaba **A) hacer YA el motor nuevo de League-Soccer**, que el dueño considera mejor en casi todo, empezando por la FASE 4 (movimiento guiado por animaciones, `MOTOR_LEAGUE_SOCCER_PLAN.md` §5). CRITERIO: **jugabilidad y diversión por encima de las cifras reales** (remates, goles por partido): las cifras del fútbol real son referencia, NO la meta de calibración. Pide además una COMPARACIÓN de TRES motores: el nuestro, el de League y uno COMBINADO (lo mejor de cada uno), con (1) un selector de motor en Ajustes para que él juegue los tres a ciegas (A/B/C) y elija por cómo se sienten; (2) cifras de diversión: ocasiones, regates y duelos, cadenas de pases, variedad de goles, cambios de marcador, tiempo sin parar; (3) capturas y vídeo con la cámara real, lado a lado; (4) coste en su teléfono (FPS en MÍNIMA). Base ya hecha: `pruebas/comparar_motor_league.tscn` y la bandera `MotorLeague.activo`.
- AVATARES (sesión 12, informe `docs/04_auditorias/avatares_2026-11-11.md`): HECHO todo lo del encargo (inventario, no realistas fuera, avatar regalo público y elegible, persona_realista OK, Swat/Soldier/Punk solo personal, personal del club con apariencia propia). QUEDA: (a) revisar el logotipo de la camiseta del avatar regalo; (b) pulir el personal del club con caras de `BibliotecaCaras`; (c) SIGUIENTE (no empezado, la sesión 12 se cerró): realismo de los FUTBOLISTAS en el partido con la cámara real (proporciones, pelo del Drive sin atravesar la cabeza, piel/cara coherentes con CaraPrior, botas y medias), hoja de 2 partidos de países distintos y medir llamadas/memoria antes y después en MÍNIMA con `hw_modesto.sh ... -- minimo` (ya existe `pruebas/captura_futbolistas.tscn`; la medición «antes» se perdió por el `tail`: guardar el log entero).
- RESPUESTAS DEL DUEÑO SOBRE AVATARES (11-11): (1) el avatar REGALO: el dueño tiene TODAS las licencias y NO es una persona real → puede ir en los builds públicos y ser elegible; (2) `persona_realista.glb`: lo mismo; (3) Swat, Soldier y Punk: SOLO para el personal del club, NO como avatar del jugador; (4) los archivos de Kenney en LFS (`Model/`, `Animations/`): BORRADOS por orden del dueño (hecho el 11-11).
- CARAS DEL PERSONAL DEL CLUB (líder, 11-11): HECHO. Los hombres del personal llevan cada uno una cara de la biblioteca (`AparienciaPersonal._poner_caras`), la primera de su tono que nadie del club lleva, desplazada por club; las mujeres siguen con la cara clásica (las mezclas son de hombre). Prueba en `_probar_avatares_realistas`; capturas en `docs/04_auditorias/capturas_personal_caras_2026-11-11/` (`CERCA=1 FILA= MITAD=` en `captura_personal_club.tscn`). PULIR: se nota la COSTURA entre la cabeza de la biblioteca y el cuello (también en peatones); caras para mujeres.
- MOTOR ELEGIDO (dueño, 11-11, orden 39): **C4** por defecto en el partido jugable (League + nuestra decisión con balón + nuestra colocación con caché + nuestra locomoción); el de siempre, de respaldo con bandera. SIGUE MEJORÁNDOSE (sesión 9): guía de animaciones también en nuestra locomoción, faltas leves y celebraciones de CMU dentro de C4, recuperar las cadenas de pases que bajaron con la caché, más regates. Medir siempre con `comparar_tres_motores` y validar con el dueño en su teléfono. **HECHO (sesión 11):** selector A-D en Ajustes (nuestro, League, C1 y C4; C2 y C3 solo en el comparador), voto 1-5 con el motor real (`user://motor_ciego.json`), «Por defecto» = C4, `MOTOR_CLASICO=1` = el de siempre, `MOTOR_LEAGUE=1` = League, `MOTOR_PARTIDO=` fuerza uno; caché de 0,1 s de la colocación nuestra (−26 % CPU) y perfil en `pruebas/perfil_colocacion.tscn`; informe `docs/04_auditorias/comparar_tres_motores_2026-11-11.md` (5 tandas). **FALTA:** el vídeo lado a lado con la cámara real; repetir con la locomoción de la sesión 9 en C4 y con más partidos (las cadenas de 5+ oscilan ±0,5 por tanda con n = 12); los votos del dueño; medir FPS de cada letra en su teléfono; el primer paso de League tarda ~170 ms (carga del catálogo de animaciones: precargar antes del saque).
- IDEAS DEL DUEÑO PARA MEJORAR C4 (11-11). HECHO por el líder (11-11, `MejorasC4`, ver §«Mejoras de C4» de `MOTOR_LEAGUE_SOCCER_PLAN.md`): (1), (2) y (4), encendidos en C4 (cadenas de 5+ 0,9 → 1,5; goles 5,2 → 6,5; CPU igual). (3) balón parado HECHO en parte (córners por desvío 4,5 → 7,8 por partido; centros desde la banda con gente en el área). FALTA: extremos que encaren por la banda hasta el fondo (para que haya centros de verdad), cabezazos más ricos, saques de banda y faltas ensayadas. Texto original: (1) MÁS DESMARQUES (carreras al espacio y de ruptura de los que no llevan el balón); (2) BALONES LARGOS (cambios de orientación y pases largos a la espalda de la defensa) para crear más jugadas y ocasiones; (3) AFINAR LAS JUGADAS A BALÓN PARADO (córners, faltas laterales y directas, saques de banda: colocación, bloqueos, segundo palo, rechaces); (4) SPRINTS SIN BALÓN (que los compañeros aceleren de verdad al atacar el espacio y al replegar). Medir cada una con `comparar_tres_motores` (C4 frente a C4 + idea), con la diversión como criterio, y vigilar la CPU en el móvil.
- MANDO TÁCTIL AL ESTILO FC MOBILE (dueño, 11-11): 4 botones fijos que cambian con la posesión (CON balón: Sprint y regate, Pase, Al hueco, Tiro; SIN balón: Sprint y entrada, Cambiar, 2.º defensor, Barrida), con colores por botón, triangulitos de gesto en el aro y los gestos de la guía de EA. Especificación en `docs/04_auditorias/MANDO_TACTIL_FC_2026-11-11.md`. Encargo de la sesión 11. **HECHO (11-11, sesión 11):** los 4 botones fijos con función, etiqueta y color por posesión (transición 0,15 s), triangulitos, gestos por botón, vertical (sesión 8) y zurdo, encendido por defecto en el teléfono; `MandoFC` (datos y tabla de gestos), `DibujoBotonFC`, `ControlesTactiles`; banco `_probar_mando_tactil_fc` (mm, separaciones, 4 a la vez, cada gesto → su acción), `tac_controles` reescrito; capturas Forward+ en `docs/04_auditorias/capturas_mando_fc_2026-11-11/`. **FALTA:** (1) el DOBLE TOQUE (pase picado, al hueco picado) no se hizo: obligaría a retrasar cada pase ~0,2 s; decidir con el dueño (¿opción en Ajustes?); (2) centro por la banda: la spec dice «izquierda = centro raso» y no hay acción distinta (hoy: arriba centro, derecha tenso, izquierda bombeado); (3) deslizar abajo en Sprint = adelantar el balón (misma acción que arriba); (4) `jugar_pase_largo` hace de «pase elevado»; (5) el veredicto en el teléfono del dueño y afinar umbrales de deslizamiento; (6) la captura da 2 fallos que ya salían en `main` en este contenedor (el jugador se mueve 0,0 m con el dedo; el II no abre la pausa).
- DATO REAL DEL DUEÑO (contado el 11-11): hacia el 4-11, en su teléfono y en calidad MÍNIMA, **60 FPS en el menú y 30 en el partido** (antes, el 3-11, en MEDIA: 5 en el partido y 28 en el menú). Es el último dato real: NO usar ya el «5 FPS». Meta: 60 en el partido.
- PENDIENTE DEL DUEÑO: borrar las ramas viejas de las listas A y B de `docs/04_auditorias/ramas_viejas_2026-11-10.md` (desde el contenedor GitHub rechaza el borrado) y la etiqueta `latest`; probar Nervión y medir FPS en su teléfono; descargas opcionales (la semana del 16-11).
- FALLOS ABIERTOS a mirar: sonda «el mejor gana al peor» (tira igual que el peor, N=6), cuelgue de las capturas del club con España y Argentina (club 3), `presupuesto_partido` con solo 2 llamadas de margen.

## PROMPT PARA LA NUEVA SESIÓN — PRIORIDAD ABSOLUTA (orden del dueño, 9-11 noche)
> Trabaja en español, en la rama asignada, sin PR salvo orden. Lee `CLAUDE.md` y `docs/PLAN_GENERAL.md` (secciones PRIORITARIO, DECISIONES PENDIENTES y PULIDO). Antes de subir a main: banco en «FIN. 0 fallos» y líneas OK. Sin nombres de modelo en commits ni archivos. No subir .mp4 al repo.
>
> Pendiente, en este orden:
> 1. **REESTRUCTURACIÓN «SOLO CLUB»** (paso 2, sesión 7, 10-11: HECHO muebles/colisiones/suelo/ascensor, ver «HECHO sesión 7» en la sección «SOLO CLUB»; FALTA la revisión del dueño y comprobar el parpadeo en un móvil real). Paso 3: medir sin ciudad con `herramientas/hw_modesto.sh`. Paso 4: decidir C/C++ solo con medidas.
> 2. **ESTÉTICA** — FALTA PULIR. La rama `ccr-da27fb86-i59x88` ya está en `main` (comprobado el 10-11: 0 commits de diferencia). Profundidad hecha (10-11, ver PULIDO); seguir afinando.
>
> **DECISIONES DEL DUEÑO:** respondidas el 10-11 noche (orden 36: ver «RESPUESTAS DEL DUEÑO A LAS 21 PREGUNTAS»). Los torneos de selecciones ya se juegan (Mundial, continentales, Finalissima y Juegos Olímpicos) y los .mp4 de `marca/` se quedan.
>
> Al completar cada punto: se BORRA de PRIORITARIO y se anota en PULIDO. Reporta al líder en cada bloque.

## REESTRUCTURACIÓN «SOLO CLUB» (orden 34, dueño, 9-11; en CLAUDE.md es el punto 33) — manda sobre todo lo anterior; el trabajo real EMPIEZA EL LUNES 16-11
- **HECHO sesión 7 (10-11), paso 2 «reparar el club»** (rama `sesion7-club`; capturas en `docs/04_auditorias/capturas_club_2026-11-10/`):
  1. **Parpadeo del suelo**: en Forward+ y Compatibility de escritorio NO se reproduce (fotos con la cámara movida 2 mm: `pruebas/captura_parpadeo_suelo.tscn`, 0 % de cambio en el suelo). Causa más probable, arreglada por causa: capas de suelo apiladas a 1 cm (losa a todo el edificio + suelo de sala encima + cascarón) con `near` 0,05 y profundidad de 16 bits en móviles. Ahora la losa solo cubre el pasillo, el suelo de cada sala es macizo hasta el cascarón y la cámara a pie usa `near` 0,12. Cruce coplanar REAL encontrado y corregido: el fondo de la cabina del ascensor (1,9×2,3 m, emisivo) estaba DENTRO de la pared con su cara en el mismo plano (se veía al abrir las puertas): ahora va 1 cm delante. Prueba `pruebas/prueba_coplanares_club.tscn` (caras coplanares visibles con distinto material: 4 antes, 0 ahora). FALTA confirmar en un móvil real.
  2. **Muebles**: auditoría `pruebas/auditoria_muebles_club.tscn` (3 países: CHI 0, ESP 3, ARG 5; apoyo en el suelo, huella dentro de la sala, colisión de lo que tiene cuerpo). Arreglado: alfombras de muebles ENTERRADAS bajo el suelo (ahora visibles), mesita de la enfermería que atravesaba la pared con 3 camas, sillas/mesitas/plantas/lámparas/perchero sin colisión, coches del estacionamiento sin colisión (`ChoqueClub`), pasillo central en la sala de prensa. Sala de prensa y comedor reajustados (prensa 6,8 m, comedor 4,7 m) para que el comedor siga transitable con sillas sólidas.
  3. **Colisiones**: `prueba_colisiones_club` ahora recorre CADA sala (11) empujando en 8 direcciones y comprueba que el cuerpo no sale del edificio ni entra en un mueble/tabique; admite `PAIS=` y `CLUB=`.
  4. **Relleno** (piezas sin usar de `kenney/muebles`, `RellenoClub`): enfermería (lavabo, botiquín, caja), sala de vídeo (planta y lámpara), cuarto de máquinas y utilería (cajas), banco en cada pasillo. En ULTRA BAJA NO se pone (para no subir el dibujo); el resto de niveles sí.
  5. **Dibujo** (CHI, 12 puntos de vista, llamadas/triángulos): MÍNIMA igual o menos en todos (853→853 … 193→187; −2 400 triángulos por vista); ALTA ±15, +45 en el pasillo (el banco). Las plantas grandes del pasillo se probaron y se quitaron (+38 llamadas cada una en ALTA).
- **HECHO sesión 7 (10-11), museo (1/3)**: el visor del trofeo (`VisorTrofeo`, ya abría con E) ahora se maneja también con TOQUE (arrastre con el dedo, botones ◀ ▶ ＋ －), MANDO (stick/cruceta giran, stick derecho acerca, A cierra con el foco, B cierra) y rueda/W/S para acercar; prueba `prueba_visor_trofeo_mandos` con 3 clubes (ENG con 3 títulos, ESP y CHI sin ninguno). FALTA: (2) presentación del museo (vitrinas, luz, carteles) y (3) que la planta 3 se abra también por número de títulos: hoy la amplía la obra «Museo del club» (nivel 5, `MuseoAmpliado`) con su animación de encendido; hace falta decisión del dueño si debe depender de los títulos.
- **HECHO sesión 7 (10-11), museo (2/3, presentación)**: `MuseoPresentacion`: placa en la peana, charco de luz en el suelo y zócalo del color del club (todo en el `Lote` con materiales que ya existían) y cartel con título y año (Label3D, solo desde BAJA). MÍNIMA: llamadas idénticas con 0 y con 14 títulos (770/770 y 788/788, CHI). Capturas en `docs/04_auditorias/capturas_museo_2026-11-10/`. Medir con `SIN_PRESENTACION_MUSEO=1`. Carteles más grandes y presentación también en la planta 3 (placa, charco y zócalo). Tercer club: ARG 7 títulos.
- **HECHO sesión 7 (10-11), museo: gallardetes** del club (colores del club) colgados sobre las vitrinas, en el lote de la sala (sin materiales nuevos; MÍNIMA 817/817 llamadas con 14 títulos). Hoja antes/después ARG 9 títulos en `capturas_museo_2026-11-10/`. HALLADO: `pruebas/ideas/a4_metro_museo.tscn` falla («planta -1: el jugador queda a y=-7.98», «planta 1: y=0.02») también con el código anterior a la oclusión por plantas: usa el `ExploradorCiudad` (`_ir_a_planta`), con la ciudad apagada; sin investigar la causa.
- **HECHO sesión 7 (10-11), realismo del club (cierre, commit b6f5a798)**: vestuario y resto de salas con texturas CC0 de Poly Haven por país (`VestuarioRealista.ESTILOS`: ing, jap, lat, ale, nor, ara, afr, def; `sala(tipo, pais)` con caché), solo MEDIA/ALTA (`activo()`; `SIN_VESTUARIO_REAL=1` para medir); pizarra táctica y escudo en el vestuario, escudo del club (`escudo_sala`; `ctx["club"]`) en oficina del DT y despacho; muebles CC0 (`ModeloCC0`, `assets/cc0_modelos/`, `herramientas/bajar_cc0_modelos.py`, texturas 512 px, `SIN_MUEBLES_CC0=1`) en oficina del DT y despacho; sin nombres flotantes (orden del dueño). Medidas (vista oficinas, ENG, MEDIA): tex 314,1 → 331,4 MB (+17,3), llamadas 1685 → 1691; ALTA 3139 llamadas, 370,6 MB. Hojas en `capturas_vestuario_realista_2026-11-10/`. FALTA: muebles CC0 en prensa, enfermería, utilería y pasillos; medir milisegundos de fotograma real; revisión del dueño. EN COLA (orden 36): planta extra del museo por TÍTULOS GANADOS (umbral a decidir) con mini evento de expansión a pantalla completa y saltable; prueba en el banco y capturas de 2 clubes de países distintos.
- **HECHO sesión 7 (10-11), VESTUARIO REALISTA (sala piloto, MEDIA y ALTA)** (`VestuarioRealista`, `SIN_VESTUARIO_REAL=1` mide el antes): suelo de resina semibrillante, yeso, azulejo con juntas hundidas, bancos con veta y una sombra en la luz central (ALTA). Llamadas/triángulos en ALTA: ARG 3.157→3.418, ENG 3.612→3.875, JPN 3.655→3.917 (+~260, +7 %; es la sombra de una luz; con las tres eran +1.176); MEDIA: ARG 2.224→2.228, ENG 2.252→2.256. Hoja en `capturas_vestuario_realista_2026-11-10/`. FALTA: taquillas, camisetas, escudo y paredes laterales con detalle real; el azulejo no se ve (queda tras las taquillas); fotograma en ms; el resto de salas.
- **MEMORIA DE TEXTURAS del vestuario realista (ALTA)**: +44,7 MB de texturas y +44 MB de vídeo (ENG 188,9→233,6 MB; JPN igual; ARG 194,3→238,9). Pendiente de rebajar (ruidos de 1024 px del hormigón/madera, escudo 256 px).
- **VESTUARIO POR PAÍS con texturas CC0 reales (10-11, el dueño autorizó los creadores 3D en línea; se eligió primero Poly Haven, sin clave)**: `herramientas/bajar_cc0.py` baja a `assets/cc0/` (11 MB, fuera de LFS, excepción en .gitattributes, licencia en LICENCIAS.md) 8 texturas PBR; `VestuarioRealista.ESTILOS`: «ing» (ENG, SCO, WAL…) tablón oscuro + ladrillo; «jap» (JPN, KOR, CHN…) hinoki claro + pared lisa; «lat» (ESP, ITA, POR y toda América Latina) baldosa de barro + yeso de arcilla; resto goma + yeso beige. Pizarra con la formación real y escudo del club. ARG ALTA: 3.161→3.424 llamadas, textura 194→261 MB (+66 MB; solo MEDIA y ALTA). FALTA: el resto de salas (despacho, oficina del DT, prensa, utilería, pasillos), taquillas con botas y toalla, mobiliario real (Poly Haven tiene 521 modelos CC0), más países en los estilos, rebajar la memoria, y probar un generador de IA 3D (Meshy/Tripo/Hunyuan vía 3D AI Studio) si hace falta una pieza que no exista (hace falta una clave).


- **ESTADO SESIÓN 7 al 10-11 tarde (para retomar si se llena el contexto)**: rama `sesion7-museo` (último commit con la pizarra y el escudo del vestuario). Hecho: club a pie (muebles/colisiones/suelo/ascensor), museo (visor con mando y toque, presentación, planta 3 de 30 vitrinas), oclusión por sala/planta/cono, fusión en BAJA, vestuario realista (resina, yeso, azulejo, madera, sombra en ALTA, pizarra con la formación real y escudo grande). EN CURSO: mediciones antes/después del vestuario (script `scratchpad/w2.sh`: llamadas + memoria de texturas + fotos de cerca con `pruebas/captura_vestuario_cerca.tscn`, 3 clubes ENG/JPN/ARG) y hoja JPG para `docs/04_auditorias/capturas_vestuario_realista_2026-11-10/`. PENDIENTE del encargo del líder: TAQUILLAS con la camiseta real de cada jugador (dorsal y nombre; hoy ya llevan camiseta con dorsal y nombre en `PiezasVestuario.taquilla`), botas y toalla a la vista; camisetas en MultiMesh/atlas si se puede; el resto de salas.



- **HECHO sesión 7 (10-11), oclusión del club a pie** (`OcultarEstadioDentro`, edificio en nodos `Planta_p`; capturas en `capturas_oclusion_2026-11-10/`): estadio/calle/plantas se ocultan según lo que se ve por las aberturas (boca del túnel, ventanas): vestuario de espaldas a la boca 886→280 llamadas (CHI; ESP 799→273, ARG 809→279), túnel de espaldas 520→276 (CHI), media de 15 puntos CHI 455→344→207; la prueba con/sin ocultación (12 rumbos, 6 clubes) no muestra diferencias salvo la animación de las puertas. Mirando al campo no cambia (es lo que se ve). DECISIÓN del líder (10-11): se QUEDA la fusión en BAJA del edificio (por planta) y el túnel (`SIN_FUNDIR_BAJA=1` mide el antes): CHI de espaldas al campo despacho 287→227, vestuario 182→142, túnel 270→205, campo 682→614, media 270→216; mirando al estadio túnel 950→974 (+24) y media 426→413; fotos con/sin ≤0,16 % de píxeles. El «+17» de «Campo» en ULTRA BAJA era un error de medición (mismo rumbo: 434→367 y 350→350). Carga del club sin diferencia medible. FALTA: llamadas en MEDIA y ALTA; el túnel mirando al campo (~950 en BAJA) lo domina el estadio.

- **INVESTIGADO sesión 7 (10-11): la captura del club ESP 3 («Nervión FC») no termina en Forward+ con llvmpipe.** El estadio se construye en ~10 s (TIEMPOS=1), el nodo carga 4,3 GB de 16 (no es falta de memoria) y el cuelgue está en el PRIMER fotograma dibujado (`TRAZA=1`: FRAME 1 a los 22 s y el 2 no llega en 5 min; ARG lo dibuja a los ~79 s). Con la misma escena: Compatibility 120 s, `--headless` 12 s; otros clubes de ESP (0, 5, 9) y el club 3 con el estadio del 0 tardan 100-120 s. Depende del perfil del estadio, no del club: `PERFIL_SET=aforo=N` con N=30 000 y 46 200 cuelga, 25 300 / 60 000 / 85 800 no; no es la ocupación, ni los acentos, ni el número de instancias de grada. Sin causa en el juego a la vista: parece un caso del Vulkan por software; FALTA probarlo en una GPU real (si cuelga ahí, es un fallo del juego).



Fuente: PDF «Plan de Reestructuración – Dinastía» y vídeo del despacho (la habitación sin puertas ni marcos y el ascensor sin animación). Decisiones obligatorias.

**Aclaraciones del dueño (9-11)**
- **Ciudad 3D** = parte APAGADA del proyecto (puede volver a futuro). Se apaga con un INTERRUPTOR DESDE EL CÓDIGO; el juego INSTALADO ya no la trae (se excluye de la exportación). No se borra nada: queda en el «repertorio». Se PUEDEN reutilizar piezas de la ciudad (muebles, carteles, vehículos, paradero Red, tiendas, peatones) dentro del club y sus instalaciones.
- **Alcance del juego base**: solo el club, sus instalaciones y la casa del personaje. La conducción y el delito SIGUEN, pero solo en esos tramos (mucho más corto).
- **Menú**: solo «Diseño de la ciudad» y «Entrar al estadio». «Diseño de la ciudad» pasa a ser una pantalla 2D de GESTIÓN (terrenos, negocios, instalaciones, estadio y municipio) y conserva TODA la política. Sin elección de «tipo de casa»: empieza con la más básica.
- **Cámaras**: se quitan las vistas aéreas/lejanas de la ciudad (solo la pantalla de las fotos del PDF, Fig. 1-2). El ESTADIO sigue pudiéndose recorrer. (12-11, dueño) Al mover al personaje SOLO hay primera persona: HECHO (`VistaJuego`; club, estadio y casa empiezan en primera persona y V no cambia de vista en el juego; en una conversación la cámara mira a la cara de quien habla; ratón capturado solo sin diálogos abiertos; textos de ayuda, consejo de carga y prólogo al día; banco `_probar_solo_primera_persona`). Las demás vistas, solo con `DINASTIA_CAMARAS=1` (capturas y herramientas). FALTA: que el dueño lo pruebe en el teléfono (mirar arrastrando el dedo).
- **Mando (corrección)**: R2 = confirmar, **Cuadrado = borrar** (el PDF lo tenía al revés), Triángulo / X = espacio, L2 = mayúsculas/minúsculas. Teclado de PC: escribir nombres de forma nativa.
- **Rueda de prensa**: selección direccional (analógico / clic / táctil) con mini animación, en vez de lista. **Coleccionables**: no se abre su panel solo al iniciar.
- **Entorno**: realista (fuera lo infantil y los avatares irreales); la lluvia no atraviesa instalaciones y se apaga en ultra bajo; menos ruido ambiente y pisadas; suelo interior liso y barato, distinto del asfalto. **Conducción**: sin «modo conducir» en menú; subir a un coche = acto ilegal; solo se anima el volante (sin manos, sin efecto «cortometraje»).
- **2D**: el prólogo pasa a animación fija en el motor (NO .mp4 en el repo), saltable tocando arriba o con el joystick. Personal quieto en su puesto con diálogos 2D (novela visual); ciudadanos 3D muy simples, 3D pleno solo en «eventos».
- **Motor**: C/C++ solo para lo que el perfilador señale (cada función nativa = copia exacta de su GDScript); cambiar de motor se decide DESPUÉS de medir sin ciudad. FPS medidos desde el menú inicial.
- **Partido**: base de físicas = League-Soccer, aún NO integrada del todo ni en su última versión; referencias de sensación: PES 2020, FIFA Mobile, FM26. **Cualquier sesión** puede tomar los 4 fallos críticos.

**Orden de trabajo (4 pasos, desde el lunes)**
1. Los 4 fallos del partido + interruptor de la ciudad (avance del 9-11):
   - HECHO: interruptor `InterruptorCiudad.activa` (apagado; fuera del menú «Pasear a pie»/«Conducir» y del botón «Salir al mundo abierto»; se conservan en `MenusLaterales.SUBS_MUNDO_ABIERTO`). FALTA: excluir la ciudad de la exportación (`export_presets.cfg`). ANALIZADO el 10-11 (sin plantillas de exportación en el contenedor, no se pudo exportar para probar): NO se puede hacer solo con `exclude_filter` sin romper el club, porque el club y el estadio usan la ciudad POR REFERENCIA ESTÁTICA (clase `CityBuilder` desde `GaleriaClub`/`ExploradorEstadio`, `MetroCiudad` desde `SubsistemasQuietos`/`Optimizar`, `Ciudad` desde `Clima`…): siguiendo las referencias desde `project.godot` quedan alcanzables ~990 archivos y solo 16 no lo son (herramientas de horneado, `CasaEscena3D`, `InterioresClub`, `PantallaCiudad`…, que el club sí carga por `CargaCiudad.de`). Lo que SÍ falta para poder excluirla es DESACOPLAR esas referencias (cargarlas por ruta con `load()` tras el interruptor) y medir con la exportación real. Los 19 MB de `assets/ciudad` sin referencia directa son texturas de modelos `.glb`, no se excluyen a ciegas.
   - HECHO (d) resumen de temporada con datos falsos: el veredicto del documental ya no proclama campeón sin jornadas jugadas (`DocumentalTemporada.guion`), con prueba.
   - HECHO (b) saque de banda atascado: causa = sin compañero a 30 m el saque del usuario no salía nunca; ahora amplía el radio, y a los 25 s saca la IA. Prueba en `partido`. Verificar con mando real.
   - HECHO (a) día de partido (como PES 2020, 9-11): con partido de tu club pendiente, «Avanzar semana» abre el menú del partido en vez de simularlo, y al llegar el sábado con partido el menú se abre solo (`AvanceSemana.partido_obliga`; ahí dentro eliges jugarlo o simularlo a conciencia). Quitados «Jugar la temporada» y «Simular toda la temporada» (queda `_jugar_temporada` como código interno de las pruebas). FALTA: la pantalla de avance de fecha estilo PES (tira de fechas con eventos, parada en cada hito); referencia pedida por el dueño: pasarle capturas del PES 2020 que le gustan, porque la búsqueda web no devolvió pantallas.
   - HECHO (c) ritmo (9-11): ajuste nuevo «Velocidad del juego en directo» (Ajustes → Juego): Lenta 0,70 / Normal 0,85 (por defecto, antes 1,0) / Rápida 1,00 / Arcade 1,15; escala jugadores, balón y reloj SOLO en directo (`RitmoJuego`, `MotorJugable._physics_process`; la simulación y las pruebas no cambian). El 0,85 (Normal) lo eligió la sesión y el DUEÑO LO APRUEBA (aviso del líder, 9-11); el ajuste Lenta/Normal/Rápida/Arcade sigue en Ajustes → Juego.
   - HECHO (PES) botón «⏩ Hito» junto a «Un día»: avanza hasta el sábado de partido o el cambio de semana; su descripción dice cuál es el próximo hito (`AvanceSemana.proximo_hito`).
   - HECHO (PES) PARTIDO DE DESPEDIDA (rehecho el 9-11 según el dueño): al FINAL de la temporada, al pulsar «Temporada siguiente», tu equipo juega contra las LEYENDAS (los mejores de TODOS los que se retiran esa temporada, `PartidoDespedida.preparar`; el cierre respeta quién se retira). Se puede JUGAR en directo, SIMULAR o dejar (`JornadaDespedida`); es de gala: no cuenta para la liga, deja taquilla ×1,6 y +ánimo, y se restauran lesiones/cansancio/tarjetas/estadísticas de tus jugadores. Con pruebas (banco + `prueba_despedida_ui` con xvfb) y captura del diálogo. REGLA DEL DUEÑO (9-11): los EVENTOS son a PANTALLA COMPLETA (`EventoPantallaCompleta`: fondo propio, filetes dorados, fundido; se desliza si la pantalla es pequeña) y solo salen al llegar a su fecha, nunca al abrir un menú: el aviso del partido de despedida (`EventoDespedida`) sale al TERMINAR LA LIGA (lo dispara `AvanceSemana._refrescar`, una sola vez por temporada, también tras guardar y cargar: `Prensa.despedida_ofrecida_anio`) y el homenaje (`CeremoniaDespedida`) al acabar el partido; prueba con pantalla `prueba_despedida_fecha` (a mitad de temporada no sale, al terminar la liga sí y ocupa toda la pantalla, no se repite). Nuevos eventos deben heredar de `EventoPantallaCompleta`. HECHO también (9-11): ceremonia de homenaje tras el partido (`CeremoniaDespedida`: los homenajeados de TU club —≥34 años y capitán, 6+ temporadas o nivel ≥74— con su CAMISETA RETIRADA, o las 3 mayores Leyendas), camisetas retiradas guardadas (`Prensa.dorsales_retirados`) y no repartidas a nadie de tu club, y lo decidido (quién se retira, año del partido) GUARDADO en la partida y reutilizado al cargar. Caras: solo `Cara.textura` (procedurales de la base ficticia; con `Datos.base_real` falso ninguna foto real se enseña). HECHO también: las camisetas retiradas se ven en Historia del club (`CamisetasRetiradas`) y en el museo del estadio (`CamisetasMuseo`, en la pared del fondo; captura con `captura_camisetas_museo`). FALTA: un homenaje en 3D en el campo.
   - REFERENCIA PES 2020 MIRADA (9-11, miniaturas públicas de 4 vídeos de YouTube: menú, Master League y squad; 120x90 px, solo orientan; no se guardan en el repo): (1) fondo morado con franjas diagonales y listas lilas translúcidas, etiqueta a la izquierda y valor a la derecha, retrato grande del jugador/DT a la derecha; (2) inicio de Master League: pestañas arriba en el color del club, tarjetas de noticias con foto al centro, tabla resumida a la derecha y, abajo, una FILA DE ESCUDOS con los próximos partidos y el botón de avanzar con la fecha; (3) pie de pantalla con las ayudas de botones según el contexto; (4) plantilla: lista con barras de puntuación a la izquierda, atributos en columna central y render grande del jugador con su camiseta a la derecha; (5) cinemáticas de despacho y de entrenamiento con personajes 3D de traje y la grada del club detrás. Para aplicar: fila de escudos de próximos partidos junto a «Hito», pie de pantalla con ayudas de botón (mando) y plantilla de tres columnas. Si el dueño graba pantallas del PES se compara cuadro a cuadro con ffmpeg.
   - HECHO (9-11) fila «PRÓXIMOS» con el escudo del rival de los siguientes 5 partidos de liga, bajo la tira de días (`FilaProximos`, con prueba). FALTA del avance de fecha estilo PES: eventos (mercado, cumpleaños, noticias) en esa fila y varias semanas con copa/continental.
   - IDEAS DEL PES PARA SEGUIR (el dueño las pidió; sin hacer): (1) CAPÍTULOS: HECHO (9-11): el documental de cada temporada se archiva en la partida (`CapitulosTemporadas`, `Prensa.capitulos`, hasta 40 años, sobrevive a guardar/cargar) y el menú Historia → «Capítulos de cada temporada» los reproduce; FALTA: comparar el ritmo y los planos con el PES cuando haya capturas; (2) MENÚ CENTRAL DE LA PLANTILLA estilo PES: HECHO (9-11) la vista de tres columnas (`PlantillaPes`: lista por líneas con barra de nota y ★ del once, atributos en barras, retrato y estado, y «⚖ Comparar» con diferencias en verde/rojo; Plantel → «Plantilla detallada» (antes «vista PES»; el dueño pidió quitar la palabra, 10-11); captura revisada con Forward+/opengl3 y prueba especial `prueba_plantilla_pes`). REHECHA el 9-11 con los ejemplos del dueño (capturas «Estrategia» y «Opción de entrenamiento» del PES) y la paleta del juego (verde y dorado, `Tema`; NO morado): campo con la formación y los once, lista con etiquetas de línea de color y nota, panel de información con retrato, nota grande y radar. HECHO también: intercambio titular↔titular y titular↔reserva desde la pantalla («↔ Cambiar en el once», `PlantillaPes.intercambiar`, con pruebas) y pasada de calidad (caras en el campo con aro y chapa de nota, filas con foto y franja dorada, barras por rango, campo que ocupa su panel, fundido de entrada; captura 1920x1080 revisada). HECHO también: ESTILO DE JUEGO con estrellas por jugador (`PlantillaEstilos`: los roles de su línea con ★ según su aptitud, el actual marcado y clic para cambiarlo; queda en Táctica y en el partido; con pruebas) y la columna de información deslizable. FALTA: mapa de calor y habilidades individuales (regate en profundidad, etc.); contexto previo: hoy `pantalla_plantel*.gd` son 3 capas de ~380-450 líneas (listas de botones); rehacerlo como una escena con campo + lista, partiendo del código existente; (3) pantalla de avance de fecha con tira de varias semanas y eventos (hoy 7 días).

   - HECHO (9-11) PASEO «SOLO CLUB»: corrección de lo dicho antes: el club (planta 0 a +2, sótanos, ascensor) YA se camina en «Entrar al estadio» (`ExploradorEstadio`), sin la ciudad. Ahora «Entrar al estadio» te deja CAMINANDO directo (`VistaEstadio.arrancar_a_pie`), sin la vista exterior, y Esc vuelve al menú; el botón 🚶 del riel y del cajón pasa a «🏟️ Entrar al club» con la ciudad apagada. Prueba especial `prueba_menu_estadio_a_pie` (en `especiales.sh`). HECHO (9-11): con la ciudad apagada NO hay prólogo caminando: «Continuar» y las partidas nuevas entran directo al menú (`VidaCiudad.arranque_3d` y `OrquestadorMundo.con_prologo` devuelven «no» sin `InterruptorCiudad.activa`; antes «Continuar» abría el prólogo 3D en la ciudad apagada). (ELIMINADO el 10-11 por orden del dueño, ver RESPUESTAS DEL DUEÑO) PRIMER CORTE de la ANIMACIÓN FIJA que lo sustituía (`PrologoAnimado`, SIN vídeo: 6 planos dibujados por el motor —estadio, vestuario, túnel, banquillo, despacho, oficina—, a pantalla completa, con barra de fases arriba que SALTA de plano al tocarla y salto total con Esc/Enter/Espacio, botón del mando o mover el stick; lo lanza `PrologoInicio` desde `AvanceSemana._refrescar` una vez, si la partida lo tiene pendiente, y la deja con el prólogo visto; prueba con pantalla `prueba_prologo_animado`, capturas de los 6 planos). FALTA: arte final (los planos son siluetas simples y oscuras con club blanco y negro), sonido/música, voz o más texto por plano y la casa del personaje caminable sin ciudad.
   - HECHO (9-11, paso 2 parcial): el ASCENSOR ya sube y baja gradual (`AscensorViaje`, 1 s por planta, en los dos exploradores; el cuerpo no camina durante el viaje) y cada puerta de sala lleva MARCO + HOJA abierta (`PuertasClub`). Capturado con `captura_edificio_club.tscn` (SOLO=6,10, opengl3): marcos y hoja se ven sin parpadeos de z-fighting. FALTA del paso 2: muebles en las salas que sigan vacías (revisar cada sala con captura), colisiones persona-objeto y el parpadeo azul/naranja del despacho (no se reprodujo en la captura: probablemente era la cámara del teléfono). Suelo liso y puertas del ascensor: HECHO el 10-11 (ver PULIDO).
2. Reparar el club: puertas y marcos, muebles (traídos de la ciudad), ascensor animado (subida/bajada), colisiones (nadie atraviesa cuerpos/objetos), suelo liso, y revisar el PARPADEO del suelo del despacho (azul oscuro ↔ naranja en el vídeo; z-fighting, luz o solo la cámara del móvil).
3. Volver a medir (`hw_modesto.sh`, RAM, llamadas, triángulos) sin la ciudad.
   - MEDIDO el 10-11 (`ESCENARIO=menu|partido HW_DRIVER=opengl3 herramientas/hw_modesto.sh res://pruebas/medir_ram.tscn -- minimo`, 2 núcleos, 4 GB). HALLAZGO Y ARREGLO: el menú compilaba el estadio, el partido 3D y la ciudad enteros (fallaba la prueba especial `mem_menu_estadio`, ya en el commit de partida) porque `AvanceSemana` nombraba la clase `JornadaDespedida`, que nombra `PartidoVivo`; ahora va por ruta. MENÚ: memoria estática 577 → **380 MB**, RSS 937 → ~700 MB, pico 1.465 → ~830 MB. PARTIDO (mínima): RSS **~2.540 MB**, estática 731 MB, texturas 84 MB, vídeo 137 MB, 2.857 nodos: sigue lejos de la meta de 1,5 GB y es lo siguiente a atacar (la memoria anónima, 2,4 GB, no es de texturas). Paso 4 (C/C++): las cifras no señalan todavía una función de CPU concreta; primero el perfilador del partido.
4. Solo entonces decidir qué pasa a C++ y si se cambia el motor.
Reglas de siempre: banco en «FIN. 0 fallos» antes de subir, capturas con la cámara real, nada se quita sin decirlo.

## PRIORITARIO (orden del dueño, 9-11) — en este orden; al completar una, se BORRA de aquí y se anota en «PULIDO» (más abajo) para pulirla después

1. **ESTÉTICA Y DISEÑO DE MENÚS Y DISTRIBUCIÓN — FALTA PULIR.** **FALTA PULIR EN TODOS LOS BLOQUES hechos** (cada uno se afina después). Hecho y en main (9-11): márgenes de las columnas del menú central, fila «PRÓXIMOS» en tarjetas, portadas del riel con rejilla dinámica, letra base del Tema y de los botones, diálogo «Capítulos», Ligas y clubes con escudos, aire en Estadio, aviso del partido de despedida (escudo de las Leyendas con 5 diseños y once titular con busto 3D) y foco visible en los botones de evento.

## ANIMACIONES GRATUITAS (sesión 10, 11-11) — PENDIENTE (lo hecho está en `docs/04_auditorias/animaciones_gratuitas_2026-11-11.md`)
- **Rohr** (`anims_futbol/`, 21 clips de fútbol): licencia sin texto en el zip. El dueño debe confirmarla y guardar la captura de la página de Gumroad; hasta entonces NO va en builds públicos.
- **Faltan clips libres de**: cabezazo, entrada de pie y portero (CMU no trae paradas). Solo existen en League-Soccer (Apache 2.0) y en Rohr.
- **Acciones de la UAL** (33 clips: sprint, saltos, caídas, slide, baile…) completas en `terceros/ual/ual_extra.res`; en los builds solo viajan las de `anims_ual/ual_uso.res`. Si la sesión 9 pide otra, se añade a `herramientas/ual_a_anims_extra.py` y se regenera con `anims_uso_a_res.gd`.
- **Estilos de 100STYLE y bailes/acciones de CMU** completos en `terceros/estilo100/` (2.522) y `terceros/cmu/` (144 + espejos); en los builds solo los 143 ciclos de `anims_extra` y los 155 de `cmu_uso.res`. Más volumen = tocar los scripts de `herramientas/estilo100_*` y `cmu_*` y regenerar.
- **Sin probar dentro del partido real**: las velocidades de los ciclos (100STYLE ~1,8 m/s, CMU 3,2-4,3 m/s, UAL sprint 7,35 m/s) pueden pedir ajustes con el motor de la sesión 9.
- **Sin comprar**: UAL «Pro» ($9,99): no hace falta, la parte gratuita ya está aprovechada.

## NOTA DEL DUEÑO (12-11): MENÚS SUBDIVIDIDOS A PANTALLA COMPLETA
- «Varios menús se pueden subdividir y hacer más menús a cámara completa», tomando de ejemplo el PES 2020 (revisar la sección «IDEAS DEL PES 2020 PARA ADAPTAR»). Lo lleva la sesión de la rama `ccr-8279c839-7t0p6w` (sin unir a `main` hasta que el dueño lo diga).
- HECHO (12-11), 1.ª tanda: mecanismo general `Principal._secc_extra` (cualquier pestaña se parte en submenús con `secc` en `MenusLaterales`, sin una variable por pestaña) y FINANZAS partida en 5 pantallas con su tarjeta en la portada de «Dinero»: Cuentas del club, Taquilla y tienda, Patrocinadores, Banco y deuda, Libro de movimientos; cada una abre con una banda de CIFRAS CLAVE (`CifrasClave`). Traducido a los 8 idiomas; banco `_probar_finanzas_por_pantallas`; fotos con `SOLO_MENU=dinero PAIS=… CLUB=… herramientas/captura_menus.sh` (revisado con clubes de ARG y BRA). De paso: `captura_menus.sh` estaba ROTA desde el 10-11 (la reunión con la directiva a pantalla completa tapaba las 34 fotos); arreglada.
- HECHO (12-11), 2.ª tanda: «Próximo partido» en 3 pantallas (`PreviaPartido`, sacada de `pantalla_plantel_p3.gd`: previa, informe y apuestas, los onces), las tres con el cartel del partido, la banda de cuotas y el botón de jugar; revisado con un club de ESP.
- HECHO (12-11), 3.ª tanda: «Táctica» en 4 pantallas (`TacticaSecciones`, sacada de `pantalla_plantel_p2.gd`, que estaba en 450 líneas justas y queda en 249): Pizarra y dibujo, Órdenes de juego, Balón parado y normas, El once; banda con formación, mentalidad y estado del once; desde el menú Partido se llega a la pizarra y a «Elegir el once». Revisado con un club de ITA.
- FALLO ARREGLADO (12-11): en Plantel → Contratos TODAS las agencias con dos clientes salían en rojo desde el primer día: la pantalla comparaba la confianza con 45 (escala 0-100) y la confianza va de −10 a +10 y arranca en 0. Ahora va en rojo solo el que tiene 2 clientes o más y desconfía (`Cantera.agente_aprieta`), en dorado el que confía; además romper un contrato restaba confianza sin tope (ahora −10). Banco `_probar_agentes_confianza` (ARG y GER).
- HECHO (12-11), 5.ª tanda: «Cantera» en 3 pantallas (`SECC_CANTERA` en `pantalla_cantera_p2.gd`): Academia (10-16 años), Juveniles (camada, listos para debutar, categorías) y Leyendas y linaje; «Linaje» del menú Historia abre directamente la suya; prueba `_probar_cantera_por_pantallas` (además vigila que ningún menú abra una pestaña partida sin decir qué pantalla). Revisado con un club de FRA. Los fondos de inversión y el mapa del talento pasaron a «Juveniles» y «Leyendas y linaje» tiene su texto cuando está vacía. Pulir: Cantera aún no tiene banda de cifras clave (`pantalla_cantera_p2.gd` está en 449 de 450 líneas: partirlo antes).
- INTERMITENTE (12-11): la especial `a4_limite_mundo (2/3 calidad y horas)` falló UNA vez corriendo junto al banco y a otras capturas («cambiando a calidad −3 con la ciudad abierta: 1 luz con sombra») y pasó sola a la primera («FIN. 0 fallos»). La prueba espera UN fotograma tras cambiar de calidad; con la máquina cargada no alcanza. Si se repite en el CI: esperar más fotogramas ahí, no tocar el juego.
- MERCADO CON DEMARCACIÓN (12-11): la lista de objetivos lleva la columna POS (demarcación; de pie no cabe y se omite) y deja 14 px a la barra de desplazamiento, que pisaba «GANAS». Revisado con Italia (PC), Brasil (móvil tumbado) y Argentina (de pie, antes del cambio: cabe). Notas: los agentes son una lista fija mundial por diseño (no es un fallo que un club japonés tenga a «R. Maldini»); la tarjeta «Jugadores libres» no lleva dato hasta que se abre la pantalla (la lista se genera entonces); en Libres hay sueldos raros (un juvenil de 19 años y media 53 pide 41k/sem).
- ENFERMERÍA EN FICHAS Y DOS INCOHERENCIAS DE LA SEMANA 1 (12-11): el parte médico va en fichas `CifrasClave` (enfermería en rojo si hay alguien, puesto en verde en la mitad alta). El veredicto decía «Se nota la inversión» sin jefe médico contratado: sin él dice solo que se pierden menos semanas que la media. «A quién ceder» listaba a todo el plantel como «0 partidos» antes de jugarse nada: los de «no juega» solo salen cuando alguien del plantel lleva 4 partidos (CAMBIO DE JUEGO: hasta entonces no se puede ceder con opción/obligación a mayores de 21; el préstamo de canteranos sigue igual). Revisado con Brasil (PC) e Inglaterra (móvil de pie). FALLO ARREGLADO DESPUÉS (12-11, cambia lo que se lee): `Medico.ranking_liga` comparaba tus días perdidos, que se ACUMULAN toda la carrera, con la estimación de UNA temporada entera de los rivales: en la semana 1 la media ya marcaba ~21 semanas y, al revés, a partir del 3.er año salías siempre el último y con el aviso de «pierdes más que la media». Ahora la referencia de los rivales crece con el tiempo jugado (`temporadas`), los empates no te bajan de puesto y sin nada jugado se dice que la comparación empieza con los primeros partidos. Banco (`ideas_a3`) con dos comprobaciones nuevas; revisado con un club colombiano.
- CONTRATOS, LO URGENTE PRIMERO (12-11): la pantalla abría con «Agencias del plantel» y «Roles prometidos» (más de 40 filas) y las RENOVACIONES (lo que la pantalla central marca en rojo) quedaban enterradas; ahora el orden es renovaciones → cedidos → a quién ceder → roles → agencias → cláusulas. Los perfiles de agente se leían en crudo («tiburon», «mediatico»): `MesaAgente.nombre_perfil` (con tilde y traducidos). De pie, las filas de renovar/ceder se salían de la pantalla (barra horizontal): los botones bajan de renglón y el desplegable de rol ya no fuerza el ancho. Revisado con Corea (PC) y Chile (móvil de pie). OBSERVACIÓN SIN TOCAR: en la semana 1 «A quién ceder» lista a casi todo el plantel como «0 partidos» (nadie ha jugado aún); y los agentes llevan nombres hispanos en cualquier país (p. ej. en un club japonés).
- CARRERA Y VIDA (12-11): la tabla de la pantalla central pinta la fila del club propio con el acento ya contrastado (`_con_contraste`; un azul marino como el de un club francés casi no se leía); el Correo vacío usa `EstadoVacio`; las tarjetas Bienestar y Familia llevan dato (estrés y familia de 100). Revisado con clubes de Francia e Italia. HECHO (12-11): la tabla central deja 14 px a la barra de desplazamiento (`TablaCompeticion._rejilla`; revisado con Alemania en PC y México en móvil de pie). Pulir: «LO QUE HA PASADO» de Familia vacío en una línea; Casa y auto, Directorio y Árbol de habilidades sin dato.
- DATO VIVO DE LAS TARJETAS (12-11): FALLO: `DatoTarjeta` busca por el NOMBRE de la tarjeta y al renombrarlas («Finanzas» → «Cuentas del club», «Mercado» → «Mercado de fichajes») perdieron su línea de color; la prueba no lo veía porque usaba los nombres viejos. Arreglado, y con dato nuevo: Próximo partido («Fuera: rival»), Ligas y clubes («N.º de M»), La gente del club, Enfermería, Pizarra y dibujo, Jugadores libres, Goleadores (tu máximo goleador). `ideas.sh men_datos` comprueba ahora contra los nombres reales de `MenusLaterales`. Revisado con Bolivia, Países Bajos y Australia. HECHO DESPUÉS (12-11): `DatoTarjeta.de_sub` + `POR_SITIO` (17 pantallas por `tab.secc`: el dato ya no depende del rótulo; la prueba cambia el rótulo y exige el dato) y dato en Taquilla («Entrada: 6 EUR») y Banco («sin deuda» / «Deuda: …»); revisado con Paraguay en móvil tumbado. Faltan: Patrocinadores, Informe, Los onces, Entrenamiento, Academia/Juveniles.
- REDES EN FICHAS Y DATO DEL PERSONAL (12-11): las cuatro cifras de Redes/Prensa/Debate (seguidores, funa, ánimo, prestigio) van en fichas `CifrasClave` (la funa cambia de color con el riesgo). FALLO: la tarjeta «Personal del club» decía «25 jugadores» (el plantel); ahora «N de 13 puestos cubiertos» (`DatoTarjeta`). Revisado con Ecuador (PC) y Turquía (móvil de pie); `ideas.sh men_datos` en 0 fallos. Pulir: «La gente del club», «Identidad visual» y «Equipación» no llevan dato vivo; «LO QUE SE DICE» vacío sigue en una línea.
- HISTORIA EN FICHAS (12-11): «TU CARRERA» (6 cifras) y «RACHAS» (4) pasan de una fila de cifras pequeñas a fichas grandes `CifrasClave` (% de victorias en verde, títulos en oro, peor sequía en rojo); `CifrasClave.banda(…, columnas)` reparte en rejilla (3 por fila en el teléfono tumbado, 2 de pie). Revisado con clubes de España (PC), EE. UU. (tumbado) y Portugal (de pie); `ideas.sh leg_resumen` adaptada y en 0 fallos. Pulir: en el teléfono tumbado las dos bandas ocupan casi toda la pantalla (valorar fichas compactas ahí).
- PANTALLAS VACÍAS (12-11): `EstadoVacio.crear(icono, título, pista, …)` (icono grande, qué pasa y qué lo llenará, centrado) en «Clásicos y rivales» y «Goleadores», que en una partida nueva eran una línea gris y el panel en negro. Goleadores sin goles lista además los 8 ASPIRANTES (delanteros de más media de la liga; los del club propio con su acento). Revisado con Corea (PC) y Argentina (móvil de pie). Banco `_probar_estado_vacio`. SEGUNDA TANDA (12-11): también en Linaje, Premios, Libro de movimientos y Récords (memoria, rivales, vitrina). FALLO VIEJO CAZADO: en Récords el aviso de «aún no hay nada» NO SALÍA NUNCA (`_filtrar_records` contaba la cabecera «TU CARRERA», siempre visible, como contenido) y los textos de `VACIO_RECORDS` no estaban traducidos; arreglado y traducido. `prueba_secciones_menu` comprueba 4 pantallas vacías (Francia y Chile). Quedan con una línea suelta, dentro de pantallas con más contenido: canteranos, grupos del vestuario, moral, «Sin títulos todavía», leyendas del club, cromos.
- TABLAS DE LIGA (12-11): el club propio se pintaba con el acento del club en crudo (un verde o azul oscuro casi no se leía sobre el panel): ahora pasa por `_con_contraste` y TODA su fila va en ese color; y la tabla deja 16 px a la derecha (la barra de desplazamiento pisaba los puntos). Revisado con clubes de México, Japón y Brasil. Falta lo mismo en la ficha del club y en goleadores.
- FALLO PROPIO CAZADO Y ARREGLADO (12-11): al partir las pestañas en pantallas, el nombre de su atajo de teclado cambiaba (`sub:plantel:Táctica` → `…Táctica.pizarra`): la T de fábrica dejaba de abrir Táctica, se perdía la migración de teclas viejas y las teclas reasignadas por el jugador quedaban huérfanas. Lo cazó la especial «atajos de teclado por menú y submenú»; `AtajosCentrales.PRIMERA` hace que la primera pantalla conserve el nombre de la pestaña; banco `_probar_atajos_tras_partir`. LECCIÓN: tras tocar menús, correr estas especiales (no las cubre el banco): líneas 99, 100, 156, 211 y 480-491 de `especiales.sh` (gestión en teléfono, estética, atajos, interfaz al límite, uifi/uite/uiaj); el 12-11 pasan las nueve.
- AVISO DE MÉTODO (12-11): `revisar_lineas.py` pone los que PASAN de 450 ARRIBA de su salida; mirar las primeras líneas («pasan de 450 líneas: 0»), no las últimas. Por mirar las últimas, `visor/edificio_club_p1.gd` estuvo en 452 líneas durante cinco subidas de esta rama (lo cazó `especiales.sh`; corregido, 449). En este contenedor `especiales.sh` tarda ~30 s por prueba (horas en total): correrlo de fondo o por bloques (`ESPECIALES_SOLO`).
- HECHO (12-11), 6.ª tanda: «Ligas y clubes» en 3 pantallas (`SECC_CLUBES` en `vistas_menu.gd`): tablas (con la ficha del club pulsado; el buscador de clubes abre esta), goleadores y clásicos y rivales (con texto cuando aún no hay rivalidades). Revisado con un club de GER.
- HECHO (12-11), 7.ª tanda: los avisos del INFORME DE LA SEMANA abren la pantalla exacta (`secc` en `Mundo.informe_de_gestion`: caja → Cuentas, marcas esperando → Patrocinadores, pretemporada → Pretemporada y horarios; banco `_probar_informe_abre_su_pantalla`). PRUEBA DE PUNTA A PUNTA nueva en `especiales.sh`: `prueba_secciones_menu.tscn` abre el menú real y comprueba, sección a sección, que cada pantalla pinta solo lo suyo (2 clubes de 2 países). FALLO QUE CAZÓ (arreglado): pedir una pantalla que el menú abierto no tiene (Táctica → balón parado con «Partido» abierto) abría la pizarra; ahora se abre el menú que sí la tiene (`Principal._abrir_en_lateral`).
- HECHO (12-11), 8.ª tanda: PAGINADOR EN PANTALLA (`PaginadorSubmenu`, en la fila de «Portada»): «◂ anterior · n / N · siguiente ▸» con el nombre de la pantalla de cada lado; con el dedo o el ratón ya no hay que volver a la portada (L1/R1 ya existía para mando y teclado). Banco `_probar_paginador_submenu`; foto con un club de MEX.
- HECHO (12-11), 9.ª tanda, TELÉFONO DE PIE: `captura_menus.sh` acepta `MOVIL=1` (con `RESOLUCION=608x1080` sale el diseño vertical). Visto así, las cuatro fichas de `CifrasClave` se cortaban (rótulo y cifra): ahora van de a dos por fila en vertical (prueba en `_probar_finanzas_por_pantallas`); el paginador compacto (flechas y «2 / 7») cabe bien. Revisado con clubes de COL y URU. 10.ª tanda (vertical, clubes de JPN, PER y KOR): el panel del submenú ahora llena el alto hasta la barra de abajo (acababa ~100 px antes); en «Órdenes de juego» el desplegable de roles ensanchaba la página y cortaba los SÍ/NO (ya no: `fit_to_longest_item = false`); las cifras en un color de club oscuro se aclaran para leerse. 11.ª tanda (vertical; clubes de NED, POR, MEX, BEL y TUR): vistas Entrenamiento, Cantera y Ligas. Arreglado: la tabla de liga perdía la columna de PUNTOS por la derecha (columnas de 34 px de pie) y en Juveniles → fondos de inversión el nombre se partía en cuatro líneas (ahora el nombre va en su línea y los fondos debajo). 12.ª tanda (clubes de ECU y PAR): en Pretemporada la explicación de cada horario baja a su línea, y los botones de fondo muestran el importe entero; vistas en vertical Finanzas → cuentas, patrocinadores y libro (bien). Con esto las 6 pestañas partidas están revisadas de pie (teléfono SIMULADO: falta la prueba del dueño en el suyo).
- BALANCE MEDIDO (12-11, sin tocar; `PAISES=URU,PAR,… godot --headless --path dinastia-godot res://pruebas/_sonda/sonda_sueldos.tscn`, semilla 20261103, proyección anual de `Finanzas` al empezar, que no cuenta premios, copas ni ventas): en las ligas grandes la masa salarial es el 20-30 % de los ingresos y nadie empieza en rojo (ESP, ENG, ITA, GER, BRA, MEX: 0 clubes; FRA, TUR, ARG: 1). En las ligas chicas de Sudamérica TODOS o casi todos los clubes empiezan con el ejercicio en rojo y los sueldos se comen los ingresos: URU mediana 100 % (16 de 16 en rojo, 14 sobre el 70 %), PAR 89 % (12 de 12), BOL 80 % (16 de 16), ECU 78 % (16 de 16), PER 59 % (13 de 18), COL 46 % (17 de 20), CHI 43 % (11 de 16). También en rojo sin sueldos altos: USA 17 de 30, NED 9 de 18, BEL 7 de 16 (ahí pesan otros gastos). No se toca sin decisión: cambia cómo se juega en esas ligas (ver PREGUNTAS PARA EL DUEÑO).
- HECHO (12-11), PIZARRÓN ENTERO EN PANTALLA: el campo dejaba vacío su cuarto de arriba y, en formaciones con el central pegado al portero (3-4-3, 5-3-2…), pedía 680 px de alto: había que deslizar para ver al portero. `PizarraTactica._alto_de` reparte ahora a los diez de campo de 0,10 a 0,71 y pone al portero aparte (0,885); el alto que pide cada formación baja a 456-504 px (cabe sin deslizar), salvo el «4-4-2 R» (rombo, 680: tres fichas en la misma columna). En «Pizarra y dibujo» el campo va sin banda de cifras. Revisado con 4-4-2 (ARG), 3-4-3 (GER) y 4-3-3 (KOR). EN EL MÓVIL (12-11): de pie cabe bien (3-4-3, GER e ITA). Tumbado (lienzo de 853 × 480) el primer arreglo dejaba al portero fuera en el 4-4-2, que antes cabía: la regla «dos fichas a menos del 14 % de lado se pisan» está pensada para 540 px de ancho; ahora `alto_para(slots, ancho_px)` usa el ancho real del campo (80 px de lado) y el 4-4-2 vuelve a 380 px y cabe (ESP). El 4-2-3-1 tumbado y con la ficha del jugador al lado (BRA) sigue pidiendo deslizar un poco: tiene dos fichas en la misma columna. Sin ver: el rombo.
- FALTA (siguientes tandas): «Mi plantel» (la lista ya ocupa la pantalla: valorar si conviene), bandas de cifras en Cantera y Ligas; que los avisos del informe semanal abran la sección exacta (hoy «marcas esperando» abre Finanzas en la última sección vista).

## IDEA DEL DUEÑO (10-11 tarde): LIGAS ACTIVAS Y DESCARGAS OPCIONALES
- **Ligas activas** (en curso, sesión 6; cifras de coste: sesión 5 en `docs/04_auditorias/coste_mundo_2026-11-10.md`): al empezar partida se eligen los países que se cargan (PC: todos; móvil: su país + las grandes por defecto); el resto no se carga; continentales y selecciones funcionan con relleno ligero; se pueden añadir ligas al cerrar temporada. `Mundo.generar(paises)` ya lo admite; hoy el juego siempre pasa la lista vacía (= todo).
- **Descargas opcionales** (DESPLAZADO A LA SEMANA PRÓXIMA por el dueño, 10-11; se hace después de «Ligas activas»): juego base ligero + paquetes `.pck` de recursos (estadios icónicos, caras, sonido; `assets/` = 394 MB) montados con el mismo sistema que `PaqueteReal`/`Parches`. Dudas: dónde alojarlos (Releases de GitHub o Drive; no en el repo), Google Play (solo datos/recursos, sin scripts, o Play Asset Delivery) y versión del paquete frente a la del juego.

## ENCARGO DEL DUEÑO (10-11 noche) — EN ESTE ORDEN; auditoría completa en `docs/04_auditorias/AUDITORIA_CONTENIDO_2026-11-10.md`
- **PASO A C++ (orden 35, sesión 5; detalle en `docs/04_auditorias/PASO_CPP_PLAN.md`)**: HECHO el partido simulado de la IA en C++ (`simular_90` con el mismo generador PCG32, goleador/asistente, `medias_linea`, choques `_cuerpos` del motor jugable), con gemelo GDScript y IGUALDAD EXACTA (2.094 cruces comparados); semana del mundo 786 → ~380 ms (−50 %). NO se porta el motor 3D en directo (lo que cambia a diario y en móvil manda la GPU). Semana del mundo entero 1532 → ~1280 ms (MercadoDT.presiones_de por liga) y `_cerrar_notas` a C++ (10-11, §2f). `.so` de Android arm64 HECHO (NDK r27c, §2g). PENDIENTE: `.dll` de Windows sin recompilar (CI o dueño; `compilar_nativo.sh windows` con mingw); caché del once DESCARTADO (forma/moral cambian cada semana); siguiente paso real: arrays planos de atributos (§2g); `--export-pack` de los 5 presets OK (solo avisa Web: sin wasm32). La sesión 5 pasa a RENDIMIENTO EN MÓVIL (GPU).
- **RENDIMIENTO EN MÓVIL (GPU), sesión 5, 10-11 (informe `docs/04_auditorias/rendimiento_movil_2026-11-10.md`)**: HECHO sin MSAA en BAJA/MEDIA BAJA (y MEDIA en móvil/web): fotograma relativo −57…−69 % con 3 clubes de 3 países; club a pie sin dibujar el estadio de fuera dentro del edificio (−52 % llamadas, −70 % triángulos); menú con bajo consumo también en BAJA/MEDIA BAJA (1 fotograma en 3 s en vez de ~50); pantalla de carga con barra entre la entrada y el menú; precarga de los 56 scripts del menú en la portada (montaje 2,0 → 1,2 s); montaje del menú en trozos detrás de la carga. MEDIDO Y DESCARTADO por ahora (opción disponible si el dueño la pide): **impostores de cuerpo** para los jugadores a >30 m (techo medido −10 % de fotograma, −12…−23 % triángulos, con cambio visible: sin animación; un impostor real ahorraría menos), y subir `mesh_lod_threshold` (−5…−9 % triángulos, satura). PENDIENTE DEL DUEÑO: recortes de ULTRA BAJA (<130 llamadas: pelo, hinchas, butacas lejanas), sombra solar en MEDIA (−13 a −17 %), ahorro del menú en MEDIA/móvil; MEDIR en su teléfono: MSAA, primer dibujado del menú (shaders) y arranque.
1. **TORNEOS Y COPAS** — HECHO (10-11): el Mundial y los torneos continentales de selecciones en sus años reales, iguales al calendario; las COPAS de TODOS los países (también la segunda copa, el mismo año) y sus SUPERCOPAS, simuladas con azar aislado, con el palmarés del mundo guardado en la partida (`CopasMundo`, banco `_probar_copas_mundo`). HECHO también (sesión 6, 10-11): los 8 continentales con SU formato en una tabla (`FormatosConti`): Champions, Europa League y Conference con fase de liga de 36 (8 o 6 partidos por bombos, `SorteoLigaConti`, playoff y octavos a ida y vuelta), Libertadores y Sudamericana de 32 en 8 grupos, Asia Elite de 24 con fase de liga, África (y la Confederación) de 16 en 4 grupos, Oceanía de 8 y Concacaf por eliminación; semanas de rondas para el calendario largo; SUPERCOPAS continentales (Europa, Recopa Sudamericana, CAF; `SupercopasConti`); MUNDIAL DE CLUBES de 32 jugable (8 grupos de 4 + eliminatorias, `MundialClubes`, plazas de la FIFA en `FifaClubes`) y COPA INTERCONTINENTAL (`CopaIntercontinental`); banco `continentales`; captura `pruebas/captura_conti_formatos.tscn`. FALTA: Leagues Cup, previas de la Libertadores (hoy 32 directos), mostrar el palmarés del mundo en Historia y Competiciones.
2. **SELECCIONES** — EN CURSO (10-11): HECHO que cada selección sea un EQUIPO de verdad (`SeleccionEquipo`) y que el Mundial (32) y los torneos continentales se JUEGUEN con partidos (`TorneoSelecciones`, `SeleccionesTorneos`; banco `_probar_torneos_selecciones`; arreglado: los partidos simulados salían todos 0-0). HECHO el cargo de SELECCIONADOR (`CargoSeleccion`: ofertas por prestigio con azar aislado, evento a pantalla completa `EventoSeleccion` + Club › Legado, doble cargo con sueldo, dimisión, historial y prestigio por título, guardado) y sus torneos JUGABLES al acabar la liga (`JornadaSeleccion`: cada partido de tu selección en directo, simulado o «el resto»; banco `_probar_cargo_seleccionador`; captura `pruebas/captura_cargo_seleccion.tscn`). HECHO también la CONVOCATORIA (hasta 26 del país en todo el mundo, a pantalla completa desde Club › Legado; banco `_probar_convocatoria_seleccion`). HECHO también: fechas FIFA (amistosos, eliminatorias y Nations League), Mundial de 48, 63 selecciones y la FINALISSIMA (10-11, `Finalissima`: campeón de la Eurocopa contra el de la Copa América el mismo año, partido único en sede neutral con penaltis, azar aislado, en el palmarés del mundo y en tu historial si la juega tu selección; banco `_probar_finalissima`; hoy simulada, no jugable en directo). HECHO también los JUEGOS OLÍMPICOS (10-11, `Olimpicos`: cada 4 años desde 2028, 16 selecciones sub-23 con hasta 3 mayores por cupos de confederación, grupos y eliminatorias simulados con azar aislado, en el palmarés del mundo; no cuentan como seleccionador; banco `_probar_olimpicos`). HECHO también jugar la Finalissima EN DIRECTO si tu selección es campeona continental (`Finalissima.preparar` + `registrar`, `JornadaSeleccion.jugar_torneos`; banco `_probar_finalissima_directo`). FALTA: cargo SOLO de selección (sin club); dirigir el equipo olímpico.
3. HECHO (10-11, sesión 3): CELEBRACIONES por tipo de título en 2D y 3D (escenario, palco con medallas, fuegos, abrazo, manteo con tu DT, foto, champán, desfile en autobús, pasillo del rival, tifos en finales, festejo propio de tu selección; ascenso y salvación); en ULTRA BAJA, 2D. Pulir: revisión del dueño.
4. HECHO (10-11, sesión 2; ver PULIDO «OBJETIVOS POR CLUB»): objetivos por club.
5. **CONTENIDO DEL MUNDO** (ver la auditoría, §7: un formato de datos por país, todo lo demás generado; por niveles; HECHO sesión 6, 10-11: `herramientas/importar_pais.py` + `herramientas/paises/<COD>.csv` —un país nuevo = un CSV de clubes y datos— con TUR 18, SCO 12, SUI 12, AUT 12, GRE 14 y QAT 12 clubes reales, sus cupos de UEFA/Asia y banco `paises_csv`; segundas divisiones de 11 países (también POR, NED y TUR con `<COD>_2.csv`) y POR/BEL/CRO/DEN con sus clubes reales; SWE, NOR, POL, CZE, ROU, SRB, UKR y CHN con su liga y cupos; FASES FINALES de liga con `FaseFinalLiga` + `ZonasLiga` y su pantalla en la ficha: Egipto (campeonato 7 / descenso 14), Argentina (zonas reales y playoffs), MLS (conferencias y series al mejor de 3), Bélgica (play-offs, puntos a la mitad), Escocia, Dinamarca, Suiza y Austria (grupos finales); también Grecia (play-offs de campeonato, de Europa y play-outs) y Bélgica con play-offs de Europa; MLS con 1 fecha interconferencia; PENDIENTE: las 6 fechas interconferencia reales de la MLS y las 10 de los play-offs belgas no caben en 38 semanas; TUR, POR, CRO y QAT se juegan a doble vuelta sin fase final, como en la realidad): faltan 101 países, ~3.400-5.900 clubes, ~67 clubes en las ligas que ya hay (recortadas a 16), ~117.000 jugadores, caras (la biblioteca de 300 mezclas ya es pública, 10-11), 150 estadios icónicos, escudos y uniformes. (10-11, orden del dueño) HECHO: cada club con su FORMACIÓN y ESTILO de la vida real (`EstiloClub`, `datos/estilos_clubes.json`: 402 clubes con nombre ficticio; con la base real se empareja por puesto; los 64 genéricos de POR/BEL/CRO/DEN, por su país; antes los 466 jugaban 4-3-3 con todo en «medio»; banco `_probar_estilos_club`). EQUILIBRADOS (10-11, caza de la sesión 2): con los estilos el simulado subía a 3,71 goles por partido (las perillas pasan por el exponente 3,2); ahora cada estilo cambia ataque por defensa y se aleja ~7 % de lo neutro (2,75 goles; `cifras_partido`, `s5_auditoria_partidos` y `est_partido_simulado_reglas` en verde; huellas re-selladas). Dudosos y modestos rebalanceados a mano por regla: revisar. HECHO (10-11 noche): LIGAS REALES con su cantidad real (`herramientas/ligas_completas.py`: +93 clubes reales con nombre ficticio, 38 descendidos fuera; ENG/ESP/ITA/BRA/COL/JPN 20, GER/FRA/MEX/KSA/NED 18, EGY 21, PER 18, ARG y USA 30 a una vuelta, PAR/KOR/AUS 12; historia de los 93 y 22 clásicos nuevos; 14 años de fundación sin confirmar). ESCUDOS realistas en 134 clubes (sesión 2). 63 selecciones y Mundial de 48. Comparativa con PES 2020 en `docs/04_auditorias/COMPARATIVA_PES2020.md`. EN CURSO: estadios realistas (sesión 3: evaluar y mejorar la herramienta, 10 icónicos), uniformes de los 466 y caras coherentes con el jugador real (sesión 2). Comprobado (10-11): con las ligas reales la temporada dura 38 semanas (ligas de 20), la copa y los continentales cierran dentro, el mundo entero se simula en ~27 s; ARG, USA (30) y EGY (21) juegan a UNA vuelta (`Liga.UNA_VUELTA_DESDE` 20; Egipto juega así su primera fase en la realidad). FALTA: fase final por grupos (campeonato/descenso) de Egipto y zonas de Argentina; conferencias de la MLS.
6. **MOTOR DEL PARTIDO**: REEMPLAZAR nuestro sistema por el de League-Soccer (C++, `terceros/league_soccer/codigo_y_recursos`), con lo nuestro montado encima como variante, más las animaciones y extras que ya tenemos. Orden expresa del dueño (prevalece sobre las órdenes 23-24). Sesión 4, rama `sesion4-motor-league`: fases 1 (estudio y plan) y 2 (PROTOTIPO `MotorLeague` detrás de `MOTOR_LEAGUE=1`) HECHAS el 10-11; plan, fases 3-7 y cifras en `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`. Fase 3 (IA sin balón) HECHA el 10-11: CPU −18 % frente al motor de siempre; remates 11,7 frente a 39,7; un equipo se queda ~80 % del balón (hallazgo en el plan §7). Siguiente: fase 4 (locomoción guiada por animaciones, que deja pasar los tiros y trae los robos por alcance). NO se propone por defecto aún.
5. **CONTENIDO DEL MUNDO** (ver la auditoría, §7: un formato de datos por país, todo lo demás generado; por niveles): faltan 107 países, ~3.500-6.000 clubes, ~67 clubes en las ligas que ya hay (recortadas a 16), ~117.000 jugadores, caras (la biblioteca de 300 mezclas ya es pública, 10-11), 150 estadios icónicos, escudos y uniformes.
6. **MOTOR DEL PARTIDO**: REEMPLAZAR nuestro sistema por el de League-Soccer (C++, `terceros/league_soccer/codigo_y_recursos`), con lo nuestro montado encima como variante, más las animaciones y extras que ya tenemos. Orden expresa del dueño (prevalece sobre las órdenes 23-24). Sesión 4, rama `sesion4-motor-league`: fases 1 (estudio y plan) y 2 (PROTOTIPO `MotorLeague` detrás de `MOTOR_LEAGUE=1`) HECHAS el 10-11; plan, fases 3-7 y cifras en `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`. Fase 3 (IA sin balón) HECHA el 10-11: CPU −18 % frente al motor de siempre; remates 11,7 frente a 39,7; un equipo se queda ~80 % del balón (hallazgo en el plan §7). Fase 4a HECHA el 10-11 noche (rama `sesion4-motor-league-2`): catálogo de toques de las animaciones originales, robos por alcance, conducción que el rival fastidia y cortes de pase. HALLAZGO: el balón cambia de dueño 3 veces menos que con el motor de siempre (25 frente a 77), sobre todo porque remata ~9 veces frente a ~49, y la posesión acaba 70-85 % para uno (plan §8). Siguiente: fase 4b (la cola de órdenes con el filtro de animaciones y el primer toque). NO se propone por defecto aún. Sesión 9 (11-11, rama `sesion9-motor-fase4`): fase 4d hecha (catálogo etiquetado extensible en `datos/anims_extra/`, guía `LeagueGuia`, humano nunca más lento, precarga sin tirones, falta leve y celebraciones de CMU) y mejora de C4 (§11-12 del plan del motor): guía en C4 APAGADA (peor), HÍBRIDO de ataque `C_ATAQUE_LEAGUE=1` (cadenas de 5+ ×2-3, +regates; −ocasiones, +14-19 % CPU; apagado). FALTA: recuperar ocasiones (último tercio `C_TERCIO` sin medir, desmarques, balones largos), bajar CPU (`C_CADENCIA_ESTADO` sin medir), disputa aérea y recorte de clips de CMU. Sesión 9 (11-11, rama `sesion9-motor-fase4`): fase 4d hecha (catálogo etiquetado extensible en `datos/anims_extra/` + guía del movimiento `LeagueGuia`, §11 del plan del motor); falta calibrar su fuerza con 6+ partidos y capturas con cámara real.
7. HECHO (10-11): las caras de la alineación se ven enteras (`Retrato3D.ALTO_CABEZA` 70).

8. **LIGAS ACTIVAS** (encargo del dueño vía líder, 10-11, sesión 6; «como Football Manager») — HECHO el núcleo y la interfaz: `nucleo/ligas_activas.gd` (lista por defecto: PC todas, móvil CHI + los 5 grandes; lista guardada con la partida, deducida de las ligas en partidas viejas; `agregar` añade países al cerrar la temporada sin mover ids y vuelve a montar copas y continentales), pantalla `ui/entrada/ligas_activas_pantalla.gd` (etapa «ligas» entre modo y país; mismo componente en modo AÑADIR al cerrar la temporada, enganchado en `AccionesTemporada._ofrecer_ligas`), los 5 sitios que generan el mundo usan `LigasActivas.para_generar()`, textos en 9 idiomas, banco `_probar_ligas_activas*` (mundos de 1, 2, 5 y 86 países, guardado/carga, añadir a mitad de partida, pantalla). MEDIDO: los cupos continentales ya se reparten entre las ligas activas (5 grandes: ucl/uel/uecl de 36; CHI sola: lib de 32), así que NO hacen falta clubes «ligeros» por ahora. FALTA: que el dueño decida «mi país» en móvil antes de elegir club (hoy CHI), captura de la pantalla en móvil/portrait y su revisión, y el coste real en el móvil (sesión 5). HECHO (10-11) Ajustes → Partida «Añadir ligas» con la temporada sin empezar; HECHO (12-11, como Football Manager) con la temporada en marcha el mismo botón PROGRAMA las ligas para la siguiente (`LigasActivas.programar`, guardadas con la partida, entran solas al cerrarla sin tocar las copas en curso; banco `_probar_ligas_programadas` con PER+URU→COL y `auditoria_ligas_activas` 0 fallos en horizontal y vertical).
9. **DATOS DE LIGAS: SIGUIENTE PASO (sesión 6, 10-11, cierre ordenado por el dueño)**: HECHO el mundo de 135 países / 2.206 clubes, la pasada RSSSF (104 países con CSV) y ARM 12 / ZAM 20 / MDA / COD 20 (2026/27 provisional). PENDIENTE, anotado en `docs/04_auditorias/datos_dudosos_2026-11-10.md`: (a) los ~13 ambiguos sin resolver (PLE, NZL, HAI, y la elección de los 20 de COD); (b) los 28 países BASE comparados con RSSSF solo en cantidad y nombre: corregir MAR y RSA (listas anteriores) y revisar BRA, URU, ECU, BOL, KOR y JPN (el pack parece ya 2026); (c) colores, fundaciones, apodos y medias de TODAS las ligas de las tandas 2-5 siguen de memoria; (d) abrir Soccerway y Transfermarkt (no se abrieron). RSSSF abre solo desde `https://www.rsssf.org/curdom.html`.

## RESPUESTAS DEL DUEÑO A LAS 21 PREGUNTAS (10-11 noche) — se borra cada fila al completarse
- MOTOR NUEVO (League-Soccer): SOLO LO VISUAL; no se calibra.
- GUARDADO DE JUGADORES con campos fijos (en vez de diccionarios): SÍ. Encargo grande: con la misma huella de igualdad y migración de las partidas guardadas.
- COLORES DE CAMISETAS: los verifican las sesiones con búsqueda en fuentes (sesión 4: 7 ligas grandes; sesión 6: RSSSF).
- RAMAS VIEJAS: el dueño DA PERMISO para borrarlas. Se borran solo las que tienen TODO su trabajo en `main` (comprobado commit a commit con `git cherry`); las que tengan algo propio se revisan antes. Se conservan siempre `respaldo-*`, `borrar-*` y `entregas/`.
- `.mp4` de `marca/`: NO se sacan (son ejemplos de referencia).
- VERSIÓN: 0.9.2, y hacer lo necesario para exportar (incluido el `.so` de Android de la extensión C++).
- BIBLIOTECA DE CARAS (mezclas, no personas reales): SÍ, se publica en la versión pública. HECHO (10-11, sesión 4): fuera de los filtros de los 5 presets y del paquete privado; `revisar_build_publico` exige que viaje y el banco lo comprueba.
- FOTOS REALES de `caras_reales.pck`: el dueño no entendió la pregunta → se mide desde aquí (cuántas caras monta el `.pck` si está) y se le explica.
- MUSEO: la planta extra se abre por TÍTULOS GANADOS y con un MINI EVENTO (la animación de expansión).
- NERVIÓN y FPS en su teléfono: el dueño AÚN NO PUEDE probarlos.
- ESTADIOS en las celebraciones: SÍ a la versión simplificada de verdad de la grada lejana / público más barato. (10-11, sesión 3, SIN EMPEZAR en el código del juego). Hecho: el diagnóstico. El plano de celebración a ras de césped dibuja ~850-1.100 llamadas porque entran en el encuadre las cuatro tribunas, el público y los focos (sin ninguna pieza escondida que culpar; ver `04_auditorias/ESTADIOS_REALISTAS_PLAN.md`). La prueba fija `pruebas/medir_grada_cine.tscn` (cámara del gol en (-9, 2, -55), DESGLOSE=1 quita pieza a pieza con llamadas y triángulos) está lista pero no se llegó a correr entera. Falta: un sustituto simplificado por tribuna lejana (una malla con la textura de grada y público pintado) que se encienda solo en cámaras de celebración y repetición, detrás de bandera, medido y con capturas Forward+ en 3 estadios de 3 países (uno icónico). Lo probado y DESCARTADO por notarse: `LodCine` (apagar piezas pequeñas lejanas; bandera apagada) y ocultar el vestuario.
- ENTORNO del estadio en los vuelos altos: DESCARTADO (10-11, líder y sesión 3). Ya está agrupado en 95 MultiMesh (~900 piezas) en celdas de 160 m; un corte a 150 m apagaría celdas enteras (se nota) y como mucho ahorraría ~95 llamadas de ~1.800 del vuelo (≈5 %).
- MÓVIL, POR DEFECTO: «Modo rendimiento» ENCENDIDO; «Ahorro en los menús también en Media» ENCENDIDO; TOPE de 90 FPS.
- ULTRA BAJA: NO se simplifican más hinchas, butacas ni jugadores lejanos.
- WEB en el móvil: SÍ a las texturas comprimidas. HECHO (10-11, sesión 4): preset aparte `WebMovil` (ETC2/ASTC; la `Web` de PC sigue con S3TC). Medido con `--export-pack`: Web 374,5 MB (312,7 MB con gzip) → WebMovil 374,5 MB (310,0 MB con gzip), sin crecer; poner las dos compresiones en un solo preset la habría subido a 474,7 MB (+27 %). En el CI sale en el trabajo web (artefacto `Dinastia-Web-movil`), en `empaquetar.ps1 -Formato web` y en `revisar_build_publico`. Falta probarla en un teléfono real (dueño).
- VERTICAL: DISEÑO PROPIO para el partido y los menús (no se quita). HECHO en parte (sesión 8, rama `sesion8-vertical`, 10-11): lienzo de 540 px de ancho de pie (`EscalaMovil.ANCHO_VERTICAL`: letra ≥ 1,8 mm y toques de 7 mm), barra inferior en vez del riel (`MenuLateral.abajo()`), filas que se deslizan y columnas apiladas (`DisenoVertical`), contenido+ficha apilados en `PantallaMenu`, ficha de competición a 500 px, arco de botones táctil propio (`ControlesTactiles.BOTONES_V`) y cámara con el ANCHO fijo (`CamaraTactil.adaptar`). Capturas antes/después en `docs/04_auditorias/capturas_vertical/` (auditoría de gestión: 22 fallos → 3). FALTA: Ajustes (filas con casilla a la derecha se recortan), nombres del plantel cortados, el cajón 🎯 sobre el último botón del Inicio, pantallas de entrada (idioma/país/club/personaje), minijuegos y ciudad, y que el teléfono pueda girar: `project.godot` sigue con `handheld/orientation=0` (apaisado), decide el dueño pasarlo a sensor (6).
- CABECERA COMPACTA: le gusta, se queda.
- ICONOS: los DIBUJADOS por defecto (los emojis quedan como opción).
- TECLADO CON MANDO (Triángulo = espacio, X = tecla): le vale.

## RESPUESTAS DEL DUEÑO (10-11)
- Quitar la palabra «PES» de la interfaz: HECHO («Plantilla detallada»).
- Estrategias rápidas en el partido: SÍ (hecho, ver abajo).
- RUEDA DE PRENSA Y EVENTOS al estilo del PES (su rueda de prensa es «muchísimo mejor en lo visual» y tiene eventos): conservar los nuestros y SUMAR los suyos, adaptando su estética a la nuestra. Encargado a la 3.ª sesión (rama `sesion3-rueda-prensa`), con la selección direccional del PDF (stick, clic o toque, con mini animación).
- COLORES: el dueño PERMITE variar la paleta («mucho verde con dorado»).
- PASAR A `main`: SÍ (10-11). Hecho por avance rápido de `ccr-1447f2a7-cdar0x`, con el banco en «FIN. 0 fallos».
- PRÓLOGO (10-11): el dueño ordenó ELIMINAR POR COMPLETO el prólogo animado dibujado por el motor (el primer corte del 9-11 y su versión de cine): hecho, sin restos en el código. El NUEVO prólogo será la IDEA DEL DUEÑO (la pasa él) y OBLIGA a subir antes la calidad de las INSTALACIONES DEL CLUB y de los MODELOS 3D (realismo y animación). Hasta entonces, con la ciudad apagada, no hay prólogo.
- Siguen abiertas: los torneos de selecciones y los .mp4 de `marca/`.

## IDEAS DEL PES 2020 PARA ADAPTAR (pedido del dueño, 10-11; investigación con fuentes, sin copiar arte ni marcas)
Dinastía ya tiene casi todo el temario de la Master League (cesiones, ojeadores, agentes y cláusulas, reconversión de puesto, capitán, vestuario, charlas, junta, informe del rival, valoraciones). Lo que falta es sobre todo MOSTRARLO. Por prioridad (★ = mucho impacto, poco esfuerzo):
1. ★ HECHO (10-11): FLECHA DE FORMA de 5 estados junto a cada jugador en la plantilla (`FlechaForma`, desde `Jugador.forma`). (12-11) Ya está también en la lista del once de Táctica y en las fichas del pizarrón (`PizarraTactica._ficha_jugador`, arriba a la izquierda de la cara). Falta: en el once del partido.
2. ★ HECHO (10-11, solo en pantalla): QUÍMICA entre compañeros de línea (`QuimicaLinea`: clan del vestuario, país, temporadas juntos y moral; `QuimicaCampo` la dibuja en el campo de la plantilla en verde, amarillo o rojo). Falta: mostrar la cifra por línea y, si el dueño quiere, que sume al motor con bandera.
3. ★ HECHO (10-11; el dueño lo APROBÓ el 10-11): ESTRATEGIAS RÁPIDAS en el partido (`EstrategiaRapida` + `BarraEstrategias`): ⚔ Ataque total, 🔥 Presión arriba, ⚡ Contraataque y 🔒 Cerrojo, preajustes de las 4 palancas de la pizarra (el motor no cambia), sin parar el partido; volver a pulsar recupera el plan; 2 minutos de espera entre cambios; Alt+1…4 y L2 + cruceta; banco `_probar_estrategia_rapida`. Pulir: probarlo con mando real y en el móvil (sitio junto a los controles táctiles).
4. HECHO (10-11): el OBJETIVO de la directiva en el menú central con tu puesto, la meta y una barra de progreso (`ObjetivoDirectiva`). Falta: metas de copa y beneficio.
5. RUMORES y «último día» del mercado con ofertas relámpago.
6. ESCENAS de diálogo a pantalla completa en hitos (fichaje estrella, despido, ascenso) con 3 respuestas (`EventoPantallaCompleta`).
7. Informe de ojeador con RANGOS de atributos que se afinan con las semanas.
8. Pantalla de PLAN DE JUEGO con 2 instrucciones de ataque y 2 de defensa.
9. HECHO (10-11) en la lista de la plantilla: la «C» amarilla del capitán (`PlantillaHabilidades.brazalete`). (12-11) Ya está también en la lista del once de Táctica y en su ficha del pizarrón.
10. HECHO (10-11): JUGADOR DEL MES cada 4 semanas en tu liga (`PremioMensual`: últimas notas, queda en su ficha, prensa y +moral si es tuyo). Falta: tarjeta a pantalla completa y once ideal del mes.
11. Revisar el alcance del editor de la partida.
13. FORMACIONES PROPIAS (pedido del dueño, 10-11 noche, «como en el PES 2020»): HECHO lo básico (sesión 4). En la pizarra de Táctica, «✏ Editar posiciones» abre `EditorFormacion` con la formación actual como base: cada ficha se arrastra (ratón o dedo; teclado o mando: Tab cambia de ficha, flechas la mueven), el PUESTO de la ficha movida cambia solo según la zona (`FormacionPropia.puesto_de`), el portero no se mueve y quedan al menos 3 defensas; «Guardar» la deja como «★ nombre» junto a las de serie (hasta 6) y la usan el once, el partido 3D y los dos motores (se registra en la tabla `FORMS`); viaja en la partida (`fprop`). Banco `_probar_formacion_propia`; captura `pruebas/_sonda/captura_editor_formacion.tscn` (dos clubes de países distintos). Falta para igualar al PES: la FORMACIÓN FLUIDA (una colocación para el saque, otra con balón y otra sin balón), elegir la base desde el propio editor y pulir el aspecto (fichas con cara como la pizarra).
12. HECHO (10-11): el patrocinador oficial (logo de `SponsorKit`) arriba del resumen de temporada; la sala de prensa ya tenía su pared de patrocinadores.
14. MENÚ CENTRAL DE LA MASTER LEAGUE (referencia del dueño, 11-11; foto en el Drive: `Dinastia_respaldo_2026-10-24/referencias_del_dueño/PES2020_ML_menu_central_2026-11-11.jpg`): pestañas arriba (Avanzar en el tiempo, Dirección del equipo, Información de mi equipo, Oficina del DT, Base de datos, Sistema) con el escudo al centro; tarjeta del ENTRENADOR con su consejo táctico («con táctica ofensiva, el estilo de ataque será: juego de posición»); NOTICIA DE VESTUARIO con foto («Efecto de maestro»: un jugador aprende de otro); TABLA top 10; los 4 PRÓXIMOS PARTIDOS (icono de competición, escudos, hora o resultado, estadio y fecha); SEGUIDORES del club (contador); COLABORADORES oficiales (patrocinadores). Comparar con nuestro menú central y adaptar lo que falte, con nuestra estética. COMPARADO (12-11, líder) con la pantalla real: ya teníamos el próximo partido, la racha, el objetivo de la directiva, la FILA DE ESCUDOS (`FilaProximos`) y la TABLA entera (columna izquierda). HECHO: SOCIOS en la cabecera (`ResumenInicio.socios_txt`) y PIE DE AYUDAS DEL MANDO (`PieMando`, solo con mando: A Elegir · B Volver · LB/RB Sección/Submenú · LT/RT Bloque/Menú, en el central y en los menús a pantalla completa; punto (3) de la referencia PES). FALTA: consejo táctico del ayudante, noticia de vestuario con foto, patrocinadores (central liviano por orden del 3-11: solo si el dueño lo pide).
Fuentes: fourfourtwo.com (reseña PES 2020), gamesatlas.com (Master League remastered), konami.com/pes2020, pesmastery.com/?p=7515, redbull.com (guía PES 2020), manual de Konami PES 2019. Sin confirmar en PES 2020: química, flechas, objetivos y rumores (vienen de la serie en general).

## DECISIONES PENDIENTES DEL DUEÑO (no se implementa hasta que conteste)
- Ninguna abierta a 10-11 noche. Las del motor League-Soccer (calibrar o no: SOLO LO VISUAL), los torneos de selecciones (ya se juegan) y los .mp4 de `marca/` (se quedan) se resolvieron con la orden 36.

## PULIDO (lo ya completo que se pule después; nada se borra, se afina)
- TIEMPO HASTA JUGAR (10-11, sesión 5; `docs/04_auditorias/rendimiento_movil_2026-11-10.md`): hechos «Continuar» con pantalla de carga, `_sacar_los_22` en tres tiempos y el CajonAjustes perezoso (E6, −0,24 s de CPU al montar el estadio). E7 NO se aplicó: con menos de 10 fotogramas de estabilizar vuelven los tirones (con 1: 1.015 ms). E5 PENDIENTE: llevar el edificio del túnel (0,26-0,61 s) y los extras (0,24-0,50 s) a la intro solo si antes `EdificioClub.montar` y los extras se parten en pasos de ~100 ms (hoy son síncronos); verificar con capturas fotograma a fotograma de 3 estadios (uno icónico). Si no, cambia espera por un tirón de 0,5-2,5 s en el móvil.
- ESCUDOS Y UNIFORMES DE LAS LIGAS RESTANTES (10-11, 2.ª pasada de los 268; `_escudos.txt` y `_uniformes.txt`): 85 clubes más con forma, patrón, figura o letras y, donde se sabe, camiseta, pantalón y medias propios: los 36 que no tenían ni figura ni letras (Países Bajos, México, MLS, Chile, etc.) y los grandes de Uruguay (Peñarol, Wanderers, Danubio, River, Liverpool M., Defensor), Paraguay, Perú, Ecuador, Bolivia, Colombia, Arabia (Hilal, Nassr, Ittihad, Ahli, Shabab), Egipto (Ahly, Zamalek), Marruecos, Sudáfrica (Pirates, Chiefs, Sundowns), Corea (Pohang, Seúl) y Australia. Revisado con hojas de 12 escudos y 12 uniformes de 12 y 6 países. HONESTO: los clubes menores de esas ligas (más de 100: la mayoría de Chile 2.ª, Egipto, Marruecos, Sudáfrica, Arabia y Oceanía) siguen con letras genéricas y colores de la liga porque no conozco con seguridad su escudo ni su camiseta; los que no traen colores en la fila no tienen segundo uniforme escrito (el juego deduce uno si chocan). Para acercarlos hace falta una fuente de datos del dueño (lista de escudos y camisetas) o más investigación.
- ESCUDOS Y DISEÑO DE UNIFORME DE LOS 93 CLUBES NUEVOS (10-11, `ligas_completas.py` → `_escudos.txt` y `_uniformes.txt`): cada uno tiene contorno, patrón, figura o letras (de las 38 del vocabulario: toro, lobo, león, águila, ave, pez, sol, montaña, caballo, ancla, torre, estrella, rayo, cruz) y, donde se conoce, su diseño de camiseta (franjas, mitades, aros, banda, mangas de contraste); los colores y el segundo uniforme salen de los de la liga (deducido por contraste). Con esto los 457 clubes tienen aspecto. Revisado con hoja de 12 clubes de 6 países (Leeds, Sunderland, Levante, Elche, Gimnasia LP, Platense, NY Red Bulls, D.C. United, Kashiwa, Fagiano Okayama, Bragantino, Vitória). Pulir: los 93 usan colores aproximados de `ligas_completas.py` y un uniforme base sin pantalón ni medias propios; el segundo uniforme es el deducido, no el real; las figuras son genéricas (p. ej. Burnley o Parma sin su dibujo propio); quedan por retocar los clubes de las ligas medianas anteriores (los 268 restantes).
- ESCUDOS MÁS PARECIDOS AL REAL (10-11, encargo del dueño; `herramientas/aspecto_clubes/_escudos.txt`): reescritos a mano contorno, patrón, figura, letras y colores de 134 clubes de las 10 ligas grandes (ESP, ENG, ITA, GER, FRA, ARG, BRA, MEX más Países Bajos y MLS en parte), con el vocabulario del juego, y un PATRÓN NUEVO, los rombos bávaros (`rombos_bav`, damero girado 45°: Bayern). Ejemplos: Real Madrid (círculo con aro azul y corona dorada), Boca (escudo con franja horizontal amarilla y CABJ), River (banda diagonal roja y CARP), Bayern (rombos azules y blancos), PSG (torre). Los datos reales van a la tabla del pack real y, con el nombre ficticio, a la pública (`base_ficticia.py`). Revisado con `pruebas/captura_escudos.tscn` (REAL=1 solo en local, CLUBES=… PAISES=…): 12 clubes de 6 países antes/después. Banco `_probar_escudos_realistas`. FIGURAS NUEVAS (tanda 2, 10-11, `EscudoEmblemas`): torre de París (`eiffel`), `murcielago`, `gallo`, `carabela`, `toro`, `dragon`, `castillo` y `delfin`, dibujadas en vectores como las 30 anteriores (hoja de revisión: `FIGURAS=1` en `captura_escudos.tscn`). Ya las usan: Paris SG (eiffel), Valencia (murciélago), Tottenham (gallo), Leipzig (toro), West Ham (castillo). Libres para los clubes nuevos de `ligas_completas.py` (dragón: Porto y equivalentes; carabela y delfín: clubes de puerto; murciélago: Mallorca/Levante si se confirma su escudo). Pulir: el dragón es una cabeza esquemática y el gallo y la torre son siluetas simples; PSG, Valencia, Tottenham o Celta son solo parecidos; el segundo escudo/retro, los 268 clubes fuera de las 10 ligas y los 64 por sorteo siguen genéricos; los colores son los de siempre del club real, no los pantones.
- CARAS POR PAÍS PARA LOS JUGADORES SIN FOTO (10-11, encargo «uniformes y caras», parte 2; `herramientas/rasgos_por_pais.py` → `datos/rasgos_pais.json`, `CaraPrior`): de los 4.311 jugadores de nombre fijo, 1.340 tienen cara medida (rasgos de foto o malla 3D) y 2.971 NO tenían nada: en la base real recibían un azar total (piel de 8 tonos a partes iguales, barba 0-7, cualquier corte) y en la pública una piel por país muy tosca con barba al azar. Ahora toman las PROPORCIONES de su país medidas en las caras reales (piel, color de pelo, barba, calvicie; solo cifras por país, sin nombres ni fotos; los países con menos de 12 caras usan la media mundial) con corte sobrio (rizado/afro posible en pieles oscuras) y sin marcas inventadas; determinista por jugador y sin tocar el motor. MEDIDO con validación cruzada de 5 pliegues sobre las 1.340 caras reales (acierto esperado de adivinar cada rasgo): piel ±1 tono 34 %/45 % (base real/pública, antes) → 44 %; color de pelo 28 %/29 % → 42 %; barba con/sin 41 % → 55 %; tipo de barba 12 % → 46 %; «cara coherente» (piel ±1, pelo y con/sin barba bien las tres) 3,8 %/4,9 % → 11,3 % (regenerado el 10-11 con el pack de ligas reales: 1.273 caras medidas, 80 países; antes 1.340 y 81). CORRECCIÓN (10-11, la detectó el banco completo): la 1.ª versión comparaba la piel medida en foto con la paleta de dibujo POR COLOR y la mandaba al medio (todos los países salían ~3,5: Inglaterra casi igual que Brasil) y además contaba «51 %→54 %» de piel; ahora se calibra por LUMINANCIA (`CaraPrior.tono_de_foto`, `FOTO_OSCURA`/`FOTO_CLARA`) y salen Alemania 1,8, España 2,0, Inglaterra 2,3, Brasil 2,5, Colombia 3,2. La piel ya no mejora frente al modelo público anterior (igual de acertada, ~44 %); lo que mejora es el pelo y la barba. La prueba compara Colombia con Alemania (contraste claro); Brasil e Inglaterra casi no se distinguen en lo medido (el techo de un modelo por país: sin foto no se sabe cómo es CADA jugador). Las FOTOS reales siguen solo en `caras_reales.pck`; `rasgos_pais.json` es público (agregado). Banco `_probar_cara_por_pais`. Pulir: afinar por edad y por posición, usar la región dentro de cada país (p. ej. Brasil, Colombia), añadir el corte de pelo medido en las mallas (rizo, largo) y ampliar las caras medidas con más fotos libres; un editor para fijar a mano la cara de las estrellas sin foto.
- UNIFORMES BASE Y SEGUNDO UNIFORME (10-11, encargo del dueño «uniformes y caras», parte 1; `herramientas/aspecto_clubes/_uniformes.txt` + `aspecto_clubes.py`): antes 255 de los 402 clubes con aspecto iban «liso» y solo se deducía un segundo uniforme (invertir colores o blanco) cuando chocaban. Ahora (a) retoques del uniforme base de las 10 ligas grandes (ESP, ENG, ITA, GER, FRA, ARG, BRA, MEX, USA, NED) y de Chile, Japón y Corea: colores, diseño (mangas de contraste, franjas, mitades…), pantalón y medias propios, rellenando los ~90 clubes que no traían colores (MEX, USA, CHI, JPN, KOR); (b) SEGUNDO UNIFORME por club (`visita`: c1, c2, camiseta, pantalón y medias): escrito a mano en los más conocidos y deducido por contraste (`visita_automatica`) en el resto (330 de 402 clubes tienen); el juego lo usa cuando el primero choca con el del rival (`AspectoClub.visita`, `DisenosKit.kit_de_club_visita`, `Puente3D.kit_visita`) y no pisa el uniforme que se haya diseñado el jugador. Los datos van a la tabla del pack real (con el nombre real) y a la base pública (con el nombre ficticio), regenerados con `base_ficticia.py`. Banco `_probar_uniformes_segundo` (8 países); hoja de revisión `pruebas/captura_uniformes.tscn` (PAISES=ESP,ENG,BRA,JPN,MEX,CHI: 2 clubes por país, 1.º y 2.º uniforme; revisada con 12 clubes de 6 países). Pulir: faltan colores reales de ~70 clubes menores (Arabia, Egipto, Marruecos, Sudáfrica, Oceanía, Chile-Segunda) que siguen con los colores base; el cuello solo cambia por hash; no hay tercer uniforme ni uniforme de portero propio por club; los diseños son parecidos al real, no copias, y los cambian cada año los clubes de verdad.
- FESTEJOS POR TIPO DE TÍTULO (10-11, sesión 3): `TipoTitulo` (liga, copa, continental, supercopa, ascenso, salvación) + `EventoCelebracion` a pantalla completa con `EscenaFestejo` 2D dibujada (solo formas, colores del club: barata en móvil): liga = levantar la copa en un escenario sobre el césped (+ «Ver la vuelta olímpica» 3D de siempre, ya no se lanza sola), copa/supercopa = palco y medallas, continental = escenario con confeti y fuegos, ascenso/salvación = abrazo sobrio en el círculo central (al cerrar la liga, antes de la despedida). Extras con botón: foto con el trofeo, mantear al DT, champán en el vestuario, desfile en autobús (2D, la ciudad 3D está apagada) y pasillo del rival (liga). Pruebas: `_probar_festejos_titulo` y `captura_festejos` (3 clubes de CHI, BRA y COL). Pulir: usar los modelos 3D y las animaciones «celebrar»/«aplaudir»/League-Soccer en las escenas (hoy figuras 2D), tifos en la grada de una final, festejos de grupo coreografiados.
- OBJETIVOS POR CLUB (10-11, encargo del dueño; `ObjetivosClub`, `ObjetivosCierre`, `Directiva.generar_objetivos`): cada club recibe su paquete: (1) OBJETIVO DE LIGA ajustado al tamaño de su liga, a sus descensos (`Liga.plazas_descenso`: «evitar el descenso» = el último puesto seguro real, ya no un 14 fijo) y a sus plazas continentales reales (`Continental.CUPOS_*`: ESP 4 de Champions, CHI 3 de Libertadores…; texto con la competición); la exigencia sube con el palmarés (`HistoriaClub`) y la masa social y baja con las deudas; (2) 3-6 SECUNDARIOS a la vez con su peso en la confianza (copa, copa continental si es de los de arriba, economía, y dos de cantera sub-21 / masa social / estilo goleador o sólido, elegidos por hash del club); (3) PROYECTO a 3 temporadas (sanear, subir, ganar la liga, volver a la copa continental, consolidarse, mejorar 3 puestos) que suma +20 o resta −12 al cerrar el tercer año. `ObjetivosCierre.cerrar` los juzga al cerrar la temporada (`mundo_p6`), mueve la confianza una vez y deja el paquete de la próxima (un proyecto a medias sigue). `Directiva.objetivo`/`meta_puesto` siguen siendo lo que leen `ObjetivoDirectiva`, `PanelObjetivos` y `ResumenTemporada` (que ahora lista ✔/✘ cada secundario y el proyecto; la fila del menú central lo muestra en su ayuda). Guardado: campos nuevos `objetivos`/`proyecto`/`bases` (una partida vieja sin ellos abre y estrena los de su club). Traducido a los 8 idiomas (patrones con el número). Calibrado el 10-11 con 3 ligas (CHI, ESP, BRA; un club de arriba, uno medio y uno de abajo, 2 temporadas): fallar resta un 25 % más que lo que suma cumplir, y la masa social pide +8 % (con +5 % casi todos lo cumplían). Progreso en vivo (`ObjetivosEnVivo`: barra por objetivo bajo el de liga en el menú central y líneas en el panel de objetivos). Banco `_probar_objetivos_por_club` (160 clubes de 9 países, tamaños 12/20/24, cierre, guardado nuevo y viejo). Pulir: la barra del menú central solo mide el objetivo de liga (falta una por secundario y un panel propio con el progreso en vivo durante la temporada); las ligas generadas hoy son de 16 clubes (el tamaño variable se probó con casos sintéticos); el objetivo de cantera usa «sub-21 en la plantilla», sin distinguir canteranos con minutos; el peso de cada tipo (4-8) y la exigencia por palmarés/masa social/caja son una primera calibración que el dueño puede retocar.
- «FOTOGRAMAS MALOS AL LÍMITE» (especial `auditoria_fps_malos_limite`, 10-11): CAUSA = la PRUEBA estaba desfasada, no el motor. `MotorJugable._physics_process` escala el tiempo por `RitmoJuego` (Normal 0,85 desde el 9-11) pero la referencia de 60 FPS usa `paso(1/60)` sin escalar; el controlador de la prueba para al llegar a T=20 s y con pasos de 0,0142 s se pasa hasta 20,003 s y el estado ya no coincide. Con el ritmo fijado a 1,0 en la prueba, 5 FPS y tirones dan el MISMO estado exacto que a 60 FPS (motor sin tocar, órdenes 23-24). Arreglada la prueba (`RitmoJuego._i = 2` durante B y se restaura). Idea para después (dueño): decidir si el reloj del partido debe medirse en tiempo de juego escalado o real.
- SUELO INTERIOR Y PUERTAS DEL ASCENSOR DEL CLUB (10-11, «solo club» paso 2): la losa de cada planta pasa de gris mate (0,5, parecido al asfalto) a un suelo claro y satinado (`EdificioClub`: color 0,74/0,72/0,68, rugosidad 0,5; sigue siendo UNA caja por planta, barata) con un camino oscuro del color del club en el pasillo. El ascensor (`PuertasAscensor`, hojas `HojaAscensor`) ya no es una plancha: marco oscuro, fondo de cabina iluminado y DOS HOJAS que se recogen a los lados al llegar (0,6 s), se quedan abiertas 3 s y se cierran solas; al salir de viaje se cierran las de la planta de origen (`AscensorViaje.viajar`, sin tocar la duración del viaje). Las hojas llevan script a propósito: `FundirPiezas.fundir_profundo` (calidad mínima) funde en una malla los nodos 3D simples sin script, y la hoja dejaba de moverse. Prueba `_probar_puertas_ascensor` (banco, grupo `varios`); captura con `captura_edificio_club.tscn` (SOLO=11, PUERTAS=1 las lleva abiertas). (12-11) CABINA CON FONDO: un plano con `cabina_ascensor.gdshader` («interior mapping», 2 triángulos, sin texturas) dibuja una cabina de 1,5 m con espejo, pasamanos, plafón y suelo con la franja del club, y cambia de perspectiva al moverse; INDICADOR de planta en ámbar sobre el dintel y TIMBRE al abrirse (sonido `notificacion`). Capturas Forward+ antes/después con ESP y ARG. Pulir: el suelo de las salas sigue siendo el de cada sala (`_suelo_de`); el timbre reutiliza un sonido del catálogo (no hay uno propio); el indicador no cambia mientras el ascensor viaja.
- FESTEJOS POR TIPO DE TÍTULO (10-11, sesión 3): `TipoTitulo` (liga, copa, continental, supercopa, ascenso, salvación) + `EventoCelebracion` a pantalla completa con `EscenaFestejo` 2D dibujada (solo formas, colores del club: barata en móvil): liga = levantar la copa en un escenario sobre el césped (+ «Ver la vuelta olímpica» 3D de siempre, ya no se lanza sola), copa/supercopa = palco y medallas, continental = escenario con confeti y fuegos, ascenso/salvación = abrazo sobrio en el círculo central (al cerrar la liga, antes de la despedida). Extras con botón: foto con el trofeo, mantear al DT, champán en el vestuario, desfile en autobús (2D, la ciudad 3D está apagada) y pasillo del rival (liga). Pruebas: `_probar_festejos_titulo` y `captura_festejos` (3 clubes de CHI, BRA y COL). 3D HECHO (10-11, `FestejoCampo3D`, hereda de `HomenajeCampo3D`): escenario, palco con medallas, fuegos, abrazo sobrio, manteo (el DT sube y baja tumbado) y foto con los MODELOS REALES y sus animaciones (celebrar, celebrar_ls, aplaudir, saltar, idle) y cámara en movimiento; champán, desfile y pasillo siguen en 2D; en calidad ULTRA BAJA (la de defecto) todo queda en 2D. Coste medido (llvmpipe, opengl3): +90-140 llamadas de dibujo sobre ~430 de la interfaz detrás. EXTRAS 3D HECHOS (10-11, `FestejoExtra3D`): champán en el vestuario (taquillas del club, chorros de espuma), desfile en autobús descapotable por una calle con edificios y público en MultiMesh (la cámara sigue al bus), pasillo del rival (dos filas aplaudiendo con sus colores, el campeón cruza caminando) y el DT con SU modelo (`PersonajeDT`) en el manteo; títulos de TU SELECCIÓN con su propio festejo (sus colores y jugadores, `CargoSeleccion.ultimo_titulo`). Medido: 396-616 llamadas (el pasillo, con 15 jugadores, es el más caro). TIFOS HECHOS (10-11): en las finales (copa, continental, supercopa, selección) dos lonas sobre la grada, el escudo y las franjas del club (+2-4 llamadas). Cielo del desfile ya no se quema (tarde azulada, sin brillo). Pasillo 616 → 446 llamadas sin quitar jugadores (focos sin sombras en esa escena). Pulir en la grada de una final, festejos de grupo coreografiados.
- RUEDA DE PRENSA EN CRUZ Y EVENTOS CON DIÁLOGO (10-11, sesión 3, rama `sesion3-rueda-prensa`; referencia: las escenas de la «liga máster» de un juego de fútbol que el dueño cita, con textos y arte PROPIOS): las respuestas ya no son una lista: `SelectorDireccional` las pone en CRUZ (arriba/derecha/abajo/izquierda; «🙋 Ayudante» al centro), el analógico o la cruceta apuntan (un rayo marca la elegida), R2/A/Enter confirma, clic o toque directo, y al elegir hay una mini animación (late y se ilumina; las demás se apagan). Paleta azul noche + acento del club (si el color del club es ilegible, azul). Se conservan todas las preguntas, posturas, texto libre y reloj. EVENTOS NUEVOS (`EventosClub` + `EventoDialogo` + `JornadaEventos`, solo en su fecha y una vez, guardados en `Prensa.eventos_vistos`): reunión con la directiva (semanas 1-2), charla del capitán la semana de un clásico, balance de mitad de liga con el ayudante; cada respuesta mueve moral del plantel y confianza de la directiva. Pruebas: `_probar_selector_direccional`, `_probar_eventos_club` (banco) y `captura_rueda_eventos` (especiales.sh). Pulir: más escenas (fichaje estrella, crisis, renovación, despedida de un ídolo), elegir con efectos que dependan de la personalidad del DT, la captura Forward+ (lavapipe no terminó en 15 min aquí), y el trato del analógico en la columna de posturas.
- PROFUNDIDAD EN LOS MENÚS (10-11, `ProfundidadUI`): CABECERA de cada menú en una banda con sombra y filo del color del menú, título con sombra difusa; TARJETAS de portada con brillo arriba, filo de luz y sombra larga que crece al pasar por encima; BOTONES del tema (Ajustes incluido) y de la cabecera con relieve: sombra en reposo, más al pasar y HUNDIDOS al pulsar. Capturas Forward+ con `herramientas/captura_menus.sh`. Pulir: el seleccionado de Ajustes en el color de acento (hoy gris en esa paleta), sombras de las tarjetas recortadas por el desplazamiento.
- Casa del personaje a pie sin ciudad (`CasaAcceso` → `CasaRecorrido`, `CasaPlano`, `CasaConstruccion`; prueba `prueba_casa_a_pie` en `especiales.sh`): casa básica de 6 habitaciones, sin entrar a la ciudad. Pulir: más muebles/decoración, interacciones (cama, tele, ordenador), variedad de casas según nivel de vida, cámara en habitaciones pequeñas y la terraza/jardín.
- MAPA DE CALOR Y HABILIDADES CON ESTRELLAS (10-11) en la plantilla a la PES: el radar con el MAPA DE CALOR al lado (`MapaCalorJugador`: campo vertical, zona principal intensa y secundarias suaves, radio según ritmo y físico) y, bajo el estilo de juego, hasta 6 HABILIDADES con ★★★ (`HabilidadesJugador`: 21 habilidades propias —regate en profundidad, pase al hueco, centro preciso, disparo lejano, marcaje, reflejos felinos, liderazgo…—, deterministas desde atributos, puesto, rasgo y capitanía; sin guardar nada). Banco `_probar_habilidades_y_calor`. Pulir: mapa de calor REAL con las posiciones del motor en los partidos jugados (hoy es la lectura de la ficha), que las habilidades influyan en el motor del partido (lo lleva el dueño/PES 6), iconos por habilidad.
- HOMENAJE EN 3D EN EL CAMPO (10-11): la ceremonia del partido de despedida proyecta `HomenajeCampo3D` (césped de noche, focos, grada llena con los colores del club en un MultiMesh, los homenajeados —modelo que juega— celebrando junto a su camiseta retirada enmarcada, papelitos dorados, cámara que gira). Prueba especial `prueba_homenaje3d`. Pulir: la grada real del estadio del club en vez de la genérica, pasillo de honor de los compañeros, sonido de ovación.
- FINAL DE TEMPORADA (10-11): pantalla ÚNICA de resumen a pantalla completa (`ResumenTemporada`, hereda de `EventoPantallaCompleta`: tu puesto y el campeón de liga, copa, continental, ascensos/descensos de tu país, gala de premios y veredicto de la directiva; luego el documental). Copa y continental a medias se juegan hasta el final y se ANUNCIAN al terminar la liga, antes de la despedida (`CierreTorneos`, también dentro de `Mundo.nueva_temporada`). Orden: fin de liga → torneos pendientes → despedida → «Temporada siguiente» (gala dentro del cierre) → resumen → nueva temporada. Pruebas: banco `_probar_final_temporada` y especial `prueba_resumen_temporada`. (12-11) ENTRADA POR TARJETAS hecha (`EventoPantallaCompleta.entrada_en_cascada`, reutilizable por las demás pantallas de evento; respeta «Animaciones reducidas»; la especial `prueba_resumen_temporada` comprueba que las 7 piezas acaban a la vista). BOTÓN FIJO ABAJO (12-11, `EventoPantallaCompleta.fijar_abajo`): «Empezar la temporada» ya no queda bajo el pliegue cuando el veredicto trae objetivos secundarios; el contenido se desliza por encima. EN VERTICAL (12-11): el resumen iba a dos columnas de 360 px y en el teléfono de pie la mitad derecha quedaba FUERA de la pantalla; ahora de pie va en una columna (cabecera, tarjetas y veredicto apilados). La especial `prueba_resumen_temporada` acepta `PAIS`, `CLUB` y `MOVIL=1` (revisado con ESP, GER, ARG e ITA). EVENTOS CON DIÁLOGO EN VERTICAL (12-11): confirmado y arreglado: la reunión con la directiva del primer día (lo primero que ve quien empieza con el teléfono de pie) tenía el texto y las respuestas cortados por la derecha. `EventoPantallaCompleta.ancho_base` da 500 px de pie a todos los eventos, y `EventoDialogo` pone el retrato arriba y el diálogo debajo (fotos con `EVENTOS=1 MOVIL=1 RESOLUCION=608x1080 SOLO_MENU=reglas SOLO_TAB=nada herramientas/captura_menus.sh`; clubes de COL y SUI). Vistos en vertical (12-11, `MOVIL=1` en `captura_rueda_eventos`, clubes de CHI y ARG): la charla del capitán y el balance de mitad de liga caben bien; la rueda de prensa también, y de paso «Ayudante» ya no se parte en dos líneas en el redondel del centro (ni en PC ni de pie). Pulir en la rueda: el rótulo «RUEDA DE PRENSA» de arriba queda tapado por los escudos del fondo y en PC el panel de respuestas tapa la cara del segundo personaje. FESTEJOS EN VERTICAL (12-11, `MOVIL=1` en `captura_festejos`; CHI, BRA y COL): confirmado y arreglado: el título, la escena y el botón «Continuar» quedaban fuera de la pantalla (la escena 2D pedía 760 px y la 3D 900); de pie todo va a 500 px, los botones de escena en varias filas y «Ver la vuelta olímpica» / «Continuar» uno bajo otro. En PC sin cambios (su captura da 0 fallos). DESPEDIDA EN VERTICAL (12-11, `MOVIL=1 CAPTURAR=…` en `prueba_despedida_ui`): la pregunta («Jugarlo / Simularlo / Ahora no») y la ceremonia del homenaje se salían por la derecha; de pie van a 500 px (escudo arriba y cancha debajo, botones apilados; campo 3D al ancho y tarjetas de 2 en 2). En PC sin cambios. FALLO ARREGLADO (12-11): el equipo de las Leyendas se armaba con el mejor portero y los 17 mejores POR NOTA sin mirar el puesto, y salía a jugar con 5 delanteros y UN defensa; ahora `PartidoDespedida.equipo_de` asegura primero 4 defensas, 3 medios y 2 delanteros (si hay retirados de ese puesto) y completa por nota; banco `_probar_partido_despedida` (también con delanteros de mucha más nota). De pie, «Jugarlo» va a lo ancho y «Simularlo» / «Ahora no» debajo, lado a lado: ya no queda nada bajo el pliegue. Pulir: varios retirados salen con silueta en vez de retrato. CALENDARIO DE SEMANAS EN VERTICAL (12-11, `ABRIR=calendario,palmares MOVIL=1 …` en `captura_menus.sh`; URU y JPN): las seis semanas iban en columnas de 150 px y se salían; de pie van una debajo de otra, a lo ancho. El palmarés del mundo cabe de pie en su estado vacío (sin ver con campeones). VISTO EN EL CALENDARIO, sin tocar: la copa y la continental salen el MISMO sábado que el partido de liga (dos partidos el mismo día en la semana 3 y la 4); decidir si se muestran entre semana. SELECCIÓN EN VERTICAL (12-11, `MOVIL=1 OUT=… SEL=…` en `captura_cargo_seleccion`; Argentina, Brasil y Francia): la oferta del cargo y el partido caben (botones apilados, escudos más chicos); la CONVOCATORIA se salía (dos columnas de 370 px) y de pie va en una columna. En PC sin cambios. CASILLAS (12-11): en la convocatoria la casilla sin marcar casi no se veía sobre el azul noche; `CasillaClara.estilar(cb)` le pone iconos propios (marco claro / cuadro dorado con palomita), prueba `_probar_casilla_clara`. Reutilizable en cualquier otra lista con casillas sobre fondo oscuro. `SEL=Japón` no sirve en esa captura («no está en el Mundial» 2026 del juego). Con esto TODAS las pantallas de evento están revisadas de pie salvo el palmarés del mundo con datos. TELÉFONO TUMBADO (12-11, `MOVIL=1` a 1920×1080: zoom 1,5, cabecera compacta; clubes de CHI y ENG): Finanzas (cuentas, taquilla) y Táctica (órdenes, once) se ven bien, sin desbordes; el paginador sale compacto (flechas y «3 / 13»). El menú central de pie también está bien; ahí el nombre de tu club en la tabla sale en el color del club y con azules oscuros se lee poco. MÉTODO (hecho el 12-11): las pruebas del banco de esta rama viven en su grupo propio, `pruebas/banco/menus.gd` (`herramientas/mini_banco.sh menus`, 30 comprobaciones), para no chocar con `varios_p13.gd` en cada fusión con `main`. `pruebas/banco.gd` está en 450 líneas justas: el próximo grupo o sección obliga a partirlo. DUDA sin mirar: con ARG el campeón salió con 24 puntos en una liga de 30 (¿formato por zonas o la prueba cierra la temporada antes de tiempo?). Pulir: sonido de gala, trofeo 3D del campeón; torneos de selecciones según la decisión del dueño.
- Plantilla a la PES (`PlantillaPes`, `PlantillaEstilos`, `GestionOnce`) y fila «PRÓXIMOS» (`FilaProximos`): aspecto (la lleva la sesión de estética).
- Avance de fecha con eventos (`EventosFecha`: liga, copa, continental, mercado, fin de temporada; `TarjetaEvento`, `CalendarioSemanas` de 6 semanas con botón 📅, «Hito» que para en cada evento): pulir aspecto (tarjetas de rondas futuras «probables», más detalle por día, mando) y comparar con el calendario del PES.
- Camisetas retiradas (Historia del club y museo del estadio, `CamisetasRetiradas`, `CamisetasMuseo`): más variedad de camiseta y foco en el museo. REVISADO en el edificio real (10-11, `RETIRADAS=1 SOLO=9 captura_edificio_club.tscn`): en el museo (planta 2) se ven las camisetas enmarcadas en la pared del fondo; (12-11) REHECHAS: cuadros un 45 % más altos, camiseta con forma (mangas caídas, cuello y bajo en el segundo color del club), paño iluminado, placa dorada con apellido y año y lámpara de cuadro encendida. Pulir: escudo en el pecho y diseño real del uniforme (franjas) en la camiseta. La captura del edificio ya fija la planta sin esperar al viaje del ascensor.
- Capítulos de cada temporada (`CapitulosTemporadas`): comparar ritmo y planos con el PES.
- Ascensor con viaje gradual (`AscensorViaje`) y puertas con marco (`PuertasClub`). HECHO el 10-11: la hoja de cada puerta se ABRE al acercarse y se cierra al alejarse (`PuertaAnimada`, banco `_probar_puerta_animada`); el VESTUARIO VISITANTE amueblado (`SalasClub.vestuario_visitante`); revisadas con captura las 12 salas: todas con muebles; las colisiones persona-objeto ya existían (`ColisionClub`). Pulir: animación de las puertas del ascensor, suelo liso en todas las plantas, el encuadre de la captura del pasillo.
- Partido de despedida (`PartidoDespedida`, `JornadaDespedida`): ceremonia con más fuerza, camiseta retirada visible en el estadio.
- «Temporada siguiente» solo al terminar la liga (`AvanceSemana.rellenar_calendario`).

## DECISIONES DEL DUEÑO (6-11 noche) — se borran al completarse del todo
- **Alcance a pie ULTRA BAJA 180 m** (BAJA 300 m): APROBADO. Lo lejano se disuelve en niebla; probar en su teléfono antes de darlo por bueno.
- **Pasto a 28 m** en calidades bajas: APROBADO.
- **Precalentado de personajes y animaciones del menú apagado** en ULTRA BAJA y BAJA: APROBADO (abrir el estadio tarda ~1,4 s más; MEDIA o más no cambia).
- **Peatones con una malla**: NO por ahora (no hace falta para la meta a pie). Pendiente de su decisión si se quiere margen extra.
- **Mapa aéreo de «Ver mi ciudad»**: APROBADO QUITARLO COMO CASO DEL JUGADOR. Queda como RECURSO DE PROGRAMACIÓN (la clase `VistaCiudad` y sus pruebas se conservan). Ahorro de RAM ≈ 0 (medido: mismo mundo a pie y en aérea); el beneficio es quitar ~1.030 llamadas de la vista aérea. Riesgo alto: obras, reloj y clima, prólogo. Orden: 1) mover la construcción de obras a la gestión o a pie; 2) entrar a pie sin pasar por el mapa; 3) quitar la entrada del menú; 4) comprobar prólogo, reloj, clima y bancos con capturas. Hacerlo con cuidado y paso a paso.
- **Carga por trozos (decisión del dueño, 6-11 noche, tarde)**: aprobado repartir cada carga en más de 100 partes, cada una corta (con `await` de fotograma), si hace falta para bajar de 200 ms por carga. Cargas de referencia de hoy (ULTRA BAJA, simulado): abrir el estadio 7 s, menú 4,45 s, abrir la ciudad 15 s. Orden: menú (compilar scripts y generar mundo) → ciudad → estadio; cada paso con capturas o banco en FIN. 0 fallos. Coordinar con la sesión de la ciudad antes de cambiar el orden de construcción.
- **Cristales azulados de los edificios singulares**: lo MENOS importante; se hacen cuando no haya nada más urgente.
- **Tiempo de carga «menos de 200 ms» = CADA carga** (decisión del dueño, 6-11 noche). Hoy la ciudad tarda ~8-10 s en construirse en simulación: meta muy lejana; hay que cargar por partes con la pantalla viva.
- **RAM = la del MOTOR** (estática + texturas + vídeo; decisión del dueño, 6-11 noche). Menú ~436 MB, partido ~941 MB, ciudad ~1.420 MB en ULTRA BAJA: meta < 1,5 GB CUMPLIDA. La medida en el teléfono se hace después (prueba de rendimiento de Ajustes).
- **Medición en teléfono del dueño**: PARA DESPUÉS (decisión del dueño, 6-11 noche). Hasta entonces, los FPS y ms son solo estimación.

## OBJETIVOS DEL DUEÑO DE RENDIMIENTO (6-11, orden 33) — META FINAL, TODO EL JUEGO
- **Pico de RAM menor de 1,5 GB** (DDR3, equipo modesto; hoy el partido llega a 2,4-3,1 GB en MEDIO y ciudad 4,4-5 GB).
- **Menos de 120 llamadas de dibujo en ULTRA BAJA** (hoy la ciudad en ULTRA BAJA ronda 471 según la sesión Tracy; sin cifra tras #203-#205).
- **Menos de 200 ms** (tiempo por fotograma o de carga; se confirma con el dueño cuál de los dos).
- Sin cambiar más lo visual. Todo el juego (menú, ciudad, estadio, museo, gestión, partido, minijuegos) debe llegar a esas metas.
- Medir con `herramientas/hw_modesto.sh` (RAM en cgroup, llamadas y triángulos; nunca el tiempo de fotograma `--headless`).
- Fusión a `main`: autorizada por el dueño (6-11) para las ramas de rendimiento listas, en cargas grandes (un lote por vez, con el banco en FIN. 0 fallos).

## ESTADO AL CIERRE DEL 4-11 TARDE (orden 32 del dueño) — para retomar
- Caza de fallos (orden 31) CERRADA por el dueño. Mega auditoría 4 hecha (5 repasos) y sus hallazgos en `docs/04_auditorias/MEGA_AUDITORIA_4/`
  (gestión, partido, interfaz, mundo 3D, móvil, rendimiento). Todo en `main` por los PR #169, #181 y #182.
- Las 4 sesiones (PES 6, ejecutora, ciudad, «Búsqueda de fallos») ARCHIVADAS; revisiones automáticas del líder APAGADAS.
- Decisiones del dueño aplicadas: bonos del humano también al simular (sin cambio), más butacas solo en ALTA, MSAA fuera en MÍNIMA,
  partido simulado recalibrado (≈24 remates, 8,3 a puerta, 11,7 % de conversión, ≈2,7 goles; goleadas entre divisiones saturadas),
  comercios de 8:00 a 20:00, entorno del estadio tapado también en MEDIA y el agregado «Partido ligero» en Ajustes (apagado por defecto).
- Lo que espera al DUEÑO (lo más importante): probar en su teléfono el APK de `main` (Actions → «Compilar y probar Dinastia» → android) y
  pasar el informe de Ajustes → «Prueba de rendimiento»; con eso se ataca la GPU del partido en el aparato real. Luego, jugar y decir
  qué se siente mal del partido (orden 23).
- Recomendación del líder (4-11, a petición del dueño): menos sesiones en paralelo (2 enfocadas), caza de fallos en segundo plano.
- Pendientes anotados: cartel/puerta 3D de «cerrado» en los comercios (hoy solo aviso en pantalla); POR_TICK de los carteles 3D perezosos;
  ~670 MB antes de la ciudad (cargar principal.tscn +195 MB, mundo+interfaz +168 MB); muesca/área segura y tiempos en el teléfono real.

- Otros pendientes del DUEÑO (siguen): nota 1-100 a las pasadas visuales de la ciudad 1-3 (`04_auditorias/pasada_ciudad_{1,2,3}_2026-11-04.md`);
  matas de hierba del Drive en el césped de las casas (¿más juntas o así?); publicar parches (Release `parche-<versión>-<escritorio|android>`
  con el `parche_<versión>.pck` de «Actualizar Dinastia (parche)»). Fallos abiertos que esperan decisión: `MEGA_AUDITORIA_4/reglas_y_codigo.md`
  (A4-REGLAS-001 y 005).
- (2-11) SIGUIENTE PASO DE CARGA (meta del dueño: ≤5 s en móvil): hecha la carga diferida (hasta ver la ciudad 7,2→3,5 s; ciudad entera 5,7→1,5 s en servidor). Falta: STREAMING POR CERCANÍA en móvil (idea del dueño: no construir los bloques lejanos hasta acercarse; PRIMEROS menor y límite de vista), diferir túnel/sombra del estadio (~1,3 s) y que el .so de Android llegue a `bin_nativo/` (dueño/CI, M-353).

## CIERRE DEL 2-11 (revisiones que faltan y ramas viejas)

**Hiper auditoría del 2-11**: `docs/04_auditorias/HIPER_AUDITORIA_2026-11-02.md` (errores H-01 a H-11, optimización, efectos, jugabilidad y físicas, con prioridad P0-P2). Primero: H-01 interpolación de física (el partido corre a 60 Hz sin interpolar, a 120 FPS da tirones) y H-02 la prueba inestable «estadio y ciudad por partes».

**Estado**: todo el trabajo de las sesiones del 2-11 está en `main` (PR #93-#100, #105, #106; CI verde: banco y los 6 tramos de especiales). Las ramas de las sesiones no tienen nada por delante. Registros: `docs/04_auditorias/rendimiento_120fps.md`, `fallos_crear_partida_2026-11-02.md`, `CLAUDE.md` (órdenes 19-21).

**Revisiones que faltan (solo las puede cerrar el dueño o un equipo con GPU)**
- Probar el PRÓLOGO en el PC de Windows: pantalla gris/congelamiento/cierre al moverse. Causa corregida (la ciudad entera se armaba en un solo fotograma: ahora por etapas y recortada al barrio, 15,9 a 6,4 s, 4.316 a 2.627 llamadas), pero el cierre en Windows NO se pudo reproducir sin GPU.
- Confirmar a ojo el ARBUSTO del personaje de bienvenida (resuelto por geometría con prueba, sin captura).
- Ejecutar el BENCHMARK (Ajustes o `--benchmark`) en el Vivo Y36 5G y en una laptop modesta: no hay ninguna cifra de FPS real. Los 120 FPS en equipos modestos NO están verificados.
- Elegir/revisar los modelos base: 37 ya integrados; faltan MakeHuman (hay que generar los .glb) y Vitruvian (2,2 GB de Blender). Kenney descartado.
- Capturas Forward+ con la cámara real (por software se cuelga con el partido) y nota del vídeo del partido (el 1080p se hace con `herramientas/grabar_partido_hd.sh` en un PC con GPU).

**Revisiones técnicas pendientes**: estadio ligero en el prólogo y carga diferida de lo no visible; `probar_por_partes`: «cede fotogramas (0)» falla siempre en local (estadio/ciudad por partes no ceden cuadros aunque `por_partes` esté puesto); tick escalonado de peatones/coches y público lejano en MultiMesh (necesitan hardware real para medirse); el tiempo de fotograma `--headless` tiene un suelo de 6,9 ms (las cifras de CPU de ciudad −19 % no valen); calidad ALTO supera 4 GB de RAM; `CLAUDE.md` tiene dos órdenes numeradas «19.» (120 FPS y TERCEROS): renumerar con cuidado, otros documentos citan 19/20/21; el PR #99 se fusionó con el CI a medias (después salió verde).

**Ramas viejas** (detalle y listas en `docs/04_auditorias/ramas_viejas_2026-11-02.md`): de 100 ramas remotas, 24 ya están en `main` (nada que unir, borrables) y 76 NO comparten historia con `main` porque `main` se reescribió el 24-10 y el 27-10: por eso no se unen (un merge traería de vuelta la historia vieja, ~4.000 archivos de diferencia); su trabajo útil ya se integró a mano y lo que falte se rescata por cherry-pick de un commit. Pendiente del dueño: borrar la lista A, decidir la lista B, cerrar los PR #83-#85 (`rend2` y `rend4` ya están en `main`) y borrar la etiqueta `latest`. Nada se borró.

**Pendiente para limpiar el repositorio (decisión del dueño, 2-11: «por ahora déjalo»)**: volver a revisar las ramas viejas y, cuando se decida, borrar por grupos. Ya hecha la comparación archivo por archivo contra `main` (sección final de `ramas_viejas_2026-11-02.md`): conservar `ccr-a64d04fd-r5uoai`, `respaldo-historia-2026-10-24` y `ccr-76d707c5-dwse9h` (tienen archivos que `main` no tiene); rescatar si se quiere los 9 `pelo_*.res`; el resto es borrable con orden explícita. Hasta entonces no se toca ninguna rama.

## ESTADO AL CIERRE DEL 28-10 (para retomar el lunes)

- **2-11 (lunes), reanudado**: versión **0.9.1** con Novedades; auditoría de código aplicada (guardado, deshacer, determinismo, 13 sitios por fotograma, texturas del estadio, materiales de coches, ciudad con menos nodos); cierres de las dos sesiones unidos; ejecutora y sesión 3 con su cola del lunes (mensajes del líder del 2-11). Lo que falta del guion: §2.5.

- **Rama**: todo unido en `claude/dazzling-rubin-v7rfyi` (líder). Banco «FIN. 0 fallos», especiales «todo en orden», prueba visual en 0 fallos (referencias al día), ningún script de más de 450 líneas. Registro detallado del 27-28-10: `docs/04_auditorias/CIERRE_2026-10-28.md`.
- **Sesiones**: la ejecutora cierra con un PR final y su resumen en `docs/04_auditorias/rendimiento.md` («ESTADO AL CIERRE 28-10»); la sesión 3 con `docs/04_auditorias/sesion_3_cierre_28-10.md`. El líder une ambos antes de parar.
- **Sesión del 2-11 (rama `ccr-2625acd2-02al7q`, todo en `main` por los PR #93 y #94)**: M-476 (metro, asientos, coches, rótulos y pasajeros del autobús: nodos de la ciudad 39.463 → 35.435), M-404 (9 de 194 módulos de `visor/` sin referencia en pruebas), M-095, M-207 (cerrada), M-058, M-235, M-447 (4 textos). Falta de todo ello la captura con la cámara real (sin GPU en el contenedor). Los fallos de «crear personaje / crear partida» los lleva otra sesión.
- **Para el lunes, primero**: unir lo último de las dos sesiones si quedó algo; repasar las correcciones de ciudad que pidió el líder (bus, paraderos de noche, semáforo peatonal, teleférico, lavado, lluvia); seguir con §2.2e (pasadas visuales) y las filas P1 de esta lista.
- **Del dueño**: §0 y §1 (FPS en hardware real, builds, keystore, publicar la política de privacidad, red a Wikimedia).
- **Auditoría de código del 28-10**: lo arreglado y lo pendiente (materiales sin compartir, vías sin conectar, probables del guardado, `MotorLibre`) está en `CIERRE_2026-10-28.md` §«Auditoría»; las órdenes sin completar y los fallos abiertos, en sus dos secciones siguientes.

## ESTADO 120 FPS (2-11-2026) — detalle en `04_auditorias/rendimiento_120fps.md`
- **Hecho y en `main`**: butacas cercanas livianas desde el inicio en MEDIO (partido −34 % de triángulos, 1,34 M → 0,88 M; RAM 3,1 → 2,4 GB); escalón 6 de calidad adaptativa «sin sombra del sol»; perfil ligero automático por hardware (`CalidadAuto`: Intel HD/UHD, ≤4,5 GB, ≤2 hilos, móvil); benchmark (`--medir`, `--benchmark`, botón en Ajustes); `hw_modesto.sh`, `presupuesto.sh` (en `especiales.sh todo`), `medir_entorno_nodos`, `medir_cpu_partido`.
- **Pendiente**: FPS reales y benchmark en Android/hardware real (dueño); ciudad ~4,4-5 GB de RAM y 9,7 s de carga (sesión del prólogo, rama `ccr-1749cbc2-dmhp94-prologo`); CPU del partido por clase con tiempo de CPU del proceso en máquina sin otras cargas; EntornoEstadio (333 llamadas) con fusión de mallas; rótulos de vallas en un atlas; tick 10-20 Hz con interpolación de peatones/coches; público lejano en MultiMesh; BC7 de caras (decisión del dueño, §4).
- **Aviso**: el tiempo de fotograma `--headless` tiene un suelo de 6,9 ms: no sirve para medir CPU; usar triángulos/llamadas/memoria o CPU del proceso.
## ESTADO AL 02-11 (fases 1-9 hechas)
- ABIERTO en `main` (no es de estas fases; falla también en `origin/main` solo): `probar_rendimiento_adaptativo` («no hay sexto escalón, y avisó de los cinco»). `prueba_menu_ciudad_pie` falló una vez con la máquina cargada y pasa sola.
- Las 9 fases de la orden 20 están hechas: registro en `docs/04_auditorias/CIERRE_FASES_2026-11-02.md`. Para el dueño:
  encender o no `PMOT_PASE` (R2), calibrar los goles (≈2,3 por partido) y su nota 1-100 sobre el vídeo del partido completo
  (orden 21; enviado el 02-11, 9 min 23 s, grabado con `pruebas/video_partido.tscn`, CEREMONIA=1 RITMO=rapido, 20 fps).

## ORDEN DE TRABAJO DEL DUEÑO (01-11)
1) fallos (los 8 de League-Soccer) → 2) clubes (recreación legal) → 3) IA → 4) jugabilidad → 5) optimización → 6) detectar fallos →
7) sonidos de sistema → 8) minijuegos → 9) entrenamiento.

## CALIDAD CONTINUA CON SONAR Y TRACY (orden del dueño, 5-11) — se borra solo si el dueño lo da por cerrado
- (12-11, sesión de pulido) Informe del día: 1 aviso abierto en `main` (`pythonsecurity:S7044`, `herramientas/bajar_cc0_modelos.py`: la ruta de la dirección de descarga viene de la respuesta de la API). ARREGLADO en la rama `ccr-8279c839-7t0p6w` (`direccion_limpia`: servidor de nuestra lista, sin «..», sin %2e, sin usuario ni puerto raro; probado con 7 direcciones malas y una descarga real). Sonar solo analiza `main` y los PR: se confirmará cuando esa rama se una.
- **Ciclo repetible, varias veces**: bajar el informe (`herramientas/sonar_informe.py`) → corregir por bloques de mayor a menor severidad → banco + especiales + CI en verde → PR → que SonarCloud lo analice → repetir hasta que Sonar diga «perfecto o casi perfecto». Meta: las notas MÁS ALTAS posibles (Seguridad, Fiabilidad y Mantenibilidad en A; 0 hotspots sin revisar; duplicación mínima) y quitar incoherencias y desorden que cuestan rendimiento.
- **Perfilar con Tracy Profiler** como práctica general (no solo con triángulos/llamadas/memoria de `hw_modesto.sh`): medir con Tracy los puntos calientes del partido, la ciudad y el menú, comparar antes/después y guardar la traza resumida en `docs/04_auditorias/`. Pendiente de estudiar: cómo integrar Tracy en Godot 4.7 (compilación del motor o extensión) y en qué sistemas es viable (Windows/Linux sí; Web/Android a revisar). Regla vigente: el tiempo de fotograma NUNCA se mide con `--headless`.
- **Estado (5-11)**: `main` pasó de 492 a 4 issues de Sonar y la puerta de calidad está en OK. **Pendiente del dueño**: aceptar en la web de SonarCloud los 4 `python:S2245` (azar no criptográfico) de `herramientas/biblioteca_caras.py` y `caras_variadas.py` (Issues → Accept). Detalle y cómo repetir: `docs/04_auditorias/sonar_2026-11-05.md`.
- **Estado de la pista A al 6-11 (rendimiento), detalle y cifras en `docs/04_auditorias/rendimiento_antes_despues_2026-11-06.md`:** HECHO: 7 niveles de calidad con migración y defecto ULTRA BAJA en todos los sistemas (prueba `ren_calidad_7_niveles`); oclusión del entorno corregida (partido ULTRA BAJA 338 → 279, MEDIA 709 → 423 llamadas de dibujo); ULTRA BAJA y BAJA sin suplentes/cuerpo técnico/camarógrafos y con la grada en 3 trozos (→ 236); cantos de pasillo 1:1 con los peldaños (pgra_grada). PENDIENTE (en este orden): ciudad en ULTRA BAJA (a pie 706, aérea 2765 llamadas: la pieza que impide la meta < 130); LISTA PRIORIZADA con qué objeto pesa más en `rendimiento_antes_despues_2026-11-06.md` (edificios sueltos building-a/b/d, Estación Central y Metro por fusión y distancia, MultiMesh en menos trozos, Rótulos 3D por distancia); además nivel de detalle de ciudadanos y oclusión en el mapa aéreo; fusionar mallas de los 22 jugadores; recorte de memoria del menú; Tracy en ejecución con el visor (PR #193); búsqueda web de consejos de Godot con fuentes; la calidad adaptativa dentro del partido sigue por escalones, no por niveles.
- Las ideas nuevas siguen en pausa (orden 26); esto es calidad de lo que ya existe.

## PLAN GIGANTE DE PULIDO (orden del dueño, 6-11): solo mejorar y pulir lo existente, ≈ 8 h por pista y 24/7
Detalle en `docs/04_auditorias/PLAN_8H_PULIDO_2026-11-06.md` (pistas A rendimiento, B bancos, C plataformas, D líder). Sin contenido nuevo. Las sesiones sin trabajo se archivan. Se borra de aquí cuando se complete.

## TAREAS NUEVAS DEL DUEÑO (6-11) — se borran al completarse del todo
- **META de rendimiento**: ULTRA BAJA con **menos de 130 llamadas de dibujo (draw calls) en promedio** (el dueño dijo 130 y luego «150»: se mantiene 130 como exigente; si confirma 150, solo cambia la cifra) (recorrido de `hw_modesto.sh`: ciudad + partido) sin gran impacto visual. Sesión de rendimiento; presupuesto en el banco extra.
- **Calidad por defecto = la más baja (hoy «MÍNIMO», que pasa a llamarse ULTRA BAJA en los 7 niveles) en TODOS los sistemas operativos** (Windows, Linux, macOS, Android, iOS, Web), no solo en Android. El código ya parte de MÍNIMO (`Calidad.elegida`), pero falta una prueba por plataforma (`OS.has_feature`) que lo fije y comprobar que ninguna ruta (archivo de ajustes ausente/viejo, restablecer, migración) lo sube. Sesión de rendimiento.
- **Velocidad de carga (idea del dueño 6-11)**: quitado el personaje 3D que giraba en el diseñador de equipación (se montaba un SubViewport 3D con el jugador entero al abrir «Configura tu club»); queda solo la camiseta 2D de frente y de espalda. Falta MEDIR el efecto (nodos/memoria al abrir el paso 3 con `mem_menu_estadio`) y buscar otros 3D en menús/pasos de configuración (Identidad, Mascota, Estadio, Tu casa) que se puedan sustituir por imágenes.
- **Carga del menú (evaluado 6-11)**: la precarga en segundo plano YA EXISTE (`CompilarFondo`: scripts compilados en un hilo; `inicio_p1.gd`: `inicio_pesado.gd` en un hilo; `Precarga`: personaje, animaciones y edificios de ciudad/estadio) y los recortes de memoria del menú están hechos (`docs/04_auditorias/compilacion_menu_2026-11-03.md`). Lo que falta es MEDIR en el teléfono del dueño el tiempo hasta el primer menú con la versión actual y, si pesa, cortar las «pantallas de gestión» (−38 MB) y la ciudad (−105 MB) del informe.
- **Personal del club quieto + ciudadanos simples (idea del dueño 6-11)**: HECHO en ULTRA BAJA y BAJA: el personal (`PersonalEstadio`) se queda en su puesto, solo con sus gestos, sin pasear (prueba en `estadio_p1.gd`); la conversación ya era un panel 2D. Falta: pose fija sin animación de esqueleto, ciudadanos con nivel de detalle por distancia y tope por calidad, y multitudes de eventos en `MultiMesh` (medir antes el coste por personaje).
- **META DE RAM del dueño (7-11): −40 % de RAM en promedio con código puro, también en ALTA, sin usar recortes de la ciudad.** Herramienta: `pruebas/medir_ram.tscn` (`ESCENARIO=menu|ciudad|partido`, `-- minimo|alto`; imprime RAM del proceso, estática, texturas, vídeo). Línea base (6-11, ULTRA BAJA, estática+texturas+vídeo): menú 692 MB, partido 970, ciudad 1.643; ALTA: partido 1.170, ciudad 1.876. HECHO (rama `pulido/ram`, PR #207): (1) el menú ya no compila el estadio (`Banca`, −128 MB), (2) caras reales en bytes (−30 MB), (3) `trocear` junta los trozos de <40 instancias (20.040 → 3.771 nodos, −220 MB en la ciudad). Resultado ULTRA BAJA: menú 544 (−21 %), partido 941 (−3 %), ciudad 1.438 (−12 %). PENDIENTE para llegar al −40 %: PrecalentarCaras/Anim en el menú (~83 MB, decisión del dueño: velocidad de abrir el estadio frente a RAM), nodos sueltos de la ciudad (9.9 k MeshInstance3D ≈ 46 MB y 9.8 k MultiMeshInstance3D ≈ 56 MB; coste medido por nodo: 4,7 y 5,7 KB), caché de datos de la partida (`Mundo.generar` +79 MB), compilación de scripts (~157 MB del menú, ~128 del estadio). PRECALENTADO DEL MENÚ (autorizado por la líder de rendimiento solo en ULTRA BAJA y BAJA, 7-11): apagado (`PrecalentarAnim.permitido()`); medido con `pruebas/medir_apertura.tscn` (ULTRA BAJA, por software): con precalentado, abrir el estadio 5,5 s, 60 fotogramas siguientes 20,0 s, peor fotograma 3,2 s, RAM estática antes de abrir 419 MB (después 799); sin él, 6,8 s, 19,2 s, 2,8 s, 215 MB (después 727): el tirón al abrir sube ~1,4 s y la RAM del menú baja ~200 MB (72 MB se quedan tras abrir). Menú en ULTRA BAJA: estática 452 → 377 MB, RSS 805 → 684. MEDIA o más: sin cambios. RAM DEL PROCESO sin renderizador (`--headless`, ULTRA BAJA, 7-11): partido 919 MB, ciudad 1.311 MB (el menú, menos); con renderizador por software el RSS sube a 2.457 / 3.294 MB porque el driver (llvmpipe/lavapipe) guarda texturas descomprimidas, objetivos de render y shaders: no es del juego ni baja con código (igual con Vulkan que con opengl3). Motor + texturas + vídeo (lo que verá una GPU real): menú 544, partido 941, ciudad 1.438 MB (< 1,5 GB). LLAMADAS DE DIBUJO (ULTRA BAJA, `hw_modesto`, 7-11): partido 236, ciudad a pie ~287 (con `FundirPiezas.fundir_ciudad` por celdas de 160 m: −27), mapa aéreo ~889 (−117); además `SubsistemasQuietos` (metro, estación central y teleférico: solo se excluyen sus trenes y cabinas) agrupa/funde su geometría quieta: −1.300 nodos, misma imagen (capturas antes/después con `SIN_QUIETOS=1`: estación 0,00-0,04 % de píxeles distintos; metro y teleférico solo cambian trenes, cabina y gente); meta < 120 NO alcanzada: lo que queda son ~7.000 MeshInstance3D sueltos (1.400 primitivas con material propio, metro 1.143, tráfico 590, esqueletos 745, grupos 633) que exigen fundir mallas por material y celda.
- **CORRECCIÓN (7-11, tras fusionar #207): el recorte de lo pequeño al 64 % del alcance a pie vaciaba el MAPA AÉREO** (sin árboles, bancos, contenedores ni edificios pequeños; capturas antes/después en ULTRA BAJA). Ahora solo rige MIENTRAS SE PASEA (`OptimizarGrada.recorte_a_pie`, llamado al entrar y salir del explorador) y al volver al mapa se devuelve lo de antes (450 m). Alcance a pie ULTRA BAJA: 180 m (medido: 200 m → 117-125 llamadas, 180 m → 117, 160 m → 106); BAJA 300 m. Mapa aéreo: ~896 llamadas (vuelve a verse completo). - **LO QUE SE VE DISTINTO tras las órdenes del dueño del 7-11 (para que lo juzgue)**: (1) ALCANCE DE DIBUJO A PIE en ULTRA BAJA 200 m y BAJA 300 m (antes 700): `OptimizarGrada.alcance_a_pie()`; la niebla de profundidad va del 43 % al 100 % de ese alcance y lo pequeño (farolas, árboles, coches…) se corta al 64 %. Medido (ULTRA BAJA, `hw_modesto`, ciudad a pie): 700 m → 275 llamadas / 603 k triángulos, 500 → 242, 400 → 212, 300 → 158 / 148 k, 250 → 151, 200 → 119-125 / 139 k. Se nota a lo lejos: el horizonte se disuelve en niebla a 200 m (capturas Forward+ 13:00, `pruebas/captura_alcance.tscn`, `ALCANCE_PIE=700` frente a defecto); MEDIA o más no cambian. `ALCANCE_PIE=n` fuerza otro valor. (2) Mallas sueltas de edificios fundidas por material unificado por firma y celda de 160 m (`FundirPiezas.fundir_ciudad`, misma imagen). Mapa aéreo: ~780 llamadas (no cambia con el alcance a pie; meta < 120 solo se mide a pie).
- **Código puro (orden del dueño 7-11: «solo mejorar el código, sin tocar lo visual»)**: construir la ciudad cuesta 6-10 s en el equipo simulado; por etapas (`TIEMPOS=1 … medir_ciudad`): `despejar` 1,9 s (cuatro pasadas; `Optimizar.trocear` 1,06 s), `_trafico` 1,2 s, `opt_agrupar` 0,7-0,8 s, `exp.afueras` 0,6 s, `exp.mobiliario` 0,5 s, `estadio.grada` 0,5 s, `obstaculos` 0,4 s. HECHO: `trocear` lee el `buffer` del MultiMesh y copia tramos seguidos de la misma celda (`Optimizar.celdas_de`, igual resultado probado): `despejar` 1.869 → 1.519 ms. Segunda pasada (`pulido/codigo2`): `agrupar` arma el buffer de una vez (`BufferMM.llenar`), clave de grupo como texto directo y `_malla_efectiva` sin lista de ids en el caso común: `opt_agrupar` ≈ 800 → 650-690 ms (dentro del ruido entre corridas, ±40 ms). `obstaculos` lee el `buffer` (`BufferMM.transform_de`) pero NO mejora: 222.000 instancias en ≈ 266 ms (1,2 µs cada una) ya es el suelo de GDScript; bajarlo exige C++ (`nativo/`). `_trafico` (≈ 1 s) es instanciar escenas de vehículos, no un bucle puro. Lo visible no cambia (círculos 47.264 igual; llamadas de dibujo dentro del ruido de corrida a corrida).
- **RAM de los jugadores y carga del menú (7-11, orden de la líder de rendimiento)**: `Jugador` pesa 5,3-5,8 KB (47 variables ≈ 3,3 KB, 4 Dictionary vacíos 1,6 KB, 5 Array vacíos 1,4 KB, señales 0,5 KB); el mundo completo (466 clubes, 11.650 jugadores) cuesta +77 MB. HECHO: `media_en` guarda una firma (`hash`) de los atributos en vez de una copia del diccionario: −7 MB tras calcular las medias y −1,6 MB al generar (misma suma de medias de los 11.650 jugadores: 738.748 antes y después). Carga perezosa de scripts del menú medida con el grafo de dependencias (264 scripts con class_name, 335 con capas, 2,9 MB de fuente, ~157 MB): los cortes seguros (CausasPartido, ajustes_actualizar+Actualizador, KitTextureFactory…) suman solo ~50-100 KB de fuente (4-8 MB, ~0,1 s); el resto o se usa en el primer pintado del menú o se instancia dentro de `Mundo` (EstadioPropio, Citas, Imprevistos): rinde poco. CARGA POR TROZOS (7-11, meta «< 200 ms por carga»): HECHA la generación del mundo (`Mundo.generar_por_trozos` + `Reales.aplicar_por_trozos`, usada por el orquestador de la entrada con fundido; `generar` síncrono intacto para los tests): mismo mundo para la misma semilla (prueba `mundo_trozos`: clubes, jugadores, ovr, valor), mayor hueco entre fotogramas 1.301 ms → ~50-60 ms (por software, trozos de 25 ms); total 1,9-2,5 s con la pantalla viva en vez de 1,3 s congelada; prueba `orquestador_trozos` del camino con fundido (mundo completo + etapa «país»). Pendiente de partir: menú (`load` de Principal 2,4 s = compilar scripts, y `Inicio._ready`), ciudad (etapas de 0,3-1,25 s) y estadio (`abrir` 7 s): cambian el orden de construcción, a coordinar con la sesión de la ciudad. Tiempos de carga HOY (ULTRA BAJA, `hw_modesto`): menú 4,45 s (`load` 2,42 s + `_ready` 1,98 s), ciudad 15,7 s de reloj con etapas de 0,3-1,25 s (`_trafico` 1.249 ms, `estadio.grada` 874, `despejar` 721, `exp.afueras` 715, `exp.mobiliario` 704, `opt_agrupar` 698), estadio `abrir` 7,0 s (peor fotograma 3,8 s).
- **Análisis completo de la ciudad (pedido del dueño 7-11)**: HECHO como informe: `docs/04_auditorias/ANALISIS_CIUDAD_2026-11-07.md` (herramienta `pruebas/analisis_ciudad.tscn`). Conclusión: ninguna zona se quita por rendimiento; el 77 % de la geometría son las 2 matas de pasto del Drive (+88 % de triángulos dentro de un parque, sin puerta de calidad). Propuestas 1-4 del informe, a la espera del OK del dueño.
- **Código puro (orden del dueño 7-11: «solo mejorar el código, sin tocar lo visual»)**: construir la ciudad cuesta 6-10 s en el equipo simulado; por etapas (`TIEMPOS=1 … medir_ciudad`): `despejar` 1,9 s (cuatro pasadas; `Optimizar.trocear` 1,06 s), `_trafico` 1,2 s, `opt_agrupar` 0,7-0,8 s, `exp.afueras` 0,6 s, `exp.mobiliario` 0,5 s, `estadio.grada` 0,5 s, `obstaculos` 0,4 s. HECHO: `trocear` lee el `buffer` del MultiMesh y copia tramos seguidos de la misma celda (`Optimizar.celdas_de`, igual resultado probado): `despejar` 1.869 → 1.519 ms. Siguiente: `obstaculos` y `agrupar` usan `get_instance_transform` por instancia (mismo truco del buffer), y mover estas pasadas a C++ (`nativo/`) si hace falta más.
- **Medición ULTRA BAJA tras #203-#205 (6-11, `hw_modesto.sh medir_ciudad`)**: a pie 331 llamadas de dibujo / 464 objetos / 582.000 primitivas; mapa aéreo 1.032 / 1.215 / 605.000; pico de RAM del proceso 3.791 MB (con la ciudad entera y el equipo simulado); construir 10,6 s. Metas del dueño: RAM < 1,5 GB, < 120 llamadas, < 200 ms: lejos las tres. Cristales azulados en singulares hechos (sin captura aún); pendientes de código puro: `exp.mobiliario`, `estadio.grada` (sin medir por etapa).
- **A REVISAR (idea del dueño 6-11, sin tocar aún)**: el menú «Ver mi ciudad» (`VistaCiudad`, vista aérea con construcción de obras) podría ser innecesario; las obras deberían construirse desde la GESTIÓN con los personajes del juego, no con ese tipo de menú. Revisar qué depende de `VistaCiudad` (`vistas_menu.gd`, prólogo, `medir_ciudad`) antes de decidir. Cristales azulados de los edificios singulares: revertidos de #205; rehacer en rama aparte con captura antes/después (Forward+, cámara real).
- **Carga de la ciudad en partes cortas, PASO 1 HECHO (rama `pulido/carga`, 6-11)**: `pruebas/medir_hueco.tscn` abre la ciudad como el juego (`_ver_ciudad_con_carga`, por partes) y apunta el mayor hueco entre fotogramas y una firma de la escena (nodos por clase, instancias, círculos). Medido sin pantalla, 2 núcleos, ULTRA BAJA (`CALIDAD=minimo taskset -c 0,1 godot --headless --path . res://pruebas/medir_hueco.tscn`; con ventana el render por software domina cada fotograma y no sirve): ANTES máximo 2.870-3.016 ms, 12-14 fotogramas > 200 ms de 38-42, carga total 9,8-10,7 s; DESPUÉS máximo 660 ms, 12 > 200 ms de 123, carga total 11,2 s (+1 s). Firma idéntica (6.385 mallas, 5.348 rótulos, 6.489 MultiMesh, 264.094 instancias, 153.953 círculos). Qué se hizo: `CargaPartes` (nuevo, `visor/carga_partes.gd`) reproduce `_optimizar` pasada a pasada con marcas entre ellas y recorre los bucles de trocear, obstáculos y agrupar pieza a pieza cediendo un fotograma cada ~40 ms (`CityBuilder.ceder`); `Optimizar.trocear/obstaculos/agrupar` se partieron en funciones por elemento (siguen síncronas: convertirlas en corrutinas creaba una dependencia circular con el explorador); `OptimizarGrada.al_final` y `FundirPiezas.fundir_ciudad` (3,3 s seguidos, de la sesión de RAM) ceden por dentro. Pendiente de repartir (huecos que quedan, ms): `_trafico` 690, `exp.metro` 500, `estadio.grada` 850 (cede por dentro pero queda un tramo), `estadio.campo` 340, `estadio.tunel` 420, `exp.mobiliario` 380.
- **Carga de la ciudad en partes cortas, PASOS 2-3 HECHOS (6-11, rama `pulido/carga`)**: `_trafico` cede un fotograma tras cada vehículo y peatón (`CityBuilder.ceder`, también en `CiudadExpansion.trafico`) y `ExpansionTardia.casas/mobiliario/afueras` y el metro tienen una marca entre sus pasos. Medido (`medir_hueco`, sin pantalla, 2 núcleos, ULTRA BAJA): máximo hueco 660 → 470 → 444 ms (de 2.870-3.016 al principio); fotogramas > 200 ms 12 de 139; firma de la escena idéntica. Quedan > 200 ms los tramos del estadio dentro de `StadiumBuilder` (`build_pitch` ~340, `TunelVestuario.montar` ~420: funciones estáticas largas sin cesión interna) y algún paso suelto de la expansión (~250-350).
- **Carga de la ciudad en partes cortas, PASO 4 HECHO (6-11, rama `pulido/carga`, sobre `main` con #210)**: el césped (`build_pitch`) y el túnel/vestuario (`TunelVestuario.montar`) ceden por fases (`StadiumBuilder._fase`: apunta el tiempo y cede si toca; fuera de la ciudad no hace nada; la ciudad pone `ceder` antes del césped); `fundir_ciudad` y `CargaPartes` comprueban que la escena siga viva tras cada cesión. `medir_hueco` rotula cada hueco con la última marca. Resultado (sin pantalla, 2 núcleos, ULTRA BAJA): máximo hueco 2.870-3.016 → 352-373 ms; 10-11 fotogramas > 200 ms de 131-134; carga total 10,5-10,8 s; firma de la escena idéntica. Banco `FIN. 0 fallos` y banco `estadio_3d` (f0b_huella, partido y visor) `FIN. 0 fallos`. Queda una COLA de tramos de 230-370 ms: `estadio.campo`/`_estadio` (~290-370), `exp.metro_montar` (365), `_calles` (304), `_karting` (285), manzanas `exp.bloque` (~250-270), `limitar_vista` (258), `_rotulo_barrio` (232); cada una exige partir su función. `ciudad_construccion` da 1 fallo que YA existe en `main` (depósitos de agua sobre torres: cuerpo grande flotando a más de 6 m del terreno) y no es de esta rama.
- **Sin vista aérea para el jugador (decisión del dueño 6-11; rama `pulido/sin_aerea`)**: `VistaCiudad` se queda como recurso de programación (clase y pruebas). Paso 1 HECHO: las obras ya se hacen a pie sin mapa (E sobre un solar o instalación → ficha → Construir/Mejorar → `_empezar_obra`); prueba `pruebas/prueba_obras_a_pie.tscn`. Paso 2 HECHO: «Ver la ciudad en 3D» (pantalla Ciudad) y «Pasear/Conducir» abren a pie directo (`_ver_ciudad_explorando` espera a la ciudad entera) y Esc vuelve al menú, no al mapa. Paso 3 PENDIENTE (aviso al líder antes): quitar «Volar sobre ella» (`menus_laterales.gd`, acción `ver_ciudad`) y `_ver_ciudad_con_carga` si nada más lo usa. Paso 4 pendiente: comprobar prólogo, reloj, clima. Mejora posterior (Puerta B): obras desde la gestión con el personaje responsable (Trabajadores), que reutilice la ficha.
- **Carga de la ciudad en partes cortas (aprobado por el dueño 6-11; meta ≤ 200 ms de bloqueo por trozo; PROPUESTA, nada tocado)**: hoy `CityBuilder._marca` solo cede un fotograma si pasaron > 40 ms desde el último, así que el bloqueo máximo es el tramo MÁS LARGO entre dos `_marca`. Tramos mayores de 200 ms medidos (ULTRA BAJA, equipo simulado): `_trafico` 1.250-1.300, `estadio.grada` 870-1.660 (ya cede por dentro con `_ceder_paso`), `estadio.tunel` 570-900, `_estadio` 830, `despejar` 720-1.400 (son CUATRO pasadas: primitivas, trocear, butacas_livianas, distancias, con UNA sola marca al final), `exp.afueras` 715-800, `exp.mobiliario` 650-700, `opt_agrupar` 700-880 (bucle de 19.700 mallas), `estadio.campo` 670, `_suelo` 475, `exp.calles` 446, `obstaculos` 370-400 (bucle de 222.000 instancias de MultiMesh), `_calles` 318, `exp.metro` 287, `_barrio_residencial` 270, `_paradas_bus` 213. Reparto propuesto SIN cambiar el orden de construcción (solo más puntos de cesión): marcas entre las cuatro pasadas de `despejar` y `trocear`/`agrupar`/`obstaculos` convertidas en corrutinas que cedan cada 40 ms dentro de su bucle; `_trafico` con una marca cada pocos vehículos (~30 marcas); marcas entre los 6-8 pasos de `ExpansionTardia.mobiliario`/`afueras`; `_ceder_paso` dentro del túnel y del campo del estadio. Coste: cada cesión es un fotograma más (≈ +1-2 s de carga total a 60 FPS, más en el móvil) a cambio de que ningún fotograma pase de ~200 ms. Riesgo: durante una cesión corre el resto del juego con la ciudad a medias (el tráfico ya añade coches mientras se mueve; `completa` y `resto_listo` siguen avisando al terminar).
- **Carga de la ciudad en partes cortas, PASO 5 (6-11, rama `pulido/carga`, PR #212)**: ceden también el metro (viaducto, túnel y cada estación), `_calles`, las manzanas (acera y edificio por separado) y `limitar_vista` (pieza a pieza; `OptimizarGrada.limitar_fuera/limitar_uno`). Máximo hueco 331-357 ms (de 2.870-3.016), 10-12 de 143 fotogramas > 200 ms, firma idéntica, banco 0 fallos. Lo que queda por encima de 200 ms son OPERACIONES INDIVISIBLES, sobre todo la generación de texturas procedurales (césped `estadio.campo` ~330, asfalto en `_calles` ~315, `_estadio` ~310) y alguna manzana grande (`exp.bloque` 250-300), `exp.casas` 257, `zonas_vista` 233. Siguiente (más grande): generar esas texturas en un HILO antes de usarlas (como `RuidosFondo.precargar`), o caché en disco.
- **Banco `ciudad_construccion` arreglado (6-11)**: «depósitos de agua sobre torres» fallaba en `main` porque las mallas `Fundido*` (agregados de piezas de azotea que crea `FundirPiezas.fundir_ciudad`) cuentan como cuerpos de 44×32 m a 13 m de altura; se excluyen del chequeo (como `Cartel`/`Grua`). Quedan 4 cuerpos reales (los depósitos y torres de siempre, tolerancia 5). Sin cambio visual.
- **Carga en partes cortas, texturas en hilo: DESCARTADO por medición (6-11, rama `pulido/texturas_hilo`)**: `medir_hueco` ahora rotula cada hueco con el punto de cesión que lo abre y el que lo cierra (`CityBuilder._cede_en`, `StadiumBuilder._ult_tm`) y se vio que las texturas NO son el cuello: `Texturas.asfalto` cuesta 5 ms (caché en disco + `RuidosFondo`); el tramo «de `_calles` a `pitch_cesped`» (~340 ms) es el comienzo de `build_pitch` (material del césped, shader, `CespedCapas`), no una textura generada. Hecho en esta rama: `fundir_profundo` (la fusión de ~540 mallas del túnel en ULTRA BAJA, 380 ms seguidos) cede mallas a mallas. Máximo hueco ahora 354 ms (9 de 135 fotogramas > 200 ms). Tramos que quedan (ms): tras `estadio.grada` hasta `_estadio` 354, `build_pitch` hasta `pitch_cesped` 341, resto de `TunelVestuario.montar` 325, manzanas grandes (`exp.bloque`) 295-296, `ZonasVista.montar` 255, `exp.casas`→`exp.mob.marquesinas_bus` 220.
- **CARGA DE LA CIUDAD: META CERRADA (6-11, decisión de la líder)**: bloqueo máximo entre fotogramas ~0,35 s (de ~3 s) en ULTRA BAJA, medido con `medir_hueco`; los seis tramos de 220-354 ms que quedan están listados arriba y NO se siguen repartiendo (cada uno ganaría ~100 ms). PRs: #212 (reparto) y el de `pulido/texturas_hilo` (`fundir_profundo` cede + medidor con puntos de cesión).
- **C++ de `obstaculos` (rama `pulido/nativo_obstaculos`, 7-11)**: `DinastiaNativo.obstaculos_multimalla` (`nativo/src/obstaculos.cpp`) es la traducción literal del bucle por instancia de `Optimizar.obstaculo_multimalla` (la parte de 222.000 instancias); el GDScript queda como respaldo (`Optimizar.circulos_mm_gd`: Android arm, Web, `DINASTIA_SIN_NATIVO=1`). `probar_nativo.tscn`: círculos IGUALES byte a byte (6.000 instancias torcidas, alargadas y dentro de rectángulos sólidos), 5 ms → 0 ms; las cuatro variantes recompiladas (Linux y Windows, debug y release). Firma de la escena idéntica con y sin la extensión (153.953 círculos). Etapa `obstaculos` de la carga: 381 → 327 ms (−14 %): el bucle ya era sólo ~un tercio; el resto es API de nodos por cada uno de los ~23.000 MultiMesh (copia de `mm.buffer`, `is_visible_in_tree`, `_sin_dinamica`), que C++ no abarata. `opt_agrupar` (677 ms) NO se pasa a C++: es casi todo API de nodos (`find_children`, `global_transform`, materiales), no aritmética; lo numérico (`a_buffer`) cuesta < 20 ms.
- **Ciudad en ULTRA BAJA (7-11)**: tope de 450 m para lo pequeño en cualquier sistema: a pie 688 → 411 llamadas de dibujo, mapa aéreo 2.761 → 1.321 (`medir_ciudad`). Segunda pasada (7-11): el tope también alcanza a los TROZOS de agrupado con piezas pequeñas (< 14 m: ventanas, postes, troncos), antes exentos por tener la caja grande: a pie 411 → 355 (en total 688 → 355, −48 %; mapa aéreo 2.761 → 1.244). Lo que queda a pie (≈ 355): objetos agrupados y mallas sueltas de `city_builder`; siguen siendo la lista de `rendimiento_antes_despues_2026-11-06.md` (edificios sueltos, Estación Central y metro, trozos de agrupados, maletines). Meta < 130: NO alcanzada (partido 236, ciudad 411).
- **Prólogo (orden del dueño 6-11: «reducirse a la mitad»)**: medido en ULTRA BAJA (`medir_prologo`, con `DETALLE=1` desglosa lo dibujado): 1.132 llamadas de dibujo al cargar. HECHO lo seguro: rótulos 3D con alcance según su tamaño (−78) y tope de 220 m para lo pequeño (−96) → 958 y, con la cámara del prólogo a 500 m (orden del dueño) y la gente del club con alcance corto, **913 (−19 %)**; 150 m solo ganaba 40 más y arriesga que aparezcan cosas de golpe. La mitad (≈ 566) NO se alcanza: lo que queda se dibuja de cerca (club, túnel del vestuario y estadio: ~70 rótulos de salas, cajas y mallas). Palancas sin hacer: fusionar los rótulos del túnel y del club en una textura, oclusores en el túnel y el club, y apagar partes del estadio que no se ven desde el recorrido. Pendiente de aclarar con el dueño a qué se refería (llamadas de dibujo, tiempo de carga —22 s en este equipo simulado—, memoria —880 MB— o gente).
- **Mapa aéreo (7-11, aprobado por el dueño)**: el tope de 450 m ya ocultaba lo pequeño al alejar; lo que sobraba eran 163 piezas del personal del club y rótulos de la galería, ahora con alcance corto (90 m el personal; rótulos según su tamaño): 1.236 → **1.045** llamadas (−15 %). Lo que queda es el estadio en vista cercana (325 trozos de escaleras y 295 mallas de `city_builder`); darles 250 m solo ganaba 15 más y se descartó.
- **Ideas de la guía de optimización de Godot (6-11, aprobadas 2, 4 y 5 por el dueño)**: HECHAS 2 y 4: (2) cámara a pie con alcance de 700 m + niebla de profundidad de 300 a 700 m en ULTRA BAJA y BAJA (a pie 355 → 310 llamadas; triángulos 880 k → 581 k; el mapa aéreo no cambia porque la niebla solo está puesta mientras se pasea); (4) los peatones detrás de la cámara (a más de 3 m) pausan su animación. (5) el LOD de mallas: probado 12 px en ULTRA BAJA, solo −2 % de triángulos a cambio de menos detalle en personajes: se deja en 6. Pendientes sin aprobar: (1) más oclusores en la ciudad; (3) edificios por bloque (HLOD con `visibility_parent`); (6) materiales más simples en ULTRA BAJA (el teléfono del dueño iba limitado por GPU, no por llamadas de dibujo); (7) revisar objetos transparentes; (8) árboles lejanos como carteles. No aplican: luces horneadas, coordenadas de mundo grande.
- Eliminar opciones POCO REALISTAS del CREADOR DE PERSONAJE (cuerpos, caras, peinados; aclarado por el dueño 6-11): inventario con capturas del estudio (`EstudioPersonaje`), retirar de los selectores de forma reversible (lista en datos, sin borrar archivos) y proponer al dueño los dudosos. Lo hace el líder. PRIMERA PASADA (6-11, líder): se dibujaron los 5 deslizadores del cuerpo (complexión, hombros, barriga, piernas, cabeza) en −1/0/+1 con el cuerpo masculino y NINGUNO se ve claramente irreal (los cambios son suaves; el más visible, hombros +1, abre los brazos). Falta ver el cuerpo femenino, los 14 peinados, los cortes medidos y las caras de la biblioteca; el dueño debe señalar con una captura qué avatares le parecen irreales.
- Personajes que atraviesan objetos: HECHO (6-11) `pruebas/detector_atraviesa.tscn` (peatones y vehículos, tope 0; corregidas la avenida del estadio —peatones y coches giraban dentro de la huella/vestuario—) y `pruebas/caminar_de_verdad.tscn` (pies quietos contra paredes; separación avatar–pared 0,50 m = radio del cuerpo). Queda decidir si el margen del avatar se quiere mayor y vigilar vehículos APARCADOS (el detector solo ve los que circulan).
- Al terminar: buscar consejos de rendimiento de Godot (con fuentes) y aplicar los seguros. Ante dudas, consultar a otras sesiones/IA.

## IDEAS Y TAREAS DEL DUEÑO (3-11 noche, conversación casual) — se borran al completarse del todo
**DECISIÓN DEL DUEÑO (3-11 noche): se mantienen los «4 juegos en 1» (gestor, partido jugable, ciudad abierta, vida del DT), pero las IDEAS NUEVAS quedan EN PAUSA. Foco: los puntos más débiles de la evaluación del líder (44/100) y pulir lo que ya existe. Cuando esté muy pulido, se abarca más.** Orden por debilidad:
1. Rendimiento en el aparato real (15/100): FPS medidos en el teléfono del dueño en MÍNIMA; ciudad ≤900 llamadas; ideas de rendimiento de abajo, midiendo.
2. Partido (30/100): que pases, tiros, área y córneres se sientan como fútbol (sesión PES 6) + **MODO JUGAR PARTIDO EN MÓVIL** (falta: controles táctiles para jugar el partido en el teléfono).
3. Foco (25/100): recortar lo que no está a la altura antes de sumar nada.
4. Ciudad (45/100) y aspecto visual (55/100): rellenar y pulir lo que ya está, sobre todo en MÍNIMA.
5. Calidad técnica (60/100): bancos (abajo) y mega auditoría.

**Recorte AUTORIZADO por el dueño (3-11) SOLO en calidad MÍNIMA:** tráfico del anillo a la mitad, sin detalles de fachadas (EdificiosDet) y menos peatones lejanos (sesión de ciudad).

**Evaluación del menú nuevo: 90/100.** Para llegar a 100:
- Tablas densas (Dinero → Finanzas, Competiciones → Ligas y clubes…): guías horizontales (línea de 1 px de baja opacidad o filas alternas «cebra») para no perder la fila al leer de izquierda a derecha.
- Deslizadores (Ajustes → Dispositivo, Ciudad → Diseño…) demasiado finos: más gruesos y con más área de toque (pantallas táctiles y mando).
- Tarjetas de las portadas: borde de 1 px con ~10 % más de luminosidad que el fondo para delimitar lo pulsable (hoy solo contraste de relleno).

**Rendimiento (ideas del dueño; revisar cuáles ya están y aplicar las que falten, midiendo):**
- Escalado 3D FSR 2.2 (Rendering > Scaling 3D) a 0,75-0,85 con salida nativa.
- Renderizador Mobile o Compatibility en móvil y equipos viejos (Forward+ solo PC alta).
- Sombras: apagarlas en luces que no las necesiten (OmniLight3D/SpotLight3D) y bajar la resolución del mapa de sombras.
- VoxelGI o ReflectionProbes en lugar de SDFGI; LightmapGI (iluminación horneada) para lo estático.
- MultiMeshInstance3D para todo lo repetido; LOD automático activado en las mallas importadas.
- VisibleOnScreenNotifier3D en objetos dinámicos: sin proceso ni física fuera de pantalla.
- Oclusión con OccluderInstance3D horneado; capas y máscaras de colisión estrictas.
- MODO ULTRA RENDIMIENTO (gráficos ultra bajos): el público existe solo al inicio del partido y luego desaparece, con una cámara desde un punto donde no se note (el público como ruido).
- Mejorar el recolector de basura / la gestión de memoria.

**Bancos de pruebas (confirmado: los del juego):** megarreforma en más de 30 bancos ESPECIALIZADOS, modulares (uno por área, corribles solos) y ultra detallados aunque tarden más.

**Exportador de GitHub (CI de builds):** más eficiente, con los bancos nuevos. (La selección del sistema ya está en «Compilar y probar» → `objetivo`; el ACTUALIZADOR aparte se hizo el 4-11: flujo «Actualizar Dinastia (parche)» + autoload `Parches`. Queda: que Android pueda bajar e instalar el parche desde el propio juego, porque en el teléfono no se puede copiar a la carpeta interna.)

**Mega auditoría nueva:** comprobar que todo funciona, que todo está conectado y que todo es accesible.

**Mundo abierto:** el botón de interactuar debe aparecer SOLO cuando estás muy cerca del objeto con el que se puede interactuar.

**Pulido pedido:** la CONFIGURACIÓN DE LOS CONTROLES DEL MANDO EN EL PARTIDO debe verse mejor; los ESCUDOS deben poder profundizarse más (más detalle/edición); buscar MÚSICA totalmente libre (dominio público / CC0) y proponer cada pista con su fuente y licencia al dueño, que decide cuáles entran (aprobado así el 3-11).

## REPARTO DEL 4-11 (decisión del dueño: menos bancos, más lo que se siente al jugar) — se borra al completarse
- PES 6 (orden DIRECTA del dueño, 4-11 03:00): su rama (PR #128) unida a `main`; ahora el modo JUGAR PARTIDO en MÓVIL (controles táctiles,
  UI del partido en pantalla pequeña, safe area). En pausa: juego por bandas (centros con el área ocupada) y velocidad defensa-atacante.
- Ejecutora: subir sus 4 bancos de interfaz; luego «Buscar actualización» dentro del juego (baja el parche de los Releases publicados a
  user://parches y pide reiniciar; Android incluido).
- Ciudad: PASADAS VISUALES con antes/después para la nota del dueño + dejar estable la prueba «estadio y ciudad por partes».
- «Búsqueda de fallos» (4.ª sesión, abierta por el dueño 4-11 03:16): ronda cada 20 min que solo REGISTRA fallos (sección «FALLOS DETECTADOS»).
- Líder: rendimiento móvil (barrido de resolución en la prueba de rendimiento; MÍNIMA hasta 60 FPS con los datos del teléfono del dueño)
  y pasar la rama a `main` (PR #120, el dueño dijo SÍ el 4-11) cuando el CI esté verde.

## COBERTURA DE PLATAFORMAS (5-11) — se borra al completarse
- `plataformas.yml` ejecuta el juego en Windows (nativo + mini banco) y en Web (menú en Chromium): ver `04_auditorias/cobertura_sistemas_2026-11-05.md`. Pendiente: banco/especiales completos en Windows (`/tmp` fijos, `xvfb-run`), humo de Android (necesita APK x86_64 o dispositivo), preset de macOS (no existe), renombrar el archivo de `material/escudos_especiales_originales/` con nombre larguísimo (no clona en Windows), entrada Web en `dinastia.gdextension` (ruido de consola).

## FALLOS DETECTADOS
- **(10-11, sesión 7) Cuelgue de la captura del edificio del club con ESP club 3 y ARG club 3** (`pruebas/captura_edificio_club.gd`, `captura_oclusion_vestuario`): en Forward+ con llvmpipe el primer fotograma no termina (Godot en 100 % de CPU, sin salida; 8+ min). Se repite con `PAIS=ESP CLUB=3` y `PAIS=ARG CLUB=3`; con `PAIS=ARG CLUB=0/1` tampoco acabó en una repetición, mientras ENG/JPN/GER terminan en ~2 min. Sospecha: aforo grande del estadio propio (30 000–46 200) + llvmpipe; no probado en GPU real. Evitar esos clubes en capturas por ahora.
- **Búsqueda de errores, tanda 1 (7-11, sesión de rendimiento; solo detectar y registrar, SIN corregir; main @04fe0a98 con #207-#213).** Cada uno con archivo:línea, cómo se repite y evidencia. Código mío en #207/#210 salvo indicación; confirmados = repetidos con una sonda temporal (borrada).
  1. **[CONFIRMADO · medio] Una generación del mundo por trozos abandonada sigue corriendo y pisa el estado global.** `nucleo/mundo_p3.gd:199` (`generar_por_trozos`), `:215` (`_generar_inicio`: `Partido.ex_de_mi_club.clear()`, `Azar.sembrar`) y `:246-254` (`_generar_cierre`: consume `Meta.heredar_proximo` y asigna `LeyesPais.clubes_mundo`). Si el jugador sale de la entrada mientras sale «Generando el mundo…» (cambio de escena libera al orquestador, `ui/entrada/orquestador.gd:276-286`), nadie cancela la corrutina: termina ~2 s después y deja `LeyesPais.clubes_mundo` apuntando al mundo abandonado y `Meta.heredar_proximo = false`. Repetir: lanzar `OrquestadorMundo.generar_mundo_por_trozos()` sin esperarla, a los 5 fotogramas poner `LeyesPais.clubes_mundo = {"marca": true}` y `Meta.heredar_proximo = true`, esperar 400 fotogramas → la marca desaparece (466 clubes) y `heredar_proximo` queda en `false`. Efecto probable: si en esos 2 s se carga una partida guardada, sus leyes de país apuntan a otro mundo; la herencia de reputación pedida se pierde. Arreglo posible (no hecho): cancelar con una bandera/`WeakRef` del orquestador y no tocar globales si se canceló.
  2. **[CONFIRMADO · ALTA (cambio visual real en main aprobado por error como «sin cambio visual»), parte de #210] `fundir_pequenas` hace trozos de MultiMesh de hasta ~400 m y Godot mide el alcance de dibujo al CENTRO de la caja.** `visor/optimizar.gd:205-208` (`MIN_TROZO`=40, `FACTOR_TROZO`=4). Evidencia en la ciudad construida (ULTRA BAJA): de 3.755 MultiMesh con corte de 380 m, 2.345 tienen la caja de más de 150 m de lado y 1.716 de más de 300 m (ej.: 9 instancias en una caja de 380 m). Prueba mínima: un MultiMesh con una instancia a 10 m de la cámara y otra a 900 m, `visibility_range_end = 380` → 0 objetos dibujados (con las dos cerca, 1). Medido a pie en (20, 300): de 35 instancias a menos de 50 m, 3 (9 %) quedan ocultas por este motivo; en (-60, 390) y (150, 100) 0. Es un cambio visual (objetos pequeños cercanos que desaparecen) que dije «sin cambio visual» en #210: era cierto para los triángulos y falso para este caso. Se agrava con `recorte_a_pie` (115 m).
  3. **[CONFIRMADO · latente] `FundirPiezas.fundir_ciudad` ignora propiedades de la instancia al fundir.** `visor/fundir_piezas.gd:299` (la clave solo lleva material, sombra, alcance final, margen, GI y celda). Prueba: dos cajas con el mismo material, una con `visibility_range_begin = 50`, `transparency = 0.6` y `extra_cull_margin = 40` → la malla fundida sale con 0, 0 y 0 (se pierden). Hoy no hay piezas con esas propiedades entre las candidatas (nombres `@…`, sin script ni grupo), pero cualquier pieza nueva con ellas se rompería sin aviso. Falta además `visibility_range_fade_mode` y `custom_aabb`.
  4. **[LECTURA · bajo] `Reales.aplicar_por_trozos` no repite el orden de comprobaciones de `aplicar`.** `nucleo/reales.gd:67-71` pide `Datos.tabla("POSD")` antes de mirar si el índice está vacío (`aplicar`, líneas 51-57, sale antes sin pedirla): si la tabla faltara con el índice vacío, la versión por trozos escribe un `push_error` que la síncrona no. No reproducido (la tabla existe).
  5. **[LECTURA · bajo] El alcance a pie se fija al crear el explorador.** `visor/optimizar_grada.gd:162-165` (`alcance_a_pie`) y `visor/explorador_ciudad_p4.gd` (`camara.far`, niebla): si se cambia la calidad en Ajustes mientras se pasea, `far`, niebla y recorte siguen con el valor anterior hasta volver a entrar. Sin reproducir con captura.
  6. **[CONFIRMADO · ALTA (de proceso)] En este contenedor NO hay «Forward+»: capturas y mediciones salen en Compatibility (OpenGL/llvmpipe).** `herramientas/captura.sh` y `herramientas/hw_modesto.sh` piden `--rendering-driver vulkan --rendering-method forward_plus`, pero no hay ICD de Vulkan (`/etc/vulkan/icd.d` vacío, falta `mesa-vulkan-drivers`) y el motor lo dice en cada arranque: «ERROR: Required Vulkan instance extension VK_KHR_surface not found» seguido de «OpenGL API 4.5 … Compatibility … llvmpipe». Consecuencias: la regla de CLAUDE.md («lo visual se revisa en Forward+») no se cumple aquí; las cifras de llamadas de dibujo, triángulos y las capturas de #207-#213 (y las de `rendimiento_120fps.md` hechas con `hw_modesto`) son de Compatibility, que es lo que usa el móvil pero NO lo que usa el PC (el Forward+ cuenta sombras y prepasadas aparte). Corrijo mis mensajes anteriores: dije «Forward+» y era Compatibility. Repetir: `xvfb-run godot --rendering-driver vulkan --rendering-method forward_plus …` y mirar la salida.
  7. **[CONFIRMADO · MEDIO] La cabecera del registro de errores miente sobre el renderizador.** `nucleo/registro.gd:140-142` (`_cabecera_sesion`) escribe el ajuste PEDIDO (`ProjectSettings … rendering_method`), no el real; el método real (`RenderingServer.get_current_rendering_method()`) ya está calculado en `_renderizador()` (líneas 134-137) y no se usa ahí. Evidencia: `user://registro.txt` abre cada sesión con «… · forward_plus» y en esas mismas sesiones hay «2D MSAA is not yet supported for GLES3» y «Subsurface scattering is only available when using the Forward+ renderer». Un informe de fallos de un jugador con Vulkan roto o en móvil diría Forward+ y engañaría a quien lo lea.
  8. **[CONFIRMADO · BAJO] Avisos repetidos de funciones que Compatibility no tiene.** `visor/vestidor_q_p2.gd:82` (`vestir_equipacion`: el shader de la equipación usa subsuperficie; «Subsurface scattering is only available when using the Forward+ renderer», 152 veces en el registro de este contenedor) e `ui/entrada/idioma_bandera.gd:67` (`msaa_2d = MSAA_4X` sin mirar el renderizador: «2D MSAA is not yet supported for GLES3» una vez por bandera, ~10 por pantalla de idioma). En móvil (Compatibility) llenan el registro y comen el tope de líneas; además esa piel y esas banderas se ven distinto que en PC.
  Observación sin confirmar: en la pantalla de título a 1280×720 la fila «PORTADA DEL JUEGO» queda cortada por la derecha («Sala ej…»); parece ser una lista con desplazamiento, no se comprobó con ratón.
  **Tanda 2 (7-11, main @04fe0a98): sin fallos nuevos.** `herramientas/especiales.sh` (las rápidas) en local: 62 pruebas OK, 0 FALLO; `banco.sh` 0 fallos; ningún script de más de 450 líneas. Revisadas por lectura y/o sonda sin hallazgo: `CargaPartes` (todas las rutas comprueban `is_instance_valid` tras ceder), `OptimizarGrada.al_final` (único llamador con `await`), `FundirPiezas.fundir_profundo` y sus llamadores (todos con `await` salvo la prueba `_probar_fundir_r2`, que llama sin ceder), `stadium_builder._ceder_paso` con `ceder` liberado (`== null` es cierto para un objeto liberado: no da error), `_ver_ciudad_explorando` de #211 y el recorte a pie (`recorte_a_pie` restaura todo al salir; a pie no queda ninguna pieza pequeña con el alcance de 450 m).
  **LISTA FINAL de las tres tandas, por prioridad (para el dueño, 7-11):** (1) ALTA — nº 2: los trozos de MultiMesh de hasta 400 m con alcance medido al centro ocultan objetos cercanos (cambio visual real en main). (2) ALTA, de proceso — nº 6: aquí no existe Forward+ (todo es Compatibility): revisar las cifras y capturas de rendimiento en un PC con GPU antes de darlas por buenas en PC. (3) MEDIA — nº 1: una generación del mundo abandonada pisa `LeyesPais.clubes_mundo` y `Meta.heredar_proximo`. (4) MEDIA — nº 7: el registro de errores anota «forward_plus» aunque se ejecute en Compatibility. (5) BAJA/latente — nº 3 (`fundir_ciudad` ignora propiedades de la pieza), nº 8 (avisos de SSS y MSAA 2D en Compatibility), nº 4 (orden de comprobaciones en `Reales.aplicar_por_trozos`), nº 5 (alcance a pie fijado al entrar). Flujo recorrido con capturas (título, intro, idioma, modo, país, hub del menú, partido con cámara de TV): sin errores de script y sin fallos visuales más allá de lo anotado.
  Descartado tras comprobarlo (no es fallo): las semillas distintas dan las MISMAS plantillas por diseño (pruebas `varios` y `varios_p6`); la generación por trozos da el mismo mundo que la síncrona para 3 semillas con los 24 países (clubes, jugadores, ovr, valor, sueldos, capitanes, reales, ids); liberar la entrada o la ciudad a mitad de carga no produce errores de script.
- **Pruebas por sistema (5-11, rama `sonar/bancos`; detalle en `04_auditorias/cobertura_pruebas_2026-11-05.md`):**
  - Reparto de `especiales` por tiempo medido (5-11): con los registros del CI (76 min de pruebas en total) `herramientas/repartir_especiales.py` deja las 6 partes en 12,7–12,8 min (antes 8,5–18,3). Con 6 partes no baja de ahí; para pasar de ~12 min a ~11 hace falta una 7.ª parte en el workflow (`ESPECIALES_PARTE` hasta `i/7`; regenerar con `--partes 7`): lo decide la sesión de plataformas. Regenerar el reparto tras añadir muchas pruebas.
  - Caza de frágiles (6-11): `cazar_fragiles.py` examinó 23 de ~340 especiales (0 frágiles). Seguir por partes (`--parte i/6 -n 5`, con carga y `--sucia`); para pruebas intermitentes basta mucha repetición. `auditoria_vida_global_limite` falló en 2 CI sin reproducirse: ya imprime el estado y la semilla si vuelve a fallar.
  - Orden aleatorio en el CI nocturno: `ESPECIALES_ORDEN=aleatorio` existe en `especiales.sh`; falta pedirle a plataformas un job nocturno que lo use.
  - Cobertura: sin cobertura de líneas de GDScript; hay la de funciones (83 %). Subir `entrenamiento`, `club_dentro`, `cantera_p2`.
  - `Actualizador.sistema()` da «escritorio» también en Web y macOS: confirmar que el parche sirve ahí (sesión de plataformas).
  - Escenas de prueba que nadie lanzaba (5-11, 100 con aserciones): 87 pasan y YA se lanzan (`especiales.sh`, bloque `reutilizadas2`, banco `reutilizadas_2`). Las 13 restantes son HALLAZGOS con su evidencia (headless, 120 s):
    · `ideas/optA_persona`: la cadera del clip «persona/parado» queda 4 cm SOBRE el reposo (el test ahora lo admite hasta 6 cm; investigar por qué sube).
    · `ideas/pgra_grada`: un canto por peldaño de pasillo (1014 / 936).
    · Sin revisar: `captura_informe_rival` (lenta) ; `ideas/sen_conexiones` terminó una vez y otra no (inestable). (`s3_auditoria_interfaz` y `s5_ocasiones` NO estaban colgadas: pasan en 2-4 min y ya se lanzan en el bloque lento de `especiales.sh todo`.)
  - Ejecutar `pruebas/so` de verdad en Windows, Android y Web (flujo `plataformas.yml`, otra sesión): `pruebas_so.py --lista --sistema web|android` dice qué toca; `--marcadores < log.txt` (por la entrada estándar) revisa el resultado.
  - Referencias visuales de `pruebas/so/referencias/` hechas con lavapipe/llvmpipe: regenerarlas en GPU real (`VISUAL=referencias`) y añadir las de móvil.
  - Funciones puras de `nucleo/` sin prueba directa (solo 4 pruebas `fun_*`): ampliar por áreas.
Los hallazgos de la auditoría viven en `docs/04_auditorias/MEGA_AUDITORIA_4/*.md` (uno por área); aquí solo lo que espera al dueño.
- **Propuesta (A4-INT-R03, 4-11): la tabla de «Mi plantel» en el móvil.** Cuesta ~537 llamadas de dibujo y ~36.000 primitivas al pintarse (25 jugadores × cara, nombre y cinco celdas, cada celda una etiqueta). Con el ahorro de MÍNIMA solo se paga al abrirla o cambiar algo, no en cada fotograma. Sin cambiar el aspecto no hay forma pequeña: dibujarla en un solo control con `_draw` o crear solo las ~15 filas visibles obliga a reescribir el orden por columnas, las marcas, los botones de la fila y la cebra. Se deja como está hasta que el dueño diga si le importa más la velocidad de abrirla en un móvil modesto que el riesgo de rehacer la tabla.

## 0. Lo que espera una decisión tuya (lista corta)

Sin esto, las filas que dependen de ello no avanzan. El detalle está en la sección que se cita.
- **Decididas por el dueño (27-10 tarde)** (CLAUDE.md orden 14): pantalla de entrada APROBADA; «el bloqueo» de modos ACEPTADO; las 53 escenas de prueba: reutilizar lo que sirva; peatones SÍ en bus y transportes; dificultad de la CPU en 8 categorías (Practicante, Cadete, Debutante = normal, Semiprofesional, Profesional, Experto, Maestro, Ultimate) más dificultades fuera del partido; policía y bomberos SÍ; peluches SÍ y coleccionables con logros; museo con trofeos interactivos; pelo con lo del Drive; clasificar las ~1.200 ideas.
- **Clasificación de las 1.201 ideas** (27-10): `docs/04_auditorias/clasificacion_ideas_2026-10-27.md`. 68 para el lanzamiento y 43 que hay que verificar jugando (unas 26-32 sesiones-día, 9-11 días con 3 sesiones); 731 después, 296 a verificar después, 63 descartadas y 20 de decisión del dueño. Revisarla y aprobarla.
- **Decididas por el dueño (26-10):** logros de racha: **cuentan jugando y simulando**; «Siempre, todo el partido» apaga ese lado del plan: **se queda así**; versión **0.9.0**; reparto de la TV 50/50: **sí**; taquilla ×3,5: **sí**; **por ahora sin pago** (nada de monedas ni gacha); banderas **detalladas** (flag-icons, MIT); narración hablada: **después del lanzamiento**; filas 1-14 de `docs/04_auditorias/investigacion_s4/03_propuesta.md`: **todas al plan** (hechas en la sesión 5: la 14 entera, la parte del partido de la 4 y el núcleo de la 18, ver `docs/04_auditorias/sesion_5.md`; de la 4 queda «en finanzas, cada ingreso y gasto con su origen»; de la 18, la interfaz de la pizarra con las dos fases y los roles, y que la IA use roles); fuentes OFL, silbato VCSL y CI: **sí**; modelo B (MakeHuman): **pulirlo más** (fase 4 traje, fase 5 cuerpo) antes de integrar; rueda de prensa: **compararla con la competencia y completarla**.
- **`main` reescrito y etiqueta `latest`**: las 8 ramas viejas ya no están (27-10); siguen la etiqueta `latest` y la historia vieja de `main` (502 objetos de capturas e informes): empujarlo necesita un *force push* que solo puede hacer el dueño (§1). Cuándo fusionar a `main` la rama actual (§9).
- **Foundry/Azure** sí o no; **abrir la red a Wikimedia** (caras y escudos que faltan) (§1).
- **Texturas de caras**: permiso para probar BC7 en una muestra y medir ΔE de piel (§4).
- **20 decisiones de producto** (monetización y estética) (§7, final) y las prioridades de «Huecos y mejoras propuestas» (§10).
- **(4-11, bancos fase 2) Recalibrar los remates del partido SIMULADO**: da 10 remates, 5,6 a puerta y 2,73 goles por partido con un 27 % de gol
  por remate (real ~25 remates, ~8,5 a puerta, ~11 %), así que el portero para el 51 % (real 60-80 %). Arreglarlo = más llegadas con menos
  conversión (`Balance.BASE_ATAQUE`/`CONVERSION`/`R_ATAJADA`), manteniendo 2,7 goles: cambian las estadísticas de todos los partidos y la huella
  del mundo. ¿Se hace? (el banco `partido_porteros` vigila que no empeore). Además (A4-PAR-L02) el mejor club (media 71) contra el peor (48)
  promedia 7,7 goles y llega a 15-0 (`pruebas/ideas/a4_partido_cruzado.tscn`): el cociente de `_probabilidad` pesa demasiado entre divisiones.
- Solo tuyo, sin decisión de diseño: FPS en hardware real, builds, keystore (cambiar contraseña), licencias, derechos de imagen, música y voces, binarios al Drive (§1).

## 1. Lunes 26-10 — del dueño

- [ ] **Borrar la etiqueta `latest`** (las 8 ramas viejas ya no están, 27-10): `git push origin --delete latest`.
- [ ] **Quitar documentos y capturas viejos del historial de `main`**: ya reescrito en la rama de trabajo (530 rutas fuera, 802 → 682 MiB, árbol idéntico); falta empujarlo a `main` (el clasificador de permisos bloqueó el empuje forzado): añadir una regla de Bash o ejecutar tú, desde un clon espejo reescrito, `git push --force-with-lease=main:2f97059740f0b995ddc1b391ea3282eb26e345bd origin main:main`. Las ramas viejas y `respaldo-historia-2026-10-24` conservan todo lo borrado.
- [ ] Probar Foundry/Azure (200 USD, 30 días) y decidir si se usa.
- [ ] Abrir la red a Wikimedia/banderas (necesario para las caras que faltan: ~906 de 2.125 y escudos).
- [ ] **Perfil de FPS en hardware real** (M-337, P0): PC modesto (Intel UHD) y móvil; aquí solo hay render por software.
- [ ] Política de privacidad (`docs/05_referencia/POLITICA_DE_PRIVACIDAD.md`, es y en, con tu correo desde el 28-10): publicarla en una dirección web fija para las tiendas.
- [ ] Builds, keystore, licencias, derechos de imagen, música y voces (🔒). Cambiar la contraseña del keystore (la vieja sigue en el historial). Confirmar la fuente de los modelos 🟡 (Sketchfab, Meshy, mocap de Gumroad, Canva).
- [ ] Subir los binarios pesados (`recursos/`, `marca/`, `material/`) al Drive con `herramientas/drive_subir.ps1` y verificar. Respaldo de texto: `docs/05_referencia/RESPALDO_DRIVE.md`.

## 2. El guion: fases 0–6 (reestructuración)

**Calendario por fases** (cada una cierra con banco en 0 fallos + capturas con la cámara real)

| Fase | Contenido | Entregable |
|---|---|---|
| **1 — Entrada** | APROBADA el 26-10 (sin jugarla aún; «a futuro pulir»): capturas en `docs/04_auditorias/capturas_fase1/` | las fases 0-5 como pantallas completas |
| **2 — Prólogo 3D** | CONSTRUIDO el 26-10 (`escenas/prologo.tscn`, `visor/prologo*.gd`, `visor/pc_oficina.gd`; prueba `pruebas/ideas/f2p_prologo`, capturas `docs/04_auditorias/capturas_fase2/`). APROBADA el 26-10 (sin jugarla aún; «a futuro pulir»); límites en §2.2b | de «Nuevo juego» hasta tu primer día |
| **3 — Vida** | CONSTRUIDO el 26-10 (`visor/vida_ciudad.gd` + `visor/casa_dt.gd`, agenda del móvil, arranque en casa/oficina; pruebas `pruebas/ideas/f3v_vida` y `f3c_casa`, capturas `docs/04_auditorias/capturas_fase3/`). APROBADA el 26-10 (sin jugarla aún; «a futuro pulir»); límites en §2.2c | un día completo jugable en 3D |
| **4 — Personas** | CONSTRUIDA el 27-10 (`nucleo/citas.gd`, `visor/citas_ciudad.gd`, `nucleo/afinidad_club.gd`; Agenda con «Ir» y «Convocar rueda»; pruebas `f4p_citas`, `f4p_personas`, `f4r_rutinas`; capturas `docs/04_auditorias/capturas_fase4/`). Sin aprobar aún (27-10: «mejorar»); límites en §2.2d | negociaciones en persona |
| **5 — Club ampliado** | CONSTRUIDA el 27-10 (`nucleo/citas.gd`: ramas, copas y celebración; `visor/vestuario_vivo.gd`: futbolistas con nombre junto a su taquilla de 10 a 12; pruebas `f5c_club` y `f4p_personas`; capturas `docs/04_auditorias/capturas_fase5/`). Sin aprobar aún (27-10: «mejorar»); límites en §2.2f | |
| **6 — Pulido y auditoría** | pasos 4-7 de 7.1, limpieza del repo, vídeo | cierre y MEGAPLAN siguiente |

Cada fase tiene un documento de estado y se pasa a `main` con un PR cuando lo pidas.

---


### 2.1 El flujo y los sistemas nuevos

#### 3. La nueva estructura del juego (tu guion)

Hay dos formas de leerlo: **el flujo** (qué ve el jugador) y **los sistemas** (qué hay que
construir debajo). Primero el flujo.

#### 3.1 El flujo

| # | Etapa | Qué es | Notas |
|---|---|---|---|
| 0 | **Intro** | Animación de marca de ≤ 5 s antes de nada | pantalla completa, saltable tras la 1.ª vez |
| 1 | **Idioma** (interno: «menú inicial fase 0») | 9 idiomas | el vídeo de The Kion pasa a ser el logo animado |
| 2 | **Menú inicial** (fase 1) | Elegir modo; al pasar el cursor, el fondo cambia al estilo de ese modo | el logo animado aparece arriba a la derecha a los 20 s |
| 3 | **Globo** (fase 2) | Elegir país; nombre completo; fondo con bandera y 5 monumentos que rotan cada 30 s | si creas un club, no se muestran los demás |
| 4 | **Configuración del club** (fase 3) | Obligatoria: casa, FPS, visual, mascota, estilo de instalaciones, densidad de población y todo el submenú de personalización | confirmación al terminar |
| 5 | **Entrada al campeonato** (fase 4) | Reemplazar un club existente, o pagar a la confederación (menos presupuesto, peor reputación) | cifras validadas (2.3) |
| 6 | **Personaje** (fase 5) | Aspecto y datos | confirmación |
| 7 | **Prólogo 3D** | Aparece fuera del estadio; el mentor te enseña las instalaciones (todas menos tu oficina) y cómo moverte | es el tutorial de la ciudad |
| 8 | **Conocer a la gente y rueda de prensa** | Directivos con su oficina; sala de prensa nueva; te presentan y preguntan | gestos animados según tus respuestas |
| 9 | **Tu oficina** | PC funcional: ahí está el **menú central** actual; una tecla lo cierra | el juego se puede seguir desde el PC o caminando por el mundo |

Reglas de estructura que pides: cada etapa es **una pantalla propia a pantalla completa**,
con su estética, **no superpuestas**, **obligatorias** y con **confirmación al rellenar**. El
menú central deja de dar acceso a la ciudad (queda el estadio 3D), porque la ciudad pasa a
ser el mundo en el que vives.

#### 3.2 Qué existe ya para cada etapa

| Etapa | Pieza actual | Qué falta |
|---|---|---|
| Globo | pantalla de país hecha (nombre, bandera, 5 monumentos) | fotos libres de monumentos cuando se abra Wikimedia |
| Prólogo + mentor | `RecorridoClub`, `PersonalEstadio`, tutorial de la ciudad | guion del recorrido guiado físicamente |
| Rueda de prensa | `RuedaPrensaEscena3D` (897) ya es 3D | sala física en el estadio, gestos según lo que diga el jugador |
| Oficina + PC | `Principal` (el menú central) | objeto 3D que lo abre/cierra, aislarlo en una clase propia |

#### 3.3 Los sistemas nuevos (lo más grande)

| Sistema | Qué incluye | Depende de |
|---|---|---|
| **Reloj y agenda únicos** | un solo tiempo para menú central y mundo 3D; jornada laboral, horas extra, días libres, adelantar el día con el teléfono, esperar | base de todo lo demás |
| **Necesidades** | comer y dormir; si fallan, aumentan las posibilidades de que las cosas salgan mal | reloj |
| **Casa y familia** | dormir en casa, hablar con la familia, vida personal | reloj, necesidades |
| **Personas en persona** | directivos con oficina, jugadores, patrocinadores, políticos y funcionarios (ficticios), agentes, entrevistas de contratación en 3D, citas en la ciudad para fichar | reloj, diálogos |
| **Misiones y mensajes** | llegan por el PC o por el móvil; algunas exigen ir a un lugar de la ciudad | reloj |
| **Negociaciones** | en tu oficina, por mensaje o en 3D (mejor resultado en 3D) | personas |
| **Eventos de ciudad** | transporte público si el coche se avería, noche en la cárcel, llamar gente a tu oficina, incitarte a salir si juegas mucho desde el PC | reloj, ciudad |
| **Vestuario** | nombre de cada jugador en su taquilla y en la camiseta; futbolistas presentes a veces | datos de plantilla |
| **Otros deportes del club** | subequipos como personas reales: exigencias, celebraciones de título en el estadio, trofeo en la sala de trofeos | datos, estadio |
| **Redes y elecciones** | fotos con el teléfono y subirlas, interacciones, elecciones del club, convocar rueda de prensa | modo foto existente |

> **Reglas del proyecto que se mantienen:** política ficticia; no atribuir religión ni
> romances a jugadores reales; datos reales solo en `pack_real.json`.

---


### 2.2 Fase 0 real: separar `Principal` (validado por el dueño)

Fase 0 CERRADA el 26-10 (pasos 1-3 hechos: noticias, sorteos, preferencias, ciclo de partida, tutorial, Ajustes → `PantallaAjustes`, estilos → `EstilosMenu`; prueba `pruebas/ideas/f0_cimientos`). Quedan los pasos 4-7, que son de la fase 6.

#### 7. Código menos delicado (cómo se hace y cómo se comprueba)

#### 7.1 Partir `principal.gd` sin romperlo
Pasos 1-7 HECHOS el 27-10: `Principal` pasó de 6.867 a 1.438 líneas (meta < 1.500) con puentes de una línea; lo extraído vive en
`ui/pantallas/*`, `ui/menu/hubs.gd` y `ui/principal/*` (`ConstruirMenu`, `AvanceSemana`, `JornadaPartido`, `TemaMenu`, `PiezasUI`, `TablasMenu`,
`PedidoPartida`…), y 26 variables se mudaron a la clase que las usa. Queda: las ~105 variables de miembro compartidas (widgets que monta
`ConstruirMenu` y preferencias) siguen en `Principal`; repartirlas exige que cada pantalla reciba sus widgets en `abrir(contexto)` (§7.2).
Renombrar la cáscara a `MenuCentral` cuando el PC de la oficina sea la única entrada.

#### 7.2 Contratos y aislamiento
- **Un contrato por pantalla:** `abrir(contexto)`, `cerrar()` y una señal; nada de que una
  pantalla lea las variables de otra.
- **Estado de partida único** (`Mundo` + `Partida`): las pantallas leen, no guardan copias.
- **Validar al entrar:** datos de guardado con esquema y versión; migraciones explícitas
  (importante cuando cambie la estructura, sección 9).
- **Guardias de nodos liberados:** el estrés de menús del 17-10 encontró 3 errores de este
  tipo; se generaliza el patrón (`is_instance_valid`) en las pantallas nuevas.
- **Cierre ordenado y autoguardado** antes de cada transición larga (intro → inicio →
  prólogo → oficina) para que un fallo no pierda la partida.

#### 7.3 Pruebas
- Añadir `prueba_colisiones_club` y las del nuevo flujo a grupos de `mini_banco.sh`.
- Una prueba de **arranque completo** (intro → idioma → fases 1-5 → prólogo) con atajo de
  desarrollo para saltar etapas, para que el banco no se haga lento.

---


### 2.2b Fase 2 — Prólogo 3D: DISEÑO (26-10, compuerta 2 del método; construir en este orden)

**Flujo.** Al confirmar el personaje, `OrquestadorMundo.preparar()` devuelve la escena `escenas/prologo.tscn`
(`PrologoDT`) en vez de `principal.tscn` para los modos con club (dt, deportivo, ayudante, interinato, cantera,
dueño, jeque, crear, fondo); Retos, Tutorial y Carrera de Jugador siguen como hoy. «Saltar prólogo» con
confirmación (y `PROLOGO=0` para pruebas); al terminar se marca `prologo_visto` en la partida y se autoguarda.

**Escena.** La ciudad real del club (misma semilla y estadio que ya usa la ciudad) con `ExploradorCiudad` a pie.
| # | Paso | Qué pasa | Pieza que se reutiliza |
|---|---|---|---|
| 1 | Llegada | Plano de presentación (cámara baja del cielo, rótulo «Ciudad · Club», 4 s) y apareces en la acera frente a la puerta del club; el mentor (`Tutorial.mentor_de`) y el portero esperan | `EntradaClub`, `PersonalEstadio` (portero), `CuadroDialogo` |
| 2 | Moverse | El mentor enseña a moverse: 4 tarjetas (moverse, correr, cámara/primera persona, E) con las teclas reales (`Mando.corto_de`); aro en el suelo + flecha hacia el siguiente punto; cada punto se cumple al llegar (1,5 m) | tutorial de la ciudad, `MovilMano` |
| 3 | Recorrido | El mentor camina delante por las plantas del edificio (vestuario, túnel, campo, −1 enfermería y utilería, +1 despacho del presidente y sala de vídeo, +2 sala de prensa y comedor) y en cada sala dice 1-2 frases; el personal está en su puesto y saluda. **Tu oficina no se enseña aún** | `ExploradorEstadio`, `EdificioClub.PLANTAS`, `RecorridoClub.SALUDOS`, `ColisionClub` (ruta del mentor por la rejilla) |
| 4 | Directiva | En el despacho del presidente te presenta a la `Junta` (presidente + 2 directivos con cuerpo); una pregunta con 2 respuestas (ambiciosa / prudente) fija la primera impresión (confianza ±3) y queda en «Qué pasa» | `Junta`, `PersonalEstadio` (presidente), `CuadroDialogo.respuesta` |
| 5 | Prensa | Sala de prensa física (planta 2) → `RuedaPrensaEscena3D` de presentación con 3 preguntas de la rueda previa; el DT GESTICULA según el tono (seguro: manos abiertas; evasivo: mano al cuello; humilde: manos juntas) | `RuedaPrensaEscena3D._montar_gesto_dt`, `ui/principal/rueda_prensa.gd` |
| 6 | Tu oficina | El mentor te entrega la Oficina del DT («aquí mandas tú»); el PC de la mesa es interactivo: E → el menú central (`Principal`) se abre como capa encima del 3D (`PcOficina`); Esc o «Apagar» vuelve a la silla | sala «Oficina del DT» de `EdificioClub`, `Principal` (como capa, no como escena) |
| 7 | Cierre | Autoguardado, logro «Primer día», `prologo_visto`; la siguiente carga arranca en la oficina (la casa es de la fase 3) | `Partida`, `Logros` |

**Reglas.** Nada superpuesto: un cuadro de diálogo a la vez; el jugador siempre puede moverse salvo en el plano
de presentación. Mentor y directivos son ficticios (nombres de `Tutorial.mentor_de` / `Junta`). Textos con
`Idiomas.t` y traducción a los 8 idiomas con `sumar_traducciones.py`. Scripts nuevos < 450 líneas:
`visor/prologo.gd` (orquestación de pasos), `visor/prologo_mentor.gd` (NPC guía que sigue puntos),
`visor/pc_oficina.gd` (el PC que abre y cierra Principal), `visor/prologo_pasos.gd` (texto de cada paso).

**Hecho el 26-10 y límites honestos (lo que se verá al jugar):**
- El mentor no busca camino por el edificio: habla, «se adelanta» (da tres pasos y se esfuma) y te espera ya en la
  sala siguiente; la flecha del HUD y el aro en el suelo te llevan (con el ascensor si cambia la planta).
- Mientras el mentor habla el personaje se queda quieto (frases cortas); todo lo demás es libre.
- La directiva son el presidente del personal del club más dos accionistas de la `Junta` con cuerpo; una pregunta,
  dos respuestas (+3 / +1 de confianza).
- El PC enciende `Principal` como capa (el mundo 3D se esconde y se congela, no se destruye); la segunda vez lo
  retoma como partida cargada para no volver a escalar la caja por la dificultad. Pendiente: que al salir del
  juego desde el PC se guarde (hoy guarda al avanzar la semana y al encenderlo la primera vez).
- Rendimiento: la ciudad entera queda cargada bajo el menú central; en gama baja habrá que medirlo (fase 6).
- (26-10, tarde) El mentor del modo DT es el presidente REAL de la junta (antes salían dos presidentes distintos en el
  despacho); la cabecera de la rueda de presentación se aclara con el color del club; al encender el PC ya no sale la guía
  antigua del taxi (contaba otro primer día).

**Pruebas (modelo V).** Idea `f2p_prologo`: los 7 pasos en modo sin pantalla (cada punto del recorrido es
alcanzable con la rejilla de `ColisionClub`; el PC abre `Principal` y lo cierra sin dejar nodos; `prologo_visto`
queda en la partida; saltar funciona). Captura `f2p_captura_prologo` (7 tomas Forward+ con la cámara del paseo).
Compuerta de aceptación: capturas al dueño.

### 2.2c Fase 3 — Vida en 3D: DISEÑO (26-10, compuerta 2; construir en este orden)

**Lo que ya existe y se enlaza (no se duplica):** `Reloj` (día y hora dentro de la semana; la semana la sigue
mandando `Mundo.avanzar_semana()`), `Necesidades` (energía y hambre, modo completa/ligera/apagada en Ajustes → Vida),
`VidaDT` (vivienda, transporte, familia, estrés, ocio semanal), la Casa Grande de la ciudad (`CiudadExpansion._casa_grande`),
`CasaEscena3D`, el móvil (`Telefono`, `MovilMano`), el paseo (a pie, coche, metro, bus, interiores) y el PC de la oficina (fase 2).

| # | Bloque | Qué hace | Regla |
|---|---|---|---|
| 1 | Reloj vivo | La hora de la ciudad (`VistaCiudad._hora`, sol y farolas) ES la del `Reloj`; al caminar pasa el tiempo (1 min real = 10 min de juego; esperar en un banco ×6; dormir salta a las 08:00). El móvil enseña día y hora | el reloj nunca avanza la semana solo: al llegar al domingo noche o al pulsar «Avanzar semana» en el PC, `Mundo.avanzar_semana()` como siempre (misma huella) |
| 2 | Jornada | 09-18 en el club cuenta como trabajo (tasas de `Necesidades`); después de las 18, horas extra: +preparación (`VidaDT.balance`) y +estrés; sábado y domingo sin partido = día libre | lo que ya hace `VidaDT` semana a semana, ahora alimentado por horas de verdad |
| 3 | Necesidades aplicadas | Comer: comedor del plantel (planta 2), tu casa o un kiosco de la ciudad; dormir: tu cama. Energía < 20 → `factor_riesgo` entra en la semana (`probabilidad_de_fallo`, ya escrito) y el médico avisa; energía 0 en la calle → despiertas en casa con estrés y un titular | sin castigos definitivos; «Vida: ligera/apagada» lo suaviza o lo quita |
| 4 | Casa y familia | Entrar a tu casa (la Casa Grande hoy; la vivienda de `VidaDT` después): salón, cocina, dormitorio; pareja, hijos y mascota con cuerpo (`VidaDT.perfil`) y 2-3 frases según `familia`; cama (dormir), mesa (comer), sofá (ocio de la semana) | gente ficticia; nada de religión ni política |
| 5 | Teléfono | App «Agenda»: día, hora, próximo entrenamiento/partido/rueda; «Adelantar»: 1 h, hasta mañana, hasta el partido; mensajes que piden ir a un sitio (la fase 4 los llena) | el teléfono adelanta el reloj con la rutina (`Reloj.RUTINA`) para que las necesidades no se disparen |
| 6 | Transporte y sucesos | Coche propio según `VidaDT.transporte` (con «micro», solo bus y metro); avería semanal por hash → transporte público; conducir a lo loco (3 choques con multa) → noche en el calabozo: lunes con −3 de confianza y titular | todo reversible en una temporada |
| 7 | Arranque del día | Tras el prólogo, cada carga empieza en la oficina; con la casa hecha, cada lunes empiezas en casa a las 08:00 y vas al club como quieras (o «ir directo» desde el móvil) | «Vida: apagada» = empiezas en la oficina con el PC |

**Hecho el 26-10 y límites honestos (lo que se verá al jugar):**
- Reloj vivo: `VidaCiudad` (colgado del explorador cuando hay partida) hace pasar 1 minuto de juego cada 6 s reales
  mientras paseas (en pausa, PC o móvil no corre); la luz de la ciudad (`VistaCiudad._hora`) ES la del reloj y la vuelta
  de 2 minutos queda apagada. La hora va en el HUD («🕒 Martes 10:40») y en el móvil de la mano. «Esperar en un banco ×6»
  no está (no hay bancos usables); el móvil lo cubre con «Adelantar».
- Jornada: en el club de lunes a viernes 09-18 cuenta como trabajo y 18-23 como horas extra (+1 preparación y +1 estrés
  por hora); el fin de semana en el club es libre (no distingue aún día de partido).
- Comer: comedor del plantel (planta 2, E), tu casa (mesa) o un bar/panadería/mercado de la ciudad (E dentro cuando no
  hay nadie al lado; se sale por la puerta). Dormir: tu cama (salta a las 08:00). Energía a cero fuera de la cama →
  despiertas en casa con +6 de estrés y un titular pendiente; los avisos de cansancio/hambre salen por el móvil.
- Casa: la Casa Grande se abre por dentro con E desde la verja (`CasaDT`: salón de la vivienda de los interiores +
  dormitorio, pareja/hijos/mascota de `VidaDT.perfil`, 2-3 frases por estado de la familia, +1 de familia la primera charla
  del día). Es la Casa Grande para todos: la vivienda de `VidaDT` (pensión… mansión) todavía no cambia la casa 3D.
- Teléfono: la T del paseo abre el móvil de siempre con la app «Agenda» (día, hora, próximo entrenamiento/partido/rueda;
  adelantar 1 h / hasta mañana 08:00 / hasta el partido, siempre con la rutina de `Reloj`: no dispara el hambre). No hay
  todavía mensajes que te citen a un sitio (fase 4).
- Transporte y sucesos: «Conducir» del menú sale a pie si `VidaDT.transporte` es «micro» o si toca avería (1 semana de
  cada 8, por hash); 3 multas por conducción temeraria = noche en el calabozo (−3 de confianza y +4 de estrés una vez por
  semana, titular, amanece a las 08:00). No hay comisaría 3D: es un fundido.
- Semana: dormir el domingo por la noche llama a `Mundo.avanzar_semana()` (el mismo camino que el PC) y amanece el lunes;
  si el PC estaba encendido alguna vez, su menú se refresca. La huella se compara por procesos (`huella_mundo.tscn`): dos
  mundos iguales avanzados en un mismo proceso no coinciden ni desde el menú (estado estático del motor).
- Arranque del día: «Continuar» y «Abrir partida» con el prólogo visto entran en 3D: el lunes a las 08:00 en tu casa, el
  resto del tiempo en la oficina con el PC; con «Vida: apagada» siempre la oficina. La ciudad tarda en construirse
  (pantalla de carga): en gama baja habrá que medirlo (fase 6).

**Pruebas (modelo V).** Idea `f3v_vida`: al caminar el reloj avanza; comer y dormir mueven las necesidades; dormir el domingo
avanza la semana con la MISMA huella que el menú (`huella_mundo`); la casa tiene a la familia y sus tres usos; el móvil
adelanta sin disparar el hambre; la avería saca el coche y el calabozo resta confianza una vez. Captura `f3v_captura_vida`
(casa por dentro, familia, cama, comedor, móvil con agenda, amanecer en la ciudad).

### 2.2d Fase 4 — Personas en persona: DISEÑO (26-10, compuerta 2; construir en este orden)

**Lo que ya existe y se enlaza (no se duplica):** `Junta` (presidente y accionistas, `resolver(op)`), `Comercial` (ofertas de
zona y proveedor: `generar_ofertas_zona`, `firmar_zona`), `MercadoAvanzado` y `Negociacion` (ofertas por jugador),
`MesaAgente` (regateo con 4 perfiles), `Politica` (gobiernos ficticios por país, `semana_votacion`), `Prensa` (ruedas,
titular pendiente), `Redes` (`publicar`, `responder`), `ModoFoto`, el móvil (`Movil.chats()`, Mensajes, Agenda), las
personas con cuerpo del prólogo (`PrologoMentor`: nombre, cargo, semilla) y del estadio (`PersonalEstadio`, `RecorridoClub.
dialogo`), la flecha del HUD del prólogo y el reloj (`Reloj`, `VidaCiudad`).

| # | Bloque | Qué hace | Regla |
|---|---|---|---|
| 1 | Citas y mensajes | `nucleo/citas.gd`: una cita = {quién, dónde (sala del estadio o punto de la ciudad), día y hora, asunto, tipo}. Nacen de lo que ya pasa cada semana: asunto de la `Junta` → el presidente en su despacho; oferta de zona de `Comercial` → el patrocinador en su sede (un `edificio_oficina` con rótulo); oferta de `MercadoAvanzado` → el agente en un bar; semana de votación de `Politica` → el funcionario en el ayuntamiento; semana con rueda → la entrevista en el plató. Llegan por Mensajes del móvil («Ir» = flecha del HUD) y salen en la Agenda | máximo 3 citas por semana y 1 por persona; si no vas, la cita caduca el domingo sin castigo (la oferta sigue su curso por el PC como hoy) |
| 2 | Personas con cuerpo y horario | Cada cita pone a la persona con cuerpo en su sitio solo en su horario (`Reloj`: 10-18 laborables; el agente de 18 a 22 en el bar); fuera de hora, el sitio está vacío y el móvil lo dice | gente ficticia (nombres de la `Junta`, `Comercial`, `MesaAgente`, `Politica.nombre_ficticio`); misma semilla = misma cara siempre |
| 3 | Negociar en persona | En la cita, el mismo `Negociacion`/`MesaAgente` de siempre con `CuadroDialogo` y opciones. En persona: el precio pedido baja un 5 % y la probabilidad de aceptar sube 10 puntos; por mensaje/PC, como hoy | nunca mejor que el tope del club ni por encima de la caja; una negociación por cita |
| 4 | Entrevistas de contratación | Al fichar a un jugador o a alguien del staff, entrevista de 3 preguntas en tu oficina (tonos seguro/evasivo/humilde, como la presentación): afinidad inicial ±2 de moral y el grupo del `Vestuario` al que entra | opcional: «Saltar» = fichaje como hoy, sin bono ni castigo |
| 5 | Patrocinadores y políticos | Firmar una zona en persona: +5 % de renta esa temporada (`Comercial.firmar_zona` con bono) si llegas a la hora. Votación: el funcionario pide apoyo público; aceptar = declaración en la rueda (+relación con el gobierno de `Politica`, −2 con la prensa crítica); negarse = nada | política 100 % ficticia; sin partidos ni personas reales |
| 6 | Redes, fotos y elecciones del club | Foto del `ModoFoto` → la app Fotos la publica en `Redes` con hashtags; «Convocar rueda de prensa» desde el móvil (máximo 1 extra por semana). Elecciones del club cada 4 temporadas (o con confianza < 25): asamblea en el salón de actos con 3 discursos (tonos) y voto de socios + junta; perder = sigues de DT con otro presidente (nuevo `Junta.presidente`, objetivo nuevo) | nada definitivo: no te echan por las elecciones |
| 7 | Rutinas y vida de las personas | Los directivos pasan por el estadio en su horario (despacho, palco los sábados); el personal del club saluda por nombre y recuerda la última charla (`PersonalEstadio` + afinidad 0-100 que sube por charla diaria y baja por semanas sin hablar) | afinidad solo cambia textos y una frase de pasillo; sin efectos en el partido |

**Hecho el 26-10 (bloques 1-4 y parte del 6) y límites honestos:**
- `Citas` nace cada semana en `Mundo._semana_modulos_del_club` (y en la primera al generar): junta abierta → presidente en su
  despacho (martes 11:00); zona con ofertas → la marca que más paga en el centro comercial (miércoles 16:00); superagente →
  terraza de la Plaza Mayor (jueves 19:00); semana antes de la votación → gabinete del alcalde en el ayuntamiento (viernes 12:00).
  Máximo 3 por semana, 1 por tipo; caducan al cambiar de semana; mensaje en el móvil y fila en la Agenda con «Ir».
- En 3D (`CitasCiudad`, colgado de `VidaCiudad`): flecha del HUD del prólogo hacia la cita marcada (dice «entra al estadio» /
  «sal a la calle» / la planta); la persona (cuerpo `PrologoMentor`, misma cara por nombre) aparece solo en su hora (2 h) y
  si estás en su mismo mundo a < 90 m; E a < 2,2 m abre el panel de dos respuestas; al responder se va andando.
- Resolver = lo de siempre + bono: junta `Junta.resolver` +1 de confianza; patrocinio `firmar_zona` +5 % de renta; agente deja
  un «favor» (`Citas.favor_agente`, el −5 % en su próxima mesa se aplica en el bloque 3); política: apoyo anotado en el
  gobierno y −2 con la prensa crítica.
- Bloque 3: con el favor del agente de la semana, `Negociacion` divide lo pedido por 0,95 y baja el umbral 0,10
  (`descuento_persona`, `bono_persona`); `MesaAgente` (los representantes de la cantera) no lo aplica aún.
- Bloque 4: al cerrar un fichaje (`Negociacion._cerrar_fichaje`) el nuevo te cita mañana a las 10:00 en tu oficina; tres
  tonos: seguro +2 de moral, evasivo −1, humilde +1. Si no vas, caduca sin efecto. El cuerpo es genérico (cara por nombre),
  no el modelo del jugador (fase 5).
- Bloque 6 (parte): las fotos del modo foto se publican desde la app Fotos como «paseo» en `Redes` (tipo nuevo, +seguidores).
- «Convocar rueda de prensa» desde la Agenda del móvil (`Citas.convocar_rueda`: una extra por semana, guion neutro, se
  responde en el PC). Bloque 7 hecho por la ejecutora (`nucleo/afinidad_club.gd`, saludos por tramo en el pasillo).
- Asamblea de socios (bloque 6, 27-10): el sábado de la semana 3 cada 4 temporadas (o cualquier temporada con la confianza
  < 25), en el salón de actos; tres discursos; votos = 40 + (ánimo de la grada − 50) × 0,5 + (confianza − 50) × 0,3 + tono
  (seguro ±, humilde + si la grada está en contra); perder cambia al presidente de la `Junta` y la confianza vuelve a 50 (tú
  sigues); ganar da +2. Determinista, sin `Azar`.
- Pendiente de la fase 4: los sitios de la ciudad son
  fijos (no hay «sede» propia por marca); las personas de las citas usan el cuerpo genérico (cara por nombre).

**Pruebas (modelo V).** Idea `f4p_personas`: un asunto de la junta genera una cita con mensaje y aparece en la Agenda; a la hora,
la persona está en su sitio (fuera de hora, no); negociar en persona aplica −5 %/+10 y por PC no; firmar una zona en persona
da el +5 %; la entrevista mueve ±2 de moral; publicar una foto suma seguidores; la asamblea cambia el presidente al perder
y nada más; las citas caducan el domingo sin castigo. Captura `f4p_captura_personas` (mensaje con «Ir», patrocinador en su
sede, agente en el bar, asamblea, foto publicada).

### 2.2f Fase 5 — Club ampliado: DISEÑO (27-10, compuerta 2; construir en este orden)

**Lo que ya existe y se enlaza:** taquillas con dorsal y nombre de la plantilla (`TunelVestuario`), museo con una copa por
título (`SalasClub.museo`, `ctx["titulos"]` en `Principal`), ramas de otros deportes que juegan su temporada y dejan palmarés
(`Hinchada.RAMAS`, `temporada_ramas`, `palmares_ramas`), trofeos de la directiva (`Directiva.trofeos`), citas en persona
(`Citas`), cuerpos genéricos (`PrologoMentor`) y los clips de la UAL (`AnimExtra.asegurar`).

| # | Bloque | Qué hace | Regla |
|---|---|---|---|
| 1 | Vestuario con vida | Laborables de 10 a 12 (reloj), 3-5 futbolistas con cuerpo junto a su taquilla (nombre y dorsal de la plantilla real; cara por nombre, no el modelo del jugador hasta tener retratos 3D en el paseo); E = frase según su moral y rol; «charla» de la UAL | solo textos: nada cambia en el partido |
| 2 | Las ramas como personas | Una cita por temporada (semana 5) con la coordinadora de cada rama abierta: pide presupuesto (10 % del coste anual) o visibilidad (un partido en el estadio); aceptar sube la fuerza de la rama esa temporada (+0,06 en `temporada_ramas`) y cuesta caja; negar no castiga | ficticio; sin religión ni política |
| 3 | Trofeos de verdad | El museo cuenta también los títulos de las ramas (puesto 1 en `palmares_ramas`); cada título nuevo añade su copa y una placa con el año | el museo lee `ctx["titulos"]` + ramas |
| 4 | Celebraciones | Título de liga o copa del primer equipo: cita «celebración» el lunes siguiente en el museo con el presidente (copa nueva, foto para Tribuna) y, en el estadio, vuelta olímpica de la plantilla con confeti al entrar al campo esa semana; título de una rama: la rama celebra en el museo y sale en portada | una vez por título; reversible |

**Hecho el 27-10:** bloque 1 `VestuarioVivo` (colgado de `CitasCiudad`): laborables de 10 a 12, 4 futbolistas (dorsal más bajo)
en chándal del club junto a las taquillas, nombre y «dorsal · puesto» en el rótulo, E = frase por moral (3 tramos × 3) con el
clip de charla; fuera de horario el vestuario queda vacío. Límite: cara por nombre (no el retrato 3D del jugador) y posiciones
aproximadas a lo largo de las paredes, no taquilla por taquilla.
**Bloques 2-4:** cita «rama» en la semana 5 por cada rama abierta (coordinadora ficticia, +10 % del coste
anual → `Hinchada.bono_rama` = +0,06 de fuerza esa temporada); el museo cuenta las copas de las ramas (`Principal._ctx_club`);
cita «celebración» el lunes siguiente a un trofeo nuevo del primer equipo (presidente en el museo; levantar la copa publica
«victoria» en Tribuna y sube 3 el ánimo). Límites: no hay todavía vuelta olímpica en el campo ni celebración 3D de las ramas
(bloque 4, parte); el presupuesto de la rama no tiene efecto visible fuera del puesto final. (30-10) La rama pide también visibilidad (un partido en el estadio) y sus títulos tienen su cita de celebración en el museo (`CitasRamas`).

**Pruebas (modelo V).** Idea `f5c_club`: en horario de vestuario hay cuerpos con nombres de la plantilla y fuera de horario
no; la cita de la rama cuesta caja y sube la fuerza; un título de rama suma una copa al museo; el título del primer equipo
crea la cita «celebración» y la vuelta olímpica se activa una sola vez. Captura `f5c_captura_club` (vestuario con gente,
museo con copas, celebración).

#### 2.2f-bis El museo que crece (orden del dueño 27-10) — HECHO, falta el veredicto del dueño
Construido en tres pasos (`MuseoAmpliado`, `MuseoAmpliadoAnim`, `SalasClub.vitrina`; prueba `f5c_club` ampliada; capturas `f5d_captura_museo` en `docs/04_auditorias/capturas_museo/`):
la sala de la planta 2 tiene una vitrina por título hasta seis; con el museo a nivel 5 (obra «Museo del club» de siempre, no una obra nueva) el ascensor
suma la planta 3 «Museo ampliado» (copas del séptimo título en adelante, panel de hitos, camisetas por década, balón de la primera copa); mientras la obra del
nivel 5 está en marcha la planta 3 sale con andamios y lona; la primera vez que se entra tras terminarla, el rótulo «Museo ampliado · N títulos» y las copas
se iluminan una a una (lo visto se guarda en los ajustes, no en la partida). A mejorar si el dueño lo pide: fundido de pantalla real, pared de camisetas con
equipaciones de verdad por década y más de 10 copas en la planta 3.

### 2.2g Redes de la ciudad y subsuelo (sesión 3): luz, agua, drenaje y gasolineras (pedido del dueño, 27-10) — CONSTRUIDO, falta mirarlo
`nucleo/redes_ciudad.gd` (modelo por horas, 25 sectores de 6x6 celdas; prueba `_probar_redes_ciudad` del banco) y
`visor/redes_ciudad_vista.gd` (dibujo; prueba `ideas/red_redes_3d`). Cuelga de `CiudadExpansion.redes`; `VidaCiudad` lo avanza
cada hora del `Reloj` con el clima de la semana (viento mueve el parque eólico, lluvia llena los colectores).
- Luz: parque eólico + central de respaldo; en hora punta sin viento se cortan sectores por turno (el hospital no); torres de
  alta tensión, subestación, transformadores con lámpara verde/roja y farolas que bajan con la fracción sin corriente.
- Agua: potabilizadora → depósito; sin luz o con rotura el sector pierde presión. Drenaje: sumideros y tapas; tormenta o
  sumideros atascados inundan el sector (lámina de agua). Gas: 3 gasolineras con depósito y cisterna; E en el surtidor = 45 l, 63 €, 10 min.
- SUBSUELO (easter egg, pedido del dueño 27-10): cinco tapas de alcantarilla con aro de óxido (E de pie sobre ellas) bajan a
  `visor/subsuelo_ciudad*.gd`: colector con canal de agua y ratas, galerías de luz (armarios con el estado de 4 sectores), agua y gas,
  sala de control (pantalla con `resumen()`, botón de reparar averías y palanca roja que corta la luz del sector de arriba) y un
  cuarto olvidado. Estado `subsuelo` del explorador; capturas en `docs/04_auditorias/capturas_subsuelo/` (escena `pruebas/captura_subsuelo`,
  corre con `xvfb-run … --rendering-driver opengl3`, SIN_LUZ=1 para el modo emergencia). Hecho en Compatibility: falta mirarlo en Forward+.
- CENTRO DE MANDO Y EVENTO (27-10, 2.ª pasada): tres pantallas reales (`visor/panel_mando.gd`: mapa sinóptico, curvas de 24 h, alertas
  y tabla de edificios) en la sala de control; sala de acometidas con un armario por edificio REAL (19: club, hospital, ayuntamiento…;
  consumo, luz, agua, rumbo y distancia desde la tapa; E aísla/restablece) y esos edificios consumen de verdad en `RedesCiudad`
  (hospital, comisaría y bomberos con generador). EVENTO «Apagón de tormenta» (`nucleo/evento_apagon.gd`): semana de tormenta, 20:00,
  60 %: dos sectores sin luz; móvil avisa, abajo hay que REARMAR el cuadro general (galería eléctrica) y RECONECTAR (botón verde) →
  titular «bien»; si nadie baja, la cuadrilla arregla a las 08:00 (titular «mal»). Detalle: hormigón texturado, franjas de peligro,
  abrazaderas, charcos, extintores, salidas, marcos por red, ventiladores y goteras. Capturas con `EVENTO=1` en la escena de captura.
  PENDIENTE: los edificios de la superficie no cambian de aspecto con el corte (solo farolas); sonido ambiente; Forward+.
- Hecho 27-10 (3.ª pasada): las redes se GUARDAN en la partida (`Mundo.redes_ciudad`, clave `redes_ciudad`; partida vieja = nuevas; ida y vuelta
  probada) y el móvil avisa de cortes e inundaciones nuevos.
- Hecho 27-10: coche con depósito real (`VidaDT.combustible`, 45 l, 2,5 l/km; se guarda): vacío no arranca hasta repostar con E en un surtidor; aviso en el móvil al bajar del 15 % (una vez por semana, `aviso_comb` guardado). Las averías se guardan (`cortes`); la cuadrilla se deriva de ellas.
- Hecho 27-10 (transporte, pedido del dueño): MAPA del transporte (`visor/mapa_transporte.gd`, tecla N en la calle: completo / autobuses / metro; capturas `capturas_transporte/mapa_*.jpg`); autobuses con NÚMERO (5 anillo, 10, 22, y dos líneas de barrio nuevas: 7 y 3) y placas; coches menos infantiles (`CocheDetalle` + `coche_real.gdshader`: paleta apagada, cristales oscuros, faros, retrovisores, placas «AB 123 CD»); transbordo del metro en el cruce real; CERRO de 420 m al sureste (`CityBuilder.MONTE_*`) con el TELEFÉRICO (`visor/teleferico.gd`: 2 estaciones, 5 torres, 2 cabinas por cable; E en la base sube al MIRADOR, `visor/mirador_cerro.gd`, 12 min de juego; estado «cima»). Cabina del coche rehecha (`visor/cabina_coche.gd`: salpicadero con esferas y pantalla, consola, puertas, techo, volante de cuero; antes/después en `capturas_transporte/cabina_*.jpg`), el coche del DT con pintura y placa, y el tren del metro con acero inoxidable, bogies, equipos de techo, marcos de puerta y rótulo (`visor/tren_detalle.gd`). PENDIENTE: ventanillas y retrovisores laterales de la cabina (hoy sin vista trasera), vista del conductor del metro, nieve/árboles en el cerro, revisar todo en Forward+.
- Hecho 27-10 (transporte): en los andenes del metro la gente de pie espera con el móvil, hablando por teléfono o quieta (`PeatonVida.en_anden`); los pilares y el tablero del viaducto son de hormigón con manchas; los autobuses del anillo paran 10 s en las 4 marquesinas (`CityBuilder.paradas_bus_pos`) y a los 3 s de parar sube y baja gente en los bancos de al lado (`GenteSentada.vigilar_buses`: cambia quién está sentado, y caminan de verdad hasta/desde la puerta (`GenteSentada.embarque`: 1 sube, 2 bajan, se borran al llegar). Prueba `ideas/tre_transporte`. Cerro: 950 pinos, camino ancho, rocas (`teleferico_paisaje.gd`). PENDIENTE: capturas finales del embarque.
- Hecho 27-10: ESTACIÓN CENTRAL real (`visor/estacion_central.gd`, kit `kenney/tren`): vestíbulo con bóveda, andén isla con marquesina, dos vías con topes y túnel cubierto al norte; dos trenes de 3 coches que entran, esperan, retroceden al túnel y dejan la vía vacía (ciclo de 70 s reales ≈ 10 min de juego, desfasados). Capturas en `docs/04_auditorias/capturas_estacion/` (Compatibility). Retoques 2.ª pasada: boca de túnel oscura con marco de hormigón texturado, fachada con puertas de cristal (`FachadaModular`), reloj de fachada con la hora del juego, parada de taxis y marquesina; trenes por el RELOJ (sin servicio 01-05 h) y pasajeros sentados en los bancos del andén (`GenteSentada`). PENDIENTE: vía de salida real fuera de la ciudad y pasajeros de pie que suban/bajen.
- Hecho 27-10: averías visibles: una cuadrilla (camión, conos y baliza) junto a la tapa central de cada sector con avería abierta; desaparece al repararse (`RedesCiudadVista._cuadrillas`).
- Hecho: sonido ambiente del subsuelo con efectos ya existentes (zumbido «noche_estadio» y gotas «clic_suave»; sonidos propios, pendientes).
- PENDIENTE: camión cisterna;
  apagón por sector en las VENTANAS (las farolas ya van por sector desde el 27-10: `ciudad_expansion._farolas_sec`, capturas `apagon_sector_*`); cables con caída;
  

- FORWARD+ DEL APAGÓN VISTO (27-10, líder): `pruebas/ideas/p_captura_apagon.tscn`, de noche y con la ciudad entera; con 4 sectores cortados
  sus farolas Y LAS VENTANAS de esos sectores se apagan y el resto sigue (`capturas_subsuelo/forward_apagon_ciudad_{antes,despues}.jpg`):
  `fachada_torre.gdshader` lee un mapa 5x5 de corriente (`CiudadExpansion.textura_luz`, una textura compartida: sin draw calls nuevos)
  en las torres del núcleo y en los edificios lejanos. Las casas y piezas del kit con ventanas propias no siguen aún al sector.
### 2.2h Dinero en la ciudad: cartera, bancos, cajeros, gasolinera «por arriba», peluches, servicios públicos y coches (pedido del dueño, 27-10) — SOLO DISEÑO, sin código hasta el OK del líder
Pedido del dueño (27-10): máquinas de peluches solo en UNA zona y que FUNCIONEN (él trae más decoración de ese estilo); la gasolinera «por arriba»
(lo que vende) funcional y unida al coche, con la sesión de redes haciendo el sistema de gas «por debajo»; sistema de pago con tarjeta física,
bancos y cajeros; policía, bomberos y servicios públicos; mejorar el sistema de coches. Esto es lo que hay hoy y cómo se parte en piezas.

**Lo que ya existe (medido el 27-10)**
- Repostar: `VidaCiudad.usar_surtidor` (E ante un surtidor) pide `redes.modelo.repostar(id, sector, litros) -> {litros, coste}` (sesión de redes, 1,4 €/l, sin
  corriente no hay bomba), avanza 10 min y COBRA AL CLUB (`mundo.mi_club().mover_saldo`), no al bolsillo del DT. Depósito `VidaDT.combustible` (45 l, 2,5 l/km).
- Dinero personal: `Roles.patrimonio` (casa, transporte y mudanzas lo gastan en `VidaDT`). Dinero del club: `Club.saldo`. Hoy NO hay efectivo, tarjeta ni cuenta.
- Gasolinera visual (`CiudadGasolinera`): marquesina, islas, tienda con fachada y mástil de precio; la tienda es decorado (no se entra ni se compra).
- Peluches: `CiudadArcade` pone 3 máquinas (`maquina_peluches.glb`, 893 KB) ante el centro comercial; son decorado. Los 14 peluches del zip NO están en el repo.
- Servicios: `CiudadServicios` pone bomberos (2 camiones + ambulancia), comisaría y hospital como edificios; ningún vehículo sale, no hay incidentes.

**Decisiones del dueño (propuesta mía entre paréntesis; 1 y 2 aprobadas por el líder el 27-10; 3-5 esperan al dueño)**
1. ¿De quién es el dinero de la gasolina y las compras? (DEL BOLSILLO DEL DT: `Roles.patrimonio`; el club paga solo lo del club). Hoy cobra al club: es un fallo de diseño.
2. ¿Moneda única en euros y una sola cartera? (sí; efectivo + una cuenta + una tarjeta de débito; crédito más adelante).
3. ¿Los peluches se pagan con fichas o con dinero? (monedas de 1 €; sale del efectivo, no de la tarjeta, para empujar a usar el cajero).
4. ¿Qué zona de recreativas se queda? (la del centro comercial; las otras dos máquinas se quitan, pasan a una sola sala con 3 máquinas funcionales).
5. ¿Los peluches nuevos (14 del zip) se suben al repo reducidos a 256 px (~100 KB cada uno, como la máquina)? (sí: es una subida de binarios nueva; hace falta su OK por la regla de LFS; van fuera de LFS con excepción).

**Piezas, en orden de construcción** (cada una = una entrega pequeña con prueba en el banco, captura Forward+ y traducciones con `sumar_traducciones.py`)
- **A. Cartera — HECHA el 27-10 (modelo + guardado + `_probar_cartera_dt`; falta la pantalla «Cartera» del móvil y el objeto en la mano)** (`nucleo/cartera_dt.gd`, sin visor): efectivo, saldo de cuenta, tarjeta (número, PIN de 4 cifras, bloqueada sí/no, límite diario), movimientos (últimos 30).
  Guardado en la partida (clave nueva, partida vieja = efectivo = 0 y cuenta = `patrimonio` actual). Prueba: ida y vuelta, no se puede gastar más de lo que hay, `patrimonio` = efectivo + cuenta.
  La tarjeta física: objeto en la mano del DT (modelo simple, textura con el escudo del club) que se ve en el móvil (pantalla «Cartera»).
- **B. Bancos y cajeros — CAJEROS HECHOS el 27-10** (`visor/cajero_ciudad.gd`, `ui/componentes/panel_cajero.gd`: teclado de PIN, retirar 20/50/100/200, ingresar, cambiar el PIN, comisión de 2 € en banco ajeno, bloqueo; tres puestos: gasolinera, centro comercial y plaza; capturas `capturas_ciudad_c2/cajero_*`). **SUCURSAL HECHA (27-10): ventanilla «Banco Andino» bajo los soportales de la plaza mayor (`visor/ciudad_banco.gd`, `BancoCiudad`, `PanelCajero` en modo ventanilla: sin PIN, desbloquea la tarjeta, restablece el PIN, ingresa el efectivo y enseña los 5 últimos movimientos; `CarteraDT.restablecer_pin`). FALTAN más cajeros (hospital, universidad, estación, estadio) y un edificio de banco propio (hoy es una ventanilla en un soportal)** (`visor/ciudad_banco.gd`): una sucursal con fachada modular y cajeros en la fachada y en la gasolinera, el centro comercial y la estación. E en el cajero:
  retirar / ingresar / ver saldo / cambiar PIN; límite diario; comisión si el cajero es de otro banco (3 bancos ficticios, nombres inventados); sin corriente en el sector (`redes`) el
  cajero muestra «fuera de servicio». Interior de la sucursal (mostrador y ventanilla) solo si sobra tiempo.
- **C. Gasolinera por arriba — HECHO el surtidor (27-10: cobra efectivo y, si no, tarjeta sin contacto ≤100 €, ya no al club; `VidaCiudad.usar_surtidor`); CAJA DE LA TIENDA HECHA (27-10: `PanelTienda` con seis artículos, `VidaCiudad.comprar_surtido`; el PIN se pide en cajeros, no en el comercio: hasta 100 € paga sin contacto)** (`visor/gasolinera_tienda.gd`): E en la tienda abre una caja: comprar lo del surtido (`kenney/comida`: bebidas, bollería, bocadillos; sube la «energía» del DT un poco),
  pagar con tarjeta (PIN) o efectivo. El surtidor deja de cobrar al club y cobra con la misma caja; elegir combustible (dos precios, que salen de las existencias de `redes`).
  CONTRATO con la sesión de redes: ella conserva `repostar(id, sector, litros) -> {litros, coste}` y los precios; yo solo hago la pantalla, el cobro y la tienda. Si cambia esa firma, me avisa.
- **Semana 6 (27-10, pedido del líder): MÁQUINAS EXPENDEDORAS y BALÓN SUELTO — HECHO en el centro comercial y la gasolinera** (`visor/expendedora_ciudad.gd`, `nucleo/expendedora.gd`, `Necesidades.animar`: cobran de `CarteraDT` y suben la energía; gancho único `ComercioCiudad.servicio`). Balón suelto en el parque más cercano (`visor/balon_suelto.gd`: gravedad, bote, rozamiento, rebote en los bordes; se patea andando, no en coche). **Hechas también (27-10, tras el OK del líder): andenes del metro (`MetroCiudad.expendedoras` + `_usar_en_anden`), estación central (junto a las puertas), estadio (exterior a la izquierda de la puerta del club y en el pasillo de la sala de prensa, `EdificioClub.expendedoras` + `VidaCiudad.usar_en_estadio`).** Capturas: `capturas_ciudad_c2/expendedora_estadio_exterior.jpg` y `expendedora_sala_prensa.jpg`. Pendiente: ver la de la estación a pie y el aviso «E: comprar» en la calle y en el estadio (en el metro ya sale).
- **D. Peluches — HECHA la parte jugable (27-10)**: `nucleo/peluches.gd` (tabla `PELUCHES` de 14 con series, máquina, peso, forma, color y `modelo`/`escala` donde enchufar los .glb del dueño; álbum y 5 logros: uno por serie y uno por la colección; guardado en `Roles`), `ui/componentes/panel_peluches.gd` (vista cenital de la garra: moneda de 1 € del EFECTIVO, A/D/W/S o flechas, espacio; probabilidad por peso y distancia, con ayuda tras cada fallo), `visor/peluches_ciudad.gd` (puntos `peluches_0..2` en las 3 máquinas de `ciudad_arcade.gd`, gancho de la E, estantería del álbum en la vivienda) y `visor/peluche_modelo.gd` (relleno con esferas hasta tener los modelos); resumen y logros en la app Banco del móvil. Falta: los 14 modelos reales (cuando el dueño pueda bajarlos del Drive y se apruebe subirlos reducidos) y ver la sala en la ciudad entera. Diseño original:
  (`visor/ciudad_arcade.gd` + `visor/peluches_ciudad.gd`): UNA sala, tres máquinas. E ante la máquina: meter moneda (1 €), mover la garra con A/D/W/S, bajar con espacio;
  la garra agarra con probabilidad que baja con el peso/tamaño del peluche y sube un poco en cada intento fallido (para no ser imposible); el premio cae al buzón y va a un
  baúl en casa del DT. Los 14 peluches del zip (reducidos) se reparten en las tres máquinas; las decoraciones nuevas del dueño se suman con una tabla (`PELUCHES`).
- **E. Policía y bomberos** — HECHO (27-10, ver `ciudad_26_10.md`). Falta: verlo
  en la ciudad ENTERA con la cámara del juego (solo hay capturas de calles de prueba) y que el accidente y el robo tengan más detalle (peatones mirando, un sospechoso).
- **F. Coches mejor**: primero una AUDITORÍA del coche actual (`motor_jugable*`, `trafico_ciudad*`: cuántos sub-pasos, colisiones, aparcar, marchas) y de los peatones; luego tres mejoras
  pequeñas elegidas por el dueño (frenada/derrape, daños visibles, aparcar entre dos coches, gasolina con luz de reserva, radio). No se diseña más hasta tener la auditoría.

**Reparto entre sesiones**: redes (sesión 3) = modelo del gas/luz/agua; yo = todo lo de arriba (cartera, banco, tienda, peluches, servicios); estación y `kit tren` = sesión 3.
**Riesgos**: (1) nada de esto debe consumir `_rng` de la ciudad (hash de la posición, como los rellenos); (2) todo script < 450 líneas; (3) el guardado: cada pieza lleva clave propia
y partida vieja = valores por defecto; (4) la economía del club no se toca (`Club.saldo`): solo se separa el bolsillo del DT; (5) PIN y tarjeta son ficticios, sin datos reales.
**Pregunta de arranque**: ¿empiezo por A+B (cartera y cajeros, base de todo) o por D (peluches, lo más visible)? Recomiendo A → C → B → D → E → F.

### 2.2e Calidad visual de ciudad y personajes (pedido del dueño, 26-10 noche) — PENDIENTE DE DISEÑO

Palabras del dueño: *«hay partes de la ciudad sin detalles y muy mejorables; los personajes se mueven de forma
antinatural, sus partes del cuerpo no son anatómicamente correctas, falta profundidad y calidad de los personajes; mejorar
y agregar animaciones; analizar toda la ciudad, mejorar la construcción y cuidar la coherencia»*. Entra como trabajo de la
fase 6 (pulido) adelantado y se hace por PASADAS con captura antes/después y veredicto del dueño en cada una.

| # | Pasada | Qué | Cómo se mide |
|---|---|---|---|
| C1 | Auditoría de la ciudad | recorrido por zonas con capturas (paseo y aérea), lista priorizada de huecos, cajas lisas, incoherencias (sesión ejecutora, tarea 7) | `docs/04_auditorias/ciudad_26_10.md` + `capturas_ciudad/` |
| C2 | Construcción y coherencia | fachadas reales donde hay cajas (centro comercial, cocheras, estación), aceras y cruces continuos, rótulos sobre algo, escalas unificadas, piezas Kenney donde falten | capturas antes/después por zona |
| P1 | Anatomía | medir el cuerpo base (`PersonajeDT`, `VestidorQ`): proporciones cabeza/tronco/brazos/piernas frente a un humano medio (7,5 cabezas), hombros, cuello, manos; corregir escalas por hueso | hoja de medidas + captura frontal/lateral |
| P2 | Movimiento natural | pasos sin patinar (velocidad de clip = velocidad real), giro con inercia, transición caminar↔correr↔parar con mezcla, peso en los brazos, mirada; en peatones y en el DT | `pruebas/sonda_movimiento.tscn` (deslizamiento de pies en cm) + vídeo corto |
| P3 | Más animaciones | sentarse, esperar (3 variantes), hablar con gestos, abrir puerta, subir escalera, saludar; usar los 333 clips del pack antes de crear nuevos | inventario de clips usados/sin usar |
| P4 | Profundidad y calidad | piel con subsuperficie suave, pelo con capas, ropa con arrugas normales, sombras de contacto, LOD sin saltos | captura de transmisión + de cerca |

Compuerta: el dueño ve cada pasada y dice «estamos» o «mejorar». Nada se quita sin avisar.

**Pasada 1 de P1 y P2 (26-10 noche), medida con `pruebas/sonda_movimiento.tscn` (complexión neutra, determinista):**

| Medida (fracción de la altura) | humano | antes | después |
|---|---|---|---|
| cabezas de altura | 7,5 | 7,6 | 7,9 (hombre) · 7,4 (mujer) |
| hombro→muñeca | 0,34 | 0,27 | 0,29 (−15 %) |
| antebrazo / brazo | 0,80 | 0,97 · 1,04 | 0,78 · 0,83 |
| pantorrilla / muslo | 0,95 | 1,07 · 1,14 | 0,98 · 1,04 |
| anchura de hombros | 0,245 | 0,23 · 0,17 | 0,21 · 0,19 (pasada 2: el brazo se desplaza hacia fuera por la clavícula, `HOMBROS_FUERA`; captura `peatones_pasada2_hombros.jpg`) |

Cambios: `PersonajeDT.ANATOMIA` (húmero ×1,15, muslo ×1,05, pantorrilla ×0,96) para DT, futbolistas y peatones. Los hombros se
resolvieron en la pasada 2 desplazando el hueso del brazo (escalar la clavícula estiraba el brazo). Movimiento: el pie apoyado de «caminar» recorre 1,0 m/s y el
paseo iba a 1,7 m/s (patinaba ×1,7; agachado ×2,4; correr ×1,3-1,5): ahora `speed_scale = velocidad real / natural del clip`
(`ExploradorCiudad.VEL_NATURAL_CLIP`) y los peatones del tráfico igual (`TraficoCiudad.agregar_vehiculo`). Hecho también: el cuerpo gira con inercia
(persigue el rumbo, `lerp_angle` a 9/s) y la mezcla al pararse dura 0,4 s. P3 (27-10, pasada 1): inventario del pack UAL = 43 clips; los
de conversación y asiento estaban mapeados en `AnimExtra.UAL` pero solo los futbolistas los cargaban. `AnimExtra.asegurar`
carga un clip en cualquier cuerpo al momento; ahora HABLAN con el clip de charla el mentor del prólogo, las personas de las
citas (mientras dura el cuadro) y la familia en casa (4 s). P1 pasada 3 (27-10, POSTURA): el «Idle» del pack era una postura de superhéroe; medido con la sonda: pies a 0,66 m
(0,35 de la altura; humano 0,20-0,30), rodilla 156° (humano > 170°). `AnimQuaternius._piernas_naturales` gira los muslos 12°
hacia dentro, estira la rodilla 14° y sube la raíz 4 cm (el pie vuelve a su altura): ahora tobillos a 0,17 m entre sí, rodilla
169°, pie a 0,087 m (antes 0,09). Capturas `p1_postura_{antes,despues}.jpg`. Y ANDANDO (misma pasada): el ancho de paso del pack
era 0,24 m (humano 0,08-0,12): 5° de muslo hacia dentro en caminar/trote/correr → 0,09-0,12 m (`PIERNAS_CADERA_ANDAR`). P3 pasada 2 (27-10): los bancos de acera y de parada registran asientos
(`CityBuilder.asientos`) y `GenteSentada` (`visor/gente_sentada.gd`, cuelga de `VidaCiudad`) sienta hasta 6 peatones con el clip
«sentado» en los asientos a < 55 m (ocupación estable por hash de asiento y hora); el DT en el sofá encadena «sentarse» → «sentado»
y se queda así hasta dar un paso (`_gesto_propio(gesto, luego)`); los vecinos ya charlaban con clip (6 s). Prueba `p3_sentados`;
capturas antes/después `docs/04_auditorias/capturas_personajes/p3_sentados_{antes,despues}.jpg`. P3 pasada 3 (27-10, ESPERAR): cuando un peatón se para por su cuenta ya no se queda siempre quieto: la mitad mira el móvil
(clip «Idle_Torch» del pack con un móvil en la palma, `PeatonVida`), un cuarto habla por teléfono y el resto espera; captura
`p3_espera_movil.jpg`. P4 pasada 1 (27-10, ROPA y PIEL): el shader del cuerpo aplanaba el relieve de la ropa de calle a 0,06
para tapar el músculo y borraba las arrugas y el tejido; ahora quita el músculo (como en la equipación) y deja la profundidad
en 0,4 (`p4_ropa_despues.jpg`; antes = `p1_postura_despues.jpg`). La piel desnuda iba con rugosidad y especular de tela
(brillo plástico en nariz y labios): ahora rugosidad 0,76, especular 0,14 y subsuperficie 0,22 (`p4_cara_{antes,despues}.jpg`; en la captura el cambio es SUTIL: el
brillo que queda en nariz y labios viene de la luz de borde `RIM` y de la cara de frente al sol; pendiente revisarlo con la cámara real).
P3 HECHO 27-10 (`ideas/p3_puertas`, `p3_escaleras`, `p3_banquillo_tour`): vecinos que abren las puertas de las entradas (`PuertaVida`: llegan, tienden la mano, la hoja gira, entran/salen), gente que sube y baja escaleras peldaño a peldaño con el ciclo de paso ajustado (`EscaleraVida`: bocas del metro, escalinata del ayuntamiento, estación del teleférico) y los 5 mejores suplentes sentados en el banquillo local de la visita al estadio (`BanquilloTour`). La grada de la visita ya lleva hinchada (35 % de ocupación, VAT). S8 MUSEO INTERACTIVO (27-10, `MuseoVitrinas` + `VisorTrofeo`, `ideas/s8_museo_vitrinas`, captura `capturas_ciudad_c2/visor_trofeo.jpg`): E ante una vitrina de la planta 2 (`SalasClub.vitrinas`) abre un panel con la copa real girando en su propio `SubViewport` (ratón o A/D para girarla) y la ficha del título k (`Roles.trofeos[k]`: competición, año, final, goleadores; lo no guardado dice «Sin datos»). Ahora se guardan la final y los tres máximos goleadores al ganar la LIGA (`Roles._ficha_liga`) y la final de la Supercopa. La planta 3 del museo ampliado (copas 7+, `MuseoAmpliado.vitrinas`) también es interactiva: ambas plantas siguen el mismo orden de hitos por año (`MuseoVitrinas.hitos`). La COPA ya suma a `Roles.trofeos` con su final (`Mundo._final_de_copa`). PENDIENTE: el museo no ha crecido más en detalle. S7 PASAJEROS DEL AUTOBÚS (27-10, `PasajerosBus`, `ideas/s7_pasajeros`): en cada marquesina (`CityBuilder.esperas_bus`) esperan 2 personas mientras el jugador está a < 70 m; al parar el autobús caminan a la puerta y suben (su semilla queda en `meta "pasajeros"` del autobús, máx. 10); en la parada siguiente BAJAN las mismas personas y se van andando. Los cristales del autobús son semitransparentes y tintados (`InteriorBus`, captura `capturas_ciudad_c2/bus_interior.jpg`) y dentro hay 10 plazas con una silueta sentada por pasajero (se encienden/apagan con `meta "pasajeros"`, `ideas/s7_pasajeros`); son siluetas simples (cápsula y esfera), no peatones con esqueleto. El metro ya lo hacía (espera, subir, viajar dentro y bajar: `metro_ciudad_p1`); el tren y el teleférico son de la ejecutora. S6 PARAGUAS (27-10, `ParaguasVida`, `ideas/s6_paraguas`, `capturas_personajes/s6_paraguas.jpg`): con clima de lluvia o tormenta (`Mundo.clima()`) los peatones abren un paraguas sobre la cabeza (6 colores apagados), caminan un 25 % más rápido y hasta 5 se resguardan unos 6-10 s bajo la marquesina de una entrada (a < 4,5 m) con el paraguas cerrado; al escampar se recoge todo. El paraguas va en la MANO derecha (BoneAttachment3D a hand_r) con el brazo levantado (clip «caminar_paraguas», el caminar con brazo y antebrazo fijados; eje corregido 35°). LLUVIA EN LA CIUDAD (`PrecipitacionCiudad`: dos emisores que siguen a la cámara, topes de partículas 1800/4200/5200 según calidad frente a ~15 000 en el partido; suelo mojado `CityBuilder.mojar`; capturas `s6_lluvia_ciudad_{seco,lluvia}.jpg`; memoria del proceso 5230 → 5233 MB con 4200 partículas en software). CLIMA EN LA CIUDAD (`ClimaCiudad`, usa `Ambience.CLIMA_PARTIDO`): con lluvia/tormenta/nublado/niebla el cielo se aplana a gris sin disco solar, el sol baja de energía y se difumina, más niebla; gotas largas y claras; ruido de lluvia cada 3 s por el bus de ambiente (`lluvia_ambiente`/`lluvia_fuerte`); capturas `s6_lluvia_ciudad_{lluvia,cerca}.jpg` (la de cerca: dos peatones con el paraguas en la mano). PENDIENTE: revisar en Forward+. P1-P3 «MEJORAR» (27-10) 1/3 MOVIMIENTO NATURAL (`MovimientoNatural`, `ideas/p1_movimiento_natural`): el peatón de la ciudad arranca con rampa de 0,45 s (la velocidad del clip la sigue), si lo frenan (jugador, semáforo, el de delante) pasa a «parado» en vez de mover las piernas sin avanzar (con 0,4 s de histéresis), gira con suavidad hacia donde va a ir (mira 0,5 m por delante en la ruta, máx. 0,33 rad por fotograma en una esquina de 90°) y 2 de cada 3 peatones a < 8 m giran la cabeza hacia el jugador (`LookAtModifier3D` de `MiradaBalon`, influencia con rampa de 0,5 s). El jugador quieto que gira sobre sí da pasitos (clip «caminar» a 0,8). INCLINACIÓN AL GIRAR (31-10, `MovimientoNatural.inclinacion`, `ideas/p2_inclinacion`): el DT corriendo por la ciudad y los futbolistas del partido se inclinan hacia dentro de la curva (atan(v·ω/g) × 0,25, tope 9°, solo por encima de 2 m/s; andando no). «MEJORAR» del dueño (31-10) → tope subido a 11,5° y además SE ECHA ADELANTE AL ACELERAR (hasta 8°, como un velocista al salir) y algo atrás al frenar en seco (4°) (`MovimientoNatural.cabeceo`; `control_partido` usa ahora el frente horizontal). Captura de los topes (`capturas_personajes/p2_inclinacion_recto_curva_arranque.jpg`: recto, curva a tope y arrancando; arriba de espaldas, abajo de lado; `pruebas/captura_inclinacion`). El movimiento en sí se ve jugando. 2/3 POSTURA y ANATOMÍA (27-10, `PosturaQ`, `ideas/p2_postura`, `capturas_personajes/p2_postura_antes_despues.jpg`, arriba antes, abajo después): un `SkeletonModifier3D` por peatón, tras la animación, suma según su semilla manos relajadas (dedos doblados 14-22° por falange, pulgar menos), hombros caídos 4-12° y cabeza/cuello adelantados 3-14°; 35 huesos, rotaciones fijas. Ejes medidos por prueba (dedos X, hombro −Z, cuello X). REVISIÓN DEL LÍDER (27-10): el adelanto de cuello es leve (1-6°) y la cabeza se NIVELA (corrige el 85 % del cabeceo medido; solo 1 de cada 12 conserva la cabeza gacha) para mirar al horizonte de perfil. MOCHILAS DE PERFIL (revisión del líder en Forward+): la mochila se hundió 3,5 cm en el torso (espalda medida a z −0,14…−0,16 entre y −0,15 y 0,22) y las correas se acortaron (el pecho llega solo hasta la axila y pegadas a la fachada del torso); captura andando `p4_mochila_perfil_antes_despues.jpg`. El «objeto oscuro del mentón» NO era una malla del peatón: era la visera de la gorra del peatón que quedaba detrás en la escena de captura (se solapaban en fila). MOCHILAS (`MochilaQ`, `capturas_personajes/p4_mochila_antes_despues.jpg`, arriba cajas, abajo ahora): cuerpo y bolsillo de bordes redondeados, asa y dos correas que pasan por el hombro, bajan por el pecho y vuelven bajo el brazo pegadas al torso (medido en `spine_03`). PENDIENTE: lo mismo en los futbolistas del partido (no se ha tocado) y 3/3 MÁS ANIMACIONES (27-10): MIRAR ESCAPARATES (`EscaparateVida`, `ideas/p3_escaparates`): junto a las entradas (`puertas_vida`) un vecino llega por la fachada, se para a 2,6 m de la puerta, gira el cuerpo al cristal, pasea la mirada 6-9 s (`LookAtModifier3D` sobre un punto que barre el escaparate) y se va; máx. 2. HABLAR EN GRUPO (`GrupoVida`, `ideas/p3_grupo`, `capturas_personajes/p3_grupo.jpg`): tres vecinos llegan por distintos lados, forman un corro a 0,95 m del centro ante una entrada, charlan 14-22 s con el clip «charla» a distinto desfase (la cabeza de cada uno sigue al que habla, que cambia cada 3 s) y se van cada uno por su lado; 1 grupo a la vez. ARREGLO DE FONDO: la «charla» (y cualquier clip `…_Loop`) NO se cargaba para los peatones porque el pack lo guarda sin el sufijo (`PeatonVida.gesto` y `TraficoCiudad._gesto` no tenían el respaldo de `AnimExtra.asegurar`, que ahora además deja esos clips en bucle): las charlas de dos peatones que se alcanzaban tampoco gesticulaban. MIRAR EL MÓVIL ya existía (`PeatonVida.esperar`: «Idle_Torch» con el móvil en la mano). SENTARSE EN UN BANCO (`GenteSentada._llegadas`, `ideas/p3_sentados`): quien ocupa un asiento MIENTRAS lo miras (a > 6 m) llega andando desde 3,2 m, se vuelve y el clip «sentarse» encadena «sentado»; los que ya estaban al acercarte siguen apareciendo sentados. El móvil y la llamada ya existían. SIN CAPTURA de las dos escenas (movimiento) y la forma de la raíz al sentarse no se ha revisado a ojo: PENDIENTE de revisar en el juego; RESPALDO CURVO de la butaca cercana (`RespaldoCurvo`, `capturas_estadio/respaldo_curvo.jpg`, vista cenital: abajo plano, arriba curvo): se deforma una vez la malla del modelo, los vértices del respaldo se adelantan hasta 5 cm en los bordes de cada respaldo (cóncavo); sutil a distancia de juego. La butaca LEJANA (3 losas) sigue plana a propósito (presupuesto de vértices). LEVANTARSE DEL BANCO (`GenteSentada._levantar/_salidas`, `capturas_personajes/p3_levantarse.jpg`): quien deja el asiento a < 38 m se levanta con el clip «levantarse» («Sitting_Exit», 1 s) y se va andando 8 m por la acera; lejos desaparece sin más. SIN HUNDIRSE (revisión del líder): medido con la pelvis, «Sitting_Idle» la deja a 1,05 m de la raíz y «Sitting_Enter/Exit» a 0,60; la raíz sube `COMPENSA` = 0,45 m durante esos clips (`GenteSentada.raiz_levantarse/raiz_sentarse`) y los peatones andan a la altura del suelo (`ExploradorCiudad.altura_suelo`). BANCOS A ALTURA REAL (orden del líder, `capturas_personajes/p3_banco_altura_antes_despues.jpg`): el tablero baja a 0,45 m sobre la acera (`GenteSentada.ASIENTO_CIUDAD` = 0,65 en el mundo; banco de acera `CiudadExpansion`, banco de parada `CityBuilder`, banco del andén `EstacionCentral` a 1,35 sobre el andén) y los sentados bajan la raíz 4 cm (`PIES_AL_SUELO`) para que las suelas apoyen (antes los pies colgaban ~28 cm). Los círculos de colisión de los bancos no dependen de la altura. AUDITORÍA DE CLIPS (`ideas/p3_clips_ual`): los 25 clips de `AnimExtra.UAL` y los de `AnimQuaternius.CLIP_REAL/CAMINATA` se cargan; otros 3 sitios que cargaban a mano sin el respaldo «_Loop» (explorador_ciudad_p2, rueda de prensa p2/p3) ahora usan `AnimExtra.asegurar`. PERSONAJE REALISTA DEL DRIVE («Realistic Male 3D Character Model», zip de 182 MB; `capturas_personajes/drive_personaje_realista.jpg`, renderizado en un proyecto aparte): es una persona vestida (sudadera, pantalón cargo, botas, pelo y barba) de calidad muy alta, pero NO SIRVE para peatones ni futbolistas: UNA sola malla de 485.122 triángulos con ropa y pelo fundidos (no se recolorea ni se cambia), esqueleto Reallusion de 101 huesos («CC_Base_*», no es el de Quaternius: no recibe nuestras animaciones sin retarget), texturas 4K de 9 + 7 MB, una sola identidad (repetida 30 veces se nota) y sin licencia escrita; un FBX/glb iría a LFS (no se puede subir). Opción si el dueño quiere: usarlo como UN personaje de primer plano (p. ej. un DT rival o el prólogo) decimado a ~30.000 triángulos y 1K de textura (<5 MB como `.res` fuera de LFS) o sacarle la cabeza para una ficha; no lo hago sin su OK. PELO DEL DRIVE (27-10, `PeloDrive`, `herramientas/pelo_drive_extraer.py` + `pelo_drive_a_res.gd`, `ideas/p4_pelo_drive`, capturas antes/después `capturas_personajes/p4_pelo_drive_*.jpg`): el OBJ «nv toufa» (122 MB, 105 peinados «samor_1125_NN» en cm y en rejilla, sin licencia escrita: PENDIENTE confirmar con el dueño) se bajó con curl y se procesó con `fast-simplification` (decimar a 800 triángulos DEJABA HUECOS: la malla son láminas de mechones; a 2.500 se ve sólida). Se probaron ~30 y quedaron 11 que asientan bien (hombres 73, 74, 77, 79, 80, 68; mujeres 28, 60, 117, 33, 36; los de coleta, trenzas y flequillo largo tapaban los ojos o no tenían masa de pelo). Salen como `assets/characters/pelo_drive/pelo_NNN.res` (603 KB en total, fuera de LFS: `.res` no está en .gitattributes). El modelo del pack mira a −z (se gira 180°); ajuste por ancho de cabeza y coronilla (`AJUSTE_M/F`). El 45 % de los peatones lleva uno (`PeloDrive.elegir`, por semilla; `SIN_PELO_DRIVE=1` lo apaga), el resto sigue con los cortes de Quaternius; bajo gorra no se ven. NO aplicado aún a los futbolistas del partido ni a la ciudad vieja de `PeatonQ` fuera de los peatones. Las correas de la mochila se acortaron otra vez (a la vista solo el tramo hombro-pecho). P4 PELO (27-10): el pack Quaternius del repo trae 6 mallas; la sin usar `Hair_BuzzedFemale` se estrena en el corte rapado de las MUJERES (`PeloQ.poner`, `ideas/p4_pelo_mujer`, `capturas_personajes/p4_pelo_mujer_antes_despues.jpg`, arriba antes y abajo después: asienta mejor). No hay más cortes en el repo; esperan los del Drive. P4 pasada 2 (27-10, CONTACTO): los peatones llevan una mancha de sombra redonda y suave bajo los pies (`PeatonQ.sombra_contacto`, una malla y un material compartidos, hasta 70 m) para que no «floten» más allá del alcance de la sombra del sol (`ideas/p4_contacto`, `capturas_personajes/p4_contacto_antes_despues.jpg`, arriba antes, abajo después). LOD SIN SALTOS: las mallas del peatón se disuelven con tramado (`VISIBILITY_RANGE_FADE_SELF`) en los 20 m de margen en vez de desaparecer de golpe (solo Forward+/Mobile; en Compatibility sigue el salto). Queda en P4: pelo con mechones (pide mallas mejores). LEAGUE-SOCCER (01-11, misión del dueño: «agarrar todo» de github.com/awest813/League-Soccer, Apache 2.0, y de soccer5v5, MIT; respaldo completo en `dinastia-godot/terceros/` salvo la base de jugadores reales y los escudos reales): conversor `herramientas/league_anim_a_res.gd` (293 animaciones + espejos → `anims_league/league.res`, nombres `ls_…`). Tanda 1: «correr» = su paso de sprint + espejo (`LeagueAnim.CICLOS`; captura `league_correr_nueva_arriba_original_abajo.jpg`). Tanda 2 (comparadas de lado, `pruebas/captura_comparar`; `league_comparacion_pase_tiro_barrida.jpg`, en cada par arriba el nuestro): «tiro_carrera» = su tiro en carrera (el hecho a mano queda como «tiro_carrera_mano»), «pase_carrera» NUEVO para pasar corriendo (> 4,5 m/s, raso; parado sigue el mocap), recortados al contacto (`LeagueAnim.GOLPEOS`; `league_tiro_arriba_pase_abajo.jpg`); su barrida NO (acaba tumbado del todo; la de la UAL2 se ve mejor). Huella del motor 19367961. Tanda 3: «control_pecho» y «control_pie» al recibir alto (los nuestros eran «golpe_pecho», una reacción a un golpe, y un aspaviento con la pierna; `league_comparacion_controles.jpg`), TROPIEZO a la carrera (> 4 m/s) con levantarse desde boca abajo (`_caer`, `levantar_con`; `league_tropiezo_y_levantarse.jpg`) y variantes «celebrar_ls» y «lamento_ls» (`league_comparacion_celebrar_tropiezo_lamento.jpg`). Arreglado en el conversor: la altura de la pelvis iba al eje equivocado (la raíz viene girada) y el cuerpo que caía flotaba. Tanda 4: «centro», «pase_largo» y «pase_bombeado» de League-Soccer (los hechos a mano levantaban el talón hasta el glúteo antes de golpear; quedan como «…_mano»; `league_comparacion_centro_largo.jpg`, `league_centro_largo_bombeado_nuevos.jpg`). Huella del motor 2696167778. Tanda 5: BLOQUEO con el cuerpo de un tiro (antes sin gesto): «bloqueo_rodilla» / «bloqueo_tronco» según la altura (`LeagueAnim.bloqueo`; `league_bloqueos.jpg`; descartados el rasante, que se queda tumbado, y el alto, que levanta el brazo = mano). PENDIENTE: interceptar (interfere), trote (no tiene paso estable), MODELOS de League-Soccer: NO entran (jugador ~4.000 triángulos, peinados de 98, piel de 16 px: muy por debajo de los nuestros), quedan de respaldo. MINIJUEGO RETRO 5v5 (soccer5v5, MIT) HECHO: `res://minijuegos/retro5v5/` (rutas reescritas, sin la fuente Daydream de uso personal, clubes con nombre modificado y jugadores inventados; arreglados 2 fallos del original: el hueco vacío del equipo y el saque que esperaba al jugador 2), `Retro5v5.abrir` lo pone encima con el mundo en pausa (Esc sale); una RECREATIVA de Kenney (`RecreativaRetro`, CC0) junto a las de peluches del centro comercial lo abre con la E. Prueba `ideas/m5_retro5v5` (en especiales); captura `minijuego_retro5v5.jpg`. «worldcup-label.png» QUITADO (01-11: «WORLD CUP» es marca registrada de la FIFA, también en software de juegos; el minijuego no lo usaba; el original queda en el respaldo). Su música (MIT) se QUEDA (dueño, 01-11: «si es música libre, claro»). SONIDOS (01-11): el partido jugable no sonaba al golpear ni en el palo; ahora el golpeo («pase_corto», «tiro_potente») y el palo («poste», «travesano») son las grabaciones de League-Soccer (`audio/ui/`, Apache 2.0), igualadas a +1 dB de la síntesis (`sui_grabados`). La MÚSICA de soccer5v5 NO entra (la música del juego se compone en vivo y la maneja el dueño): queda de respaldo. Sus efectos retro de 8 bits tampoco (no encajan en un juego realista). `SIN_LEAGUE=1` vuelve a lo anterior. TERCEROS, QUÉ MÁS SE PUEDE APROVECHAR (01-11, análisis de 2 bots; informes completos en `docs/04_auditorias/terceros_ia_motor_2026-11-01.md` y `terceros_gestion_recursos_2026-11-01.md`). Gestión, guardado y menús de League-Soccer: PEORES que los nuestros (nada que reemplazar). IA/MOTOR — ahora, en bloques pequeños con su prueba: R1 VENTAJA HECHA (01-11, `MotorVentaja`, banco `_probar_ventaja`): la falta queda pendiente y si en 3,5 s de juego el equipo de la víctima pierde el balón, el árbitro vuelve a la falta y la pita donde fue; si no, o si el juego se para, se da por jugada (sigue sin ventaja en el área ni con tarjeta: «la amarilla en la siguiente parada» queda PENDIENTE), R3 HECHO (01-11, `MotorPresion`, banco `_probar_presion_estable`): primero y segundo presionador se eligen una vez por paso y se conservan salvo que otro esté 1,5 m mejor; de segundo, un central cuenta 3 m de más (sale un medio). Medido en 32 partidos (`zz_medir_partido`, `SIN_PRESION_ESTABLE=1` = antes): tiros 285 → 293, faltas 146 → 143, pases buenos 1950 → 1974, goles 53 → 73 (19 → 37 en la 1.ª tanda, 34 → 36 en la 2.ª: los goles varían mucho; VIGILAR al calibrar). Huella del motor 1594249054. U1 HECHO (01-11, `MotorPresion.zona`, banco `_probar_presion_zona`): un gatillo más de `_gatillo_presion`; sale a morder si el balón está adentrado (territorio > 0,55 − 0,9·presión) y hay alguien a < 5 + 8·presión m, y aguanta 2 + 2·presión s (`SIN_ZONA=1` = antes). 32 partidos frente a R3: duelos 1476 → 1532, faltas 143 → 153, pases buenos 1974 → 2001, tiros 293 → 281, goles 73 → 54 (vuelve a lo de antes de R3). Huella 1486609092. U3 HECHO (01-11, `_ultima_linea` + `MotorPresion.PREVE_LINEA`, banco `_probar_linea_prevista`): para los desmarques la última línea rival se mira donde estará en 0,24 s (el árbitro no cambia; `SIN_LINEA_PREVISTA=1` = antes). 32 partidos: fueras de juego 21 → 16, tiros 281 → 310, goles 54 → 69. Al medirlo salió un FALLO de fondo: el portero paraba en el instante en que decidía (hasta 1,6 s antes), y el balón volaba 16 m a sus manos a 167 m/s o rebotaba antes de llegar; ARREGLADO con `MotorParada` (la parada se hace cuando el balón cruza su línea; si se queda corto o lo toca otro, se anula). Con eso: tiros 310 → 352, goles 69 → 79 (2,5 por partido: el rechace ya sale junto al portero y hay segundas jugadas; VIGILAR al calibrar). Huella 1995017035. U5 HECHO (01-11, `MotorControl`, banco `_probar_primer_toque`): el control de un jugador de campo puede irse largo (rival a < 1,6 m, balón > 12 m/s y más si llega por la espalda, balón alto; menos con regate; tope 25 %; con el error de dificultad del pase; `SIN_PRIMER_TOQUE=1` = antes). Suave: 28 controles largos en 32 partidos; lo demás, dentro del ruido. Huella 3180886866. U2 HECHO (01-11, `MotorTacticaViva`, banco `_probar_tactica_viva`): a la mentalidad del bloque de la CPU se le suma 0,35 por gol de diferencia (pierde = adelanta, gana = repliega; tope 0,7), que pesa del 30 % al 100 % del partido; no toca al equipo del usuario (`SIN_TACTICA_VIVA=1` = antes). 32 partidos: goles 84 → 74, tiros 337 → 330, faltas 149 → 137 (cerca del ruido). Huella sin cambios; R2 HECHO detrás de la bandera `PMOT_PASE=1` (01-11, `MotorPaseMejora`, banco `_probar_pase_mejora`; APAGADA = la cuenta de siempre, huella igual): receptor previsto a 0,5 s y rivales a 0,3 s, pasillo 0,45 + 0,22·m, coste por pasar a la espalda. Encendida, en 32 partidos frente a U2: pases buenos 1873 → 1953, fueras de juego 24 → 11, faltas 137 → 165, tiros 330 → 275, goles 74 → 59 (circula más seguro y arriesga menos). DECISIÓN DEL DUEÑO: encenderla o no; U8 HECHO (01-11, `MotorTacticaViva.estilo_club`, banco `_probar_estilo_club`): cada club suma a su línea y amplitud un matiz continuo fijo de ±0,35 (de su país y colores, igual en las dos bases) y algo de su reputación; lo pone el estadio (`f_linea`, `f_amplitud`) y lo lee `_forma` (`SIN_ESTILO_CLUB=1` = antes). PENDIENTE de U8: `dribble_offensiveness` en la conducción; en la PASADA FINAL del motor (orden 13): F1-F8 — LOS LLEVA EL DUEÑO (3-11, orden 23) — (colocación sin balón, roles dinámicos, desmarques por campo de fuerzas, marcaje, carreras al espacio, línea de tiro, portero, «imagen mental» para las 8 dificultades). RECURSOS: U1 regenerar los iconos de mando/teclado con su script (dominio público), CLUBES (01-11, paso 2 de la orden 20): de los 8 clubes de League-Soccer, 6 ya estaban recreados (orden 15); Ajax y PSV no tenían liga. PAÍSES BAJOS deja de ser inventado (`paises_extra`): la Eredivisie 25-26 (18 clubes) sale del pack real (`herramientas/liga_paises_bajos.py` → `base_ficticia.py`), con nombres ficticios (los 12 de antes se conservan), aspecto (escudo, uniforme), historia y 7 clásicos, y plantillas reales de Ajax, PSV, Feyenoord y AZ (en la base, con guiño). Su base de jugadores NO sirve: es de ~2014 (solo 23 de 144 siguen activos). Prueba `ideas/c1_paises_bajos` (en especiales). PENDIENTE: plantillas reales del resto de los 18 y captura de los escudos nuevos; sus tácticas por club van con U8. U7 los 8 fallos que ellos ya resolvieron REVISADOS (01-11, `ideas/fallos_terceros`, en especiales): 1-5 y 7 no existen aquí; ARREGLADOS la posesión del motor libre que podía sumar 101 (6), el equipo con menos de siete por rojas que seguía jugando (8: se suspende, 3-0 o el marcador del rival si ya ganaba por 3+; solo en el partido jugable, el simulado no saca al expulsado del once) y, de paso, los jugadores LIBRES que no cumplían años; y los goles del descuento del 3D se guardan y se leen «90+3'» (`Partido.texto_minuto`, lista de goles del final), U6 prueba de partida dañada, U2 glosario de 5 idiomas para revisar los nuestros. LICENCIAS: sumados a `LICENCIAS.md`; PENDIENTE (dueño) confirmar el origen de la música del minijuego y de los 4 sonidos de League-Soccer (🟡). PIES SOBRE EL CÉSPED (31-10, «mejora» del dueño; medido con `pruebas/auditoria_biomecanica.tscn`): `SueloAnim` (al construir la librería) recorre cada clip con cinemática directa y sube la pelvis lo que haga falta para que ni el pie ni la punta bajen de su altura en «parado» (tumbado o sentado, de la de un pie apoyado de lado, para no dejar cuerpos flotando). Animaciones con problemas 246 → 80; avisos de pie bajo el suelo 543 → 45 (los que quedan son poses tumbadas que la auditoría mide con la altura de pie: estiradas, tijeras, sentados). Captura `capturas_personajes/p1_pies_sobre_cesped_antes_despues.jpg` (arriba antes: puntas y un pie y una mano bajo el césped). `SIN_SUELO_ANIM=1` lo apaga. CODOS (31-10, `CodoAnim`, desde `SueloAnim.corregir`): los gestos a mano (silbato del árbitro, besar el escudo, mano al oído, manos a la cabeza, silbar, pedir silencio) llegaban a 175-180° y el antebrazo desaparecía dentro del brazo (un muñón); las claves estaban bien, se pasaba la INTERPOLACIÓN entre claves (179,7° a 0,63 s sin clave ahí). Se muestrea a 30 fps y la pista del antebrazo se reescribe con tope 145°: `codo_flexion` 14 → 0; captura `capturas_personajes/p1_codos_antes_despues.jpg` (arriba antes: brazo terminado en el codo; abajo: la mano a la barbilla). La auditoría sigue llamando «codo atrás» a esos 145° con el brazo levantado (calibra el plano del codo corriendo); en la captura dobla hacia el lado natural. Quedan: cadera estirada 40-48° al armar la pierna en centros y pases largos (es captura real), aducción > 35° en trivela y zancadilla, y muñecas a 86° (1° de más). La VOLTERETA (codo atrás 134°, cadera 165°) ya no es una variante del regate (31-10: nadie regatea rodando); el clip sigue cargado. UAL2 (31-10, idea del dueño: buscar en GitHub más articulaciones y esqueletos): la «Universal Animation Library 2» de Quaternius (CC0, MISMO esqueleto de 65 huesos; copia en github.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender) aporta 43 clips; 17 elegidos van en `assets/characters/quaternius/anims_ual2/ual2_elegidos.res` (750 KB, fuera de LFS; `herramientas/ual2_a_res.gd`) y se cargan BAJO DEMANDA (`AnimExtra.UAL2` + `asegurar`): brazos cruzados, teléfono a la oreja, negar, asentir, llevar una caja, beber, apoyado en la baranda (y llamando), BARRIDA (inicio/desliza/fin), SAQUE DE MANO del portero, choque, LEVANTARSE DEL SUELO, trepar, abrir una caja, regar. Ya en uso: la llamada del peatón (móvil a la oreja) y una 4.ª espera con brazos cruzados (`ideas/p3_ual2`, `capturas_personajes/p3_ual2_espera_antes_despues.jpg`). BARRIDA y SAQUE DE MANO en el partido HECHOS (31-10, `ideas/p4_saque_barrida`, tira de fotogramas `capturas_personajes/p4_barrida_saque_ual2.jpg`): `AnimExtra.unir` arma `barrida_real` (entra 0,83 s + se desliza 0,5 s + se levanta 0,5 s = 1,83 s), una de cada tres barridas del jugador y 2 de 7 en `_entrada`; tras ella se queda en el suelo frenando hasta levantarse (`levanta_hasta`, también si lo mueve la IA). El portero que ATRAPÓ (`en_manos`) y pasa raso a < 32 m lo lanza con la mano (`saque_mano`); el balón SE QUEDA EN LA MANO mientras carga el brazo y sale al lanzar, a los 0,45 s (`SUELTA_MANO`, `_retener_en_mano`; si el juego se para antes, se anula). Los envíos largos siguen de volea. La IA no barre (solo el jugador): decisión de diseño anterior. CAÍDA POR FALTA (31-10, `_caer`): cae de espaldas («caida_lesion»), se queda en el suelo y se LEVANTA con el clip de la UAL2 (antes la caída se cortaba a 1,2 s y se ponía a correr de golpe; «caida_fea» no vale: acaba boca abajo y el levantarse empieza boca arriba, se daba la vuelta; tira de fotogramas, 3.ª fila). Si es el lanzador del tiro libre, va al balón al levantarse. PENDIENTE usar: baranda en la grada y el mirador, caja en la utilería, regar en los parques. Falta P3: capturas de escaleras en Forward+, clips propios de abrir puerta/subir escalón (el pack gratuito solo trae «Interact»), peatones que entran en tiendas pequeñas (no tienen puerta registrada); y P4: pelo (mechones poligonales). PROBADO Y DESCARTADO (27-10): suavizar las normales de las 4 mallas de pelo del pack
(promedio por vértice) empeora: las tarjetas de mechón comparten vértices y salen manchas claras/oscuras; el pelo pide mallas
mejores (o más cortes del pack de Quaternius), no un cambio de sombreado. VEREDICTO DEL DUEÑO (27-10): «MEJORAR» (P1-P3 no bastan: seguir subiendo anatomía, movimiento, animaciones y acabado; la C2 de ciudad sigue hasta agotar P0 y P1).

#### 2.2h Butacas y aficionados (decisión del dueño 27-10) — HECHO, falta Forward+
`StadiumBuilder._butacas` (hueco entre hinchas: tope de ocupación 86 %, quien tiene vecino deja el asiento libre 1 de cada 3, cuerpos algo más
delgados; barniz en el plástico de la butaca), `colores_de_nivel` (abajo color 1, en medio color 2, arriba una mezcla; `est["asientoNivel"]`
= `por_nivel` por defecto o `uniforme`), `_vomitorios` (boca de hormigón con dintel y jambas, hueco negro, rótulo de SALIDA y descansillo, en
3 MultiMesh por grada) y la opción elegible en el diseñador (Club → Estadio → La grada, `EST_NIVELES`) y en el menú inicial (paso Estadio,
`ConfigClubDatos.asiento_nivel`). Prueba `ideas/e1_butacas`; capturas `docs/04_auditorias/capturas_estadio/butacas_{antes,despues}_{1,2}.jpg`
(cámara alta de TV y tribuna; en Compatibility; la de partido cercana y Forward+ las repite el líder). REVISIÓN DEL LÍDER (27-10): los vomitorios flotaban → ahora son bloques de hormigón asentados en la rampa, al final de un pasillo (`VomitoriosGrada`); el «bloque negro con una P» de la toma alta era la fila de PALCOS VIP del lado −X sobre la que estaba MI cámara de captura (no un fallo del juego; la toma alta se hace ahora desde +X). Butaca lejana con reposabrazos (+48 vértices por grupo). Capturas con un club rosa y celeste (`butacas_vivo_*.jpg`: el color por nivel se ve, abajo rosa y arriba mezcla; y la cámara real del partido a pie de campo). ZANCAS EN LOS PASILLOS DE TODAS LAS BANDEJAS (27-10, `DetalleGrada.zancas_pasillo`, `ideas/e2_zancas_pasillos`, `capturas_estadio/zancas_pasillos_antes_despues.jpg` y `zancas_pasillos_tv.jpg`): un murete de 0,14 × 0,5 m a cada lado de cada pasillo, de la primera a la última fila, siguiendo la pendiente (la barandilla ya existía). Desde la cámara de TV el cambio es SUTIL (los muretes son finos); se ve de cerca. HINCHAS «DEFORMADOS» EN LAS BANDEJAS ALTAS (revisión del líder, `capturas_estadio/hinchas_altas_antes_despues.jpg`, arriba antes, abajo después): eran la malla VAT «lejos» (~70 vértices, la decimación más basta de `hornear_publico_vat`: triángulos con púas) vista a 3-5 m; las filas altas la usaban SIEMPRE. Ahora esas filas llevan la malla «medio» (160 vértices) a menos de `LIMITE_ALTAS` = 26 m de cada uno de 8 trozos por bandeja y «lejos» más allá (`_montar_publico_lod` con límite y trozos propios): desde la TV no cambia nada. COSTE: un MultiMesh extra por trozo (solo se dibuja el cercano). La malla «lejos» en sí no se ha tocado (rehornearla da solo los LOD de `generate_lods`: ~70 o ~160). Las 13 poses se ven bien en «cerca» y «medio» (`pruebas/captura_vat_clips.gd`). M-038 (piernas cortadas en la cadera) sigue pendiente. TORRE DE FOCOS DEL DRIVE (27-10, `TorreFocos`, `ideas/e3_torre_focos`, `capturas_estadio/torre_focos_{tv,cerca}_antes_despues.jpg`, izquierda día y derecha noche, arriba antes y abajo después): el regalo `assets/regalos/torre_focos.glb` (23,2 m, ~21.800 triángulos, 30 proyectores con escalerilla) sustituye al poste de cilindro y la cabeza de cajas en las torres de las 4 esquinas (`StadiumBuilder._focos`, tipos «torres» y «mixto»), escalado a la altura de siempre, girado para que los focos miren al campo y con la emisión del color de luz del club (x1,8); sin el recurso o con `SIN_TORRE_DRIVE=1` se usa lo de antes. Desde la TV son del mismo tamaño en pantalla (puntitos) y de noche brillan igual; de cerca se ve el bastidor real. COSTE: ~87.000 triángulos por estadio con 4 torres (sin sombra). La corona de focos de los estadios «corona»/«halo» no se ha tocado. TÚNEL DE VESTUARIO EN OTRO LADO (M-017): DECIDIDO NO HACERLO (líder, 27-10): el túnel está fijo en la tribuna +Z (`StadiumBuilder._tunel`, `tunel_x` solo varía la X: central o esquina) y la salida de equipos, la ceremonia, los banquillos y la cámara asumen ese lado; moverlo toca 8-10 archivos y arriesga romper la salida de equipos. Si algún día se quiere: parámetro `est["tunel_lado"]` (±1) reflejando z en la boca, el hueco de grada, la ruta de salida y la cámara. PARADEROS COMO LOS DE SANTIAGO (27-10, `ParaderoRed`, `ideas/p5_paradero_red`, `capturas_ciudad_c2/paradero_red_antes_despues.jpg`, arriba antes, abajo después, desde la cámara a pie): marquesina de acero gris con techo plano de poco vuelo y franja burdeos con el rótulo «Red», trasera de cristal con pósters de mapa de recorridos, lateral de cristal, banca corrida de láminas metálicas (tablero a 0,45 m) y, aparte, el POSTE con el cartel del paradero (franja verde «PARADERO», código «PA» + cifras estable por paradero, un QR y 3-5 recorridos en cajitas de color). De noche (cámara de paseo con la luz apagada, `captura_paradero.gd` con NOCHE=1) los pósters y la placa del cartel se leen (sin luz propia el resto queda a oscuras, como la acera). Lo usan las 4 paradas del anillo (`CityBuilder._paradas_bus`, 7,5 m) y las marquesinas de las líneas de bus (`CiudadExpansion._marquesinas_bus`, 3,6 m). LIMITACIÓN: las webs de Red/DTPM (red.cl, infraestructurapublica.cl) no se pueden abrir desde el contenedor (host fuera de la red permitida): el diseño sale de memoria; hace falta una foto real para afinar colores y proporciones (¿el burdeos es el de la marca?). Los carteles de recorridos son inventados (no son líneas reales). BARANDA EN LAS BANDEJAS ALTAS (orden del líder, `DetalleGrada.barandas_pasillo`, `capturas_estadio/pasillo_alto_antes_despues.jpg`, arriba antes y abajo después, de frente y de lado): pasamanos fino a 0,45 m sobre cada zanca con un poste cada ~2 m; solo en bandejas altas (la baja tiene sus escaleras con zancas y pasamanos). PENDIENTE: si el dueño lo pide, escaleras exteriores del anillo hasta la bandeja alta.

### 2.3 Fase 4: cifras validadas (entrar al campeonato)

#### 9.1 Propuesta para la fase 4 (entrar al campeonato) — cifras VALIDADAS por el dueño el 24-10
Sea B el presupuesto inicial que tendría un club de esa división.

| | **Reemplazar un club existente** | **Pagar a la confederación (club extra)** |
|---|---|---|
| Coste | ninguno | cuota de afiliación = 25 % de B, al contado |
| Presupuesto de partida | B | 0,75 × B |
| Reputación inicial | la del club reemplazado − 10 puntos («recién llegado») | la de un club recién creado − 20 puntos («compró su plaza») |
| División | la del club reemplazado | siempre la más baja (la liga pasa a tener un club más; calendario con descansos si queda impar) |
| Confianza de la directiva | 60 | 40 |
| Ánimo de la afición | normal | −15 el primer mes; se recupera en ~1 temporada con buenos resultados |
| El otro club | desaparece de la liga; sus jugadores quedan libres (puedes ficharlos) y su afición se reparte | no se toca |
| Prensa | «Nace un club sobre las cenizas de X» | «Un club compra su plaza»; preguntas duras en la primera rueda de prensa |

Efecto buscado: reemplazar es barato pero tiene coste moral y de plantilla; pagar es limpio con el resto de
la liga pero empiezas peor. Los dos son recuperables, ninguno es un castigo definitivo.


### 2.5 Lo que falta del guion (auditoría del 28-10; detalle en `docs/04_auditorias/GUION_FRENTE_AL_CODIGO_2026-10-28.md`)

Cumplimiento medido en el código: entrada ~95 %, fase 0 (separar `Principal`) ~65 %, prólogo ~75 %, vida ~80 %, personas ~80 %,
club ampliado ~85 %, redes ~85 %, dinero ~70 %, calidad visual ~70 % (el dueño dijo «MEJORAR» dos veces), cifras 2.3 100 %.
Las pruebas f1-f5 del guion ya corren en `especiales.sh` (28-10). Lo que falta, por importancia para el jugador (horas de sesión):

5. Entrevista de 3 preguntas: HECHA con el vestuario (2-11); falta la versión para el staff (sesión de ciudad).
8. Fase 0: HECHO el contrato (31-10): `PantallaBase` con `abrir(sección, contexto)`, `cerrar()` y la señal `cerrada` en las 15 pantallas del menú central; `Principal._refrescar` las abre por `abrir` (34 secciones; prueba `f0_contratos` en especiales). Falta (deuda interna, invisible al jugador): que cada pantalla tenga su propio nodo y estado en vez de pintar en `p._lista_*` y leer `p.*`, y los 9 trozos que otros paneles componen a mano (`federacion_menu`, `paneles_club`, `vistas_menu`). El autoguardado al salir de la entrada está HECHO.
9. Club ampliado: la rama de otro deporte no ofrece «visibilidad» ni celebra sus títulos (2 h).
10. Dinero: coches: auditoría HECHA (`docs/04_auditorias/coches_31_10.md`), el dueño pidió TODAS (A-G, 31-10): A gasolina en el móvil/HUD/salpicadero; B derrape; C daños visibles y taller; D bajarse y aparcar; E claxon (la RADIO espera música con licencia del dueño); F atropello con reacción, 150 € y titular; G claxon y velocidad asustan a los peatones; consumo 0,5 l/km y multa temeraria 60 €. Solo falta la radio. Pendiente de mirar en Forward+ en el PC del dueño: los cajeros nuevos (hospital, universidad, estación, estadio).
11. Redes: captura Forward+ en el PC del dueño (aquí la ciudad se queda sin memoria en Forward+; revisado en Compatibility: camión cisterna y ventanas de las casas del kit que se encienden de noche y se apagan con su sector).
12. Calidad visual (2.2e): POSTURA («atleta», `PosturaQ.MANO_ATLETA`) y PELO DEL DRIVE en los futbolistas del partido HECHOS (31-10 en main; 2-11 también en la rama de la sesión de ciudad, con `SIN_PELO_DRIVE=1` / `SIN_POSTURA=1` para el antes): unificar las dos al fusionar y dejar una sola hoja antes/después con la cámara real. Falta: pelo femenino (ningún peinado femenino del Drive aceptado).

Lo que el guion exige de verdad ya está hecho o a falta de unir; lo abierto es deuda interna (8), lo que espera al PC del dueño (10-11) y el pelo femenino (12); el total de la lista larga del informe es ~65 h.

### 2.4 Pendientes del traspaso anterior

- (31-10, rescatado de `ccr-76d707c5`) Viajes y día de partido por distancia y costo de vida (`nucleo/viajes.gd`, `datos/geografia.json`): falta usarlo en los viajes de copas continentales si se añaden y revisar `ESCALA_JUEGO` si cambia la taquilla.
De `PENDIENTES.md` (traspaso al 21-10):
- **Fusionar a `main`**: nada de la rama actual (ni de la sesión 2, §9) está en `main` aún.
- **Partido**: roles por jugador (PlayStyles), más desmarques de ruptura, cartel del 4.º
  árbitro con corte de cámara, red del arco.
- **Gente del club y ciudad en primeras filas** (M-040) y mejor variedad (M-033).
- **Rendimiento**: saber qué pone 1,34 M de triángulos en pantalla; texturas sin comprimir
  (3.103); oclusión en más zonas; medir FPS en hardware real (🔒 dueño).
- **Hallazgos del vídeo de gameplay del 21-10**: pocas ocasiones a ritmo normal, de noche
  calzada negra y conos de luz triangulares, malabares muy básico.
- **Ciudad**: pilares de puente y rotondas con el kit de carreteras; sustituir calzadas
  (decisión consciente de no hacerlo por riesgo con semáforos).
- **Estadios por fuera**: tribunas «falsas», patrocinadores reales y más escudos.
- **Peatones**: tomar coches del tráfico (dijiste «no por ahora»; el atropello con reacción y subir al bus ya están).
- **Esperando al dueño (🔒)**: builds, keystore, licencias, derechos de imagen, música y voces.


## 3. Ruta de lanzamiento (semanas 2–9 del plan de ruta)

Marca «verificar» lo que la memoria del proyecto dice haber hecho en parte (táctica en vivo, porteros, ceremonia, repeticiones): comprobar con el motor real antes de dejarlo o borrarlo.

### Semana 2 (20-10 → 26-10) — Partido I: táctica en vivo
- [ ] Panel en pausa y atajos en vivo: formación, mentalidad (defensiva ↔ ofensiva), presión, línea defensiva.
- [ ] La IA cambia de verdad: altura del bloque, distancia entre líneas, quién sube.
- [ ] Prueba en el banco: con presión alta se recupera más arriba (medido).

### Semana 5 (10-11 → 16-11) — Ciudad hacia «look GTA» posible
- HECHO 27-10 (capturas `docs/04_auditorias/capturas_s5/`, prueba `ideas/s5_detalles`, escena `captura_luz_ciudad`): sol corregido (estaba INVERTIDO: vertical al amanecer y horizontal a mediodía; ahora la altura manda de verdad y la luna sube a ~64°), hora dorada (sol ámbar, calima cálida, ambiente cálido), farolas con charco de sodio y encendido al anochecer, paleta por barrio (3 familias por sector, `FAMILIAS_BARRIO`), desgaste de las paredes modulares (suciedad en la base, churretes, moteado en `bloque_modular.gdshader`) y objetos por bloque (`DetalleFachada`: aires, cable, carteles, grafiti). SOL BAJO (27-10, a petición del líder tras sus capturas Forward+): el asfalto a las 7:00 y 17:24 pasa de luminancia media 29 a ~60 (`bajo` en `_aplicar_hora`: más energía de sol y rebote del cielo cuando la altura es pequeña; las caras al sol y a la sombra siguen distinguiéndose, `sol_bajo_*.jpg`). TEJADOS POR TIPO (`TejadoTipo`, hastiales ya limpios: plano, dos aguas, depósito con antena, jardín; `tejados.jpg`). El asfalto ya trae grano, grietas y manchas de aceite/rodadura (`Texturas.asfalto`); más desgaste con parches se repetiría cada 4 m: sin hacer. CABLES ENTRE POSTES (`ciudad_expansion._cable_entre`: 3 hilos combados en un MultiMesh, 278 vanos en las calles de barrio; `cables_postes.jpg`). NIEBLA POR HORA (27-10, sin captura Forward+ aún: bruma de mañana que se levanta hacia las 9, calima ámbar al ocaso y aire oscuro de noche también con niebla volumétrica ULTRA; `_aplicar_hora`). Los toldos ya los traen los bloques modulares (5 colores por bloque). ARRIATES a pie de fachada (`DetalleFachada`: tierra, matas y flores en una franja de 0,55 m a los lados de la puerta; `arriates_fachada.jpg`): cierra «patios y jardines a nivel de calle» (los patios interiores no se ven desde la calle: sin hacer). PENDIENTE: revisar la niebla volumétrica en Forward+ ULTRA (el dueño en su PC), patios y jardines a nivel de calle (etapa 6). Revisar en Forward+ la fachada a contraluz en la hora dorada.

### Semana 6 (17-11 → 23-11) — Interacción y vida
- [ ] Interacción con objetos: sentarse en bancos, máquinas expendedoras, puertas que se abren, balón suelto en el parque.
- [ ] NPC: más oficios y charlas por barrio y hora, paraguas con lluvia.

### Semana 7 (24-11 → 30-11) — Tutorial y primera hora de juego
- [ ] Indicaciones sobre la pantalla: hay resaltado y flecha sobre el control de cada misión (27-10); falta acortar los textos más largos del mentor (medir en la primera hora con jugadores nuevos).

- [ ] Pruebas de la primera hora: qué ve un jugador nuevo, sin perderse.

### Semana 8 (1-12 → 7-12) — Ultra pulido de todo
- [ ] Recorrido pantalla por pantalla: textos cortados, colores, tamaños, traducciones.
- [ ] Recorrido de cada etapa 1–6 con capturas.

### Semana 9 (8-12 → 15-12) — Auditoría y lanzamiento
- [ ] Auditoría completa y prueba larga de 10 temporadas.
- [ ] Optimización de gama baja.
- [ ] Lista para el dueño: builds, licencias, tienda (🔒).

Fuera de alcance: multijugador online (requiere servidor).


### Qué falta para un juego lanzable


| Área | Estado | Falta |
|---|---|---|
| Estabilidad | banco verde, sin cuelgues conocidos | prueba larga de 10 temporadas en cada modo, sin errores en la consola |
| Rendimiento | medido en triángulos y CPU | FPS en un móvil y un PC de gama baja reales (🔒 del dueño) |
| Tutorial | existe (970 líneas) | más corto, por capas, que se pueda saltar y repetir, con indicaciones sobre la pantalla |
| Partido jugable | básico completo | táctica en vivo, porteros, presets, cinemáticas, ayudas |
| Interfaz | mucha información | coherencia de estilo, diálogos (hecho el 13-10), accesibilidad (texto grande, daltónicos) |
| Audio | 🔒 música del dueño | efectos de interfaz y ambiente revisados |
| Guardado | copias rotativas, huella y versiones (`pruebas/ideas/sav_guardado.gd`); aviso visible si se recupera la copia (menú y arranque 3D) o si no se puede abrir (27-10); topes de historiales VERIFICADOS el 27-10 con `pruebas/sonda_memoria.tscn` (6 temporadas: 0,54 → 1,10 MB; todas las listas con tope: pubs 80, libres 80, portadas 60, mensajes 60, libro 60, posts 50, historial y moral del jugador 12; lo que crece, ~56 KB/temporada, es `clubes`) | medir 30 temporadas y desglosar `clubes` si el guardado pasa de 3 MB |
| Legal | política ficticia | licencias de recursos y caras reales (🔒 del dueño) |
| Tienda | — | iconos, capturas, descripción, clasificación por edad (🔒 del dueño) |


También abiertos del ROADMAP: juegos mentales en el túnel antes de salir a la cancha (B4); medir FPS en el PC modesto.


### Detectados en pruebas y aún sin cerrar

- **Pruebas visuales tras unir main 72aa8812** (01-11, segunda sesión): con las referencias nuevas, en este contenedor las 20 pantallas cambian solo en el indicador del móvil (abajo a la derecha, sale ~8 px más arriba que en la referencia); la rama no toca la interfaz, así que viene de main o del estado de la máquina. Antes hay que hacer `godot --headless --import` (sin él, el pelo del Drive de los retratos no sale y fallan todas). Revisar en el PC del dueño antes de regenerar.
- **«Ciudad: dos armados de una vez dan lo mismo» intermitente** (01-11, `probar_por_partes` en especiales): con el mismo código salen 3-10 filas distintas (tope 12) y a veces pasa del tope; también sin los cambios del día. Lo diferido (gente, tráfico) no es igual entre dos armados: con `PARTES_DETALLE=1` se ven las filas: (1) edificios «low-detail-building» de `city_builder` en los bordes (x ≈ ±231 y x = 717,5) que cambian de modelo o salen 0-2 veces (no viene de `ciudad_expansion._pisos`, que sale igual); (2) un peatón que saca o no el móvil (normal, depende del tiempo). Aparte: `vestir_torre(nodo, get_instance_id())` (city_builder_p7/p9/p11) elige el color de las torres por el id del nodo, distinto en cada arranque: pasarlo a la posición.
- **«Sin castellano en alemán» intermitente** (31-10): con el mismo código falló 2 de 4 veces (1 frase) y pasó 2; al guardar la salida no se repitió (01-11: pasó otra vez, 6 min). Seguramente un texto que depende del momento (aviso, noticia). Si vuelve a fallar, guardar la salida (`RECORRIDO_IDIOMA=de RECORRIDO_CASTELLANO_MAX=0`) y traducir la frase con `sumar_traducciones.py`.
- **TIRO_PULIDO** (dueño 27-10: encender y pulir más). ENCENDIDO el 27-10 (`PMOT_TIRO=0` lo apaga). Medido con el mismo once a los dos lados, 6 partidos: encendido tal cual daba 0,8 goles por partido porque el portero paraba el 89 % de lo que iba dentro; con la parada que cuesta más lejos del cuerpo y con tiros fuertes (`PARADA_LEJOS` 0,5) quedan 2,3 goles, 20 % de conversión y 59 % de paradas (real: ~2,7, ~11 % y ~70 %). Queda para la pasada final del motor: más tiros por partido (hoy ~12; real ~25), el portero algo más seguro y el pie malo.
- **Pasto del Drive** (27-10): `grass.blend` son dos matas de hierba SILVESTRE (60-90 cm, ~6.000 vértices cada una), no césped de cancha. Subidas como `assets/pasto/mata_1.glb` y `mata_2.glb` (texturas a 512 px); captura `docs/04_auditorias/capturas_ciudad/pasto_drive.jpg`. Uso: parques, bordes de caminos y solares vacíos de la ciudad, repartidas con `MultiMesh` y con distancia de corte; el césped de la cancha sigue en la pasada final del motor.
- **Más regalos del Drive** (27-10), en `assets/regalos/`: `torre_focos.glb` (torre de iluminación de 23 m, para los focos de los estadios) y `sillon_oficina.glb` (para el despacho del DT y la oficina de la directiva). Captura `docs/04_auditorias/capturas_estadio/regalos_torre_sillon.jpg`. Faltan por colocar. La sala de TV (`.3DS`) y las texturas de libros y tazas quedan en el Drive: se evaluarán al amueblar interiores.
- **Restos de español en otros idiomas** (27-10): el recorrido en alemán con `RECORRIDO_TEXTOS` y un filtro de palabras españolas ya sale limpio (calendario, federación, quejas del vestuario, árbitros, estilos de DT, prenómina, créditos: hechos). Quedan los textos que el recorrido no abre (otras noticias armadas con `%` en `nucleo/`, ficha del país en `ui/eleccion_club.gd` «%d liga%s, %d clubes») y 22 fiestas que el código escribe en el idioma de su país («Thanksgiving», «Fête nationale»), a propósito. Los logros sin sistema muestran «(su sistema aún no está portado)» al jugador: antes de lanzar, ocultarlos o reescribir. Las posiciones (POR, DC, MC…) se quedan en español en todos los idiomas (dueño, 27-10).
- **Pelo de los peatones** (27-10, P4): los mechones se ven duros; suavizar normales empeora. Arreglarlo pide cambiar las mallas de pelo (Quaternius trae más cortes): decisión de aspecto del dueño.
- **Cada gesto con su habilidad, su pie y su clima** (dueño 27-10, HECHO la base: `GestoTecnico`, sonda `s3g_gesto_tecnico`): rosca, vaselina, raso, potente, cabezazo y los pases corto, tenso, al hueco y largo pesan sus atributos; la pierna débil (1-5 estrellas) suma hasta un 48 % de error; el clima del partido (lluvia, tormenta, nieve, niebla) cambia el error, el agarre del portero y lo que rueda el balón. Medido (6 partidos): 2,3 goles en seco, 2,5 con lluvia, 2,7 con nieve. Para la pasada final: rasgos del jugador (los «PlayStyles»), viento en lo que va por el aire, calor y altura en el cansancio, y un ajuste fino con N grande.
- **PASADA FINAL DEL MOTOR (decisión del dueño, 27-10)**: al final del plan, junta la contrapartida táctica (abajo), lo visual, la IA de la CPU, el comportamiento, el físico, el pasto nuevo (`grass.blend` del Drive, 13,9 MB; el contenedor no lo puede bajar porque es privado: el dueño lo comparte «cualquiera con el enlace» o lo exporta a .glb; Blender ya está listo como `bpy` 5.0.1 para convertirlo), las físicas y más sonidos.
- **Táctica sin contrapartida** (27-10, `sonda_motor_dt` ESCENARIO=tactica N=6, umbrales M-414): el local ofensivo (presión y línea altas) tira 12,8 y concede 6,2; el defensivo tira 3,0 y concede 9,8 (y encaja 2,0 goles frente a 1,7). Presionar arriba no deja la espalda libre y el bloque bajo no protege: ofensivo siempre gana. Falta el coste de la línea alta (balones a la espalda, contras) y que el bloque bajo quite tiros. Probado y revertido el 27-10: doblar el peso de la línea sin balón y filtrar más contra línea alta EMPEORA (el bloque bajo pierde 6 de 6 y concede 11 tiros); la causa parece la pasividad de mentalidad 0 + presión 0 (regala el balón). Pide una pasada propia con N grande.
- **Capturas de la ciudad en Forward+ ya no caben** (27-10 tarde): con todo lo sumado hoy (pasajeros, cables, detalles, lluvia, parques) la captura de mediodía también pasa del límite de memoria del contenedor y la mata el sistema. Revisar en Compatibility aquí (posiciones y composición) y la luz en el PC del dueño; o bajar la calidad a MEDIO en `captura_luz_ciudad`.
- **Capturas de noche en Forward+** (27-10): en este contenedor (Vulkan por software) la ciudad con las farolas encendidas (103 luces, 49 farolas de 46 m) pasa de 14,5 GB y el sistema mata la captura, desde las 18:20; también con el código de antes de S5. Mediodía y mañana caben (~7 GB). La noche se revisa en Compatibility o en hardware real; medir FPS de noche en el PC del dueño (§1).
- **Butacas y aficionados** (dueño 27-10, sesión 3): separar un poco a los hinchas (se ven muy juntos), subir la calidad de las butacas, mejorar los accesos y colorear las butacas por nivel según el color del club, elegible en la personalización del menú inicial.
- **Roles por jugador** (como los PlayStyles de FC 26) con efecto en el motor.
- **Red del arco**: onda más ancha y lenta (17-10), techo sin asomar por el larguero. **Cartel del cuarto árbitro**: 20-10 a tamaño real (0,92 × 0,62 m), dígitos con halo, mango y por encima de la cabeza. Desde la toma abierta de TV sigue siendo pequeño (como en la tele de verdad, que corta a un primer plano): pendiente un corte de cámara al cartel.
- Desmarques de ruptura (los peatones: §2.4).
- Pocas ocasiones a ritmo normal; de noche calzada negra y conos de luz; malabares muy básico (verificar tras los arreglos del 21-10).

## 4. Mejoras de código

- [ ] Funciones de más de 100 líneas (medido el 27-10): 171, de ellas 10 de más de 200. Las mayores: `Banco._probar_tanda_c_1` 383, `_probar_guardado_1` 376, `StadiumBuilder._butacas` 322, `MotorJugable._control_usuario` 273, `Estadio._construir` 248, `InteriorInstalacion._piscina` 242 y `_estacion` 234. Partir por responsabilidad, no por tamaño: un corte automático solo separa colas pequeñas (probado el 27-10 y descartado). Hechas el 27-10: `ConstruirMenu._construir` (4 partes), `Noticias._conectar_1` (3) y `PantallaFicha._ver_ficha` (3).
- [ ] Capas `_pN` (233 archivos): repartir por responsabilidad real hasta que la herencia en cadena ya no haga falta (`docs/05_referencia/indice_de_capas.md`).
- [ ] Texturas (medido el 24-10): de las 3.103 sin pérdida, 2.535 son caras reales (prohibido tocarlas sin tu OK), 494 iconos de botones y 40 escudos especiales; el resto ya está comprimido. Hecho: 4 texturas normal/roughness de personajes a 1024 px (−48 MB estimados). DECISIÓN DEL DUEÑO: probar BC7 de alta calidad en una muestra de caras y medir ΔE de piel antes de generalizar; identificar ~24 texturas dinámicas de 1024² sin nombre (~100 MB); reapuntar 38 duplicados (ahorra disco, no VRAM).
- [ ] Oclusión en más zonas de la ciudad (`OclusoresCiudad`); el `_process` de `dibujo_mando`/`MandoGiratorio` ya solo pinta cuando cambia (comprobado el 27-10).
- [ ] **PRÓLOGO en Windows (2-11, urgente del dueño; hecho en parte)**: la pantalla gris con el cartel «…a primera persona» era la `PantallaCarga` congelada porque el prólogo armaba la ciudad entera en un solo fotograma (cuadro más largo 6.997 ms). Hecho: carga por partes con la pantalla viva (970 ms), ciudad recortada al barrio del club (`CityBuilder.modo_prologo`: manzanas 486→92, tramos 1.027→176; sin metro, autopista, eólico ni teleférico), tráfico y peatones al 40 %, tope de dibujo a 380 m (`OptimizarGrada.limitar_vista`), cámara a 650 m (`PrologoDT.activo`), error de script del paraguas corregido. Cifras (render por software; `pruebas/medir_prologo.tscn`, `PROLOGO_COMPLETO=1` mide la ciudad entera): carga 15,9→6,4 s, nodos 58.737→21.511, memoria 1.348→1.007 MB, llamadas de dibujo 4.316→2.627, primitivas 3,61→1,97 M. PENDIENTE: no llega al TRIPLE pedido; el estadio es ~1/3 de la carga y +285 MB (estadio ligero en el prólogo, coordinar con `EntornoEstadio` de la sesión 120 FPS); carga diferida de lo no visible; el CIERRE al pedir moverse en Windows NO se reprodujo (sin GPU): el dueño debe probarlo y, si sigue, medir con `herramientas/medir_mi_pc.bat`.
- [ ] `pruebas/probar_por_partes` inestable (2-11): (1) «dos armados dan lo mismo» oscilaba por esperar un número fijo de 10 cuadros a que se cree lo diferido (gente, tráfico): ahora espera a que el árbol esté quieto 8 cuadros seguidos (`_esperar_estable`), pendiente de ver en el CI; (2) «cede fotogramas (0)» NO es azar: falla siempre en local (y por señal `process_frame` también da 0, así que no es el contador del motor): estadio y ciudad por partes NO ceden ni un cuadro aquí, aunque `por_partes` está puesto; en el prólogo real SÍ ceden (cuadro más largo 970 ms). Falta averiguar qué camino de `abrir` se salta los `_respiro`/`_marca` (¿caché de la segunda construcción?).
- [ ] Escenas de prueba que nadie lanza (27-10, orden 14: reutilizar antes de borrar). Contadas de nuevo: 354 en `pruebas/` sin mención, casi todas capturas y diagnósticos que se lanzan a mano (se quedan). De las 14 `prueba_*`: 6 siguen pasando y ya corren en `especiales.sh` (contador de FPS, dominadas, minijuegos nuevos, motor jugable; ceremonia de carrera y práctica en `todo`). Revisadas el 2-11: `prueba_repeticion` ARREGLADA (disparaba a un cuadro fijo; ahora espera 8 s grabados) y en `especiales.sh`; `prueba_descanso_3d` sin pantalla solo llega al minuto 43 en 7 min (el reloj del partido va a tiempo real: darle un reloj acelerado o correrla solo con GPU); `prueba_intro` y `prueba_casa_kenney` necesitan pantalla (`captura.sh`) y no afirman nada: son capturas, pasarlas a `pruebas/captura_*` o retirarlas. Sin veredicto propio: `prueba_alineacion_indebida`, `prueba_carrera_flujo`, `prueba_ciudad_modelos` (inventario). Fase 0: repasar si queda algún módulo de `visor/`/`nucleo/` sin prueba directa.
- [ ] Escenas de prueba que nadie lanza (2-11, orden 14): las 62 que pasan ya corren en `especiales.sh` (bloque «reutilizadas», 3 lentas en `todo`). Rotas, a arreglar o retirar: `prueba_repeticion`, `prueba_descanso_3d`, `prueba_intro`, `prueba_casa_kenney` (de antes) y, nuevas: `ideas/f0m_visor_ciudad` (las carreteras ya no bajan 4 tramos: 21), `ideas/pers_ropa` (sin mochilas en la muestra), `ideas/pest_estadio` (ya no existen los `BastidorFoco*`); sin veredicto (no son pruebas): `auditar_textos_movil`, `ideas/f1o_video`. `ideas/pani_pasos` (guardia lateral con los pies a −861 m del césped) falla en el CI y con una `user://` sucia, y pasa en una carpeta limpia local: se dejó FUERA de `especiales.sh` hasta saber por qué. Siguen sin mención ~340 escenas `captura_*`, `diagnostico_*`, `video_*` y `hoja_*`: se lanzan a mano.
- [ ] C++/GDExtension solo si el perfil en hardware real lo pide.
- [ ] 23 imágenes ≥ 2048 px que no lo necesitan: bajarlas a 2048 (auditoría 3, §4; no las caras sin tu OK).

## 5. Mejoras abiertas del catálogo (356)

Prioridad P0–P3 · estado · qué falta. Reverificar la fila antes de construir (algunas pueden estar ya hechas: el TOP anterior tenía hechos sin marcar).


### F0 cimientos (33)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-379 | P2 | PARCIAL | 70 funciones > 120 líneas (medido 28-10): las 5 peores eran `_butacas` 354, `_control_usuario` 274, `Estadio._construir` 254, `_piscina` 239, `_estacion` 233 | 28-10: partidas `_butacas` (stadium_builder_p6: paleta, poblar, hinchas, montar; hash idéntico de todos los MultiMesh en 2 calidades × 3 clubes), `Estadio._construir` (HUD y cajón aparte) y `_piscina` (8 zonas; mismo árbol de nodos). `_control_usuario` partido con la huella de `igualdad_motor` idéntica. Quedan 66 (siguientes: `_estacion` 233, `_ver_ficha` 212, `_pintar_dispositivo` 211) |
| M-382 | P2 | PENDIENTE | Sin análisis estático | sin gdlint |
| M-383 | P2 | PENDIENTE | Tipado: muchos `Dictionary` sin forma (jugadores del motor) | sin `JugadorMotor` tipado |
| M-384 | P2 | PARCIAL | `Mundo` 2.921 líneas, `Roles` 2.065, `Prensa` 2.541: acoplamiento alto | sin extraer servicios (28-10: ya en capas de <450 líneas; queda repartir por responsabilidad) |
| M-387 | P2 | PENDIENTE | Mensajes de error silenciosos (`return` sin aviso) | sin registro de errores |
| M-392 | P3 | PARCIAL | `MotorLibre` (567 líneas): NO es código muerto | 28-10: lo usa `OcasionesDT.lectura` (las ocasiones jugables del partido del DT: lee la jugada y propone pase, conducción o tiro). Lo que sobra es su prueba `_probar_motor_libre`, la más lenta del banco (38 s de 129): acortarla (menos partidos simulados con los mismos umbrales) |
| M-393 | P2 | PENDIENTE | Código de pruebas mezclado con herramientas (`herramientas/*.ps1`) | sin separar |
| M-394 | P2 | PENDIENTE | Herramientas `.exe`/`.cs` binarias en repo | `herramientas/*.exe` siguen en el repo |
| M-396 | P2 | PENDIENTE | Convenciones: mezcla de español/inglés en nombres | sin guía de estilo |
| M-397 | P2 | PENDIENTE | Comentarios muy extensos (valioso pero ruidoso) | sin ADRs |
| M-398 | P2 | PENDIENTE | Sin documentación de arquitectura actualizada (`LEEME.md`) | LEEME sin diagrama |
| M-401 | P2 | PENDIENTE | Dependencia de nombres de nodo (`find_child`) frágil | sin cambio |
| M-402 | P2 | PENDIENTE | Duplicación de carga de JSON (`Datos` 212 tablas) | sin carga perezosa |
| M-406 | P2 | PENDIENTE | `Retrato3D` no se ejercita en headless | sin prueba con xvfb |
| M-410 | P2 | PARCIAL | Pruebas de rendimiento con umbrales | la simulación tiene umbral (`eq_diez_temporadas`, EQ_MODO=rendimiento: la semana del año 20 < 2× la del año 1 + 20 ms) y el banco mide ms por paso del motor; faltan umbrales de FPS en hardware real (dueño) |
| M-417 | P2 | PENDIENTE | `herramientas/banco.sh` sólo bash | sin unificar |
| M-418 | P2 | PENDIENTE | Sin informes de cobertura | sin cobertura |

### F1 entrada al juego (36)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-280 | P1 | PARCIAL | Clases de UI que ninguna prueba nombra | 2-11: visor y núcleo ya al 100 % (`vis_sueltos`, `_probar_nucleo_sueltos`); en `ui/` 62 clases no se nombran, pero las pantallas las recorre `recorrido_pantallas` (34 secciones, 9 idiomas); falta prueba directa de las piezas que el recorrido no abre (tanda, garra, vitrina, móvil en la mano) |
| M-284 | P2 | PARCIAL | Lectura de pantalla (TTS) |  2-11: `LectorPantalla` lee el control con foco y, en cola, los avisos emergentes y las notificaciones del móvil (`anunciar`); falta leer las tablas largas fila a fila y probarlo con voces reales en el PC del dueño |
| M-435 | P2 | DESCARTADA (líder, 2-11; el dueño puede revertirla) | Sin gatillos analógicos para potencia de pase | LT y RT ya son modificadores del tiro y del pase en el esquema tipo FC (raso, rosca, potente, vaselina con LB): darles la potencia rompería esas combinaciones. Si se quiere, iría como esquema alternativo en Controles |
| M-436 | P2 | PENDIENTE | Sin giroscopio para cámara en primera persona (móvil) | sin giroscopio |
| M-438 | P2 | PENDIENTE | UI de móvil: botones pequeños. Medido el 27-10: un botón de 32 px en un teléfono apaisado (~68 mm de alto, 720 px lógicos) mide ~3 mm; al zoom máximo (140 %) ~4,2 mm; Android pide ~7,6 mm (48 dp). No se arregla con escala: a ×1,8 las pantallas de 1280 × 720 no caben. Propuesta: modo móvil con una columna (lista lateral → pestañas), botones de 64 px y el zoom por defecto a 120 % al primer arranque en móvil. Necesita probarse en un teléfono (dueño). | sin tamaño mínimo |
| M-439 | P2 | PARCIAL | Orientación vertical: diseño propio hecho para menús y partido (ver «VERTICAL» arriba); falta el giro del aparato y Ajustes | sesión 8 |
| M-440 | P2 | PENDIENTE | Sin modo una mano | sin modo una mano |

### F3 vida en 3D (40)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-167 | P1 | PENDIENTE | Calzadas = cajas de asfalto con marcas propias; Kenney sólo… | calzadas propias; losetas Kenney no usadas |
| M-168 | P2 | PARCIAL | Rotondas | 28-10: una rotonda decorativa en un cruce sin rutas (`visor/ciudad_rotonda.gd`); falta rotonda con tráfico que la recorra |
| M-170 | P2 | PARCIAL | Semáforos peatonales con botón | 28-10: botón y hombrecito (`visor/semaforos.gd pedir`); FALLO: el ciclo es global a toda la ciudad y los peatones de `TraficoCiudad` no respetan la fase; cabeza peatonal pequeña |
| M-173 | P2 | PARCIAL | Sin sonido de motor/marchas/derrape | 21-10: el motor del coche suena, sintetizado en vivo con revoluciones y 5 marchas (`visor/motor_coche_sonido.gd`); sin radio |
| M-176 | P2 | PENDIENTE | Sin tipos de vehículo (moto, bus conducible, camión) | solo coche conducible |
| M-180 | P2 | PARCIAL | Metro: sin vendedores/música/anuncios | anuncios en el vagón, vendedor con puesto en cada andén (28-10) y, 3-11, carteles publicitarios en la pared de los andenes subterráneos y megafonía EN TEXTO rotando en las pantallas (`MetroPublicidad`); falta solo la música (el audio lo maneja el dueño) |
| M-182 | P2 | PARCIAL | Tarjeta de transporte y coste | 28-10: `CarteraDT.saldo_transporte`, metro 1 €, teleférico 3 €; falta cobrar el bus, saldo en la app Red y abono |
| M-183 | P2 | PARCIAL | Peatones: rutinas | 28-10: densidad por sector y hora, flujo direccional, maletines y mochilas (`visor/rutina_peatones.gd`); falta rutina por PERSONA (casa→trabajo→casa) |
| M-184 | P2 | PENDIENTE | Sin NPC con nombre y memoria (te reconocen) | sin vecinos con memoria |
| M-185 | P2 | PENDIENTE | Diálogos por oficio (hecho) pero sin ramas ni consecuencias | diálogos sin consecuencias |
| M-186 | P2 | PARCIAL | Interiores: 15 salas; edificios entrables «la mayoría» sin… | gimnasio, piscina, estación central, recreativos con muebles Kenney (15/16-10); 21-10: edificio del club con muebles de verdad del catálogo común `Modulos` (oficina del DT, despacho, sala de vídeo, pr |
| M-189 | P2 | PENDIENTE | Sin bares/restaurantes con minijuego | sin bar con minijuego |
| M-192 | P2 | SIN VERIFICAR | Aceras/pavimentos: 3 texturas | no se midió la variedad de aceras por barrio |
| M-196 | P2 | PENDIENTE | Botes sin sonido/estela | sin estela de botes |
| M-198 | P2 | PARCIAL | Viajes: estación de tren y aeropuerto | 28-10: Estación Central con andén y trenes (`visor/estacion_central.gd`); sin viajes ni aeropuerto |
| M-203 | P2 | PENDIENTE | Sin colisión/oclusión de sonido en interiores | sin filtro de sonido en interiores |
| M-204 | P2 | PENDIENTE | LOD de edificios lejanos con ventanas (cristal) pero sin siluetas… | sin impostores de edificios |
| M-205 | P2 | PARCIAL | `ciudad_expansion.gd` 2.321 líneas y `city_builder.gd` 4.687 | `ciudad_expansion.gd` creció a 3.569 líneas (28-10: ya en capas de <450 líneas; queda repartir por responsabilidad) |
| M-206 | P2 | PENDIENTE | Sin editor de ciudad más allá de terrenos/negocios | sin editor de ciudad |
| M-265 | P2 | PENDIENTE | Avatar propio sin personalización de cuerpo | sin personalización del cuerpo |
| M-266 | P2 | PARCIAL | Sin entrenador como NPC con diálogos sobre el jugador | `relacion_dt` decide minutos; sin entrenador con diálogos |
| M-267 | P2 | PENDIENTE | Transferencias vistas desde el jugador: ofertas sin negociación… | la Carrera no usa `MesaAgente` |
| M-268 | P2 | PARCIAL | Selección nacional: convocatorias sin escena | convocatoria como evento; sin cinemática |
| M-269 | P2 | PENDIENTE | Lesiones del jugador: sin recuperación jugable (fisio) | sin rehabilitación jugable |
| M-270 | P2 | PENDIENTE | Retiro con paso a DT ok; sin homenaje | sin homenaje de retiro |
| M-271 | P2 | PENDIENTE | Sin contratos de imagen propios | sin contratos de imagen |
| M-272 | P2 | PENDIENTE | Fuera de juego, cambios, selección ✅; sin protestas/tarjetas del… | sin expediente disciplinario |
| M-273 | P2 | PENDIENTE | Rivales NPC por `Fama`; sin rivalidades nominales | sin rival de posición |
| M-276 | P2 | SIN VERIFICAR | Pruebas: modo cubierto en `prueba_modos`; faltan casos extremos… | no se comprobaron los casos extremos en `prueba_modos` |

### F4 personas (56)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-359 | P1 | PENDIENTE | Estadio real en 46 % de clubes (C-01) | 46 % |
| M-209 | P2 | PARCIAL | La prueba larga sólo comprueba que no hay errores, no el equilibrio | `prueba_larga` comprueba medias en rango; sin métricas de equilibrio |
| M-211 | P2 | PARCIAL | Cláusulas de rescisión: sin «cláusulazo» automático de IA | el mercado reconoce pagos de cláusula (`Mercado` l.345); sin «clausulazo» de IA deliberado |
| M-213 | P2 | PARCIAL | Sin agentes con personalidad reflejada en comisiones (hay 4 perfiles) | perfiles de agente (`MesaAgente.PERFIL`); sin historial |
| M-214 | P2 | PENDIENTE | Cesiones con opción de compra obligatoria sin seguimiento de… | cesiones sin bonus por partidos |
| M-216 | P2 | SIN VERIFICAR | Fichajes de IA entre clubes poco visibles | no se comprobó la noticia semanal de traspasos de IA |
| M-218 | P2 | PARCIAL | Sin límite de fair play financiero explícito (hay aviso) | tope salarial con administrador (`Insolvencia`); sin ratio salarial general |
| M-220 | P2 | PARCIAL | Sin intereses variables según reputación y mercado | préstamos con tasas por tipo (`Banco`); no dinámicas |
| M-221 | P2 | SIN VERIFICAR | Impuestos y derechos de TV simplificados | derechos de TV con multiplicador; no se comprobó el reparto por país |
| M-222 | P2 | PARCIAL | Venta de entradas: precio único | precio único por partido; sin sectores ni precio por rival |
| M-223 | P2 | PARCIAL | Abonos/socios: modelo simple | socios por temporada (`Reputacion`) y campaña de abonos (`Hinchada`); sin lista de espera |
| M-225 | P2 | PENDIENTE | `Comercial` zonas de patrocinio manual para el usuario; IA sin… | sin noticias de contratos comerciales de IA |
| M-229 | P2 | PENDIENTE | Academia: sin variedad de métodos pedagógicos | sin planes pedagógicos |
| M-230 | P2 | PARCIAL | Cantera 1.422 líneas con representantes; pocos hitos narrativos | `EventosCantera`: torneo, dejarlo, padres, convocatoria; sin lesión/mudanza |
| M-231 | P2 | PARCIAL | Ojeadores con sesgo regional (ya) sin informes visuales (campo vs… | ojeadores con personalidad que infla/recorta informes (`Ojeadores`); sin informe visual |
| M-232 | P2 | PENDIENTE | Staff de 6 puestos sin personalidad ni relaciones entre sí | staff sin química |
| M-233 | P2 | PENDIENTE | Entrenamiento 1.117 líneas; sesiones sin visualización 3D | sin escenas de entrenamiento |
| M-234 | P2 | PENDIENTE | Maestrías con efecto en partido poco visible | maestrías sin registro en el resumen |
| M-236 | P2 | PENDIENTE | Vestuario 1.436 líneas con grupos; sin conflictos con… | sin discusiones visibles en partido |
| M-239 | P2 | PARCIAL | Junta/accionistas: sin asambleas jugables | asamblea en insolvencia/federación; no jugable |
| M-243 | P2 | PARCIAL | Redes sociales: seguidores y comentarios; sin bots/trolls/tendencias | tendencias y hashtags (`Redes.tendencia`); sin trolls |
| M-244 | P2 | PENDIENTE | Sin entrevistas en TV con escena 3D variada (existe rueda de… | un solo set de rueda de prensa |
| M-245 | P2 | PARCIAL | Federación 999 líneas con reglas; votaciones sin presentación | votaciones con señales (`Federacion`); pantalla de sesión sin comprobar |
| M-248 | P2 | PARCIAL | Mundial de clubes/selecciones (1.012 líneas) con pocos modos | convocatorias con efecto en el físico (`Selecciones`); sin concentraciones |
| M-249 | P2 | PARCIAL | Hinchada con segmentos; sin rivalidades por barrio | clásico con incidentes (`Prensa`); sin rivalidades por barrio |
| M-250 | P2 | PENDIENTE | Ciudad y club: terrenos/negocios; economía simplificada | negocios sin depender de la ocupación |
| M-251 | P2 | PENDIENTE | Gente del club (10 personas) sin crecimiento de relaciones | gente del club sin afinidad |
| M-252 | P2 | PARCIAL | Trabajadores/instalaciones con eventos; sin huelgas/negociación | huelga de hinchas y por sueldos impagos (`Prensa`); sin negociación laboral |
| M-253 | P2 | PENDIENTE | Licencia de entrenador: exámenes; sin cursos con coste y tiempo | licencia sin cursos |
| M-254 | P2 | PARCIAL | Vida del DT (bienestar, casa, familia): sin impacto en rendimiento… | estrés en `VidaDT`; efecto en rendimiento sin comprobar |
| M-257 | P2 | PENDIENTE | Historia del club generada; sin línea de tiempo interactiva | sin línea de tiempo |
| M-258 | P2 | PENDIENTE | Documental de temporada: guion fijo | documental con guion fijo |
| M-259 | P2 | PARCIAL | Clima sin efecto en el desgaste | el clima ya cambia error, agarre y roce (`gesto_tecnico.gd`); falta su efecto en cansancio (calor, altura) |
| M-261 | P2 | PENDIENTE | Sin modo historia/campaña guiada | sin modo historia |
| M-361 | P2 | SIN VERIFICAR | `tablas.json` en una línea (D-04) | no se revisó `tablas.json` |
| M-362 | P2 | PENDIENTE | `ESTADIO_CLUB` por nombre (frágil con leetspeak) | `ESTADIO_CLUB` por nombre |
| M-363 | P2 | PENDIENTE | Mapa ficticio→real (`CLUBES` en `base_ficticia.py`) sin prueba de… | sin prueba de cobertura |
| M-364 | P2 | PENDIENTE | Países: 23 con 16 clubes (Chile 32) | sin ligas nuevas |
| M-367 | P2 | PENDIENTE | Calendario con feriados (`Calendario` 350 líneas); sin zonas horarias | sin zonas horarias |
| M-368 | P2 | PENDIENTE | Jugadores históricos/leyendas sin mecánica de «cromo» | leyendas sin cromo |
| M-369 | P2 | PENDIENTE | Nombres de estadios ficticios sin apodos amplios (`GuinosEstadio`) | `GuinosEstadio` sin ampliar |
| M-370 | P2 | PENDIENTE | Historia de clubes (`historia_clubes.py`) por club; verificación… | sin prueba de coherencia |
| M-371 | P2 | PENDIENTE | Himnos y cánticos sin letra | himnos sin letra |
| M-372 | P2 | PENDIENTE | Retratos de DT/presidente generados; sin variedad étnica medida | sin estadística por país |
| M-376 | P2 | PENDIENTE | Premios individuales sin votación explicada | sin votación explicada |
| M-377 | P2 | PARCIAL | Sin clima por país/estación realista | `Clima.del_partido` por país/estación; sin tabla completa verificada |
| M-378 | P2 | PENDIENTE | Sin datos de ciudades (población, altura) para estadios | sin datos de ciudades |

### F5 club ampliado / pulido (26)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-003 | P1 | PENDIENTE | Las formas no varían de forma continua | `RETRANQUEO_BANDEJA` sigue siendo constante; sin parámetros por club |
| M-004 | P1 | PENDIENTE | El «estadio real» sólo copia forma/niveles/techo/pista/focos/fachada | `ESTADIOS` de `herramientas/estadios_reales.py` sin color de pista/vallas, año ni pantalla |
| M-005 | P1 | PENDIENTE | Colores propios de butacas en 47 de 176 estadios reales | `ASIENTOS` sigue con 47 de 176 estadios |
| M-014 | P1 | PARCIAL | Sin diferencia día/noche en el aspecto de la iluminación… | 21-10: el haz de cada farola de la ciudad es un cono volumétrico falso con degradado y sin contorno (`visor/cono_farola.gdshader`); sin haces de los focos del estadio |
| M-017 | P1 | PENDIENTE | Túnel de vestuario sólo en +Z | túnel fijo en la tribuna +Z (`tunel_x`) |
| M-007 | P2 | PENDIENTE | Sin variación de entorno por país (palmeras, nieve, montaña de fondo) | sin fondo lejano por país/clima en el estadio |
| M-009 | P2 | PARCIAL | Sin voladizo/cubierta visible en estadios sin techo | techo «visera» y cerchas vistas desde fuera (`FachadaEstadio`); sin visera parcial con estructura por sector |
| M-010 | P2 | PENDIENTE | Sin carteles de pared (patrocinadores, fechas, escudo) fuera del campo | sin carteles en muros exteriores (la fachada tiene rótulos de puerta, no publicidad) |
| M-012 | P2 | PENDIENTE | Vallas LED con la misma rotación de marcas inventadas (30) | `VallasLed` sin catálogo ampliado; `Auspicio` tiene 38 marcas |
| M-013 | P2 | PARCIAL | Banderas de esquina/córner genéricas | banderines con tela y color del asiento del estadio (`_corners`); sin banderola del país ni viento |
| M-015 | P2 | PENDIENTE | El césped usa 12 dibujos, asignación por hash | el dibujo de césped sigue por hash (`Club._CESPED`); no hay campo en estadios reales |
| M-016 | P2 | PENDIENTE | Sin campo de entrenamiento/calentamiento visible fuera del estadio | sin campo anexo con calentamiento |
| M-018 | P2 | PENDIENTE | Banquillos de un solo diseño por preset | `EST_BANQUILLOS` sin ampliar |
| M-019 | P2 | PARCIAL | Sin zona de prensa/cabinas de TV visibles en el graderío | cabina de prensa en `estadio_extras.gd`; sin vidrio ni NPC de prensa dentro |
| M-020 | P2 | PARCIAL | Sin palcos reales (`palcos` existe como instalación) | palcos como pieza de `estadio_extras.gd` y `ClubDentro.PALCO`; sin interior con personas |
| M-022 | P2 | PENDIENTE | Sin sonido espacial por sector (cantos locales vs visitantes) | solo `servicios_vida.gd` usa `AudioStreamPlayer3D` en el juego |
| M-024 | P2 | PARCIAL | Sombras de la grada sobre el campo no cambian con la hora real del… | `Ambience` usa la hora elegida para el estadio, no la hora/estación real del partido |
| M-025 | P2 | PARCIAL | Poca variedad de torres de luz (4 esquinas) | focos «corona/mixto/halo» además de torres; no 6/8 torres por forma |
| M-027 | P2 | PENDIENTE | Sin variación de terreno exterior (cerro, mar, río) según `rasgo` | el texto `rasgo` no elige fondo ni niebla |
| M-028 | P2 | PARCIAL | El estadio propio y el rival usan caminos de construcción… | `pruebas/captura_mismo_estadio.gd` (manual); no está en el banco |
| M-029 | P2 | PARCIAL | Ampliaciones del estadio propio sin animación de obra detallada | andamios, grúa torre y vallado (`estadio_extras.gd`, `EstadioPropio.obra`); sin polvo ni operarios |
| M-031 | P2 | PENDIENTE | Sin mapa de estadios (galería) para ver todos los del juego | sin pantalla «Estadios del mundo» |
| M-032 | P2 | PARCIAL | Sin ficha de estadio con datos reales (capacidad oficial, año,… | aforo OFICIAL en la ficha (`ui/estadio.gd:544`); faltan año y superficie |
| M-023 | P3 | PARCIAL | Sin clima visible en el estadio más allá de lluvia/niebla (nieve,… | nieve, lluvia y niebla (`Precipitacion`, `Clima`); sin calima/polvo ni charcos que reflejan |
| M-026 | P3 | PARCIAL | Estadios sin nombre dibujado en fachada | rótulos en las puertas de la fachada; sin nombre grande del estadio por tipografía de club |
| M-030 | P3 | PENDIENTE | Sin estadio nacional/selección con identidad propia | sin sedes de selección con arquitectura propia |

### F6 pulido (82)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-035 | P1 | PARCIAL | Sin bufandas/banderas/camisetas del club en la mano | banda de bufandas y tifo en grada (`StadiumBuilder` «bufandas»/«tifo»); sin mallas en la mano |
| M-054 | P1 | PENDIENTE | Ropa con volumen sólo en retratos (K-02) | `VestidorQ.ropa_aparte` sigue apagado en partido por coste |
| M-055 | P1 | PARCIAL | Sin arrugas dinámicas según animación | pliegues de tela estáticos (`pliegues()` en el shader); no dependen de la animación |
| M-058 | P1 | PARCIAL | 30 marcas de patrocinio (K-03) | 70 marcas en `Auspicio` (2-11: +34 ficticias en `tablas.json`; banco 0 fallos); meta cumplida, falta solo revisar su logo en captura |
| M-079 | P1 | PENDIENTE | Retrato real 13 % (base real) | 13 % con retrato real; descarga bloqueada por la red |
| M-091 | P1 | PARCIAL | Botines: variedad añadida, pero sin modelos distintos por forma | `VestidorQ._botin_de` varía modelo/color por dorsal; no hay mallas de bota alta/calcetín |
| M-094 | P1 | PARCIAL | Animación de caminata del DT: 6 estilos (✅) | «Mi caminata» con 6 estilos para el DT; peatones y jugadores no |
| M-037 | P2 | PENDIENTE | Sin sector «barra brava»/torcida con comportamiento diferente (de… | sin sector ultra con bengalas/humo |
| M-038 | P2 | PENDIENTE | Hinchas sentados con piernas invisibles (se cortan en la cadera) | público horneado cortado en la cadera |
| M-039 | P2 | PARCIAL | Tres niveles de detalle; el salto «cerca→medio→lejos» puede verse | detalle por distancia por tramos de grada (16-10, 2,24→1,72 M tris); sin mezcla por dithering |
| M-041 | P2 | PENDIENTE | Sin niños, familias ni asistentes en sillas de ruedas | sin niños/familias/sillas de ruedas en grada |
| M-042 | P2 | PARCIAL | Ocupación = reputación, no asistencia del partido | ocupación = asistencia de `Finanzas` (depende del precio); no por sector |
| M-043 | P2 | PENDIENTE | Sin diferencia de público por competición (final vs liga) | sin decoración especial en finales |
| M-044 | P2 | PARCIAL | Gol local: ceremonia de público única | 20-10: además del confeti/bengalas, onda de saltos desde ese fondo, la ola con el partido decidido y la protesta; falta variar por sector |
| M-048 | P2 | PARCIAL | Fotógrafos/camarógrafos pocos y repetidos | `visor/camarografos_siguen.gd` (giran con el balón, uno camina); siguen siendo pocos |
| M-056 | P2 | PENDIENTE | Sin sudor/barro/lluvia en la camiseta | sin uniform de barro/mojado |
| M-060 | P2 | PENDIENTE | Patrocinio fijo por club entre temporadas, sin contratos de IA que… | sin renovación/cambio de patrocinador de clubes IA |
| M-061 | P2 | PENDIENTE | Sin patrocinador en la parte trasera del pantalón ni en las medias | sin zonas `short_trasero`/`medias` |
| M-064 | P2 | PENDIENTE | Falta ornamento reconocible (león, águila, estrella, castillo,… | sin biblioteca de símbolos (solo el almenado) |
| M-065 | P2 | PENDIENTE | Texto/iniciales ilegibles <24 px | sin prueba de legibilidad a 24 px |
| M-067 | P2 | PENDIENTE | Sin escudo animado en el marcador al gol | sin pulso del escudo en el marcador |
| M-069 | P2 | PENDIENTE | 12 diseños con reparto casi uniforme (C-06) | sin pesos en el reparto de diseños |
| M-070 | P2 | PENDIENTE | Sin segunda/tercera camiseta con diseño propio | sin tercera equipación |
| M-071 | P2 | PENDIENTE | Portero: color por contraste, sin diseño | portero solo por contraste; guantes como color de accesorio |
| M-074 | P2 | PENDIENTE | Medias/pantalón: diseño correcto pero sin franjas del fabricante | sin franjas del fabricante en medias/pantalón |
| M-075 | P2 | PENDIENTE | Dorsal sin fuente propia por club | dorsal en siete segmentos, una sola fuente |
| M-077 | P2 | PENDIENTE | Retrato con camiseta de volumen pero sin patrocinio en pecho visible | encuadre del retrato sin cambiar |
| M-078 | P2 | PARCIAL | Foto real de equipación sólo con pack real (C-08) | 2D y 3D con cuello/costuras desde el 14/17-10; diferencia con foto real sigue |
| M-080 | P2 | PENDIENTE | Fotos agachadas aún oscuras/deformadas | fotos agachadas sin re-detección (límite anotado en MOTOR_CARAS.md) |
| M-082 | P2 | PENDIENTE | Altura sólo por escala global | sin proporciones variables |
| M-083 | P2 | PARCIAL | Sin tatuajes/cicatrices por jugador salvo civiles | tatuaje solo en ropa civil (`equipacion_q.gdshader` `tatuaje`); no en jugadores |
| M-084 | P2 | PENDIENTE | Biblioteca de caras = 72 mezclas | biblioteca de 72 caras |
| M-085 | P2 | PARCIAL | Envejecimiento visual de jugadores (canas, arrugas) no ligado a `edad` | 21-10: canas desde los 32 en los inventados (`Cara.look_de`, a uno de cada cuatro casi nada); los reales llevan el color de su foto; arrugas pendientes |
| M-086 | P2 | PENDIENTE | Expresiones faciales limitadas a `Expresion` básica | `Expresion` sin emociones nuevas |
| M-087 | P2 | PARCIAL | Sin parpadeo/respiración idle variados | parpadeo en el DT/`Expresion`; sin respiración idle en jugadores |
| M-089 | P2 | PENDIENTE | Barbas/cejas por capas apagadas (manchas) | barba/cejas por capas siguen apagadas |
| M-090 | P2 | PENDIENTE | Guantes de portero sólo color | sin geometría de guante |
| M-092 | P2 | PENDIENTE | Cordones/tacos sin geometría | sin relieve de cordones/tacos |
| M-093 | P2 | PENDIENTE | Sin canilleras/vendas/cintas visibles | sin canilleras/vendas en partido |
| M-096 | P2 | PENDIENTE | Transiciones entre clips con mezcla fija 0,25 s | mezcla fija entre clips |
| M-097 | P2 | PARCIAL | Retarget con pies que patinan | IK de piernas solo en la ciudad (`AnimQuaternius._ik_pierna`); sin foot locking en partido |
| M-099 | P2 | PARCIAL | Cuerpos sin colisión entre brazos/piernas (solapes sólo en XZ) | cuerpos que se empujan y duelos en el motor (`MotorJugable._cuerpos`, 17-10), en 2D; sin cápsulas 3D |
| M-101 | P2 | PARCIAL | Celebraciones por rasgo (ya) pero sólo 2/3 propias | carrera al córner y abrazo (`_ia_celebracion`); sin 10 por rasgo ni coreografías |
| M-102 | P2 | PARCIAL | Sin reacciones de banquillo coordinadas | celebra el gol (`_banca_celebra`); 21-10: protesta la roja de uno de los suyos (`_banca_protesta`); 27-10: se llevan las manos a la cabeza (o brazos cruzados / inquietos) ante la lesión de uno de los suyos (`_banca_lesion`, `BanquilloVivo.LESIONES`; sentados sin levantarse y de pie con «lamento»; `ideas/vat_hinchada` comprueba los clips; SIN captura en partido, solo prueba) |
| M-103 | P2 | PARCIAL | Lesiones sin animación específica | clip de dolor (`AnimQuaternius`); sin camilla ni médicos en campo |
| M-108 | P2 | SIN VERIFICAR | Mascotas con animación limitada | `MascotaQ` tiene animaciones propias; no se comprobó si son 6 ni si hay rutas |
| M-109 | P2 | PARCIAL | Niños de ceremonia con una misma malla | niños con cuerpos de peatones variados (`CeremoniaPartido`); sin comprobar variedad de malla |
| M-110 | P2 | PENDIENTE | Sin voces/murmullos de jugadores | sin voces de jugadores |
| M-112 | P2 | PENDIENTE | Sin avatar del usuario en el estadio como jugador (carrera) con su… | la Carrera de Jugador no usa el cuerpo del creador |
| M-444 | P2 | PARCIAL | Fuga de texturas GL al cerrar `prueba_carrera_flujo` | 28-10: acotada a «al cerrar el partido jugable» (2 texturas de 256², solo al apagar); añadidas cachés a `Cierre.CACHES`; sin resolver |
| M-445 | P2 | PENDIENTE | Pruebas que no caben en 5 min con render por software (`intro`,… | sin modo rápido del arnés (H-13) |
| M-448 | P2 | PENDIENTE | `auditoria_clubes` tarda ~8 min y `auditoria_datos` ~1 min | sin muestra |
| M-449 | P2 | PENDIENTE | Los informes (`AUDITORIA_CLUBES.csv`) se regeneran a mano | sin CI nocturno |
| M-450 | P2 | PENDIENTE | `pruebas/prueba_*` no tienen un índice de «qué cubre cada una» | sin índice de pruebas |
| M-451 | P2 | PENDIENTE | Duplicación del arnés (`_ok`, `_fallos`) en decenas de pruebas | sin `PruebaBase` |
| M-452 | P2 | PENDIENTE | Salida de pruebas sin código de retorno uniforme (algunas… | varias pruebas acaban con `quit()` sin código |
| M-453 | P2 | PENDIENTE | Pruebas ligadas al azar sin semilla fija en algunos casos (la IA… | sin semillas fijas generalizadas |
| M-454 | P2 | PENDIENTE | Capturas que cambian el estado de la máquina (ajustes de… | sin restaurar |
| M-455 | P2 | PENDIENTE | Pruebas que escriben en `user://ajustes.cfg` real (E-10) | sin ruta inyectable |
| M-456 | P2 | PENDIENTE | `auditoria_tecnica` solo carga las escenas de `escenas/` y `ui/` (4) | sin cambio |
| M-457 | P2 | PENDIENTE | Los nodos huérfanos se miden solo en la pantalla principal | sin cambio |
| M-459 | P2 | PENDIENTE | Cinco idiomas de los nueve nacieron con frases que luego se… | sin flujo único |
| M-460 | P2 | PENDIENTE | Las traducciones nuevas (552) están hechas a mano sin revisión nativa | sin marcar |
| M-461 | P2 | PENDIENTE | Las cadenas con `%s`/`%d` dependen del orden de argumentos; en… | sin placeholders con nombre |
| M-464 | P2 | PENDIENTE | No existe un informe de «frases por pantalla»: no se sabe qué… | sin informe por pantalla |
| M-466 | P2 | PENDIENTE | `datos/idiomas_extra.json` se reescribe entero con cada ampliación… | un solo archivo |
| M-468 | P2 | PENDIENTE | Plurales y géneros en las 69 frases nuevas (p. ej. «%d botones»)… | sin plurales |
| M-470 | P2 | PARCIAL | El banco no ejecuta `auditoria_tecnica`, `auditoria_datos` ni las… | 31-10: la técnica (shaders, escenas, huérfanos: 0 fallos) y la de datos ya van en `especiales.sh`; las visuales, en `especiales.sh todo`. Queda fuera `auditoria_biomecanica`: es un informe, no una prueba (246 animaciones con pies bajo el suelo o articulaciones fuera de rango); va a la pasada de personajes (§2.2e) |
| M-046 | P3 | PENDIENTE | Sin multitudes en accesos, tienda y museo del estadio | sin flujo de NPC antes/después del partido |
| M-076 | P3 | PENDIENTE | Sin parches de competición (campeón, copa) | sin parches de competición |
| M-111 | P3 | PENDIENTE | Sin modo foto con poses y expresión (existe `ModoFoto`) | `ModoFoto` sin poses ni editor de expresión |
| M-465 | P3 | PENDIENTE | Sin pruebas de rendimiento de la carga de idiomas (`idiomas.gd`… | sin carga perezosa |
| M-469 | P3 | PENDIENTE | Falta documentación del flujo de pruebas para colaboradores | sin sección en LEEME |

### F6 pulido (motor) (31)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-147 | P1 | PARCIAL | Hitbox del balón vs cuerpo: 0 casos atravesando (sonda); pero… | balón con altura y cabezazo en el motor; colisión por distancia, sin cápsulas |
| M-120 | P2 | PARCIAL | Córners con 3 variantes | receptor/2.º/3.er lanzador en córners (14-10); sin jugadas ensayadas de `CatalogoJugadas` |
| M-121 | P2 | PARCIAL | Tiros libres: barrera simple | barrera de 4 a 9,15 m fija |
| M-122 | P2 | PARCIAL | Sin saque de banda largo/estratégico | saque de banda largo del usuario (X); sin atributo |
| M-125 | P2 | PENDIENTE | Sin tácticas de medio campo (doble pivote, falso 9) | sin roles con comportamiento propio |
| M-126 | P2 | PARCIAL | Cambios de IA por cansancio (60/70/80') fijos | DT rival cambia en 60/70/80' y ajusta la pizarra según marcador (`_dt_rival`); minutos fijos |
| M-128 | P2 | PARCIAL | Portero con salidas sólo en mano a mano | colocación y achique del portero (14-10); sin salidas aéreas |
| M-134 | P2 | PARCIAL | Sin cámaras de repetición cinematográficas (grúa, dron) | cámaras «Dron orbital» y otras en el rig; la repetición no alterna planos |
| M-135 | P2 | PENDIENTE | Sin cámara de gol del cuarto árbitro/línea | sin cámara de línea de gol |
| M-140 | P2 | PENDIENTE | Descanso: charla de medio tiempo con opciones; sin vestuario 3D… | el descanso vuelve al camarín 2D (`prueba_descanso_3d`); sin cinemática de vestuario |
| M-142 | P2 | SIN VERIFICAR | Rueda de prensa posterior no enlazada con incidentes del partido | no se encontró tema de árbitro/VAR en `Prensa.resolver` |
| M-143 | P2 | PENDIENTE | Sin clima dinámico durante el partido (tormenta repentina) | sin cambio de clima en vivo |
| M-144 | P2 | PARCIAL | Campo se desgasta (barro) sin visualización | desgaste fijo en áreas y punto de penal (`cesped.gdshader`); no evoluciona |
| M-145 | P2 | PENDIENTE | Sin marcas de césped (pisadas, deslizamientos) | sin marcas de pisadas |
| M-146 | P2 | PENDIENTE | Balón con skins pero sin desgaste/mojado | balón sin desgaste/mojado |
| M-148 | P2 | PARCIAL | Sin rebotes contra postes/larguero realistas con física propia | poste y larguero detectados en el motor; rebote sin comprobar |
| M-150 | P2 | PENDIENTE | Sin balones adicionales (calentamiento, reserva) | sin balones decorativos |
| M-153 | P2 | PENDIENTE | Sin modo multijugador local | sin multijugador local |
| M-155 | P2 | PARCIAL | Penal de usuario con barra, sin variantes por pierna | el zurdo usa clips en espejo; penal del usuario sin variante por pierna |
| M-156 | P2 | PENDIENTE | Sin decisión de capitán (protesta) | sin protesta del capitán |
| M-157 | P2 | PENDIENTE | Sin cantos/anuncios del estadio (megafonía con alineaciones) | sin megafonía |
| M-159 | P2 | PARCIAL | Sin himno por país con partitura procedural | un motivo genérico «himno» sintetizado; no por país |
| M-161 | P2 | PENDIENTE | Sin mini-partidos de selección con identidad | sin identidad de selección en el 3D |
| M-163 | P2 | PARCIAL | Sin modo «Director técnico automático» configurable (IA del usuario) | `MotorJugable.autopiloto`; sin perfil configurable |
| M-164 | P2 | PENDIENTE | Sin modo espectador con cámara libre | sin cámara libre en la UI |
| M-154 | P3 | PENDIENTE | Sin online | fuera de alcance, sin documentar |
| M-166 | P3 | PENDIENTE | Sin partidos de fútbol sala/playa/mujeres (género existe) | fuera de alcance, sin documentar |

### F6 pulido (rendimiento) (17)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-469 | P2 | MEDIDO | (01-11, fase 5) Cuánto espera el jugador por semana (`pruebas/zz_medir_semana.tscn`) | 1 país: 68 ms (máx 120); 6 países: 187 ms (máx 242); las 22 ligas a la vez: 665 ms (máx 866), el 87 % en jugar ~200 partidos simulados (2,5 ms cada uno: 1,2 en armar los dos onces, 1,2 en los 90 minutos). `LeyesPais.ajustar_once` con salida rápida si el once ya cumple (0,035 → 0,012 ms). Queda: `Club.once()` ~0,6 ms por las ~275 `media_en` (su memoria compara el diccionario de atributos en cada llamada); bajarlo pide invalidar la memoria al cambiar atributos (riesgo de medias viejas) · (3-11, medido otra vez con `PAISES=TODOS`) semana media ~495 ms; `Club.once()` se llama 466 veces por semana (una por club, ~340 µs: bucle de puestos ~300, `disponibles` 35, `ajustar_once` 17) = ~160 ms. HECHO (3-11): el bucle de puestos de `Club.once` (primera vuelta del once automático) está en C++ (`once_asignar`, copia exacta; respaldo GDScript en `OnceAuto.asignar_gd` para Web/Android sin binario/`DINASTIA_SIN_NATIVO=1`). `probar_nativo` compara los dos en ~466 clubes × todas las formaciones con forma, moral y puestos secundarios al azar: 0 fallos. Por once: 299-318 → 173-192 µs (el resto es preparar los arrays en GDScript); semana con todas las ligas ~500 → ~440 ms (-12 %). igualdad_mundo 998022970 e igualdad_motor 2265294183 intactas. Binarios de Linux y Windows recompilados; Android lo compila el CI (sin el método, cae a GDScript) |
| M-470 | P2 | MEDIDO | (01-11, fase 6 «detectar fallos») Barrido de las 211 pruebas de `pruebas/ideas` que no están en especiales (de 6 en 6, 90 s) | 160 pasan. ARREGLADOS: pelvis de clips en bucle que se disparaba (la guardia lateral del portero a −821 m 0,03 s: `SueloAnim` ahora lineal), sonido «pase» inexistente en malabares, mensaje del patrocinio sin traducir (patrón + 5 zonas), y 5 pruebas viejas (portero con la parada al llegar, taquilla con clima, vitrinas tras el palmarés, editor tras la mudanza a `PantallaEditor`, bandera EUS = región); `p1_movimiento_natural` falla solo con la máquina cargada. PENDIENTES (no de esta sesión): `optA_persona` cadera 4 cm sobre el reposo en «persona/parado»; `pers_ropa` sin mochilas en la muestra; `f0m_visor_ciudad` 21 tramos de carretera al revés; `s3_coste_cruce` 4,15 ms (tope 3,2); `pest_estadio` pide GPU (torres en MultiMesh); 15 pruebas agotan los 90 s (capturas o lentas: `cop_prorroga_tanda`, `fugas_menus`, `s3_rotacion_menus`, `s5_ocasiones`, `s5_tactica_roles`, `s6_paises_lote1`, `sen_conexiones`, `uipl_plantel`, `uipl_textos`, `f0e_resolver`, `f0s_huellas_sonido`, `s3_auditoria_interfaz`…) |
| M-343 | P2 | PARCIAL | Draw calls 700 | 30-10: `EntornoEstadio.agrupar` (coches, árboles y edificios repetidos en MultiMesh): TV 1.158→981, ras de campo 1.645→1.323; el entorno aún suma ~440 llamadas con sus sombras; sin atlas; 3-11 (MÍNIMO): `EntornoOclusion` oculta el entorno tapado por las gradas: TV 560 → 336 llamadas (−40 %); en MEDIO/ALTO/ULTRA sigue entero (decidir si extenderlo) |
| M-344 | P2 | PARCIAL | Overdraw en grada por butacas y personas | 21-10: oclusión en la CIUDAD (`OclusoresCiudad`, 1.120 paredes): −16 % de llamadas a pie de calle (12.128 → 10.192 en 4 calles, `medir_oclusion`); en la grada del estadio sigue sin `OccluderInstance3D |
| M-346 | P2 | PARCIAL | Texturas con compresión (s3tc en PC); sin variantes móviles… | 21-10: revisado: las texturas grandes de 3D ya están en VRAM (s3tc) y limitadas (ropa 4K → 1024); las 3.103 sin comprimir son caras reales, iconos 2D y paletas de Kenney, que se dejan sin pérdida a pr |
| M-471 | P1 | PENDIENTE | Rendimiento en el PC real del dueño | Medir con `herramientas/medir_mi_pc.bat` (juego exportado, `-- --medir`: tiempos de carga, FPS medio/1 %/peor, GPU, si la extensión C++ y el paquete de caras están activos) en la laptop del dueño, una vez con la carpeta `cache` borrada (1.ª sesión) y otra normal. En este contenedor (sin GPU) no se puede medir ni el 1.er fotograma (compilar shaders: 30 s en lavapipe) ni los FPS reales 🔒. 31-10: comprobar también que el juego CIERRA limpio al terminar `medir_mi_pc.bat`: aquí, dibujando por software tras cargar estadio y ciudad, cae con «Segmentation fault» al cerrar (sin dibujar y desde el menú cierra bien; probablemente memoria del servidor, sin confirmar) |
| M-349 | P2 | HECHO | (3-11) Generación de `Mundo` (todas las ligas, 466 clubes) y `Reales.aplicar` (`pruebas/zz_medir_generar.tscn`) | `generar`: ~795 → ~550 ms (poblar plantillas 461 → 336 ms, crear clubes 9, preparar ligas 5); `Reales.aplicar`: ~165 → ~100 ms (4.311 reales). (1) `SorteoNombre` (`nucleo/sorteo_nombre.gd`): las bolsas de nombres ya resueltas por país y región (se buscaban en cada intento, y cada jugador reintenta si el nombre se repite); se invalida en `Datos.usar_base_real`. (2) `Reales._aplicar_en_club` sin `Callable` por jugador: demarcación y grupo de cada puesto una vez por club. Resultado idéntico: huella del mundo 205778320 antes y después, igualdad_mundo 998022970 e igualdad_motor 2265294183 intactas. Sin `WorkerThreadPool`: el mundo se genera con un solo `Azar`, repartirlo cambiaría los resultados |
| M-351 | P2 | PENDIENTE | Hilos: ¿se usan para IA/ciudad? | sin hilos para tráfico/peatones (solo LOD del tráfico) |
| M-352 | P2 | PENDIENTE | GC/alloc en `_process` (Dictionary por jugador) | sin Packed arrays en el motor |
| M-353 | P2 | PARCIAL | Extensión C++ (GDExtension, `nativo/` → `bin_nativo/`) | 30-10: alisado de ropa, terreno, hierba y rampa de ruidos en C++ (mismos bytes, `probar_nativo`). 31-10: Android arm64 lo compila el CI (`nativo-android`, sin FMA) y `nativo-arm` comprueba los mismos bytes en una máquina ARM. Falta: Web (allí se usa la versión GDScript) y más funciones si el perfil lo pide (pelo `_cuero`, `CaraMalla._cargar`) |
| M-358 | P2 | PARCIAL | Arranque del juego hasta el menú | 30-10, juego EXPORTADO: ver el menú 4,5 → 0,75 s. Las autocargas ya no nombran `Partida`/`Reales` (compilaban 562 scripts) y el menú no nombra lo pesado (`ui/inicio_pesado.gd`, cargado en un hilo; partida en curso, perfil y álbum se pintan al llegar, ~5 s). `CompilarFondo` compila el resto en segundo plano DE UNO EN UNO (con 4 a la vez la ciudad iba ~1,5× más lenta: tipos sin resolver). Estadio y ciudad, igual que antes (2,2 y 4,4 s). Falta: separar `Principal` y que `Mundo` no nombre interfaz (charlas → ficha → Principal) para compilar menos en total. (En desarrollo, CERRAR tarda ~9 s: no afecta al juego exportado.) |
| M-472 | P2 | PENDIENTE | Builds: firma y reparto | 30-10: el CI exporta Windows, Linux y Android (APK de depuración) públicos; lo real va en `caras_reales.pck` (`herramientas/empaquetar_caras.gd`, no se publica). Falta (🔒 dueño): APK de publicación firmado con su keystore; subir el .pck a su Drive privado; decidir si el CI también exporta la Web |
| M-476 | P1 | PARCIAL | La ciudad tras unir el guion: +50 % de coste | 31-10 (`medir_ciudad`, cachés calientes, por software): construir ~8-11 s → ~15 s; nodos 42.700 → 65.200; llamadas de dibujo a pie 688 → 1.012 y en vista aérea 3.144 → 4.050. Repartido entre el contenido nuevo (pasto, detalles de fachada y tejados, +38 rótulos Label3D, estación con trenes de ~160 piezas, cajeros…). Hacer una pasada de rendimiento SIN quitar contenido: piezas fijas fuera de nodos con script (si no, `Optimizar.agrupar` no las junta), MultiMesh para lo repetido y `visibility_range` en lo de más de 10 m. Estadio y semana simulada: sin cambios (estadio 4,8 s en las dos; semana 145 → 138 ms). 1-11: `FundirPiezas` (una malla por material y sombra) en el autobús (~97 piezas → ~14 superficies, corte a 600 m) y en los paraderos Red y su cartel: a pie de calle 1.013 → 888 llamadas con el bus (los paraderos, sin remedir); capturas de día y de noche idénticas. 2-11: trenes del metro con `FundirPiezas` (`excluir` deja sueltas las puertas que se deslizan y el interior con su corte): piezas sueltas del metro 2.313 → 1.059, nodos 39.463 → 38.209 (`medir_ciudad`, por software, sin draw calls); banco «FIN. 0 fallos»; FALTA captura de los trenes con la cámara real (Forward+ por software no terminó en 280 s: repetir con GPU). Asientos del interior del autobús fundidos en una malla (nodos 38.209 → 37.974; salen de la lista A_PIE). `DETALLE=1` ahora imprime un ejemplo de cada grupo. Coches del tráfico (`CityBuilder.instanciar_trafico`: carrocería, ruedas, placas y faros fundidos): mallas de coche dibujadas a pie ~30 → ~8, nodos 37.974 → 36.646. Siluetas de pasajeros del autobús creadas al sentarse alguien y mallas/materiales compartidos entre autobuses (nodos 36.638 → 35.435; `s7_pasajeros` cubre subir y bajar). Probado y DESCARTADO: compartir la malla fundida de cada modelo de coche (las placas, distintas por coche, añaden ~780 nodos y el tiempo de construir no mejora); `append_from` es el 80 % del coste de fundir (~650 ms en total). `DETALLE=1` ahora lista también las mallas que cada grupo impide juntar (`GRUPO_TODAS`): ~1.100 en total (paradero_red 496, edificio_club 321, personal_club 127, feria_animada 79, bus_red 52), no son la palanca grande; mayores motivos de `Optimizar`: tráfico con script (1.941), mallas ocultas (881) y con script propio (788). Dentro de `Trafico` (`TRAFICO_MALLAS`): 1.809 de las ~1.900 mallas cuelgan de nodos anónimos (coches ya fundidos y, sobre todo, peatones con esqueleto: no se funden), autobuses 46, karts 30. Siguientes: rótulos Label3D de los buses (los 133 «Node3D/Node3D/MeshInstance3D» restantes ya son las mallas agrupadas de la ciudad, no hay feria suelta); 3-11: carga DIFERIDA (hasta ver el prólogo 7,2 → ~3 s, ciudad entera 5,7 → 1,5 s, cuadro más largo 3,4 → 0,5 s en el servidor), vehículos en hilos, estadio cediendo el hilo; falta medir en el teléfono |
| M-357 | P2 | PARCIAL | Capturas pesadas en repo (`pruebas/capturas`) | `.gitignore` de promo/lotes y JPG por defecto; resto en repo |

### F6 pulido (traducciones) (6)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-328 | P2 | PENDIENTE | Patrones numéricos (`patrones` 58) con plurales simples | sin reglas de plural por idioma |
| M-329 | P2 | PARCIAL | Sin género gramatical (entrenadora/jugadora) en todos los idiomas | `Genero` solo en español |
| M-330 | P2 | PENDIENTE | Formatos de fecha/número por idioma | sin `Idiomas.fecha/numero` |
| M-332 | P2 | PENDIENTE | Narración traducida (`narracion.json`) sin revisión nativa | sin revisión nativa |
| M-334 | P2 | PENDIENTE | Sin RTL (árabe, hebreo) aunque hay KSA/EGY/MAR | sin RTL |

### dueño (27)

| id | P | estado | idea | qué falta |
|---|---|---|---|---|
| M-337 | P0 | 🔒 DUEÑO | No hay perfil en hardware real (R-01) | perfil en hardware real |
| M-341 | P1 | 🔒 DUEÑO | Sombras: 4 cortes en ALTO; sin ahorro medible al bajar (probado),… | coste de sombras en GPU real |
| M-419 | P1 | 🔒 DUEÑO | `.git` 5,5 GB con punteros LFS antiguos (D-03) | historial/LFS: decisión del dueño |
| M-313 | P2 | PENDIENTE | `Sonido._sintetizar` 1.000 líneas: efectos sintetizados sin editor | `_sintetizar` sigue monolítica |
| M-314 | P2 | PENDIENTE | Sin mezcla dinámica (ducking de música en diálogo/gol) | sin ducking |
| M-315 | P2 | PARCIAL | Música (`Musica` 384 líneas, procedural): sin variaciones por mood… | `Musica` con capas por estado |
| M-316 | P2 | PARCIAL | Cantos de hinchada genéricos | cánticos sintetizados; sin sincronía con el juego |
| M-317 | P2 | 🔒 DUEÑO | Sin comentarista | narración por voz = audios (decisión del dueño; COMPARACION_JUEGOS_2) |
| M-318 | P2 | PENDIENTE | Sin sonidos de pisadas por superficie en partido | sin pisadas |
| M-319 | P2 | PARCIAL | Sin eco/reverb en túnel/vestuario/estadio | sonido «eco_estadio»; sin reverb por zona |
| M-320 | P2 | PENDIENTE | Sonido del balón (patada) sin variación por tipo/potencia | sin variantes de patada por potencia |
| M-321 | P2 | PENDIENTE | Volúmenes por bus sin perfil «noche»/audífonos | sin presets de volumen |
| M-322 | P2 | PENDIENTE | Sin audio espacial en la ciudad (fuentes 3D) | sin audio espacial (0 `AudioStreamPlayer3D`) |
| M-324 | P2 | PENDIENTE | Sin prueba que detecte clipping/silencios | sin prueba de clipping |
| M-422 | P2 | PENDIENTE | 8 presets de exportación; sin pruebas de compilación | sin CI de exportación |
| M-423 | P2 | 🔒 DUEÑO | Android: keystore del dueño (regla) | keystore |
| M-426 | P2 | PENDIENTE | Archivos grandes sueltos (`.glb` >5 MB) | sin compresión de GLB grandes |
| M-427 | P2 | PARCIAL | `pruebas/capturas` crece sin control | carpetas promo/lotes ignoradas; capturas siguen en el repo |
| M-428 | P2 | 🔒 DUEÑO | `.zip` de terceros dentro de `recursos/` (punteros LFS) | archivos de terceros con LFS: decisión del dueño |
| M-432 | P2 | PENDIENTE | Sin política de contenido (religión/política ficticia) | sin lista en CI |
| M-323 | P3 | 🔒 DUEÑO | Sin música licenciada (decisión del dueño) | música licenciada: decisión del dueño |

## 6. Tus ideas 1–350: lo que NO está hecho del todo

De las 350, **124 se dieron por hechas y comprobadas** (hay implementación y una prueba del banco que la toca) y se borraron. Criterio honesto: una prueba automática no mide si está *bien* hecha a tu nivel de exigencia; si alguna borrada no te convence, dilo y vuelve a esta lista. Abajo: lo abierto.


### Pendientes (no se encontró nada) (43)


**3. Personalización visual**
- 39. Colecciones especiales (edición aniversario, homenaje)
- 40. Personalización del logo del club en redes sociales
- 42. Personalización del himno/cántico del club
- 45. Diseño de banderines y merchandising

**9. Economía y Finanzas**
- 118. Fondo de emergencia del club
- 120. Bonos e incentivos fiscales por inversión en cantera

**10. Auspicios y Marketing**
- 125. Sponsor de entrenamiento
- 130. Colaboraciones con marcas para ediciones limitadas
- 131. Sponsors regionales vs. internacionales
- 133. Sponsors "sorpresa" que ofrecen tratos únicos
- 135. Ferias/eventos de marca para aumentar reputación

**11. Fans y Comunidad**
- 144. Fan zone fuera del estadio en días de partido
- 145. Programa de fidelización de hinchas

**13. Medios y Prensa**
- 162. Ranking de prensa sobre mejores DTs/presidentes
- 164. Reportajes especiales sobre la cantera

**15. Premios y Reconocimientos**
- 177. Mejor arquero del año
- 179. Mejor presidente/dueño del año
- 183. Premio al club más popular

**17. Rivalidades y Clásicos**
- 204. Eventos especiales previos al clásico
- 206. Fichajes polémicos entre rivales
- 208. Comparación de logros con el rival histórico

**18. Legado e Historia del Club**
- 211. Línea de tiempo histórica del club
- 219. Leyendas como mentores de la cantera

**20. Extras y Sistemas Meta**
- 231. Modo historia con objetivos guiados
- 234. Guardado de partida en la nube
- 238. Comparación con otros jugadores (si hay online)
- 240. Modo "carrera rápida" para partidas cortas
- 250. Modo multijugador asíncrono (comparar ligas entre amigos)

**21. Detalles de Ambientación**
- 257. Impacto económico del club en la ciudad ficticia

**22. Sistemas de Jugadores (detalle extra)**
- 269. Patrocinios personales de jugadores (compite con el club)

**23. Eventos de Crisis y Oportunidad**
- 272. Boom económico repentino de un sponsor
- 275. Oferta de fusión con otro club (dilema)
- 279. Presión por bajar precios de entradas

**24. Progresión y Metas**
- 283. Ranking histórico de mejores gestiones (leaderboard interno)

**25. Toques Finales de Personalización**
- 294. Personalización del bus del equipo

**27. Récords, Historia y Memoria del Club**
- 318. Línea de tiempo navegable de temporadas anteriores
- 324. Historial de presidentes/DTs anteriores y su legado

**28. Sala de Trofeos y Celebraciones**
- 332. Exhibición temporal de un trofeo destacado en el estadio
- 333. Ceremonia de entrega de camiseta homenaje en aniversarios
- 334. Muro de campeones con fotos de planteles ganadores

**29. Más Ideas Adicionales**
- 345. Resumen de prensa internacional si el club gana notoriedad
- 348. Eventos climáticos que afectan la asistencia y el ánimo del público
- 349. Modo "reconstrucción": heredar un club en crisis y sanearlo

### Parciales (existe una parte) (82)


**1. Infraestructura y Estadio**
- 15. Accesos para hinchada visitante (afecta seguridad/incidentes)

**3. Personalización visual**
- 34. Diseñador de camiseta de arquero
- 41. Personalización de la mascota del club
- 43. Personalización de la bandera del club
- 44. Personalización de uniforme del cuerpo técnico

**4. Personaje (DT / Presidente / Dueño)**
- 50. Frases/estilo de comunicación personalizable
- 51. Relaciones personales con jugadores clave
- 52. Rivalidad personal con otro DT/presidente

**5. Plantilla y Jugadores**
- 66. Cláusulas de bonos por objetivos
- 67. Elección de número de camiseta
- 68. Jugadores "ícono" con historia especial

**6. Cantera y Formación Juvenil**
- 71. Categorías juveniles (sub-15, sub-17, sub-20)
- 73. Academias asociadas en otras ciudades/países
- 80. Historial de canteranos que llegaron a ser estrellas

**7. Fichajes y Negociación**
- 85. Fichajes sorpresa (oportunidades limitadas en el tiempo)
- 90. Traspasos con jugador + dinero incluido

**8. Cuerpo Técnico y Staff**
- 101. Personal de relaciones públicas

**9. Economía y Finanzas**
- 114. Recortes de gastos en momentos de crisis

**10. Auspicios y Marketing**
- 127. Sponsors temáticos con personalidad propia
- 128. Renovación o pérdida de sponsors según resultados
- 129. Campañas publicitarias especiales
- 132. Penalizaciones por incumplir contrato de sponsor

**11. Fans y Comunidad**
- 142. Cánticos personalizados de la hinchada

**12. Redes Sociales**
- 147. Publicaciones oficiales del club que puedes redactar
- 149. Trolls y críticos recurrentes en redes
- 152. Crisis de imagen por un comentario mal manejado
- 153. Cuenta oficial de jugadores (reacciones a decisiones tuyas)
- 154. Memes generados por la comunidad del juego

**13. Medios y Prensa**
- 165. Cobertura internacional si el club gana relevancia

**15. Premios y Reconocimientos**
- 176. Balón de Oro del juego
- 182. Premio al fair play
- 184. Premio a la mejor hinchada
- 185. Premio al estadio más impresionante

**16. Eventos Narrativos y Decisiones**
- 191. Sponsor que exige una decisión ética incómoda
- 195. Escándalo de arbitraje que genera indignación
- 199. Conflicto entre cuerpo técnico y directiva

**17. Rivalidades y Clásicos**
- 202. Rivalidad regional/de ciudad
- 205. Presión extra de la afición en el clásico
- 207. Robo de un canterano por el club rival
- 209. "Guerra" de sponsors entre clubes rivales
- 210. Ranking de rivalidad según intensidad de eventos

**18. Legado e Historia del Club**
- 215. Homenajes a ídolos fallecidos o retirados

**19. Roles de Juego (DT / Presidente / Dueño)**
- 226. Elecciones internas si eres presidente (reelección)
- 229. Modo sandbox sin presión de despido

**20. Extras y Sistemas Meta**
- 237. Estadísticas exportables de tu carrera
- 244. Notificaciones push de eventos importantes
- 246. Sistema de logros ocultos/easter eggs

**21. Detalles de Ambientación**
- 253. Horarios de partido elegibles (afecta asistencia/TV)
- 256. Turismo deportivo si el club crece mucho
- 258. Relación con el gobierno local
- 259. Alianzas con otros clubes (amistosos, intercambio de canteranos)
- 260. Torneo de veteranos con ex-jugadores del club

**22. Sistemas de Jugadores (detalle extra)**
- 263. Jugadores con doble nacionalidad (elegibilidad)
- 266. Sistema de lesiones crónicas vs. agudas
- 268. Jugadores con marca personal (redes propias)
- 270. Jugadores "problema" que requieren gestión especial

**23. Eventos de Crisis y Oportunidad**
- 273. Caída de un sponsor por escándalo externo
- 277. Oferta de venta total del club (si eres dueño)
- 278. Escándalo de dopaje a resolver

**24. Progresión y Metas**
- 287. Estadísticas comparativas año a año
- 288. Certificaciones del club (sustentable, formativo, etc.)
- 289. Ranking de mejores canteras a nivel ficticio-continental
- 290. Hitos de asistencia al estadio (lleno histórico)

**25. Toques Finales de Personalización**
- 292. Personalización de la sala de prensa
- 293. Personalización del palco presidencial
- 295. Personalización del avión/transporte para giras
- 296. Personalización de la app oficial del club (ficticia)
- 297. Personalización del sitio web del club (ficticio)
- 299. Personalización de la ceremonia de presentación de fichajes

**27. Récords, Historia y Memoria del Club**
- 319. Resumen anual automático al cerrar cada temporada
- 320. Archivo de planteles históricos por temporada
- 325. Comparador de generaciones (equipo actual vs. el mejor histórico)

**28. Sala de Trofeos y Celebraciones**
- 327. Animación/celebración especial al ganar un trofeo
- 331. Evento especial de "gala de campeones" con invitados históricos
- 335. Fuegos artificiales/mosaico especial configurable para festejos grandes

**29. Más Ideas Adicionales**
- 336. Modo "día a día" con calendario navegable (entrenamientos, viajes, medios)
- 337. Sistema de fatiga por viajes largos en torneos internacionales
- 339. Reuniones de directorio con actas resumidas
- 340. Contrato de imagen del club con una liga de videojuegos ficticia (guiño meta)
- 346. Cláusula de fidelidad: bono si un jugador no pide salir en X años
- 350. Estadísticas de eficiencia de tu gestión (ROI de fichajes, cantera, etc.)

### Declaradas hechas pero sin prueba que las compruebe (38): verificar jugando; las que no existan pasan a pendientes


**1. Infraestructura y Estadio**
- 1. Ampliación de estadio por sectores (norte, sur, palcos)
- 2. Nivel máximo de estadio sin límite realista ("niveles inhumanos")

**2. Ciudad Deportiva / Instalaciones**
- 17. Canchas auxiliares para categorías juveniles
- 25. Auditorio para conferencias de prensa
- 26. Oficinas administrativas del club

**4. Personaje (DT / Presidente / Dueño)**
- 46. Editor de apariencia del personaje
- 54. Nivel de carisma que afecta negociaciones

**5. Plantilla y Jugadores**
- 62. Relación entre compañeros (química de vestuario)

**6. Cantera y Formación Juvenil**
- 75. Riesgo de perder canteranos a otros clubes

**7. Fichajes y Negociación**
- 88. Jugadores que piden ser vendidos

**11. Fans y Comunidad**
- 136. Nivel de aprobación general de la afición
- 143. Mosaicos y coreografías en el estadio

**12. Redes Sociales**
- 148. Tendencias/hashtags según eventos del club

**13. Medios y Prensa**
- 159. Rumores de fichajes filtrados por la prensa

**15. Premios y Reconocimientos**
- 178. Mejor DT del año

**16. Eventos Narrativos y Decisiones**
- 188. Escándalo mediático de un jugador
- 190. Oferta irrechazable por un jugador clave
- 194. Jugador que pide salir por motivos personales
- 196. Incidente de seguridad en el estadio
- 197. Petición de la comunidad local (obra social)
- 198. Oferta de inversión extranjera con condiciones

**18. Legado e Historia del Club**
- 218. Leyendas contratables como embajadores

**20. Extras y Sistemas Meta**
- 241. Accesibilidad: modo daltónico, texto ajustable
- 243. Modo offline completo
- 245. Resumen semanal tipo "informe de gestión"

**21. Detalles de Ambientación**
- 255. Eventos comunitarios fuera del fútbol (caridad)

**22. Sistemas de Jugadores (detalle extra)**
- 262. Prestigio internacional del jugador
- 265. Reconversión de jugador a manager/staff al retirarse
- 267. Rendimiento afectado por vida personal (eventos)

**23. Eventos de Crisis y Oportunidad**
- 276. Terreno disponible para expandir la ciudad deportiva

**25. Toques Finales de Personalización**
- 291. Personalización del vestuario (colores, mobiliario)

**27. Récords, Historia y Memoria del Club**
- 317. Efemérides: "un día como hoy" con hechos pasados del club

**28. Sala de Trofeos y Celebraciones**
- 326. Sala de trofeos visual con vitrina por cada título
- 328. Celebración de aniversario del club (ej. cada 5 o 10 años)
- 329. Celebración especial al llegar a un hito de trofeos (ej. 100)
- 330. Placas conmemorativas de hitos históricos

**29. Más Ideas Adicionales**
- 341. Sistema de fair play entre hinchadas (premia buena conducta)

## 7. Tus ideas 351–1100: auditadas contra el código (24-10)

Auditoría por lectura del código (no por juego). **Existe** = implementada; aun así NO sale del plan hasta que una prueba del banco la compruebe (el campo «cómo probar» dice qué afirmar). **Parcial** = falta lo indicado. **No** = no hay nada. Cuando una prueba la verifique, se borra con `python3 herramientas/quitar_ideas.py N…`.

Hallazgos de código a arreglar: `datos/tablas.json` trae tablas que nada usa (ESCENARIOS, APODOS, WIDGETS); los desafíos `leyenda30` y `sinRecarga` son solo aviso; `pobreza` no bloquea créditos; `Cesiones.riesgo_opaco` no sanciona; `linaje['padre_en_club']` y `['pedido']` se escriben y nadie los lee (el padre retirado no presiona); el texto del mercado promete precontratos que no existen; la licencia denegada no impide ascender; plazas continentales fijas (sin coeficientes ni repechaje); vibración solo de mando, no de móvil.


### Existen: falta una prueba que las compruebe (cómo probar) (335)


**30. Simulación de Partido (motor y experiencia)**
- 352. Velocidad de simulación configurable (x1, x2, x4, saltar a evento) — _Afirmar MatchPlayback.VELOCIDADES.size()>=3 y que mas_rapido() sube vel_idx_
- 353. Botón "saltar al próximo gol" para partidas rápidas — _Con Partido.simular_minuto en bucle hasta que cambie el marcador (lógica en la UI, no extraída a nucleo)_
- 360. Cambios en vivo con vista rápida del banco de suplentes — _Partido.cambiar(club, sale, entra) y afirmar once actualizado y límite MAX_CAMBIOS_
- 363. Indicador de fatiga por jugador en tiempo real — _MotorJugable.forma_fisica(p) decrece con el tiempo de partido (requiere motor)_
- 371. Modo "solo resultado" para quienes simulan temporadas rápido — _Mundo.avanzar_semana() x N y afirmar tabla coherente (ya es el flujo base del banco)_

**31. Táctica y Sistema de Juego**
- 383. Roles por posición (lateral ofensivo, pivote, falso 9, mediapunta) — _Vestuario.fijar_rol_tactico(j,'pivote'); rol_tactico(j)=='pivote'; bonus_roles(once) cambia att/def_
- 393. Editor simple de jugadas ensayadas de córner — _Tactica.efectividad(once, def_corner(c)[3], entrenamiento) en rango 0.82-1.35_
- 394. Editor de jugadas ensayadas de tiro libre — _Tactica.def_libre('ensayada') y efectividad_
- 400. Análisis previo del rival con puntos débiles sugeridos — _Mundo.analizar_rival() devuelve '' y fija bono_analisis>1; InformeRival.mostrar solo UI_
- 404. Índice de compatibilidad jugador-rol — _Vestuario.aptitud_rol(j,'pivote') entre 0.82 y 1.14 y mayor con mejores atributos_
- 405. Jugadores que rinden mejor o peor en un rol específico — _Comparar aptitud_rol de dos jugadores con perfiles distintos en el mismo rol_
- 411. Evolución táctica por era: el fútbol de moda cambia con los años — _Mundo.factor_moda(formacion) devuelve BONO_MODA/CASTIGO_MODA/1.0 según era_actual_
- 412. Estadística de eficacia por cada táctica utilizada — _Mundo.anotar_eficacia('4-3-3',2,0); ranking_tactico()[0].ppp==3.0_
- 413. Pizarra táctica para explicar el plan en la charla previa — _PizarraTactica.pintar solo UI_
- 414. Rotación planificada para calendarios congestionados — _Mundo.rotacion_activa=true; fijar fisico bajo en un titular; aplicar_rotacion()>=1_

**32. Entrenamiento y Desarrollo**
- 420. Reconversión de posición (lateral a central, extremo a lateral) — _Jugador.reconvertir('LI') cambia pos_e y baja media_en temporalmente_
- 421. Entrenamiento de habilidades específicas (penales, cabeceo, tiro libre) — _Entrenamiento.dar_habilidad(j,'cabezazo'); tiene_habilidad; efectividad() sube_
- 422. Curva de aprendizaje según edad: los jóvenes progresan más rápido — _Jugador j.edad=19, ovr<pot: procesar_semana x N sube ovr; con edad=30 no_
- 423. Techo de crecimiento visible solo mediante ojeadores confiables — _Mundo.ojeados.has(j.id) controla la visibilidad de pot_
- 441. Video-análisis grupal antes de rivales difíciles — _Mundo.analizar_rival() devuelve '' y bono_analisis>1_
- 442. Índice de calidad de instalaciones que multiplica el progreso — _Instalaciones con nivel de centro>0 => ritmo_de_progreso()>1_
- 443. Veteranos que ya no mejoran pero transmiten experiencia — _Entrenamiento.crear_mentoria(vet, joven) y tras semanas el pupilo progresa_

**33. Scouting y Red de Ojeadores**
- 446. Red de ojeadores contratables con especialidad regional — _Ojeadores.alternar_pais('ARG') con staff nivel>0 crea ojeadores['ARG']_
- 448. Informes con rango de incertidumbre en vez de números exactos — _Ojeadores.ovr_texto(j) devuelve rango 'a-b' para ajeno y exacto para ojeado_
- 449. Ojeadores con distinto nivel de precisión y sesgos propios — _Ojeadores.sesgo_de(pais) en SESGOS y _error_de dependiente_
- 450. Ojeador que exagera sus hallazgos para justificar su sueldo — _Con sesgo 'vende' ovr_aproximado sale mayor que con 'fiel'_
- 453. Base de datos que se va revelando a medida que investigas — _Mundo.ojeados[j.id]=true cambia ovr_texto de rango a exacto_
- 459. Competencia con otros clubes por el mismo objetivo — _Negociacion._rival_en_juego(m,j) devuelve id de club o ''_
- 461. Informe de personalidad además del informe de habilidad — _Ojeadores.informe_personalidad(j,club) devuelve {prof,vestuario,mudanza}_
- 462. Informe médico previo al fichaje, con costo asociado — _Medico.informe_de(j) devuelve riesgo/graves; costo_informe(j)>0_
- 466. Ojeador que renuncia si ignoras sistemáticamente sus informes — _Ojeadores.ojeadores[p].ignorados alto + 25 semanas => ojeadores.has(p)==false_
- 468. Presupuesto de scouting separado del de fichajes — _Ojeadores.ojear(j) descuenta del presupuesto de ojeo antes que del saldo_
- 469. Análisis de datos como alternativa moderna al ojeo tradicional — _Ojeadores.mejorar_analitica() sube nivel; semana_analitica() llena hallazgos_
- 470. Departamento de análisis con modelo estadístico propio del club — _Ojeadores.hallazgos_vivos() tras semana_analitica_
- 471. Conflicto interno entre el ojeador tradicional y el analista de datos — _Subir analitica_nivel>=2 y semanas => analitica_tension aumenta_
- 475. Informe de "jugadores similares" para reemplazar una salida — _FichaJugadorAcciones.pintar_similares (UI)_

**34. Regens, Hijos de Jugadores y Linaje**
- 476. Sistema de regens: nuevas generaciones que reemplazan a los retirados — _Mundo.nueva_temporada(): plantillas conservan tamaño tras retiros y llegan juveniles (Cantera.camada_actual)_
- 477. Hijos de jugadores históricos que heredan el apellido — _Cantera.registrar_retiro(j,club) con ovr>=76 añade leyenda; tras anio_hijo, un jugador con linaje_de(j)['padre']==nombre_
- 479. Probabilidad alta de que el hijo juegue en la posición del padre — _Repetir _hijos_de_leyendas y contar proporción de grupo igual_
- 480. Hijo que debuta en el club donde su padre fue leyenda — __hijos_de_leyendas: destino==club_padre en ~70%_
- 481. Presión mediática específica sobre el hijo de una leyenda — _Cantera.etiquetar_promesa(j,'X'); procesar_semana emite etiqueta_pesa tras 6 semanas malas_
- 482. Riesgo narrativo de que el hijo nunca alcance el nivel del padre — _Forzar notas bajas y comprobar etiqueta_pesa_
- 483. Caso excepcional: el hijo supera al padre y se vuelve ícono — _Subir ovr por encima del nivel del padre y comprobar etiqueta_superada_
- 484. Nietos de jugadores en partidas de muy largo plazo — _Retirar un jugador con linaje_de no vacío => nueva leyenda_
- 485. Hermanos futbolistas con bonificación de química en cancha — _Vestuario.emparentar(a,b); bonus_hermanos(once con ambos)>1_
- 486. Gemelos con atributos casi idénticos — _Cantera._sortear_hermano en bucle: gemelos tienen la misma edad y diferencia de ovr <=2_
- 491. Época dorada: oleada de talento en un país cada cierto tiempo — _Eras.cierre_de_temporada() puede dejar activas[pais]; Eras.bono(pais,anio)==1.13_
- 492. Decadencia futbolística de un país si su liga colapsa — _Eras con país arruinado entra en decadencia (bono 0.9)_
- 495. Cantidad y calidad de regens condicionada por la inversión en cantera — _Cantera.bono_de_camada() sube con instalaciones/staff_
- 497. Historia de origen del regen (barrio humilde, academia de élite, refugiado) — _Cantera._sortear_origen(j) deja origen_de(j) no vacío_
- 498. Biografía breve autogenerada para cada regen — _FichaJugadorInfo.bio_de(j,mundo) contiene 'Hijo de la leyenda' si hay linaje_
- 499. Avatar generado proceduralmente en estilo minimalista — _Cara.look_de(j) determinista por id_
- 502. Etiqueta mediática "el nuevo [leyenda]" con la presión que implica — _Cantera.etiquetar_promesa y etiqueta_de(j) no vacía_
- 508. Árbol genealógico navegable de familias futbolísticas — _Cantera.familias() agrupa claves L:padre y H:ids_

**35. Lesiones y Medicina Deportiva**
- 516. Catálogo amplio de lesiones con tiempos de recuperación distintos — _Medico.catalogo().size()==22; lesionar(j,GRAVE) devuelve semanas dentro del rango de una fila_
- 517. Diferenciación entre lesiones musculares, articulares y óseas — _Medico.ficha(j)['clase'] tras lesionar_
- 520. Rasgo de jugador propenso a lesionarse — _riesgo_por_fatiga(j fragil) > riesgo de uno normal_
- 521. Historial médico que afecta el valor de mercado — _Medico.lesionar graves x2 => j.valor baja ~15%_
- 525. Médico del club con nivel de competencia propio y mejorable — _Staff.subir('medico') baja semanas de lesionar()_
- 529. Lesión sufrida durante una gira de selección nacional — _Selecciones._fecha_fifa con jugador convocado muchos partidos => vuelve_tocado_
- 530. Lesión larga que obliga a un fichaje de emergencia — _Roles.abrir_emergencia(id) => ventana_abierta y puede_fichar libre con mercado cerrado_
- 531. Ventana de fichaje de emergencia por lesión grave (regla configurable) — _Roles.abrir_emergencia segunda vez en el mismo anio devuelve false_
- 532. Retiro forzado por lesión crónica — _Medico.retiro_forzado(j) true con 3 lesiones largas (probabilístico)_
- 535. Fatiga acumulada como variable distinta de la forma física — _riesgo_por_fatiga depende de fisico y no de forma_
- 537. Descanso programado como herramienta preventiva — _Entrenamiento.fijar_dia(i,'descanso') baja carga_riesgo_
- 539. Enfermedades no deportivas que arruinan una semana de trabajo — _Medico.lesionar con fila de clase enfermedad_
- 541. Estadística de días perdidos por lesión en la temporada — _Medico.lesionar(jugador propio) aumenta dias_perdidos_
- 542. Comparativa de tu departamento médico contra el resto de la liga — _Medico.ranking_liga(club, liga)['puesto'] entre 1 y total_
- 543. Rehabilitación con progreso visible semana a semana — _Medico.rehabilitacion(j) descuenta 1 semana y baja terapia_

**36. Vestuario, Psicología y Dinámica de Grupo**
- 546. Jerarquía de vestuario visible (líderes, influyentes, periféricos) — _Vestuario.armar() y clan_de(j)['lider']_
- 550. Jugador que se queja por falta de minutos — _Vestuario._chequeo_roles con jugador 'titular' que juega poco emite rol_incumplido_
- 551. Jugador que pide expresamente salir del club — _Vestuario.resolver_solicitud(true) con solicitud 'salida' marca transferible_
- 556. Elección de capitán y vicecapitán con efecto real en el grupo — _Vestuario.votar_capitan() asigna capitán y 'capitan' en solicitud lo cambia_
- 560. Charla motivacional con distintos tonos y resultados variables — _Vestuario.charla(tono, ...) cambia moral dentro de ef[0..1] y ansiedad_
- 561. Jugadores que responden mejor al elogio o a la exigencia — _Vestuario.charla con tono que 'gusta' al jugador suma más moral_
- 563. Jugador conflictivo pero determinante como dilema permanente — _Vestuario.suceso_semanal() con un 'polemico' devuelve tipo 'lio'_
- 564. Multas internas por indisciplina — _Mundo.normas['multas']=true y _suceso_lio descuenta sueldo*MULTA_SEMANAS_
- 565. Reglamento interno del club configurable por ti — _Mundo.normas[clave] activa/desactiva y afecta _suceso_lio_
- 566. Fiestas y escándalos extradeportivos con consecuencias — _Vestuario.suceso_semanal()['tipo'] ∈ {lio,arenga,racha,joya,cumple}_
- 569. Extranjero que no se adapta al país y pide volver — _Cantera.chequeo_promesas con promesa incumplida => j.pide_salir (si no hay traductor)_
- 572. Compañero del mismo país que facilita la adaptación — _Cantera.prometer_compatriota(j); chequeo_promesas con compatriota => moral +8_
- 574. Efecto de tus declaraciones públicas sobre el ánimo interno — _Prensa.responder(opcion) devuelve moral/confianza y mueve moral del plantel_
- 577. Rebelión de vestuario capaz de costarte el puesto — _Directiva.mover_confianza hasta <=0 => despido; chequeo de clan_enfadado_

**37. Mercado de Fichajes Avanzado**
- 583. Jugadores libres disponibles durante todo el año — _Mundo.generar_libres(); fichar_libre(0, club) con mercado cerrado devuelve ok o rechazado_
- 584. Cesiones con opción de compra y con obligación de compra — _Cesiones.ceder_con_opcion(j,destino,tipo,opcion) y resolver(anio) vende si obliga_
- 585. Cesión con porcentaje del sueldo pagado por el club de destino — _Cesiones.ahorro_salarial(club_id) == sueldo*pct de cedidos_
- 586. Intercambio de jugadores más diferencia en dinero — _Negociacion.poner_intercambio(j2); valor_percibido() sube valor*0.88_
- 587. Porcentaje de futura venta como moneda de negociación — _Cesiones.pactar_porcentaje_de_venta + vender => plusvalía pendiente_
- 590. Pago en cuotas a varios años y su efecto en el flujo de caja — _Cesiones.registrar_compromisos y pagar_cuotas reducen saldo por semanas_
- 593. Terceros propietarios del pase como dilema normativo — _Cesiones.oferta_de_fondo(j) y vender_participacion_
- 594. Guerra de ofertas entre varios clubes por el mismo jugador — _MercadoAvanzado.guerra_de_ofertas(mundo) añade puja con puja==true_
- 595. Jugador que rechaza tu club por falta de proyecto deportivo — _Mercado.deseo_de_venir(j,club)['p'] baja con club menor_
- 598. Presión del agente para subir su comisión — _Cantera.sortear_guerra_agentes() fija exigencia; MesaAgente.regatear_
- 602. Cupo de extranjeros configurable por liga — _LeyesPais.reglas('ESP') y cuantos_cupo(club)_
- 603. Límite de plantel y exigencia de jugadores formados en casa — _LeyesPais.exceso_plantel(club); Federacion.revisar_cupo_juvenil_
- 608. Bonificación reputacional por operaciones rentables — _Reputacion.registrar('negociador',+20,'x') sube mult_ventas_
- 610. Paciencia del club vendedor como contador visible en la negociación — _Negociacion.paciencia decrece por ronda; estado 'rota' al llegar a 0_
- 611. Renovación preventiva para no perder a un jugador gratis — _Cantera.renovar(j,anios) aumenta anios_contrato y cobra firma_
- 613. Agente libre estrella disponible cada cierto tiempo — _Mundo._procesar_libres en bucle de semanas crea libre estrella (_nuevo_libre(true))_

**38. Agentes, Representantes y Zonas Grises**
- 616. Agentes con cartera propia de jugadores — _Cantera.agencias_del_plantel() agrupa jugadores por agente y suma clientes_
- 617. Nivel de confianza construido con cada agente — _Cantera.resolver_agente('a') sube confianza_de(nombre)_
- 620. Superagente que controla a media liga — _MercadoAvanzado._montar(m,'superagente'); resolver(m,'a')_
- 622. Agente que filtra información a la prensa — _Prensa._eventos_nuevos incluye eventos con agente (hay_evento / sortear_evento)_
- 623. Oferta de retorno por comisión como decisión ética con riesgo — _Cantera.resolver_agente('a') con tipo comision incrementa turbio_
- 625. Sanción por incumplir el fair play financiero — _Federacion.revisar_fair_play(...) con masa salarial alta dos años => puede_pagar_traspaso()==false_
- 628. Reputación limpia como ventaja concreta en negociaciones — _Reputacion.registrar('honesto',+30,'x') baja mult_compras_
- 630. Fichaje impuesto directamente por el dueño del club — _MercadoAvanzado.resolver(m,'a') con impuesto ficha al libre_
- 631. Rechazar un fichaje impuesto y ganarte un enemigo interno — _resolver(m,'b'): confianza del directorio baja 6_
- 637. Jugador de tu plantel implicado en apuestas — _MercadoAvanzado._montar(m,'apuestas'); resolver(m,'b') puede suspender 5_

**39. Economía Avanzada, Deuda e Insolvencia**
- 642. Balance con activos, pasivos y patrimonio — _Replicar la cuenta: activo=saldo+sum(valor)+obras; patrimonio=activo-deuda(Banco.prestamos)_
- 643. Flujo de caja proyectado a doce meses — _Finanzas.proyeccion_anual()['resultado']/12 repetido 12 veces sobre c.saldo_
- 647. Deuda bancaria con tasa e intereses visibles — _Banco.pedir(i,c) añade préstamo con cuota_francesa y semana() cobra interés = deuda*tasa_
- 649. Renegociación de deuda con los acreedores del club — _Banco.renegociar(0) cambia restan y tasa y marca renegociado_
- 653. Sanción deportiva por deuda: resta de puntos — _Insolvencia.semana(m) con hay_veedor => Liga.tabla_puntos baja 6_
- 654. Prohibición de fichar mientras exista deuda pendiente — _Banco.en_mora()==true y _motivo_fichaje_bloqueado devuelve texto (UI)_
- 656. Procedimiento de reorganización para salvar al club — _Insolvencia.resolver(m,'a') con pendiente refundacion limpia Banco.prestamos_
- 657. Liquidación del club como final de partida alternativo — _Banco.semana con semanas_en_rojo>=12 => liquidado_ya_
- 658. Administrador externo designado que limita tus decisiones — _Insolvencia.semana con veedor fija tope_salarial>0 y vende al más caro_
- 664. Emisión de bonos del club comprados por los propios hinchas — _Banco.emitir_bono(c) agrega préstamo con bono==true_
- 667. Multipropiedad: red de clubes bajo un mismo dueño — _Roles.comprar_filial() con capital suficiente añade filial_
- 668. Club satélite donde ceder juveniles — _Roles.comprar_filial(); Cesiones.ceder_canterano(j, club)_

**40. Propiedad, Directorio y Política Interna**
- 684. Voto de censura del directorio — _Junta.resolver con humor bajo => censura true y confianza baja 10_
- 685. Padrón de socios que crece o decrece según tu gestión — _Hinchada.campana_abonos(club,animo,trofeos) cambia c.socios_
- 686. Cuota social como ingreso estable y predecible — _Finanzas.cuotas_socios() == socios*cuota_
- 688. Accionistas con intereses distintos: deportivo contra financiero — _Junta.formar(club) crea 3 accionistas; resolver cambia humor del que habla_
- 696. Club filial en otra ciudad o país — _Roles.comprar_filial() añade filial; semana_filiales cobra/paga_
- 697. Directorio con miembros de personalidad definida — _Junta.formar crea presidente con estilo en ESTILOS_
- 698. Director deportivo con autonomía delegable — _Roles.fijar_directriz('rotacion',...) y dt_obedece()_
- 701. Paciencia del directorio como barra siempre visible — _Directiva.mover_confianza(-90) => despedido_ya_
- 702. Despido y búsqueda posterior de un nuevo cargo — _Directiva.mover_confianza(-100) => despedido; Roles.ofertas_trabajo() lista clubes_
- 703. Ofertas de otros clubes en plena temporada — _Roles.sortear_oferta_de_club() con prestigio alto devuelve oferta_
- 706. Reputación profesional que abre o cierra puertas — _Roles.sumar_prestigio(50) habilita sortear_oferta_de_club_
- 709. Historial de cargos con estadísticas completas de tu carrera — _Roles.curriculum tras cambiar de club / palmares_por_tipo()_

**41. Infraestructura Urbana y Entorno**
- 711. Mapa de la ciudad con terrenos comprables — _Ciudad.comprar_terreno('norte',club) descuenta saldo y tiene_terreno('norte')_
- 714. Barrio del club que se desarrolla junto con el éxito deportivo — _CiudadAnimo.de(mundo,club) devuelve estado según puesto/racha_
- 715. Negociación con la municipalidad por permisos de construcción — _Ciudad.pedir_permiso(club) crea permiso; Ciudad.semana resuelve aprobado o no_
- 716. Oposición vecinal a la ampliación del estadio — _Ciudad.gestion_vecinal('obra',club) sube vecinos_
- 719. Arriendo del estadio para conciertos y eventos masivos — _Ciudad.arrendar_estadio(club) suma saldo y baja cesped_
- 720. Ingresos por eventos no deportivos — _Ciudad.renta_negocios(club) suma renta semanal por negocio construido_
- 721. Daño al césped por eventos y su costo de reparación — _Ciudad.arrendar_estadio baja cesped; reparar_cesped lo restaura y descuenta_
- 724. Hotel del club como negocio anexo — _Ciudad.construir_negocio('hotel',club) tras comprar terreno 'norte'_
- 725. Restaurante y bar temático del club — _Ciudad.construir_negocio('resto',club)_
- 726. Clínica deportiva abierta al público general — _Ciudad.construir_negocio('clinica',club) sube Instalaciones 'rehab'_
- 727. Escuela de fútbol comercial con franquicias — _Ciudad.construir_negocio('escuela',club)_
- 728. Centro comercial anexo al estadio — _Ciudad.construir_negocio('comercial',club) requiere terreno 'centro'_
- 729. Paneles solares y sostenibilidad con beneficios tributarios — _Ciudad.instalar_paneles(club) sube paneles y ahorro_energetico_
- 730. Certificación ecológica del estadio — _Ciudad.certificar(club) fija certificado y renta_
- 731. Seguridad privada y control de accesos — _Ciudad.mejorar_seguridad('privada',club) sube seg_privada y baja riesgo_incidente_
- 732. Sistema de cámaras y protocolo antiviolencia — _Ciudad.riesgo_incidente(animo,funa) con seg_camaras>0 es menor_
- 733. Multas por incidentes ocurridos en el estadio — _Ciudad.sancionar('cerradas') => factor_aforo()==0_
- 734. Sanción de partido a puertas cerradas — _Ciudad.sancionar('cerradas'); factor_aforo()==0.0_
- 735. Aforo reducido temporal y su golpe económico — _Ciudad.sancionar('aforo'); factor_aforo()==0.4_

**42. Hinchada, Barras y Cultura Popular**
- 736. Segmentación de la hinchada en grupos con demandas distintas — _Hinchada.semana(80) mueve segmentos; segmentos[k] en 0..100_
- 737. Hinchas históricos frente a hinchas nuevos atraídos por el éxito — _Hinchada.semana(animo>65) en bucle: nuevos sube más rápido que historicos_
- 739. Protestas por el precio de las entradas — _Hinchada.alternar_precio_dinamico(); castigo_por_subida(5, 9)>0_
- 741. Banderazo de apoyo antes de un partido clave — _Prensa.semana() con animo=90 repetido emite noticia Banderazo_
- 746. Incidentes que derivan en sanciones para el club — _Ciudad.sancionar('aforo') y factor_aforo()<1_
- 749. Abonos de temporada con distintos planes y coberturas — _Hinchada.fijar_abono('premium'); campana_abonos(club,animo,trofeos) devuelve ingreso_
- 750. Precios dinámicos según el atractivo del partido — _Hinchada.precio_efectivo(10, 80) > 10 con precio_dinamico_
- 752. Día del hincha con actividades dentro del estadio — _Hinchada.dia_del_hincha(club,prensa) incrementa dias_hincha y socios_
- 753. Peñas o filiales del club en otras ciudades — _Hinchada.fundar_pena(club) añade penas y socios_
- 755. Encuesta de satisfacción a los hinchas — _Hinchada.encuesta no vacía tras semana() y responder_encuesta(mejor)['acerto']_
- 765. Rama de fútbol femenino como área gestionable — _Hinchada.abrir_rama('femenino',club) => tiene_rama true_
- 766. Rama de futsal o fútbol playa como apuesta menor — _Hinchada.abrir_rama('futsal',club)_
- 767. Deporte adaptado y su impacto en la imagen institucional — _Hinchada.abrir_rama('adaptado',club)_
- 769. Índice de reputación social del club — _Reputacion.registrar('social',+20,'x'); socios_por_temporada() sube_

**43. Prensa, Medios y Narrativa**
- 771. Conferencias de prensa con preguntas y opciones de respuesta — _Prensa.abrir_rueda(true,false) y responder(0) devuelve moral/confianza/socios_
- 772. Periodistas con línea editorial y sesgos definidos — _Prensa.periodista_de('ibarra')[3]=='crítico'_
- 773. Periodista que te tiene manía y busca desgastarte — _Prensa._poner_periodista(false,false); relacion_con('ibarra')_
- 775. Titulares generados según resultados y declaraciones — _Prensa.titular_prensa(true,false,false,'x')['tit'] no vacío_
- 776. Guerra mediática con un DT rival — _Roles.buscar_rival_dt() con rivalidad alta fija rival_dt; registrar_duelo_
- 777. Declaración pública que motiva o desmotiva al plantel — _Prensa.responder(opcion) => cambia j.moral del plantel_
- 780. Entrevista larga en un programa deportivo — _Prensa.mesa_de_debate() devuelve 5 voces con frase según estado_
- 781. Programa de debate donde se discute tu gestión — _Prensa.mesa_de_debate()_
- 787. Vocero del club habilitado para hablar en tu lugar — _Prensa.nombrar_vocero(club) elige capitan/lider; vocero no vacío_
- 789. Documental tras bambalinas: ingresos a cambio de exposición — _Prensa.hay_camaras() tras aceptar documental; renta_medios_
- 790. Cámaras en el vestuario como decisión rentable pero riesgosa — _Prensa.semanas_documental>0 baja moral de j.rasgo=='fragil'_
- 794. Derechos de TV negociados individualmente o en bloque — _Prensa.negociar_tv(true,club); factor_tv()==1.35 o 0.70_
- 795. Horarios de partido impuestos por la televisión — _Mundo.horario='lunes_noche' => factor_publico<1 y factor_tv_horario>1_
- 797. Cobertura internacional al firmar a una estrella — _CinematicaFichaje (UI)_
- 799. Archivo navegable de portadas históricas del club — _Prensa.guardar_portada(tit,cuerpo,'bien',{}) y listas de portadas crece_
- 800. Narrador de temporada que resume la campaña como relato — _Prensa.narrador_temporada() devuelve texto no vacío_

**44. Árbitros, Reglamento y Disciplina**
- 802. Designación arbitral conocida antes del partido — _Previa.arbitro_de('x',5) igual en llamadas repetidas_
- 803. Historial de resultados con cada árbitro — _Federacion.anotar_arbitro('A','casero',2,0); texto_arbitro('A')_
- 804. Reclamo formal por una designación arbitral — _Prensa.arbitro_dudoso('X'); sortear_evento incluye 'reclamo'_
- 805. VAR activable o no según la competencia — _Federacion.factor_tarjetas() ==0.5 si var_activo; Partido.ctx_factor_tarjetas_
- 806. Errores arbitrales que generan polémica y narrativa — _Partido.simular con árbitro 'estricto' genera decision_arbitral_
- 807. Sanción por reclamar públicamente contra el arbitraje — _Prensa.resolver('reclamo') con Azar fijo_
- 808. Expulsión del DT y prohibición de dirigir el partido siguiente — _Federacion.sancionar_dt(2); dt_sancionado()==true_
- 813. Castigo largo por agresión dentro del campo — _Federacion.abrir_caso('agresion',j,6,...) suspende al jugador_
- 817. Jugador que da positivo y el impacto deportivo y de imagen — _control_antidopaje positivo => j.suspension>0, signal escandalo_
- 818. Defensa legal del club en un caso de dopaje — _Federacion.apelar(id_dopaje, club)_
- 819. Reglamento de competencia consultable dentro del juego — _Federacion.reglas_vigentes('CHI') no vacío_
- 826. Sanción por alineación indebida — _LeyesPais.infracciones_once(club, once) con once indebido y revisar_leyes_pais_
- 827. Pérdida de puntos por incumplimiento administrativo — _Liga.sancionar(club.id, 3) baja tabla_puntos_

**45. Federaciones, Licencias y Política Deportiva**
- 831. Licencia de club exigida para competir — _Federacion.auditoria_anual(club,obras,anio)['estado']_
- 832. Requisitos de infraestructura mínima por división — _Federacion.requisitos_licencia(club,obras) devuelve 'ok' false con aforo bajo_
- 833. Requisitos financieros para obtener la licencia — _requisitos_licencia con club en rojo => fallos_
- 834. Auditoría federativa anual — _Federacion.auditoria_anual con 3 fallos => licencia=='denegada'_
- 837. Presidente de la liga con agenda propia — _Federacion.revisar_presidencia(anio) fija presidente['agenda']; agenda_empuja('var')_
- 844. Fecha FIFA que te deja sin jugadores clave — _Selecciones._fecha_fifa(anio,semana) baja j.fisico de convocados_
- 846. Compensación económica por cesión a la selección — _Selecciones tras lesión de gira: saldo del club sube_
- 847. Cupos obligatorios de juveniles en cancha — _Federacion.cupo_juvenil=true; revisar_cupo_juvenil(club, once_sin_sub21) devuelve multa_
- 848. Bonificación federativa por dar minutos a canteranos — _revisar_cupo_juvenil con juveniles en el once devuelve bono>0_
- 850. Playoffs de descenso con máxima tensión — _Mundo.jugar_promocion() con promocion activa mueve clubes de liga_

**46. Selecciones Nacionales**
- 862. Convocatorias con lista preliminar y lista definitiva — _Selecciones.semana(anio,6) publica prenómina; en semana 7 convoca 18_
- 863. Jugadores nacionalizados por años de residencia — _Selecciones.residencias() 4 veces y nacionalizar(j) fija nacionalidad_deportiva_
- 867. Copa del mundo simulada cada cuatro años — _Selecciones.toca_copa_del_mundo(2026+4k) y copa_del_mundo(anio) devuelve campeón_
- 871. Conflicto club-selección por un jugador clave — _Selecciones.pedir_descanso(j) => pidio_descanso(j)_
- 872. Jugador que vuelve lesionado o agotado de la selección — _Selecciones._fecha_fifa y comprobar j.fisico baja y vuelve_tocado_
- 874. Vitrina mundialista que dispara el precio de tus jugadores — _Selecciones._vitrina_mundialista(j,anio) en bucle sube j.ovr y valor_
- 881. Amistosos internacionales que generan ingresos — _Mundo.jugar_amistosos('gira') suma saldo neto positivo con rep alta_

**47. Competencias y Formatos**
- 886. Editor de competencias personalizado — _Editor.renombrar_liga(l,'Torneo X'); fijar_descensos(l,3); fijar_puntos_victoria(l,2)_
- 890. Copas de eliminación directa — _Copa.new('X').preparar(clubes); jugar_hasta_el_final() devuelve campeón_
- 893. Supercopa entre campeones — _Mundo.jugar_supercopa() con campeones distintos devuelve {campeon}_
- 894. Copa de la liga como torneo secundario — _Copa.copas_de('ENG','Inglaterra').size()==2_
- 895. Torneos de verano y amistosos de pretemporada — _Mundo.jugar_amistosos('local') sube forma de la plantilla_
- 896. Copa internacional de clubes — _Continental.sortear(clubes, ligas, campeon_copa) devuelve torneos de 16_
- 901. Sorteo transmitido en vivo como evento del juego — _Copa.anunciar_sorteo() emite sorteo_eliminatoria con parejas_
- 903. Fase de grupos con múltiples criterios de clasificación — _Continental.preparar y tabla_de_grupo(i) ordenada_
- 904. Eliminatoria a partido único en cancha neutral — _Copa.jugar_ronda en final => p.neutral_
- 905. Final única en sede predefinida con años de anticipación — _Editor.fijar_sede_final(club); Copa.sede_final_id_
- 907. Premios económicos crecientes por fase alcanzada — _Continental.premio_de_ronda(n) creciente_
- 908. Cupos internacionales asignados por posición en la liga — _Continental.plazas(clubes,ligas,campeon) devuelve 16 por copa_

**48. Datos, Editor y Comunidad**
- 911. Base de datos editable desde el propio juego — _Editor.renombrar_club(c,'X'); c.nombre=='X'_
- 912. Editor de ligas, clubes y jugadores sin salir de la partida — _Editor.fijar_campo(j,'edad',30) en partida cargada_
- 914. Exportación de tu base para compartirla con otros — _Editor.exportar_csv(true) devuelve texto reimportable (importar_csv)_
- 916. Editor de escudos con formas y capas — _Club.esc_forma='x'; Escudo.firma_identidad cambia_
- 917. Editor de camisetas con patrones predefinidos — _Club.kit_estilo cambia Prensa.firma_identidad_
- 918. Editor de estadios simplificado — _EstadioPropio.aplicar_preset('x') y presupuesto()_
- 919. Nombres genéricos por defecto con opción de renombrar todo — _Datos.base_real==false por defecto; Editor.renombrar_club_
- 923. Sistema de parche de datos separado del programa principal — _Datos.usar_base_real(true) con pack presente => base_real true_
- 924. Editor de nombres de competencias — _Editor.renombrar_liga(l,'Liga Z')_
- 928. Editor de atributos con validación de rangos — _Editor.mover_atributo(j,'tir',999) queda en 99_
- 929. Generador aleatorio de mundo ficticio completo — _Mundo.new(); generar(semilla) crea clubes y jugadores_
- 930. Modo mundo alternativo sin ningún dato real — _Datos.base_real==false y nombres censurados_
- 942. Modo sin conexión totalmente funcional — _Ejecutar sin red; Partida.guardar/cargar_
- 944. Compatibilidad garantizada con dispositivos de gama baja — _RendimientoAdaptativo + Calidad.nivel_

**49. Modos de Juego y Desafíos**
- 946. Modo carrera clásico con club a elección — _Mundo.tomar_el_mando('club_id') crea Directiva y objetivo_
- 948. Modo club creado desde cero en la última división — _Mundo.fundar_club('X','CHI','#fff','#000','E') devuelve Club_
- 949. Modo salvar al club con quiebra inminente — _Retos.montar(m,'deuda') deja c.saldo<0; Retos.juzgar_
- 950. Modo solo canteranos: prohibido fichar — _Mundo.desafios=['cantera']; Mercado.abrir_negociacion(j) devuelve texto de veto_
- 952. Modo un solo país: sin extranjeros permitidos — _Mundo.desafios=['local']; abrir_negociacion(jugador extranjero) devuelve motivo_
- 953. Modo trotamundos: obligado a cambiar de club cada dos años — _Mundo.desafios=['trotamundos']; tras 2 temporadas resumen['trotamundos']==true_
- 955. Modo invicto: la partida termina con la primera derrota — _Mundo.desafios=['invicto']; _chequear_desafios_tras_partido(0,1,r) fija fin_partida_
- 959. Modo dueño: solo decisiones financieras — _Roles.rol==DUENO; puede_inyectar_capital()_
- 961. Modo director deportivo: solo fichajes y cantera — _Roles.arrancar('dir'); puede_alinear()==false, puede_fichar()==true_
- 970. Modo caja de arena con recursos infinitos — _Roles.arrancar('jeque') deja caja muy alta_
- 973. Modificadores activables al iniciar la partida — _Mundo.desafios=[...]; tiene_desafio('x')_
- 974. Puntaje de partida calculado según la dificultad elegida — _Mundo.puntaje_carrera()['total']==base*multiplicador_
- 985. Tutorial narrativo integrado a la primera temporada — _Tutorial.visto()_

**50. Progresión Meta y Rejugabilidad**
- 988. Nivel de perfil de gestor que persiste entre partidas — _Logros.perfil_sumar_xp(100,'x') suma una vez (hito); perfil_leer()['xp']_
- 990. Colección de cromos de jugadores legendarios de tus partidas — _Meta.abrir_sobre(mundo) devuelve 5 cromos y los guarda en Meta.leer()['cromos']_
- 991. Museo global que reúne lo logrado en todas tus carreras — _Meta.registrar_trofeo(...) y Meta.leer()['museo'] crece_
- 993. Récords personales por carrera — _Logros.tras_partido con 5-0 => rec['mayor_goleada']_
- 997. Hitos narrativos que cierran capítulos de tu carrera — _Roles.cerrar_capitulo('c','Club',2030,'despido') añade al historial_
- 998. Final de carrera con evaluación completa de tu legado — _Roles.veredicto_carrera()['texto'] no vacío_
- 1002. Resumen de vida al momento de retirarte — _Roles.retirarse() devuelve '' y deja veredicto_
- 1004. Historial de todos los clubes dirigidos con su balance — _Roles.cerrar_capitulo + abrir_capitulo y Roles.curriculum.size()_
- 1006. Mundo distinto en cada partida nueva — _Mundo.generar([],1) vs generar([],2) difieren en jugadores_
- 1010. Nueva partida con el mundo heredado de la anterior — _Meta.heredar_proximo=true; Mundo.generar() usa reputaciones guardadas_

**51. Interfaz y Calidad de Vida**
- 1011. Navegación por pestañas inferiores fijas — _Principal._pestanas existe con 5 hojas_
- 1015. Marcar mensajes como leídos en bloque — _Movil.recibir x3; leer_todo(); sin_leer()==0_
- 1018. Favoritos para acceso rápido a pantallas frecuentes — _Principal._alternar_favorito('Club') añade a _favoritos_
- 1019. Comparador de jugadores lado a lado — _Principal._comparar_ids max 3_
- 1024. Escalado de texto para accesibilidad — _Principal._escala_texto=1.5 y _texto(12,...) escala el tamaño_
- 1025. Paletas alternativas para daltonismo — _Principal._daltonico=true cambia los colores de _color_accesible_
- 1029. Autoguardado configurable — _Principal._autoguardado=true; Partida.guardar(mundo,RANURA)_
- 1030. Guardado manual con varias ranuras — _Partida.guardar(mundo,'ranura1'); Partida.listar() las incluye_
- 1038. Glosario integrado de términos del juego — _Datos.tabla('GLOSARIO') no vacío_
- 1041. Modo experto que oculta toda la ayuda — _Principal._modo_experto=true y _pintar_* omiten notas_
- 1043. Widget de próximo partido — _TableroInicio.pintar(...) (UI)_
- 1044. Widget de finanzas resumidas — _TableroInicio._tarjeta_caja_
- 1045. Widget de tabla de posiciones — _TableroInicio._tarjeta_posicion_
- 1049. Rendimiento fluido en dispositivos de gama baja — _RendimientoAdaptativo_

**52. Audio, Estética y Presentación**
- 1053. Paleta que se adapta automáticamente a los colores del club — _Club.color_acento() usa color del club_
- 1054. Tipografía condensada, legible en pantallas pequeñas — _Principal.TIPOGRAFIAS.has('estrecha')_
- 1059. Animaciones cortas y funcionales, nunca bloqueantes — _Animar.reducidas(); Animar.aparecer(control)_
- 1062. Sonido ambiente de estadio durante el partido — _Sonido.toca('murmullo',Sonido.Bus.AMBIENTE)_
- 1063. Silbato, murmullo y explosión de gol como capas separadas — _Sonido.volumen[Sonido.Bus.AMBIENTE] independiente del de EFECTOS_
- 1065. Música de menú discreta y desactivable — _Musica.parar(); Musica.aplicar_volumen(0)_
- 1067. Sonido distintivo para el gol propio y para el gol rival — _Sonido.NOMBRES.has('gol_rival')_
- 1068. Modo silencioso completo para jugar en público — _Sonido.encendido=false; Sonido.toca no reproduce_
- 1070. Portada de diario animada para las noticias importantes — _Prensa.guardar_portada + PortadaPeriodico (UI)_
- 1071. Tarjetas visuales para los resúmenes de temporada — _DocumentalTemporada.guion(mundo) devuelve páginas_
- 1074. Celebración sobria pero satisfactoria al ganar un título — _Logros.celebrar_titulo('Liga') suma trofeo/xp y emite señal_

**53. Monetización y Modelo Indie**
- 1080. Sin mecánicas de pagar para ganar — _Escanear código: ninguna llamada a SDK de compras_
- 1096. Sin necesidad de conexión permanente para jugar — _Escanear fuentes por HTTPRequest/WebSocketPeer y afirmar 0_
- 1097. Sin recolección innecesaria de datos personales — _Escanear fuentes por 'analytics, telemetr, HTTPRequest' y afirmar 0_

### Parciales (qué falta) (222)


**30. Simulación de Partido (motor y experiencia)**
- 351. Motor 2D cenital con fichas de color en vez de modelos 3D (bajo costo, alta legibilidad) — _El motor visible del partido es 3D (visor/motor_jugable*.gd); no hay vista cenital de fichas como motor principal/alternativo de bajo coste_
- 356. Cadenas de jugada: la simulación encadena 3 a 5 acciones antes de resolver — _En Partido.simular_minuto cada llegada se resuelve con una sola tirada (partido_p2.gd:313 _atacar), sin cadena de 3-5 acciones_
- 359. Interrupciones: invasión de cancha, corte de luz, lluvia intensa — _No hay corte de luz ni otras interrupciones; lluvia intensa solo como clima base_
- 364. Riesgo de lesión visible al forzar a un jugador tocado — _No hay aviso/riesgo visible al decidir alinear a un tocado durante el partido o antes de forzarlo_
- 366. Tanda de penales con elección de palo y orden de ejecutantes — _No hay elección del orden de ejecutantes ni selección de palo por el DT en la tanda automática_
- 367. Especialistas designados para penales, córners y tiros libres — _En modo DT no se designa especialista concreto por jugador para penal/córner/falta_
- 368. Rendimiento diferenciado por altitud, clima y desgaste de viaje — _Sin altitud en ningún sitio; clima y viaje sí_
- 369. Efecto medible del público según ocupación real del estadio — _No se encontró efecto del nº de público/ocupación sobre el resultado del partido (ventaja local ligada a aforo ocupado)_
- 370. Cancha en mal estado que reduce precisión de pases — _Afecta probabilidad de ataque en general, no 'precisión de pases' específicamente; solo cuando el estadio es tuyo_
- 374. Nota de rendimiento por jugador (1 a 10) con justificación breve — _No hay justificación breve por nota (solo número)_
- 375. Detección automática de "partido histórico" archivado en el club — _Solo por diferencia de goles/penales; no detecta finales, remontadas épicas ni derbis (remontada sí se marca como logro)_
- 377. Dificultad de la IA rival ajustada por liga y presupuesto — _La IA rival simulada no se ajusta por liga ni presupuesto como mecánica explícita (la fuerza viene del plantel)_

**31. Táctica y Sistema de Juego**
- 384. Instrucciones individuales por jugador — _No hay instrucciones sueltas por jugador (mantener posición, tirar a puerta, marcar a X); solo el rol_
- 396. Plan A / Plan B / Plan C activables según el marcador — _Solo dos planes condicionados al marcador (ofensivo/cerrojo), no A/B/C seleccionables_
- 397. Cambio táctico automático por minuto (ej. cerrar desde el 80) — _El minuto es fijo (60); no se puede configurar 'desde el 80'_
- 399. Penalización si el sistema no calza con las cualidades del plantel — _No hay penalización global por elegir una formación que no calza con las cualidades del plantel_
- 401. Recomendación del ayudante técnico (activable o desactivable) — _El 'ayudante técnico' no existe como recomendador de alineación/táctica; solo el informe del rival se puede apagar_
- 402. Contra-táctica diseñada para un rival concreto — _El bono es genérico (+1-7%) y no diseña una contra-táctica específica contra el sistema del rival_
- 408. Identidad de juego del club definida a largo plazo — _La identidad de juego no la define el club a largo plazo ni condiciona la plantilla (excepto Athletic-like por región)_
- 410. DT con estilo propio que choca o encaja con la identidad del club — _No hay choque/encaje entre el estilo del DT y una identidad del club_
- 415. Alineación automática sugerida según frescura y rival — _No considera al rival ni sugiere explícitamente; frescura entra solo vía j.forma_

**32. Entrenamiento y Desarrollo**
- 427. Microciclo de recuperación tras partidos seguidos — _No existe microciclo automático/sugerido tras partidos seguidos (hay que ponerlo a mano)_
- 431. Trabajo mental con psicólogo deportivo — _El psicólogo mejora charlas y terapia; no existe un bloque de entrenamiento de 'trabajo mental' que haga progresar atributos_
- 432. Entrenamiento de liderazgo para formar futuros capitanes — _No hay entrenamiento específico que forme futuros capitanes_
- 433. Entrenador de arqueros con línea de desarrollo propia — _Es un bono de staff, sin línea de desarrollo propia (plan de porteros)_
- 434. Cantera entrenada bajo una filosofía definida por el club — _El club no define una filosofía de formación propia para su cantera_
- 435. Informe semanal de progreso entregado por el staff — _No hay un informe semanal del staff dedicado al progreso de jugadores_
- 437. Disciplina individual que determina cuánto aprovecha el entrenamiento — _La disciplina/profesionalidad individual no multiplica el aprovechamiento del entrenamiento del primer equipo_
- 444. Declive físico realista según edad y posición — _Declive igual para todas las posiciones (solo distingue portero) y sin escalonado por edad_
- 445. Historial gráfico de evolución de atributos por jugador — _Es tabla de texto; solo el ovr, no historial gráfico por atributo_

**33. Scouting y Red de Ojeadores**
- 447. Costo mensual por ojeador y por región cubierta — _No se cobra un sueldo mensual por ojeador/región cubierta (solo por informe y por academia)_
- 452. Descubrimiento de joyas en ligas menores o mercados exóticos — _No hay 'ligas menores' ni mercados exóticos exploración explícita (usa países cubiertos)_
- 454. Filtros de búsqueda avanzados (edad, valor, contrato, posición) — _Faltan filtros por edad, valor, contrato, país y potencial_
- 455. Lista de seguimiento con alertas automáticas — _No emite alertas automáticas sobre los seguidos_
- 456. Alerta de jugador que entra en su último año de contrato — _No hay alerta de jugadores AJENOS en su último año de contrato_
- 460. Rumores de mercado que pueden resultar falsos — _No hay rumores de mercado generados con porcentaje de falsedad_
- 463. Informe de situación familiar que afecta la disposición a mudarse — _Sin situación familiar propia (pareja, hijos) para jugadores ajenos_
- 467. Ranking interno de objetivos por prioridad — _Sin ranking interno priorizado de objetivos_
- 472. Torneos juveniles internacionales como escaparate de talento — _No es una competición juvenil escaparate de talento ajeno que se pueda ojear_

**34. Regens, Hijos de Jugadores y Linaje**
- 478. Herencia parcial de atributos del padre con variación aleatoria — _Los atributos individuales no se heredan (generar_atributos sortea desde cero); solo el techo y la posición_
- 488. Ex-jugador que regresa como DT del club donde brilló — _No hay evento donde un ex-jugador del club regrese como DT de la IA_
- 489. Regens generados con nacionalidad ponderada por la fuerza del país — _No hay ponderación de nacionalidad por fuerza del país (los canteranos son del país del club salvo extranjeros por origen)_
- 490. Nombres realistas por país y por época de nacimiento — _Nombres por país sí; por época de nacimiento no (sin pools por década)_
- 493. Regens de élite: dos o tres por generación con potencial de leyenda — _No hay garantía de 2-3 regens de élite por generación_
- 494. Rareza de potencial (común, prometedor, excepcional, generacional) — _No hay categoría de rareza de potencial para canteranos en la ficha_
- 496. País pequeño que produce un talento generacional como historia épica — _No hay historia épica generada ni garantía para países pequeños_
- 503. Regen prometedor que se pierde por indisciplina — _No hay pérdida del regen por indisciplina específica_
- 504. Regen que sufre una lesión grave y trunca su carrera — _No es específico de regens y solo para tu club_
- 505. Regen que emigra demasiado joven y no se desarrolla — _No hay 'emigrar demasiado joven y no desarrollarse' como efecto negativo posterior_
- 506. Doble nacionalidad asignada a ciertos regens — _La doble nacionalidad no se asigna a regens al nacer; solo tramitada por el usuario_
- 509. Registro histórico de dinastías formadas en tu club — _No hay registro persistente de dinastías formadas en el club (las leyendas usadas se podan)_
- 515. Modo legado familiar: mantener una misma familia tres generaciones — _No es un modo 'tres generaciones' con objetivo, solo la mecánica_

**35. Lesiones y Medicina Deportiva**
- 523. Costo de operaciones y clínicas de calidad variable — _No hay clínicas externas de calidad/precio variable por operación_
- 527. Riesgo de lesión aumentado por cancha en mal estado — _El desgaste del césped no sube el riesgo de lesión (solo la superficie elegida); el mal estado afecta rendimiento, no lesiones_
- 528. Riesgo de lesión aumentado por calendario congestionado — _No hay recargo de lesión explícito por jugar 3 partidos en una semana_
- 533. Jugador que se infiltra para jugar, con riesgo posterior — _En modo DT no existe infiltrar a un jugador_
- 545. Nutricionista que reduce la incidencia de lesiones blandas — _El del primer equipo recupera físico, pero no reduce incidencia de lesiones blandas_

**36. Vestuario, Psicología y Dinámica de Grupo**
- 549. Jugador que pide hablar contigo en privado — _No es una charla 'en privado' diferenciada; es una solicitud con dos respuestas_
- 552. Jugador que exige renovación tras un buen semestre — _No condicionado a 'buen semestre' explícito (depende de candidatos por situación)_
- 553. Jugador que se ofende si queda fuera de la lista de un torneo — _No hay reacción de ofensa del jugador por quedar fuera de la lista de un torneo_
- 555. Reacción del vestuario ante la venta de un referente — _Reacción explícita ante la venta de un referente_
- 558. Moral colectiva separada de la moral individual — _No hay variable 'moral colectiva' separada guardada_
- 559. Efecto acumulativo de las rachas de derrotas en el ánimo — _Efecto acumulativo explícito en el ánimo interno: solo ansiedad por mala racha_
- 562. Perfil psicológico oculto que se descubre con el tiempo — _No hay perfil psicológico oculto que se descubre con el tiempo en tus propios jugadores_
- 567. Jugador con problemas personales que necesita apoyo del club — _Los problemas personales (familia, salud) no son un evento propio; solo ansiedad_
- 570. Barrera idiomática que dificulta la integración — _No existe 'barrera idiomática' como variable; solo el traductor y la promesa de compatriota_
- 573. Actividades de integración del plantel — _No hay actividades de integración elegibles (cena, viaje, asado)_
- 575. Jugador que se siente traicionado si lo criticas en prensa — _No hay reacción de traición de un jugador criticado en prensa_
- 576. Defensa pública de un jugador que dispara su moral — _No hay 'defensa pública de un jugador concreto' que dispare su moral_
- 579. Índice de confianza del plantel hacia tu gestión — _No existe un índice agregado de confianza del PLANTEL hacia el DT (Gente.confianza_media es de empleados del club)_
- 580. Renovación generacional del liderazgo del vestuario — _No hay evento de relevo generacional de liderazgo_

**37. Mercado de Fichajes Avanzado**
- 591. Bonos por partidos jugados, goles marcados y títulos ganados — _Solo bonos por partidos; faltan goles marcados y títulos_
- 592. Derechos de formación y mecanismo de solidaridad — _No hay mecanismo de solidaridad (porcentaje a clubes formadores)_
- 597. Jugador que solo aceptará ir a un club grande — _No existe el rasgo 'solo irá a un grande' (umbral duro)_
- 599. Último día de mercado con ofertas frenéticas de última hora — _No hay ofertas frenéticas especiales en el último día (misma frecuencia)_
- 601. Fichaje caído por problema de visa o cupo de extranjeros — _No hay visa/papeleo como evento que tumbe un fichaje ya cerrado_
- 604. Lista de inscritos por torneo con decisiones difíciles — _Sin inscripción separada por torneo (liga/copa/continental)_
- 607. Valor de mercado dinámico según rendimiento y contrato — _El valor no depende del rendimiento reciente (goles/notas)_
- 615. Historial completo de operaciones con balance neto acumulado — _No hay historial completo multi-temporada con balance neto acumulado_

**38. Agentes, Representantes y Zonas Grises**
- 618. Agente que te ofrece jugadores en exclusiva si le caes bien — _negociacion.gd:19 admite que la exclusiva (G.exclusiva) NO está portada como efecto en el mercado; solo se guarda el nombre_
- 619. Agente que te bloquea operaciones si lo tratas mal — _No hay un bloqueo explícito de operaciones con sus jugadores por trato hostil_
- 621. Comisiones negociables y su impacto en el presupuesto — _La comisión por traspaso no se negocia, la fija el perfil del agente_
- 624. Investigación federativa por operaciones sospechosas — _La 'investigación' solo resta confianza al directorio; no abre expediente federativo con sanción por operaciones sospechosas_
- 627. Contabilidad paralela como opción arriesgada y sancionable — _riesgo_opaco solo se acumula y se guarda: ninguna lógica lo lee para sancionar_
- 629. Presión de un dirigente para fichar a un representado suyo — _No se trata de 'un representado suyo' sino de un libre que impone la directiva_
- 635. Filtración de un contrato completo a la prensa — _No se filtra un contrato completo (cláusulas, sueldos)_

**39. Economía Avanzada, Deuda e Insolvencia**
- 641. Estado de resultados mensual y anual del club — _Solo hay proyección anual en pantalla; no hay estado de resultados mensual histórico ni cierre anual guardado (el cierre de mes es una línea de log: principal_p9.gd:278)_
- 644. Diferencia explícita entre resultado contable y caja disponible — _No hay concepto explícito 'resultado contable' (devengado) vs caja: el resultado se usa como flujo_
- 648. Líneas de crédito y capacidad máxima de endeudamiento — _La capacidad máxima de endeudamiento es el tope de 2 líneas + monto fijo por club, no una capacidad calculada de balance/ingresos_
- 651. Mora en el pago de sueldos y sus consecuencias inmediatas — _Los sueldos nunca se dejan de pagar realmente: la mora es por caja negativa, y la huelga es un evento aleatorio_
- 652. Jugadores habilitados a rescindir por sueldos impagos — _Tus jugadores no pueden rescindir por impago: no hay lógica que lo haga_
- 655. Descenso administrativo por insolvencia — _No hay descenso de categoría por insolvencia: el final es la liquidación/fin de etapa, no un descenso administrativo_
- 660. Venta forzada de activos: estadio, ciudad deportiva, terrenos — _Venta forzada de estadio, ciudad deportiva o terrenos_
- 666. Fondo de inversión que compra un porcentaje del club — _No hay un fondo externo que compre un porcentaje de TU club_
- 671. Tope salarial interno autoimpuesto — _Tope salarial autoimpuesto por el usuario_
- 672. Escalas salariales y conflictos internos por desigualdad — _No hay escala salarial formal ni conflicto sistemático por desigualdad_
- 677. Auditoría anual con informe público — _Es auditoría de licencia (6 requisitos), no auditoría financiera con informe público de cuentas_
- 678. Panel de indicadores financieros (liquidez, endeudamiento, cobertura) — _Falta liquidez corriente y endeudamiento (deuda/patrimonio) como indicadores_

**40. Propiedad, Directorio y Política Interna**
- 682. Elecciones de presidente cada cierto número de años — _No hay elecciones de presidente del CLUB cada N años_
- 683. Campaña electoral con promesas que después debes cumplir — _No hay campaña electoral del club con promesas posteriores verificables_
- 687. Asamblea anual de socios con preguntas incómodas — _No es una asamblea anual de SOCIOS con preguntas incómodas (es junta de accionistas + encuestas de hinchada)_
- 692. Conflicto por modificar el escudo o los colores tradicionales — _Sin conflicto con socios/votación; solo pregunta de rueda de prensa_
- 695. Refundación tras la quiebra, partiendo en la última división — _La refundación NO baja a la última división; mantiene categoría con reputación -12_
- 699. Delegar o no las negociaciones, con efecto en tu carga de trabajo — _No se puede delegar negociaciones de fichajes a un tercero ni ahorra 'carga de trabajo'_
- 700. Objetivos de temporada negociados con el directorio — _El objetivo NO se negocia (la propia cabecera dice 'No se elige')_
- 704. Cláusula de salida en tu propio contrato — _Solo existe ante mora; no es una cláusula general negociable en tu contrato_
- 705. Indemnización por despido — _No hay indemnización calculada por tu despido_
- 708. Elegir entre club grande con presión o proyecto largo sin prisa — _No hay descripción de 'proyecto largo sin prisa' vs 'presión' como opción narrativa_
- 710. Salón de la fama de dirigentes y entrenadores del mundo del juego — _El salón es de jugadores; no hay salón de dirigentes y entrenadores del mundo_

**41. Infraestructura Urbana y Entorno**
- 713. Conexión de transporte público hacia el estadio — _Sin efecto en asistencia ni inversión en transporte_
- 717. Estudio de impacto ambiental obligatorio — _No hay un estudio de impacto ambiental obligatorio como paso separado_

**42. Hinchada, Barras y Cultura Popular**
- 738. Índice de conexión emocional entre hinchada y equipo — _El 'índice de conexión emocional' es el ánimo genérico; no mezcla segmentos_
- 744. Barra organizada con demandas y riesgo de violencia — _La barra no tiene demandas explícitas ni violencia como entidad propia_
- 751. Entradas populares a precio social como decisión de imagen — _No hay 'entradas populares a precio social' como acción de imagen puntual_
- 754. Filiales internacionales si el club se globaliza — _No hay 'filiales internacionales' formales por globalización del club_
- 757. Ídolo popular al que la hinchada protege aunque rinda poco — _No hay protección de la hinchada a un ídolo con mal rendimiento_
- 759. Silbatina en el estadio que afecta el rendimiento del equipo — _No hay silbatina en el estadio que afecte el rendimiento del equipo en el partido_
- 760. Proceso de recuperación de la confianza tras una crisis — _No hay un proceso explícito de recuperación de confianza tras una crisis_
- 761. Documental sobre la hinchada producido por el club — _Es de la temporada, no sobre la hinchada_
- 762. Museo con exhibición participativa de objetos de hinchas — _Sin exhibición participativa de objetos de hinchas_
- 764. Programa social en barrios vulnerables — _No son programas sociales en barrios vulnerables específicos_

**43. Prensa, Medios y Narrativa**
- 774. Periodista aliado al que puedes filtrar información — _No hay filtrar información a un periodista aliado como acción_
- 779. Multa federativa por declaraciones desafortunadas — _Solo ligada al reclamo arbitral, no a cualquier declaración polémica en rueda de prensa_
- 782. Encuesta de opinión pública sobre tu continuidad — _No hay encuesta de opinión sobre tu continuidad como DT_
- 784. Filtración de la alineación antes del partido — _La filtración de TU alineación al rival no existe_
- 785. Investigación periodística sobre las finanzas del club — _No hay investigación periodística sobre las finanzas como evento_
- 788. Departamento de comunicaciones mejorable por niveles — _No hay un 'departamento de comunicaciones' con niveles propios para la imagen/crisis_
- 796. Presión por jugar en horarios incómodos para el hincha — _El hincha no reacciona como grupo (segmentos) al horario_

**44. Árbitros, Reglamento y Disciplina**
- 811. Suspensión automática por acumulación de amarillas — _No hay suspensión automática por acumulación de amarillas entre partidos (N amarillas = 1 fecha)_
- 824. Criterios de desempate configurables — _Solo dos criterios (enfrentamiento directo o diferencia de gol), no configurables libremente_
- 828. Protesta formal contra un resultado — _No cambia resultado ni se protesta por alineación indebida del rival_
- 829. Fallo del tribunal que modifica la tabla de posiciones — _No existe fallo que revierta un resultado de partido_
- 830. Historial disciplinario del club por temporada — _No hay vista de historial disciplinario del club por temporada_

**45. Federaciones, Licencias y Política Deportiva**
- 836. Alianzas políticas con otros clubes — _No hay pactos con clubes concretos, solo un contador de peso político_
- 840. Sanción por participar en una liga no reconocida — _No hay sanción federativa formal (multa/puntos) por participar en una liga no reconocida; solo funa_
- 842. Lucha por una mayor tajada de los ingresos centrales — _No hay lucha política continua por tajada de ingresos centrales más allá de esas dos decisiones_
- 843. Calendario definido por la federación con conflictos de fechas — _El calendario es fijo del juego; la federación no lo define ni hay conflictos de fechas resolubles_
- 845. Reclamo por lesión de un jugador en la selección — _No hay un 'reclamo' como acción del usuario; la compensación es automática_
- 849. Cambio de formato de ascensos y descensos entre temporadas — _Solo esos cambios de formato; no hay cambios de número de ascensos/descensos (Editor.fijar_descensos es de editor)_
- 853. Corrupción federativa como trama de fondo de la partida — _Es un asunto puntual, no una trama de fondo que evolucione_
- 856. Torneo continental nuevo creado a mitad de partida — _No se crea un torneo continental nuevo a mitad de partida_
- 857. Ranking de coeficientes de países que define cupos — _Los cupos por país son fijos (PAIS_ANFITRION); no hay coeficiente de país que cambie los cupos_
- 860. Gira internacional que requiere aprobación federativa — _No requiere aprobación federativa_

**46. Selecciones Nacionales**
- 861. Modo seleccionador nacional paralelo o alternativo — _No existe un modo de dirigir una selección (ni paralelo ni alternativo); no hay Roles.SELECCIONADOR_
- 868. Torneos continentales con formatos propios — _El puesto se sortea con bolsa sesgada, sin cuadro propio por formato_
- 873. Prestigio del club según cantidad de seleccionados — _El prestigio/reputación del club no depende de cuántos seleccionados tiene_
- 875. Ojear durante un mundial y fichar a la revelación — _No hay revelación de otros clubes durante el mundial que se pueda ojear_
- 878. Historial de seleccionados formados en tu club — _No hay historial de seleccionados formados en tu club_
- 879. Ranking mundial de selecciones dinámico — _La fuerza es casi estática por nombre; no se recalcula con los jugadores reales_
- 880. Naturalización masiva en países pequeños como dilema — _Es tramitación individual por el usuario; no hay naturalización masiva como dilema_

**47. Competencias y Formatos**
- 887. Crear tu propia liga con reglas a medida — _No se puede crear una liga nueva desde cero con reglas propias (la cabecera de editor.gd dice 'No crea clubes ni ligas nuevas')_
- 888. Definir número de equipos, ascensos y descensos — _El número de equipos y los ascensos no son editables_
- 889. Formatos: todos contra todos, apertura y clausura, playoffs — _No hay formato Apertura/Clausura ni elegir formato desde editor_
- 891. Copa nacional con participación de equipos amateurs — _No hay equipos amateurs ajenos a las ligas_
- 892. Cenicienta de copa que llega inesperadamente lejos — _No hay detector/narrativa de 'cenicienta' que llega lejos (sale por azar del cuadro)_
- 897. Mundial de clubes con formato ampliado — _Formato fijo simplificado; no un formato ampliado configurable_
- 900. Sistema de sorteo con bombos y restricciones — _El sorteo de copa es por orden de lista sin restricciones; en grupos hay restricción de cruces_
- 906. Definición por penales con estadísticas históricas propias — _No hay estadística histórica de tandas de penales por club/jugador_
- 910. Calendario visual con todas las competencias superpuestas — _No hay vista visual con todas las competencias superpuestas_

**48. Datos, Editor y Comunidad**
- 913. Importación de paquetes de datos creados por la comunidad — _Solo UN pack a la vez y sin gestor de paquetes comunitarios_
- 915. Verificación de compatibilidad entre versiones de datos — _El pack tiene campo 'formato' pero no se verifica su valor; no hay compatibilidad entre versiones de datos_
- 920. Herramienta de renombrado masivo — _No hay herramienta de renombrado masivo de clubes/ligas (solo uno a uno o vía CSV de jugadores)_
- 925. Editor de reglas de competencias existentes — _Solo tres reglas editables; las demás (formato, cupos) se votan en la federación_
- 927. Editor de finanzas iniciales de cada club — _No hay función explícita para finanzas iniciales de un club (saldo) en Editor_
- 933. Copias de seguridad automáticas de la base — _El respaldo es de la partida, no de la base de datos editada_
- 936. Compartir capturas de logros con formato propio — _No hay captura de logro con formato propio para compartir_
- 940. Créditos automáticos a los autores de los datos — _Los autores del pack no se muestran automáticamente_

**49. Modos de Juego y Desafíos**
- 947. Modo empezar desde abajo con un club amateur — _No existe un club amateur ni división inferior a Segunda para empezar desde abajo_
- 954. Modo clásico eterno: ganar todos los derbis de la temporada — _El desafío castiga perder, no exige ganar todos los derbis de la temporada_
- 957. Modo dinastía familiar centrado en hijos y nietos — _No es un modo de juego centrado en la familia con objetivos de generaciones_
- 958. Modo presidente: solo decisiones institucionales — _No hay un modo 'presidente' solo institucional (la junta/accionistas existen como sistema)_
- 964. Escenario: evitar el descenso con el peor plantel de la liga — _No es 'evitar el descenso con el peor plantel' (la meta del reto es terminar entre los ocho primeros)_
- 968. Modo rápido de una sola temporada — _No hay un modo 'una sola temporada' con final y puntaje propio_
- 972. Dificultad ajustable por sistema (finanzas, mercado, IA rival) — _Global (3 niveles), no ajustable por sistema (finanzas/mercado/IA rival) y solo se aplica a la caja inicial_
- 980. Modo espectador de una liga completamente simulada — _No hay modo espectador de una liga sin gestor_
- 981. Modo solo simulación: ver evolucionar el mundo sin intervenir — _Siempre hay un club propio; no hay modo sin club que observe el mundo_
- 983. Semilla de partida compartible entre jugadores — _No hay entrada/compartición de semilla en la UI_
- 984. Modo sin recarga de partida guardada — _Es solo un aviso, sin bloquear la carga_

**50. Progresión Meta y Rejugabilidad**
- 986. Sistema de logros con recompensas cosméticas — _Las recompensas por logro son XP y sobres; cosméticos solo escudos especiales por nivel_
- 987. Desbloqueo de estadios, escudos y camisetas por logros — _Solo escudos; no se desbloquean estadios ni camisetas_
- 989. Árbol de mejoras de perfil, opcional y desactivable — _Las maestrías son de la partida, no un árbol de perfil entre partidas desactivable_
- 992. Estadísticas acumuladas de todas tus partidas — _No hay una pantalla de estadísticas acumuladas de todas las partidas (partidos, goles, títulos totales)_
- 996. Sistema de prestigio al reiniciar con pequeñas ventajas — _No hay prestigio al reiniciar que dé ventajas pequeñas al jugador_
- 999. Epílogo generado según las decisiones tomadas — _El epílogo es una frase por rango, no se genera según decisiones concretas tomadas_
- 1000. Salón de la fama personal del jugador — _El salón es de jugadores del club, no el 'salón de la fama personal' del jugador/gestor_
- 1003. Placa conmemorativa por cantidad de temporadas dirigidas — _La placa es por títulos, no por cantidad de temporadas dirigidas_
- 1007. Eventos históricos aleatorios que cambian entre partidas — _No hay 'eventos históricos' que cambien el mundo entre partidas, solo eventos de club_
- 1008. Fuerza variable de las ligas en cada mundo generado — _No hay fuerza variable por liga en cada mundo generado (Datos fija ligas)_
- 1009. Cartas de evento que aparecen una sola vez por partida — _En modo DT no hay cartas de evento únicas por partida_

**51. Interfaz y Calidad de Vida**
- 1012. Botón de continuar siempre en la misma posición — _No es un único botón 'Continuar' universal; cambia según pantalla (Resumen ▶ Continuar en partido)_
- 1013. Bandeja de entrada unificada con notificaciones agrupadas — _La bandeja unificada solo cubre noticias mapeadas a remitentes; hay además banners (Aviso) y log sin agrupar_
- 1016. Buscador global de jugadores, clubes y competencias — _No busca competencias_
- 1020. Tablas ordenables por cualquier columna — _Sólo seis columnas definidas, no cualquier columna_
- 1022. Vista compacta y vista detallada intercambiables — _Compacta/detallada solo en alguna vista_
- 1023. Modo oscuro y modo claro — _No hay un interruptor claro/oscuro explícito: el juego es oscuro con paletas alternativas_
- 1028. Deshacer la última acción no crítica — _Solo estas dos decisiones, no un deshacer general_
- 1031. Carga inmediata de la última partida al abrir la app — _No se confirmó que cargue automáticamente la última al abrir_
- 1034. Resumen del día al avanzar el calendario — _No hay un 'resumen del día' formal al avanzar un día_
- 1037. Sugerencias contextuales desactivables — _No todas las sugerencias son desactivables individualmente_
- 1039. Ayuda contextual desplegable en cada pantalla — _No hay ayuda contextual desplegable uniforme por pantalla_
- 1042. Pantalla de inicio personalizable con widgets — _El tablero es fijo; no consume WIDGETS ni se personaliza_
- 1046. Widget de lesionados y suspendidos — _No hay tarjeta de lesionados en el tablero de inicio_
- 1050. Consumo de batería optimizado por diseño — _No hay un modo de batería explícito_

**52. Audio, Estética y Presentación**
- 1052. Íconos simples y consistentes en toda la aplicación — _No hay set de iconos propio y simple; dependen de la fuente emoji del sistema_
- 1056. Ilustraciones vectoriales para los eventos narrativos — _Los eventos narrativos usan texto/avisos, no ilustraciones vectoriales propias_
- 1057. Avatares minimalistas generados a partir de atributos — _No son avatares minimalistas ni derivados de atributos_
- 1058. Cancha 2D con fichas en los colores reales del club — _La vista principal es 3D, no cancha 2D con fichas_
- 1060. Transiciones suaves entre pantallas — _No hay transición uniforme entre todas las pantallas_
- 1061. Vibración breve en decisiones importantes — _Solo vibración de mando (Input.start_joy_vibration); no vibración del móvil (Input.vibrate_handheld); no en decisiones de gestión_
- 1064. Volumen del público según asistencia y momento del partido — _El volumen no escala con la asistencia real del partido_
- 1066. Cántico del club reproducido en momentos clave — _No hay cántico único del club_
- 1069. Pantalla de carga con datos curiosos del club — _Los consejos son del juego, no datos curiosos específicos del club_
- 1073. Gráficos limpios para finanzas y evolución de jugadores — _No hay gráficos de líneas de finanzas ni de evolución del jugador (solo tablas de historial y flujo de caja en texto)_

**53. Monetización y Modelo Indie**
- 1081. Sin cajas de recompensa ni azar pagado — _Existe una mecánica tipo 'sobre'; la promesa 'sin cajas de recompensa' es válida mientras no se pague_
- 1095. Compatibilidad hacia atrás de las bases de datos — _Sin versionado de bases de datos_

### No existen (173)


**30. Simulación de Partido (motor y experiencia)**
- 354. Relator de texto con tono configurable (sobrio, exagerado, humorístico) — _Todo_
- 365. Aviso de "amonestado bajo presión" antes de una posible expulsión — _No hay aviso de amonestado en riesgo de expulsión_
- 372. Relato del partido guardable y compartible como texto — _Todo_
- 373. Comparativa post-partido contra el promedio de la liga — _Todo_
- 379. Modo espectador para ver partidos de otros equipos — _Todo_
- 380. Resultados de la fecha actualizándose mientras juegas tu partido — _Todo_

**31. Táctica y Sistema de Juego**
- 381. Editor de formación con arrastrar y soltar — _Arrastrar y soltar jugadores/posiciones_
- 382. Formaciones guardadas como presets con nombre propio — _Presets nombrados de formación/táctica_
- 395. Saque lateral largo como arma táctica — _Todo_
- 398. Familiaridad táctica: el equipo tarda semanas en asimilar un sistema — _Todo_
- 403. Modo espejo: copiar la táctica de un equipo que admires — _Todo_
- 406. Táctica de emergencia con diez jugadores tras una expulsión — _Todo_
- 407. Plan de partido para jugar con ventaja numérica — _Todo_
- 409. Hinchada que exige un estilo (ofensivo, aguerrido, de toque) — _Todo_

**32. Entrenamiento y Desarrollo**
- 424. Explosión tardía: jugadores que despegan entre los 24 y 26 — _Explosión tardía_
- 425. Jugadores que se estancan si no acumulan minutos — _Estancamiento por falta de minutos_
- 428. Sesiones a puertas cerradas o abiertas al público — _Todo_
- 436. Jugadores que se quejan si el entrenamiento es muy duro o muy blando — _Todo_
- 438. Trabajo extra voluntario de los jugadores más profesionales — _Todo_
- 439. Pérdida de ritmo competitivo por parón de liga — _Todo_
- 440. Entrenamiento adaptado a la superficie de la próxima cancha rival — _Todo_

**33. Scouting y Red de Ojeadores**
- 451. Asignación de un ojeador a un torneo juvenil específico — _Todo_
- 457. Alerta de jugador descontento en otro club — _Todo_
- 458. Alerta de cláusula de rescisión anormalmente baja — _Alerta_
- 464. Invitar a un jugador libre a entrenar a prueba — _Todo_
- 465. Descubrimiento por casualidad durante un amistoso — _Todo_
- 473. Convenios con clubes menores por derecho de primera opción — _Todo_
- 474. Scouting de entrenadores y staff, no solo de jugadores — _Todo_

**34. Regens, Hijos de Jugadores y Linaje**
- 487. Padre retirado que presiona al club para que su hijo juegue — _Presión del padre retirado para que juegue su hijo_
- 500. Rasgos físicos heredados visibles en el avatar del hijo — _Todo_
- 501. Apodos automáticos para regens destacados — _Apodos de jugadores_
- 507. Regens que eligen selección nacional entre dos opciones — _Todo_
- 510. Bonificación de afinidad al fichar al hijo de un ídolo del club — _Todo_
- 511. Reacción hostil de la hinchada al fichar al hijo de un ídolo rival — _Todo_
- 512. Padrinazgo: un ídolo del club apadrina al hijo de otro — _Todo_
- 513. Evento: el padre retirado pide un cargo en la cantera — _Todo_
- 514. Estadística de cuántos regens de tu cantera llegaron a la élite — _Todo_

**35. Lesiones y Medicina Deportiva**
- 522. Seguro médico contratable para todo el plantel — _Todo_
- 526. Kinesiólogo que acorta los plazos de recuperación — _Todo (hay jefe médico, nutricionista y fisio decorativo en 3D)_
- 534. Costo reputacional si abusas de las infiltraciones — _Todo_
- 536. Índice de carga de trabajo por jugador durante el mes — _Índice de carga por jugador_
- 538. Alerta médica previa: "no recomiendo que juegue" — _Todo_
- 544. Regreso triunfal tras lesión larga como evento narrativo — _Todo_

**36. Vestuario, Psicología y Dinámica de Grupo**
- 554. Reacción del vestuario ante un fichaje muy caro — _Todo_
- 557. Consejo de capitanes que negocia contigo condiciones internas — _Todo_
- 571. Clases de idioma financiadas por el club — _Clases de idioma_
- 578. Jugador que se convierte en tu aliado dentro del grupo — _Todo_

**37. Mercado de Fichajes Avanzado**
- 581. Ventanas de mercado con fechas distintas según el país — _Fechas de ventana por país_
- 582. Mercado de invierno más caro y con menos opciones — _Recargo/menos oferta en invierno_
- 588. Cláusula de no alinear al cedido contra el club dueño — _Todo_
- 589. Cláusula que impide la reventa a un rival directo — _Todo_
- 596. Jugador que acepta menos dinero para jugar torneo internacional — _Todo_
- 600. Fichaje caído tras la revisión médica — _Todo_
- 605. Mercado inflado por un club recién comprado por un magnate — _Todo_
- 606. Burbuja de precios que crece con el paso de los años — _Todo_
- 609. Rechazo automático de ofertas por debajo de un monto fijado — _Todo_
- 612. Precontrato con jugador en su último semestre — _Precontrato en último semestre_
- 614. Traspaso récord del club registrado como hito histórico — _Todo_

**38. Agentes, Representantes y Zonas Grises**
- 626. Denuncia anónima que dispara una auditoría — _Todo_
- 632. Intermediario que infla artificialmente el precio de una operación — _Todo_
- 633. Agente que representa al comprador y al vendedor a la vez — _Todo_
- 634. Cláusula secreta que se revela tiempo después — _Todo_
- 636. Escándalo de amaño de partidos dentro de tu liga — _Todo_
- 638. Programa interno de integridad del club — _Todo_
- 639. Ranking de transparencia con efecto sobre los auspiciadores — _Todo_
- 640. Delación compensada dentro de un caso federativo — _Todo_

**39. Economía Avanzada, Deuda e Insolvencia**
- 645. Amortización del valor de los pases en libros — _Todo_
- 646. Plusvalía contable generada por venta de jugadores — _Todo_
- 650. Convenio de pago con proveedores — _Todo_
- 659. Junta de acreedores que vota el destino del club — _Junta de acreedores_
- 661. Venta del estadio con arriendo posterior como maniobra financiera — _Todo_
- 663. Aumento de capital con dilución de los accionistas actuales — _Todo_
- 665. Financiamiento colectivo de hinchas para un fichaje puntual — _Todo_
- 669. Presupuesto anual que debe aprobar el directorio — _Todo_
- 670. Reasignación de presupuesto entre fichajes y salarios — _Todo_
- 673. Impuestos por país y su efecto en el sueldo neto ofrecido — _Todo_
- 674. Régimen tributario especial para atraer extranjeros — _Todo_
- 675. Inflación y devaluación de la moneda local — _Todo_
- 676. Ingresos en moneda extranjera por torneos internacionales — _Todo_
- 679. Calificación de riesgo del club que encarece o abarata el crédito — _Todo_
- 680. Premio anual a la gestión financiera sostenible — _Todo_

**40. Propiedad, Directorio y Política Interna**
- 681. Elección entre club de socios o sociedad anónima deportiva — _Todo_
- 689. Oferta de compra hostil sobre el club — _Todo_
- 691. Dueño extranjero que quiere cambiar la identidad del club — _Todo_
- 693. Traslado del club a otra ciudad como decisión polémica — _Todo_
- 694. Fusión con otro club — _Todo_
- 707. Entrevista de trabajo con un club interesado — _Todo_

**41. Infraestructura Urbana y Entorno**
- 712. Ubicación del estadio que afecta la asistencia promedio — _Todo_
- 718. Estadio compartido con otro club de la misma ciudad — _Todo_
- 722. Estadio provisional mientras construyes el definitivo — _Todo_
- 723. Mudanza temporal a otra ciudad durante la obra — _Todo_

**42. Hinchada, Barras y Cultura Popular**
- 740. Protestas por la venta de un ídolo — _Todo_
- 742. Recibimiento masivo al bus del equipo — _Todo_
- 743. Mosaico organizado por la hinchada — _Mosaico como evento_
- 745. Decisión estratégica de negociar o enfrentar a la barra — _Todo_
- 747. Hinchada que viaja masivamente a un partido decisivo — _Todo_
- 748. Programa de socios con beneficios por antigüedad — _Todo_
- 756. Cánticos que aparecen dedicados a jugadores destacados — _Todo_
- 758. Jugador señalado por la hinchada tras un error decisivo — _Todo_
- 763. Colecta solidaria organizada por el club — _Todo_
- 768. Voluntariado de jugadores en la comunidad — _Todo_
- 770. Premio a la mejor institución del año — _Todo_

**43. Prensa, Medios y Narrativa**
- 783. Rumor falso de tu despido publicado en portada — _Todo_
- 791. Biografía autorizada de un ídolo del club — _Todo_
- 798. Reacción de la prensa extranjera ante un fichaje sorpresivo — _Todo_

**44. Árbitros, Reglamento y Disciplina**
- 812. Amnistía de amarillas al llegar a determinada fase — _Todo_
- 814. Denuncia por insultos discriminatorios — _Todo_
- 815. Protocolo antidiscriminación con partido suspendido — _Todo_
- 821. Regla de cinco cambios activable — _Todo_
- 822. Reglas experimentales aplicadas en ligas menores — _Todo_
- 823. Gol de visitante como criterio configurable — _Todo_
- 825. Puntos de fair play como criterio de desempate — _Todo_

**45. Federaciones, Licencias y Política Deportiva**
- 851. Repechaje internacional por un cupo — _Todo_
- 852. Sistema de licencias que impide ascender pese al mérito deportivo — _Todo_
- 854. Investigación internacional que sacude a la federación — _Todo_
- 855. Cambio de asociación continental en casos excepcionales — _Todo_
- 858. Aporte de tu club al coeficiente nacional — _Todo_
- 859. Diplomacia con federaciones extranjeras para amistosos — _Todo_

**46. Selecciones Nacionales**
- 864. Disputa entre dos selecciones por un mismo jugador — _Todo_
- 865. Eliminatorias organizadas por confederación — _Todo_
- 866. Repechaje intercontinental — _Todo_
- 869. Selecciones juveniles vinculadas a la absoluta — _Todo_
- 870. Torneo olímpico con reglas de edad — _Todo_
- 876. Retiro de la selección de un veterano emblemático — _Todo_
- 877. Debut de un canterano tuyo en la selección mayor — _Todo_
- 882. DT de selección que compite contigo por la atención de un jugador — _Todo_
- 883. Oferta para dirigir una selección mientras diriges un club — _Todo_
- 884. Doble cargo permitido o prohibido según el país — _Todo_
- 885. Legado como seleccionador registrado en el salón de la fama — _Todo_

**47. Competencias y Formatos**
- 898. Torneos regionales de carácter histórico — _Todo_
- 899. Torneos ficticios desbloqueables por logros — _Todo_
- 902. Cabezas de serie definidos por coeficiente — _Todo_
- 909. Tabla anual y tabla acumulada funcionando en paralelo — _Todo_

**48. Datos, Editor y Comunidad**
- 921. Plantillas de datos por país descargables — _Todo_
- 922. Actualización de plantillas al inicio de cada temporada real — _Todo_
- 926. Editor de calendario y fechas — _Todo_
- 931. Bloqueo opcional de edición para partidas competitivas — _Todo_
- 932. Registro de cambios aplicados a la base de datos — _Todo_
- 934. Sincronización en la nube entre dispositivos — _Todo_
- 935. Tabla de clasificación global de gestores en línea — _Todo_
- 937. Muro o foro de comunidad integrado — _Todo_
- 938. Desafíos semanales creados por la comunidad — _Todo_
- 939. Sistema de valoración de paquetes de datos — _Todo_
- 941. Herramientas de moderación para contenido de la comunidad — _Todo_
- 945. Guardado en la nube con recuperación de partidas — _Todo_

**49. Modos de Juego y Desafíos**
- 960. Modo DT puro: sin control sobre el dinero — _Todo_
- 962. Escenarios históricos recreados como desafío — _Todo_
- 963. Escenario: remontar diez puntos en ocho fechas — _Todo_
- 965. Escenario: ganar una copa con un club chico — _Todo_
- 966. Escenario: alcanzar una meta de ventas en una temporada — _Todo_
- 967. Escenario: formar cinco seleccionados en diez años — _Todo_
- 969. Modo largo de cincuenta temporadas — _Todo_
- 975. Ranking local de mejores puntajes — _Todo_
- 976. Multijugador por turnos en el mismo dispositivo — _Todo_
- 977. Multijugador en línea con varios gestores en la misma liga — _Todo_
- 978. Liga privada para jugar con amigos — _Todo_
- 979. Modo cooperativo: dos personas gestionando el mismo club — _Todo_
- 982. Reinicio de temporada con la misma semilla — _Todo_

**50. Progresión Meta y Rejugabilidad**
- 994. Desafíos diarios cortos independientes de la carrera — _Todo_
- 995. Recompensa por completar temporadas consecutivas — _Todo_
- 1001. Comparación de tu carrera con la de otros usuarios — _Todo_
- 1005. Metas autoimpuestas configurables por el usuario — _Todo_

**51. Interfaz y Calidad de Vida**
- 1014. Filtro de notificaciones por importancia — _Todo_
- 1017. Historial de navegación con botón de volver atrás — _Todo_
- 1021. Columnas configurables por el usuario — _Todo_
- 1026. Gestos de deslizamiento para cambiar de pestaña — _Todo_
- 1033. Retomar exactamente en la pantalla donde quedaste — _Todo_
- 1047. Notificaciones opcionales del próximo partido — _Todo_
- 1048. Sincronización de partida entre teléfono y tablet — _Todo_

**53. Monetización y Modelo Indie**
- 1092. Canal de reporte de errores dentro del juego — _Todo_
- 1093. Encuestas a jugadores para priorizar funciones — _Todo_

### Decisiones de producto, no tareas (20): monetización y estética; decide el dueño

943, 1051, 1055, 1072, 1075, 1076, 1077, 1078, 1079, 1082, 1083, 1084, 1085, 1086, 1087, 1088, 1089, 1090, 1099, 1100

## 8. Hallazgos de la tanda de pulido (25-10), sin arreglar
- Balance (medido por `pruebas/ideas/eq_diez_temporadas.gd`, especial `todo`; 10 temporadas × 3 semillas): el grande sin gestionar se hacía rico (rep 88→96, sueldos 17-27 % de los ingresos, caja 6,6→65-95 M en 10 años); 27-10: con `CrisisCaja` termina en 13-35 M y baja en 1-4 de las 10 temporadas. El chico sin gestionar pierde ~1-2 M/año también en Primera (resultado previsto −1,1 a −1,7 M): es estructural, no del descenso. s303 GRANDE da «último año 11 %» en t1 (rango 12-38 %).
- `Mundo.generar(["CHI"], semilla)` da el MISMO mundo en t0 con 101, 202 y 303 (la semilla solo cambia la simulación): ¿buscado?
- Pantalla de entrada: pendiente de tu aprobación como escena principal (`Inicio.flujo_nuevo`, §0).
- Carrera/partido jugable: el portero que no llega a un tiro ya se estira hacia el balón y queda batido (27-10, `MotorJugable._reaccion_portero`); falta verlo con la cámara real en un gol y decidir si la estirada fallida necesita un clip «batido» propio.
- Licencias 🟡 que quedan (sesión 6, `docs/04_auditorias/sesion_6.md`): `persona_realista.glb` → relevo de MakeHuman (CC0) ya enganchado en `visor/persona_mh.gd`: falta que el dueño suba por LFS `assets/personas/persona_mh_cuerpo.glb` y `persona_mh_ropa.glb` (generar con `herramientas/makehuman/mh_generar.py <datos> <Quaternius.gltf> persona_mh m` y renombrar) cuando el traje esté pulido (bajo de la chaqueta dentado, cejas manchadas), y luego excluir `persona_realista*` de las exportaciones públicas; `anims_futbol/` → la vía barata es guardar la captura de la página de Gumroad (dueño); CMU sirve de licencia pero exige retargetear BVH en Blender y no trae regates; `vagabond.obj` (velero), `arco_entrada`, `asientos_lod`, `podio_prensa` y las insignias de Canva siguen sin confirmar.

- Primera hora (informe onb, 26-10): cerrado el 26-10 (todo `grab_focus` diferido de `ui/entrada/*` pasa por `FocoSeguro.dar`, que comprueba que el control siga en el árbol; el resto es síncrono o va con `is_inside_tree()`). Lo demás (cabecera con ayudas, objetivos que ceden la ficha, reabrir el tutorial, carril de chips de los hubs) lo cerró la sesión 3.

- Más países jugables (fila 26 s4, sesión 6): medido por `pruebas/ideas/s6_paises.gd`: el juego conoce 86 países (banderas) y tiene liga en 23. Hecho: nombre de los 86 en los 9 idiomas (CLDR, `datos/paises.json`, `Paises`). Falta para hacerlos jugables: liga y clubes ficticios (`herramientas/base_ficticia.py`), bolsas de nombres propias para 62 (faker por locale, MIT) y regiones (GeoNames) más allá de ESP/EUS.

## 9. Sesión 2 (interfaz): rama `ccr-76d707c5-dwse9h-s2`, sin fusionar
Informe: `docs/04_auditorias/sesion_2.md` en esa rama. Al fusionar: reaplicar `datos/trad_parches/s2_*.json` con `sumar_traducciones.py` y `s2_sobrescrituras.json` con un script con candado (ver el informe).

Peticiones a zonas que no eran suyas (la 14, partir `banco_p25.gd`, ya está hecha: 67 líneas):
12. Tilde en `nucleo/prensa_p4_p1.gd:27` «mas corta»: la frase es clave de `datos/narracion_traducida*.json`; cambiarla exige renombrar la clave y regenerar (`extraer_narracion.py` + `montar_narracion.py`), y hoy esa regeneración cambia ~8.000 líneas de `narracion*.json` (revisar antes por qué).

Defectos a la vista que dejó anotados: ninguno pendiente (el de «Forma del escudo» ya estaba aplicado el 26-10).

Auditoría de fuentes y de presentación del texto (26-10, sesión fnt). Lo de traducción es para S1:
- **150 claves que no aparecen literalmente en el código ni en los datos**: casi todas se componen en tiempo de ejecución (icono + texto, «✔  …», «·····  Jefe médico», «sí   Construir»), así que NO son claves muertas seguras. Hay restos claros, como «Estrecha (cabe mas)» sin tilde, que es el nombre viejo de la tipografía. Antes de borrar nada: un barrido que registre en partida qué claves se piden de verdad.
- **Caídas por formato**: no hay ninguna clave cuyos `%s`/`%d` no casen con su traducción. Los 42 avisos que salen al comparar son «%» de porcentaje literal («12% más»), no marcadores. La única llamada que formatea DENTRO de `Idiomas.t` es `ui/principal/rueda_prensa.gd:414` (`Idiomas.t("%s %s" % …)`, icono + texto); funciona porque `t` separa el icono, pero lo limpio es `Idiomas.t(datos[1])` (zona de la rueda de prensa).
- **Nombres propios con la misma forma en todos los idiomas**: las leyes laborales (Arbeitszeitgesetz, Fair Labor Standards Act…), DINASTÍA, VAR, Valparaíso. Están bien; no hay que traducirlos.
- **El registro «Qué pasa»** («Mundo nuevo. Semilla …») queda en el idioma en que se escribió: son entradas guardadas, no rótulos. Está bien así, pero conviene saberlo.

## 10. Huecos y mejoras propuestas
Lo que un juego de gestión de fútbol pulido necesita y no estaba en ningún sitio del plan (o solo como idea suelta en §5-7). Prioridad: **alta** = bloquea el lanzamiento o la primera impresión; **media** = se nota en la primera semana de juego; **baja** = pulido.

| Hueco | Prioridad | Por qué | Primer paso |
|---|---|---|---|
| **Pruebas de juego reales** (personas que no lo conocen) | alta | el banco mide reglas, no si se entiende ni si divierte; nadie ajeno ha jugado la primera hora | 3-5 jugadores, sesión grabada de 60 min, lista de dónde se pierden |
| **Onboarding de la primera hora** medido | alta | el tutorial (970 líneas) existe, pero no hay prueba de qué hace un novato en los primeros 10 min | prueba de arranque completo (7.3) + cronometrar «hasta el primer partido» |
| **Rendimiento en móvil** (memoria, batería, calentamiento) | alta | solo hay medidas en software; 1,34 M triángulos y caras sin comprimir pesan más en móvil | perfil de calidad «móvil» y presupuesto de memoria por escena; medirlo el dueño (§1) |
| **Builds y tienda** (Steam/itch/Play): iconos, capturas, tráiler, texto, clasificación | alta | sin esto no hay lanzamiento; hoy solo «🔒 dueño» | lista de requisitos de cada tienda y quién hace cada pieza |
| **Sonido y música**: mezcla final, volumen por canal, música 🔒 | media | 214 recetas de efectos, pero sin pasada de mezcla ni música final | pasada de volúmenes por escena; qué falta si la música no llega |
| **Localización de nombres** (clubes, ciudades, competiciones, nombres propios) | media | la sesión 2 dejó ~120 textos por idioma que son nombres propios; no hay regla de cuáles se traducen | lista de «no traducir» (como `marca_sin_traducir`) y de los que sí (competiciones) |
| **Accesibilidad (lo que falta del nivel básico)**: lector de pantalla mínimo; reasignar las teclas del menú lateral y del móvil; repasar con contraste alto las pantallas en 3D (estadio, ciudad) y las capas a pantalla completa | media | hecho en la sesión 3: reasignar aceptar/volver/pestañas, contraste alto (paleta + `Tema`), zonas y plantel sin depender del color | probar el juego entero con contraste alto y solo teclado |
| **Guardado en la nube** / entre dispositivos | media | ideas 234, 934, 945 y 1048 sin plan; los jugadores de gestión llevan partidas de meses | empezar por exportar/importar la partida a un archivo; la nube depende de la tienda |
| **Ayuda contextual y glosario** (qué es cada cifra) | media | un juego de gestión tiene cientos de cifras; hoy hay ayudas sueltas | botón «?» por pantalla con 3 líneas y enlace al glosario |
| **Canal de errores dentro del juego** | baja | idea 1092; necesario tras lanzar (las notas de versión ya están: «Novedades», `datos/novedades.json`) | enviar el informe del registro de fallos desde el juego |


## 11. Propuestas de lanzamiento (investigación s4, aprobadas 26-10)
Filas 1-14 de `docs/04_auditorias/investigacion_s4/03_propuesta.md`, aprobadas por el dueño el 26-10. Esfuerzo: **S** < 1 día, **M** 1-5 días, **L** > 1 semana. Lo que ya estaba en otra sección se remite allí y no se duplica.

| # | Qué | Prioridad | Esfuerzo | Archivo o sistema | Estado |
|---|---|---|---|---|---|
| 1 | **Presupuesto de clics**: medir las 10 tareas más frecuentes (once, fichar, renovar, entrenar, avanzar semana, táctica, prensa…) con tope ≤ 2 clics o 1 atajo, en el PC de la oficina y el menú central | alta | M | `ui/principal*.gd`, `ui/componentes/menu_lateral.gd`; prueba nueva en `pruebas/` | hecho por la sesión 3 (`s3_atajos_clics`: las 10 tareas a ≤ 2 clics y a una tecla); falta medirlo con jugadores (§10) |
| 2 | **Atajos de teclado** en todo el menú central, editables, y vista «densa» de tablas | alta | M | `ui/principal_p2.gd`, `nucleo/mando.gd`, `ui/componentes/panel_controles*.gd` | atajos hechos por la sesión 3 (1-9, 0, N, F3, F5; editables en Accesibilidad); falta la vista «densa» de tablas |
| 3 | **Fuentes propias** con cobertura completa (Inter, Noto Emoji, Noto Sans Symbols 2, Barlow Condensed, Bebas Neue; ~4,3 MB, OFL, fuera de LFS) | alta | S | `ui/tema.gd`, `ui/principal_p2.gd` (`TIPOGRAFIAS`, `REPUESTO_SIMBOLOS`), `ui/principal_p4.gd` (`_fuente_de`) | en curso (otro agente) |
| 4 | **Explicar el porqué**: 3 causas tras cada partido; en finanzas, cada ingreso y gasto con su origen | alta | M | `nucleo/partido_p1.gd`, `ui/componentes/resumen_partido.gd`, `nucleo/finanzas.gd`, `ui/componentes/panel_finanzas*.gd` | pendiente (el flujo de caja ya está en §9) |
| 5 | **Vida privada regulable**: Ajustes «Vida: completa / ligera / apagada» | alta | S | `nucleo/necesidades.gd`, `ui/pantallas/pantalla_ajustes_vida.gd` | en curso (hecho el 26-10, falta revisarlo jugando) |
| 6 | **Hinchada y banquillo animados**: Mesh2Motion (CC0) + plugin VAT (MIT) | alta | M | `herramientas/hornear_publico.gd`, `visor/stadium_builder_p5.gd`/`p6.gd`, `visor/hinchada.gdshader`, `visor/festejo_grada.gd`, `visor/personaje_dt*.gd` | pendiente (parte en §3 semana 4 «espectáculo») |
| 7 | **Quitar los 🟡 de licencias** que quedan (KayKit ya hecho en la s6): MPFB2/MakeHuman → `persona_realista.glb`; CMU → tiros y protestas | alta | M-L | `visor/persona_realista.gd`, `visor/city_builder*.gd`, `visor/anim_futbol*.gd`, `visor/retarget_futbol_q.gd`, `docs/05_referencia/LICENCIAS.md` | pendiente (completa §1 «confirmar 🟡») |
| 8 | **CI con Godot 4.7.2** (`barichello/godot-ci:4.7.2-stable` o `chickensoft-games/setup-godot`) que corra `banco.sh` | alta | S | `.github/workflows/compilar.yml`, `dinastia-godot/herramientas/banco.sh` | en curso (otro agente; es la misma tarea de §1) |
| 9 | **Silbato real y percusión** de VCSL (CC0): `audio/ui/silbato.ogg` y capas del bombo | alta | S | `nucleo/sonido.gd` (`AJUSTE_DB`) | en curso (otro agente) |
| 10 | **Registro de errores visible** + «copiar informe» | alta | S | `nucleo/registro.gd`, `ui/pantallas/pantalla_ajustes_registro.gd` | hecho (26-10): `user://registro.txt` y Ajustes → Partida → «Informe de fallos»; queda el aviso de guardado corrupto en `nucleo/partida_archivo.gd` |
| 11 | **Pruebas con 3-5 jugadores ajenos** en la primera hora | alta | S (del dueño) | — | ya en §10 «Pruebas de juego reales»: no se duplica |
| 12 | **Monetización** | alta | — | — | por ahora sin pago (decisión del dueño, 26-10) |
| 13 | **Imprevistos con contexto**: 42 eventos con condiciones y efectos que duran | alta | M | `nucleo/imprevistos.gd`, llamada en `nucleo/mundo_p5_p2.gd` (`_semana_imprevisto`) | en curso (hecho el 26-10, falta revisarlo jugando) |
| 14 | **Ocasiones jugables en el partido del DT**: en las 3-6 llegadas claras, pausa y eliges pase, conducción o tiro con la cámara a pie de campo | alta | L | `nucleo/partido*.gd`, `nucleo/motor_libre.gd` (`tomar_control`), `ui/partido_vivo*.gd`, `visor/control_partido.gd` | pendiente |

Exportar e importar la partida (fila 30 de la propuesta, §10 «Guardado en la nube») ya está hecho: Ajustes → Partida (`ui/pantallas/pantalla_ajustes_p1.gd`, `_exportar_partida` y `_importar_partida`). Queda la nube.

- (27-10) Paradero Red rehecho según las fotos del dueño (`visor/paradero_red.gd`, tabla `datos/paraderos_red.json`); la sesión líder conecta `RecorridosRed` al cartel al unir. Correas de mochila planas pegadas al torso (falta captura de frente). Sillón de oficina en despacho DT/presidente (`visor/sillon_oficina.gd`; faltan capturas sin avatar). Pelo Drive a ~4500 tris: falta revisar los 11 peinados uno a uno (hoja antes/después) antes de usarlos en futbolistas. Pasto: pendiente.
- (27-10) Revisión del pelo Drive, 11 peinados a 1,5 m (`docs/04_auditorias/capturas_personajes/pelo_drive_revision_11.jpg`, filas: 73,74,77,79,80,68,28,60,117,33,36; izquierda = Quaternius, derecha = Drive): solo quedan el 80 (rizado) y el 68 (flequillo); los otros 9 se descartaron (casco, ojos tapados, huecos). No hay pelo Drive femenino ni en futbolistas. Para más variedad: elegir otros del OBJ con la misma vara (de cerca, MEJOR que Quaternius).
- (27-10) Pasto del Drive (`visor/pasto_ciudad.gd`): matas `mata_1/2.glb` con MultiMesh por celdas de 24 m, ocultas a 42 m, sin sombra; en parques (borde y manchones, fuera de cancha, lago y paseos) y orillas del río. Captura `capturas_ciudad_c2/pasto_antes_despues.jpg` (arriba antes, abajo después). PASTO_DRIVE=0 lo apaga. Densidad subida (bordes de paseos, pie de árboles, orillas cada 1,6 m, huecos entre casas) y tono llevado al verde del parque. Ya también en patios de manzana, feria y finca grande. COSTE medido (cámara de parque, software): +90 mil triángulos (3,89 M → 3,98 M, +2 %) y +22 llamadas de dibujo con 15.776 matas sembradas gracias al corte a 42 m. Falta: mirar FPS en hardware real
- (27-10) 327 Celebración de trofeo en 3D (`visor/celebracion_trofeo.gd`, test `p6_celebracion_trofeo`, captura `capturas_personajes/celebracion_trofeo.jpg`): el once se junta en el círculo, el capitán (nunca el portero) levanta la copa del título (`TrofeoModelo`), confeti, vuelta olímpica por la pista con el equipo detrás, grada de pie y saltando, panorámica final. Se lanza sola al ganar un título (`vistas_menu._ver_vuelta_olimpica`; se apaga con la clave `vuelta_olimpica`; nunca en headless ni con otro 3D abierto). Pulir: el plano del segundo 12 pasa por el túnel; la copa podría ir más arriba en la vuelta.
- (27-10) M-186 edificios entrables: 5 salas propias nuevas para los comercios que abrían una tienda/oficina genérica (`interior_instalacion_p7.gd`: farmacia, banco, hotel, ferretería, floristería; `SALA_DE_ROTULO` las enlaza; captura `capturas_ciudad_c2/salas_comercio_nuevas.jpg`, test `p6_salas_comercio`). Correos, Deportes, Pizzería y Heladería también (`salas_comercio_nuevas2.jpg`) y la Peña del club (`sala_pena_club.jpg`). Hotel algo vacío: añadir habitaciones arriba.
- (28-10) M-183 rutinas de peatones por hora y barrio (`visor/rutina_peatones.gd`, test `p6_rutina_peatones`, captura `capturas_ciudad_c2/rutinas_peatones_sur.jpg`: arriba antes, abajo después; barrio sur a las 8 y a las 13 h): curvas de densidad por sector de `RecorridosRed`, +25 % de prisa en hora punta, -15 % paseando y más paradas a la hora de comer; se apaga con `RUTINA_PEATONES=0`. FLUJO DIRECCIONAL hecho (`RutinaPeatones.sentido/factor_flujo`: a contramano de la hora sale menos gente; medido en el barrio sur, solo peatones de rumbo claro: a las 8 h antes 23 hacia el trabajo y 17 de vuelta, ahora 22 y 11; a las 18 h antes 31 y 23, ahora 18 y 21). Maletines en hora punta hechos (`PeatonVida.maletin`, `capturas_personajes/peatones_maletin.jpg`). Mochilas por hora hechas (`PeatonVida.mochila`, `RutinaPeatones.lleva_mochila`; medido en el barrio sur: 35 de 92 a las 8 h, 20 de 61 a las 11 h, 0 a las 2 h). Pendiente: que `ParaguasVida` y las rutinas compartan la velocidad base (hoy se multiplican).
- (28-10) Autobús: las puertas del modelo pasan al lado de la ACERA (−X; el bus mira a +Z) y los pasajeros suben/bajan por ahí (`city_builder_p10.autobus`, `PasajerosBus.parada`); comprobado con la cámara (`pruebas/captura_bus_puerta.gd`: la puerta nueva queda 2,6 m más cerca de la espera). Paraderos: los 124 miran a la calzada (`pruebas/captura_paraderos_orient.gd`, 0 mal orientados); hoja `capturas_ciudad_c2/paraderos_por_sector.jpg` (izq. = frente, der. = espalda). Dato para la tabla de recorridos: un paradero en x=454 (sector 300 según `sector_de`) lleva el código PA1002 (sector 100).
- (28-10) Peatones que SUBEN de verdad al bus (orden 14): ahora caminan a la puerta del lado de la acera, suben el escalón y se adentran por el pasillo (los que bajan salen del pasillo por la puerta a la acera). Captura `capturas_ciudad_c2/peatones_suben_bus_antes_despues.jpg` (filas 1-2 antes: puerta del lado de la calzada, rodean el bus y desaparecen tras él; filas 3-4 después), escena `pruebas/captura_subir_bus.gd` (`BUS_PUERTA_ANTIGUA=1` pone el modelo de antes). Pendiente: que los trenes y el teleférico hagan lo mismo (otra sesión).
- (28-10) Autobús (orden 13): modelo sacado a `visor/autobus_modelo.gd` con librea «Red» (blanco con faldón rojo y filete del color del recorrido), ruedas a escala con llanta, pasos de rueda, parabrisas inclinado y espejos; el bus para con la PUERTA DELANTERA frente al paradero (`BusesRed.PUERTA_ADELANTE`: la parada se adelanta 4,6 m); los pasajeros esperan BAJO EL TECHO del paradero (`PasajerosBus.sitio_espera`). Captura `peatones_suben_bus_antes_despues.jpg` (arriba antes, abajo después, cámara a 1,7 m). Hecho también: montantes negros entre ventanas, faros y luces traseras (`bus_red_modelo.jpg`). Pendiente: cristal con reflejo, y mismo tratamiento para el metro y el tren.
- (28-10) Paraderos de noche revisados (`capturas_ciudad_c2/paraderos_de_noche.jpg`, 22:00, un paradero por sector): cabecera, cartel y panel se leen (emisivos); tubo fluorescente bajo el techo añadido. Falta que el paradero ilumine la acera (una luz real sería cara en 124 paraderos: valorar proyector falso en el suelo).
- (28-10) Pelo Drive, 2.ª ronda (`capturas_personajes/pelo_drive_revision_ronda2.jpg`, filas: 78,81,83,63,92,55,57,61,59,69): solo entra el 59 (rizado corto); los demás tapan los ojos, dejan la nuca pelada o con huecos. Hoy hay 3 peinados masculinos (80, 68, 59) y ninguno femenino; los 105 del OBJ ya se han mirado a vista de pájaro, el resto son largos/coletas/trenzas.
- (28-10) Teleférico con gente que sube y baja (`visor/pasajeros_teleferico.gd`, test `p6_pasajeros_teleferico`, captura `capturas_ciudad_c2/teleferico_gente.jpg`): al llegar la cabina a la estación de abajo bajan dos personas por la puerta y cruzan el andén; unos segundos después suben otras dos desde la plaza y entran. Metro (`MetroCiudad._planear_embarque`) y Estación Central (`PasajerosEstacion`) ya tenían embarque; el tren del metro ya lleva carrocería de acero, bogies, interior y rótulos (`TrenDetalle`), así que no se le aplica la librea Red (es «Metro», no Red). Pendiente: gente que suba a la cabina de ARRIBA y que se vea el cambio de viajeros dentro de la cabina.
- (28-10) M-174 interior del coche: ya existía `CabinaCoche` (salpicadero, volante con manos, retrovisor, pilares; captura `capturas_ciudad_c2/cabina_coche_3d.jpg`, tecla V: capó / primera persona); queda el `VolanteUI` 2D solo para el mando táctil. M-177 gasolinera con LAVADO DE AUTOS y APARCAMIENTO (`visor/ciudad_lavado.gd`, captura `gasolinera_lavado_aparcamiento.jpg`): túnel de 18 m con rodillos y cepillo que giran (grupo `lavado_giratorio`, para que `Optimizar.agrupar` no los funda), espuma, rótulo y semáforo; 8 plazas numeradas con 3 coches de la flota. Pendiente: lavar de verdad el coche del DT (suciedad + E en el túnel) y plazas «usables» para aparcar el coche propio.
- (28-10) M-170 semáforos peatonales con botón (`visor/semaforos.gd`, test `p6_semaforo_peatonal`, captura `capturas_ciudad_c2/semaforo_peatonal.jpg`: arriba rojo, abajo verde): en cada poste una cabeza peatonal por eje (rojo / verde / verde intermitente los últimos 4 s) y un botón amarillo a 1,1 m; a pie, E junto al poste pide el verde (llega en ~2 s) o avisa de que ya se puede cruzar (`pedir`/`pedir_con_aviso`; el ciclo es COMPARTIDO por todos los cruces, así que adelanta el de toda la ciudad). Pendiente: que los peatones de `TraficoCiudad` respeten la fase peatonal (hoy ceden paso por distancia a los coches, no por la luz) y botón por cruce en vez del ciclo global.
- (28-10) M-168 rotonda (`visor/ciudad_rotonda.gd`, captura `capturas_ciudad_c2/rotonda_antes_despues.jpg`, arriba antes con semáforos, abajo después): en el cruce avenida × avenida (-660, 330), uno de los 38 que NO tiene ninguna ruta de coches a menos de 16 m (así no rompe la red): se le quita el semáforo y se levanta isla de 6,5 m con bordillo, monumento, arbustos y árboles, anillo asfaltado con rayas, señales de ceda el paso y flechas de giro antihorario; la isla es obstáculo sólido (`CityBuilder.circulos`). `SIN_ROTONDA=1` la apaga. Pendiente: una rotonda con TRÁFICO (desviar las rutas por el círculo; hay que reconstruir las paradas y los controles de las rutas que pasan por el cruce) y quitar de la lista de semáforos peatonales los botones de ese cruce.
- (28-10) M-193 flores (`PastoCiudad.flores`, captura `capturas_ciudad_c2/flores_antes_despues.jpg`, izquierda antes y derecha después): una de cada dos matas del parque, los patios y la feria es el centro de un ramillete de 9 flores de cinco colores (tallo + cabeza con color por instancia), MultiMesh por celdas con corte a 38 m; coste medido +1,1 % de triángulos (4,28 M → 4,33 M) y +4 llamadas. `SIN_FLORES=1` las apaga. Pendiente: setos con flor y enredaderas en fachadas.
- (28-10) M-182 tarjeta de transporte Red (`CarteraDT.saldo_transporte/TARIFAS/recargar_transporte/pagar_pasaje`, test `p6_tarjeta_transporte`; `VidaCiudad.usar_billetes/cobrar_pasaje`): las máquinas de billetes de los andenes (E) recargan 5 € de la cartera; entrar al metro cuesta 1 € y subir al teleférico 3 €, de la tarjeta; sin saldo no se sube y avisa. Se guarda en la partida (`transporte`). Sin captura (es texto de diálogo). Pendiente: cobrar también el bus cuando el DT suba a uno (hoy solo suben figurantes), mostrar el saldo en la app «Red» del móvil y abono mensual.
- (28-10 cierre) Quedan de la sesión 3: peatones NPC que respeten la fase peatonal; rotonda con tráfico real; metro y tren con librea (no «Red»); luz de acera en paraderos; reflejo de farolas en los charcos de noche; el pasaje solo lo cobra el bus del DT; saldo de la tarjeta en la app «Red». Ver `docs/04_auditorias/sesion_3_cierre_28-10.md`.

- (2-11) Sesión 3, cola del lunes. HECHO: peatones NPC que cruzan avenidas con su fase peatonal (`PeatonesCruce`, 24 cruces, test `p6_peatones_cruce`; `TraficoCiudad` usa `Semaforos.peatonal` para peatones), rotonda con 3 coches en su carril circular (`CiudadRotonda.trafico`), el DT sube al bus Red junto al paradero (E, paga 1 € de la tarjeta, baja 3 paradas después: `BusDT`, test `p6_bus_dt`) y la app Red muestra el saldo, velocidad de peatones = base × prisa de la hora × prisa de la lluvia (`RutinaPeatones.poner_factor`), PA1002 en su sector (el sector del código sale de DONDE queda el paradero), `BanderasGrada` conectada a `FestejoGrada` en el gol (captura `banderas_grada.jpg`), teleférico: estación de arriba con su rampa y su gente, llegadas de las dos cabinas y viajeros que cambian dentro (`PasajerosTeleferico.cambiar_viajeros`), prólogo con túnel, utilería, sala de vídeo y comedor (el personal saluda: `PrologoDT._saludan`), gesto del DT según el tono en la presentación (`PrologoPasos.GESTO_TONO`), entrevista de contratación de 3 preguntas (`Citas.RONDAS`; falta la versión para el staff), rama con «visibilidad» (ceder el estadio) y celebración de sus títulos (`Citas`, `Hinchada.visibilidad_rama`), M-187 casas con horario (`HabitantesCasa`), M-180 vendedor del andén. Pasada visual en el partido: peinados del Drive y postura en los futbolistas (`player_spawner_p1`, apagable con `SIN_PELO_DRIVE=1` / `SIN_POSTURA=1`); mochilas no (no tienen sentido en el campo). PENDIENTE: pelo femenino (los 5 candidatos se descartaron; hace falta elegir otros del OBJ), hoja `capturas_personajes/pelo_postura_partido_antes_despues.jpg` (arriba antes, abajo después; en la cámara de TV no se distingue y el plano cercano es poco concluyente porque los jugadores se mueven entre una y otra pasada: falta una toma con el balón parado y el veredicto del dueño), música del metro.

- (2-11) Pelo femenino del Drive: probados otros 12 peinados sobre el cuerpo femenino (hoja `capturas_personajes/pelo_mujer_drive_candidatas_2.jpg`); NINGUNO mejora el corte de Quaternius (láminas con huecos, flequillos que tapan los ojos, el moño parece casco). `PeloDrive.MUJERES` sigue vacío; hace falta otro pack de pelo femenino o modelarlo a mano. Los 24 índices ya probados: 18, 25, 28, 33, 36, 38, 44, 49, 53, 55, 57, 59, 60, 61, 63, 65, 68, 69, 76, 78, 81, 83, 84, 85, 90, 92, 108, 111, 112, 115, 117.
- (2-11) M-199 señales de límite de velocidad (`SenalesVelocidad`, 164 en los cruces, 40/50/60 por sector, captura `capturas_ciudad_c2/senales_velocidad.jpg`) y multa de 60 € por pasar 20 km/h con la policía a la vista; M-170 el peatón NPC pulsa el botón del cruce (una vez cada 25 s en todo el mapa). LECCIONES: un `visibility_range_end` en un MultiMeshInstance3D se mide desde el ORIGEN del nodo (oculta lo lejano); `CiudadExpansion` es RefCounted (colgar de `ex.b`); mirar siempre las últimas líneas del banco por SCRIPT ERROR.
- (2-11, queja del dueño con captura del móvil) HECHO: la pantalla de carga de «Construyendo la ciudad…» salía en una esquina, cortada y sobre gris (centrada con `PRESET_CENTER` sobre un padre de tamaño 0): ahora un `CenterContainer` a pantalla completa y se ajusta a la ventana (`PantallaCarga._ajustar`, test `p6_pantalla_carga`); la barra avanza con las etapas reales de la construcción y dice cuál es. Los chips de pasos de arriba de la configuración del club ya no dejan saltarse un paso con error (`ir_a_chip`). Móvil: zoom de interfaz 1,5 la primera vez en Android/iOS/web táctil (`EscalaMovil`, se respeta lo elegido en Ajustes, máximo 1,8) y campos de texto de 56 px. Velocidad del diseñador de uniforme: la camiseta 2D guarda su estructura por tamaño (`DisenosKitEstructura`, idéntica píxel a píxel en 480 comparaciones y 4 veces más rápida), se dibuja sin supermuestreo y se afina a los 0,7 s, y las 70 miniaturas se generan con presupuesto de 6 ms por fotograma (abrir «Equipación» en el servidor: de ~4 s a ~1,2 s). PENDIENTE: construir la ciudad sigue tardando ~17 s en este servidor (mide con `TIEMPO=1 medir_ciudad`: estadio 2,8 s, suelo 2,2, despejar 1,9, bloques 1,8, tráfico 1,8, afueras 0,9, mobiliario 0,9, agrupar 0,9). En Android falta la extensión C++ (solo hay Linux y Windows en `bin_nativo/`): el terreno y la hierba van en GDScript y tardan bastante más; DECISIÓN de la líder (2-11): DIFERIR lo lejano tras mostrar la ciudad (lo hace la sesión de ciudad, con medida antes/después y prueba de igualdad de piezas). El .so de Android ya lo compila el CI (`nativo-android`, M-353): falta que el artefacto llegue a `bin_nativo/` o a la exportación de Android (dueño/CI).

- PULIDO (10-11, caras): la edad se ve en la cara 2D (`CaraEdad`: canas, entradas, calvicie, arrugas; también a los de cara típica por país; no a quien lleva color medido de foto) y la biblioteca de mezclas pasó de 72 a 300 caras (6 tonos x 50; PUBLICADA el 10-11 por orden 36 del dueño; revisar_build_publico exige que viaje). Antes/después de 12 jugadores de 6 países: `docs/04_auditorias/caras_edad_antes_despues_2026-11-10.jpg`. Pendiente: peinados del Drive para mujeres/más cortes, arrugas en la cara 3D de jugadores.

- PULIDO (10-11, uniformes 3D): segundo uniforme propio (`VisitaGenerada`: conserva los colores del mínimo deducido y le da diseño, pantalón y medias; si el adorno choca con el local pasa a un diseño de adorno pequeño) y `KitLegible` (en el campo, los diseños finos pasan a su versión ancha; fichas y editor no cambian). Antes/después en `docs/04_auditorias/uniformes_3d_antes_despues_2026-11-10.jpg`. A la cámara real los equipos se distinguen; los dibujos siguen siendo poco legibles (jugador ~30 px): pendiente textura/shader del torso.

- PULIDO (10-11, legibilidad del torso): `equipacion_q.gdshader` separa el dibujo de la camiseta del color base cuando el jugador se ve pequeño (uniform `legible`, 0,7; 0 lo apaga; solo ALU por píxel, sin llamadas ni triángulos). Mejora pequeña a ~25 px (blancas más nítidas, oscuras con más contraste); los dibujos finos siguen costando a esa distancia. Antes/después: `docs/04_auditorias/uniformes_legible_antes_despues_2026-11-10.jpg` (CHI–USA, KOR–NED, POR–URU). Ajustes siguientes: subir `legible` o ensanchar más el dibujo por familia.

- CIERRE DE LA SESIÓN «segunda» (10-11, rama `especiales-datos`; commit final en el aviso al líder). HECHO: pasada completa de `especiales.sh todo` sobre `main` con 1.215 clubes y arreglo por causa de: a4_metro_museo (carrera de la prueba con el viaje del ascensor), s5_tactica_roles (contrapresión real en el 3D: ventana «tras la pérdida» por equipo), pizarra_motor (N=6 por tiempo), presupuesto_partido (rótulos con contorno solo los 5 más cercanos al balón en calidad baja + capas de cabeza solo de cerca: jugadores 126→74 llamadas, techo 76, margen de 2), auditoría de datos, aspecto de los clubes (escudos repetidos: `_escudos_zz_choques.txt`), recetas de trofeo por país (`TrofeosReales.id_de`), Países Bajos, banderas de China y Emiratos, y las pruebas desfasadas por las ligas de formato propio, las segundas divisiones, todos los países con liga y la biblioteca de 300 caras. PENDIENTE: (1) repetir `a4_limite_mundo` (falló en la pasada; mi `pkill -x godot` pudo matarla) y la sonda «motor: el mejor gana al peor» (`ESCENARIO=calidad N=6`, 304 s, falló la pasada; sin investigar); (2) presupuesto_partido con margen de 2 llamadas: si se añade algo por jugador, optimizar más (fusión de capas de cabeza o pelo lejano); (3) legibilidad de diseños de camiseta a la cámara real: mejora pequeña, falta textura/shader del torso o cámara más cerca; (4) ORDEN 36: jugadores con campos fijos (misma huella en igualdad_mundo/igualdad_motor, migración de partidas viejas con prueba, medir memoria y tiempo por semana antes y después): NO empezada. (5) Las pruebas de recorrido con RECORRIDO_IDIOMA dejan `idioma` guardado en `user://preferencias.cfg`: hay que restaurarlo al terminar (la sesión 4 ya lo hizo en la suya).
